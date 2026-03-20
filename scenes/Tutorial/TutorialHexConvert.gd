extends "res://scenes/Tutorial/TutorialBase.gd"
# TutorialHexConvert.gd — Перевод HEX↔BIN↔DEC
# Готовит к: Дешифратор B/C

class_name TutorialHexConvert

func _initialize_tutorial() -> void:
	tutorial_id = "hex_convert"
	tutorial_title = "Перевод HEX↔BIN↔DEC"
	linked_quest_scene = "res://scenes/Decryptor.tscn"

	tutorial_steps = [
		{
			"text": "Три системы счисления — одни и те же числа, разные записи:\n\nDEC (10) — обычные числа\nBIN (2)  — биты\nHEX (16) — компактная форма бит\n\nСвязь: каждые 4 бита = 1 HEX-цифра.\nЗначит: 8 бит = 2 HEX-цифры = 1 байт.\n\nЭта связь делает HEX удобным для работы с памятью и цветами.",
			"render_func": "render_systems_overview",
		},
		{
			"text": "Полная таблица соответствия 0–15.\n\nЗапомни столбик HEX ↔ BIN для цифр A–F — именно они чаще всего встречаются в ЕНТ.\n\nТрик: чтобы перевести HEX-цифру в 4 бита, просто запомни что A=1010, B=1011, C=1100, D=1101, E=1110, F=1111.",
			"render_func": "render_full_table",
		},
		{
			"text": "BIN → HEX (быстрый способ):\n\n1. Разбей биты на группы по 4 (справа налево)\n2. Каждую группу переведи в одну HEX-цифру\n\nПример: 10111100₂\n→ 1011 | 1100\n→   B  |  C\n→ BC₁₆\n\nПроверка: B=11, C=12 → 11×16 + 12 = 188₁₀",
			"render_func": "render_bin_to_hex_step",
			"binary": "10111100",
			"groups": ["1011", "1100"],
			"hex_out": ["B", "C"],
			"total": 188,
		},
		{
			"text": "HEX → BIN (обратное):\n\nКаждую HEX-цифру разверни в 4 бита.\n\nПример: 3F₁₆\n3 → 0011\nF → 1111\n→ 00111111₂\n\nВажно: всегда пиши ровно 4 бита для каждой цифры.\n3 → 0011 (не просто 11!)\n\nПроверка: 32+16+8+4+2+1 = 63₁₀ = 3F₁₆ ✓",
			"render_func": "render_hex_to_bin_step",
			"hex_digits": ["3", "F"],
			"bin_groups": ["0011", "1111"],
			"total": 63,
		},
		{
			"text": "DEC → HEX (через деление на 16):\n\nПример: 200₁₀\n200 ÷ 16 = 12  остаток 8  → C8₁₆\n\n(12 = C, поэтому старшая цифра C)\n\nЧитаем: сначала частное (C), потом остаток (8) → C8₁₆\n\nПроверка: 12×16 + 8 = 192 + 8 = 200 ✓\n\nВ ЕНТ часто дают числа до 255 — они умещаются в 2 HEX-цифры (00–FF).",
			"render_func": "render_dec_to_hex",
			"number": 200,
			"quotient": 12,
			"remainder": 8,
			"hex_result": "C8",
		},
		{
			"text": "Цвета в HTML/CSS — прямое применение HEX:\n\n#RRGGBB — три байта: красный, зелёный, синий\n\n#FF0000 = чистый красный (R=255, G=0, B=0)\n#00FF00 = чистый зелёный\n#0000FF = чистый синий\n#FFFFFF = белый (все максимум)\n#000000 = чёрный (все ноль)\n#808080 = серый (все по 128)\n\nВ квесте встречаются цветовые коды — теперь ты умеешь их читать.",
			"render_func": "render_color_table",
		},
		{
			"text": "Быстрая шпаргалка для ЕНТ:\n\nВ тестах чаще всего встречаются:\n• FF₁₆ = 255₁₀ = 11111111₂\n• 80₁₆ = 128₁₀ = 10000000₂\n• 0F₁₆ = 15₁₀  = 00001111₂\n• 10₁₆ = 16₁₀  = 00010000₂\n• A0₁₆ = 160₁₀ = 10100000₂\n\nЗная эти пять — решишь большинство задач без вычислений.",
			"render_func": "render_cheatsheet",
		},
	]


