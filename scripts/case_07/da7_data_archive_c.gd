extends Control

const CasesHub = preload("res://scripts/case_07/da7_cases.gd")
const CasesModuleC = preload("res://scripts/case_07/da7_cases_c.gd")

const BREAKPOINT_PX := 900
const SESSION_CASE_COUNT := 6
const TYPEWRITER_INTERVAL_SEC := 0.05
const LAYOUT_MOBILE := "mobile"
const LAYOUT_DESKTOP := "desktop"

var session_cases: Array = []
var current_case_index: int = -1
var current_case: Dictionary = {}
var current_layout: String = LAYOUT_DESKTOP
var session_finished: bool = false

var trial_seq: int = 0
var task_session: Dictionary = {}

var case_started_ts: int = 0
var time_to_first_action_ms: int = -1
var is_trial_active: bool = false
var trial_locked: bool = false
var timed_out: bool = false

var limit_sec: int = 120
var time_left_sec: float = 120.0
var typewriter_active: bool = false
var typewriter_accum: float = 0.0

var selected_sequence_ids: Array[String] = []
var block_by_id: Dictionary = {}
var repo_button_by_id: Dictionary = {}
var allow_repeat_roles: Array = []

var reorder_count: int = 0
var undo_count: int = 0
var block_pick_count: int = 0
var clear_used: bool = false
var unique_blocks_used: Dictionary = {}
var token_pick_count: int = 0
var placement_count: int = 0
var clear_count: int = 0
var submit_attempt_count: int = 0
var duplicate_role_attempt_count: int = 0
var syntax_error_seen_count: int = 0
var semantic_error_seen_count: int = 0
var time_to_first_pick_ms: int = -1
var time_to_first_submit_ms: int = -1
var time_after_last_edit_to_submit_ms: int = -1
var sequence_length_peak: int = 0
var changed_after_error: bool = false
var error_feedback_seen: bool = false
var last_edit_ts: int = -1
var details_open_count: int = 0
var hint_open_count: int = 0

var _status_i18n_key: String = ""
var _status_i18n_default: String = ""
var _status_i18n_params: Dictionary = {}
var _body_scroll_installed: bool = false

@onready var root_layout: VBoxContainer = $SafeArea/Margin/Root
@onready var title_label: Label = $SafeArea/Margin/Root/Header/HeaderVBox/Title
@onready var btn_back: Button = $SafeArea/Margin/Root/BackRow/BtnBack
@onready var stability_label: Label = $SafeArea/Margin/Root/Header/HeaderVBox/TimerRow/StabilityLabel
@onready var timer_bar: ProgressBar = $SafeArea/Margin/Root/Header/HeaderVBox/TimerRow/TimerBar
@onready var timer_label: Label = $SafeArea/Margin/Root/Header/HeaderVBox/TimerRow/TimerLabel
@onready var prompt_label: RichTextLabel = $SafeArea/Margin/Root/Prompt
@onready var code_panel: PanelContainer = $SafeArea/Margin/Root/CodePanel
@onready var code_area: HFlowContainer = $SafeArea/Margin/Root/CodePanel/CodeArea
@onready var repo_panel: PanelContainer = $SafeArea/Margin/Root/RepoPanel
@onready var btn_undo: Button = $SafeArea/Margin/Root/ControlsRow/BtnUndo
@onready var btn_clear: Button = $SafeArea/Margin/Root/ControlsRow/BtnClear
@onready var btn_submit: Button = $SafeArea/Margin/Root/ControlsRow/BtnSubmit
@onready var btn_next: Button = $SafeArea/Margin/Root/ControlsRow/BtnNext
@onready var status_label: Label = $SafeArea/Margin/Root/StatusLabel
@onready var block_repository: GridContainer = $SafeArea/Margin/Root/RepoPanel/RepoScroll/BlockRepository
@onready var sfx_click: AudioStreamPlayer = $SFX/SfxClick
@onready var sfx_error: AudioStreamPlayer = $SFX/SfxError
@onready var sfx_relay: AudioStreamPlayer = $SFX/SfxRelay

func _exit_tree() -> void:
	if I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.disconnect(_on_language_changed)

func _tr(key: String, default_text: String, params: Dictionary = {}) -> String:
	var merged: Dictionary = params.duplicate(true)
	merged["default"] = default_text
	return I18n.tr_key(key, merged)

func _on_language_changed(_code: String) -> void:
	_apply_i18n()

func _apply_i18n() -> void:
	btn_back.text = _tr("da7.c.ui.btn_back", "BACK")
	btn_undo.text = _tr("da7.c.ui.btn_undo", "UNDO")
	btn_clear.text = _tr("da7.c.ui.btn_clear", "CLEAR")
	btn_submit.text = _tr("da7.c.ui.btn_submit", "SUBMIT")
	_update_stability_ui()
	if session_finished:
		_apply_complete_i18n()
	elif is_trial_active or trial_locked:
		_refresh_case_ui_i18n()
	if not _status_i18n_key.is_empty():
		status_label.text = _tr(_status_i18n_key, _status_i18n_default, _status_i18n_params)

