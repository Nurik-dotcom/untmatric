extends Control

# Data & Config
const CasesModule = preload("res://scripts/case_07/da7_cases_a.gd")
const BREAKPOINT_PX = 820
const SESSION_CASE_COUNT = 8

# State
var session_cases: Array = []
var current_case_index: int = 0
var current_case: Dictionary = {}
var is_trial_active: bool = false
var is_game_over: bool = false

# Telemetry State
var stability_start: float = 0.0
var ui_ready_ts: float = 0.0
var time_to_first_action_ms: float = -1.0
var scroll_used: bool = false
var click_timestamps: Array[float] = []
var lag_compensation_ms: float = 0.0

# Nodes
@onready var desktop_layout = $RootLayout/Body/DesktopLayout
@onready var mobile_layout = $RootLayout/Body/MobileLayout
@onready var table_section = $TableSection # Initially separate or placeholder, we will reparent
@onready var task_section = $TaskSection   # Initially separate or placeholder

# We will need to find where TableSection/TaskSection are initially.
# Plan: In the scene, put them as children of a "ContentHolder" or just under DesktopLayout initially.
# I'll assume they start under DesktopLayout.

@onready var data_tree: Tree = $RootLayout/Body/DesktopLayout/TableSection/DataTree
@onready var prompt_label: RichTextLabel = $RootLayout/Body/DesktopLayout/TaskSection/PromptLabel
@onready var options_grid: GridContainer = $RootLayout/Body/DesktopLayout/TaskSection/OptionsGrid
@onready var stability_bar: ProgressBar = $RootLayout/Footer/StabilityBar
@onready var stability_label: Label = $RootLayout/Footer/StabilityLabel
@onready var title_label: RichTextLabel = $RootLayout/Header/Title

# Audio
@onready var sfx_click = $Runtime/Audio/SfxClick
@onready var sfx_error = $Runtime/Audio/SfxError
@onready var sfx_relay = $Runtime/Audio/SfxRelay

# Timers
@onready var typewriter_timer: Timer = $Runtime/TypewriterTimer

func _ready():
	randomize()
	_init_session()

	# Initial layout check
	get_tree().root.size_changed.connect(_on_viewport_size_changed)
	# Defer to ensure nodes are ready for reparenting if needed
	call_deferred("_on_viewport_size_changed")

	_load_next_case()

func _process(delta):
	if is_trial_active:
		# Lag compensation
		if delta > 0.25:
			lag_compensation_ms += delta * 1000.0

func _init_session():
	var all_cases = CasesModule.CASES_A.duplicate(true)
	# Validate all
	var valid_cases = []
	for c in all_cases:
		if CasesModule.validate_case(c):
			valid_cases.append(c)

	valid_cases.shuffle()
	session_cases = valid_cases.slice(0, min(SESSION_CASE_COUNT, valid_cases.size()))
	current_case_index = -1

	GlobalMetrics.stability = 100.0
	_update_stability_ui()

func _load_next_case():
	current_case_index += 1
	if current_case_index >= session_cases.size():
		_finish_session()
		return

	current_case = session_cases[current_case_index]
	is_trial_active = true

	# Reset Telemetry
	ui_ready_ts = Time.get_ticks_msec()
	time_to_first_action_ms = -1.0
	scroll_used = false
	click_timestamps.clear()
	lag_compensation_ms = 0.0
	stability_start = GlobalMetrics.stability

	_render_ui()
	_start_typewriter()

