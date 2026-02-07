extends Control

# --- CONSTANTS ---
const LAYOUT_CASCADE_TOP = "CASCADE_TOP" # (A op B) op C
const LAYOUT_CASCADE_BOTTOM = "CASCADE_BOTTOM" # A op (B op C)

const GATE_NONE = "NONE"
const GATE_AND = "AND"
const GATE_OR = "OR"
const GATE_NOT = "NOT"
const GATE_XOR = "XOR"
const GATE_NAND = "NAND"
const GATE_NOR = "NOR"

# Cases Data (Level B)
const CASES = [
	{
		"id": "B_01",
		"layout": LAYOUT_CASCADE_TOP,
		"story": "Система (1) активна, если [b]ДАТЧИК_1[/b] ИЛИ [b]ДАТЧИК_2[/b] сработали, и при этом [b]КЛЮЧ[/b] повернут.",
		"labels": ["ДАТЧИК 1", "ДАТЧИК 2", "КЛЮЧ"],
		"correct_gates": [GATE_OR, GATE_AND], # Slot 1 (A/B), Slot 2 (Res/C)
		"hint": "Сначала объедини датчики (ИЛИ), потом проверь ключ (И)."
	},
	{
		"id": "B_02",
		"layout": LAYOUT_CASCADE_BOTTOM,
		"story": "Авария (1) происходит, если [b]ДАВЛЕНИЕ[/b] высоко, И ([b]ТЕМПЕРАТУРА[/b] критична ИЛИ [b]НАСОС[/b] отказал).",
		"labels": ["ДАВЛЕНИЕ", "ТЕМПЕРАТУРА", "НАСОС"],
		"correct_gates": [GATE_OR, GATE_AND], # Slot 1 (B/C), Slot 2 (A/Res) -> Note: S1 is usually the 'inner' one in bottom cascade visually?
		# Let's define: In Cascade Bottom, Slot 1 is B-C, Slot 2 is A-(S1).
		"hint": "Скобки важны. Сначала реши проблему температуры и насоса."
	},
	{
		"id": "B_03",
		"layout": LAYOUT_CASCADE_TOP,
		"story": "Доступ (1): Достаточно одного из ключей ([b]КЛЮЧ_А[/b] или [b]КЛЮЧ_B[/b]), но [b]РУБИЛЬНИК[/b] должен быть включен.",
		"labels": ["КЛЮЧ А", "КЛЮЧ B", "РУБИЛЬНИК"],
		"correct_gates": [GATE_OR, GATE_AND],
		"hint": "Ключи через ИЛИ, результат с рубильником через И."
	},
	{
		"id": "B_04",
		"layout": LAYOUT_CASCADE_BOTTOM,
		"story": "Тревога (1): [b]ДАТЧИК_1[/b] активен, либо ([b]ДАТЧИК_2[/b] и [b]ДАТЧИК_3[/b] активны одновременно).",
		"labels": ["ДАТЧИК 1", "ДАТЧИК 2", "ДАТЧИК 3"],
		"correct_gates": [GATE_AND, GATE_OR], # S1(B,C)=AND, S2(A, S1)=OR
		"hint": "Внутреннее условие: 2 и 3. Внешнее: 1 или результат."
	},
	{
		"id": "B_05",
		"layout": LAYOUT_CASCADE_TOP,
		"story": "Секрет (1): [b]РЫЧАГ_1[/b] не равен [b]РЫЧАГУ_2[/b], и [b]РЫЧАГ_3[/b] тоже должен быть включен.",
		"labels": ["РЫЧАГ 1", "РЫЧАГ 2", "РЫЧАГ 3"],
		"correct_gates": [GATE_XOR, GATE_AND],
		"hint": "Не равны = XOR."
	}
]

# --- UI NODES ---
@onready var story_text = $MainLayout/StoryPanel/StoryMargin/StoryText
@onready var stats_label = $MainLayout/HeaderPanel/HeaderMargin/HeaderHBox/StatsLabel
@onready var stability_label = $MainLayout/HeaderPanel/HeaderMargin/HeaderHBox/StabilityLabel

