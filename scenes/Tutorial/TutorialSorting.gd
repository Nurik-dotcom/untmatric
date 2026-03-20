extends "res://scenes/Tutorial/TutorialBase.gd"
# TutorialSorting.gd — Алгоритмы сортировки
# Готовит к: Архив данных B/C

class_name TutorialSorting

func _initialize_tutorial() -> void:
	tutorial_id = "algo_sort"
	tutorial_title = "Алгоритмы сортировки"
	linked_quest_scene = "res://scenes/case_07/da7_data_archive_b.tscn"

	tutorial_steps = [
		{
			"text": "Сортировка — упорядочивание элементов массива.\n\nЗачем это нужно:\n• Поиск в отсортированном массиве намного быстрее\n• Многие алгоритмы требуют отсортированных данных\n• ЕНТ проверяет понимание алгоритмов и их сложность\n\nТри алгоритма которые нужно знать:\n1. Пузырьковая (Bubble Sort)\n2. Выборочная (Selection Sort)\n3. Вставками (Insertion Sort)",
			"render_func": "render_sort_overview",
		},
		{
			"text": "Пузырьковая сортировка (Bubble Sort):\n\nИдея: сравниваем соседние элементы, меняем местами если нужно. Большие «всплывают» наверх.\n\nМассив: [5, 3, 8, 1, 4]\n\nПроход 1:\n5↔3 → [3,5,8,1,4]\n5<8 → без изм.\n8↔1 → [3,5,1,8,4]\n8↔4 → [3,5,1,4,8] ← 8 встал на место\n\nСложность: O(n²) — для каждого из n элементов делаем до n сравнений.",
			"render_func": "render_bubble_sort",
			"array": [5, 3, 8, 1, 4],
			"passes": [
				[3, 5, 1, 4, 8],
				[3, 1, 4, 5, 8],
				[1, 3, 4, 5, 8],
				[1, 3, 4, 5, 8],
			],
		},
		{
			"text": "Выборочная сортировка (Selection Sort):\n\nИдея: находим минимум в неотсортированной части, ставим в начало.\n\nМассив: [5, 3, 8, 1, 4]\n\nШаг 1: минимум в [5,3,8,1,4] = 1, меняем с 5\n→ [1, 3, 8, 5, 4]\n\nШаг 2: минимум в [3,8,5,4] = 3, уже на месте\n→ [1, 3, 8, 5, 4]\n\nШаг 3: минимум в [8,5,4] = 4, меняем с 8\n→ [1, 3, 4, 5, 8]\n\nСложность: O(n²), но делает меньше перестановок чем пузырёк.",
			"render_func": "render_selection_sort",
			"array": [5, 3, 8, 1, 4],
			"steps": [
				{"sorted": [], "unsorted": [5, 3, 8, 1, 4], "min_idx": 3, "swap": [0, 3]},
				{"sorted": [1], "unsorted": [3, 8, 5, 4], "min_idx": 0, "swap": []},
				{"sorted": [1, 3], "unsorted": [8, 5, 4], "min_idx": 2, "swap": [0, 2]},
				{"sorted": [1, 3, 4], "unsorted": [5, 8], "min_idx": 0, "swap": []},
			],
		},
		{
			"text": "Вставками (Insertion Sort):\n\nИдея: строим отсортированную часть слева. Каждый новый элемент вставляем на правильное место.\n\nМассив: [5, 3, 8, 1, 4]\n\n[5] | 3 → 3<5, сдвигаем: [3, 5]\n[3,5] | 8 → 8>5, место найдено: [3, 5, 8]\n[3,5,8] | 1 → сдвигаем всё: [1, 3, 5, 8]\n[1,3,5,8] | 4 → вставляем: [1, 3, 4, 5, 8]\n\nСложность: O(n²) в худшем случае, O(n) для почти отсортированного.",
			"render_func": "render_insertion_sort",
			"array": [5, 3, 8, 1, 4],
			"steps": [
				[3, 5],
				[3, 5, 8],
				[1, 3, 5, 8],
				[1, 3, 4, 5, 8],
			],
		},
		{
			"text": "Сравнение алгоритмов — таблица для ЕНТ:\n\nВсе три алгоритма выше имеют сложность O(n²) — это значит что при n=100 нужно ~10 000 операций, при n=1000 — ~1 000 000.\n\nДля больших данных используют быстрые алгоритмы:\nMerge Sort и Quick Sort — O(n × log n)\n\nВ ЕНТ чаще всего спрашивают:\n• Сколько сравнений/перестановок в худшем случае\n• Как работает конкретный алгоритм пошагово",
			"render_func": "render_comparison_table",
		},
		{
			"text": "Задача ЕНТ на счёт шагов:\n\nМассив [4, 2, 7, 1, 5], пузырьковая сортировка.\n«Сколько перестановок в первом проходе?»\n\nПроход 1:\n4>2 → переставить (1)\n4<7 → нет\n7>1 → переставить (2)\n7>5 → переставить (3)\n\nОтвет: 3 перестановки.\n\nПравило: в первом проходе пузырёк делает столько перестановок, сколько инверсий (пар где большее стоит перед меньшим).",
			"render_func": "render_ent_task",
			"array": [4, 2, 7, 1, 5],
			"swaps": [[0,1], [2,3], [3,4]],
			"result": [2, 4, 1, 5, 7],
		},
	]


