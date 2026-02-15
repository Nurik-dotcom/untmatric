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

@onready var title_label: Label = $SafeArea/Margin/Root/Header/HeaderVBox/Title
@onready var stability_label: Label = $SafeArea/Margin/Root/Header/HeaderVBox/TimerRow/StabilityLabel
@onready var timer_bar: ProgressBar = $SafeArea/Margin/Root/Header/HeaderVBox/TimerRow/TimerBar
@onready var timer_label: Label = $SafeArea/Margin/Root/Header/HeaderVBox/TimerRow/TimerLabel
@onready var prompt_label: RichTextLabel = $SafeArea/Margin/Root/Prompt
@onready var code_area: HFlowContainer = $SafeArea/Margin/Root/CodePanel/CodeArea
@onready var btn_undo: Button = $SafeArea/Margin/Root/ControlsRow/BtnUndo
@onready var btn_clear: Button = $SafeArea/Margin/Root/ControlsRow/BtnClear
@onready var btn_submit: Button = $SafeArea/Margin/Root/ControlsRow/BtnSubmit
@onready var btn_next: Button = $SafeArea/Margin/Root/ControlsRow/BtnNext
@onready var status_label: Label = $SafeArea/Margin/Root/StatusLabel
@onready var block_repository: GridContainer = $SafeArea/Margin/Root/RepoPanel/RepoScroll/BlockRepository
@onready var sfx_click: AudioStreamPlayer = $SFX/SfxClick
@onready var sfx_error: AudioStreamPlayer = $SFX/SfxError
@onready var sfx_relay: AudioStreamPlayer = $SFX/SfxRelay

func _ready() -> void:
	randomize()
	if not GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.connect(_on_stability_changed)
	get_tree().root.size_changed.connect(_on_viewport_size_changed)
	btn_undo.pressed.connect(_on_undo_pressed)
	btn_clear.pressed.connect(_on_clear_pressed)
	btn_submit.pressed.connect(_on_submit_pressed)
	btn_next.pressed.connect(_on_next_pressed)

	_init_session()
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
		_finish_trial(false, "INCOMPLETE_QUERY", {"timed_out": true})

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
	clear_used = false
	selected_sequence_ids.clear()
	repo_button_by_id.clear()
	block_by_id.clear()
	_render_case()

func _render_case() -> void:
	var case_id: String = str(current_case.get("id", "DA7-C-00"))
	title_label.text = "CASE #7: MASTER SQL [%s]" % case_id
	var timing_policy: Dictionary = current_case.get("timing_policy", {}) as Dictionary
	limit_sec = int(timing_policy.get("limit_sec", 120))
	time_left_sec = float(limit_sec)
	timer_bar.max_value = max(1.0, float(limit_sec))
	timer_bar.value = timer_bar.max_value
	prompt_label.bbcode_enabled = true
	prompt_label.text = "[b]%s[/b]" % str(current_case.get("prompt", "Build SQL sequence."))
	prompt_label.visible_characters = 0
	typewriter_active = true
	typewriter_accum = 0.0
	allow_repeat_roles = ((current_case.get("constraints", {}) as Dictionary).get("allow_repeat_roles", []) as Array)
	_build_block_repository()
	_rebuild_code_area()
	_set_input_locked(false)
	btn_next.text = "NEXT"
	btn_next.visible = false
	status_label.text = "Compose query tokens and submit."
	_update_timer_ui()
	_update_stability_ui()

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
		btn.custom_minimum_size = Vector2(0, 56)
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
		status_label.text = "Role %s is already used." % role
		return
	selected_sequence_ids.append(block_id)
	block_pick_count += 1
	var btn: Button = repo_button_by_id.get(block_id, null) as Button
	if is_instance_valid(btn):
		btn.disabled = true
	if is_instance_valid(sfx_click):
		sfx_click.play()
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
		btn_left.custom_minimum_size = Vector2(36, 42)
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
		btn_right.custom_minimum_size = Vector2(36, 42)
		btn_right.disabled = idx >= selected_sequence_ids.size() - 1
		btn_right.pressed.connect(_on_move_token.bind(idx, 1))
		row.add_child(btn_right)

		var btn_remove: Button = Button.new()
		btn_remove.text = "X"
		btn_remove.custom_minimum_size = Vector2(36, 42)
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
	if is_instance_valid(sfx_click):
		sfx_click.play()
	_rebuild_code_area()

