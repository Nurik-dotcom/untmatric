extends "res://scenes/Tutorial/TutorialBase.gd"
class_name TutorialDBFundamentals

func _initialize_tutorial() -> void:
	tutorial_id = "db_fundamentals"
	tutorial_title = "Основы баз данных"
	linked_quest_scene = "res://scenes/case_07/da7_data_archive_a.tscn"

	tutorial_steps = [
		{
			"text": """
Реляционная БД хранит данные в ТАБЛИЦАХ.

Таблица AGENTS:
ID | Name   | Dept | Rank
1  | Novak  | Ops  | A
2  | Reeves | Sec  | B
3  | Chen   | Ops  | A

- СТРОКА (запись) - один объект (один агент)
- СТОЛБЕЦ (поле) - атрибут (имя, отдел)
- ЯЧЕЙКА - одно конкретное значение
""",
			"render_func": "render_table_anatomy",
		},
		{
			"text": """
ПЕРВИЧНЫЙ КЛЮЧ (Primary Key, PK):

Столбец, который уникально идентифицирует строку.

ID | Name
1  | Novak
2  | Reeves

PK = ID (уникален для каждой строки)
Name - НЕ ключ (два агента могут иметь одно имя)

Правила PK:
- Уникальный (не повторяется)
- Не пустой (NOT NULL)
- Обычно - числовой ID
""",
			"render_func": "render_pk_highlight",
		},
		{
			"text": """
1NF (Первая нормальная форма) - АТОМАРНОСТЬ:

НАРУШЕНИЕ 1NF:
ID | Phone
1  | +7-700-111, +7-701-222   <- ДВА значения в ячейке!

ПРАВИЛЬНО (1NF):
ID | Phone
1  | +7-700-111
1  | +7-701-222

Правило: каждая ячейка = ОДНО значение.
Если видишь запятую в ячейке - это нарушение 1NF.
""",
			"render_func": "render_1nf_comparison",
		},
		{
			"text": """
Фильтрация - выбор строк по условию:

Таблица:
ID | Name   | Score
1  | Novak  | 85
2  | Reeves | 60
3  | Chen   | 92

Условие: Score > 80
Результат: строки 1 (85) и 3 (92)

ВНИМАНИЕ: > 80 НЕ включает 80!
>= 80 включает 80.
Это самая частая ошибка!
""",
			"render_func": "render_filter_demo",
		},
		{
			"text": """
Связи между таблицами:

1:1 - Один к одному
  Человек <-> Паспорт (один паспорт = один человек)

1:M - Один ко многим
  Учитель -> Ученики (один учитель, много учеников)

M:M - Многие ко многим
  Студенты <-> Курсы (студент на нескольких курсах,
  курс у нескольких студентов)

На ЕНТ просят определить тип связи по описанию.
""",
			"render_func": "render_relationships",
		},
		{
			"text": """
Типы данных:

INTEGER (INT) - целые числа: 1, 42, -5
REAL / FLOAT - дробные: 3.14, -0.5
TEXT / VARCHAR - строки: 'Astana', 'hello'
BOOLEAN - логический: TRUE/FALSE
DATE - дата: 2025-01-15

Ловушка: '42' в кавычках - это TEXT, не INT!
Телефон +7-700-111 - это TEXT (содержит дефисы).
""",
			"render_func": "render_types_table",
		},
		{
			"text": """
В квесте "Теневой архив" (Дело #8):

Сложность А: Нажми на нужный элемент таблицы.
  - Найди первичный ключ (PK)
  - Найди нарушение 1NF (неатомарную ячейку)
  - Определи тип данных

Сложность Б: Фильтрация и связи.
  - Зачеркни строки, НЕ подходящие под условие
  - Определи тип связи между таблицами

Помни: > и >= - РАЗНЫЕ операторы!
""",
			"render_func": "",
		},
	]


func render_table_anatomy(area: Control, _step: Dictionary) -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	area.add_child(vbox)

	vbox.add_child(_make_table_row(["ID", "Name", "Dept", "Rank"], true))
	vbox.add_child(_make_table_row(["1", "Novak", "Ops", "A"], false))
	vbox.add_child(_make_table_row(["2", "Reeves", "Sec", "B"], false))
	vbox.add_child(_make_table_row(["3", "Chen", "Ops", "A"], false))
	vbox.add_child(_make_info_panel("Строка = запись | Столбец = поле | Ячейка = одно значение", Color(0.08, 0.12, 0.20, 1.0), Color(0.28, 0.42, 0.68, 1.0), 14))


