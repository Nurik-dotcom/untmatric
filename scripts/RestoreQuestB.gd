extends Control

# --- CONFIGURATION ---
const LEVELS_PATH = "res://data/quest_b_levels.json"
const CODE_BLOCK_SCENE = preload("res://scripts/ui/CodeBlock.gd") # Script only, instanced as Button
const DIAGNOSTICS_SCENE = preload("res://scenes/ui/DiagnosticsPanelB.tscn") # Scene for panel

enum State { INIT, SOLVING_EMPTY, SOLVING_FILLED, SUBMITTING, FEEDBACK_SUCCESS, FEEDBACK_FAIL, DIAGNOSTIC, SAFE_MODE }

# --- NODES ---
@onready var main_layout = $MainLayout
@onready var lbl_clue_title = $MainLayout/Header/LblClueTitle
@onready var lbl_session = $MainLayout/Header/LblSessionId
@onready var decrypt_bar = $MainLayout/BarsRow/DecryptBar
@onready var energy_bar = $MainLayout/BarsRow/EnergyBar
@onready var lbl_target = $MainLayout/TargetDisplay/LblTarget
@onready var code_display = $MainLayout/TerminalFrame/CodeScroll/CodeDisplay
@onready var drop_zone = $MainLayout/SlotRow/DropZone
@onready var lbl_slot_hint = $MainLayout/SlotRow/LblSlotHint
@onready var blocks_container = $MainLayout/InventoryFrame/InventoryScroll/InventoryPadding/BlocksContainer
@onready var btn_analyze = $MainLayout/Actions/BtnAnalyze
@onready var btn_submit = $MainLayout/Actions/BtnSubmit
@onready var btn_next = $MainLayout/Actions/BtnNext
@onready var diag_dimmer = $DiagDimmer
@onready var diag_panel = $DiagnosticsPanelB

# --- AUDIO ---
# Reuse global audio if available or preload simple
const AUDIO_CLICK = preload("res://audio/click.wav")
const AUDIO_ERROR = preload("res://audio/error.wav")
const AUDIO_RELAY = preload("res://audio/relay.wav")

# --- DATA ---
var levels = []
var current_level_idx = 0
var current_task: Dictionary = {}
var state = State.INIT
var energy = 100.0
var wrong_count = 0
var task_started_at = 0
var task_session = {}
var switches_before_submit = 0
var hint_total_ms = 0
var hint_open_time = 0
var is_safe_mode = false
var variant_hash = ""
var result_sent = false
var paused_total_ms = 0
var pause_started_ticks = -1
var hint_open_effective_ms = -1

func _ready():
	_load_levels_from_json()
	_connect_signals()

	# Start
	current_level_idx = GlobalMetrics.current_level_index # Assume passed by QuestSelect
	if current_level_idx >= levels.size():
		current_level_idx = 0

	_start_level(current_level_idx)

func _load_levels_from_json():
	if not FileAccess.file_exists(LEVELS_PATH):
		push_error("Levels file not found: " + LEVELS_PATH)
		return

	var file = FileAccess.open(LEVELS_PATH, FileAccess.READ)
	var content = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(content)
	if error == OK:
		if typeof(json.data) != TYPE_ARRAY:
			push_error("Levels JSON root must be an array.")
			return
		var parsed_levels: Array = json.data
		levels.clear()
		for level_v in parsed_levels:
			if typeof(level_v) != TYPE_DICTIONARY:
				continue
			var level: Dictionary = level_v
			if _validate_level(level):
				levels.append(level)
			else:
				push_error("Invalid Restore B level: %s" % str(level.get("id", "UNKNOWN")))
	else:
		push_error("JSON Parse Error: " + json.get_error_message())

