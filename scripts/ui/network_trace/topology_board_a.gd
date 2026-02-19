extends Control
class_name NetworkTraceTopologyBoardA

signal device_installed(device_id: String, label_text: String, error_code: String)
signal device_removed
signal trace_animation_finished(success: bool)

const SLOT_NODE_NAME := "?"

var node_names: Array[String] = []
var edge_pairs: Array = []
var node_labels: Dictionary = {}
var node_positions: Dictionary = {}

var slot_size: Vector2 = Vector2(170.0, 90.0)
var tools_locked: bool = true

var installed_device_id: String = ""
var installed_device_label: String = ""
var installed_error_code: String = ""

var packet_visible: bool = false
var packet_progress: float = 0.0
var packet_path: Array[Vector2] = []
var trace_success: bool = true
var trace_tween: Tween = null

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	_recalculate_layout()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_recalculate_layout()
		queue_redraw()

func setup_topology(data: Dictionary) -> void:
	node_names.clear()
	edge_pairs.clear()
	node_labels.clear()
	node_positions.clear()

	var nodes_variant: Variant = data.get("nodes", [])
	if typeof(nodes_variant) == TYPE_ARRAY:
		var nodes_array: Array = nodes_variant
		for node_var in nodes_array:
			node_names.append(str(node_var))

	var edges_variant: Variant = data.get("edges", [])
	if typeof(edges_variant) == TYPE_ARRAY:
		var edges_array: Array = edges_variant
		for edge_var in edges_array:
			if typeof(edge_var) != TYPE_ARRAY:
				continue
			var edge_array: Array = edge_var
			if edge_array.size() < 2:
				continue
			edge_pairs.append([str(edge_array[0]), str(edge_array[1])])

	var labels_variant: Variant = data.get("labels", {})
	if typeof(labels_variant) == TYPE_DICTIONARY:
		node_labels = (labels_variant as Dictionary).duplicate(true)

	if node_names.is_empty():
		node_names = ["SRC", SLOT_NODE_NAME, "DST"]
		edge_pairs = [["SRC", SLOT_NODE_NAME], [SLOT_NODE_NAME, "DST"]]

	_recalculate_layout()
	clear_installed_device()
	queue_redraw()

func set_tools_locked(locked: bool) -> void:
	tools_locked = locked

func has_device_installed() -> bool:
	return not installed_device_id.is_empty()

func get_installed_device_id() -> String:
	return installed_device_id

func get_installed_error_code() -> String:
	return installed_error_code

func clear_installed_device() -> void:
	var had_device: bool = has_device_installed()
	installed_device_id = ""
	installed_device_label = ""
	installed_error_code = ""
	packet_visible = false
	packet_progress = 0.0
	queue_redraw()
	if had_device:
		device_removed.emit()

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if tools_locked:
		return false
	if typeof(data) != TYPE_DICTIONARY:
		return false
	var drag_data: Dictionary = data
	if str(drag_data.get("type", "")) != "network_trace_device":
		return false
	return _slot_rect().grow(12.0).has_point(at_position)

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if typeof(data) != TYPE_DICTIONARY:
		return
	var drag_data: Dictionary = data
	installed_device_id = str(drag_data.get("device_id", ""))
	installed_device_label = str(drag_data.get("label", ""))
	installed_error_code = str(drag_data.get("error_code", ""))
	queue_redraw()
	device_installed.emit(installed_device_id, installed_device_label, installed_error_code)

func play_trace_animation(success: bool) -> void:
	if trace_tween != null:
		trace_tween.kill()

	if packet_path.size() < 2:
		trace_animation_finished.emit(success)
		return

	trace_success = success
	packet_visible = true
	packet_progress = 0.0
	queue_redraw()

	var end_progress: float = 1.0 if success else 0.52
	trace_tween = create_tween()
	trace_tween.tween_method(Callable(self, "_set_packet_progress"), 0.0, end_progress, 1.15)
	await trace_tween.finished

	if not success:
		await get_tree().create_timer(0.15).timeout

	packet_visible = false
	packet_progress = 0.0
	queue_redraw()
	trace_animation_finished.emit(success)

func _set_packet_progress(value: float) -> void:
	packet_progress = clampf(value, 0.0, 1.0)
	queue_redraw()

func _recalculate_layout() -> void:
	node_positions.clear()
	if node_names.is_empty():
		packet_path.clear()
		return

	var count: int = node_names.size()
	var width_available: float = maxf(120.0, size.x - 64.0)
	var x_start: float = (size.x - width_available) * 0.5
	var y_line: float = size.y * 0.44

	if count == 1:
		node_positions[node_names[0]] = Vector2(size.x * 0.5, y_line)
	else:
		var step: float = width_available / float(count - 1)
		for idx in range(count):
			var node_name: String = node_names[idx]
			var pos: Vector2 = Vector2(x_start + float(idx) * step, y_line)
			node_positions[node_name] = pos

	_build_packet_path()

