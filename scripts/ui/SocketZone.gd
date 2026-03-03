extends PanelContainer

signal hint_requested(item_id: String, socket_id: String)
signal hint_hover(item_id: String, socket_id: String)
signal drop_accepted(item_id: String, socket_id: String)
signal drop_rejected(item_id: String, socket_id: String)

@export var socket_id: String = ""
@export var title_path: NodePath = NodePath("VBox/BucketTitle")
@export var items_container_path: NodePath = NodePath("VBox/ItemsFlow")
@export var glow_path: NodePath = NodePath("GlowRect")
@export var accept_ids: Array[String] = []

var occupied_ids: Array[String] = []
var _drag_item_id: String = ""
var _hover_accepts: bool = false
var _feedback_mode: String = "neutral"
var _base_glow_color: Color = Color(0.6, 0.6, 0.6, 0.18)

@onready var _title_label: Label = get_node_or_null(title_path) as Label
@onready var _items_container: Control = get_node_or_null(items_container_path) as Control
@onready var _glow_rect: ColorRect = get_node_or_null(glow_path) as ColorRect

func _ready() -> void:
	if is_instance_valid(_glow_rect):
		_base_glow_color = _glow_rect.color
		_glow_rect.visible = false

	mouse_exited.connect(func() -> void:
		_drag_item_id = ""
		_hover_accepts = false
		_apply_visual_state()
	)

func setup(p_socket_id: String, p_label_text: String, p_accept_ids: Array[String] = []) -> void:
	socket_id = p_socket_id.to_upper()
	accept_ids = p_accept_ids.duplicate()
	if is_instance_valid(_title_label):
		_title_label.text = p_label_text
	set_feedback_mode("neutral")

func set_accept_ids(ids: Array[String]) -> void:
	accept_ids = ids.duplicate()

func set_feedback_mode(mode: String) -> void:
	_feedback_mode = mode
	_apply_visual_state()

func flash_reject() -> void:
	set_feedback_mode("rejected")
	var tween: Tween = create_tween()
	tween.tween_interval(0.18)
	tween.tween_callback(func() -> void:
		if _feedback_mode == "rejected":
			set_feedback_mode("neutral")
	)

func clear_items() -> void:
	occupied_ids.clear()
	if not is_instance_valid(_items_container):
		return
	for child in _items_container.get_children():
		child.queue_free()

func add_item_control(item_control: Control) -> void:
	if not is_instance_valid(_items_container):
		return
	if item_control.get_parent() != _items_container:
		item_control.reparent(_items_container)

	if item_control.has_method("set_zone_id"):
		item_control.call("set_zone_id", socket_id)
	else:
		item_control.set_meta("zone_id", socket_id)

	var item_id: String = str(item_control.get_meta("item_id", ""))
	if item_id == "" and item_control.has_method("get_item_id"):
		item_id = str(item_control.call("get_item_id"))
	if item_id != "" and not occupied_ids.has(item_id):
		occupied_ids.append(item_id)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if _is_input_locked():
		return false
	if typeof(data) != TYPE_DICTIONARY:
		return false

	var payload: Dictionary = data as Dictionary
	if str(payload.get("kind", "")) != "RESUS_PART":
		return false

	_drag_item_id = str(payload.get("item_id", ""))
	_hover_accepts = _accepts_item(_drag_item_id)
	if _hover_accepts:
		hint_requested.emit(_drag_item_id, socket_id)
		hint_hover.emit(_drag_item_id, socket_id)
	_apply_visual_state()
	return true

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if _is_input_locked():
		return
	if typeof(data) != TYPE_DICTIONARY:
		return

	var payload: Dictionary = data as Dictionary
	if str(payload.get("kind", "")) != "RESUS_PART":
		return

	var item_id: String = str(payload.get("item_id", ""))
	var accepted: bool = _accepts_item(item_id)
	if accepted:
		drop_accepted.emit(item_id, socket_id)
	else:
		drop_rejected.emit(item_id, socket_id)

	var controller: Node = _controller()
	if controller != null and controller.has_method("on_socket_drop"):
		controller.call("on_socket_drop", payload, socket_id, accepted)

	_drag_item_id = ""
	_hover_accepts = false
	_apply_visual_state()

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_drag_item_id = ""
		_hover_accepts = false
		_apply_visual_state()

func _apply_visual_state() -> void:
	var mode: String = _feedback_mode
	if _drag_item_id != "":
		mode = "hover_valid" if _hover_accepts else "hover_invalid"

	match mode:
		"target_valid":
			modulate = Color(1.04, 1.08, 1.04, 1.0)
			_set_glow(true, _base_glow_color)
		"target_invalid":
			modulate = Color(0.96, 0.96, 0.96, 1.0)
			_set_glow(true, Color(0.92, 0.74, 0.32, 0.16))
		"hover_valid":
			modulate = Color(1.08, 1.12, 1.08, 1.0)
			_set_glow(true, _base_glow_color.lightened(0.15))
		"hover_invalid":
			modulate = Color(1.08, 0.92, 0.92, 1.0)
			_set_glow(true, Color(0.92, 0.32, 0.36, 0.2))
		"rejected":
			modulate = Color(1.12, 0.88, 0.9, 1.0)
			_set_glow(true, Color(0.95, 0.36, 0.38, 0.24))
		_:
			modulate = Color(1.0, 1.0, 1.0, 1.0)
			_set_glow(false, _base_glow_color)

func _set_glow(active: bool, color: Color) -> void:
	if not is_instance_valid(_glow_rect):
		return
	_glow_rect.visible = active
	_glow_rect.color = color
	var material: ShaderMaterial = _glow_rect.material as ShaderMaterial
	if material != null:
		material.set_shader_parameter("active", active)

func _accepts_item(item_id: String) -> bool:
	if item_id == "":
		return false
	for accepted_id in accept_ids:
		if accepted_id == item_id:
			return true
	return false

func _is_input_locked() -> bool:
	var controller: Node = _controller()
	if controller == null:
		return false
	if controller.has_method("is_input_locked"):
		return bool(controller.call("is_input_locked"))
	return false

func _controller() -> Node:
	return get_tree().get_first_node_in_group("resus_a_controller")
