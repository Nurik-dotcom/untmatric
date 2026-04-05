extends "res://scenes/Tutorial/TutorialBase.gd"
# TutorialLogicGates.gd — Логические вентили
# Готовит к: Логические вентили A/B/C

class_name TutorialLogicGates

func _initialize_tutorial() -> void:
	tutorial_id = "logic_basic"
	tutorial_title = "Логические вентили"
	linked_quest_scene = "res://scenes/LogicQuestA.tscn"

	tutorial_steps = [
		{
			"text": "Логический вентиль — это простая электронная схема.\nОна принимает один или два сигнала (0 или 1) и выдаёт один сигнал на выходе.\n\nВ компьютере миллиарды таких вентилей. Вместе они выполняют любые вычисления.\n\nВ квесте ты будешь составлять цепочки из вентилей чтобы получить нужный выход.",
			"render_func": "",
		},
		{
			"text": "AND (И) — строгий вентиль.\n\nВыход = 1 ТОЛЬКО когда ОБА входа = 1.\nВо всех остальных случаях — 0.\n\nАналог из жизни:\n«Машина заведётся, если вставлен КЛЮЧ И нажата ПЕДАЛЬ»",
			"render_func": "render_gate_styled",
			"gate": "AND",
			"truth_table": [
				{"a": 0, "b": 0, "out": 0},
				{"a": 0, "b": 1, "out": 0},
				{"a": 1, "b": 0, "out": 0},
				{"a": 1, "b": 1, "out": 1},
			],
			"rule": "A AND B = 1 только если A=1 и B=1",
		},
		{
			"text": "OR (ИЛИ) — мягкий вентиль.\n\nВыход = 1 если ХОТЯ БЫ один вход = 1.\nВыход = 0 только когда ОБА входа = 0.\n\nАналог:\n«Ты промокнешь, если идёт ДОЖДЬ ИЛИ СНЕГ»",
			"render_func": "render_gate_styled",
			"gate": "OR",
			"truth_table": [
				{"a": 0, "b": 0, "out": 0},
				{"a": 0, "b": 1, "out": 1},
				{"a": 1, "b": 0, "out": 1},
				{"a": 1, "b": 1, "out": 1},
			],
			"rule": "A OR B = 0 только если A=0 и B=0",
		},
		{
			"text": "NOT (НЕ) — инвертор. Принимает ОДИН вход.\n\nВыход = противоположность входа:\n0 → 1\n1 → 0\n\nАналог:\n«Детектор лжи: правда (1) на входе → сигнал тревоги (0) на выходе отсутствует»",
			"render_func": "render_gate_not_styled",
		},
		{
			"text": "XOR (Исключающее ИЛИ) — вентиль разности.\n\nВыход = 1 если входы РАЗНЫЕ.\nВыход = 0 если входы ОДИНАКОВЫЕ.\n\nАналог:\n«Сигнализация срабатывает только когда датчики показывают разные значения»\n\nXOR широко используется в шифровании!",
			"render_func": "render_gate_styled",
			"gate": "XOR",
			"truth_table": [
				{"a": 0, "b": 0, "out": 0},
				{"a": 0, "b": 1, "out": 1},
				{"a": 1, "b": 0, "out": 1},
				{"a": 1, "b": 1, "out": 0},
			],
			"rule": "XOR = 1 если A ≠ B",
		},
		{
			"text": "NAND и NOR — производные вентили.\n\nNAND = NOT(AND): выход 0 только если оба входа = 1\nNOR  = NOT(OR):  выход 1 только если оба входа = 0\n\nЛюбую логическую схему можно собрать только из NAND или только из NOR. Они называются «функционально полными».",
			"render_func": "render_nand_nor_table",
		},
		{
			"text": "Сравнение всех вентилей рядом — запомни паттерны:\n\nAND:  только 1,1 → 1\nOR:   только 0,0 → 0\nXOR:  только разные → 1\nNAND: только 1,1 → 0  (инверсия AND)\nNOR:  только 0,0 → 1  (инверсия OR)",
			"render_func": "render_all_gates_compare",
		},
		{
			"text": "Типичный вопрос ЕНТ:\n\n«A=1, B=0. Чему равен выход вентиля XOR?»\n\nАлгоритм:\n1. Вспомни правило XOR: выход=1 если входы разные\n2. A=1, B=0 — они разные → выход = 1\n\nЧасто проверяют AND, OR, XOR и иногда NAND.",
			"render_func": "render_ent_practice",
		},
	]


