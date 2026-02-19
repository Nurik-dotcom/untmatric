extends PanelContainer

signal slot_changed(slot_index: int, option_id: String, prev_option_id: String)
signal slot_cleared(slot_index: int, prev_option_id: String)

@export var slot_index: int = 1
@export var title_path: NodePath = NodePath("Margin/VBox/TopRow/SlotTitle")
@export var item_label_path: NodePath = NodePath("Margin/VBox/ItemLabel")
@export var item_holder_path: NodePath = NodePath("Margin/VBox/ItemHolder")
@export var clear_button_path: NodePath = NodePath("Margin/VBox/TopRow/BtnClear")

var current_option_id: String = ""

var _locked: bool = false
var _drag_hovered: bool = false
var _feedback_state: String = "neutral"

@onready var _title_label: Label = get_node_or_null(title_path) as Label
@onready var _item_label: Label = get_node_or_null(item_label_path) as Label
@onready var _item_holder: Control = get_node_or_null(item_holder_path) as Control
@onready var _btn_clear: Button = get_node_or_null(clear_button_path) as Button

func _ready() -> void:
	if is_instance_valid(_btn_clear):
		_btn_clear.pressed.connect(_on_clear_pressed)

	mouse_exited.connect(func() -> void:
		_drag_hovered = false
		_apply_visual_state()
	)

	set_slot_title(slot_index)
	set_current_option("", "")
	set_locked(false)
	_apply_visual_state()

func set_slot_title(index: int) -> void:
	slot_index = index
	if is_instance_valid(_title_label):
		_title_label.text = "СЛОТ %d" % slot_index

func set_locked(locked: bool) -> void:
	_locked = locked
	_update_clear_button_state()
	_apply_visual_state()

func set_feedback_state(state: String) -> void:
	_feedback_state = state
	_apply_visual_state()

func set_current_option(option_id: String, option_label: String = "") -> void:
	current_option_id = option_id
	if is_instance_valid(_item_label):
		if current_option_id == "":
			_item_label.text = "<пусто>"
		elif option_label != "":
			_item_label.text = option_label
		else:
			_item_label.text = current_option_id
	_update_clear_button_state()
	_apply_visual_state()

func attach_item_control(item_control: Control) -> void:
	if not is_instance_valid(_item_holder):
		return
	if item_control.get_parent() != _item_holder:
		item_control.reparent(_item_holder)
	item_control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_control.size_flags_vertical = Control.SIZE_EXPAND_FILL
	item_control.custom_minimum_size = Vector2(0, 80)
	if is_instance_valid(_item_label):
		_item_label.text = ""
	_pulse()
	_update_clear_button_state()

func clear_item_holder() -> void:
	if not is_instance_valid(_item_holder):
		return
	for child in _item_holder.get_children():
		_item_holder.remove_child(child)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if _locked:
		return false
	if typeof(data) != TYPE_DICTIONARY:
		return false

	var payload: Dictionary = data as Dictionary
	if str(payload.get("kind", "")) != "NET_ITEM":
		return false

	var controller: Node = _get_controller()
	if controller != null and bool(controller.call("is_input_locked")):
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
	var controller: Node = _get_controller()
	if controller == null:
		return

	var result_variant: Variant = controller.call("handle_drop_to_slot", slot_index, payload)
	if typeof(result_variant) != TYPE_DICTIONARY:
		return
	var result: Dictionary = result_variant as Dictionary
	if not bool(result.get("success", false)):
		_flash_reject()
		return

	var new_option_id: String = str(result.get("option_id", ""))
	var prev_option_id: String = str(result.get("prev_option_id", ""))
	var label: String = str(result.get("label", new_option_id))
	set_current_option(new_option_id, label)
	slot_changed.emit(slot_index, new_option_id, prev_option_id)

func _on_clear_pressed() -> void:
	if _locked:
		return
	var controller: Node = _get_controller()
	if controller == null:
		return

	var result_variant: Variant = controller.call("handle_clear_slot", slot_index)
	if typeof(result_variant) != TYPE_DICTIONARY:
		return
	var result: Dictionary = result_variant as Dictionary
	if not bool(result.get("success", false)):
		return

	var prev_option_id: String = str(result.get("prev_option_id", ""))
	set_current_option("", "")
	slot_cleared.emit(slot_index, prev_option_id)

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and not is_drag_successful():
		_drag_hovered = false
		_apply_visual_state()

func _get_controller() -> Node:
	return get_tree().get_first_node_in_group("resus_c_controller")

func _update_clear_button_state() -> void:
	if not is_instance_valid(_btn_clear):
		return
	_btn_clear.disabled = _locked or current_option_id == ""

func _apply_visual_state() -> void:
	var tone: Color = Color(1.0, 1.0, 1.0, 1.0)
	match _feedback_state:
		"correct":
			tone = Color(0.82, 1.08, 0.84, 1.0)
		"wrong":
			tone = Color(1.08, 0.80, 0.80, 1.0)
		"missing":
			tone = Color(1.05, 0.97, 0.72, 1.0)
		_:
			tone = Color(1.0, 1.0, 1.0, 1.0)

	if _drag_hovered:
		tone = Color(tone.r * 1.08, tone.g * 1.08, tone.b * 1.08, tone.a)

	if _locked and _feedback_state == "neutral":
		tone = Color(0.9, 0.9, 0.9, 1.0)

	self_modulate = tone

func _pulse() -> void:
	var tween: Tween = create_tween()
	scale = Vector2(1.02, 1.02)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)

func _flash_reject() -> void:
	self_modulate = Color(1.1, 0.72, 0.72, 1.0)
	var tween: Tween = create_tween()
	tween.tween_property(self, "self_modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)
