extends Control

const LEVELS_PATH := "res://data/quest_c_levels.json"
const PHONE_LANDSCAPE_MAX_HEIGHT := 740.0
const PHONE_PORTRAIT_MAX_WIDTH := 520.0
const SEMANTIC_EVALUATOR_SCRIPT := preload("res://scripts/disarm_c/DisarmCSemanticEvaluator.gd")

enum State {
	INIT,
	LINE_SELECT,
	LINE_FOCUSED,
	FIX_MENU,
	PATCH_STAGED,
	VERIFY,
	FEEDBACK_WRONG_LINE,
	FEEDBACK_WRONG_PATCH,
	FEEDBACK_SUCCESS,
	DIAGNOSTIC,
	SAFE_REVIEW
}

@onready var safe_area: MarginContainer = $SafeArea
@onready var main_layout: VBoxContainer = $SafeArea/MainLayout
@onready var header_row: HBoxContainer = $SafeArea/MainLayout/HeaderRow
@onready var monitors_row: HBoxContainer = $SafeArea/MainLayout/StatusMonitor/MonitorsRow
@onready var body_row: HBoxContainer = $SafeArea/MainLayout/BodyRow
@onready var code_frame: PanelContainer = $SafeArea/MainLayout/BodyRow/CodeFrame
@onready var side_info: VBoxContainer = $SafeArea/MainLayout/BodyRow/SideInfo
@onready var actions_row: HBoxContainer = $SafeArea/MainLayout/ActionsRow
@onready var lbl_clue_title: Label = $SafeArea/MainLayout/HeaderRow/LblClueTitle
@onready var lbl_session: Label = $SafeArea/MainLayout/HeaderRow/LblSession
@onready var btn_back: Button = $SafeArea/MainLayout/HeaderRow/BtnBack
@onready var expected_panel: PanelContainer = $SafeArea/MainLayout/StatusMonitor/MonitorsRow/ExpectedPanel
@onready var actual_panel: PanelContainer = $SafeArea/MainLayout/StatusMonitor/MonitorsRow/ActualPanel
@onready var lbl_expected_title: Label = $SafeArea/MainLayout/StatusMonitor/MonitorsRow/ExpectedPanel/ExpectedVBox/LblExpectedTitle
@onready var lbl_actual_title: Label = $SafeArea/MainLayout/StatusMonitor/MonitorsRow/ActualPanel/ActualVBox/LblActualTitle
@onready var lbl_expected_value: Label = $SafeArea/MainLayout/StatusMonitor/MonitorsRow/ExpectedPanel/ExpectedVBox/LblExpectedValue
@onready var lbl_actual_value: Label = $SafeArea/MainLayout/StatusMonitor/MonitorsRow/ActualPanel/ActualVBox/LblActualValue
@onready var lbl_delta: Label = $SafeArea/MainLayout/StatusMonitor/MonitorsRow/ActualPanel/ActualVBox/LblDelta
@onready var code_view: CodeEdit = $SafeArea/MainLayout/BodyRow/CodeFrame/CodeRoot/CodeView
@onready var line_highlight: ColorRect = $SafeArea/MainLayout/BodyRow/CodeFrame/CodeRoot/LineHighlight
@onready var lbl_hint: Label = $SafeArea/MainLayout/BodyRow/SideInfo/LblHint
@onready var lbl_inspector: Label = $SafeArea/MainLayout/BodyRow/SideInfo/LblInspector
@onready var lbl_misclicks: Label = $SafeArea/MainLayout/BodyRow/SideInfo/MisclickCounter
@onready var btn_analyze: Button = $SafeArea/MainLayout/ActionsRow/BtnAnalyze
@onready var btn_reset: Button = $SafeArea/MainLayout/ActionsRow/BtnReset
@onready var btn_verify: Button = $SafeArea/MainLayout/ActionsRow/BtnVerify
@onready var btn_next: Button = $SafeArea/MainLayout/ActionsRow/BtnNext
@onready var diagnostics_blocker: ColorRect = $DiagnosticsBlocker
@onready var fix_menu: PopupPanel = $FixMenuC
@onready var diagnostics_panel: PanelContainer = $DiagnosticsPanelC

func _tr(key: String, default_text: String, params: Dictionary = {}) -> String:
	var merged: Dictionary = params.duplicate(true)
	merged["default"] = default_text
	return I18n.tr_key(key, merged)

var levels: Array = []
var quarantined_level_ids: Array[String] = []
var semantic_reports_by_level_id: Dictionary = {}

var current_level_idx := 0
var current_task: Dictionary = {}
var current_semantic_report: Dictionary = {}
var state: State = State.INIT
var state_before_diagnostic: State = State.LINE_SELECT
var current_diagnostics_mode := "text_only"
var variant_hash := ""
var task_started_ticks := 0
var paused_total_ms := 0
var pause_started_ticks := -1
var hint_open_ticks := 0
var hint_total_ms := 0
var selected_line_index := -1
var selected_option_id := ""
var current_variant_preview: Dictionary = {}
var patch_previews_by_option_id: Dictionary = {}
var task_is_semantically_valid := true
var verify_fail_count := 0
var misclicks_before_correct := 0
var wrong_fix_attempts_before_correct := 0
var has_selected_correct_line := false
var level_result_sent := false
var suppress_caret_event := false
var highlight_tween: Tween
var actual_panel_error_tween: Tween
var task_session: Dictionary = {}
var trial_seq: int = 0

var law_select_count: int = 0
var patch_select_count: int = 0
var patch_apply_count: int = 0
var validation_count: int = 0
var counterexample_seen_count: int = 0

var changed_after_validation_fail: bool = false
var changed_after_overload: bool = false

var time_to_first_analyze_ms: int = -1
var time_to_first_patch_ms: int = -1
var time_to_first_validation_ms: int = -1
var time_from_patch_to_validation_ms: int = -1

var last_edit_ms: int = -1
var last_verdict_code: String = "INIT"
var _await_change_after_validation_fail: bool = false
var _await_change_after_overload: bool = false
var cached_line_height := 26
var last_scroll_vertical := -1
var _body_mobile_layout: VBoxContainer = null
var _monitor_mobile_layout: VBoxContainer = null
var _body_scroll_installed: bool = false
var _body_scroll: ScrollContainer = null
var _body_scroll_content: VBoxContainer = null

var semantic_evaluator = SEMANTIC_EVALUATOR_SCRIPT.new()

func _ready() -> void:
	_configure_code_view()
	_connect_signals()
	_install_body_scroll()
	if not I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.connect(_on_language_changed)
	_apply_localized_texts()
	_apply_static_titles()
	_load_levels()
	if levels.is_empty():
		lbl_hint.text = _tr("disarm.c.status.levels_not_loaded", "No semantically valid Disarm C levels loaded.")
		lbl_inspector.text = "Semantic validation quarantined all levels."
		return

	var idx: int = int(GlobalMetrics.current_level_index)
	if idx < 0 or idx >= levels.size():
		idx = 0
	_start_level(idx)
	_on_viewport_size_changed()
	if not get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.connect(_on_viewport_size_changed)

