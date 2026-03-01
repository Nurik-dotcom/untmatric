extends Control

# --- CONSTANTS & CONFIG ---
const PHASE_TRAINING = "TRAINING"
const PHASE_TRANSLATION = "TRANSLATION"
const PHASE_DETECTION = "DETECTION"

const GATE_AND = "AND"
const GATE_OR = "OR"
const GATE_NOT = "NOT"
const GATE_XOR = "XOR"
const GATE_NAND = "NAND"
const GATE_NOR = "NOR"

const MAX_ATTEMPTS = 3
const VERDICT_LOCK_TIME = 2.0

# --- I18N HELPERS ---
func _tr(key: String, default_text: String, params: Dictionary = {}) -> String:
	var merged := params.duplicate(true)
	merged["default"] = default_text
	return I18n.tr_key(key, merged)

func _case_text(field: String, default_value: String = "") -> String:
	var key := str(current_case.get("%s_key" % field, ""))
	return _tr(key, str(current_case.get(field, default_value)))

func _gate_label(gate_id: String) -> String:
	return _tr("logic.common.gate.%s" % gate_id.to_lower(), gate_id)

# Cases Data (keys + defaults)
const CASES = [
	{
		"id": "A1_01", "phase": PHASE_TRAINING, "gate": GATE_AND,
		"a_key": "logic.a.case.A1_01.a", "a_text": "KEY",
		"b_key": "logic.a.case.A1_01.b", "b_text": "START",
		"witness_key": "logic.a.case.A1_01.w", "witness_text": "Engine starts only if KEY is present and START is pressed.",
		"min_seen": 2, "hint_keys": ["logic.a.case.A1_01.h1", "logic.a.case.A1_01.h2"], "hints": ["Need both conditions.", "This is AND."]
	},
	{
		"id": "A1_02", "phase": PHASE_TRAINING, "gate": GATE_OR,
		"a_key": "logic.a.case.A1_02.a", "a_text": "RAIN",
		"b_key": "logic.a.case.A1_02.b", "b_text": "SNOW",
		"witness_key": "logic.a.case.A1_02.w", "witness_text": "You get wet if there is RAIN or SNOW.",
		"min_seen": 2, "hint_keys": ["logic.a.case.A1_02.h1", "logic.a.case.A1_02.h2"], "hints": ["One condition is enough.", "This is OR."]
	},
	{
		"id": "A1_03", "phase": PHASE_TRAINING, "gate": GATE_NOT,
		"a_key": "logic.a.case.A1_03.a", "a_text": "SIGNAL",
		"b_key": "logic.a.case.A1_03.b", "b_text": "---",
		"witness_key": "logic.a.case.A1_03.w", "witness_text": "Lie detector inverts: input 0 -> output 1, input 1 -> output 0.",
		"min_seen": 2, "hint_keys": ["logic.a.case.A1_03.h1", "logic.a.case.A1_03.h2"], "hints": ["Inversion 1->0, 0->1.", "This is NOT."]
	}
]
# --- UI NODES ---
@onready var clue_title_label: Label = $SafeArea/MainLayout/Header/LblClueTitle
@onready var session_label: Label = $SafeArea/MainLayout/Header/LblSessionId
@onready var facts_bar: ProgressBar = $SafeArea/MainLayout/BarsRow/FactsBar
@onready var energy_bar: ProgressBar = $SafeArea/MainLayout/BarsRow/EnergyBar
@onready var target_label: Label = $SafeArea/MainLayout/TargetDisplay/LblTarget
@onready var content_split: SplitContainer = $SafeArea/MainLayout/ContentHSplit
@onready var terminal_text: RichTextLabel = $SafeArea/MainLayout/ContentHSplit/LeftPane/TerminalFrame/TerminalScroll/TerminalRichText
@onready var stats_label: Label = $SafeArea/MainLayout/ContentHSplit/RightPane/StatusRow/StatsLabel
@onready var feedback_label: Label = $SafeArea/MainLayout/ContentHSplit/RightPane/StatusRow/FeedbackLabel

