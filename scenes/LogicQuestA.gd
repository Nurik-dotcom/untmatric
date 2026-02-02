extends Control

enum GateType { NONE, AND, OR, NOT, XOR, NOR, NAND }

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
const SYM_NAND = "NAND"

const GATE_NONE_LABEL = "\u0432\u044b\u0431\u0435\u0440\u0438..."

const RESULT_OK = "\u0414\u0415\u041b\u041e \u0417\u0410\u041a\u0420\u042b\u0422\u041e. \u041b\u041e\u0413\u0418\u041a\u0410 \u0412\u0415\u0420\u041d\u0410."
const RESULT_WAIT = "\u0412\u042b\u0411\u0415\u0420\u0418\u0422\u0415 \u0412\u0415\u041d\u0422\u0418\u041b\u042c"
const RESULT_MISMATCH = "\u041e\u0428\u0418\u0411\u041a\u0410! \u0421\u0422\u0410\u0411\u0418\u041b\u042c\u041d\u041e\u0421\u0422\u042c \u0421\u0418\u0421\u0422\u0415\u041c\u042b \u041f\u0410\u0414\u0410\u0415\u0422."
const RESULT_NEXT = "\u0421\u041b\u0415\u0414\u0423\u042e\u0429\u0415\u0415 \u0414\u0415\u041b\u041e \u0414\u041e\u0421\u0422\u0423\u041f\u041d\u041e"
const RESULT_DONE = "\u0410\u041f\u0420\u041e\u0411\u0410\u0426\u0418\u042f \u0423\u0420\u041e\u0412\u041d\u042f A \u041f\u0420\u041e\u0419\u0414\u0415\u041d\u0410"

var input_a: bool = false
var input_b: bool = false
var selected_gate: GateType = GateType.NONE
var current_quest_index: int = 0
var current_quest_data: Dictionary = {}

@onready var story_simple = $StoryLabelSimple
@onready var story_cheat = $StoryLabelCheat
@onready var story_noir = $StoryLabelNoir
@onready var background = $Background
@onready var lamp = $BoardContainer/Lamp
@onready var wire_a = $BoardContainer/WiresLayer/InputA_Wire
@onready var wire_b = $BoardContainer/WiresLayer/InputB_Wire
@onready var wire_out = $BoardContainer/WiresLayer/Output_Wire
@onready var result_label = $ResultLabel
@onready var hint_label = $HintLabel
@onready var gate_selector = $BoardContainer/GateSelector
@onready var input_a_btn = $BoardContainer/InputA_Btn
@onready var input_b_btn = $BoardContainer/InputB_Btn
@onready var lamp_label = $BoardContainer/Lamp/LampLabel
@onready var next_button = $NextButton
@onready var back_button = $BackButton
@onready var click_player = $ClickPlayer
@onready var game_over_panel = $GameOverPanel
@onready var game_over_label = $GameOverPanel/CenterContainer/VBox/Title
@onready var game_over_button = $GameOverPanel/CenterContainer/VBox/RestartButton

