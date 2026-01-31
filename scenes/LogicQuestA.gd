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
