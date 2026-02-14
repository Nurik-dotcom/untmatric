extends Control

# --- CONFIGURATION ---
const LEVELS_PATH = "res://data/quest_c_levels.json"
const DIAGNOSTICS_SCENE = preload("res://scenes/ui/DiagnosticsPanelC.tscn")

enum State { INIT, LINE_SELECT, FIX_MENU, READY_TO_VERIFY, VERIFY, FEEDBACK_SUCCESS, FEEDBACK_FAIL, DIAGNOSTIC, SAFE_MODE }

# --- NODES ---
@onready var lbl_clue_title = $MainLayout/HeaderRow/LblClueTitle
@onready var lbl_session = $MainLayout/HeaderRow/LblSession
@onready var expected_panel = $MainLayout/StatusMonitor/MonitorsRow/ExpectedPanel
@onready var lbl_expected_val = $MainLayout/StatusMonitor/MonitorsRow/ExpectedPanel/VBox/LblExpectedValue
@onready var actual_panel = $MainLayout/StatusMonitor/MonitorsRow/ActualPanel
@onready var lbl_actual_val = $MainLayout/StatusMonitor/MonitorsRow/ActualPanel/VBox/LblActualValue
@onready var code_view = $MainLayout/BodyRow/CodeFrame/CodeView
@onready var lbl_hint = $MainLayout/BodyRow/SideInfo/LblHint
@onready var misclick_label = $MainLayout/BodyRow/SideInfo/MisclickCounter
@onready var btn_analyze = $MainLayout/ActionsRow/BtnAnalyze
@onready var btn_verify = $MainLayout/ActionsRow/BtnVerify
@onready var btn_next = $MainLayout/ActionsRow/BtnNext
@onready var fix_menu = $FixMenuC
@onready var diag_panel = $DiagnosticsPanelC

# --- AUDIO ---
const AUDIO_CLICK = preload("res://audio/click.wav")
const AUDIO_ERROR = preload("res://audio/error.wav")
const AUDIO_RELAY = preload("res://audio/relay.wav")

# --- DATA ---
var levels = []
var current_level_idx = 0
var current_task: Dictionary = {}
var state = State.INIT
var task_started_at = 0
var task_session = {}
var misclicks_before_correct = 0
var wrong_fix_attempts_before_correct = 0
var selected_line_index = -1
var selected_fix_option_id = null
var variant_hash = ""

func _ready():
	_load_levels_from_json()
	_connect_signals()

	current_level_idx = GlobalMetrics.current_level_index
	if current_level_idx >= levels.size():
		current_level_idx = 0

	if levels.size() > 0:
		_start_level(current_level_idx)
	else:
		lbl_hint.text = "No levels loaded."

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
	code_view.caret_changed.connect(_on_caret_changed)
	# Also handle gui_input for clicks if needed, but caret_changed is usually enough for selection
	fix_menu.option_selected.connect(_on_fix_option_selected)
	btn_verify.pressed.connect(_on_verify_pressed)
	btn_analyze.pressed.connect(_on_analyze_pressed)
	btn_next.pressed.connect(_on_next_pressed)

func _start_level(idx):
	if idx >= levels.size():
		idx = 0

	current_level_idx = idx
	current_task = levels[idx].duplicate()

	task_started_at = Time.get_ticks_msec()
	task_session = {
		"task_id": current_task.id,
		"variant_hash": str(hash(str(current_task))),
		"started_at_ticks": task_started_at,
		"attempts": [],
		"events": []
	}
	variant_hash = task_session.variant_hash

	# Reset State
	state = State.LINE_SELECT
	misclicks_before_correct = 0
	wrong_fix_attempts_before_correct = 0
	selected_line_index = -1
	selected_fix_option_id = null

	# UI Reset
	lbl_clue_title.text = "CASE " + current_task.id + ": DISARM"
	lbl_session.text = "SESS " + str(randi() % 9000 + 1000)
	lbl_expected_val.text = "s = " + str(current_task.expected_s)
	lbl_actual_val.text = "s = " + str(current_task.actual_s)
	lbl_actual_val.modulate = Color(1, 0.2, 0.2) # Red
	lbl_expected_val.modulate = Color(0, 1, 0.25) # Green

	# Reset Panels Color (overrides)
	# Assuming themes are used, we can just set modulate or stylebox override if needed
	actual_panel.modulate = Color(1, 1, 1)

	misclick_label.text = "MISCLICKS: 0"
	lbl_hint.text = current_task.briefing

	code_view.text = ""
	code_view.clear_executing_lines()
	code_view.text = "\n".join(current_task.code_lines)

	btn_verify.disabled = true
	btn_next.visible = false
	btn_analyze.disabled = false

	_log_event("task_start", {})

