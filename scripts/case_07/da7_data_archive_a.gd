extends Control

const CasesHub = preload("res://scripts/case_07/da7_cases.gd")
const CasesA = preload("res://scripts/case_07/da7_cases_a.gd")

const BREAKPOINT_PX := 800
const SESSION_CASE_COUNT := 6
const LONG_PRESS_MS := 350
const LONG_PRESS_MOVE_PX := 10.0
const HEADER_ROW_ID := "header"
const LAYOUT_MOBILE := "mobile"
const LAYOUT_DESKTOP := "desktop"

enum TrialState {
	IDLE,
	INSPECT_MODE,
	TARGET_SELECTED,
	ANSWER_LOCKED,
	CASE_RESOLVED
}

var session_cases: Array = []
var current_case_index := -1
var current_case: Dictionary = {}
var case_started_ts := 0
var first_action_ts := -1
var trial_locked := false
var scroll_used := false
var table_has_scroll := false
var table_width_overflow := false
var current_layout_mode := LAYOUT_DESKTOP
var exit_btn: Button

var trial_seq: int = 0
var task_session: Dictionary = {}
var check_attempt_count: int = 0
var details_open_count: int = 0
var hint_open_count: int = 0

var inspect_open_count: int = 0
var inspect_cell_count: int = 0
var inspect_header_count: int = 0
var scan_action_count: int = 0
var selection_change_count: int = 0
var row_click_count: int = 0
var cell_click_count: int = 0
var header_click_count: int = 0
var misclick_count: int = 0
var time_to_first_selection_ms: int = -1
var time_to_submit_ms: int = -1
var changed_after_inspect: bool = false

var inspect_count := 0
var unique_rows_inspected: Dictionary = {}
var answered_without_inspection := false
var last_inspected_row_id := ""
var time_to_first_inspect_ms := -1
var miss_click_count := 0

var selected_before_submit := false
var selection_changes_count := 0
var confirm_submit_used := false
var submit_via_double_click := false
var inspect_via_long_press_count := 0
var inspect_via_button_count := 0
var invalid_tap_count := 0
var invalid_header_tap_count := 0
var invalid_cell_tap_count := 0
var invalid_row_tap_count := 0
var tap_on_non_answerable_area_count := 0
var tap_cancelled_by_scroll_count := 0
var selected_target_changed_before_submit := false
var answered_after_inspection := false
var inspected_same_target_before_submit := false
var submit_latency_after_selection_ms := -1
var mobile_layout_used := false

var tutorial_seen_once := false
var tutorial_shown := false
var tutorial_dismissed := false
var tutorial_completed := false

var row_item_by_id: Dictionary = {}
var col_index_by_id: Dictionary = {}
var col_id_by_index: Dictionary = {}
var row_data_by_id: Dictionary = {}

var trial_state := TrialState.IDLE
var selected_target: Dictionary = {}
var selected_clicked_kind := ""
var selected_row_id := ""
var selected_col_id := ""
var selected_signature := ""
var selected_target_ts := -1
var inspected_target_signatures: Dictionary = {}

var _press_active := false
var _press_start_ms := 0
var _press_start_pos := Vector2.ZERO
var _press_moved := false
var _press_hit: Dictionary = {}
var _transition_token := 0
var _body_scroll_installed: bool = false

@onready var title_label: RichTextLabel = $SafeArea/RootLayout/Header/Margin/Title
@onready var btn_back: Button = $SafeArea/RootLayout/BackRow/BtnBack
@onready var root_layout: VBoxContainer = $SafeArea/RootLayout
@onready var body_container: MarginContainer = $SafeArea/RootLayout/Body
@onready var desktop_layout: HSplitContainer = $SafeArea/RootLayout/Body/DesktopLayout
@onready var mobile_layout: VBoxContainer = $SafeArea/RootLayout/Body/MobileLayout
@onready var table_section: VBoxContainer = $SafeArea/RootLayout/Body/DesktopLayout/TableSection
@onready var task_section: VBoxContainer = $SafeArea/RootLayout/Body/DesktopLayout/TaskSection
@onready var data_tree: Tree = $SafeArea/RootLayout/Body/DesktopLayout/TableSection/DataTree
@onready var table_title: Label = $SafeArea/RootLayout/Body/DesktopLayout/TableSection/TableTitle
@onready var scanner_overlay: Control = get_node_or_null("SafeArea/RootLayout/Body/DesktopLayout/TableSection/ScannerOverlay") as Control
@onready var inspect_panel: PanelContainer = $SafeArea/RootLayout/Body/DesktopLayout/TableSection/InspectPanel
@onready var btn_inspect: Button = $SafeArea/RootLayout/Body/DesktopLayout/TableSection/InspectPanel/InspectMargin/InspectVBox/InspectToolbar/BtnInspect
@onready var inspect_mode_label: Label = $SafeArea/RootLayout/Body/DesktopLayout/TableSection/InspectPanel/InspectMargin/InspectVBox/InspectToolbar/InspectModeLabel
@onready var inspect_label: RichTextLabel = $SafeArea/RootLayout/Body/DesktopLayout/TableSection/InspectPanel/InspectMargin/InspectVBox/InspectLabel
@onready var scan_label: Label = $SafeArea/RootLayout/Body/DesktopLayout/TableSection/InspectPanel/InspectMargin/InspectVBox/ScanLabel
@onready var selected_label: RichTextLabel = $SafeArea/RootLayout/Body/DesktopLayout/TableSection/ActionPanel/ActionMargin/ActionVBox/SelectedLabel
@onready var status_label: Label = $SafeArea/RootLayout/Body/DesktopLayout/TableSection/ActionPanel/ActionMargin/ActionVBox/StatusLabel
@onready var btn_confirm_answer: Button = $SafeArea/RootLayout/Body/DesktopLayout/TableSection/ActionPanel/ActionMargin/ActionVBox/BtnConfirmAnswer
@onready var case_title_label: Label = $SafeArea/RootLayout/Body/DesktopLayout/TaskSection/DossierPanel/DossierMargin/DossierVBox/CaseTitleLabel
@onready var briefing_label: RichTextLabel = $SafeArea/RootLayout/Body/DesktopLayout/TaskSection/DossierPanel/DossierMargin/DossierVBox/BriefingLabel
@onready var objective_label: Label = $SafeArea/RootLayout/Body/DesktopLayout/TaskSection/DossierPanel/DossierMargin/DossierVBox/ObjectiveLabel
@onready var prompt_label: RichTextLabel = $SafeArea/RootLayout/Body/DesktopLayout/TaskSection/PromptLabel
@onready var options_grid: GridContainer = $SafeArea/RootLayout/Body/DesktopLayout/TaskSection/OptionsGrid
@onready var explain_line: RichTextLabel = $SafeArea/RootLayout/Body/DesktopLayout/TaskSection/ExplainLine
@onready var stability_label: Label = $SafeArea/RootLayout/Footer/StabilityLabel
@onready var stability_bar: ProgressBar = $SafeArea/RootLayout/Footer/StabilityBar
@onready var tutorial_overlay: ColorRect = $TutorialOverlay
@onready var tutorial_title_label: Label = $TutorialOverlay/Center/TutorialPanel/TutorialMargin/TutorialVBox/TutorialTitle
@onready var tutorial_step_1: Label = $TutorialOverlay/Center/TutorialPanel/TutorialMargin/TutorialVBox/TutorialStep1
@onready var tutorial_step_2: Label = $TutorialOverlay/Center/TutorialPanel/TutorialMargin/TutorialVBox/TutorialStep2
@onready var tutorial_step_3: Label = $TutorialOverlay/Center/TutorialPanel/TutorialMargin/TutorialVBox/TutorialStep3
@onready var tutorial_close_btn: Button = $TutorialOverlay/Center/TutorialPanel/TutorialMargin/TutorialVBox/BtnTutorialClose
@onready var sfx_click: AudioStreamPlayer = $Runtime/Audio/SfxClick
@onready var sfx_error: AudioStreamPlayer = $Runtime/Audio/SfxError
@onready var sfx_relay: AudioStreamPlayer = $Runtime/Audio/SfxRelay
@onready var result_stamp: Control = $ResultStamp

