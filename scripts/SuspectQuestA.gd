extends Control

const THEME_GREEN: Theme = preload("res://ui/theme_terminal_green.tres")
const THEME_AMBER: Theme = preload("res://ui/theme_terminal_amber.tres")

const AUDIO_CLICK: AudioStream = preload("res://audio/click.wav")
const AUDIO_ERROR: AudioStream = preload("res://audio/error.wav")
const AUDIO_RELAY: AudioStream = preload("res://audio/relay.wav")

const LEVELS_PATH := "res://data/suspect_a_levels.json"
const MAX_ATTEMPTS := 3
const PALETTE_ID_GREEN := 0
const PALETTE_ID_AMBER := 1
const FX_ID_LOW := 0
const FX_ID_HIGH := 1

enum State {
	INIT,
	BRIEFING,
	SOLVING,
	FEEDBACK_SUCCESS,
	FEEDBACK_FAIL,
	SAFE_MODE,
	DIAGNOSTIC
}

@export_enum("green", "amber") var terminal_palette: String = "green"
@export_enum("low", "high") var fx_quality: String = "low"
@export var typewriter_delay_sec: float = 0.03

@onready var main_layout: VBoxContainer = $MainLayout
@onready var crt_overlay: ColorRect = $CanvasLayer/CRT_Overlay
@onready var code_label: RichTextLabel = $MainLayout/TerminalFrame/ScrollContainer/CodeLabel
@onready var code_scroll: ScrollContainer = $MainLayout/TerminalFrame/ScrollContainer
@onready var input_display: Label = $MainLayout/InputFrame/InputDisplay
@onready var lbl_status: Label = $MainLayout/StatusRow/LblStatus
@onready var lbl_attempts: Label = $MainLayout/StatusRow/LblAttempts
@onready var decrypt_bar: ProgressBar = $MainLayout/BarsRow/DecryptBar
@onready var energy_bar: ProgressBar = $MainLayout/BarsRow/EnergyBar
@onready var diag_panel: PanelContainer = $DiagnosticsPanel
@onready var diag_trace: RichTextLabel = $DiagnosticsPanel/VBoxContainer/TraceList
@onready var diag_explain: RichTextLabel = $DiagnosticsPanel/VBoxContainer/ExplainList
@onready var btn_enter: Button = $MainLayout/Actions/BtnEnter
@onready var btn_analyze: Button = $MainLayout/Actions/BtnAnalyze
@onready var btn_next: Button = $MainLayout/Actions/BtnNext
@onready var btn_close_diag: Button = $DiagnosticsPanel/VBoxContainer/BtnCloseDiag
@onready var lbl_clue_title: Label = $MainLayout/Header/LblClueTitle
@onready var lbl_session: Label = $MainLayout/Header/LblSessionId
@onready var palette_select: OptionButton = $MainLayout/SettingsRow/PaletteSelect
@onready var fx_select: OptionButton = $MainLayout/SettingsRow/FxSelect
@onready var numpad: GridContainer = $MainLayout/Numpad

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
	_setup_runtime_controls()
	_apply_theme()
	_configure_overlay_shader()
	_init_audio_player()
	_connect_signals()
	_apply_mobile_min_sizes()

	if not _load_levels_from_json():
		_show_boot_error("Не удалось загрузить уровни подозреваемых.")
		return

	if levels.size() != 18:
		push_warning("Suspect levels expected 18, got %d" % levels.size())

	GlobalMetrics.current_level_index = 0
	_load_level(0)

func _apply_theme() -> void:
	theme = THEME_GREEN if terminal_palette == "green" else THEME_AMBER

