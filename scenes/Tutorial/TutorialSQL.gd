extends "res://scenes/Tutorial/TutorialBase.gd"
# Базы данных и SQL
# Готовит к: DataArchive B/C

class_name TutorialSQL

func _initialize_tutorial() -> void:
	tutorial_id = "sql_basics"
	tutorial_title = "Базы данных: SQL"
	linked_quest_scene = "res://scenes/case_07/da7_data_archive_b.tscn"

	tutorial_steps = [
		{
			"text": "База данных — организованное хранилище структурированных данных.\n\nSQL (Structured Query Language) — язык запросов к реляционным БД.\n\nРеляционная БД состоит из таблиц:\n• Строки — записи (один объект)\n• Столбцы — поля (атрибуты объекта)\n\nПример: таблица AGENTS\nID | Name    | Level | Score\n1  | Novak   | A     | 850\n2  | Reeves  | B     | 720\n3  | Chen    | A     | 910",
			"render_func": "render_db_intro",
		},
		{
			"text": "SELECT — выборка данных:\n\nSELECT * FROM AGENTS\n→ все столбцы, все строки\n\nSELECT Name, Score FROM AGENTS\n→ только Name и Score\n\nSELECT * FROM AGENTS WHERE Level = 'A'\n→ только агенты уровня A\n\nSELECT * FROM AGENTS ORDER BY Score DESC\n→ все агенты, от большего счёта к меньшему\n\nSELECT * FROM AGENTS WHERE Score > 800 ORDER BY Name\n→ с фильтром и сортировкой",
			"render_func": "render_select_examples",
		},
		{
			"text": "WHERE — фильтрация:\n\nОператоры сравнения:\n= равно\n<> или != не равно\n> больше, < меньше\n>= больше или равно, <= меньше или равно\n\nЛогические операторы:\nAND — оба условия верны\nOR  — хотя бы одно условие\nNOT — отрицание\nBETWEEN — диапазон\nLIKE — шаблон (% = любые символы)\nIN — значение из списка",
			"render_func": "render_where_operators",
		},
		{
			"text": "Агрегатные функции:\n\nCOUNT(*) — количество строк\nSUM(поле) — сумма значений\nAVG(поле) — среднее значение\nMAX(поле) — максимум\nMIN(поле) — минимум\n\nПримеры:\nSELECT COUNT(*) FROM AGENTS\nSELECT AVG(Score) FROM AGENTS WHERE Level='A'\nSELECT MAX(Score) FROM AGENTS",
			"render_func": "render_aggregate_demo",
		},
		{
			"text": "GROUP BY — группировка:\n\nSELECT Level, COUNT(*) as Count, AVG(Score) as AvgScore\nFROM AGENTS\nGROUP BY Level\n\nРезультат:\nLevel | Count | AvgScore\nA     | 2     | 880\nB     | 1     | 720\n\nHAVING — фильтр после группировки:\nGROUP BY Level HAVING COUNT(*) > 1\n→ только группы с более чем 1 записью",
			"render_func": "render_group_by_demo",
		},
		{
			"text": "JOIN — объединение таблиц:\n\nINNER JOIN — только совпадающие записи из обеих таблиц\nLEFT JOIN — все из левой, совпадения из правой\nRIGHT JOIN — все из правой, совпадения из левой\n\nПример:\nSELECT AGENTS.Name, MISSIONS.Title\nFROM AGENTS\nINNER JOIN MISSIONS ON AGENTS.ID = MISSIONS.AgentID\n\n→ Имена агентов вместе с их миссиями",
			"render_func": "render_join_demo",
		},
		{
			"text": "Порядок выполнения SQL-запроса:\n\nFROM       → откуда берём данные\nJOIN       → объединяем таблицы\nWHERE      → фильтруем строки\nGROUP BY   → группируем\nHAVING     → фильтруем группы\nSELECT     → выбираем столбцы\nORDER BY   → сортируем\nLIMIT      → ограничиваем количество\n\nВажно: порядок написания ≠ порядок выполнения!",
			"render_func": "render_execution_order",
		},
		{
			"text": "В квесте «Архив данных» (уровень B/C):\n\n• Тебе дают таблицу с данными\n• Нужно составить SQL-запрос для поиска\n• Или выполнить запрос вручную (мысленно)\n• Найти запись по условию\n\nЧаще всего в ЕНТ:\n→ SELECT + WHERE + ORDER BY\n→ COUNT и MAX/MIN\n→ Понимание JOIN",
			"render_func": "render_sql_preview",
		},
	]


