extends Control

const LEVELS_PATH: String = "res://data/clues_levels.json"
const FLOW_SCENE_PATH: String = "res://scenes/case_01/Case01Flow.tscn"
const QUEST_SELECT_SCENE: String = "res://scenes/QuestSelect.tscn"
const CASE_ID: String = "CASE_01_DIGITAL_RESUS"
const STAGE_ID: String = "C"
const NET_ITEM_SCENE: PackedScene = preload("res://scenes/ui/NetItem.tscn")
const ATTACK_RENDERER_SCENE: PackedScene = preload("res://scenes/case_01/renderers/AttackMatchRenderer.tscn")
const SUBNET_RENDERER_SCENE: PackedScene = preload("res://scenes/case_01/renderers/SubnetRenderer.tscn")
const ResusData = preload("res://scripts/case_01/ResusData.gd")
const ResusScoring = preload("res://scripts/case_01/ResusScoring.gd")
const TrialV2 = preload("res://scripts/TrialV2.gd")
const PHONE_LANDSCAPE_MAX_HEIGHT := 740.0
const PHONE_PORTRAIT_MAX_WIDTH := 520.0

const COLOR_OK: Color = Color(0.9, 0.93, 0.98, 1.0)
const COLOR_WARN: Color = Color(0.98, 0.8, 0.52, 1.0)
const COLOR_ERR: Color = Color(0.95, 0.36, 0.38, 1.0)

var levels: Array = []
var current_level_index: int = 0
var stage_c_data: Dictionary = {}
var option_by_id: Dictionary = {}
var correct_set: Dictionary = {}
var option_order: Array[String] = []

var item_nodes_by_option: Dictionary = {}
var slot_item_by_index: Dictionary = {}
var slots: Array[String] = ["", "", ""]

var trace: Array = []
var stage_started_ms: int = 0
var attempt_index: int = 0
var trial_seq: int = 0
var task_session: Dictionary = {}
var format_id: String = ""
var drag_count: int = 0
var slot_change_count: int = 0
var unique_used_set: Dictionary = {}
var time_to_first_action_ms: int = -1
var input_locked: bool = false
var _last_result: Dictionary = {}
var _last_payload: Dictionary = {}
var _renderer: Node = null
var _renderer_rounds_complete: bool = false

var selection_change_count: int = 0
var drag_count_local: int = 0
var drop_count_local: int = 0
var confirm_attempt_count: int = 0
var reset_count_local: int = 0
var inspect_open_count: int = 0
var hint_open_count: int = 0

var changed_after_fail: bool = false
var changed_after_hint: bool = false

var time_to_first_select_ms: int = -1
var time_to_first_confirm_ms: int = -1
var time_from_last_edit_to_confirm_ms: int = -1

var last_edit_ms: int = -1

var defense_pick_count: int = 0
var wrong_defense_try_count: int = 0

var ip_input_change_count: int = 0
var network_answer_change_count: int = 0
var broadcast_answer_change_count: int = 0
var hosts_answer_change_count: int = 0

var _awaiting_edit_after_fail: bool = false
var _awaiting_edit_after_hint: bool = false
var _last_renderer_error_type: String = ""

@onready var noir_overlay: Node = $NoirOverlay
@onready var safe_area: MarginContainer = $SafeArea
@onready var main_vbox: VBoxContainer = $SafeArea/MainVBox
@onready var header: HBoxContainer = $SafeArea/MainVBox/Header
@onready var content_scroll: ScrollContainer = $SafeArea/MainVBox/ContentScroll
@onready var content_vbox: VBoxContainer = $SafeArea/MainVBox/ContentScroll/Content
@onready var bottom_bar: VBoxContainer = $SafeArea/MainVBox/BottomBar
@onready var title_label: Label = $SafeArea/MainVBox/Header/TitleLabel
@onready var stage_label: Label = $SafeArea/MainVBox/Header/StageLabel
@onready var stability_bar: ProgressBar = $SafeArea/MainVBox/Header/StabilityBar
@onready var btn_back: Button = $SafeArea/MainVBox/Header/BtnBack

@onready var prompt_card: PanelContainer = $SafeArea/MainVBox/ContentScroll/Content/PromptCard
@onready var prompt_label: Label = $SafeArea/MainVBox/ContentScroll/Content/PromptCard/PromptLabel
@onready var diagram_card: PanelContainer = $SafeArea/MainVBox/ContentScroll/Content/DiagramCard
@onready var packets_layer: Node = $SafeArea/MainVBox/ContentScroll/Content/DiagramCard/PacketsLayer
@onready var slot_1: Node = $SafeArea/MainVBox/ContentScroll/Content/DiagramCard/DiagramVBox/DiagramRow/Slot1
@onready var slot_2: Node = $SafeArea/MainVBox/ContentScroll/Content/DiagramCard/DiagramVBox/DiagramRow/Slot2
@onready var slot_3: Node = $SafeArea/MainVBox/ContentScroll/Content/DiagramCard/DiagramVBox/DiagramRow/Slot3
@onready var attacker_node: PanelContainer = $SafeArea/MainVBox/ContentScroll/Content/DiagramCard/DiagramVBox/DiagramRow/AttackerNode
@onready var attacker_label: Label = $SafeArea/MainVBox/ContentScroll/Content/DiagramCard/DiagramVBox/DiagramRow/AttackerNode/AttackerLabel

@onready var risk_card: PanelContainer = $SafeArea/MainVBox/ContentScroll/Content/RiskCard
@onready var risk_title: Label = $SafeArea/MainVBox/ContentScroll/Content/RiskCard/RiskVBox/RiskTitle
@onready var collisions_label: Label = $SafeArea/MainVBox/ContentScroll/Content/RiskCard/RiskVBox/CollisionsRow/CollisionsLabel
@onready var eavesdrop_label: Label = $SafeArea/MainVBox/ContentScroll/Content/RiskCard/RiskVBox/EavesdropRow/EavesdropLabel
@onready var filtering_label: Label = $SafeArea/MainVBox/ContentScroll/Content/RiskCard/RiskVBox/FilteringRow/FilteringLabel
@onready var media_label: Label = $SafeArea/MainVBox/ContentScroll/Content/RiskCard/RiskVBox/MediaRow/MediaLabel
@onready var collisions_value: Label = $SafeArea/MainVBox/ContentScroll/Content/RiskCard/RiskVBox/CollisionsRow/CollisionsValue
@onready var eavesdrop_value: Label = $SafeArea/MainVBox/ContentScroll/Content/RiskCard/RiskVBox/EavesdropRow/EavesdropValue
@onready var filtering_value: Label = $SafeArea/MainVBox/ContentScroll/Content/RiskCard/RiskVBox/FilteringRow/FilteringValue
@onready var media_value: Label = $SafeArea/MainVBox/ContentScroll/Content/RiskCard/RiskVBox/MediaRow/MediaValue

@onready var palette_card: PanelContainer = $SafeArea/MainVBox/ContentScroll/Content/PaletteCard
@onready var palette_flow: GridContainer = $SafeArea/MainVBox/ContentScroll/Content/PaletteCard/PaletteVBox/Scroll/PaletteFlow
@onready var explanation_card: PanelContainer = $SafeArea/MainVBox/ContentScroll/Content/ExplanationCard
@onready var expl_headline: Label = $SafeArea/MainVBox/ContentScroll/Content/ExplanationCard/ExplVBox/ExplHeadline
@onready var expl_details: RichTextLabel = $SafeArea/MainVBox/ContentScroll/Content/ExplanationCard/ExplVBox/ExplDetails
@onready var expl_why: RichTextLabel = $SafeArea/MainVBox/ContentScroll/Content/ExplanationCard/ExplVBox/ExplWhy
@onready var renderer_host: PanelContainer = $SafeArea/MainVBox/ContentScroll/Content/RendererHost