func _setup_runtime_controls() -> void:
	palette_select.clear()
	palette_select.add_item("ЗЕЛЁНЫЙ", PALETTE_ID_GREEN)
	palette_select.add_item("ЯНТАРНЫЙ", PALETTE_ID_AMBER)
	palette_select.select(PALETTE_ID_GREEN if terminal_palette == "green" else PALETTE_ID_AMBER)

	fx_select.clear()
	fx_select.add_item("НИЗКИЙ", FX_ID_LOW)
	fx_select.add_item("ВЫСОКИЙ", FX_ID_HIGH)
	fx_select.select(FX_ID_HIGH if fx_quality == "high" else FX_ID_LOW)

	palette_select.item_selected.connect(_on_palette_selected)
	fx_select.item_selected.connect(_on_fx_selected)

func _configure_overlay_shader() -> void:
	var shader_mat := crt_overlay.material as ShaderMaterial
	if shader_mat == null:
		return
	shader_mat.set_shader_parameter("fx_quality", 1 if fx_quality == "high" else 0)
	shader_mat.set_shader_parameter("glitch_strength", 0.0)
	if terminal_palette == "amber":
		shader_mat.set_shader_parameter("tint_color", Color(1.0, 0.69, 0.0, 1.0))
	else:
		shader_mat.set_shader_parameter("tint_color", Color(0.0, 1.0, 0.254902, 1.0))

func _init_audio_player() -> void:
	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SfxPlayer"
	add_child(sfx_player)

func _connect_signals() -> void:
	for btn in numpad.get_children():
		if btn is Button:
			(btn as Button).pressed.connect(_on_numpad_pressed.bind(btn))

	btn_enter.pressed.connect(_on_enter_pressed)
	btn_analyze.pressed.connect(_on_analyze_pressed)
	btn_next.pressed.connect(_on_next_pressed)
	btn_close_diag.pressed.connect(_on_close_diag_pressed)

func _on_palette_selected(index: int) -> void:
	var item_id: int = palette_select.get_item_id(index)
	terminal_palette = "amber" if item_id == PALETTE_ID_AMBER else "green"
	_apply_theme()
	_configure_overlay_shader()

func _on_fx_selected(index: int) -> void:
	var item_id: int = fx_select.get_item_id(index)
	fx_quality = "high" if item_id == FX_ID_HIGH else "low"
	_configure_overlay_shader()

func _apply_mobile_min_sizes() -> void:
	palette_select.custom_minimum_size = Vector2(120, 44)
	fx_select.custom_minimum_size = Vector2(110, 44)
	for btn in numpad.get_children():
		if btn is Button:
			(btn as Button).custom_minimum_size = Vector2(64, 64)
	btn_enter.custom_minimum_size = Vector2(0, 56)
	btn_analyze.custom_minimum_size = Vector2(0, 56)
	btn_next.custom_minimum_size = Vector2(0, 56)

func _load_levels_from_json() -> bool:
	var f := FileAccess.open(LEVELS_PATH, FileAccess.READ)
	if f == null:
		push_error("Cannot open %s" % LEVELS_PATH)
		return false

	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_error("%s is not an array" % LEVELS_PATH)
		return false

	var loaded_levels: Array = parsed
	var valid_levels: Array = []
	for item in loaded_levels:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var level: Dictionary = item
		if _validate_level(level):
			valid_levels.append(level)
		else:
			push_error("Invalid suspect level: %s" % str(level.get("id", "UNKNOWN")))

	levels = valid_levels
	return levels.size() > 0

func _validate_level(level: Dictionary) -> bool:
	var required_keys := ["id", "bucket", "briefing", "code", "expected", "trace", "explain", "economy"]
	for key in required_keys:
		if not level.has(key):
			return false

	if typeof(level.get("code")) != TYPE_ARRAY:
		return false
	if typeof(level.get("trace")) != TYPE_ARRAY:
		return false
	if typeof(level.get("explain")) != TYPE_ARRAY:
		return false
	if typeof(level.get("economy")) != TYPE_DICTIONARY:
		return false

	var trace: Array = level.get("trace", [])
	if trace.is_empty():
		return false

	for step in trace:
		if typeof(step) != TYPE_DICTIONARY:
			return false
		var d: Dictionary = step
		if not d.has("i") or not d.has("cond") or not d.has("s_before") or not d.has("s_after"):
			return false

	return true

