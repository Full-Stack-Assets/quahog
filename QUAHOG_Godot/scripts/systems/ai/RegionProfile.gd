# RegionProfile.gd
# res://scripts/systems/ai/RegionProfile.gd
# Custom Resource — create via FileSystem > right-click > New Resource > RegionProfile
extends Resource
class_name RegionProfile

@export var region_name: String = ""
@export var pedestrian_density: float = 1.0
@export var vehicle_density: float = 1.0
@export var npc_types: Array[String] = []
@export var ambient_audio_bus: String = ""