@onready var input_a_frame: PanelContainer = $SafeArea/MainLayout/ContentHSplit/RightPane/InteractionRow/InputAFrame
@onready var input_b_frame: PanelContainer = $SafeArea/MainLayout/ContentHSplit/RightPane/InteractionRow/InputBFrame
@onready var gate_slot_frame: PanelContainer = $SafeArea/MainLayout/ContentHSplit/RightPane/InteractionRow/GateSlot
@onready var input_a_btn: Button = $SafeArea/MainLayout/ContentHSplit/RightPane/InteractionRow/InputAFrame/InputAVBox/InputA_Btn
@onready var input_b_btn: Button = $SafeArea/MainLayout/ContentHSplit/RightPane/InteractionRow/InputBFrame/InputBVBox/InputB_Btn
@onready var gate_label: Label = $SafeArea/MainLayout/ContentHSplit/RightPane/InteractionRow/GateSlot/GateVBox/GateLabel
@onready var output_value_label: Label = $SafeArea/MainLayout/ContentHSplit/RightPane/InteractionRow/OutputSlot/OutputVBox/OutputValueLabel
@onready var model_value_label: Label = $SafeArea/MainLayout/ContentHSplit/RightPane/InteractionRow/OutputSlot/OutputVBox/ModelValueLabel
@onready var match_label: Label = $SafeArea/MainLayout/ContentHSplit/RightPane/InteractionRow/OutputSlot/OutputVBox/MatchLabel
@onready var inventory_frame: PanelContainer = $SafeArea/MainLayout/ContentHSplit/RightPane/InventoryFrame

@onready var gate_and_btn: Button = $SafeArea/MainLayout/ContentHSplit/RightPane/InventoryFrame/InventoryMargin/InventoryScroll/GatesContainer/GateAndBtn
@onready var gate_or_btn: Button = $SafeArea/MainLayout/ContentHSplit/RightPane/InventoryFrame/InventoryMargin/InventoryScroll/GatesContainer/GateOrBtn
@onready var gate_not_btn: Button = $SafeArea/MainLayout/ContentHSplit/RightPane/InventoryFrame/InventoryMargin/InventoryScroll/GatesContainer/GateNotBtn
@onready var gate_xor_btn: Button = $SafeArea/MainLayout/ContentHSplit/RightPane/InventoryFrame/InventoryMargin/InventoryScroll/GatesContainer/GateXorBtn
@onready var gate_nand_btn: Button = $SafeArea/MainLayout/ContentHSplit/RightPane/InventoryFrame/InventoryMargin/InventoryScroll/GatesContainer/GateNandBtn
@onready var gate_nor_btn: Button = $SafeArea/MainLayout/ContentHSplit/RightPane/InventoryFrame/InventoryMargin/InventoryScroll/GatesContainer/GateNorBtn

@onready var btn_hint: Button = $SafeArea/MainLayout/ContentHSplit/RightPane/Actions/BtnHint
@onready var btn_probe: Button = $SafeArea/MainLayout/ContentHSplit/RightPane/Actions/BtnProbe
@onready var btn_verdict: Button = $SafeArea/MainLayout/ContentHSplit/RightPane/Actions/BtnVerdict
@onready var btn_next: Button = $SafeArea/MainLayout/ContentHSplit/RightPane/Actions/BtnNext
@onready var diagnostics_blocker: ColorRect = $DiagnosticsBlocker
@onready var diagnostics_panel: PanelContainer = $DiagnosticsPanelA
@onready var diagnostics_title: Label = $DiagnosticsPanelA/PopupMargin/PopupVBox/PopupTitle
@onready var diagnostics_text: RichTextLabel = $DiagnosticsPanelA/PopupMargin/PopupVBox/PopupText
@onready var diagnostics_next_button: Button = $DiagnosticsPanelA/PopupMargin/PopupVBox/PopupBtnNext
@onready var click_player: AudioStreamPlayer = $ClickPlayer

# --- STATE ---
var current_case_index: int = 0
var current_case: Dictionary = {}

var input_a: bool = false
var input_b: bool = false
var selected_gate_guess: String = ""
var observed_output: bool = false
var has_observation: bool = false

var seen_combinations: Dictionary = {}
var seen_trace_entries: Array[Dictionary] = []
var case_attempts: int = 0
var hints_used: int = 0
var analyze_count: int = 0
var start_time_msec: int = 0
var first_action_ms: int = -1
var verdict_count: int = 0

