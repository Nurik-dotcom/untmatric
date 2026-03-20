extends "res://scenes/Tutorial/TutorialBase.gd"
# TutorialBinConvert.gd — Урок: Перевод 2↔10
# Готовит к: Дешифратор A

class_name TutorialBinConvert

func _initialize_tutorial() -> void:
	tutorial_id = "bin_convert"
	tutorial_title = "Перевод 2↔10"
	linked_quest_scene = "res://scenes/Decryptor.tscn"

	tutorial_steps = [
		{
			"text": "Мы уже знаем, как прочитать двоичное число.\nТеперь научимся работать в обе стороны:\n\n2→10: умножаем каждый бит на его вес и складываем\n10→2: делим число на 2, собираем остатки снизу вверх\n\nОба алгоритма используются в ЕНТ каждый год.",
			"render_func": "render_direction_overview",
		},
		{
			"text": "Алгоритм 2→10 (уже знакомый):\n\nВозьмём 10110₂\n\nПозиции (справа): 0,1,2,3,4\nВеса:              1,2,4,8,16\nБиты:              0,1,1,0,1\n\n1×16 + 0×8 + 1×4 + 1×2 + 0×1\n= 16 + 4 + 2 = 22₁₀\n\nВсё, что нужно — выписать веса и сложить те, где бит = 1.",
			"render_func": "render_binary_to_dec",
			"bits": [1, 0, 1, 1, 0],
			"result": 22,
		},
		{
			"text": "Алгоритм 10→2 (деление на 2):\n\nПереводим 22₁₀:\n\n22 ÷ 2 = 11  остаток 0  ← младший бит\n11 ÷ 2 = 5   остаток 1\n 5 ÷ 2 = 2   остаток 1\n 2 ÷ 2 = 1   остаток 0\n 1 ÷ 2 = 0   остаток 1  ← старший бит\n\nЧитаем остатки СНИЗУ ВВЕРХ: 10110₂\n\nПравило: делим пока не получим 0, затем читаем остатки снизу.",
			"render_func": "render_division_table",
			"number": 22,
			"steps": [
				{"dividend": 22, "quotient": 11, "remainder": 0},
				{"dividend": 11, "quotient": 5,  "remainder": 1},
				{"dividend": 5,  "quotient": 2,  "remainder": 1},
				{"dividend": 2,  "quotient": 1,  "remainder": 0},
				{"dividend": 1,  "quotient": 0,  "remainder": 1},
			],
			"result_bin": "10110",
		},
		{
			"text": "Практика ЕНТ: переведи 45₁₀ в двоичную.\n\n45 ÷ 2 = 22  остаток 1\n22 ÷ 2 = 11  остаток 0\n11 ÷ 2 = 5   остаток 1\n 5 ÷ 2 = 2   остаток 1\n 2 ÷ 2 = 1   остаток 0\n 1 ÷ 2 = 0   остаток 1\n\nЧитаем снизу: 101101₂\n\nПроверка: 32+8+4+1 = 45 ✓",
			"render_func": "render_division_table",
			"number": 45,
			"steps": [
				{"dividend": 45, "quotient": 22, "remainder": 1},
				{"dividend": 22, "quotient": 11, "remainder": 0},
				{"dividend": 11, "quotient": 5,  "remainder": 1},
				{"dividend": 5,  "quotient": 2,  "remainder": 1},
				{"dividend": 2,  "quotient": 1,  "remainder": 0},
				{"dividend": 1,  "quotient": 0,  "remainder": 1},
			],
			"result_bin": "101101",
		},
		{
			"text": "Частые числа ЕНТ — запомни их наизусть.\n\nЭти числа — степени двойки и их суммы — встречаются в заданиях чаще всего.",
			"render_func": "render_common_conversions",
		},
		{
			"text": "Быстрый способ проверить себя:\n\n1. Сложи все веса активных битов → должно дать исходное число\n2. Для обратного: последний остаток — всегда старший бит\n3. Число битов = ⌊log₂(N)⌋ + 1\n\nПример: 255 = 11111111₂ (8 единиц, 8 бит)\nПример: 256 = 100000000₂ (9 бит!)\n\nЗапомни: 2⁸ = 256 — первое 9-битное число.",
			"render_func": "render_edge_cases",
		},
	]


