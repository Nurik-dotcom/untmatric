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
@onready var blocks_container = $MainLayout/InventoryFrame/InventoryScroll/BlocksContainer
@onready var btn_analyze = $MainLayout/Actions/BtnAnalyze
@onready var btn_submit = $MainLayout/Actions/BtnSubmit
@onready var btn_next = $MainLayout/Actions/BtnNext
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
		levels = json.data
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

func _start_level(idx):
	if idx >= levels.size():
		idx = 0 # Loop or finish

	current_level_idx = idx
	current_task = levels[idx].duplicate()

	task_started_at = Time.get_ticks_msec()
	task_session = {
		"task_id": current_task.id,
		"variant_hash": str(hash(str(current_task))),
		"started_at_ticks": task_started_at,
		"attempts": [],
		"events": [],
		"hint_total_ms": 0
	}
	variant_hash = task_session.variant_hash

	# Reset State
	state = State.SOLVING_EMPTY
	energy = 100.0 # Or persist? usually reset per level in quests
	wrong_count = 0
	switches_before_submit = 0
	hint_total_ms = 0
	is_safe_mode = false

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
		blocks_container.add_child(btn)

func _on_block_dropped(data):
	_play_sound(AUDIO_CLICK)

	# Logic: if slot was empty -> 0 switches (filling). If slot had block -> switch + 1.
	if state == State.SOLVING_EMPTY:
		state = State.SOLVING_FILLED
		btn_submit.disabled = false
		lbl_slot_hint.text = "Ready to check."
		# switches remain 0
	else:
		switches_before_submit += 1

	_log_event("slot_changed", {"new_block": data.block_id})
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

	var now = Time.get_ticks_msec()

	# Log attempt
	var attempt = {
		"kind": "block_selection",
		"selected_block_id": selected_id,
		"switches_before_submit": switches_before_submit,
		"duration_input_ms_excluding_hint": (now - task_started_at) - hint_total_ms,
		"hint_open_at_submit": diag_panel.visible,
		"correct": is_correct,
		"state_after": "PENDING"
	}

	if is_correct:
		_handle_success()
		attempt.state_after = "FEEDBACK_SUCCESS"
	else:
		_handle_fail()
		attempt.state_after = "FEEDBACK_FAIL"
		if is_safe_mode:
			attempt.state_after = "SAFE_MODE"

	task_session.attempts.append(attempt)
	_log_event("submit_pressed", {"correct": is_correct})

func _handle_success():
	state = State.FEEDBACK_SUCCESS
	_play_sound(AUDIO_RELAY)

	# Visuals
	decrypt_bar.value += current_task.economy.reward
	drop_zone.modulate = Color(0, 1, 0) # Green tint
	btn_next.visible = true

	# Metrics
	var result_data = {
		"is_correct": true,
		"is_fit": true,
		"task_id": current_task.id,
		"variant_hash": variant_hash,
		"time_ms": Time.get_ticks_msec() - task_started_at,
		"task_session": task_session
	}
	GlobalMetrics.register_trial(result_data)

func _handle_fail():
	wrong_count += 1
	_play_sound(AUDIO_ERROR)

	# Penalty
	energy -= current_task.economy.wrong_penalty
	energy_bar.value = energy

	# Visuals: return block
	drop_zone.reset()
	state = State.SOLVING_EMPTY
	lbl_slot_hint.text = "Incorrect. Try again."

	if wrong_count >= 3:
		_trigger_safe_mode()

func _trigger_safe_mode():
	state = State.SAFE_MODE
	is_safe_mode = true
	_on_analyze_pressed(true) # Free analyze

	# Register Fail
	var result_data = {
		"is_correct": false,
		"is_fit": false,
		"task_id": current_task.id,
		"variant_hash": variant_hash,
		"time_ms": Time.get_ticks_msec() - task_started_at,
		"task_session": task_session
	}
	GlobalMetrics.register_trial(result_data)

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
	# Listener on visibility changed will handle state/timer

func _on_diag_visibility_changed():
	if diag_panel.visible:
		# Opened
		hint_open_time = Time.get_ticks_msec()
		_log_event("analyze_open", {})
		# Pause interactions if needed?
		# State could be DIAGNOSTIC to block other inputs
		# But we are in a Control UI, usually modal blocks underneath.
	else:
		# Closed
		var duration = Time.get_ticks_msec() - hint_open_time
		hint_total_ms += duration
		task_session.hint_total_ms = hint_total_ms
		_log_event("analyze_close", {"duration": duration})

func _on_next_pressed():
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
