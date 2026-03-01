extends Control

const THEME_NOIR: Theme = preload("res://ui/theme_noir_pencil.tres")

const AUDIO_CLICK: AudioStream = preload("res://audio/click.wav")
const AUDIO_ERROR: AudioStream = preload("res://audio/error.wav")
const AUDIO_RELAY: AudioStream = preload("res://audio/relay.wav")

const LEVELS_PATH := "res://data/suspect_a_levels.json"
const MAX_ATTEMPTS := 3
const FX_ID_LOW := 0
const FX_ID_HIGH := 1
const OVERLAY_ID_PENCIL := 0
const OVERLAY_ID_CRT := 1
const PHONE_PORTRAIT_MAX_WIDTH := 560.0
const PHONE_LANDSCAPE_MAX_HEIGHT := 760.0

const STATUS_COLOR_NEUTRAL := Color(0.72, 0.72, 0.70)
const STATUS_COLOR_READY := Color(0.93, 0.93, 0.91)
const STATUS_COLOR_FAIL := Color(0.82, 0.82, 0.80)
const STATUS_COLOR_WARN := Color(0.78, 0.78, 0.76)
const STATUS_COLOR_SUCCESS := Color(0.97, 0.97, 0.95)

func _tr(key: String, default_text: String, params: Dictionary = {}) -> String:
	var merged: Dictionary = params.duplicate(true)
	merged["default"] = default_text
	return I18n.tr_key(key, merged)

enum State {
	INIT,
	BRIEFING,
	SOLVING,
	FEEDBACK_SUCCESS,
	FEEDBACK_FAIL,
	SAFE_MODE,
	DIAGNOSTIC
}

@export_enum("low", "high") var fx_quality: String = "high"
@export_enum("pencil", "crt") var overlay_mode: String = "pencil"
@export var typewriter_delay_sec: float = 0.03

@onready var safe_area: MarginContainer = $SafeArea
@onready var main_layout: VBoxContainer = $SafeArea/MainLayout
@onready var header_row: HBoxContainer = $SafeArea/MainLayout/Header
@onready var terminal_frame: PanelContainer = $SafeArea/MainLayout/TerminalFrame
@onready var actions_row: HBoxContainer = $SafeArea/MainLayout/Actions
@onready var noir_overlay: CanvasLayer = $NoirOverlay

@onready var briefing_goal: Label = $SafeArea/MainLayout/BriefingCard/BriefingMargin/BriefingVBox/LblGoal
@onready var briefing_hint: Label = $SafeArea/MainLayout/BriefingCard/BriefingMargin/BriefingVBox/LblHint

@onready var code_label: RichTextLabel = $SafeArea/MainLayout/TerminalFrame/ScrollContainer/CodeLabel
@onready var code_scroll: ScrollContainer = $SafeArea/MainLayout/TerminalFrame/ScrollContainer
@onready var input_display: Label = $SafeArea/MainLayout/InputFrame/InputDisplay
@onready var lbl_status: Label = $SafeArea/MainLayout/StatusRow/LblStatus
@onready var lbl_attempts: Label = $SafeArea/MainLayout/StatusRow/LblAttempts
@onready var decrypt_bar: ProgressBar = $SafeArea/MainLayout/BarsRow/DecryptBar
@onready var energy_bar: ProgressBar = $SafeArea/MainLayout/BarsRow/EnergyBar

@onready var diag_panel: PanelContainer = $DiagnosticsPanel
@onready var diag_trace: RichTextLabel = $DiagnosticsPanel/VBoxContainer/TraceList
@onready var diag_explain: RichTextLabel = $DiagnosticsPanel/VBoxContainer/ExplainList

@onready var btn_enter: Button = $SafeArea/MainLayout/Actions/BtnEnter
@onready var btn_analyze: Button = $SafeArea/MainLayout/Actions/BtnAnalyze
@onready var btn_next: Button = $SafeArea/MainLayout/Actions/BtnNext
@onready var btn_close_diag: Button = $DiagnosticsPanel/VBoxContainer/BtnCloseDiag
@onready var btn_quest_back: Button = $SafeArea/MainLayout/Header/BtnQuestBack
@onready var btn_settings: Button = $SafeArea/MainLayout/Header/BtnSettings
@onready var lbl_clue_title: Label = $SafeArea/MainLayout/Header/LblClueTitle
@onready var lbl_session: Label = $SafeArea/MainLayout/Header/LblSessionId
@onready var numpad: GridContainer = $SafeArea/MainLayout/Numpad