# ══════════════════════════════════════════════════════════════
# RENDER FUNCTIONS
# ══════════════════════════════════════════════════════════════

func _make_array_row(values: Array, highlight_indices: Array = [],
		hi_color: Color = Color(0.9, 0.8, 0.2, 1.0),
		sorted_count: int = 0) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in range(values.size()):
		var cell := PanelContainer.new()
		cell.custom_minimum_size = Vector2(42, 42)
		var cs := StyleBoxFlat.new()
		cs.corner_radius_top_left    = 6; cs.corner_radius_top_right   = 6
		cs.corner_radius_bottom_left = 6; cs.corner_radius_bottom_right = 6
		cs.content_margin_left = 4; cs.content_margin_right = 4
		cs.content_margin_top  = 4; cs.content_margin_bottom = 4
		cs.set_border_width_all(1)

		if i < sorted_count:
			cs.bg_color     = Color(0.06, 0.20, 0.10, 1.0)
			cs.border_color = Color(0.20, 0.70, 0.40, 0.8)
		elif i in highlight_indices:
			cs.bg_color     = hi_color * Color(1, 1, 1, 0.20)
			cs.border_color = hi_color
		else:
			cs.bg_color     = Color(0.09, 0.09, 0.14, 1.0)
			cs.border_color = Color(0.25, 0.25, 0.38, 0.7)
		cell.add_theme_stylebox_override("panel", cs)
		row.add_child(cell)

		var lbl := Label.new()
		lbl.text = str(values[i])
		lbl.add_theme_font_size_override("font_size", 20)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		var col: Color
		if i < sorted_count:
			col = Color(0.25, 0.90, 0.55, 1.0)
		elif i in highlight_indices:
			col = hi_color
		else:
			col = Color(0.75, 0.75, 0.88, 1.0)
		lbl.add_theme_color_override("font_color", col)
		cell.add_child(lbl)
	return row


