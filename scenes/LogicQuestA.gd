extends Control

enum GateType { NONE, AND, OR, NOT, XOR, NOR }

const PHASE_TRAINING = "TRAINING"
const PHASE_TRANSLATION = "TRANSLATION"
const PHASE_DETECTION = "DETECTION"

const WORD_AND = "\u0418"
const WORD_OR = "\u0418\u041b\u0418"
const WORD_NOT = "\u041d\u0415"

const SYM_AND = "&"
const SYM_OR = "1"
const SYM_NOT = "\u00ac"
const SYM_XOR = "\u2295"
const SYM_NOR = "\u22bd"

const GATE_NONE_LABEL = "\u0412\u044b\u0431\u043e\u0440 \u0432\u0435\u043d\u0442\u0438\u043b\u044f"

const RESULT_OK = "\u0423\u041b\u0418\u041a\u0410 \u041f\u041e\u0414\u0422\u0412\u0415\u0420\u0416\u0414\u0415\u041d\u0410"
const RESULT_WAIT = "\u0412\u042b\u0411\u0415\u0420\u0418\u0422\u0415 \u0412\u0415\u041d\u0422\u0418\u041b\u042c"
const RESULT_MISMATCH = "\u0412\u0415\u041d\u0422\u0418\u041b\u042c \u041d\u0415 \u0421\u041e\u041e\u0422\u0412\u0415\u0422\u0421\u0422\u0412\u0423\u0415\u0422 \u0421\u042e\u0416\u0415\u0422\u0423"
const RESULT_NEXT = "\u0421\u041b\u0415\u0414\u0423\u042e\u0429\u0415\u0415 \u0414\u0415\u041b\u041e \u0414\u041e\u0421\u0422\u0423\u041f\u041d\u041e"
const RESULT_DONE = "\u0410\u041f\u0420\u041e\u0411\u0410\u0426\u0418\u042f \u0423\u0420\u041e\u0412\u041d\u042f A \u041f\u0420\u041e\u0419\u0414\u0415\u041d\u0410"

const INPUT_A_ON = "\u0423\u043b\u0438\u043a\u0430 A: 1"
const INPUT_A_OFF = "\u0423\u043b\u0438\u043a\u0430 A: 0"
const INPUT_B_ON = "\u0423\u043b\u0438\u043a\u0430 B: 1"
const INPUT_B_OFF = "\u0423\u043b\u0438\u043a\u0430 B: 0"

var input_a: bool = false
var input_b: bool = false
var selected_gate: GateType = GateType.NONE
var current_quest_index: int = 0

@onready var story_simple = $StoryLabelSimple
@onready var story_cheat = $StoryLabelCheat
@onready var story_noir = $StoryLabelNoir
@onready var lamp = $BoardContainer/Lamp
@onready var wire_a = $BoardContainer/WiresLayer/InputA_Wire
@onready var wire_b = $BoardContainer/WiresLayer/InputB_Wire
@onready var wire_out = $BoardContainer/WiresLayer/Output_Wire
@onready var result_label = $ResultLabel
@onready var hint_label = $HintLabel
@onready var gate_selector = $BoardContainer/GateSelector
@onready var input_a_btn = $BoardContainer/InputA_Btn
@onready var input_b_btn = $BoardContainer/InputB_Btn
@onready var next_button = $NextButton
@onready var back_button = $BackButton
@onready var click_player = $ClickPlayer

