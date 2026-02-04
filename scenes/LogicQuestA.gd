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

# Cases Data
const CASES = [
	# --- PHASE 1: TRAINING (Words) ---
	{
		"id": "A1_01", "phase": PHASE_TRAINING, "gate": GATE_AND,
		"a_text": "КЛЮЧ", "b_text": "КНОПКА",
		"witness_text": "Машина заводится только когда вставлен КЛЮЧ 'И' нажата КНОПКА.",
		"min_seen": 2, "hints": ["Оба условия должны быть выполнены (1 и 1).", "Это логическое И."]
	},
	{
		"id": "A1_02", "phase": PHASE_TRAINING, "gate": GATE_OR,
		"a_text": "ДОЖДЬ", "b_text": "СНЕГ",
		"witness_text": "Я промокну, если пойдет ДОЖДЬ 'ИЛИ' если пойдет СНЕГ.",
		"min_seen": 2, "hints": ["Хотя бы одно условие истинно (1 или 1).", "Это логическое ИЛИ."]
	},
	{
		"id": "A1_03", "phase": PHASE_TRAINING, "gate": GATE_NOT,
		"a_text": "СВЕТ", "b_text": "---",
		"witness_text": "Датчик работает наоборот: если СВЕТ есть, сигнала НЕТ. Если СВЕТА нет, сигнал ЕСТЬ.",
		"min_seen": 2, "hints": ["Выход противоположен входу.", "Это логическое НЕ."]
	},
	{
		"id": "A1_04", "phase": PHASE_TRAINING, "gate": GATE_XOR,
		"a_text": "РЫЧАГ 1", "b_text": "РЫЧАГ 2",
		"witness_text": "Дверь открывается, если нажат только ОДИН из рычагов. Если оба или ни одного — дверь закрыта.",
		"min_seen": 3, "hints": ["Строго одно из двух. (1,0) или (0,1).", "Исключающее ИЛИ."]
	},
	{
		"id": "A1_05", "phase": PHASE_TRAINING, "gate": GATE_AND,
		"a_text": "ПАРОЛЬ", "b_text": "СКАН",
		"witness_text": "Доступ разрешен, если введен ПАРОЛЬ 'И' пройден СКАН сетчатки.",
		"min_seen": 2, "hints": ["Оба условия: 1 и 1.", "Это И (AND)."]
	},

	# --- PHASE 2: TRANSLATION (Symbols) ---
	{
		"id": "A2_01", "phase": PHASE_TRANSLATION, "gate": GATE_AND,
		"a_text": "A", "b_text": "B",
		"witness_text": "В документации указан символ '&'. Проверь, как он работает.",
		"min_seen": 2, "hints": ["& означает Конъюнкцию (И).", "Только 1 & 1 дает 1."]
	},
	{
		"id": "A2_02", "phase": PHASE_TRANSLATION, "gate": GATE_OR,
		"a_text": "A", "b_text": "B",
		"witness_text": "На схеме стоит '1' (или 'v'). Это Дизъюнкция. Проверь таблицу.",
		"min_seen": 2, "hints": ["Это ИЛИ.", "Дает 1, если есть хотя бы одна единица."]
	},
	{
		"id": "A2_03", "phase": PHASE_TRANSLATION, "gate": GATE_NOT,
		"a_text": "A", "b_text": "---",
		"witness_text": "Символ '¬' означает инверсию.",
		"min_seen": 2, "hints": ["Меняет 0 на 1 и наоборот.", "Это НЕ (NOT)."]
	},
	{
		"id": "A2_04", "phase": PHASE_TRANSLATION, "gate": GATE_XOR,
		"a_text": "A", "b_text": "B",
		"witness_text": "Символ '⊕' — сумма по модулю 2. Проверь его.",
		"min_seen": 3, "hints": ["Разные входы дают 1, одинаковые 0.", "Это XOR."]
	},
	{
		"id": "A2_05", "phase": PHASE_TRANSLATION, "gate": GATE_NOR,
		"a_text": "A", "b_text": "B",
		"witness_text": "Стрелка Пирса (↓ или NOR). Инверсия ИЛИ.",
		"min_seen": 3, "hints": ["Дает 1 только когда оба 0.", "Это ИЛИ-НЕ (NOR)."]
	},

	# --- PHASE 3: DETECTION (Pure Logic) ---
	{
		"id": "A3_01", "phase": PHASE_DETECTION, "gate": GATE_NAND,
		"a_text": "X", "b_text": "Y",
		"witness_text": "Свидетель: 'Лампа погасла только тогда, когда включили ОБА рубильника'.",
		"min_seen": 3, "hints": ["0 только при (1,1).", "Это Штрих Шеффера (NAND)."]
	},
	{
		"id": "A3_02", "phase": PHASE_DETECTION, "gate": GATE_XOR,
		"a_text": "СИГНАЛ 1", "b_text": "СИГНАЛ 2",
		"witness_text": "Аномалия регистрируется, когда сигналы РАЗЛИЧАЮТСЯ.",
		"min_seen": 3, "hints": ["0,1 -> 1; 1,0 -> 1.", "Это XOR."]
	},
	{
		"id": "A3_03", "phase": PHASE_DETECTION, "gate": GATE_NOR,
		"a_text": "ДАТЧИК А", "b_text": "ДАТЧИК Б",
		"witness_text": "Система спокойна (1), только если оба датчика молчат (0). Любая активность вызывает тревогу (0).",
		"min_seen": 3, "hints": ["1 только при (0,0).", "Это NOR."]
	},
	{
		"id": "A3_04", "phase": PHASE_DETECTION, "gate": GATE_AND,
		"a_text": "КЛЮЧ А", "b_text": "КЛЮЧ Б",
		"witness_text": "Сейф открылся (1). Значит, оба ключа повернули.",
		"min_seen": 2, "hints": ["Нужны оба.", "AND."]
	},
	{
		"id": "A3_05", "phase": PHASE_DETECTION, "gate": GATE_OR,
		"a_text": "КНОПКА 1", "b_text": "КНОПКА 2",
		"witness_text": "Лифт поехал (1). Кто-то нажал кнопку здесь ИЛИ там.",
		"min_seen": 2, "hints": ["Хватит одной.", "OR."]
	}
]

