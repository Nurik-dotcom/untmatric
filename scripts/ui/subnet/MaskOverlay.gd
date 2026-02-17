extends PanelContainer
class_name SubnetMaskOverlay

signal mask_selected(mask_data: Dictionary, sender: Node)
signal mask_drag_started(mask_data: Dictionary)

var label_mask: Label = null
var mask_data: Dictionary = {}

func _ready() -> void:
	_ensure_label()
	_refresh_label()

func setup(cidr: int, mask_last: int) -> void:
	mask_data = {
		"cidr": cidr,
		"mask_last": mask_last,
		"display": "/%d" % cidr
	}
	_refresh_label()
	set_selected(false)
	tooltip_text = "mask /%d (last octet %d)" % [cidr, mask_last]

func get_mask_data() -> Dictionary:
	return mask_data.duplicate(true)

func set_selected(active: bool) -> void:
	if active:
		modulate = Color(1.0, 0.95, 0.72, 1.0)
	else:
		modulate = Color(1.0, 1.0, 1.0, 1.0)

func _get_drag_data(_at_position: Vector2) -> Variant:
	if mask_data.is_empty():
		return null

	emit_signal("mask_drag_started", mask_data.duplicate(true))

	var preview_panel: PanelContainer = PanelContainer.new()
	preview_panel.custom_minimum_size = Vector2(128.0, 52.0)
	var preview_margin: MarginContainer = MarginContainer.new()
	preview_margin.add_theme_constant_override("margin_left", 8)
	preview_margin.add_theme_constant_override("margin_top", 6)
	preview_margin.add_theme_constant_override("margin_right", 8)
	preview_margin.add_theme_constant_override("margin_bottom", 6)
	var preview_label: Label = Label.new()
	preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	preview_label.text = "MASK %s" % str(mask_data.get("display", ""))
	preview_margin.add_child(preview_label)
	preview_panel.add_child(preview_margin)
	set_drag_preview(preview_panel)

	return {
		"kind": "subnet_mask_overlay",
		"mask": mask_data.duplicate(true)
	}

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			emit_signal("mask_selected", mask_data.duplicate(true), self)
			accept_event()
		return

	if event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event
		if touch_event.pressed:
			emit_signal("mask_selected", mask_data.duplicate(true), self)
			accept_event()

func _ensure_label() -> void:
	if label_mask == null:
		label_mask = get_node_or_null("Margin/LabelMask") as Label

func _refresh_label() -> void:
	_ensure_label()
	if label_mask == null:
		return
	if mask_data.is_empty():
		label_mask.text = "MASK ?"
	else:
		label_mask.text = "MASK %s" % str(mask_data.get("display", ""))