func _on_remove_token(index: int) -> void:
	if trial_locked or not is_trial_active:
		return
	if index < 0 or index >= selected_sequence_ids.size():
		return
	_register_interaction()
	var block_id: String = selected_sequence_ids[index]
	selected_sequence_ids.remove_at(index)
	var btn: Button = repo_button_by_id.get(block_id, null) as Button
	if is_instance_valid(btn):
		btn.disabled = false
	if is_instance_valid(sfx_click):
		sfx_click.play()
	_rebuild_code_area()

func _on_undo_pressed() -> void:
	if trial_locked or not is_trial_active:
		return
	if selected_sequence_ids.is_empty():
		return
	undo_count += 1
	_on_remove_token(selected_sequence_ids.size() - 1)

func _on_clear_pressed() -> void:
	if trial_locked or not is_trial_active:
		return
	clear_used = true
	selected_sequence_ids.clear()
	for block_id in repo_button_by_id.keys():
		var btn: Button = repo_button_by_id.get(block_id, null) as Button
		if is_instance_valid(btn):
			btn.disabled = false
	_rebuild_code_area()
	status_label.text = "Sequence cleared."

func _on_submit_pressed() -> void:
	if trial_locked or not is_trial_active:
		return
	_register_interaction()
	var eval_result: Dictionary = _evaluate_sequence(selected_sequence_ids)
	var is_correct: bool = bool(eval_result.get("is_correct", false))
	var f_reason: Variant = null if is_correct else str(eval_result.get("f_reason", "LOGIC_MISMATCH"))
	_finish_trial(is_correct, f_reason, eval_result)

func _finish_trial(is_correct: bool, f_reason: Variant, eval_result: Dictionary) -> void:
	trial_locked = true
	is_trial_active = false
	typewriter_active = false
	prompt_label.visible_characters = -1
	_set_input_locked(true)
	if is_correct:
		status_label.text = "ACCESS GRANTED. Query is valid."
		if is_instance_valid(sfx_relay):
			sfx_relay.play()
	else:
		status_label.text = "FAILED: %s" % str(f_reason)
		if is_instance_valid(sfx_error):
			sfx_error.play()
	_log_trial(is_correct, f_reason, eval_result)
	_update_stability_ui()
	btn_next.visible = true

func _evaluate_sequence(selected_ids: Array[String]) -> Dictionary:
	var constraints: Dictionary = current_case.get("constraints", {}) as Dictionary
	var required_roles: Array = constraints.get("required_roles", []) as Array
	var forbidden_roles: Array = constraints.get("forbidden_roles", []) as Array
	var skeleton_order: Array = constraints.get("skeleton_order", []) as Array
	var min_tokens: int = int(constraints.get("min_tokens", 1))
	var max_tokens: int = int(constraints.get("max_tokens", 64))
	var correct_ids: Array = current_case.get("correct_sequence_ids", []) as Array
	if selected_ids == correct_ids:
		return {
			"is_correct": true,
			"f_reason": null,
			"missing_roles": [],
			"selected_roles": _roles_for_ids(selected_ids)
		}

	var selected_roles: Array = _roles_for_ids(selected_ids)
	var missing_roles: Array = _missing_required_roles(selected_roles, required_roles)
	if selected_ids.size() < min_tokens or not missing_roles.is_empty():
		return {
			"is_correct": false,
			"f_reason": "INCOMPLETE_QUERY",
			"missing_roles": missing_roles,
			"selected_roles": selected_roles
		}

	if _contains_any_role(selected_roles, forbidden_roles):
		return {
			"is_correct": false,
			"f_reason": "SQL_SYNTAX_ERROR",
			"missing_roles": missing_roles,
			"selected_roles": selected_roles
		}

	if not _roles_follow_order(selected_roles, skeleton_order):
		return {
			"is_correct": false,
			"f_reason": "KEYWORD_ORDER",
			"missing_roles": missing_roles,
			"selected_roles": selected_roles
		}

	if selected_ids.size() > max_tokens or _has_extra_tokens(selected_ids, correct_ids):
		return {
			"is_correct": false,
			"f_reason": "EXTRA_TOKENS",
			"missing_roles": missing_roles,
			"selected_roles": selected_roles
		}

	return {
		"is_correct": false,
		"f_reason": "LOGIC_MISMATCH",
		"missing_roles": missing_roles,
		"selected_roles": selected_roles
	}

func _roles_for_ids(ids: Array[String]) -> Array:
	var roles: Array = []
	for id in ids:
		var block_data: Dictionary = block_by_id.get(id, {}) as Dictionary
		roles.append(str(block_data.get("role", "")))
	return roles

