extends Control

const CasesHub = preload("res://scripts/case_07/da7_cases.gd")

const BREAKPOINT_PX := 800
const SESSION_CASE_COUNT := 6

var session_cases: Array = []
var current_case_index: int = -1
var current_case: Dictionary = {}
var case_started_ts: int = 0
var first_action_ts: int = -1
var trial_locked: bool = false
var scroll_used: bool = false
var prompt_has_scroll: bool = false
var exit_btn: Button

@onready var title_label: RichTextLabel = $RootLayout/Header/Margin/Title
@onready var desktop_layout: HSplitContainer = $RootLayout/Body/DesktopLayout
@onready var mobile_layout: VBoxContainer = $RootLayout/Body/MobileLayout
@onready var table_section: VBoxContainer = $RootLayout/Body/DesktopLayout/TableSection
@onready var task_section: VBoxContainer = $RootLayout/Body/DesktopLayout/TaskSection
@onready var data_tree: Tree = $RootLayout/Body/DesktopLayout/TableSection/DataTree
@onready var prompt_label: RichTextLabel = $RootLayout/Body/DesktopLayout/TaskSection/PromptLabel
@onready var options_grid: GridContainer = $RootLayout/Body/DesktopLayout/TaskSection/OptionsGrid
@onready var stability_label: Label = $RootLayout/Footer/StabilityLabel
@onready var stability_bar: ProgressBar = $RootLayout/Footer/StabilityBar
@onready var sfx_error: AudioStreamPlayer = $Runtime/Audio/SfxError
@onready var sfx_relay: AudioStreamPlayer = $Runtime/Audio/SfxRelay

func _ready() -> void:
	randomize()
	if not GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.connect(_on_stability_changed)
	get_tree().root.size_changed.connect(_on_viewport_size_changed)
	if not data_tree.gui_input.is_connected(_on_scroll_input):
		data_tree.gui_input.connect(_on_scroll_input)
	if not prompt_label.gui_input.is_connected(_on_scroll_input):
		prompt_label.gui_input.connect(_on_scroll_input)

	_init_session()
	call_deferred("_on_viewport_size_changed")
	_load_next_case()

func _init_session() -> void:
	var all_cases: Array = CasesHub.get_cases("A")
	if all_cases.is_empty():
		_show_fatal("No CASES_A found. Check scripts/case_07/da7_cases_a.gd")
		return

	all_cases.shuffle()
	session_cases = all_cases.slice(0, min(SESSION_CASE_COUNT, all_cases.size()))
	current_case_index = -1
	GlobalMetrics.stability = 100.0
	_update_stability_ui()

func _load_next_case() -> void:
	if session_cases.is_empty():
		return

	current_case_index += 1
	if current_case_index >= session_cases.size():
		_finish_session()
		return

	current_case = (session_cases[current_case_index] as Dictionary).duplicate(true)
	case_started_ts = Time.get_ticks_msec()
	first_action_ts = -1
	scroll_used = false
	prompt_has_scroll = false
	trial_locked = false
	_render_case()

func _render_case() -> void:
	title_label.text = "CASE #7: SECRET ARCHIVE [A %d/%d]" % [current_case_index + 1, session_cases.size()]
	prompt_label.bbcode_enabled = true
	prompt_label.text = "[b]%s[/b]" % str(current_case.get("prompt", ""))

	_render_table(current_case.get("table", {}) as Dictionary)
	_render_options(current_case.get("options", []) as Array)
	call_deferred("_update_silent_reading_possible_flag")

func _render_table(table_def: Dictionary) -> void:
	data_tree.clear()
	var root: TreeItem = data_tree.create_item()
	data_tree.hide_root = true
	data_tree.select_mode = Tree.SELECT_ROW

	var cols: Array = table_def.get("columns", []) as Array
	if cols.is_empty():
		data_tree.columns = 1
		data_tree.set_column_title(0, "Data")
		data_tree.column_titles_visible = true
		return

	data_tree.columns = cols.size()
	for i in range(cols.size()):
		var col: Dictionary = cols[i]
		data_tree.set_column_title(i, str(col.get("title", "COL")))
	data_tree.column_titles_visible = true

	var rows: Array = table_def.get("rows", []) as Array
	for row_v in rows:
		if typeof(row_v) != TYPE_DICTIONARY:
			continue
		var row_data: Dictionary = row_v as Dictionary
		var row_item: TreeItem = data_tree.create_item(root)
		var cells: Dictionary = row_data.get("cells", {}) as Dictionary
		for i in range(cols.size()):
			var col: Dictionary = cols[i]
			var col_id: String = str(col.get("col_id", ""))
			row_item.set_text(i, str(cells.get(col_id, "")))

func _render_options(options: Array) -> void:
	for child in options_grid.get_children():
		child.queue_free()

	for opt_v in options:
		if typeof(opt_v) != TYPE_DICTIONARY:
			continue
		var opt: Dictionary = opt_v as Dictionary
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(0, 56)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.text = str(opt.get("text", "Option"))
		btn.pressed.connect(_on_option_selected.bind(str(opt.get("id", ""))))
		options_grid.add_child(btn)

func _on_option_selected(selected_id: String) -> void:
	if trial_locked:
		return
	_register_first_action()
	trial_locked = true

	var answer_id: String = str(current_case.get("answer_id", ""))
	var is_correct: bool = selected_id == answer_id
	if is_correct:
		prompt_label.text = "[b]%s[/b]\n[color=#77ff77]Correct.[/color]" % str(current_case.get("prompt", ""))
		if sfx_relay != null:
			sfx_relay.play()
	else:
		prompt_label.text = "[b]%s[/b]\n[color=#ff6b6b]Incorrect.[/color]" % str(current_case.get("prompt", ""))
		if sfx_error != null:
			sfx_error.play()

	_set_options_locked(true)
	_log_trial(selected_id, answer_id, is_correct)
	_update_stability_ui()

	await get_tree().create_timer(0.9).timeout

	if GlobalMetrics.stability <= 0.0:
		_game_over()
	else:
		_load_next_case()

