extends "res://scenes/Tutorial/TutorialBase.gd"
# TutorialGraphs.gd — Графы: основы
# Готовит к: CityMapQuest A/B

class_name TutorialGraphs

func _initialize_tutorial() -> void:
	tutorial_id = "graph_basics"
	tutorial_title = "Графы: основы"
	linked_quest_scene = "res://scenes/CityMapQuestA.tscn"

	tutorial_steps = [
		{
			"text": "Граф — математическая структура из вершин (узлов) и рёбер (связей).\n\nВершина (Node/Vertex) — точка, объект\nРебро (Edge) — связь между двумя вершинами\n\nГрафы используются для моделирования:\n• Карт городов (вершины=города, рёбра=дороги)\n• Социальных сетей (люди и связи)\n• Компьютерных сетей (устройства и каналы)\n• Расписаний, зависимостей в коде",
			"render_func": "render_graph_intro",
		},
		{
			"text": "Виды графов:\n\nОриентированный (Directed) — рёбра со стрелками.\nСвязь A→B не означает B→A.\nПример: «А ведёт к Б» (односторонняя дорога)\n\nНеориентированный (Undirected) — рёбра без стрелок.\nЕсли A–B, то и B–A.\nПример: «А и Б соединены» (двусторонняя дорога)\n\nВзвешенный (Weighted) — у каждого ребра есть вес (расстояние, стоимость, время).",
			"render_func": "render_graph_types",
		},
		{
			"text": "Основные термины:\n\nСтепень вершины — количество рёбер, выходящих из неё.\nПуть — последовательность вершин через рёбра.\nЦикл — путь который возвращается в начало.\nСвязный граф — из любой вершины можно добраться до любой другой.\n\nВ ЕНТ часто спрашивают: «Степень вершины X?», «Существует ли путь из A в B?»",
			"render_func": "render_graph_terms",
		},
		{
			"text": "Представление графа — матрица смежности:\n\nДля графа с N вершинами — таблица N×N.\nЯчейка [i][j] = 1 если есть ребро из i в j, иначе 0.\nДля взвешенного — вместо 1 ставим вес.\n\nДостоинство: быстрая проверка связи O(1)\nНедостаток: много памяти O(N²)\n\nДля ЕНТ: умей читать матрицу и находить степени вершин.",
			"render_func": "render_adjacency_matrix",
			"edges": [[0,1],[0,2],[1,2],[1,3],[2,4],[3,4]],
			"n": 5,
		},
		{
			"text": "Обход графа — обход в ширину (BFS):\n\nBFS (Breadth-First Search) — идём «волной», сначала все соседи, потом их соседи.\n\nАлгоритм:\n1. Начать с вершины S, добавить в очередь\n2. Взять вершину из очереди\n3. Добавить все непосещённые соседи\n4. Повторять пока очередь не пуста\n\nПрименение: кратчайший путь в невзвешенном графе, обход сети.",
			"render_func": "render_bfs_demo",
		},
		{
			"text": "Дерево — частный случай графа:\n\nСвязный граф без циклов называется деревом.\n\nСвойства дерева:\n• N вершин → ровно N−1 рёбер\n• Между любыми двумя вершинами ровно 1 путь\n• Одна вершина — корень\n• У каждой не-корневой вершины ровно один родитель\n\nВ ЕНТ: «Является ли граф деревом?» — проверь: N−1 рёбер и нет циклов.",
			"render_func": "render_tree_demo",
		},
		{
			"text": "Задача ЕНТ: «Дан граф. Найди вершину с максимальной степенью.»\n\nСтепень = количество рёбер у вершины.\n\nДля неориентированного: считай сколько раз вершина встречается в списке рёбер.\n\nДля матрицы смежности: сумма строки (или столбца) = степень вершины.\n\nВ ориентированном:\n• Входящая степень (in-degree) = сумма столбца\n• Исходящая степень (out-degree) = сумма строки",
			"render_func": "render_degree_task",
			"edges": [[0,1],[0,2],[0,3],[1,2],[2,3],[2,4]],
			"n": 5,
			"labels": ["A", "B", "C", "D", "E"],
		},
	]


# ══════════════════════════════════════════════════════════════
# RENDER FUNCTIONS
# ══════════════════════════════════════════════════════════════

