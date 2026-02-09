extends Control

# Перечисления для типов вентилей
enum GateType { NONE, AND, OR, NOT, XOR }

# Состояние уровня
var input_a: bool = false
var input_b: bool = false
var target_output: bool = true # Чего мы хотим добиться
var selected_gate: GateType = GateType.NONE

@onready var lamp = $MainLayout/ContentArea/CircuitBoard/Lamp
@onready var result_label = $MainLayout/ResultContainer/ResultLabel
@onready var story_label = $MainLayout/ContentArea/StoryLabel
@onready var gate_selector = $MainLayout/ContentArea/CircuitBoard/GateSelector

# Данные для квестов уровня А
var quests = [
	{
		"text": "Свидетель: 'Свет включился, когда сработала И дверь, И окно'.",
		"a": true, "b": true, "target": true, "hint": "Нужна полная конъюнкция."
	},
	{
		"text": "Детектор должен показать ЛОЖЬ, если хотя бы один датчик активен.",
		"a": true, "b": false, "target": false, "hint": "Ищи инверсию или исключение."
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
	setup_quest(0)

func _setup_gate_selector():
	gate_selector.clear()
	gate_selector.add_item("ВЫБРАТЬ", GateType.NONE)
	gate_selector.add_item("& (И)", GateType.AND)
	gate_selector.add_item("≥1 (ИЛИ)", GateType.OR)
	gate_selector.add_item("1 (НЕ)", GateType.NOT)
	gate_selector.add_item("=1 (XOR)", GateType.XOR)

func setup_quest(idx):
	if idx >= quests.size(): idx = 0
	var q = quests[idx]
	story_label.text = q.text
	input_a = q.a
	input_b = q.b
	target_output = q.target

	# Reset state
	selected_gate = GateType.NONE
	gate_selector.selected = 0
	lamp.color = Color(0.2, 0.2, 0.2)
	result_label.text = "ОЖИДАНИЕ ВЫБОРА..."

# Сердце механики — расчет логики
func check_logic() -> bool:
	var current_output = false
	match selected_gate:
		GateType.AND:
			current_output = input_a and input_b
		GateType.OR:
			current_output = input_a or input_b
		GateType.NOT:
			current_output = not input_a # В уровне А для НЕ используем только один вход
		GateType.XOR:
			current_output = input_a != input_b

	return current_output

func _on_gate_selected(index):
	selected_gate = index as GateType

	if selected_gate == GateType.NONE:
		lamp.color = Color(0.2, 0.2, 0.2)
		result_label.text = "..."
		return

	var output = check_logic()
	var is_correct = (output == target_output)

	# Визуальный отклик в стиле нуар
	if output:
		lamp.color = Color.WHITE # Лампа "зажглась"
	else:
		lamp.color = Color(0.1, 0.1, 0.1) # Лампа погасла (но это может быть правильным ответом!)

	if is_correct:
		result_label.add_theme_color_override("font_color", Color.GREEN)
		result_label.text = "УЛИКА ПОДТВЕРЖДЕНА"
	else:
		result_label.add_theme_color_override("font_color", Color.RED)
		result_label.text = "ПРОТИВОРЕЧИЕ..."

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")