func _install_body_scroll() -> void:
	if _body_scroll_installed:
		return
	if main_layout == null or body_row == null:
		return
	var existing_scroll: ScrollContainer = main_layout.get_node_or_null("BodyScroll") as ScrollContainer
	if existing_scroll != null:
		var existing_content: VBoxContainer = existing_scroll.get_node_or_null("BodyScrollContent") as VBoxContainer
		if existing_content != null and existing_content.get_node_or_null("BodyRow") != null:
			_body_scroll = existing_scroll
			_body_scroll_content = existing_content
			_body_scroll_installed = true
			return
	_body_scroll = ScrollContainer.new()
	_body_scroll.name = "BodyScroll"
	_body_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_body_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_body_scroll.follow_focus = true
	_body_scroll_content = VBoxContainer.new()
	_body_scroll_content.name = "BodyScrollContent"
	_body_scroll_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body_scroll_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body_scroll_content.add_theme_constant_override("separation", 8)
	_body_scroll.add_child(_body_scroll_content)
	var idx: int = body_row.get_index()
	main_layout.add_child(_body_scroll)
	main_layout.move_child(_body_scroll, idx)
	body_row.reparent(_body_scroll_content)
	_body_scroll_installed = true

func _on_language_changed(_code: String) -> void:
	_apply_localized_texts()
	_apply_static_titles()
	_update_misclick_label()
	_update_inspector()

func _apply_localized_texts() -> void:
	btn_back.text = _tr("disarm.c.btn.back", "BACK")
	btn_analyze.text = _tr("disarm.c.btn.analyze", "ANALYZE")
	btn_reset.text = _tr("disarm.c.btn.reset", "RESET PICK")
	btn_verify.text = _tr("disarm.c.btn.verify", "VERIFY")
	btn_next.text = _tr("disarm.c.btn.next", "NEXT")
	lbl_clue_title.text = _tr("disarm.c.labels.title", "DISARM C")

func _apply_static_titles() -> void:
	lbl_expected_title.text = _tr("disarm.c.labels.expected", "EXPECTED (X)")
	lbl_actual_title.text = _tr("disarm.c.labels.actual", "ACTUAL (Y)")
	if lbl_delta != null:
		lbl_delta.text = _tr("disarm.c.labels.delta_init", "Δ = --")

func _update_result_panels(expected_s: Variant, actual_s: Variant) -> void:
	lbl_expected_value.text = "s = %s" % _format_number(expected_s)
	lbl_actual_value.text = "s = %s" % _format_number(actual_s)
	if lbl_delta != null:
		if _is_numeric(expected_s) and _is_numeric(actual_s):
			lbl_delta.text = "Δ = %s (Y - X)" % _format_number(float(actual_s) - float(expected_s))
		else:
			lbl_delta.text = "Δ = --"

func _format_number(value: Variant) -> String:
	if not _is_numeric(value):
		return str(value)
	var as_float: float = float(value)
	var rounded_int: int = int(round(as_float))
	if absf(as_float - float(rounded_int)) <= 0.00001:
		return str(rounded_int)
	return String.num(as_float, 4).rstrip("0").rstrip(".")

func _is_numeric(value: Variant) -> bool:
	var value_type: int = typeof(value)
	return value_type == TYPE_INT or value_type == TYPE_FLOAT

func _exit_tree() -> void:
	if I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.disconnect(_on_language_changed)
	if get_tree() != null and get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.disconnect(_on_viewport_size_changed)

func _configure_code_view() -> void:
	code_view.editable = false
	_try_set_control_property("wrap_mode", 0)
	_try_set_control_property("line_wrapping_mode", 0)
	_try_set_control_property("caret_draw_when_editable_disabled", true)
	_try_set_control_property("gutters_draw_line_numbers", true)
	_try_set_control_property("gutter_draw_line_numbers", true)
	_try_set_control_property("gutters_zero_pad_line_numbers", true)
	_try_set_control_property("gutter_zero_pad_line_numbers", true)

	line_highlight.visible = false
	line_highlight.color = Color(0.93, 0.93, 0.91, 0.14)
	if code_view.has_method("get_line_height"):
		cached_line_height = int(code_view.call("get_line_height"))

func _try_set_control_property(prop_name: String, value: Variant) -> void:
	for prop_var in code_view.get_property_list():
		if typeof(prop_var) != TYPE_DICTIONARY:
			continue
		var prop: Dictionary = prop_var
		if str(prop.get("name", "")) == prop_name:
			code_view.set(prop_name, value)
			return

func _connect_signals() -> void:
	code_view.caret_changed.connect(_on_code_caret_changed)
	code_view.gui_input.connect(_on_code_gui_input)
	btn_back.pressed.connect(_on_back_pressed)
	btn_analyze.pressed.connect(_on_analyze_pressed)
	btn_reset.pressed.connect(_on_reset_pressed)
	btn_verify.pressed.connect(_on_verify_pressed)
	btn_next.pressed.connect(_on_next_pressed)
	diagnostics_panel.visibility_changed.connect(_on_diagnostics_visibility_changed)
	var on_option_selected := Callable(self, "_on_fix_option_selected")
	var on_apply_requested := Callable(self, "_on_fix_apply_requested")
	var on_canceled := Callable(self, "_on_fix_menu_canceled")
	if not fix_menu.is_connected("option_selected", on_option_selected):
		fix_menu.connect("option_selected", on_option_selected)
	if not fix_menu.is_connected("apply_requested", on_apply_requested):
		fix_menu.connect("apply_requested", on_apply_requested)
	if not fix_menu.is_connected("canceled", on_canceled):
		fix_menu.connect("canceled", on_canceled)

func _load_levels() -> void:
	levels.clear()
	quarantined_level_ids.clear()
	semantic_reports_by_level_id.clear()
	if not FileAccess.file_exists(LEVELS_PATH):
		push_error("DisarmQuestC levels file missing: " + LEVELS_PATH)
		return

	var file: FileAccess = FileAccess.open(LEVELS_PATH, FileAccess.READ)
	if file == null:
		push_error("Unable to open " + LEVELS_PATH)
		return

	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("JSON parse error in quest_c_levels.json: " + json.get_error_message())
		return

	if typeof(json.data) != TYPE_ARRAY:
		push_error("quest_c_levels.json must be an array.")
		return

	for level_var in json.data:
		if typeof(level_var) != TYPE_DICTIONARY:
			continue
		var level: Dictionary = level_var
		var level_id: String = str(level.get("id", "UNKNOWN"))
		if not _validate_level_structure(level):
			_register_semantic_warning(level_id, {
				"status": "invalid_structure",
				"issues": [{"code": "invalid_structure"}]
			})
			continue
		var report: Dictionary = _semantic_validate_level(level)
		semantic_reports_by_level_id[level_id] = report
		if not bool(report.get("semantic_valid", false)):
			quarantined_level_ids.append(level_id)
			_register_semantic_warning(level_id, report)
			continue
		levels.append(level)

	if not quarantined_level_ids.is_empty():
		push_warning("Disarm C quarantined levels: %s" % ", ".join(quarantined_level_ids))

