## ServiceLocator.gd
## Lightweight static service-locator for Project QUAHOG.
## Provides a runtime registry of named service objects so systems can
## reach each other without hard-coded node paths or circular autoload deps.
##
## Ported from ServiceLocator.cs (Unity) to Godot 4 GDScript.
##
## Usage:
##   # Register (typically in _ready() of a manager node):
##   ServiceLocator.register("PlayerController", $PlayerController)
##
##   # Retrieve anywhere:
##   var pc = ServiceLocator.get_service("PlayerController")
##   if pc:
##       pc.do_something()
##
##   # Check before retrieving in hot paths:
##   if ServiceLocator.has_service("HeatManager"):
##       ServiceLocator.get_service("HeatManager").add_heat(10)
class_name ServiceLocator

# ---------------------------------------------------------------------------
# Internal registry  (static — shared across all instances / callers)
# ---------------------------------------------------------------------------
static var _registry: Dictionary = {}

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Registers service under key.  Overwrites any existing entry and warns.
static func register(key: String, service: Object) -> void:
	if _registry.has(key):
		push_warning("[ServiceLocator] Overwriting existing service '%s'." % key)
	_registry[key] = service
	print("[ServiceLocator] Registered: '%s' (%s)" % [key, service.get_class()])


## Returns the service registered under key, or null if not found.
static func get_service(key: String) -> Object:
	if not _registry.has(key):
		push_warning("[ServiceLocator] Service not found: '%s'." % key)
		return null
	var svc: Object = _registry[key]
	# Guard against stale references (e.g. after scene reload)
	if not is_instance_valid(svc):
		push_warning("[ServiceLocator] Service '%s' is no longer valid — removing." % key)
		_registry.erase(key)
		return null
	return svc


## Returns true if a valid service is registered under key.
static func has_service(key: String) -> bool:
	if not _registry.has(key):
		return false
	var svc: Object = _registry[key]
	if not is_instance_valid(svc):
		_registry.erase(key)
		return false
	return true


## Removes the service registered under key (if any).
static func unregister(key: String) -> void:
	if _registry.has(key):
		_registry.erase(key)
		print("[ServiceLocator] Unregistered: '%s'" % key)
	else:
		push_warning("[ServiceLocator] unregister() called for unknown key '%s'." % key)


## Clears the entire registry.  Use on scene transitions if needed.
static func clear() -> void:
	var count: int = _registry.size()
	_registry.clear()
	print("[ServiceLocator] Registry cleared (%d entries removed)." % count)


## Returns a snapshot of all currently registered keys (for debugging).
static func get_registered_keys() -> Array:
	return _registry.keys()


## Debug dump — prints all registered services and their class names.
static func debug_print() -> void:
	print("[ServiceLocator] === Registry dump (%d entries) ===" % _registry.size())
	for key in _registry.keys():
		var svc: Object = _registry[key]
		var class_info: String = svc.get_class() if is_instance_valid(svc) else "<INVALID>"
		print("  %-30s → %s" % [key, class_info])
	print("[ServiceLocator] ===================================")