@onready var status_label: Label = $SafeArea/MainVBox/BottomBar/StatusRow/StatusLabel
@onready var btn_reset: Button = $SafeArea/MainVBox/BottomBar/ActionsRow/BtnReset
@onready var btn_analyze: Button = $SafeArea/MainVBox/BottomBar/ActionsRow/BtnAnalyze
@onready var btn_next_level: Button = $SafeArea/MainVBox/BottomBar/ActionsRow/BtnNextLevel

var _slot_nodes: Array[Node] = []

func _tr(key: String, default_text: String, params: Dictionary = {}) -> String:
	var merged: Dictionary = params.duplicate(true)
	merged["default"] = default_text
	return I18n.tr_key(key, merged)

func _ready() -> void:
	add_to_group("resus_c_controller")
	if not GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.connect(_on_stability_changed)
	if not get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.connect(_on_viewport_size_changed)
	if not I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.connect(_on_language_changed)

	btn_back.pressed.connect(_on_back_pressed)
	btn_reset.pressed.connect(_on_reset_pressed)
	btn_analyze.pressed.connect(_on_analyze_pressed)
	btn_next_level.pressed.connect(_on_next_level_pressed)

	_slot_nodes = [slot_1, slot_2, slot_3]
	levels = ResusData.load_stage_levels(LEVELS_PATH, STAGE_ID)
	if levels.is_empty():
		_show_error(_tr("resus.c.error.load", "Stage C data is missing."))
		return

	_load_current_level(0)
	_on_viewport_size_changed()

func _exit_tree() -> void:
	if I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.disconnect(_on_language_changed)
	if GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.disconnect(_on_stability_changed)
	if get_tree() != null and get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.disconnect(_on_viewport_size_changed)

func _on_language_changed(_code: String) -> void:
	_apply_i18n()
	if _renderer != null and _renderer.has_method("apply_i18n"):
		_renderer.call("apply_i18n")

func _apply_i18n() -> void:
	title_label.text = _tr("resus.title", "Case 01: Digital Resus")
	stage_label.text = _tr("resus.c.stage.progress", "STAGE C {n}/{total}", {
		"n": current_level_index + 1,
		"total": max(1, levels.size())
	})
	btn_reset.text = _tr("resus.c.btn.reset", "RESET")
	btn_analyze.text = _tr("resus.c.btn.analyze", "ANALYZE") if _is_slots_level() else _tr("resus.btn.confirm", "CONFIRM")
	btn_next_level.text = _next_level_button_text()
	risk_title.text = _tr("resus.c01.dashboard.title", "RISK DASHBOARD")
	collisions_label.text = _tr("resus.c01.dashboard.collisions", "COLLISIONS")
	eavesdrop_label.text = _tr("resus.c01.dashboard.eavesdrop", "EAVESDROP")
	filtering_label.text = _tr("resus.c01.dashboard.filtering", "FILTERING")
	media_label.text = _tr("resus.c01.dashboard.media", "MEDIA")
	if not stage_c_data.is_empty():
		if _is_slots_level():
			prompt_label.text = I18n.resolve_field(stage_c_data, "prompt", {"default": str(stage_c_data.get("prompt", ""))})
		else:
			prompt_label.text = I18n.resolve_field(stage_c_data, "briefing", {"default": str(stage_c_data.get("briefing", ""))})

func _elapsed_ms_now() -> int:
	return maxi(0, Time.get_ticks_msec() - stage_started_ms)

func _reset_trial_runtime() -> void:
	drag_count = 0
	slot_change_count = 0
	unique_used_set.clear()
	time_to_first_action_ms = -1
	selection_change_count = 0
	drag_count_local = 0
	drop_count_local = 0
	confirm_attempt_count = 0
	reset_count_local = 0
	inspect_open_count = 0
	hint_open_count = 0
	changed_after_fail = false
	changed_after_hint = false
	time_to_first_select_ms = -1
	time_to_first_confirm_ms = -1
	time_from_last_edit_to_confirm_ms = -1
	last_edit_ms = -1
	defense_pick_count = 0
	wrong_defense_try_count = 0
	ip_input_change_count = 0
	network_answer_change_count = 0
	broadcast_answer_change_count = 0
	hosts_answer_change_count = 0
	_awaiting_edit_after_fail = false
	_awaiting_edit_after_hint = false
	_last_renderer_error_type = ""

func _begin_trial_session() -> void:
	trial_seq += 1
	format_id = str(stage_c_data.get("format", "")).to_upper()
	stage_started_ms = Time.get_ticks_msec()
	task_session = {
		"events": [],
		"trial_seq": trial_seq
	}
	_reset_trial_runtime()
	_log_event("trial_started", {
		"level_id": str(stage_c_data.get("id", "")),
		"format_id": format_id,
		"briefing": str(stage_c_data.get("briefing", "")),
		"round_count": int((stage_c_data.get("rounds", []) as Array).size())
	})

func _mark_first_select() -> void:
	if time_to_first_select_ms < 0:
		time_to_first_select_ms = _elapsed_ms_now()
	if time_to_first_action_ms < 0:
		time_to_first_action_ms = time_to_first_select_ms

func _mark_edit_action() -> void:
	last_edit_ms = _elapsed_ms_now()
	_mark_first_select()
	if _awaiting_edit_after_fail:
		changed_after_fail = true
		_awaiting_edit_after_fail = false
	if _awaiting_edit_after_hint:
		changed_after_hint = true
		_awaiting_edit_after_hint = false

func _resolve_renderer_error_type(details: Array) -> String:
	if format_id == "ATTACK_MATCH":
		var has_defense_fail: bool = false
		var has_attack_fail: bool = false
		for detail_v in details:
			if typeof(detail_v) != TYPE_DICTIONARY:
				continue
			var detail: Dictionary = detail_v as Dictionary
			if not bool(detail.get("defense_ok", true)):
				has_defense_fail = true
			if not bool(detail.get("attack_ok", true)):
				has_attack_fail = true
		if has_defense_fail:
			return "WRONG_DEFENSE"
		if has_attack_fail:
			return "THREAT_MISMATCH"
		return "PARTIAL_FAIL"
	if format_id == "SUBNET_CALC":
		for detail_v in details:
			if typeof(detail_v) != TYPE_DICTIONARY:
				continue
			var detail: Dictionary = detail_v as Dictionary
			for sub_v in detail.get("sub", []) as Array:
				if typeof(sub_v) != TYPE_DICTIONARY:
					continue
				var sub: Dictionary = sub_v as Dictionary
				if bool(sub.get("ok", false)):
					continue
				var q_type: String = str(sub.get("type", "")).to_lower()
				if q_type == "network" or q_type == "network_address":
					return "WRONG_NETWORK"
				if q_type == "broadcast":
					return "WRONG_BROADCAST"
				if q_type == "hosts" or q_type == "host_count":
					return "WRONG_HOSTS"
		return "SUBNET_CONCEPT_ERROR"
	return "PARTIAL_FAIL"

