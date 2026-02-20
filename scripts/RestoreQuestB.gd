extends Control

const LEVELS_PATH := "res://data/quest_b_levels.json"
const CODE_BLOCK_SCENE := preload("res://scripts/ui/CodeBlock.gd")
const MAX_ATTEMPTS := 3

const AUDIO_CLICK := preload("res://audio/click.wav")
const AUDIO_ERROR := preload("res://audio/error.wav")
const AUDIO_RELAY := preload("res://audio/relay.wav")

enum State {
	INIT,
	SOLVING_EMPTY,
	SOLVING_FILLED,
	SUBMITTING,
	FEEDBACK_SUCCESS,
	FEEDBACK_FAIL,
	DIAGNOSTIC,
	SAFE_MODE
}

@onready var lbl_clue_title: Label = $MainLayout/Header/LblClueTitle
@onready var lbl_session: Label = $MainLayout/Header/LblSessionId
@onready var btn_back: Button = $MainLayout/Header/BtnBack
@onready var decrypt_bar: ProgressBar = $MainLayout/BarsRow/DecryptBar
@onready var energy_bar: ProgressBar = $MainLayout/BarsRow/EnergyBar
@onready var lbl_target: Label = $MainLayout/TargetDisplay/LblTarget
@onready var code_display: RichTextLabel = $MainLayout/TerminalFrame/CodeScroll/CodeDisplay
@onready var drop_zone: PanelContainer = $MainLayout/SlotRow/DropZone
@onready var lbl_slot_hint: Label = $MainLayout/SlotRow/LblSlotHint
@onready var blocks_container: HBoxContainer = $MainLayout/InventoryFrame/InventoryMargin/InventoryScroll/BlocksContainer
@onready var btn_analyze: Button = $MainLayout/Actions/BtnAnalyze
@onready var btn_submit: Button = $MainLayout/Actions/BtnSubmit
@onready var btn_next: Button = $MainLayout/Actions/BtnNext
@onready var diagnostics_blocker: ColorRect = $DiagnosticsBlocker
@onready var diag_panel: PanelContainer = $DiagnosticsPanelB

var levels: Array = []
var current_level_idx := 0
var current_task: Dictionary = {}
var state: State = State.INIT
var energy := 100.0
var wrong_count := 0
var task_started_at := 0
var t_start_ticks := 0
var paused_total_ms := 0
var pause_started_ticks := -1
var hint_total_ms := 0
var hint_open_time := 0
var switches_before_submit := 0
var is_safe_mode := false
var variant_hash := ""
var level_result_sent := false
var task_session: Dictionary = {}

func _ready() -> void:
	_load_levels_from_json()
	_connect_signals()

	diag_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	diagnostics_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	diagnostics_blocker.visible = false
	diag_panel.visible = false

	current_level_idx = GlobalMetrics.current_level_index
	if current_level_idx < 0 or current_level_idx >= levels.size():
		current_level_idx = 0

	_start_level(current_level_idx)

func _load_levels_from_json() -> void:
	levels.clear()
	if not FileAccess.file_exists(LEVELS_PATH):
		push_error("Levels file not found: " + LEVELS_PATH)
		return

	var file := FileAccess.open(LEVELS_PATH, FileAccess.READ)
	if file == null:
		push_error("Unable to open levels file: " + LEVELS_PATH)
		return

	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("JSON parse error in quest_b_levels.json: " + json.get_error_message())
		return

	if typeof(json.data) != TYPE_ARRAY:
		push_error("quest_b_levels.json root must be an array.")
		return

	for raw_level in json.data:
		if typeof(raw_level) != TYPE_DICTIONARY:
			continue
		var level: Dictionary = raw_level
		if _validate_level(level):
			levels.append(level)
		else:
			push_warning("Skipping invalid RestoreQuestB level: " + str(level.get("id", "UNKNOWN")))

