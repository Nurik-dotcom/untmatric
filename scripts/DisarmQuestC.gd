extends Control

const LEVELS_PATH := "res://data/quest_c_levels.json"

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

@onready var lbl_clue_title: Label = $SafeArea/MainLayout/HeaderRow/LblClueTitle
@onready var lbl_session: Label = $SafeArea/MainLayout/HeaderRow/LblSession
@onready var btn_back: Button = $SafeArea/MainLayout/HeaderRow/BtnBack
@onready var expected_panel: PanelContainer = $SafeArea/MainLayout/StatusMonitor/MonitorsRow/ExpectedPanel
@onready var actual_panel: PanelContainer = $SafeArea/MainLayout/StatusMonitor/MonitorsRow/ActualPanel
@onready var lbl_expected_value: Label = $SafeArea/MainLayout/StatusMonitor/MonitorsRow/ExpectedPanel/ExpectedVBox/LblExpectedValue
@onready var lbl_actual_value: Label = $SafeArea/MainLayout/StatusMonitor/MonitorsRow/ActualPanel/ActualVBox/LblActualValue
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
var task_session: Dictionary = {}
var cached_line_height := 26
var last_scroll_vertical := -1

func _ready() -> void:
	_configure_code_view()
	_connect_signals()
	_load_levels()
	if levels.is_empty():
		lbl_hint.text = "Данные уровня C не загружены."
		return

	var idx: int = int(GlobalMetrics.current_level_index)
	if idx < 0 or idx >= levels.size():
		idx = 0
	_start_level(idx)

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

	lbl_clue_title.text = "ДЕЛО C: РАЗМИНИРОВАНИЕ"
	lbl_session.text = "СЕССИЯ: %s" % str(current_task.get("id", "C-00"))
	lbl_expected_value.text = "s = %s" % str(current_task.get("expected_s", "?"))
	lbl_actual_value.text = "s = %s" % str(current_task.get("actual_s", "?"))
	lbl_hint.text = "Нажмите на строку с ошибкой, затем выберите исправление."
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
	lbl_hint.text = "Исправление применено. Нажмите ПРОВЕРИТЬ."
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
	lbl_actual_value.text = "s = %s" % str(current_task.get("expected_s", "?"))
	lbl_hint.text = "ДОСТУП РАЗРЕШЁН"
	btn_verify.disabled = true
	btn_next.visible = true
	_set_actual_panel_error(false)
	_register_result(true)

func _handle_fail(correct_line: int) -> void:
	state = State.FEEDBACK_FAIL
	_set_actual_panel_error(true)

	var selected_result: Variant = _get_selected_fix_result()
	if selected_line_index == correct_line and selected_result != null:
		lbl_actual_value.text = "s = %s" % str(selected_result)
		lbl_hint.text = "Неверное исправление: результат не совпадает."
	else:
		lbl_hint.text = "Выбрана неверная строка."

func _set_actual_panel_error(is_error: bool, pulse: bool = true) -> void:
	if is_error:
		actual_panel.modulate = Color(0.78, 0.78, 0.76, 1.0)
		if pulse:
			var tw := create_tween()
			tw.tween_property(actual_panel, "modulate", Color(0.9, 0.9, 0.88, 1.0), 0.12)
			tw.tween_property(actual_panel, "modulate", Color(0.78, 0.78, 0.76, 1.0), 0.14)
			tw.tween_property(actual_panel, "modulate", Color(0.9, 0.9, 0.88, 1.0), 0.14)
			tw.tween_property(actual_panel, "modulate", Color(0.78, 0.78, 0.76, 1.0), 0.16)
	else:
		actual_panel.modulate = Color(0.92, 0.92, 0.9, 1.0)

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
	analysis_lines.append("Ожидаемое: s=%s" % str(current_task.get("expected_s", "?")))
	analysis_lines.append("Фактическое: s=%s" % str(current_task.get("actual_s", "?")))
	if selected_line_index >= 0:
		analysis_lines.append("Выбранная строка: %d" % (selected_line_index + 1))
	if selected_option_id != "":
		var fix_result: Variant = _get_selected_fix_result()
		var fix_line := ""
		var fix: Dictionary = _get_fix_option(selected_option_id)
		if not fix.is_empty():
			fix_line = str(fix.get("replace_line", ""))
		analysis_lines.append("Ваш вариант: %s -> s=%s" % [selected_option_id, str(fix_result)])
		if fix_line != "":
			analysis_lines.append("Заменить на: %s" % fix_line)
	analysis_lines.append("")
	for line_var in current_task.get("explain_short", []):
		analysis_lines.append(str(line_var))
	diagnostics_panel.call("setup", "ДИАГНОСТИКА: %s" % str(current_task.get("id", "C-00")), analysis_lines)
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
	lbl_misclicks.text = "ПРОМАХИ: %d" % misclicks_before_correct