@onready var inspector_popup: PopupPanel = $InspectorPopup
@onready var popup_fx_select: OptionButton = $InspectorPopup/Root/SettingsGrid/FxSelect
@onready var popup_overlay_select: OptionButton = $InspectorPopup/Root/SettingsGrid/OverlaySelect
@onready var popup_close: Button = $InspectorPopup/Root/BtnClose

var levels: Array = []
var current_level_idx := 0
var current_task: Dictionary = {}
var user_input := ""
var state: State = State.INIT
var energy := 100.0
var wrong_count := 0
var task_started_at := 0
var task_finished := false
var task_result_sent := false
var is_safe_mode := false
var is_code_ready := false
var variant_hash := ""
var task_session: Dictionary = {}

var sfx_player: AudioStreamPlayer

func _ready() -> void:
	_apply_theme()
	_configure_overlay_shader()
	_init_audio_player()
	_connect_signals()
	if not I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.connect(_on_language_changed)
	_apply_i18n()
	_apply_mobile_min_sizes()
	_apply_layout_mode()

	if not _load_levels_from_json():
		_show_boot_error(_tr("suspect.a.status.boot_error", "Failed to load suspect quest levels."))
		return

	if levels.size() != 18:
		push_warning("Suspect levels expected 18, got %d" % levels.size())

	GlobalMetrics.current_level_index = 0
	_load_level(0)

func _exit_tree() -> void:
	if I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.disconnect(_on_language_changed)

func _on_language_changed(_code: String) -> void:
	_apply_i18n()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_apply_layout_mode()

func _apply_theme() -> void:
	theme = THEME_NOIR

func _setup_runtime_controls() -> void:
	popup_fx_select.select(FX_ID_HIGH if fx_quality == "high" else FX_ID_LOW)
	popup_overlay_select.select(OVERLAY_ID_PENCIL if overlay_mode == "pencil" else OVERLAY_ID_CRT)

func _apply_i18n() -> void:
	btn_quest_back.text = _tr("suspect.a.btn.back", "BACK")
	btn_settings.text = _tr("suspect.a.btn.settings", "SETT")
	btn_analyze.text = _tr("suspect.a.btn.analyze", "ANALYZE")
	btn_enter.text = _tr("suspect.a.btn.enter", "ENTER")
	btn_next.text = _tr("suspect.a.btn.next", "NEXT")
	btn_close_diag.text = _tr("suspect.a.btn.close", "CLOSE")
	popup_close.text = _tr("suspect.a.btn.close", "CLOSE")

	var popup_title: Label = inspector_popup.get_node_or_null("Root/LblTitle") as Label
	if popup_title != null:
		popup_title.text = _tr("suspect.a.ui.settings_title", "SETTINGS")
	var popup_fx_title: Label = inspector_popup.get_node_or_null("Root/SettingsGrid/LblFx") as Label
	if popup_fx_title != null:
		popup_fx_title.text = _tr("suspect.a.ui.effects", "EFFECTS")
	var popup_overlay_title: Label = inspector_popup.get_node_or_null("Root/SettingsGrid/LblOverlay") as Label
	if popup_overlay_title != null:
		popup_overlay_title.text = _tr("suspect.a.ui.overlay", "OVERLAY")

	var diag_title: Label = diag_panel.get_node_or_null("VBoxContainer/Label") as Label
	if diag_title != null:
		diag_title.text = _tr("suspect.a.ui.diagnostics", "DIAGNOSTICS")

	popup_fx_select.clear()
	popup_fx_select.add_item(_tr("suspect.a.settings.fx_low", "Low"), FX_ID_LOW)
	popup_fx_select.add_item(_tr("suspect.a.settings.fx_high", "High"), FX_ID_HIGH)
	popup_fx_select.select(FX_ID_HIGH if fx_quality == "high" else FX_ID_LOW)

	popup_overlay_select.clear()
	popup_overlay_select.add_item(_tr("suspect.a.settings.overlay_pencil", "Pencil"), OVERLAY_ID_PENCIL)
	popup_overlay_select.add_item("CRT", OVERLAY_ID_CRT)
	popup_overlay_select.select(OVERLAY_ID_PENCIL if overlay_mode == "pencil" else OVERLAY_ID_CRT)