# ─── RENDER FUNCTIONS ─────────────────────────────────────────────────────────

func render_gate_styled(area: Control, step: Dictionary) -> void:
	var gate: String = step.get("gate", "AND")
	var truth: Array = step.get("truth_table", [])
	var rule: String = step.get("rule", "")

	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	# Заголовок вентиля
	var header_panel := PanelContainer.new()
	var hp := StyleBoxFlat.new()
	hp.bg_color = Color(0.06, 0.14, 0.22, 1.0)
	hp.border_color = Color(0.15, 0.50, 0.85, 0.8)
	hp.set_border_width_all(1)
	hp.corner_radius_top_left    = 8; hp.corner_radius_top_right   = 8
	hp.corner_radius_bottom_left = 8; hp.corner_radius_bottom_right = 8
	hp.content_margin_left = 14; hp.content_margin_right = 14
	hp.content_margin_top  = 10; hp.content_margin_bottom = 10
	header_panel.add_theme_stylebox_override("panel", hp)
	container.add_child(header_panel)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	header_panel.add_child(hbox)

	var name_lbl := Label.new()
	name_lbl.text = gate
	name_lbl.add_theme_font_size_override("font_size", 28)
	name_lbl.add_theme_color_override("font_color", Color(0.35, 0.75, 1.00, 1.0))
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(name_lbl)

	var rule_lbl := Label.new()
	rule_lbl.text = rule
	rule_lbl.add_theme_font_size_override("font_size", 13)
	rule_lbl.add_theme_color_override("font_color", Color(0.65, 0.75, 0.90, 1.0))
	rule_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	rule_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rule_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(rule_lbl)

	# Таблица истинности
	var table := VBoxContainer.new()
	table.add_theme_constant_override("separation", 3)
	container.add_child(table)

	table.add_child(_make_table_row_bg(["A", "B", "Выход"], true))
	for row_data in truth:
		var out_val: int = row_data.get("out", 0)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		table.add_child(row)
		for key in ["a", "b", "out"]:
			var val: int = row_data.get(key, 0)
			var cell := PanelContainer.new()
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var cs := StyleBoxFlat.new()
			var is_out_col: bool = key == "out"
			if is_out_col and out_val == 1:
				cs.bg_color     = Color(0.06, 0.20, 0.10, 1.0)
				cs.border_color = Color(0.20, 0.70, 0.40, 0.8)
			elif is_out_col:
				cs.bg_color     = Color(0.14, 0.06, 0.06, 1.0)
				cs.border_color = Color(0.55, 0.18, 0.18, 0.7)
			else:
				cs.bg_color     = Color(0.07, 0.08, 0.12, 1.0)
				cs.border_color = Color(0.15, 0.15, 0.22, 0.5)
			cs.set_border_width_all(1)
			cs.corner_radius_top_left    = 4; cs.corner_radius_top_right   = 4
			cs.corner_radius_bottom_left = 4; cs.corner_radius_bottom_right = 4
			cs.content_margin_left = 8; cs.content_margin_right = 8
			cs.content_margin_top  = 7; cs.content_margin_bottom = 7
			cell.add_theme_stylebox_override("panel", cs)
			row.add_child(cell)

			var lbl := Label.new()
			lbl.text = str(val)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.add_theme_font_size_override("font_size", 16)
			var col: Color
			if is_out_col and out_val == 1:
				col = Color(0.25, 0.90, 0.55, 1.0)
			elif is_out_col:
				col = Color(0.90, 0.30, 0.30, 1.0)
			else:
				col = Color(0.80, 0.80, 0.90, 1.0)
			lbl.add_theme_color_override("font_color", col)
			cell.add_child(lbl)


