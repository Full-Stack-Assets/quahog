## PlayerWallet.gd
## Autoload singleton — tracks the player's cash balance with a full audit trail.
## Ported from PlayerWallet.cs (Unity) to Godot 4 GDScript.
## Access via: PlayerWallet.<method_or_property>
extends Node

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal balance_changed(new_balance: float)      ## Emitted after every balance mutation.
signal transaction_logged(message: String)      ## Emitted with a human-readable transaction record.

# ---------------------------------------------------------------------------
# Private state
# ---------------------------------------------------------------------------
var _balance: float = 0.0

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
	print("[PlayerWallet] Initialised. Balance: $%.2f" % _balance)

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Read-only access to the current balance.
func get_balance() -> float:
	return _balance


## Returns true if the player can afford the given amount.
func can_afford(amount: float) -> bool:
	return _balance >= amount


## Deducts the given amount from the wallet if affordable.
## Returns true on success, false if insufficient funds.
func deduct(amount: float, reason: String = "") -> bool:
	if amount < 0.0:
		push_warning("[PlayerWallet] deduct() called with negative amount (%.2f). Use add() instead." % amount)
		return false

	if not can_afford(amount):
		var msg: String = "FAILED deduct $%.2f (%s) — insufficient funds (balance: $%.2f)" % [amount, reason, _balance]
		print("[PlayerWallet] %s" % msg)
		emit_signal("transaction_logged", msg)
		return false

	_balance -= amount
	var msg: String = "DEDUCT $%.2f (%s) → balance: $%.2f" % [amount, reason, _balance]
	print("[PlayerWallet] %s" % msg)
	emit_signal("transaction_logged", msg)
	emit_signal("balance_changed", _balance)
	return true


## Adds the given amount to the wallet.
func add(amount: float, reason: String = "") -> void:
	if amount < 0.0:
		push_warning("[PlayerWallet] add() called with negative amount (%.2f). Use deduct() instead." % amount)
		return

	_balance += amount
	var msg: String = "ADD $%.2f (%s) → balance: $%.2f" % [amount, reason, _balance]
	print("[PlayerWallet] %s" % msg)
	emit_signal("transaction_logged", msg)
	emit_signal("balance_changed", _balance)


## Directly sets the balance (used by SaveLoadManager on load).
## Does not emit transaction_logged — this is a restore operation.
func set_balance(amount: float) -> void:
	_balance = maxf(amount, 0.0)
	print("[PlayerWallet] Balance set directly to $%.2f" % _balance)
	emit_signal("balance_changed", _balance)