func _resolve_outcome_code_c(result: Dictionary) -> String:
	if bool(result.get("is_correct", false)):
		return "SUCCESS"
	if format_id == "ATTACK_MATCH" or format_id == "SUBNET_CALC":
		if _last_renderer_error_type != "":
			return _last_renderer_error_type
		return _resolve_renderer_error_type(result.get("details", []) as Array)
	if format_id != "MULTI_CHOICE_SLOTS":
		return "FORMAT_ERROR"
	return "PARTIAL_FAIL"

func _resolve_mastery_block_reason_c(outcome_code: String) -> String:
	if outcome_code == "SUCCESS":
		return "NONE"
	if hint_open_count > 0 and changed_after_hint:
		return "HINT_DEPENDENCY"
	if confirm_attempt_count >= 3:
		return "MULTI_CONFIRM_GUESSING"
	if reset_count_local >= 3:
		return "RESET_OVERUSE"
	if format_id == "SUBNET_CALC" and outcome_code != "SUCCESS":
		return "SUBNET_RULE_CONFUSION"
	if format_id == "ATTACK_MATCH" and outcome_code != "SUCCESS":
		return "THREAT_MODEL_CONFUSION"
	if selection_change_count >= 8:
		return "FORMAT_CONFUSION"
	return "NONE"

func _load_current_level(index: int) -> void:
	current_level_index = clamp(index, 0, max(0, levels.size() - 1))
	stage_c_data = (levels[current_level_index] as Dictionary).duplicate(true)
	format_id = str(stage_c_data.get("format", "")).to_upper()
	if _is_slots_level():
		_setup_slots_level()
		_begin_attempt()
	else:
		_setup_renderer_level()
		_begin_renderer_attempt()

func _setup_slots_level() -> void:
	_clear_renderer()
	prompt_card.visible = true
	diagram_card.visible = true
	risk_card.visible = true
	palette_card.visible = true
	explanation_card.visible = true
	renderer_host.visible = false
	_apply_i18n()
	prompt_label.text = I18n.resolve_field(stage_c_data, "prompt", {"default": str(stage_c_data.get("prompt", ""))})
	btn_next_level.visible = false
	btn_next_level.disabled = true

	_build_option_catalog()
	_build_palette()
	_setup_slots()
	_update_risk_dashboard()
	_update_stability_ui()

func _setup_renderer_level() -> void:
	prompt_card.visible = true
	diagram_card.visible = false
	risk_card.visible = false
	palette_card.visible = false
	explanation_card.visible = false
	renderer_host.visible = true
	btn_next_level.visible = false
	btn_next_level.disabled = true
	_apply_i18n()
	prompt_label.text = I18n.resolve_field(stage_c_data, "briefing", {"default": str(stage_c_data.get("briefing", ""))})
	_swap_renderer()
	_update_stability_ui()

func _swap_renderer() -> void:
	_clear_renderer()
	_renderer_rounds_complete = false
	var format: String = str(stage_c_data.get("format", "")).to_upper()
	var scene: PackedScene = null
	match format:
		"ATTACK_MATCH":
			scene = ATTACK_RENDERER_SCENE
		"SUBNET_CALC":
			scene = SUBNET_RENDERER_SCENE
		_:
			_show_error(_tr("resus.c.error.format", "Unknown format: {format}", {"format": format}))
			return
	_renderer = scene.instantiate()
	renderer_host.add_child(_renderer)
	if _renderer.has_method("setup"):
		_renderer.call("setup", stage_c_data, self)
	if _renderer.has_signal("all_rounds_complete"):
		_renderer.connect("all_rounds_complete", Callable(self, "_on_renderer_complete"))
	else:
		_renderer_rounds_complete = true

func _clear_renderer() -> void:
	if _renderer != null:
		_renderer.queue_free()
		_renderer = null

func _begin_renderer_attempt() -> void:
	trace.clear()
	_begin_trial_session()
	input_locked = false
	_last_result.clear()
	_last_payload.clear()
	if _renderer != null and _renderer.has_signal("all_rounds_complete"):
		_renderer_rounds_complete = false
	else:
		_renderer_rounds_complete = true
	btn_analyze.disabled = not _renderer_rounds_complete
	btn_next_level.visible = false
	btn_next_level.disabled = true
	status_label.text = _tr("resus.status.quiz_progress", "Complete all rounds, then confirm.")
	status_label.modulate = COLOR_OK
	if _renderer != null and _renderer.has_method("reset"):
		_renderer.call("reset")

func _analyze_renderer() -> void:
	if _renderer == null or not _renderer.has_method("get_answers"):
		return
	if not _renderer_rounds_complete:
		return
	confirm_attempt_count += 1
	if time_to_first_confirm_ms < 0:
		time_to_first_confirm_ms = _elapsed_ms_now()
	if last_edit_ms >= 0:
		time_from_last_edit_to_confirm_ms = maxi(0, _elapsed_ms_now() - last_edit_ms)
	_log_event("confirm_pressed", {
		"attempt": confirm_attempt_count,
		"format_id": format_id
	})
	var answers: Variant = _renderer.call("get_answers")
	var result: Dictionary = _score_renderer(answers)
	_last_renderer_error_type = _resolve_renderer_error_type(result.get("details", []) as Array)
	_register_renderer_trial(answers, result)
	input_locked = true
	btn_analyze.disabled = true
	if _renderer.has_method("show_result"):
		_renderer.call("show_result", result)
	status_label.text = _tr("resus.status.result", "{verdict} | {points}/{max}", {
		"verdict": str(result.get("verdict_code", "FAIL")),
		"points": int(result.get("points", 0)),
		"max": int(result.get("max_points", 2))
	})
	status_label.modulate = COLOR_OK if bool(result.get("is_correct", false)) else COLOR_WARN
	var can_advance: bool = bool(result.get("is_correct", false)) and (_has_next_level() or _is_flow_active())
	btn_next_level.visible = can_advance
	btn_next_level.disabled = not can_advance
	btn_next_level.text = _next_level_button_text()
	if bool(result.get("is_correct", false)):
		_play_sfx("relay")
	elif bool(result.get("is_fit", false)):
		_play_sfx("click")
	else:
		_play_sfx("error")

func _score_renderer(answers: Variant) -> Dictionary:
	var format: String = str(stage_c_data.get("format", "")).to_upper()
	match format:
		"ATTACK_MATCH":
			return ResusScoring.calculate_attack_match_result(stage_c_data, answers as Array)
		"SUBNET_CALC":
			return ResusScoring.calculate_subnet_result(stage_c_data, answers as Array)
		_:
			return {
				"points": 0,
				"max_points": 2,
				"is_correct": false,
				"is_fit": false,
				"stability_delta": -30,
				"verdict_code": "FAIL"
			}

