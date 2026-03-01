extends Control

const LEVELS_PATH := "res://data/quest_c_levels.json"
const PHONE_LANDSCAPE_MAX_HEIGHT := 740.0
const PHONE_PORTRAIT_MAX_WIDTH := 520.0

enum State {
	INIT,
	LINE_SELECT,
	FIX_MENU,
	READY_TO_VERIFY,
	VERIFY,
	FEEDBACK_SUCCESS,
	FEEDBACK_FAIL,
	DIAGNOSTIC
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
@onready var lbl_misclicks: Label = $SafeArea/MainLayout/BodyRow/SideInfo/MisclickCounter
@onready var btn_analyze: Button = $SafeArea/MainLayout/ActionsRow/BtnAnalyze
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
var current_level_idx := 0
var current_task: Dictionary = {}
var state: State = State.INIT
var variant_hash := ""
var task_started_ticks := 0
var paused_total_ms := 0
var pause_started_ticks := -1
var hint_open_ticks := 0
var hint_total_ms := 0
var selected_line_index := -1
var selected_option_id := ""
var misclicks_before_correct := 0
var wrong_fix_attempts_before_correct := 0
var has_selected_correct_line := false
var level_result_sent := false
var suppress_caret_event := false
var line_pick_armed := false
var highlight_tween: Tween
var actual_panel_error_tween: Tween
var task_session: Dictionary = {}
var cached_line_height := 26
var last_scroll_vertical := -1
var _body_mobile_layout: VBoxContainer = null
var _monitor_mobile_layout: VBoxContainer = null

func _ready() -> void:
	_configure_code_view()
	_connect_signals()
	if not I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.connect(_on_language_changed)
	_apply_localized_texts()
	_apply_static_titles()
	_load_levels()
	if levels.is_empty():
		lbl_hint.text = _tr("disarm.c.status.levels_not_loaded", "Disarm C levels not loaded.")
		return

	var idx: int = int(GlobalMetrics.current_level_index)
	if idx < 0 or idx >= levels.size():
		idx = 0
	_start_level(idx)
	_on_viewport_size_changed()
	if not get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.connect(_on_viewport_size_changed)

func _on_language_changed(_code: String) -> void:
	_apply_localized_texts()
	_apply_static_titles()

func _apply_localized_texts() -> void:
	btn_back.text = _tr("disarm.c.btn.back", "BACK")
	btn_analyze.text = _tr("disarm.c.btn.analyze", "ANALYZE")
	btn_verify.text = _tr("disarm.c.btn.verify", "VERIFY")
	btn_next.text = _tr("disarm.c.btn.next", "NEXT")
	lbl_clue_title.text = _tr("disarm.c.labels.title", "DISARM C")

func _apply_static_titles() -> void:
	lbl_expected_title.text = _tr("disarm.c.labels.expected", "EXPECTED (X)")
	lbl_actual_title.text = _tr("disarm.c.labels.actual", "ACTUAL (Y)")
	if lbl_delta != null:
		lbl_delta.text = _tr("disarm.c.labels.delta_init", "Δ = --")

func _update_result_panels(expected_s: int, actual_s: int) -> void:
	lbl_expected_value.text = "s = %d" % expected_s
	lbl_actual_value.text = "s = %d" % actual_s
	if lbl_delta != null:
		lbl_delta.text = "Δ = %d (Y - X)" % (actual_s - expected_s)

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
		if _validate_level(level):
			levels.append(level)
		else:
			push_warning("Skipping invalid C level: " + str(level.get("id", "UNKNOWN")))

func _validate_level(level: Dictionary) -> bool:
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

	var explain_short_raw: Variant = level.get("explain_short", [])
	if typeof(explain_short_raw) != TYPE_ARRAY:
		return false
	var explain_short: Array = explain_short_raw
	for line_var in explain_short:
		if typeof(line_var) != TYPE_STRING:
			return false

	var correct_option_id := str(bug.get("correct_option_id", "")).strip_edges().to_upper()
	return required_ids.has(correct_option_id) and ids_seen.has("A") and ids_seen.has("B") and ids_seen.has("C")

func _is_numeric(value: Variant) -> bool:
	var value_type := typeof(value)
	return value_type == TYPE_INT or value_type == TYPE_FLOAT

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
	variant_hash = str(hash(build_variant_key(current_task)))
	task_started_ticks = Time.get_ticks_msec()
	paused_total_ms = 0
	pause_started_ticks = -1
	hint_open_ticks = 0
	hint_total_ms = 0
	selected_line_index = -1
	selected_option_id = ""
	misclicks_before_correct = 0
	wrong_fix_attempts_before_correct = 0
	has_selected_correct_line = false
	level_result_sent = false
	line_pick_armed = false
	last_scroll_vertical = -1
	state = State.LINE_SELECT