# --- UI NODES ---
@onready var stability_label = $MarginContainer/ScrollContainer/MainContent/HeaderPanel/HeaderHBox/StabilityLabel
@onready var stats_label = $MarginContainer/ScrollContainer/MainContent/HeaderPanel/HeaderHBox/StatsLabel
@onready var story_text = $MarginContainer/ScrollContainer/MainContent/StoryPanel/StoryMargin/StoryText

@onready var btn_input_a = $MarginContainer/ScrollContainer/MainContent/TestBenchPanel/TestBenchMargin/HBox/InputsVBox/BtnInputA
@onready var btn_input_b = $MarginContainer/ScrollContainer/MainContent/TestBenchPanel/TestBenchMargin/HBox/InputsVBox/BtnInputB
@onready var lamp_rect = $MarginContainer/ScrollContainer/MainContent/TestBenchPanel/TestBenchMargin/HBox/OutputVBox/Lamp
@onready var lamp_label = $MarginContainer/ScrollContainer/MainContent/TestBenchPanel/TestBenchMargin/HBox/OutputVBox/LampLabel

@onready var journal_label = $MarginContainer/ScrollContainer/MainContent/JournalPanel/JournalMargin/JournalLabel

@onready var gate_grid = $MarginContainer/ScrollContainer/MainContent/SelectorPanel/SelectorMargin/GateGrid
# Gate Buttons
@onready var btn_gate_and = $MarginContainer/ScrollContainer/MainContent/SelectorPanel/SelectorMargin/GateGrid/BtnAND
@onready var btn_gate_or = $MarginContainer/ScrollContainer/MainContent/SelectorPanel/SelectorMargin/GateGrid/BtnOR
@onready var btn_gate_not = $MarginContainer/ScrollContainer/MainContent/SelectorPanel/SelectorMargin/GateGrid/BtnNOT
@onready var btn_gate_xor = $MarginContainer/ScrollContainer/MainContent/SelectorPanel/SelectorMargin/GateGrid/BtnXOR
@onready var btn_gate_nand = $MarginContainer/ScrollContainer/MainContent/SelectorPanel/SelectorMargin/GateGrid/BtnNAND
@onready var btn_gate_nor = $MarginContainer/ScrollContainer/MainContent/SelectorPanel/SelectorMargin/GateGrid/BtnNOR

