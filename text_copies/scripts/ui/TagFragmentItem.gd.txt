extends Button

signal drag_started(fragment_id: String, from_zone: String)

var fragment_id: String = ""
var fragment_label: String = ""
var fragment_kind: String = ""
var fragment_token: String = ""

func setup(fragment_data: Dictionary) -> void:
	fragment_id = str(fragment_data.get("fragment_id", ""))
	fragment_label = str(fragment_data.get("label", ""))
	fragment_kind = str(fragment_data.get("kind", ""))
	fragment_token = str(fragment_data.get("token", fragment_label))

	text = fragment_label
	custom_minimum_size = Vector2(0, 72)
	theme_type_variation = &"FlatButton"
	set_zone_id("PILE")

func set_zone_id(zone_id: String) -> void:
	set_meta("zone_id", zone_id)

func get_zone_id() -> String:
	return str(get_meta("zone_id", "PILE"))

func get_fragment_id() -> String:
	return fragment_id

func _get_drag_data(_at_position: Vector2) -> Variant:
	var from_zone: String = get_zone_id()
	drag_started.emit(fragment_id, from_zone)

	var data: Dictionary = {
		"kind": "TAG_FRAGMENT",
		"fragment_id": fragment_id,
		"from_zone": from_zone,
		"source_path": get_path()
	}

	var preview: Button = duplicate() as Button
	preview.modulate.a = 0.9
	var holder: Control = Control.new()
	holder.add_child(preview)
	preview.position = -0.5 * preview.size
	set_drag_preview(holder)

	return data
