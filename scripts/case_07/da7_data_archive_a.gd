extends Control

const CasesHub = preload("res://scripts/case_07/da7_cases.gd")

const BREAKPOINT_PX := 800
const SESSION_CASE_COUNT := 6
const TYPEWRITER_INTERVAL_SEC := 0.03

var session_cases: Array = []
var current_case_index: int = -1
var current_case: Dictionary = {}
var case_started_ts: int = 0
var first_action_ts: int = -1
var trial_locked: bool = false
var scroll_used: bool = false
var table_has_scroll: bool = false
var exit_btn: Button

var inspect_count: int = 0
var unique_rows_inspected: Dictionary = {}
var answered_without_inspection: bool = false
var last_inspected_row_id: String = ""

var row_item_by_id: Dictionary = {}
var col_index_by_id: Dictionary = {}
var row_data_by_id: Dictionary = {}

var _typewriter_steps: Array[Dictionary] = []
var _typewriter_step_index: int = -1
var _typewriter_target: RichTextLabel
var _typewriter_source: String = ""
var _typewriter_cursor: int = 0

@onready var title_label: RichTextLabel = $RootLayout/Header/Margin/Title
@onready var desktop_layout: HSplitContainer = $RootLayout/Body/DesktopLayout
@onready var mobile_layout: VBoxContainer = $RootLayout/Body/MobileLayout
@onready var table_section: VBoxContainer = $RootLayout/Body/DesktopLayout/TableSection
@onready var task_section: VBoxContainer = $RootLayout/Body/DesktopLayout/TaskSection
@onready var data_tree: Tree = $RootLayout/Body/DesktopLayout/TableSection/DataTree
@onready var inspect_label: RichTextLabel = $RootLayout/Body/DesktopLayout/TableSection/InspectPanel/InspectMargin/InspectVBox/InspectLabel
@onready var scan_label: Label = $RootLayout/Body/DesktopLayout/TableSection/InspectPanel/InspectMargin/InspectVBox/ScanLabel
@onready var case_title_label: Label = $RootLayout/Body/DesktopLayout/TaskSection/DossierPanel/DossierMargin/DossierVBox/CaseTitleLabel
@onready var briefing_label: RichTextLabel = $RootLayout/Body/DesktopLayout/TaskSection/DossierPanel/DossierMargin/DossierVBox/BriefingLabel
@onready var objective_label: Label = $RootLayout/Body/DesktopLayout/TaskSection/DossierPanel/DossierMargin/DossierVBox/ObjectiveLabel
@onready var prompt_label: RichTextLabel = $RootLayout/Body/DesktopLayout/TaskSection/PromptLabel
@onready var options_grid: GridContainer = $RootLayout/Body/DesktopLayout/TaskSection/OptionsGrid
@onready var explain_line: RichTextLabel = $RootLayout/Body/DesktopLayout/TaskSection/ExplainLine
@onready var stability_label: Label = $RootLayout/Footer/StabilityLabel
@onready var stability_bar: ProgressBar = $RootLayout/Footer/StabilityBar
@onready var sfx_click: AudioStreamPlayer = $Runtime/Audio/SfxClick
@onready var sfx_error: AudioStreamPlayer = $Runtime/Audio/SfxError
@onready var sfx_relay: AudioStreamPlayer = $Runtime/Audio/SfxRelay
@onready var result_stamp: Control = $ResultStamp
@onready var typewriter_timer: Timer = $Runtime/TypewriterTimer

func _ready() -> void:
	randomize()
	if not GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.connect(_on_stability_changed)
	get_tree().root.size_changed.connect(_on_viewport_size_changed)
	if not data_tree.gui_input.is_connected(_on_scroll_input):
		data_tree.gui_input.connect(_on_scroll_input)
	if not prompt_label.gui_input.is_connected(_on_scroll_input):
		prompt_label.gui_input.connect(_on_scroll_input)
	if not data_tree.item_selected.is_connected(_on_tree_item_selected):
		data_tree.item_selected.connect(_on_tree_item_selected)
	if not typewriter_timer.timeout.is_connected(_on_typewriter_tick):
		typewriter_timer.timeout.connect(_on_typewriter_tick)

	_init_session()
	call_deferred("_on_viewport_size_changed")
	_load_next_case()