# ══════════════════════════════════════════════════════════════
# RENDER FUNCTIONS
# ══════════════════════════════════════════════════════════════

func render_systems_overview(area: Control, _step: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	area.add_child(row)

	var systems := [
		{"name": "DEC", "base": "10", "ex": "255", "col": Color(0.35, 0.70, 1.00, 1.0)},
		{"name": "BIN", "base": "2",  "ex": "11111111", "col": Color(0.20, 0.85, 0.55, 1.0)},
		{"name": "HEX", "base": "16", "ex": "FF", "col": Color(0.80, 0.50, 1.00, 1.0)},
	]
	for sys in systems:
		var cell := PanelContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cs := StyleBoxFlat.new()
		cs.bg_color = sys["col"] * Color(1, 1, 1, 0.10)
		cs.border_color = sys["col"]
		cs.set_border_width_all(2)
		cs.corner_radius_top_left    = 10; cs.corner_radius_top_right   = 10
		cs.corner_radius_bottom_left = 10; cs.corner_radius_bottom_right = 10
		cs.content_margin_left = 10; cs.content_margin_right = 10
		cs.content_margin_top  = 10; cs.content_margin_bottom = 10
		cell.add_theme_stylebox_override("panel", cs)
		row.add_child(cell)

		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 4)
		cell.add_child(vb)

		var name_lbl := Label.new()
		name_lbl.text = sys["name"]
		name_lbl.add_theme_font_size_override("font_size", 24)
		name_lbl.add_theme_color_override("font_color", sys["col"])
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(name_lbl)

		var base_lbl := Label.new()
		base_lbl.text = "основание %s" % sys["base"]
		base_lbl.add_theme_font_size_override("font_size", 11)
		base_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.70, 1.0))
		base_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(base_lbl)

		var ex_lbl := Label.new()
		ex_lbl.text = sys["ex"]
		ex_lbl.add_theme_font_size_override("font_size", 16)
		ex_lbl.add_theme_color_override("font_color", sys["col"])
		ex_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(ex_lbl)


func render_full_table(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 3)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	container.add_child(_make_table_row_bg(["DEC", "HEX", "BIN"], true))
	var bin_map := [
		"0000","0001","0010","0011","0100","0101","0110","0111",
		"1000","1001","1010","1011","1100","1101","1110","1111"
	]
	var hex_map := ["0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"]
	for i in range(16):
		var row := _make_table_row_bg([str(i), hex_map[i], bin_map[i]], false)
		# A–F: tint purple
		if i >= 10:
			row.modulate = Color(0.90, 0.80, 1.00, 1.0)
		container.add_child(row)


