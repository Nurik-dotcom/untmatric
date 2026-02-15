extends Button

var item_id: String = ""
var label: String = ""
var correct_bucket_id: String = ""

func setup(item_data: Dictionary):
	item_id = item_data.get("item_id", "")
	label = item_data.get("label", "")
	correct_bucket_id = item_data.get("correct_bucket_id", "")

	text = label
	custom_minimum_size = Vector2(0, 80)

func _get_drag_data(_at_position: Vector2):
	var data = {
		"kind": "CLUE_ITEM",
		"item_id": item_id,
		"label": label,
		"source_path": get_path()
	}

	var preview = self.duplicate()
	preview.modulate.a = 0.8
	# Wrap in control to center
	var c = Control.new()
	c.add_child(preview)
	preview.position = -0.5 * preview.size
	set_drag_preview(c)

	return data
