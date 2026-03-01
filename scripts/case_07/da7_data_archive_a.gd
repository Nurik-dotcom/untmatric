extends Control

const CasesHub = preload("res://scripts/case_07/da7_cases.gd")
const CasesA = preload("res://scripts/case_07/da7_cases_a.gd")

const BREAKPOINT_PX := 800
const SESSION_CASE_COUNT := 6
const LONG_PRESS_MS := 350
const LONG_PRESS_MOVE_PX := 10.0

var session_cases: Array = []
var current_case_index := -1
var current_case: Dictionary = {}
var case_started_ts := 0
var first_action_ts := -1
var trial_locked := false
var scroll_used := false
var table_has_scroll := false
var exit_btn: Button

var inspect_count := 0
var unique_rows_inspected: Dictionary = {}
var answered_without_inspection := false
var last_inspected_row_id := ""
var time_to_first_inspect_ms := -1
var miss_click_count := 0

var row_item_by_id: Dictionary = {}
var col_index_by_id: Dictionary = {}
var col_id_by_index: Dictionary = {}
var row_data_by_id: Dictionary = {}

var _press_active := false
var _press_start_ms := 0
var _press_start_pos := Vector2.ZERO
var _press_moved := false
var _press_hit: Dictionary = {}

@onready var title_label: RichTextLabel = $SafeArea/RootLayout/Header/Margin/Title
@onready var btn_back: Button = $SafeArea/RootLayout/BackRow/BtnBack
@onready var desktop_layout: HSplitContainer = $SafeArea/RootLayout/Body/DesktopLayout
@onready var mobile_layout: VBoxContainer = $SafeArea/RootLayout/Body/MobileLayout
@onready var table_section: VBoxContainer = $SafeArea/RootLayout/Body/DesktopLayout/TableSection
@onready var task_section: VBoxContainer = $SafeArea/RootLayout/Body/DesktopLayout/TaskSection
@onready var data_tree: Tree = $SafeArea/RootLayout/Body/DesktopLayout/TableSection/DataTree
@onready var table_title: Label = $SafeArea/RootLayout/Body/DesktopLayout/TableSection/TableTitle
@onready var scanner_overlay: Control = get_node_or_null("SafeArea/RootLayout/Body/DesktopLayout/TableSection/ScannerOverlay") as Control
@onready var inspect_label: RichTextLabel = $SafeArea/RootLayout/Body/DesktopLayout/TableSection/InspectPanel/InspectMargin/InspectVBox/InspectLabel
@onready var scan_label: Label = $SafeArea/RootLayout/Body/DesktopLayout/TableSection/InspectPanel/InspectMargin/InspectVBox/ScanLabel
@onready var case_title_label: Label = $SafeArea/RootLayout/Body/DesktopLayout/TaskSection/DossierPanel/DossierMargin/DossierVBox/CaseTitleLabel
@onready var briefing_label: RichTextLabel = $SafeArea/RootLayout/Body/DesktopLayout/TaskSection/DossierPanel/DossierMargin/DossierVBox/BriefingLabel
@onready var objective_label: Label = $SafeArea/RootLayout/Body/DesktopLayout/TaskSection/DossierPanel/DossierMargin/DossierVBox/ObjectiveLabel
@onready var prompt_label: RichTextLabel = $SafeArea/RootLayout/Body/DesktopLayout/TaskSection/PromptLabel
@onready var options_grid: GridContainer = $SafeArea/RootLayout/Body/DesktopLayout/TaskSection/OptionsGrid
@onready var explain_line: RichTextLabel = $SafeArea/RootLayout/Body/DesktopLayout/TaskSection/ExplainLine
@onready var stability_label: Label = $SafeArea/RootLayout/Footer/StabilityLabel
@onready var stability_bar: ProgressBar = $SafeArea/RootLayout/Footer/StabilityBar
@onready var sfx_click: AudioStreamPlayer = $Runtime/Audio/SfxClick
@onready var sfx_error: AudioStreamPlayer = $Runtime/Audio/SfxError
@onready var sfx_relay: AudioStreamPlayer = $Runtime/Audio/SfxRelay
@onready var result_stamp: Control = $ResultStamp

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
	btn_back.text = _tr("da7.common.back", "BACK")
	if is_instance_valid(table_title):
		table_title.text = _tr("da7.a.ui.data_mode_title", "DATA MODE // READ-ONLY")
	_update_stability_ui()
	if not current_case.is_empty():
		_refresh_case_ui_i18n()

