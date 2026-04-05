extends "res://scenes/Tutorial/TutorialBase.gd"
# Логические схемы — комбинирование вентилей
# Готовит к: LogicQuest C

class_name TutorialLogicCircuits

func _initialize_tutorial() -> void:
	tutorial_id = "logic_circuits"
	tutorial_title = "Логические схемы"
	linked_quest_scene = "res://scenes/LogicQuestC.tscn"

	tutorial_steps = [
		{
			"text": "Логическая схема — соединение нескольких вентилей в цепочку.\n\nВыход одного вентиля может стать входом другого.\n\nПорядок вычисления — слева направо, от входов к выходу.\n\nПример: (A AND B) OR (NOT C)\n→ сначала AND, затем NOT, затем OR\n\nВ ЕНТ: дают схему или выражение → найди выход для заданных входов.",
			"render_func": "render_circuit_intro",
		},
		{
			"text": "Схема: (A AND B) OR C\n\nВычисление для A=1, B=0, C=1:\n\nШаг 1: AND(A, B) = AND(1, 0) = 0\nШаг 2: OR(0, C)  = OR(0, 1)  = 1\n\nВыход = 1\n\nПравило: раскладывай схему на шаги. Каждый шаг — один вентиль.",
			"render_func": "render_circuit_step",
			"expr": "(A AND B) OR C",
			"inputs": {"A": 1, "B": 0, "C": 1},
			"steps": [
				{"op": "AND(A, B)", "vals": "AND(1, 0)", "result": 0},
				{"op": "OR(0, C)",  "vals": "OR(0, 1)",  "result": 1},
			],
			"output": 1,
		},
		{
			"text": "Схема: NOT(A OR B) AND C\n\nВычисление для A=0, B=0, C=1:\n\nШаг 1: OR(A, B)     = OR(0, 0)  = 0\nШаг 2: NOT(0)        = 1\nШаг 3: AND(1, C)     = AND(1, 1) = 1\n\nВыход = 1\n\nОбрати внимание: NOT(A OR B) = NOR(A, B).\nЭто закон де Моргана в действии!",
			"render_func": "render_circuit_step",
			"expr": "NOT(A OR B) AND C",
			"inputs": {"A": 0, "B": 0, "C": 1},
			"steps": [
				{"op": "OR(A, B)",    "vals": "OR(0, 0)",    "result": 0},
				{"op": "NOT(0)",      "vals": "NOT(0)",       "result": 1},
				{"op": "AND(1, C)",   "vals": "AND(1, 1)",    "result": 1},
			],
			"output": 1,
		},
		{
			"text": "Схема с XOR: (A XOR B) AND (B XOR C)\n\nВычисление для A=1, B=1, C=0:\n\nШаг 1: XOR(A, B) = XOR(1, 1) = 0\nШаг 2: XOR(B, C) = XOR(1, 0) = 1\nШаг 3: AND(0, 1) = 0\n\nВыход = 0\n\nXOR-схемы часто используются в сумматорах (сложение двоичных чисел).",
			"render_func": "render_circuit_step",
			"expr": "(A XOR B) AND (B XOR C)",
			"inputs": {"A": 1, "B": 1, "C": 0},
			"steps": [
				{"op": "XOR(A, B)", "vals": "XOR(1, 1)", "result": 0},
				{"op": "XOR(B, C)", "vals": "XOR(1, 0)", "result": 1},
				{"op": "AND(0, 1)", "vals": "AND(0, 1)", "result": 0},
			],
			"output": 0,
		},
		{
			"text": "Таблица истинности схемы:\n\nДля схемы (A AND B) OR (NOT A AND C) при всех входах:\n\nЭто называется мультиплексор 2:1 — выбирает B или C в зависимости от A.\n\nПри A=1: выход = B (NOT A = 0, второй И = 0)\nПри A=0: выход = C (первый И = 0, NOT A = 1)",
			"render_func": "render_mux_table",
		},
		{
			"text": "Полусумматор — классическая схема:\n\nСкладывает два однобитных числа A и B.\n\nСумма   S = A XOR B\nПеренос C = A AND B\n\nA=0, B=0: S=0, C=0 (0+0=0)\nA=0, B=1: S=1, C=0 (0+1=1)\nA=1, B=0: S=1, C=0 (1+0=1)\nA=1, B=1: S=0, C=1 (1+1=10₂)\n\nТак работает сложение на уровне железа!",
			"render_func": "render_half_adder",
		},
		{
			"text": "Задачи ЕНТ на схемы:\n\nТип 1: «Какой выход схемы при A=1, B=0?»\n→ Подставь значения, пройди по шагам\n\nТип 2: «При каких входах схема даёт 1?»\n→ Составь таблицу истинности\n\nТип 3: «Упрости выражение»\n→ Используй законы де Моргана\n\nЗапомни: любую схему можно выразить через AND, OR, NOT.",
			"render_func": "render_ent_circuit_tasks",
		},
	]