func _exit_tree() -> void:
	_bump_transition_token()
	if I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.disconnect(_on_language_changed)
	if GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.disconnect(_on_stability_changed)
	if btn_back.pressed.is_connected(_on_back_pressed):
		btn_back.pressed.disconnect(_on_back_pressed)
	if btn_inspect.pressed.is_connected(_on_inspect_button_pressed):
		btn_inspect.pressed.disconnect(_on_inspect_button_pressed)
	if btn_confirm_answer.pressed.is_connected(_on_confirm_answer_pressed):
		btn_confirm_answer.pressed.disconnect(_on_confirm_answer_pressed)
	if tutorial_close_btn.pressed.is_connected(_on_tutorial_close_pressed):
		tutorial_close_btn.pressed.disconnect(_on_tutorial_close_pressed)
	if data_tree.gui_input.is_connected(_on_data_tree_gui_input):
		data_tree.gui_input.disconnect(_on_data_tree_gui_input)
	if data_tree.has_signal("column_title_clicked") and data_tree.column_title_clicked.is_connected(_on_column_title_clicked):
		data_tree.column_title_clicked.disconnect(_on_column_title_clicked)
	if prompt_label.gui_input.is_connected(_on_scroll_input):
		prompt_label.gui_input.disconnect(_on_scroll_input)
	var root := get_tree().root
	if root != null and root.size_changed.is_connected(_on_viewport_size_changed):
		root.size_changed.disconnect(_on_viewport_size_changed)

func _tr(key: String, default_text: String, params: Dictionary = {}) -> String:
	var merged: Dictionary = params.duplicate(true)
	merged["default"] = default_text
	return I18n.tr_key(key, merged)

func _on_language_changed(_code: String) -> void:
	_apply_i18n()

func _apply_i18n() -> void:
	btn_back.text = _tr("da7.common.back", "BACK")
	btn_inspect.text = _tr("archive_a.btn.inspect", "INSPECT")
	btn_confirm_answer.text = _tr("archive_a.btn.confirm_answer", "CONFIRM ANSWER")
	if is_instance_valid(exit_btn):
		exit_btn.text = _tr("da7.common.exit", "EXIT")
	if is_instance_valid(table_title):
		table_title.text = _tr("da7.a.ui.data_mode_title", "DATA MODE // READ-ONLY")
	if is_instance_valid(tutorial_title_label):
		tutorial_title_label.text = _tr("archive_a.tutorial.title", "ARCHIVE BRIEFING")
	if is_instance_valid(tutorial_step_1):
		tutorial_step_1.text = _tr("archive_a.tutorial.step1", "Tap a table element to select an answer target.")
	if is_instance_valid(tutorial_step_2):
		tutorial_step_2.text = _tr("archive_a.tutorial.step2", "Long-press or press Inspect to examine evidence.")
	if is_instance_valid(tutorial_step_3):
		tutorial_step_3.text = _tr("archive_a.tutorial.step3", "Column headers can also be correct answers.")
	if is_instance_valid(tutorial_close_btn):
		tutorial_close_btn.text = _tr("archive_a.tutorial.close", "START INVESTIGATION")
	_update_stability_ui()
	_update_inspect_mode_label()
	if not current_case.is_empty():
		_refresh_case_ui_i18n()
	else:
		_set_idle_inspect_hint()
		scan_label.text = _tr("da7.a.ui.scan", "SCAN: {count}", {"count": inspect_count})
	_update_selection_ui()

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
	if inspect_count <= 0:
		_set_idle_inspect_hint()
	scan_label.text = _tr("da7.a.ui.scan", "SCAN: {count}", {"count": inspect_count})
	_update_selection_ui()

