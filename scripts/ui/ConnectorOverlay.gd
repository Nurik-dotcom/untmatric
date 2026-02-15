extends Control

var _from_control: Control
var _to_control: Control
var _anchor_root: Control

@export var line_color: Color = Color(0.88, 0.64, 0.16, 0.9)
@export var line_width: float = 3.0
@export var arrow_size: float = 10.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func set_endpoints(from_control: Control, to_control: Control, anchor_root: Control) -> void:
	_disconnect_signals()
	_from_control = from_control
	_to_control = to_control
	_anchor_root = anchor_root
	_connect_signal_safe(_from_control)
	_connect_signal_safe(_to_control)
	_connect_signal_safe(_anchor_root)
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_TRANSFORM_CHANGED or what == NOTIFICATION_VISIBILITY_CHANGED:
		queue_redraw()

func _draw() -> void:
	if not _can_draw_connector():
		return
	var from_rect: Rect2 = _from_control.get_global_rect()
	var to_rect: Rect2 = _to_control.get_global_rect()
	var from_point: Vector2 = _global_to_local(from_rect.get_center())
	var to_point: Vector2 = _global_to_local(to_rect.get_center())
	draw_line(from_point, to_point, line_color, line_width, true)
	_draw_arrow(from_point, to_point)

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

func _can_draw_connector() -> bool:
	return is_instance_valid(_from_control) and is_instance_valid(_to_control) and _from_control.visible and _to_control.visible

func _connect_signal_safe(node: Control) -> void:
	if not is_instance_valid(node):
		return
	if not node.resized.is_connected(_on_endpoint_changed):
		node.resized.connect(_on_endpoint_changed)
	if not node.visibility_changed.is_connected(_on_endpoint_changed):
		node.visibility_changed.connect(_on_endpoint_changed)

func _disconnect_signals() -> void:
	_disconnect_signal_safe(_from_control)
	_disconnect_signal_safe(_to_control)
	_disconnect_signal_safe(_anchor_root)

func _disconnect_signal_safe(node: Control) -> void:
	if not is_instance_valid(node):
		return
	if node.resized.is_connected(_on_endpoint_changed):
		node.resized.disconnect(_on_endpoint_changed)
	if node.visibility_changed.is_connected(_on_endpoint_changed):
		node.visibility_changed.disconnect(_on_endpoint_changed)

func _on_endpoint_changed() -> void:
	queue_redraw()
