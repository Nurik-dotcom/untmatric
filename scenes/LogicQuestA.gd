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
@onready var stability_label = $MainLayout/HeaderPanel/HeaderMargin/HeaderHBox/StabilityLabel
@onready var stats_label = $MainLayout/HeaderPanel/HeaderMargin/HeaderHBox/StatsLabel
@onready var story_text = $MainLayout/StoryPanel/StoryMargin/StoryText
@onready var journal_label = $MainLayout/BoardContainer/JournalLabel

@onready var input_a_btn = $MainLayout/BoardContainer/InputA_Btn
@onready var input_b_btn = $MainLayout/BoardContainer/InputB_Btn
@onready var gate_selector = $MainLayout/BoardContainer/GateSelector
@onready var lamp_rect = $MainLayout/BoardContainer/Lamp
@onready var lamp_label = $MainLayout/BoardContainer/Lamp/LampLabel

@onready var wire_a = $MainLayout/BoardContainer/WiresLayer/InputA_Wire
@onready var wire_b = $MainLayout/BoardContainer/WiresLayer/InputB_Wire
@onready var wire_out = $MainLayout/BoardContainer/WiresLayer/Output_Wire

@onready var feedback_label = $MainLayout/ControlsPanel/ControlsMargin/HBox/FeedbackLabel
@onready var btn_verdict = $MainLayout/ControlsPanel/ControlsMargin/HBox/BtnVerdict
@onready var btn_next = $MainLayout/ControlsPanel/ControlsMargin/HBox/BtnNext
@onready var btn_hint = $MainLayout/ControlsPanel/ControlsMargin/HBox/BtnHint

@onready var game_over_panel = $GameOverPanel
@onready var game_over_label = $GameOverPanel/CenterContainer/VBox/Title
@onready var click_player = $ClickPlayer

# --- STATE ---
var current_case_index: int = 0
var current_case: Dictionary = {}

var input_a: bool = false
var input_b: bool = false
var selected_gate_guess: String = ""

var seen_combinations: Dictionary = {}
var case_attempts: int = 0
var hints_used: int = 0
var start_time_msec: int = 0

var last_verdict_time: float = 0.0
var verdict_timer: Timer = null
var is_safe_mode: bool = false

# Colors for Wires/Effects
const COLOR_WIRE_OFF = Color(0.15, 0.15, 0.15, 1) # Dark Grey
const COLOR_WIRE_ON = Color(1.2, 1.2, 1.2, 1)     # Glowing White (HDR)
const COLOR_LAMP_OFF = Color(0.1, 0.1, 0.1, 1)
const COLOR_LAMP_ON = Color(1.5, 1.5, 1.3, 1)     # Bright Warm White

func _ready():
	_setup_gate_selector()
	_update_stability_ui(GlobalMetrics.stability, 0)
	GlobalMetrics.stability_changed.connect(_update_stability_ui)
	GlobalMetrics.game_over.connect(_on_game_over)

	verdict_timer = Timer.new()
	verdict_timer.one_shot = true
	verdict_timer.timeout.connect(_on_verdict_unlock)
	add_child(verdict_timer)

	load_case(0)

func _setup_gate_selector():
	gate_selector.clear()
	gate_selector.add_item(" ... ", 0) # ID 0 = None
	# Using strict ENT symbols as requested
	gate_selector.add_item(" &  (AND)", 1)
	gate_selector.add_item(" 1  (OR)", 2)
	gate_selector.add_item(" ﾂｬ  (NOT)", 3)
	gate_selector.add_item(" 竓・ (XOR)", 4)
	gate_selector.add_item(" |  (NAND)", 5)
	gate_selector.add_item(" 竊・ (NOR)", 6)

	gate_selector.set_item_metadata(1, GATE_AND)
	gate_selector.set_item_metadata(2, GATE_OR)
	gate_selector.set_item_metadata(3, GATE_NOT)
	gate_selector.set_item_metadata(4, GATE_XOR)
	gate_selector.set_item_metadata(5, GATE_NAND)
	gate_selector.set_item_metadata(6, GATE_NOR)

