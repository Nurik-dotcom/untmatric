extends Button
class_name NetworkTraceDeviceCard

var device_id: String = ""
var device_label: String = ""
var error_code: String = ""

func setup(option_id: String, label_text: String, option_error_code: String) -> void:
	device_id = option_id
	device_label = label_text
	error_code = option_error_code
	text = label_text
	tooltip_text = label_text
	disabled = false

func clear_state() -> void:
	device_id = ""
	device_label = ""
	error_code = ""
	text = ""
	disabled = true

func _get_drag_data(_at_position: Vector2) -> Variant:
	if disabled:
		return null
	if device_id.is_empty():
		return null

	var preview: Label = Label.new()
	preview.text = device_label
	preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview.add_theme_font_size_override("font_size", 18)
	set_drag_preview(preview)

	return {
		"type": "network_trace_device",
		"device_id": device_id,
		"label": device_label,
		"error_code": error_code
	}
