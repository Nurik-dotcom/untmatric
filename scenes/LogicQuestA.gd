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
const ANALYZE_COOLDOWN_SEC: float = 4.0
const LOW_CONFIDENCE_BONUS: float = 5.0

const DIAG_NONE = ""
const DIAG_NEXT = "NEXT_CASE"
const DIAG_EXIT = "EXIT_QUESTS"

enum UiStep {
	SET_INPUTS,
	GATHER_FACTS,
	CHOOSE_HYPOTHESIS,
	CASE_DONE,
	SAFE_MODE
}

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
@onready var btn_back: Button = $SafeArea/MainLayout/Header/BtnBack
@onready var facts_bar_label: Label = $SafeArea/MainLayout/BarsRow/FactsBarLabel
@onready var facts_bar: ProgressBar = $SafeArea/MainLayout/BarsRow/FactsBar
@onready var energy_bar_label: Label = $SafeArea/MainLayout/BarsRow/EnergyBarLabel
@onready var energy_bar: ProgressBar = $SafeArea/MainLayout/BarsRow/EnergyBar
@onready var target_label: Label = $SafeArea/MainLayout/TargetDisplay/LblTarget
@onready var content_split: SplitContainer = $SafeArea/MainLayout/ContentHSplit
@onready var left_pane: VBoxContainer = $SafeArea/MainLayout/ContentHSplit/LeftPane
@onready var right_pane: VBoxContainer = $SafeArea/MainLayout/ContentHSplit/RightPane
@onready var terminal_text: RichTextLabel = $SafeArea/MainLayout/ContentHSplit/LeftPane/TerminalFrame/TerminalScroll/TerminalRichText
@onready var stats_label: Label = $SafeArea/MainLayout/ContentHSplit/RightPane/StatusRow/StatsLabel
@onready var feedback_label: Label = $SafeArea/MainLayout/ContentHSplit/RightPane/StatusRow/FeedbackLabel

@onready var interaction_row: GridContainer = $SafeArea/MainLayout/ContentHSplit/RightPane/InteractionRow
@onready var input_a_frame: PanelContainer = $SafeArea/MainLayout/ContentHSplit/RightPane/InteractionRow/InputAFrame
@onready var input_b_frame: PanelContainer = $SafeArea/MainLayout/ContentHSplit/RightPane/InteractionRow/InputBFrame
@onready var gate_slot_frame: PanelContainer = $SafeArea/MainLayout/ContentHSplit/RightPane/InteractionRow/GateSlot
@onready var output_slot_frame: PanelContainer = $SafeArea/MainLayout/ContentHSplit/RightPane/InteractionRow/OutputSlot

@onready var input_a_btn: Button = $SafeArea/MainLayout/ContentHSplit/RightPane/InteractionRow/InputAFrame/InputAVBox/InputA_Btn
@onready var input_b_btn: Button = $SafeArea/MainLayout/ContentHSplit/RightPane/InteractionRow/InputBFrame/InputBVBox/InputB_Btn
@onready var input_a_title_label: Label = $SafeArea/MainLayout/ContentHSplit/RightPane/InteractionRow/InputAFrame/InputAVBox/InputATitle
@onready var input_b_title_label: Label = $SafeArea/MainLayout/ContentHSplit/RightPane/InteractionRow/InputBFrame/InputBVBox/InputBTitle
@onready var gate_title_label: Label = $SafeArea/MainLayout/ContentHSplit/RightPane/InteractionRow/GateSlot/GateVBox/GateTitle
@onready var output_title_label: Label = $SafeArea/MainLayout/ContentHSplit/RightPane/InteractionRow/OutputSlot/OutputVBox/OutputTitle
@onready var gate_label: Label = $SafeArea/MainLayout/ContentHSplit/RightPane/InteractionRow/GateSlot/GateVBox/GateLabel
@onready var output_value_label: Label = $SafeArea/MainLayout/ContentHSplit/RightPane/InteractionRow/OutputSlot/OutputVBox/OutputValueLabel
@onready var model_value_label: Label = $SafeArea/MainLayout/ContentHSplit/RightPane/InteractionRow/OutputSlot/OutputVBox/ModelValueLabel
@onready var match_label: Label = $SafeArea/MainLayout/ContentHSplit/RightPane/InteractionRow/OutputSlot/OutputVBox/MatchLabel
@onready var inventory_frame: PanelContainer = $SafeArea/MainLayout/ContentHSplit/RightPane/InventoryFrame