func render_graph_intro(area: Control, _step: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	area.add_child(row)

	for info in [
		{"icon": "●", "title": "Вершина", "desc": "Объект, узел,\nточка на карте", "col": Color(0.35, 0.70, 1.00, 1.0)},
		{"icon": "─", "title": "Ребро",   "desc": "Связь между\nдвумя вершинами", "col": Color(0.20, 0.85, 0.55, 1.0)},
	]:
		var cell := PanelContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cs := StyleBoxFlat.new()
		cs.bg_color     = info["col"] * Color(1, 1, 1, 0.10)
		cs.border_color = info["col"]
		cs.set_border_width_all(2)
		cs.corner_radius_top_left = 10; cs.corner_radius_top_right = 10
		cs.corner_radius_bottom_left = 10; cs.corner_radius_bottom_right = 10
		cs.content_margin_left = 12; cs.content_margin_right = 12
		cs.content_margin_top = 10; cs.content_margin_bottom = 10
		cell.add_theme_stylebox_override("panel", cs)
		row.add_child(cell)

		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 5)
		cell.add_child(vb)

		var icon_lbl := Label.new()
		icon_lbl.text = info["icon"]
		icon_lbl.add_theme_font_size_override("font_size", 32)
		icon_lbl.add_theme_color_override("font_color", info["col"])
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(icon_lbl)

		var title_lbl := Label.new()
		title_lbl.text = info["title"]
		title_lbl.add_theme_font_size_override("font_size", 18)
		title_lbl.add_theme_color_override("font_color", info["col"])
		title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(title_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = info["desc"]
		desc_lbl.add_theme_font_size_override("font_size", 13)
		desc_lbl.add_theme_color_override("font_color", Color(0.70, 0.70, 0.80, 1.0))
		desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		vb.add_child(desc_lbl)


func render_graph_types(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	for gtype in [
		["Неориентированный", "A ─── B", "Двусторонние дороги, соцсети", Color(0.35, 0.70, 1.00, 1.0)],
		["Ориентированный",   "A ──→ B", "Веб-ссылки, зависимости",     Color(0.20, 0.85, 0.55, 1.0)],
		["Взвешенный",        "A ─5─ B", "Карты с расстояниями",         Color(0.80, 0.60, 0.20, 1.0)],
	]:
		var panel := PanelContainer.new()
		var ps := StyleBoxFlat.new()
		ps.bg_color     = gtype[3] * Color(1, 1, 1, 0.09)
		ps.border_color = gtype[3]
		ps.set_border_width_all(1)
		ps.corner_radius_top_left = 8; ps.corner_radius_top_right = 8
		ps.corner_radius_bottom_left = 8; ps.corner_radius_bottom_right = 8
		ps.content_margin_left = 12; ps.content_margin_right = 12
		ps.content_margin_top = 8; ps.content_margin_bottom = 8
		panel.add_theme_stylebox_override("panel", ps)
		container.add_child(panel)

		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 12)
		panel.add_child(hb)

		var name_lbl := Label.new()
		name_lbl.text = gtype[0]
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.add_theme_color_override("font_color", gtype[3])
		name_lbl.custom_minimum_size = Vector2(160, 0)
		hb.add_child(name_lbl)

		var ex_lbl := Label.new()
		ex_lbl.text = gtype[1]
		ex_lbl.add_theme_font_size_override("font_size", 18)
		ex_lbl.add_theme_color_override("font_color", gtype[3])
		ex_lbl.custom_minimum_size = Vector2(80, 0)
		hb.add_child(ex_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = gtype[2]
		desc_lbl.add_theme_font_size_override("font_size", 12)
		desc_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.78, 1.0))
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(desc_lbl)


