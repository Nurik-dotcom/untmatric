extends PanelContainer
class_name SubnetMaskDropTarget

signal mask_dropped(mask_data: Dictionary)
signal bad_drop(data: Dictionary)
signal target_tapped

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	var mask_data: Dictionary = _extract_mask_data(data)
	return not mask_data.is_empty()

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var mask_data: Dictionary = _extract_mask_data(data)
	if mask_data.is_empty():
		emit_signal("bad_drop", {})
		return
	emit_signal("mask_dropped", mask_data)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			emit_signal("target_tapped")
			accept_event()
		return

	if event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event
		if touch_event.pressed:
			emit_signal("target_tapped")
			accept_event()

func flash_bad_drop() -> void:
	modulate = Color(1.0, 0.55, 0.55, 1.0)
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)

func _extract_mask_data(data: Variant) -> Dictionary:
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	var drop_data: Dictionary = data
	if str(drop_data.get("kind", "")) != "subnet_mask_overlay":
		return {}
	var mask_variant: Variant = drop_data.get("mask", {})
	if typeof(mask_variant) != TYPE_DICTIONARY:
		return {}
	var mask_dict: Dictionary = mask_variant
	return mask_dict.duplicate(true)