func _configure_overlay_shader() -> void:
	if noir_overlay != null and noir_overlay.has_method("set_overlay_mode"):
		noir_overlay.call("set_overlay_mode", "PENCIL" if overlay_mode == "pencil" else "CRT")

	var overlay_rect: ColorRect = noir_overlay.get_node_or_null("CRT_Overlay") as ColorRect
	if overlay_rect == null:
		return
	var shader_mat: ShaderMaterial = overlay_rect.material as ShaderMaterial
	if shader_mat == null:
		return

	var high_fx: bool = fx_quality == "high"
	if overlay_mode == "pencil":
		_set_overlay_param(shader_mat, "intensity", 0.35)
		_set_overlay_param(shader_mat, "fx_quality", 1 if high_fx else 0)
		_set_overlay_param(shader_mat, "grain_strength", 0.36 if high_fx else 0.24)
		_set_overlay_param(shader_mat, "hatch_strength", 0.30 if high_fx else 0.14)
		_set_overlay_param(shader_mat, "vignette_strength", 0.44)
		_set_overlay_param(shader_mat, "jitter_strength", 0.0)
		_set_overlay_param(shader_mat, "pulse", 0.0)
		_set_overlay_param(shader_mat, "glitch_strength", 0.0)
	else:
		_set_overlay_param(shader_mat, "tint_color", Color(0.93, 0.93, 0.93, 1.0))
		_set_overlay_param(shader_mat, "intensity", 0.18)
		_set_overlay_param(shader_mat, "fx_quality", 1 if high_fx else 0)
		_set_overlay_param(shader_mat, "jitter_strength", 0.0)
		_set_overlay_param(shader_mat, "pulse", 0.0)
		_set_overlay_param(shader_mat, "glitch_strength", 0.0)

func _set_overlay_param(shader_mat: ShaderMaterial, param_name: String, value: Variant) -> void:
	if shader_mat == null:
		return
	var shader: Shader = shader_mat.shader
	if shader == null:
		return
	for uniform_var in shader.get_shader_uniform_list():
		if typeof(uniform_var) != TYPE_DICTIONARY:
			continue
		var uniform: Dictionary = uniform_var
		if str(uniform.get("name", "")) == param_name:
			shader_mat.set_shader_parameter(param_name, value)
			return

func _init_audio_player() -> void:
	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SfxPlayer"
	add_child(sfx_player)