	task_session = {
		"task_id": str(current_task.get("id", "C-00")),
		"variant_hash": variant_hash,
		"started_at_ticks": task_started_ticks,
		"ended_at_ticks": 0,
		"attempts": [],
		"events": [],
		"hint_total_ms": 0,
		"paused_total_ms": 0
	}

	lbl_clue_title.text = _tr("disarm.c.labels.title_fix", "DISARM C: FIX")
	lbl_session.text = _tr("disarm.c.labels.session", "SESSION: {id}", {"id": str(current_task.get("id", "C-00"))})
	_update_result_panels(int(current_task.get("expected_s", 0)), int(current_task.get("actual_s", 0)))
	lbl_hint.text = _tr("disarm.c.status.main_hint", "Expected s in window (X). Got in buggy system (Y). Fix code so Y = X.")
	_update_misclick_label()

	btn_verify.disabled = true
	btn_next.visible = false
	diagnostics_blocker.visible = false
	diagnostics_panel.visible = false
	fix_menu.hide()
	_render_code()
	_set_actual_panel_error(true, false)
	_log_event("task_start", {"bucket": str(current_task.get("bucket", "unknown"))})

func _render_code(caret_line: int = 0) -> void:
	var base_lines: Array = current_task.get("code_lines", [])
	_set_code_lines(base_lines, caret_line)

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

func _apply_fix_preview() -> void:
	if selected_line_index < 0:
		return
	var base_lines: Array = current_task.get("code_lines", [])
	if selected_line_index >= base_lines.size():
		return
	var fix: Dictionary = _get_fix_option(selected_option_id)
	if fix.is_empty():
		return
	var preview_lines: Array = base_lines.duplicate()
	preview_lines[selected_line_index] = str(fix.get("replace_line", ""))
	_set_code_lines(preview_lines, selected_line_index)
	_update_line_highlight()

func _on_code_caret_changed() -> void:
	if suppress_caret_event:
		return
	if state == State.FEEDBACK_SUCCESS:
		return
	if not line_pick_armed:
		return
	line_pick_armed = false

	selected_line_index = code_view.get_caret_line()
	selected_option_id = ""
	btn_verify.disabled = true
	_render_code(selected_line_index)
	_log_event("line_clicked", {"line": selected_line_index})

	var correct_line := int(current_task.get("bug", {}).get("correct_line_index", -1))
	if selected_line_index == correct_line:
		has_selected_correct_line = true
	elif not has_selected_correct_line:
		misclicks_before_correct += 1
		_update_misclick_label()

	_update_line_highlight()
	_open_fix_menu()

func _on_code_gui_input(event: InputEvent) -> void:
	if state == State.FEEDBACK_SUCCESS:
		return
	if state == State.DIAGNOSTIC:
		return
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			line_pick_armed = true
	elif event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event
		if touch_event.pressed:
			line_pick_armed = true

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
	state = State.FIX_MENU
	_log_event("fix_menu_open", {"line": selected_line_index})
	fix_menu.popup_centered_ratio(0.68)

func _on_fix_option_selected(option_id: String) -> void:
	selected_option_id = option_id.strip_edges().to_upper()
	_apply_fix_preview()
	_log_event("fix_selected", {"option_id": selected_option_id, "line": selected_line_index})

func _on_fix_apply_requested(option_id: String) -> void:
	selected_option_id = option_id.strip_edges().to_upper()
	btn_verify.disabled = selected_line_index < 0 or selected_option_id == ""
	_apply_fix_preview()
	lbl_hint.text = _tr("disarm.c.status.fix_selected", "Fix selected. Press VERIFY.")
	state = State.READY_TO_VERIFY
	_log_event("fix_applied", {"option_id": selected_option_id, "line": selected_line_index})

func _on_fix_menu_canceled() -> void:
	if state != State.FEEDBACK_SUCCESS:
		selected_option_id = ""
		btn_verify.disabled = true
		if selected_line_index >= 0:
			_render_code(selected_line_index)
			_update_line_highlight()
		state = State.LINE_SELECT

func _on_verify_pressed() -> void:
	if btn_verify.disabled:
		return
	if selected_line_index < 0 or selected_option_id == "":
		return

