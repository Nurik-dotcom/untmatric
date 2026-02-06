extends Control

signal value_changed(new_value: int)

@export var min_value: int = 1
@export var max_value: int = 12
@export var value: int = 1:
	set(v):
		value = clampi(v, min_value, max_value)
		queue_redraw()
@export var min_angle_deg: float = -135.0
@export var max_angle_deg: float = 135.0

var is_dragging: bool = false

func _ready():
	custom_minimum_size = Vector2(220, 220)
	mouse_filter = MOUSE_FILTER_STOP

func _gui_input(event):
	var is_active = false

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				is_active = true
			else:
				is_dragging = false

	elif event is InputEventScreenTouch:
		if event.pressed:
			is_dragging = true
			is_active = true
		else:
			is_dragging = false

	elif (event is InputEventMouseMotion or event is InputEventScreenDrag) and is_dragging:
		is_active = true

	if is_active:
		_process_input_pos(get_local_mouse_position())

func _process_input_pos(local_pos: Vector2):
	var center = size / 2.0
	var angle = (local_pos - center).angle() # Radians -PI to PI
	var deg = rad_to_deg(angle)

	# Rotate so -90 (up) is 0 for easier calc if needed,
	# but simple clamping to min/max angle range works better standardly.
	# Godot 0 is Right (3 o'clock). -90 is Up. 90 is Down.
	# Our range is typically -135 (South-West) to +135 (South-East) going clockwise via Top.
	# This crosses the -180/180 discontinuity if we go via bottom, but via top (-135 to -180... wait)
	# Let's map typical knob:
	# Min (-135 deg) -> 7-8 o'clock
	# Max (135 deg) -> 4-5 o'clock
	# 0 deg -> 3 o'clock. -90 -> 12 o'clock.
	# The range -135 to +135 is continuous if we treat it as -135...0...+135.
	# But input `angle` returns -180..180.
	# If input is 170 (bottom left), it's outside our range > 135.
	# If input is -170 (bottom left), it's < -135.
	# So simple clamp works for the top hemisphere.

	# Actually, usually knobs have 0 at -90 (Up) or -135 (Start).
	# Let's shift so MinAngle is 0.0 internal progress.

	# Let's just project to closest point in range.
	# Check if angle is in the "dead zone" at the bottom.
	# Dead zone is roughly 135 to 180 and -180 to -135.
	if deg > max_angle_deg and deg < 180:
		deg = max_angle_deg
	elif deg < min_angle_deg and deg > -180:
		deg = min_angle_deg
	elif deg >= 180 or deg <= -180:
		# Bottom center, snap to closest boundary
		if abs(deg - max_angle_deg) < abs(deg - min_angle_deg):
			deg = max_angle_deg
		else:
			deg = min_angle_deg

	# Map deg to value
	var t = (deg - min_angle_deg) / (max_angle_deg - min_angle_deg)
	t = clampf(t, 0.0, 1.0)

	var new_val = roundi(lerp(float(min_value), float(max_value), t))

	if new_val != value:
		value = new_val
		value_changed.emit(value)
		queue_redraw()

func _draw():
	var center = size / 2.0
	var radius = min(size.x, size.y) / 2.0 - 10.0

	# 1. Base/Glow
	draw_circle(center, radius, Color(0.1, 0.1, 0.1, 1.0))
	draw_circle(center, radius * 0.95, Color(0.2, 0.2, 0.2, 1.0))

	# Glow effect (faint rings)
	draw_arc(center, radius * 0.8, 0, TAU, 32, Color(0.2, 1.0, 0.2, 0.05), 4.0)
	draw_arc(center, radius * 0.6, 0, TAU, 32, Color(0.2, 1.0, 0.2, 0.05), 4.0)

	# 2. Ticks
	var total_steps = max_value - min_value
	for i in range(total_steps + 1):
		var t = float(i) / total_steps
		var angle_rad = deg_to_rad(lerp(min_angle_deg, max_angle_deg, t))
		var dir = Vector2.from_angle(angle_rad)
		var p1 = center + dir * (radius - 15)
		var p2 = center + dir * (radius - 5)

		# Highlight active tick
		var val_i = min_value + i
		var color = Color(0.4, 0.4, 0.4)
		var width = 2.0

		if val_i <= value:
			color = Color(0.2, 1.0, 0.2) # Active range
		if val_i == value:
			color = Color(1.0, 1.0, 1.0) # Current value tick
			width = 3.0

		draw_line(p1, p2, color, width, true)

	# 3. Indicator (Needle)
	var t_curr = float(value - min_value) / total_steps
	var angle_curr = deg_to_rad(lerp(min_angle_deg, max_angle_deg, t_curr))
	var dir_curr = Vector2.from_angle(angle_curr)

	draw_line(center, center + dir_curr * (radius - 20), Color(1, 1, 1), 4.0, true)
	draw_circle(center, 8.0, Color(0.8, 0.8, 0.8)) # Pivot cap