func _validate_level(level: Dictionary) -> bool:
	var slot: Dictionary = level.get("slot", {})
	var blocks: Array = level.get("blocks", [])
	var slot_type: String = str(slot.get("slot_type", ""))
	if slot_type != "INT" and slot_type != "OP":
		return false
	if blocks.is_empty():
		return false

	var has_correct := false
	var correct_id := str(level.get("correct_block_id", ""))
	for b in blocks:
		if typeof(b) != TYPE_DICTIONARY:
			return false
		var block: Dictionary = b
		if str(block.get("slot_type", "")) != slot_type:
			return false
		if str(block.get("block_id", "")) == correct_id:
			has_correct = true
	return has_correct

func _connect_signals() -> void:
	drop_zone.block_dropped.connect(_on_block_dropped)
	btn_back.pressed.connect(_on_back_pressed)
	btn_analyze.pressed.connect(_on_analyze_pressed)
	btn_submit.pressed.connect(_on_submit_pressed)
	btn_next.pressed.connect(_on_next_pressed)
	diag_panel.visibility_changed.connect(_on_diag_visibility_changed)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func build_variant_key(task: Dictionary) -> String:
	var code: String = "\n".join(task.get("code_template", []))
	var target := str(task.get("target_s", ""))
	var slot: Dictionary = task.get("slot", {})
	var slot_type := str(slot.get("slot_type", ""))
	var ids: Array[String] = []
	for b in task.get("blocks", []):
		if typeof(b) == TYPE_DICTIONARY:
			ids.append(str((b as Dictionary).get("block_id", "")))
	ids.sort()
	return "%s|%s|%s|%s|%s" % [str(task.get("id", "")), code, target, slot_type, ",".join(ids)]

func _start_level(idx: int) -> void:
	if levels.is_empty():
		return
	if idx >= levels.size():
		idx = 0

	current_level_idx = idx
	current_task = (levels[idx] as Dictionary).duplicate(true)
	variant_hash = str(hash(build_variant_key(current_task)))
	t_start_ticks = Time.get_ticks_msec()
	task_started_at = t_start_ticks
	paused_total_ms = 0
	pause_started_ticks = -1
	level_result_sent = false

	task_session = {
		"task_id": str(current_task.get("id", "B-00")),
		"variant_hash": variant_hash,
		"started_at_ticks": t_start_ticks,
		"ended_at_ticks": 0,
		"attempts": [],
		"events": [],
		"hint_total_ms": 0,
		"paused_total_ms": 0
	}

	state = State.SOLVING_EMPTY
	energy = 100.0
	wrong_count = 0
	hint_total_ms = 0
	hint_open_time = 0
	switches_before_submit = 0
	is_safe_mode = false

	lbl_clue_title.text = "ВОССТАНОВЛЕНИЕ " + str(current_task.get("id", "B-00"))
	lbl_session.text = "СЕСС " + str(randi() % 9000 + 1000)
	lbl_target.text = "ЦЕЛЬ: s = " + str(current_task.get("target_s", "?"))
	lbl_slot_hint.text = "<-- Перетащите блок сюда"

	_render_code()
	_render_inventory()
	drop_zone.call("setup", str(current_task.get("slot", {}).get("slot_type", "INT")))
	drop_zone.modulate = Color(1, 1, 1, 1)

	btn_submit.disabled = true
	btn_analyze.disabled = false
	btn_next.visible = false
	energy_bar.value = energy

	diagnostics_blocker.visible = false
	diag_panel.visible = false

	_log_event("task_start", {"bucket": str(current_task.get("bucket", "unknown"))})

func _render_code() -> void:
	var txt := ""
	for line in current_task.get("code_template", []):
		var processed := str(line).replace("[SLOT]", "[color=yellow][SLOT][/color]")
		txt += processed + "\n"
	code_display.text = txt

func _render_inventory() -> void:
	for child in blocks_container.get_children():
		child.queue_free()

	for b_data in current_task.get("blocks", []):
		if typeof(b_data) != TYPE_DICTIONARY:
			continue
		var btn := Button.new()
		btn.set_script(CODE_BLOCK_SCENE)
		btn.call("setup", b_data)
		btn.custom_minimum_size = Vector2(160, 80)
		blocks_container.add_child(btn)