func _set_idle_inspect_hint() -> void:
	inspect_label.text = _tr("da7.a.ui.inspect_hint", "Long-press a row/cell or press Inspect to examine evidence.")

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
	if not btn_inspect.pressed.is_connected(_on_inspect_button_pressed):
		btn_inspect.pressed.connect(_on_inspect_button_pressed)
	if not btn_confirm_answer.pressed.is_connected(_on_confirm_answer_pressed):
		btn_confirm_answer.pressed.connect(_on_confirm_answer_pressed)
	if not tutorial_close_btn.pressed.is_connected(_on_tutorial_close_pressed):
		tutorial_close_btn.pressed.connect(_on_tutorial_close_pressed)
	if not data_tree.gui_input.is_connected(_on_data_tree_gui_input):
		data_tree.gui_input.connect(_on_data_tree_gui_input)
	if data_tree.has_signal("column_title_clicked") and not data_tree.column_title_clicked.is_connected(_on_column_title_clicked):
		data_tree.column_title_clicked.connect(_on_column_title_clicked)
	if not prompt_label.gui_input.is_connected(_on_scroll_input):
		prompt_label.gui_input.connect(_on_scroll_input)
	var root := get_tree().root
	if root != null and not root.size_changed.is_connected(_on_viewport_size_changed):
		root.size_changed.connect(_on_viewport_size_changed)
	if is_instance_valid(result_stamp):
		result_stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_instance_valid(scanner_overlay):
		scanner_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_install_body_scroll()
	options_grid.visible = false
	if is_instance_valid(tutorial_overlay):
		tutorial_overlay.visible = false
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
		_show_fatal("No valid DA7 A cases found in scripts/case_07/da7_cases_a.gd")
		return

	valid_cases.shuffle()
	session_cases = valid_cases.slice(0, mini(SESSION_CASE_COUNT, valid_cases.size()))
	current_case_index = -1
	GlobalMetrics.stability = 100.0
	_update_stability_ui()

func _load_next_case() -> void:
	_bump_transition_token()
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
	table_width_overflow = false
	check_attempt_count = 0
	details_open_count = 0
	hint_open_count = 0
	inspect_open_count = 0
	inspect_cell_count = 0
	inspect_header_count = 0
	scan_action_count = 0
	selection_change_count = 0
	row_click_count = 0
	cell_click_count = 0
	header_click_count = 0
	misclick_count = 0
	time_to_first_selection_ms = -1
	time_to_submit_ms = -1
	changed_after_inspect = false
	inspect_count = 0
	unique_rows_inspected.clear()
	answered_without_inspection = false
	last_inspected_row_id = ""
	time_to_first_inspect_ms = -1
	miss_click_count = 0
	selected_before_submit = false
	selection_changes_count = 0
	confirm_submit_used = false
	submit_via_double_click = false
	inspect_via_long_press_count = 0
	inspect_via_button_count = 0
	invalid_tap_count = 0
	invalid_header_tap_count = 0
	invalid_cell_tap_count = 0
	invalid_row_tap_count = 0
	tap_on_non_answerable_area_count = 0
	tap_cancelled_by_scroll_count = 0
	selected_target_changed_before_submit = false
	answered_after_inspection = false
	inspected_same_target_before_submit = false
	submit_latency_after_selection_ms = -1
	mobile_layout_used = current_layout_mode == LAYOUT_MOBILE
	tutorial_shown = false
	tutorial_dismissed = false
	tutorial_completed = false
	row_item_by_id.clear()
	col_index_by_id.clear()
	col_id_by_index.clear()
	row_data_by_id.clear()
	inspected_target_signatures.clear()
	selected_target.clear()
	selected_clicked_kind = ""
	selected_row_id = ""
	selected_col_id = ""
	selected_signature = ""
	selected_target_ts = -1
	trial_state = TrialState.IDLE
	_press_active = false
	_press_moved = false
	_press_hit.clear()
	_set_tree_locked(false)
	_clear_selection_visual()
	_begin_trial_session()
	if is_instance_valid(tutorial_overlay):
		tutorial_overlay.visible = false

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
	_set_idle_inspect_hint()
	scan_label.text = _tr("da7.a.ui.scan", "SCAN: {count}", {"count": 0})
	status_label.text = ""
	options_grid.visible = false
	for child in options_grid.get_children():
		child.queue_free()
	_update_selection_ui()
	_update_inspect_mode_label()

	_render_table(current_case.get("table", {}) as Dictionary)
	call_deferred("_post_render_setup")

func _post_render_setup() -> void:
	_update_silent_reading_possible_flag()
	_show_tutorial_once_if_needed()

func _show_tutorial_once_if_needed() -> void:
	if tutorial_seen_once:
		return
	if not is_instance_valid(tutorial_overlay):
		return
	tutorial_seen_once = true
	tutorial_shown = true
	tutorial_dismissed = false
	tutorial_completed = false
	tutorial_overlay.visible = true
	details_open_count += 1
	_log_event("details_opened", {"source": "tutorial_overlay"})

func _on_tutorial_close_pressed() -> void:
	_dismiss_tutorial(true)

func _dismiss_tutorial(dismissed_by_user: bool) -> void:
	if not is_instance_valid(tutorial_overlay):
		return
	if not tutorial_overlay.visible:
		return
	tutorial_overlay.visible = false
	tutorial_completed = true
	if dismissed_by_user:
		tutorial_dismissed = true

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
	_clear_selection_visual()

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
		var moved := _press_moved
		var is_double_click := mouse_event.double_click
		_press_active = false
		if moved:
			_handle_invalid_interaction("tap_cancelled_by_scroll", "", "", "")
			return
		if hold_ms >= LONG_PRESS_MS:
			_handle_long_press(release_hit if not release_hit.is_empty() else _press_hit)
		else:
			_handle_tree_click(release_hit, is_double_click)
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
			var touch_moved := _press_moved
			_press_active = false
			if touch_moved:
				_handle_invalid_interaction("tap_cancelled_by_scroll", "", "", "")
				return
			if touch_hold_ms >= LONG_PRESS_MS:
				_handle_long_press(touch_hit if not touch_hit.is_empty() else _press_hit)
			else:
				_handle_tree_click(touch_hit, false)

func _on_column_title_clicked(column: int, mouse_button_index: int = MOUSE_BUTTON_LEFT) -> void:
	if trial_locked:
		return
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return
	_register_first_action()
	var col_id := str(col_id_by_index.get(column, ""))
	if col_id.is_empty():
		_handle_invalid_interaction("invalid_target", "HEADER", HEADER_ROW_ID, "")
		return
	var header_hit := _build_header_hit(column, col_id)
	if trial_state == TrialState.INSPECT_MODE:
		_handle_inspect_request(header_hit, "button")
		_restore_state_after_inspect_mode()
		return
	var target := _find_target("COLUMN_HEADER", HEADER_ROW_ID, col_id)
	if target.is_empty():
		_handle_invalid_interaction("invalid_target", "HEADER", HEADER_ROW_ID, col_id)
		return
	_handle_target_select(target, "COLUMN_HEADER", HEADER_ROW_ID, col_id, header_hit)

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
	_handle_inspect_request(hit, "long_press")

