extends Control

const LEVELS_PATH := "res://data/clues_levels.json"
const CONFIG_CARD_SCENE := preload("res://scenes/ui/ConfigCard.tscn")
const ResusData := preload("res://scripts/case_01/ResusData.gd")
const ResusScoring := preload("res://scripts/case_01/ResusScoring.gd")

const COLOR_OK := Color(0.42, 0.95, 0.55, 1.0)
const COLOR_WARN := Color(1.0, 0.78, 0.25, 1.0)
const COLOR_ERR := Color(1.0, 0.45, 0.45, 1.0)

var stage_b_data: Dictionary = {}
var options_by_id: Dictionary = {}
var option_cards_by_id: Dictionary = {}

var selected_option_id: String = ""
var trace: Array = []
var stage_started_ms: int = 0
var time_to_first_select_ms: int = -1
var selection_count: int = 0
var attempt_index: int = 0
var input_locked: bool = false

@onready var title_label: Label = $SafeArea/MainVBox/Header/TitleLabel
@onready var stage_label: Label = $SafeArea/MainVBox/Header/StageLabel
@onready var stability_bar: ProgressBar = $SafeArea/MainVBox/Header/StabilityBar
@onready var btn_back: Button = $SafeArea/MainVBox/Header/BtnBack

@onready var context_label: Label = $SafeArea/MainVBox/ContextCard/ContextVBox/ContextLabel
@onready var budget_label: Label = $SafeArea/MainVBox/ContextCard/ContextVBox/BudgetRow/BudgetValue

@onready var options_vbox: VBoxContainer = $SafeArea/MainVBox/OptionsCard/Scroll/OptionsVBox

@onready var diagnostic_card: PanelContainer = $SafeArea/MainVBox/DiagnosticCard
@onready var diag_headline: Label = $SafeArea/MainVBox/DiagnosticCard/DiagnosticVBox/DiagHeadline
@onready var diag_body: RichTextLabel = $SafeArea/MainVBox/DiagnosticCard/DiagnosticVBox/DiagBody
@onready var diag_hint: Label = $SafeArea/MainVBox/DiagnosticCard/DiagnosticVBox/DiagHint

@onready var status_label: Label = $SafeArea/MainVBox/BottomBar/StatusLabel
@onready var btn_reset: Button = $SafeArea/MainVBox/BottomBar/BtnReset
@onready var btn_confirm: Button = $SafeArea/MainVBox/BottomBar/BtnConfirm

func _ready() -> void:
	if not GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.connect(_on_stability_changed)
	btn_back.pressed.connect(_on_back_pressed)
	btn_reset.pressed.connect(_on_reset_pressed)
	btn_confirm.pressed.connect(_on_confirm_pressed)

	stage_b_data = ResusData.load_stage_b(LEVELS_PATH)
	if stage_b_data.is_empty():
		_show_error("Stage B data is invalid. Returning to menu.")
		return

	_setup_ui()
	_begin_attempt()

func _setup_ui() -> void:
	title_label.text = "CASE #1: DIGITAL RESUSCITATION"
	stage_label.text = "STAGE B"
	btn_reset.text = "RESET"
	btn_confirm.text = "CONFIRM"

	context_label.text = str(stage_b_data.get("context", ""))
	budget_label.text = "%d$" % int(stage_b_data.get("budget", 0))
	_update_stability_ui()
	_build_option_cards()

func _build_option_cards() -> void:
	for child in options_vbox.get_children():
		child.queue_free()
	options_by_id.clear()
	option_cards_by_id.clear()

	var budget: int = int(stage_b_data.get("budget", 0))
	var options: Array = stage_b_data.get("options", []) as Array
	for option_v in options:
		if typeof(option_v) != TYPE_DICTIONARY:
			continue
		var option_data: Dictionary = option_v as Dictionary
		var option_id: String = str(option_data.get("option_id", ""))
		if option_id == "":
			continue
		options_by_id[option_id] = option_data
		var card_node: Node = CONFIG_CARD_SCENE.instantiate()
		if not (card_node is PanelContainer):
			continue
		var card: PanelContainer = card_node as PanelContainer
		options_vbox.add_child(card)
		if card.has_method("setup"):
			card.call("setup", option_data, budget)
		if card.has_signal("selected"):
			card.connect("selected", Callable(self, "_on_option_selected"))
		option_cards_by_id[option_id] = card

func _begin_attempt() -> void:
	selected_option_id = ""
	trace.clear()
	selection_count = 0
	time_to_first_select_ms = -1
	stage_started_ms = Time.get_ticks_msec()
	input_locked = false
	btn_confirm.disabled = true
	diagnostic_card.visible = false
	status_label.text = "Select a configuration and press CONFIRM."
	status_label.modulate = COLOR_WARN
	_update_selection_visuals()
	_set_option_lock_state(false)