var last_verdict_time: float = 0.0
var verdict_timer: Timer = null
var analyze_timer: Timer = null
var is_safe_mode: bool = false
var gate_buttons: Dictionary = {}
var highlighted_step: int = -1
var contradiction_index: int = -1
var is_landscape_layout: bool = false

const COLOR_OUTPUT_ON = Color(0.95, 0.95, 0.90, 1.0)
const COLOR_OUTPUT_OFF = Color(0.55, 0.55, 0.55, 1.0)
const COLOR_OUTPUT_MODEL = Color(0.56, 0.78, 0.96, 1.0)
const COLOR_MATCH = Color(0.45, 0.92, 0.62, 1.0)
const COLOR_MISMATCH = Color(1.0, 0.35, 0.32, 1.0)
const ANALYZE_COOLDOWN_SEC: float = 4.0
const LOW_CONFIDENCE_BONUS: float = 5.0

func _ready() -> void:
	_setup_gate_buttons()
	_update_stability_ui(GlobalMetrics.stability, 0)
	if not GlobalMetrics.stability_changed.is_connected(_update_stability_ui):
		GlobalMetrics.stability_changed.connect(_update_stability_ui)
	if not GlobalMetrics.game_over.is_connected(_on_game_over):
		GlobalMetrics.game_over.connect(_on_game_over)
	if not get_viewport().size_changed.is_connected(_on_viewport_resized):
		get_viewport().size_changed.connect(_on_viewport_resized)
	if not I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.connect(_on_language_changed)

	verdict_timer = Timer.new()
	verdict_timer.one_shot = true
	verdict_timer.timeout.connect(_on_verdict_unlock)
	add_child(verdict_timer)

	analyze_timer = Timer.new()
	analyze_timer.one_shot = true
	analyze_timer.timeout.connect(_on_analyze_unlock)
	add_child(analyze_timer)

	_apply_responsive_layout()
	_apply_i18n()
	load_case(0)

func _on_verdict_unlock() -> void:
	btn_verdict.disabled = false

func _on_analyze_unlock() -> void:
	btn_hint.disabled = false

func _exit_tree() -> void:
	if GlobalMetrics.stability_changed.is_connected(_update_stability_ui):
		GlobalMetrics.stability_changed.disconnect(_update_stability_ui)
	if GlobalMetrics.game_over.is_connected(_on_game_over):
		GlobalMetrics.game_over.disconnect(_on_game_over)
	if get_viewport() and get_viewport().size_changed.is_connected(_on_viewport_resized):
		get_viewport().size_changed.disconnect(_on_viewport_resized)
	if I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.disconnect(_on_language_changed)

func _setup_gate_buttons() -> void:
	gate_buttons = {
		GATE_AND: gate_and_btn,
		GATE_OR: gate_or_btn,
		GATE_NOT: gate_not_btn,
		GATE_XOR: gate_xor_btn,
		GATE_NAND: gate_nand_btn,
		GATE_NOR: gate_nor_btn
	}
	_clear_gate_selection()

func _on_viewport_resized() -> void:
	_apply_responsive_layout()

func _apply_responsive_layout() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var landscape := viewport_size.x > viewport_size.y
	var should_vertical := not landscape
	if is_landscape_layout == landscape and content_split.vertical == should_vertical:
		return
	is_landscape_layout = landscape
	content_split.vertical = should_vertical
	content_split.split_offset = int(viewport_size.x * 0.5)
	_update_ui_state()

func _on_language_changed(_code: String) -> void:
	_apply_i18n()
	_update_stats_ui()
	_update_target_and_bars()
	_render_trace()
	_update_ui_state()