func load_case(idx: int):
	if idx >= CASES.size():
		idx = 0 # Loop for now

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
	is_safe_mode = false

	# Update UI Text
	story_text.text = current_case.witness_text
	_update_stats_ui()
	journal_label.text = "LOG: SYSTEM READY"

	# Reset Inputs
	input_a_btn.button_pressed = false
	input_b_btn.button_pressed = false
	input_a_btn.disabled = false
	input_b_btn.disabled = false
	btn_hint.disabled = false
	_update_input_labels()

	# Handle NOT gate (Single input)
	if current_case.gate == GATE_NOT:
		input_b_btn.visible = false
		wire_b.visible = false
	else:
		input_b_btn.visible = true
		wire_b.visible = true

	# Reset Selector & Output
	gate_selector.selected = 0
	gate_selector.disabled = false

	# Reset Controls
	btn_verdict.visible = true
	btn_verdict.disabled = false
	btn_next.visible = false
	feedback_label.text = ""

	_update_circuit()

func _update_input_labels():
	input_a_btn.text = "%s\n%s" % [current_case.a_text, "1" if input_a else "0"]
	if current_case.gate != GATE_NOT:
		input_b_btn.text = "%s\n%s" % [current_case.b_text, "1" if input_b else "0"]

func _on_input_a_toggled(pressed: bool):
	input_a = pressed
	_play_click()
	_update_input_labels()
	_update_circuit()

func _on_input_b_toggled(pressed: bool):
	input_b = pressed
	_play_click()
	_update_input_labels()
	_update_circuit()

func _update_circuit():
	# 1. Update Input Wires
	wire_a.default_color = COLOR_WIRE_ON if input_a else COLOR_WIRE_OFF
	wire_b.default_color = COLOR_WIRE_ON if input_b else COLOR_WIRE_OFF

	# 2. Calculate Logic
	var out_val = _calculate_gate_output(input_a, input_b, current_case.gate)

	# 3. Update Output Wire & Lamp
	wire_out.default_color = COLOR_WIRE_ON if out_val else COLOR_WIRE_OFF

	if out_val:
		lamp_rect.color = COLOR_LAMP_ON
		lamp_label.modulate = Color(0, 0, 0, 1) # Black text on bright lamp
	else:
		lamp_rect.color = COLOR_LAMP_OFF
		lamp_label.modulate = Color(0.3, 0.3, 0.3, 1) # Dim text

	# 4. Log
	var key = ""
	if current_case.gate == GATE_NOT:
		key = "A=%d" % [1 if input_a else 0]
	else:
		key = "A=%d B=%d" % [1 if input_a else 0, 1 if input_b else 0]

	if not seen_combinations.has(key):
		seen_combinations[key] = out_val
		_update_journal_log()
		_update_stats_ui()

func _calculate_gate_output(a: bool, b: bool, type: String) -> bool:
	match type:
		GATE_AND: return a and b
		GATE_OR: return a or b
		GATE_NOT: return not a
		GATE_XOR: return a != b
		GATE_NAND: return not (a and b)
		GATE_NOR: return not (a or b)
	return false

func _update_journal_log():
	var txt = "LOG:\n"
	for k in seen_combinations:
		var res = "1" if seen_combinations[k] else "0"
		txt += "%s -> F=%s | " % [k, res]
	journal_label.text = txt

func _on_gate_selected(index):
	if index == 0:
		selected_gate_guess = ""
	else:
		selected_gate_guess = gate_selector.get_item_metadata(index)
		_play_click()

func _on_verdict_pressed():
	if is_safe_mode: return

	# Anti-spam
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_verdict_time < 0.8:
		_show_feedback("ﾐ斷ｵ ﾑび巾ｺﾐｰﾐｹ. ﾐ湲ﾐｾﾐｲﾐｵﾑﾑ・ﾑ・ｰﾐｺﾑび・", Color(1, 0.5, 0))
		_lock_verdict(3.0)
		return
	last_verdict_time = current_time

	if selected_gate_guess == "":
		_show_feedback("SELECT GATE FIRST", Color(1, 1, 0))
		return

	var min_seen = current_case.get("min_seen", 2)
	if seen_combinations.size() < min_seen:
		_show_feedback("INSUFFICIENT DATA (%d/%d)" % [seen_combinations.size(), min_seen], Color(1, 0.5, 0))
		_apply_penalty(2.0)
		_lock_verdict(2.0)
		return

	if selected_gate_guess == current_case.gate:
		_show_feedback("ACCESS GRANTED", Color(0, 1, 0))
		btn_verdict.visible = false
		btn_next.visible = true
		_disable_controls()
	else:
		case_attempts += 1
		_update_stats_ui()

		var penalty = 10.0
		if case_attempts == 2: penalty = 15.0
		elif case_attempts >= 3: penalty = 25.0

		_apply_penalty(penalty)
		_show_feedback("ACCESS DENIED (-%d)" % int(penalty), Color(1, 0, 0))

		if case_attempts >= MAX_ATTEMPTS:
			_enter_safe_mode()