func _register_renderer_trial(answers: Variant, result: Dictionary) -> void:
	var elapsed_ms: int = _elapsed_ms_now()
	var level_id: String = str(stage_c_data.get("id", "CASE01_C"))
	var details: Array = (result.get("details", []) as Array).duplicate(true)
	var outcome_code: String = _resolve_outcome_code_c(result)
	var mastery_block_reason: String = _resolve_mastery_block_reason_c(outcome_code)
	_log_event("confirm_result", {
		"is_correct": bool(result.get("is_correct", false)),
		"format_id": format_id,
		"rounds_complete": _renderer_rounds_complete,
		"score": int(result.get("points", 0)),
		"error_type": outcome_code
	})
	var payload: Dictionary = TrialV2.build(CASE_ID, STAGE_ID, level_id, "FORMAT_ROUTER", str(attempt_index))
	payload.merge({
		"case_run_id": _case_run_id(),
		"level_id": level_id,
		"format": str(stage_c_data.get("format", "")),
		"format_id": format_id,
		"snapshot": answers,
		"trial_seq": trial_seq,
		"task_session": task_session.duplicate(true),
		"elapsed_ms": elapsed_ms,
		"time_to_first_action_ms": max(-1, time_to_first_action_ms),
		"time_to_first_select_ms": time_to_first_select_ms,
		"time_to_first_confirm_ms": time_to_first_confirm_ms,
		"time_from_last_edit_to_confirm_ms": time_from_last_edit_to_confirm_ms,
		"selection_change_count": selection_change_count,
		"drag_count_local": drag_count_local,
		"drop_count_local": drop_count_local,
		"confirm_attempt_count": confirm_attempt_count,
		"reset_count": reset_count_local,
		"inspect_open_count": inspect_open_count,
		"hint_open_count": hint_open_count,
		"changed_after_fail": changed_after_fail,
		"changed_after_hint": changed_after_hint,
		"points": int(result.get("points", 0)),
		"max_points": int(result.get("max_points", 2)),
		"is_correct": bool(result.get("is_correct", false)),
		"is_fit": bool(result.get("is_fit", false)),
		"stability_delta": int(result.get("stability_delta", 0)),
		"verdict_code": str(result.get("verdict_code", "FAIL")),
		"outcome_code": outcome_code,
		"mastery_block_reason": mastery_block_reason,
		"details": details,
		"trace": trace.duplicate(true)
	}, true)
	if format_id == "ATTACK_MATCH":
		payload.merge({
			"defense_pick_count": defense_pick_count,
			"wrong_defense_try_count": wrong_defense_try_count
		}, true)
	elif format_id == "SUBNET_CALC":
		payload.merge({
			"ip_input_change_count": ip_input_change_count,
			"network_answer_change_count": network_answer_change_count,
			"broadcast_answer_change_count": broadcast_answer_change_count,
			"hosts_answer_change_count": hosts_answer_change_count
		}, true)
	GlobalMetrics.register_trial(payload)
	_last_result = result.duplicate(true)
	_last_payload = payload.duplicate(true)
	attempt_index += 1
	_update_stability_ui()

func _build_option_catalog() -> void:
	option_by_id.clear()
	correct_set.clear()
	option_order.clear()

	for option_v in stage_c_data.get("options", []) as Array:
		if typeof(option_v) != TYPE_DICTIONARY:
			continue
		var option_data: Dictionary = option_v as Dictionary
		var option_id: String = str(option_data.get("option_id", "")).strip_edges()
		if option_id == "":
			continue
		option_by_id[option_id] = option_data
		option_order.append(option_id)
		if bool(option_data.get("is_correct", false)):
			correct_set[option_id] = true

func _build_palette() -> void:
	for child in palette_flow.get_children():
		child.queue_free()
	item_nodes_by_option.clear()

	for option_id in option_order:
		var option_data: Dictionary = option_by_id.get(option_id, {}) as Dictionary
		var node_v: Variant = NET_ITEM_SCENE.instantiate()
		if not (node_v is Control):
			continue
		var item_node: Control = node_v as Control
		palette_flow.add_child(item_node)
		if item_node.has_method("setup"):
			item_node.call("setup", option_data)
		if item_node.has_method("set_source"):
			item_node.call("set_source", "PALETTE", -1)
		if item_node.has_signal("drag_started"):
			item_node.connect("drag_started", Callable(self, "_on_item_drag_started"))
		item_nodes_by_option[option_id] = item_node

	_sort_palette_items()

func _setup_slots() -> void:
	for i in range(_slot_nodes.size()):
		var slot_node: Node = _slot_nodes[i]
		if slot_node == null:
			continue
		if slot_node.has_method("set_slot_title"):
			slot_node.call("set_slot_title", i + 1)
		if slot_node.has_method("set_current_option"):
			slot_node.call("set_current_option", "", "")
		if slot_node.has_method("set_feedback_state"):
			slot_node.call("set_feedback_state", "neutral")
		if slot_node.has_method("set_locked"):
			slot_node.call("set_locked", false)

func _begin_attempt() -> void:
	trace.clear()
	_begin_trial_session()
	input_locked = false
	_last_result.clear()
	_last_payload.clear()

	explanation_card.visible = false
	btn_analyze.disabled = false
	btn_next_level.visible = false
	btn_next_level.disabled = true

	slots = ["", "", ""]
	slot_item_by_index.clear()

	for option_id in option_order:
		var item_v: Variant = item_nodes_by_option.get(option_id, null)
		if not (item_v is Control):
			continue
		var item_node: Control = item_v as Control
		if item_node.get_parent() != palette_flow:
			item_node.reparent(palette_flow)
		if item_node.has_method("set_source"):
			item_node.call("set_source", "PALETTE", -1)
		if item_node.has_method("set_feedback_state"):
			item_node.call("set_feedback_state", "neutral")
		if item_node.has_method("set_locked"):
			item_node.call("set_locked", false)

	_sort_palette_items()

	for i in range(_slot_nodes.size()):
		var slot_node: Node = _slot_nodes[i]
		if slot_node == null:
			continue
		if slot_node.has_method("set_current_option"):
			slot_node.call("set_current_option", "", "")
		if slot_node.has_method("set_feedback_state"):
			slot_node.call("set_feedback_state", "neutral")
		if slot_node.has_method("set_locked"):
			slot_node.call("set_locked", false)

	if packets_layer != null and packets_layer.has_method("reset_to_idle"):
		packets_layer.call("reset_to_idle")
	_apply_attacker_visual("IDLE", _calculate_risk(slots))

	_update_status_line(_tr("resus.c.status.ready", "Mount three modules, then analyze the link."))
	_update_risk_dashboard()
	_update_stability_ui()

func is_input_locked() -> bool:
	return input_locked

func handle_drop_to_slot(slot_index: int, data: Dictionary) -> Dictionary:
	if input_locked:
		return {"success": false}
	if not _is_slot_index_valid(slot_index):
		return {"success": false}
	if str(data.get("kind", "")) != "NET_MODULE":
		return {"success": false}

	var module_id: String = str(data.get("module_id", "")).strip_edges()
	if module_id == "" or not option_by_id.has(module_id):
		return {"success": false}

	var source_path: String = str(data.get("node_path", ""))
	var source_node: Node = get_node_or_null(source_path)
	if source_node == null:
		var fallback_node: Variant = item_nodes_by_option.get(module_id, null)
		if fallback_node is Node:
			source_node = fallback_node as Node
	if source_node == null or not (source_node is Control):
		return {"success": false}

	var from_slot: int = int(data.get("from_slot", -1))
	var target_idx: int = slot_index - 1
	var prev_module_id: String = slots[target_idx]

	if from_slot == slot_index and prev_module_id == module_id:
		return {
			"success": true,
			"module_id": module_id,
			"prev_module_id": prev_module_id,
			"label": str((option_by_id.get(module_id, {}) as Dictionary).get("label", module_id))
		}

	if from_slot >= 1 and from_slot <= 3 and from_slot != slot_index:
		_clear_slot_state(from_slot)

	var prev_node_v: Variant = slot_item_by_index.get(slot_index, null)
	if prev_node_v is Control and prev_node_v != source_node:
		_move_item_to_palette(prev_node_v as Control)

	_attach_item_to_slot(source_node as Control, slot_index)
	slots[target_idx] = module_id
	slot_item_by_index[slot_index] = source_node

	_mark_first_action()
	_mark_edit_action()
	slot_change_count += 1
	selection_change_count += 1
	drop_count_local += 1
	unique_used_set[module_id] = true
	_log_event("SLOT_CHANGED", {
		"slot": slot_index,
		"module_id": module_id,
		"prev_module_id": prev_module_id
	})
	_log_event("slot_changed", {
		"slot": slot_index,
		"module_id": module_id,
		"prev_module_id": prev_module_id
	})
	_log_event("item_dropped", {
		"slot": slot_index,
		"module_id": module_id,
		"prev_module_id": prev_module_id
	})
	_update_status_line("")
	_update_risk_dashboard()
	_play_sfx("click")

	return {
		"success": true,
		"module_id": module_id,
		"prev_module_id": prev_module_id,
		"label": str((option_by_id.get(module_id, {}) as Dictionary).get("label", module_id))
	}

