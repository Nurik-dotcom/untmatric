extends Button

signal drag_started(item_id: String, from_zone: String)

var item_id: String = ""
var item_label: String = ""
var correct_bucket_id: String = ""

func setup(item_data: Dictionary) -> void:
	item_id = str(item_data.get("item_id", ""))
	item_label = str(item_data.get("label", ""))
	correct_bucket_id = str(item_data.get("correct_bucket_id", "")).to_upper()
	text = item_label
	custom_minimum_size = Vector2(0, 76)
	set_meta("zone_id", "PILE")

func set_zone_id(zone_id: String) -> void:
	set_meta("zone_id", zone_id)

func get_zone_id() -> String:
	return str(get_meta("zone_id", "PILE"))

func _get_drag_data(_at_position: Vector2) -> Variant:
	var from_zone: String = get_zone_id()
	drag_started.emit(item_id, from_zone)

	var data: Dictionary = {
		"kind": "RESUS_ITEM",
		"item_id": item_id,
		"label": item_label,
		"source_path": get_path(),
		"from_zone": from_zone
	}

	var preview: Button = duplicate() as Button
	preview.modulate.a = 0.9
	var holder: Control = Control.new()
	holder.add_child(preview)
	preview.position = -0.5 * preview.size
	set_drag_preview(holder)

	return data
