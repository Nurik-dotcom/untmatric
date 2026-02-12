extends Control

const CasesHub = preload("res://scripts/case_07/da7_cases.gd")

const BREAKPOINT_PX := 800
const SESSION_CASE_COUNT := 6

var session_cases: Array = []
var current_case_index: int = -1
var current_case: Dictionary = {}
var case_started_ts: int = 0
var trial_locked: bool = false
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
	trial_locked = false
	_render_case()

func _render_case() -> void:
	title_label.text = "CASE #7: SECRET ARCHIVE [A %d/%d]" % [current_case_index + 1, session_cases.size()]
	prompt_label.bbcode_enabled = true
	prompt_label.text = "[b]%s[/b]" % str(current_case.get("prompt", ""))

	_render_table(current_case.get("table", {}))
	_render_options(current_case.get("options", []))

func _render_table(table_def: Dictionary) -> void:
	data_tree.clear()
	var root: TreeItem = data_tree.create_item()
	data_tree.hide_root = true
	data_tree.select_mode = Tree.SELECT_ROW

	var cols: Array = table_def.get("columns", [])
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

	var rows: Array = table_def.get("rows", [])
	for row_v in rows:
		if typeof(row_v) != TYPE_DICTIONARY:
			continue
		var row_data: Dictionary = row_v
		var row_item: TreeItem = data_tree.create_item(root)
		var cells: Dictionary = row_data.get("cells", {})
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
		var opt: Dictionary = opt_v
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 56)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.text = str(opt.get("text", "Option"))
		btn.pressed.connect(_on_option_selected.bind(str(opt.get("id", ""))))
		options_grid.add_child(btn)

func _on_option_selected(selected_id: String) -> void:
	if trial_locked:
		return
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
	var elapsed_ms: int = Time.get_ticks_msec() - case_started_ts
	var payload: Dictionary = {
		"quest_id": "CASE_07_DATA_ARCHIVE",
		"quest": "data_archive",
		"stage": "A",
		"level": "A",
		"case_id": str(current_case.get("id", "DA7-A-00")),
		"topic": str(current_case.get("topic", "DB_BASICS")),
		"interaction_type": "SINGLE_CHOICE",
		"match_key": "DA7_A|%s" % str(current_case.get("id", "DA7-A-00")),
		"is_correct": is_correct,
		"elapsed_ms": elapsed_ms,
		"answer": {
			"selected_option_id": selected_id,
			"answer_id": answer_id
		}
	}
	GlobalMetrics.register_trial(payload)

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
