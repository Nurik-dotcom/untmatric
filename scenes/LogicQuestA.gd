extends Control

enum GateType { NONE, AND, OR, NOT, XOR, NOR }

var input_a: bool = false
var input_b: bool = false
var target_output: bool = true
var selected_gate: GateType = GateType.NONE
var current_quest_idx: int = 0

@onready var lamp = $BoardContainer/Lamp
@onready var result_label = $ResultLabel
@onready var story_label = $StoryLabel
@onready var gate_selector = $BoardContainer/GateSelector
@onready var input_a_btn = $BoardContainer/InputA_Btn
@onready var input_b_btn = $BoardContainer/InputB_Btn
@onready var back_button = $BackButton

const STORY_1 = "\u0421\u0432\u0438\u0434\u0435\u0442\u0435\u043b\u044c \u0443\u0442\u0432\u0435\u0440\u0436\u0434\u0430\u0435\u0442: \u00ab\u0421\u0432\u0435\u0442 \u0432\u043a\u043b\u044e\u0447\u0438\u043b\u0441\u044f, \u043a\u043e\u0433\u0434\u0430 \u0441\u0440\u0430\u0431\u043e\u0442\u0430\u043b\u0438 \u0438 \u0434\u0432\u0435\u0440\u044c, \u0438 \u043e\u043a\u043d\u043e\u00bb."
const STORY_2 = "\u0414\u0435\u0442\u0435\u043a\u0442\u043e\u0440 \u0434\u043e\u043b\u0436\u0435\u043d \u043f\u043e\u043a\u0430\u0437\u0430\u0442\u044c \u041b\u041e\u0416\u042c, \u0435\u0441\u043b\u0438 \u0445\u043e\u0442\u044f \u0431\u044b \u043e\u0434\u0438\u043d \u0434\u0430\u0442\u0447\u0438\u043a \u0430\u043a\u0442\u0438\u0432\u0435\u043d. (\u042d\u0442\u043e NOR)"
const RESULT_OK = "\u0423\u041b\u0418\u041a\u0410 \u041f\u041e\u0414\u0422\u0412\u0415\u0420\u0416\u0414\u0415\u041d\u0410"
const RESULT_BAD = "\u041f\u0420\u041e\u0422\u0418\u0412\u041e\u0420\u0415\u0427\u0418\u0415..."
const RESULT_WAIT = "\u0412\u042b\u0411\u0415\u0420\u0418\u0422\u0415 \u0412\u0415\u041d\u0422\u0418\u041b\u042c"
const RESULT_MISMATCH = "\u0412\u0415\u041d\u0422\u0418\u041b\u042c \u041d\u0415 \u0421\u041e\u041e\u0422\u0412\u0415\u0422\u0421\u0422\u0412\u0423\u0415\u0422 \u0421\u042e\u0416\u0415\u0422\u0423"

const INPUT_A_ON = "\u0414\u0430\u0442\u0447\u0438\u043a \u0434\u0432\u0435\u0440\u0438: \u0412\u041a\u041b"
const INPUT_A_OFF = "\u0414\u0430\u0442\u0447\u0438\u043a \u0434\u0432\u0435\u0440\u0438: \u0412\u042b\u041a\u041b"
const INPUT_B_ON = "\u0414\u0430\u0442\u0447\u0438\u043a \u043e\u043a\u043d\u0430: \u0412\u041a\u041b"
const INPUT_B_OFF = "\u0414\u0430\u0442\u0447\u0438\u043a \u043e\u043a\u043d\u0430: \u0412\u042b\u041a\u041b"

const GATE_NONE = "\u0412\u044b\u0431\u043e\u0440 \u0432\u0435\u043d\u0442\u0438\u043b\u044f"
const GATE_AND = "&"
const GATE_OR = "\u22651"
const GATE_NOT = "1"
const GATE_XOR = "=1"
const GATE_NOR = "NOR"

var quests = [
	{
		"text": STORY_1,
		"a": true, "b": true, "target": true,
		"truth": { "00": false, "01": false, "10": false, "11": true }
	},
	{
		"text": STORY_2,
		"a": true, "b": false, "target": false,
		"truth": { "00": true, "01": false, "10": false, "11": false }
	}
]

func _ready():
	_setup_gate_selector()
	_setup_inputs()
	setup_quest(0)

func _setup_gate_selector():
	gate_selector.clear()
	gate_selector.add_item(GATE_NONE, GateType.NONE)
	gate_selector.add_item(GATE_AND, GateType.AND)
	gate_selector.add_item(GATE_OR, GateType.OR)
	gate_selector.add_item(GATE_NOT, GateType.NOT)
	gate_selector.add_item(GATE_XOR, GateType.XOR)
	gate_selector.add_item(GATE_NOR, GateType.NOR)

func _setup_inputs():
	input_a_btn.disabled = false
	input_b_btn.disabled = false
	back_button.text = "\u041d\u0430\u0437\u0430\u0434"
	result_label.text = RESULT_WAIT
	input_a_btn.pressed.connect(_on_input_a_pressed)
	input_b_btn.pressed.connect(_on_input_b_pressed)

func setup_quest(idx: int):
	if idx >= quests.size():
		idx = 0
	current_quest_idx = idx
	var q = quests[idx]
	story_label.text = q.text
	input_a = q.a
	input_b = q.b
	target_output = q.target

	selected_gate = GateType.NONE
	gate_selector.selected = 0
	lamp.color = Color(0.2, 0.2, 0.2)
	result_label.text = RESULT_WAIT
	_update_input_labels()
	result_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

func _update_input_labels():
	input_a_btn.text = INPUT_A_ON if input_a else INPUT_A_OFF
	input_b_btn.text = INPUT_B_ON if input_b else INPUT_B_OFF

func check_logic() -> bool:
	var current_output = false
	match selected_gate:
		GateType.AND:
			current_output = input_a and input_b
		GateType.OR:
			current_output = input_a or input_b
		GateType.NOT:
			current_output = not input_a
		GateType.XOR:
			current_output = input_a != input_b
		GateType.NOR:
			current_output = not (input_a or input_b)
		_:
			current_output = false

	return current_output

func _on_gate_selected(index):
	selected_gate = gate_selector.get_item_id(index) as GateType

	if selected_gate == GateType.NONE:
		lamp.color = Color(0.2, 0.2, 0.2)
		result_label.text = RESULT_WAIT
		return

	var is_correct = _validate_gate_against_story(selected_gate)

	lamp.color = Color(1, 1, 1) if is_correct else Color(0.15, 0.15, 0.15)

	if is_correct:
		result_label.add_theme_color_override("font_color", Color(0.7, 1, 0.7))
		result_label.text = RESULT_OK
	else:
		result_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
		result_label.text = RESULT_MISMATCH

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _on_input_a_pressed():
	input_a = not input_a
	_update_input_labels()

func _on_input_b_pressed():
	input_b = not input_b
	_update_input_labels()

func _validate_gate_against_story(gate: GateType) -> bool:
	var q = quests[current_quest_idx]
	if "truth" not in q:
		return check_logic() == target_output

	var saved_a = input_a
	var saved_b = input_b
	var saved_gate = selected_gate
	selected_gate = gate

	var truth = q.truth
	for a in [false, true]:
		for b in [false, true]:
			input_a = a
			input_b = b
			var key = str(int(a)) + str(int(b))
			if key in truth:
				var expected = truth[key]
				var actual = check_logic()
				if actual != expected:
					input_a = saved_a
					input_b = saved_b
					selected_gate = saved_gate
					return false

	input_a = saved_a
	input_b = saved_b
	selected_gate = saved_gate
	_update_input_labels()
	return true