func _on_option_selected(option_id: String) -> void:
	if input_locked:
		return
	selected_option_id = option_id
	selection_count += 1
	if time_to_first_select_ms < 0:
		time_to_first_select_ms = Time.get_ticks_msec() - stage_started_ms
	_log_event("OPTION_SELECTED", {
		"option_id": option_id,
		"selection_index": selection_count
	})
	_update_selection_visuals()
	btn_confirm.disabled = false
	status_label.text = "Selected: %s" % option_id
	status_label.modulate = COLOR_WARN
	if has_node("/root/AudioManager"):
		AudioManager.play("click")

func _update_selection_visuals() -> void:
	for option_id_v in option_cards_by_id.keys():
		var option_id: String = str(option_id_v)
		var card_v: Variant = option_cards_by_id[option_id]
		if card_v == null:
			continue
		if card_v.has_method("set_selected_state"):
			card_v.call("set_selected_state", option_id == selected_option_id)

func _set_option_lock_state(locked: bool) -> void:
	for card_v in option_cards_by_id.values():
		if card_v == null:
			continue
		if card_v.has_method("set_locked"):
			card_v.call("set_locked", locked)

func _on_confirm_pressed() -> void:
	if input_locked:
		return
	_log_event("CONFIRM_PRESSED", {
		"option_id": selected_option_id,
		"has_selection": selected_option_id != ""
	})

	var snapshot: Dictionary = {"selected_option_id": selected_option_id}
	var result: Dictionary = ResusScoring.calculate_stage_b_result(stage_b_data, snapshot)
	_register_trial(result)
	_show_diagnostic(result)
	_update_stability_ui()
	attempt_index += 1

	input_locked = true
	_set_option_lock_state(true)
	btn_confirm.disabled = true

	if bool(result.get("is_correct", false)):
		if has_node("/root/AudioManager"):
			AudioManager.play("relay")
	else:
		if has_node("/root/AudioManager"):
			AudioManager.play("error")

func _on_reset_pressed() -> void:
	_log_event("RESET_PRESSED", {"prev_option_id": selected_option_id})
	if input_locked:
		_begin_attempt()
		return
	selected_option_id = ""
	_update_selection_visuals()
	diagnostic_card.visible = false
	btn_confirm.disabled = true
	status_label.text = "Selection cleared."
	status_label.modulate = COLOR_WARN
	if has_node("/root/AudioManager"):
		AudioManager.play("click")

func _register_trial(result: Dictionary) -> void:
	var elapsed_ms: int = Time.get_ticks_msec() - stage_started_ms
	var payload: Dictionary = {
		"quest_id": "CASE_01_DIGITAL_RESUS",
		"stage": "B",
		"format": "SINGLE_CHOICE_CONTEXT",
		"level_id": str(stage_b_data.get("id", "CASE01_B_01")),
		"match_key": "CASE01_B_%d" % attempt_index,
		"context": str(stage_b_data.get("context", "")),
		"budget": int(stage_b_data.get("budget", 0)),
		"selected_option_id": selected_option_id,
		"selection_count": selection_count,
		"time_to_first_select_ms": max(-1, time_to_first_select_ms),
		"elapsed_ms": elapsed_ms,
		"points": int(result.get("points", 0)),
		"max_points": int(result.get("max_points", 2)),
		"is_correct": bool(result.get("is_correct", false)),
		"is_fit": bool(result.get("is_fit", false)),
		"stability_delta": int(result.get("stability_delta", 0)),
		"verdict_code": str(result.get("verdict_code", "WRONG")),
		"error_code": str(result.get("error_code", "UNKNOWN")),
		"diagnostic_headline": str(result.get("diagnostic_headline", "")),
		"diagnostic_details": (result.get("diagnostic_details", []) as Array).duplicate(),
		"trace": trace.duplicate(true)
	}
	GlobalMetrics.register_trial(payload)

func _show_diagnostic(result: Dictionary) -> void:
	diagnostic_card.visible = true
	var is_correct: bool = bool(result.get("is_correct", false))
	var headline: String = str(result.get("diagnostic_headline", ""))
	var details: Array = result.get("diagnostic_details", []) as Array

	diag_headline.text = headline
	diag_headline.modulate = COLOR_OK if is_correct else COLOR_ERR

	var detail_lines: Array[String] = []
	for detail_v in details:
		detail_lines.append("? %s" % str(detail_v))
	diag_body.text = "\n".join(detail_lines)

	var hint_text: String = ""
	var budget: int = int(stage_b_data.get("budget", 0))
	var option_data: Dictionary = options_by_id.get(selected_option_id, {}) as Dictionary
	var total_price: int = int(option_data.get("total_price", 0))
	if total_price > budget:
		hint_text = "Budget exceeded: +%d$" % (total_price - budget)
	elif selected_option_id == "":
		hint_text = "Select one option and try again."
	else:
		hint_text = "Press RESET to choose another option."
	diag_hint.text = hint_text
	diag_hint.modulate = COLOR_WARN

	status_label.text = "Decision locked. Press RESET to start a new attempt."
	status_label.modulate = COLOR_OK if is_correct else COLOR_WARN

func _log_event(event_name: String, data: Dictionary = {}) -> void:
	trace.append({
		"t_ms": Time.get_ticks_msec() - stage_started_ms,
		"event": event_name,
		"data": data.duplicate(true)
	})

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