func _apply_i18n() -> void:
	clue_title_label.text = _tr("logic.a.ui.title", "ДЕТЕКТОР ЛЖИ A-01")
	btn_probe.text = _tr("logic.a.ui.btn_probe", "ПРОГОН")
	btn_verdict.text = _tr("logic.a.ui.btn_verdict", "ВЕРДИКТ")
	btn_hint.text = _tr("logic.a.ui.btn_hint", "АНАЛИЗ")
	btn_next.text = _tr("logic.a.ui.btn_next", "ДАЛЕЕ")
	gate_label.text = _tr("logic.a.ui.gate_label", "ВЕНТИЛЬ")
	match_label.text = _tr("logic.a.ui.match_label", "MATCH: --")
	target_label.text = _tr("logic.a.ui.target_default", "ЦЕЛЬ: собрать факты и вынести вердикт")
	diagnostics_title.text = _tr("logic.a.ui.safe_title", "SAFE MODE")
	diagnostics_text.text = _tr("logic.a.ui.safe_brief", "Диагностический отчёт.")
	diagnostics_next_button.text = _tr("logic.a.ui.btn_next", "ДАЛЕЕ")
	gate_and_btn.text = _gate_label(GATE_AND)
	gate_or_btn.text = _gate_label(GATE_OR)
	gate_not_btn.text = _gate_label(GATE_NOT)
	gate_xor_btn.text = _gate_label(GATE_XOR)
	gate_nand_btn.text = _gate_label(GATE_NAND)
	gate_nor_btn.text = _gate_label(GATE_NOR)
	_update_gate_slot_label()
	_update_input_labels()
	_update_circuit()


func load_case(idx: int) -> void:
	if idx >= CASES.size():
		idx = 0

	current_case_index = idx
	current_case = CASES[idx]

	input_a = false
	input_b = false
	selected_gate_guess = ""
	observed_output = false
	has_observation = false
	seen_combinations.clear()
	seen_trace_entries.clear()
	case_attempts = 0
	hints_used = 0
	analyze_count = 0
	start_time_msec = Time.get_ticks_msec()
	first_action_ms = -1
	verdict_count = 0
	last_verdict_time = 0.0
	is_safe_mode = false
	contradiction_index = -1
	if analyze_timer != null:
		analyze_timer.stop()

	_apply_i18n()
	_update_stats_ui()
	_hide_diagnostics()

	input_a_btn.button_pressed = false
	input_b_btn.button_pressed = false
	input_a_btn.disabled = false
	input_b_btn.disabled = false
	btn_hint.disabled = false
	btn_probe.disabled = false
	btn_verdict.visible = true
	btn_verdict.disabled = false
	btn_next.visible = false
	feedback_label.visible = false
	feedback_label.text = ""
	match_label.text = _tr("logic.a.ui.match_label", "MATCH: --")
	match_label.add_theme_color_override("font_color", COLOR_OUTPUT_OFF)

	if str(current_case.get("gate", "")) == GATE_NOT:
		input_b_frame.visible = false
		input_b_btn.disabled = true
	else:
		input_b_frame.visible = true
		input_b_btn.disabled = false

	_set_gate_buttons_enabled(true)
	_clear_gate_selection()
	_update_input_labels()
	_update_circuit()
	_update_ui_state()

func _update_input_labels() -> void:
	input_a_btn.text = "%s\n[%s]" % [_case_text("a", "A"), "1" if input_a else "0"]
	if str(current_case.get("gate", "")) != GATE_NOT:
		input_b_btn.text = "%s\n[%s]" % [_case_text("b", "B"), "1" if input_b else "0"]

func _on_input_a_toggled(pressed: bool) -> void:
	_mark_first_action()
	input_a = pressed
	_play_click()
	_update_input_labels()
	_update_circuit()

func _on_input_b_toggled(pressed: bool) -> void:
	_mark_first_action()
	input_b = pressed
	_play_click()
	_update_input_labels()
	_update_circuit()

func _on_probe_pressed() -> void:
	if is_safe_mode or not btn_verdict.visible:
		return
	_mark_first_action()

	var out_val := _calculate_gate_output(input_a, input_b, str(current_case.get("gate", "")))
	observed_output = out_val
	has_observation = true
	contradiction_index = -1

	var combo_key := _combo_key_for_inputs(input_a, input_b)
	if not seen_combinations.has(combo_key):
		seen_combinations[combo_key] = out_val
		seen_trace_entries.append({
			"a": 1 if input_a else 0,
			"b": -1 if str(current_case.get("gate", "")) == GATE_NOT else (1 if input_b else 0),
			"f": 1 if out_val else 0,
			"idx": seen_trace_entries.size() + 1
		})
		_show_feedback(" #%d" % seen_trace_entries.size(), Color(0.56, 0.78, 0.96))
	else:
		_show_feedback("   .", Color(0.66, 0.66, 0.66))

	_update_stats_ui()
	_update_circuit()
	_play_click()

