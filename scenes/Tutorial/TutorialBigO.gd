extends TutorialBase

func _initialize_tutorial() -> void:
	tutorial_id = "algo_complexity"
	tutorial_title = "Сложность алгоритмов: Big-O"
	linked_quest_scene = "res://scripts/case_08/fr8_final_report_c.gd"

	tutorial_steps = [
		{
			"text": "Сложность алгоритма — это оценка того, как растёт время работы при увеличении входных данных.\n\nЗапись O(f(n)) называется «Большое O» и описывает наихудший случай.",
			"render_func": "render_bigo_intro",
		},
		{
			"text": "O(1) — константная сложность. Время не зависит от размера данных.\n\nПримеры: чтение элемента массива по индексу, проверка первого символа строки.",
			"render_func": "render_o1",
		},
		{
			"text": "O(n) — линейная сложность. Время растёт пропорционально размеру данных.\n\nПримеры: линейный поиск, обход массива, подсчёт суммы.",
			"render_func": "render_on",
		},
		{
			"text": "O(n²) — квадратичная сложность. Время растёт как квадрат от n.\n\nПримеры: сортировка пузырьком, вставками, выборкой. Два вложенных цикла.",
			"render_func": "render_on2",
		},
		{
			"text": "O(log n) — логарифмическая сложность. Каждый шаг делит задачу пополам.\n\nПримеры: бинарный поиск, дихотомия. При n=1024 нужно всего 10 шагов.",
			"render_func": "render_ologn",
		},
		{
			"text": "Таблица сравнения сложностей: как растёт количество операций при n = 10, 100, 1000.",
			"render_func": "render_comparison_table",
		},
		{
			"text": "Задача ЕНТ: Алгоритм выполняет вложенный цикл: внешний от 1 до n, внутренний от 1 до n. Сколько операций при n=100? Какова сложность?",
			"render_func": "render_ent_task",
			"n": 100,
		},
	]

func _make_styled_cell(text: String, bg: Color, border: Color, min_w: float = 60.0) -> PanelContainer:
	var cell := PanelContainer.new()
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.custom_minimum_size = Vector2(min_w, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	cell.add_theme_stylebox_override("panel", style)
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95, 1.0))
	cell.add_child(lbl)
	return cell

func _make_row(cols: Array, bg: Color, border: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	for c in cols:
		row.add_child(_make_styled_cell(str(c), bg, border))
	return row

func _make_info_panel(text: String, bg: Color, border: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	var lbl := Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0, 1.0))
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(lbl)
	return panel