# ═══ RENDER FUNCTIONS ═══════════════════════════════════════════════════════

func render_direction_overview(area: Control, _step: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	area.add_child(row)

	for info in [
		{"dir": "2 → 10", "method": "Суммируй веса\nгде бит = 1", "col": Color(0.2, 0.85, 0.55, 1.0)},
		{"dir": "10 → 2", "method": "Дели на 2,\nбери остатки снизу", "col": Color(0.35, 0.70, 1.00, 1.0)},
	]:
		var cell := PanelContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cs := StyleBoxFlat.new()
		cs.bg_color = Color(0.07, 0.10, 0.16, 1.0)
		cs.border_color = info["col"]
		cs.set_border_width_all(2)
		cs.corner_radius_top_left    = 10; cs.corner_radius_top_right   = 10
		cs.corner_radius_bottom_left = 10; cs.corner_radius_bottom_right = 10
		cs.content_margin_left = 14; cs.content_margin_right = 14
		cs.content_margin_top  = 12; cs.content_margin_bottom = 12
		cell.add_theme_stylebox_override("panel", cs)
		row.add_child(cell)

		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 6)
		cell.add_child(vb)

		var dir_lbl := Label.new()
		dir_lbl.text = info["dir"]
		dir_lbl.add_theme_font_size_override("font_size", 26)
		dir_lbl.add_theme_color_override("font_color", info["col"])
		dir_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(dir_lbl)

		var method_lbl := Label.new()
		method_lbl.text = info["method"]
		method_lbl.add_theme_font_size_override("font_size", 13)
		method_lbl.add_theme_color_override("font_color", Color(0.70, 0.70, 0.80, 1.0))
		method_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		method_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		vb.add_child(method_lbl)


func render_binary_to_dec(area: Control, step: Dictionary) -> void:
	var bits: Array = step.get("bits", [1, 0, 1, 1, 0])
	var result: int = step.get("result", 22)
	var weights_full := [128, 64, 32, 16, 8, 4, 2, 1]
	var n := bits.size()
	var weights: Array = []
	for i in range(n):
		weights.append(weights_full[8 - n + i])

	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_child(row)

	for i in range(n):
		var cell := PanelContainer.new()
		cell.custom_minimum_size = Vector2(44, 0)
		var cs := StyleBoxFlat.new()
		cs.corner_radius_top_left    = 6; cs.corner_radius_top_right   = 6
		cs.corner_radius_bottom_left = 6; cs.corner_radius_bottom_right = 6
		cs.content_margin_left = 6; cs.content_margin_right = 6
		cs.content_margin_top  = 5; cs.content_margin_bottom = 5
		cs.set_border_width_all(1)
		if bits[i] == 1:
			cs.bg_color     = Color(0.08, 0.22, 0.14, 1.0)
			cs.border_color = Color(0.18, 0.78, 0.48, 1.0)
		else:
			cs.bg_color     = Color(0.09, 0.09, 0.14, 1.0)
			cs.border_color = Color(0.22, 0.22, 0.32, 1.0)
		cell.add_theme_stylebox_override("panel", cs)
		row.add_child(cell)

		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 2)
		cell.add_child(cv)

		var b_lbl := Label.new()
		b_lbl.text = str(bits[i])
		b_lbl.add_theme_font_size_override("font_size", 22)
		b_lbl.add_theme_color_override("font_color",
			Color(0.2, 1.0, 0.6, 1.0) if bits[i] == 1 else Color(0.3, 0.3, 0.42, 1.0))
		b_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cv.add_child(b_lbl)

		var w_lbl := Label.new()
		w_lbl.text = str(weights[i])
		w_lbl.add_theme_font_size_override("font_size", 11)
		w_lbl.add_theme_color_override("font_color",
			Color(0.15, 0.85, 0.5, 1.0) if bits[i] == 1 else Color(0.25, 0.25, 0.38, 1.0))
		w_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cv.add_child(w_lbl)

	var parts: PackedStringArray = []
	for i in range(n):
		if bits[i] == 1:
			parts.append(str(weights[i]))
	var expr: String = " + ".join(parts) + " = %d₁₀" % result
	area.add_child(_make_info_panel(expr, Color(0.08, 0.18, 0.12, 1.0), Color(0.20, 0.65, 0.42, 0.7)))