var quests = [
	# --- PHASE 1: TRAINING ---
	{"phase": PHASE_TRAINING, "story": "\u041c\u0430\u0448\u0438\u043d\u0430 \u0437\u0430\u0432\u0435\u0434\u0435\u0442\u0441\u044f, \u0435\u0441\u043b\u0438 \u0435\u0441\u0442\u044c \u041a\u041b\u042e\u0427 [ ? ] \u043d\u0430\u0436\u0430\u0442\u0430 \u043a\u043d\u043e\u043f\u043a\u0430 \u0421\u0422\u0410\u0420\u0422.", "label_a": "\u041a\u041b\u042e\u0427", "label_b": "\u0421\u0422\u0410\u0420\u0422", "out_name": "\u0417\u0410\u0416\u0418\u0413\u0410\u041d\u0418\u0415", "gate_type": GateType.AND},
	{"phase": PHASE_TRAINING, "story": "\u0412\u044b \u043f\u0440\u043e\u043c\u043e\u043a\u043d\u0435\u0442\u0435, \u0435\u0441\u043b\u0438 \u0438\u0434\u0435\u0442 \u0414\u041e\u0416\u0414\u042c [ ? ] \u0438\u0434\u0435\u0442 \u0421\u041d\u0415\u0413 (\u0437\u043e\u043d\u0442\u0430 \u043d\u0435\u0442).", "label_a": "\u0414\u041e\u0416\u0414\u042c", "label_b": "\u0421\u041d\u0415\u0413", "out_name": "\u041f\u0420\u041e\u041c\u041e\u041a\u0410\u041d\u0418\u0415", "gate_type": GateType.OR},
	{"phase": PHASE_TRAINING, "story": "\u0412\u0445\u043e\u0434 \u0432 \u043f\u043e\u0447\u0442\u0443 \u0440\u0430\u0437\u0440\u0435\u0448\u0435\u043d, \u0435\u0441\u043b\u0438 \u0432\u0432\u0435\u0434\u0435\u043d \u041f\u0410\u0420\u041e\u041b\u042c [ ? ] \u043f\u0440\u043e\u0439\u0434\u0435\u043d \u0422\u0415\u041b\u0415\u0424\u041e\u041d.", "label_a": "\u041f\u0410\u0420\u041e\u041b\u042c", "label_b": "\u0422\u0415\u041b\u0415\u0424\u041e\u041d", "out_name": "\u0414\u041e\u0421\u0422\u0423\u041f", "gate_type": GateType.AND},
	{"phase": PHASE_TRAINING, "story": "\u0421\u0432\u0435\u0442 \u0432 \u043a\u043e\u0440\u0438\u0434\u043e\u0440\u0435 \u0433\u043e\u0440\u0438\u0442, \u0435\u0441\u043b\u0438 \u043d\u0430\u0436\u0430\u0442 \u043f\u0435\u0440\u0432\u044b\u0439 \u0412\u042b\u041a\u041b\u042e\u0427\u0410\u0422\u0415\u041b\u042c [ ? ] \u0432\u0442\u043e\u0440\u043e\u0439.", "label_a": "\u0412\u042b\u041a\u041b_1", "label_b": "\u0412\u042b\u041a\u041b_2", "out_name": "\u0421\u0412\u0415\u0422", "gate_type": GateType.OR},
	{"phase": PHASE_TRAINING, "story": "\u0414\u0435\u0442\u0435\u043a\u0442\u043e\u0440 \u043b\u0436\u0438 \u2014 \u044d\u0442\u043e \u0438\u043d\u0432\u0435\u0440\u0442\u043e\u0440. \u041e\u043d \u0433\u043e\u0432\u043e\u0440\u0438\u0442 \u0414\u0410, \u0435\u0441\u043b\u0438 \u043d\u0430 \u0432\u0445\u043e\u0434\u0435 \u041d\u0415\u0422.", "label_a": "\u0421\u0418\u0413\u041d\u0410\u041b", "label_b": "---", "out_name": "\u041e\u0422\u0412\u0415\u0422", "gate_type": GateType.NOT},

	# --- PHASE 2: TRANSLATION ---
	{"phase": PHASE_TRANSLATION, "story": "\u0412 \u0415\u041d\u0422 \u043b\u043e\u0433\u0438\u0447\u0435\u0441\u043a\u043e\u0435 '\u0418' (\u041a\u043e\u043d\u044a\u044e\u043d\u043a\u0446\u0438\u044f) \u043e\u0431\u043e\u0437\u043d\u0430\u0447\u0430\u0435\u0442\u0441\u044f \u0437\u043d\u0430\u043a\u043e\u043c &. \u041d\u0430\u0439\u0434\u0438 \u0435\u0433\u043e.", "label_a": "A", "label_b": "B", "out_name": "F(A,B)", "gate_type": GateType.AND},
	{"phase": PHASE_TRANSLATION, "story": "\u041b\u043e\u0433\u0438\u0447\u0435\u0441\u043a\u043e\u0435 '\u0418\u041b\u0418' (\u0414\u0438\u0437\u044a\u044e\u043d\u043a\u0446\u0438\u044f) \u043e\u0431\u043e\u0437\u043d\u0430\u0447\u0430\u0435\u0442\u0441\u044f \u0437\u043d\u0430\u043a\u043e\u043c 1 \u0438\u043b\u0438 v. \u0412\u044b\u0431\u0435\u0440\u0438 \u0435\u0433\u043e.", "label_a": "A", "label_b": "B", "out_name": "F(A,B)", "gate_type": GateType.OR},
	{"phase": PHASE_TRANSLATION, "story": "\u0418\u043d\u0432\u0435\u0440\u0441\u0438\u044f (\u041e\u0442\u0440\u0438\u0446\u0430\u043d\u0438\u0435) \u043e\u0431\u043e\u0437\u043d\u0430\u0447\u0430\u0435\u0442\u0441\u044f \u0437\u043d\u0430\u043a\u043e\u043c \u00ac. \u041d\u0430\u0439\u0434\u0438 \u044d\u0442\u043e\u0442 \u0441\u0438\u043c\u0432\u043e\u043b.", "label_a": "A", "label_b": "---", "out_name": "not A", "gate_type": GateType.NOT},
	{"phase": PHASE_TRANSLATION, "story": "\u0421\u043b\u043e\u0436\u0435\u043d\u0438\u0435 \u043f\u043e \u043c\u043e\u0434\u0443\u043b\u044e 2 (\u0418\u0441\u043a\u043b\u044e\u0447\u0430\u044e\u0449\u0435\u0435 \u0418\u041b\u0418) \u2014 \u044d\u0442\u043e \u0437\u043d\u0430\u043a \u2295. \u0412\u044b\u0431\u0435\u0440\u0438 \u0435\u0433\u043e.", "label_a": "A", "label_b": "B", "out_name": "F", "gate_type": GateType.XOR},
	{"phase": PHASE_TRANSLATION, "story": "\u0421\u0442\u0440\u0435\u043b\u043a\u0430 \u041f\u0438\u0440\u0441\u0430 (\u0418\u041b\u0418-\u041d\u0415) \u043e\u0431\u043e\u0437\u043d\u0430\u0447\u0430\u0435\u0442\u0441\u044f \u043a\u0430\u043a \u22bd. \u041d\u0430\u0439\u0434\u0438 \u0438\u043d\u0432\u0435\u0440\u0441\u0438\u044e \u0441\u0443\u043c\u043c\u044b.", "label_a": "A", "label_b": "B", "out_name": "F", "gate_type": GateType.NOR},

	# --- PHASE 3: DETECTION ---
	{"phase": PHASE_DETECTION, "story": "\u0421\u0432\u0438\u0434\u0435\u0442\u0435\u043b\u044c: '\u0421\u0435\u0439\u0444 \u043e\u0442\u043a\u0440\u044b\u043b\u0441\u044f (1), \u043a\u043e\u0433\u0434\u0430 \u041e\u0411\u0410 \u043a\u043e\u0434\u0430 \u0431\u044b\u043b\u0438 \u043d\u0435\u0432\u0435\u0440\u043d\u044b (0,0)'.", "label_a": "\u041a\u041e\u0414_1", "label_b": "\u041a\u041e\u0414_2", "out_name": "\u0421\u0415\u0419\u0424", "gate_type": GateType.NOR},
	{"phase": PHASE_DETECTION, "story": "\u0423\u043b\u0438\u043a\u0430: '\u0421\u0438\u0433\u043d\u0430\u043b\u0438\u0437\u0430\u0446\u0438\u044f \u043c\u043e\u043b\u0447\u0438\u0442 (0), \u0442\u043e\u043b\u044c\u043a\u043e \u043a\u043e\u0433\u0434\u0430 \u0441\u0438\u0433\u043d\u0430\u043b\u044b \u0421\u041e\u0412\u041f\u0410\u0414\u0410\u042e\u0422'.", "label_a": "\u0414\u0410\u0422\u0427\u0418\u041a_1", "label_b": "\u0414\u0410\u0422\u0427\u0418\u041a_2", "out_name": "\u0421\u0418\u0420\u0415\u041d\u0410", "gate_type": GateType.XOR},
	{"phase": PHASE_DETECTION, "story": "\u0418\u043d\u0441\u043f\u0435\u043a\u0442\u043e\u0440: '\u0417\u0430\u043c\u043e\u043a \u0437\u0430\u043a\u043b\u0438\u043d\u0438\u0442 (0), \u0435\u0441\u043b\u0438 \u043d\u0430\u0436\u0430\u0442\u044c \u0445\u043e\u0442\u044f \u0431\u044b \u043e\u0434\u0438\u043d \u0440\u044b\u0447\u0430\u0433'.", "label_a": "\u0420\u042b\u0427\u0410\u0413_1", "label_b": "\u0420\u042b\u0427\u0410\u0413_2", "out_name": "\u0417\u0410\u041c\u041e\u041a", "gate_type": GateType.NOR},
	{"phase": PHASE_DETECTION, "story": "\u0428\u043f\u0438\u043e\u043d: '\u041f\u0435\u0440\u0435\u0445\u0432\u0430\u0442 \u0434\u0430\u043d\u043d\u044b\u0445 (1) \u0438\u0434\u0435\u0442 \u0442\u043e\u043b\u044c\u043a\u043e \u043f\u0440\u0438 \u0440\u0430\u0437\u043d\u044b\u0445 \u0447\u0430\u0441\u0442\u043e\u0442\u0430\u0445'.", "label_a": "\u0427\u0410\u0421\u0422\u041e\u0422\u0410_1", "label_b": "\u0427\u0410\u0421\u0422\u041e\u0422\u0410_2", "out_name": "\u041f\u0415\u0420\u0415\u0425\u0412\u0410\u0422", "gate_type": GateType.XOR},
	{"phase": PHASE_DETECTION, "story": "\u0424\u0438\u043d\u0430\u043b\u044c\u043d\u044b\u0439 \u043a\u043e\u0434: \u041d\u0443\u0436\u0435\u043d \u0432\u0435\u043d\u0442\u0438\u043b\u044c, \u0434\u0430\u044e\u0449\u0438\u0439 \u041b\u041e\u0416\u042c \u0442\u043e\u043b\u044c\u043a\u043e \u043f\u0440\u0438 \u0434\u0432\u0443\u0445 \u0418\u0421\u0422\u0418\u041d\u0410\u0425.", "label_a": "X", "label_b": "Y", "out_name": "\u0412\u042b\u0425\u041e\u0414", "gate_type": GateType.NAND}
]