@onready var input_a_btn = $MainLayout/BoardContainer/Switches/InputA_Btn
@onready var input_b_btn = $MainLayout/BoardContainer/Switches/InputB_Btn
@onready var input_c_btn = $MainLayout/BoardContainer/Switches/InputC_Btn

@onready var layout_top = $MainLayout/BoardContainer/Layouts/Layout_Cascade_Top
@onready var layout_bottom = $MainLayout/BoardContainer/Layouts/Layout_Cascade_Bottom

@onready var slot1_btn = $MainLayout/BoardContainer/Slots/Slot1
@onready var slot1_lbl = $MainLayout/BoardContainer/Slots/Slot1/Symbol
@onready var slot2_btn = $MainLayout/BoardContainer/Slots/Slot2
@onready var slot2_lbl = $MainLayout/BoardContainer/Slots/Slot2/Symbol

@onready var inter_lamp = $MainLayout/BoardContainer/InterLamp
@onready var out_lamp = $MainLayout/BoardContainer/OutputLamp
@onready var out_lamp_lbl = $MainLayout/BoardContainer/OutputLamp/Label

@onready var feedback_lbl = $MainLayout/ControlsPanel/Margin/HBox/FeedbackLabel
@onready var btn_verdict = $MainLayout/ControlsPanel/Margin/HBox/BtnVerdict
@onready var btn_next = $MainLayout/ControlsPanel/Margin/HBox/BtnNext
@onready var btn_hint = $MainLayout/ControlsPanel/Margin/HBox/BtnHint

@onready var game_over_panel = $GameOverPanel
@onready var click_player = $ClickPlayer

# Wires Top
@onready var t_wire_a = $MainLayout/BoardContainer/Layouts/Layout_Cascade_Top/Wire_A_S1
@onready var t_wire_b = $MainLayout/BoardContainer/Layouts/Layout_Cascade_Top/Wire_B_S1
@onready var t_wire_s1 = $MainLayout/BoardContainer/Layouts/Layout_Cascade_Top/Wire_S1_S2
@onready var t_wire_c = $MainLayout/BoardContainer/Layouts/Layout_Cascade_Top/Wire_C_S2
@onready var t_wire_out = $MainLayout/BoardContainer/Layouts/Layout_Cascade_Top/Wire_S2_Out

# Wires Bottom
@onready var b_wire_a = $MainLayout/BoardContainer/Layouts/Layout_Cascade_Bottom/Wire_A_S2
@onready var b_wire_b = $MainLayout/BoardContainer/Layouts/Layout_Cascade_Bottom/Wire_B_S1
@onready var b_wire_c = $MainLayout/BoardContainer/Layouts/Layout_Cascade_Bottom/Wire_C_S1
@onready var b_wire_s1 = $MainLayout/BoardContainer/Layouts/Layout_Cascade_Bottom/Wire_S1_S2
@onready var b_wire_out = $MainLayout/BoardContainer/Layouts/Layout_Cascade_Bottom/Wire_S2_Out

# Gate Buttons
@onready var gates_grid = $MainLayout/SelectorPanel/Margin/GateGrid

# --- STATE ---
var current_case_idx = 0
var current_case = {}
var inputs = [false, false, false] # A, B, C
var placed_gates = [GATE_NONE, GATE_NONE] # Slot 1, Slot 2
var selected_slot_idx = -1
var hints_used = 0
var case_attempts = 0

const COLOR_ON = Color(1.2, 1.2, 1.2, 1)
const COLOR_OFF = Color(0.15, 0.15, 0.15, 1)
const COLOR_LAMP_ON = Color(1.5, 1.5, 1.2, 1)
const COLOR_LAMP_OFF = Color(0.1, 0.1, 0.1, 1)

func _ready():
	GlobalMetrics.stability_changed.connect(_update_stability)
	_update_stability(GlobalMetrics.stability, 0)
	load_case(0)