func _on_caret_changed():
	if state != State.LINE_SELECT and state != State.READY_TO_VERIFY:
		return

	var line = code_view.get_caret_line()
	# Debounce or check valid
	if line < 0 or line >= current_task.code_lines.size():
		return

	_handle_line_click(line)

func _handle_line_click(line_idx):
	_log_event("line_clicked", {"line": line_idx})

	# Only process click if we are selecting lines
	if state != State.LINE_SELECT and state != State.READY_TO_VERIFY:
		return

	var correct_line = int(current_task.bug.correct_line_index)
	if line_idx == correct_line:
		# Correct line found
		selected_line_index = line_idx
		_play_sound(AUDIO_CLICK)
		_open_fix_menu()
	else:
		# Wrong line
		misclicks_before_correct += 1
		misclick_label.text = "MISCLICKS: " + str(misclicks_before_correct)
		_play_sound(AUDIO_ERROR)
		_flash_error()

func _open_fix_menu():
	state = State.FIX_MENU
	var line_text = current_task.code_lines[selected_line_index]
	fix_menu.setup(line_text, current_task.bug.fix_options)
	fix_menu.popup_centered()
	_log_event("fix_menu_open", {})

func _on_fix_option_selected(option_id):
	selected_fix_option_id = option_id
	state = State.READY_TO_VERIFY
	btn_verify.disabled = false

	lbl_hint.text = "Patch ready. Verify?"
	_log_event("fix_selected", {"option_id": option_id})

func _on_verify_pressed():
	if state != State.READY_TO_VERIFY: return

	state = State.VERIFY
	btn_verify.disabled = true

	var correct_line = int(current_task.bug.correct_line_index)
	var correct_opt = str(current_task.bug.correct_option_id)

	var is_correct = (selected_line_index == correct_line and selected_fix_option_id == correct_opt)

	var now = Time.get_ticks_msec()
	var attempt = {
		"kind": "debugging",
		"task_id": current_task.id,
		"variant_hash": variant_hash,
		"selected_line_index": selected_line_index,
		"fix_option_id": selected_fix_option_id,
		"correct": is_correct,
		"effective_time_ms": now - task_started_at,
		"misclicks_before_correct": misclicks_before_correct,
		"wrong_fix_attempts_before_correct": wrong_fix_attempts_before_correct
	}

	task_session.attempts.append(attempt)
	_log_event("verify_pressed", {"correct": is_correct})

	if is_correct:
		_handle_success()
	else:
		_handle_fail()

func _handle_success():
	state = State.FEEDBACK_SUCCESS
	_play_sound(AUDIO_RELAY)

	# Visuals
	lbl_actual_val.text = "s = " + str(current_task.expected_s)
	lbl_actual_val.modulate = Color(0, 1, 0.25)
	lbl_hint.text = "ACCESS GRANTED. SYSTEM STABILIZED."

	# Apply fix to code view visual
	var options = current_task.bug.fix_options
	var new_line = ""
	for opt in options:
		if opt.option_id == selected_fix_option_id:
			new_line = opt.replace_line

	# Safety check if line valid
	if selected_line_index >= 0 and selected_line_index < code_view.get_line_count():
		code_view.set_line(selected_line_index, new_line)
		# Highlight green
		code_view.set_line_background_color(selected_line_index, Color(0, 0.5, 0.1, 0.3))

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
	wrong_fix_attempts_before_correct += 1
	_play_sound(AUDIO_ERROR)

	# Get result s for explanation
	var actual_result = "?"
	for opt in current_task.bug.fix_options:
		if opt.option_id == selected_fix_option_id:
			actual_result = str(opt.get("result_s", "?"))

	lbl_actual_val.text = "s = " + actual_result
	_flash_error()

	lbl_hint.text = "Patch failed. Result: " + actual_result + ". Try another fix."

	# Return to line selection to try again
	state = State.LINE_SELECT
	selected_fix_option_id = null
	btn_verify.disabled = true

func _on_analyze_pressed():
	diag_panel.setup(current_task.explain_short)
	diag_panel.visible = true

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

func _flash_error():
	var tween = create_tween()
	actual_panel.modulate = Color(2, 0.5, 0.5)
	tween.tween_property(actual_panel, "modulate", Color(1, 1, 1), 0.3)
