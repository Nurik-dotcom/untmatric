extends PanelContainer

signal selected(option_id: String)

const COLOR_BASE := Color(1, 1, 1, 1)
const COLOR_SELECTED := Color(1.1, 1.1, 1.1, 1)
const COLOR_BUDGET_OK := Color(0.42, 0.95, 0.55, 1)
const COLOR_BUDGET_BAD := Color(1.0, 0.45, 0.45, 1)

var option_id: String = ""
var total_price: int = 0
var budget_limit: int = 0
var _locked: bool = false

@onready var title_label: Label = $VBox/Title
@onready var price_label: Label = $VBox/Price
@onready var parts_label: Label = $VBox/Parts
@onready var tags_label: Label = $VBox/Tags

func setup(option_data: Dictionary, budget: int) -> void:
	option_id = str(option_data.get("option_id", ""))
	total_price = int(option_data.get("total_price", 0))
	budget_limit = budget

	title_label.text = str(option_data.get("title", option_id))
	price_label.text = "Price: %d$" % total_price
	price_label.modulate = COLOR_BUDGET_BAD if total_price > budget_limit else COLOR_BUDGET_OK

	var parts_lines: Array[String] = []
	var parts: Array = option_data.get("parts", []) as Array
	for part_v in parts:
		if typeof(part_v) != TYPE_DICTIONARY:
			continue
		var part: Dictionary = part_v as Dictionary
		parts_lines.append("%s: %s (%s$)" % [str(part.get("k", "?")), str(part.get("v", "?")), str(part.get("price", 0))])
	parts_label.text = "\n".join(parts_lines)

	var tags: Array = option_data.get("tags", []) as Array
	var tags_text: String = ""
	for tag_v in tags:
		if tags_text != "":
			tags_text += "  |  "
		tags_text += str(tag_v)
	tags_label.text = tags_text

func set_selected_state(is_selected: bool) -> void:
	modulate = COLOR_SELECTED if is_selected else COLOR_BASE

func set_locked(locked: bool) -> void:
	_locked = locked

func _gui_input(event: InputEvent) -> void:
	if _locked:
		return
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			accept_event()
			selected.emit(option_id)
	elif event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
		if touch_event.pressed:
			accept_event()
			selected.emit(option_id)