var quests = [
	# --- PHASE 1: TRAINING ---
	{
		"phase": PHASE_TRAINING,
		"story": "\u0422\u044b \u0432\u044b\u0439\u0434\u0435\u0448\u044c \u0441\u0443\u0445\u0438\u043c \u0438\u0437 \u0432\u043e\u0434\u044b, \u0435\u0441\u043b\u0438 \u043d\u0430\u0434\u0435\u043d\u0435\u0448\u044c \u043f\u043b\u0430\u0449 [ ? ] \u0432\u043e\u0437\u044c\u043c\u0435\u0448\u044c \u0437\u043e\u043d\u0442.",
		"gate_options": [WORD_AND, WORD_OR],
		"correct_gate": "OR",
		"hint": "\u0422\u0435\u0431\u0435 \u043d\u0443\u0436\u043d\u043e \u0425\u041e\u0422\u042f \u0411\u042b \u041e\u0414\u041d\u041e \u0443\u0441\u043b\u043e\u0432\u0438\u0435."
	},
	{
		"phase": PHASE_TRAINING,
		"story": "\u0414\u0432\u0435\u0440\u044c \u043e\u0442\u043a\u0440\u043e\u0435\u0442\u0441\u044f, \u0435\u0441\u043b\u0438 \u0443 \u0442\u0435\u0431\u044f \u0435\u0441\u0442\u044c \u043a\u043b\u044e\u0447 [ ? ] \u0442\u044b \u0437\u043d\u0430\u0435\u0448\u044c \u043a\u043e\u0434.",
		"gate_options": [WORD_AND, WORD_OR],
		"correct_gate": "AND",
		"hint": "\u0411\u0435\u0437 \u043e\u0431\u043e\u0438\u0445 \u0443\u0441\u043b\u043e\u0432\u0438\u0439 \u0437\u0430\u043c\u043e\u043a \u043d\u0435 \u043f\u043e\u0434\u0434\u0430\u0441\u0442\u0441\u044f."
	},

	# --- PHASE 2: TRANSLATION ---
	{
		"phase": PHASE_TRANSLATION,
		"story": "\u0412 \u0442\u0435\u0440\u043c\u0438\u043d\u0430\u043b\u0430\u0445 \u043b\u043e\u0433\u0438\u043a\u0430 \u2018\u0418\u2019 (\u043e\u0431\u0430 \u0443\u0441\u043b\u043e\u0432\u0438\u044f \u0441\u0440\u0430\u0437\u0443) \u043e\u0431\u043e\u0437\u043d\u0430\u0447\u0430\u0435\u0442\u0441\u044f \u0441\u0438\u043c\u0432\u043e\u043b\u043e\u043c \u2018&\u2019. \u041d\u0430\u0439\u0434\u0438 \u0435\u0433\u043e.",
		"gate_options": [SYM_AND, SYM_OR, SYM_NOT],
		"correct_gate": "AND",
		"hint": "\u0410\u043c\u043f\u0435\u0440\u0441\u0430\u043d\u0434 (&) \u2014 \u044d\u0442\u043e \u0442\u0435\u0445\u043d\u0438\u0447\u0435\u0441\u043a\u043e\u0435 \u2018\u0418\u2019."
	},

	# --- PHASE 3: DETECTION ---
	{
		"phase": PHASE_DETECTION,
		"story": "\u0421\u0432\u0438\u0434\u0435\u0442\u0435\u043b\u044c: \u2018\u0421\u0432\u0435\u0442 \u0432 \u0434\u043e\u043f\u0440\u043e\u0441\u043d\u043e\u0439 \u0437\u0430\u0436\u0435\u0433\u0441\u044f \u0442\u043e\u043b\u044c\u043a\u043e \u043a\u043e\u0433\u0434\u0430 \u0441\u0440\u0430\u0431\u043e\u0442\u0430\u043b\u0438 \u0434\u0430\u0442\u0447\u0438\u043a \u0434\u0432\u0435\u0440\u0438 \u0418 \u0434\u0430\u0442\u0447\u0438\u043a \u043e\u043a\u043d\u0430\u2019.",
		"gate_options": [SYM_AND, SYM_OR, SYM_NOT, SYM_XOR],
		"correct_gate": "AND",
		"hint": "\u041f\u0440\u043e\u0432\u0435\u0440\u044c \u043f\u043e\u043a\u0430\u0437\u0430\u043d\u0438\u044f \u043d\u0430 \u0441\u043e\u0432\u043f\u0430\u0434\u0435\u043d\u0438\u0435 \u0441 \u043b\u043e\u0433\u0438\u043a\u043e\u0439 '&'."
	},
	{
		"phase": PHASE_DETECTION,
		"story": "\u0414\u0435\u0442\u0435\u043a\u0442\u0438\u0432: \u2018\u0421\u0438\u0433\u043d\u0430\u043b\u0438\u0437\u0430\u0446\u0438\u044f \u0434\u043e\u043b\u0436\u043d\u0430 \u043c\u043e\u043b\u0447\u0430\u0442\u044c (0), \u0435\u0441\u043b\u0438 \u041e\u0411\u0410 \u043a\u043e\u0434\u0430 \u0432\u0432\u0435\u0434\u0435\u043d\u044b \u0432\u0435\u0440\u043d\u043e (1,1)\u2019.",
		"gate_options": [SYM_AND, SYM_OR, SYM_NOT, SYM_NOR],
		"correct_gate": "NOR",
		"hint": "\u0418\u043d\u0432\u0435\u0440\u0442\u0438\u0440\u0443\u0439 \u0440\u0435\u0437\u0443\u043b\u044c\u0442\u0430\u0442 \u0441\u043b\u043e\u0436\u0435\u043d\u0438\u044f."
	}
]

