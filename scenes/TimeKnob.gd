extends Control

signal value_changed(value: float, delta: float)

@export var min_value: float = 0.0
@export var max_value: float = 30.0
@export var step: float = 0.1
@export var start_angle_deg: float = -225.0
@export var end_angle_deg: float = 45.0
@export var value: float = 0.0

var _dragging: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	value = _quantize(clampf(value, min_value, max_value))
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event
		if touch_event.pressed:
			_dragging = true
			_set_value_from_pos(touch_event.position)
		else:
			_dragging = false
	elif event is InputEventScreenDrag:
		if _dragging:
			var drag_event: InputEventScreenDrag = event
			_set_value_from_pos(drag_event.position)
	elif event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = mouse_event.pressed
			if mouse_event.pressed:
				_set_value_from_pos(mouse_event.position)
	elif event is InputEventMouseMotion and _dragging:
		var motion_event: InputEventMouseMotion = event
		_set_value_from_pos(motion_event.position)

func _draw() -> void:
	var center: Vector2 = size * 0.5
	var radius: float = minf(size.x, size.y) * 0.42
	if radius <= 2.0:
		return

	var base_color: Color = Color(0.15, 0.15, 0.15, 1.0)
	var active_color: Color = Color(0.2, 0.9, 0.4, 1.0)
	var pointer_color: Color = Color(0.95, 0.95, 0.95, 1.0)

	draw_circle(center, radius, base_color)
	draw_circle(center, radius * 0.82, Color(0.06, 0.06, 0.06, 1.0))

	var start_rad: float = deg_to_rad(start_angle_deg)
	var sweep_rad: float = _get_sweep_rad()
	var current_t: float = _value_to_t(value)

	draw_arc(center, radius * 0.95, start_rad, start_rad + sweep_rad, 64, Color(0.25, 0.25, 0.25, 1.0), 5.0, true)
	draw_arc(center, radius * 0.95, start_rad, start_rad + sweep_rad * current_t, 64, active_color, 6.0, true)

	var marker_angle: float = start_rad + sweep_rad * current_t
	var marker_dir: Vector2 = Vector2(cos(marker_angle), sin(marker_angle))
	var marker_pos: Vector2 = center + marker_dir * radius * 0.70
	draw_circle(marker_pos, radius * 0.10, pointer_color)

func set_knob_value(new_value: float, emit_change: bool = false) -> void:
	var normalized: float = _quantize(clampf(new_value, min_value, max_value))
	if is_equal_approx(normalized, value):
		return

	var delta: float = normalized - value
	value = normalized
	queue_redraw()
	if emit_change:
		value_changed.emit(value, delta)

func _set_value_from_pos(pos: Vector2) -> void:
	var center: Vector2 = size * 0.5
	var local: Vector2 = pos - center
	if local.length() < 4.0:
		return

	var angle: float = atan2(local.y, local.x)
	var t: float = _angle_to_t(angle)
	var new_value: float = min_value + (max_value - min_value) * t
	set_knob_value(new_value, true)

func _get_sweep_rad() -> float:
	var start_rad: float = deg_to_rad(start_angle_deg)
	var end_rad: float = deg_to_rad(end_angle_deg)
	var sweep: float = wrapf(end_rad - start_rad, 0.0, TAU)
	if sweep <= 0.0:
		sweep += TAU
	return sweep

func _angle_to_t(angle: float) -> float:
	var start_rad: float = deg_to_rad(start_angle_deg)
	var sweep: float = _get_sweep_rad()
	var rel: float = wrapf(angle - start_rad, 0.0, TAU)
	var t: float = rel / sweep
	return clampf(t, 0.0, 1.0)

func _value_to_t(current_value: float) -> float:
	if max_value <= min_value:
		return 0.0
	return clampf((current_value - min_value) / (max_value - min_value), 0.0, 1.0)

func _quantize(input_value: float) -> float:
	if step <= 0.0:
		return input_value
	var steps: float = round((input_value - min_value) / step)
	return min_value + steps * step