func _ready():
	GlobalMetrics.game_over.connect(_on_system_failure)
	GlobalMetrics.stability_changed.connect(_on_stability_changed)
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
	current_quest_data = q
	_set_story_phase(q)
	_update_selector_style(q.phase)

	input_a = false
	input_b = false
	_update_input_visuals()
	input_a_btn.button_pressed = input_a
	input_b_btn.button_pressed = input_b
	input_b_btn.visible = q.gate_type != GateType.NOT
	wire_b.visible = q.gate_type != GateType.NOT

	selected_gate = GateType.NONE
	gate_selector.selected = 0
	result_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	result_label.text = RESULT_WAIT
	hint_label.text = ""
	next_button.visible = false
	lamp_label.text = q.out_name
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

func _update_selector_style(phase: String):
	gate_selector.clear()
	if phase == PHASE_TRAINING:
		gate_selector.add_item(GATE_NONE_LABEL, GateType.NONE)
		gate_selector.add_item("\u0418 (AND)", GateType.AND)
		gate_selector.add_item("\u0418\u041b\u0418 (OR)", GateType.OR)
		gate_selector.add_item("\u041d\u0415 (NOT)", GateType.NOT)
	else:
		gate_selector.add_item("\u0432\u0435\u043d\u0442\u0438\u043b\u044c...", GateType.NONE)
		gate_selector.add_item("& (\u041a\u043e\u043d\u044a\u044e\u043d\u043a\u0446\u0438\u044f)", GateType.AND)
		gate_selector.add_item("1 (\u0414\u0438\u0437\u044a\u044e\u043d\u043a\u0446\u0438\u044f)", GateType.OR)
		gate_selector.add_item("\u00ac (\u0418\u043d\u0432\u0435\u0440\u0441\u0438\u044f)", GateType.NOT)
		gate_selector.add_item("\u2295 (XOR)", GateType.XOR)
		gate_selector.add_item("\u22bd (NOR)", GateType.NOR)
		if phase == PHASE_DETECTION:
			gate_selector.add_item("NAND (NAND)", GateType.NAND)