func _refresh_case_ui_i18n() -> void:
	var case_id: String = str(current_case.get("id", ""))
	title_label.text = _tr("da7.a.ui.title_running", "CASE #7: DATA ARCHIVE [A {current}/{total}]",
		{"current": current_case_index + 1, "total": session_cases.size()})
	case_title_label.text = _tr("da7.a.ui.case_title", "CASE {value}",
		{"value": str(current_case.get("case_title", current_case.get("id", "")))})
	briefing_label.text = _case_text(case_id, "briefing")
	objective_label.text = _tr("da7.a.ui.objective_label", "OBJECTIVE: {value}",
		{"value": _case_text(case_id, "objective")})
	prompt_label.text = _case_text(case_id, "prompt")
	inspect_label.text = _tr("da7.a.ui.inspect_hint", "Long-press a row or cell to inspect.")
	scan_label.text = _tr("da7.a.ui.scan", "SCAN: {count}", {"count": inspect_count})

func _case_text(case_id: String, field: String) -> String:
	var raw: String = str(current_case.get(field, ""))
	return _tr("da7.a.case.%s.%s" % [case_id, field], raw)

func _case_reveal_text(is_correct: bool, f_reason: Variant) -> String:
	var case_id: String = str(current_case.get("id", ""))
	var reveal: Dictionary = current_case.get("reveal", {}) as Dictionary
	if is_correct:
		var raw: String = str(reveal.get("on_correct", ""))
		var fallback: String = raw if not raw.is_empty() else _tr("da7.a.ui.explain_default_correct", "Correct.")
		return _tr("da7.a.case.%s.reveal.correct" % case_id, fallback)
	var reason_map: Dictionary = reveal.get("on_wrong_by_reason", {}) as Dictionary
	var raw: String = str(reason_map.get(str(f_reason), ""))
	var fallback: String = raw if not raw.is_empty() else _tr("da7.a.ui.explain_default_wrong", "Incorrect.")
	return _tr("da7.a.case.%s.reveal.%s" % [case_id, str(f_reason)], fallback)

func _ready() -> void:
	randomize()
	if not I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.connect(_on_language_changed)
	if not GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.connect(_on_stability_changed)
	if not btn_back.pressed.is_connected(_on_back_pressed):
		btn_back.pressed.connect(_on_back_pressed)
	if not data_tree.gui_input.is_connected(_on_data_tree_gui_input):
		data_tree.gui_input.connect(_on_data_tree_gui_input)
	if data_tree.has_signal("column_title_clicked") and not data_tree.column_title_clicked.is_connected(_on_column_title_clicked):
		data_tree.column_title_clicked.connect(_on_column_title_clicked)
	if not prompt_label.gui_input.is_connected(_on_scroll_input):
		prompt_label.gui_input.connect(_on_scroll_input)
	get_tree().root.size_changed.connect(_on_viewport_size_changed)
	if is_instance_valid(result_stamp):
		result_stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_instance_valid(scanner_overlay):
		scanner_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	options_grid.visible = false
	_init_session()
	_apply_i18n()
	call_deferred("_on_viewport_size_changed")
	_load_next_case()

func _init_session() -> void:
	var all_cases: Array = CasesHub.get_cases("A")
	var valid_cases: Array = []
	for case_v in all_cases:
		if typeof(case_v) != TYPE_DICTIONARY:
			continue
		var case_data: Dictionary = case_v as Dictionary
		if CasesA.validate_case_a(case_data):
			valid_cases.append(case_data)
	if valid_cases.is_empty():
		_show_fatal("В файле scripts/case_07/da7_cases_a.gd не обнаружено действительных случаев DA7 A.")
		return

	valid_cases.shuffle()
	session_cases = valid_cases.slice(0, mini(SESSION_CASE_COUNT, valid_cases.size()))
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
	trial_locked = false
	scroll_used = false
	table_has_scroll = false
	inspect_count = 0
	unique_rows_inspected.clear()
	answered_without_inspection = false
	last_inspected_row_id = ""
	time_to_first_inspect_ms = -1
	miss_click_count = 0
	row_item_by_id.clear()
	col_index_by_id.clear()
	col_id_by_index.clear()
	row_data_by_id.clear()
	_press_active = false
	_press_moved = false
	_press_hit.clear()
	_set_tree_locked(false)

	_render_case()

