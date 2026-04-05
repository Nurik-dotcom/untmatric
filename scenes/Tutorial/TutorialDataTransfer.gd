extends "res://scenes/Tutorial/TutorialBase.gd"
class_name TutorialDataTransfer

func _initialize_tutorial() -> void:
	tutorial_id = "data_transfer"
	tutorial_title = "Скорость передачи данных"
	linked_quest_scene = "res://scenes/RadioQuestB.tscn"

	tutorial_steps = [
		{
			"text": """
Скорость передачи измеряется в бит/с (bps).

1 байт = 8 бит
1 Кбайт = 1024 байт
1 Мбайт = 1024 Кбайт

1 Кбит/с = 1000 бит/с
1 Мбит/с = 1000 Кбит/с = 1 000 000 бит/с

ВНИМАНИЕ: при переводе байтов - множитель 1024,
при переводе скорости - множитель 1000!
""",
			"render_func": "render_units_table",
		},
		{
			"text": """
Главная формула:

        t = I / v

t - время передачи (секунды)
I - размер файла (биты)
v - скорость канала (бит/с)

ВАЖНО: I и v должны быть в одинаковых единицах!
Если файл в Кбайтах - перевести в биты.
Если скорость в Мбит/с - перевести в бит/с.
""",
			"render_func": "render_formula",
		},
		{
			"text": """
Пример 1:

Файл: 500 Кбайт
Скорость: 100 Кбит/с

Шаг 1: Переводим файл в Кбиты
500 Кбайт x 8 = 4000 Кбит

Шаг 2: Делим на скорость
4000 Кбит / 100 Кбит/с = 40 секунд

Ответ: 40 секунд
""",
			"render_func": "render_example_calc",
			"example": {"file_kb": 500, "speed_kbps": 100, "answer_sec": 40.0},
		},
		{
			"text": """
Пример 2:

Файл: 2 Мбайт
Скорость: 4 Мбит/с

Шаг 1: Переводим файл
2 Мбайт = 2 x 1024 x 1024 x 8 = 16 777 216 бит

Шаг 2: Переводим скорость
4 Мбит/с = 4 x 1 000 000 = 4 000 000 бит/с

Шаг 3: t = 16 777 216 / 4 000 000 ~= 4.19 с

Ответ: ~= 4.2 секунды
""",
			"render_func": "render_example_calc",
			"example": {"file_mb": 2, "speed_mbps": 4, "answer_sec": 4.2},
		},
		{
			"text": """
Частые ловушки ЕНТ:

1. Кбайт и Кбит - НЕ ОДНО И ТО ЖЕ!
   1 Кбайт = 8 Кбит

2. Кило в байтах = 1024, Кило в битах/с = 1000

3. Если ответ получается дробный - проверь единицы

4. "Пропускная способность" = скорость канала (v)
""",
			"render_func": "",
		},
		{
			"text": """
В квесте "Радиоперехват" (Дело #2):

Сложность Б: Собери конвейер формулы.
Тебе даны модули: x1024, x8, /t, bps.
Расставь их в правильном порядке.

Сложность С: Вычисли время передачи.
Установи t на вращалке и нажми РИСКНУТЬ,
если успеваешь до обнаружения.
""",
			"render_func": "",
		},
	]


func render_units_table(area: Control, _step: Dictionary) -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	area.add_child(vbox)

	vbox.add_child(_make_table_row(["Единица", "Байты", "Скорость"], true))
	vbox.add_child(_make_table_row(["Кило (K)", "1024", "1000"], false))
	vbox.add_child(_make_table_row(["Мега (M)", "1024 x 1024", "1 000 000"], false))
	vbox.add_child(_make_table_row(["Гига (G)", "1024^3", "1 000 000 000"], false))


func render_formula(area: Control, _step: Dictionary) -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	area.add_child(vbox)

	var formula := _make_info_panel("t = I / v", Color(0.10, 0.12, 0.28, 1.0), Color(0.30, 0.52, 0.90, 1.0), 30)
	vbox.add_child(formula)

	vbox.add_child(_make_info_panel("t = время\nI = объем данных (в битах)\nv = скорость канала (бит/с)", Color(0.07, 0.09, 0.14, 1.0), Color(0.22, 0.28, 0.45, 1.0), 14))


func render_example_calc(area: Control, step: Dictionary) -> void:
	var example: Dictionary = step.get("example", {})
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	area.add_child(vbox)

	if example.has("file_kb"):
		var file_kb: int = int(example.get("file_kb", 0))
		var speed_kbps: int = int(example.get("speed_kbps", 1))
		var file_kbit: int = file_kb * 8
		var sec := float(file_kbit) / float(max(1, speed_kbps))
		vbox.add_child(_make_table_row(["Файл", "%d Кбайт" % file_kb, "%d Кбит" % file_kbit], true))
		vbox.add_child(_make_info_panel("%d x 8 = %d Кбит" % [file_kb, file_kbit], Color(0.08, 0.18, 0.11, 1.0), Color(0.24, 0.64, 0.36, 1.0), 14))
		vbox.add_child(_make_info_panel("t = %d / %d = %.2f c" % [file_kbit, speed_kbps, sec], Color(0.08, 0.18, 0.11, 1.0), Color(0.24, 0.64, 0.36, 1.0), 14))
		vbox.add_child(_make_info_panel("Ответ: %.2f c" % sec, Color(0.26, 0.12, 0.10, 1.0), Color(0.82, 0.34, 0.28, 1.0), 20))
	elif example.has("file_mb"):
		var file_mb: int = int(example.get("file_mb", 0))
		var speed_mbps: int = int(example.get("speed_mbps", 1))
		var bits: int = file_mb * 1024 * 1024 * 8
		var bps: int = speed_mbps * 1000000
		var sec_f := float(bits) / float(max(1, bps))
		vbox.add_child(_make_table_row(["Файл", "%d Мбайт" % file_mb, "%d бит" % bits], true))
		vbox.add_child(_make_info_panel("%d x 1024 x 1024 x 8 = %d бит" % [file_mb, bits], Color(0.08, 0.18, 0.11, 1.0), Color(0.24, 0.64, 0.36, 1.0), 14))
		vbox.add_child(_make_info_panel("%d Мбит/с = %d бит/с" % [speed_mbps, bps], Color(0.08, 0.18, 0.11, 1.0), Color(0.24, 0.64, 0.36, 1.0), 14))
		vbox.add_child(_make_info_panel("t = %d / %d ~= %.2f c" % [bits, bps, sec_f], Color(0.08, 0.18, 0.11, 1.0), Color(0.24, 0.64, 0.36, 1.0), 14))
		vbox.add_child(_make_info_panel("Ответ: ~= %.2f c" % sec_f, Color(0.26, 0.12, 0.10, 1.0), Color(0.82, 0.34, 0.28, 1.0), 20))


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
