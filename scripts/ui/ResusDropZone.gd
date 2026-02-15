extends PanelContainer

signal item_placed(item_id: String, to_bucket: String, from_bucket: String)

@export var title_path: NodePath = NodePath("VBox/BucketTitle")
@export var items_container_path: NodePath = NodePath("VBox/ItemsFlow")

var bucket_id: String = ""

@onready var _title_label: Label = get_node_or_null(title_path) as Label
@onready var _items_container: Control = get_node_or_null(items_container_path) as Control

func _ready() -> void:
	mouse_exited.connect(func() -> void:
		modulate = Color(1, 1, 1, 1)
	)

func setup(p_bucket_id: String, p_label_text: String) -> void:
	bucket_id = p_bucket_id.to_upper()
	if is_instance_valid(_title_label):
		_title_label.text = p_label_text

func get_items_container() -> Control:
	return _items_container

func clear_items() -> void:
	if not is_instance_valid(_items_container):
		return
	for child in _items_container.get_children():
		child.queue_free()

func add_item_control(item_control: Control) -> void:
	if not is_instance_valid(_items_container):
		return
	_items_container.add_child(item_control)
	if item_control.has_method("set_zone_id"):
		item_control.call("set_zone_id", bucket_id)
	else:
		item_control.set_meta("zone_id", bucket_id)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	var payload: Dictionary = data as Dictionary
	if str(payload.get("kind", "")) != "RESUS_ITEM":
		return false
	modulate = Color(1.15, 1.15, 1.15, 1.0)
	return true

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	modulate = Color(1, 1, 1, 1)
	if typeof(data) != TYPE_DICTIONARY:
		return
	var payload: Dictionary = data as Dictionary
	var source_path: String = str(payload.get("source_path", ""))
	if source_path == "":
		return
	var source_node: Node = get_node_or_null(source_path)
	if source_node == null or not is_instance_valid(_items_container):
		return

	var from_bucket: String = str(payload.get("from_zone", source_node.get_meta("zone_id", "PILE")))
	source_node.reparent(_items_container)
	if source_node.has_method("set_zone_id"):
		source_node.call("set_zone_id", bucket_id)
	else:
		source_node.set_meta("zone_id", bucket_id)

	if source_node is Control:
		var control_node: Control = source_node as Control
		var tween: Tween = create_tween()
		control_node.scale = Vector2(1.05, 1.05)
		tween.tween_property(control_node, "scale", Vector2.ONE, 0.1)

	item_placed.emit(str(payload.get("item_id", "")), bucket_id, from_bucket)
	if has_node("/root/AudioManager"):
		AudioManager.play("click")

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and not is_drag_successful():
		modulate = Color(1, 1, 1, 1)