func render_graph_terms(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var terms := [
		["Степень вершины", "Число рёбер у вершины",           Color(0.35, 0.70, 1.00, 1.0)],
		["Путь",            "Цепочка вершин через рёбра",      Color(0.20, 0.85, 0.55, 1.0)],
		["Цикл",            "Путь, начало = конец",            Color(0.80, 0.60, 0.20, 1.0)],
		["Связность",       "Можно добраться до любой вершины",Color(0.80, 0.50, 1.00, 1.0)],
		["Дерево",          "Связный граф без циклов",         Color(0.55, 0.85, 0.55, 1.0)],
	]
	container.add_child(_make_table_row_bg(["Термин", "Определение"], true))
	for t in terms:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		container.add_child(row)
		for j in range(2):
			var cell := PanelContainer.new()
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var cs := StyleBoxFlat.new()
			cs.bg_color     = t[2] * Color(1, 1, 1, 0.08)
			cs.border_color = t[2] * Color(1, 1, 1, 0.35)
			cs.set_border_width_all(1)
			cs.corner_radius_top_left = 4; cs.corner_radius_top_right = 4
			cs.corner_radius_bottom_left = 4; cs.corner_radius_bottom_right = 4
			cs.content_margin_left = 8; cs.content_margin_right = 8
			cs.content_margin_top = 7; cs.content_margin_bottom = 7
			cell.add_theme_stylebox_override("panel", cs)
			row.add_child(cell)
			var lbl := Label.new()
			lbl.text = t[j]
			lbl.add_theme_font_size_override("font_size", 13)
			lbl.add_theme_color_override("font_color",
				t[2] if j == 0 else Color(0.80, 0.80, 0.90, 1.0))
			lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
			cell.add_child(lbl)


func render_adjacency_matrix(area: Control, step: Dictionary) -> void:
	var n: int       = step.get("n", 5)
	var edges: Array = step.get("edges", [])

	var matrix: Array = []
	for i in range(n):
		var row_arr: Array = []
		for _j in range(n):
			row_arr.append(0)
		matrix.append(row_arr)
	for edge in edges:
		matrix[edge[0]][edge[1]] = 1
		matrix[edge[1]][edge[0]] = 1

	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 3)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 3)
	container.add_child(header)
	header.add_child(_matrix_cell("", true, Color(0.55, 0.55, 0.70, 1.0)))
	for j in range(n):
		header.add_child(_matrix_cell(str(j), true, Color(0.35, 0.70, 1.00, 1.0)))

	for i in range(n):
		var row_h := HBoxContainer.new()
		row_h.add_theme_constant_override("separation", 3)
		container.add_child(row_h)
		row_h.add_child(_matrix_cell(str(i), true, Color(0.35, 0.70, 1.00, 1.0)))
		for j in range(n):
			var val: int = matrix[i][j]
			var col: Color = Color(0.20, 0.85, 0.55, 1.0) if val == 1 else Color(0.35, 0.35, 0.45, 1.0)
			row_h.add_child(_matrix_cell(str(val), false, col))


func _matrix_cell(text: String, is_header: bool, col: Color) -> PanelContainer:
	var cell := PanelContainer.new()
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.custom_minimum_size = Vector2(0, 30)
	var cs := StyleBoxFlat.new()
	cs.bg_color     = Color(0.10, 0.12, 0.20, 1.0) if is_header else Color(0.07, 0.08, 0.12, 1.0)
	cs.border_color = col * Color(1, 1, 1, 0.35)
	cs.set_border_width_all(1)
	cs.corner_radius_top_left = 3; cs.corner_radius_top_right = 3
	cs.corner_radius_bottom_left = 3; cs.corner_radius_bottom_right = 3
	cs.content_margin_left = 4; cs.content_margin_right = 4
	cs.content_margin_top = 4; cs.content_margin_bottom = 4
	cell.add_theme_stylebox_override("panel", cs)
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", col)
	cell.add_child(lbl)
	return cell


func render_bfs_demo(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 5)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var bfs_steps := [
		["Шаг 0", "Старт: A",  "Очередь: [A]",    "Посещено: {A}"],
		["Шаг 1", "Берём A",   "Очередь: [B,C]",  "Посещено: {A,B,C}"],
		["Шаг 2", "Берём B",   "Очередь: [C,D]",  "Посещено: {A,B,C,D}"],
		["Шаг 3", "Берём C",   "Очередь: [D,E]",  "Посещено: {A,B,C,D,E}"],
		["Шаг 4", "Берём D,E", "Очередь: []",     "Готово!"],
	]
	container.add_child(_make_table_row_bg(["Шаг", "Действие", "Очередь", "Посещено"], true))
	for s in bfs_steps:
		container.add_child(_make_table_row_bg(s, false))


func render_tree_demo(area: Control, _step: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	area.add_child(row)

	for info in [
		{"title": "Дерево ✓",    "body": "5 вершин\n4 ребра\nНет циклов",  "col": Color(0.20, 0.85, 0.55, 1.0)},
		{"title": "Не дерево ✗", "body": "5 вершин\n5 рёбер\nЕсть цикл!", "col": Color(0.90, 0.30, 0.30, 1.0)},
	]:
		var cell := PanelContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cs := StyleBoxFlat.new()
		cs.bg_color     = info["col"] * Color(1, 1, 1, 0.10)
		cs.border_color = info["col"]
		cs.set_border_width_all(2)
		cs.corner_radius_top_left = 10; cs.corner_radius_top_right = 10
		cs.corner_radius_bottom_left = 10; cs.corner_radius_bottom_right = 10
		cs.content_margin_left = 12; cs.content_margin_right = 12
		cs.content_margin_top = 10; cs.content_margin_bottom = 10
		cell.add_theme_stylebox_override("panel", cs)
		row.add_child(cell)

		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 6)
		cell.add_child(vb)

		var tl := Label.new()
		tl.text = info["title"]
		tl.add_theme_font_size_override("font_size", 18)
		tl.add_theme_color_override("font_color", info["col"])
		tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(tl)

		var bl := Label.new()
		bl.text = info["body"]
		bl.add_theme_font_size_override("font_size", 13)
		bl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85, 1.0))
		bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(bl)