	state = State.VERIFY
	_log_event("verify_pressed", {"line": selected_line_index, "option_id": selected_option_id})

	var bug: Dictionary = current_task.get("bug", {})
	var correct_line := int(bug.get("correct_line_index", -1))
	var correct_option := str(bug.get("correct_option_id", "")).strip_edges().to_upper()
	var is_correct := (selected_line_index == correct_line and selected_option_id == correct_option)
	var effective_time_ms := _effective_elapsed_ms(Time.get_ticks_msec())
	var paused_ms_snapshot := paused_total_ms
	var hint_ms_snapshot := hint_total_ms

	if selected_line_index == correct_line and selected_option_id != correct_option:
		wrong_fix_attempts_before_correct += 1

	var attempt := {
		"kind": "debugging",
		"level_id": str(current_task.get("id", "C-00")),
		"task_id": str(current_task.get("id", "C-00")),
		"variant_hash": variant_hash,
		"selected_line_index": selected_line_index,
		"fix_option_id": selected_option_id,
		"correct": is_correct,
		"effective_time_ms": effective_time_ms,
		"paused_total_ms": paused_ms_snapshot,
		"hint_total_ms": hint_ms_snapshot,
		"misclicks_before_correct": misclicks_before_correct,
		"wrong_fix_attempts_before_correct": wrong_fix_attempts_before_correct
	}
	(task_session["attempts"] as Array).append(attempt)

	if is_correct:
		_handle_success()
	else:
		_handle_fail(correct_line)

func _handle_success() -> void:
	state = State.FEEDBACK_SUCCESS
	_update_result_panels(
		int(current_task.get("expected_s", 0)),
		int(current_task.get("expected_s", 0))
	)
	lbl_hint.text = _tr("disarm.c.status.correct", "Fix confirmed: actual value matches expected.")
	btn_verify.disabled = true
	btn_next.visible = true
	_set_actual_panel_error(false)
	_register_result(true)

func _handle_fail(correct_line: int) -> void:
	state = State.FEEDBACK_FAIL
	_set_actual_panel_error(true)

	var selected_result: Variant = _get_selected_fix_result()
	if selected_line_index == correct_line and selected_result != null:
		_update_result_panels(
			int(current_task.get("expected_s", 0)),
			int(selected_result)
		)
		lbl_hint.text = _tr("disarm.c.status.wrong_patch", "Correct line, wrong patch. Try another option.")
	else:
		_update_result_panels(
			int(current_task.get("expected_s", 0)),
			int(current_task.get("actual_s", 0))
		)
		lbl_hint.text = _tr("disarm.c.status.wrong_line", "Bug not in that line. Find the line that changes s.")

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

func _get_selected_fix_result() -> Variant:
	var fix_options: Array = current_task.get("bug", {}).get("fix_options", [])
	var normalized_option_id := selected_option_id.strip_edges().to_upper()
	for fix_var in fix_options:
		if typeof(fix_var) != TYPE_DICTIONARY:
			continue
		var fix: Dictionary = fix_var
		if str(fix.get("option_id", "")).strip_edges().to_upper() == normalized_option_id:
			return fix.get("result_s", null)
	return null

func _on_analyze_pressed() -> void:
	if diagnostics_panel.visible:
		return
	var analysis_lines: Array = []
	var expected_s := int(current_task.get("expected_s", 0))
	var actual_s := int(current_task.get("actual_s", 0))
	analysis_lines.append(_tr("disarm.c.diag.expected_line", "EXPECTED (X): s={val}", {"val": expected_s}))
	analysis_lines.append(_tr("disarm.c.diag.actual_line", "ACTUAL (Y): s={val}", {"val": actual_s}))
	analysis_lines.append(_tr("disarm.c.diag.delta_line", "Δ = Y - X: {val}", {"val": actual_s - expected_s}))
	if selected_line_index >= 0:
		analysis_lines.append(_tr("disarm.c.diag.selected_line", "Selected line: {n}", {"n": selected_line_index + 1}))
	if selected_option_id != "":
		var fix_result: Variant = _get_selected_fix_result()
		var fix: Dictionary = _get_fix_option(selected_option_id)
		var fix_line := str(fix.get("replace_line", "")) if not fix.is_empty() else ""
		analysis_lines.append(_tr("disarm.c.diag.selected_fix", "Selected fix {option} → s={val}", {"option": selected_option_id, "val": str(fix_result)}))
		if fix_line != "":
			analysis_lines.append(_tr("disarm.c.diag.replacement_code", "Replacement: {code}", {"code": fix_line}))
	analysis_lines.append("")
	var task_id: String = str(current_task.get("id", "C-01"))
	var raw_explains: Array = current_task.get("explain_short", [])
	for line_idx in range(raw_explains.size()):
		var default_line: String = str(raw_explains[line_idx])
		analysis_lines.append(_tr("disarm.c.level.%s.explain.%d" % [task_id, line_idx], default_line))
	var diag_title: String = _tr("disarm.c.diag.title", "Disarm C analysis: {id}", {"id": task_id})
	diagnostics_panel.call("setup", diag_title, analysis_lines)
	diagnostics_panel.visible = true

func _on_diagnostics_visibility_changed() -> void:
	if diagnostics_panel.visible:
		diagnostics_blocker.visible = true
		if pause_started_ticks == -1 and hint_open_ticks == 0:
			hint_open_ticks = Time.get_ticks_msec()
		_log_event("analyze_open", {})
		state = State.DIAGNOSTIC
	else:
		diagnostics_blocker.visible = false
		if hint_open_ticks > 0:
			var delta := Time.get_ticks_msec() - hint_open_ticks
			hint_total_ms += delta
			task_session["hint_total_ms"] = hint_total_ms
			_log_event("analyze_close", {"duration_ms": delta})
			hint_open_ticks = 0
		if state != State.FEEDBACK_SUCCESS:
			state = State.LINE_SELECT

func _notification(what: int) -> void:
	if task_started_ticks <= 0:
		return