func _init_session() -> void:
	var all_cases: Array = CasesHub.get_cases("A")
	if all_cases.is_empty():
		_show_fatal("Кейсы уровня A не найдены. Проверьте scripts/case_07/da7_cases_a.gd")
		return

	all_cases.shuffle()
	session_cases = all_cases.slice(0, mini(SESSION_CASE_COUNT, all_cases.size()))
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
	table_has_scroll = false
	trial_locked = false
	inspect_count = 0
	unique_rows_inspected.clear()
	answered_without_inspection = false
	last_inspected_row_id = ""
	row_item_by_id.clear()
	col_index_by_id.clear()
	row_data_by_id.clear()
	typewriter_timer.stop()
	_render_case()

func _render_case() -> void:
	title_label.text = "ДЕЛО #7: СЕКРЕТНЫЙ АРХИВ [A %d/%d]" % [current_case_index + 1, session_cases.size()]

	case_title_label.text = "ФАЙЛ: %s" % str(current_case.get("case_title", current_case.get("id", "НЕИЗВЕСТНЫЙ_ФАЙЛ")))
	briefing_label.bbcode_enabled = false
	briefing_label.text = str(current_case.get("briefing", ""))
	objective_label.text = "ЦЕЛЬ: %s" % str(current_case.get("objective", ""))

	prompt_label.bbcode_enabled = false
	prompt_label.text = str(current_case.get("prompt", ""))
	explain_line.bbcode_enabled = false
	explain_line.text = ""

	inspect_label.bbcode_enabled = false
	inspect_label.text = "Выберите строку для проверки улики."
	scan_label.text = "СКАН: 0"

	_render_table(current_case.get("table", {}) as Dictionary)
	_render_options(current_case.get("options", []) as Array)
	_start_typewriter_sequence()
	call_deferred("_update_silent_reading_possible_flag")

func _start_typewriter_sequence() -> void:
	typewriter_timer.stop()
	_typewriter_steps.clear()
	_typewriter_step_index = -1
	_typewriter_steps.append({
		"target": briefing_label,
		"text": str(current_case.get("briefing", ""))
	})
	_typewriter_steps.append({
		"target": prompt_label,
		"text": str(current_case.get("prompt", ""))
	})
	_start_next_typewriter_step()

func _start_next_typewriter_step() -> void:
	_typewriter_step_index += 1
	if _typewriter_step_index >= _typewriter_steps.size():
		typewriter_timer.stop()
		return

	var step: Dictionary = _typewriter_steps[_typewriter_step_index]
	var target_v: Variant = step.get("target", null)
	if not (target_v is RichTextLabel):
		_start_next_typewriter_step()
		return

	_typewriter_target = target_v as RichTextLabel
	_typewriter_source = str(step.get("text", ""))
	_typewriter_cursor = 0
	_typewriter_target.bbcode_enabled = false
	_typewriter_target.text = ""

	if _typewriter_source.is_empty():
		_start_next_typewriter_step()
		return

	typewriter_timer.wait_time = TYPEWRITER_INTERVAL_SEC
	typewriter_timer.start()

func _on_typewriter_tick() -> void:
	if not is_instance_valid(_typewriter_target):
		return

	if _typewriter_cursor < _typewriter_source.length():
		_typewriter_cursor += 1
		_typewriter_target.text = _typewriter_source.substr(0, _typewriter_cursor)
		typewriter_timer.start()
	else:
		_start_next_typewriter_step()

func _render_table(table_def: Dictionary) -> void:
	data_tree.clear()
	row_item_by_id.clear()
	col_index_by_id.clear()
	row_data_by_id.clear()

	var root: TreeItem = data_tree.create_item()
	data_tree.hide_root = true
	data_tree.select_mode = Tree.SELECT_ROW

	var cols: Array = table_def.get("columns", []) as Array
	if cols.is_empty():
		data_tree.columns = 1
		data_tree.set_column_title(0, "Данные")
		data_tree.column_titles_visible = true
		return

	data_tree.columns = cols.size()
	for i in range(cols.size()):
		var col_data_v: Variant = cols[i]
		if typeof(col_data_v) != TYPE_DICTIONARY:
			continue
		var col: Dictionary = col_data_v as Dictionary
		var col_id: String = str(col.get("col_id", ""))
		col_index_by_id[col_id] = i
		data_tree.set_column_title(i, str(col.get("title", "СТОЛБЕЦ")))
	data_tree.column_titles_visible = true

	var rows: Array = table_def.get("rows", []) as Array
	for row_v in rows:
		if typeof(row_v) != TYPE_DICTIONARY:
			continue
		var row_data: Dictionary = row_v as Dictionary
		var row_id: String = str(row_data.get("row_id", ""))
		if row_id.is_empty():
			continue
		var row_item: TreeItem = data_tree.create_item(root)
		row_item.set_metadata(0, row_id)
		row_item_by_id[row_id] = row_item
		row_data_by_id[row_id] = row_data

		var cells: Dictionary = row_data.get("cells", {}) as Dictionary
		for i in range(cols.size()):
			var col_v: Variant = cols[i]
			if typeof(col_v) != TYPE_DICTIONARY:
				continue
			var col_def: Dictionary = col_v as Dictionary
			var col_id := str(col_def.get("col_id", ""))
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
		btn.text = str(opt.get("text", "Вариант"))
		btn.pressed.connect(_on_option_selected.bind(str(opt.get("id", ""))))
		options_grid.add_child(btn)