func render_degree_task(area: Control, step: Dictionary) -> void:
	var n: int       = step.get("n", 5)
	var edges: Array = step.get("edges", [])
	var labels: Array = step.get("labels", ["A","B","C","D","E"])

	# Подсчёт степеней
	var degrees: Array = []
	for i in range(n):
		degrees.append(0)
	for edge in edges:
		degrees[edge[0]] += 1
		degrees[edge[1]] += 1

	var max_deg: int = 0
	var max_vert: String = ""
	for i in range(n):
		if degrees[i] > max_deg:
			max_deg = degrees[i]
			max_vert = labels[i]

	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 6)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	# Рёбра
	var edges_lbl := Label.new()
	var edge_strs: Array[String] = []
	for e in edges:
		edge_strs.append("%s─%s" % [labels[e[0]], labels[e[1]]])
	edges_lbl.text = "Рёбра: " + ", ".join(edge_strs)
	edges_lbl.add_theme_font_size_override("font_size", 13)
	edges_lbl.add_theme_color_override("font_color", Color(0.60, 0.60, 0.75, 1.0))
	edges_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	container.add_child(edges_lbl)

	# Таблица степеней
	container.add_child(_make_table_row_bg(["Вершина", "Степень"], true))
	for i in range(n):
		var is_max: bool = degrees[i] == max_deg
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		container.add_child(row)
		for j in range(2):
			var cell := PanelContainer.new()
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var cs := StyleBoxFlat.new()
			if is_max:
				cs.bg_color     = Color(0.06, 0.20, 0.10, 1.0)
				cs.border_color = Color(0.20, 0.70, 0.40, 0.8)
			else:
				cs.bg_color     = Color(0.07, 0.08, 0.12, 1.0)
				cs.border_color = Color(0.15, 0.15, 0.22, 0.5)
			cs.set_border_width_all(1)
			cs.corner_radius_top_left = 4; cs.corner_radius_top_right = 4
			cs.corner_radius_bottom_left = 4; cs.corner_radius_bottom_right = 4
			cs.content_margin_left = 8; cs.content_margin_right = 8
			cs.content_margin_top = 6; cs.content_margin_bottom = 6
			cell.add_theme_stylebox_override("panel", cs)
			row.add_child(cell)
			var lbl := Label.new()
			lbl.text = labels[i] if j == 0 else str(degrees[i])
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.add_theme_font_size_override("font_size", 14)
			lbl.add_theme_color_override("font_color",
				Color(0.25, 0.90, 0.55, 1.0) if is_max else Color(0.80, 0.80, 0.90, 1.0))
			cell.add_child(lbl)

	area.add_child(_make_info_panel(
		"Макс. степень: вершина %s = %d" % [max_vert, max_deg],
		Color(0.08, 0.18, 0.12, 1.0), Color(0.20, 0.65, 0.42, 0.7)))


# ══════════════════════════════════════════════════════════════
# HELPERS
# ══════════════════════════════════════════════════════════════

func _make_info_panel(text: String, bg: Color, border: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = bg; ps.border_color = border
	ps.set_border_width_all(1)
	ps.corner_radius_top_left = 6; ps.corner_radius_top_right = 6
	ps.corner_radius_bottom_left = 6; ps.corner_radius_bottom_right = 6
	ps.content_margin_left = 12; ps.content_margin_right = 12
	ps.content_margin_top = 8; ps.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", ps)
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.82, 0.25, 1.0))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	panel.add_child(lbl)
	return panel

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
		cs.corner_radius_top_left = 4; cs.corner_radius_top_right = 4
		cs.corner_radius_bottom_left = 4; cs.corner_radius_bottom_right = 4
		cs.content_margin_left = 8; cs.content_margin_right = 8
		cs.content_margin_top = 5; cs.content_margin_bottom = 5
		cell.add_theme_stylebox_override("panel", cs)
		row.add_child(cell)
		var lbl := Label.new()
		lbl.text = str(val)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color",
			Color(0.5, 0.7, 1.0, 1.0) if is_header else Color(0.8, 0.8, 0.9, 1.0))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		cell.add_child(lbl)
	return row

func _calculate_stars() -> int:
	return 3 if current_step_index >= tutorial_steps.size() - 1 else 2