func _apply_complete_i18n() -> void:
	title_label.text = _tr("da7.c.ui.title_complete", "CASE #7: SQL MASTER [COMPLETE]")
	btn_next.text = _tr("da7.c.ui.btn_exit", "EXIT")

func _refresh_case_ui_i18n() -> void:
	if current_case.is_empty():
		return
	var case_id: String = str(current_case.get("id", "DA7-C-00"))
	title_label.text = _tr("da7.c.ui.title_running", "CASE #7: SQL MASTER [{case_id}]",
		{"case_id": case_id})
	var raw_prompt: String = str(current_case.get("prompt", ""))
	prompt_label.text = "[b]%s[/b]" % _tr("da7.c.case.%s.prompt" % case_id, raw_prompt)

func _set_status_i18n(key: String, default_text: String, params: Dictionary = {}) -> void:
	_status_i18n_key = key
	_status_i18n_default = default_text
	_status_i18n_params = params.duplicate(true)
	status_label.text = _tr(key, default_text, params)

func _ready() -> void:
	randomize()
	if not I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.connect(_on_language_changed)
	if not GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.connect(_on_stability_changed)
	get_tree().root.size_changed.connect(_on_viewport_size_changed)
	btn_back.pressed.connect(_on_back_pressed)
	btn_undo.pressed.connect(_on_undo_pressed)
	btn_clear.pressed.connect(_on_clear_pressed)
	btn_submit.pressed.connect(_on_submit_pressed)
	btn_next.pressed.connect(_on_next_pressed)
	_install_body_scroll()

	_init_session()
	_apply_i18n()
	call_deferred("_on_viewport_size_changed")
	_load_next_case()

func _process(delta: float) -> void:
	if typewriter_active:
		typewriter_accum += delta
		while typewriter_accum >= TYPEWRITER_INTERVAL_SEC and typewriter_active:
			typewriter_accum -= TYPEWRITER_INTERVAL_SEC
			if prompt_label.visible_characters < prompt_label.get_total_character_count():
				prompt_label.visible_characters += 1
			else:
				typewriter_active = false
				prompt_label.visible_characters = -1

	if not is_trial_active:
		return

	time_left_sec = max(0.0, time_left_sec - delta)
	_update_timer_ui()
	if time_left_sec <= 0.0 and not timed_out:
		timed_out = true
		submit_attempt_count += 1
		if time_to_first_submit_ms < 0:
			time_to_first_submit_ms = Time.get_ticks_msec() - case_started_ts
		if last_edit_ts > 0:
			time_after_last_edit_to_submit_ms = maxi(0, Time.get_ticks_msec() - last_edit_ts)
		_log_event("submit_pressed", {
			"attempt": submit_attempt_count,
			"sequence_size": selected_sequence_ids.size(),
			"source": "timeout"
		})
		var timeout_eval: Dictionary = _evaluate_sequence(selected_sequence_ids, true)
		_finish_trial(false, "TIMEOUT", timeout_eval, "TIMEOUT")

func _init_session() -> void:
	var all_cases: Array = CasesHub.get_cases("C")
	var valid_cases: Array = []
	for case_v in all_cases:
		if typeof(case_v) != TYPE_DICTIONARY:
			continue
		var case_data: Dictionary = case_v as Dictionary
		if CasesModuleC.validate_case_c(case_data):
			valid_cases.append(case_data)
	valid_cases.shuffle()
	session_cases = valid_cases.slice(0, min(SESSION_CASE_COUNT, valid_cases.size()))
	current_case_index = -1
	GlobalMetrics.stability = 100.0
	_update_stability_ui()

func _load_next_case() -> void:
	current_case_index += 1
	if current_case_index >= session_cases.size():
		_finish_session()
		return
	current_case = (session_cases[current_case_index] as Dictionary).duplicate(true)
	session_finished = false
	case_started_ts = Time.get_ticks_msec()
	time_to_first_action_ms = -1
	is_trial_active = true
	trial_locked = false
	timed_out = false
	reorder_count = 0
	undo_count = 0
	block_pick_count = 0
	token_pick_count = 0
	placement_count = 0
	clear_used = false
	clear_count = 0
	submit_attempt_count = 0
	duplicate_role_attempt_count = 0
	syntax_error_seen_count = 0
	semantic_error_seen_count = 0
	time_to_first_pick_ms = -1
	time_to_first_submit_ms = -1
	time_after_last_edit_to_submit_ms = -1
	sequence_length_peak = 0
	changed_after_error = false
	error_feedback_seen = false
	last_edit_ts = -1
	details_open_count = 0
	hint_open_count = 0
	unique_blocks_used.clear()
	selected_sequence_ids.clear()
	repo_button_by_id.clear()
	block_by_id.clear()
	_begin_trial_session()
	_render_case()

func _begin_trial_session() -> void:
	trial_seq += 1
	var case_id := str(current_case.get("id", "DA7-C-00"))
	task_session = {
		"trial_seq": trial_seq,
		"quest_id": "DATA_ARCHIVE",
		"stage_id": "C",
		"task_id": case_id,
		"started_at_ticks": case_started_ts,
		"ended_at_ticks": 0,
		"events": []
	}
	_log_event("trial_started", {
		"trial_seq": trial_seq,
		"case_id": case_id,
		"mode": "SQL_MASTER"
	})