func render_bin_to_hex_step(area: Control, step: Dictionary) -> void:
	var binary: String  = step.get("binary", "10111100")
	var groups: Array   = step.get("groups", ["1011", "1100"])
	var hex_out: Array  = step.get("hex_out", ["B", "C"])
	var total: int      = step.get("total", 188)

	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 10)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	area.add_child(_make_info_panel("Двоичное: %s₂" % binary,
		Color(0.08, 0.10, 0.18, 1.0), Color(0.25, 0.38, 0.60, 0.7)))

	var groups_row := HBoxContainer.new()
	groups_row.add_theme_constant_override("separation", 12)
	groups_row.alignment = BoxContainer.ALIGNMENT_CENTER
	area.add_child(groups_row)

	for i in range(groups.size()):
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 4)
		groups_row.add_child(col)

		var grp := _make_styled_cell(groups[i], 18, Color(0.55, 0.75, 1.00, 1.0),
			Color(0.08, 0.12, 0.22, 1.0), Color(0.25, 0.45, 0.80, 0.7))
		col.add_child(grp)

		var arr := Label.new()
		arr.text = "↓"
		arr.add_theme_color_override("font_color", Color(0.45, 0.45, 0.60, 1.0))
		arr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(arr)

		var hex := _make_styled_cell(hex_out[i], 26, Color(0.80, 0.50, 1.00, 1.0),
			Color(0.10, 0.06, 0.20, 1.0), Color(0.55, 0.25, 0.90, 0.9))
		col.add_child(hex)

	area.add_child(_make_info_panel(
		"%s%s₁₆ = %d₁₀" % [hex_out[0], hex_out[1], total],
		Color(0.08, 0.18, 0.12, 1.0), Color(0.20, 0.65, 0.42, 0.7)))


func render_hex_to_bin_step(area: Control, step: Dictionary) -> void:
	var hex_digits: Array  = step.get("hex_digits", ["3", "F"])
	var bin_groups: Array  = step.get("bin_groups", ["0011", "1111"])
	var total: int         = step.get("total", 63)

	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 10)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var hex_str: String = "".join(hex_digits)
	area.add_child(_make_info_panel("HEX: %s₁₆" % hex_str,
		Color(0.10, 0.06, 0.20, 1.0), Color(0.55, 0.25, 0.90, 0.9)))

	var groups_row := HBoxContainer.new()
	groups_row.add_theme_constant_override("separation", 12)
	groups_row.alignment = BoxContainer.ALIGNMENT_CENTER
	area.add_child(groups_row)

	for i in range(hex_digits.size()):
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 4)
		groups_row.add_child(col)

		var hex := _make_styled_cell(hex_digits[i], 26, Color(0.80, 0.50, 1.00, 1.0),
			Color(0.10, 0.06, 0.20, 1.0), Color(0.55, 0.25, 0.90, 0.9))
		col.add_child(hex)

		var arr := Label.new()
		arr.text = "↓"
		arr.add_theme_color_override("font_color", Color(0.45, 0.45, 0.60, 1.0))
		arr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(arr)

		var grp := _make_styled_cell(bin_groups[i], 18, Color(0.55, 0.75, 1.00, 1.0),
			Color(0.08, 0.12, 0.22, 1.0), Color(0.25, 0.45, 0.80, 0.7))
		col.add_child(grp)

	var bin_result: String = "".join(bin_groups)
	area.add_child(_make_info_panel(
		"%s₂ = %d₁₀" % [bin_result, total],
		Color(0.08, 0.18, 0.12, 1.0), Color(0.20, 0.65, 0.42, 0.7)))


func render_dec_to_hex(area: Control, step: Dictionary) -> void:
	var number: int    = step.get("number", 200)
	var quotient: int  = step.get("quotient", 12)
	var remainder: int = step.get("remainder", 8)
	var hex_res: String = step.get("hex_result", "C8")

	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	container.add_child(_make_table_row_bg(["Шаг", "Действие", "Результат"], true))
	container.add_child(_make_table_row_bg(
		["1", "%d ÷ 16" % number, "= %d ост. %d" % [quotient, remainder]], false))
	container.add_child(_make_table_row_bg(
		["2", "%d → HEX" % quotient, "= %s" % ("A B C D E F".split(" ")[quotient - 10] if quotient >= 10 else str(quotient))], false))
	container.add_child(_make_table_row_bg(
		["3", "%d → HEX" % remainder, "= %d" % remainder], false))

	area.add_child(_make_info_panel(
		"%d₁₀ = %s₁₆" % [number, hex_res],
		Color(0.08, 0.18, 0.12, 1.0), Color(0.20, 0.65, 0.42, 0.7)))


