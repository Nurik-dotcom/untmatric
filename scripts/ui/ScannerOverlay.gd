extends Control

@export var cursor_color: Color = Color(0.35, 0.95, 0.75, 0.8)
@export var highlight_color: Color = Color(1.0, 0.85, 0.28, 0.22)
@export var border_color: Color = Color(1.0, 0.9, 0.4, 0.85)
@export var cursor_radius: float = 18.0

var _cursor_visible := false
var _cursor_pos := Vector2.ZERO
var _highlight_visible := false
var _highlight_rect := Rect2()
var _pulse_visible := false
var _pulse_pos := Vector2.ZERO
var _pulse_t := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	if _pulse_visible:
		_pulse_t += delta
		if _pulse_t > 0.42:
			_pulse_visible = false
		queue_redraw()

func set_cursor(pos: Vector2) -> void:
	_cursor_visible = true
	_cursor_pos = pos
	queue_redraw()

func clear_cursor() -> void:
	_cursor_visible = false
	queue_redraw()

func set_highlight_rect(rect: Rect2) -> void:
	_highlight_visible = true
	_highlight_rect = rect
	queue_redraw()

func clear_highlight() -> void:
	_highlight_visible = false
	queue_redraw()

func pulse(pos: Vector2) -> void:
	_pulse_visible = true
	_pulse_pos = pos
	_pulse_t = 0.0
	queue_redraw()

func _draw() -> void:
	if _highlight_visible:
		draw_rect(_highlight_rect, highlight_color, true)
		draw_rect(_highlight_rect, border_color, false, 1.5)
	if _cursor_visible:
		draw_arc(_cursor_pos, cursor_radius, 0.0, TAU, 32, cursor_color, 1.8, true)
		draw_line(_cursor_pos + Vector2(-6, 0), _cursor_pos + Vector2(6, 0), cursor_color, 1.0, true)
		draw_line(_cursor_pos + Vector2(0, -6), _cursor_pos + Vector2(0, 6), cursor_color, 1.0, true)
	if _pulse_visible:
		var p := clampf(_pulse_t / 0.42, 0.0, 1.0)
		var radius := lerpf(10.0, 48.0, p)
		var alpha := lerpf(0.8, 0.0, p)
		draw_arc(_pulse_pos, radius, 0.0, TAU, 40, Color(border_color.r, border_color.g, border_color.b, alpha), 2.0, true)
