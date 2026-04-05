extends "res://scenes/Tutorial/TutorialBase.gd"
class_name TutorialHTML

func _initialize_tutorial() -> void:
	tutorial_id = "html_basics"
	tutorial_title = "Основы HTML"
	linked_quest_scene = "res://scenes/case_08/fr8_final_report_a.tscn"

	tutorial_steps = [
		{
			"text": """
HTML - язык разметки веб-страниц.

Все в HTML состоит из ТЕГОВ:

<тег>содержимое</тег>

Открывающий тег: <p>
Закрывающий тег: </p> (со слешем /)

Пример:
<p>Привет, мир!</p>
-> абзац текста "Привет, мир!"
""",
			"render_func": "render_tag_anatomy",
		},
		{
			"text": """
Основные теги:

<h1>Заголовок 1</h1>  - самый крупный
<h2>Заголовок 2</h2>  - поменьше
<p>Абзац текста</p>   - параграф
<ul>                   - маркированный список
  <li>Пункт 1</li>
  <li>Пункт 2</li>
</ul>
<ol>                   - нумерованный список
  <li>Первый</li>
  <li>Второй</li>
</ol>
""",
			"render_func": "render_tags_gallery",
		},
		{
			"text": """
Вложенность - главное правило HTML:

ПРАВИЛЬНО (тег закрывается в обратном порядке):
<div><p>текст</p></div>

НЕПРАВИЛЬНО (теги перекрещиваются):
<div><p>текст</div></p>  <- ОШИБКА!

Представь матрешку: маленькая внутри большой.
Каждый открытый тег ОБЯЗАН быть закрыт
ДО того как закроется его родитель.
""",
			"render_func": "render_nesting_visual",
		},
		{
			"text": """
Структура HTML-документа:

<html>
  <head>
    <title>Заголовок страницы</title>
  </head>
  <body>
    <h1>Привет!</h1>
    <p>Это моя страница.</p>
  </body>
</html>

html -> head + body
head -> метаданные (title)
body -> видимое содержимое
""",
			"render_func": "render_html_tree",
		},
		{
			"text": """
Ссылки и изображения:

<a href="url">текст ссылки</a>
<img src="photo.jpg">

Атрибуты - дополнительная информация в теге:
href - адрес ссылки
src - путь к картинке
class - CSS класс
id - уникальный идентификатор

<img> - самозакрывающийся тег (без </img>).
""",
			"render_func": "",
		},
		{
			"text": """
В квесте "Финальный отчет" (Дело #9):

Сложность А: Расставь HTML-фрагменты в правильном
порядке. Следи за вложенностью тегов!

Сложность Б: Определи правильный порядок действий.

Сложность С: Собери документ с шифрованными блоками.

Главная ошибка (UNBALANCED_TAG):
Не забывай закрывать каждый тег!
<ul>...<li>...</li>...</ul> <- правильно
""",
			"render_func": "",
		},
	]


func render_tag_anatomy(area: Control, _step: Dictionary) -> void:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	area.add_child(root)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	root.add_child(row)

	row.add_child(_make_info_panel("<p>", Color(0.08, 0.22, 0.14, 1.0), Color(0.18, 0.70, 0.42, 1.0), 18))
	var content := Label.new()
	content.text = "Привет, мир!"
	content.add_theme_font_size_override("font_size", 16)
	row.add_child(content)
	row.add_child(_make_info_panel("</p>", Color(0.24, 0.12, 0.10, 1.0), Color(0.80, 0.35, 0.28, 1.0), 18))

	root.add_child(_make_info_panel("Открывающий тег + содержимое + закрывающий тег", Color(0.10, 0.13, 0.22, 1.0), Color(0.30, 0.52, 0.90, 1.0), 14))


func render_tags_gallery(area: Control, _step: Dictionary) -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	area.add_child(vbox)

	vbox.add_child(_make_table_row(["Тег", "Назначение"], true))
	vbox.add_child(_make_table_row(["<h1> ... </h1>", "Заголовок"], false))
	vbox.add_child(_make_table_row(["<p> ... </p>", "Абзац"], false))
	vbox.add_child(_make_table_row(["<ul> ... </ul>", "Маркированный список"], false))
	vbox.add_child(_make_table_row(["<ol> ... </ol>", "Нумерованный список"], false))
	vbox.add_child(_make_table_row(["<li> ... </li>", "Элемент списка"], false))


func render_nesting_visual(area: Control, _step: Dictionary) -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	area.add_child(vbox)

	vbox.add_child(_make_info_panel("ПРАВИЛЬНО\n<div><p>текст</p></div>", Color(0.08, 0.24, 0.14, 1.0), Color(0.18, 0.70, 0.42, 1.0), 15))
	vbox.add_child(_make_info_panel("НЕПРАВИЛЬНО\n<div><p>текст</div></p>", Color(0.24, 0.12, 0.10, 1.0), Color(0.80, 0.35, 0.28, 1.0), 15))


func render_html_tree(area: Control, _step: Dictionary) -> void:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	area.add_child(root)

	root.add_child(_make_info_panel("<html>", Color(0.10, 0.13, 0.22, 1.0), Color(0.30, 0.52, 0.90, 1.0), 16))
	var branches := HBoxContainer.new()
	branches.alignment = BoxContainer.ALIGNMENT_CENTER
	branches.add_theme_constant_override("separation", 18)
	root.add_child(branches)

	branches.add_child(_make_info_panel("<head>\n<title>", Color(0.20, 0.12, 0.30, 1.0), Color(0.62, 0.35, 0.84, 1.0), 14))
	branches.add_child(_make_info_panel("<body>\n<h1>, <p>, ...", Color(0.08, 0.22, 0.14, 1.0), Color(0.18, 0.70, 0.42, 1.0), 14))


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