func _render_ui():
	# 1. Table
	data_tree.clear()
	var root = data_tree.create_item() # Hidden root
	data_tree.hide_root = true

	# Columns
	var cols = current_case.table.columns
	data_tree.columns = cols.size()
	for i in range(cols.size()):
		data_tree.set_column_title(i, cols[i].title)
	data_tree.column_titles_visible = true

	# Rows
	for row_data in current_case.table.rows:
		var item = data_tree.create_item(root)
		# Store row_id in metadata of column 0
		item.set_metadata(0, row_data.row_id)

		for i in range(cols.size()):
			var col_id = cols[i].col_id
			var val = row_data.cells.get(col_id, "")
			item.set_text(i, val)
			# Style tweaks if possible (e.g. monospaced)

	# 2. Prompt
	prompt_label.text = current_case.prompt
	prompt_label.visible_characters = 0

	# 3. Options
	for child in options_grid.get_children():
		child.queue_free()

	var opts = current_case.options.duplicate()
	if current_case.anti_cheat.get("shuffle_options", false):
		opts.shuffle()

	for opt in opts:
		var btn = Button.new()
		btn.text = opt.text
		btn.name = "Btn_" + opt.id
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size.y = 48
		btn.add_theme_font_size_override("font_size", 18)
		btn.pressed.connect(_register_interaction) # For First Action
		btn.pressed.connect(_on_option_selected.bind(opt))
		options_grid.add_child(btn)

func _start_typewriter():
	typewriter_timer.stop()
	if typewriter_timer.is_connected("timeout", _on_typewriter_tick):
		typewriter_timer.timeout.disconnect(_on_typewriter_tick)

	typewriter_timer.wait_time = 0.03
	typewriter_timer.timeout.connect(_on_typewriter_tick)
	typewriter_timer.start()

func _on_typewriter_tick():
	if prompt_label.visible_characters < prompt_label.get_total_character_count():
		prompt_label.visible_characters += 1
	else:
		typewriter_timer.stop()

# --- Interaction & Telemetry ---

func _register_interaction():
	if not is_trial_active: return
	if time_to_first_action_ms < 0:
		time_to_first_action_ms = Time.get_ticks_msec() - ui_ready_ts

	# Burst detection
	var now = Time.get_ticks_msec()
	click_timestamps.append(now)
	# Keep only last 3
	while click_timestamps.size() > 3:
		click_timestamps.pop_front()

func _input(event):
	if not is_trial_active: return

	if event is InputEventMouseButton:
		if event.pressed:
			_register_interaction()

			# Check scroll
			if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				# Check if over tree?
				# Simplified: if wheel used anywhere, record it.
				# Strict: check global rect. Let's assume generic scroll usage.
				scroll_used = true

	elif event is InputEventScreenTouch:
		if event.pressed:
			_register_interaction()

	elif event is InputEventScreenDrag:
		_register_interaction()
		scroll_used = true

func _on_option_selected(opt: Dictionary):
	if not is_trial_active: return
	is_trial_active = false # Lock
	typewriter_timer.stop()
	prompt_label.visible_characters = -1 # Show full

	# Disable buttons
	for btn in options_grid.get_children():
		btn.disabled = true
		if btn.name == "Btn_" + opt.id:
			# Highlight selection
			pass

	# Logic
	var is_correct = (opt.id == current_case.answer_id)
	var f_reason = opt.f_reason

	# Auto f_reason logic (optional per spec, but good to have placeholders)
	var f_reason_auto = null

	# Stability
	var stability_end = GlobalMetrics.stability
	if not is_correct:
		GlobalMetrics.stability = max(0, GlobalMetrics.stability - 10.0)
		stability_end = GlobalMetrics.stability
		if sfx_error: sfx_error.play()
	else:
		if sfx_relay: sfx_relay.play()

	_update_stability_ui()

	# Log
	_log_trial(opt, is_correct, f_reason, f_reason_auto, stability_end)

	# Visual Delay before next
	await get_tree().create_timer(1.0).timeout

	if GlobalMetrics.stability <= 0:
		_game_over()
	else:
		_load_next_case()