func render_db_intro(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 6)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var header := Label.new()
	header.text = "Таблица AGENTS:"
	header.add_theme_font_size_override("font_size", 13)
	header.add_theme_color_override("font_color", Color(0.55,0.55,0.70,1.0))
	container.add_child(header)

	container.add_child(_make_row_bg(["ID","Name","Level","Score"], true))
	var rows := [["1","Novak","A","850"],["2","Reeves","B","720"],["3","Chen","A","910"]]
	for r in rows:
		container.add_child(_make_row_bg(r, false))


func render_select_examples(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 5)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var queries := [
		["SELECT * FROM AGENTS",                          "Все данные",              Color(0.35,0.70,1.00,1.0)],
		["SELECT Name, Score FROM AGENTS",                 "Два столбца",             Color(0.35,0.70,1.00,1.0)],
		["... WHERE Level = 'A'",                          "Фильтр по уровню",        Color(0.80,0.60,0.20,1.0)],
		["... ORDER BY Score DESC",                        "Сортировка убыванием",    Color(0.20,0.85,0.55,1.0)],
		["... WHERE Score > 800 ORDER BY Name",            "Фильтр + сортировка",     Color(0.80,0.50,1.00,1.0)],
	]
	for q in queries:
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", _flat_style(q[2]*Color(1,1,1,0.09), q[2], 1, 6))
		container.add_child(panel)
		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 3)
		panel.add_child(vb)
		var ql := Label.new()
		ql.text = q[0]
		ql.add_theme_font_size_override("font_size", 13)
		ql.add_theme_color_override("font_color", q[2])
		ql.autowrap_mode = TextServer.AUTOWRAP_WORD
		vb.add_child(ql)
		var dl := Label.new()
		dl.text = q[1]
		dl.add_theme_font_size_override("font_size", 11)
		dl.add_theme_color_override("font_color", Color(0.55,0.55,0.70,1.0))
		vb.add_child(dl)


func render_where_operators(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 3)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var ops := [
		["=",          "Равно",           "WHERE Score = 900"],
		["<> / !=",    "Не равно",        "WHERE Level != 'C'"],
		["> / <",      "Больше/меньше",   "WHERE Score > 800"],
		["BETWEEN",    "Диапазон",        "WHERE Score BETWEEN 700 AND 900"],
		["LIKE '%a%'", "Содержит 'a'",    "WHERE Name LIKE '%ov%'"],
		["IN (...)",   "Из списка",       "WHERE Level IN ('A','B')"],
		["AND / OR",   "Логика",          "WHERE Level='A' AND Score>800"],
	]
	container.add_child(_make_row_bg(["Оператор","Смысл","Пример"], true))
	for op in ops:
		container.add_child(_make_row_bg(op, false))


func render_aggregate_demo(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 5)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var agg := [
		["COUNT(*)", "3",   "Количество агентов",     Color(0.35,0.70,1.00,1.0)],
		["SUM(Score)","2480","Сумма очков",            Color(0.20,0.85,0.55,1.0)],
		["AVG(Score)","827", "Среднее",                Color(0.80,0.60,0.20,1.0)],
		["MAX(Score)","910", "Максимум",               Color(0.80,0.50,1.00,1.0)],
		["MIN(Score)","720", "Минимум",                Color(0.90,0.30,0.30,1.0)],
	]
	container.add_child(_make_row_bg(["Функция","Результат","Смысл"], true))
	for a in agg:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		container.add_child(row)
		for j in range(3):
			row.add_child(_make_cell(str(a[j]), 13,
				a[3] if j < 2 else Color(0.70,0.70,0.82,1.0),
				a[3]*Color(1,1,1,0.08), a[3]*Color(1,1,1,0.30)))