func _render_case() -> void:
	var case_id: String = str(current_case.get("id", "DA7-C-00"))
	title_label.text = _tr("da7.c.ui.title_running", "CASE #7: SQL MASTER [{case_id}]",
		{"case_id": case_id})
	var timing_policy: Dictionary = current_case.get("timing_policy", {}) as Dictionary
	limit_sec = int(timing_policy.get("limit_sec", 120))
	time_left_sec = float(limit_sec)
	timer_bar.max_value = max(1.0, float(limit_sec))
	timer_bar.value = timer_bar.max_value
	prompt_label.bbcode_enabled = true
	var raw_prompt: String = str(current_case.get("prompt", ""))
	prompt_label.text = "[b]%s[/b]" % _tr("da7.c.case.%s.prompt" % case_id, raw_prompt)
	prompt_label.visible_characters = 0
	typewriter_active = true
	typewriter_accum = 0.0
	var rules: Dictionary = _active_rules()
	allow_repeat_roles = (rules.get("allow_repeat_roles", []) as Array).duplicate()
	_build_block_repository()
	_rebuild_code_area()
	_set_input_locked(false)
	btn_next.text = _tr("da7.c.ui.btn_next", "NEXT")
	btn_next.visible = false
	_set_status_i18n("da7.c.ui.status_initial", "Assemble the query and submit.")
	_update_timer_ui()
	_update_stability_ui()

func _active_rules() -> Dictionary:
	var rules: Dictionary = current_case.get("rules", {}) as Dictionary
	if rules.is_empty():
		rules = current_case.get("constraints", {}) as Dictionary
	return rules

func _build_block_repository() -> void:
	for child in block_repository.get_children():
		child.queue_free()
	var blocks: Array = (current_case.get("available_blocks", []) as Array).duplicate()
	var anti_cheat: Dictionary = current_case.get("anti_cheat", {}) as Dictionary
	if bool(anti_cheat.get("shuffle_blocks", false)):
		blocks.shuffle()
	for block_v in blocks:
		if typeof(block_v) != TYPE_DICTIONARY:
			continue
		var block_data: Dictionary = block_v as Dictionary
		var block_id: String = str(block_data.get("id", ""))
		if block_id == "":
			continue
		block_by_id[block_id] = block_data
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(0, 44 if _is_compact_phone() else 56)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.text = str(block_data.get("text", block_id))
		btn.pressed.connect(_on_block_pressed.bind(block_id))
		block_repository.add_child(btn)
		repo_button_by_id[block_id] = btn

func _on_block_pressed(block_id: String) -> void:
	if trial_locked or not is_trial_active:
		return
	if not block_by_id.has(block_id):
		return
	_register_interaction()
	var role: String = str((block_by_id.get(block_id, {}) as Dictionary).get("role", ""))
	if _role_is_single_use(role) and _sequence_has_role(role):
		duplicate_role_attempt_count += 1
		error_feedback_seen = true
		hint_open_count += 1
		_log_event("hint_opened", {"source": "duplicate_role", "role": role})
		_log_event("duplicate_role_attempt", {"role": role, "block_id": block_id})
		_set_status_i18n("da7.c.ui.status_role_used", "Role {role} already used.", {"role": role})
		return
	if time_to_first_pick_ms < 0:
		time_to_first_pick_ms = Time.get_ticks_msec() - case_started_ts
	selected_sequence_ids.append(block_id)
	token_pick_count += 1
	block_pick_count += 1
	placement_count += 1
	unique_blocks_used[block_id] = true
	sequence_length_peak = maxi(sequence_length_peak, selected_sequence_ids.size())
	_mark_sequence_edited()
	var btn: Button = repo_button_by_id.get(block_id, null) as Button
	if is_instance_valid(btn):
		btn.disabled = true
	if is_instance_valid(sfx_click):
		sfx_click.play()
	_log_event("token_added", {
		"token_id": block_id,
		"token_label": str((block_by_id.get(block_id, {}) as Dictionary).get("text", block_id)),
		"sequence_size": selected_sequence_ids.size()
	})
	_log_event("selection_changed", {
		"action": "add",
		"token_id": block_id,
		"sequence_size": selected_sequence_ids.size()
	})
	_rebuild_code_area()

func _rebuild_code_area() -> void:
	for child in code_area.get_children():
		child.queue_free()
	for idx in range(selected_sequence_ids.size()):
		var block_id: String = selected_sequence_ids[idx]
		var block_data: Dictionary = block_by_id.get(block_id, {}) as Dictionary
		var chip: PanelContainer = PanelContainer.new()
		chip.custom_minimum_size = Vector2(0, 54)
		var row: HBoxContainer = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 6)
		chip.add_child(row)

		var btn_left: Button = Button.new()
		btn_left.text = "<"
		btn_left.custom_minimum_size = Vector2(44, 44)
		btn_left.disabled = idx == 0
		btn_left.pressed.connect(_on_move_token.bind(idx, -1))
		row.add_child(btn_left)

		var lbl: Label = Label.new()
		lbl.text = str(block_data.get("text", block_id))
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(lbl)

		var btn_right: Button = Button.new()
		btn_right.text = ">"
		btn_right.custom_minimum_size = Vector2(44, 44)
		btn_right.disabled = idx >= selected_sequence_ids.size() - 1
		btn_right.pressed.connect(_on_move_token.bind(idx, 1))
		row.add_child(btn_right)

		var btn_remove: Button = Button.new()
		btn_remove.text = "X"
		btn_remove.custom_minimum_size = Vector2(44, 44)
		btn_remove.pressed.connect(_on_remove_token.bind(idx))
		row.add_child(btn_remove)

		code_area.add_child(chip)
	_update_submit_state()