func _validate_level_structure(level: Dictionary) -> bool:
	var required := [
		"id",
		"bucket",
		"briefing",
		"expected_s",
		"actual_s",
		"code_lines",
		"bug"
	]
	for key in required:
		if not level.has(key):
			return false

	if str(level.get("id", "")).strip_edges().is_empty():
		return false
	if str(level.get("bucket", "")).strip_edges().is_empty():
		return false
	if str(level.get("briefing", "")).strip_edges().is_empty():
		return false
	if not _is_numeric(level.get("expected_s", null)):
		return false
	if not _is_numeric(level.get("actual_s", null)):
		return false

	if typeof(level.get("code_lines", [])) != TYPE_ARRAY:
		return false
	var code_lines: Array = level.get("code_lines", [])
	if code_lines.is_empty():
		return false
	for code_line_var in code_lines:
		if typeof(code_line_var) != TYPE_STRING:
			return false
		if str(code_line_var).is_empty():
			return false

	var bug: Dictionary = level.get("bug", {})
	if typeof(bug) != TYPE_DICTIONARY:
		return false
	var correct_line_index := int(bug.get("correct_line_index", -1))
	if correct_line_index < 0 or correct_line_index >= code_lines.size():
		return false

	var fix_options: Array = bug.get("fix_options", [])
	if fix_options.size() != 3:
		return false

	var required_ids: Dictionary = {"A": true, "B": true, "C": true}
	var ids_seen: Dictionary = {}
	for fix_var in fix_options:
		if typeof(fix_var) != TYPE_DICTIONARY:
			return false
		var fix: Dictionary = fix_var
		var option_id := str(fix.get("option_id", "")).strip_edges().to_upper()
		if not required_ids.has(option_id):
			return false
		if ids_seen.has(option_id):
			return false
		if not fix.has("replace_line") or str(fix.get("replace_line", "")) == "":
			return false
		if not _is_numeric(fix.get("result_s", null)):
			return false
		ids_seen[option_id] = true

	var correct_option_id := str(bug.get("correct_option_id", "")).strip_edges().to_upper()
	return required_ids.has(correct_option_id) and ids_seen.has("A") and ids_seen.has("B") and ids_seen.has("C")

func _semantic_validate_level(level: Dictionary) -> Dictionary:
	return semantic_evaluator.semantic_validate_level(level)

func _register_semantic_warning(level_id: String, report: Dictionary) -> void:
	push_warning("Disarm C semantic warning for %s: %s" % [level_id, str(report.get("status", "unknown"))])
	if GlobalMetrics != null and GlobalMetrics.has_method("register_trial"):
		GlobalMetrics.register_trial({
			"quest_id": "DISARM_QUEST",
			"stage_id": "C",
			"match_key": "DISARM_C|SEMANTIC_WARNING|%s" % level_id,
			"is_correct": true,
			"is_fit": true,
			"elapsed_ms": 0,
			"duration": 0.0,
			"task_id": level_id,
			"semantic_event": "semantic_level_warning",
			"semantic_report": report,
			"stability_delta": 0.0
		})

func build_variant_key(level: Dictionary) -> String:
	var bug: Dictionary = level.get("bug", {})
	var code_blob := "\n".join(level.get("code_lines", []))
	var fix_parts: Array[String] = []
	for fix_var in bug.get("fix_options", []):
		if typeof(fix_var) != TYPE_DICTIONARY:
			continue
		var fix: Dictionary = fix_var
		fix_parts.append("%s:%s:%s" % [
			str(fix.get("option_id", "")),
			str(fix.get("replace_line", "")),
			str(fix.get("result_s", ""))
		])
	fix_parts.sort()
	return "%s|exp:%s|act:%s|%s|line:%s|opts:%s" % [
		str(level.get("id", "")),
		str(level.get("expected_s", "")),
		str(level.get("actual_s", "")),
		code_blob,
		str(bug.get("correct_line_index", -1)),
		",".join(fix_parts)
	]

func _start_level(idx: int) -> void:
	if idx >= levels.size():
		idx = 0
	current_level_idx = idx
	current_task = (levels[idx] as Dictionary).duplicate(true)
	current_semantic_report = semantic_reports_by_level_id.get(str(current_task.get("id", "")), {})
	task_is_semantically_valid = bool(current_semantic_report.get("semantic_valid", false))
	variant_hash = str(hash(build_variant_key(current_task)))
	task_started_ticks = Time.get_ticks_msec()
	paused_total_ms = 0
	pause_started_ticks = -1
	hint_open_ticks = 0
	hint_total_ms = 0
	selected_line_index = -1
	selected_option_id = ""
	current_variant_preview.clear()
	patch_previews_by_option_id.clear()
	verify_fail_count = 0
	misclicks_before_correct = 0
	wrong_fix_attempts_before_correct = 0
	has_selected_correct_line = false
	level_result_sent = false
	last_scroll_vertical = -1
	state_before_diagnostic = State.LINE_SELECT
	current_diagnostics_mode = "text_only"
	trial_seq += 1
	law_select_count = 0
	patch_select_count = 0
	patch_apply_count = 0
	validation_count = 0
	counterexample_seen_count = 0
	changed_after_validation_fail = false
	changed_after_overload = false
	time_to_first_analyze_ms = -1
	time_to_first_patch_ms = -1
	time_to_first_validation_ms = -1
	time_from_patch_to_validation_ms = -1
	last_edit_ms = -1
	last_verdict_code = "INIT"
	_await_change_after_validation_fail = false
	_await_change_after_overload = false
	_set_state(State.LINE_SELECT)

	task_session = {
		"task_id": str(current_task.get("id", "C-00")),
		"variant_hash": variant_hash,
		"trial_seq": trial_seq,
		"started_at_ticks": task_started_ticks,
		"ended_at_ticks": 0,
		"attempts": [],
		"events": [],
		"hint_total_ms": 0,
		"paused_total_ms": 0
	}

	lbl_clue_title.text = _tr("disarm.c.labels.title_fix", "DISARM C: FIX")
	lbl_session.text = _tr("disarm.c.labels.session", "SESSION: {id}", {"id": str(current_task.get("id", "C-00"))})
	_update_result_panels(current_task.get("expected_s", 0), current_task.get("actual_s", 0))
	lbl_hint.text = _tr("disarm.c.status.main_hint", "Expected is X, current buggy value is Y. Focus a suspicious line, stage a patch, then verify.")
	_update_misclick_label()
	_update_inspector()

	btn_verify.disabled = true
	btn_next.visible = false
	diagnostics_blocker.visible = false
	diagnostics_panel.visible = false
	fix_menu.hide()
	_render_code()
	_set_actual_panel_error(true, false)
	_build_patch_previews_for_correct_line()
	_log_event("task_start", {"bucket": str(current_task.get("bucket", "unknown"))})
	_log_event("trial_started", {
		"case_id": str(current_task.get("id", "C-00")),
		"source_expr": "\n".join(current_task.get("code_lines", [])),
		"target_line": int(current_task.get("bug", {}).get("correct_line_index", -1)),
		"state": int(state)
	})

func _build_patch_previews_for_correct_line() -> void:
	patch_previews_by_option_id.clear()
	var fix_options: Array = current_task.get("bug", {}).get("fix_options", [])
	for fix_var in fix_options:
		if typeof(fix_var) != TYPE_DICTIONARY:
			continue
		var fix: Dictionary = fix_var
		var option_id: String = str(fix.get("option_id", "")).strip_edges().to_upper()
		if option_id.is_empty():
			continue
		patch_previews_by_option_id[option_id] = semantic_evaluator.evaluate_patch(current_task, option_id)

func _set_state(next_state: State) -> void:
	state = next_state
	_update_inspector()

func _render_code(caret_line: int = 0) -> void:
	var base_lines: Array = current_task.get("code_lines", [])
	_set_code_lines(base_lines, caret_line)
	_update_line_highlight()

