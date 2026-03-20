extends "res://scenes/Tutorial/TutorialBase.gd"
# TutorialASCII.gd — ASCII и Unicode
# Готовит к: Дешифратор A/B, Радиоперехват A

class_name TutorialASCII

func _initialize_tutorial() -> void:
	tutorial_id = "encode_ascii"
	tutorial_title = "ASCII и Unicode"
	linked_quest_scene = "res://scenes/Decryptor.tscn"

	tutorial_steps = [
		{
			"text": "ASCII (American Standard Code for Information Interchange) — стандарт кодирования символов.\n\nКаждому символу — буква, цифра, знак — присваивается число от 0 до 127.\n\nПочему 128? Потому что 7 бит = 2⁷ = 128 значений.\n\nASCII придуман в 1963 году и до сих пор лежит в основе всех текстовых стандартов.",
			"render_func": "render_ascii_intro",
		},
		{
			"text": "Три главных диапазона ASCII:\n\n32–47:   Знаки препинания и спецсимволы ( !\"#$%&'()*+,-./)\n48–57:   Цифры 0–9\n65–90:   Заглавные буквы A–Z\n97–122:  Строчные буквы a–z\n\nКлюч ЕНТ: 'A' = 65, 'a' = 97, '0' = 48\nРазница между заглавной и строчной = 32.",
			"render_func": "render_ascii_ranges",
		},
		{
			"text": "Таблица важных символов.\n\nЗапомни: A=65, a=97, 0=48 — от них отсчитывается всё остальное.\n\nB=66, C=67 … Z=90\nb=98, c=99 … z=122\n1=49, 2=50 … 9=57",
			"render_func": "render_key_chars_table",
		},
		{
			"text": "ASCII и двоичный код — прямая связь:\n\n'A' = 65₁₀ = 01000001₂ = 41₁₆\n'B' = 66₁₀ = 01000010₂ = 42₁₆\n'Z' = 90₁₀ = 01011010₂ = 5A₁₆\n\nВ квесте Дешифратор:\n1. Получаешь двоичный или HEX код\n2. Переводишь в десятичное число\n3. Ищешь число в таблице ASCII\n4. Получаешь символ → часть сообщения",
			"render_func": "render_ascii_decode_example",
		},
		{
			"text": "Unicode — расширение ASCII на все языки мира.\n\nASCII:   7 бит, 128 символов (английский)\nExtended ASCII: 8 бит, 256 символов\nUnicode: до 21 бит, более 140 000 символов\n\nUTF-8 — самая популярная кодировка Unicode.\nСимволы ASCII (0–127) в UTF-8 занимают 1 байт.\nКириллица — 2 байта.\nЭмодзи — 4 байта.\n\nЕНТ проверяет UTF-8 через вопросы про размер файла.",
			"render_func": "render_unicode_sizes",
		},
		{
			"text": "Задача ЕНТ на размер файла:\n\n«Текстовый файл содержит 100 символов кириллицы в UTF-8. Какой его размер?»\n\nРешение:\n• Каждый символ кириллицы = 2 байта в UTF-8\n• 100 × 2 = 200 байт\n\nЛовушки ЕНТ:\n• ASCII-текст: 1 байт на символ\n• Кириллица в UTF-8: 2 байта\n• Кириллица в Windows-1251: 1 байт\n• Emoji: 4 байта",
			"render_func": "render_file_size_table",
		},
		{
			"text": "Управляющие символы ASCII (0–31):\n\nЭто невидимые символы для управления терминалом.\n\n0  = NUL (пустой)\n7  = BEL (звонок)\n9  = TAB (табуляция)\n10 = LF  (перевод строки)\n13 = CR  (возврат каретки)\n27 = ESC (escape)\n32 = SP  (пробел — первый видимый!)\n\nВ ЕНТ иногда спрашивают коды 9, 10, 13, 32.",
			"render_func": "render_control_chars",
		},
	]


# ══════════════════════════════════════════════════════════════
# RENDER FUNCTIONS
# ══════════════════════════════════════════════════════════════

