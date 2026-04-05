extends "res://scenes/Tutorial/TutorialBase.gd"
# TutorialHexadecimal.gd — Урок: Шестнадцатеричная система
# Готовит к: Дешифратор B (HEX-коды)

class_name TutorialHexadecimal

func _initialize_tutorial() -> void:
	tutorial_id = "hex_basics"
	tutorial_title = "Шестнадцатеричная система"
	linked_quest_scene = "res://scenes/Decryptor.tscn"

	tutorial_steps = [
		{
			"text": "HEX — это система счисления с основанием 16.\n\nВместо 10 цифр (0–9) здесь 16:\n0 1 2 3 4 5 6 7 8 9 A B C D E F\n\nA = 10, B = 11, C = 12, D = 13, E = 14, F = 15\n\nПочему HEX? Одна HEX-цифра точно соответствует 4 битам. Два HEX-символа = один байт. Это удобно.",
			"render_func": "render_hex_digit_table",
		},
		{
			"text": "Каждая позиция в HEX-числе — это степень 16.\n\nПозиция 0 (правая) = 16⁰ = 1\nПозиция 1            = 16¹ = 16\nПозиция 2            = 16² = 256\nПозиция 3            = 16³ = 4096\n\nЧтобы перевести HEX → DEC: умножь каждую цифру на её вес и сложи.",
			"render_func": "render_hex_weights",
		},
		{
			"text": "Разберём FF₁₆:\n\nF × 16¹ + F × 16⁰\n= 15 × 16 + 15 × 1\n= 240 + 15\n= 255₁₀\n\nFF — максимум для одного байта.\nВ CSS: #FFFFFF = белый цвет (три байта R=FF, G=FF, B=FF).\n\nВ игре FF часто означает «все биты включены».",
			"render_func": "render_hex_conversion",
			"hex_digits": ["F", "F"],
			"weights":    [16, 1],
			"dec_vals":   [240, 15],
			"total":      255,
		},
		{
			"text": "Разберём A5₁₆:\n\nA × 16¹ + 5 × 16⁰\n= 10 × 16 + 5 × 1\n= 160 + 5\n= 165₁₀\n\nКлюч ЕНТ: A всегда = 10, B = 11, … F = 15.\nЭто нужно запомнить как таблицу умножения.",
			"render_func": "render_hex_conversion",
			"hex_digits": ["A", "5"],
			"weights":    [16, 1],
			"dec_vals":   [160, 5],
			"total":      165,
		},
		{
			"text": "Перевод двоичного в HEX — быстрый способ:\n\n11110101₂\n↓ Разбей на группы по 4 бита\n1111  0101\n↓ Переведи каждую группу отдельно\n F     5\n\nРезультат: F5₁₆ = 245₁₀\n\nПочему группы по 4? Потому что 2⁴ = 16 — ровно одна HEX-цифра.",
			"render_func": "render_bin_to_hex",
			"binary": "11110101",
			"groups": ["1111", "0101"],
			"hex_out": ["F", "5"],
			"total": 245,
		},
		{
			"text": "Типичный вопрос ЕНТ:\n\n«Число 2C₁₆ в десятичной равно…»\n\nАлгоритм:\n1. Заменить буквы: 2=2, C=12\n2. Вычислить: 2 × 16 + 12 × 1\n3. = 32 + 12 = 44₁₀\n\nВторой вид вопроса: «Запишите 75₁₀ в HEX»\n75 ÷ 16 = 4 остаток 11 → 4B₁₆",
			"render_func": "render_hex_conversion",
			"hex_digits": ["2", "C"],
			"weights":    [16, 1],
			"dec_vals":   [32, 12],
			"total":      44,
		},
		{
			"text": "Быстрая таблица часто встречающихся HEX-значений:\n\nЗапомни эти числа — они встречаются в ЕНТ каждый год.",
			"render_func": "render_common_hex_table",
		},
		{
			"text": "В квесте «Дешифратор» (уровень B):\n\n• Тебе дают HEX-коды вместо бинарных\n• Нужно перевести в числа\n• Цепочка HEX → DEC → символ → сообщение\n\nОтличие от уровня A: используешь 16 вместо 2 как основание. Всё остальное — тот же алгоритм.",
			"render_func": "render_quest_preview_hex",
		},
	]


# ─── RENDER FUNCTIONS ─────────────────────────────────────────────────────────

