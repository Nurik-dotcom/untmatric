extends Control

enum GateType { NONE, AND, OR, NOT, XOR, NOR }

var input_a: bool = false
var input_b: bool = false
var selected_gate: GateType = GateType.NONE
var current_quest_index: int = 0

@onready var lamp = $BoardContainer/Lamp
@onready var wire_a = $BoardContainer/WiresLayer/InputA_Wire
@onready var wire_b = $BoardContainer/WiresLayer/InputB_Wire
@onready var wire_out = $BoardContainer/WiresLayer/Output_Wire
@onready var result_label = $ResultLabel
@onready var hint_label = $HintLabel
@onready var story_label = $StoryLabel
@onready var gate_selector = $BoardContainer/GateSelector
@onready var input_a_btn = $BoardContainer/InputA_Btn
@onready var input_b_btn = $BoardContainer/InputB_Btn
@onready var next_button = $NextButton
@onready var back_button = $BackButton
@onready var click_player = $ClickPlayer

const RESULT_OK = "\u0423\u041b\u0418\u041a\u0410 \u041f\u041e\u0414\u0422\u0412\u0415\u0420\u0416\u0414\u0415\u041d\u0410"
const RESULT_BAD = "\u041f\u0420\u041e\u0422\u0418\u0412\u041e\u0420\u0415\u0427\u0418\u0415..."
const RESULT_WAIT = "\u0412\u042b\u0411\u0415\u0420\u0418\u0422\u0415 \u0412\u0415\u041d\u0422\u0418\u041b\u042c"
const RESULT_MISMATCH = "\u0412\u0415\u041d\u0422\u0418\u041b\u042c \u041d\u0415 \u0421\u041e\u041e\u0422\u0412\u0415\u0422\u0421\u0422\u0412\u0423\u0415\u0422 \u0421\u042e\u0416\u0415\u0422\u0423"
const RESULT_NEXT = "\u0421\u041b\u0415\u0414\u0423\u042e\u0429\u0415\u0415 \u0414\u0415\u041b\u041e \u0414\u041e\u0421\u0422\u0423\u041f\u041d\u041e"

const INPUT_A_ON = "\u0423\u043b\u0438\u043a\u0430 A: 1"
const INPUT_A_OFF = "\u0423\u043b\u0438\u043a\u0430 A: 0"
const INPUT_B_ON = "\u0423\u043b\u0438\u043a\u0430 B: 1"
const INPUT_B_OFF = "\u0423\u043b\u0438\u043a\u0430 B: 0"

const GATE_NONE = "\u0412\u044b\u0431\u043e\u0440 \u0432\u0435\u043d\u0442\u0438\u043b\u044f"
const GATE_AND = "&"
const GATE_OR = "\u22651"
const GATE_NOT = "1"
const GATE_XOR = "=1"
const GATE_NOR = "NOR"