@onready var gates_container: GridContainer = $SafeArea/MainLayout/ContentHSplit/RightPane/InventoryFrame/InventoryMargin/InventoryScroll/GatesContainer
@onready var gate_and_btn: Button = $SafeArea/MainLayout/ContentHSplit/RightPane/InventoryFrame/InventoryMargin/InventoryScroll/GatesContainer/GateAndBtn
@onready var gate_or_btn: Button = $SafeArea/MainLayout/ContentHSplit/RightPane/InventoryFrame/InventoryMargin/InventoryScroll/GatesContainer/GateOrBtn
@onready var gate_not_btn: Button = $SafeArea/MainLayout/ContentHSplit/RightPane/InventoryFrame/InventoryMargin/InventoryScroll/GatesContainer/GateNotBtn
@onready var gate_xor_btn: Button = $SafeArea/MainLayout/ContentHSplit/RightPane/InventoryFrame/InventoryMargin/InventoryScroll/GatesContainer/GateXorBtn
@onready var gate_nand_btn: Button = $SafeArea/MainLayout/ContentHSplit/RightPane/InventoryFrame/InventoryMargin/InventoryScroll/GatesContainer/GateNandBtn
@onready var gate_nor_btn: Button = $SafeArea/MainLayout/ContentHSplit/RightPane/InventoryFrame/InventoryMargin/InventoryScroll/GatesContainer/GateNorBtn

@onready var actions_container: BoxContainer = $SafeArea/MainLayout/ContentHSplit/RightPane/Actions
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
var is_case_complete: bool = false
var gate_buttons: Dictionary = {}
var contradiction_index: int = -1
var is_landscape_layout: bool = false
var diagnostics_action: String = DIAG_NONE

const COLOR_OUTPUT_ON = Color(0.95, 0.95, 0.90, 1.0)
const COLOR_OUTPUT_OFF = Color(0.55, 0.55, 0.55, 1.0)
const COLOR_OUTPUT_MODEL = Color(0.56, 0.78, 0.96, 1.0)
const COLOR_MATCH = Color(0.45, 0.92, 0.62, 1.0)
const COLOR_MISMATCH = Color(1.0, 0.35, 0.32, 1.0)

const COLOR_STATE_ACTIVE = Color(0.96, 0.74, 0.38, 1.0)
const COLOR_STATE_FILLED = Color(0.62, 0.84, 0.98, 1.0)
const COLOR_STATE_SUCCESS = Color(0.45, 0.92, 0.62, 1.0)
const COLOR_STATE_ERROR = Color(1.0, 0.38, 0.34, 1.0)
const COLOR_STATE_LOCKED = Color(0.38, 0.38, 0.40, 1.0)
const COLOR_TEXT_MUTED = Color(0.70, 0.70, 0.72, 1.0)
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
	_update_ui_state()

func _on_analyze_unlock() -> void:
	_update_ui_state()

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
	for gate_id in gate_buttons.keys():
		var gate_btn: Button = gate_buttons[gate_id]
		var call := Callable(self, "_on_gate_button_toggled").bind(gate_id)
		if not gate_btn.toggled.is_connected(call):
			gate_btn.toggled.connect(call)
	_clear_gate_selection()

func _on_viewport_resized() -> void:
	_apply_responsive_layout()

func _apply_responsive_layout() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var landscape := viewport_size.x >= viewport_size.y
	var mobile := viewport_size.x < 900.0
	var very_narrow := viewport_size.x < 640.0
	is_landscape_layout = landscape

	content_split.vertical = not landscape
	if landscape:
		content_split.split_offset = int(viewport_size.x * 0.52)
		left_pane.size_flags_stretch_ratio = 1.0
		right_pane.size_flags_stretch_ratio = 1.0
		actions_container.vertical = false
		gates_container.columns = 6
		interaction_row.columns = 4
		interaction_row.add_theme_constant_override("h_separation", 12)
		interaction_row.add_theme_constant_override("v_separation", 12)
		terminal_text.add_theme_font_size_override("normal_font_size", 20)
	else:
		content_split.split_offset = int(viewport_size.y * 0.33)
		left_pane.size_flags_stretch_ratio = 0.75
		right_pane.size_flags_stretch_ratio = 1.25
		actions_container.vertical = true
		gates_container.columns = 2 if very_narrow else 3
		interaction_row.columns = 2
		interaction_row.add_theme_constant_override("h_separation", 10)
		interaction_row.add_theme_constant_override("v_separation", 10)
		terminal_text.add_theme_font_size_override("normal_font_size", 17 if mobile else 19)

	for btn in gate_buttons.values():
		(btn as Button).custom_minimum_size = Vector2(96 if mobile else 120, 56 if mobile else 64)
	for btn_action in [btn_hint, btn_probe, btn_verdict, btn_next]:
		btn_action.custom_minimum_size = Vector2(0, 56 if mobile else 60)

	_update_ui_state()

func _on_language_changed(_code: String) -> void:
	_apply_i18n()
	_update_stats_ui()
	_update_target_and_bars()
	_render_trace()
	_update_ui_state()

