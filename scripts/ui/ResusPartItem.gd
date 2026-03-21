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
var _touch_selected: bool = false
var _hovered: bool = false

const COLOR_INPUT := Color(0.13, 0.59, 0.95, 1.0)
const COLOR_OUTPUT := Color(0.3, 0.69, 0.31, 1.0)
const COLOR_MEMORY := Color(0.61, 0.15, 0.69, 1.0)
const COLOR_UNKNOWN := Color(0.5, 0.5, 0.5, 1.0)
const COLOR_NEUTRAL := Color(0.45, 0.55, 0.65, 1.0)

func _ready() -> void:
	_update_visuals()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_sync_glow_visibility()

func setup(item_data: Dictionary) -> void:
	item_id = str(item_data.get("item_id", ""))
	_apply_item_label(item_data)
	correct_bucket_id = str(item_data.get("correct_bucket_id", "")).to_upper()
	text = item_label
	custom_minimum_size = Vector2(0, 76)
	set_meta("item_id", item_id)
	set_meta("zone_id", "PILE")
	_update_visuals()

func refresh_localized_text(item_data: Dictionary) -> void:
	_apply_item_label(item_data)
	text = item_label

func _apply_item_label(item_data: Dictionary) -> void:
	var label_key: String = str(item_data.get("label_key", ""))
	var label_fallback: String = str(item_data.get("label", ""))
	if label_key != "":
		item_label = I18n.tr_key(label_key, {"default": label_fallback})
	else:
		item_label = label_fallback

func _update_visuals() -> void:
	# Neutral style before confirmation: no category hints via color/icon.
	var color := COLOR_NEUTRAL
	var icon_text := "?"
	if type_indicator:
		type_indicator.color = color
	if glow_overlay:
		glow_overlay.color = Color(color.r, color.g, color.b, 0.2)
	if type_icon:
		type_icon.text = icon_text
	_sync_glow_visibility()

func reveal_correct_color() -> void:
	var color := COLOR_UNKNOWN
	match correct_bucket_id:
		"INPUT":
			color = COLOR_INPUT
		"OUTPUT":
			color = COLOR_OUTPUT
		"MEMORY":
			color = COLOR_MEMORY
	if type_indicator:
		type_indicator.color = color
	if glow_overlay:
		glow_overlay.color = Color(color.r, color.g, color.b, 0.3)

func set_zone_id(zone_id: String) -> void:
	set_meta("zone_id", zone_id)

func get_zone_id() -> String:
	return str(get_meta("zone_id", "PILE"))

func get_item_id() -> String:
	return item_id

func set_touch_selected(selected: bool) -> void:
	_touch_selected = selected
	_sync_glow_visibility()

func _on_mouse_entered() -> void:
	_hovered = true
	_sync_glow_visibility()

func _on_mouse_exited() -> void:
	_hovered = false
	_sync_glow_visibility()

func _get_drag_data(_at_position: Vector2) -> Variant:
	# Touch/web flow uses popup placement in the parent controller.
	if OS.has_feature("mobile") or OS.has_feature("web"):
		return null

	var from_zone: String = get_zone_id()
	_drag_from_zone = from_zone
	drag_started.emit(item_id, from_zone)

	if drag_hint:
		drag_hint.visible = true
	_sync_glow_visibility()

	var data: Dictionary = {
		"kind": "RESUS_PART",
		"item_id": item_id,
		"label": item_label,
		"node_path": str(get_path()),
		"from_zone": from_zone
	}

	var preview: Button = duplicate() as Button
	preview.modulate.a = 0.9
	preview.modulate.v = 1.2
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
		_sync_glow_visibility()

func _sync_glow_visibility() -> void:
	if glow_overlay == null:
		return
	var drag_active: bool = drag_hint != null and drag_hint.visible
	glow_overlay.visible = _touch_selected or _hovered or drag_active
