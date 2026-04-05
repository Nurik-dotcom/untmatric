extends "res://scenes/Tutorial/TutorialBase.gd"
# Таблицы истинности для сложных выражений
# Готовит к: LogicQuest B

class_name TutorialLogicTables

func _initialize_tutorial() -> void:
	tutorial_id = "logic_tables"
	tutorial_title = "Таблицы истинности"
	linked_quest_scene = "res://scenes/LogicQuestB.tscn"

	tutorial_steps = [
		{
			"text": "Таблица истинности показывает значение логического выражения для ВСЕХ наборов входов.\n\nЕсли переменных n, то строк будет 2ⁿ:\n• 1 переменная → 2 строки\n• 2 переменные → 4 строки\n• 3 переменные → 8 строк\n\nВ ЕНТ это основной способ проверить формулу без ошибок.",
			"render_func": "render_intro",
		},
		{
			"text": "Быстрый старт: таблицы для базовых операций.\n\nNOT инвертирует бит, AND даёт 1 только при (1,1), OR даёт 0 только при (0,0).\n\nЭто база, на которой строятся сложные выражения.",
			"render_func": "render_basic_gates",
		},
		{
			"text": "Пример выражения: F = (A AND B) OR NOT A.\n\nДелаем промежуточные столбцы:\n1) A AND B\n2) NOT A\n3) OR предыдущих столбцов\n\nТак легче не потерять порядок вычисления.",
			"render_func": "render_two_var_example",
		},
		{
			"text": "Приоритет операций в логике:\n1) NOT\n2) AND\n3) OR\n\nЕсли есть скобки, сначала скобки.\n\nЧастая ошибка ЕНТ: считать OR раньше AND.",
			"render_func": "render_priority_rules",
		},
		{
			"text": "Пример на 3 переменные: F = (A XOR B) AND C.\n\nСначала XOR, затем AND с C.\n\nДля 3 переменных строим 8 строк: от 000 до 111.",
			"render_func": "render_three_var_example",
		},
		{
			"text": "Типичные задачи ЕНТ:\n\nТип 1: заполнить пропущенные ячейки таблицы.\nТип 2: по таблице определить формулу.\nТип 3: найти наборы, где F=1.\n\nРабочая стратегия: делай промежуточные столбцы, не считай всё «в уме».",
			"render_func": "render_ent_tasks",
		},
		{
			"text": "Чек-лист перед ответом:\n• Количество строк = 2ⁿ\n• Все комбинации входов учтены\n• Приоритет NOT/AND/OR соблюдён\n• Промежуточные столбцы проверены\n\nТак ты снимаешь большинство технических ошибок.",
			"render_func": "render_checklist",
		},
	]


func render_intro(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 6)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	container.add_child(_make_row_bg(["Переменных", "Строк", "Комментарий"], true))
	container.add_child(_make_row_bg(["1", "2", "0 / 1"], false))
	container.add_child(_make_row_bg(["2", "4", "00, 01, 10, 11"], false))
	container.add_child(_make_row_bg(["3", "8", "000 ... 111"], false))

	var tip := Label.new()
	tip.text = "Формула: число строк = 2^n"
	tip.add_theme_font_size_override("font_size", 14)
	tip.add_theme_color_override("font_color", Color(0.90,0.82,0.25,1.0))
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(tip)


func render_basic_gates(area: Control, _step: Dictionary) -> void:
	var container := HBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var not_box := VBoxContainer.new()
	not_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	not_box.add_theme_constant_override("separation", 3)
	not_box.add_child(_make_row_bg(["A", "NOT A"], true))
	not_box.add_child(_make_row_bg(["0", "1"], false))
	not_box.add_child(_make_row_bg(["1", "0"], false))
	container.add_child(not_box)

	var and_or_box := VBoxContainer.new()
	and_or_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	and_or_box.add_theme_constant_override("separation", 3)
	and_or_box.add_child(_make_row_bg(["A", "B", "AND", "OR"], true))
	for r in [[0,0,0,0],[0,1,0,1],[1,0,0,1],[1,1,1,1]]:
		and_or_box.add_child(_make_row_bg([str(r[0]),str(r[1]),str(r[2]),str(r[3])], false))
	container.add_child(and_or_box)