@onready var feedback_label = $MarginContainer/ScrollContainer/MainContent/FeedbackLabel
@onready var btn_hint = $MarginContainer/ScrollContainer/MainContent/ActionsHBox/BtnHint
@onready var btn_verdict = $MarginContainer/ScrollContainer/MainContent/ActionsHBox/BtnVerdict
@onready var btn_next = $MarginContainer/ScrollContainer/MainContent/ActionsHBox/BtnNext

# --- STATE ---
var current_case_index: int = 0
var current_case: Dictionary = {}

var input_a: bool = false
var input_b: bool = false
var selected_gate_guess: String = ""

var seen_combinations: Dictionary = {} # Stores "0,1" -> output (bool)
var case_attempts: int = 0
var hints_used: int = 0
var start_time_msec: int = 0

# Colors
const COL_ACTIVE = Color(0.2, 0.8, 0.2, 1)
const COL_INACTIVE = Color(0.3, 0.3, 0.3, 1)
const COL_ERROR = Color(1, 0.3, 0.3, 1)
const COL_WARN = Color(1, 0.8, 0.2, 1)
const COL_SUCCESS = Color(0.3, 1, 0.3, 1)
const COL_LAMP_ON = Color(1, 1, 0.5, 1)
const COL_LAMP_OFF = Color(0.1, 0.1, 0.1, 1)

func _ready():
	_connect_signals()
	# Update Stability UI from global
	_update_stability_ui(GlobalMetrics.stability, 0)
	GlobalMetrics.stability_changed.connect(_update_stability_ui)

	load_case(0)

func _connect_signals():
	# UI signals are already connected via editor/tscn usually, but we check here if needed
	# For safety, we rely on the Tscn connections to `_on_...` methods
	pass

func load_case(idx: int):
	if idx >= CASES.size():
		idx = 0 # Loop or Finish
		# Ideally show a "Quest Complete" screen here

	current_case_index = idx
	current_case = CASES[idx]

	# Reset State
	input_a = false
	input_b = false
	selected_gate_guess = ""
	seen_combinations.clear()
	case_attempts = 0
	hints_used = 0
	start_time_msec = Time.get_ticks_msec()

	# Update UI
	story_text.text = current_case.witness_text

	# Inputs Labels
	btn_input_a.text = "%s: 0" % current_case.a_text
	btn_input_a.button_pressed = false

	if current_case.gate == GATE_NOT:
		btn_input_b.visible = false
		btn_input_b.disabled = true
	else:
		btn_input_b.visible = true
		btn_input_b.disabled = false
		btn_input_b.text = "%s: 0" % current_case.b_text
		btn_input_b.button_pressed = false

	# Reset Lamp
	_update_lamp_output()

	# Reset Journal
	journal_label.text = "Журнал проверок:\n(Пусто)"

	# Reset Selector Buttons
	_reset_gate_buttons()

	# Reset Controls
	feedback_label.text = ""
	btn_verdict.disabled = false
	btn_next.visible = false
	btn_verdict.visible = true
	btn_hint.disabled = false

	_update_stats_ui()

	# Update Gate Button Labels for Phases
	_update_gate_labels(current_case.phase)