var quests = [
	{
		"id": "A1",
		"story": "\u0421\u0432\u0438\u0434\u0435\u0442\u0435\u043b\u044c: \u00ab\u041e\u0445\u0440\u0430\u043d\u043d\u0430\u044f \u043b\u0430\u043c\u043f\u0430 \u0437\u0430\u0433\u043e\u0440\u0430\u0435\u0442\u0441\u044f \u0442\u043e\u043b\u044c\u043a\u043e \u0442\u043e\u0433\u0434\u0430, \u043a\u043e\u0433\u0434\u0430 \u0438 \u0434\u0432\u0435\u0440\u044c \u043e\u0442\u043a\u0440\u044b\u0442\u0430, \u0438 \u0434\u0430\u0442\u0447\u0438\u043a \u0434\u0432\u0438\u0436\u0435\u043d\u0438\u044f \u0430\u043a\u0442\u0438\u0432\u0435\u043d\u00bb.",
		"logic_type": GateType.AND,
		"hint": "\u041a\u043e\u043d\u044a\u044e\u043d\u043a\u0446\u0438\u044f: \u0442\u043e\u043a \u0438\u0434\u0435\u0442 \u0442\u043e\u043b\u044c\u043a\u043e \u043f\u0440\u0438 \u0434\u0432\u0443\u0445 \u0441\u0438\u0433\u043d\u0430\u043b\u0430\u0445."
	},
	{
		"id": "A2",
		"story": "\u0418\u043d\u0441\u043f\u0435\u043a\u0442\u043e\u0440: \u00ab\u0421\u0438\u0441\u0442\u0435\u043c\u0430 \u043f\u043e\u0434\u0430\u0441\u0442 \u0441\u0438\u0433\u043d\u0430\u043b, \u0435\u0441\u043b\u0438 \u0432\u043e\u0440 \u0437\u0430\u043b\u0435\u0437\u0435\u0442 \u043b\u0438\u0431\u043e \u0447\u0435\u0440\u0435\u0437 \u043e\u043a\u043d\u043e, \u043b\u0438\u0431\u043e \u0447\u0435\u0440\u0435\u0437 \u0447\u0435\u0440\u0434\u0430\u043a (\u0445\u043e\u0442\u044f \u0431\u044b \u043e\u0434\u0438\u043d \u043f\u0443\u0442\u044c)\u00bb.",
		"logic_type": GateType.OR,
		"hint": "\u0414\u0438\u0437\u044a\u044e\u043d\u043a\u0446\u0438\u044f: \u0434\u043e\u0441\u0442\u0430\u0442\u043e\u0447\u043d\u043e \u043e\u0434\u043d\u043e\u0433\u043e \u0441\u0438\u0433\u043d\u0430\u043b\u0430."
	},
	{
		"id": "A3",
		"story": "\u0422\u0435\u0445\u043d\u0438\u043a: \u00ab\u042d\u0442\u043e\u0442 \u0438\u043d\u0432\u0435\u0440\u0442\u043e\u0440 \u0441\u043b\u043e\u043c\u0430\u043d. \u0415\u0441\u043b\u0438 \u043d\u0430 \u0432\u0445\u043e\u0434\u0435 \u0418\u0441\u0442\u0438\u043d\u0430, \u043e\u043d \u0432\u044b\u0434\u0430\u0435\u0442 \u041b\u043e\u0436\u044c\u00bb.",
		"logic_type": GateType.NOT,
		"hint": "\u041e\u0442\u0440\u0438\u0446\u0430\u043d\u0438\u0435: \u0432\u0441\u0435 \u043d\u0430\u043e\u0431\u043e\u0440\u043e\u0442."
	},
	{
		"id": "A4",
		"story": "\u0414\u0435\u0442\u0435\u043a\u0442\u0438\u0432: \u00ab\u0421\u0432\u0435\u0442 \u0432 \u043a\u043e\u0440\u0438\u0434\u043e\u0440\u0435 \u043c\u0438\u0433\u0430\u0435\u0442 \u0442\u043e\u043b\u044c\u043a\u043e \u043a\u043e\u0433\u0434\u0430 \u043a\u043d\u043e\u043f\u043a\u0438 \u0432 \u0440\u0430\u0437\u043d\u044b\u0445 \u043f\u043e\u043b\u043e\u0436\u0435\u043d\u0438\u044f\u0445 (\u043e\u0434\u043d\u0430 \u043d\u0430\u0436\u0430\u0442\u0430, \u0434\u0440\u0443\u0433\u0430\u044f \u043d\u0435\u0442)\u00bb.",
		"logic_type": GateType.XOR,
		"hint": "\u0418\u0441\u043a\u043b\u044e\u0447\u0430\u044e\u0449\u0435\u0435 \u0418\u041b\u0418: \u0438\u0441\u0442\u0438\u043d\u0430 \u043f\u0440\u0438 \u0440\u0430\u0437\u043d\u044b\u0445 \u0432\u0445\u043e\u0434\u0430\u0445."
	}
]

func _ready():
	_setup_gate_selector()
	_setup_inputs()
	setup_quest(current_quest_index)

func _setup_gate_selector():
	gate_selector.clear()
	gate_selector.add_item(GATE_NONE, GateType.NONE)
	gate_selector.add_item(GATE_AND, GateType.AND)
	gate_selector.add_item(GATE_OR, GateType.OR)
	gate_selector.add_item(GATE_NOT, GateType.NOT)
	gate_selector.add_item(GATE_XOR, GateType.XOR)
	gate_selector.add_item(GATE_NOR, GateType.NOR)