func _on_block_dropped(data: Dictionary) -> void:
	_play_sound(AUDIO_CLICK)

	var prev_id: Variant = drop_zone.call("get_last_prev_block_id")
	var new_id: Variant = data.get("block_id", null)
	if prev_id != null and new_id != null and str(prev_id) != str(new_id):
		switches_before_submit += 1

	state = State.SOLVING_FILLED
	btn_submit.disabled = false
	lbl_slot_hint.text = "Готово к проверке."

	_log_event("slot_changed", {"prev": prev_id, "new": new_id})

func _on_submit_pressed() -> void:
	if state != State.SOLVING_FILLED:
		return

	state = State.SUBMITTING
	btn_submit.disabled = true

	var selected_id: Variant = drop_zone.call("get_block_id")
	var correct_id: Variant = current_task.get("correct_block_id", null)
	var is_correct := str(selected_id) == str(correct_id)
	var end_ticks := Time.get_ticks_msec()
	var elapsed_input_ms := _effective_elapsed_ms(end_ticks)
	var is_terminal_fail := (not is_correct) and (wrong_count + 1 >= MAX_ATTEMPTS)
	var state_after := "FEEDBACK_SUCCESS" if is_correct else ("SAFE_MODE" if is_terminal_fail else "FEEDBACK_FAIL")

	var attempt := {
		"kind": "block_selection",
		"selected_block_id": selected_id,
		"correct_block_id": correct_id,
		"switches_before_submit": switches_before_submit,
		"duration_input_ms": elapsed_input_ms,
		"duration_input_ms_excluding_hint": elapsed_input_ms,
		"hint_open_at_submit": diag_panel.visible,
		"correct": is_correct,
		"state_after": state_after
	}
	(task_session["attempts"] as Array).append(attempt)
	_log_event("submit_pressed", {"correct": is_correct, "selected": selected_id})

	if is_correct:
		_handle_success(end_ticks)
	elif is_terminal_fail:
		wrong_count += 1
		_handle_fail_terminal(end_ticks)
	else:
		wrong_count += 1
		_handle_fail_retry(selected_id)

func _handle_success(end_ticks: int) -> void:
	state = State.FEEDBACK_SUCCESS
	_play_sound(AUDIO_RELAY)
	drop_zone.modulate = Color(0.3, 1.0, 0.3, 1.0)
	decrypt_bar.value += float(current_task.get("economy", {}).get("reward", 0))
	btn_analyze.disabled = true
	btn_submit.disabled = true
	btn_next.visible = true
	_register_result(true, end_ticks, "SUCCESS")

func _handle_fail_retry(selected_id) -> void:
	state = State.FEEDBACK_FAIL
	_play_sound(AUDIO_ERROR)
	energy = maxf(0.0, energy - float(current_task.get("economy", {}).get("wrong_penalty", 0)))
	energy_bar.value = energy
	drop_zone.call("reset")
	drop_zone.modulate = Color(1, 1, 1, 1)
	lbl_slot_hint.text = "Неверно. Попробуйте снова."
	state = State.SOLVING_EMPTY
	btn_submit.disabled = true
	_show_distractor_feedback(selected_id)

func _handle_fail_terminal(end_ticks: int) -> void:
	_play_sound(AUDIO_ERROR)
	energy = maxf(0.0, energy - float(current_task.get("economy", {}).get("wrong_penalty", 0)))
	energy_bar.value = energy
	_trigger_safe_mode(end_ticks)

func _trigger_safe_mode(end_ticks: int) -> void:
	state = State.SAFE_MODE
	is_safe_mode = true
	_on_analyze_pressed(true)
	btn_analyze.disabled = true
	btn_submit.disabled = true
	btn_next.visible = true
	_log_event("safe_mode_triggered", {})
	_register_result(false, end_ticks, "SAFE_MODE")

func _on_analyze_pressed(free := false) -> void:
	if diag_panel.visible:
		return

	if not free:
		var cost := int(current_task.get("economy", {}).get("analyze_cost", 0))
		if energy < float(cost):
			_play_sound(AUDIO_ERROR)
			return
		energy -= float(cost)
		energy_bar.value = energy

	diag_panel.call(
		"setup",
		current_task.get("explain_short", []),
		current_task.get("trace_correct", [])
	)
	diag_panel.visible = true