func _set_code_lines(lines: Array, caret_line: int) -> void:
	suppress_caret_event = true
	code_view.text = "\n".join(lines)
	if lines.is_empty():
		code_view.set_caret_line(0)
	else:
		var safe_line: int = clampi(caret_line, 0, lines.size() - 1)
		code_view.set_caret_line(safe_line)
	code_view.set_caret_column(0)
	suppress_caret_event = false

func _get_fix_option(option_id: String) -> Dictionary:
	var normalized_option_id := option_id.strip_edges().to_upper()
	var fix_options: Array = current_task.get("bug", {}).get("fix_options", [])
	for fix_var in fix_options:
		if typeof(fix_var) != TYPE_DICTIONARY:
			continue
		var fix: Dictionary = fix_var
		if str(fix.get("option_id", "")).strip_edges().to_upper() == normalized_option_id:
			return fix
	return {}

func _get_selected_patch_line() -> String:
	var fix: Dictionary = _get_fix_option(selected_option_id)
	if fix.is_empty():
		return ""
	return str(fix.get("replace_line", ""))

func _evaluate_current_selection_preview() -> Dictionary:
	if selected_line_index < 0 or selected_option_id.is_empty():
		return {}
	var fix: Dictionary = _get_fix_option(selected_option_id)
	if fix.is_empty():
		return {}
	return semantic_evaluator.evaluate_selected_line_replace(
		current_task,
		selected_line_index,
		str(fix.get("replace_line", "")),
		selected_option_id
	)

func _apply_fix_preview() -> void:
	if selected_line_index < 0:
		return
	if current_variant_preview.is_empty():
		current_variant_preview = _evaluate_current_selection_preview()
	if bool(current_variant_preview.get("ok", false)):
		var preview_lines: Array = current_variant_preview.get("rendered_code", [])
		_set_code_lines(preview_lines, selected_line_index)
		_update_line_highlight()
		return
	_render_code(selected_line_index)

func _reset_selection(keep_line: bool = false) -> void:
	if not keep_line:
		selected_line_index = -1
	selected_option_id = ""
	current_variant_preview.clear()
	btn_verify.disabled = true
	if selected_line_index >= 0:
		_render_code(selected_line_index)
		_update_line_highlight()
		_set_state(State.LINE_FOCUSED)
	else:
		_render_code(0)
		line_highlight.visible = false
		_set_state(State.LINE_SELECT)
	_update_inspector()

func _on_code_caret_changed() -> void:
	if suppress_caret_event:
		return
	if state == State.FEEDBACK_SUCCESS or state == State.DIAGNOSTIC:
		return
	var caret_line := code_view.get_caret_line()
	_focus_line(caret_line, false)

func _on_code_gui_input(event: InputEvent) -> void:
	if state == State.FEEDBACK_SUCCESS or state == State.DIAGNOSTIC:
		return
	var local_y := -1.0
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			local_y = mouse_event.position.y
	elif event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event
		if touch_event.pressed:
			local_y = touch_event.position.y
	if local_y < 0.0:
		return

	var line_idx := _line_from_local_y(local_y)
	_focus_line(line_idx, true)

func _line_from_local_y(local_y: float) -> int:
	var line_count := _get_code_line_count()
	if line_count <= 0:
		return 0
	var local_offset: float = maxf(0.0, local_y - 8.0)
	var line_local: int = int(floor(local_offset / maxf(1.0, float(cached_line_height))))
	var with_scroll: int = line_local + _get_scroll_vertical()
	return clampi(with_scroll, 0, line_count - 1)

func _get_code_line_count() -> int:
	if code_view.has_method("get_line_count"):
		return int(code_view.call("get_line_count"))
	return max(1, code_view.text.split("\n").size())

func _focus_line(line_idx: int, open_menu: bool) -> void:
	var safe_line := clampi(line_idx, 0, max(0, _get_code_line_count() - 1))
	var had_line := selected_line_index >= 0
	var line_changed := (safe_line != selected_line_index)
	selected_line_index = safe_line
	if line_changed:
		law_select_count += 1
		_mark_edit_action()
		_log_event("line_focused", {"line": selected_line_index})
		_log_event("law_selected", {"law_family": "line_focus", "line": selected_line_index})
		if had_line:
			selected_option_id = ""
			current_variant_preview.clear()
			btn_verify.disabled = true
		var correct_line := int(current_task.get("bug", {}).get("correct_line_index", -1))
		if selected_line_index == correct_line:
			has_selected_correct_line = true
		elif not has_selected_correct_line:
			misclicks_before_correct += 1
			_update_misclick_label()

	_render_code(selected_line_index)
	_update_line_highlight()
	_set_state(State.LINE_FOCUSED)
	if open_menu:
		_open_fix_menu()

func _update_line_highlight(restart_animation: bool = true) -> void:
	if selected_line_index < 0:
		line_highlight.visible = false
		return

	var visible_line_index := selected_line_index - _get_scroll_vertical()
	line_highlight.position = Vector2(6, 6 + (visible_line_index * cached_line_height))
	line_highlight.size = Vector2(code_view.size.x - 12, float(cached_line_height))
	line_highlight.visible = true

	if restart_animation:
		if highlight_tween != null:
			highlight_tween.kill()
		highlight_tween = create_tween().set_loops()
		highlight_tween.tween_property(line_highlight, "modulate:a", 0.26, 0.28)
		highlight_tween.tween_property(line_highlight, "modulate:a", 0.12, 0.28)

func _get_scroll_vertical() -> int:
	if code_view.has_method("get_v_scroll"):
		return int(code_view.call("get_v_scroll"))
	if code_view.has_method("get_scroll_vertical"):
		return int(code_view.call("get_scroll_vertical"))
	for prop_var in code_view.get_property_list():
		if typeof(prop_var) != TYPE_DICTIONARY:
			continue
		var prop: Dictionary = prop_var
		var prop_name := str(prop.get("name", ""))
		if prop_name == "scroll_vertical" or prop_name == "v_scroll":
			return int(code_view.get(prop_name))
	return 0

func _process(_delta: float) -> void:
	if not line_highlight.visible:
		return
	var scroll_vertical := _get_scroll_vertical()
	if scroll_vertical != last_scroll_vertical:
		last_scroll_vertical = scroll_vertical
		_update_line_highlight(false)

func _open_fix_menu() -> void:
	if selected_line_index < 0:
		return

	var lines: Array = current_task.get("code_lines", [])
	var original_line := ""
	if selected_line_index >= 0 and selected_line_index < lines.size():
		original_line = str(lines[selected_line_index])

	fix_menu.call(
		"setup",
		selected_line_index + 1,
		original_line,
		current_task.get("bug", {}).get("fix_options", []),
		selected_option_id
	)
	_set_state(State.FIX_MENU)
	_log_event("fix_menu_open", {"line": selected_line_index})
	fix_menu.popup_centered_ratio(0.68)

func _on_fix_option_selected(option_id: String) -> void:
	var normalized_option := option_id.strip_edges().to_upper()
	if normalized_option.is_empty():
		return
	patch_select_count += 1
	_mark_edit_action()
	if not selected_option_id.is_empty() and selected_option_id != normalized_option and state != State.VERIFY:
		_log_event("patch_changed_before_verify", {
			"line": selected_line_index,
			"from": selected_option_id,
			"to": normalized_option
		})
	selected_option_id = normalized_option
	current_variant_preview = _evaluate_current_selection_preview()
	_apply_fix_preview()
	_log_event("patch_selected", {"option_idx": selected_option_id, "line": selected_line_index})
	_log_event("fix_selected", {"option_id": selected_option_id, "line": selected_line_index})
	_update_inspector()