func _on_move_token(index: int, direction: int) -> void:
	if trial_locked or not is_trial_active:
		return
	var new_index: int = index + direction
	if new_index < 0 or new_index >= selected_sequence_ids.size():
		return
	_register_interaction()
	var token: String = selected_sequence_ids[index]
	selected_sequence_ids[index] = selected_sequence_ids[new_index]
	selected_sequence_ids[new_index] = token
	reorder_count += 1
	_mark_sequence_edited()
	if is_instance_valid(sfx_click):
		sfx_click.play()
	_log_event("selection_changed", {
		"action": "reorder",
		"from_index": index,
		"to_index": new_index,
		"sequence_size": selected_sequence_ids.size()
	})
	_rebuild_code_area()

func _on_remove_token(index: int) -> void:
	if trial_locked or not is_trial_active:
		return
	if index < 0 or index >= selected_sequence_ids.size():
		return
	_register_interaction()
	var block_id: String = selected_sequence_ids[index]
	selected_sequence_ids.remove_at(index)
	_mark_sequence_edited()
	var btn: Button = repo_button_by_id.get(block_id, null) as Button
	if is_instance_valid(btn):
		btn.disabled = false
	if is_instance_valid(sfx_click):
		sfx_click.play()
	_log_event("selection_changed", {
		"action": "remove",
		"token_id": block_id,
		"sequence_size": selected_sequence_ids.size()
	})
	_rebuild_code_area()

func _on_undo_pressed() -> void:
	if trial_locked or not is_trial_active:
		return
	if selected_sequence_ids.is_empty():
		return
	undo_count += 1
	_log_event("undo_pressed", {"undo_count": undo_count})
	_on_remove_token(selected_sequence_ids.size() - 1)

func _on_clear_pressed() -> void:
	if trial_locked or not is_trial_active:
		return
	if selected_sequence_ids.is_empty():
		return
	_register_interaction()
	clear_used = true
	clear_count += 1
	_log_event("clear_pressed", {
		"clear_count": clear_count,
		"sequence_size_before": selected_sequence_ids.size()
	})
	selected_sequence_ids.clear()
	_mark_sequence_edited()
	_log_event("selection_changed", {"action": "clear", "sequence_size": 0})
	for block_id in repo_button_by_id.keys():
		var btn: Button = repo_button_by_id.get(block_id, null) as Button
		if is_instance_valid(btn):
			btn.disabled = false
	_rebuild_code_area()
	_set_status_i18n("da7.c.ui.status_cleared", "Sequence cleared.")

func _on_submit_pressed() -> void:
	if trial_locked or not is_trial_active:
		return
	_register_interaction()
	submit_attempt_count += 1
	if time_to_first_submit_ms < 0:
		time_to_first_submit_ms = Time.get_ticks_msec() - case_started_ts
	if last_edit_ts > 0:
		time_after_last_edit_to_submit_ms = maxi(0, Time.get_ticks_msec() - last_edit_ts)
	_log_event("submit_pressed", {
		"attempt": submit_attempt_count,
		"sequence_size": selected_sequence_ids.size(),
		"source": "button"
	})
	var eval_result: Dictionary = _evaluate_sequence(selected_sequence_ids)
	var is_correct: bool = bool(eval_result.get("is_correct", false))
	var f_reason: Variant = eval_result.get("f_reason", null)
	var end_state: String = "SUCCESS" if is_correct else "FAIL"
	_finish_trial(is_correct, f_reason, eval_result, end_state)

func _finish_trial(is_correct: bool, f_reason: Variant, eval_result: Dictionary, end_state: String) -> void:
	trial_locked = true
	is_trial_active = false
	typewriter_active = false
	prompt_label.visible_characters = -1
	_set_input_locked(true)
	if is_correct:
		_set_status_i18n("da7.c.ui.status_success", "ACCESS GRANTED. Query is correct.")
		if is_instance_valid(sfx_relay):
			sfx_relay.play()
	else:
		_set_status_i18n("da7.c.ui.status_error", "ERROR: {reason}", {"reason": str(f_reason)})
		if is_instance_valid(sfx_error):
			sfx_error.play()
		if str(f_reason) == "SQL_SYNTAX_ERROR":
			syntax_error_seen_count += 1
		elif str(f_reason) != "TIMEOUT" and str(f_reason) != "INCOMPLETE_QUERY":
			semantic_error_seen_count += 1
		error_feedback_seen = true
	var error_type: String = "NONE" if is_correct else str(f_reason)
	_log_event("submit_result", {
		"is_correct": is_correct,
		"error_type": error_type,
		"end_state": end_state,
		"sequence_size": selected_sequence_ids.size()
	})
	task_session["ended_at_ticks"] = Time.get_ticks_msec()
	_log_event("trial_finished", {
		"is_correct": is_correct,
		"error_type": error_type,
		"end_state": end_state
	})
	_log_trial(is_correct, f_reason, eval_result, end_state)
	_update_stability_ui()
	btn_next.visible = true