func _on_inspect_button_pressed() -> void:
	if trial_locked:
		return
	_register_first_action()
	if trial_state == TrialState.INSPECT_MODE:
		_restore_state_after_inspect_mode()
		status_label.text = _tr("archive_a.inspect_mode_off", "Inspect mode: OFF")
		return
	trial_state = TrialState.INSPECT_MODE
	_update_inspect_mode_label()
	status_label.text = _tr("archive_a.inspect_mode_on", "Inspect mode: ON. Tap a target to inspect.")
	_play_sound("click", sfx_click)

func _on_confirm_answer_pressed() -> void:
	_submit_selected_target(true, false)

func _handle_tree_click(hit: Dictionary, is_double_click: bool = false) -> void:
	_register_first_action()
	if hit.is_empty():
		_handle_invalid_interaction("non_answerable_area", "", "", "")
		return
	if trial_state == TrialState.INSPECT_MODE:
		_handle_inspect_request(hit, "button")
		_restore_state_after_inspect_mode()
		return

	var target_pick := _resolve_target_from_hit(hit)
	if target_pick.is_empty():
		_handle_invalid_interaction("invalid_target", _infer_invalid_zone_for_tree_tap(), str(hit.get("row_id", "")), str(hit.get("col_id", "")))
		return

	var target: Dictionary = target_pick.get("target", {}) as Dictionary
	var clicked_kind := str(target_pick.get("clicked_kind", "CELL"))
	var row_id := str(target_pick.get("row_id", ""))
	var col_id := str(target_pick.get("col_id", ""))
	var candidate_signature := _build_target_signature(clicked_kind, row_id, col_id)
	var was_already_selected := (selected_signature == candidate_signature and not selected_signature.is_empty())
	_handle_target_select(target, clicked_kind, row_id, col_id, hit)
	if is_double_click and was_already_selected:
		_submit_selected_target(false, true)

func _resolve_target_from_hit(hit: Dictionary) -> Dictionary:
	var row_id := str(hit.get("row_id", ""))
	var col_id := str(hit.get("col_id", ""))
	var cell_target := _find_target("CELL", row_id, col_id)
	if not cell_target.is_empty():
		return {
			"target": cell_target,
			"clicked_kind": "CELL",
			"row_id": row_id,
			"col_id": col_id
		}
	var row_target := _find_target("ROW", row_id, "")
	if not row_target.is_empty():
		return {
			"target": row_target,
			"clicked_kind": "ROW",
			"row_id": row_id,
			"col_id": ""
		}
	return {}

func _handle_inspect_request(hit: Dictionary, source: String) -> void:
	_register_first_action()
	if hit.is_empty():
		_handle_invalid_interaction("non_answerable_area", "", "", "")
		return
	var row_id := str(hit.get("row_id", ""))
	var col_id := str(hit.get("col_id", ""))
	var kind := str(hit.get("kind", "CELL")).to_upper()
	if kind.is_empty():
		kind = "CELL"
	if source == "long_press":
		inspect_via_long_press_count += 1
	else:
		inspect_via_button_count += 1
	inspect_open_count += 1
	scan_action_count += 1
	if kind == "COLUMN_HEADER":
		inspect_header_count += 1
	else:
		inspect_cell_count += 1
	_register_inspection(row_id)
	inspected_target_signatures[_build_target_signature(kind, row_id, col_id)] = true
	inspect_label.text = _build_inspect_text(kind, row_id, col_id)
	_log_event("inspect_opened", {
		"kind": kind,
		"row": row_id,
		"col": col_id,
		"source": source,
		"value": inspect_label.text
	})
	_play_sound("click", sfx_click)
	if is_instance_valid(scanner_overlay) and scanner_overlay.has_method("pulse"):
		scanner_overlay.call("pulse", hit.get("overlay_center", Vector2.ZERO))
	if is_instance_valid(scanner_overlay) and scanner_overlay.has_method("set_highlight_rect") and hit.has("rect"):
		var hit_rect: Rect2 = hit.get("rect", Rect2())
		scanner_overlay.call("set_highlight_rect", _tree_rect_to_overlay(hit_rect))

func _build_inspect_text(kind: String, row_id: String, col_id: String) -> String:
	if kind == "COLUMN_HEADER":
		return _build_column_inspect_line(col_id)
	return _build_inspect_line(row_id, col_id)

func _build_column_inspect_line(col_id: String) -> String:
	if col_id.is_empty():
		return _tr("da7.a.ui.inspect_missing", "INSPECT: row={row} col={col}", {"row": HEADER_ROW_ID, "col": col_id})
	var title := _get_column_title(col_id)
	var samples: Array[String] = []
	for row_id_v in row_data_by_id.keys():
		var row_id := str(row_id_v)
		var row_data: Dictionary = row_data_by_id.get(row_id, {}) as Dictionary
		var cells: Dictionary = row_data.get("cells", {}) as Dictionary
		samples.append(str(cells.get(col_id, "")))
		if samples.size() >= 3:
			break
	return "INSPECT COLUMN %s: %s" % [title, ", ".join(samples)]

func _handle_target_select(target: Dictionary, clicked_kind: String, row_id: String, col_id: String, hit: Dictionary) -> void:
	if trial_locked:
		return
	var new_signature := _build_target_signature(clicked_kind, row_id, col_id)
	if time_to_first_selection_ms < 0:
		time_to_first_selection_ms = Time.get_ticks_msec() - case_started_ts
	selection_change_count += 1
	match clicked_kind:
		"ROW":
			row_click_count += 1
		"COLUMN_HEADER":
			header_click_count += 1
		_:
			cell_click_count += 1
	if not selected_signature.is_empty() and selected_signature != new_signature:
		selection_changes_count += 1
		selected_target_changed_before_submit = true
		if inspect_open_count > 0:
			changed_after_inspect = true
	selected_target = target.duplicate(true)
	selected_clicked_kind = clicked_kind
	selected_row_id = row_id
	selected_col_id = col_id
	selected_signature = new_signature
	selected_target_ts = Time.get_ticks_msec()
	_update_selection_visual(clicked_kind, row_id, col_id, hit)
	_update_selection_ui()
	trial_state = TrialState.TARGET_SELECTED
	_update_inspect_mode_label()
	status_label.text = _tr("archive_a.status.selected", "Target selected. Press Confirm Answer.")
	_log_event("selection_changed", {
		"kind": clicked_kind,
		"row": row_id,
		"col": col_id
	})
	if is_instance_valid(scanner_overlay) and scanner_overlay.has_method("pulse"):
		scanner_overlay.call("pulse", hit.get("overlay_center", Vector2.ZERO))
	_play_sound("click", sfx_click)