func render_circuit_intro(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 6)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _flat_style(Color(0.07,0.10,0.20,1.0), Color(0.25,0.45,0.85,0.7), 2, 10))
	container.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	panel.add_child(vb)
	for line_data in [
		["Входы (A, B, C…)", Color(0.35,0.70,1.00,1.0)],
		["     ↓", Color(0.55,0.55,0.70,1.0)],
		["[Вентиль 1] → промежуточный результат", Color(0.80,0.60,0.20,1.0)],
		["     ↓", Color(0.55,0.55,0.70,1.0)],
		["[Вентиль 2] → следующий результат", Color(0.80,0.50,1.00,1.0)],
		["     ↓", Color(0.55,0.55,0.70,1.0)],
		["Выход (F)", Color(0.20,0.85,0.55,1.0)],
	]:
		var lbl := Label.new()
		lbl.text = line_data[0]
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", line_data[1])
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(lbl)


func render_circuit_step(area: Control, step: Dictionary) -> void:
	var expr: String    = step.get("expr", "")
	var inputs: Dictionary = step.get("inputs", {})
	var steps_data: Array  = step.get("steps", [])
	var output: int     = step.get("output", 0)

	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 6)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	# Выражение
	var ep := PanelContainer.new()
	ep.add_theme_stylebox_override("panel", _flat_style(Color(0.08,0.10,0.20,1.0), Color(0.25,0.45,0.85,0.7), 1, 8))
	container.add_child(ep)
	var el := Label.new()
	el.text = expr
	el.add_theme_font_size_override("font_size", 15)
	el.add_theme_color_override("font_color", Color(0.55,0.75,1.00,1.0))
	el.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ep.add_child(el)

	# Входы
	var inp_row := HBoxContainer.new()
	inp_row.add_theme_constant_override("separation", 8)
	inp_row.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_child(inp_row)
	for k in inputs.keys():
		var lbl := Label.new()
		lbl.text = "%s=%d" % [k, inputs[k]]
		lbl.add_theme_font_size_override("font_size", 15)
		lbl.add_theme_color_override("font_color", Color(0.80,0.80,0.90,1.0))
		inp_row.add_child(lbl)

	# Шаги
	var table := VBoxContainer.new()
	table.add_theme_constant_override("separation", 3)
	container.add_child(table)
	table.add_child(_make_row_bg(["Шаг", "Операция", "Подстановка", "Результат"], true))
	for i in range(steps_data.size()):
		var s: Dictionary = steps_data[i]
		var res: int = s.get("result", 0)
		var res_col: Color = Color(0.20,0.85,0.55,1.0) if res == 1 else Color(0.90,0.30,0.30,1.0)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		table.add_child(row)
		for j in range(4):
			var txt: String = [str(i+1), s.get("op",""), s.get("vals",""), str(res)][j]
			var fc: Color = res_col if j == 3 else Color(0.80,0.80,0.90,1.0)
			row.add_child(_make_cell(txt, 13, fc,
				Color(0.06,0.20,0.10,1.0) if (j==3 and res==1) else Color(0.07,0.08,0.12,1.0),
				Color(0.15,0.15,0.22,0.4)))

	_make_info_panel_add(area, "Выход F = %d" % output,
		Color(0.08,0.18,0.12,1.0) if output==1 else Color(0.18,0.06,0.06,1.0),
		Color(0.20,0.65,0.42,0.7) if output==1 else Color(0.65,0.18,0.18,0.7))