func load_case(idx):
	if idx >= CASES.size():
		idx = 0
	current_case_idx = idx
	current_case = CASES[idx]

	inputs = [false, false, false]
	placed_gates = [GATE_NONE, GATE_NONE]
	selected_slot_idx = -1
	hints_used = 0
	case_attempts = 0

	# Update UI
	story_text.text = current_case.story
	stats_label.text = "CASE: %02d" % (idx + 1)

	var labels = current_case.labels
	input_a_btn.text = "%s: 0" % labels[0]
	input_b_btn.text = "%s: 0" % labels[1]
	input_c_btn.text = "%s: 0" % labels[2]
	input_a_btn.button_pressed = false
	input_b_btn.button_pressed = false
	input_c_btn.button_pressed = false

	# Reset Slots
	_update_slot_visuals(0)
	_update_slot_visuals(1)

	# Select Layout
	layout_top.visible = (current_case.layout == LAYOUT_CASCADE_TOP)
	layout_bottom.visible = (current_case.layout == LAYOUT_CASCADE_BOTTOM)

	# Reset State
	btn_verdict.visible = true
	btn_next.visible = false
	feedback_lbl.text = ""

	# Reset Controls
	_set_selector_enabled(false)

	_update_circuit()

func _update_slot_visuals(idx):
	var gate = placed_gates[idx]
	var btn = slot1_btn if idx == 0 else slot2_btn
	var lbl = slot1_lbl if idx == 0 else slot2_lbl

	if gate == GATE_NONE:
		lbl.text = "?"
		lbl.modulate = Color(0.5, 0.5, 0.5)
	else:
		lbl.text = _get_gate_symbol(gate)
		lbl.modulate = Color(1, 1, 1)

func _get_gate_symbol(type):
	match type:
		GATE_AND: return "&"
		GATE_OR: return "1"
		GATE_NOT: return "¬"
		GATE_XOR: return "⊕"
		GATE_NAND: return "|"
		GATE_NOR: return "↓"
	return "?"

func _on_input_a_toggled(pressed):
	inputs[0] = pressed
	input_a_btn.text = "%s: %s" % [current_case.labels[0], "1" if pressed else "0"]
	_update_circuit()

func _on_input_b_toggled(pressed):
	inputs[1] = pressed
	input_b_btn.text = "%s: %s" % [current_case.labels[1], "1" if pressed else "0"]
	_update_circuit()

func _on_input_c_toggled(pressed):
	inputs[2] = pressed
	input_c_btn.text = "%s: %s" % [current_case.labels[2], "1" if pressed else "0"]
	_update_circuit()

func _on_slot1_pressed():
	_select_slot(0)

func _on_slot2_pressed():
	_select_slot(1)

func _select_slot(idx):
	selected_slot_idx = idx
	_play_click()

	# Highlight UI
	var style_normal = load("res://scenes/LogicQuestB.tscn::StyleBoxFlat_slot_normal") # Fallback/Hack if not local
	# Actually we rely on theme override in scene, simpler to just set focus or border
	# For now, just enable selector
	_set_selector_enabled(true)
	feedback_lbl.text = "SELECT COMPONENT FOR SLOT %d" % (idx + 1)
	feedback_lbl.add_theme_color_override("font_color", Color(0.5, 0.8, 1))
	feedback_lbl.visible = true

func _set_selector_enabled(enabled):
	for child in gates_grid.get_children():
		child.disabled = !enabled

func _on_gate_btn_pressed(type):
	if selected_slot_idx == -1: return

	placed_gates[selected_slot_idx] = type
	_update_slot_visuals(selected_slot_idx)
	_play_click()

	selected_slot_idx = -1
	_set_selector_enabled(false)
	feedback_lbl.text = ""
	_update_circuit()

func _update_circuit():
	var res = _calculate_circuit()
	var inter_val = res.inter
	var final_val = res.final

	# Visuals
	if current_case.layout == LAYOUT_CASCADE_TOP:
		t_wire_a.default_color = COLOR_ON if inputs[0] else COLOR_OFF
		t_wire_b.default_color = COLOR_ON if inputs[1] else COLOR_OFF
		t_wire_c.default_color = COLOR_ON if inputs[2] else COLOR_OFF

		# S1 is first stage
		t_wire_s1.default_color = COLOR_ON if inter_val else COLOR_OFF
		t_wire_out.default_color = COLOR_ON if final_val else COLOR_OFF

	elif current_case.layout == LAYOUT_CASCADE_BOTTOM:
		b_wire_a.default_color = COLOR_ON if inputs[0] else COLOR_OFF
		b_wire_b.default_color = COLOR_ON if inputs[1] else COLOR_OFF
		b_wire_c.default_color = COLOR_ON if inputs[2] else COLOR_OFF

		# S1 is inner stage (B, C) usually
		b_wire_s1.default_color = COLOR_ON if inter_val else COLOR_OFF
		b_wire_out.default_color = COLOR_ON if final_val else COLOR_OFF

	# Lamps
	inter_lamp.color = COLOR_LAMP_ON if inter_val else COLOR_LAMP_OFF

	if final_val:
		out_lamp.color = COLOR_LAMP_ON
		out_lamp_lbl.modulate = Color(0, 0, 0)
	else:
		out_lamp.color = COLOR_LAMP_OFF
		out_lamp_lbl.modulate = Color(0.3, 0.3, 0.3)