func _show_boot_error(text: String) -> void:
	lbl_status.text = text
	lbl_status.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	btn_enter.disabled = true
	btn_analyze.disabled = true
	btn_next.disabled = true

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

	lbl_clue_title.text = "УЛИКА #%s" % str(current_task.get("id", "A-00"))
	lbl_session.text = "СЕСС %04d" % (randi() % 10000)
	lbl_status.text = "ДЕШИФРОВКА..."
	lbl_status.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	lbl_attempts.text = "ОШ: 0/%d" % MAX_ATTEMPTS
	decrypt_bar.value = float(current_level_idx) / maxf(1.0, float(levels.size() - 1)) * 100.0
	energy_bar.value = energy

	btn_enter.disabled = true
	btn_analyze.disabled = true
	btn_next.visible = false
	diag_panel.visible = false

	_update_input_display()
	_log_event("task_start", {"bucket": str(current_task.get("bucket", "unknown"))})

	var briefing := str(current_task.get("briefing", ""))
	code_label.text = "[color=#7A7A7A]%s[/color]\n\n" % briefing
	await _typewrite_code(current_task.get("code", []))

	is_code_ready = true
	state = State.SOLVING
	btn_enter.disabled = false
	btn_analyze.disabled = false
	lbl_status.text = "ВВОД ГОТОВ"
	lbl_status.add_theme_color_override("font_color", Color(0.6, 0.95, 0.6))

func _typewrite_code(lines: Array) -> void:
	for line_variant in lines:
		var line := str(line_variant)
		code_label.append_text("[code]%s[/code]\n" % line)
		code_scroll.scroll_vertical = 1000000
		await get_tree().create_timer(typewriter_delay_sec).timeout
	_log_event("code_shown", {"line_count": lines.size()})

func _on_numpad_pressed(btn_node: Node) -> void:
	if state != State.SOLVING or not is_code_ready or task_finished:
		return

	var btn := btn_node as Button
	if btn == null:
		return

	_play_sfx(AUDIO_CLICK)
	var char := btn.text
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
	var stripped := raw.strip_edges().replace(" ", "")
	if stripped.is_empty():
		return {"ok": false, "error": "EMPTY"}
	if not stripped.is_valid_int():
		return {"ok": false, "error": "NAN"}
	var value := int(stripped)
	if value < 0 or value > 9999:
		return {"ok": false, "error": "RANGE"}
	return {"ok": true, "val": value, "str": str(value)}

func _on_enter_pressed() -> void:
	if state != State.SOLVING or not is_code_ready or task_finished:
		return

	var now := Time.get_ticks_msec()
	var normalized := _normalize(user_input)
	if not bool(normalized.get("ok", false)):
		_play_sfx(AUDIO_ERROR)
		_trigger_glitch()
		_shake_screen()
		lbl_status.text = "НЕКОРРЕКТНЫЙ ВВОД"
		lbl_status.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		task_session["attempts"].append({
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

	var expected := int(current_task.get("expected", 0))
	var is_correct := int(normalized.get("val", -1)) == expected
	var state_after := "SOLVING"

	if is_correct:
		_handle_success_feedback()
		state_after = "FEEDBACK_SUCCESS"
	else:
		_handle_fail_feedback()
		if is_safe_mode:
			state_after = "SAFE_MODE"
		elif state == State.FEEDBACK_FAIL:
			state_after = "FEEDBACK_FAIL"

	var attempt := {
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
	task_session["attempts"].append(attempt)

	if is_correct:
		_finalize_task_result(true, "SUCCESS")
	elif is_safe_mode:
		_finalize_task_result(false, "SAFE_MODE")

	if not is_correct and not is_safe_mode:
		user_input = ""
		_update_input_display()

func _handle_success_feedback() -> void:
	state = State.FEEDBACK_SUCCESS
	lbl_status.text = "ДОСТУП РАЗРЕШЁН"
	lbl_status.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))
	btn_enter.disabled = true
	btn_analyze.disabled = true
	btn_next.visible = true
	decrypt_bar.value = minf(100.0, decrypt_bar.value + float(current_task.get("economy", {}).get("reward", 0)))
	_play_sfx(AUDIO_RELAY)

func _handle_fail_feedback() -> void:
	wrong_count += 1
	lbl_attempts.text = "ОШ: %d/%d" % [wrong_count, MAX_ATTEMPTS]
	lbl_status.text = "ДОСТУП ЗАПРЕЩЁН"
	lbl_status.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))

	var wrong_penalty := int(current_task.get("economy", {}).get("wrong", 10))
	energy = maxf(0.0, energy - float(wrong_penalty))
	energy_bar.value = energy

	_play_sfx(AUDIO_ERROR)
	_trigger_glitch()
	_shake_screen()

	if wrong_count >= MAX_ATTEMPTS:
		_trigger_safe_mode()
	else:
		state = State.FEEDBACK_FAIL
		state = State.SOLVING