func _on_tree_item_selected() -> void:
	if trial_locked:
		return

	var item: TreeItem = data_tree.get_selected()
	if item == null:
		return
	var row_id: String = str(item.get_metadata(0))
	if row_id.is_empty() or not row_data_by_id.has(row_id):
		return

	_register_first_action()
	inspect_count += 1
	unique_rows_inspected[row_id] = true
	last_inspected_row_id = row_id
	scan_label.text = "СКАН: %d" % inspect_count
	inspect_label.text = _build_inspect_line(row_id)
	if is_instance_valid(sfx_click):
		sfx_click.play()

func _build_inspect_line(row_id: String) -> String:
	var row_data: Dictionary = row_data_by_id.get(row_id, {}) as Dictionary
	var table_def: Dictionary = current_case.get("table", {}) as Dictionary
	var cols: Array = table_def.get("columns", []) as Array
	var cells: Dictionary = row_data.get("cells", {}) as Dictionary

	var parts: Array[String] = []
	for col_v in cols:
		if typeof(col_v) != TYPE_DICTIONARY:
			continue
		var col_def: Dictionary = col_v as Dictionary
		var col_id: String = str(col_def.get("col_id", ""))
		var col_title: String = str(col_def.get("title", col_id.to_upper()))
		parts.append("%s=%s" % [col_title, str(cells.get(col_id, ""))])

	return "СТРОКА %s: %s" % [row_id, " | ".join(parts)]

func _on_option_selected(selected_id: String) -> void:
	if trial_locked:
		return

	_register_first_action()
	answered_without_inspection = inspect_count == 0
	trial_locked = true
	typewriter_timer.stop()
	briefing_label.text = str(current_case.get("briefing", ""))
	prompt_label.text = str(current_case.get("prompt", ""))

	if is_instance_valid(sfx_click):
		sfx_click.play()

	var answer_id: String = str(current_case.get("answer_id", ""))
	var selected_option: Dictionary = _find_option(selected_id)
	var is_correct: bool = selected_id == answer_id

	if is_correct:
		if sfx_relay != null:
			sfx_relay.play()
	else:
		if sfx_error != null:
			sfx_error.play()

	_set_options_locked(true)
	_apply_highlight(current_case.get("highlight", {}) as Dictionary)
	_show_explain_line(is_correct, selected_option)
	if is_instance_valid(result_stamp) and result_stamp.has_method("show_result"):
		result_stamp.call("show_result", is_correct)

	_log_trial(selected_id, answer_id, is_correct)
	_update_stability_ui()

	await get_tree().create_timer(0.9).timeout

	if GlobalMetrics.stability <= 0.0:
		_game_over()
	else:
		_load_next_case()

func _show_explain_line(is_correct: bool, selected_option: Dictionary) -> void:
	var reveal: Dictionary = current_case.get("reveal", {}) as Dictionary
	var line: String = ""
	if is_correct:
		line = str(reveal.get("on_correct", "Подтверждено."))
	else:
		var reason: String = str(selected_option.get("f_reason", "WRONG_OPTION_GENERIC"))
		var reason_map: Dictionary = reveal.get("on_wrong_by_reason", {}) as Dictionary
		line = str(reason_map.get(reason, "Проверьте выделенные улики и повторите попытку."))
	explain_line.text = line