func _connect_signals():
	drop_zone.block_dropped.connect(_on_block_dropped)
	btn_analyze.pressed.connect(_on_analyze_pressed)
	btn_submit.pressed.connect(_on_submit_pressed)
	btn_next.pressed.connect(_on_next_pressed)
	# Connect close button of diag panel if exposed, or rely on internal logic.
	# But DiagnosticsPanelB script handles close button internally hiding self.
	# We want to track analyze_close event though.
	diag_panel.visibility_changed.connect(_on_diag_visibility_changed)
	diag_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	diag_dimmer.mouse_filter = Control.MOUSE_FILTER_STOP

func _start_level(idx):
	if idx >= levels.size():
		idx = 0 # Loop or finish

	current_level_idx = idx
	current_task = levels[idx].duplicate()
	variant_hash = str(hash(_build_variant_key(current_task)))

	task_started_at = Time.get_ticks_msec()
	task_session = {
		"task_id": current_task.id,
		"variant_hash": variant_hash,
		"started_at_ticks": task_started_at,
		"attempts": [],
		"events": [],
		"hint_total_ms": 0
	}

	# Reset State
	state = State.SOLVING_EMPTY
	energy = 100.0 # Or persist? usually reset per level in quests
	wrong_count = 0
	switches_before_submit = 0
	hint_total_ms = 0
	hint_open_time = 0
	paused_total_ms = 0
	pause_started_ticks = -1
	hint_open_effective_ms = -1
	is_safe_mode = false
	result_sent = false

	# UI Reset
	lbl_clue_title.text = "RESTORE " + current_task.id
	lbl_session.text = "SESS " + str(randi() % 9000 + 1000)
	lbl_target.text = "TARGET: s = " + str(current_task.target_s)

	_render_code()
	_render_inventory()
	drop_zone.setup(current_task.slot.slot_type)

	btn_submit.disabled = true
	btn_next.visible = false
	btn_analyze.disabled = false
	diag_panel.visible = false
	diag_dimmer.visible = false

	energy_bar.value = energy

	_log_event("task_start", {})

func _render_code():
	var lines = current_task.code_template
	var txt = ""
	for line in lines:
		# Replace [SLOT] with yellow text placeholder if desired, or let RichTextLabel handle it
		var processed_line = line.replace("[SLOT]", "[color=yellow][SLOT][/color]")
		txt += processed_line + "\n"
	code_display.text = txt

func _render_inventory():
	# Clear old
	for child in blocks_container.get_children():
		child.queue_free()

	# Add new
	for b_data in current_task.blocks:
		var btn = Button.new() # Using Button as base
		btn.set_script(CODE_BLOCK_SCENE)
		btn.setup(b_data)
		btn.custom_minimum_size = Vector2(160, 80)
		blocks_container.add_child(btn)

func _on_block_dropped(previous_block_id, data):
	_play_sound(AUDIO_CLICK)
	var new_id = data.get("block_id")

	# Logic: if slot was empty -> 0 switches (filling). If slot had block -> switch + 1.
	if state == State.SOLVING_EMPTY:
		state = State.SOLVING_FILLED
		btn_submit.disabled = false
		lbl_slot_hint.text = "Ready to check."
		# switches remain 0
	elif previous_block_id != null and str(previous_block_id) != str(new_id):
		switches_before_submit += 1

	_log_event("slot_changed", {"prev": previous_block_id, "new": new_id})
	# Spec 4.1: "max 1 block... old block return to inventory".
	# Implementation: Drag is COPY (infinite source) for simplicity and robustness in Control DnD.
	# Blocks are not consumed from inventory, so "returning" happens automatically (they never left).

func _on_submit_pressed():
	if state != State.SOLVING_FILLED: return

	state = State.SUBMITTING
	btn_submit.disabled = true

	var selected_id = drop_zone.get_block_id()
	var correct_id = current_task.correct_block_id
	var is_correct = (str(selected_id) == str(correct_id))
	var level_finished = false

	var now = Time.get_ticks_msec()
	var think_time_ms = _get_think_time_ms(now)

	# Log attempt
	var attempt = {
		"kind": "block_selection",
		"selected_block_id": selected_id,
		"switches_before_submit": switches_before_submit,
		"duration_input_ms_excluding_hint": think_time_ms,
		"hint_open_at_submit": diag_panel.visible,
		"correct": is_correct,
		"state_after": "PENDING"
	}

	if is_correct:
		_handle_success()
		attempt.state_after = "FEEDBACK_SUCCESS"
		level_finished = true
	else:
		level_finished = _handle_fail(selected_id)
		attempt.state_after = "FEEDBACK_FAIL"
		if is_safe_mode:
			attempt.state_after = "SAFE_MODE"

	task_session.attempts.append(attempt)
	_log_event("submit_pressed", {"correct": is_correct})

	if level_finished:
		_finalize_level_result(is_correct and not is_safe_mode)