func _gate_type_from_name(name: String) -> GateType:
	match name:
		"AND": return GateType.AND
		"OR": return GateType.OR
		"NOT": return GateType.NOT
		"XOR": return GateType.XOR
		"NOR": return GateType.NOR
		"NAND": return GateType.NAND
		_: return GateType.NONE

func _gate_type_from_option(option: String) -> GateType:
	match option:
		WORD_AND, SYM_AND: return GateType.AND
		WORD_OR, SYM_OR: return GateType.OR
		WORD_NOT, SYM_NOT: return GateType.NOT
		SYM_XOR: return GateType.XOR
		SYM_NOR, "NOR": return GateType.NOR
		SYM_NAND, "NAND": return GateType.NAND
		_: return GateType.NONE

func _update_input_visuals():
	var label_a = current_quest_data.get("label_a", "A")
	var label_b = current_quest_data.get("label_b", "B")
	input_a_btn.text = "%s: %s" % [label_a, "1" if input_a else "0"]
	input_b_btn.text = "%s: %s" % [label_b, "1" if input_b else "0"]

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
		GateType.NAND:
			current_output = not (a and b)
		_:
			current_output = false

	return current_output

func _on_gate_selected(index):
	if GlobalMetrics.stability <= 0:
		return
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
	var expected_gate = q.gate_type

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
	# Global penalty for mistakes
	GlobalMetrics.stability = max(0.0, GlobalMetrics.stability - 15.0)
	GlobalMetrics.stability_changed.emit(GlobalMetrics.stability, -15.0)

	result_label.text = "%s \u0421\u0422\u0410\u0411\u0418\u041b\u042c\u041d\u041e\u0421\u0422\u042c: %d%%" % [RESULT_MISMATCH, int(GlobalMetrics.stability)]
	hint_label.text = current_quest_data.get("hint", "")
	next_button.visible = false

