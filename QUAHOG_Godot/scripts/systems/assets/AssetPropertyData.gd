# AssetPropertyData.gd
# Resource holding static data for a purchasable property in the QUAHOG empire system.
# Attach as a .tres resource to an AssetProperty node via @export.
extends Resource

class_name AssetPropertyData

@export var property_id: String = ""
@export var display_name: String = ""
@export var district: String = ""
@export var purchase_price: float = 0.0
@export var daily_yield: float = 0.0
@export var is_owned: bool = false
@export var day_acquired: int = 0
@export var linked_mission_id: String = ""