func _handle_success():
	state = State.FEEDBACK_SUCCESS
	_play_sound(AUDIO_RELAY)

	# Visuals
	decrypt_bar.value += current_task.economy.reward
	drop_zone.modulate = Color(0, 1, 0) # Green tint
	btn_next.visible = true

func _handle_fail(selected_id) -> bool:
	wrong_count += 1
	_play_sound(AUDIO_ERROR)

	# Penalty
	energy -= current_task.economy.wrong_penalty
	energy_bar.value = energy

	# Visuals: return block
	drop_zone.reset()
	state = State.SOLVING_EMPTY
	lbl_slot_hint.text = _build_distractor_hint(selected_id)

	if wrong_count >= 3:
		_trigger_safe_mode()
		return true
	return false

func _trigger_safe_mode():
	state = State.SAFE_MODE
	is_safe_mode = true
	_on_analyze_pressed(true) # Free analyze

	# Allow Next
	btn_next.visible = true

func _on_analyze_pressed(free=false):
	if state == State.DIAGNOSTIC: return

	if not free:
		var cost = current_task.economy.analyze_cost
		if energy < cost:
			_play_sound(AUDIO_ERROR)
			return
		energy -= cost
		energy_bar.value = energy

	diag_panel.setup(current_task.explain_short, current_task.trace_correct)
	diag_panel.visible = true
	diag_dimmer.visible = true
	# Listener on visibility changed will handle state/timer

func _on_diag_visibility_changed():
	diag_dimmer.visible = diag_panel.visible
	if diag_panel.visible:
		# Opened
		hint_open_time = Time.get_ticks_msec()
		hint_open_effective_ms = _get_effective_elapsed_ms(hint_open_time)
		_log_event("analyze_open", {})
		# Pause interactions if needed?
		# State could be DIAGNOSTIC to block other inputs
		# But we are in a Control UI, usually modal blocks underneath.
	else:
		# Closed
		var duration = 0
		if hint_open_effective_ms >= 0:
			duration = max(0, _get_effective_elapsed_ms(Time.get_ticks_msec()) - hint_open_effective_ms)
		hint_total_ms += duration
		task_session.hint_total_ms = hint_total_ms
		_log_event("analyze_close", {"duration": duration})
		hint_open_time = 0
		hint_open_effective_ms = -1

func _on_next_pressed():
	if diag_panel.visible:
		diag_panel.visible = false
	diag_dimmer.visible = false
	_log_event("task_end", {})
	_start_level(current_level_idx + 1)

func _log_event(name, payload):
	var ev = {
		"name": name,
		"t_ms": Time.get_ticks_msec() - task_started_at,
		"payload": payload
	}
	task_session.events.append(ev)

func _play_sound(stream):
	var player = AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

func _finalize_level_result(is_correct: bool) -> void:
	if result_sent:
		return
	result_sent = true
	_finalize_pause_if_needed(Time.get_ticks_msec())
	task_session["ended_at_ticks"] = Time.get_ticks_msec()
	task_session["paused_total_ms"] = paused_total_ms
	task_session["hint_total_ms"] = hint_total_ms
	GlobalMetrics.register_trial(_build_result_payload(is_correct))