func render_color_table(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 5)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var colors := [
		["#FF0000", "255,0,0",   "Красный",  Color(0.9, 0.15, 0.15, 1.0)],
		["#00FF00", "0,255,0",   "Зелёный",  Color(0.15, 0.85, 0.25, 1.0)],
		["#0000FF", "0,0,255",   "Синий",    Color(0.20, 0.45, 1.00, 1.0)],
		["#FFFFFF", "255,255,255","Белый",   Color(0.92, 0.92, 0.92, 1.0)],
		["#000000", "0,0,0",     "Чёрный",   Color(0.35, 0.35, 0.42, 1.0)],
		["#808080", "128,128,128","Серый",   Color(0.60, 0.60, 0.68, 1.0)],
	]
	container.add_child(_make_table_row_bg(["HEX-код", "R,G,B", "Цвет"], true))
	for c in colors:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		container.add_child(row)
		for j in range(3):
			var cell := PanelContainer.new()
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var cs := StyleBoxFlat.new()
			cs.bg_color = c[3] * Color(1, 1, 1, 0.15) if j == 2 else Color(0.07, 0.08, 0.12, 1.0)
			cs.border_color = c[3] * Color(1, 1, 1, 0.50) if j == 2 else Color(0.15, 0.15, 0.22, 0.5)
			cs.set_border_width_all(1)
			cs.corner_radius_top_left    = 4; cs.corner_radius_top_right   = 4
			cs.corner_radius_bottom_left = 4; cs.corner_radius_bottom_right = 4
			cs.content_margin_left = 8; cs.content_margin_right = 8
			cs.content_margin_top  = 6; cs.content_margin_bottom = 6
			cell.add_theme_stylebox_override("panel", cs)
			row.add_child(cell)
			var lbl := Label.new()
			lbl.text = c[j]
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.add_theme_font_size_override("font_size", 13)
			lbl.add_theme_color_override("font_color", c[3] if j == 2 else Color(0.80, 0.80, 0.90, 1.0))
			cell.add_child(lbl)


func render_cheatsheet(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var data := [
		["FF₁₆", "255₁₀", "11111111₂", "Макс. байт"],
		["80₁₆", "128₁₀", "10000000₂", "Первый бит"],
		["0F₁₆", "15₁₀",  "00001111₂", "Младшие 4 бита"],
		["10₁₆", "16₁₀",  "00010000₂", "= 2⁴"],
		["A0₁₆", "160₁₀", "10100000₂", "A×16"],
	]
	container.add_child(_make_table_row_bg(["HEX", "DEC", "BIN", "Значение"], true))
	for row_data in data:
		container.add_child(_make_table_row_bg(row_data, false))


# ══════════════════════════════════════════════════════════════
# HELPERS
# ══════════════════════════════════════════════════════════════

func _make_styled_cell(text: String, font_size: int, font_col: Color, bg: Color, border: Color) -> PanelContainer:
	var cell := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = bg; cs.border_color = border
	cs.set_border_width_all(1)
	cs.corner_radius_top_left    = 6; cs.corner_radius_top_right   = 6
	cs.corner_radius_bottom_left = 6; cs.corner_radius_bottom_right = 6
	cs.content_margin_left = 12; cs.content_margin_right = 12
	cs.content_margin_top  = 6;  cs.content_margin_bottom = 6
	cell.add_theme_stylebox_override("panel", cs)
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", font_col)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cell.add_child(lbl)
	return cell

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
		lbl.add_theme_font_size_override("font_size", 13 if is_header else 13)
		lbl.add_theme_color_override("font_color",
			Color(0.5, 0.7, 1.0, 1.0) if is_header else Color(0.8, 0.8, 0.9, 1.0))
		cell.add_child(lbl)
	return row

func _calculate_stars() -> int:
	return 3 if current_step_index >= tutorial_steps.size() - 1 else 2