func handle_clear_slot(slot_index: int) -> Dictionary:
	if input_locked:
		return {"success": false}
	if not _is_slot_index_valid(slot_index):
		return {"success": false}

	var idx: int = slot_index - 1
	var prev_module_id: String = slots[idx]
	if prev_module_id == "":
		return {"success": false}

	var prev_node_v: Variant = slot_item_by_index.get(slot_index, null)
	if prev_node_v is Control:
		_move_item_to_palette(prev_node_v as Control)

	_clear_slot_state(slot_index)
	_mark_first_action()
	_mark_edit_action()
	slot_change_count += 1
	selection_change_count += 1
	_log_event("SLOT_CLEARED", {
		"slot": slot_index,
		"prev_module_id": prev_module_id
	})
	_log_event("slot_changed", {
		"slot": slot_index,
		"module_id": "",
		"prev_module_id": prev_module_id
	})
	_update_status_line("")
	_update_risk_dashboard()
	_play_sfx("click")

	return {
		"success": true,
		"prev_module_id": prev_module_id
	}

func _attach_item_to_slot(item_node: Control, slot_index: int) -> void:
	var slot_node: Node = _get_slot_node(slot_index)
	if slot_node == null:
		return
	if slot_node.has_method("attach_item_control"):
		slot_node.call("attach_item_control", item_node)
	if item_node.has_method("set_source"):
		item_node.call("set_source", "SLOT", slot_index)
	if item_node.has_method("set_locked"):
		item_node.call("set_locked", input_locked)

func _move_item_to_palette(item_node: Control) -> void:
	if item_node.get_parent() != palette_flow:
		item_node.reparent(palette_flow)
	if item_node.has_method("set_source"):
		item_node.call("set_source", "PALETTE", -1)
	if item_node.has_method("set_locked"):
		item_node.call("set_locked", input_locked)
	if not input_locked and item_node.has_method("set_feedback_state"):
		item_node.call("set_feedback_state", "neutral")
	_sort_palette_items()

func _clear_slot_state(slot_index: int) -> void:
	if not _is_slot_index_valid(slot_index):
		return
	var idx: int = slot_index - 1
	slots[idx] = ""
	slot_item_by_index.erase(slot_index)

	var slot_node: Node = _get_slot_node(slot_index)
	if slot_node == null:
		return
	if slot_node.has_method("set_current_option"):
		slot_node.call("set_current_option", "", "")
	if not input_locked and slot_node.has_method("set_feedback_state"):
		slot_node.call("set_feedback_state", "neutral")

func _on_item_drag_started(module_id: String, source: String, from_slot: int) -> void:
	if input_locked:
		return
	_mark_first_action()
	drag_count += 1
	drag_count_local += 1
	_log_event("DRAG_START", {
		"module_id": module_id,
		"from": source,
		"from_slot": from_slot
	})
	_log_event("item_drag_started", {
		"module_id": module_id,
		"from": source,
		"from_slot": from_slot
	})

func _on_analyze_pressed() -> void:
	if input_locked:
		return
	if not _is_slots_level():
		_analyze_renderer()
		return

	confirm_attempt_count += 1
	if time_to_first_confirm_ms < 0:
		time_to_first_confirm_ms = _elapsed_ms_now()
	if last_edit_ms >= 0:
		time_from_last_edit_to_confirm_ms = maxi(0, _elapsed_ms_now() - last_edit_ms)
	_log_event("confirm_pressed", {
		"attempt": confirm_attempt_count,
		"format_id": format_id
	})

	var selected_ids: Array[String] = _collect_selected_ids()
	var risk: Dictionary = _calculate_risk(slots)
	var scoring_snapshot: Dictionary = {
		"slots": slots.duplicate(),
		"selected": selected_ids.duplicate(),
		"unique_used_count": unique_used_set.size()
	}

	_log_event("ANALYZE_PRESSED", {
		"selected_count": selected_ids.size(),
		"filled_slots": _filled_slots_count()
	})

	var result: Dictionary = ResusScoring.calculate_stage_c_result(stage_c_data, scoring_snapshot)
	_last_renderer_error_type = _resolve_outcome_code_c(result)
	_log_event("confirm_result", {
		"is_correct": bool(result.get("is_correct", false)),
		"format_id": format_id,
		"rounds_complete": true,
		"score": int(result.get("points", 0)),
		"error_type": _last_renderer_error_type
	})
	if packets_layer != null and packets_layer.has_method("configure_from_verdict"):
		packets_layer.call("configure_from_verdict", str(result.get("verdict_code", "FAIL")), stage_c_data.get("visual_sim", {}), risk)
	_apply_attacker_visual(str(result.get("verdict_code", "FAIL")), risk)

	_register_trial(result, risk)
	attempt_index += 1
	_show_explanation(result, risk)
	_apply_result_highlight(result)
	_update_stability_ui()

	input_locked = true
	btn_analyze.disabled = true
	_set_input_locked(true)
	_update_risk_dashboard()
	var can_advance: bool = bool(result.get("is_correct", false)) and (_has_next_level() or _is_flow_active())
	btn_next_level.visible = can_advance
	btn_next_level.disabled = not can_advance
	btn_next_level.text = _next_level_button_text()

	if bool(result.get("is_correct", false)):
		_play_sfx("relay")
	elif bool(result.get("is_fit", false)):
		_play_sfx("click")
	else:
		_play_sfx("error")

func _on_reset_pressed() -> void:
	reset_count_local += 1
	_log_event("RESET_PRESSED", {
		"prev_filled_slots": _filled_slots_count()
	})
	_log_event("reset_pressed", {"count": reset_count_local})
	_apply_retry_floor()
	if _is_slots_level():
		_begin_attempt()
	else:
		_begin_renderer_attempt()
	_play_sfx("click")

func _on_next_level_pressed() -> void:
	if _last_result.is_empty() or not bool(_last_result.get("is_correct", false)):
		return
	if _has_next_level():
		_load_current_level(current_level_index + 1)
		_play_sfx("click")
		return
	if _is_flow_active():
		GlobalMetrics.record_case_stage_result(STAGE_ID, _build_flow_stage_summary())
		get_tree().change_scene_to_file(FLOW_SCENE_PATH)

func _on_renderer_complete() -> void:
	_renderer_rounds_complete = true
	_log_event("scan_result", {"rounds_complete": true})
	if input_locked:
		return
	btn_analyze.disabled = false
	status_label.text = _tr("resus.status.quiz_done", "Quiz complete. Confirm to submit.")
	status_label.modulate = COLOR_OK