func _build_result_payload(is_correct: bool) -> Dictionary:
	var now_ticks = Time.get_ticks_msec()
	var elapsed_ms = _get_think_time_ms(now_ticks)
	var task_id = str(current_task.get("id", "B-00"))
	return {
		"match_key": "SUSPECT_RESTORE_B|%s" % task_id,
		"is_correct": is_correct,
		"is_fit": is_correct,
		"elapsed_ms": elapsed_ms,
		"duration": float(elapsed_ms) / 1000.0,
		"task_id": task_id,
		"variant_hash": variant_hash,
		"task_session": task_session
	}

func _build_variant_key(task: Dictionary) -> String:
	var code_text = ""
	var code_template: Array = task.get("code_template", [])
	for line in code_template:
		code_text += str(line) + "\n"

	var slot: Dictionary = task.get("slot", {})
	var slot_type = str(slot.get("slot_type", ""))

	var block_ids: Array = []
	var blocks: Array = task.get("blocks", [])
	for b in blocks:
		if typeof(b) == TYPE_DICTIONARY:
			block_ids.append(str(b.get("block_id", "")))
	block_ids.sort()

	return "%s|%s|%s|%s|%s" % [
		str(task.get("id", "")),
		code_text,
		str(task.get("target_s", "")),
		slot_type,
		",".join(block_ids)
	]

func _validate_level(level: Dictionary) -> bool:
	var required = ["id", "target_s", "code_template", "slot", "blocks", "correct_block_id", "economy"]
	for key in required:
		if not level.has(key):
			return false

	var slot: Dictionary = level.get("slot", {})
	var slot_type = str(slot.get("slot_type", ""))
	if slot_type != "INT" and slot_type != "OP":
		return false

	var blocks: Array = level.get("blocks", [])
	if blocks.is_empty():
		return false

	var ids: Array = []
	for block_v in blocks:
		if typeof(block_v) != TYPE_DICTIONARY:
			return false
		var block: Dictionary = block_v
		if str(block.get("slot_type", "")) != slot_type:
			return false
		ids.append(str(block.get("block_id", "")))

	return ids.has(str(level.get("correct_block_id", "")))

func _build_distractor_hint(selected_id) -> String:
	var feedback_map = current_task.get("distractor_feedback", {})
	if typeof(feedback_map) != TYPE_DICTIONARY:
		return "Incorrect. Try again."

	var entry = feedback_map.get(str(selected_id), null)
	if typeof(entry) != TYPE_DICTIONARY:
		return "Incorrect. Try again."

	var s_final = entry.get("s_final", null)
	var hint = str(entry.get("hint", ""))
	var target_s = str(current_task.get("target_s", "?"))
	if s_final == null:
		return hint if hint != "" else "Incorrect. Try again."
	return "Got s=%s, target s=%s. %s" % [str(s_final), target_s, hint]

func _get_effective_elapsed_ms(now_ticks: int) -> int:
	var total_paused = paused_total_ms
	if pause_started_ticks >= 0:
		total_paused += max(0, now_ticks - pause_started_ticks)
	return max(0, now_ticks - task_started_at - total_paused)

func _get_think_time_ms(now_ticks: int) -> int:
	return max(0, _get_effective_elapsed_ms(now_ticks) - hint_total_ms)

func _finalize_pause_if_needed(now_ticks: int) -> void:
	if pause_started_ticks >= 0:
		paused_total_ms += max(0, now_ticks - pause_started_ticks)
		pause_started_ticks = -1

func _notification(what: int) -> void:
	if task_started_at <= 0:
		return

	if what == MainLoop.NOTIFICATION_APPLICATION_PAUSED:
		if pause_started_ticks < 0:
			pause_started_ticks = Time.get_ticks_msec()
			_log_event("app_paused", {})
	elif what == MainLoop.NOTIFICATION_APPLICATION_RESUMED:
		if pause_started_ticks >= 0:
			var now_ticks = Time.get_ticks_msec()
			var pause_ms = max(0, now_ticks - pause_started_ticks)
			paused_total_ms += pause_ms
			pause_started_ticks = -1
			_log_event("app_resumed", {"pause_ms": pause_ms})