func _setup_inputs():
	back_button.text = "\u041d\u0430\u0437\u0430\u0434"
	next_button.text = "\u0421\u041b\u0415\u0414\u0423\u042e\u0429\u0415\u0415 \u0414\u0415\u041b\u041e"
	result_label.text = RESULT_WAIT
	hint_label.text = ""

func setup_quest(idx: int):
	if idx >= quests.size():
		idx = 0
	current_quest_index = idx
	var q = quests[idx]
	story_label.text = q.story
	input_a = false
	input_b = false

	selected_gate = GateType.NONE
	gate_selector.selected = 0
	lamp.color = Color(0.2, 0.2, 0.2)
	result_label.text = RESULT_WAIT
	_update_input_labels()
	result_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	hint_label.text = ""
	next_button.visible = false
	update_wires()

func _update_input_labels():
	input_a_btn.text = INPUT_A_ON if input_a else INPUT_A_OFF
	input_b_btn.text = INPUT_B_ON if input_b else INPUT_B_OFF

func check_logic(a: bool, b: bool, gate: GateType) -> bool:
	var current_output = false
	match gate:
		GateType.AND:
			current_output = a and b
		GateType.OR:
			current_output = a or b
		GateType.NOT:
			current_output = not a
		GateType.XOR:
			current_output = a != b
		GateType.NOR:
			current_output = not (a or b)
		_:
			current_output = false

	return current_output

func _on_gate_selected(index):
	selected_gate = gate_selector.get_item_id(index) as GateType
	update_wires()

	if selected_gate == GateType.NONE:
		lamp.color = Color(0.2, 0.2, 0.2)
		result_label.text = RESULT_WAIT
		hint_label.text = ""
		next_button.visible = false
		return

	var is_correct = _validate_gate_against_story(selected_gate)

	if is_correct:
		result_label.add_theme_color_override("font_color", Color(0.7, 1, 0.7))
		result_label.text = RESULT_OK
		hint_label.text = RESULT_NEXT
		next_button.visible = true
		_flash_lamp()
	else:
		result_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
		result_label.text = RESULT_MISMATCH
		hint_label.text = quests[current_quest_index].hint
		next_button.visible = false

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _validate_gate_against_story(gate: GateType) -> bool:
	var q = quests[current_quest_index]
	var expected_gate = q.logic_type

	for a in [false, true]:
		for b in [false, true]:
			var expected = check_logic(a, b, expected_gate)
			var actual = check_logic(a, b, gate)
			if actual != expected:
				return false
	return true

func _on_input_a_toggled(pressed: bool):
	input_a = pressed
	_play_click()
	_update_input_labels()
	update_wires()

func _on_input_b_toggled(pressed: bool):
	input_b = pressed
	_play_click()
	_update_input_labels()
	update_wires()

func update_wires():
	var on_color = Color(0.9, 0.9, 0.9)
	var off_color = Color(0.2, 0.2, 0.2)
	wire_a.default_color = on_color if input_a else off_color
	wire_b.default_color = on_color if input_b else off_color

	var out_on = false
	if selected_gate != GateType.NONE:
		out_on = check_logic(input_a, input_b, selected_gate)
	wire_out.default_color = on_color if out_on else off_color
	lamp.color = Color(1, 1, 1) if out_on else Color(0.15, 0.15, 0.15)

func _flash_lamp():
	lamp.modulate = Color(1, 1, 1, 1)
	var tween = create_tween()
	tween.tween_property(lamp, "modulate", Color(1, 1, 1, 1), 0.05)
	tween.tween_property(lamp, "modulate", Color(1, 1, 1, 0.4), 0.2)
	tween.tween_property(lamp, "modulate", Color(1, 1, 1, 1), 0.2)

func _play_click():
	if click_player.stream:
		click_player.play()

func _on_next_button_pressed():
	current_quest_index += 1
	if current_quest_index >= quests.size():
		get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")
		return
	setup_quest(current_quest_index)