func _apply_i18n() -> void:
	clue_title_label.text = _tr("logic.a.ui.title", "ДЕТЕКТОР ЛЖИ")
	btn_back.text = _tr("logic.a.ui.btn_back", "НАЗАД")
	btn_probe.text = _tr("logic.a.ui.btn_probe", "ПРОГОН")
	btn_verdict.text = _tr("logic.a.ui.btn_verdict", "ВЕРДИКТ")
	btn_hint.text = _tr("logic.a.ui.btn_hint", "АНАЛИЗ")
	btn_next.text = _tr("logic.a.ui.btn_next", "ДАЛЕЕ")
	match_label.text = _tr("logic.a.ui.match_label", "СОВПАДЕНИЕ: --")
	input_a_title_label.text = _tr("logic.a.ui.input_a_title", "ВХОД A")
	input_b_title_label.text = _tr("logic.a.ui.input_b_title", "ВХОД B")
	gate_title_label.text = _tr("logic.a.ui.gate_title", "ГИПОТЕЗА")
	output_title_label.text = _tr("logic.a.ui.output_title", "ВЫХОД")
	diagnostics_title.text = _tr("logic.a.ui.safe_title", "SAFE MODE")
	diagnostics_text.text = _tr("logic.a.ui.safe_brief", "Диагностика готова. Вы можете перейти дальше.")
	diagnostics_next_button.text = _tr("logic.a.ui.btn_next", "ДАЛЕЕ")
	facts_bar_label.text = _tr("logic.a.ui.facts_bar", "ФАКТЫ")
	energy_bar_label.text = _tr("logic.a.ui.energy_bar", "СТАБИЛЬНОСТЬ")
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
	if idx < 0 or idx >= CASES.size():
		return

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
	is_case_complete = false
	contradiction_index = -1
	diagnostics_action = DIAG_NONE
	if analyze_timer != null:
		analyze_timer.stop()
	if verdict_timer != null:
		verdict_timer.stop()

	_apply_i18n()
	_update_stats_ui()
	_hide_diagnostics()

	input_a_btn.button_pressed = false
	input_b_btn.button_pressed = false
	feedback_label.visible = false
	feedback_label.text = ""

	if _is_not_case():
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
	GlobalMetrics.start_quest(str(current_case.get("id", "LogicQuestA")))

func _is_not_case() -> bool:
	return str(current_case.get("gate", "")) == GATE_NOT
func _update_input_labels() -> void:
	input_a_btn.text = "%s\n[%s]" % [_case_text("a", "A"), "1" if input_a else "0"]
	if not _is_not_case():
		input_b_btn.text = "%s\n[%s]" % [_case_text("b", "B"), "1" if input_b else "0"]

func _on_input_a_toggled(pressed: bool) -> void:
	if is_case_complete or is_safe_mode:
		input_a_btn.set_pressed_no_signal(input_a)
		return
	_mark_first_action()
	input_a = pressed
	_play_click()
	_update_input_labels()
	_update_circuit()

func _on_input_b_toggled(pressed: bool) -> void:
	if is_case_complete or is_safe_mode or _is_not_case():
		input_b_btn.set_pressed_no_signal(input_b)
		return
	_mark_first_action()
	input_b = pressed
	_play_click()
	_update_input_labels()
	_update_circuit()

func _on_probe_pressed() -> void:
	if is_safe_mode or is_case_complete:
		return
	_mark_first_action()

	var out_val := _calculate_gate_output(input_a, input_b, str(current_case.get("gate", "")))
	observed_output = out_val
	has_observation = true
	contradiction_index = -1

	var combo_key := _combo_key_for_inputs(input_a, input_b)
	if not seen_combinations.has(combo_key):
		seen_combinations[combo_key] = out_val
		var entry: Dictionary = {
			"index": seen_trace_entries.size(),
			"a": 1 if input_a else 0,
			"has_b": not _is_not_case(),
			"b": -1 if _is_not_case() else (1 if input_b else 0),
			"f_box": 1 if out_val else 0,
			"combo": combo_key
		}
		seen_trace_entries.append(entry)
		_show_feedback(_tr("logic.a.ui.fact_saved", "ФАКТ #{n} ЗАПИСАН", {"n": seen_trace_entries.size()}), Color(0.56, 0.78, 0.96))
	else:
		_show_feedback(_tr("logic.a.ui.fact_duplicate", "ЭТА КОМБИНАЦИЯ УЖЕ ПРОВЕРЕНА"), COLOR_TEXT_MUTED)

	_update_stats_ui()
	_update_circuit()
	_play_click()

func _combo_key_for_inputs(a_val: bool, b_val: bool) -> String:
	if _is_not_case():
		return "A=%d" % [1 if a_val else 0]
	return "A=%d B=%d" % [1 if a_val else 0, 1 if b_val else 0]