func _submit_selected_target(submit_from_confirm: bool, submit_from_double_click: bool) -> void:
	if trial_locked:
		return
	if selected_target.is_empty():
		_handle_invalid_interaction("invalid_target", "", "", "")
		return
	check_attempt_count += 1
	selected_before_submit = true
	confirm_submit_used = submit_from_confirm
	submit_via_double_click = submit_from_double_click
	if time_to_submit_ms < 0:
		time_to_submit_ms = Time.get_ticks_msec() - case_started_ts
	if selected_target_ts > 0:
		submit_latency_after_selection_ms = maxi(0, Time.get_ticks_msec() - selected_target_ts)
	else:
		submit_latency_after_selection_ms = -1
	answered_without_inspection = _compute_answered_without_inspection()
	answered_after_inspection = not answered_without_inspection
	inspected_same_target_before_submit = inspected_target_signatures.has(selected_signature)
	mobile_layout_used = current_layout_mode == LAYOUT_MOBILE
	_log_event("submit_pressed", {
		"attempt": check_attempt_count,
		"from_confirm": submit_from_confirm,
		"from_double_click": submit_from_double_click,
		"selected_kind": selected_clicked_kind,
		"selected_row": selected_row_id,
		"selected_col": selected_col_id
	})
	_submit_target(selected_target, selected_clicked_kind, selected_row_id, selected_col_id)

func _handle_invalid_interaction(reason: String, zone: String, _row_id: String, _col_id: String) -> void:
	_register_first_action()
	var toast := _tr("archive_a.toast.invalid_target", "This is not an answer target.")
	match reason:
		"invalid_target":
			invalid_tap_count += 1
			match zone:
				"HEADER":
					invalid_header_tap_count += 1
				"ROW":
					invalid_row_tap_count += 1
				"CELL":
					invalid_cell_tap_count += 1
		"non_answerable_area":
			tap_on_non_answerable_area_count += 1
		"tap_cancelled_by_scroll":
			tap_cancelled_by_scroll_count += 1
			toast = _tr("archive_a.toast.scroll_cancel", "Tap canceled by scroll.")
		_:
			invalid_tap_count += 1
	_recompute_miss_click_count()
	var expected_kind := _expected_kind_label()
	status_label.text = "%s %s" % [toast, _tr("archive_a.toast.try_inspect", "Try Inspect. This case expects {kind}.", {"kind": expected_kind})]
	hint_open_count += 1
	_log_event("hint_opened", {
		"source": "invalid_interaction",
		"reason": reason
	})
	_log_event("selection_invalid", {
		"reason": reason,
		"zone": zone
	})
	_play_sound("error", sfx_error)

func _expected_kind_label() -> String:
	var kind := _correct_target_kind()
	match kind:
		"ROW":
			return _tr("archive_a.kind.row", "row")
		"CELL":
			return _tr("archive_a.kind.cell", "cell")
		"COLUMN_HEADER":
			return _tr("archive_a.kind.column", "column")
	return _tr("archive_a.kind.target", "target")

func _correct_target_kind() -> String:
	var targets: Array = current_case.get("targets", []) as Array
	for target_v in targets:
		if typeof(target_v) != TYPE_DICTIONARY:
			continue
		var target: Dictionary = target_v as Dictionary
		if bool(target.get("is_correct", false)):
			return str(target.get("kind", ""))
	return ""

func _infer_invalid_zone_for_tree_tap() -> String:
	var kind := _correct_target_kind()
	if kind == "ROW":
		return "ROW"
	return "CELL"

func _restore_state_after_inspect_mode() -> void:
	if trial_state != TrialState.INSPECT_MODE:
		return
	if selected_target.is_empty():
		trial_state = TrialState.IDLE
	else:
		trial_state = TrialState.TARGET_SELECTED
	_update_inspect_mode_label()
	status_label.text = _tr("archive_a.inspect_mode_off", "Inspect mode: OFF")

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
		"kind": "CELL",
		"item": item,
		"row_id": row_id,
		"col_idx": col_idx,
		"col_id": col_id,
		"rect": rect,
		"overlay_center": _tree_local_to_overlay(rect.get_center())
	}

