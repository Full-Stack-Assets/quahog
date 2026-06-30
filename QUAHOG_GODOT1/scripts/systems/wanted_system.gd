extends Node
class_name WantedSystem





const POLICE_SCRIPT: = preload("res://scripts/police.gd")

var player: Node3D = null
var world: Node3D = null

var _cops: Array = []
var _spawn_timer: float = 0.0
var _decay_timer: float = 0.0
var _busted_cooldown: float = 0.0

const MAX_COPS: = 5
const SPAWN_DIST: = 42.0
const DECAY_TIME: = 13.0


func setup(p_player: Node3D, p_world: Node3D) -> void :
    player = p_player
    world = p_world


func get_cops() -> Array:
    return _cops


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


    var want_cops: int = min(level + 1, MAX_COPS)
    _spawn_timer -= delta
    if _cops.size() < want_cops and _spawn_timer <= 0.0:
        _spawn_timer = 1.6
        _spawn_cop()


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
    _busted_cooldown = 4.0
    var lost: int = int(GameManager.cash * 0.25) + 15
    GameManager.add_cash( - lost)
    GameManager.show_message("BUSTED! The cops took $%d." % lost)
    if AudioManager:
        var snd: = load("res://assets/audio/sfx/ui/ui_busted.mp3")
        if snd:
            AudioManager.play_sfx(snd, -2.0)
    GameManager.set_wanted(0)
    GameManager.set_faction(0)
    _clear_cops()

    if player and is_instance_valid(player) and player.has_method("on_busted"):
        player.on_busted()


func _clear_cops() -> void :
    for c in _cops:
        if is_instance_valid(c):
            c.queue_free()
    _cops.clear()
