extends Button

signal item_tapped(item_id: String)
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
var _touch_start_pos: Vector2 = Vector2.ZERO
var _touch_start_time: int = 0
var _touch_tracking: bool = false

const TAP_MAX_DISTANCE: float = 20.0
const TAP_MAX_TIME_MS: int = 500

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
	focus_mode = Control.FOCUS_NONE
	set_process_input(true)

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

func _input(event: InputEvent) -> void:
	if not visible or not is_visible_in_tree():
		return
	if disabled:
		return

	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if touch.pressed:
			var local_pos: Vector2 = _local_event_position(event)
			if Rect2(Vector2.ZERO, size).has_point(local_pos):
				_touch_start_pos = touch.position
				_touch_start_time = Time.get_ticks_msec()
				_touch_tracking = true
		elif _touch_tracking:
			_touch_tracking = false
			var dist: float = touch.position.distance_to(_touch_start_pos)
			var elapsed: int = Time.get_ticks_msec() - _touch_start_time
			if dist < TAP_MAX_DISTANCE and elapsed < TAP_MAX_TIME_MS:
				var local_pos: Vector2 = _local_event_position(event)
				if Rect2(Vector2.ZERO, size).has_point(local_pos):
					item_tapped.emit(item_id)
		return

	if event is InputEventScreenDrag and _touch_tracking:
		var drag: InputEventScreenDrag = event as InputEventScreenDrag
		if drag.position.distance_to(_touch_start_pos) > TAP_MAX_DISTANCE:
			_touch_tracking = false

func _local_event_position(event: InputEvent) -> Vector2:
	var local_event: InputEvent = make_input_local(event)
	if local_event is InputEventScreenTouch:
		return (local_event as InputEventScreenTouch).position
	if local_event is InputEventScreenDrag:
		return (local_event as InputEventScreenDrag).position
	if local_event is InputEventMouseButton:
		return (local_event as InputEventMouseButton).position
	return Vector2(-100000.0, -100000.0)

func _pressed() -> void:
	if OS.has_feature("mobile") or OS.has_feature("web"):
		return
	item_tapped.emit(item_id)

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		if drag_hint:
			drag_hint.visible = false
		_sync_glow_visibility()

func _sync_glow_visibility() -> void:
	if glow_overlay == null:
		return
	glow_overlay.visible = _touch_selected or _hovered