func _on_input_a_toggled(pressed: bool):
	input_a = pressed
	_play_click()
	_update_input_visuals()
	_on_gate_selected(gate_selector.selected)

func _on_input_b_toggled(pressed: bool):
	input_b = pressed
	_play_click()
	_update_input_visuals()
	_on_gate_selected(gate_selector.selected)

func update_wires(a_val: bool, b_val: bool, out_val: bool):
	var on_color = Color(1, 1, 1)
	var off_color = Color(0.2, 0.2, 0.2)
	wire_a.default_color = on_color if a_val else off_color
	wire_b.default_color = on_color if b_val else off_color
	wire_out.default_color = on_color if out_val else off_color
	lamp.color = Color(1, 1, 1) if out_val else Color(0.15, 0.15, 0.15)
	lamp_label.text = "%s: %s" % [current_quest_data.get("out_name", "OUT"), "1" if out_val else "0"]

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

func _on_stability_changed(new_val, _change):
	if new_val <= 0:
		return
	if new_val < 30.0:
		background.color = Color(0.1, 0, 0, 1)
	else:
		background.color = Color(0, 0, 0, 1)

func _disable_terminal():
	gate_selector.disabled = true
	input_a_btn.disabled = true
	input_b_btn.disabled = true
	next_button.disabled = true
	result_label.text = "\u041a\u0420\u0418\u0422\u0418\u0427\u0415\u0421\u041a\u0410\u042f \u041e\u0428\u0418\u0411\u041a\u0410: \u0421\u0418\u0421\u0422\u0415\u041c\u0410 \u0417\u0410\u0411\u041b\u041e\u041a\u0418\u0420\u041e\u0412\u0410\u041d\u0410"
	result_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))

func _on_system_failure():
	_disable_terminal()
	game_over_panel.visible = true
	game_over_label.text = "\u0412\u0430\u0448\u0430 \u043b\u043e\u0433\u0438\u043a\u0430 \u043f\u0440\u0438\u0432\u0435\u043b\u0430 \u043a \u0445\u0430\u043e\u0441\u0443.\n\u0420\u0430\u0441\u0441\u043b\u0435\u0434\u043e\u0432\u0430\u043d\u0438\u0435 \u043f\u0440\u043e\u0432\u0430\u043b\u0435\u043d\u043e.\n\u0421\u0434\u0430\u0439\u0442\u0435 \u0436\u0435\u0442\u043e\u043d \u0438 \u043f\u0438\u0441\u0442\u043e\u043b\u0435\u0442."

func _on_restart_pressed():
	GlobalMetrics.stability = 100.0
	GlobalMetrics.stability_changed.emit(GlobalMetrics.stability, 100.0)
	game_over_panel.visible = false
	gate_selector.disabled = false
	input_a_btn.disabled = false
	input_b_btn.disabled = false
	next_button.disabled = false
	setup_quest(current_quest_index)