func render_gate_not_styled(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var header_panel := PanelContainer.new()
	var hp := StyleBoxFlat.new()
	hp.bg_color = Color(0.06, 0.14, 0.22, 1.0)
	hp.border_color = Color(0.15, 0.50, 0.85, 0.8)
	hp.set_border_width_all(1)
	hp.corner_radius_top_left    = 8; hp.corner_radius_top_right   = 8
	hp.corner_radius_bottom_left = 8; hp.corner_radius_bottom_right = 8
	hp.content_margin_left = 14; hp.content_margin_right = 14
	hp.content_margin_top  = 10; hp.content_margin_bottom = 10
	header_panel.add_theme_stylebox_override("panel", hp)
	container.add_child(header_panel)

	var name_lbl := Label.new()
	name_lbl.text = "NOT    (один вход)"
	name_lbl.add_theme_font_size_override("font_size", 24)
	name_lbl.add_theme_color_override("font_color", Color(0.35, 0.75, 1.00, 1.0))
	header_panel.add_child(name_lbl)

	var table := VBoxContainer.new()
	table.add_theme_constant_override("separation", 3)
	container.add_child(table)

	table.add_child(_make_table_row_bg(["Вход A", "Выход NOT(A)"], true))
	for pair in [[0, 1], [1, 0]]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		table.add_child(row)
		for i in range(2):
			var cell := PanelContainer.new()
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var cs := StyleBoxFlat.new()
			var is_out: bool = i == 1
			var val: int = pair[i]
			if is_out:
				cs.bg_color     = Color(0.06, 0.20, 0.10, 1.0) if val == 1 else Color(0.14, 0.06, 0.06, 1.0)
				cs.border_color = Color(0.20, 0.70, 0.40, 0.8) if val == 1 else Color(0.55, 0.18, 0.18, 0.7)
			else:
				cs.bg_color     = Color(0.07, 0.08, 0.12, 1.0)
				cs.border_color = Color(0.15, 0.15, 0.22, 0.5)
			cs.set_border_width_all(1)
			cs.corner_radius_top_left    = 4; cs.corner_radius_top_right   = 4
			cs.corner_radius_bottom_left = 4; cs.corner_radius_bottom_right = 4
			cs.content_margin_left = 8; cs.content_margin_right = 8
			cs.content_margin_top  = 7; cs.content_margin_bottom = 7
			cell.add_theme_stylebox_override("panel", cs)
			row.add_child(cell)
			var lbl := Label.new()
			lbl.text = str(val)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.add_theme_font_size_override("font_size", 16)
			lbl.add_theme_color_override("font_color",
				Color(0.25, 0.90, 0.55, 1.0) if val == 1 else Color(0.90, 0.30, 0.30, 1.0))
			cell.add_child(lbl)


func render_nand_nor_table(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 10)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	for gate_info in [
		{"name": "NAND", "table": [[0,0,1],[0,1,1],[1,0,1],[1,1,0]]},
		{"name": "NOR",  "table": [[0,0,1],[0,1,0],[1,0,0],[1,1,0]]},
	]:
		var gate_panel := PanelContainer.new()
		var gp := StyleBoxFlat.new()
		gp.bg_color = Color(0.08, 0.08, 0.14, 1.0)
		gp.border_color = Color(0.30, 0.30, 0.50, 0.6)
		gp.set_border_width_all(1)
		gp.corner_radius_top_left    = 8; gp.corner_radius_top_right   = 8
		gp.corner_radius_bottom_left = 8; gp.corner_radius_bottom_right = 8
		gp.content_margin_left = 12; gp.content_margin_right = 12
		gp.content_margin_top  = 10; gp.content_margin_bottom = 10
		gate_panel.add_theme_stylebox_override("panel", gp)
		container.add_child(gate_panel)

		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 4)
		gate_panel.add_child(vb)

		var title_lbl := Label.new()
		title_lbl.text = gate_info["name"]
		title_lbl.add_theme_font_size_override("font_size", 18)
		title_lbl.add_theme_color_override("font_color", Color(0.35, 0.75, 1.00, 1.0))
		vb.add_child(title_lbl)

		vb.add_child(_make_table_row_bg(["A", "B", "Выход"], true))
		for row_arr in gate_info["table"]:
			vb.add_child(_make_table_row_bg(
				[str(row_arr[0]), str(row_arr[1]), str(row_arr[2])], false))