func render_sort_overview(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 6)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	for algo in [
		["Пузырьковая", "Bubble", "O(n²)", "Сравниваем соседей", Color(0.35, 0.70, 1.00, 1.0)],
		["Выборочная", "Selection", "O(n²)", "Ищем минимум каждый раз", Color(0.20, 0.85, 0.55, 1.0)],
		["Вставками", "Insertion", "O(n²)", "Вставляем в нужное место", Color(0.80, 0.60, 0.20, 1.0)],
	]:
		var panel := PanelContainer.new()
		var ps := StyleBoxFlat.new()
		ps.bg_color = algo[4] * Color(1, 1, 1, 0.10)
		ps.border_color = algo[4]
		ps.set_border_width_all(1)
		ps.corner_radius_top_left    = 8; ps.corner_radius_top_right   = 8
		ps.corner_radius_bottom_left = 8; ps.corner_radius_bottom_right = 8
		ps.content_margin_left = 12; ps.content_margin_right = 12
		ps.content_margin_top  = 7;  ps.content_margin_bottom = 7
		panel.add_theme_stylebox_override("panel", ps)
		container.add_child(panel)

		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		panel.add_child(hb)

		var name_lbl := Label.new()
		name_lbl.text = algo[0]
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.add_theme_color_override("font_color", algo[4])
		name_lbl.custom_minimum_size = Vector2(110, 0)
		hb.add_child(name_lbl)

		var big_o := Label.new()
		big_o.text = algo[2]
		big_o.add_theme_font_size_override("font_size", 14)
		big_o.add_theme_color_override("font_color", algo[4])
		big_o.custom_minimum_size = Vector2(55, 0)
		hb.add_child(big_o)

		var desc := Label.new()
		desc.text = algo[3]
		desc.add_theme_font_size_override("font_size", 12)
		desc.add_theme_color_override("font_color", Color(0.65, 0.65, 0.78, 1.0))
		hb.add_child(desc)


func render_bubble_sort(area: Control, step: Dictionary) -> void:
	var initial: Array = step.get("array", [5, 3, 8, 1, 4])
	var passes: Array  = step.get("passes", [])

	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var lbl0 := Label.new()
	lbl0.text = "Начало:"
	lbl0.add_theme_font_size_override("font_size", 12)
	lbl0.add_theme_color_override("font_color", Color(0.55, 0.55, 0.70, 1.0))
	container.add_child(lbl0)
	container.add_child(_make_array_row(initial))

	for i in range(passes.size()):
		var lbl := Label.new()
		lbl.text = "После прохода %d:" % (i + 1)
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.70, 1.0))
		container.add_child(lbl)
		# Подсветить уже отсортированные (справа)
		container.add_child(_make_array_row(passes[i], [], Color.WHITE, i + 1))


func render_selection_sort(area: Control, step: Dictionary) -> void:
	var initial: Array = step.get("array", [5, 3, 8, 1, 4])
	var steps_data: Array = step.get("steps", [])

	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var lbl0 := Label.new()
	lbl0.text = "Начало:"
	lbl0.add_theme_font_size_override("font_size", 12)
	lbl0.add_theme_color_override("font_color", Color(0.55, 0.55, 0.70, 1.0))
	container.add_child(lbl0)
	container.add_child(_make_array_row(initial))

	var current := initial.duplicate()
	for i in range(steps_data.size()):
		var s: Dictionary = steps_data[i]
		var sorted_part: Array = s.get("sorted", [])
		var unsorted_part: Array = s.get("unsorted", [])
		var min_idx: int = s.get("min_idx", 0)
		var swap_pair: Array = s.get("swap", [])

		var lbl := Label.new()
		lbl.text = "Шаг %d (минимум = %s):" % [i + 1,
			str(unsorted_part[min_idx]) if min_idx < unsorted_part.size() else "?"]
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.70, 1.0))
		container.add_child(lbl)

		var combined := sorted_part + unsorted_part
		var hi: Array = []
		if swap_pair.size() == 2:
			hi = [sorted_part.size() + swap_pair[0], sorted_part.size() + swap_pair[1]]
		container.add_child(_make_array_row(combined, hi,
			Color(0.90, 0.65, 0.20, 1.0), sorted_part.size()))

		if swap_pair.size() == 2 and not unsorted_part.is_empty():
			var a: int = swap_pair[0]; var b: int = swap_pair[1]
			var temp: int = unsorted_part[a]
			unsorted_part[a] = unsorted_part[b]
			unsorted_part[b] = temp