func _trigger_safe_mode() -> void:
	state = State.SAFE_MODE
	is_safe_mode = true
	btn_enter.disabled = true
	btn_next.visible = true
	lbl_status.text = "БЕЗОПАСНЫЙ РЕЖИМ АКТИВЕН"
	lbl_status.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))

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
		var analyze_cost := int(current_task.get("economy", {}).get("analyze", 20))
		if energy < float(analyze_cost):
			lbl_status.text = "НЕДОСТАТОЧНО ЭНЕРГИИ"
			lbl_status.add_theme_color_override("font_color", Color(1.0, 0.55, 0.25))
			_play_sfx(AUDIO_ERROR)
			return
		energy -= float(analyze_cost)
		energy_bar.value = energy

	diag_panel.visible = true
	_render_diagnostic()
	_log_event("analyze_open", {"free": free})
	state = State.DIAGNOSTIC if state == State.SOLVING else state

func _render_diagnostic() -> void:
	var explain_lines: Array = current_task.get("explain", [])
	var explain_text := "[b]ANALYSIS[/b]\n"
	for line_var in explain_lines:
		explain_text += "- %s\n" % str(line_var)
	diag_explain.text = explain_text

	var trace: Array = current_task.get("trace", [])
	var trace_text := ""
	for step_var in trace:
		var step: Dictionary = step_var
		trace_text += "i=%s | cond=%s | s: %s -> %s\n" % [
			str(step.get("i", "?")),
			str(step.get("cond", "?")),
			str(step.get("s_before", "?")),
			str(step.get("s_after", "?"))
		]
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

func _finalize_task_result(is_correct: bool, reason: String) -> void:
	if task_result_sent:
		return

	task_result_sent = true
	task_finished = true
	var ended := Time.get_ticks_msec()
	task_session["ended_at_ticks"] = ended
	_log_event("task_end", {"reason": reason, "is_correct": is_correct})

	var level_id := str(current_task.get("id", "A-00"))
	var bucket := str(current_task.get("bucket", "unknown"))
	var elapsed_ms := ended - task_started_at

	var result_data := {
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
	if fx_quality != "high":
		return
	var shader_mat := crt_overlay.material as ShaderMaterial
	if shader_mat == null:
		return
	shader_mat.set_shader_parameter("glitch_strength", 1.0)
	var tw := create_tween()
	tw.tween_method(func(v: float): shader_mat.set_shader_parameter("glitch_strength", v), 1.0, 0.0, 0.25)

func _shake_screen() -> void:
	var original_pos := main_layout.position
	var tw := create_tween()
	for _i in range(4):
		tw.tween_property(main_layout, "position", original_pos + Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0)), 0.04)
	tw.tween_property(main_layout, "position", original_pos, 0.05)

func _log_event(name: String, payload: Dictionary) -> void:
	var elapsed := Time.get_ticks_msec() - task_started_at
	var events: Array = task_session.get("events", [])
	events.append({
		"name": name,
		"t_ms": elapsed,
		"payload": payload
	})
	task_session["events"] = events