func _on_fix_apply_requested(option_id: String) -> void:
	patch_apply_count += 1
	if time_to_first_patch_ms < 0:
		time_to_first_patch_ms = _elapsed_ms_now()
	selected_option_id = option_id.strip_edges().to_upper()
	current_variant_preview = _evaluate_current_selection_preview()
	_mark_edit_action()
	btn_verify.disabled = selected_line_index < 0 or selected_option_id == ""
	_apply_fix_preview()
	lbl_hint.text = _tr("disarm.c.status.fix_selected", "Patch staged. Press VERIFY to test this hypothesis.")
	_set_state(State.PATCH_STAGED)
	_log_event("patch_applied", {"applied_option_idx": selected_option_id, "line": selected_line_index, "count": patch_apply_count})
	_log_event("patch_staged", {"option_id": selected_option_id, "line": selected_line_index})
	_update_inspector()

func _on_fix_menu_canceled() -> void:
	if state == State.FEEDBACK_SUCCESS:
		return
	if selected_line_index >= 0 and selected_option_id.is_empty():
		_render_code(selected_line_index)
		_update_line_highlight()
		_set_state(State.LINE_FOCUSED)
	elif selected_line_index >= 0:
		_set_state(State.PATCH_STAGED)
	else:
		_set_state(State.LINE_SELECT)

func _on_verify_pressed() -> void:
	if btn_verify.disabled:
		return
	if selected_line_index < 0 or selected_option_id == "":
		return

	validation_count += 1
	if time_to_first_validation_ms < 0:
		time_to_first_validation_ms = _elapsed_ms_now()
	if last_edit_ms >= 0:
		time_from_patch_to_validation_ms = maxi(0, _elapsed_ms_now() - last_edit_ms)
	_set_state(State.VERIFY)
	current_variant_preview = _evaluate_current_selection_preview()
	_log_event("validation_started", {"applied_option_idx": selected_option_id, "line": selected_line_index})
	_log_event("verify_pressed", {"line": selected_line_index, "option_id": selected_option_id})

	var bug: Dictionary = current_task.get("bug", {})
	var correct_line := int(bug.get("correct_line_index", -1))
	var correct_option := str(bug.get("correct_option_id", "")).strip_edges().to_upper()
	var semantic_match: bool = _semantic_preview_matches_expected(current_variant_preview)
	var line_correct: bool = selected_line_index == correct_line
	var is_correct: bool = line_correct and semantic_match
	var declared_match: bool = line_correct and selected_option_id == correct_option
	if is_correct != declared_match:
		push_warning(
			"Disarm C semantic mismatch id=%s selected_line=%d selected_option=%s declared_correct=%s semantic_match=%s" %
			[
				str(current_task.get("id", "C-00")),
				selected_line_index,
				selected_option_id,
				correct_option,
				str(semantic_match)
			]
		)

	var effective_time_ms := _effective_elapsed_ms(Time.get_ticks_msec())
	var paused_ms_snapshot := paused_total_ms
	var hint_ms_snapshot := hint_total_ms
	if line_correct and not semantic_match:
		wrong_fix_attempts_before_correct += 1

	var attempt := {
		"kind": "debugging",
		"level_id": str(current_task.get("id", "C-00")),
		"task_id": str(current_task.get("id", "C-00")),
		"variant_hash": variant_hash,
		"selected_line_index": selected_line_index,
		"fix_option_id": selected_option_id,
		"correct": is_correct,
		"semantic_match": semantic_match,
		"effective_time_ms": effective_time_ms,
		"paused_total_ms": paused_ms_snapshot,
		"hint_total_ms": hint_ms_snapshot,
		"misclicks_before_correct": misclicks_before_correct,
		"wrong_fix_attempts_before_correct": wrong_fix_attempts_before_correct
	}
	(task_session["attempts"] as Array).append(attempt)

	if is_correct:
		last_verdict_code = "SUCCESS"
		_log_event("validation_result", {
			"validation_passed": true,
			"validation_failed": false,
			"validation_overloaded": false
		})
		_handle_success(current_variant_preview)
		return

	verify_fail_count += 1
	var overloaded_now: bool = verify_fail_count >= 3
	last_verdict_code = "OVERLOAD" if overloaded_now else ("VALIDATION_FAIL_PATCH" if line_correct else "VALIDATION_FAIL_LINE")
	counterexample_seen_count += 1
	_await_change_after_validation_fail = true
	if overloaded_now:
		_await_change_after_overload = true
	_log_event("counterexample_shown", {
		"state": int(state),
		"selected_line_index": selected_line_index,
		"selected_option_id": selected_option_id,
		"fail_count": verify_fail_count
	})
	_log_event("validation_result", {
		"validation_passed": false,
		"validation_failed": true,
		"validation_overloaded": overloaded_now
	})
	if line_correct:
		_handle_wrong_patch(current_variant_preview)
	else:
		_handle_wrong_line()
	_maybe_enter_safe_review()

func _semantic_preview_matches_expected(preview: Dictionary) -> bool:
	if not bool(preview.get("ok", false)):
		return false
	if not _is_numeric(preview.get("result_s", null)):
		return false
	var expected_s: float = float(current_task.get("expected_s", 0.0))
	var result_s: float = float(preview.get("result_s", 0.0))
	return absf(result_s - expected_s) <= 0.00001

func _handle_success(preview: Dictionary) -> void:
	_set_state(State.FEEDBACK_SUCCESS)
	_update_result_panels(current_task.get("expected_s", 0), preview.get("result_s", current_task.get("expected_s", 0)))
	lbl_hint.text = _tr("disarm.c.status.correct", "Patch verified: expected and actual now match.")
	btn_verify.disabled = true
	btn_next.visible = true
	_set_actual_panel_error(false)
	_register_result(true)
	_update_inspector()

func _handle_wrong_line() -> void:
	_set_state(State.FEEDBACK_WRONG_LINE)
	_set_actual_panel_error(true)
	_update_result_panels(current_task.get("expected_s", 0), current_task.get("actual_s", 0))
	lbl_hint.text = _tr("disarm.c.status.wrong_line", "This line does not resolve the mismatch. Pick a line that directly affects s.")
	_log_event("verify_wrong_line", {
		"line": selected_line_index,
		"option_id": selected_option_id,
		"fail_count": verify_fail_count
	})
	_update_inspector()

func _handle_wrong_patch(preview: Dictionary) -> void:
	_set_state(State.FEEDBACK_WRONG_PATCH)
	_set_actual_panel_error(true)
	_update_result_panels(current_task.get("expected_s", 0), preview.get("result_s", current_task.get("actual_s", 0)))
	lbl_hint.text = _tr("disarm.c.status.wrong_patch", "Correct line, wrong patch. Keep the line and try another patch.")
	_log_event("verify_wrong_patch", {
		"line": selected_line_index,
		"option_id": selected_option_id,
		"result_s": preview.get("result_s", null),
		"fail_count": verify_fail_count
	})
	_update_inspector()

func _maybe_enter_safe_review() -> void:
	if verify_fail_count < 3:
		return
	_open_safe_review()

