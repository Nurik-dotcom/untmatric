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

# Cases Data
const CASES = [
	{
		"id": "A1_01", "phase": PHASE_TRAINING, "gate": GATE_AND,
		"a_text": "КЛЮЧ", "b_text": "СТАРТ",
		"witness_text": "Машина заведется, если есть КЛЮЧ и нажата кнопка СТАРТ.",
		"min_seen": 2, "hints": ["Нужны оба условия.", "Это AND (И)."]
	},
	{
		"id": "A1_02", "phase": PHASE_TRAINING, "gate": GATE_OR,
		"a_text": "ДОЖДЬ", "b_text": "СНЕГ",
		"witness_text": "Вы промокнете, если идет ДОЖДЬ или СНЕГ (зонта нет).",
		"min_seen": 2, "hints": ["Достаточно одного условия.", "Это OR (ИЛИ)."]
	},
	{
		"id": "A1_03", "phase": PHASE_TRAINING, "gate": GATE_AND,
		"a_text": "ПАРОЛЬ", "b_text": "ТЕЛЕФОН",
		"witness_text": "Вход в почту разрешен, если введен ПАРОЛЬ и пройден ТЕЛЕФОН.",
		"min_seen": 2, "hints": ["Нужны оба условия.", "Это AND (И)."]
	},
	{
		"id": "A1_04", "phase": PHASE_TRAINING, "gate": GATE_OR,
		"a_text": "ВЫКЛ_1", "b_text": "ВЫКЛ_2",
		"witness_text": "Свет в коридоре горит, если включен ВЫКЛ_1 или ВЫКЛ_2.",
		"min_seen": 2, "hints": ["Достаточно одного выключателя.", "Это OR (ИЛИ)."]
	},
	{
		"id": "A1_05", "phase": PHASE_TRAINING, "gate": GATE_NOT,
		"a_text": "СИГНАЛ", "b_text": "---",
		"witness_text": "Детектор лжи инвертирует сигнал: если на входе НЕТ, на выходе ДА.",
		"min_seen": 2, "hints": ["Инверсия: 1->0, 0->1.", "Это NOT (НЕ)."]
	},
	{
		"id": "A2_01", "phase": PHASE_TRANSLATION, "gate": GATE_AND,
		"a_text": "A", "b_text": "B",
		"witness_text": "Логическое И обозначается символом &. Найдите его.",
		"min_seen": 2, "hints": ["& это И.", "Конъюнкция."]
	},
	{
		"id": "A2_02", "phase": PHASE_TRANSLATION, "gate": GATE_OR,
		"a_text": "A", "b_text": "B",
		"witness_text": "Логическое ИЛИ обозначается как OR. Найдите его.",
		"min_seen": 2, "hints": ["OR это ИЛИ.", "Дизъюнкция."]
	},
	{
		"id": "A2_03", "phase": PHASE_TRANSLATION, "gate": GATE_NOT,
		"a_text": "A", "b_text": "---",
		"witness_text": "Инверсия обозначается как NOT. Найдите его.",
		"min_seen": 2, "hints": ["NOT это НЕ.", "Отрицание."]
	},
	{
		"id": "A2_04", "phase": PHASE_TRANSLATION, "gate": GATE_XOR,
		"a_text": "A", "b_text": "B",
		"witness_text": "Исключающее ИЛИ обозначается как XOR. Найдите его.",
		"min_seen": 2, "hints": ["XOR это XOR.", "Истина при разных входах."]
	},
	{
		"id": "A2_05", "phase": PHASE_TRANSLATION, "gate": GATE_NOR,
		"a_text": "A", "b_text": "B",
		"witness_text": "Стрелка Пирса (ИЛИ-НЕ) обозначается как NOR.",
		"min_seen": 2, "hints": ["Это инверсия ИЛИ.", "NOR."]
	},
	{
		"id": "A3_01", "phase": PHASE_DETECTION, "gate": GATE_NOR,
		"a_text": "КОД_1", "b_text": "КОД_2",
		"witness_text": "Сейф открылся (1), когда оба кода были неверны (0,0).",
		"min_seen": 3, "hints": ["Выход 1 только при 0,0.", "Это NOR."]
	},
	{
		"id": "A3_02", "phase": PHASE_DETECTION, "gate": GATE_XOR,
		"a_text": "ДАТЧИК_1", "b_text": "ДАТЧИК_2",
		"witness_text": "Сигнализация молчит (0), только когда сигналы совпадают.",
		"min_seen": 3, "hints": ["Истина при разных входах.", "Это XOR."]
	},
	{
		"id": "A3_03", "phase": PHASE_DETECTION, "gate": GATE_NOR,
		"a_text": "РЫЧАГ_1", "b_text": "РЫЧАГ_2",
		"witness_text": "Замок заклинит (0), если нажать хотя бы один рычаг.",
		"min_seen": 3, "hints": ["Выход 1 только при 0,0.", "Это NOR."]
	},
	{
		"id": "A3_04", "phase": PHASE_DETECTION, "gate": GATE_XOR,
		"a_text": "ЧАСТОТА_1", "b_text": "ЧАСТОТА_2",
		"witness_text": "Перехват данных (1) идет только при разных частотах.",
		"min_seen": 3, "hints": ["Разные входы дают 1.", "Это XOR."]
	},
	{
		"id": "A3_05", "phase": PHASE_DETECTION, "gate": GATE_NAND,
		"a_text": "X", "b_text": "Y",
		"witness_text": "Нужен вентиль, дающий ЛОЖЬ только при двух ИСТИНАХ.",
		"min_seen": 3, "hints": ["0 только при 1,1.", "Это NAND."]
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
@onready var output_slot_frame: PanelContainer = $SafeArea/MainLayout/ContentHSplit/RightPane/InteractionRow/OutputSlot
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
var contradiction_key: String = ""
var mastery_flag: bool = false
var mastery_checks: int = 0
var is_landscape_layout: bool = false

const COLOR_OUTPUT_ON = Color(0.95, 0.95, 0.90, 1.0)
const COLOR_OUTPUT_OFF = Color(0.55, 0.55, 0.55, 1.0)
const COLOR_OUTPUT_MODEL = Color(0.56, 0.78, 0.96, 1.0)
const COLOR_MATCH = Color(0.45, 0.92, 0.62, 1.0)
const COLOR_MISMATCH = Color(1.0, 0.35, 0.32, 1.0)
const ANALYZE_COOLDOWN_SEC: float = 3.0
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

	verdict_timer = Timer.new()
	verdict_timer.one_shot = true
	verdict_timer.timeout.connect(_on_verdict_unlock)
	add_child(verdict_timer)

	analyze_timer = Timer.new()
	analyze_timer.one_shot = true
	analyze_timer.timeout.connect(_on_analyze_unlock)
	add_child(analyze_timer)

	_apply_responsive_layout()
	load_case(0)

func _exit_tree() -> void:
	if GlobalMetrics.stability_changed.is_connected(_update_stability_ui):
		GlobalMetrics.stability_changed.disconnect(_update_stability_ui)
	if GlobalMetrics.game_over.is_connected(_on_game_over):
		GlobalMetrics.game_over.disconnect(_on_game_over)
	if get_viewport() and get_viewport().size_changed.is_connected(_on_viewport_resized):
		get_viewport().size_changed.disconnect(_on_viewport_resized)

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
		gate_btn.text = "%s\n%s" % [_gate_symbol(gate_id), gate_id]
		var callback := Callable(self, "_on_gate_button_toggled").bind(gate_id)
		if not gate_btn.toggled.is_connected(callback):
			gate_btn.toggled.connect(callback)
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
	highlighted_step = -1
	contradiction_index = -1
	contradiction_key = ""
	mastery_flag = false
	mastery_checks = 0
	if analyze_timer != null:
		analyze_timer.stop()

	clue_title_label.text = "ДЕТЕКТОР ЛЖИ A-01"
	_update_stats_ui()
	_hide_diagnostics()

	input_a_btn.button_pressed = false
	input_b_btn.button_pressed = false
	input_a_btn.disabled = false
	input_b_btn.disabled = false
	btn_hint.disabled = false
	btn_hint.text = "АНАЛИЗ"
	btn_probe.disabled = false
	btn_verdict.visible = true
	btn_verdict.disabled = true
	btn_next.visible = false
	feedback_label.visible = false
	feedback_label.text = ""
	match_label.text = "СОВПАДЕНИЕ: --"
	match_label.add_theme_color_override("font_color", COLOR_OUTPUT_OFF)

	if current_case.gate == GATE_NOT:
		input_b_frame.visible = false
		input_b_btn.disabled = true
	else:
		input_b_frame.visible = true
		input_b_btn.disabled = false

	_set_gate_buttons_enabled(false)
	_clear_gate_selection()
	_update_input_labels()
	_update_circuit()
	_update_ui_state()

func _update_input_labels() -> void:
	input_a_btn.text = "%s\n[%s]" % [str(current_case.get("a_text", "A")), "1" if input_a else "0"]
	if current_case.gate != GATE_NOT:
		input_b_btn.text = "%s\n[%s]" % [str(current_case.get("b_text", "B")), "1" if input_b else "0"]

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
	contradiction_key = ""

	var combo_key := _combo_key_for_inputs(input_a, input_b)
	if not seen_combinations.has(combo_key):
		seen_combinations[combo_key] = out_val
		seen_trace_entries.append({
			"a": 1 if input_a else 0,
			"b": -1 if current_case.gate == GATE_NOT else (1 if input_b else 0),
			"f": 1 if out_val else 0,
			"idx": seen_trace_entries.size() + 1
		})
		_show_feedback("ПРОГОН ЗАПИСАН: факт #%d" % seen_trace_entries.size(), Color(0.56, 0.78, 0.96))
	else:
		_show_feedback("ПРОГОН: комбинация уже в журнале.", Color(0.66, 0.66, 0.66))

	_update_stats_ui()
	_update_circuit()
	_pulse_output_slot()
	_play_click()

func _combo_key_for_inputs(a_val: bool, b_val: bool) -> String:
	if current_case.gate == GATE_NOT:
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
			_update_circuit()
		return

	_mark_first_action()
	for key in gate_buttons.keys():
		if key != gate_id:
			var btn_other: Button = gate_buttons[key]
			btn_other.set_pressed_no_signal(false)

	selected_gate_guess = gate_id
	_play_click()
	_update_gate_slot_label()
	if not _has_min_facts():
		_show_feedback(
			"Гипотеза выбрана: %s. Для вердикта нужен ещё %d прогон(а)." % [
				_gate_title(gate_id),
				_facts_remaining()
			],
			Color(0.56, 0.78, 0.96)
		)
	_update_circuit()

func _update_circuit() -> void:
	if has_observation:
		output_value_label.text = "F (ПРИБОР) = %s" % ("1" if observed_output else "0")
		output_value_label.add_theme_color_override("font_color", COLOR_OUTPUT_ON if observed_output else COLOR_OUTPUT_OFF)
	else:
		output_value_label.text = "F (ПРИБОР) = ?"
		output_value_label.add_theme_color_override("font_color", COLOR_OUTPUT_OFF)

	if selected_gate_guess.is_empty():
		model_value_label.text = "F (МОДЕЛЬ) = ?"
		model_value_label.add_theme_color_override("font_color", COLOR_OUTPUT_OFF)
		match_label.text = "СОВПАДЕНИЕ: --"
		match_label.add_theme_color_override("font_color", COLOR_OUTPUT_OFF)
	else:
		var model_out := _calculate_gate_output(input_a, input_b, selected_gate_guess)
		model_value_label.text = "F (МОДЕЛЬ) = %s" % ("1" if model_out else "0")
		model_value_label.add_theme_color_override("font_color", COLOR_OUTPUT_MODEL if model_out else COLOR_OUTPUT_OFF)
		if has_observation:
			var is_match := model_out == observed_output
			match_label.text = "СОВПАДЕНИЕ: %s" % ("ДА" if is_match else "НЕТ")
			match_label.add_theme_color_override("font_color", COLOR_MATCH if is_match else COLOR_MISMATCH)
		else:
			match_label.text = "СОВПАДЕНИЕ: --"
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

func _update_terminal_text(out_val: bool) -> void:
	var lines: Array[String] = []
	var a_label := str(current_case.get("a_text", "A"))
	var b_label := str(current_case.get("b_text", "B"))
	var min_seen := _min_facts_required()
	var facts_seen := _facts_seen()
	var facts_remaining := _facts_remaining()
	var confidence_ratio := _confidence_ratio()
	var confidence_bucket := _confidence_bucket(confidence_ratio)

	lines.append("[b]БРИФИНГ[/b]")
	lines.append(str(current_case.get("witness_text", "")))
	lines.append("")
	lines.append("[b]ШАГИ[/b]")
	lines.append("1) Выставьте входы и нажмите ПРОГОН.")
	lines.append("2) Соберите факты: %d/%d. До вердикта осталось: %d." % [facts_seen, min_seen, facts_remaining])
	lines.append("3) Выберите вентиль и нажмите ВЕРДИКТ.")
	lines.append("")
	lines.append("Уверенность: %s (%d/%d)" % [
		confidence_bucket,
		facts_seen,
		_total_unique_combinations()
	])
	lines.append("")
	if facts_seen < min_seen:
		lines.append("Для вердикта нужно минимум %d проверок. Сейчас собрано %d." % [min_seen, facts_seen])
		lines.append("")
	lines.append("[b]ЖУРНАЛ ПРОВЕРОК[/b]")

	if seen_trace_entries.is_empty():
		lines.append("• ЖУРНАЛ ПУСТ")
	else:
		for i in range(seen_trace_entries.size()):
			var entry: Dictionary = seen_trace_entries[i]
			var row := ""
			if int(entry.get("b", -1)) < 0:
				row = "• #%d: %s=%d ⇒ F=%d" % [
					int(entry.get("idx", i + 1)),
					a_label,
					int(entry.get("a", 0)),
					int(entry.get("f", 0))
				]
			else:
				row = "• #%d: %s=%d, %s=%d ⇒ F=%d" % [
					int(entry.get("idx", i + 1)),
					a_label,
					int(entry.get("a", 0)),
					b_label,
					int(entry.get("b", 0)),
					int(entry.get("f", 0))
				]
			if i == contradiction_index:
				row = "[color=#ff7a7a]%s  [ПРОТИВОРЕЧИЕ][/color]" % row
			elif i == seen_trace_entries.size() - 1:
				row = "[color=#f4f2e6]%s[/color]" % row
			lines.append(row)

	lines.append("")
	lines.append("[b]ПОКАЗАНИЯ ПРИБОРА[/b]")
	if has_observation:
		lines.append("F (ПРИБОР) = %s" % ("1" if out_val else "0"))
	else:
		lines.append("F (ПРИБОР) = ? (нажмите ПРОГОН)")
	if selected_gate_guess.is_empty():
		lines.append("F (МОДЕЛЬ) = ?")
		lines.append("СОВПАДЕНИЕ: --")
	else:
		var model_out := _calculate_gate_output(input_a, input_b, selected_gate_guess)
		lines.append("F (МОДЕЛЬ) = %s" % ("1" if model_out else "0"))
		if has_observation:
			lines.append("СОВПАДЕНИЕ: %s" % ("ДА" if model_out == observed_output else "НЕТ"))
		else:
			lines.append("СОВПАДЕНИЕ: --")

	terminal_text.text = "\n".join(lines)

func _update_gate_slot_label() -> void:
	if selected_gate_guess.is_empty():
		gate_label.text = "ВЕНТИЛЬ: ?"
		return
	gate_label.text = "ВЕНТИЛЬ: %s" % _gate_title(selected_gate_guess)

func _gate_symbol(gate_id: String) -> String:
	match gate_id:
		GATE_AND:
			return "И"
		GATE_OR:
			return "ИЛИ"
		GATE_NOT:
			return "НЕ"
		GATE_XOR:
			return "ИСКЛ-ИЛИ"
		GATE_NAND:
			return "И-НЕ"
		GATE_NOR:
			return "ИЛИ-НЕ"
		_:
			return "?"

func _gate_title(gate_id: String) -> String:
	match gate_id:
		GATE_AND:
			return "И (AND)"
		GATE_OR:
			return "ИЛИ (OR)"
		GATE_NOT:
			return "НЕ (NOT)"
		GATE_XOR:
			return "ИСКЛ-ИЛИ (XOR)"
		GATE_NAND:
			return "И-НЕ (NAND)"
		GATE_NOR:
			return "ИЛИ-НЕ (NOR)"
		_:
			return "НЕИЗВЕСТНО"

func _set_gate_buttons_enabled(enabled: bool) -> void:
	for gate_id in gate_buttons.keys():
		var gate_btn: Button = gate_buttons[gate_id]
		gate_btn.disabled = not enabled

func _clear_gate_selection() -> void:
	for gate_id in gate_buttons.keys():
		var gate_btn: Button = gate_buttons[gate_id]
		gate_btn.set_pressed_no_signal(false)
	selected_gate_guess = ""
	_update_gate_slot_label()

func _select_gate_button(gate_id: String) -> void:
	_clear_gate_selection()
	if not gate_buttons.has(gate_id):
		return
	var gate_btn: Button = gate_buttons[gate_id]
	gate_btn.set_pressed_no_signal(true)
	selected_gate_guess = gate_id
	_update_gate_slot_label()
	_update_circuit()

func _facts_seen() -> int:
	return seen_combinations.size()

func _min_facts_required() -> int:
	return int(current_case.get("min_seen", 2))

func _facts_remaining() -> int:
	return maxi(0, _min_facts_required() - _facts_seen())

func _has_min_facts() -> bool:
	return _facts_seen() >= _min_facts_required()

func _total_unique_combinations() -> int:
	if str(current_case.get("gate", "")) == GATE_NOT:
		return 2
	return 4

func _confidence_ratio() -> float:
	return float(_facts_seen()) / float(maxi(1, _total_unique_combinations()))

func _confidence_bucket(ratio: float) -> String:
	if ratio < 0.34:
		return "LOW"
	if ratio < 0.67:
		return "MID"
	return "HIGH"

func _first_contradiction_for_gate(gate_id: String) -> Dictionary:
	for i in range(seen_trace_entries.size()):
		var entry: Dictionary = seen_trace_entries[i]
		var a_val := int(entry.get("a", 0)) == 1
		var b_raw := int(entry.get("b", -1))
		var b_val := b_raw == 1
		var expected := int(entry.get("f", 0)) == 1
		var predicted := _calculate_gate_output(a_val, b_val, gate_id)
		if predicted != expected:
			return {
				"index": i,
				"a": a_val,
				"b": b_raw,
				"expected": expected,
				"predicted": predicted
			}
	return {}

func _update_target_and_bars() -> void:
	var facts_progress := float(_facts_seen()) / float(maxi(1, _min_facts_required()))
	facts_bar.value = clampf(facts_progress * 100.0, 0.0, 100.0)
	energy_bar.value = clampf(GlobalMetrics.stability, 0.0, 100.0)
 
func _update_ui_state() -> void:
	var has_result := is_safe_mode or not btn_verdict.visible
	var facts_seen := _facts_seen()
	var min_seen := _min_facts_required()
	var facts_remaining := _facts_remaining()
	var has_first_probe := facts_seen >= 1
	var has_min_facts := _has_min_facts()
	var gate_ready := not selected_gate_guess.is_empty()
	var analyze_on_cooldown := analyze_timer != null and not analyze_timer.is_stopped()
	var verdict_locked := verdict_timer != null and not verdict_timer.is_stopped()

	btn_hint.text = "ПЕРЕГРЕВ..." if analyze_on_cooldown and not has_result else "АНАЛИЗ"
	btn_hint.disabled = has_result or analyze_on_cooldown

	if has_result:
		target_label.text = "ШАГ 3/3: анализ завершен, переходите далее"
		btn_verdict.disabled = true
		btn_probe.disabled = true
		_set_gate_buttons_enabled(false)
		_pulse_step(3)
		return

	btn_probe.disabled = false
	_set_gate_buttons_enabled(has_first_probe)
	btn_verdict.disabled = verdict_locked or not (has_min_facts and gate_ready)

	if not has_first_probe:
		target_label.text = "ШАГ 1/3: выставь входы и нажми ПРОГОН"
		_pulse_step(1)
	elif not has_min_facts:
		target_label.text = "ШАГ 2/3: данных мало — собрано %d/%d. Сделай ещё %d прогон(а)." % [
			facts_seen,
			min_seen,
			facts_remaining
		]
		_pulse_step(1)
	elif not gate_ready:
		target_label.text = "ШАГ 3/3: выбери вентиль"
		_pulse_step(2)
	else:
		target_label.text = "ШАГ 3/3: нажми ВЕРДИКТ"
		_pulse_step(3)

func _pulse_step(step: int) -> void:
	if highlighted_step == step:
		return
	highlighted_step = step
	input_a_frame.modulate = Color(1, 1, 1, 1)
	input_b_frame.modulate = Color(1, 1, 1, 1)
	gate_slot_frame.modulate = Color(1, 1, 1, 1)
	inventory_frame.modulate = Color(1, 1, 1, 1)
	btn_probe.modulate = Color(1, 1, 1, 1)
	btn_verdict.modulate = Color(1, 1, 1, 1)

	var target: CanvasItem = btn_probe
	if step == 2:
		target = inventory_frame
	elif step == 3:
		target = btn_verdict

	var tween := create_tween()
	tween.tween_property(target, "modulate", Color(1.08, 1.08, 1.04, 1.0), 0.18)
	tween.tween_property(target, "modulate", Color(1, 1, 1, 1), 0.22)

func _pulse_output_slot() -> void:
	output_slot_frame.modulate = Color(1, 1, 1, 1)
	var tween := create_tween()
	tween.tween_property(output_slot_frame, "modulate", Color(0.84, 1.14, 0.84, 1.0), 0.10)
	tween.tween_property(output_slot_frame, "modulate", Color(1, 1, 1, 1), 0.10)

func _format_fact_details(a_val: bool, b_raw: int) -> String:
	var details := "%s=%d" % [str(current_case.get("a_text", "A")), 1 if a_val else 0]
	if b_raw >= 0:
		details += ", %s=%d" % [str(current_case.get("b_text", "B")), b_raw]
	return details

func _contradiction_key_from_data(contradiction: Dictionary) -> String:
	if contradiction.is_empty():
		return ""
	var row_num := int(contradiction.get("index", -1)) + 1
	var a_val := 1 if bool(contradiction.get("a", false)) else 0
	var b_raw := int(contradiction.get("b", -1))
	if b_raw < 0:
		return "a=%d|row=%d" % [a_val, row_num]
	return "a=%d|b=%d|row=%d" % [a_val, b_raw, row_num]

func _on_verdict_pressed() -> void:
	if is_safe_mode:
		return
	if btn_verdict.disabled:
		return
	_mark_first_action()
	verdict_count += 1

	var current_time: float = Time.get_ticks_msec() / 1000.0
	if current_time - last_verdict_time < 0.8:
		_show_feedback("Подождите перед следующим вердиктом.", Color(1.0, 0.62, 0.28))
		_lock_verdict(3.0)
		_register_trial("RATE_LIMITED", false)
		return
	last_verdict_time = current_time

	if selected_gate_guess.is_empty():
		_show_feedback("Сначала выберите вентиль.", Color(1.0, 0.86, 0.32))
		_register_trial("WRONG", false, {"reason": "empty_selection"})
		return

	contradiction_index = -1
	contradiction_key = ""
	if selected_gate_guess == current_case.gate:
		mastery_checks = _facts_seen()
		mastery_flag = mastery_checks <= 2
		if mastery_flag:
			GlobalMetrics.stability = min(100.0, GlobalMetrics.stability + LOW_CONFIDENCE_BONUS)
			GlobalMetrics.stability_changed.emit(GlobalMetrics.stability, LOW_CONFIDENCE_BONUS)
			_show_feedback(
				"ДОСТУП РАЗРЕШЁН. МАСТЕРСТВО: %d проверки (+%d стабильности)." % [
					mastery_checks,
					int(LOW_CONFIDENCE_BONUS)
				],
				Color(0.45, 0.92, 0.62)
			)
		else:
			_show_feedback("ДОСТУП РАЗРЕШЁН.", Color(0.45, 0.92, 0.62))
		btn_verdict.visible = false
		btn_next.visible = true
		_disable_controls()
		_register_trial("SUCCESS", true)
	else:
		case_attempts += 1
		var attempted_gate := selected_gate_guess
		_update_stats_ui()

		var penalty := 10.0
		if case_attempts == 2:
			penalty = 15.0
		elif case_attempts >= 3:
			penalty = 25.0

		_apply_penalty(penalty)
		var contradiction := _first_contradiction_for_gate(selected_gate_guess)
		if not contradiction.is_empty():
			contradiction_index = int(contradiction.get("index", -1))
			contradiction_key = _contradiction_key_from_data(contradiction)
			var details := _format_fact_details(
				bool(contradiction.get("a", false)),
				int(contradiction.get("b", -1))
			)
			_show_feedback(
				"Вы выбрали %s, но при %s модель даёт %d, а прибор дал %d. ДОСТУП ЗАПРЕЩЁН (-%d)." % [
					_gate_title(selected_gate_guess),
					details,
					1 if bool(contradiction.get("predicted", false)) else 0,
					1 if bool(contradiction.get("expected", false)) else 0,
					int(penalty)
				],
				Color(1.0, 0.35, 0.32)
			)
		else:
			_show_feedback("ДОСТУП ЗАПРЕЩЁН (-%d)" % int(penalty), Color(1.0, 0.35, 0.32))
		var verdict_code := "WRONG"
		if case_attempts >= MAX_ATTEMPTS:
			_enter_safe_mode()
			verdict_code = "SAFE_MODE"
		_register_trial(verdict_code, false, {
			"selected_gate_guess": attempted_gate,
			"selected_gate_id": attempted_gate
		})

	_update_circuit()

func _lock_verdict(duration: float) -> void:
	if is_safe_mode:
		return
	btn_verdict.disabled = true
	verdict_timer.start(duration)

func _on_verdict_unlock() -> void:
	if is_safe_mode:
		return
	if GlobalMetrics.stability > 0.0 and btn_verdict.visible:
		_update_ui_state()

func _enter_safe_mode() -> void:
	is_safe_mode = true
	_disable_controls()
	btn_verdict.disabled = true
	btn_probe.disabled = true
	btn_next.visible = true

	_set_gate_buttons_enabled(false)
	_select_gate_button(str(current_case.get("gate", "")))

	var gate_title := _gate_title(str(current_case.get("gate", "")))
	var safe_msg := "БЕЗОПАСНЫЙ РЕЖИМ: включён автоподбор. Правильный вентиль %s." % gate_title
	_show_feedback(safe_msg, Color(1.0, 0.74, 0.32))
	_show_diagnostics("БЕЗОПАСНЫЙ РЕЖИМ", "%s\nИзучите журнал проверок и переходите далее." % safe_msg)
	_update_ui_state()

func _show_diagnostics(title: String, message: String) -> void:
	diagnostics_title.text = title
	diagnostics_text.text = message
	diagnostics_blocker.visible = true
	diagnostics_panel.visible = true
	diagnostics_next_button.grab_focus()

func _hide_diagnostics() -> void:
	diagnostics_blocker.visible = false
	diagnostics_panel.visible = false

func _on_diagnostics_close_pressed() -> void:
	_hide_diagnostics()

func _start_analyze_cooldown() -> void:
	if analyze_timer == null:
		return
	btn_hint.disabled = true
	btn_hint.text = "ПЕРЕГРЕВ..."
	analyze_timer.start(ANALYZE_COOLDOWN_SEC)

func _on_analyze_unlock() -> void:
	if is_safe_mode or not btn_verdict.visible:
		return
	btn_hint.text = "АНАЛИЗ"
	btn_hint.disabled = false

func _show_feedback(msg: String, col: Color) -> void:
	feedback_label.text = msg
	feedback_label.add_theme_color_override("font_color", col)
	feedback_label.visible = true
	_update_ui_state()

func _apply_penalty(amount: float) -> void:
	GlobalMetrics.stability = max(0.0, GlobalMetrics.stability - amount)
	GlobalMetrics.stability_changed.emit(GlobalMetrics.stability, -amount)

func _update_stability_ui(val: float, _change: float) -> void:
	energy_bar.value = clampf(val, 0.0, 100.0)
	_update_stats_ui()
	_update_ui_state()

func _update_stats_ui() -> void:
	var case_id := str(current_case.get("id", "A_00"))
	var confidence_ratio := _confidence_ratio()
	session_label.text = "СЕССИЯ: %02d/%02d | КЕЙС %s" % [current_case_index + 1, CASES.size(), case_id]
	stats_label.text = "ПОП: %d/%d | ФАКТЫ: %d/%d | УВЕР: %s | АНАЛИЗ: %d | СТАБ: %d%%" % [
		case_attempts,
		MAX_ATTEMPTS,
		_facts_seen(),
		_total_unique_combinations(),
		_confidence_bucket(confidence_ratio),
		analyze_count,
		int(GlobalMetrics.stability)
	]
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
		_show_feedback("АНАЛИЗ: ПЕРЕГРЕВ... %.1f с" % analyze_timer.time_left, Color(1.0, 0.78, 0.32))
		return

	analyze_count += 1
	hints_used += 1

	if seen_trace_entries.is_empty():
		_show_feedback("АНАЛИЗ: сначала снимите показания через ПРОГОН.", Color(0.56, 0.78, 0.96))
	elif selected_gate_guess.is_empty():
		_show_feedback("АНАЛИЗ: сначала выбери вентиль.", Color(0.56, 0.78, 0.96))
	elif not _has_min_facts():
		contradiction_key = ""
		_show_feedback(
			"АНАЛИЗ: данных недостаточно. Собрано %d/%d. Сделайте ещё %d прогон(а). Текущая гипотеза пока не опровергнута, но проверок ещё мало." % [
				_facts_seen(),
				_min_facts_required(),
				_facts_remaining()
			],
			Color(1.0, 0.78, 0.32)
		)
	else:
		var contradiction := _first_contradiction_for_gate(selected_gate_guess)
		if contradiction.is_empty():
			contradiction_key = ""
			_show_feedback("АНАЛИЗ: явных противоречий нет, модель согласуется с фактами.", Color(0.45, 0.92, 0.62))
		else:
			contradiction_index = int(contradiction.get("index", -1))
			contradiction_key = _contradiction_key_from_data(contradiction)
			var details := _format_fact_details(
				bool(contradiction.get("a", false)),
				int(contradiction.get("b", -1))
			)
			_show_feedback(
				"АНАЛИЗ: %s не сходится. При %s модель даёт %d, а прибор дал %d." % [
					_gate_title(selected_gate_guess),
					details,
					1 if bool(contradiction.get("predicted", false)) else 0,
					1 if bool(contradiction.get("expected", false)) else 0
				],
				Color(1.0, 0.78, 0.32)
			)

	_update_circuit()
	_start_analyze_cooldown()

func _mark_first_action() -> void:
	if first_action_ms < 0:
		first_action_ms = Time.get_ticks_msec() - start_time_msec

func _register_trial(verdict_code: String, is_correct: bool, extra: Dictionary = {}) -> void:
	var case_id := str(current_case.get("id", "A_00"))
	var payload := TrialV2.build("LOGIC_QUEST", "A", case_id, "GATE_IDENTIFY")
	var elapsed_ms: int = maxi(0, Time.get_ticks_msec() - start_time_msec)
	var current_phase := str(current_case.get("phase", PHASE_TRAINING))
	var min_seen := _min_facts_required()
	var facts_seen := _facts_seen()
	var recorded_mastery_checks := mastery_checks if mastery_checks > 0 else facts_seen
	payload["elapsed_ms"] = elapsed_ms
	payload["duration"] = float(elapsed_ms) / 1000.0
	payload["time_to_first_action_ms"] = first_action_ms if first_action_ms >= 0 else elapsed_ms
	payload["is_correct"] = is_correct
	payload["is_fit"] = is_correct
	payload["stability_delta"] = 0
	payload["case_id"] = case_id
	payload["phase"] = current_phase
	payload["verdict_code"] = verdict_code
	payload["min_seen"] = min_seen
	payload["facts_seen"] = facts_seen
	payload["unique_checks"] = facts_seen
	payload["selected_gate_guess"] = selected_gate_guess
	payload["correct_gate"] = str(current_case.get("gate", ""))
	payload["mastery_flag"] = mastery_flag
	payload["mastery_checks"] = recorded_mastery_checks
	payload["contradiction_key"] = contradiction_key
	payload["selected_gate_id"] = selected_gate_guess
	payload["correct_gate_id"] = str(current_case.get("gate", ""))
	payload["seen_combinations"] = facts_seen
	payload["hints_used"] = hints_used
	payload["analyze_count"] = analyze_count
	payload["attempts"] = case_attempts
	payload["verdict_count"] = verdict_count
	payload["confidence_ratio"] = _confidence_ratio()
	payload["observation_count"] = seen_trace_entries.size()
	payload["has_observation"] = has_observation
	for key in extra.keys():
		payload[key] = extra[key]
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