func _evaluate_sequence(selected_ids: Array[String], force_timeout: bool = false) -> Dictionary:
	var rules: Dictionary = _active_rules()
	var required_roles: Array = rules.get("required_roles", []) as Array
	var forbidden_roles: Array = rules.get("forbidden_roles", []) as Array
	var forbidden_block_ids: Array = rules.get("forbidden_block_ids", []) as Array
	var skeleton_roles: Array = rules.get("skeleton_roles", []) as Array
	var order_rules: Array = rules.get("order_rules", []) as Array
	var min_tokens: int = int(rules.get("min_tokens", 1))
	var correct_ids: Array[String] = _to_string_array(current_case.get("correct_sequence_ids", []) as Array)

	var selected_roles: Array[String] = _roles_for_ids(selected_ids)
	var missing_roles: Array[String] = _missing_required_roles(selected_roles, required_roles)
	var diff: Dictionary = _build_diff(selected_ids, correct_ids)

	if force_timeout:
		return _build_eval("TIMEOUT", selected_roles, missing_roles, diff)
	if selected_ids == correct_ids:
		return _build_eval("SUCCESS", selected_roles, [], diff)
	if _has_forbidden_tokens(selected_ids, selected_roles, forbidden_block_ids, forbidden_roles):
		return _build_eval("SQL_SYNTAX_ERROR", selected_roles, missing_roles, diff)
	if selected_ids.size() < min_tokens or not missing_roles.is_empty():
		return _build_eval("INCOMPLETE_QUERY", selected_roles, missing_roles, diff)
	if _violates_order_rules(selected_roles, order_rules) or _violates_skeleton_order(selected_roles, skeleton_roles):
		return _build_eval("KEYWORD_ORDER", selected_roles, missing_roles, diff)
	if _same_multiset(selected_ids, correct_ids) and selected_ids != correct_ids:
		return _build_eval("KEYWORD_ORDER", selected_roles, missing_roles, diff)
	if (diff.get("extra_ids", []) as Array).size() > 0:
		return _build_eval("EXTRA_TOKENS", selected_roles, missing_roles, diff)
	return _build_eval("LOGIC_MISMATCH", selected_roles, missing_roles, diff)

func _build_eval(reason: String, selected_roles: Array[String], missing_roles: Array[String], diff: Dictionary) -> Dictionary:
	var is_correct: bool = reason == "SUCCESS"
	var final_reason: Variant = null
	if not is_correct:
		final_reason = reason
	return {
		"is_correct": is_correct,
		"f_reason": final_reason,
		"selected_roles": selected_roles,
		"missing_roles": missing_roles,
		"diff": diff
	}

func _to_string_array(values: Array) -> Array[String]:
	var out: Array[String] = []
	for value_v in values:
		out.append(str(value_v))
	return out

func _roles_for_ids(ids: Array[String]) -> Array[String]:
	var roles: Array[String] = []
	for id in ids:
		var block_data: Dictionary = block_by_id.get(id, {}) as Dictionary
		roles.append(str(block_data.get("role", "")))
	return roles

func _missing_required_roles(selected_roles: Array[String], required_roles: Array) -> Array[String]:
	var lookup: Dictionary = {}
	for role_v in selected_roles:
		lookup[str(role_v)] = true
	var missing: Array[String] = []
	for role_v in required_roles:
		var role: String = str(role_v)
		if not lookup.has(role):
			missing.append(role)
	return missing

func _has_forbidden_tokens(selected_ids: Array[String], selected_roles: Array[String], forbidden_block_ids: Array, forbidden_roles: Array) -> bool:
	var forbidden_block_lookup: Dictionary = {}
	for block_id_v in forbidden_block_ids:
		forbidden_block_lookup[str(block_id_v)] = true
	for selected_id in selected_ids:
		if forbidden_block_lookup.has(selected_id):
			return true

	var forbidden_role_lookup: Dictionary = {}
	for role_v in forbidden_roles:
		forbidden_role_lookup[str(role_v)] = true
	for selected_role in selected_roles:
		if forbidden_role_lookup.has(selected_role):
			return true
	return false

func _violates_order_rules(selected_roles: Array[String], order_rules: Array) -> bool:
	for rule_v in order_rules:
		if typeof(rule_v) != TYPE_DICTIONARY:
			continue
		var rule: Dictionary = rule_v as Dictionary
		var before_role: String = str(rule.get("before", ""))
		var after_role: String = str(rule.get("after", ""))
		if before_role == "" or after_role == "":
			continue
		var before_idx: int = _first_role_index(selected_roles, before_role)
		var after_idx: int = _first_role_index(selected_roles, after_role)
		if before_idx < 0 or after_idx < 0:
			continue
		if before_idx <= after_idx:
			return true
	return false