func _open_safe_review() -> void:
	var correct_option_id: String = str(current_task.get("bug", {}).get("correct_option_id", "")).strip_edges().to_upper()
	var correct_preview: Dictionary = patch_previews_by_option_id.get(correct_option_id, {})
	var explain_lines: Array = _collect_explain_lines()
	var payload: Dictionary = {
		"mode": "safe_review",
		"title": _tr("disarm.c.diag.title", "Disarm C diagnostics: {id}", {"id": str(current_task.get("id", "C-00"))}),
		"task_id": str(current_task.get("id", "C-00")),
		"expected_s": current_task.get("expected_s", 0),
		"actual_s": current_task.get("actual_s", 0),
		"selected_line_index": selected_line_index,
		"selected_patch_id": selected_option_id,
		"selected_patch_line": _get_selected_patch_line(),
		"reasoning_lines": explain_lines,
		"why_not_lines": [
			"Safe review is open after repeated verify failures.",
			"Compare your staged patch with the behavior of the semantic winner."
		],
		"action_hint": "Re-open patch menu on the same line and test the corrected hypothesis."
	}
	if bool(correct_preview.get("ok", false)):
		payload["selected_result_s"] = correct_preview.get("result_s", null)
		payload["trace"] = correct_preview.get("trace", [])
	_open_diagnostics(payload, "safe_review_opened", true)
	_set_state(State.SAFE_REVIEW)

func _set_actual_panel_error(is_error: bool, pulse: bool = true) -> void:
	if actual_panel_error_tween != null and actual_panel_error_tween.is_valid():
		actual_panel_error_tween.kill()
		actual_panel_error_tween = null

	if is_error:
		actual_panel.modulate = Color(0.78, 0.78, 0.76, 1.0)
		lbl_actual_title.modulate = Color(0.88, 0.88, 0.86, 1.0)
		actual_panel_error_tween = create_tween().set_loops()
		actual_panel_error_tween.tween_property(actual_panel, "modulate", Color(0.90, 0.90, 0.88, 1.0), 0.10)
		actual_panel_error_tween.tween_property(actual_panel, "modulate", Color(0.76, 0.76, 0.74, 1.0), 0.12)
		actual_panel_error_tween.tween_property(lbl_actual_title, "modulate", Color(0.78, 0.78, 0.76, 0.82), 0.08)
		actual_panel_error_tween.tween_property(lbl_actual_title, "modulate", Color(0.92, 0.92, 0.90, 1.0), 0.10)
		if pulse:
			var tw := create_tween()
			tw.tween_property(actual_panel, "scale", Vector2(1.008, 0.996), 0.06)
			tw.tween_property(actual_panel, "scale", Vector2(0.996, 1.006), 0.06)
			tw.tween_property(actual_panel, "scale", Vector2.ONE, 0.08)
	else:
		actual_panel.modulate = Color(0.92, 0.92, 0.9, 1.0)
		actual_panel.scale = Vector2.ONE
		lbl_actual_title.modulate = Color(0.92, 0.92, 0.90, 1.0)

func _on_analyze_pressed() -> void:
	if diagnostics_panel.visible:
		return
	if time_to_first_analyze_ms < 0:
		time_to_first_analyze_ms = _elapsed_ms_now()
	_log_event("analyze_pressed", {
		"selected_law_family": "line_focus",
		"selected_option_idx": selected_option_id
	})
	var payload := _build_diagnostics_payload()
	var is_preverify: bool = str(payload.get("mode", "")) == "preverify"
	_open_diagnostics(payload, "diagnostics_opened_preverify" if is_preverify else "diagnostics_opened_postverify", false)

func _build_diagnostics_payload() -> Dictionary:
	var expected_s: Variant = current_task.get("expected_s", 0)
	var actual_buggy: Variant = current_task.get("actual_s", 0)
	var selected_patch_line: String = _get_selected_patch_line()
	var explain_lines: Array = _collect_explain_lines()
	var mode := "preverify"
	var action_hint := "Focus a suspicious line, stage a patch, then verify."
	var actual_for_panel: Variant = actual_buggy
	var selected_result: Variant = null
	var trace: Array = []
	var why_not: Array = []

	match state:
		State.FEEDBACK_WRONG_LINE:
			mode = "wrong_line"
			action_hint = "Switch to another line that influences accumulator s."
			why_not = [
				"Changing this line did not repair the mismatch.",
				"Trace impact stayed aligned with buggy behavior."
			]
		State.FEEDBACK_WRONG_PATCH:
			mode = "wrong_patch"
			action_hint = "Keep the same line and test another patch."
			selected_result = current_variant_preview.get("result_s", null)
			if selected_result != null:
				actual_for_panel = selected_result
			trace = current_variant_preview.get("trace", [])
			why_not = [
				"The line focus is correct, but this patch still misses expected X.",
				"Review branch or operation semantics before re-verifying."
			]
		State.FEEDBACK_SUCCESS:
			mode = "success"
			action_hint = "Patch confirmed. Proceed to the next case."
			selected_result = current_variant_preview.get("result_s", null)
			if selected_result != null:
				actual_for_panel = selected_result
			trace = current_variant_preview.get("trace", [])
		State.SAFE_REVIEW:
			mode = "safe_review"
			action_hint = "Use safe review to compare your hypothesis against the semantic winner."
			if not current_variant_preview.is_empty():
				selected_result = current_variant_preview.get("result_s", null)
				if selected_result != null:
					actual_for_panel = selected_result
				trace = current_variant_preview.get("trace", [])
		_:
			mode = "preverify"
			action_hint = "No numeric patch spoiler is shown before verify."
			if not selected_option_id.is_empty():
				why_not = [
					"Patch is staged, but result is hidden until verify.",
					"Use reasoning and control-flow clues before confirming."
				]

	var payload := {
		"mode": mode,
		"title": _tr("disarm.c.diag.title", "Disarm C diagnostics: {id}", {"id": str(current_task.get("id", "C-00"))}),
		"task_id": str(current_task.get("id", "C-00")),
		"expected_s": expected_s,
		"actual_s": actual_for_panel,
		"selected_line_index": selected_line_index,
		"selected_patch_id": selected_option_id,
		"selected_patch_line": selected_patch_line,
		"reasoning_lines": explain_lines,
		"why_not_lines": why_not,
		"action_hint": action_hint
	}
	if selected_result != null and mode != "preverify":
		payload["selected_result_s"] = selected_result
	if not trace.is_empty() and mode != "preverify":
		payload["trace"] = trace
	return payload

func _collect_explain_lines() -> Array:
	var task_id: String = str(current_task.get("id", "C-01"))
	var raw_explains: Array = current_task.get("explain_short", [])
	var out: Array = []
	for line_idx in range(raw_explains.size()):
		var default_line: String = str(raw_explains[line_idx])
		# Content lines are sourced from JSON at runtime. I18n keys should not override them.
		out.append(default_line)
		# Keep legacy keys warm for projects still depending on i18n references.
		var _unused := _tr("disarm.c.level.%s.explain.%d" % [task_id, line_idx], default_line)
	return out

func _open_diagnostics(payload: Dictionary, event_name: String, is_safe_review: bool) -> void:
	if diagnostics_panel.has_method("setup"):
		diagnostics_panel.call("setup", payload)
	state_before_diagnostic = state
	current_diagnostics_mode = str(payload.get("mode", "text_only"))
	diagnostics_panel.visible = true
	_set_state(State.DIAGNOSTIC)
	_log_event(event_name, {
		"mode": current_diagnostics_mode,
		"safe_review": is_safe_review
	})