func render_pk_highlight(area: Control, _step: Dictionary) -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	area.add_child(vbox)

	var header := _make_table_row(["ID (PK)", "Name"], true)
	vbox.add_child(header)
	vbox.add_child(_make_table_row(["1", "Novak"], false))
	vbox.add_child(_make_table_row(["2", "Reeves"], false))
	vbox.add_child(_make_info_panel("PK должен быть уникальным и не пустым.", Color(0.18, 0.14, 0.08, 1.0), Color(0.78, 0.62, 0.26, 1.0), 14))


func render_1nf_comparison(area: Control, _step: Dictionary) -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	area.add_child(vbox)

	vbox.add_child(_make_info_panel("НАРУШЕНИЕ 1NF", Color(0.24, 0.10, 0.10, 1.0), Color(0.85, 0.26, 0.26, 1.0), 14))
	vbox.add_child(_make_table_row(["ID", "Phone"], true))
	vbox.add_child(_make_table_row(["1", "+7-700-111, +7-701-222"], false))

	vbox.add_child(_make_info_panel("ПРАВИЛЬНО (1NF)", Color(0.08, 0.20, 0.12, 1.0), Color(0.22, 0.72, 0.40, 1.0), 14))
	vbox.add_child(_make_table_row(["ID", "Phone"], true))
	vbox.add_child(_make_table_row(["1", "+7-700-111"], false))
	vbox.add_child(_make_table_row(["1", "+7-701-222"], false))


func render_filter_demo(area: Control, _step: Dictionary) -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	area.add_child(vbox)

	vbox.add_child(_make_info_panel("Условие: Score > 80", Color(0.10, 0.11, 0.24, 1.0), Color(0.34, 0.46, 0.90, 1.0), 14))
	vbox.add_child(_make_table_row(["ID", "Name", "Score"], true))
	vbox.add_child(_make_table_row(["1", "Novak", "85"], false))
	vbox.add_child(_make_table_row(["2", "Reeves", "60 (не подходит)"], false))
	vbox.add_child(_make_table_row(["3", "Chen", "92"], false))


func render_relationships(area: Control, _step: Dictionary) -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	area.add_child(vbox)

	vbox.add_child(_make_info_panel("1:1  Человек <-> Паспорт", Color(0.08, 0.12, 0.20, 1.0), Color(0.28, 0.42, 0.68, 1.0), 15))
	vbox.add_child(_make_info_panel("1:M  Учитель -> Ученики", Color(0.08, 0.16, 0.12, 1.0), Color(0.22, 0.62, 0.36, 1.0), 15))
	vbox.add_child(_make_info_panel("M:M  Студенты <-> Курсы", Color(0.20, 0.14, 0.08, 1.0), Color(0.76, 0.54, 0.26, 1.0), 15))


func render_types_table(area: Control, _step: Dictionary) -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	area.add_child(vbox)

	vbox.add_child(_make_table_row(["Тип", "Пример", "Комментарий"], true))
	vbox.add_child(_make_table_row(["INT", "42", "Целое число"], false))
	vbox.add_child(_make_table_row(["REAL", "3.14", "Дробное"], false))
	vbox.add_child(_make_table_row(["TEXT", "'Astana'", "Строка"], false))
	vbox.add_child(_make_table_row(["BOOLEAN", "TRUE", "Логический"], false))
	vbox.add_child(_make_table_row(["DATE", "2025-01-15", "Дата"], false))
	vbox.add_child(_make_info_panel("Ловушка: '42' в кавычках = TEXT.", Color(0.24, 0.10, 0.10, 1.0), Color(0.85, 0.26, 0.26, 1.0), 14))


func _make_table_row(values: Array, header: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	for value in values:
		var cell := PanelContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.10, 0.12, 0.20, 1.0) if header else Color(0.07, 0.08, 0.12, 1.0)
		style.border_color = Color(0.26, 0.34, 0.52, 0.8) if header else Color(0.16, 0.18, 0.28, 0.8)
		style.set_border_width_all(1)
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		style.content_margin_left = 8
		style.content_margin_right = 8
		style.content_margin_top = 6
		style.content_margin_bottom = 6
		cell.add_theme_stylebox_override("panel", style)
		row.add_child(cell)

		var label := Label.new()
		label.text = str(value)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 13 if header else 14)
		label.add_theme_color_override("font_color", Color(0.52, 0.72, 1.0, 1.0) if header else Color(0.84, 0.84, 0.92, 1.0))
		cell.add_child(label)
	return row


func _make_info_panel(text: String, bg: Color, border: Color, font_size: int) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.98, 1.0))
	panel.add_child(label)
	return panel