func _log_trial(selected_id: String, answer_id: String, is_correct: bool) -> void:
	var now_ms: int = Time.get_ticks_msec()
	var elapsed_ms: int = now_ms - case_started_ts
	var first_action_ms: int = elapsed_ms
	if first_action_ts >= case_started_ts:
		first_action_ms = first_action_ts - case_started_ts
	var silent_reading_possible: bool = (not prompt_has_scroll and not scroll_used and first_action_ms >= 30000)
	var case_id: String = str(current_case.get("id", "DA7-A-00"))
	var selected_option: Dictionary = _find_option(selected_id)
	var f_reason: Variant = null if is_correct else selected_option.get("f_reason", "WRONG_OPTION_GENERIC")
	var payload: Dictionary = {
		"question_id": case_id,
		"case_id": case_id,
		"quest_id": "DA7",
		"quest": "data_archive",
		"stage": "A",
		"level": "A",
		"topic": str(current_case.get("topic", "DB_BASICS")),
		"interaction_type": "SINGLE_CHOICE",
		"schema_version": str(current_case.get("schema_version", "DA7.A.v1")),
		"match_key": "DA7_A|%s" % case_id,
		"is_correct": is_correct,
		"f_reason": f_reason,
		"elapsed_ms": elapsed_ms,
		"duration": float(elapsed_ms) / 1000.0,
		"timing": {
			"effective_elapsed_ms": elapsed_ms,
			"time_to_first_action_ms": first_action_ms,
			"policy_mode": "LEARNING",
			"limit_sec": 120
		},
		"answer": {
			"selected_option_id": selected_id
		},
		"expected": {
			"answer_id": answer_id
		},
		"flags": {
			"silent_reading_possible": silent_reading_possible,
			"scroll_used": scroll_used
		},
		"anti_cheat": current_case.get("anti_cheat", {}),
		"telemetry": {
			"time_to_first_action_ms": first_action_ms,
			"scroll_used": scroll_used
		}
	}
	GlobalMetrics.register_trial(payload)

func _find_option(selected_id: String) -> Dictionary:
	var options: Array = current_case.get("options", []) as Array
	for opt_v in options:
		if typeof(opt_v) != TYPE_DICTIONARY:
			continue
		var opt: Dictionary = opt_v as Dictionary
		if str(opt.get("id", "")) == selected_id:
			return opt
	return {}

func _register_first_action() -> void:
	if first_action_ts < 0:
		first_action_ts = Time.get_ticks_msec()

func _update_silent_reading_possible_flag() -> void:
	if not is_instance_valid(prompt_label):
		return
	var v_scroll: VScrollBar = prompt_label.get_v_scroll_bar()
	if is_instance_valid(v_scroll):
		prompt_has_scroll = v_scroll.max_value > 0.0 and v_scroll.page < v_scroll.max_value
	else:
		prompt_has_scroll = false

func _on_scroll_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP or mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scroll_used = true
	elif event is InputEventScreenDrag:
		scroll_used = true

func _set_options_locked(locked: bool) -> void:
	for child in options_grid.get_children():
		if child is Button:
			(child as Button).disabled = locked

func _finish_session() -> void:
	trial_locked = true
	title_label.text = "SESSION COMPLETE [A]"
	prompt_label.bbcode_enabled = true
	prompt_label.text = "[b]Archive training finished.[/b]"
	_set_options_locked(true)
	_ensure_exit_button()

func _game_over() -> void:
	trial_locked = true
	title_label.text = "MISSION FAILED [A]"
	prompt_label.bbcode_enabled = true
	prompt_label.text = "[b]Stability dropped to zero.[/b]"
	_set_options_locked(true)
	_ensure_exit_button()

func _ensure_exit_button() -> void:
	if exit_btn != null and is_instance_valid(exit_btn):
		return
	exit_btn = Button.new()
	exit_btn.text = "EXIT"
	exit_btn.custom_minimum_size = Vector2(140, 48)
	exit_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")
	)
	$RootLayout/Footer.add_child(exit_btn)

func _show_fatal(text: String) -> void:
	prompt_label.bbcode_enabled = false
	prompt_label.text = text
	trial_locked = true

func _on_stability_changed(_new_val: float, _delta: float) -> void:
	_update_stability_ui()

func _update_stability_ui() -> void:
	if is_instance_valid(stability_bar):
		stability_bar.value = GlobalMetrics.stability
	if is_instance_valid(stability_label):
		stability_label.text = "STABILITY: %d%%" % int(GlobalMetrics.stability)

func _on_viewport_size_changed() -> void:
	var is_mobile: bool = get_viewport_rect().size.x < BREAKPOINT_PX
	desktop_layout.split_offset = int(get_viewport_rect().size.x * 0.48)
	if is_mobile:
		if table_section.get_parent() != mobile_layout:
			table_section.reparent(mobile_layout)
		if task_section.get_parent() != mobile_layout:
			task_section.reparent(mobile_layout)
		mobile_layout.visible = true
		desktop_layout.visible = false
	else:
		if table_section.get_parent() != desktop_layout:
			table_section.reparent(desktop_layout)
		if task_section.get_parent() != desktop_layout:
			task_section.reparent(desktop_layout)
		desktop_layout.move_child(table_section, 0)
		desktop_layout.move_child(task_section, 1)
		desktop_layout.visible = true
		mobile_layout.visible = false
