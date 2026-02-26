extends Button

signal drag_started(item_id: String, from_zone: String)
signal drag_cancelled(item_id: String, from_zone: String)

@onready var glow_overlay: ColorRect = $GlowOverlay
@onready var type_indicator: ColorRect = $TypeIndicator
@onready var type_icon: Label = $IconContainer/TypeIcon
@onready var drag_hint: Label = $DragHint

var item_id: String = ""
var item_label: String = ""
var correct_bucket_id: String = ""
var _drag_from_zone: String = "PILE"

# Colors for different bucket types
const COLOR_INPUT := Color(0.13, 0.59, 0.95, 1.0)   # Blue
const COLOR_OUTPUT := Color(0.3, 0.69, 0.31, 1.0)   # Green
const COLOR_MEMORY := Color(0.61, 0.15, 0.69, 1.0)  # Purple
const COLOR_UNKNOWN := Color(0.5, 0.5, 0.5, 1.0)   # Gray

func _ready() -> void:
	_update_visuals()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func setup(item_data: Dictionary) -> void:
	item_id = str(item_data.get("item_id", ""))
	item_label = str(item_data.get("label", ""))
	correct_bucket_id = str(item_data.get("correct_bucket_id", "")).to_upper()
	text = item_label
	custom_minimum_size = Vector2(0, 76)
	set_meta("item_id", item_id)
	set_meta("zone_id", "PILE")
	_update_visuals()

func _update_visuals() -> void:
	# Set color based on correct bucket
	var color := COLOR_UNKNOWN
	var icon_text := "?"
	match correct_bucket_id:
		"INPUT", "A":
			color = COLOR_INPUT
			icon_text = "◉"
		"OUTPUT", "B":
			color = COLOR_OUTPUT
			icon_text = "▶"
		"MEMORY", "C":
			color = COLOR_MEMORY
			icon_text = "◈"
		_:
			color = COLOR_UNKNOWN
			icon_text = "?"
	
	if type_indicator:
		type_indicator.color = color
	if glow_overlay:
		glow_overlay.color = Color(color.r, color.g, color.b, 0.3)
	if type_icon:
		type_icon.text = icon_text

func set_zone_id(zone_id: String) -> void:
	set_meta("zone_id", zone_id)

func get_zone_id() -> String:
	return str(get_meta("zone_id", "PILE"))

func get_item_id() -> String:
	return item_id

func _on_mouse_entered() -> void:
	if glow_overlay:
		glow_overlay.visible = true

func _on_mouse_exited() -> void:
	if glow_overlay and drag_hint and not drag_hint.visible:
		glow_overlay.visible = false

func _get_drag_data(_at_position: Vector2) -> Variant:
	var from_zone: String = get_zone_id()
	_drag_from_zone = from_zone
	drag_started.emit(item_id, from_zone)

	# Show drag hint
	if drag_hint:
		drag_hint.visible = true

	var data: Dictionary = {
		"kind": "RESUS_PART",
		"item_id": item_id,
		"label": item_label,
		"node_path": str(get_path()),
		"from_zone": from_zone
	}

	var preview: Button = duplicate() as Button
	preview.modulate.a = 0.9
	preview.modulate.v = 1.2  # Slight brightness boost
	var holder: Control = Control.new()
	holder.add_child(preview)
	preview.position = -0.5 * preview.size
	set_drag_preview(holder)

	return data

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and not is_drag_successful():
		drag_cancelled.emit(item_id, _drag_from_zone)
		if drag_hint:
			drag_hint.visible = false
