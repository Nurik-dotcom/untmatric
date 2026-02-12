extends PanelContainer

signal block_dropped(block_data)

var required_type: String = "INT"
var current_block_data = null
var breathing_tween: Tween

@onready var lbl_hint = $Label

func _ready():
	_start_breathing()

func setup(type: String):
	required_type = type
	_reset_state()

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	# Ensure the data is a dictionary and has the right type
	if typeof(data) == TYPE_DICTIONARY and data.get("kind") == "CODE_BLOCK":
		return data.get("slot_type") == required_type
	return false

func _drop_data(at_position: Vector2, data: Variant) -> void:
	# Stop breathing
	if breathing_tween:
		breathing_tween.kill()

	current_block_data = data
	lbl_hint.text = str(data.get("label", "ERROR"))

	# Snapping Effect
	modulate = Color(1, 1, 1, 1) # Full opaque
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

	block_dropped.emit(data)

func _start_breathing():
	if breathing_tween:
		breathing_tween.kill()

	modulate = Color(1, 1, 1, 0.7)
	breathing_tween = create_tween().set_loops()
	breathing_tween.tween_property(self, "modulate:a", 1.0, 1.0)
	breathing_tween.tween_property(self, "modulate:a", 0.6, 1.0)

func _reset_state():
	current_block_data = null
	lbl_hint.text = "[SLOT]"
	_start_breathing()

func get_block_id():
	if current_block_data:
		return current_block_data.get("block_id")
	return null
