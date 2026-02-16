extends Control

const LEVELS_PATH := "res://data/clues_levels.json"
const ResusData := preload("res://scripts/case_01/ResusData.gd")
const ResusScoring := preload("res://scripts/case_01/ResusScoring.gd")

const COLOR_OK := Color(0.42, 0.95, 0.55, 1.0)
const COLOR_WARN := Color(1.0, 0.78, 0.25, 1.0)
const COLOR_ERR := Color(1.0, 0.45, 0.45, 1.0)

var stage_c_data: Dictionary = {}
var option_by_id: Dictionary = {}
var checkbox_by_id: Dictionary = {}

var selected: Dictionary = {}
var trace: Array = []
var stage_started_ms: int = 0
var toggle_count: int = 0
var time_to_first_toggle_ms: int = -1
var attempt_index: int = 0
var input_locked: bool = false
var suppress_toggle_events: bool = false

@onready var title_label: Label = $SafeArea/MainVBox/Header/TitleLabel
@onready var stage_label: Label = $SafeArea/MainVBox/Header/StageLabel
@onready var stability_bar: ProgressBar = $SafeArea/MainVBox/Header/StabilityBar
@onready var btn_back: Button = $SafeArea/MainVBox/Header/BtnBack

@onready var prompt_label: Label = $SafeArea/MainVBox/PromptCard/PromptLabel
@onready var options_vbox: VBoxContainer = $SafeArea/MainVBox/OptionsCard/Scroll/OptionsVBox

@onready var explanation_card: PanelContainer = $SafeArea/MainVBox/ExplanationCard
@onready var expl_headline: Label = $SafeArea/MainVBox/ExplanationCard/ExplVBox/ExplHeadline
@onready var expl_body: RichTextLabel = $SafeArea/MainVBox/ExplanationCard/ExplVBox/ExplBody

@onready var status_label: Label = $SafeArea/MainVBox/BottomBar/StatusLabel
@onready var btn_reset: Button = $SafeArea/MainVBox/BottomBar/BtnReset
@onready var btn_confirm: Button = $SafeArea/MainVBox/BottomBar/BtnConfirm

func _ready() -> void:
	if not GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.connect(_on_stability_changed)

	btn_back.pressed.connect(_on_back_pressed)
	btn_reset.pressed.connect(_on_reset_pressed)
	btn_confirm.pressed.connect(_on_confirm_pressed)

	stage_c_data = ResusData.load_stage_c(LEVELS_PATH)
	if stage_c_data.is_empty():
		_show_error("Stage C data is invalid. Returning to menu.")
		return

	_setup_ui()
	_begin_attempt()

func _setup_ui() -> void:
	title_label.text = "CASE #1: DIGITAL RESUSCITATION"
	stage_label.text = "STAGE C"
	btn_reset.text = "RESET"
	btn_confirm.text = "ANALYZE"
	prompt_label.text = str(stage_c_data.get("prompt", ""))
	_update_stability_ui()
	_build_option_rows()

func _build_option_rows() -> void:
	for child in options_vbox.get_children():
		child.queue_free()
	option_by_id.clear()
	checkbox_by_id.clear()

	var options: Array = stage_c_data.get("options", []) as Array
	for option_v in options:
		if typeof(option_v) != TYPE_DICTIONARY:
			continue
		var option_data: Dictionary = option_v as Dictionary
		var option_id: String = str(option_data.get("option_id", "")).strip_edges()
		if option_id == "":
			continue

		option_by_id[option_id] = option_data

		var row_panel: PanelContainer = PanelContainer.new()
		row_panel.custom_minimum_size = Vector2(0, 76)
		row_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		options_vbox.add_child(row_panel)

		var row_margin: MarginContainer = MarginContainer.new()
		row_margin.add_theme_constant_override("margin_left", 8)
		row_margin.add_theme_constant_override("margin_top", 6)
		row_margin.add_theme_constant_override("margin_right", 8)
		row_margin.add_theme_constant_override("margin_bottom", 6)
		row_panel.add_child(row_margin)

		var row_hbox: HBoxContainer = HBoxContainer.new()
		row_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row_hbox.add_theme_constant_override("separation", 10)
		row_margin.add_child(row_hbox)

		var checkbox: CheckBox = CheckBox.new()
		checkbox.custom_minimum_size = Vector2(0, 62)
		checkbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		checkbox.text = str(option_data.get("label", option_id))
		checkbox.toggled.connect(_on_option_toggled.bind(option_id))
		row_hbox.add_child(checkbox)

		checkbox_by_id[option_id] = checkbox