func _build_header_hit(column: int, col_id: String) -> Dictionary:
	var rect := _build_column_rect(column)
	if rect.size != Vector2.ZERO:
		rect.position.y = maxf(0.0, rect.position.y - 24.0)
		rect.size.y += 24.0
	return {
		"kind": "COLUMN_HEADER",
		"row_id": HEADER_ROW_ID,
		"col_idx": column,
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
	trial_state = TrialState.ANSWER_LOCKED
	_update_inspect_mode_label()
	_set_tree_locked(true)
	_dismiss_tutorial(false)

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
		var pulse_point := _tree_local_to_overlay(_press_start_pos)
		if selected_signature != "":
			pulse_point = _selection_overlay_center()
		scanner_overlay.call("pulse", pulse_point)

	var error_type: String = "NONE" if is_correct else str(f_reason)
	_log_event("submit_result", {
		"is_correct": is_correct,
		"error_type": error_type,
		"selected_kind": clicked_kind,
		"selected_row": row_id,
		"selected_col": col_id
	})
	task_session["ended_at_ticks"] = Time.get_ticks_msec()
	_log_event("trial_finished", {
		"is_correct": is_correct,
		"error_type": error_type
	})
	_log_trial(is_correct, f_reason, target, clicked_kind, row_id, col_id)
	_update_stability_ui()

	var transition_token := _transition_token
	await get_tree().create_timer(0.9).timeout
	if not is_inside_tree():
		return
	if transition_token != _transition_token:
		return
	if current_case_index >= session_cases.size():
		return
	trial_state = TrialState.CASE_RESOLVED
	_update_inspect_mode_label()
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

func _update_inspect_mode_label() -> void:
	if not is_instance_valid(inspect_mode_label):
		return
	if trial_state == TrialState.INSPECT_MODE:
		inspect_mode_label.text = _tr("archive_a.inspect_mode_on", "Inspect mode: ON. Tap a target to inspect.")
	else:
		inspect_mode_label.text = _tr("archive_a.inspect_mode_off", "Inspect mode: OFF")

func _update_selection_ui() -> void:
	if not is_instance_valid(selected_label):
		return
	if selected_target.is_empty():
		selected_label.text = _tr("archive_a.selected.none", "No target selected.")
		if is_instance_valid(btn_confirm_answer):
			btn_confirm_answer.disabled = true
		return
	var row_title := selected_row_id
	var col_title := _get_column_title(selected_col_id)
	match selected_clicked_kind:
		"ROW":
			selected_label.text = _tr("archive_a.selected.row", "Selected: row {row_id}", {"row_id": row_title})
		"COLUMN_HEADER":
			selected_label.text = _tr("archive_a.selected.column", "Selected: column {col_id}", {"col_id": col_title})
		_:
			selected_label.text = _tr("archive_a.selected.cell", "Selected: cell {col_id} / row {row_id}",
				{"col_id": col_title, "row_id": row_title})
	if is_instance_valid(btn_confirm_answer):
		btn_confirm_answer.disabled = false

func _update_selection_visual(clicked_kind: String, row_id: String, _col_id: String, hit: Dictionary) -> void:
	if not is_instance_valid(scanner_overlay) or not scanner_overlay.has_method("set_selection_rect"):
		return
	var rect := Rect2()
	match clicked_kind:
		"ROW":
			var row_item: TreeItem = row_item_by_id.get(row_id, null) as TreeItem
			rect = _build_row_rect(row_item)
		"COLUMN_HEADER":
			var col_idx := int(hit.get("col_idx", -1))
			rect = _build_column_rect(col_idx)
		_:
			rect = hit.get("rect", Rect2())
	if rect.size == Vector2.ZERO:
		scanner_overlay.call("clear_selection")
		return
	scanner_overlay.call("set_selection_rect", _tree_rect_to_overlay(rect))

func _build_row_rect(item: TreeItem) -> Rect2:
	if item == null:
		return Rect2()
	var union_rect := Rect2()
	var has_any := false
	for col_idx in range(data_tree.columns):
		var rect := data_tree.get_item_area_rect(item, col_idx)
		if rect.size == Vector2.ZERO:
			continue
		if not has_any:
			union_rect = rect
			has_any = true
		else:
			union_rect = union_rect.merge(rect)
	return union_rect if has_any else Rect2()

func _build_column_rect(col_idx: int) -> Rect2:
	if col_idx < 0:
		return Rect2()
	var union_rect := Rect2()
	var has_any := false
	for row_id_v in row_item_by_id.keys():
		var item: TreeItem = row_item_by_id[row_id_v] as TreeItem
		if item == null:
			continue
		var rect := data_tree.get_item_area_rect(item, col_idx)
		if rect.size == Vector2.ZERO:
			continue
		if not has_any:
			union_rect = rect
			has_any = true
		else:
			union_rect = union_rect.merge(rect)
	return union_rect if has_any else Rect2()
func _selection_overlay_center() -> Vector2:
	var center := _tree_local_to_overlay(_press_start_pos)
	if selected_target.is_empty():
		return center
	var rect := Rect2()
	match selected_clicked_kind:
		"ROW":
			rect = _build_row_rect(row_item_by_id.get(selected_row_id, null) as TreeItem)
		"COLUMN_HEADER":
			var col_idx := int(col_index_by_id.get(selected_col_id, -1))
			rect = _build_column_rect(col_idx)
		_:
			var item: TreeItem = row_item_by_id.get(selected_row_id, null) as TreeItem
			var col_idx := int(col_index_by_id.get(selected_col_id, -1))
			if item != null and col_idx >= 0:
				rect = data_tree.get_item_area_rect(item, col_idx)
	if rect.size == Vector2.ZERO:
		return center
	return _tree_local_to_overlay(rect.get_center())

func _clear_selection_visual() -> void:
	if is_instance_valid(scanner_overlay) and scanner_overlay.has_method("clear_selection"):
		scanner_overlay.call("clear_selection")

func _get_column_title(col_id: String) -> String:
	if col_id.is_empty():
		return ""
	if not col_index_by_id.has(col_id):
		return col_id
	var col_idx := int(col_index_by_id[col_id])
	return data_tree.get_column_title(col_idx)

func _register_first_action() -> void:
	if first_action_ts < 0:
		first_action_ts = Time.get_ticks_msec()

func _begin_trial_session() -> void:
	trial_seq += 1
	var case_id := str(current_case.get("id", "DA7-A-00"))
	task_session = {
		"trial_seq": trial_seq,
		"quest_id": "DATA_ARCHIVE",
		"stage_id": "A",
		"task_id": case_id,
		"started_at_ticks": case_started_ts,
		"ended_at_ticks": 0,
		"events": []
	}
	_log_event("trial_started", {
		"trial_seq": trial_seq,
		"case_id": case_id,
		"objective": str(current_case.get("objective", "")),
		"mode": "READ_ONLY"
	})

func _register_inspection(row_id: String) -> void:
	inspect_count += 1
	if time_to_first_inspect_ms < 0:
		time_to_first_inspect_ms = Time.get_ticks_msec() - case_started_ts
	if not row_id.is_empty() and row_id != HEADER_ROW_ID:
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
	return "INSPECT %s [%s]: %s" % [row_id, col_id, " | ".join(parts)]

func _compute_answered_without_inspection() -> bool:
	return inspect_count == 0 and inspect_via_button_count == 0 and inspect_via_long_press_count == 0

func _build_target_signature(kind: String, row_id: String, col_id: String) -> String:
	return "%s|%s|%s" % [kind, row_id, col_id]

func _recompute_miss_click_count() -> void:
	miss_click_count = invalid_tap_count + tap_on_non_answerable_area_count + tap_cancelled_by_scroll_count
	misclick_count = miss_click_count

func _log_trial(is_correct: bool, f_reason: Variant, target: Dictionary, clicked_kind: String, row_id: String, col_id: String) -> void:
	var now_ms := Time.get_ticks_msec()
	var elapsed_ms := now_ms - case_started_ts
	var first_action_ms := elapsed_ms
	if first_action_ts >= case_started_ts:
		first_action_ms = first_action_ts - case_started_ts
	var case_id := str(current_case.get("id", "DA7-A-00"))
	var interaction_type := str(current_case.get("interaction_type", "SINGLE_CHOICE"))
	var interaction_variant := str(current_case.get("interaction_variant", "CLICK_TARGET"))
	var schema_version := str(current_case.get("schema_version", "DA7.A.v4"))
	var timing_policy: Dictionary = current_case.get("timing_policy", {}) as Dictionary
	var variant_hash := str(hash("%s|%s|%s|%s" % [case_id, interaction_type, interaction_variant, schema_version]))
	var payload: Dictionary = TrialV2.build("DATA_ARCHIVE", "A", case_id, interaction_type, variant_hash)
	var error_type: String = "NONE" if is_correct else str(f_reason)
	var outcome_code: String = _outcome_code_for_a(is_correct, f_reason)
	var mastery_block_reason: String = _mastery_block_reason_for_a(is_correct, outcome_code)
	var valid_for_mastery: bool = mastery_block_reason == "NONE"
	var silent_reading_possible := (not table_has_scroll and not scroll_used and first_action_ms >= 30000)
	var effective_submit_ms := time_to_submit_ms
	if effective_submit_ms < 0:
		effective_submit_ms = elapsed_ms

	payload.merge({
		"question_id": case_id,
		"case_id": case_id,
		"quest": "data_archive",
		"stage_id": "A",
		"level": "A",
		"topic": str(current_case.get("topic", "DB_BASICS")),
		"interaction_variant": interaction_variant,
		"schema_version": schema_version,
		"f_reason": f_reason,
		"is_correct": is_correct,
		"is_fit": is_correct,
		"elapsed_ms": elapsed_ms,
		"duration": float(elapsed_ms) / 1000.0,
		"time_to_first_action_ms": first_action_ms,
		"time_to_first_inspect_ms": time_to_first_inspect_ms,
		"time_to_first_selection_ms": time_to_first_selection_ms,
		"time_to_submit_ms": effective_submit_ms,
		"check_attempt_count": check_attempt_count,
		"hint_used": hint_open_count > 0,
		"details_used": details_open_count > 0,
		"inspect_used": inspect_open_count > 0,
		"valid_for_diagnostics": true,
		"valid_for_mastery": valid_for_mastery,
		"error_type": error_type,
		"outcome_code": outcome_code,
		"mastery_block_reason": mastery_block_reason,
		"selected_kind": clicked_kind,
		"selected_row": row_id,
		"selected_col": col_id,
		"inspect_open_count": inspect_open_count,
		"inspect_cell_count": inspect_cell_count,
		"inspect_header_count": inspect_header_count,
		"scan_action_count": scan_action_count,
		"selection_change_count": selection_change_count,
		"row_click_count": row_click_count,
		"cell_click_count": cell_click_count,
		"header_click_count": header_click_count,
		"misclick_count": misclick_count,
		"changed_after_inspect": changed_after_inspect,
		"timing": {
			"effective_elapsed_ms": elapsed_ms,
			"time_to_first_action_ms": first_action_ms,
			"time_to_first_inspect_ms": time_to_first_inspect_ms,
			"time_to_first_selection_ms": time_to_first_selection_ms,
			"time_to_submit_ms": effective_submit_ms,
			"policy_mode": str(timing_policy.get("mode", "LEARNING")),
			"limit_sec": int(timing_policy.get("limit_sec", 120))
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
			"inspect_open_count": inspect_open_count,
			"inspect_cell_count": inspect_cell_count,
			"inspect_header_count": inspect_header_count,
			"scan_action_count": scan_action_count,
			"unique_rows_inspected": unique_rows_inspected.size(),
			"time_to_first_inspect_ms": time_to_first_inspect_ms,
			"time_to_first_selection_ms": time_to_first_selection_ms,
			"time_to_submit_ms": effective_submit_ms,
			"answered_without_inspection": answered_without_inspection,
			"clicked_target_kind": clicked_kind,
			"miss_click_count": miss_click_count,
			"misclick_count": misclick_count,
			"last_inspected_row_id": last_inspected_row_id,
			"selected_before_submit": selected_before_submit,
			"selection_change_count": selection_change_count,
			"selection_changes_count": selection_changes_count,
			"confirm_submit_used": confirm_submit_used,
			"submit_via_double_click": submit_via_double_click,
			"inspect_via_long_press_count": inspect_via_long_press_count,
			"inspect_via_button_count": inspect_via_button_count,
			"invalid_tap_count": invalid_tap_count,
			"invalid_header_tap_count": invalid_header_tap_count,
			"invalid_cell_tap_count": invalid_cell_tap_count,
			"invalid_row_tap_count": invalid_row_tap_count,
			"tap_on_non_answerable_area_count": tap_on_non_answerable_area_count,
			"tap_cancelled_by_scroll_count": tap_cancelled_by_scroll_count,
			"tutorial_shown": tutorial_shown,
			"tutorial_dismissed": tutorial_dismissed,
			"tutorial_completed": tutorial_completed,
			"mobile_layout_used": mobile_layout_used,
			"table_width_overflow": table_width_overflow,
			"selected_target_kind": clicked_kind,
			"selected_target_changed_before_submit": selected_target_changed_before_submit,
			"answered_after_inspection": answered_after_inspection,
			"inspected_same_target_before_submit": inspected_same_target_before_submit,
			"submit_latency_after_selection_ms": submit_latency_after_selection_ms,
			"changed_after_inspect": changed_after_inspect,
			"details_open_count": details_open_count,
			"hint_open_count": hint_open_count
		},
		"task_session": task_session.duplicate(true)
	}, true)
	payload["stability_delta"] = -10.0 if not is_correct else 0.0
	GlobalMetrics.register_trial(payload)

func _outcome_code_for_a(is_correct: bool, f_reason: Variant) -> String:
	if is_correct:
		return "SUCCESS"
	var reason := str(f_reason)
	match reason:
		"CONFUSED_ROW_COLUMN":
			return "CONFUSED_ROW_COLUMN"
		"COUNT_HEADER_AS_RECORD":
			return "COUNT_HEADER_AS_RECORD"
		"MISSED_ROW":
			return "MISSED_ROW"
		"MISSED_COLUMN":
			return "MISSED_COLUMN"
		"WRONG_FIELD_TYPE", "TYPE_MISMATCH":
			return "WRONG_FIELD_TYPE"
		_:
			if reason.find("ROW_COLUMN") >= 0:
				return "CONFUSED_ROW_COLUMN"
			if reason.find("HEADER") >= 0:
				return "COUNT_HEADER_AS_RECORD"
			if reason.find("ROW") >= 0:
				return "MISSED_ROW"
			if reason.find("COLUMN") >= 0:
				return "MISSED_COLUMN"
	return "OTHER_WRONG"

func _mastery_block_reason_for_a(is_correct: bool, outcome_code: String) -> String:
	if hint_open_count > 0:
		return "USED_HINT"
	if inspect_open_count >= 5:
		return "USED_INSPECT_TOO_HEAVILY"
	if selection_change_count >= 4 or selection_changes_count >= 2:
		return "MULTI_SELECTION_GUESSING"
	if not is_correct and outcome_code != "SUCCESS":
		return "WRONG_CONCEPT"
	return "NONE"

func _log_event(name: String, payload: Dictionary = {}) -> void:
	if task_session.is_empty():
		return
	var events: Array = task_session.get("events", [])
	events.append({
		"name": name,
		"t_ms": _trial_elapsed_ms(Time.get_ticks_msec()),
		"payload": payload
	})
	task_session["events"] = events

func _trial_elapsed_ms(now_ms: int) -> int:
	if case_started_ts <= 0:
		return 0
	return maxi(0, now_ms - case_started_ts)

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
	table_width_overflow = _tree_has_horizontal_scroll(data_tree)

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

func _tree_has_horizontal_scroll(tree: Tree) -> bool:
	if not is_instance_valid(tree):
		return false
	var stack: Array = [tree]
	while not stack.is_empty():
		var node: Node = stack.pop_back() as Node
		if node is HScrollBar:
			var bar: HScrollBar = node as HScrollBar
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
	_bump_transition_token()
	trial_locked = true
	trial_state = TrialState.CASE_RESOLVED
	_update_inspect_mode_label()
	_set_tree_locked(true)
	title_label.text = _tr("da7.a.ui.title_complete", "DATA ARCHIVE // SESSION COMPLETE [A]")
	prompt_label.bbcode_enabled = true
	prompt_label.text = "[b]%s[/b]" % _tr("da7.a.ui.session_complete", "Investigation complete.")
	explain_line.text = ""
	_ensure_exit_button()

func _game_over() -> void:
	_bump_transition_token()
	trial_locked = true
	trial_state = TrialState.CASE_RESOLVED
	_update_inspect_mode_label()
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
	_bump_transition_token()
	prompt_label.bbcode_enabled = false
	prompt_label.text = text
	trial_locked = true
	trial_state = TrialState.CASE_RESOLVED
	_update_inspect_mode_label()
	_set_tree_locked(true)

func _play_sound(sound_name: String, fallback: AudioStreamPlayer) -> void:
	var manager := get_node_or_null("/root/AudioManager")
	if manager != null and manager.has_method("play"):
		manager.call("play", sound_name)
		return
	if is_instance_valid(fallback):
		fallback.play()

func _on_back_pressed() -> void:
	_bump_transition_token()
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _on_stability_changed(_new_val: float, _delta: float) -> void:
	_update_stability_ui()

func _update_stability_ui() -> void:
	if is_instance_valid(stability_bar):
		stability_bar.value = GlobalMetrics.stability
	if is_instance_valid(stability_label):
		stability_label.text = _tr("da7.common.stability", "STABILITY: {value}%", {"value": int(GlobalMetrics.stability)})

func _install_body_scroll() -> void:
	if _body_scroll_installed:
		return
	if root_layout == null or body_container == null:
		return
	var existing_scroll: ScrollContainer = root_layout.get_node_or_null("BodyScroll") as ScrollContainer
	if existing_scroll != null and existing_scroll.get_node_or_null("Body") != null:
		_body_scroll_installed = true
		return
	var scroll := ScrollContainer.new()
	scroll.name = "BodyScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.follow_focus = true
	var idx: int = body_container.get_index()
	root_layout.add_child(scroll)
	root_layout.move_child(scroll, idx)
	body_container.reparent(scroll)
	_body_scroll_installed = true

func _apply_compact_layout(compact: bool, is_mobile: bool) -> void:
	if is_instance_valid(inspect_panel):
		inspect_panel.custom_minimum_size.y = 72.0 if compact else 108.0
	if is_instance_valid(btn_inspect):
		btn_inspect.custom_minimum_size = Vector2(96.0 if compact else 132.0, 44.0 if compact else 46.0)
	if is_instance_valid(btn_confirm_answer):
		btn_confirm_answer.custom_minimum_size.y = 44.0 if compact else 46.0
	if is_instance_valid(data_tree):
		if compact:
			data_tree.custom_minimum_size.y = 120.0
		elif is_mobile:
			data_tree.custom_minimum_size.y = 360.0
		else:
			data_tree.custom_minimum_size.y = 200.0
	if is_instance_valid(options_grid):
		options_grid.add_theme_constant_override("v_separation", 8 if compact else 10)
		options_grid.add_theme_constant_override("h_separation", 8 if compact else 10)

func _on_viewport_size_changed() -> void:
	var viewport_size := get_viewport_rect().size
	var is_mobile := viewport_size.x < BREAKPOINT_PX
	var compact: bool = (viewport_size.x >= viewport_size.y and viewport_size.y <= 420.0) or (viewport_size.y > viewport_size.x and viewport_size.x <= 520.0)
	current_layout_mode = LAYOUT_MOBILE if is_mobile else LAYOUT_DESKTOP
	mobile_layout_used = is_mobile
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
		data_tree.custom_minimum_size = Vector2(0, 360)
		data_tree.add_theme_constant_override("v_separation", 7)
		data_tree.add_theme_font_size_override("font_size", 14 if compact else 18)
	else:
		if table_section.get_parent() != desktop_layout:
			table_section.reparent(desktop_layout)
		if task_section.get_parent() != desktop_layout:
			task_section.reparent(desktop_layout)
		desktop_layout.move_child(table_section, 0)
		desktop_layout.move_child(task_section, 1)
		desktop_layout.visible = true
		mobile_layout.visible = false
		data_tree.custom_minimum_size = Vector2(0, 200)
		data_tree.add_theme_constant_override("v_separation", 4)
		data_tree.add_theme_font_size_override("font_size", 14 if compact else 16)
	_apply_compact_layout(compact, is_mobile)
	call_deferred("_update_silent_reading_possible_flag")

func _bump_transition_token() -> void:
	_transition_token += 1
