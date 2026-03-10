extends PanelContainer

signal all_rounds_complete

var _level_data: Dictionary = {}
var _controller: Node = null
var _rounds: Array = []
var _answers: Array = []
var _round_index: int = 0
var _selected_by_round: Dictionary = {}
var _awaiting_next: bool = false

@onready var progress_label: Label = $VBox/ProgressLabel
@onready var visual_host: Control = $VBox/VisualHost
@onready var topology_visual: Control = $VBox/VisualHost/TopologyVisual
@onready var prompt_label: Label = $VBox/PromptLabel
@onready var options_grid: GridContainer = $VBox/OptionsGrid
@onready var btn_next_round: Button = $VBox/BtnNextRound
@onready var explain_label: RichTextLabel = $VBox/ExplainLabel

func _ready() -> void:
	btn_next_round.pressed.connect(_on_next_round_pressed)
	btn_next_round.visible = false

func setup(level_data: Dictionary, controller: Node) -> void:
	_level_data = level_data.duplicate(true)
	_controller = controller
	_rounds = _level_data.get("rounds", []) as Array
	_round_index = 0
	_answers.clear()
	_selected_by_round.clear()
	_awaiting_next = false
	btn_next_round.visible = false
	explain_label.text = ""
	_render_round()

func apply_i18n() -> void:
	_render_round()

func reset() -> void:
	_round_index = 0
	_answers.clear()
	_selected_by_round.clear()
	_awaiting_next = false
	btn_next_round.visible = false
	explain_label.text = ""
	_render_round()

func get_answers() -> Variant:
	return _answers.duplicate(true)

func show_result(result: Dictionary) -> void:
	var verdict: String = str(result.get("verdict_code", ""))
	explain_label.text = "[b]%s[/b]\n%s/%s" % [verdict, int(result.get("correct_count", 0)), int(result.get("total", 0))]

func _render_round() -> void:
	for child in options_grid.get_children():
		child.queue_free()
	btn_next_round.visible = false
	_awaiting_next = false

	if _rounds.is_empty():
		progress_label.text = "0/0"
		prompt_label.text = ""
		explain_label.text = ""
		if topology_visual != null:
			topology_visual.visible = false
		return

	var idx: int = clampi(_round_index, 0, _rounds.size() - 1)
	var round_data: Dictionary = _rounds[idx] as Dictionary
	progress_label.text = "%d/%d" % [idx + 1, _rounds.size()]
	prompt_label.text = _resolve_round_text(round_data, "prompt")

	if topology_visual != null and round_data.has("topology_visual"):
		topology_visual.visible = true
		topology_visual.call("set_topology", str(round_data.get("topology_visual", "")))
	elif topology_visual != null:
		topology_visual.visible = false

	var selected_id: String = str(_selected_by_round.get(idx, ""))
	for option_v in round_data.get("options", []) as Array:
		if typeof(option_v) != TYPE_DICTIONARY:
			continue
		var option_data: Dictionary = option_v as Dictionary
		var option_id: String = str(option_data.get("id", ""))
		var button: Button = Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 52)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.text = _resolve_option_label(option_data)
		button.pressed.connect(_on_option_pressed.bind(option_id))
		button.modulate = Color(1.08, 1.08, 1.08, 1.0) if option_id == selected_id else Color(1, 1, 1, 1)
		options_grid.add_child(button)

func _on_option_pressed(option_id: String) -> void:
	if _rounds.is_empty() or _awaiting_next:
		return

	var idx: int = clampi(_round_index, 0, _rounds.size() - 1)
	_selected_by_round[idx] = option_id
	if _answers.size() <= idx:
		_answers.resize(idx + 1)
	_answers[idx] = option_id

	var round_data: Dictionary = _rounds[idx] as Dictionary
	var is_correct: bool = _check_answer(round_data, option_id)
	_highlight_options(option_id, is_correct, round_data)
	explain_label.text = _resolve_round_explain(round_data)

	_awaiting_next = true
	_set_options_disabled(true)
	btn_next_round.text = I18n.tr_key("resus.btn.next_round", {"default": "NEXT ->"}) if _round_index < _rounds.size() - 1 else I18n.tr_key("resus.btn.finish_quiz", {"default": "FINISH"})
	btn_next_round.visible = true

func _on_next_round_pressed() -> void:
	if not _awaiting_next:
		return

	_awaiting_next = false
	btn_next_round.visible = false
	explain_label.text = ""

	if _round_index < _rounds.size() - 1:
		_round_index += 1
		_render_round()
	else:
		all_rounds_complete.emit()

func _check_answer(round_data: Dictionary, option_id: String) -> bool:
	for option_v in round_data.get("options", []) as Array:
		if typeof(option_v) != TYPE_DICTIONARY:
			continue
		var option_data: Dictionary = option_v as Dictionary
		if str(option_data.get("id", "")).strip_edges() == option_id:
			return bool(option_data.get("is_correct", false))
	return false

func _highlight_options(selected_id: String, is_correct: bool, round_data: Dictionary) -> void:
	var options: Array = round_data.get("options", []) as Array
	var idx: int = 0
	for child in options_grid.get_children():
		if not (child is Button):
			continue
		var button: Button = child as Button
		button.disabled = true
		button.modulate = Color(1, 1, 1, 1)
		if idx < options.size() and typeof(options[idx]) == TYPE_DICTIONARY:
			var option_data: Dictionary = options[idx] as Dictionary
			var option_id: String = str(option_data.get("id", ""))
			var option_correct: bool = bool(option_data.get("is_correct", false))
			if option_id == selected_id:
				button.modulate = Color(0.7, 1.0, 0.7, 1.0) if is_correct else Color(1.0, 0.7, 0.7, 1.0)
			elif option_correct and not is_correct:
				button.modulate = Color(0.8, 1.0, 0.8, 0.65)
		idx += 1

func _set_options_disabled(disabled: bool) -> void:
	for child in options_grid.get_children():
		if child is Button:
			(child as Button).disabled = disabled

func _resolve_round_text(round_data: Dictionary, field: String) -> String:
	var key: String = str(round_data.get("%s_key" % field, ""))
	var fallback: String = str(round_data.get(field, ""))
	if key != "":
		return I18n.tr_key(key, {"default": fallback})
	return fallback

func _resolve_option_label(option_data: Dictionary) -> String:
	var key: String = str(option_data.get("label_key", ""))
	var fallback: String = str(option_data.get("label", option_data.get("id", "")))
	if key != "":
		return I18n.tr_key(key, {"default": fallback})
	return fallback

func _resolve_round_explain(round_data: Dictionary) -> String:
	var key: String = str(round_data.get("explain_key", ""))
	var fallback: String = str(round_data.get("explain", ""))
	if key != "":
		return I18n.tr_key(key, {"default": fallback})
	return fallback