func _on_diagnostics_visibility_changed() -> void:
	if diagnostics_panel.visible:
		diagnostics_blocker.visible = true
		if pause_started_ticks == -1 and hint_open_ticks == 0:
			hint_open_ticks = Time.get_ticks_msec()
		_log_event("analyze_open", {"mode": current_diagnostics_mode})
	else:
		diagnostics_blocker.visible = false
		if hint_open_ticks > 0:
			var delta := Time.get_ticks_msec() - hint_open_ticks
			hint_total_ms += delta
			task_session["hint_total_ms"] = hint_total_ms
			_log_event("analyze_close", {"duration_ms": delta, "mode": current_diagnostics_mode})
			hint_open_ticks = 0
		if state == State.DIAGNOSTIC:
			_set_state(state_before_diagnostic)

func _notification(what: int) -> void:
	if task_started_ticks <= 0:
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
	if hint_open_ticks > 0:
		hint_total_ms += maxi(0, now_ticks - hint_open_ticks)
		task_session["hint_total_ms"] = hint_total_ms
		hint_open_ticks = 0
	_log_event("app_paused", {})

func _on_app_resumed() -> void:
	if pause_started_ticks == -1:
		return
	var now_ticks := Time.get_ticks_msec()
	var pause_delta := maxi(0, now_ticks - pause_started_ticks)
	paused_total_ms += pause_delta
	pause_started_ticks = -1
	task_session["paused_total_ms"] = paused_total_ms
	if diagnostics_panel.visible:
		hint_open_ticks = now_ticks
	_log_event("app_resumed", {"paused_ms": pause_delta})

func _on_reset_pressed() -> void:
	if state == State.FEEDBACK_SUCCESS:
		return
	_mark_edit_action()
	_reset_selection(false)
	lbl_hint.text = _tr("disarm.c.status.reset", "Selection cleared. Focus a line, stage a patch, then verify.")
	_log_event("selection_reset", {})

func _on_next_pressed() -> void:
	_log_event("task_end", {"status": "next_pressed"})
	_start_level(current_level_idx + 1)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _register_result(is_correct: bool) -> void:
	if level_result_sent:
		return
	level_result_sent = true
	var end_ticks := Time.get_ticks_msec()
	task_session["ended_at_ticks"] = end_ticks
	task_session["hint_total_ms"] = hint_total_ms
	task_session["paused_total_ms"] = paused_total_ms
	task_session["is_correct"] = is_correct
	_log_event("task_end", {"status": "complete", "is_correct": is_correct})

	var elapsed_ms := _effective_elapsed_ms(end_ticks)
	var payload := {
		"quest_id": "DISARM_QUEST",
		"stage_id": "C",
		"match_key": "DISARM_C|%s" % str(current_task.get("id", "C-00")),
		"is_correct": is_correct,
		"is_fit": is_correct,
		"elapsed_ms": elapsed_ms,
		"duration": float(elapsed_ms) / 1000.0,
		"task_id": str(current_task.get("id", "C-00")),
		"variant_hash": variant_hash,
		"selected_law_family": "line_focus",
		"applied_option_idx": selected_option_id,
		"validation_passed": last_verdict_code == "SUCCESS",
		"validation_failed": last_verdict_code == "VALIDATION_FAIL_LINE" or last_verdict_code == "VALIDATION_FAIL_PATCH",
		"validation_overloaded": last_verdict_code == "OVERLOAD",
		"safe_mode_used": state == State.SAFE_REVIEW or verify_fail_count >= 3,
		"trial_seq": trial_seq,
		"law_select_count": law_select_count,
		"patch_select_count": patch_select_count,
		"patch_apply_count": patch_apply_count,
		"validation_count": validation_count,
		"counterexample_seen_count": counterexample_seen_count,
		"changed_after_validation_fail": changed_after_validation_fail,
		"changed_after_overload": changed_after_overload,
		"time_to_first_analyze_ms": time_to_first_analyze_ms,
		"time_to_first_patch_ms": time_to_first_patch_ms,
		"time_to_first_validation_ms": time_to_first_validation_ms,
		"time_from_patch_to_validation_ms": time_from_patch_to_validation_ms,
		"outcome_code": last_verdict_code,
		"mastery_block_reason": _build_mastery_block_reason_for_c(last_verdict_code),
		"task_session": task_session,
		"stability_delta": -20.0 if not is_correct else 0.0
	}
	GlobalMetrics.register_trial(payload)

func _effective_elapsed_ms(now_ticks: int) -> int:
	var paused_ms := paused_total_ms
	if pause_started_ticks != -1:
		paused_ms += maxi(0, now_ticks - pause_started_ticks)
	var hint_ms := hint_total_ms
	if hint_open_ticks > 0:
		hint_ms += maxi(0, now_ticks - hint_open_ticks)
	return maxi(0, (now_ticks - task_started_ticks) - paused_ms - hint_ms)

func _elapsed_ms_now() -> int:
	return _effective_elapsed_ms(Time.get_ticks_msec())

func _mark_edit_action() -> void:
	last_edit_ms = _elapsed_ms_now()
	if _await_change_after_validation_fail:
		changed_after_validation_fail = true
		_await_change_after_validation_fail = false
	if _await_change_after_overload:
		changed_after_overload = true
		_await_change_after_overload = false

func _build_mastery_block_reason_for_c(verdict_code: String) -> String:
	if verdict_code == "SUCCESS":
		if changed_after_overload:
			return "solved_after_overload_recovery"
		if changed_after_validation_fail:
			return "solved_after_validation_fail"
		return "solved_without_recovery"
	if verdict_code == "OVERLOAD":
		return "validation_overload"
	if verdict_code == "VALIDATION_FAIL_LINE":
		return "wrong_line"
	if verdict_code == "VALIDATION_FAIL_PATCH":
		return "wrong_patch"
	return "incomplete"

func _log_event(name: String, payload: Dictionary) -> void:
	var events: Array = task_session.get("events", [])
	events.append({
		"name": name,
		"t_ms": _effective_elapsed_ms(Time.get_ticks_msec()),
		"payload": payload
	})
	task_session["events"] = events

func _update_misclick_label() -> void:
	lbl_misclicks.text = _tr("disarm.c.labels.misclicks", "MISCLICKS: {n}", {"n": misclicks_before_correct})