func _on_gate_button_toggled(pressed: bool, gate_id: String) -> void:
	if gate_id.is_empty() or is_safe_mode or is_case_complete:
		return

	if not pressed:
		if selected_gate_guess == gate_id:
			selected_gate_guess = ""
			_update_gate_slot_label()
			_update_ui_state()
		return

	_mark_first_action()
	for key in gate_buttons.keys():
		if key != gate_id:
			var btn_other: Button = gate_buttons[key]
			btn_other.set_pressed_no_signal(false)

	selected_gate_guess = gate_id
	_play_click()
	_update_gate_slot_label()
	_update_circuit()

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
		match_label.text = _tr("logic.a.ui.match_label", "СОВПАДЕНИЕ: --")
		match_label.add_theme_color_override("font_color", COLOR_OUTPUT_OFF)
	else:
		var model_out := _calculate_gate_output(input_a, input_b, selected_gate_guess)
		model_value_label.text = "F_model = %s" % ("1" if model_out else "0")
		model_value_label.add_theme_color_override("font_color", COLOR_OUTPUT_MODEL if model_out else COLOR_OUTPUT_OFF)
		if has_observation:
			var is_match := model_out == observed_output
			match_label.text = _tr("logic.a.ui.match_value", "СОВПАДЕНИЕ: {value}", {"value": _tr("logic.a.ui.match_yes", "ДА") if is_match else _tr("logic.a.ui.match_no", "НЕТ")})
			match_label.add_theme_color_override("font_color", COLOR_MATCH if is_match else COLOR_MISMATCH)
		else:
			match_label.text = _tr("logic.a.ui.match_label", "СОВПАДЕНИЕ: --")
			match_label.add_theme_color_override("font_color", COLOR_OUTPUT_OFF)

	_update_target_and_bars()
	_update_terminal_text()
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
	energy_bar_label.text = _tr("logic.a.ui.energy_bar_value", "СТАБИЛЬНОСТЬ {value}%", {"value": int(clampf(val, 0.0, 100.0))})
	_update_ui_state()

func _update_target_and_bars() -> void:
	var total := _total_unique_combinations()
	var facts := seen_combinations.size()
	facts_bar.max_value = max(1, total)
	facts_bar.value = facts
	facts_bar_label.text = _tr("logic.a.ui.facts_bar_value", "ФАКТЫ {seen}/{total}", {"seen": facts, "total": total})

func _render_trace() -> void:
	_update_terminal_text()

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
func _derive_ui_step() -> int:
	if is_safe_mode:
		return UiStep.SAFE_MODE
	if is_case_complete:
		return UiStep.CASE_DONE
	if seen_combinations.is_empty():
		return UiStep.SET_INPUTS
	if selected_gate_guess.is_empty():
		return UiStep.GATHER_FACTS
	return UiStep.CHOOSE_HYPOTHESIS

func _update_ui_state() -> void:
	var step := _derive_ui_step()
	var has_guess := not selected_gate_guess.is_empty()
	var min_seen := int(current_case.get("min_seen", 2))
	var has_min_facts := seen_combinations.size() >= min_seen
	var verdict_on_cooldown := verdict_timer != null and not verdict_timer.is_stopped()
	var analyze_on_cooldown := analyze_timer != null and not analyze_timer.is_stopped()
	var controls_locked := is_case_complete or is_safe_mode

	input_a_btn.disabled = controls_locked
	input_b_btn.disabled = controls_locked or _is_not_case()
	btn_probe.disabled = controls_locked
	btn_hint.disabled = controls_locked or analyze_on_cooldown
	btn_verdict.visible = not is_case_complete and not is_safe_mode
	btn_verdict.disabled = controls_locked or not has_guess or not has_min_facts or verdict_on_cooldown
	btn_next.visible = is_case_complete or is_safe_mode

	_set_gate_buttons_enabled(not controls_locked)

	if step == UiStep.SET_INPUTS:
		target_label.text = _tr("logic.a.ui.target_set_inputs", "ЦЕЛЬ: выставьте входы и запишите первый факт")
	elif step == UiStep.GATHER_FACTS:
		if has_min_facts:
			target_label.text = _tr("logic.a.ui.target_ready_verdict", "ЦЕЛЬ: фактов достаточно, выберите гипотезу и вынесите вердикт")
		else:
			target_label.text = _tr("logic.a.ui.target_collect", "ЦЕЛЬ: соберите ещё факты и выберите гипотезу")
	elif step == UiStep.CHOOSE_HYPOTHESIS:
		if has_min_facts:
			target_label.text = _tr("logic.a.ui.target_verdict", "ЦЕЛЬ: гипотеза выбрана, можно выносить вердикт")
		else:
			target_label.text = _tr("logic.a.ui.target_collect_more", "ЦЕЛЬ: гипотеза есть, но нужно больше фактов")
	elif step == UiStep.CASE_DONE:
		target_label.text = _tr("logic.a.ui.target_done", "КЕЙС ЗАКРЫТ. Переходите дальше")
	else:
		target_label.text = _tr("logic.a.ui.target_safe", "КЕЙС ЗАВЕРШЁН В SAFE MODE")

	_update_panel_accents(step)
	_update_gate_button_visuals(step)
	_update_action_button_visuals(step, has_min_facts)

