extends "res://scenes/Tutorial/TutorialBase.gd"
# XOR, NAND, NOR — производные вентили
# Готовит к: LogicQuest A/B

class_name TutorialLogicXOR

func _initialize_tutorial() -> void:
	tutorial_id = "logic_xor_nand"
	tutorial_title = "XOR, NAND, NOR"
	linked_quest_scene = "res://scenes/LogicQuestA.tscn"

	tutorial_steps = [
		{
			"text": "Производные вентили строятся из базовых AND, OR, NOT.\n\nXOR  = (A OR B) AND NOT(A AND B)\nNAND = NOT(A AND B)\nNOR  = NOT(A OR B)\nXNOR = NOT(A XOR B)\n\nЗачем они нужны: NAND и NOR — «функционально полные». Из одного только NAND или NOR можно собрать любую логическую схему.\n\nВ ЕНТ: все 6 вентилей (AND/OR/NOT/XOR/NAND/NOR) равновероятны.",
			"render_func": "render_gates_overview",
		},
		{
			"text": "XOR — Исключающее ИЛИ:\n\nВыход = 1 если входы РАЗНЫЕ\nВыход = 0 если входы ОДИНАКОВЫЕ\n\nПроверка чётности: XOR нескольких бит = 1 если нечётное число единиц.\n\nXOR в криптографии: A XOR K = B, и B XOR K = A.\nОдин и тот же ключ шифрует и расшифровывает!\n\nXOR часто появляется как отдельный шаг в вопросах ЕНТ про битовые операции.",
			"render_func": "render_gate_table",
			"gate": "XOR",
			"truth_table": [[0,0,0],[0,1,1],[1,0,1],[1,1,0]],
			"rule": "1 если A ≠ B",
			"col": Color(0.75, 0.40, 1.00, 1.0),
		},
		{
			"text": "NAND — «И-НЕ»:\n\nNAND = NOT(AND)\nВыход = 0 ТОЛЬКО когда ОБА входа = 1.\nВо всех остальных случаях = 1.\n\nЛёгкий способ запомнить: инвертируй таблицу AND.\n\nФизически: транзисторные схемы проще строить на NAND, чем на AND. Именно поэтому большинство реальных микросхем используют NAND внутри.",
			"render_func": "render_gate_table",
			"gate": "NAND",
			"truth_table": [[0,0,1],[0,1,1],[1,0,1],[1,1,0]],
			"rule": "0 только если A=1 И B=1",
			"col": Color(0.90, 0.55, 0.20, 1.0),
		},
		{
			"text": "NOR — «ИЛИ-НЕ»:\n\nNOR = NOT(OR)\nВыход = 1 ТОЛЬКО когда ОБА входа = 0.\nВо всех остальных случаях = 0.\n\nЛёгкий способ запомнить: инвертируй таблицу OR.\n\nNOR используется в SR-триггерах — базовый элемент памяти (1 бит флипфлопа).",
			"render_func": "render_gate_table",
			"gate": "NOR",
			"truth_table": [[0,0,1],[0,1,0],[1,0,0],[1,1,0]],
			"rule": "1 только если A=0 И B=0",
			"col": Color(0.20, 0.75, 0.85, 1.0),
		},
		{
			"text": "XNOR — «Равнозначность»:\n\nXNOR = NOT(XOR)\nВыход = 1 если входы ОДИНАКОВЫЕ\nВыход = 0 если входы РАЗНЫЕ\n\nМнемоника: XNOR = «равно» (=).\nA XNOR B = 1 означает «A равно B».\n\nИспользуется в схемах сравнения чисел.",
			"render_func": "render_gate_table",
			"gate": "XNOR",
			"truth_table": [[0,0,1],[0,1,0],[1,0,0],[1,1,1]],
			"rule": "1 если A = B",
			"col": Color(0.35, 0.85, 0.55, 1.0),
		},
		{
			"text": "Сравнение всех 6 вентилей:\n\nЗапомни паттерны для пар (0,0) и (1,1) — они самые показательные:\n\n(0,0): AND=0 OR=0 XOR=0 NAND=1 NOR=1 XNOR=1\n(1,1): AND=1 OR=1 XOR=0 NAND=0 NOR=0 XNOR=1\n\nКлючевое наблюдение:\n• NAND — всегда противоположность AND\n• NOR  — всегда противоположность OR\n• XNOR — всегда противоположность XOR",
			"render_func": "render_all_six_compare",
		},
		{
			"text": "Задачи ЕНТ на производные вентили:\n\nТип 1: «A=1, B=0. NAND(A,B) = ?»\n→ AND(1,0)=0, NOT(0)=1. Ответ: 1\n\nТип 2: «Чему равен NOR(0,0)?»\n→ OR(0,0)=0, NOT(0)=1. Ответ: 1\n\nТип 3: «XOR(1,1) XOR XOR(0,1) = ?»\n→ XOR(1,1)=0, XOR(0,1)=1, XOR(0,1)=1. Ответ: 1\n\nСтратегия: всегда раскладывай NAND/NOR/XNOR на базовые операции.",
			"render_func": "render_ent_tasks_xor",
		},
	]


