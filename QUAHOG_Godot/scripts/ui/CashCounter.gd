# CashCounter.gd
# Project QUAHOG — Label that displays the player's cash balance.
# Connects to PlayerWallet autoload and animates the number counting up/down.
extends Label

# ──────────────────────────────────────────────
# Constants
# ──────────────────────────────────────────────
const COUNT_DURATION: float = 0.6   ## Seconds to animate the count

# ──────────────────────────────────────────────
# Private state
# ──────────────────────────────────────────────
var _display_value: float = 0.0   ## The value currently shown (animated)
var _target_value: float  = 0.0   ## The value we're counting toward
var _tween: Tween         = null

# ──────────────────────────────────────────────
# Lifecycle
# ──────────────────────────────────────────────
func _ready() -> void:
	var wallet = get_node_or_null("/root/PlayerWallet")
	if wallet:
		if not wallet.balance_changed.is_connected(_on_balance_changed):
			wallet.balance_changed.connect(_on_balance_changed)
		# Initialise display with the wallet's current balance if available
		if wallet.has_method("get_balance"):
			_display_value = wallet.get_balance()
			_target_value  = _display_value
	else:
		push_warning("CashCounter: PlayerWallet autoload not found.")

	_update_label(_display_value)


# ──────────────────────────────────────────────
# Signal handler
# ──────────────────────────────────────────────
func _on_balance_changed(balance: float) -> void:
	_target_value = balance
	_animate_to(balance)


# ──────────────────────────────────────────────
# Animation
# ──────────────────────────────────────────────
func _animate_to(target: float) -> void:
	# Kill any running tween so we don't compound
	if _tween != null and _tween.is_valid():
		_tween.kill()

	_tween = create_tween()
	_tween.tween_method(_update_label, _display_value, target, COUNT_DURATION)
	_tween.tween_callback(func() -> void:
		_display_value = target
	)


func _update_label(value: float) -> void:
	_display_value = value
	text = "$%s" % _format_cash(int(value))


# ──────────────────────────────────────────────
# Formatting
# ──────────────────────────────────────────────
## Format with comma separators: 1234567 → "1,234,567"
func _format_cash(amount: int) -> String:
	var s: String = str(abs(amount))
	var result: String = ""
	var count: int = 0

	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1

	return ("-" if amount < 0 else "") + result


# ──────────────────────────────────────────────
# Public helpers
# ──────────────────────────────────────────────
func set_balance_immediate(balance: float) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_display_value = balance
	_target_value  = balance
	_update_label(balance)