func _update_panel_accents(step: int) -> void:
	_set_panel_tint(input_a_frame, COLOR_STATE_ACTIVE if step == UiStep.SET_INPUTS else COLOR_STATE_LOCKED)
	if _is_not_case():
		_set_panel_tint(input_b_frame, COLOR_STATE_LOCKED)
	else:
		_set_panel_tint(input_b_frame, COLOR_STATE_ACTIVE if step == UiStep.SET_INPUTS else COLOR_STATE_LOCKED)

	if selected_gate_guess.is_empty():
		_set_panel_tint(gate_slot_frame, COLOR_STATE_ACTIVE if step == UiStep.CHOOSE_HYPOTHESIS else COLOR_STATE_LOCKED)
	else:
		_set_panel_tint(gate_slot_frame, COLOR_STATE_FILLED)

	if not has_observation:
		_set_panel_tint(output_slot_frame, COLOR_STATE_LOCKED)
	elif selected_gate_guess.is_empty():
		_set_panel_tint(output_slot_frame, COLOR_STATE_FILLED)
	else:
		var model_out := _calculate_gate_output(input_a, input_b, selected_gate_guess)
		_set_panel_tint(output_slot_frame, COLOR_STATE_SUCCESS if model_out == observed_output else COLOR_STATE_ERROR)

	_set_panel_tint(inventory_frame, COLOR_STATE_ACTIVE if step in [UiStep.GATHER_FACTS, UiStep.CHOOSE_HYPOTHESIS] else COLOR_STATE_LOCKED)

func _set_panel_tint(panel: PanelContainer, color: Color) -> void:
	panel.modulate = Color(1.0, 1.0, 1.0, 1.0)
	panel.add_theme_color_override("font_color", color)

func _update_gate_button_visuals(step: int) -> void:
	for gate_id in gate_buttons.keys():
		var btn: Button = gate_buttons[gate_id]
		if btn.disabled:
			btn.modulate = Color(0.62, 0.62, 0.62, 1.0)
			continue
		if selected_gate_guess == gate_id:
			btn.modulate = Color(1.0, 0.88, 0.72, 1.0)
		else:
			btn.modulate = Color(0.88, 0.88, 0.90, 1.0) if step in [UiStep.GATHER_FACTS, UiStep.CHOOSE_HYPOTHESIS] else Color(0.74, 0.74, 0.76, 1.0)

func _update_action_button_visuals(step: int, has_min_facts: bool) -> void:
	btn_probe.modulate = Color(1.0, 0.95, 0.80, 1.0) if step in [UiStep.SET_INPUTS, UiStep.GATHER_FACTS] and not btn_probe.disabled else Color(0.8, 0.8, 0.82, 1.0)
	btn_verdict.modulate = Color(1.0, 0.90, 0.78, 1.0) if has_min_facts and not btn_verdict.disabled else Color(0.78, 0.78, 0.80, 1.0)
	btn_hint.modulate = Color(0.80, 0.84, 0.88, 1.0) if not btn_hint.disabled else Color(0.7, 0.7, 0.72, 1.0)
	btn_next.modulate = Color(0.82, 0.98, 0.88, 1.0) if btn_next.visible else Color(0.75, 0.75, 0.75, 1.0)

func _hide_diagnostics() -> void:
	diagnostics_panel.visible = false
	diagnostics_blocker.visible = false
	diagnostics_action = DIAG_NONE

func _show_diagnostics(title: String, message: String, button_text: String, action: String) -> void:
	diagnostics_title.text = title
	diagnostics_text.text = message
	diagnostics_next_button.text = button_text
	diagnostics_action = action
	diagnostics_panel.visible = true
	diagnostics_blocker.visible = true
	diagnostics_next_button.grab_focus()

func _show_feedback(msg: String, col: Color) -> void:
	feedback_label.text = msg
	feedback_label.add_theme_color_override("font_color", col)
	feedback_label.visible = true

func _enter_safe_mode() -> void:
	is_safe_mode = true
	is_case_complete = true
	_set_gate_buttons_enabled(false)
	btn_hint.disabled = true
	btn_probe.disabled = true
	btn_verdict.disabled = true
	btn_next.visible = true
	_show_feedback(_tr("logic.a.ui.safe_feedback", "SAFE MODE АКТИВЕН: кейс завершён в диагностике"), Color(1.0, 0.78, 0.32))
	_show_diagnostics(
		_tr("logic.a.ui.safe_title", "SAFE MODE"),
		_tr("logic.a.ui.safe_continue", "Кейс завершён в диагностическом режиме. Нажмите, чтобы перейти дальше."),
		_tr("logic.a.ui.safe_continue_btn", "К СЛЕДУЮЩЕМУ КЕЙСУ"),
		DIAG_NEXT
	)
	_update_ui_state()

func _start_analyze_cooldown() -> void:
	if analyze_timer:
		analyze_timer.start(ANALYZE_COOLDOWN_SEC)
	_update_ui_state()
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