func _apply_highlight(highlight: Dictionary) -> void:
	if highlight.is_empty():
		return

	var mode: String = str(highlight.get("mode", "")).to_upper()
	var bg: Color = Color(0.42, 0.30, 0.10, 0.55)
	var fg: Color = Color(1.0, 0.94, 0.78, 1.0)

	match mode:
		"ROWS":
			var target_rows: Array = highlight.get("target_row_ids", []) as Array
			for row_id_v in target_rows:
				var row_id: String = str(row_id_v)
				_highlight_row(row_id, bg, fg)
		"COLUMNS":
			var target_cols: Array = highlight.get("target_col_ids", []) as Array
			for col_id_v in target_cols:
				var col_id: String = str(col_id_v)
				if not col_index_by_id.has(col_id):
					continue
				var col_idx: int = int(col_index_by_id[col_id])
				for row_id_v in row_item_by_id.keys():
					var item: TreeItem = row_item_by_id[row_id_v] as TreeItem
					_highlight_cell(item, col_idx, bg, fg)
		"CELL":
			var target_cell: Dictionary = highlight.get("target_cell", {}) as Dictionary
			var row_id: String = str(target_cell.get("row_id", ""))
			var col_id: String = str(target_cell.get("col_id", ""))
			if row_item_by_id.has(row_id) and col_index_by_id.has(col_id):
				var row_item: TreeItem = row_item_by_id[row_id] as TreeItem
				var col_idx: int = int(col_index_by_id[col_id])
				_highlight_cell(row_item, col_idx, bg, fg)

func _highlight_row(row_id: String, bg: Color, fg: Color) -> void:
	if not row_item_by_id.has(row_id):
		return
	var item: TreeItem = row_item_by_id[row_id] as TreeItem
	for col_idx in range(data_tree.columns):
		_highlight_cell(item, col_idx, bg, fg)

func _highlight_cell(item: TreeItem, col_idx: int, bg: Color, fg: Color) -> void:
	if item == null:
		return
	item.set_custom_bg_color(col_idx, bg)
	item.set_custom_color(col_idx, fg)

func _log_trial(selected_id: String, answer_id: String, is_correct: bool) -> void:
	var now_ms: int = Time.get_ticks_msec()
	var elapsed_ms: int = now_ms - case_started_ts
	var first_action_ms: int = elapsed_ms
	if first_action_ts >= case_started_ts:
		first_action_ms = first_action_ts - case_started_ts
	var silent_reading_possible: bool = (not table_has_scroll and not scroll_used and first_action_ms >= 30000)
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
			"scroll_used": scroll_used,
			"answered_without_inspection": answered_without_inspection
		},
		"anti_cheat": current_case.get("anti_cheat", {}),
		"telemetry": {
			"time_to_first_action_ms": first_action_ms,
			"scroll_used": scroll_used,
			"inspect_count": inspect_count,
			"unique_rows_inspected": unique_rows_inspected.size(),
			"last_inspected_row_id": last_inspected_row_id
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
	table_has_scroll = _tree_has_vertical_scroll(data_tree)

func _tree_has_vertical_scroll(tree: Tree) -> bool:
	if not is_instance_valid(tree):
		return false
	var stack: Array = [tree]
	while not stack.is_empty():
		var node: Node = stack.pop_back() as Node
		if node is VScrollBar:
			var bar: VScrollBar = node as VScrollBar
			return bar.max_value > 0.0 and bar.page < bar.max_value
		for child in node.get_children():
			stack.append(child)
	return false

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
	typewriter_timer.stop()
	title_label.text = "СЕССИЯ ЗАВЕРШЕНА [A]"
	prompt_label.bbcode_enabled = true
	prompt_label.text = "[b]Тренировка архива завершена.[/b]"
	explain_line.text = ""
	_set_options_locked(true)
	_ensure_exit_button()

func _game_over() -> void:
	trial_locked = true
	typewriter_timer.stop()
	title_label.text = "МИССИЯ ПРОВАЛЕНА [A]"
	prompt_label.bbcode_enabled = true
	prompt_label.text = "[b]Стабильность упала до нуля.[/b]"
	explain_line.text = ""
	_set_options_locked(true)
	_ensure_exit_button()

func _ensure_exit_button() -> void:
	if exit_btn != null and is_instance_valid(exit_btn):
		return
	exit_btn = Button.new()
	exit_btn.text = "ВЫХОД"
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
		stability_label.text = "СТАБИЛЬНОСТЬ: %d%%" % int(GlobalMetrics.stability)

func _on_viewport_size_changed() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var is_mobile: bool = viewport_size.x < BREAKPOINT_PX
	desktop_layout.split_offset = int(viewport_size.x * 0.48)
	options_grid.columns = 1 if is_mobile else 2

	if is_mobile:
		if table_section.get_parent() != mobile_layout:
			table_section.reparent(mobile_layout)
		if task_section.get_parent() != mobile_layout:
			task_section.reparent(mobile_layout)
		mobile_layout.move_child(table_section, 0)
		mobile_layout.move_child(task_section, 1)
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