func render_all_gates_compare(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var pairs := [
		["A=1, B=1", "AND→1", "OR→1", "XOR→0", "NAND→0", "NOR→0"],
		["A=0, B=0", "AND→0", "OR→0", "XOR→0", "NAND→1", "NOR→1"],
		["A=1, B=0", "AND→0", "OR→1", "XOR→1", "NAND→1", "NOR→0"],
	]
	container.add_child(_make_table_row_bg(["Входы", "AND", "OR", "XOR", "NAND", "NOR"], true))
	for row_data in pairs:
		container.add_child(_make_table_row_bg(row_data, false))


func render_ent_practice(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var problems := [
		{"inputs": "A=1, B=1", "gate": "AND",  "result": "1", "hint": "Оба 1 → 1"},
		{"inputs": "A=1, B=0", "gate": "OR",   "result": "1", "hint": "Хотя бы один 1 → 1"},
		{"inputs": "A=0, B=0", "gate": "XOR",  "result": "0", "hint": "Оба одинаковы → 0"},
		{"inputs": "A=1, B=1", "gate": "NAND", "result": "0", "hint": "NOT(AND(1,1)) = NOT(1) = 0"},
	]
	for prob in problems:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		container.add_child(row)

		var q_panel := PanelContainer.new()
		q_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var qs := StyleBoxFlat.new()
		qs.bg_color = Color(0.07, 0.08, 0.14, 1.0)
		qs.border_color = Color(0.20, 0.25, 0.45, 0.6)
		qs.set_border_width_all(1)
		qs.corner_radius_top_left    = 6; qs.corner_radius_top_right   = 6
		qs.corner_radius_bottom_left = 6; qs.corner_radius_bottom_right = 6
		qs.content_margin_left = 10; qs.content_margin_right = 10
		qs.content_margin_top  = 7;  qs.content_margin_bottom = 7
		q_panel.add_theme_stylebox_override("panel", qs)
		row.add_child(q_panel)

		var q_lbl := Label.new()
		q_lbl.text = "%s, вентиль %s" % [prob["inputs"], prob["gate"]]
		q_lbl.add_theme_font_size_override("font_size", 13)
		q_lbl.add_theme_color_override("font_color", Color(0.80, 0.80, 0.90, 1.0))
		q_panel.add_child(q_lbl)

		var a_panel := PanelContainer.new()
		var as_ := StyleBoxFlat.new()
		as_.bg_color = Color(0.06, 0.18, 0.10, 1.0)
		as_.border_color = Color(0.20, 0.65, 0.38, 0.7)
		as_.set_border_width_all(1)
		as_.corner_radius_top_left    = 6; as_.corner_radius_top_right   = 6
		as_.corner_radius_bottom_left = 6; as_.corner_radius_bottom_right = 6
		as_.content_margin_left = 12; as_.content_margin_right = 12
		as_.content_margin_top  = 7;  as_.content_margin_bottom = 7
		a_panel.add_theme_stylebox_override("panel", as_)
		row.add_child(a_panel)

		var a_lbl := Label.new()
		a_lbl.text = "→ %s" % prob["result"]
		a_lbl.add_theme_font_size_override("font_size", 18)
		a_lbl.add_theme_color_override("font_color", Color(0.25, 0.90, 0.55, 1.0))
		a_panel.add_child(a_lbl)


# ─── HELPERS ──────────────────────────────────────────────────────────────────

func _make_table_row_bg(values: Array, is_header: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	for val in values:
		var cell := PanelContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cs := StyleBoxFlat.new()
		cs.bg_color     = Color(0.10, 0.12, 0.20, 1.0) if is_header else Color(0.07, 0.08, 0.12, 1.0)
		cs.border_color = Color(0.22, 0.35, 0.55, 0.7) if is_header else Color(0.15, 0.15, 0.22, 0.5)
		cs.set_border_width_all(1)
		cs.corner_radius_top_left    = 4; cs.corner_radius_top_right   = 4
		cs.corner_radius_bottom_left = 4; cs.corner_radius_bottom_right = 4
		cs.content_margin_left = 8; cs.content_margin_right = 8
		cs.content_margin_top  = 6; cs.content_margin_bottom = 6
		cell.add_theme_stylebox_override("panel", cs)
		row.add_child(cell)
		var lbl := Label.new()
		lbl.text = str(val)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 13 if is_header else 14)
		lbl.add_theme_color_override("font_color",
			Color(0.5, 0.7, 1.0, 1.0) if is_header else Color(0.8, 0.8, 0.9, 1.0))
		cell.add_child(lbl)
	return row

func _calculate_stars() -> int:
	return 3 if current_step_index >= tutorial_steps.size() - 1 else 2
