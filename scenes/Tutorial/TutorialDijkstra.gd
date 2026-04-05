extends "res://scenes/Tutorial/TutorialBase.gd"
# Алгоритм Дейкстры для кратчайших путей
# Готовит к: CityMap B/C

class_name TutorialDijkstra

func _initialize_tutorial() -> void:
	tutorial_id = "graph_dijkstra"
	tutorial_title = "Алгоритм Дейкстры"
	linked_quest_scene = "res://scenes/CityMapQuestB.tscn"

	tutorial_steps = [
		{
			"text": "Алгоритм Дейкстры ищет кратчайшие пути от стартовой вершины до всех остальных в графе с НЕОТРИЦАТЕЛЬНЫМИ весами.\n\nВес ребра — это стоимость шага (время, расстояние, цена).\n\nВ задачах ЕНТ обычно просят путь до конкретной вершины.",
			"render_func": "render_intro",
		},
		{
			"text": "Идея алгоритма:\n1) dist[start] = 0, остальные = ∞\n2) Берём непосещённую вершину с минимальным dist\n3) Пытаемся улучшить соседей (релаксация)\n4) Помечаем вершину как обработанную\n5) Повторяем\n\nПосле фиксации вершины её расстояние уже оптимально.",
			"render_func": "render_algorithm_steps",
		},
		{
			"text": "Пример графа (старт A):\nA-B:4, A-C:2, C-B:1, B-D:5, C-D:8, C-E:10, D-E:2\n\nНужно найти кратчайший путь из A в E.",
			"render_func": "render_graph_data",
		},
		{
			"text": "Пошаговая таблица Дейкстры для этого графа.\n\nСмотри, как обновляются расстояния после выбора минимальной вершины.",
			"render_func": "render_iteration_table",
		},
		{
			"text": "Восстановление пути делается через массив prev (предков).\n\nЕсли prev[E]=D, prev[D]=B, prev[B]=C, prev[C]=A,\nто путь A→C→B→D→E.",
			"render_func": "render_path_restore",
		},
		{
			"text": "Оценка сложности:\n• Наивно (без очереди приоритетов): O(V²)\n• С очередью приоритетов: O((V+E) log V)\n\nВ школьных задачах чаще применяют табличный, «ручной» вариант.",
			"render_func": "render_complexity",
		},
		{
			"text": "Типичные ошибки:\n• Обновляют уже зафиксированную вершину\n• Выбирают не минимальный dist\n• Путают порядок восстановления пути\n• Применяют Дейкстру к отрицательным весам\n\nПроверка: итоговый путь должен совпадать с суммой рёбер по таблице.",
			"render_func": "render_common_errors",
		},
	]


func render_intro(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 6)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	container.add_child(_make_row_bg(["Алгоритм", "Когда использовать", "Когда нельзя"], true))
	container.add_child(_make_row_bg(["Dijkstra", "Веса >= 0", "Отрицательные веса"], false))

	var note := Label.new()
	note.text = "Цель: минимальная суммарная стоимость пути"
	note.add_theme_font_size_override("font_size", 14)
	note.add_theme_color_override("font_color", Color(0.90,0.82,0.25,1.0))
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(note)


func render_algorithm_steps(area: Control, _step: Dictionary) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _flat_style(Color(0.08,0.10,0.20,1.0), Color(0.25,0.45,0.85,0.7), 1, 8))
	area.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	panel.add_child(vb)

	for step_text in [
		"1) Инициализация dist: старт=0, остальные=∞",
		"2) Выбери непосещённую вершину с минимумом dist",
		"3) Для каждого соседа проверь улучшение",
		"4) Зафиксируй вершину как посещённую",
		"5) Повтори до конца",
	]:
		var lbl := Label.new()
		lbl.text = step_text
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.80,0.80,0.90,1.0))
		vb.add_child(lbl)


func render_graph_data(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 3)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	container.add_child(_make_row_bg(["Ребро", "Вес"], true))
	for e in [["A-B","4"],["A-C","2"],["C-B","1"],["B-D","5"],["C-D","8"],["C-E","10"],["D-E","2"]]:
		container.add_child(_make_row_bg(e, false))


