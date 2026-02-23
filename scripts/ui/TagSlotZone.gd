extends PanelContainer

signal item_placed(fragment_id: String, to_zone: String, from_zone: String)

@export var title_path: NodePath = NodePath("VBox/SlotTitle")
@export var items_container_path: NodePath = NodePath("VBox/Center/Items")
@export var empty_overlay_path: NodePath = NodePath("EmptyOverlay")
@export var empty_label_path: NodePath = NodePath("EmptyOverlay/Center/EmptyLabel")

var zone_id: String = ""
var _feedback_state: String = "neutral"
var _drag_hovered: bool = false
var _wrong_flash_active: bool = false
var _wrong_flash_tween: Tween

@onready var _title_label: Label = get_node_or_null(title_path) as Label
@onready var _items_container: Control = get_node_or_null(items_container_path) as Control
@onready var _empty_overlay: ColorRect = get_node_or_null(empty_overlay_path) as ColorRect
@onready var _empty_label: Label = get_node_or_null(empty_label_path) as Label

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

func get_zone_id() -> String:
	return zone_id

func get_items_container() -> Control:
	return _items_container

func clear_items() -> void:
	if not is_instance_valid(_items_container):
		return
	for child in _items_container.get_children():
		_items_container.remove_child(child)
		child.queue_free()
	_apply_visual_state()

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
	_apply_visual_state()

func get_current_fragment_id() -> String:
	if not is_instance_valid(_items_container):
		return ""
	if _items_container.get_child_count() <= 0:
		return ""
	var item_node: Node = _items_container.get_child(0)
	if item_node.has_method("get_fragment_id"):
		return str(item_node.call("get_fragment_id"))
	return str(item_node.get_meta("fragment_id", ""))

func set_feedback_state(state: String) -> void:
	_feedback_state = state
	_apply_visual_state()

func flash_wrong() -> void:
	if _empty_overlay == null:
		return
	if _wrong_flash_tween != null and _wrong_flash_tween.is_running():
		_wrong_flash_tween.kill()
	_wrong_flash_active = true
	_empty_overlay.visible = true
	_empty_overlay.modulate = Color(1.0, 0.26, 0.26, 0.0)
	_wrong_flash_tween = create_tween()
	_wrong_flash_tween.tween_property(_empty_overlay, "modulate:a", 0.84, 0.06)
	_wrong_flash_tween.tween_property(_empty_overlay, "modulate:a", 0.0, 0.18)
	_wrong_flash_tween.finished.connect(func() -> void:
		_wrong_flash_active = false
		_apply_visual_state()
	)

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

	var result_variant: Variant = controller.call("handle_drop_to_slot", zone_id, payload)
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
	var occupied: bool = false
	if is_instance_valid(_items_container):
		occupied = _items_container.get_child_count() > 0

	var tone: Color = Color(1.0, 1.0, 1.0, 1.0)
	match _feedback_state:
		"ok":
			tone = Color(0.78, 1.05, 0.82, 1.0)
		"bad":
			tone = Color(1.08, 0.78, 0.78, 1.0)
		_:
			tone = Color(1.0, 1.0, 1.0, 1.0)

	if _drag_hovered:
		tone = Color(tone.r * 1.08, tone.g * 1.08, tone.b * 1.08, tone.a)

	self_modulate = tone

	if _empty_overlay != null and not _wrong_flash_active:
		_empty_overlay.visible = not occupied
		_empty_overlay.modulate = Color(1.0, 1.0, 1.0, 0.42) if not occupied else Color(1.0, 1.0, 1.0, 0.0)
	if _empty_label != null:
		_empty_label.visible = not occupied and not _wrong_flash_active

func _pulse() -> void:
	var tween: Tween = create_tween()
	scale = Vector2(1.02, 1.02)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)