func render_group_by_demo(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var qp := PanelContainer.new()
	qp.add_theme_stylebox_override("panel", _flat_style(Color(0.08,0.10,0.20,1.0), Color(0.25,0.45,0.85,0.7), 1, 8))
	container.add_child(qp)
	var ql := Label.new()
	ql.text = "SELECT Level, COUNT(*), AVG(Score)\nFROM AGENTS GROUP BY Level"
	ql.add_theme_font_size_override("font_size", 14)
	ql.add_theme_color_override("font_color", Color(0.55,0.75,1.00,1.0))
	ql.autowrap_mode = TextServer.AUTOWRAP_WORD
	qp.add_child(ql)

	container.add_child(_make_row_bg(["Level","Count","AvgScore"], true))
	container.add_child(_make_row_bg(["A","2","880"], false))
	container.add_child(_make_row_bg(["B","1","720"], false))


func render_join_demo(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	container.add_child(row)

	for tbl_data in [
		{"name":"AGENTS", "cols":["ID","Name"], "rows":[["1","Novak"],["2","Reeves"],["3","Chen"]], "col":Color(0.35,0.70,1.00,1.0)},
		{"name":"MISSIONS","cols":["AgentID","Title"],"rows":[["1","Op.Shadow"],["1","Op.Storm"],["3","Op.Ice"]],"col":Color(0.20,0.85,0.55,1.0)},
	]:
		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 3)
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(vb)
		var t := Label.new()
		t.text = tbl_data["name"]
		t.add_theme_font_size_override("font_size", 13)
		t.add_theme_color_override("font_color", tbl_data["col"])
		vb.add_child(t)
		vb.add_child(_make_row_bg(tbl_data["cols"], true))
		for r in tbl_data["rows"]:
			vb.add_child(_make_row_bg(r, false))

	var result_lbl := Label.new()
	result_lbl.text = "INNER JOIN → Novak:Op.Shadow, Novak:Op.Storm, Chen:Op.Ice\n(Reeves не в результате — нет миссий)"
	result_lbl.add_theme_font_size_override("font_size", 13)
	result_lbl.add_theme_color_override("font_color", Color(0.90,0.82,0.25,1.0))
	result_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	container.add_child(result_lbl)


func render_execution_order(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var order := [
		["1","FROM",     "Определяем таблицу",    Color(0.35,0.70,1.00,1.0)],
		["2","JOIN",     "Объединяем таблицы",     Color(0.35,0.70,1.00,1.0)],
		["3","WHERE",    "Фильтруем строки",       Color(0.80,0.60,0.20,1.0)],
		["4","GROUP BY", "Группируем",             Color(0.80,0.50,1.00,1.0)],
		["5","HAVING",   "Фильтруем группы",       Color(0.80,0.50,1.00,1.0)],
		["6","SELECT",   "Выбираем столбцы",       Color(0.20,0.85,0.55,1.0)],
		["7","ORDER BY", "Сортируем",              Color(0.55,0.55,0.70,1.0)],
		["8","LIMIT",    "Ограничиваем кол-во",    Color(0.55,0.55,0.70,1.0)],
	]
	for item in order:
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", _flat_style(item[3]*Color(1,1,1,0.08), item[3]*Color(1,1,1,0.35), 1, 5))
		container.add_child(panel)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		panel.add_child(hb)
		for j in range(3):
			var lbl := Label.new()
			lbl.text = str(item[j])
			lbl.add_theme_font_size_override("font_size", 13 if j > 0 else 11)
			lbl.add_theme_color_override("font_color", item[3] if j < 2 else Color(0.65,0.65,0.78,1.0))
			if j == 0: lbl.custom_minimum_size = Vector2(20, 0)
			if j == 1: lbl.custom_minimum_size = Vector2(80, 0)
			if j == 2:
				lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
			hb.add_child(lbl)


func render_sql_preview(area: Control, _step: Dictionary) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _flat_style(Color(0.07,0.10,0.06,1.0), Color(0.25,0.60,0.20,0.6), 1, 10))
	area.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 7)
	panel.add_child(vb)
	var t := Label.new()
	t.text = "💾 АРХИВ ДАННЫХ — Уровень B/C"
	t.add_theme_font_size_override("font_size", 16)
	t.add_theme_color_override("font_color", Color(0.25,0.80,0.35,1.0))
	vb.add_child(t)
	for hint in ["📊 Тебе дают таблицу с данными","🔍 Нужно составить запрос SELECT","⚙️ Часто: WHERE + ORDER BY","📈 COUNT и MAX/MIN в вопросах"]:
		var lbl := Label.new()
		lbl.text = hint
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.75,0.75,0.85,1.0))
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

func _calculate_stars() -> int:
	return 3 if current_step_index >= tutorial_steps.size() - 1 else 2