func _lock_verdict(duration: float):
	if is_safe_mode: return
	btn_verdict.disabled = true
	verdict_timer.start(duration)

func _on_verdict_unlock():
	if is_safe_mode: return
	if GlobalMetrics.stability > 0:
		btn_verdict.disabled = false

func _enter_safe_mode():
	is_safe_mode = true
	_disable_controls()
	btn_verdict.disabled = true
	btn_next.visible = true

	# Auto-select correct gate
	for i in range(gate_selector.item_count):
		if gate_selector.get_item_metadata(i) == current_case.gate:
			gate_selector.select(i)
			gate_selector.disabled = true
			break

	var gate_symbol = "?"
	match current_case.gate:
		GATE_AND: gate_symbol = "& (AND)"
		GATE_OR: gate_symbol = "1 (OR)"
		GATE_NOT: gate_symbol = "ﾂｬ (NOT)"
		GATE_XOR: gate_symbol = "竓・(XOR)"
		GATE_NAND: gate_symbol = "| (NAND)"
		GATE_NOR: gate_symbol = "竊・(NOR)"

	_show_feedback("SAFE MODE: ﾐｿﾑﾐｰﾐｲﾐｸﾐｻﾑ糊ｽﾑ巾ｹ ﾐｲﾐｵﾐｽﾑひｸﾐｻﾑ・窶・%s. ﾐ｡ﾐｸﾑ・ひｵﾐｼﾐｰ ﾑ・ｱﾑﾐｾﾑ威ｵﾐｽﾐｰ." % gate_symbol, Color(1, 0.5, 0))

func _show_feedback(msg: String, col: Color):
	feedback_label.text = msg
	feedback_label.add_theme_color_override("font_color", col)
	feedback_label.visible = true

func _apply_penalty(amount):
	GlobalMetrics.stability = max(0.0, GlobalMetrics.stability - amount)
	GlobalMetrics.stability_changed.emit(GlobalMetrics.stability, -amount)

func _update_stability_ui(val, _change):
	stability_label.text = "STABILITY: %d%%" % int(val)
	if val < 30:
		stability_label.add_theme_color_override("font_color", Color(1, 0, 0))
	elif val < 70:
		stability_label.add_theme_color_override("font_color", Color(1, 1, 0))
	else:
		stability_label.add_theme_color_override("font_color", Color(0, 1, 0))

func _update_stats_ui():
	var min_seen = current_case.get("min_seen", 2)
	stats_label.text = "CASE: %02d | ATT: %d/%d | FACTS: %d/%d" % [
		current_case_index + 1,
		case_attempts,
		MAX_ATTEMPTS,
		seen_combinations.size(),
		min_seen
	]

func _on_game_over():
	_enter_safe_mode()
	# The original game over panel is now redundant if we want "Safe Mode" style instead
	# But per instructions, if stability drops to 0, we enter Safe Mode.
	# We can keep the glitch effect if desired, but "Safe Mode" implies continuing.
	# Let's hide the old game over panel if it pops up via other paths, or just not use it.
	game_over_panel.visible = false

func _on_system_failure():
	# Deprecated by Safe Mode logic, but kept as fallback/extreme fail
	_enter_safe_mode()

func _on_restart_pressed():
	# Legacy restart, might not be needed if Safe Mode handles everything
	GlobalMetrics.stability = 100.0
	GlobalMetrics.stability_changed.emit(100.0, 0)
	game_over_panel.visible = false
	load_case(current_case_index)

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _on_next_button_pressed():
	load_case(current_case_index + 1)

func _on_hint_pressed():
	if hints_used < current_case.hints.size():
		var h = current_case.hints[hints_used]
		hints_used += 1
		_show_feedback("HINT: " + h, Color(0.5, 0.8, 1))
		_apply_penalty(5.0)
	else:
		_show_feedback("NO MORE HINTS", Color(0.5, 0.5, 0.5))

func _play_click():
	if click_player.stream:
		click_player.play()

func _disable_controls():
	input_a_btn.disabled = true
	input_b_btn.disabled = true
	gate_selector.disabled = true
	btn_hint.disabled = true