func render_iteration_table(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 3)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	container.add_child(_make_row_bg(["Шаг", "Выбрали", "dist(A,B,C,D,E)"], true))
	for row_data in [
		["0", "A", "0, ∞, ∞, ∞, ∞"],
		["1", "C", "0, 4, 2, 10, 12"],
		["2", "B", "0, 3, 2, 8, 12"],
		["3", "D", "0, 3, 2, 8, 10"],
		["4", "E", "0, 3, 2, 8, 10"],
	]:
		container.add_child(_make_row_bg(row_data, false))

	var result := Label.new()
	result.text = "Кратчайший путь A→E: стоимость 10"
	result.add_theme_font_size_override("font_size", 14)
	result.add_theme_color_override("font_color", Color(0.20,0.85,0.55,1.0))
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(result)


func render_path_restore(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 5)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	container.add_child(_make_row_bg(["Вершина", "prev"], true))
	for p in [["B","C"],["C","A"],["D","B"],["E","D"]]:
		container.add_child(_make_row_bg(p, false))

	var route := Label.new()
	route.text = "Восстановленный путь: A → C → B → D → E"
	route.add_theme_font_size_override("font_size", 15)
	route.add_theme_color_override("font_color", Color(0.75,0.40,1.00,1.0))
	route.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(route)


func render_complexity(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 6)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	for item in [
		["Табличный вариант", "O(V²)", Color(0.35,0.70,1.00,1.0)],
		["С приоритетной очередью", "O((V+E) log V)", Color(0.20,0.85,0.55,1.0)],
	]:
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", _flat_style(item[2]*Color(1,1,1,0.10), item[2], 1, 7))
		container.add_child(p)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		p.add_child(hb)

		var k := Label.new()
		k.text = item[0]
		k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		k.add_theme_font_size_override("font_size", 13)
		k.add_theme_color_override("font_color", Color(0.80,0.80,0.90,1.0))
		hb.add_child(k)

		var v := Label.new()
		v.text = item[1]
		v.add_theme_font_size_override("font_size", 14)
		v.add_theme_color_override("font_color", item[2])
		hb.add_child(v)


func render_common_errors(area: Control, _step: Dictionary) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _flat_style(Color(0.10,0.07,0.07,1.0), Color(0.65,0.18,0.18,0.7), 1, 8))
	area.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	panel.add_child(vb)

	for line in [
		"• Не выбирать вершину с минимальным dist",
		"• Игнорировать обновление соседа через более короткий путь",
		"• Применять алгоритм при отрицательных весах",
		"• Восстанавливать путь не через prev, а по памяти",
	]:
		var lbl := Label.new()
		lbl.text = line
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.85,0.80,0.80,1.0))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		vb.add_child(lbl)


# HELPERS ─────────────────────────────────────────────────────
func _flat_style(bg: Color, border: Color, bw: int = 1, radius: int = 6) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s

func _make_cell(text: String, fsize: int, fcol: Color, bg: Color, border: Color) -> PanelContainer:
	var cell := PanelContainer.new()
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cs := StyleBoxFlat.new()
	cs.bg_color = bg
	cs.border_color = border
	cs.set_border_width_all(1)
	cs.corner_radius_top_left = 3
	cs.corner_radius_top_right = 3
	cs.corner_radius_bottom_left = 3
	cs.corner_radius_bottom_right = 3
	cs.content_margin_left = 6
	cs.content_margin_right = 6
	cs.content_margin_top = 5
	cs.content_margin_bottom = 5
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
		row.add_child(_make_cell(str(val), 12,
			Color(0.5,0.7,1.0,1.0) if is_header else Color(0.8,0.8,0.9,1.0),
			Color(0.10,0.12,0.20,1.0) if is_header else Color(0.07,0.08,0.12,1.0),
			Color(0.22,0.35,0.55,0.7) if is_header else Color(0.15,0.15,0.22,0.5)))
	return row

func _calculate_stars() -> int:
	return 3 if current_step_index >= tutorial_steps.size() - 1 else 2