func _update_gate_labels(phase: String):
	# Default Labels
	btn_gate_and.text = "AND"
	btn_gate_or.text = "OR"
	btn_gate_not.text = "NOT"
	btn_gate_xor.text = "XOR"
	btn_gate_nand.text = "NAND"
	btn_gate_nor.text = "NOR"

	if phase == PHASE_TRAINING:
		btn_gate_and.text = "И (AND)"
		btn_gate_or.text = "ИЛИ (OR)"
		btn_gate_not.text = "НЕ (NOT)"
		btn_gate_xor.text = "ИСКЛ. ИЛИ"
	elif phase == PHASE_TRANSLATION:
		btn_gate_and.text = "& (AND)"
		btn_gate_or.text = "1 (OR)"
		btn_gate_not.text = "¬ (NOT)"
		btn_gate_xor.text = "⊕ (XOR)"
		btn_gate_nor.text = "↓ (NOR)"
	elif phase == PHASE_DETECTION:
		btn_gate_and.text = "∧"
		btn_gate_or.text = "∨"
		btn_gate_not.text = "¬"
		btn_gate_xor.text = "⊕"
		btn_gate_nand.text = "|"
		btn_gate_nor.text = "↓"

	# Disable NAND/NOR in early phases if not used to avoid confusion?
	# TZ says "Grid with buttons AND OR NOT XOR (+ optionally NAND/NOR later)"
	# We can just leave them enabled but maybe dim or just standard.
	# For simplicity, they are always there.

func _reset_gate_buttons():
	for btn in [btn_gate_and, btn_gate_or, btn_gate_not, btn_gate_xor, btn_gate_nand, btn_gate_nor]:
		btn.button_pressed = false
		btn.modulate = Color(1, 1, 1, 1)

func _on_input_a_pressed():
	input_a = btn_input_a.button_pressed
	btn_input_a.text = "%s: %s" % [current_case.a_text, "1" if input_a else "0"]
	_update_lamp_output()

func _on_input_b_pressed():
	input_b = btn_input_b.button_pressed
	btn_input_b.text = "%s: %s" % [current_case.b_text, "1" if input_b else "0"]
	_update_lamp_output()

func _update_lamp_output():
	var val = _calculate_gate_output(input_a, input_b, current_case.gate)

	# Visuals
	if val:
		lamp_rect.color = COL_LAMP_ON
		lamp_label.text = "ON (1)"
		lamp_label.modulate = Color(0, 0, 0, 1)
	else:
		lamp_rect.color = COL_LAMP_OFF
		lamp_label.text = "OFF (0)"
		lamp_label.modulate = Color(0.5, 0.5, 0.5, 1)

	# Log to Journal
	var key = ""
	if current_case.gate == GATE_NOT:
		key = "A=%d" % [1 if input_a else 0]
	else:
		key = "A=%d, B=%d" % [1 if input_a else 0, 1 if input_b else 0]

	if not seen_combinations.has(key):
		seen_combinations[key] = val
		_update_journal()

func _calculate_gate_output(a: bool, b: bool, type: String) -> bool:
	match type:
		GATE_AND: return a and b
		GATE_OR: return a or b
		GATE_NOT: return not a
		GATE_XOR: return a != b
		GATE_NAND: return not (a and b)
		GATE_NOR: return not (a or b)
	return false

func _update_journal():
	var text = "Журнал проверок:\n"
	for k in seen_combinations:
		var res = "1" if seen_combinations[k] else "0"
		text += "%s -> F=%s\n" % [k, res]
	journal_label.text = text

func _on_gate_btn_pressed(gate_type: String):
	selected_gate_guess = gate_type

	# Visual update: Highlight selected, dim others
	var btns = {
		GATE_AND: btn_gate_and,
		GATE_OR: btn_gate_or,
		GATE_NOT: btn_gate_not,
		GATE_XOR: btn_gate_xor,
		GATE_NAND: btn_gate_nand,
		GATE_NOR: btn_gate_nor
	}

	for g in btns:
		var btn = btns[g]
		if g == gate_type:
			btn.button_pressed = true
			btn.modulate = COL_ACTIVE
		else:
			btn.button_pressed = false
			btn.modulate = Color(1, 1, 1, 1)

	feedback_label.text = "" # Clear errors when user changes mind

