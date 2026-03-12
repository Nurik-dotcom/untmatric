extends PanelContainer

signal block_dropped(block_data)
signal slot_tapped

var required_type: String = "INT"
var current_block_data: Dictionary = {}
var has_block: bool = false
var last_prev_block_id: Variant = null
var breathing_tween: Tween

@onready var lbl_hint: Label = $Label

func _ready() -> void:
	_start_breathing()

func setup(slot_type: String) -> void:
	required_type = slot_type
	_reset_state()

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return _is_valid_block_payload(data)

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	place_block(data)

func place_block(data: Variant) -> bool:
	if not _is_valid_block_payload(data):
		return false
	var payload: Dictionary = data
	_accept_block_data(payload)
	return true

func _accept_block_data(data: Dictionary) -> void:
	if breathing_tween:
		breathing_tween.kill()

	last_prev_block_id = get_block_id()
	current_block_data = data.duplicate(true)
	has_block = true
	lbl_hint.text = str(data.get("label", "[BLOCK]"))

	modulate = Color(1, 1, 1, 1)
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.08)
	tween.tween_property(self, "scale", Vector2.ONE, 0.08)

	block_dropped.emit(data.duplicate(true))

func _is_valid_block_payload(data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	var payload: Dictionary = data
	if str(payload.get("kind", "")) != "CODE_BLOCK":
		return false
	return str(payload.get("slot_type", "")) == required_type

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			slot_tapped.emit()
	elif event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed:
			slot_tapped.emit()

func _start_breathing() -> void:
	if breathing_tween:
		breathing_tween.kill()

	modulate = Color(1, 1, 1, 0.75)
	breathing_tween = create_tween().set_loops()
	breathing_tween.tween_property(self, "modulate:a", 1.0, 0.9)
	breathing_tween.tween_property(self, "modulate:a", 0.6, 0.9)

func _reset_state() -> void:
	current_block_data.clear()
	has_block = false
	last_prev_block_id = null
	lbl_hint.text = "[SLOT]"
	_start_breathing()

func reset() -> void:
	_reset_state()

func get_block_id() -> Variant:
	if has_block:
		return current_block_data.get("block_id", null)
	return null

func get_block_data() -> Variant:
	if not has_block:
		return null
	return current_block_data.duplicate(true)

func get_last_prev_block_id() -> Variant:
	return last_prev_block_id
