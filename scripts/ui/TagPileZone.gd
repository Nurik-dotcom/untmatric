extends PanelContainer

signal item_placed(fragment_id: String, to_zone: String, from_zone: String)

@export var title_path: NodePath = NodePath("VBox/PileTitle")
@export var items_container_path: NodePath = NodePath("VBox/Scroll/ItemsGrid")

var zone_id: String = "PILE"
var _drag_hovered: bool = false

@onready var _title_label: Label = get_node_or_null(title_path) as Label
@onready var _items_container: Control = get_node_or_null(items_container_path) as Control

func _ready() -> void:
	mouse_exited.connect(func() -> void:
		_drag_hovered = false
		_apply_visual_state()
	)
	_apply_visual_state()

func setup(p_zone_id: String, p_label_text: String) -> void:
	zone_id = p_zone_id
	if is_instance_valid(_title_label):
		_title_label.text = p_label_text

func clear_items() -> void:
	if not is_instance_valid(_items_container):
		return
	for child in _items_container.get_children():
		_items_container.remove_child(child)
		child.queue_free()

func add_item_control(item_control: Control) -> void:
	if not is_instance_valid(_items_container):
		return
	var current_parent: Node = item_control.get_parent()
	if current_parent == null:
		_items_container.add_child(item_control)
	elif current_parent != _items_container:
		item_control.reparent(_items_container)
	if item_control.has_method("set_zone_id"):
		item_control.call("set_zone_id", zone_id)
	else:
		item_control.set_meta("zone_id", zone_id)

	var tween: Tween = create_tween()
	item_control.scale = Vector2(1.05, 1.05)
	tween.tween_property(item_control, "scale", Vector2.ONE, 0.1)

func set_grid_columns(columns: int) -> void:
	if not (_items_container is GridContainer):
		return
	(_items_container as GridContainer).columns = max(1, columns)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	var payload: Dictionary = data as Dictionary
	if str(payload.get("kind", "")) != "TAG_FRAGMENT":
		return false
	_drag_hovered = true
	_apply_visual_state()
	return true

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	_drag_hovered = false
	_apply_visual_state()
	if typeof(data) != TYPE_DICTIONARY:
		return

	var payload: Dictionary = data as Dictionary
	var controller: Node = _get_drop_controller()
	if controller == null:
		return

	var result_variant: Variant = controller.call("handle_drop_to_pile", payload)
	if typeof(result_variant) != TYPE_DICTIONARY:
		return
	var result: Dictionary = result_variant as Dictionary
	if not bool(result.get("success", false)):
		return

	_pulse()
	item_placed.emit(str(result.get("fragment_id", "")), zone_id, str(result.get("from_zone", "PILE")))
	if has_node("/root/AudioManager"):
		AudioManager.play("click")

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and not is_drag_successful():
		_drag_hovered = false
		_apply_visual_state()

func _get_drop_controller() -> Node:
	return get_tree().get_first_node_in_group("fr8_drop_controller")

func _apply_visual_state() -> void:
	self_modulate = Color(1.06, 1.06, 1.06, 1.0) if _drag_hovered else Color(1.0, 1.0, 1.0, 1.0)

func _pulse() -> void:
	var tween: Tween = create_tween()
	scale = Vector2(1.01, 1.01)
	tween.tween_property(self, "scale", Vector2.ONE, 0.08)