func _violates_skeleton_order(selected_roles: Array[String], skeleton_roles: Array) -> bool:
	var cursor: int = -1
	for role_v in skeleton_roles:
		var role: String = str(role_v)
		var idx: int = _first_role_index(selected_roles, role)
		if idx < 0:
			continue
		if idx < cursor:
			return true
		cursor = idx
	return false

func _first_role_index(selected_roles: Array[String], role: String) -> int:
	for idx in range(selected_roles.size()):
		if selected_roles[idx] == role:
			return idx
	return -1

func _build_diff(selected_ids: Array[String], correct_ids: Array[String]) -> Dictionary:
	var selected_counts: Dictionary = _counts(selected_ids)
	var correct_counts: Dictionary = _counts(correct_ids)

	var missing_ids: Array[String] = []
	for key_v in correct_counts.keys():
		var key: String = str(key_v)
		var need: int = int(correct_counts[key]) - int(selected_counts.get(key, 0))
		for _i in range(max(0, need)):
			missing_ids.append(key)

	var extra_ids: Array[String] = []
	for key_v in selected_counts.keys():
		var key: String = str(key_v)
		var extra: int = int(selected_counts[key]) - int(correct_counts.get(key, 0))
		for _j in range(max(0, extra)):
			extra_ids.append(key)

	var first_mismatch_index: int = -1
	var max_len: int = max(selected_ids.size(), correct_ids.size())
	for idx in range(max_len):
		var selected_id: String = selected_ids[idx] if idx < selected_ids.size() else "<none>"
		var correct_id: String = correct_ids[idx] if idx < correct_ids.size() else "<none>"
		if selected_id != correct_id:
			first_mismatch_index = idx
			break

	return {
		"missing_ids": missing_ids,
		"extra_ids": extra_ids,
		"first_mismatch_index": first_mismatch_index
	}

func _counts(ids: Array[String]) -> Dictionary:
	var out: Dictionary = {}
	for id in ids:
		out[id] = int(out.get(id, 0)) + 1
	return out

func _same_multiset(a: Array[String], b: Array[String]) -> bool:
	if a.size() != b.size():
		return false
	return _counts(a) == _counts(b)

func _role_is_single_use(role: String) -> bool:
	return not allow_repeat_roles.has(role)

func _sequence_has_role(role: String) -> bool:
	for block_id in selected_sequence_ids:
		var block_data: Dictionary = block_by_id.get(block_id, {}) as Dictionary
		if str(block_data.get("role", "")) == role:
			return true
	return false

func _register_interaction() -> void:
	if time_to_first_action_ms < 0:
		time_to_first_action_ms = Time.get_ticks_msec() - case_started_ts

func _mark_sequence_edited() -> void:
	last_edit_ts = Time.get_ticks_msec()
	if error_feedback_seen:
		changed_after_error = true
		error_feedback_seen = false

