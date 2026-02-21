extends PanelContainer
class_name PipelineSlotControl

signal module_dropped(slot_type: String, module_data: Dictionary)
signal slot_tapped(slot_type: String)
signal clear_pressed(slot_type: String)
signal bad_drop(slot_type: String, module_data: Dictionary)

@onready var label_slot_title: Label = $Margin/VBox/LabelSlotTitle
@onready var label_module_name: Label = $Margin/VBox/LabelModuleName
@onready var btn_clear: Button = $Margin/VBox/BtnClear

var slot_type: String = ""
var current_module: Dictionary = {}

func _ready() -> void:
	btn_clear.pressed.connect(_on_clear_pressed)
	_update_visual_state()

func setup(p_slot_type: String, title: String) -> void:
	slot_type = p_slot_type
	label_slot_title.text = title
	clear_module()

func has_module() -> bool:
	return not current_module.is_empty()

func get_module() -> Dictionary:
	return current_module.duplicate(true)

func get_module_id() -> String:
	if current_module.is_empty():
		return ""
	return str(current_module.get("module_id", ""))

func set_module(module_data: Dictionary) -> void:
	current_module = module_data.duplicate(true)
	label_module_name.text = str(current_module.get("display", "?"))
	_update_visual_state()

func clear_module() -> void:
	current_module.clear()
	label_module_name.text = "<пусто>"
	_update_visual_state()

func flash_bad_drop() -> void:
	modulate = Color(1.0, 0.55, 0.55, 1.0)
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	var module_data: Dictionary = _extract_module_data(data)
	if module_data.is_empty():
		return false
	return str(module_data.get("slot_type", "")) == slot_type

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var module_data: Dictionary = _extract_module_data(data)
	if module_data.is_empty():
		return

	if str(module_data.get("slot_type", "")) != slot_type:
		emit_signal("bad_drop", slot_type, module_data)
		return

	emit_signal("module_dropped", slot_type, module_data)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			emit_signal("slot_tapped", slot_type)
		return

	if event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event
		if touch_event.pressed:
			emit_signal("slot_tapped", slot_type)

func _on_clear_pressed() -> void:
	emit_signal("clear_pressed", slot_type)

func _extract_module_data(data: Variant) -> Dictionary:
	if typeof(data) != TYPE_DICTIONARY:
		return {}

	var drop_data: Dictionary = data
	if str(drop_data.get("kind", "")) != "pipeline_module":
		return {}

	var module_variant: Variant = drop_data.get("module", {})
	if typeof(module_variant) != TYPE_DICTIONARY:
		return {}

	var module_data: Dictionary = module_variant
	return module_data.duplicate(true)

func _update_visual_state() -> void:
	btn_clear.disabled = current_module.is_empty()
	if current_module.is_empty():
		modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		modulate = Color(0.86, 1.0, 0.9, 1.0)