func render_gates_overview(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 5)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var gates := [
		["XOR",  "A OR B, но не оба",     "(A OR B) AND NOT(A AND B)", Color(0.75,0.40,1.00,1.0)],
		["NAND", "NOT AND",                "NOT(A AND B)",              Color(0.90,0.55,0.20,1.0)],
		["NOR",  "NOT OR",                 "NOT(A OR B)",               Color(0.20,0.75,0.85,1.0)],
		["XNOR", "НЕ-исключающее ИЛИ",    "NOT(A XOR B)",              Color(0.35,0.85,0.55,1.0)],
	]
	container.add_child(_make_row_bg(["Вентиль", "Смысл", "Формула"], true))
	for g in gates:
		container.add_child(_make_colored_row(g[0], g[1], g[2], g[3]))


func render_gate_table(area: Control, step: Dictionary) -> void:
	var gate: String        = step.get("gate", "XOR")
	var tt: Array           = step.get("truth_table", [])
	var rule: String        = step.get("rule", "")
	var col: Color          = step.get("col", Color(0.75,0.40,1.00,1.0))

	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var header := PanelContainer.new()
	var hs := _flat_style(col * Color(1,1,1,0.12), col, 2, 10)
	header.add_theme_stylebox_override("panel", hs)
	container.add_child(header)
	var h_row := HBoxContainer.new()
	h_row.add_theme_constant_override("separation", 12)
	header.add_child(h_row)
	var name_l := Label.new()
	name_l.text = gate
	name_l.add_theme_font_size_override("font_size", 26)
	name_l.add_theme_color_override("font_color", col)
	h_row.add_child(name_l)
	var rule_l := Label.new()
	rule_l.text = rule
	rule_l.add_theme_font_size_override("font_size", 14)
	rule_l.add_theme_color_override("font_color", Color(0.78,0.78,0.88,1.0))
	rule_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h_row.add_child(rule_l)

	var table := VBoxContainer.new()
	table.add_theme_constant_override("separation", 3)
	container.add_child(table)
	table.add_child(_make_row_bg(["A", "B", gate], true))
	for r in tt:
		var out: int = r[2]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		table.add_child(row)
		for j in range(3):
			var v: int = r[j]
			var is_out := j == 2
			var c_bg: Color = (Color(0.06,0.20,0.10,1.0) if out==1 else Color(0.16,0.06,0.06,1.0)) if is_out else Color(0.07,0.08,0.12,1.0)
			var c_border: Color = (col * Color(1,1,1,0.6)) if is_out else Color(0.20,0.20,0.30,0.5)
			var cell := _make_cell(str(v), 15, (col if out==1 else Color(0.90,0.30,0.30,1.0)) if is_out else Color(0.75,0.75,0.88,1.0), c_bg, c_border)
			row.add_child(cell)