func render_hex_digit_table(area: Control, _step: Dictionary) -> void:
	var digits   := ["0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"]
	var dec_vals := [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]

	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 6)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	for row_i in range(4):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		container.add_child(row)
		for col_i in range(4):
			var idx := row_i * 4 + col_i
			var cell := PanelContainer.new()
			cell.custom_minimum_size = Vector2(64, 54)
			var cs := StyleBoxFlat.new()
			cs.corner_radius_top_left    = 6; cs.corner_radius_top_right   = 6
			cs.corner_radius_bottom_left = 6; cs.corner_radius_bottom_right = 6
			cs.content_margin_left = 6; cs.content_margin_right = 6
			cs.content_margin_top  = 4; cs.content_margin_bottom = 4
			cs.set_border_width_all(1)
			if idx >= 10:
				cs.bg_color     = Color(0.10, 0.06, 0.20, 1.0)
				cs.border_color = Color(0.55, 0.25, 0.90, 0.9)
			else:
				cs.bg_color     = Color(0.08, 0.10, 0.18, 1.0)
				cs.border_color = Color(0.25, 0.38, 0.60, 0.7)
			cell.add_theme_stylebox_override("panel", cs)
			row.add_child(cell)

			var cv := VBoxContainer.new()
			cv.alignment = BoxContainer.ALIGNMENT_CENTER
			cell.add_child(cv)

			var hex_lbl := Label.new()
			hex_lbl.text = digits[idx]
			hex_lbl.add_theme_font_size_override("font_size", 22)
			hex_lbl.add_theme_color_override("font_color",
				Color(0.80, 0.50, 1.00, 1.0) if idx >= 10 else Color(0.55, 0.75, 1.00, 1.0))
			hex_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cv.add_child(hex_lbl)

			var dec_lbl := Label.new()
			dec_lbl.text = "(%d)" % dec_vals[idx]
			dec_lbl.add_theme_font_size_override("font_size", 10)
			dec_lbl.add_theme_color_override("font_color", Color(0.50, 0.50, 0.65, 1.0))
			dec_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cv.add_child(dec_lbl)


func render_hex_weights(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var data := [
		["Позиция 3", "16³", "4 096"],
		["Позиция 2", "16²", "256"],
		["Позиция 1", "16¹", "16"],
		["Позиция 0", "16⁰", "1"],
	]
	container.add_child(_make_table_row_bg(["Позиция", "Степень", "Вес"], true))
	for row_data in data:
		container.add_child(_make_table_row_bg(row_data, false))


func render_hex_conversion(area: Control, step: Dictionary) -> void:
	var hex_digits: Array = step.get("hex_digits", ["F","F"])
	var weights:    Array = step.get("weights",    [16, 1])
	var dec_vals:   Array = step.get("dec_vals",   [240, 15])
	var total: int        = step.get("total",      255)

	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var cells_row := HBoxContainer.new()
	cells_row.add_theme_constant_override("separation", 6)
	cells_row.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_child(cells_row)

	for i in range(hex_digits.size()):
		var cell := PanelContainer.new()
		cell.custom_minimum_size = Vector2(72, 0)
		var cs := StyleBoxFlat.new()
		cs.corner_radius_top_left    = 8; cs.corner_radius_top_right   = 8
		cs.corner_radius_bottom_left = 8; cs.corner_radius_bottom_right = 8
		cs.content_margin_left = 10; cs.content_margin_right = 10
		cs.content_margin_top  = 8;  cs.content_margin_bottom = 8
		cs.set_border_width_all(1)
		var is_letter: bool = hex_digits[i] >= "A" and hex_digits[i] <= "F"
		cs.bg_color     = Color(0.10, 0.06, 0.20, 1.0) if is_letter else Color(0.08, 0.10, 0.18, 1.0)
		cs.border_color = Color(0.55, 0.25, 0.90, 0.9) if is_letter else Color(0.25, 0.38, 0.60, 0.7)
		cell.add_theme_stylebox_override("panel", cs)
		cells_row.add_child(cell)

		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 2)
		cell.add_child(cv)

		var hex_lbl := Label.new()
		hex_lbl.text = hex_digits[i]
		hex_lbl.add_theme_font_size_override("font_size", 30)
		hex_lbl.add_theme_color_override("font_color",
			Color(0.80, 0.50, 1.00, 1.0) if is_letter else Color(0.55, 0.75, 1.00, 1.0))
		hex_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cv.add_child(hex_lbl)

		var w_lbl := Label.new()
		w_lbl.text = "×%d" % weights[i]
		w_lbl.add_theme_font_size_override("font_size", 11)
		w_lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.60, 1.0))
		w_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cv.add_child(w_lbl)

		var d_lbl := Label.new()
		d_lbl.text = "=%d" % dec_vals[i]
		d_lbl.add_theme_font_size_override("font_size", 12)
		d_lbl.add_theme_color_override("font_color", Color(0.20, 0.85, 0.60, 1.0))
		d_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cv.add_child(d_lbl)

	var parts: PackedStringArray = []
	for v in dec_vals:
		parts.append(str(v))
	var expr := " + ".join(parts) + " = %d₁₀" % total
	area.add_child(_make_info_panel(expr, Color(0.08, 0.18, 0.12, 1.0), Color(0.20, 0.65, 0.42, 0.7)))