func _build_packet_path() -> void:
	packet_path.clear()
	if node_names.size() < 2:
		return

	var start_name: String = node_names[0]
	var end_name: String = node_names[node_names.size() - 1]
	var slot_center: Vector2 = _slot_center()

	var start_pos: Vector2 = node_positions.get(start_name, Vector2(size.x * 0.15, size.y * 0.45))
	var end_pos: Vector2 = node_positions.get(end_name, Vector2(size.x * 0.85, size.y * 0.45))

	packet_path.append(start_pos)
	if slot_center.distance_to(start_pos) > 1.0 and slot_center.distance_to(end_pos) > 1.0:
		packet_path.append(slot_center)
	packet_path.append(end_pos)

func _slot_center() -> Vector2:
	if node_positions.has(SLOT_NODE_NAME):
		return node_positions[SLOT_NODE_NAME]
	return Vector2(size.x * 0.5, size.y * 0.44)

func _slot_rect() -> Rect2:
	var center: Vector2 = _slot_center()
	return Rect2(center - slot_size * 0.5, slot_size)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.06, 0.09, 0.08, 0.35), true)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.2, 0.45, 0.3, 0.45), false, 2.0)

	for edge_var in edge_pairs:
		if typeof(edge_var) != TYPE_ARRAY:
			continue
		var edge: Array = edge_var
		if edge.size() < 2:
			continue
		var from_name: String = str(edge[0])
		var to_name: String = str(edge[1])
		if not node_positions.has(from_name) or not node_positions.has(to_name):
			continue
		var from_pos: Vector2 = node_positions[from_name]
		var to_pos: Vector2 = node_positions[to_name]
		draw_line(from_pos, to_pos, Color(0.35, 0.7, 0.55, 0.9), 3.0)

	for node_name_var in node_names:
		var node_name: String = str(node_name_var)
		if not node_positions.has(node_name):
			continue
		var node_pos: Vector2 = node_positions[node_name]
		if node_name == SLOT_NODE_NAME:
			continue
		draw_circle(node_pos, 16.0, Color(0.12, 0.25, 0.2, 1.0))
		draw_arc(node_pos, 16.0, 0.0, TAU, 24, Color(0.3, 0.85, 0.6, 0.75), 2.0)
		_draw_centered_text(node_name, node_pos + Vector2(0.0, 36.0), 160.0, Color(0.83, 0.98, 0.9, 1.0), 15)
		if node_labels.has(node_name):
			_draw_centered_text(str(node_labels[node_name]), node_pos + Vector2(0.0, 54.0), 220.0, Color(0.65, 0.75, 0.7, 1.0), 13)

	var slot_rect: Rect2 = _slot_rect()
	draw_rect(slot_rect, Color(0.08, 0.12, 0.1, 0.95), true)
	draw_rect(slot_rect, Color(0.95, 0.75, 0.25, 0.9), false, 3.0)
	if tools_locked:
		_draw_centered_text("ЗАБЛОКИРОВАНО", slot_rect.get_center() + Vector2(0.0, 6.0), slot_rect.size.x - 8.0, Color(0.95, 0.45, 0.4, 1.0), 18)
	elif installed_device_id.is_empty():
		_draw_centered_text("ПОМЕСТИТЕ УСТРОЙСТВО", slot_rect.get_center() + Vector2(0.0, 6.0), slot_rect.size.x - 8.0, Color(0.95, 0.95, 0.8, 1.0), 18)
	else:
		_draw_centered_text(installed_device_label, slot_rect.get_center() + Vector2(0.0, 0.0), slot_rect.size.x - 8.0, Color(0.75, 1.0, 0.82, 1.0), 18)

	if packet_visible and packet_path.size() >= 2:
		var packet_pos: Vector2 = _point_on_path(packet_progress)
		var packet_color: Color = Color(0.4, 1.0, 0.45, 1.0) if trace_success else Color(1.0, 0.35, 0.35, 1.0)
		draw_circle(packet_pos, 9.0, packet_color)
		draw_arc(packet_pos, 12.0, 0.0, TAU, 20, Color(packet_color.r, packet_color.g, packet_color.b, 0.35), 2.0)

func _point_on_path(progress: float) -> Vector2:
	if packet_path.is_empty():
		return Vector2.ZERO
	if packet_path.size() == 1:
		return packet_path[0]

	var distances: Array[float] = []
	var total_length: float = 0.0
	for idx in range(packet_path.size() - 1):
		var segment_length: float = packet_path[idx].distance_to(packet_path[idx + 1])
		distances.append(segment_length)
		total_length += segment_length

	if total_length <= 0.001:
		return packet_path[packet_path.size() - 1]

	var target_distance: float = clampf(progress, 0.0, 1.0) * total_length
	var accumulated: float = 0.0
	for idx in range(distances.size()):
		var segment_length: float = distances[idx]
		if accumulated + segment_length >= target_distance:
			var local_t: float = 0.0
			if segment_length > 0.001:
				local_t = (target_distance - accumulated) / segment_length
			return packet_path[idx].lerp(packet_path[idx + 1], local_t)
		accumulated += segment_length

	return packet_path[packet_path.size() - 1]

func _draw_centered_text(text_value: String, center: Vector2, width: float, color: Color, font_size: int) -> void:
	var font: Font = get_theme_default_font()
	if font == null:
		return
	var draw_pos: Vector2 = Vector2(center.x - width * 0.5, center.y)
	draw_string(font, draw_pos, text_value, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, color)
