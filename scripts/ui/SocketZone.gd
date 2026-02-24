extends PanelContainer

signal hint_requested(item_id: String, socket_id: String)
signal hint_hover(item_id: String, socket_id: String)
signal drop_accepted(item_id: String, socket_id: String)
signal drop_rejected(item_id: String, socket_id: String)

@export var socket_id: String = ""
@export var title_path: NodePath = NodePath("VBox/BucketTitle")
@export var items_container_path: NodePath = NodePath("VBox/ItemsFlow")
@export var accept_ids: Array[String] = []

var occupied_ids: Array[String] = []
var _drag_item_id: String = ""
var _hover_accepts: bool = false

@onready var _title_label: Label = get_node_or_null(title_path) as Label
@onready var _items_container: Control = get_node_or_null(items_container_path) as Control

func _ready() -> void:
	mouse_exited.connect(func() -> void:
		_drag_item_id = ""
		_hover_accepts = false
		_apply_hover(false, false)
	)

func setup(p_socket_id: String, p_label_text: String, p_accept_ids: Array[String] = []) -> void:
	socket_id = p_socket_id.to_upper()
	accept_ids = p_accept_ids.duplicate()
	if is_instance_valid(_title_label):
		_title_label.text = p_label_text

func set_accept_ids(ids: Array[String]) -> void:
	accept_ids = ids.duplicate()

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
	_apply_hover(true, _hover_accepts)
	return _hover_accepts

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	_apply_hover(false, false)
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

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_apply_hover(false, false)

func _apply_hover(active: bool, accepted: bool) -> void:
	if not active:
		modulate = Color(1.0, 1.0, 1.0, 1.0)
		return
	if accepted:
		modulate = Color(1.05, 1.1, 1.05, 1.0)
	else:
		modulate = Color(1.1, 0.92, 0.92, 1.0)

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