func _combo_key_for_inputs(a_val: bool, b_val: bool) -> String:
		if str(current_case.get("gate", "")) == GATE_NOT:
			return "A=%d" % [1 if a_val else 0]
		return "A=%d B=%d" % [1 if a_val else 0, 1 if b_val else 0]

func _on_gate_button_toggled(arg1: Variant, arg2: Variant = null) -> void:
	var pressed := false
	var gate_id := ""
	if arg1 is bool:
		pressed = arg1
		gate_id = str(arg2)
	else:
		gate_id = str(arg1)
		pressed = bool(arg2)
	if gate_id.is_empty():
		return

	if is_safe_mode:
		return
	if gate_and_btn.disabled:
		return
	if not pressed:
		if selected_gate_guess == gate_id:
			selected_gate_guess = ""
			_update_gate_slot_label()
		return

	_mark_first_action()
	for key in gate_buttons.keys():
		if key != gate_id:
			var btn_other: Button = gate_buttons[key]
			btn_other.set_pressed_no_signal(false)

	selected_gate_guess = gate_id
	_play_click()
	_update_gate_slot_label()

func _update_circuit() -> void:
	if has_observation:
		output_value_label.text = "F_box = %s" % ("1" if observed_output else "0")
		output_value_label.add_theme_color_override("font_color", COLOR_OUTPUT_ON if observed_output else COLOR_OUTPUT_OFF)
	else:
		output_value_label.text = "F_box = ?"
		output_value_label.add_theme_color_override("font_color", COLOR_OUTPUT_OFF)

	if selected_gate_guess.is_empty():
		model_value_label.text = "F_model = ?"
		model_value_label.add_theme_color_override("font_color", COLOR_OUTPUT_OFF)
		match_label.text = "MATCH: --"
		match_label.add_theme_color_override("font_color", COLOR_OUTPUT_OFF)
	else:
		var model_out := _calculate_gate_output(input_a, input_b, selected_gate_guess)
		model_value_label.text = "F_model = %s" % ("1" if model_out else "0")
		model_value_label.add_theme_color_override("font_color", COLOR_OUTPUT_MODEL if model_out else COLOR_OUTPUT_OFF)
		if has_observation:
			var is_match := model_out == observed_output
			match_label.text = "MATCH: %s" % ("YES" if is_match else "NO")
			match_label.add_theme_color_override("font_color", COLOR_MATCH if is_match else COLOR_MISMATCH)
		else:
			match_label.text = "MATCH: --"
			match_label.add_theme_color_override("font_color", COLOR_OUTPUT_OFF)

	var output_for_log := observed_output if has_observation else false
	_update_target_and_bars()
	_update_terminal_text(output_for_log)
	_update_ui_state()

func _calculate_gate_output(a: bool, b: bool, type: String) -> bool:
	match type:
		GATE_AND:
			return a and b
		GATE_OR:
			return a or b
		GATE_NOT:
			return not a
		GATE_XOR:
			return a != b
		GATE_NAND:
			return not (a and b)
		GATE_NOR:
			return not (a or b)
	return false

func _update_stability_ui(val: float, _change: float = 0.0) -> void:
	energy_bar.value = clampf(val, 0.0, 100.0)
	_update_ui_state()

func _update_target_and_bars() -> void:
	target_label.text = _tr("logic.a.ui.target_default", target_label.text)
	facts_bar.value = seen_combinations.size()
	facts_bar.max_value = max(1, _total_unique_combinations())

func _render_trace() -> void:
	_update_terminal_text(observed_output if has_observation else false)

func _clear_gate_selection() -> void:
	selected_gate_guess = ""
	for btn in gate_buttons.values():
		(btn as Button).set_pressed_no_signal(false)
	_update_gate_slot_label()

func _update_gate_slot_label() -> void:
	var label_text := _gate_label(selected_gate_guess) if not selected_gate_guess.is_empty() else _tr("logic.a.ui.gate_slot_empty", "?")
	gate_label.text = label_text