func on_renderer_event(event_name: String, payload: Dictionary = {}) -> void:
	match event_name:
		"attack_selected":
			selection_change_count += 1
			_mark_edit_action()
			_log_event("attack_selected", payload)
		"defense_selected":
			defense_pick_count += 1
			selection_change_count += 1
			_mark_edit_action()
			_log_event("defense_selected", payload)
		"network_answer_changed":
			ip_input_change_count += 1
			network_answer_change_count += 1
			selection_change_count += 1
			_mark_edit_action()
			_log_event("network_answer_changed", payload)
		"broadcast_answer_changed":
			ip_input_change_count += 1
			broadcast_answer_change_count += 1
			selection_change_count += 1
			_mark_edit_action()
			_log_event("broadcast_answer_changed", payload)
		"hosts_answer_changed":
			hosts_answer_change_count += 1
			selection_change_count += 1
			_mark_edit_action()
			_log_event("hosts_answer_changed", payload)
		"hint_opened":
			hint_open_count += 1
			_awaiting_edit_after_hint = true
			_log_event("hint_opened", payload)
		"inspect_opened":
			inspect_open_count += 1
			_log_event("inspect_opened", payload)
		"round_checked":
			var round_ok: bool = bool(payload.get("round_ok", false))
			if format_id == "ATTACK_MATCH" and not bool(payload.get("defense_ok", true)):
				wrong_defense_try_count += 1
			_last_renderer_error_type = str(payload.get("error_type", ""))
			if not round_ok:
				_awaiting_edit_after_fail = true
			_log_event("scan_result", payload)
		_:
			_log_event(event_name, payload)

func _has_next_level() -> bool:
	return current_level_index < levels.size() - 1

func _set_input_locked(locked: bool) -> void:
	for slot_node in _slot_nodes:
		if slot_node != null and slot_node.has_method("set_locked"):
			slot_node.call("set_locked", locked)
	for item_v in item_nodes_by_option.values():
		if item_v is Node and (item_v as Node).has_method("set_locked"):
			(item_v as Node).call("set_locked", locked)

func _show_explanation(result: Dictionary, risk: Dictionary) -> void:
	explanation_card.visible = true

	var verdict_code: String = str(result.get("verdict_code", "FAIL"))
	var raw_headline: String = str(result.get("feedback_headline", verdict_code))
	expl_headline.text = _resolve_feedback_text(raw_headline)
	if verdict_code == "PERFECT":
		expl_headline.modulate = COLOR_OK
	elif verdict_code == "GOOD" or verdict_code == "NOISY":
		expl_headline.modulate = COLOR_WARN
	else:
		expl_headline.modulate = COLOR_ERR

	var detail_lines: Array[String] = []
	for detail_v in result.get("feedback_details", []) as Array:
		var raw_detail: String = str(detail_v)
		detail_lines.append("- %s" % _resolve_feedback_text(raw_detail))
	detail_lines.append("")
	detail_lines.append(_tr("resus.c.explain.risk_line",
		"Risk: collisions={col} | eavesdrop={eav} | filtering={fil} | media={med}", {
			"col": str(risk.get("collisions", "MID")),
			"eav": str(risk.get("eavesdrop", "MID")),
			"fil": str(risk.get("filtering", "OFF")),
			"med": str(risk.get("media", "UNKNOWN"))
	}))
	expl_details.text = "\n".join(detail_lines)

	var why_lines: Array[String] = []
	var strategy_flags: Array = result.get("strategy_flags", []) as Array
	var missing_required: Array = result.get("missing_required", []) as Array
	var wrong_selected: int = int(result.get("wrong_selected", 0))

	why_lines.append(_tr("resus.c.explain.selected_modules", "Selected modules:"))
	for selected_id in _collect_selected_ids():
		why_lines.append("- %s" % selected_id)

	if missing_required.is_empty() and wrong_selected == 0:
		why_lines.append(_tr("resus.c.explain.all_present", "All required modules are present."))
	elif not missing_required.is_empty():
		why_lines.append(_tr("resus.c.explain.missing", "Missing required modules: {ids}", {
			"ids": ", ".join(_to_string_array(missing_required))
		}))
	if wrong_selected > 0:
		why_lines.append(_tr("resus.c.explain.wrong_count", "Wrong modules selected: {n}", {"n": wrong_selected}))
	if strategy_flags.has("TOUCHED_ALL_OPTIONS"):
		why_lines.append(_tr("resus.c.explain.strategy_touched", "Strategy flag: TOUCHED_ALL_OPTIONS"))

	expl_why.text = "\n".join(why_lines)

	status_label.text = _tr("resus.c.status.blocked", "{code} | slots {slots}/3", {
		"code": verdict_code,
		"slots": _filled_slots_count()
	})
	status_label.modulate = expl_headline.modulate

func _resolve_feedback_text(text: String) -> String:
	var normalized: String = text.strip_edges()
	if normalized.begins_with("resus.") and normalized.find(" ") == -1:
		return I18n.tr_key(normalized, {"default": normalized})
	return normalized

func _apply_result_highlight(result: Dictionary) -> void:
	for i in range(1, 4):
		var slot_node: Node = _get_slot_node(i)
		if slot_node != null and slot_node.has_method("set_feedback_state"):
			slot_node.call("set_feedback_state", "neutral")

	for option_id in option_order:
		var item_v: Variant = item_nodes_by_option.get(option_id, null)
		if item_v is Node and (item_v as Node).has_method("set_feedback_state"):
			(item_v as Node).call("set_feedback_state", "neutral")

	for i in range(3):
		var option_id: String = slots[i]
		if option_id == "":
			continue
		var state: String = "correct" if correct_set.has(option_id) else "wrong"
		var slot_node: Node = _get_slot_node(i + 1)
		if slot_node != null and slot_node.has_method("set_feedback_state"):
			slot_node.call("set_feedback_state", state)
		var item_v: Variant = item_nodes_by_option.get(option_id, null)
		if item_v is Node and (item_v as Node).has_method("set_feedback_state"):
			(item_v as Node).call("set_feedback_state", state)

	for missing_id_v in result.get("missing_required", []) as Array:
		var missing_id: String = str(missing_id_v)
		if _is_option_in_slots(missing_id):
			continue
		var missing_node_v: Variant = item_nodes_by_option.get(missing_id, null)
		if missing_node_v is Node and (missing_node_v as Node).has_method("set_feedback_state"):
			(missing_node_v as Node).call("set_feedback_state", "missing")