func render_ascii_intro(area: Control, _step: Dictionary) -> void:
	# Показать несколько символов с их кодами крупно
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	area.add_child(row)

	var examples := [
		["A", 65, Color(0.35, 0.70, 1.00, 1.0)],
		["a", 97, Color(0.50, 0.85, 1.00, 1.0)],
		["0", 48, Color(0.20, 0.85, 0.55, 1.0)],
		["!", 33, Color(0.90, 0.65, 0.20, 1.0)],
		[" ", 32, Color(0.55, 0.55, 0.70, 1.0)],
	]
	for ex in examples:
		var cell := PanelContainer.new()
		cell.custom_minimum_size = Vector2(64, 0)
		var cs := StyleBoxFlat.new()
		cs.bg_color = ex[2] * Color(1, 1, 1, 0.12)
		cs.border_color = ex[2]
		cs.set_border_width_all(1)
		cs.corner_radius_top_left    = 8; cs.corner_radius_top_right   = 8
		cs.corner_radius_bottom_left = 8; cs.corner_radius_bottom_right = 8
		cs.content_margin_left = 8;  cs.content_margin_right = 8
		cs.content_margin_top  = 8;  cs.content_margin_bottom = 8
		cell.add_theme_stylebox_override("panel", cs)
		row.add_child(cell)

		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 3)
		cell.add_child(vb)

		var char_lbl := Label.new()
		char_lbl.text = "'%s'" % ex[0] if ex[1] != 32 else "SP"
		char_lbl.add_theme_font_size_override("font_size", 28)
		char_lbl.add_theme_color_override("font_color", ex[2])
		char_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(char_lbl)

		var code_lbl := Label.new()
		code_lbl.text = str(ex[1])
		code_lbl.add_theme_font_size_override("font_size", 14)
		code_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.78, 1.0))
		code_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(code_lbl)


func render_ascii_ranges(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 6)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var ranges := [
		["32–47",  "Знаки",          "! \" # $ % & '",     Color(0.85, 0.65, 0.25, 1.0)],
		["48–57",  "Цифры 0–9",      "0 1 2 3 4 5",        Color(0.20, 0.85, 0.55, 1.0)],
		["65–90",  "Заглавные A–Z",  "A B C … X Y Z",      Color(0.35, 0.70, 1.00, 1.0)],
		["97–122", "Строчные a–z",   "a b c … x y z",      Color(0.60, 0.85, 1.00, 1.0)],
	]
	for r in ranges:
		var panel := PanelContainer.new()
		var ps := StyleBoxFlat.new()
		ps.bg_color = r[3] * Color(1, 1, 1, 0.10)
		ps.border_color = r[3]
		ps.set_border_width_all(1)
		ps.corner_radius_top_left    = 8; ps.corner_radius_top_right   = 8
		ps.corner_radius_bottom_left = 8; ps.corner_radius_bottom_right = 8
		ps.content_margin_left = 12; ps.content_margin_right = 12
		ps.content_margin_top  = 8;  ps.content_margin_bottom = 8
		panel.add_theme_stylebox_override("panel", ps)
		container.add_child(panel)

		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 12)
		panel.add_child(hb)

		var range_lbl := Label.new()
		range_lbl.text = r[0]
		range_lbl.add_theme_font_size_override("font_size", 16)
		range_lbl.add_theme_color_override("font_color", r[3])
		range_lbl.custom_minimum_size = Vector2(70, 0)
		hb.add_child(range_lbl)

		var name_lbl := Label.new()
		name_lbl.text = r[1]
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.add_theme_color_override("font_color", Color(0.80, 0.80, 0.90, 1.0))
		name_lbl.custom_minimum_size = Vector2(120, 0)
		hb.add_child(name_lbl)

		var ex_lbl := Label.new()
		ex_lbl.text = r[2]
		ex_lbl.add_theme_font_size_override("font_size", 12)
		ex_lbl.add_theme_color_override("font_color", r[3] * Color(1, 1, 1, 0.75))
		hb.add_child(ex_lbl)


func render_key_chars_table(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 3)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var chars := []
	# A-Z
	for i in range(26):
		chars.append([char(65 + i), str(65 + i), "4%d₁₆" % (1 + i) if (1 + i) < 10 else "%X₁₆" % (65 + i)])
	
	container.add_child(_make_table_row_bg(["Символ", "DEC", "HEX"], true))
	# Показать ключевые: A, B, M, Z, a, z, 0, 9
	var key_indices := [0, 1, 12, 25]  # A B M Z
	for idx in key_indices:
		var c = chars[idx]
		container.add_child(_make_table_row_bg(c, false))
	
	# Разделитель
	var sep_lbl := Label.new()
	sep_lbl.text = "a = 97  ·  z = 122  ·  0 = 48  ·  9 = 57"
	sep_lbl.add_theme_font_size_override("font_size", 13)
	sep_lbl.add_theme_color_override("font_color", Color(0.55, 0.75, 1.00, 1.0))
	sep_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(sep_lbl)

	var note_lbl := Label.new()
	note_lbl.text = "Разница A(65) → a(97) = 32  ·  Разница 0(48) → A(65) = 17"
	note_lbl.add_theme_font_size_override("font_size", 12)
	note_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.78, 1.0))
	note_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	container.add_child(note_lbl)