	if what == MainLoop.NOTIFICATION_APPLICATION_PAUSED:
		_on_app_paused()
	elif what == MainLoop.NOTIFICATION_APPLICATION_RESUMED:
		_on_app_resumed()

func _on_app_paused() -> void:
	# Debounce duplicate pause callbacks on some Android devices.
	if pause_started_ticks != -1:
		return

	var now_ticks := Time.get_ticks_msec()
	pause_started_ticks = now_ticks

	# If diagnostics is open, stop hint timer before pause window.
	if hint_open_ticks > 0:
		hint_total_ms += maxi(0, now_ticks - hint_open_ticks)
		task_session["hint_total_ms"] = hint_total_ms
		hint_open_ticks = 0

	_log_event("app_paused", {})

func _on_app_resumed() -> void:
	# Debounce duplicate resume callbacks.
	if pause_started_ticks == -1:
		return

	var now_ticks := Time.get_ticks_msec()
	var pause_delta := maxi(0, now_ticks - pause_started_ticks)
	paused_total_ms += pause_delta
	pause_started_ticks = -1
	task_session["paused_total_ms"] = paused_total_ms

	# If diagnostics is still visible, resume hint timer from now.
	if diagnostics_panel.visible:
		hint_open_ticks = now_ticks

	_log_event("app_resumed", {"paused_ms": pause_delta})

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
		"match_key": "DISARM_C|%s" % str(current_task.get("id", "C-00")),
		"is_correct": is_correct,
		"is_fit": is_correct,
		"elapsed_ms": elapsed_ms,
		"duration": float(elapsed_ms) / 1000.0,
		"task_id": str(current_task.get("id", "C-00")),
		"variant_hash": variant_hash,
		"task_session": task_session
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

	btn_back.custom_minimum_size = Vector2(96.0 if compact else 120.0, 52.0 if compact else 56.0)
	btn_analyze.custom_minimum_size.y = 52.0 if compact else 60.0
	btn_verify.custom_minimum_size.y = 52.0 if compact else 60.0
	btn_next.custom_minimum_size.y = 52.0 if compact else 60.0
	side_info.custom_minimum_size.x = 220.0 if compact else 300.0
	code_view.add_theme_font_size_override("font_size", 20 if compact else 24)
	lbl_hint.add_theme_font_size_override("font_size", 18 if compact else 22)
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
	main_layout.add_child(_body_mobile_layout)
	main_layout.move_child(_body_mobile_layout, main_layout.get_children().find(body_row) + 1)
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
