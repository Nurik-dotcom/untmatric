extends "res://scenes/Tutorial/TutorialBase.gd"
class_name TutorialCodeTrace

func _initialize_tutorial() -> void:
	tutorial_id = "code_trace"
	tutorial_title = "Трассировка кода"
	linked_quest_scene = "res://scenes/SuspectQuestA.tscn"

	tutorial_steps = [
		{
			"text": """
Трассировка - это пошаговое выполнение программы вручную.

Ты читаешь код строка за строкой и отслеживаешь:
- Какие переменные существуют
- Какие значения они получают
- Как меняются при каждой операции

Это самый частый тип задач в ЕНТ по информатике!
""",
			"render_func": "",
		},
		{
			"text": """
Переменные и присваивание:

x = 5         # x получает значение 5
y = x + 3     # y = 5 + 3 = 8
x = x * 2     # x = 5 * 2 = 10 (теперь x = 10!)

ТАБЛИЦА ТРАССИРОВКИ:
Строка | x  | y
1      | 5  | -
2      | 5  | 8
3      | 10 | 8
""",
			"render_func": "render_trace_table",
			"code": ["x = 5", "y = x + 3", "x = x * 2"],
			"trace": [{"x": 5}, {"x": 5, "y": 8}, {"x": 10, "y": 8}],
			"headers": ["x", "y"],
		},
		{
			"text": """
Условия (if / else):

x = 7
if x > 5:
    y = 1
else:
    y = 0

x = 7, проверяем: 7 > 5? -> ДА -> y = 1

Если бы x = 3:
3 > 5? -> НЕТ -> y = 0
""",
			"render_func": "render_if_diagram",
		},
		{
			"text": """
Цикл for:

s = 0
for i in range(1, 4):    # i = 1, 2, 3
    s = s + i

ТРАССИРОВКА:
i=1: s = 0 + 1 = 1
i=2: s = 1 + 2 = 3
i=3: s = 3 + 3 = 6

Ответ: s = 6

range(1, 4) дает числа 1, 2, 3 (НЕ включая 4!)
""",
			"render_func": "render_trace_table",
			"code": ["s = 0", "for i in range(1,4):", "    s = s + i"],
			"trace": [{"s": 0}, {"i": 1, "s": 1}, {"i": 2, "s": 3}, {"i": 3, "s": 6}],
			"headers": ["i", "s"],
		},
		{
			"text": """
Цикл while:

x = 10
count = 0
while x > 1:
    x = x // 2
    count += 1

ТРАССИРОВКА:
x=10: 10//2=5, count=1
x=5:  5//2=2,  count=2
x=2:  2//2=1,  count=3
x=1:  1>1? НЕТ -> стоп

Ответ: count = 3

// - целочисленное деление (отбрасывает дробную часть)
""",
			"render_func": "render_trace_table",
			"code": ["x=10", "count=0", "while x>1:", "  x=x//2", "  count+=1"],
			"trace": [{"x": 10, "count": 0}, {"x": 5, "count": 1}, {"x": 2, "count": 2}, {"x": 1, "count": 3}],
			"headers": ["x", "count"],
		},
		{
			"text": """
Строки и списки:

s = 'hello'
print(len(s))     # 5
print(s[0])       # 'h'
print(s[1:3])     # 'el'

a = [10, 20, 30]
print(a[0])       # 10
print(len(a))     # 3
a.append(40)      # [10, 20, 30, 40]

Индексация с 0! Первый элемент - [0], не [1].
""",
			"render_func": "render_string_index",
		},
		{
			"text": """
В квесте "Взлом шифроблока" (Дело #5):

Сложность А: Читаешь код Python строка за строкой.
Определяешь значения переменных.

Сложность Б: Восстанавливаешь пропущенные строки.

Сложность С: Обезвреживаешь скрипт -
находишь ошибку в коде.

Веди трассировку на бумаге:
строка | переменная1 | переменная2 | ...
""",
			"render_func": "",
		},
	]


func render_trace_table(area: Control, step: Dictionary) -> void:
	var layout := HBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	area.add_child(layout)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(left)

	var code: Array = step.get("code", [])
	var code_text := ""
	for i in range(code.size()):
		code_text += "%d) %s\n" % [i + 1, str(code[i])]
	left.add_child(_make_info_panel(code_text.strip_edges(), Color(0.10, 0.11, 0.18, 1.0), Color(0.32, 0.40, 0.62, 1.0), 14))

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(right)

	var headers: Array = step.get("headers", [])
	var row_headers: Array = ["Шаг"]
	for h in headers:
		row_headers.append(str(h))
	right.add_child(_make_table_row(row_headers, true))

	var trace: Array = step.get("trace", [])
	for i in range(trace.size()):
		var row_data := [str(i + 1)]
		var values: Dictionary = trace[i]
		for h in headers:
			row_data.append(str(values.get(str(h), "-")))
		right.add_child(_make_table_row(row_data, false))


func render_if_diagram(area: Control, _step: Dictionary) -> void:
	var root := VBoxContainer.new()
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 10)
	area.add_child(root)

	root.add_child(_make_info_panel("x = 7", Color(0.10, 0.11, 0.18, 1.0), Color(0.32, 0.40, 0.62, 1.0), 16))
	var arrow := Label.new()
	arrow.text = "|"
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(arrow)
	root.add_child(_make_info_panel("x > 5 ?", Color(0.20, 0.12, 0.30, 1.0), Color(0.62, 0.35, 0.84, 1.0), 16))

	var branches := HBoxContainer.new()
	branches.alignment = BoxContainer.ALIGNMENT_CENTER
	branches.add_theme_constant_override("separation", 26)
	root.add_child(branches)

	branches.add_child(_make_info_panel("ДА\ny = 1", Color(0.08, 0.24, 0.14, 1.0), Color(0.18, 0.70, 0.42, 1.0), 15))
	branches.add_child(_make_info_panel("НЕТ\ny = 0", Color(0.24, 0.12, 0.10, 1.0), Color(0.80, 0.35, 0.28, 1.0), 15))


func render_string_index(area: Control, _step: Dictionary) -> void:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	area.add_child(root)

	var chars := ["h", "e", "l", "l", "o"]
	var indices := ["0", "1", "2", "3", "4"]
	var row_idx: Array = ["Индекс"]
	var row_char: Array = ["Символ"]
	for i in range(chars.size()):
		row_idx.append(indices[i])
		row_char.append("'%s'" % chars[i])

	root.add_child(_make_table_row(row_idx, true))
	root.add_child(_make_table_row(row_char, false))
	root.add_child(_make_info_panel("len('hello') = 5\nПервый символ: s[0]\nСрез: s[1:3] = 'el'", Color(0.10, 0.13, 0.22, 1.0), Color(0.30, 0.52, 0.90, 1.0), 14))


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
