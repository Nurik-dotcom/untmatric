extends PanelContainer
class_name NetworkLockIndicator

var label_state: Label = null

func _ready() -> void:
	_ensure_label()
	set_locked()

func set_locked() -> void:
	_apply_state("LOCKED", Color(1.0, 0.58, 0.42, 1.0), Color(0.2, 0.08, 0.08, 0.9))

func set_ready() -> void:
	_apply_state("MASK PLACED", Color(0.95, 0.88, 0.55, 1.0), Color(0.18, 0.16, 0.08, 0.9))

func set_applied() -> void:
	_apply_state("AND APPLIED", Color(0.62, 0.95, 1.0, 1.0), Color(0.08, 0.14, 0.18, 0.9))

func set_open() -> void:
	_apply_state("OPEN", Color(0.4, 1.0, 0.6, 1.0), Color(0.08, 0.18, 0.1, 0.9))

func set_error() -> void:
	_apply_state("REJECTED", Color(1.0, 0.4, 0.4, 1.0), Color(0.22, 0.05, 0.05, 0.9))

func _apply_state(text_value: String, font_color: Color, bg_color: Color) -> void:
	_ensure_label()
	if label_state != null:
		label_state.text = text_value
		label_state.add_theme_color_override("font_color", font_color)
	self_modulate = bg_color

func _ensure_label() -> void:
	if label_state == null:
		label_state = get_node_or_null("Margin/LabelState") as Label