func render_ascii_decode_example(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	# Демо: 01000001 → A
	var steps_data := [
		["01000001₂", "→ DEC", "65"],
		["65₁₀",      "→ ASCII", "'A'"],
	]
	for s in steps_data:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		container.add_child(row)

		var from := _make_badge(s[0], Color(0.35, 0.70, 1.00, 1.0))
		row.add_child(from)
		var arrow := Label.new()
		arrow.text = s[1]
		arrow.add_theme_color_override("font_color", Color(0.45, 0.45, 0.60, 1.0))
		arrow.add_theme_font_size_override("font_size", 14)
		row.add_child(arrow)
		var to_badge := _make_badge(s[2], Color(0.80, 0.50, 1.00, 1.0))
		row.add_child(to_badge)

	area.add_child(_make_info_panel(
		"01000001₂ = 65₁₀ = 'A'",
		Color(0.08, 0.18, 0.12, 1.0), Color(0.20, 0.65, 0.42, 0.7)))


func render_unicode_sizes(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 6)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var data := [
		["ASCII (латиница)", "1 байт", "A, B, 0-9, !"],
		["Кириллица (UTF-8)", "2 байта", "А, Б, В, Я"],
		["Греческий, арабский", "2 байта", "α, β, γ"],
		["CJK (иероглифы)", "3 байта", "中, 日, 한"],
		["Emoji", "4 байта", "😀, 🔥, ⭐"],
	]
	container.add_child(_make_table_row_bg(["Тип символа", "Размер UTF-8", "Примеры"], true))
	for row_data in data:
		container.add_child(_make_table_row_bg(row_data, false))


func render_file_size_table(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 6)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var cases := [
		["100 ASCII-символов", "× 1 байт", "= 100 байт"],
		["100 кириллических (UTF-8)", "× 2 байта", "= 200 байт"],
		["100 кириллических (Win-1251)", "× 1 байт", "= 100 байт"],
		["50 emoji (UTF-8)", "× 4 байта", "= 200 байт"],
	]
	container.add_child(_make_table_row_bg(["Содержимое", "Множитель", "Итог"], true))
	for row_data in cases:
		container.add_child(_make_table_row_bg(row_data, false))


func render_control_chars(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var data := [
		["0",  "NUL", "Пустой символ"],
		["7",  "BEL", "Звуковой сигнал"],
		["9",  "TAB", "Горизонтальная табуляция"],
		["10", "LF",  "Line Feed (\\n) — новая строка"],
		["13", "CR",  "Carriage Return (\\r)"],
		["27", "ESC", "Escape"],
		["32", "SP",  "Пробел — первый видимый!"],
	]
	container.add_child(_make_table_row_bg(["Код", "Аббр.", "Значение"], true))
	for row_data in data:
		container.add_child(_make_table_row_bg(row_data, false))


# ══════════════════════════════════════════════════════════════
# HELPERS
# ══════════════════════════════════════════════════════════════

func _make_badge(text: String, col: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = col * Color(1, 1, 1, 0.14)
	ps.border_color = col
	ps.set_border_width_all(1)
	ps.corner_radius_top_left    = 8; ps.corner_radius_top_right   = 8
	ps.corner_radius_bottom_left = 8; ps.corner_radius_bottom_right = 8
	ps.content_margin_left = 12; ps.content_margin_right = 12
	ps.content_margin_top  = 6;  ps.content_margin_bottom = 6
	p.add_theme_stylebox_override("panel", ps)
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", col)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(lbl)
	return p

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
		cs.content_margin_left = 8;  cs.content_margin_right = 8
		cs.content_margin_top  = 6;  cs.content_margin_bottom = 6
		cell.add_theme_stylebox_override("panel", cs)
		row.add_child(cell)
		var lbl := Label.new()
		lbl.text = str(val)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color",
			Color(0.5, 0.7, 1.0, 1.0) if is_header else Color(0.8, 0.8, 0.9, 1.0))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		cell.add_child(lbl)
	return row

func _calculate_stars() -> int:
	return 3 if current_step_index >= tutorial_steps.size() - 1 else 2