func render_mux_table(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 3)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	container.add_child(_make_row_bg(["A","B","C","NOT A","A AND B","NOT A AND C","Выход"], true))
	var data := [
		[0,0,0,1,0,0,0],
		[0,0,1,1,0,1,1],
		[0,1,0,1,0,0,0],
		[0,1,1,1,0,1,1],
		[1,0,0,0,0,0,0],
		[1,0,1,0,0,0,0],
		[1,1,0,0,1,0,1],
		[1,1,1,0,1,0,1],
	]
	for row_d in data:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		container.add_child(row)
		for j in range(row_d.size()):
			var v: int = row_d[j]
			var is_out := j == row_d.size() - 1
			var col: Color = (Color(0.20,0.85,0.55,1.0) if v==1 else Color(0.90,0.30,0.30,1.0)) if is_out else Color(0.70,0.70,0.82,1.0)
			row.add_child(_make_cell(str(v), 12, col,
				Color(0.06,0.20,0.10,1.0) if (is_out and v==1) else Color(0.07,0.08,0.12,1.0),
				col * Color(1,1,1,0.25)))


func render_half_adder(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	for formula_data in [
		["Сумма S = A XOR B", Color(0.75,0.40,1.00,1.0)],
		["Перенос C = A AND B", Color(0.35,0.70,1.00,1.0)],
	]:
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", _flat_style(formula_data[1]*Color(1,1,1,0.10), formula_data[1], 2, 8))
		container.add_child(p)
		var lbl := Label.new()
		lbl.text = formula_data[0]
		lbl.add_theme_font_size_override("font_size", 18)
		lbl.add_theme_color_override("font_color", formula_data[1])
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		p.add_child(lbl)

	container.add_child(_make_row_bg(["A","B","S (XOR)","C (AND)","Результат"], true))
	var ha_data := [[0,0,0,0,"0+0=0"],[0,1,1,0,"0+1=1"],[1,0,1,0,"1+0=1"],[1,1,0,1,"1+1=10₂"]]
	for r in ha_data:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		container.add_child(row)
		for j in range(5):
			var txt: String = str(r[j])
			var fc: Color = Color(0.75,0.40,1.00,1.0) if j==2 else (Color(0.35,0.70,1.00,1.0) if j==3 else Color(0.80,0.80,0.90,1.0))
			row.add_child(_make_cell(txt, 13, fc, Color(0.07,0.08,0.12,1.0), Color(0.15,0.15,0.22,0.4)))


func render_ent_circuit_tasks(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 6)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var types := [
		["Тип 1", "Найди выход при заданных входах", "Подставь → считай шаг за шагом", Color(0.35,0.70,1.00,1.0)],
		["Тип 2", "При каких входах выход = 1?", "Составь таблицу истинности",         Color(0.20,0.85,0.55,1.0)],
		["Тип 3", "Упрости выражение",            "Законы де Моргана, поглощения",      Color(0.80,0.60,0.20,1.0)],
	]
	for t in types:
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", _flat_style(t[3]*Color(1,1,1,0.09), t[3], 1, 8))
		container.add_child(panel)
		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 4)
		panel.add_child(vb)
		for i in range(3):
			var lbl := Label.new()
			lbl.text = t[i]
			lbl.add_theme_font_size_override("font_size", 15 if i==0 else (13 if i==1 else 12))
			lbl.add_theme_color_override("font_color", t[3] if i==0 else (Color(0.80,0.80,0.90,1.0) if i==1 else Color(0.60,0.60,0.72,1.0)))
			lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
			vb.add_child(lbl)


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
	lbl.text = text; lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", fsize)
	lbl.add_theme_color_override("font_color", fcol)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	cell.add_child(lbl)
	return cell

func _make_row_bg(values: Array, is_header: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	for val in values:
		row.add_child(_make_cell(str(val), 12,
			Color(0.5,0.7,1.0,1.0) if is_header else Color(0.8,0.8,0.9,1.0),
			Color(0.10,0.12,0.20,1.0) if is_header else Color(0.07,0.08,0.12,1.0),
			Color(0.22,0.35,0.55,0.7) if is_header else Color(0.15,0.15,0.22,0.5)))
	return row

func _make_info_panel_add(area: Control, text: String, bg: Color, border: Color) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _flat_style(bg, border, 1, 6))
	area.add_child(panel)
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", Color(0.9,0.82,0.25,1.0))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	panel.add_child(lbl)

func _calculate_stars() -> int:
	return 3 if current_step_index >= tutorial_steps.size() - 1 else 2