func _ready():
	_setup_inputs()
	setup_quest(current_quest_index)

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
	_set_story_phase(q)
	_setup_gate_selector(q)

	var inputs = q.get("inputs", [false, false])
	input_a = inputs[0]
	input_b = inputs[1]
	_update_input_labels()
	input_a_btn.button_pressed = input_a
	input_b_btn.button_pressed = input_b

	selected_gate = GateType.NONE
	gate_selector.selected = 0
	result_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	result_label.text = RESULT_WAIT
	hint_label.text = ""
	next_button.visible = false
	update_wires(input_a, input_b, false)

func _set_story_phase(q):
	story_simple.visible = true
	story_cheat.visible = false
	story_noir.visible = false

	match q.phase:
		PHASE_TRAINING:
			story_simple.modulate = Color.CYAN
		PHASE_TRANSLATION:
			story_simple.modulate = Color.YELLOW
		_:
			story_simple.modulate = Color.WHITE

	story_simple.text = q.story

func _setup_gate_selector(q):
	gate_selector.clear()
	gate_selector.add_item(GATE_NONE_LABEL, GateType.NONE)
	for opt in q.gate_options:
		gate_selector.add_item(opt, _gate_type_from_option(opt))

func _gate_type_from_name(name: String) -> GateType:
	match name:
		"AND": return GateType.AND
		"OR": return GateType.OR
		"NOT": return GateType.NOT
		"XOR": return GateType.XOR
		"NOR": return GateType.NOR
		_: return GateType.NONE

func _gate_type_from_option(option: String) -> GateType:
	match option:
		WORD_AND, SYM_AND: return GateType.AND
		WORD_OR, SYM_OR: return GateType.OR
		WORD_NOT, SYM_NOT: return GateType.NOT
		SYM_XOR: return GateType.XOR
		SYM_NOR, "NOR": return GateType.NOR
		_: return GateType.NONE

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
	var out_val = false
	if selected_gate != GateType.NONE:
		out_val = check_logic(input_a, input_b, selected_gate)
	update_wires(input_a, input_b, out_val)

	if selected_gate == GateType.NONE:
		result_label.text = RESULT_WAIT
		hint_label.text = ""
		next_button.visible = false
		return

	if _validate_gate_against_story(selected_gate):
		_on_quest_solved()
	else:
		_on_wrong_answer()

func _validate_gate_against_story(gate: GateType) -> bool:
	var q = quests[current_quest_index]
	var expected_gate = _gate_type_from_name(q.correct_gate)

	for a in [false, true]:
		for b in [false, true]:
			var expected = check_logic(a, b, expected_gate)
			var actual = check_logic(a, b, gate)
			if actual != expected:
				return false
	return true

func _on_quest_solved():
	result_label.add_theme_color_override("font_color", Color(0.7, 1, 0.7))
	result_label.text = RESULT_OK
	hint_label.text = RESULT_NEXT
	next_button.visible = true
	_flash_lamp()

func _on_wrong_answer():
	result_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	result_label.text = RESULT_MISMATCH
	hint_label.text = quests[current_quest_index].hint
	next_button.visible = false

	# Global penalty for mistakes
	GlobalMetrics.stability = max(0.0, GlobalMetrics.stability - 10.0)
	GlobalMetrics.stability_changed.emit(GlobalMetrics.stability, -10.0)

func _on_input_a_toggled(pressed: bool):
	input_a = pressed
	_play_click()
	_update_input_labels()
	_on_gate_selected(gate_selector.selected)

func _on_input_b_toggled(pressed: bool):
	input_b = pressed
	_play_click()
	_update_input_labels()
	_on_gate_selected(gate_selector.selected)

func update_wires(a_val: bool, b_val: bool, out_val: bool):
	var on_color = Color(1, 1, 1)
	var off_color = Color(0.2, 0.2, 0.2)
	wire_a.default_color = on_color if a_val else off_color
	wire_b.default_color = on_color if b_val else off_color
	wire_out.default_color = on_color if out_val else off_color
	lamp.color = Color(1, 1, 1) if out_val else Color(0.15, 0.15, 0.15)

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
	if current_quest_index < quests.size():
		setup_quest(current_quest_index)
	else:
		show_victory_screen()

func show_victory_screen():
	story_simple.visible = true
	story_cheat.visible = false
	story_noir.visible = false
	story_simple.text = RESULT_DONE
	$BoardContainer.visible = false
	next_button.visible = false
	result_label.text = RESULT_DONE
	hint_label.text = ""

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")