func _log_trial(is_correct: bool, f_reason: Variant, eval_result: Dictionary, end_state: String) -> void:
	var now_ms: int = Time.get_ticks_msec()
	var elapsed_ms: int = now_ms - case_started_ts
	var effective_first_action_ms: int = max(0, time_to_first_action_ms)
	if time_to_first_action_ms < 0:
		effective_first_action_ms = elapsed_ms

	var case_id := str(current_case.get("id", "DA7-C-00"))
	var interaction_type := str(current_case.get("interaction_type", "ASSEMBLE_BLOCKS"))
	var schema_version := str(current_case.get("schema_version", "DA7.C.v1"))
	var variant_hash := str(hash("%s|%s|%s|%s" % [case_id, interaction_type, schema_version, str(current_case.get("topic", "DB_SQL"))]))
	var payload: Dictionary = TrialV2.build("DATA_ARCHIVE", "C", case_id, interaction_type, variant_hash)
	var timing_policy: Dictionary = current_case.get("timing_policy", {}) as Dictionary
	var rules: Dictionary = _active_rules()
	var diff: Dictionary = eval_result.get("diff", {}) as Dictionary
	var error_type: String = "NONE" if is_correct else str(f_reason)
	var outcome_code: String = _outcome_code_for_c(is_correct, f_reason, end_state)
	var mastery_block_reason: String = _mastery_block_reason_for_c(is_correct, outcome_code)
	var valid_for_mastery: bool = is_correct and mastery_block_reason == "NONE"
	var effective_first_submit_ms := time_to_first_submit_ms
	if effective_first_submit_ms < 0:
		effective_first_submit_ms = elapsed_ms
	var effective_edit_to_submit_ms := time_after_last_edit_to_submit_ms
	if effective_edit_to_submit_ms < 0 and last_edit_ts > 0:
		effective_edit_to_submit_ms = maxi(0, now_ms - last_edit_ts)

	payload.merge({
		"quest": "data_archive",
		"level": "C",
		"stage_id": "C",
		"case_id": case_id,
		"question_id": case_id,
		"topic": str(current_case.get("topic", "DB_SQL")),
		"schema_version": schema_version,
		"is_correct": is_correct,
		"is_fit": is_correct,
		"f_reason": f_reason,
		"error_type": error_type,
		"outcome_code": outcome_code,
		"mastery_block_reason": mastery_block_reason,
		"valid_for_diagnostics": true,
		"valid_for_mastery": valid_for_mastery,
		"end_state": end_state,
		"elapsed_ms": elapsed_ms,
		"duration": float(elapsed_ms) / 1000.0,
		"time_to_first_action_ms": effective_first_action_ms,
		"time_to_first_pick_ms": time_to_first_pick_ms,
		"time_to_first_submit_ms": effective_first_submit_ms,
		"time_after_last_edit_to_submit_ms": effective_edit_to_submit_ms,
		"check_attempt_count": submit_attempt_count,
		"hint_used": hint_open_count > 0,
		"details_used": details_open_count > 0,
		"inspect_used": false,
		"token_pick_count": token_pick_count,
		"unique_token_count": unique_blocks_used.size(),
		"placement_count": placement_count,
		"reorder_count": reorder_count,
		"undo_count": undo_count,
		"clear_count": clear_count,
		"submit_attempt_count": submit_attempt_count,
		"duplicate_role_attempt_count": duplicate_role_attempt_count,
		"syntax_error_seen_count": syntax_error_seen_count,
		"semantic_error_seen_count": semantic_error_seen_count,
		"sequence_length_peak": sequence_length_peak,
		"changed_after_error": changed_after_error,
		"timing": {
			"policy_mode": str(timing_policy.get("mode", "EXAM")),
			"limit_sec": int(timing_policy.get("limit_sec", limit_sec)),
			"effective_elapsed_ms": elapsed_ms,
			"time_to_first_action_ms": effective_first_action_ms,
			"time_to_first_pick_ms": time_to_first_pick_ms,
			"time_to_first_submit_ms": effective_first_submit_ms,
			"time_after_last_edit_to_submit_ms": effective_edit_to_submit_ms
		},
		"answer": {
			"user_sequence_ids": selected_sequence_ids.duplicate(),
			"selected_roles": eval_result.get("selected_roles", [])
		},
		"expected": {
			"correct_sequence_ids": _to_string_array(current_case.get("correct_sequence_ids", []) as Array),
			"required_roles": rules.get("required_roles", []),
			"skeleton_roles": rules.get("skeleton_roles", []),
			"order_rules": rules.get("order_rules", [])
		},
		"diff": {
			"missing_ids": diff.get("missing_ids", []),
			"extra_ids": diff.get("extra_ids", []),
			"first_mismatch_index": int(diff.get("first_mismatch_index", -1))
		},
		"telemetry": {
			"time_to_first_action_ms": effective_first_action_ms,
			"time_to_first_pick_ms": time_to_first_pick_ms,
			"time_to_first_submit_ms": effective_first_submit_ms,
			"time_after_last_edit_to_submit_ms": effective_edit_to_submit_ms,
			"pick_count": block_pick_count,
			"block_pick_count": block_pick_count,
			"token_pick_count": token_pick_count,
			"placement_count": placement_count,
			"unique_blocks_used": unique_blocks_used.size(),
			"unique_blocks_used_ids": unique_blocks_used.keys(),
			"reorder_count": reorder_count,
			"undo_count": undo_count,
			"clear_used": clear_used,
			"clear_count": clear_count,
			"submit_attempt_count": submit_attempt_count,
			"duplicate_role_attempt_count": duplicate_role_attempt_count,
			"syntax_error_seen_count": syntax_error_seen_count,
			"semantic_error_seen_count": semantic_error_seen_count,
			"sequence_length_peak": sequence_length_peak,
			"changed_after_error": changed_after_error
		},
		"flags": {
			"timed_out": timed_out
		},
		"ui": {
			"layout": current_layout,
			"vw": int(get_viewport_rect().size.x),
			"vh": int(get_viewport_rect().size.y)
		},
		"anti_cheat": current_case.get("anti_cheat", {}) as Dictionary,
		"task_session": task_session.duplicate(true)
	}, true)
	payload["stability_delta"] = -20.0 if not is_correct else 0.0
	GlobalMetrics.register_trial(payload)

func _outcome_code_for_c(is_correct: bool, f_reason: Variant, end_state: String) -> String:
	if is_correct:
		return "SQL_SUCCESS"
	var reason := str(f_reason)
	if end_state == "TIMEOUT" or reason == "TIMEOUT":
		return "SQL_TIMEOUT"
	if reason == "SQL_SYNTAX_ERROR":
		return "SQL_SYNTAX_ERROR"
	if reason == "INCOMPLETE_QUERY":
		if duplicate_role_attempt_count > 0:
			return "SQL_DUPLICATE_ROLE"
		return "SQL_INCOMPLETE_SEQUENCE"
	if duplicate_role_attempt_count > 0:
		return "SQL_DUPLICATE_ROLE"
	return "SQL_SEMANTIC_ERROR"

func _mastery_block_reason_for_c(is_correct: bool, outcome_code: String) -> String:
	if undo_count >= 4:
		return "UNDO_OVERUSE"
	if clear_count >= 2:
		return "CLEAR_OVERUSE"
	if submit_attempt_count >= 2:
		return "MULTI_SUBMIT_GUESSING"
	if duplicate_role_attempt_count > 0:
		return "ROLE_DUPLICATION"
	if syntax_error_seen_count > 0:
		return "SYNTAX_UNSTABLE"
	if semantic_error_seen_count > 0:
		return "SEMANTIC_UNSTABLE"
	if not is_correct and outcome_code == "SQL_INCOMPLETE_SEQUENCE":
		return "SEMANTIC_UNSTABLE"
	if not is_correct:
		return "SEMANTIC_UNSTABLE"
	return "NONE"

