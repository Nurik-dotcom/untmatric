extends PanelContainer
class_name PipelineModuleCard

signal module_selected(module_data: Dictionary, sender: Node)
signal module_drag_started(module_data: Dictionary)

var label_text: Label = null

var module_data: Dictionary = {}

func _ready() -> void:
	if label_text == null:
		label_text = get_node_or_null("Margin/Label") as Label
	if label_text != null and not module_data.is_empty():
		label_text.text = str(module_data.get("display", "?"))

func setup(data: Dictionary) -> void:
	module_data = data.duplicate(true)
	if label_text == null:
		label_text = get_node_or_null("Margin/Label") as Label
	if label_text != null:
		label_text.text = str(module_data.get("display", "?"))
	tooltip_text = "%s [%s]" % [
		str(module_data.get("module_id", "unknown")),
		str(module_data.get("slot_type", ""))
	]
	set_selected(false)

func get_module_data() -> Dictionary:
	return module_data.duplicate(true)

func set_selected(selected: bool) -> void:
	if selected:
		modulate = Color(1.0, 1.0, 0.82, 1.0)
	else:
		modulate = Color(1.0, 1.0, 1.0, 1.0)

func _get_drag_data(_at_position: Vector2) -> Variant:
	if module_data.is_empty():
		return null

	emit_signal("module_drag_started", module_data.duplicate(true))

	var preview_panel: PanelContainer = PanelContainer.new()
	preview_panel.custom_minimum_size = Vector2(120.0, 48.0)
	var preview_margin: MarginContainer = MarginContainer.new()
	preview_margin.add_theme_constant_override("margin_left", 8)
	preview_margin.add_theme_constant_override("margin_top", 6)
	preview_margin.add_theme_constant_override("margin_right", 8)
	preview_margin.add_theme_constant_override("margin_bottom", 6)
	var preview_label: Label = Label.new()
	preview_label.text = str(module_data.get("display", "?"))
	preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	preview_margin.add_child(preview_label)
	preview_panel.add_child(preview_margin)
	set_drag_preview(preview_panel)

	return {
		"kind": "pipeline_module",
		"module": module_data.duplicate(true)
	}

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			emit_signal("module_selected", module_data.duplicate(true), self)
			accept_event()
		return

	if event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event
		if touch_event.pressed:
			emit_signal("module_selected", module_data.duplicate(true), self)
			accept_event()