func _log_trial(opt, is_correct, f_reason, f_reason_auto, stability_end):
	var now = Time.get_ticks_msec()
	var raw_elapsed = now - ui_ready_ts
	var effective_elapsed = raw_elapsed - lag_compensation_ms
	var over_soft = effective_elapsed > (current_case.timing_policy.limit_sec * 1000)

	# Quality Flags
	# table_fits: approximate check.
	# Tree items don't easily give rects.
	# Logic: if row_count * row_height < tree_height.
	# Assume standard row height ~30px + header.
	var row_h = 35 # approx
	var content_h = (current_case.table.rows.size() * row_h) + 40
	var fits = content_h <= data_tree.size.y

	var idle_30 = (time_to_first_action_ms >= 30000)
	var silent = fits and (not scroll_used) and idle_30 and true # finished

	var burst = false
	if click_timestamps.size() >= 3:
		if (click_timestamps[-1] - click_timestamps[0]) <= 600:
			burst = true

	var payload = {
		"quest_id": "CASE_07_DATA_ARCHIVE",
		"case_id": current_case.id,
		"schema_version": current_case.schema_version,
		"level": current_case.level,
		"topic": current_case.topic,
		"case_kind": current_case.case_kind,
		"interaction_type": "SINGLE_CHOICE",

		"answer": {
			"selected_option_id": opt.id,
			"correct_option_id": current_case.answer_id,
			"is_correct": is_correct,
			"f_reason": f_reason,
			"f_reason_auto": f_reason_auto
		},

		"timing": {
			"ui_ready_ts": ui_ready_ts,
			"time_to_first_action_ms": time_to_first_action_ms,
			"raw_elapsed_ms": raw_elapsed,
			"lag_compensation_ms": lag_compensation_ms,
			"effective_elapsed_time_ms": effective_elapsed,
			"over_soft_limit": over_soft
		},

		"quality_flags": {
			"table_fits_without_scroll_initial": fits,
			"scroll_used": scroll_used,
			"idle_30s_before_action": idle_30,
			"silent_reading_possible": silent,
			"rapid_click_burst": burst,
			"threshold_unstable": (GlobalMetrics.stability < 30)
		},

		"stability": {
			"start": stability_start,
			"end": stability_end,
			"delta": stability_end - stability_start
		}
	}

	GlobalMetrics.register_trial(payload)

func _update_stability_ui():
	stability_bar.value = GlobalMetrics.stability
	stability_label.text = "STABILITY: %d%%" % int(GlobalMetrics.stability)

func _on_viewport_size_changed():
	var win_size = get_viewport_rect().size

	# Find the sections. They might be in DesktopLayout or MobileLayout.
	# We need to find them safely.
	var ts = table_section
	var tsk = task_section

	if not ts or not tsk:
		# Fallback search if onready didn't catch (e.g. they were moved)
		ts = find_child("TableSection", true, false)
		tsk = find_child("TaskSection", true, false)

	if not ts or not tsk:
		return # Should not happen if scene is correct

	if win_size.x < BREAKPOINT_PX:
		# Mobile Mode
		if ts.get_parent() != mobile_layout:
			ts.reparent(mobile_layout)
		if tsk.get_parent() != mobile_layout:
			tsk.reparent(mobile_layout)

		desktop_layout.visible = false
		mobile_layout.visible = true
	else:
		# Desktop Mode
		if ts.get_parent() != desktop_layout:
			ts.reparent(desktop_layout)
		if tsk.get_parent() != desktop_layout:
			tsk.reparent(desktop_layout)

		desktop_layout.visible = true
		mobile_layout.visible = false

func _finish_session():
	is_game_over = true
	title_label.text = "SESSION COMPLETE"
	prompt_label.text = "All archives processed. Return to base."
	options_grid.queue_free()
	# Button to return?
	var btn_exit = Button.new()
	btn_exit.text = "EXIT"
	btn_exit.pressed.connect(_on_exit_pressed)
	# Add to where options were
	task_section.add_child(btn_exit)

func _game_over():
	is_game_over = true
	title_label.text = "MISSION FAILED"
	prompt_label.text = "Stability critical. Connection severed."
	options_grid.queue_free()
	var btn_exit = Button.new()
	btn_exit.text = "EXIT"
	btn_exit.pressed.connect(_on_exit_pressed)
	task_section.add_child(btn_exit)

func _on_exit_pressed():
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")