func _missing_required_roles(selected_roles: Array, required_roles: Array) -> Array:
	var lookup: Dictionary = {}
	for role_v in selected_roles:
		lookup[str(role_v)] = true
	var missing: Array = []
	for role_v in required_roles:
		var role: String = str(role_v)
		if not lookup.has(role):
			missing.append(role)
	return missing

func _contains_any_role(selected_roles: Array, forbidden_roles: Array) -> bool:
	var forbidden_lookup: Dictionary = {}
	for role_v in forbidden_roles:
		forbidden_lookup[str(role_v)] = true
	for role_v in selected_roles:
		if forbidden_lookup.has(str(role_v)):
			return true
	return false

func _roles_follow_order(selected_roles: Array, skeleton_order: Array) -> bool:
	var cursor: int = -1
	for required_role_v in skeleton_order:
		var required_role: String = str(required_role_v)
		var found_idx: int = -1
		for i in range(cursor + 1, selected_roles.size()):
			if str(selected_roles[i]) == required_role:
				found_idx = i
				break
		if found_idx < 0:
			return false
		cursor = found_idx
	return true

func _has_extra_tokens(selected_ids: Array[String], correct_ids: Array) -> bool:
	for id in selected_ids:
		if not correct_ids.has(id):
			return true
	return selected_ids.size() > correct_ids.size()

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

func _log_trial(is_correct: bool, f_reason: Variant, eval_result: Dictionary) -> void:
	var now_ms: int = Time.get_ticks_msec()
	var elapsed_ms: int = now_ms - case_started_ts
	var timing_policy: Dictionary = current_case.get("timing_policy", {}) as Dictionary
	var constraints: Dictionary = current_case.get("constraints", {}) as Dictionary
	var payload: Dictionary = {
		"quest_id": "DA7",
		"level": "C",
		"stage": "C",
		"case_id": str(current_case.get("id", "DA7-C-00")),
		"question_id": str(current_case.get("id", "DA7-C-00")),
		"interaction_type": str(current_case.get("interaction_type", "ASSEMBLE_BLOCKS")),
		"topic": str(current_case.get("topic", "DB_SQL")),
		"schema_version": str(current_case.get("schema_version", "DA7.C.v1")),
		"match_key": "DA7_C|%s" % str(current_case.get("id", "DA7-C-00")),
		"is_correct": is_correct,
		"f_reason": f_reason,
		"elapsed_ms": elapsed_ms,
		"duration": float(elapsed_ms) / 1000.0,
		"timing": {
			"policy_mode": str(timing_policy.get("mode", "EXAM")),
			"limit_sec": int(timing_policy.get("limit_sec", limit_sec)),
			"effective_elapsed_ms": elapsed_ms,
			"time_to_first_action_ms": max(0, time_to_first_action_ms)
		},
		"answer": {
			"selected_sequence_ids": selected_sequence_ids.duplicate(),
			"selected_roles": eval_result.get("selected_roles", [])
		},
		"expected": {
			"correct_sequence_ids": current_case.get("correct_sequence_ids", []),
			"required_roles": constraints.get("required_roles", []),
			"skeleton_order": constraints.get("skeleton_order", [])
		},
		"telemetry": {
			"reorder_count": reorder_count,
			"undo_count": undo_count,
			"block_pick_count": block_pick_count,
			"clear_used": clear_used
		},
		"flags": {
			"timed_out": timed_out
		},
		"ui": {
			"layout": current_layout,
			"vw": int(get_viewport_rect().size.x),
			"vh": int(get_viewport_rect().size.y)
		},
		"anti_cheat": current_case.get("anti_cheat", {}) as Dictionary
	}
	GlobalMetrics.register_trial(payload)

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
	var minutes: int = int(time_left_sec) / 60
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

func _finish_session() -> void:
	is_trial_active = false
	trial_locked = true
	session_finished = true
	typewriter_active = false
	title_label.text = "CASE #7: MASTER SQL [COMPLETE]"
	status_label.text = "Session complete."
	btn_next.text = "EXIT"
	btn_next.disabled = false
	btn_next.visible = true
	_set_input_locked(true)

func _on_stability_changed(_new_value: float, _delta: float) -> void:
	_update_stability_ui()

func _update_stability_ui() -> void:
	stability_label.text = "Stability: %d%%" % int(GlobalMetrics.stability)

func _on_viewport_size_changed() -> void:
	var size: Vector2 = get_viewport_rect().size
	if size.x < BREAKPOINT_PX:
		current_layout = LAYOUT_MOBILE
		block_repository.columns = 3
	else:
		current_layout = LAYOUT_DESKTOP
		block_repository.columns = 4