func render_bigo_intro(area: Control, _step: Dictionary) -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	area.add_child(vbox)

	var title := Label.new()
	title.text = "Классы сложности"
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color(0.0, 0.9, 0.9, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var classes: Array[Array] = [
		["O(1)", "Константная", "🟢"],
		["O(log n)", "Логарифмическая", "🟡"],
		["O(n)", "Линейная", "🟡"],
		["O(n log n)", "Линеарифмическая", "🟠"],
		["O(n²)", "Квадратичная", "🔴"],
		["O(2ⁿ)", "Экспоненциальная", "🔴"],
	]

	var colors: Array[Color] = [
		Color(0.05, 0.18, 0.08, 1.0),
		Color(0.1, 0.16, 0.05, 1.0),
		Color(0.1, 0.15, 0.05, 1.0),
		Color(0.18, 0.12, 0.03, 1.0),
		Color(0.2, 0.06, 0.06, 1.0),
		Color(0.25, 0.04, 0.04, 1.0),
	]
	var borders: Array[Color] = [
		Color(0.2, 0.7, 0.3, 0.8),
		Color(0.5, 0.65, 0.1, 0.8),
		Color(0.55, 0.65, 0.1, 0.8),
		Color(0.75, 0.5, 0.1, 0.8),
		Color(0.75, 0.2, 0.2, 0.8),
		Color(0.85, 0.1, 0.1, 0.8),
	]

	for i in range(classes.size()):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		vbox.add_child(row)

		var badge := _make_styled_cell(classes[i][0], colors[i], borders[i], 90.0)
		badge.get_child(0).add_theme_font_size_override("font_size", 16)
		row.add_child(badge)

		var name_lbl := Label.new()
		name_lbl.text = classes[i][2] + "  " + classes[i][1]
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.add_theme_color_override("font_color", Color(0.8, 0.82, 0.88, 1.0))
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(name_lbl)

func render_o1(area: Control, _step: Dictionary) -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	area.add_child(vbox)

	var title := Label.new()
	title.text = "O(1) — Константная сложность"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	vbox.add_child(_make_info_panel(
		"arr[5]  →  O(1)\nПрямой доступ по индексу.\nНе важно, 10 элементов или 10 000 000.",
		Color(0.05, 0.18, 0.08, 1.0), Color(0.2, 0.7, 0.3, 0.8)
	))

	var code_panel := _make_info_panel(
		"# Пример O(1)\nfunc get_first(arr):\n    return arr[0]  # одна операция",
		Color(0.06, 0.06, 0.12, 1.0), Color(0.2, 0.2, 0.4, 0.8)
	)
	vbox.add_child(code_panel)

	var table := VBoxContainer.new()
	table.add_theme_constant_override("separation", 3)
	vbox.add_child(table)

	table.add_child(_make_row(["n", "Операций"], Color(0.08, 0.12, 0.2, 1.0), Color(0.2, 0.4, 0.7, 0.8)))
	for n_val in [10, 100, 1000, 1000000]:
		table.add_child(_make_row([str(n_val), "1"], Color(0.06, 0.08, 0.12, 1.0), Color(0.15, 0.15, 0.25, 0.7)))

func render_on(area: Control, _step: Dictionary) -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	area.add_child(vbox)

	var title := Label.new()
	title.text = "O(n) — Линейная сложность"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	vbox.add_child(_make_info_panel(
		"Один проход по всем n элементам.\nВремя растёт линейно: вдвое больше данных → вдвое дольше.",
		Color(0.12, 0.12, 0.04, 1.0), Color(0.6, 0.55, 0.1, 0.8)
	))

	vbox.add_child(_make_info_panel(
		"# Пример O(n) — линейный поиск\nfunc find(arr, target):\n    for x in arr:\n        if x == target: return true\n    return false",
		Color(0.06, 0.06, 0.12, 1.0), Color(0.2, 0.2, 0.4, 0.8)
	))

	var table := VBoxContainer.new()
	table.add_theme_constant_override("separation", 3)
	vbox.add_child(table)

	table.add_child(_make_row(["n", "≈ Операций"], Color(0.08, 0.12, 0.2, 1.0), Color(0.2, 0.4, 0.7, 0.8)))
	for n_val in [10, 100, 1000]:
		table.add_child(_make_row([str(n_val), str(n_val)], Color(0.06, 0.08, 0.12, 1.0), Color(0.15, 0.15, 0.25, 0.7)))

func render_on2(area: Control, _step: Dictionary) -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	area.add_child(vbox)

	var title := Label.new()
	title.text = "O(n²) — Квадратичная сложность"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	vbox.add_child(_make_info_panel(
		"Два вложенных цикла по n.\nПри n=100 → 10 000 операций.\nПри n=1000 → 1 000 000 операций.",
		Color(0.2, 0.06, 0.04, 1.0), Color(0.75, 0.2, 0.15, 0.8)
	))

	vbox.add_child(_make_info_panel(
		"# Пример O(n²) — сортировка пузырьком\nfor i in range(n):\n    for j in range(n-1):\n        if arr[j] > arr[j+1]:\n            swap(arr, j, j+1)",
		Color(0.06, 0.06, 0.12, 1.0), Color(0.2, 0.2, 0.4, 0.8)
	))

	var table := VBoxContainer.new()
	table.add_theme_constant_override("separation", 3)
	vbox.add_child(table)

	table.add_child(_make_row(["n", "≈ Операций (n²)"], Color(0.08, 0.12, 0.2, 1.0), Color(0.2, 0.4, 0.7, 0.8)))
	var ns := [10, 100, 1000]
	for n_val in ns:
		table.add_child(_make_row([str(n_val), str(n_val * n_val)], Color(0.12, 0.05, 0.04, 1.0), Color(0.5, 0.15, 0.12, 0.7)))

func render_ologn(area: Control, _step: Dictionary) -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	area.add_child(vbox)

	var title := Label.new()
	title.text = "O(log n) — Логарифмическая"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	vbox.add_child(_make_info_panel(
		"Бинарный поиск: каждый шаг отбрасывает половину.\nn=1024 → 10 шагов (2¹⁰ = 1024)\nn=1048576 → 20 шагов (2²⁰)",
		Color(0.05, 0.1, 0.2, 1.0), Color(0.2, 0.5, 0.85, 0.8)
	))

	vbox.add_child(_make_info_panel(
		"# Бинарный поиск — O(log n)\nfunc bin_search(arr, target):\n    lo, hi = 0, len(arr)-1\n    while lo <= hi:\n        mid = (lo+hi)//2\n        if arr[mid]==target: return mid\n        elif arr[mid]<target: lo=mid+1\n        else: hi=mid-1",
		Color(0.06, 0.06, 0.12, 1.0), Color(0.2, 0.2, 0.4, 0.8)
	))

	var table := VBoxContainer.new()
	table.add_theme_constant_override("separation", 3)
	vbox.add_child(table)

	table.add_child(_make_row(["n", "log₂(n) шагов"], Color(0.08, 0.12, 0.2, 1.0), Color(0.2, 0.4, 0.7, 0.8)))
	var pairs: Array[Array] = [
		[8, 3], [16, 4], [64, 6], [1024, 10], [1048576, 20]
	]
	for p in pairs:
		table.add_child(_make_row([str(p[0]), str(p[1])], Color(0.05, 0.08, 0.15, 1.0), Color(0.15, 0.25, 0.5, 0.7)))

func render_comparison_table(area: Control, _step: Dictionary) -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	area.add_child(vbox)

	var title := Label.new()
	title.text = "Сравнение сложностей"
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color(0.0, 0.9, 0.9, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var table := VBoxContainer.new()
	table.add_theme_constant_override("separation", 3)
	vbox.add_child(table)

	# Header
	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 3)
	table.add_child(hdr)
	for col_text in ["Класс", "n=10", "n=100", "n=1000"]:
		var c := _make_styled_cell(col_text, Color(0.08, 0.12, 0.2, 1.0), Color(0.2, 0.4, 0.7, 0.8))
		c.get_child(0).add_theme_color_override("font_color", Color(0.5, 0.75, 1.0, 1.0))
		hdr.add_child(c)

	# Data rows
	var rows_data: Array[Array] = [
		["O(1)", "1", "1", "1"],
		["O(log n)", "3", "7", "10"],
		["O(n)", "10", "100", "1 000"],
		["O(n log n)", "33", "664", "9 966"],
		["O(n²)", "100", "10 000", "1 000 000"],
	]
	var row_bgs: Array[Color] = [
		Color(0.05, 0.18, 0.08, 1.0),
		Color(0.05, 0.1, 0.2, 1.0),
		Color(0.1, 0.12, 0.05, 1.0),
		Color(0.15, 0.1, 0.03, 1.0),
		Color(0.2, 0.05, 0.04, 1.0),
	]
	var row_borders: Array[Color] = [
		Color(0.2, 0.65, 0.3, 0.7),
		Color(0.2, 0.5, 0.8, 0.7),
		Color(0.55, 0.6, 0.1, 0.7),
		Color(0.75, 0.5, 0.1, 0.7),
		Color(0.75, 0.2, 0.15, 0.7),
	]

	for i in range(rows_data.size()):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		table.add_child(row)
		for j in range(rows_data[i].size()):
			var cell := _make_styled_cell(rows_data[i][j], row_bgs[i], row_borders[i])
			if j == 0:
				cell.get_child(0).add_theme_font_size_override("font_size", 15)
			row.add_child(cell)

func render_ent_task(area: Control, step: Dictionary) -> void:
	var n: int = step.get("n", 100)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	area.add_child(vbox)

	var title := Label.new()
	title.text = "Задача ЕНТ"
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color(0.0, 0.9, 0.9, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	vbox.add_child(_make_info_panel(
		"for i in range(%d):\n    for j in range(%d):\n        do_something()" % [n, n],
		Color(0.06, 0.06, 0.14, 1.0), Color(0.2, 0.25, 0.55, 0.8)
	))

	var ops: int = n * n
	vbox.add_child(_make_info_panel(
		"Внешний цикл: %d итераций\nВнутренний цикл: %d итераций\nВсего: %d × %d = %s операций" % [
			n, n, n, n, _format_number(ops)
		],
		Color(0.06, 0.12, 0.06, 1.0), Color(0.2, 0.6, 0.25, 0.8)
	))

	vbox.add_child(_make_info_panel(
		"Два вложенных цикла по n → O(n²)\nПри n=%d: %s операций" % [n, _format_number(ops)],
		Color(0.14, 0.08, 0.02, 1.0), Color(0.7, 0.45, 0.1, 0.8)
	))

	var answer_panel := _make_info_panel(
		"✅ Ответ: O(n²)\nОперации: %s" % _format_number(ops),
		Color(0.05, 0.2, 0.08, 1.0), Color(0.25, 0.75, 0.35, 0.9)
	)
	answer_panel.get_child(0).add_theme_color_override("font_color", Color(0.4, 1.0, 0.55, 1.0))
	vbox.add_child(answer_panel)

func _format_number(n: int) -> String:
	var s := str(n)
	var result := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = " " + result
		result = s[i] + result
		count += 1
	return result