func _render_case() -> void:
	_set_tree_locked(false)
	trial_locked = false
	var case_id: String = str(current_case.get("id", ""))
	title_label.text = _tr("da7.a.ui.title_running", "CASE #7: DATA ARCHIVE [A {current}/{total}]",
		{"current": current_case_index + 1, "total": session_cases.size()})
	case_title_label.text = _tr("da7.a.ui.case_title", "CASE {value}",
		{"value": str(current_case.get("case_title", current_case.get("id", "")))})
	briefing_label.bbcode_enabled = false
	briefing_label.text = _case_text(case_id, "briefing")
	objective_label.text = _tr("da7.a.ui.objective_label", "OBJECTIVE: {value}",
		{"value": _case_text(case_id, "objective")})
	prompt_label.bbcode_enabled = false
	prompt_label.text = _case_text(case_id, "prompt")
	explain_line.bbcode_enabled = false
	explain_line.text = ""
	inspect_label.bbcode_enabled = false
	inspect_label.text = _tr("da7.a.ui.inspect_hint", "Long-press a row or cell to inspect.")
	scan_label.text = _tr("da7.a.ui.scan", "SCAN: {count}", {"count": 0})
	options_grid.visible = false
	for child in options_grid.get_children():
		child.queue_free()

	_render_table(current_case.get("table", {}) as Dictionary)
	call_deferred("_update_silent_reading_possible_flag")

func _render_table(table_def: Dictionary) -> void:
	data_tree.clear()
	row_item_by_id.clear()
	col_index_by_id.clear()
	col_id_by_index.clear()
	row_data_by_id.clear()

	var root: TreeItem = data_tree.create_item()
	data_tree.hide_root = true
	data_tree.select_mode = Tree.SELECT_ROW

	var cols: Array = table_def.get("columns", []) as Array
	if cols.is_empty():
		data_tree.columns = 1
		data_tree.set_column_title(0, "NO_DATA")
		data_tree.column_titles_visible = true
		return

	data_tree.columns = cols.size()
	for i in range(cols.size()):
		if typeof(cols[i]) != TYPE_DICTIONARY:
			continue
		var col: Dictionary = cols[i] as Dictionary
		var col_id := str(col.get("col_id", ""))
		col_index_by_id[col_id] = i
		col_id_by_index[i] = col_id
		data_tree.set_column_title(i, str(col.get("title", col_id.to_upper())))
	data_tree.column_titles_visible = true

	var rows: Array = (table_def.get("rows", []) as Array).duplicate(true)
	var anti_cheat: Dictionary = current_case.get("anti_cheat", {}) as Dictionary
	if bool(anti_cheat.get("shuffle_rows", false)):
		rows.shuffle()

	for row_v in rows:
		if typeof(row_v) != TYPE_DICTIONARY:
			continue
		var row_data: Dictionary = row_v as Dictionary
		var row_id := str(row_data.get("row_id", ""))
		if row_id.is_empty():
			continue
		var row_item: TreeItem = data_tree.create_item(root)
		row_item.set_metadata(0, row_id)
		row_item_by_id[row_id] = row_item
		row_data_by_id[row_id] = row_data

		var cells: Dictionary = row_data.get("cells", {}) as Dictionary
		for i in range(cols.size()):
			if typeof(cols[i]) != TYPE_DICTIONARY:
				continue
			var col_def: Dictionary = cols[i] as Dictionary
			var col_id := str(col_def.get("col_id", ""))
			row_item.set_text(i, str(cells.get(col_id, "")))

	if is_instance_valid(scanner_overlay) and scanner_overlay.has_method("clear_highlight"):
		scanner_overlay.call("clear_highlight")
	if is_instance_valid(scanner_overlay) and scanner_overlay.has_method("clear_cursor"):
		scanner_overlay.call("clear_cursor")