func _confidence_bucket_label(ratio: float) -> String:
	match _confidence_bucket(ratio):
		"HIGH":
			return _tr("logic.a.ui.conf_high", "высокая")
		"MID":
			return _tr("logic.a.ui.conf_mid", "средняя")
	return _tr("logic.a.ui.conf_low", "низкая")

func _total_unique_combinations() -> int:
	return 2 if _is_not_case() else 4

func _format_inputs_text(a_val: int, has_b: bool, b_val: int) -> String:
	var a_name := _case_text("a", "A")
	if has_b:
		var b_name := _case_text("b", "B")
		return "%s=%d, %s=%d" % [a_name, a_val, b_name, b_val]
	return "%s=%d" % [a_name, a_val]

func _build_contradiction_text(data: Dictionary) -> String:
	if data.is_empty():
		return ""
	var index_human := int(data.get("index", -1)) + 1
	var text := _format_inputs_text(int(data.get("a", 0)), bool(data.get("has_b", false)), int(data.get("b", -1)))
	return "#%d: %s -> F_box=%d, F_model=%d" % [
		index_human,
		text,
		int(data.get("f_box", 0)),
		int(data.get("f_model", 0))
	]

func _first_contradiction_for_gate(gate_id: String) -> Dictionary:
	for i in range(seen_trace_entries.size()):
		var entry := seen_trace_entries[i]
		var a_bool := int(entry.get("a", 0)) == 1
		var has_b := bool(entry.get("has_b", false))
		var b_raw := int(entry.get("b", -1))
		var b_bool := (b_raw == 1) if has_b else false
		var f_box := int(entry.get("f_box", 0))
		var f_model := 1 if _calculate_gate_output(a_bool, b_bool, gate_id) else 0
		if f_model != f_box:
			var result := {
				"index": i,
				"a": int(entry.get("a", 0)),
				"has_b": has_b,
				"b": b_raw,
				"f_box": f_box,
				"f_model": f_model
			}
			result["text"] = _build_contradiction_text(result)
			return result
	return {}

func _update_terminal_text() -> void:
	var lines: Array[String] = []
	var confidence_ratio := _confidence_ratio()
	var confidence_text := _confidence_bucket_label(confidence_ratio)

	lines.append("[b]%s[/b]" % _tr("logic.a.ui.briefing_title", "БРИФИНГ"))
	lines.append(_case_text("witness", ""))
	lines.append("")
	lines.append("[b]%s[/b]" % _tr("logic.a.ui.steps_title", "ШАГИ"))
	lines.append(_tr("logic.a.ui.step1", "1) Настройте входы и нажмите ПРОГОН."))
	lines.append(_tr("logic.a.ui.step2", "2) Соберите факты по разным комбинациям."))
	lines.append(_tr("logic.a.ui.step3", "3) Выберите гипотезу вентиля и вынесите вердикт."))
	lines.append("")

	lines.append("[b]%s[/b]" % _tr("logic.a.ui.log_title", "ЖУРНАЛ НАБЛЮДЕНИЙ"))
	if seen_trace_entries.is_empty():
		lines.append(_tr("logic.a.ui.log_empty", "- Нет фактов. Сделайте первый прогон."))
	else:
		for entry in seen_trace_entries:
			var idx := int(entry.get("index", 0)) + 1
			var a_val := int(entry.get("a", 0))
			var has_b := bool(entry.get("has_b", false))
			var b_val := int(entry.get("b", -1))
			var f_box := int(entry.get("f_box", 0))
			lines.append("#%d: %s -> F_box=%d" % [idx, _format_inputs_text(a_val, has_b, b_val), f_box])
	lines.append("")

	lines.append("[b]%s[/b]" % _tr("logic.a.ui.analysis_title", "АНАЛИЗ"))
	lines.append(_tr("logic.a.ui.hypothesis_line", "Гипотеза: {gate}", {"gate": _gate_label(selected_gate_guess) if not selected_gate_guess.is_empty() else _tr("logic.a.ui.hypothesis_empty", "не выбрана")}))
	lines.append(_tr("logic.a.ui.confidence_line", "Уверенность: {bucket} ({seen}/{total})", {
		"bucket": confidence_text,
		"seen": seen_combinations.size(),
		"total": _total_unique_combinations()
	}))

	if contradiction_index >= 0 and contradiction_index < seen_trace_entries.size() and not selected_gate_guess.is_empty():
		var contradiction := _first_contradiction_for_gate(selected_gate_guess)
		if not contradiction.is_empty():
			lines.append("[color=#ff7a7a]%s[/color]" % _tr("logic.a.ui.contradiction", "ПРОТИВОРЕЧИЕ"))
			lines.append("[color=#ff7a7a]%s[/color]" % str(contradiction.get("text", "")))

	terminal_text.text = "\n".join(lines)
	terminal_text.scroll_to_line(0)

