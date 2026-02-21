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
		"witness_text": "Логическое ИЛИ обозначается символом ∨. Найдите его.",
		"min_seen": 2, "hints": ["∨ это ИЛИ.", "Дизъюнкция."]
	},
	{
		"id": "A2_03", "phase": PHASE_TRANSLATION, "gate": GATE_NOT,
		"a_text": "A", "b_text": "---",
		"witness_text": "Инверсия обозначается символом ¬. Найдите его.",
		"min_seen": 2, "hints": ["¬ это НЕ.", "Отрицание."]
	},
	{
		"id": "A2_04", "phase": PHASE_TRANSLATION, "gate": GATE_XOR,
		"a_text": "A", "b_text": "B",
		"witness_text": "Исключающее ИЛИ обозначается символом ⊕. Найдите его.",
		"min_seen": 2, "hints": ["⊕ это XOR.", "Истина при разных входах."]
	},
	{
		"id": "A2_05", "phase": PHASE_TRANSLATION, "gate": GATE_NOR,
		"a_text": "A", "b_text": "B",
		"witness_text": "Стрелка Пирса (ИЛИ-НЕ) обозначается символом ⊽.",
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
@onready var clue_title_label: Label = $MainLayout/Header/LblClueTitle
@onready var session_label: Label = $MainLayout/Header/LblSessionId
@onready var facts_bar: ProgressBar = $MainLayout/BarsRow/FactsBar
@onready var energy_bar: ProgressBar = $MainLayout/BarsRow/EnergyBar
@onready var target_label: Label = $MainLayout/TargetDisplay/LblTarget
@onready var terminal_text: RichTextLabel = $MainLayout/TerminalFrame/TerminalScroll/TerminalRichText
@onready var stats_label: Label = $MainLayout/StatusRow/StatsLabel
@onready var feedback_label: Label = $MainLayout/StatusRow/FeedbackLabel

@onready var input_a_frame: PanelContainer = $MainLayout/InteractionRow/InputAFrame
@onready var input_b_frame: PanelContainer = $MainLayout/InteractionRow/InputBFrame
@onready var input_a_btn: Button = $MainLayout/InteractionRow/InputAFrame/InputAVBox/InputA_Btn
@onready var input_b_btn: Button = $MainLayout/InteractionRow/InputBFrame/InputBVBox/InputB_Btn
@onready var gate_label: Label = $MainLayout/InteractionRow/GateSlot/GateVBox/GateLabel
@onready var output_value_label: Label = $MainLayout/InteractionRow/OutputSlot/OutputVBox/OutputValueLabel

@onready var gate_and_btn: Button = $MainLayout/InventoryFrame/InventoryMargin/InventoryScroll/GatesContainer/GateAndBtn
@onready var gate_or_btn: Button = $MainLayout/InventoryFrame/InventoryMargin/InventoryScroll/GatesContainer/GateOrBtn
@onready var gate_not_btn: Button = $MainLayout/InventoryFrame/InventoryMargin/InventoryScroll/GatesContainer/GateNotBtn
@onready var gate_xor_btn: Button = $MainLayout/InventoryFrame/InventoryMargin/InventoryScroll/GatesContainer/GateXorBtn
@onready var gate_nand_btn: Button = $MainLayout/InventoryFrame/InventoryMargin/InventoryScroll/GatesContainer/GateNandBtn
@onready var gate_nor_btn: Button = $MainLayout/InventoryFrame/InventoryMargin/InventoryScroll/GatesContainer/GateNorBtn

@onready var btn_hint: Button = $MainLayout/Actions/BtnHint
@onready var btn_verdict: Button = $MainLayout/Actions/BtnVerdict
@onready var btn_next: Button = $MainLayout/Actions/BtnNext
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

var seen_combinations: Dictionary = {}
var seen_trace_entries: Array[Dictionary] = []
var case_attempts: int = 0
var hints_used: int = 0
var start_time_msec: int = 0
var first_action_ms: int = -1
var verdict_count: int = 0

var last_verdict_time: float = 0.0
var verdict_timer: Timer = null
var is_safe_mode: bool = false
var gate_buttons: Dictionary = {}

const COLOR_OUTPUT_ON = Color(0.95, 0.95, 0.90, 1.0)
const COLOR_OUTPUT_OFF = Color(0.55, 0.55, 0.55, 1.0)

func _ready() -> void:
	_setup_gate_buttons()
	_update_stability_ui(GlobalMetrics.stability, 0)
	if not GlobalMetrics.stability_changed.is_connected(_update_stability_ui):
		GlobalMetrics.stability_changed.connect(_update_stability_ui)
	if not GlobalMetrics.game_over.is_connected(_on_game_over):
		GlobalMetrics.game_over.connect(_on_game_over)

	verdict_timer = Timer.new()
	verdict_timer.one_shot = true
	verdict_timer.timeout.connect(_on_verdict_unlock)
	add_child(verdict_timer)

	load_case(0)

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

func load_case(idx: int) -> void:
	if idx >= CASES.size():
		idx = 0

	current_case_index = idx
	current_case = CASES[idx]

	input_a = false
	input_b = false
	selected_gate_guess = ""
	seen_combinations.clear()
	seen_trace_entries.clear()
	case_attempts = 0
	hints_used = 0
	start_time_msec = Time.get_ticks_msec()
	first_action_ms = -1
	verdict_count = 0
	last_verdict_time = 0.0
	is_safe_mode = false

	clue_title_label.text = "ДЕТЕКТОР ЛЖИ A-01"
	_update_stats_ui()
	_hide_diagnostics()

	input_a_btn.button_pressed = false
	input_b_btn.button_pressed = false
	input_a_btn.disabled = false
	input_b_btn.disabled = false
	btn_hint.disabled = false
	btn_verdict.visible = true
	btn_verdict.disabled = false
	btn_next.visible = false
	feedback_label.visible = false
	feedback_label.text = ""

	if current_case.gate == GATE_NOT:
		input_b_frame.visible = false
	else:
		input_b_frame.visible = true

	_set_gate_buttons_enabled(true)
	_clear_gate_selection()
	_update_input_labels()
	_update_circuit()

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

func _on_gate_button_toggled(gate_id: String, pressed: bool) -> void:
	if is_safe_mode:
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
	var out_val := _calculate_gate_output(input_a, input_b, str(current_case.get("gate", "")))
	output_value_label.text = "F = %s" % ("1" if out_val else "0")
	output_value_label.add_theme_color_override("font_color", COLOR_OUTPUT_ON if out_val else COLOR_OUTPUT_OFF)

	var key := ""
	if current_case.gate == GATE_NOT:
		key = "A=%d" % [1 if input_a else 0]
	else:
		key = "A=%d B=%d" % [1 if input_a else 0, 1 if input_b else 0]

	if not seen_combinations.has(key):
		seen_combinations[key] = out_val
		seen_trace_entries.append({
			"a": 1 if input_a else 0,
			"b": -1 if current_case.gate == GATE_NOT else (1 if input_b else 0),
			"f": 1 if out_val else 0
		})
		_update_stats_ui()

	_update_target_and_bars()
	_update_terminal_text(out_val)

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
	lines.append("[b]БРИФИНГ[/b]")
	lines.append(str(current_case.get("witness_text", "")))
	lines.append("")
	lines.append("[b]FACTS LOG[/b]")

	if seen_trace_entries.is_empty():
		lines.append("• ЖУРНАЛ ПУСТ")
	else:
		for i in range(seen_trace_entries.size()):
			var entry: Dictionary = seen_trace_entries[i]
			var row := ""
			if int(entry.get("b", -1)) < 0:
				row = "• KEY=%d  =>  F=%d" % [int(entry.get("a", 0)), int(entry.get("f", 0))]
			else:
				row = "• KEY=%d  BTN=%d  =>  F=%d" % [int(entry.get("a", 0)), int(entry.get("b", 0)), int(entry.get("f", 0))]
			if i == seen_trace_entries.size() - 1:
				row = "[color=#f4f2e6]> %s[/color]" % row
			lines.append(row)

	lines.append("")
	lines.append("[b]CURRENT OUTPUT[/b]")
	lines.append("F = %s" % ("1" if out_val else "0"))

	terminal_text.text = "\n".join(lines)

func _update_gate_slot_label() -> void:
	if selected_gate_guess.is_empty():
		gate_label.text = "GATE: ?"
		return
	gate_label.text = "GATE: %s (%s)" % [_gate_symbol(selected_gate_guess), _gate_title(selected_gate_guess)]

func _gate_symbol(gate_id: String) -> String:
	match gate_id:
		GATE_AND:
			return "∧"
		GATE_OR:
			return "∨"
		GATE_NOT:
			return "¬"
		GATE_XOR:
			return "⊕"
		GATE_NAND:
			return "⊼"
		GATE_NOR:
			return "⊽"
		_:
			return "?"

func _gate_title(gate_id: String) -> String:
	match gate_id:
		GATE_AND:
			return "AND"
		GATE_OR:
			return "OR"
		GATE_NOT:
			return "NOT"
		GATE_XOR:
			return "XOR"
		GATE_NAND:
			return "NAND"
		GATE_NOR:
			return "NOR"
		_:
			return "UNKNOWN"

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

func _update_target_and_bars() -> void:
	var min_seen: int = int(current_case.get("min_seen", 2))
	var seen_count: int = seen_combinations.size()
	var ratio := float(seen_count) / float(maxi(1, min_seen))
	facts_bar.value = clampf(ratio * 100.0, 0.0, 100.0)
	energy_bar.value = clampf(GlobalMetrics.stability, 0.0, 100.0)
	target_label.text = "ЦЕЛЬ: собрать факты %d/%d и вынести вердикт" % [mini(seen_count, min_seen), min_seen]

func _on_verdict_pressed() -> void:
	if is_safe_mode:
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
		_show_feedback("СНАЧАЛА ВЫБЕРИТЕ ВЕНТИЛЬ", Color(1.0, 0.86, 0.32))
		_register_trial("EMPTY_SELECTION", false)
		return

	var min_seen: int = int(current_case.get("min_seen", 2))
	if seen_combinations.size() < min_seen:
		_show_feedback("НЕДОСТАТОЧНО ДАННЫХ (%d/%d)" % [seen_combinations.size(), min_seen], Color(1.0, 0.62, 0.28))
		_apply_penalty(2.0)
		_lock_verdict(2.0)
		_register_trial("INSUFFICIENT_DATA", false)
		return

	if selected_gate_guess == current_case.gate:
		_show_feedback("ДОСТУП РАЗРЕШЁН", Color(0.45, 0.92, 0.62))
		btn_verdict.visible = false
		btn_next.visible = true
		_disable_controls()
		_register_trial("SUCCESS", true)
	else:
		case_attempts += 1
		_update_stats_ui()

		var penalty := 10.0
		if case_attempts == 2:
			penalty = 15.0
		elif case_attempts >= 3:
			penalty = 25.0

		_apply_penalty(penalty)
		_show_feedback("ДОСТУП ЗАПРЕЩЁН (-%d)" % int(penalty), Color(1.0, 0.35, 0.32))
		var verdict_code := "WRONG_GATE"
		if case_attempts >= MAX_ATTEMPTS:
			_enter_safe_mode()
			verdict_code = "SAFE_MODE_TRIGGERED"
		_register_trial(verdict_code, false)

func _lock_verdict(duration: float) -> void:
	if is_safe_mode:
		return
	btn_verdict.disabled = true
	verdict_timer.start(duration)

func _on_verdict_unlock() -> void:
	if is_safe_mode:
		return
	if GlobalMetrics.stability > 0.0:
		btn_verdict.disabled = false

func _enter_safe_mode() -> void:
	is_safe_mode = true
	_disable_controls()
	btn_verdict.disabled = true
	btn_next.visible = true

	_set_gate_buttons_enabled(false)
	_select_gate_button(str(current_case.get("gate", "")))

	var gate_symbol := _gate_symbol(str(current_case.get("gate", "")))
	var gate_title := _gate_title(str(current_case.get("gate", "")))
	var safe_msg := "БЕЗОПАСНЫЙ РЕЖИМ: правильный вентиль %s (%s)." % [gate_symbol, gate_title]
	_show_feedback(safe_msg, Color(1.0, 0.74, 0.32))
	_show_diagnostics("SAFE MODE", "%s\nВыполнен авторазбор, изучите журнал и переходите далее." % safe_msg)

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

func _show_feedback(msg: String, col: Color) -> void:
	feedback_label.text = msg
	feedback_label.add_theme_color_override("font_color", col)
	feedback_label.visible = true

func _apply_penalty(amount: float) -> void:
	GlobalMetrics.stability = max(0.0, GlobalMetrics.stability - amount)
	GlobalMetrics.stability_changed.emit(GlobalMetrics.stability, -amount)

func _update_stability_ui(val: float, _change: float) -> void:
	energy_bar.value = clampf(val, 0.0, 100.0)
	_update_stats_ui()

func _update_stats_ui() -> void:
	var min_seen: int = int(current_case.get("min_seen", 2))
	var case_id := str(current_case.get("id", "A_00"))
	session_label.text = "СЕССИЯ: %02d/%02d • CASE %s" % [current_case_index + 1, CASES.size(), case_id]
	stats_label.text = "ПОП: %d/%d • ФАКТЫ: %d/%d • СТАБ: %d%%" % [
		case_attempts,
		MAX_ATTEMPTS,
		seen_combinations.size(),
		min_seen,
		int(GlobalMetrics.stability)
	]
	_update_target_and_bars()

func _on_game_over() -> void:
	_enter_safe_mode()

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _on_next_button_pressed() -> void:
	_hide_diagnostics()
	load_case(current_case_index + 1)

func _on_hint_pressed() -> void:
	_mark_first_action()
	if hints_used < current_case.hints.size():
		var h := str(current_case.hints[hints_used])
		hints_used += 1
		_show_feedback("ПОДСКАЗКА: " + h, Color(0.56, 0.78, 0.96))
		_apply_penalty(5.0)
	else:
		_show_feedback("ПОДСКАЗОК БОЛЬШЕ НЕТ", Color(0.66, 0.66, 0.66))

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
	payload["attempts"] = case_attempts
	payload["verdict_count"] = verdict_count
	GlobalMetrics.register_trial(payload)

func _play_click() -> void:
	if click_player.stream:
		click_player.play()

func _disable_controls() -> void:
	input_a_btn.disabled = true
	input_b_btn.disabled = true
	_set_gate_buttons_enabled(false)
	btn_hint.disabled = true