func _begin_attempt() -> void:
	selected.clear()
	trace.clear()
	toggle_count = 0
	time_to_first_toggle_ms = -1
	stage_started_ms = Time.get_ticks_msec()
	input_locked = false
	explanation_card.visible = false
	btn_confirm.disabled = false
	_set_options_enabled(true)
	_clear_selection_ui()
	status_label.text = "Selected: 0/5"
	status_label.modulate = COLOR_WARN

func _on_option_toggled(value: bool, option_id: String) -> void:
	if suppress_toggle_events:
		return
	if input_locked:
		return

	if value:
		selected[option_id] = true
	else:
		selected.erase(option_id)

	toggle_count += 1
	if time_to_first_toggle_ms < 0:
		time_to_first_toggle_ms = Time.get_ticks_msec() - stage_started_ms

	var selected_count: int = _collect_selected_ids().size()
	_log_event("TOGGLE_CHANGED", {
		"option_id": option_id,
		"value": value,
		"selected_count": selected_count
	})

	status_label.text = "Selected: %d/5" % selected_count
	status_label.modulate = COLOR_WARN
	_play_sfx("click")

func _on_confirm_pressed() -> void:
	if input_locked:
		return

	var selected_ids: Array[String] = _collect_selected_ids()
	_log_event("CONFIRM_PRESSED", {"selected_count": selected_ids.size()})

	var snapshot: Dictionary = {"selected": selected_ids}
	var result: Dictionary = ResusScoring.calculate_stage_c_result(stage_c_data, snapshot)
	_register_trial(result, selected_ids)
	_show_explanation(result)
	_update_stability_ui()

	attempt_index += 1
	input_locked = true
	_set_options_enabled(false)
	btn_confirm.disabled = true

	if bool(result.get("is_correct", false)):
		_play_sfx("relay")
	elif bool(result.get("is_fit", false)):
		_play_sfx("click")
	else:
		_play_sfx("error")

func _on_reset_pressed() -> void:
	_log_event("RESET_PRESSED", {"selected_before": _collect_selected_ids()})
	if input_locked:
		_begin_attempt()
		_play_sfx("click")
		return

	_clear_selection_ui()
	explanation_card.visible = false
	status_label.text = "Selected: 0/5"
	status_label.modulate = COLOR_WARN
	_play_sfx("click")

func _register_trial(result: Dictionary, selected_ids: Array[String]) -> void:
	var elapsed_ms: int = Time.get_ticks_msec() - stage_started_ms
	var payload: Dictionary = {
		"quest_id": "CASE_01_DIGITAL_RESUS",
		"stage": "C",
		"format": "MULTI_CHOICE",
		"level_id": str(stage_c_data.get("id", "CASE01_C_01")),
		"match_key": "CASE01_C_%d" % attempt_index,
		"prompt": str(stage_c_data.get("prompt", "")),
		"selected": selected_ids.duplicate(),
		"selected_count": int(result.get("selected_count", 0)),
		"correct_selected": int(result.get("correct_selected", 0)),
		"wrong_selected": int(result.get("wrong_selected", 0)),
		"points": int(result.get("points", 0)),
		"max_points": int(result.get("max_points", 2)),
		"is_correct": bool(result.get("is_correct", false)),
		"is_fit": bool(result.get("is_fit", false)),
		"stability_delta": int(result.get("stability_delta", 0)),
		"verdict_code": str(result.get("verdict_code", "FAIL")),
		"feedback_headline": str(result.get("feedback_headline", "")),
		"feedback_details": (result.get("feedback_details", []) as Array).duplicate(),
		"explain_selected": (result.get("explain_selected", []) as Array).duplicate(true),
		"toggle_count": toggle_count,
		"time_to_first_toggle_ms": max(-1, time_to_first_toggle_ms),
		"elapsed_ms": elapsed_ms,
		"trace": trace.duplicate(true)
	}
	GlobalMetrics.register_trial(payload)