func _connect_signals() -> void:
	for btn_var in numpad.get_children():
		if btn_var is Button:
			(btn_var as Button).pressed.connect(_on_numpad_pressed.bind(btn_var))

	btn_enter.pressed.connect(_on_enter_pressed)
	btn_analyze.pressed.connect(_on_analyze_pressed)
	btn_next.pressed.connect(_on_next_pressed)
	btn_close_diag.pressed.connect(_on_close_diag_pressed)
	btn_quest_back.pressed.connect(_on_back_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	popup_close.pressed.connect(_on_settings_close_pressed)
	popup_fx_select.item_selected.connect(_on_popup_fx_selected)
	popup_overlay_select.item_selected.connect(_on_popup_overlay_selected)

func _on_settings_pressed() -> void:
	inspector_popup.popup_centered_ratio(0.38)

func _on_settings_close_pressed() -> void:
	inspector_popup.hide()

func _on_popup_fx_selected(index: int) -> void:
	var item_id: int = popup_fx_select.get_item_id(index)
	fx_quality = "high" if item_id == FX_ID_HIGH else "low"
	_configure_overlay_shader()

func _on_popup_overlay_selected(index: int) -> void:
	var item_id: int = popup_overlay_select.get_item_id(index)
	overlay_mode = "pencil" if item_id == OVERLAY_ID_PENCIL else "crt"
	_configure_overlay_shader()

func _apply_mobile_min_sizes() -> void:
	for btn_var in numpad.get_children():
		if btn_var is Button:
			(btn_var as Button).custom_minimum_size = Vector2(64, 64)
	btn_enter.custom_minimum_size = Vector2(0, 56)
	btn_analyze.custom_minimum_size = Vector2(0, 56)
	btn_next.custom_minimum_size = Vector2(0, 56)
	popup_fx_select.custom_minimum_size = Vector2(220, 48)
	popup_overlay_select.custom_minimum_size = Vector2(220, 48)

func _apply_layout_mode() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var portrait: bool = viewport_size.x < viewport_size.y
	var compact: bool = (portrait and viewport_size.x <= PHONE_PORTRAIT_MAX_WIDTH) or ((not portrait) and viewport_size.y <= PHONE_LANDSCAPE_MAX_HEIGHT)

	safe_area.add_theme_constant_override("margin_left", 10 if compact else 16)
	safe_area.add_theme_constant_override("margin_top", 8 if compact else 12)
	safe_area.add_theme_constant_override("margin_right", 10 if compact else 16)
	safe_area.add_theme_constant_override("margin_bottom", 8 if compact else 12)

	main_layout.add_theme_constant_override("separation", 6 if compact else 8)
	header_row.add_theme_constant_override("separation", 6 if compact else 8)
	terminal_frame.size_flags_stretch_ratio = 2.0 if compact else 2.2
	terminal_frame.custom_minimum_size = Vector2(0, 180 if compact else 230)
	numpad.size_flags_stretch_ratio = 0.7 if compact else 0.72
	actions_row.size_flags_stretch_ratio = 0.34 if compact else 0.36
	code_label.add_theme_font_size_override("normal_font_size", 24 if compact else 28)
	code_label.add_theme_font_size_override("mono_font_size", 30 if compact else 34)
	briefing_goal.add_theme_font_size_override("font_size", 18 if compact else 20)
	briefing_hint.add_theme_font_size_override("font_size", 15 if compact else 16)

	for btn_var in numpad.get_children():
		if btn_var is Button:
			(btn_var as Button).custom_minimum_size = Vector2(52, 52) if compact else Vector2(64, 64)
	btn_enter.custom_minimum_size = Vector2(0, 48) if compact else Vector2(0, 56)
	btn_analyze.custom_minimum_size = Vector2(0, 48) if compact else Vector2(0, 56)
	btn_next.custom_minimum_size = Vector2(0, 48) if compact else Vector2(0, 56)

func _load_levels_from_json() -> bool:
	var file: FileAccess = FileAccess.open(LEVELS_PATH, FileAccess.READ)
	if file == null:
		push_error("Cannot open %s" % LEVELS_PATH)
		return false

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_error("%s is not an array" % LEVELS_PATH)
		return false

	var loaded_levels: Array = parsed
	var valid_levels: Array = []
	for item_var in loaded_levels:
		if typeof(item_var) != TYPE_DICTIONARY:
			continue
		var level: Dictionary = item_var
		if _validate_level(level):
			valid_levels.append(level)
		else:
			push_error("Invalid suspect level: %s" % str(level.get("id", "UNKNOWN")))

	levels = valid_levels
	return levels.size() > 0

func _validate_level(level: Dictionary) -> bool:
	var required_keys: Array[String] = ["id", "bucket", "briefing", "code", "expected", "trace", "economy", "topic_tags", "explain_short"]
	for key in required_keys:
		if not level.has(key):
			return false

	if typeof(level.get("code")) != TYPE_ARRAY:
		return false
	if typeof(level.get("trace")) != TYPE_ARRAY:
		return false
	if typeof(level.get("economy")) != TYPE_DICTIONARY:
		return false
	if typeof(level.get("topic_tags")) != TYPE_ARRAY:
		return false
	if typeof(level.get("explain_short")) != TYPE_ARRAY:
		return false

	var trace: Array = level.get("trace", [])
	if trace.is_empty():
		return false

	for step_var in trace:
		if typeof(step_var) != TYPE_DICTIONARY:
			return false
		var step: Dictionary = step_var
		if not step.has("i") or not step.has("cond") or not step.has("s_before") or not step.has("s_after"):
			return false

	return true

func _show_boot_error(text: String) -> void:
	lbl_status.text = text
	lbl_status.add_theme_color_override("font_color", STATUS_COLOR_FAIL)
	btn_enter.disabled = true
	btn_analyze.disabled = true
	btn_next.disabled = true

func _localized_briefing_text(task: Dictionary) -> String:
	var source: String = str(task.get("briefing", "")).strip_edges()
	var task_id: String = str(task.get("id", "unknown"))
	return _tr("suspect.a.level.%s.briefing" % task_id, source)

func _load_level(idx: int) -> void:
	if levels.is_empty():
		return

	if idx >= levels.size():
		idx = 0
	current_level_idx = idx

	current_task = (levels[idx] as Dictionary).duplicate(true)
	variant_hash = str(hash(JSON.stringify(current_task)))
	task_started_at = Time.get_ticks_msec()

	task_session = {
		"task_id": str(current_task.get("id", "A-00")),
		"variant_hash": variant_hash,
		"started_at_ticks": task_started_at,
		"ended_at_ticks": 0,
		"attempts": [],
		"events": []
	}

	state = State.BRIEFING
	wrong_count = 0
	energy = 100.0
	user_input = ""
	is_safe_mode = false
	is_code_ready = false
	task_finished = false
	task_result_sent = false

	lbl_clue_title.text = _tr("suspect.a.labels.clue_title", "CLUE #{id}", {"id": str(current_task.get("id", "A-00"))})
	lbl_session.text = _tr("suspect.a.labels.session", "SESSION {n}", {"n": "%04d" % (randi() % 10000)})
	lbl_status.text = _tr("suspect.a.status.loading", "Loading suspect code...")
	lbl_status.add_theme_color_override("font_color", STATUS_COLOR_NEUTRAL)
	lbl_attempts.text = _tr("suspect.a.labels.attempts_init", "ATTEMPTS: 0/{max}", {"max": MAX_ATTEMPTS})
	decrypt_bar.value = float(current_level_idx) / maxf(1.0, float(levels.size() - 1)) * 100.0
	energy_bar.value = energy

	btn_enter.disabled = true
	btn_analyze.disabled = true
	btn_next.visible = false
	diag_panel.visible = false

	_update_input_display()
	_update_briefing_card()
	_log_event("task_start", {"bucket": str(current_task.get("bucket", "unknown"))})

	var briefing: String = _localized_briefing_text(current_task)
	code_label.text = "[color=#8A8A8A]%s[/color]\n\n" % briefing
	await _typewrite_code(current_task.get("code", []))

	is_code_ready = true
	state = State.SOLVING
	btn_enter.disabled = false
	btn_analyze.disabled = false
	lbl_status.text = _tr("suspect.a.status.ready", "Calculate the final s and enter your answer.")
	lbl_status.add_theme_color_override("font_color", STATUS_COLOR_READY)

func _update_briefing_card() -> void:
	briefing_goal.text = _tr("suspect.a.labels.goal", "Goal: find the final value of s")

	var hints: Array[String] = []
	for tag_var in current_task.get("topic_tags", []):
		var tag: String = str(tag_var)
		match tag:
			"range_stop_exclusive":
				hints.append(_tr("suspect.a.hint.range_stop", "stop in range is exclusive"))
			"while_boundary":
				hints.append(_tr("suspect.a.hint.while_boundary", "check the while boundary"))
			"break_flow":
				hints.append(_tr("suspect.a.hint.break_flow", "break exits the loop"))
			"continue_flow":
				hints.append(_tr("suspect.a.hint.continue_flow", "continue skips the step"))
			"list_iteration":
				hints.append(_tr("suspect.a.hint.list_iteration", "list defines explicit order"))
			"step_trap":
				hints.append(_tr("suspect.a.hint.step_trap", "check the range step"))
			_:
				hints.append(tag.replace("_", " "))
	if hints.is_empty():
		hints.append(_tr("suspect.a.hint.general", "check loop bounds and condition"))

	briefing_hint.text = _tr("suspect.a.labels.hint_prefix", "Hint: {hint}",
		{"hint": ", ".join(hints.slice(0, min(2, hints.size())))})

func _typewrite_code(lines: Array) -> void:
	for line_var in lines:
		var line: String = str(line_var)
		code_label.append_text("[code]%s[/code]\n" % line)
		code_scroll.scroll_vertical = 1000000
		await get_tree().create_timer(typewriter_delay_sec).timeout
	_log_event("code_shown", {"line_count": lines.size()})

func _on_numpad_pressed(btn_node: Node) -> void:
	if state != State.SOLVING or not is_code_ready or task_finished:
		return

	var btn: Button = btn_node as Button
	if btn == null:
		return

	_play_sfx(AUDIO_CLICK)
	var char: String = btn.text
	if char == "CLR":
		user_input = ""
	elif char == "<-":
		if user_input.length() > 0:
			user_input = user_input.left(user_input.length() - 1)
	elif user_input.length() < 4:
		user_input += char

	_update_input_display()

func _update_input_display() -> void:
	input_display.text = "----" if user_input.is_empty() else user_input

func _normalize(raw: String) -> Dictionary:
	var stripped: String = raw.strip_edges().replace(" ", "")
	if stripped.is_empty():
		return {"ok": false, "error": "EMPTY"}
	if not stripped.is_valid_int():
		return {"ok": false, "error": "NAN"}
	var value: int = int(stripped)
	if value < 0 or value > 9999:
		return {"ok": false, "error": "RANGE"}
	return {"ok": true, "val": value, "str": str(value)}

func _on_enter_pressed() -> void:
	if state != State.SOLVING or not is_code_ready or task_finished:
		return

	var now: int = Time.get_ticks_msec()
	var normalized: Dictionary = _normalize(user_input)
	if not bool(normalized.get("ok", false)):
		_play_sfx(AUDIO_ERROR)
		_trigger_glitch()
		_shake_screen()
		lbl_status.text = _tr("suspect.a.status.invalid_format", "Invalid input format.")
		lbl_status.add_theme_color_override("font_color", STATUS_COLOR_FAIL)
		(task_session["attempts"] as Array).append({
			"kind": "numpad",
			"raw": user_input,
			"norm": "",
			"duration_input_ms": now - task_started_at,
			"correct": false,
			"parse_error": str(normalized.get("error", "UNKNOWN")),
			"state_after": "INVALID_INPUT",
			"energy_after": energy,
			"wrong_count_after": wrong_count
		})
		return

	var expected: int = int(current_task.get("expected", 0))
	var is_correct: bool = int(normalized.get("val", -1)) == expected
	var state_after: String = "SOLVING"

	if is_correct:
		_handle_success_feedback()
		state_after = "FEEDBACK_SUCCESS"
	else:
		_handle_fail_feedback()
		if is_safe_mode:
			state_after = "SAFE_MODE"
		elif state == State.FEEDBACK_FAIL:
			state_after = "FEEDBACK_FAIL"

	var attempt: Dictionary = {
		"kind": "numpad",
		"raw": user_input,
		"norm": str(normalized.get("str", "")),
		"duration_input_ms": now - task_started_at,
		"hint_open_at_enter": diag_panel.visible,
		"correct": is_correct,
		"state_after": state_after,
		"energy_after": energy,
		"wrong_count_after": wrong_count
	}
	(task_session["attempts"] as Array).append(attempt)

	if is_correct:
		_finalize_task_result(true, "SUCCESS")
	elif is_safe_mode:
		_finalize_task_result(false, "SAFE_MODE")

	if not is_correct and not is_safe_mode:
		user_input = ""
		_update_input_display()

func _handle_success_feedback() -> void:
	state = State.FEEDBACK_SUCCESS
	lbl_status.text = _tr("suspect.a.status.correct", "Correct. Value confirmed.")
	lbl_status.add_theme_color_override("font_color", STATUS_COLOR_SUCCESS)
	btn_enter.disabled = true
	btn_analyze.disabled = true
	btn_next.visible = true
	decrypt_bar.value = minf(100.0, decrypt_bar.value + float(current_task.get("economy", {}).get("reward", 0)))
	_play_sfx(AUDIO_RELAY)
	_play_success_clean_effect()

func _handle_fail_feedback() -> void:
	wrong_count += 1
	lbl_attempts.text = _tr("suspect.a.labels.attempts", "ATTEMPTS: {n}/{max}", {"n": wrong_count, "max": MAX_ATTEMPTS})
	lbl_status.text = _tr("suspect.a.status.incorrect", "Incorrect. Try again.")
	lbl_status.add_theme_color_override("font_color", STATUS_COLOR_FAIL)

	var wrong_penalty: int = int(current_task.get("economy", {}).get("wrong", 10))
	energy = maxf(0.0, energy - float(wrong_penalty))
	energy_bar.value = energy

	_play_sfx(AUDIO_ERROR)
	_trigger_glitch()
	_shake_screen()

	if wrong_count >= MAX_ATTEMPTS:
		_trigger_safe_mode()
	else:
		state = State.SOLVING

func _trigger_safe_mode() -> void:
	state = State.SAFE_MODE
	is_safe_mode = true
	btn_enter.disabled = true
	btn_next.visible = true
	lbl_status.text = _tr("suspect.a.status.error_limit", "Error limit reached. Safe mode enabled.")
	lbl_status.add_theme_color_override("font_color", STATUS_COLOR_WARN)

	btn_analyze.disabled = false
	_on_analyze_pressed(true)
	btn_analyze.disabled = true
	_log_event("safe_mode_triggered", {})

func _on_analyze_pressed(free: bool = false) -> void:
	if not is_code_ready:
		return
	if state != State.SOLVING and state != State.SAFE_MODE:
		return

	if not free:
		var analyze_cost: int = int(current_task.get("economy", {}).get("analyze", 20))
		if energy < float(analyze_cost):
			lbl_status.text = _tr("suspect.a.status.low_energy", "Insufficient energy for analysis.")
			lbl_status.add_theme_color_override("font_color", STATUS_COLOR_WARN)
			_play_sfx(AUDIO_ERROR)
			return
		energy -= float(analyze_cost)
		energy_bar.value = energy

	diag_panel.visible = true
	_render_diagnostic()
	_log_event("analyze_open", {"free": free})
	state = State.DIAGNOSTIC if state == State.SOLVING else state

func _render_diagnostic() -> void:
	var explain_lines: Array = current_task.get("explain_short", [])
	if explain_lines.is_empty():
		explain_lines = current_task.get("explain", [])

	var task_id: String = str(current_task.get("id", "A-01"))
	var explain_text: String = "[b]%s[/b]\n" % _tr("suspect.a.diag.analysis_title", "ANALYSIS")
	for line_idx in range(explain_lines.size()):
		var default_line: String = str(explain_lines[line_idx])
		var key: String = "suspect.a.level.%s.explain.%d" % [task_id, line_idx]
		explain_text += "- %s\n" % _tr(key, default_line)
	diag_explain.text = explain_text

	var trace: Array = current_task.get("trace", [])
	var i_values: Array[String] = []
	var trace_lines: Array[String] = []
	for step_var in trace:
		var step: Dictionary = step_var
		i_values.append(str(step.get("i", "?")))
		trace_lines.append("i=%s | cond=%s | s: %s -> %s" % [
			str(step.get("i", "?")),
			str(step.get("cond", "?")),
			str(step.get("s_before", "?")),
			str(step.get("s_after", "?"))
		])

	var seq_label: String = _tr("suspect.a.diag.i_sequence_label", "i sequence")
	var trace_text: String = "%s: [%s]\n\n%s" % [seq_label, ", ".join(i_values), "\n".join(trace_lines)]
	diag_trace.text = trace_text

func _on_close_diag_pressed() -> void:
	if not diag_panel.visible:
		return
	diag_panel.visible = false
	_log_event("analyze_close", {})
	if state == State.DIAGNOSTIC and not is_safe_mode and not task_finished:
		state = State.SOLVING

func _on_next_pressed() -> void:
	if not task_finished:
		return
	_log_event("next_pressed", {"from_task": str(current_task.get("id", "A-00"))})
	_load_level(current_level_idx + 1)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _finalize_task_result(is_correct: bool, reason: String) -> void:
	if task_result_sent:
		return

	task_result_sent = true
	task_finished = true
	var ended: int = Time.get_ticks_msec()
	task_session["ended_at_ticks"] = ended
	_log_event("task_end", {"reason": reason, "is_correct": is_correct})

	var level_id: String = str(current_task.get("id", "A-00"))
	var bucket: String = str(current_task.get("bucket", "unknown"))
	var elapsed_ms: int = ended - task_started_at

	var result_data: Dictionary = {
		"quest": "suspect_script",
		"stage": "A",
		"match_key": "SUSPECT_A|%s" % level_id,
		"task_id": level_id,
		"bucket": bucket,
		"variant_hash": variant_hash,
		"is_correct": is_correct,
		"is_fit": is_correct,
		"safe_mode": is_safe_mode,
		"elapsed_ms": elapsed_ms,
		"duration": float(elapsed_ms) / 1000.0,
		"task_session": task_session
	}

	GlobalMetrics.register_trial(result_data)

func _play_sfx(stream: AudioStream) -> void:
	if sfx_player == null:
		return
	sfx_player.stop()
	sfx_player.stream = stream
	sfx_player.play()

func _trigger_glitch() -> void:
	var overlay_rect: ColorRect = noir_overlay.get_node_or_null("CRT_Overlay") as ColorRect
	if overlay_rect == null:
		return
	var shader_mat: ShaderMaterial = overlay_rect.material as ShaderMaterial
	if shader_mat == null:
		return
	var high_fx: bool = fx_quality == "high"
	_set_overlay_param(shader_mat, "pulse", 1.0 if high_fx else 0.65)
	_set_overlay_param(shader_mat, "jitter_strength", 0.8 if high_fx else 0.35)
	_set_overlay_param(shader_mat, "glitch_strength", 0.9 if high_fx else 0.55)
	var tw: Tween = create_tween()
	tw.tween_method(func(v: float) -> void: _set_overlay_param(shader_mat, "pulse", v), 1.0 if high_fx else 0.65, 0.0, 0.26)
	tw.parallel().tween_method(func(v: float) -> void: _set_overlay_param(shader_mat, "jitter_strength", v), 0.8 if high_fx else 0.35, 0.0, 0.22)
	tw.parallel().tween_method(func(v: float) -> void: _set_overlay_param(shader_mat, "glitch_strength", v), 0.9 if high_fx else 0.55, 0.0, 0.22)

func _shake_screen() -> void:
	var original_pos: Vector2 = main_layout.position
	var tw: Tween = create_tween()
	for _i in range(4):
		tw.tween_property(main_layout, "position", original_pos + Vector2(randf_range(-2.0, 2.0), randf_range(-1.5, 1.5)), 0.04)
	tw.tween_property(main_layout, "position", original_pos, 0.05)

func _play_success_clean_effect() -> void:
	var overlay_rect: ColorRect = noir_overlay.get_node_or_null("CRT_Overlay") as ColorRect
	if overlay_rect == null:
		return
	var shader_mat: ShaderMaterial = overlay_rect.material as ShaderMaterial
	if shader_mat == null:
		return
	var tw: Tween = create_tween()
	tw.tween_method(func(v: float) -> void: _set_overlay_param(shader_mat, "grain_strength", v), 0.32, 0.16, 0.20)
	tw.parallel().tween_method(func(v: float) -> void: _set_overlay_param(shader_mat, "hatch_strength", v), 0.24, 0.10, 0.20)
	tw.tween_interval(0.12)
	tw.tween_method(func(v: float) -> void: _set_overlay_param(shader_mat, "grain_strength", v), 0.16, 0.32, 0.28)
	tw.parallel().tween_method(func(v: float) -> void: _set_overlay_param(shader_mat, "hatch_strength", v), 0.10, 0.24, 0.28)

func _log_event(name: String, payload: Dictionary) -> void:
	var elapsed: int = Time.get_ticks_msec() - task_started_at
	var events: Array = task_session.get("events", [])
	events.append({
		"name": name,
		"t_ms": elapsed,
		"payload": payload
	})
	task_session["events"] = events
