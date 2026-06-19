## TestSceneBootstrap.gd
## Minimal test-scene initializer for core systems + basic UI.
## Ported from TestSceneBootstrap.cs (Unity C#) for Project QUAHOG / Godot 4
##
## Attach to a Node in an otherwise-empty scene and run it: _ready() spins up a
## minimal harness — validates the core autoload singletons and draws a cash
## counter (top-left) plus a health bar (bottom-left). The individual steps are
## also exposed as public methods so they can be driven manually.

extends Node

# ---------------------------------------------------------------------------
# Dependencies
# ---------------------------------------------------------------------------

## Core autoload singletons the test scene depends on. In Godot these are
## registered in project.godot under [autoload], so init is a validation pass
## rather than runtime instantiation.
const CORE_SINGLETONS: Array[String] = [
	"PlayerWallet",
	"TimeOfDayClock",
	"WeatherController",
	"HeatManager",
]

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	init_test_scene()

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Full test-scene setup: core systems then minimal UI.
func init_test_scene() -> void:
	init_core_systems()
	init_minimal_ui()

## Verifies the core autoload singletons (wallet, time, weather, heat) exist.
func init_core_systems() -> void:
	var missing: int = 0
	for singleton_name in CORE_SINGLETONS:
		if get_node_or_null("/root/" + singleton_name) == null:
			push_error("[TestSceneBootstrap] Core singleton '%s' is missing. Register it as an autoload in project.godot." % singleton_name)
			missing += 1
	if missing == 0:
		print("[TestSceneBootstrap] Core systems initialized.")

## Creates a CanvasLayer with a cash counter (top-left) + health bar (bottom-left).
func init_minimal_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "TestUI_Canvas"
	add_child(layer)

	# Cash counter — top-left
	var cash := Label.new()
	cash.name = "CashCounter"
	cash.add_theme_font_size_override("font_size", 24)
	cash.add_theme_color_override("font_color", Color.GREEN)
	cash.position = Vector2(20, 20)
	layer.add_child(cash)
	_bind_cash(cash)

	# Health bar — bottom-left
	var bar := ProgressBar.new()
	bar.name = "HealthBar"
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.value = 1.0
	bar.show_percentage = false
	bar.anchor_top = 1.0
	bar.anchor_bottom = 1.0
	bar.offset_left = 20.0
	bar.offset_right = 220.0
	bar.offset_top = -40.0
	bar.offset_bottom = -20.0
	layer.add_child(bar)

	print("[TestSceneBootstrap] Minimal UI initialized.")

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

## Binds a Label to PlayerWallet so it shows the live cash balance.
func _bind_cash(label: Label) -> void:
	var wallet: Node = get_node_or_null("/root/PlayerWallet")
	if wallet == null:
		label.text = "$0"
		return

	var refresh := func(balance: float) -> void:
		if is_instance_valid(label):
			label.text = "$%d" % int(balance)

	refresh.call(wallet.get_balance())
	if not wallet.balance_changed.is_connected(refresh):
		wallet.balance_changed.connect(refresh)