func render_division_table(area: Control, step: Dictionary) -> void:
	var steps_data: Array = step.get("steps", [])
	var result_bin: String = step.get("result_bin", "")
	var number: int = step.get("number", 0)

	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 6)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var title_lbl := Label.new()
	title_lbl.text = "Деление %d на 2:" % number
	title_lbl.add_theme_font_size_override("font_size", 14)
	title_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.70, 1.0))
	container.add_child(title_lbl)

	container.add_child(_make_table_row_bg(["Число", "÷2 =", "Остаток"], true))

	for i in range(steps_data.size()):
		var s: Dictionary = steps_data[i]
		var is_last: bool = i == steps_data.size() - 1
		var row_data := [str(s["dividend"]), str(s["quotient"]), str(s["remainder"])]
		var row := _make_table_row_bg(row_data, false)
		if is_last:
			row.modulate = Color(0.9, 1.0, 0.85, 1.0)
		container.add_child(row)

	if result_bin != "":
		area.add_child(_make_info_panel(
			"Читаем снизу: %s₂" % result_bin,
			Color(0.08, 0.18, 0.12, 1.0), Color(0.20, 0.65, 0.42, 0.7)))


func render_common_conversions(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var data := [
		["1",   "1",          "2⁰"],
		["2",   "10",         "2¹"],
		["4",   "100",        "2²"],
		["8",   "1000",       "2³"],
		["16",  "10000",      "2⁴"],
		["32",  "100000",     "2⁵"],
		["64",  "1000000",    "2⁶"],
		["128", "10000000",   "2⁷"],
		["255", "11111111",   "2⁸−1"],
		["256", "100000000",  "2⁸"],
	]
	container.add_child(_make_table_row_bg(["DEC", "BIN", "Как читать"], true))
	for row_data in data:
		container.add_child(_make_table_row_bg(row_data, false))


func render_edge_cases(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	for info in [
		["255 = 11111111₂", "8 бит — все единицы", Color(0.18, 0.78, 0.48, 1.0)],
		["256 = 100000000₂", "9 бит — первое 9-битное", Color(0.35, 0.70, 1.00, 1.0)],
		["0 = 00000000₂", "Все нули", Color(0.55, 0.55, 0.70, 1.0)],
	]:
		var p := PanelContainer.new()
		var ps := StyleBoxFlat.new()
		ps.bg_color = Color(0.08, 0.09, 0.15, 1.0)
		ps.border_color = info[2]
		ps.set_border_width_all(1)
		ps.corner_radius_top_left    = 6; ps.corner_radius_top_right   = 6
		ps.corner_radius_bottom_left = 6; ps.corner_radius_bottom_right = 6
		ps.content_margin_left = 12; ps.content_margin_right = 12
		ps.content_margin_top  = 8;  ps.content_margin_bottom = 8
		p.add_theme_stylebox_override("panel", ps)
		container.add_child(p)

		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 12)
		p.add_child(hb)

		var val_lbl := Label.new()
		val_lbl.text = info[0]
		val_lbl.add_theme_font_size_override("font_size", 16)
		val_lbl.add_theme_color_override("font_color", info[2])
		val_lbl.custom_minimum_size = Vector2(200, 0)
		hb.add_child(val_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = info[1]
		desc_lbl.add_theme_font_size_override("font_size", 13)
		desc_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.75, 1.0))
		desc_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hb.add_child(desc_lbl)


# ═══ HELPERS ════════════════════════════════════════════════════════════════

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