func render_all_six_compare(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 3)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var cols := ["A","B","AND","OR","XOR","NAND","NOR","XNOR"]
	container.add_child(_make_row_bg(cols, true))
	var data := [
		[0,0,0,0,0,1,1,1],
		[0,1,0,1,1,1,0,0],
		[1,0,0,1,1,1,0,0],
		[1,1,1,1,0,0,0,1],
	]
	for row_data in data:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		container.add_child(row)
		for j in range(row_data.size()):
			var v: int = row_data[j]
			var is_in := j < 2
			var col: Color = Color(0.55,0.55,0.70,1.0) if is_in else (Color(0.20,0.85,0.55,1.0) if v==1 else Color(0.90,0.30,0.30,1.0))
			var cell := _make_cell(str(v), 13, col, col * Color(1,1,1,0.08), col * Color(1,1,1,0.30))
			row.add_child(cell)


func render_ent_tasks_xor(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var tasks := [
		["NAND(1, 0)", "AND(1,0)=0 → NOT(0)=1", "1", Color(0.90,0.55,0.20,1.0)],
		["NOR(0, 0)",  "OR(0,0)=0 → NOT(0)=1",  "1", Color(0.20,0.75,0.85,1.0)],
		["XOR(1, 1)",  "Входы одинаковые → 0",   "0", Color(0.75,0.40,1.00,1.0)],
		["XNOR(1, 0)", "XOR(1,0)=1 → NOT(1)=0", "0", Color(0.35,0.85,0.55,1.0)],
	]
	for t in tasks:
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", _flat_style(t[3]*Color(1,1,1,0.09), t[3], 1, 8))
		container.add_child(panel)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		panel.add_child(hb)
		for txt_data in [[t[0], 16, t[3]], [t[1], 13, Color(0.72,0.72,0.82,1.0)], ["= "+t[2], 18, t[3]]]:
			var lbl := Label.new()
			lbl.text = txt_data[0]
			lbl.add_theme_font_size_override("font_size", txt_data[1])
			lbl.add_theme_color_override("font_color", txt_data[2])
			if txt_data[1] == 13:
				lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
			hb.add_child(lbl)


# HELPERS ─────────────────────────────────────────────────────

func _flat_style(bg: Color, border: Color, bw: int = 1, radius: int = 6) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg; s.border_color = border
	s.set_border_width_all(bw)
	s.corner_radius_top_left = radius; s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius; s.corner_radius_bottom_right = radius
	s.content_margin_left = 10; s.content_margin_right = 10
	s.content_margin_top = 6; s.content_margin_bottom = 6
	return s

func _make_cell(text: String, fsize: int, fcol: Color, bg: Color, border: Color) -> PanelContainer:
	var cell := PanelContainer.new()
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cs := StyleBoxFlat.new()
	cs.bg_color = bg; cs.border_color = border
	cs.set_border_width_all(1)
	cs.corner_radius_top_left = 3; cs.corner_radius_top_right = 3
	cs.corner_radius_bottom_left = 3; cs.corner_radius_bottom_right = 3
	cs.content_margin_left = 6; cs.content_margin_right = 6
	cs.content_margin_top = 5; cs.content_margin_bottom = 5
	cell.add_theme_stylebox_override("panel", cs)
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", fsize)
	lbl.add_theme_color_override("font_color", fcol)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	cell.add_child(lbl)
	return cell

func _make_row_bg(values: Array, is_header: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	for val in values:
		row.add_child(_make_cell(str(val), 12 if is_header else 13,
			Color(0.5,0.7,1.0,1.0) if is_header else Color(0.8,0.8,0.9,1.0),
			Color(0.10,0.12,0.20,1.0) if is_header else Color(0.07,0.08,0.12,1.0),
			Color(0.22,0.35,0.55,0.7) if is_header else Color(0.15,0.15,0.22,0.5)))
	return row

func _make_colored_row(c0: String, c1: String, c2: String, col: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	for j in range(3):
		var txt := [c0, c1, c2][j]
		var cell := _make_cell(txt, 13, col if j==0 else Color(0.80,0.80,0.90,1.0),
			col*Color(1,1,1,0.08), col*Color(1,1,1,0.35))
		row.add_child(cell)
	return row

func _calculate_stars() -> int:
	return 3 if current_step_index >= tutorial_steps.size() - 1 else 2