func render_bin_to_hex(area: Control, step: Dictionary) -> void:
	var binary: String = step.get("binary", "11110101")
	var groups: Array  = step.get("groups", ["1111","0101"])
	var hex_out: Array = step.get("hex_out", ["F","5"])
	var total: int     = step.get("total",  245)

	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 10)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	area.add_child(_make_info_panel("Двоичное: %s₂" % binary,
		Color(0.08, 0.10, 0.18, 1.0), Color(0.25, 0.38, 0.60, 0.7)))

	var groups_row := HBoxContainer.new()
	groups_row.add_theme_constant_override("separation", 8)
	groups_row.alignment = BoxContainer.ALIGNMENT_CENTER
	area.add_child(groups_row)

	for i in range(groups.size()):
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 4)
		groups_row.add_child(col)

		var grp_panel := PanelContainer.new()
		var gs := StyleBoxFlat.new()
		gs.bg_color = Color(0.08, 0.12, 0.22, 1.0)
		gs.border_color = Color(0.25, 0.45, 0.80, 0.7)
		gs.set_border_width_all(1)
		gs.corner_radius_top_left    = 6; gs.corner_radius_top_right   = 6
		gs.corner_radius_bottom_left = 6; gs.corner_radius_bottom_right = 6
		gs.content_margin_left = 10; gs.content_margin_right = 10
		gs.content_margin_top  = 6;  gs.content_margin_bottom = 6
		grp_panel.add_theme_stylebox_override("panel", gs)
		col.add_child(grp_panel)

		var grp_lbl := Label.new()
		grp_lbl.text = groups[i]
		grp_lbl.add_theme_font_size_override("font_size", 18)
		grp_lbl.add_theme_color_override("font_color", Color(0.55, 0.75, 1.00, 1.0))
		grp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grp_panel.add_child(grp_lbl)

		var arrow_lbl := Label.new()
		arrow_lbl.text = "↓"
		arrow_lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.60, 1.0))
		arrow_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(arrow_lbl)

		var hex_panel := PanelContainer.new()
		var hs := StyleBoxFlat.new()
		hs.bg_color = Color(0.10, 0.06, 0.20, 1.0)
		hs.border_color = Color(0.55, 0.25, 0.90, 0.9)
		hs.set_border_width_all(1)
		hs.corner_radius_top_left    = 6; hs.corner_radius_top_right   = 6
		hs.corner_radius_bottom_left = 6; hs.corner_radius_bottom_right = 6
		hs.content_margin_left = 14; hs.content_margin_right = 14
		hs.content_margin_top  = 6;  hs.content_margin_bottom = 6
		hex_panel.add_theme_stylebox_override("panel", hs)
		col.add_child(hex_panel)

		var h_lbl := Label.new()
		h_lbl.text = hex_out[i]
		h_lbl.add_theme_font_size_override("font_size", 26)
		h_lbl.add_theme_color_override("font_color", Color(0.80, 0.50, 1.00, 1.0))
		h_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hex_panel.add_child(h_lbl)

	area.add_child(_make_info_panel(
		"%s%s₁₆ = %d₁₀" % [hex_out[0], hex_out[1], total],
		Color(0.08, 0.18, 0.12, 1.0), Color(0.20, 0.65, 0.42, 0.7)))


func render_common_hex_table(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var data := [
		["00", "0",   "Ноль / пустой байт"],
		["0A", "10",  "Перевод строки (\\n)"],
		["1F", "31",  "Макс. управляющий символ"],
		["20", "32",  "Пробел"],
		["41", "65",  "Буква 'A' в ASCII"],
		["7F", "127", "Макс. ASCII"],
		["80", "128", "Начало 8-й позиции"],
		["FF", "255", "Макс. байт"],
	]
	container.add_child(_make_table_row_bg(["HEX", "DEC", "Значение"], true))
	for row_data in data:
		container.add_child(_make_table_row_bg(row_data, false))


func render_quest_preview_hex(area: Control, _step: Dictionary) -> void:
	var panel := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.08, 0.06, 0.18, 1.0)
	ps.border_color = Color(0.45, 0.20, 0.80, 0.6)
	ps.set_border_width_all(1)
	ps.corner_radius_top_left    = 10; ps.corner_radius_top_right   = 10
	ps.corner_radius_bottom_left = 10; ps.corner_radius_bottom_right = 10
	ps.content_margin_left = 14; ps.content_margin_right = 14
	ps.content_margin_top  = 12; ps.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", ps)
	area.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "🔓 ДЕШИФРАТОР — Уровень B (HEX)"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.75, 0.50, 1.00, 1.0))
	vbox.add_child(title)

	for hint in [
		"📥 Тебе дают HEX-коды вместо двоичных",
		"🧮 Переводишь HEX → DEC (основание 16)",
		"🔍 Число расшифровывает символ ASCII",
		"✅ Уровень B сложнее А, но алгоритм тот же",
	]:
		var lbl := Label.new()
		lbl.text = hint
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85, 1.0))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(lbl)


# ─── HELPERS ──────────────────────────────────────────────────────────────────

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
		cs.content_margin_left = 8; cs.content_margin_right = 8
		cs.content_margin_top  = 6; cs.content_margin_bottom = 6
		cell.add_theme_stylebox_override("panel", cs)
		row.add_child(cell)
		var lbl := Label.new()
		lbl.text = str(val)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 13 if is_header else 14)
		lbl.add_theme_color_override("font_color",
			Color(0.5, 0.7, 1.0, 1.0) if is_header else Color(0.8, 0.8, 0.9, 1.0))
		cell.add_child(lbl)
	return row

func _calculate_stars() -> int:
	return 3 if current_step_index >= tutorial_steps.size() - 1 else 2