func _on_data_tree_gui_input(event: InputEvent) -> void:
	if trial_locked:
		return
	if event is InputEventMouseMotion:
		var motion: InputEventMouseMotion = event
		_update_scanner_hover(motion.position)
		if _press_active and motion.position.distance_to(_press_start_pos) > LONG_PRESS_MOVE_PX:
			_press_moved = true
		return
	if event is InputEventScreenDrag:
		scroll_used = true
		if _press_active:
			var drag: InputEventScreenDrag = event
			if drag.position.distance_to(_press_start_pos) > LONG_PRESS_MOVE_PX:
				_press_moved = true
		return
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP or mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scroll_used = true
			return
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse_event.pressed:
			_press_active = true
			_press_start_ms = Time.get_ticks_msec()
			_press_start_pos = mouse_event.position
			_press_moved = false
			_press_hit = _resolve_hit_data(mouse_event.position)
			return
		if not _press_active:
			return
		var hold_ms := Time.get_ticks_msec() - _press_start_ms
		var release_hit: Dictionary = _resolve_hit_data(mouse_event.position)
		_press_active = false
		if hold_ms >= LONG_PRESS_MS and not _press_moved:
			_handle_long_press(release_hit if not release_hit.is_empty() else _press_hit)
		else:
			_handle_tree_click(release_hit)
		return
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed:
			_press_active = true
			_press_start_ms = Time.get_ticks_msec()
			_press_start_pos = touch.position
			_press_moved = false
			_press_hit = _resolve_hit_data(touch.position)
		else:
			if not _press_active:
				return
			var touch_hold_ms := Time.get_ticks_msec() - _press_start_ms
			var touch_hit: Dictionary = _resolve_hit_data(touch.position)
			_press_active = false
			if touch_hold_ms >= LONG_PRESS_MS and not _press_moved:
				_handle_long_press(touch_hit if not touch_hit.is_empty() else _press_hit)
			else:
				_handle_tree_click(touch_hit)

func _on_column_title_clicked(column: int, mouse_button_index: int = MOUSE_BUTTON_LEFT) -> void:
	if trial_locked:
		return
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return
	_register_first_action()
	var col_id := str(col_id_by_index.get(column, ""))
	if col_id.is_empty():
		miss_click_count += 1
		return
	var target := _find_target("COLUMN_HEADER", "header", col_id)
	if target.is_empty():
		miss_click_count += 1
		return
	answered_without_inspection = inspect_count == 0
	_submit_target(target, "COLUMN_HEADER", "header", col_id)

func _update_scanner_hover(local_pos: Vector2) -> void:
	if not is_instance_valid(scanner_overlay):
		return
	var overlay_point := _tree_local_to_overlay(local_pos)
	if scanner_overlay.has_method("set_cursor"):
		scanner_overlay.call("set_cursor", overlay_point)
	var hit := _resolve_hit_data(local_pos)
	if hit.is_empty():
		if scanner_overlay.has_method("clear_highlight"):
			scanner_overlay.call("clear_highlight")
		return
	if scanner_overlay.has_method("set_highlight_rect"):
		var rect: Rect2 = hit.get("rect", Rect2())
		scanner_overlay.call("set_highlight_rect", _tree_rect_to_overlay(rect))

func _handle_long_press(hit: Dictionary) -> void:
	if hit.is_empty():
		return
	_register_first_action()
	var row_id := str(hit.get("row_id", ""))
	var col_id := str(hit.get("col_id", ""))
	_register_inspection(row_id)
	inspect_label.text = _build_inspect_line(row_id, col_id)
	_play_sound("click", sfx_click)
	if is_instance_valid(scanner_overlay) and scanner_overlay.has_method("pulse"):
		scanner_overlay.call("pulse", hit.get("overlay_center", Vector2.ZERO))

