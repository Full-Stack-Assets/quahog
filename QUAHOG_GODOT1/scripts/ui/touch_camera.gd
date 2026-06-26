extends Control



signal look_delta(delta: Vector2)

var _touch_index: int = -1
var _last_pos: Vector2 = Vector2.ZERO
var _active: bool = false

func _ready() -> void :
    mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event: InputEvent) -> void :
    if event is InputEventScreenTouch:
        if event.pressed and not _active:
            _active = true
            _touch_index = event.index
            _last_pos = event.position
        elif not event.pressed and event.index == _touch_index:
            _active = false
            _touch_index = -1
    elif event is InputEventScreenDrag and _active and event.index == _touch_index:
        var delta: Vector2 = event.position - _last_pos
        _last_pos = event.position
        look_delta.emit(Vector2( - delta.x, - delta.y))
