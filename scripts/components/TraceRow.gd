extends PanelContainer

const COLOR_TEXT_REVEALED := Color(0.78, 0.78, 0.76)
const COLOR_TEXT_ACTIVE := Color(0.96, 0.96, 0.93)
const COLOR_TEXT_COMPLETED := Color(0.68, 0.68, 0.66)

@onready var step_label: Label = $Padding/Row/StepLabel
@onready var context_label: Label = $Padding/Row/ContextLabel
@onready var before_label: Label = $Padding/Row/BeforeLabel
@onready var arrow_label: Label = $Padding/Row/ArrowLabel
@onready var after_label: Label = $Padding/Row/AfterLabel
@onready var event_label: Label = $Padding/Row/EventLabel

var _step_data: Dictionary = {}

func _ready() -> void:
	if not _step_data.is_empty():
		_apply_step_data()

func set_step_data(data: Dictionary) -> void:
	_step_data = data.duplicate(true)
	if step_label == null:
		return
	_apply_step_data()

func _apply_step_data() -> void:
	var step_index: int = int(_step_data.get("step", 0))
	var i_value: String = str(_step_data.get("i", "?"))
	var cond_text: String = str(_step_data.get("cond", "loop"))
	var s_before: String = str(_step_data.get("s_before", "?"))
	var s_after: String = str(_step_data.get("s_after", "?"))
	var event_text: String = str(_step_data.get("event", "")).strip_edges()
	var line_ref: int = int(_step_data.get("line_ref", -1))

	step_label.text = "Шаг %d" % max(1, step_index)
	context_label.text = "i=%s | %s" % [i_value, cond_text]
	before_label.text = "s:%s" % s_before
	arrow_label.text = "->"
	after_label.text = "%s" % s_after

	if line_ref > 0:
		event_text = ("L%d" % line_ref) if event_text.is_empty() else "%s | L%d" % [event_text, line_ref]
	event_label.text = event_text
	event_label.visible = not event_text.is_empty()

func set_row_mode(mode: String) -> void:
	match mode:
		"hidden":
			visible = false
		"active":
			visible = true
			_apply_style(Color(0.20, 0.20, 0.18, 0.78), Color(0.95, 0.90, 0.62, 0.95), COLOR_TEXT_ACTIVE)
		"completed":
			visible = true
			_apply_style(Color(0.12, 0.12, 0.11, 0.55), Color(0.34, 0.34, 0.30, 0.78), COLOR_TEXT_COMPLETED)
		_:
			visible = true
			_apply_style(Color(0.10, 0.10, 0.10, 0.40), Color(0.30, 0.30, 0.28, 0.62), COLOR_TEXT_REVEALED)

func _apply_style(fill: Color, border: Color, text_color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = border
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	add_theme_stylebox_override("panel", style)

	for label in [step_label, context_label, before_label, arrow_label, after_label, event_label]:
		if label is Label:
			(label as Label).add_theme_color_override("font_color", text_color)
