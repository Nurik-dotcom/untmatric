extends PanelContainer
class_name SubnetBitCell

var label_value: Label = null
var bit_value: int = -1
var highlighted: bool = false

func _ready() -> void:
	_ensure_label()
	_refresh()

func set_bit(value: int) -> void:
	bit_value = clampi(value, 0, 1)
	_refresh()

func set_empty() -> void:
	bit_value = -1
	_refresh()

func set_highlight(active: bool) -> void:
	highlighted = active
	_refresh()

func pulse(color: Color, duration_sec: float = 0.12) -> void:
	modulate = color
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), duration_sec)

func _ensure_label() -> void:
	if label_value == null:
		label_value = get_node_or_null("LabelValue") as Label

func _refresh() -> void:
	_ensure_label()
	if label_value == null:
		return

	if bit_value < 0:
		label_value.text = "-"
		label_value.modulate = Color(0.62, 0.64, 0.62, 1.0)
	elif bit_value == 0:
		label_value.text = "0"
		label_value.modulate = Color(0.78, 0.84, 0.8, 1.0)
	else:
		label_value.text = "1"
		label_value.modulate = Color(0.4, 1.0, 0.62, 1.0)

	if highlighted:
		self_modulate = Color(1.0, 1.0, 0.82, 1.0)
	else:
		self_modulate = Color(1.0, 1.0, 1.0, 1.0)
