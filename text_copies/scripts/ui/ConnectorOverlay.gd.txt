extends Control

const ANCHOR_CENTER := "center"
const ANCHOR_EDGE := "edge"
const ORIENTATION_AUTO := "auto"
const ORIENTATION_HORIZONTAL := "horizontal"
const ORIENTATION_VERTICAL := "vertical"

var _links: Array = []
var _anchor_root: Control
var _watched_controls: Array = []
var _anchor_mode: String = ANCHOR_CENTER
var _orientation: String = ORIENTATION_AUTO

@export var line_color: Color = Color(0.88, 0.64, 0.16, 0.9)
@export var line_width: float = 3.0
@export var arrow_size: float = 10.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func set_anchor_mode(anchor_mode: String, orientation: String = ORIENTATION_AUTO) -> void:
	_anchor_mode = anchor_mode.to_lower()
	_orientation = orientation.to_lower()
	queue_redraw()

func set_endpoints(from_control: Control, to_control: Control, anchor_root: Control) -> void:
	set_links([{"from": from_control, "to": to_control}], anchor_root, _anchor_mode, _orientation)

func set_links(links: Array, anchor_root: Control, anchor_mode: String = ANCHOR_CENTER, orientation: String = ORIENTATION_AUTO) -> void:
	_disconnect_signals()
	_links.clear()
	_anchor_root = anchor_root
	_anchor_mode = anchor_mode.to_lower()
	_orientation = orientation.to_lower()
	for link_v in links:
		if typeof(link_v) != TYPE_DICTIONARY:
			continue
		var link: Dictionary = link_v as Dictionary
		var from_control: Control = link.get("from", null) as Control
		var to_control: Control = link.get("to", null) as Control
		if is_instance_valid(from_control) and is_instance_valid(to_control):
			_links.append({"from": from_control, "to": to_control})
			_connect_signal_safe(from_control)
			_connect_signal_safe(to_control)
	if is_instance_valid(_anchor_root):
		_connect_signal_safe(_anchor_root)
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_TRANSFORM_CHANGED or what == NOTIFICATION_VISIBILITY_CHANGED:
		queue_redraw()

func _draw() -> void:
	for link_v in _links:
		if typeof(link_v) != TYPE_DICTIONARY:
			continue
		var link: Dictionary = link_v as Dictionary
		var from_control: Control = link.get("from", null) as Control
		var to_control: Control = link.get("to", null) as Control
		if not _can_draw_connector(from_control, to_control):
			continue
		var points: Dictionary = _resolve_points(from_control.get_global_rect(), to_control.get_global_rect())
		var from_global: Vector2 = points.get("from", Vector2.ZERO)
		var to_global: Vector2 = points.get("to", Vector2.ZERO)
		var from_point: Vector2 = _global_to_local(from_global)
		var to_point: Vector2 = _global_to_local(to_global)
		draw_line(from_point, to_point, line_color, line_width, true)
		_draw_arrow(from_point, to_point)

func _resolve_points(from_rect: Rect2, to_rect: Rect2) -> Dictionary:
	if _anchor_mode != ANCHOR_EDGE:
		return {
			"from": from_rect.get_center(),
			"to": to_rect.get_center()
		}
	var orientation: String = _resolved_orientation(from_rect, to_rect)
	if orientation == ORIENTATION_VERTICAL:
		return {
			"from": Vector2(from_rect.get_center().x, from_rect.end.y),
			"to": Vector2(to_rect.get_center().x, to_rect.position.y)
		}
	return {
		"from": Vector2(from_rect.end.x, from_rect.get_center().y),
		"to": Vector2(to_rect.position.x, to_rect.get_center().y)
	}

func _resolved_orientation(from_rect: Rect2, to_rect: Rect2) -> String:
	if _orientation == ORIENTATION_HORIZONTAL or _orientation == ORIENTATION_VERTICAL:
		return _orientation
	var delta: Vector2 = to_rect.get_center() - from_rect.get_center()
	return ORIENTATION_HORIZONTAL if absf(delta.x) >= absf(delta.y) else ORIENTATION_VERTICAL

func _draw_arrow(from_point: Vector2, to_point: Vector2) -> void:
	var direction: Vector2 = (to_point - from_point).normalized()
	if direction.length() <= 0.0:
		return
	var normal: Vector2 = Vector2(-direction.y, direction.x)
	var tip: Vector2 = to_point
	var base: Vector2 = tip - direction * arrow_size
	var left: Vector2 = base + normal * (arrow_size * 0.45)
	var right: Vector2 = base - normal * (arrow_size * 0.45)
	draw_line(tip, left, line_color, line_width, true)
	draw_line(tip, right, line_color, line_width, true)

func _global_to_local(point: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * point

func _can_draw_connector(from_control: Control, to_control: Control) -> bool:
	return is_instance_valid(from_control) and is_instance_valid(to_control) and from_control.visible and to_control.visible

func _connect_signal_safe(node: Control) -> void:
	if not is_instance_valid(node):
		return
	if not _watched_controls.has(node):
		_watched_controls.append(node)
	if not node.resized.is_connected(_on_endpoint_changed):
		node.resized.connect(_on_endpoint_changed)
	if not node.visibility_changed.is_connected(_on_endpoint_changed):
		node.visibility_changed.connect(_on_endpoint_changed)

func _disconnect_signals() -> void:
	for node_v in _watched_controls:
		var node: Control = node_v as Control
		_disconnect_signal_safe(node)
	_watched_controls.clear()

func _disconnect_signal_safe(node: Control) -> void:
	if not is_instance_valid(node):
		return
	if node.resized.is_connected(_on_endpoint_changed):
		node.resized.disconnect(_on_endpoint_changed)
	if node.visibility_changed.is_connected(_on_endpoint_changed):
		node.visibility_changed.disconnect(_on_endpoint_changed)

func _on_endpoint_changed() -> void:
	queue_redraw()
