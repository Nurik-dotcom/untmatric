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
	# --- PHASE 1: TRAINING (Words -> Logic) ---
	{
		"id": "A1_01", "phase": PHASE_TRAINING, "gate": GATE_AND,
		"a_text": "КЛЮЧ", "b_text": "КНОПКА",
		"witness_text": "Машина заводится только когда вставлен КЛЮЧ [b]И[/b] нажата КНОПКА.",
		"min_seen": 2, "hints": ["Оба условия должны быть 1.", "Это конъюнкция (&)."]
	},
	{
		"id": "A1_02", "phase": PHASE_TRAINING, "gate": GATE_OR,
		"a_text": "ДОЖДЬ", "b_text": "СНЕГ",
		"witness_text": "Я промокну, если пойдет ДОЖДЬ [b]ИЛИ[/b] если пойдет СНЕГ.",
		"min_seen": 2, "hints": ["Хотя бы одно условие истинно.", "Это дизъюнкция (1/v)."]
	},
	{
		"id": "A1_03", "phase": PHASE_TRAINING, "gate": GATE_NOT,
		"a_text": "СВЕТ", "b_text": "---",
		"witness_text": "Датчик работает наоборот: если СВЕТ есть, сигнала [b]НЕТ[/b].",
		"min_seen": 2, "hints": ["Инверсия: 1->0, 0->1.", "Это НЕ (¬)."]
	},
	{
		"id": "A1_04", "phase": PHASE_TRAINING, "gate": GATE_XOR,
		"a_text": "РЫЧАГ A", "b_text": "РЫЧАГ B",
		"witness_text": "Дверь открывается, если нажат [b]ТОЛЬКО ОДИН[/b] из рычагов.",
		"min_seen": 3, "hints": ["Разные входы дают 1.", "Исключающее ИЛИ (⊕)."]
	},

	# --- PHASE 2: TRANSLATION (Symbols) ---
	{
		"id": "A2_01", "phase": PHASE_TRANSLATION, "gate": GATE_AND,
		"a_text": "A", "b_text": "B",
		"witness_text": "В документации указан символ [b]&[/b]. Проверь, как он работает.",
		"min_seen": 2, "hints": ["& означает И.", "Только 1 & 1 = 1."]
	},
	{
		"id": "A2_02", "phase": PHASE_TRANSLATION, "gate": GATE_OR,
		"a_text": "A", "b_text": "B",
		"witness_text": "На схеме стоит [b]1[/b] (или v). Это Дизъюнкция.",
		"min_seen": 2, "hints": ["ИЛИ.", "Дает 1, если есть хоть одна 1."]
	},
	{
		"id": "A2_03", "phase": PHASE_TRANSLATION, "gate": GATE_NOT,
		"a_text": "A", "b_text": "---",
		"witness_text": "Символ [b]¬[/b] означает инверсию.",
		"min_seen": 2, "hints": ["Меняет значение на обратное.", "НЕ."]
	},
	{
		"id": "A2_04", "phase": PHASE_TRANSLATION, "gate": GATE_XOR,
		"a_text": "A", "b_text": "B",
		"witness_text": "Символ [b]⊕[/b] — сумма по модулю 2.",
		"min_seen": 3, "hints": ["Разные — 1, одинаковые — 0.", "XOR."]
	},

	# --- PHASE 3: DETECTION (Pure Logic) ---
	{
		"id": "A3_01", "phase": PHASE_DETECTION, "gate": GATE_NAND,
		"a_text": "X", "b_text": "Y",
		"witness_text": "Лампа погасла (0) только тогда, когда включили [b]ОБА[/b] рубильника.",
		"min_seen": 3, "hints": ["0 только при (1,1).", "NAND (Штрих Шеффера)."]
	},
	{
		"id": "A3_02", "phase": PHASE_DETECTION, "gate": GATE_XOR,
		"a_text": "S1", "b_text": "S2",
		"witness_text": "Аномалия регистрируется, когда сигналы [b]РАЗЛИЧАЮТСЯ[/b].",
		"min_seen": 3, "hints": ["0,1 -> 1; 1,0 -> 1.", "XOR."]
	},
	{
		"id": "A3_03", "phase": PHASE_DETECTION, "gate": GATE_NOR,
		"a_text": "SENSE_A", "b_text": "SENSE_B",
		"witness_text": "Система спокойна (1), только если [b]ОБА[/b] датчика молчат (0).",
		"min_seen": 3, "hints": ["1 только при (0,0).", "NOR (Стрелка Пирса)."]
	},
	{
		"id": "A3_04", "phase": PHASE_DETECTION, "gate": GATE_AND,
		"a_text": "KEY_1", "b_text": "KEY_2",
		"witness_text": "Сейф открылся (1). Значит, [b]ОБА[/b] ключа повернули.",
		"min_seen": 2, "hints": ["Нужны оба.", "AND."]
	},
	{
		"id": "A3_05", "phase": PHASE_DETECTION, "gate": GATE_OR,
		"a_text": "BTN_1", "b_text": "BTN_2",
		"witness_text": "Лифт поехал (1). Кто-то нажал кнопку [b]ЗДЕСЬ[/b] или [b]ТАМ[/b].",
		"min_seen": 2, "hints": ["Хватит одной кнопки.", "OR."]
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
	gate_selector.add_item(" ¬  (NOT)", 3)
	gate_selector.add_item(" ⊕  (XOR)", 4)
	gate_selector.add_item(" |  (NAND)", 5)
	gate_selector.add_item(" ↓  (NOR)", 6)

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
		_show_feedback("Не тыкай. Проверь факты.", Color(1, 0.5, 0))
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
		GATE_NOT: gate_symbol = "¬ (NOT)"
		GATE_XOR: gate_symbol = "⊕ (XOR)"
		GATE_NAND: gate_symbol = "| (NAND)"
		GATE_NOR: gate_symbol = "↓ (NOR)"

	status_label.text = "SAFE MODE: правильный вентиль — %s. Система сброшена." % gate_symbol
	_show_feedback("SAFE MODE ACTIVATED", Color(1, 0.5, 0))

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