func _register_trial(result: Dictionary, risk: Dictionary) -> void:
	var elapsed_ms: int = _elapsed_ms_now()
	var selected_ids: Array[String] = _collect_selected_ids()
	var strategy_flags: Array[String] = _to_string_array(result.get("strategy_flags", []))
	var level_id: String = str(stage_c_data.get("id", "CASE01_C_01"))
	var outcome_code: String = _resolve_outcome_code_c(result)
	var mastery_block_reason: String = _resolve_mastery_block_reason_c(outcome_code)
	var payload: Dictionary = TrialV2.build(
		CASE_ID,
		STAGE_ID,
		level_id,
		"NETWORK_HARDENING",
		str(attempt_index)
	)
	var snapshot: Dictionary = {
		"slots": slots.duplicate(),
		"selected": selected_ids.duplicate(),
		"risk": risk.duplicate(true),
		"strategy_flags": strategy_flags.duplicate(),
		"unique_used_count": unique_used_set.size()
	}
	payload.merge({
		"case_run_id": _case_run_id(),
		"level_id": level_id,
		"format": str(stage_c_data.get("format", "MULTI_CHOICE_SLOTS")),
		"format_id": format_id,
		"snapshot": snapshot,
		"risk": risk.duplicate(true),
		"trial_seq": trial_seq,
		"task_session": task_session.duplicate(true),
		"points": int(result.get("points", 0)),
		"max_points": int(result.get("max_points", 2)),
		"is_correct": bool(result.get("is_correct", false)),
		"is_fit": bool(result.get("is_fit", false)),
		"stability_delta": int(result.get("stability_delta", 0)),
		"verdict_code": str(result.get("verdict_code", "FAIL")),
		"outcome_code": outcome_code,
		"mastery_block_reason": mastery_block_reason,
		"selected_count": int(result.get("selected_count", selected_ids.size())),
		"correct_selected": int(result.get("correct_selected", 0)),
		"wrong_selected": int(result.get("wrong_selected", 0)),
		"missing_required": _to_string_array(result.get("missing_required", [])),
		"drag_count": drag_count,
		"slot_change_count": slot_change_count,
		"selection_change_count": selection_change_count,
		"drag_count_local": drag_count_local,
		"drop_count_local": drop_count_local,
		"confirm_attempt_count": confirm_attempt_count,
		"reset_count": reset_count_local,
		"inspect_open_count": inspect_open_count,
		"hint_open_count": hint_open_count,
		"changed_after_fail": changed_after_fail,
		"changed_after_hint": changed_after_hint,
		"unique_used_count": unique_used_set.size(),
		"strategy_flags": strategy_flags.duplicate(),
		"time_to_first_action_ms": max(-1, time_to_first_action_ms),
		"time_to_first_select_ms": time_to_first_select_ms,
		"time_to_first_confirm_ms": time_to_first_confirm_ms,
		"time_from_last_edit_to_confirm_ms": time_from_last_edit_to_confirm_ms,
		"elapsed_ms": elapsed_ms,
		"trace": trace.duplicate(true)
	}, true)
	GlobalMetrics.register_trial(payload)
	_last_result = result.duplicate(true)
	_last_payload = payload.duplicate(true)

func _update_status_line(prefix: String) -> void:
	if not _is_slots_level():
		return
	if input_locked:
		return
	var filled: int = _filled_slots_count()
	var used_unique: int = unique_used_set.size()
	if prefix.strip_edges() == "":
		status_label.text = _tr("resus.c.status.slots", "Slots {n}/3 | touched {u}", {"n": filled, "u": used_unique})
	else:
		status_label.text = _tr("resus.c.status.slots_prefix", "{prefix} | slots {n}/3 | touched {u}", {
			"prefix": prefix,
			"n": filled,
			"u": used_unique
		})
	status_label.modulate = COLOR_WARN

func _update_risk_dashboard() -> void:
	if not _is_slots_level():
		return
	if not input_locked:
		collisions_value.text = "???"
		eavesdrop_value.text = "???"
		filtering_value.text = "???"
		media_value.text = "???"
		var hidden_tone := Color(0.55, 0.55, 0.55, 1.0)
		collisions_value.modulate = hidden_tone
		eavesdrop_value.modulate = hidden_tone
		filtering_value.modulate = hidden_tone
		media_value.modulate = hidden_tone
		return
	var risk: Dictionary = _calculate_risk(slots)
	var collisions_raw: String = str(risk.get("collisions", "MID"))
	var eavesdrop_raw: String = str(risk.get("eavesdrop", "MID"))
	var filtering_raw: String = str(risk.get("filtering", "OFF"))
	var media_raw: String = str(risk.get("media", "UNKNOWN"))

	collisions_value.text = collisions_raw
	eavesdrop_value.text = eavesdrop_raw
	filtering_value.text = filtering_raw
	media_value.text = media_raw

	collisions_value.modulate = _risk_color("collisions", collisions_raw)
	eavesdrop_value.modulate = _risk_color("eavesdrop", eavesdrop_raw)
	filtering_value.modulate = _risk_color("filtering", filtering_raw)
	media_value.modulate = _risk_color("media", media_raw)

func _calculate_risk(slot_values: Array[String]) -> Dictionary:
	var selected_set: Dictionary = {}
	for option_id in slot_values:
		if option_id == "":
			continue
		selected_set[option_id] = true

	var effects_list: Array = []
	for option_id_v in selected_set.keys():
		var option_id: String = str(option_id_v)
		var option_data: Dictionary = option_by_id.get(option_id, {}) as Dictionary
		effects_list.append(option_data.get("effects", {}) as Dictionary)

	var collisions: String = "MID"
	var filtering: String = "OFF"
	var eavesdrop: String = "MID"
	var media: String = "UNKNOWN"

	for effect_v in effects_list:
		var effect: Dictionary = effect_v as Dictionary
		var coll_val: String = str(effect.get("collisions", "NEUTRAL"))
		if coll_val == "HIGH":
			collisions = "HIGH"
		elif coll_val == "LOW" and collisions != "HIGH":
			collisions = "LOW"

		var filt_val: String = str(effect.get("filtering", "OFF"))
		if filt_val == "ON":
			filtering = "ON"

		var eav_val: String = str(effect.get("eavesdrop", "MID"))
		if eav_val == "HIGH":
			eavesdrop = "HIGH"
		elif eav_val == "LOW" and eavesdrop != "HIGH":
			eavesdrop = "LOW"

		var media_val: String = str(effect.get("media", "NEUTRAL"))
		if media_val == "FIBER":
			media = "FIBER"
		elif media_val == "COAX" and media != "FIBER":
			media = "COAX"

	return {
		"collisions": collisions,
		"eavesdrop": eavesdrop,
		"filtering": filtering,
		"media": media
	}

func _risk_color(kind: String, value: String) -> Color:
	match kind:
		"collisions", "eavesdrop":
			if value == "LOW":
				return COLOR_OK
			if value == "MID":
				return COLOR_WARN
			return COLOR_ERR
		"filtering":
			return COLOR_OK if value == "ON" else COLOR_ERR
		"media":
			if value == "FIBER":
				return COLOR_OK
			if value == "UNKNOWN":
				return COLOR_WARN
			return COLOR_ERR
		_:
			return COLOR_WARN

func _apply_attacker_visual(verdict_code: String, risk: Dictionary) -> void:
	var config: Dictionary = (stage_c_data.get("visual_sim", {}) as Dictionary).get(verdict_code, {}) as Dictionary
	var alpha: float = float(config.get("attacker_alpha", 0.3))
	var tint: Color = Color(0.92, 0.32, 0.36, 1.0)
	if config.has("attacker_tint"):
		tint = _parse_color(config.get("attacker_tint"), tint)

	if verdict_code == "IDLE":
		alpha = 0.22
	elif verdict_code == "PERFECT" or verdict_code == "GOOD":
		alpha = min(alpha, 0.28)
	elif verdict_code == "NOISY":
		alpha = max(alpha, 0.55)
	else:
		alpha = max(alpha, 0.82)

	if str(risk.get("eavesdrop", "MID")) == "HIGH":
		alpha = min(1.0, alpha + 0.08)

	attacker_node.self_modulate = Color(tint.r, tint.g, tint.b, alpha)
	attacker_label.modulate = Color(1.0, 1.0, 1.0, min(1.0, alpha + 0.15))

func _parse_color(value: Variant, fallback: Color) -> Color:
	if value is Color:
		return value
	var text: String = str(value).strip_edges()
	if text == "":
		return fallback
	var parsed := Color.from_string(text, fallback)
	return parsed