func _on_diag_visibility_changed() -> void:
	if diag_panel.visible:
		diagnostics_blocker.visible = true
		if pause_started_ticks == -1:
			hint_open_time = Time.get_ticks_msec()
		_log_event("analyze_open", {})
	else:
		diagnostics_blocker.visible = false
		var duration := _consume_open_hint_duration(Time.get_ticks_msec())
		if duration > 0:
			_log_event("analyze_close", {"duration_ms": duration})

func _notification(what: int) -> void:
	if t_start_ticks <= 0:
		return
	if what == MainLoop.NOTIFICATION_APPLICATION_PAUSED:
		_on_app_paused()
	elif what == MainLoop.NOTIFICATION_APPLICATION_RESUMED:
		_on_app_resumed()

func _on_app_paused() -> void:
	if pause_started_ticks != -1:
		return
	var now_ticks := Time.get_ticks_msec()
	pause_started_ticks = now_ticks
	_consume_open_hint_duration(now_ticks)
	_log_event("app_paused", {})

func _on_app_resumed() -> void:
	if pause_started_ticks == -1:
		return
	var now_ticks := Time.get_ticks_msec()
	var paused_ms := maxi(0, now_ticks - pause_started_ticks)
	paused_total_ms += paused_ms
	pause_started_ticks = -1
	task_session["paused_total_ms"] = paused_total_ms
	if diag_panel.visible:
		hint_open_time = now_ticks
	_log_event("app_resumed", {"paused_ms": paused_ms})

func _on_next_pressed() -> void:
	if diag_panel.visible:
		diag_panel.visible = false
	_log_event("next_pressed", {"from_task": str(current_task.get("id", "B-00"))})
	_start_level(current_level_idx + 1)

func _register_result(is_correct: bool, end_ticks: int, reason: String) -> void:
	if level_result_sent:
		return
	level_result_sent = true

	var elapsed_ms := _effective_elapsed_ms(end_ticks)
	task_session["ended_at_ticks"] = end_ticks
	task_session["hint_total_ms"] = hint_total_ms
	task_session["paused_total_ms"] = paused_total_ms
	_log_event("task_end", {"reason": reason, "is_correct": is_correct})

	var payload := {
		"match_key": "RESTORE_B|%s" % str(current_task.get("id", "B-00")),
		"is_correct": is_correct,
		"is_fit": is_correct,
		"elapsed_ms": elapsed_ms,
		"duration": float(elapsed_ms) / 1000.0,
		"task_id": str(current_task.get("id", "B-00")),
		"variant_hash": variant_hash,
		"task_session": task_session
	}
	GlobalMetrics.register_trial(payload)

func _log_event(name: String, payload: Dictionary) -> void:
	var events: Array = task_session.get("events", [])
	events.append({
		"name": name,
		"t_ms": _effective_elapsed_ms(Time.get_ticks_msec()),
		"payload": payload
	})
	task_session["events"] = events

func _effective_elapsed_ms(now_ticks: int) -> int:
	return maxi(0, (now_ticks - t_start_ticks) - paused_total_ms - hint_total_ms)

func _consume_open_hint_duration(until_ticks: int) -> int:
	if hint_open_time <= 0:
		return 0
	var duration := maxi(0, until_ticks - hint_open_time)
	hint_total_ms += duration
	task_session["hint_total_ms"] = hint_total_ms
	hint_open_time = 0
	return duration

func _show_distractor_feedback(selected_id) -> void:
	var map: Variant = current_task.get("distractor_feedback", {})
	if typeof(map) != TYPE_DICTIONARY:
		return
	var key := str(selected_id)
	if not map.has(key):
		return
	var feedback: Variant = map[key]
	if typeof(feedback) != TYPE_DICTIONARY:
		return

	var s_final = str((feedback as Dictionary).get("s_final", "?"))
	var hint = str((feedback as Dictionary).get("hint", ""))
	var target = str(current_task.get("target_s", "?"))
	var explain_lines := [
		"Получилось s=%s, нужно s=%s." % [s_final, target],
		hint
	]
	diag_panel.call("setup", explain_lines, [])
	diag_panel.visible = true
	_log_event("distractor_feedback_shown", {"selected": key, "s_final": s_final})

func _play_sound(stream: AudioStream) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