func _calculate_circuit():
	var g1 = placed_gates[0]
	var g2 = placed_gates[1]

	var inter = false
	var final = false

	if current_case.layout == LAYOUT_CASCADE_TOP:
		# Slot 1: A, B -> Inter
		# Slot 2: Inter, C -> Final
		if g1 != GATE_NONE:
			inter = _gate_op(inputs[0], inputs[1], g1)

		if g2 != GATE_NONE:
			final = _gate_op(inter, inputs[2], g2)

	elif current_case.layout == LAYOUT_CASCADE_BOTTOM:
		# Slot 1: B, C -> Inter
		# Slot 2: A, Inter -> Final
		if g1 != GATE_NONE:
			inter = _gate_op(inputs[1], inputs[2], g1)

		if g2 != GATE_NONE:
			final = _gate_op(inputs[0], inter, g2)

	return {"inter": inter, "final": final}

func _gate_op(a, b, type):
	match type:
		GATE_AND: return a and b
		GATE_OR: return a or b
		GATE_NOT: return not a # Usually single input, assume 'a' is primary
		GATE_XOR: return a != b
		GATE_NAND: return not (a and b)
		GATE_NOR: return not (a or b)
	return false

func _on_verdict_pressed():
	# Check completeness
	if placed_gates[0] == GATE_NONE or placed_gates[1] == GATE_NONE:
		_show_feedback("CIRCUIT INCOMPLETE", Color(1, 0.5, 0))
		return

	var correct = current_case.correct_gates
	if placed_gates[0] == correct[0] and placed_gates[1] == correct[1]:
		_show_feedback("SYSTEM STABLE. ACCESS GRANTED.", Color(0, 1, 0))
		btn_verdict.visible = false
		btn_next.visible = true
		_set_selector_enabled(false)
	else:
		case_attempts += 1
		var pen = 15.0 + (case_attempts * 5.0)
		_apply_penalty(pen)
		_show_feedback("LOGIC ERROR. STABILITY -%d" % int(pen), Color(1, 0, 0))

func _show_feedback(msg, col):
	feedback_lbl.text = msg
	feedback_lbl.add_theme_color_override("font_color", col)
	feedback_lbl.visible = true

func _apply_penalty(amt):
	GlobalMetrics.stability = max(0.0, GlobalMetrics.stability - amt)
	GlobalMetrics.stability_changed.emit(GlobalMetrics.stability, -amt)
	if GlobalMetrics.stability <= 0:
		_game_over()

func _game_over():
	game_over_panel.visible = true

func _update_stability(val, _change):
	stability_label.text = "STABILITY: %d%%" % int(val)
	if val < 30: stability_label.add_theme_color_override("font_color", Color(1, 0, 0))
	elif val < 70: stability_label.add_theme_color_override("font_color", Color(1, 1, 0))
	else: stability_label.add_theme_color_override("font_color", Color(0, 1, 0))

func _on_next_button_pressed():
	load_case(current_case_idx + 1)

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _play_click():
	if click_player.stream:
		click_player.play()

func _on_hint_pressed():
	_show_feedback("HINT: " + current_case.hint, Color(0.5, 0.8, 1))
	_apply_penalty(5.0)

func _on_restart_pressed():
	GlobalMetrics.stability = 100.0
	GlobalMetrics.stability_changed.emit(100.0, 0)
	game_over_panel.visible = false
	load_case(current_case_idx)
