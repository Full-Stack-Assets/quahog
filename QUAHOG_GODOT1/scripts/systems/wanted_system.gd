extends Node
class_name WantedSystem





const POLICE_SCRIPT: = preload("res://scripts/police.gd")
const ENFORCER_SCRIPT: = preload("res://scripts/faction_enforcer.gd")

var player: Node3D = null
var world: Node3D = null

var _cops: Array = []
var _enforcers: Array = []
var _spawn_timer: float = 0.0
var _enforcer_spawn_timer: float = 0.0
var _decay_timer: float = 0.0
var _busted_cooldown: float = 0.0

const MAX_COPS: = 5
const MAX_ENFORCERS: = 3
const SPAWN_DIST: = 42.0
const DECAY_TIME: = 13.0


func setup(p_player: Node3D, p_world: Node3D) -> void :
    player = p_player
    world = p_world


func get_cops() -> Array:
    return _cops


func get_enforcers() -> Array:
    return _enforcers


func clear_pursuit() -> void :
    _clear_cops()
    _clear_enforcers()
    _busted_cooldown = 2.0


func add_heat(stars: int) -> void :
    # Cheat: suppress all police heat while testing.
    if GameManager and GameManager.cheat_no_police:
        return
    if _busted_cooldown > 0.0:
        return
    GameManager.set_wanted(GameManager.wanted_level + stars)
    _decay_timer = DECAY_TIME * 1.5
    if GameManager.wanted_level == 1 and stars > 0:
        GameManager.show_message("You've drawn police attention!")


func add_faction_heat(stars: int) -> void :
    if GameManager == null:
        return
    if _busted_cooldown > 0.0:
        return
    var was: int = GameManager.faction_level
    GameManager.set_faction(GameManager.faction_level + stars)
    _decay_timer = DECAY_TIME * 1.5
    if was == 0 and GameManager.faction_level >= 1:
        GameManager.show_message("The streets noticed that.")


func on_cop_killed() -> void :
    add_heat(1)


func on_player_caught() -> void :
    if _busted_cooldown > 0.0:
        return
    _busted()


func _process(delta: float) -> void :
    _busted_cooldown = max(0.0, _busted_cooldown - delta)

    for i in range(_cops.size() - 1, -1, -1):
        if not is_instance_valid(_cops[i]):
            _cops.remove_at(i)

    var level: int = GameManager.wanted_level
    var faction: int = GameManager.faction_level
    if level <= 0 and faction <= 0:
        if not _cops.is_empty():
            _clear_cops()
        return

    if level <= 0 and not _cops.is_empty():
        _clear_cops()

    _decay_timer -= delta
    if _decay_timer <= 0.0:
        _decay_timer = DECAY_TIME
        level = GameManager.wanted_level
        faction = GameManager.faction_level
        if level > 0:
            GameManager.set_wanted(level - 1)
            if GameManager.wanted_level == 0 and GameManager.faction_level == 0:
                GameManager.show_message("You lost the heat.")
            elif GameManager.wanted_level == 0:
                GameManager.show_message("You lost the cops.")
        if faction > 0:
            GameManager.set_faction(faction - 1)
            if GameManager.faction_level == 0 and GameManager.wanted_level > 0:
                GameManager.show_message("The crews backed off.")

    if GameManager.wanted_level <= 0:
        return


    if GameManager.wanted_level <= 0:
        return

    var want_cops: int = min(level + 1, MAX_COPS)
    _spawn_timer -= delta
    if _cops.size() < want_cops and _spawn_timer <= 0.0:
        _spawn_timer = 1.6
        _spawn_cop()

    _update_enforcers(delta)


func _update_enforcers(delta: float) -> void :
    for i in range(_enforcers.size() - 1, -1, -1):
        if not is_instance_valid(_enforcers[i]):
            _enforcers.remove_at(i)

    var faction: int = GameManager.faction_level
    if faction <= 0:
        if not _enforcers.is_empty():
            _clear_enforcers()
        return

    var want: int = mini(faction + 1, MAX_ENFORCERS)
    _enforcer_spawn_timer -= delta
    if _enforcers.size() < want and _enforcer_spawn_timer <= 0.0 and player != null:
        _enforcer_spawn_timer = 2.4
        _spawn_enforcer()


func _spawn_enforcer() -> void :
    if world == null or player == null:
        return
    var ang: float = randf() * TAU
    var offset: = Vector3(cos(ang), 0, sin(ang)) * (SPAWN_DIST * 0.85)
    var pos: Vector3 = player.global_position + offset
    pos.y = 0.4
    var goon: = CharacterBody3D.new()
    goon.set_script(ENFORCER_SCRIPT)
    goon.setup(player, self)
    world.add_child(goon)
    goon.global_position = pos
    _enforcers.append(goon)


func _spawn_cop() -> void :
    if world == null or player == null:
        return
    var ang: float = randf() * TAU
    var offset: = Vector3(cos(ang), 0, sin(ang)) * SPAWN_DIST
    var pos: Vector3 = player.global_position + offset
    pos.y = 0.4
    var cop: = CharacterBody3D.new()
    cop.set_script(POLICE_SCRIPT)
    cop.setup(player, self)
    world.add_child(cop)
    cop.global_position = pos
    _cops.append(cop)


func _busted() -> void :
    if ConsequenceManager and ConsequenceManager.is_active():
        return
    _busted_cooldown = 4.0
    _clear_cops()
    if ConsequenceManager and ConsequenceManager.has_method("start"):
        ConsequenceManager.start("busted")
        return
    # Fallback if autoload missing.
    GameManager.set_wanted(0)
    GameManager.set_faction(0)
    if player and is_instance_valid(player) and player.has_method("on_busted"):
        player.on_busted()


func _clear_enforcers() -> void :
    for e in _enforcers:
        if is_instance_valid(e):
            e.queue_free()
    _enforcers.clear()


func _clear_cops() -> void :
    for c in _cops:
        if is_instance_valid(c):
            c.queue_free()
    _cops.clear()