func _update_inspector() -> void:
	var lines: Array[String] = []
	if selected_line_index < 0:
		lines.append("Selected line: -")
	else:
		lines.append("Selected line: %d" % (selected_line_index + 1))
	if selected_option_id.is_empty():
		lines.append("Selected patch: -")
	else:
		lines.append("Selected patch: %s" % selected_option_id)

	var debug_status := ""
	match state:
		State.LINE_SELECT:
			debug_status = "Debug status: choose a suspicious line."
		State.LINE_FOCUSED:
			debug_status = "Debug status: line focused, open patch menu."
		State.FIX_MENU:
			debug_status = "Debug status: patch options open."
		State.PATCH_STAGED:
			debug_status = "Debug status: patch staged, verify to test."
		State.FEEDBACK_WRONG_LINE:
			debug_status = "Debug status: wrong line. Shift focus."
		State.FEEDBACK_WRONG_PATCH:
			debug_status = "Debug status: wrong patch on correct line."
		State.FEEDBACK_SUCCESS:
			debug_status = "Debug status: fixed."
		State.SAFE_REVIEW:
			debug_status = "Debug status: safe review active."
		_:
			debug_status = "Debug status: working."
	lines.append(debug_status)

	if selected_line_index >= 0:
		var correct_line := int(current_task.get("bug", {}).get("correct_line_index", -1))
		if selected_line_index == correct_line:
			lines.append("Why suspicious: this line controls the final mismatch path.")
		else:
			lines.append("Why suspicious: verify whether this line changes s or only flow noise.")
	else:
		lines.append("Why suspicious: inspect boundaries, operators, and branch conditions.")

	if state == State.PATCH_STAGED:
		lines.append("Verify guidance: result remains hidden until VERIFY.")
	elif state == State.FEEDBACK_WRONG_PATCH:
		lines.append("Verify guidance: keep this line and try another patch.")
	elif state == State.FEEDBACK_WRONG_LINE:
		lines.append("Verify guidance: choose another line first.")
	elif state == State.FEEDBACK_SUCCESS:
		lines.append("Verify guidance: proceed to NEXT.")
	else:
		lines.append("Verify guidance: stage one patch hypothesis before VERIFY.")

	lbl_inspector.text = "\n".join(lines)

func _on_viewport_size_changed() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var is_landscape: bool = viewport_size.x >= viewport_size.y
	var phone_landscape: bool = is_landscape and viewport_size.y <= PHONE_LANDSCAPE_MAX_HEIGHT
	var phone_portrait: bool = (not is_landscape) and viewport_size.x <= PHONE_PORTRAIT_MAX_WIDTH
	var compact: bool = phone_landscape or phone_portrait

	_apply_safe_area_padding(compact)
	main_layout.add_theme_constant_override("separation", 8 if compact else 10)
	header_row.add_theme_constant_override("separation", 8 if compact else 10)
	monitors_row.add_theme_constant_override("separation", 8 if compact else 12)
	body_row.add_theme_constant_override("separation", 8 if compact else 10)
	actions_row.add_theme_constant_override("separation", 8 if compact else 12)

	_set_monitor_mobile_mode(compact)
	_set_body_mobile_mode(compact)
	if not compact:
		var body_box: BoxContainer = body_row
		body_box.vertical = not is_landscape

	btn_back.custom_minimum_size = Vector2(96.0 if compact else 120.0, 52.0 if compact else 56.0)
	btn_analyze.custom_minimum_size.y = 52.0 if compact else 60.0
	btn_reset.custom_minimum_size.y = 52.0 if compact else 60.0
	btn_verify.custom_minimum_size.y = 52.0 if compact else 60.0
	btn_next.custom_minimum_size.y = 52.0 if compact else 60.0
	side_info.custom_minimum_size.x = 220.0 if compact else 300.0
	code_view.add_theme_font_size_override("font_size", 20 if compact else 24)
	lbl_hint.add_theme_font_size_override("font_size", 17 if compact else 22)
	lbl_inspector.add_theme_font_size_override("font_size", 15 if compact else 18)
	lbl_misclicks.add_theme_font_size_override("font_size", 16 if compact else 20)

	fix_menu.size = Vector2i(
		int(clampf(viewport_size.x - (24.0 if compact else 120.0), 320.0, 860.0)),
		int(clampf(viewport_size.y - (24.0 if compact else 120.0), 240.0, 460.0))
	)

func _set_monitor_mobile_mode(use_mobile: bool) -> void:
	var mobile_layout: VBoxContainer = _ensure_monitor_mobile_layout()
	if use_mobile:
		if monitors_row.visible:
			if expected_panel.get_parent() != mobile_layout:
				expected_panel.reparent(mobile_layout)
			if actual_panel.get_parent() != mobile_layout:
				actual_panel.reparent(mobile_layout)
		monitors_row.visible = false
		mobile_layout.visible = true
	else:
		if not monitors_row.visible:
			if expected_panel.get_parent() != monitors_row:
				expected_panel.reparent(monitors_row)
			if actual_panel.get_parent() != monitors_row:
				actual_panel.reparent(monitors_row)
		mobile_layout.visible = false
		monitors_row.visible = true

func _ensure_monitor_mobile_layout() -> VBoxContainer:
	if _monitor_mobile_layout != null and is_instance_valid(_monitor_mobile_layout):
		return _monitor_mobile_layout
	_monitor_mobile_layout = VBoxContainer.new()
	_monitor_mobile_layout.name = "MonitorMobileLayout"
	_monitor_mobile_layout.visible = false
	_monitor_mobile_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_monitor_mobile_layout.add_theme_constant_override("separation", 8)
	var status_monitor: Node = monitors_row.get_parent()
	status_monitor.add_child(_monitor_mobile_layout)
	status_monitor.move_child(_monitor_mobile_layout, status_monitor.get_children().find(monitors_row) + 1)
	return _monitor_mobile_layout

func _set_body_mobile_mode(use_mobile: bool) -> void:
	var mobile_layout: VBoxContainer = _ensure_body_mobile_layout()
	if use_mobile:
		if body_row.visible:
			if code_frame.get_parent() != mobile_layout:
				code_frame.reparent(mobile_layout)
			if side_info.get_parent() != mobile_layout:
				side_info.reparent(mobile_layout)
		body_row.visible = false
		mobile_layout.visible = true
	else:
		if not body_row.visible:
			if code_frame.get_parent() != body_row:
				code_frame.reparent(body_row)
			if side_info.get_parent() != body_row:
				side_info.reparent(body_row)
		mobile_layout.visible = false
		body_row.visible = true

func _ensure_body_mobile_layout() -> VBoxContainer:
	if _body_mobile_layout != null and is_instance_valid(_body_mobile_layout):
		return _body_mobile_layout
	_body_mobile_layout = VBoxContainer.new()
	_body_mobile_layout.name = "BodyMobileLayout"
	_body_mobile_layout.visible = false
	_body_mobile_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body_mobile_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body_mobile_layout.add_theme_constant_override("separation", 8)
	var parent_container: Node = _body_scroll_content if _body_scroll_content != null else main_layout
	parent_container.add_child(_body_mobile_layout)
	parent_container.move_child(_body_mobile_layout, parent_container.get_children().find(body_row) + 1)
	return _body_mobile_layout

func _apply_safe_area_padding(compact: bool) -> void:
	var left: float = 8.0 if compact else 16.0
	var top: float = 8.0 if compact else 12.0
	var right: float = 8.0 if compact else 16.0
	var bottom: float = 8.0 if compact else 12.0

	var safe_rect: Rect2i = DisplayServer.get_display_safe_area()
	if safe_rect.size.x > 0 and safe_rect.size.y > 0:
		var viewport_size: Vector2 = get_viewport_rect().size
		left = maxf(left, float(safe_rect.position.x))
		top = maxf(top, float(safe_rect.position.y))
		right = maxf(right, viewport_size.x - float(safe_rect.position.x + safe_rect.size.x))
		bottom = maxf(bottom, viewport_size.y - float(safe_rect.position.y + safe_rect.size.y))

	safe_area.add_theme_constant_override("margin_left", int(round(left)))
	safe_area.add_theme_constant_override("margin_top", int(round(top)))
	safe_area.add_theme_constant_override("margin_right", int(round(right)))
	safe_area.add_theme_constant_override("margin_bottom", int(round(bottom)))
