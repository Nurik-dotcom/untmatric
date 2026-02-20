extends PanelContainer

signal selected(option_id: String)

const COLOR_BASE := Color(1.0, 1.0, 1.0, 1.0)
const COLOR_SELECTED := Color(1.08, 1.08, 1.08, 1.0)
const COLOR_BUDGET_OK := Color(0.92, 0.92, 0.92, 1.0)
const COLOR_BUDGET_BAD := Color(0.93, 0.34, 0.38, 1.0)

var option_id: String = ""
var total_price: int = 0
var budget_limit: int = 0
var _locked: bool = false

@onready var title_label: Label = _resolve_label("VBox/Title")
@onready var price_label: Label = _resolve_label("VBox/Price")
@onready var parts_label: Label = _resolve_label("VBox/Parts", "VBox/Детали")
@onready var tags_label: Label = _resolve_label("VBox/Tags", "VBox/Теги")

func _resolve_label(primary_path: String, fallback_path: String = "") -> Label:
	var node: Node = get_node_or_null(primary_path)
	if node == null and fallback_path != "":
		node = get_node_or_null(fallback_path)
	return node as Label

func setup(option_data: Dictionary, budget: int) -> void:
	option_id = str(option_data.get("option_id", ""))
	total_price = int(option_data.get("total_price", 0))
	budget_limit = budget

	if is_instance_valid(title_label):
		title_label.text = str(option_data.get("title", option_id))
	if is_instance_valid(price_label):
		price_label.text = "Бюджет: %d$" % total_price
		price_label.modulate = COLOR_BUDGET_BAD if total_price > budget_limit else COLOR_BUDGET_OK
	
	var parts_lines: Array[String] = []
	var parts: Array = option_data.get("parts", []) as Array
	for part_v in parts:
		if typeof(part_v) != TYPE_DICTIONARY:
			continue
		var part: Dictionary = part_v as Dictionary
		parts_lines.append("%s: %s (%s$)" % [str(part.get("k", "?")), str(part.get("v", "?")), str(part.get("price", 0))])
	if is_instance_valid(parts_label):
		parts_label.text = "\n".join(parts_lines)

	var tags: Array = option_data.get("tags", []) as Array
	var tags_text: String = ""
	for tag_v in tags:
		if tags_text != "":
			tags_text += "  |  "
		tags_text += str(tag_v)
	if is_instance_valid(tags_label):
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