func _show_explanation(result: Dictionary) -> void:
	explanation_card.visible = true

	var verdict_code: String = str(result.get("verdict_code", "FAIL"))
	expl_headline.text = str(result.get("feedback_headline", verdict_code))
	if verdict_code == "PERFECT":
		expl_headline.modulate = COLOR_OK
	elif verdict_code == "GOOD" or verdict_code == "NOISY":
		expl_headline.modulate = COLOR_WARN
	else:
		expl_headline.modulate = COLOR_ERR

	var lines: Array[String] = []
	var details: Array = result.get("feedback_details", []) as Array
	for detail_v in details:
		lines.append("- %s" % str(detail_v))

	var explains: Array = result.get("explain_selected", []) as Array
	if not explains.is_empty():
		lines.append("")
		lines.append("Selected components:")
		for item_v in explains:
			if typeof(item_v) != TYPE_DICTIONARY:
				continue
			var explain_item: Dictionary = item_v as Dictionary
			var marker: String = "[OK]" if bool(explain_item.get("is_correct", false)) else "[EXTRA]"
			lines.append("%s %s: %s" % [
				marker,
				str(explain_item.get("label", explain_item.get("option_id", "?"))),
				str(explain_item.get("why", ""))
			])

	expl_body.text = "\n".join(lines)
	status_label.text = "Result: %s | Selected: %d/5" % [verdict_code, int(result.get("selected_count", 0))]
	status_label.modulate = expl_headline.modulate

func _clear_selection_ui() -> void:
	suppress_toggle_events = true
	selected.clear()
	for checkbox_v in checkbox_by_id.values():
		if not (checkbox_v is CheckBox):
			continue
		var checkbox: CheckBox = checkbox_v as CheckBox
		checkbox.button_pressed = false
	suppress_toggle_events = false

func _set_options_enabled(enabled: bool) -> void:
	for checkbox_v in checkbox_by_id.values():
		if not (checkbox_v is CheckBox):
			continue
		var checkbox: CheckBox = checkbox_v as CheckBox
		checkbox.disabled = not enabled

func _collect_selected_ids() -> Array[String]:
	var selected_ids: Array[String] = []
	for option_id_v in selected.keys():
		var option_id: String = str(option_id_v)
		if bool(selected.get(option_id, false)):
			selected_ids.append(option_id)
	selected_ids.sort()
	return selected_ids

func _log_event(event_name: String, data: Dictionary = {}) -> void:
	trace.append({
		"t_ms": Time.get_ticks_msec() - stage_started_ms,
		"event": event_name,
		"data": data.duplicate(true)
	})

func _play_sfx(event_name: String) -> void:
	if has_node("/root/AudioManager"):
		AudioManager.play(event_name)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _on_stability_changed(_new_value: float, _delta: float) -> void:
	_update_stability_ui()

func _update_stability_ui() -> void:
	stability_bar.value = GlobalMetrics.stability

func _show_error(message: String) -> void:
	status_label.text = message
	status_label.modulate = COLOR_ERR
	btn_confirm.disabled = true
	btn_reset.disabled = true
	await get_tree().create_timer(1.2).timeout
	_on_back_pressed()