func render_insertion_sort(area: Control, step: Dictionary) -> void:
	var initial: Array = step.get("array", [5, 3, 8, 1, 4])
	var steps_data: Array = step.get("steps", [])

	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var lbl0 := Label.new()
	lbl0.text = "Начало:"
	lbl0.add_theme_font_size_override("font_size", 12)
	lbl0.add_theme_color_override("font_color", Color(0.55, 0.55, 0.70, 1.0))
	container.add_child(lbl0)
	container.add_child(_make_array_row(initial))

	for i in range(steps_data.size()):
		var arr: Array = steps_data[i]
		var lbl := Label.new()
		lbl.text = "После вставки элемента %d:" % (i + 2)
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.70, 1.0))
		container.add_child(lbl)
		container.add_child(_make_array_row(arr, [], Color.WHITE, arr.size()))


func render_comparison_table(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var data := [
		["Пузырьковая", "O(n²)", "O(n²)", "O(n)", "Stable"],
		["Выборочная",  "O(n²)", "O(n²)", "O(n²)","Нет"],
		["Вставками",   "O(n²)", "O(n²)", "O(n)", "Stable"],
		["Merge Sort",  "O(n·logn)", "O(n·logn)", "O(n·logn)", "Stable"],
		["Quick Sort",  "O(n²)", "O(n·logn)", "O(n·logn)", "Нет"],
	]
	container.add_child(_make_table_row_bg(["Алгоритм", "Худший", "Средний", "Лучший", "Стаб?"], true))
	for row_data in data:
		container.add_child(_make_table_row_bg(row_data, false))


func render_ent_task(area: Control, step: Dictionary) -> void:
	var arr: Array     = step.get("array", [4, 2, 7, 1, 5])
	var swaps: Array   = step.get("swaps", [])
	var result: Array  = step.get("result", [])

	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var lbl_init := Label.new()
	lbl_init.text = "Исходный массив:"
	lbl_init.add_theme_font_size_override("font_size", 12)
	lbl_init.add_theme_color_override("font_color", Color(0.55, 0.55, 0.70, 1.0))
	container.add_child(lbl_init)
	container.add_child(_make_array_row(arr))

	var lbl_swap := Label.new()
	lbl_swap.text = "Перестановки (выделены):"
	lbl_swap.add_theme_font_size_override("font_size", 12)
	lbl_swap.add_theme_color_override("font_color", Color(0.55, 0.55, 0.70, 1.0))
	container.add_child(lbl_swap)

	var hi_flat: Array = []
	for pair in swaps:
		hi_flat.append_array(pair)
	container.add_child(_make_array_row(arr, hi_flat, Color(0.90, 0.65, 0.20, 1.0)))

	area.add_child(_make_info_panel(
		"Перестановок в 1-м проходе: %d" % swaps.size(),
		Color(0.08, 0.18, 0.12, 1.0), Color(0.20, 0.65, 0.42, 0.7)))

	if not result.is_empty():
		var lbl_res := Label.new()
		lbl_res.text = "После 1-го прохода:"
		lbl_res.add_theme_font_size_override("font_size", 12)
		lbl_res.add_theme_color_override("font_color", Color(0.55, 0.55, 0.70, 1.0))
		container.add_child(lbl_res)
		container.add_child(_make_array_row(result, [], Color.WHITE, 1))


# ══════════════════════════════════════════════════════════════
# HELPERS
# ══════════════════════════════════════════════════════════════

func _make_info_panel(text: String, bg: Color, border: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = bg; ps.border_color = border
	ps.set_border_width_all(1)
	ps.corner_radius_top_left    = 6; ps.corner_radius_top_right   = 6
	ps.corner_radius_bottom_left = 6; ps.corner_radius_bottom_right = 6
	ps.content_margin_left = 12; ps.content_margin_right = 12
	ps.content_margin_top  = 8;  ps.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", ps)
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 15)
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
		cs.corner_radius_top_left    = 4; cs.corner_radius_top_right   = 4
		cs.corner_radius_bottom_left = 4; cs.corner_radius_bottom_right = 4
		cs.content_margin_left = 6;  cs.content_margin_right = 6
		cs.content_margin_top  = 5;  cs.content_margin_bottom = 5
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