func _update_stats_ui() -> void:
	var case_id := str(current_case.get("id", "A_00"))
	var confidence_ratio := _confidence_ratio()
	session_label.text = _tr("logic.a.ui.session", "СЕССИЯ: {cur}/{total} | КЕЙС {case}", {
		"cur": current_case_index + 1,
		"total": CASES.size(),
		"case": case_id
	})
	stats_label.text = _tr(
		"logic.a.ui.stats",
		"ПОПЫТКИ: {attempts}/{max} | ФАКТЫ: {facts}/{total_facts} | УВЕРЕННОСТЬ: {conf} ({facts}/{total_facts}) | АНАЛИЗ: {analyze} | СТАБИЛЬНОСТЬ: {stability}%",
		{
			"attempts": case_attempts,
			"max": MAX_ATTEMPTS,
			"facts": seen_combinations.size(),
			"total_facts": _total_unique_combinations(),
			"conf": _confidence_bucket_label(confidence_ratio),
			"analyze": analyze_count,
			"stability": int(GlobalMetrics.stability)
		}
	)
	_update_target_and_bars()
	_update_ui_state()

func _on_game_over() -> void:
	if is_safe_mode or is_case_complete:
		return
	GlobalMetrics.add_mistake("Диагностический провал логического кейса: case=%s, selected_gate=%s, attempts=%d, seen=%d, stability=%d" % [
		str(current_case.get("id", "LogicQuestA")),
		selected_gate_guess,
		case_attempts,
		seen_combinations.size(),
		int(GlobalMetrics.stability)
	])
	GlobalMetrics.finish_quest(str(current_case.get("id", "LogicQuestA")), 0, false)
	_enter_safe_mode()

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _show_finish_dialog() -> void:
	_show_diagnostics(
		_tr("logic.a.ui.finish_title", "СЛОЖНОСТЬ A ЗАВЕРШЕНА"),
		_tr("logic.a.ui.finish_text", "Все кейсы сложности A завершены. Возвратитесь в выбор квестов."),
		_tr("logic.a.ui.finish_btn", "К КВЕСТАМ"),
		DIAG_EXIT
	)

func _advance_case_or_exit() -> void:
	_hide_diagnostics()
	var next_idx := current_case_index + 1
	if next_idx < CASES.size():
		load_case(next_idx)
		return
	_show_finish_dialog()

func _on_next_button_pressed() -> void:
	_advance_case_or_exit()
func _on_hint_pressed() -> void:
	if is_safe_mode or is_case_complete:
		return
	_mark_first_action()
	if analyze_timer != null and not analyze_timer.is_stopped():
		_show_feedback(_tr("logic.a.ui.analyze_cooldown", "АНАЛИЗ НЕДОСТУПЕН: ПЕРЕГРЕВ {left}с", {"left": "%.1f" % analyze_timer.time_left}), Color(1.0, 0.78, 0.32))
		return

	analyze_count += 1
	hints_used += 1

	if seen_trace_entries.is_empty():
		_show_feedback(_tr("logic.a.ui.analyze_no_facts", "НЕТ ФАКТОВ ДЛЯ АНАЛИЗА"), Color(0.56, 0.78, 0.96))
	elif selected_gate_guess.is_empty():
		_show_feedback(_tr("logic.a.ui.analyze_no_hypothesis", "СНАЧАЛА ВЫБЕРИТЕ ГИПОТЕЗУ"), Color(0.56, 0.78, 0.96))
	else:
		var contradiction := _first_contradiction_for_gate(selected_gate_guess)
		if contradiction.is_empty():
			_show_feedback(_tr("logic.a.ui.analyze_no_contradiction", "ПРОТИВОРЕЧИЙ НЕ НАЙДЕНО"), Color(0.45, 0.92, 0.62))
		else:
			contradiction_index = int(contradiction.get("index", -1))
			_show_feedback(_tr("logic.a.ui.analyze_counterexample", "КОНТРПРИМЕР: {line}", {"line": str(contradiction.get("text", ""))}), Color(1.0, 0.78, 0.32))

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