func _collect_selected_ids() -> Array[String]:
	var selected_set: Dictionary = {}
	for option_id in slots:
		if option_id == "":
			continue
		selected_set[option_id] = true
	var selected_ids: Array[String] = []
	for option_id_v in selected_set.keys():
		selected_ids.append(str(option_id_v))
	selected_ids.sort()
	return selected_ids

func _filled_slots_count() -> int:
	var count: int = 0
	for option_id in slots:
		if option_id != "":
			count += 1
	return count

func _is_option_in_slots(option_id: String) -> bool:
	for current in slots:
		if current == option_id:
			return true
	return false

func _sort_palette_items() -> void:
	var move_index: int = 0
	for option_id in option_order:
		var item_v: Variant = item_nodes_by_option.get(option_id, null)
		if not (item_v is Node):
			continue
		var item_node: Node = item_v as Node
		if item_node.get_parent() != palette_flow:
			continue
		palette_flow.move_child(item_node, move_index)
		move_index += 1

func _is_slot_index_valid(slot_index: int) -> bool:
	return slot_index >= 1 and slot_index <= 3

func _get_slot_node(slot_index: int) -> Node:
	if not _is_slot_index_valid(slot_index):
		return null
	return _slot_nodes[slot_index - 1]

func _mark_first_action() -> void:
	if time_to_first_action_ms < 0:
		time_to_first_action_ms = _elapsed_ms_now()

func _log_event(event_name: String, data: Dictionary = {}) -> void:
	var elapsed: int = _elapsed_ms_now()
	var safe_payload: Dictionary = data.duplicate(true)
	trace.append({
		"t_ms": elapsed,
		"event": event_name,
		"data": safe_payload
	})
	var events: Array = task_session.get("events", []) as Array
	events.append({
		"name": event_name,
		"t_ms": elapsed,
		"payload": safe_payload
	})
	task_session["events"] = events

func _to_string_array(values: Variant) -> Array[String]:
	var out: Array[String] = []
	if typeof(values) != TYPE_ARRAY:
		return out
	for value_v in values as Array:
		out.append(str(value_v))
	return out

func _play_sfx(event_name: String) -> void:
	if has_node("/root/AudioManager"):
		AudioManager.play(event_name)

func _on_back_pressed() -> void:
	if _is_flow_active():
		GlobalMetrics.clear_case_flow()
	get_tree().change_scene_to_file(QUEST_SELECT_SCENE)

func _on_stability_changed(_new_value: float, _delta: float) -> void:
	_update_stability_ui()

func _update_stability_ui() -> void:
	stability_bar.value = GlobalMetrics.stability
	if noir_overlay != null and noir_overlay.has_method("set_danger_level"):
		noir_overlay.call("set_danger_level", float(GlobalMetrics.stability))

func _show_error(message: String) -> void:
	status_label.text = message
	status_label.modulate = COLOR_ERR
	btn_analyze.disabled = true
	btn_reset.disabled = true
	btn_next_level.disabled = true

func _on_viewport_size_changed() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var is_landscape: bool = viewport_size.x >= viewport_size.y
	var phone_landscape: bool = is_landscape and viewport_size.y <= PHONE_LANDSCAPE_MAX_HEIGHT
	var phone_portrait: bool = (not is_landscape) and viewport_size.x <= PHONE_PORTRAIT_MAX_WIDTH
	var compact: bool = phone_landscape or phone_portrait

	_apply_safe_area_padding(compact)
	main_vbox.add_theme_constant_override("separation", 8 if compact else 10)
	content_vbox.add_theme_constant_override("separation", 8 if compact else 10)
	header.add_theme_constant_override("separation", 8 if compact else 10)
	bottom_bar.add_theme_constant_override("separation", 8 if compact else 10)
	stability_bar.custom_minimum_size.x = 160.0 if compact else 220.0
	btn_back.custom_minimum_size = Vector2(56.0 if compact else 72.0, 56.0 if compact else 72.0)
	btn_reset.custom_minimum_size = Vector2(0.0, 60.0 if compact else 72.0)
	btn_analyze.custom_minimum_size = Vector2(0.0, 60.0 if compact else 72.0)
	btn_next_level.custom_minimum_size = Vector2(0.0, 60.0 if compact else 72.0)
	status_label.custom_minimum_size.y = 44.0 if compact else 56.0
	palette_flow.columns = 1 if phone_portrait else 2

func _apply_safe_area_padding(compact: bool) -> void:
	var left: float = 8.0 if compact else 16.0
	var top: float = 8.0 if compact else 12.0
	var right: float = 8.0 if compact else 16.0
	var bottom: float = 8.0 if compact else 12.0
	var safe_rect: Rect2i = DisplayServer.get_display_safe_area()
	if safe_rect.size.x > 0 and safe_rect.size.y > 0:
		var viewport_size: Vector2 = get_viewport_rect().size
		left = maxf(left, float(safe_rect.position.x))
		top = maxf(top, float(safe_rect.position.y))
		right = maxf(right, viewport_size.x - float(safe_rect.position.x + safe_rect.size.x))
		bottom = maxf(bottom, viewport_size.y - float(safe_rect.position.y + safe_rect.size.y))
	safe_area.add_theme_constant_override("margin_left", int(round(left)))
	safe_area.add_theme_constant_override("margin_top", int(round(top)))
	safe_area.add_theme_constant_override("margin_right", int(round(right)))
	safe_area.add_theme_constant_override("margin_bottom", int(round(bottom)))

func _build_flow_stage_summary() -> Dictionary:
	var case_run_id: String = _case_run_id()
	var total_points: int = 0
	var total_stability_delta: int = 0
	for entry_v in GlobalMetrics.session_history:
		if typeof(entry_v) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_v as Dictionary
		if str(entry.get("quest_id", "")) != CASE_ID:
			continue
		if str(entry.get("stage", "")) != STAGE_ID:
			continue
		if str(entry.get("case_run_id", "")) != case_run_id:
			continue
		total_points += int(entry.get("points", 0))
		total_stability_delta += int(entry.get("stability_delta", 0))
	return {
		"stage": STAGE_ID,
		"case_run_id": case_run_id,
		"levels_completed": levels.size(),
		"last_level_id": str(stage_c_data.get("id", "")),
		"points": total_points,
		"stability_delta": total_stability_delta,
		"completed_at_unix": Time.get_unix_time_from_system()
	}

func _next_level_button_text() -> String:
	if not _has_next_level() and _is_flow_active():
		return _tr("resus.c.btn.close_case", "CLOSE CASE")
	return _tr("resus.c.btn.next_level", "NEXT LEVEL")

func _is_slots_level() -> bool:
	return str(stage_c_data.get("format", "")).to_upper() == "MULTI_CHOICE_SLOTS"

func _apply_retry_floor() -> void:
	if GlobalMetrics.stability < 20.0:
		var previous: float = float(GlobalMetrics.stability)
		GlobalMetrics.stability = 20.0
		GlobalMetrics.emit_signal("stability_changed", GlobalMetrics.stability, GlobalMetrics.stability - previous)

func _is_flow_active() -> bool:
	var flow: Dictionary = GlobalMetrics.get_case_flow()
	return bool(flow.get("is_active", false)) and str(flow.get("case_id", "")) == CASE_ID

func _case_run_id() -> String:
	var flow: Dictionary = GlobalMetrics.get_case_flow()
	return str(flow.get("case_run_id", ""))