func _handle_tree_click(hit: Dictionary) -> void:
	_register_first_action()
	if hit.is_empty():
		miss_click_count += 1
		return
	var row_id := str(hit.get("row_id", ""))
	var col_id := str(hit.get("col_id", ""))
	var target := _find_target("CELL", row_id, col_id)
	if target.is_empty():
		target = _find_target("ROW", row_id, "")
	if target.is_empty():
		miss_click_count += 1
		_register_inspection(row_id)
		inspect_label.text = _build_inspect_line(row_id, col_id)
		_play_sound("click", sfx_click)
		return
	answered_without_inspection = inspect_count == 0
	_submit_target(target, str(target.get("kind", "CELL")), row_id, col_id)

func _resolve_hit_data(local_pos: Vector2) -> Dictionary:
	var item: TreeItem = data_tree.get_item_at_position(local_pos)
	if item == null:
		return {}
	var col_idx := _resolve_column_index(item, local_pos)
	if col_idx < 0:
		return {}
	var rect := data_tree.get_item_area_rect(item, col_idx)
	var row_id := str(item.get_metadata(0))
	var col_id := str(col_id_by_index.get(col_idx, ""))
	return {
		"item": item,
		"row_id": row_id,
		"col_idx": col_idx,
		"col_id": col_id,
		"rect": rect,
		"overlay_center": _tree_local_to_overlay(rect.get_center())
	}

func _resolve_column_index(item: TreeItem, local_pos: Vector2) -> int:
	for col_idx in range(data_tree.columns):
		var rect := data_tree.get_item_area_rect(item, col_idx)
		if rect.has_point(local_pos):
			return col_idx
	return -1

func _find_target(kind: String, row_id: String, col_id: String) -> Dictionary:
	var targets: Array = current_case.get("targets", []) as Array
	for target_v in targets:
		if typeof(target_v) != TYPE_DICTIONARY:
			continue
		var target: Dictionary = target_v as Dictionary
		if str(target.get("kind", "")) != kind:
			continue
		if str(target.get("row_id", "")) != row_id:
			continue
		if kind == "ROW":
			return target
		if str(target.get("col_id", "")) == col_id:
			return target
	return {}

func _submit_target(target: Dictionary, clicked_kind: String, row_id: String, col_id: String) -> void:
	if trial_locked:
		return
	trial_locked = true
	_set_tree_locked(true)

	var is_correct := bool(target.get("is_correct", false))
	var f_reason: Variant = null
	if not is_correct:
		f_reason = target.get("f_reason", "WRONG_OPTION_GENERIC")
	if is_correct:
		_play_sound("relay", sfx_relay)
	else:
		_play_sound("error", sfx_error)

	_apply_highlight(current_case.get("highlight", {}) as Dictionary)
	_show_explain_line(is_correct, f_reason)
	if is_instance_valid(result_stamp) and result_stamp.has_method("show_result"):
		result_stamp.call("show_result", is_correct)
	if is_instance_valid(scanner_overlay) and scanner_overlay.has_method("pulse"):
		scanner_overlay.call("pulse", _tree_local_to_overlay(_press_start_pos))

	_log_trial(is_correct, f_reason, target, clicked_kind, row_id, col_id)
	_update_stability_ui()

	await get_tree().create_timer(0.9).timeout
	if not is_inside_tree():
		return
	if current_case_index >= session_cases.size():
		return
	if GlobalMetrics.stability <= 0.0:
		_game_over()
	else:
		_load_next_case()

func _show_explain_line(is_correct: bool, f_reason: Variant) -> void:
	explain_line.text = _case_reveal_text(is_correct, f_reason)