func _set_gate_buttons_enabled(enabled: bool) -> void:
	for btn in gate_buttons.values():
		(btn as Button).disabled = not enabled

func _update_ui_state() -> void:
	# Minimal stub: could add visual state toggles if needed
	pass

func _hide_diagnostics() -> void:
	diagnostics_panel.visible = false
	diagnostics_blocker.visible = false

func _show_feedback(msg: String, col: Color) -> void:
	feedback_label.text = msg
	feedback_label.add_theme_color_override("font_color", col)
	feedback_label.visible = true

func _enter_safe_mode() -> void:
	is_safe_mode = true
	_set_gate_buttons_enabled(false)
	btn_hint.disabled = true
	btn_probe.disabled = true
	btn_verdict.disabled = true
	diagnostics_panel.visible = true
	diagnostics_blocker.visible = true

func _start_analyze_cooldown() -> void:
	btn_hint.disabled = true
	if analyze_timer:
		analyze_timer.start(ANALYZE_COOLDOWN_SEC)

func _confidence_ratio() -> float:
	if _total_unique_combinations() <= 0:
		return 0.0
	return float(seen_combinations.size()) / float(_total_unique_combinations())

func _confidence_bucket(ratio: float) -> String:
	if ratio >= 0.75:
		return "HIGH"
	if ratio >= 0.4:
		return "MID"
	return "LOW"

func _total_unique_combinations() -> int:
	return 4 if str(current_case.get("gate", "")) != GATE_NOT else 2

func _first_contradiction_for_gate(gate_id: String) -> Dictionary:
	for i in range(seen_trace_entries.size()):
		var entry := seen_trace_entries[i]
		var expected := _calculate_gate_output(bool(entry.get("a", false)), bool(entry.get("b", false)), gate_id)
		if expected != bool(entry.get("f", false)):
			return {"index": i, "a": entry.get("a", false), "b": entry.get("b", -1)}
	return {}
func _update_terminal_text(out_val: bool) -> void:
	var lines: Array[String] = []
	var a_label := _case_text("a", "A")
	var b_label := _case_text("b", "B")
	var confidence_ratio := _confidence_ratio()
	var confidence_bucket := _confidence_bucket(confidence_ratio)

	lines.append("[b]%s[/b]" % _tr("logic.a.ui.briefing_title", "БРИФИНГ"))
	lines.append(_case_text("witness", ""))
	lines.append("")
	lines.append("[b]%s[/b]" % _tr("logic.a.ui.steps_title", "ШАГИ"))
	lines.append(_tr("logic.a.ui.step1", "1) Выставьте входы."))
	lines.append(_tr("logic.a.ui.step2", "2) Нажмите ПРОГОН, чтобы записать факт."))
	lines.append(_tr("logic.a.ui.step3", "3) Выберите вентиль в инвентаре."))
	lines.append(_tr("logic.a.ui.step4", "4) Нажмите ВЕРДИКТ."))
	lines.append("")
	lines.append(_tr("logic.a.ui.confidence", "Уверенность: {bucket} ({seen}/{total})", {
		"bucket": confidence_bucket,
		"seen": seen_combinations.size(),
		"total": _total_unique_combinations()
	}))
	lines.append("")
	if has_observation:
		lines.append("A=%d, B=%d -> F_box=%d" % [
			1 if input_a else 0,
			1 if input_b else 0,
			1 if out_val else 0
		])
	if has_observation and not selected_gate_guess.is_empty():
		lines.append("%s(%s,%s) = %d" % [
			selected_gate_guess,
			a_label,
			b_label,
			1 if _calculate_gate_output(input_a, input_b, selected_gate_guess) else 0
		])
	if contradiction_index >= 0 and contradiction_index < seen_trace_entries.size():
		var entry := seen_trace_entries[contradiction_index]
		lines.append("[color=#ff7a7a]%s[/color]" % _tr("logic.a.ui.contradiction", "ПРОТИВОРЕЧИЕ"))

	if lines.size() <= 0:
		lines.append(_tr("logic.a.ui.log_empty", "- ЖУРНАЛ ПУСТ"))

	terminal_text.text = "\n".join(lines)
	terminal_text.scroll_to_line(0)