func render_two_var_example(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 3)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	container.add_child(_make_row_bg(["A","B","A AND B","NOT A","F"], true))
	var rows := [
		[0,0,0,1,1],
		[0,1,0,1,1],
		[1,0,0,0,0],
		[1,1,1,0,1],
	]
	for r in rows:
		container.add_child(_make_row_bg([str(r[0]),str(r[1]),str(r[2]),str(r[3]),str(r[4])], false))

	var note := Label.new()
	note.text = "F = (A AND B) OR NOT A"
	note.add_theme_font_size_override("font_size", 14)
	note.add_theme_color_override("font_color", Color(0.55,0.75,1.0,1.0))
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(note)


func render_priority_rules(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 6)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	for item in [
		["1", "NOT", "Сначала инверсия", Color(0.80,0.50,1.00,1.0)],
		["2", "AND", "Потом логическое И", Color(0.35,0.70,1.00,1.0)],
		["3", "OR", "В конце логическое ИЛИ", Color(0.20,0.85,0.55,1.0)],
	]:
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", _flat_style(item[3]*Color(1,1,1,0.10), item[3], 1, 6))
		container.add_child(panel)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		panel.add_child(hb)
		for j in range(3):
			var lbl := Label.new()
			lbl.text = item[j]
			lbl.add_theme_font_size_override("font_size", 13 if j == 0 else 14)
			lbl.add_theme_color_override("font_color", item[3] if j < 2 else Color(0.75,0.75,0.85,1.0))
			if j == 0:
				lbl.custom_minimum_size = Vector2(20, 0)
			if j == 1:
				lbl.custom_minimum_size = Vector2(60, 0)
			hb.add_child(lbl)


func render_three_var_example(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 3)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	container.add_child(_make_row_bg(["A","B","C","A XOR B","F"], true))
	var data := [
		[0,0,0,0,0],
		[0,0,1,0,0],
		[0,1,0,1,0],
		[0,1,1,1,1],
		[1,0,0,1,0],
		[1,0,1,1,1],
		[1,1,0,0,0],
		[1,1,1,0,0],
	]
	for r in data:
		container.add_child(_make_row_bg([str(r[0]),str(r[1]),str(r[2]),str(r[3]),str(r[4])], false))

	var note := Label.new()
	note.text = "F = (A XOR B) AND C"
	note.add_theme_font_size_override("font_size", 14)
	note.add_theme_color_override("font_color", Color(0.75,0.40,1.00,1.0))
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(note)


func render_ent_tasks(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 6)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var items := [
		["Тип 1", "Заполни таблицу", "Считай по промежуточным столбцам", Color(0.35,0.70,1.00,1.0)],
		["Тип 2", "Найди все F=1", "Отметь строки, где выход равен 1", Color(0.20,0.85,0.55,1.0)],
		["Тип 3", "Восстанови формулу", "Смотри паттерн 1/0 в финальном столбце", Color(0.80,0.60,0.20,1.0)],
	]
	for it in items:
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", _flat_style(it[3]*Color(1,1,1,0.09), it[3], 1, 7))
		container.add_child(panel)
		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 2)
		panel.add_child(vb)
		for i in range(3):
			var lbl := Label.new()
			lbl.text = it[i]
			lbl.add_theme_font_size_override("font_size", 14 if i == 0 else 12)
			lbl.add_theme_color_override("font_color", it[3] if i == 0 else (Color(0.80,0.80,0.90,1.0) if i == 1 else Color(0.62,0.62,0.75,1.0)))
			lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
			vb.add_child(lbl)


func render_checklist(area: Control, _step: Dictionary) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _flat_style(Color(0.08,0.10,0.20,1.0), Color(0.22,0.45,0.85,0.7), 1, 8))
	area.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 5)
	panel.add_child(vb)

	for line in [
		"1) Проверил 2^n строк",
		"2) Все комбинации входов перечислены",
		"3) NOT/AND/OR посчитаны в правильном порядке",
		"4) Финальный столбец F сверен",
	]:
		var lbl := Label.new()
		lbl.text = line
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.82,0.82,0.92,1.0))
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