func _log_event(event_name: String, payload: Dictionary = {}) -> void:
	if task_session.is_empty():
		return
	var events: Array = task_session.get("events", [])
	events.append({
		"name": event_name,
		"t_ms": _trial_elapsed_ms(Time.get_ticks_msec()),
		"payload": payload
	})
	task_session["events"] = events

func _trial_elapsed_ms(now_ms: int) -> int:
	if case_started_ts <= 0:
		return 0
	return maxi(0, now_ms - case_started_ts)

func _set_input_locked(locked: bool) -> void:
	btn_undo.disabled = locked
	btn_clear.disabled = locked
	btn_submit.disabled = locked or selected_sequence_ids.is_empty()
	for block_id_v in repo_button_by_id.keys():
		var block_id: String = str(block_id_v)
		var btn_v: Variant = repo_button_by_id[block_id]
		if not (btn_v is Button):
			continue
		var btn: Button = btn_v as Button
		if locked:
			btn.disabled = true
		else:
			btn.disabled = selected_sequence_ids.has(block_id)

func _update_submit_state() -> void:
	btn_submit.disabled = trial_locked or not is_trial_active or selected_sequence_ids.is_empty()

func _update_timer_ui() -> void:
	timer_bar.value = time_left_sec
	var minutes: int = int(float(int(time_left_sec)) / 60.0)
	var seconds: int = int(time_left_sec) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]
	if time_left_sec <= 20.0:
		timer_label.modulate = Color(1.0, 0.4, 0.3, 1.0)
	else:
		timer_label.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _on_next_pressed() -> void:
	if session_finished:
		get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")
		return
	_load_next_case()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _finish_session() -> void:
	is_trial_active = false
	trial_locked = true
	session_finished = true
	typewriter_active = false
	_apply_complete_i18n()
	_set_status_i18n("da7.c.ui.status_complete", "Session complete.")
	btn_next.disabled = false
	btn_next.visible = true
	_set_input_locked(true)

func _on_stability_changed(_new_value: float, _delta: float) -> void:
	_update_stability_ui()

func _update_stability_ui() -> void:
	stability_label.text = _tr("da7.common.stability", "STABILITY: {value}%", {"value": int(GlobalMetrics.stability)})

func _install_body_scroll() -> void:
	if _body_scroll_installed:
		return
	if root_layout == null:
		return
	var prompt_node: Control = prompt_label
	if prompt_node == null or code_panel == null or repo_panel == null:
		return
	var existing_scroll: ScrollContainer = root_layout.get_node_or_null("BodyScroll") as ScrollContainer
	if existing_scroll != null and existing_scroll.get_node_or_null("BodyInner") != null:
		_body_scroll_installed = true
		return
	var scroll := ScrollContainer.new()
	scroll.name = "BodyScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.follow_focus = true
	var inner := VBoxContainer.new()
	inner.name = "BodyInner"
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 8)
	scroll.add_child(inner)
	var insert_index: int = prompt_node.get_index()
	root_layout.add_child(scroll)
	root_layout.move_child(scroll, insert_index)
	for node in [prompt_label, code_panel, repo_panel]:
		(node as Control).reparent(inner)
		(node as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body_scroll_installed = true

func _is_compact_phone() -> bool:
	var size: Vector2 = get_viewport_rect().size
	return (size.x >= size.y and size.y <= 420.0) or (size.y > size.x and size.x <= 520.0)

func _apply_compact_layout(compact: bool) -> void:
	prompt_label.custom_minimum_size.y = 48.0 if compact else 84.0
	code_panel.custom_minimum_size.y = 80.0 if compact else 140.0
	repo_panel.custom_minimum_size.y = 140.0 if compact else 220.0
	btn_undo.custom_minimum_size.y = 44.0 if compact else 56.0
	btn_clear.custom_minimum_size.y = 44.0 if compact else 56.0
	btn_submit.custom_minimum_size.y = 44.0 if compact else 56.0
	btn_next.custom_minimum_size.y = 44.0 if compact else 56.0
	status_label.custom_minimum_size.y = 28.0 if compact else 34.0
	for child in block_repository.get_children():
		if child is Button:
			(child as Button).custom_minimum_size.y = 44.0 if compact else 56.0
	block_repository.columns = 4 if (not compact and get_viewport_rect().size.x >= BREAKPOINT_PX) else (4 if get_viewport_rect().size.x > 600.0 else 3)

func _on_viewport_size_changed() -> void:
	var size: Vector2 = get_viewport_rect().size
	var compact: bool = _is_compact_phone()
	if size.x < BREAKPOINT_PX:
		current_layout = LAYOUT_MOBILE
		block_repository.columns = 4 if size.x > 600.0 else 3
	else:
		current_layout = LAYOUT_DESKTOP
		block_repository.columns = 4
	_apply_compact_layout(compact)