func _on_verdict_pressed():
	# 1. Validation: Selected?
	if selected_gate_guess == "":
		_show_feedback("Выберите вентиль!", COL_WARN)
		return

	# 2. Shield: Time
	var time_diff = (Time.get_ticks_msec() - start_time_msec) / 1000.0
	var min_seen = current_case.get("min_seen", 2)

	# Special Shield condition: "Too fast" or "Not enough checks"
	if seen_combinations.size() < min_seen:
		_trigger_shield("Сначала проверь факты (%d/%d)!" % [seen_combinations.size(), min_seen])
		return

	if time_diff < 1.0: # Very fast click
		_trigger_shield("Не спеши!")
		return

	# 3. Check Answer
	if selected_gate_guess == current_case.gate:
		_handle_success()
	else:
		_handle_failure()

func _trigger_shield(msg: String):
	_show_feedback(msg, COL_WARN)
	btn_verdict.disabled = true

	# Small penalty? TZ says "stability -2/-3, not as error"
	_apply_penalty(2.0)

	await get_tree().create_timer(2.0).timeout
	if is_inside_tree():
		btn_verdict.disabled = false
		if feedback_label.text == msg:
			feedback_label.text = ""

func _handle_success():
	_show_feedback("ВЕРНО! Логика совпадает.", COL_SUCCESS)
	btn_verdict.visible = false
	btn_next.visible = true

	# Disable controls
	_disable_inputs()

func _handle_failure():
	case_attempts += 1
	var penalty = 10.0
	if case_attempts == 2: penalty = 15.0
	if case_attempts >= 3: penalty = 25.0

	_apply_penalty(penalty)
	_show_feedback("ОШИБКА! Это не тот вентиль.", COL_ERROR)

	if case_attempts >= 3:
		_handle_game_over_case()

func _handle_game_over_case():
	feedback_label.text = "Провал операции. Правильный ответ: %s" % current_case.gate
	btn_verdict.visible = false
	btn_next.visible = true # Allow skip even on fail (Safe Mode)
	_disable_inputs()

func _disable_inputs():
	btn_input_a.disabled = true
	btn_input_b.disabled = true
	for btn in [btn_gate_and, btn_gate_or, btn_gate_not, btn_gate_xor, btn_gate_nand, btn_gate_nor]:
		btn.disabled = true
	btn_hint.disabled = true

func _apply_penalty(amount: float):
	GlobalMetrics.stability = max(0.0, GlobalMetrics.stability - amount)
	GlobalMetrics.stability_changed.emit(GlobalMetrics.stability, -amount)

func _update_stability_ui(val, _change):
	stability_label.text = "Stability: %d%%" % int(val)
	if val > 70: stability_label.add_theme_color_override("font_color", COL_SUCCESS)
	elif val > 30: stability_label.add_theme_color_override("font_color", COL_WARN)
	else: stability_label.add_theme_color_override("font_color", COL_ERROR)

func _update_stats_ui():
	stats_label.text = "Case: %d/%d | Att: %d/3" % [current_case_index + 1, CASES.size(), case_attempts]

func _show_feedback(msg: String, col: Color):
	feedback_label.text = msg
	feedback_label.add_theme_color_override("font_color", col)

func _on_hint_pressed():
	if hints_used >= current_case.hints.size():
		_show_feedback("Больше подсказок нет.", COL_WARN)
		return

	var hint_text = current_case.hints[hints_used]
	hints_used += 1

	_show_feedback("ПОДСКАЗКА: " + hint_text, Color(0.5, 0.8, 1))
	_apply_penalty(5.0)

func _on_next_pressed():
	load_case(current_case_index + 1)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")
