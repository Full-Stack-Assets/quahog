# AudioBarkManager.gd
# res://scripts/systems/audio/AudioBarkManager.gd
extends Node

# ---------------------------------------------------------------------------
# Bark type enum
# ---------------------------------------------------------------------------
enum BarkType {
	IDLE,
	REACT_PLAYER,
	REACT_CRIME,
	REACT_FIGHT,
	DISTRICT_FLAVOR
}

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------
## Array of BarkProfile resources.  Each BarkProfile (custom Resource) should
## expose:
##   @export var district: String
##   @export var bark_type: int            (BarkType value)
##   @export var audio_clips: Array[AudioStream]
@export var bark_profiles: Array[Resource] = []
@export var bark_cooldown: float = 3.0

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var _cooldown_timer: float = 0.0

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _process(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Play a contextual bark on `npc_node`.  The NPC must have an
## AudioStreamPlayer3D child (or one will be created) and a district String.
func play_bark(npc_node: Node3D, bark_type: int, district: String) -> void:
	if _cooldown_timer > 0.0:
		return

	var clip: AudioStream = _pick_clip(bark_type, district)
	if clip == null:
		return

	var player: AudioStreamPlayer3D = _get_or_create_player(npc_node)
	if player == null:
		push_warning("AudioBarkManager: could not get AudioStreamPlayer3D on %s" % npc_node.name)
		return

	player.stream = clip
	player.play()

	_cooldown_timer = bark_cooldown

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

## Find the best-matching BarkProfile and return a random clip from it.
func _pick_clip(bark_type: int, district: String) -> AudioStream:
	# Collect matching profiles (same bark_type + district, or same bark_type with empty district)
	var matches: Array[Resource] = []
	for profile in bark_profiles:
		if not profile.has_method("get") and not ("bark_type" in profile):
			continue
		var pt: int = profile.get("bark_type") if "bark_type" in profile else -1
		var pd: String = profile.get("district") if "district" in profile else ""
		if pt != bark_type:
			continue
		if pd == district or pd == "":
			matches.append(profile)

	# Prefer district-specific matches
	var district_matches: Array[Resource] = []
	for p in matches:
		var pd: String = p.get("district") if "district" in p else ""
		if pd == district:
			district_matches.append(p)

	var chosen_profile: Resource = null
	if district_matches.size() > 0:
		chosen_profile = district_matches[randi() % district_matches.size()]
	elif matches.size() > 0:
		chosen_profile = matches[randi() % matches.size()]
	else:
		return null

	var clips: Array = chosen_profile.get("audio_clips") if "audio_clips" in chosen_profile else []
	if clips.size() == 0:
		return null

	return clips[randi() % clips.size()] as AudioStream

## Return the existing AudioStreamPlayer3D child, or create one.
func _get_or_create_player(npc_node: Node3D) -> AudioStreamPlayer3D:
	for child in npc_node.get_children():
		if child is AudioStreamPlayer3D:
			return child
	var player := AudioStreamPlayer3D.new()
	player.name = "BarkPlayer"
	player.bus = "Voice"
	player.unit_size = 10.0
	npc_node.add_child(player)
	return player