func _update_stats_ui() -> void:
	var case_id := str(current_case.get("id", "A_00"))
	var confidence_ratio := _confidence_ratio()
	session_label.text = _tr("logic.a.ui.session", "SESSION: {cur}/{total} | CASE {case}", {
		"cur": current_case_index + 1,
		"total": CASES.size(),
		"case": case_id
	})
	stats_label.text = _tr(
		"logic.a.ui.stats",
		"ATT: {attempts}/{max} | FACTS: {facts}/{total_facts} | CONF: {conf} | ANALYZE: {analyze} | STAB: {stability}%",
		{
			"attempts": case_attempts,
			"max": MAX_ATTEMPTS,
			"facts": seen_combinations.size(),
			"total_facts": _total_unique_combinations(),
			"conf": _confidence_bucket(confidence_ratio),
			"analyze": analyze_count,
			"stability": int(GlobalMetrics.stability)
		}
	)
	_update_target_and_bars()
	_update_ui_state()

func _on_game_over() -> void:
	_enter_safe_mode()

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _on_next_button_pressed() -> void:
	_hide_diagnostics()
	load_case(current_case_index + 1)

func _on_hint_pressed() -> void:
	if is_safe_mode or not btn_verdict.visible:
		return
	_mark_first_action()
	if analyze_timer != null and not analyze_timer.is_stopped():
		_show_feedback("ANALYZE OVERHEAT... %.1fs" % analyze_timer.time_left, Color(1.0, 0.78, 0.32))
		return

	analyze_count += 1
	hints_used += 1

	if seen_trace_entries.is_empty():
		_show_feedback("    ", Color(0.56, 0.78, 0.96))
	elif selected_gate_guess.is_empty():
		_show_feedback("    .", Color(0.56, 0.78, 0.96))
	else:
		var contradiction := _first_contradiction_for_gate(selected_gate_guess)
		if contradiction.is_empty():
			_show_feedback("   .", Color(0.45, 0.92, 0.62))
		else:
			contradiction_index = int(contradiction.get("index", -1))
			var a_name := str(current_case.get("a_text", "A"))
			var b_name := str(current_case.get("b_text", "B"))
			var a_text := "%s=%d" % [a_name, 1 if bool(contradiction.get("a", false)) else 0]
			var b_raw := int(contradiction.get("b", -1))
			if b_raw >= 0:
				a_text += ", %s=%d" % [b_name, b_raw]
			_show_feedback("    #%d (%s)." % [contradiction_index + 1, a_text], Color(1.0, 0.78, 0.32))

	_update_circuit()
	_start_analyze_cooldown()

func _mark_first_action() -> void:
	if first_action_ms < 0:
		first_action_ms = Time.get_ticks_msec() - start_time_msec

func _register_trial(verdict_code: String, is_correct: bool) -> void:
	var case_id := str(current_case.get("id", "A_00"))
	var payload := TrialV2.build("LOGIC_QUEST", "A", case_id, "GATE_IDENTIFY")
	var elapsed_ms: int = maxi(0, Time.get_ticks_msec() - start_time_msec)
	payload["elapsed_ms"] = elapsed_ms
	payload["duration"] = float(elapsed_ms) / 1000.0
	payload["time_to_first_action_ms"] = first_action_ms if first_action_ms >= 0 else elapsed_ms
	payload["is_correct"] = is_correct
	payload["is_fit"] = is_correct
	payload["stability_delta"] = 0
	payload["verdict_code"] = verdict_code
	payload["selected_gate_id"] = selected_gate_guess
	payload["correct_gate_id"] = str(current_case.get("gate", ""))
	payload["seen_combinations"] = seen_combinations.size()
	payload["hints_used"] = hints_used
	payload["analyze_count"] = analyze_count
	payload["attempts"] = case_attempts
	payload["verdict_count"] = verdict_count
	payload["confidence_ratio"] = _confidence_ratio()
	payload["observation_count"] = seen_trace_entries.size()
	payload["has_observation"] = has_observation
	GlobalMetrics.register_trial(payload)

func _play_click() -> void:
	if click_player.stream:
		click_player.play()

func _disable_controls() -> void:
	input_a_btn.disabled = true
	input_b_btn.disabled = true
	_set_gate_buttons_enabled(false)
	btn_hint.disabled = true
	btn_probe.disabled = true
