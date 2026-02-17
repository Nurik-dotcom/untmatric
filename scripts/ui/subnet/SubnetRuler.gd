extends Control
class_name SubnetRulerControl

var step: int = 64
var ip_last: int = 0
var network_last: int = -1
var applied: bool = false
var pulse_until_ms: int = 0

func _ready() -> void:
	set_process(false)
	queue_redraw()

func configure(new_step: int, new_ip_last: int) -> void:
	step = maxi(1, new_step)
	ip_last = clampi(new_ip_last, 0, 255)
	queue_redraw()

func set_result(new_network_last: int) -> void:
	network_last = clampi(new_network_last, 0, 255)
	applied = true
	queue_redraw()

func reset_state() -> void:
	network_last = -1
	applied = false
	pulse_until_ms = 0
	set_process(false)
	queue_redraw()

func pulse_marker(duration_ms: int = 1000) -> void:
	pulse_until_ms = Time.get_ticks_msec() + maxi(0, duration_ms)
	set_process(true)
	queue_redraw()

func current_segment_text() -> String:
	if not applied or network_last < 0:
		return "SEGMENT: --"
	var segment_end: int = mini(255, network_last + step - 1)
	return "SEGMENT: %d..%d | NET ID: %d" % [network_last, segment_end, network_last]

func _process(_delta: float) -> void:
	if pulse_until_ms <= Time.get_ticks_msec():
		set_process(false)
	queue_redraw()

func _draw() -> void:
	var bg_rect: Rect2 = Rect2(Vector2.ZERO, size)
	draw_rect(bg_rect, Color(0.06, 0.08, 0.07, 0.48), true)
	draw_rect(bg_rect, Color(0.24, 0.42, 0.32, 0.55), false, 2.0)

	if size.x < 80.0 or size.y < 60.0:
		return

	var left: float = 18.0
	var right: float = size.x - 18.0
	var axis_y: float = size.y * 0.5
	var axis_width: float = maxf(10.0, right - left)
	draw_line(Vector2(left, axis_y), Vector2(right, axis_y), Color(0.65, 0.85, 0.72, 0.95), 2.0)

	var grid_step: int = 32
	for value in range(0, 257, grid_step):
		var x_pos: float = _x_for_value(float(value), left, axis_width)
		draw_line(Vector2(x_pos, axis_y - 8.0), Vector2(x_pos, axis_y + 8.0), Color(0.4, 0.6, 0.5, 0.8), 1.0)
		if value % 64 == 0:
			_draw_text_centered(str(value), Vector2(x_pos, axis_y + 26.0), 64.0, 13, Color(0.7, 0.86, 0.74, 0.95))

	for boundary in range(0, 257, step):
		var boundary_x: float = _x_for_value(float(boundary), left, axis_width)
		draw_line(Vector2(boundary_x, axis_y - 18.0), Vector2(boundary_x, axis_y + 18.0), Color(0.92, 0.82, 0.42, 0.55), 1.5)

	if applied and network_last >= 0:
		var seg_start: float = _x_for_value(float(network_last), left, axis_width)
		var seg_end: int = mini(256, network_last + step)
		var seg_end_x: float = _x_for_value(float(seg_end), left, axis_width)
		var seg_rect: Rect2 = Rect2(Vector2(seg_start, axis_y - 16.0), Vector2(maxf(2.0, seg_end_x - seg_start), 32.0))
		draw_rect(seg_rect, Color(0.25, 0.55, 0.35, 0.42), true)
		draw_rect(seg_rect, Color(0.48, 0.92, 0.62, 0.8), false, 2.0)

	var marker_x: float = _x_for_value(float(ip_last), left, axis_width)
	var pulse_alpha: float = 0.0
	if pulse_until_ms > Time.get_ticks_msec():
		pulse_alpha = 0.2 + 0.2 * (0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.02))
	draw_line(Vector2(marker_x, axis_y - 24.0), Vector2(marker_x, axis_y + 24.0), Color(1.0, 0.85, 0.25, 0.95), 2.0)
	draw_circle(Vector2(marker_x, axis_y - 26.0), 5.0, Color(1.0, 0.85, 0.25, 1.0))
	if pulse_alpha > 0.0:
		draw_circle(Vector2(marker_x, axis_y - 26.0), 10.0, Color(1.0, 0.85, 0.25, pulse_alpha))

	_draw_text_centered("IP %d" % ip_last, Vector2(marker_x, axis_y - 34.0), 90.0, 13, Color(0.96, 0.92, 0.78, 1.0))
	_draw_text_centered(current_segment_text(), Vector2(size.x * 0.5, size.y - 10.0), size.x - 20.0, 15, Color(0.62, 0.95, 0.72, 1.0))

func _x_for_value(value: float, left: float, width_value: float) -> float:
	return left + (clampf(value, 0.0, 256.0) / 256.0) * width_value

func _draw_text_centered(text_value: String, center: Vector2, width_value: float, font_size: int, color: Color) -> void:
	var font: Font = get_theme_default_font()
	if font == null:
		return
	var draw_pos: Vector2 = Vector2(center.x - width_value * 0.5, center.y)
	draw_string(font, draw_pos, text_value, HORIZONTAL_ALIGNMENT_CENTER, width_value, font_size, color)