func _apply_highlight(highlight: Dictionary) -> void:
	if highlight.is_empty():
		return
	var mode := str(highlight.get("mode", "")).to_upper()
	var bg := Color(0.42, 0.30, 0.10, 0.55)
	var fg := Color(1.0, 0.94, 0.78, 1.0)

	match mode:
		"ROWS":
			var target_rows: Array = highlight.get("target_row_ids", []) as Array
			for row_id_v in target_rows:
				_highlight_row(str(row_id_v), bg, fg)
		"COLUMNS":
			var target_cols: Array = highlight.get("target_col_ids", []) as Array
			for col_id_v in target_cols:
				var col_id := str(col_id_v)
				if not col_index_by_id.has(col_id):
					continue
				var col_idx := int(col_index_by_id[col_id])
				for row_id_v in row_item_by_id.keys():
					var item: TreeItem = row_item_by_id[row_id_v] as TreeItem
					_highlight_cell(item, col_idx, bg, fg)
		"CELL":
			var target_cell: Dictionary = highlight.get("target_cell", {}) as Dictionary
			var row_id := str(target_cell.get("row_id", ""))
			var col_id := str(target_cell.get("col_id", ""))
			if row_item_by_id.has(row_id) and col_index_by_id.has(col_id):
				var row_item: TreeItem = row_item_by_id[row_id] as TreeItem
				var col_idx := int(col_index_by_id[col_id])
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

func _set_tree_locked(locked: bool) -> void:
	data_tree.mouse_filter = Control.MOUSE_FILTER_IGNORE if locked else Control.MOUSE_FILTER_STOP

func _register_first_action() -> void:
	if first_action_ts < 0:
		first_action_ts = Time.get_ticks_msec()

func _register_inspection(row_id: String) -> void:
	inspect_count += 1
	if time_to_first_inspect_ms < 0:
		time_to_first_inspect_ms = Time.get_ticks_msec() - case_started_ts
	if not row_id.is_empty():
		unique_rows_inspected[row_id] = true
		last_inspected_row_id = row_id
	scan_label.text = _tr("da7.a.ui.scan", "SCAN: {count}", {"count": inspect_count})

func _build_inspect_line(row_id: String, col_id: String) -> String:
	if not row_data_by_id.has(row_id):
		return _tr("da7.a.ui.inspect_missing", "INSPECT: row={row} col={col}", {"row": row_id, "col": col_id})
	var row_data: Dictionary = row_data_by_id[row_id] as Dictionary
	var table_def: Dictionary = current_case.get("table", {}) as Dictionary
	var cols: Array = table_def.get("columns", []) as Array
	var cells: Dictionary = row_data.get("cells", {}) as Dictionary
	var parts: Array[String] = []
	for col_v in cols:
		if typeof(col_v) != TYPE_DICTIONARY:
			continue
		var col_def: Dictionary = col_v as Dictionary
		var id := str(col_def.get("col_id", ""))
		parts.append("%s=%s" % [str(col_def.get("title", id)), str(cells.get(id, ""))])
	return "Осмотрите %s [%s]: %s" % [row_id, col_id, " | ".join(parts)]

func _log_trial(is_correct: bool, f_reason: Variant, target: Dictionary, clicked_kind: String, row_id: String, col_id: String) -> void:
	var now_ms := Time.get_ticks_msec()
	var elapsed_ms := now_ms - case_started_ts
	var first_action_ms := elapsed_ms
	if first_action_ts >= case_started_ts:
		first_action_ms = first_action_ts - case_started_ts
	var silent_reading_possible := (not table_has_scroll and not scroll_used and first_action_ms >= 30000)
	var case_id := str(current_case.get("id", "DA7-A-00"))
	var payload: Dictionary = {
		"question_id": case_id,
		"case_id": case_id,
		"quest_id": "DA7",
		"quest": "data_archive",
		"stage": "A",
		"level": "A",
		"topic": str(current_case.get("topic", "DB_BASICS")),
		"interaction_type": str(current_case.get("interaction_type", "SINGLE_CHOICE")),
		"interaction_variant": str(current_case.get("interaction_variant", "CLICK_TARGET")),
		"schema_version": str(current_case.get("schema_version", "DA7.A.v4")),
		"match_key": "DA7_A|%s" % case_id,
		"is_correct": is_correct,
		"f_reason": f_reason,
		"elapsed_ms": elapsed_ms,
		"duration": float(elapsed_ms) / 1000.0,
		"timing": {
			"effective_elapsed_ms": elapsed_ms,
			"time_to_first_action_ms": first_action_ms,
			"time_to_first_inspect_ms": time_to_first_inspect_ms,
			"policy_mode": str((current_case.get("timing_policy", {}) as Dictionary).get("mode", "LEARNING")),
			"limit_sec": int((current_case.get("timing_policy", {}) as Dictionary).get("limit_sec", 120))
		},
		"answer": {
			"clicked_target_id": str(target.get("id", "")),
			"clicked_kind": clicked_kind,
			"row_id": row_id,
			"col_id": col_id
		},
		"flags": {
			"silent_reading_possible": silent_reading_possible,
			"scroll_used": scroll_used,
			"answered_without_inspection": answered_without_inspection
		},
		"telemetry": {
			"inspect_count": inspect_count,
			"unique_rows_inspected": unique_rows_inspected.size(),
			"time_to_first_inspect_ms": time_to_first_inspect_ms,
			"answered_without_inspection": answered_without_inspection,
			"clicked_target_kind": clicked_kind,
			"miss_click_count": miss_click_count,
			"last_inspected_row_id": last_inspected_row_id
		}
	}
	GlobalMetrics.register_trial(payload)