func _on_verdict_pressed() -> void:
	if is_safe_mode or is_case_complete:
		return
	if btn_verdict.disabled:
		return
	_mark_first_action()
	verdict_count += 1

	var current_time: float = Time.get_ticks_msec() / 1000.0
	if current_time - last_verdict_time < 0.8:
		_show_feedback(_tr("logic.a.ui.verdict_rate", "Подождите перед следующим вердиктом."), Color(1.0, 0.62, 0.28))
		GlobalMetrics.add_mistake("Слишком быстрый повтор вердикта: case=%s, selected_gate=%s, delta=%.2f" % [
			str(current_case.get("id", "LogicQuestA")),
			selected_gate_guess,
			current_time - last_verdict_time
		])
		_lock_verdict(3.0)
		_register_trial("RATE_LIMITED", false)
		return
	last_verdict_time = current_time

	if selected_gate_guess.is_empty():
		_show_feedback(_tr("logic.a.ui.verdict_need_gate", "СНАЧАЛА ВЫБЕРИТЕ ГИПОТЕЗУ"), Color(1.0, 0.86, 0.32))
		GlobalMetrics.add_mistake("Вердикт без выбора гипотезы: case=%s, seen=%d" % [
			str(current_case.get("id", "LogicQuestA")),
			seen_combinations.size()
		])
		_register_trial("EMPTY_SELECTION", false)
		return

	var min_seen: int = int(current_case.get("min_seen", 2))
	if seen_combinations.size() < min_seen:
		_show_feedback(_tr("logic.a.ui.verdict_insufficient", "НЕДОСТАТОЧНО ФАКТОВ ({seen}/{required})", {
			"seen": seen_combinations.size(),
			"required": min_seen
		}), Color(1.0, 0.5, 0.0))
		GlobalMetrics.add_mistake("Недостаточно фактов для вердикта: case=%s, selected_gate=%s, seen=%d, required=%d" % [
			str(current_case.get("id", "LogicQuestA")),
			selected_gate_guess,
			seen_combinations.size(),
			min_seen
		])
		_apply_penalty(2.0)
		_lock_verdict(VERDICT_LOCK_TIME)
		_register_trial("INSUFFICIENT_DATA", false)
		return

	contradiction_index = -1
	if selected_gate_guess == str(current_case.get("gate", "")):
		var confidence_ratio := _confidence_ratio()
		var confidence_bucket := _confidence_bucket_label(confidence_ratio)
		if seen_combinations.size() <= 2:
			GlobalMetrics.stability = min(100.0, GlobalMetrics.stability + LOW_CONFIDENCE_BONUS)
			GlobalMetrics.stability_changed.emit(GlobalMetrics.stability, LOW_CONFIDENCE_BONUS)
			_show_feedback(_tr("logic.a.ui.verdict_success_fast", "ВЕРДИКТ ПРИНЯТ (+{bonus}). Уверенность: {conf}", {
				"bonus": int(LOW_CONFIDENCE_BONUS),
				"conf": confidence_bucket
			}), Color(0.45, 0.92, 0.62))
		else:
			_show_feedback(_tr("logic.a.ui.verdict_success", "ВЕРДИКТ ПРИНЯТ. Уверенность: {conf}", {"conf": confidence_bucket}), Color(0.45, 0.92, 0.62))

		_register_trial("SUCCESS", true)
		GlobalMetrics.finish_quest(str(current_case.get("id", "LogicQuestA")), 100, true)
		is_case_complete = true
		btn_next.visible = true
		_disable_controls()
	else:
		case_attempts += 1
		_update_stats_ui()

		var penalty := 10.0
		if case_attempts == 2:
			penalty = 15.0
		elif case_attempts >= 3:
			penalty = 25.0

		_apply_penalty(penalty)
		var contradiction := _first_contradiction_for_gate(selected_gate_guess)
		var mistake_detail := "Неверная гипотеза: case=%s, selected=%s, correct=%s, attempts=%d, penalty=%d" % [
			str(current_case.get("id", "LogicQuestA")),
			selected_gate_guess,
			str(current_case.get("gate", "")),
			case_attempts,
			int(penalty)
		]
		if not contradiction.is_empty():
			contradiction_index = int(contradiction.get("index", -1))
			var details := str(contradiction.get("text", ""))
			_show_feedback(_tr("logic.a.ui.verdict_counterexample", "ПРОТИВОРЕЧИЕ: {details} (-{penalty})", {
				"details": details,
				"penalty": int(penalty)
			}), Color(1.0, 0.35, 0.32))
			mistake_detail += ", contradiction=%s" % details
		else:
			_show_feedback(_tr("logic.a.ui.verdict_denied", "ВЕРДИКТ ОТКЛОНЁН (-{penalty})", {"penalty": int(penalty)}), Color(1.0, 0.35, 0.32))
		GlobalMetrics.add_mistake(mistake_detail)

		var verdict_code := "WRONG_GATE"
		if case_attempts >= MAX_ATTEMPTS:
			GlobalMetrics.finish_quest(str(current_case.get("id", "LogicQuestA")), 0, false)
			_enter_safe_mode()
			verdict_code = "SAFE_MODE_TRIGGERED"
		_register_trial(verdict_code, false)

	_update_circuit()

func _lock_verdict(duration: float) -> void:
	if is_safe_mode or is_case_complete:
		return
	if verdict_timer != null:
		verdict_timer.start(duration)
	_update_ui_state()

func _apply_penalty(amount: float) -> void:
	GlobalMetrics.stability = max(0.0, GlobalMetrics.stability - amount)
	GlobalMetrics.stability_changed.emit(GlobalMetrics.stability, -amount)

func _on_diagnostics_close_pressed() -> void:
	if diagnostics_action == DIAG_NEXT:
		_advance_case_or_exit()
		return
	if diagnostics_action == DIAG_EXIT:
		_hide_diagnostics()
		get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")
		return
	_hide_diagnostics()