func _tree_local_to_overlay(tree_local: Vector2) -> Vector2:
	if not is_instance_valid(scanner_overlay):
		return tree_local
	var global_pos := data_tree.get_global_transform_with_canvas() * tree_local
	return scanner_overlay.get_global_transform_with_canvas().affine_inverse() * global_pos

func _tree_rect_to_overlay(tree_rect: Rect2) -> Rect2:
	if not is_instance_valid(scanner_overlay):
		return tree_rect
	var global_pos := data_tree.get_global_transform_with_canvas() * tree_rect.position
	var global_end := data_tree.get_global_transform_with_canvas() * tree_rect.end
	var overlay_pos := scanner_overlay.get_global_transform_with_canvas().affine_inverse() * global_pos
	var overlay_end := scanner_overlay.get_global_transform_with_canvas().affine_inverse() * global_end
	return Rect2(overlay_pos, overlay_end - overlay_pos)

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

func _finish_session() -> void:
	trial_locked = true
	_set_tree_locked(true)
	title_label.text = _tr("da7.a.ui.title_complete", "DATA ARCHIVE // SESSION COMPLETE [A]")
	prompt_label.bbcode_enabled = true
	prompt_label.text = "[b]%s[/b]" % _tr("da7.a.ui.session_complete", "Investigation complete.")
	explain_line.text = ""
	_ensure_exit_button()

func _game_over() -> void:
	trial_locked = true
	_set_tree_locked(true)
	title_label.text = _tr("da7.a.ui.title_locked", "DATA ARCHIVE // SYSTEM LOCK [A]")
	prompt_label.bbcode_enabled = true
	prompt_label.text = "[b]%s[/b]" % _tr("da7.a.ui.system_lock", "Stability dropped to zero.")
	explain_line.text = ""
	_ensure_exit_button()

func _ensure_exit_button() -> void:
	if exit_btn != null and is_instance_valid(exit_btn):
		return
	exit_btn = Button.new()
	exit_btn.text = _tr("da7.common.exit", "EXIT")
	exit_btn.custom_minimum_size = Vector2(140, 48)
	exit_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")
	)
	$SafeArea/RootLayout/Footer.add_child(exit_btn)

func _show_fatal(text: String) -> void:
	prompt_label.bbcode_enabled = false
	prompt_label.text = text
	trial_locked = true
	_set_tree_locked(true)

func _play_sound(sound_name: String, fallback: AudioStreamPlayer) -> void:
	var manager := get_node_or_null("/root/AudioManager")
	if manager != null and manager.has_method("play"):
		manager.call("play", sound_name)
		return
	if is_instance_valid(fallback):
		fallback.play()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _on_stability_changed(_new_val: float, _delta: float) -> void:
	_update_stability_ui()

func _update_stability_ui() -> void:
	if is_instance_valid(stability_bar):
		stability_bar.value = GlobalMetrics.stability
	if is_instance_valid(stability_label):
		stability_label.text = _tr("da7.common.stability", "STABILITY: {value}%", {"value": int(GlobalMetrics.stability)})

func _on_viewport_size_changed() -> void:
	var viewport_size := get_viewport_rect().size
	var is_mobile := viewport_size.x < BREAKPOINT_PX
	desktop_layout.split_offset = int(viewport_size.x * 0.48)

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
