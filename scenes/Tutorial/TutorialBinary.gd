extends "res://scenes/Tutorial/TutorialBase.gd"
# TutorialBinary.gd — Урок: Биты и байты
# Готовит к: Дешифратор (уровень A)
# Темы ЕНТ: перевод 2↔10, 8-битный диапазон, ASCII

class_name TutorialBinary

func _initialize_tutorial() -> void:
	tutorial_id = "bin_basics"
	tutorial_title = "Биты и байты"
	linked_quest_scene = "res://scenes/Decryptor.tscn"

	tutorial_steps = [
		# ── ШАГ 1: Зачем нужна двоичная система ────────────────────
		{
			"text": "Компьютер — это электрическая машина. Транзистор может быть в двух состояниях:\n\n⊘  0 — нет тока (выключено)\n⊙  1 — есть ток (включено)\n\nВсё в компьютере — числа, буквы, картинки, звук — хранится в виде последовательностей 0 и 1.\n\nЭто называется двоичная система счисления (основание 2).",
			"render_func": "render_voltage_demo",
		},

		# ── ШАГ 2: Бит и байт ───────────────────────────────────────
		{
			"text": "Один 0 или 1 — это бит (binary digit).\n\n8 бит = 1 байт\n\nПочему 8? Так сложилось исторически — 8 бит хватает чтобы закодировать все буквы латиницы (0–127 в ASCII).\n\n1 байт может хранить число от 0 до 255.",
			"render_func": "render_byte_structure",
		},

		# ── ШАГ 3: Позиционные веса ─────────────────────────────────
		{
			"text": "Каждый бит в байте имеет свой вес — степень двойки.\n\nПравый бит (позиция 0) = 2⁰ = 1\nСледующий (позиция 1) = 2¹ = 2\n...\nЛевый бит (позиция 7) = 2⁷ = 128\n\nЧтобы получить десятичное число — суммируй веса тех позиций, где стоит 1.",
			"render_func": "render_weights_table",
		},

		# ── ШАГ 4: Пример 10101010 ───────────────────────────────────
		{
			"text": "Разберём число 10101010₂\n\nBit 7=1 → +128\nBit 6=0 → +0\nBit 5=1 → +32\nBit 4=0 → +0\nBit 3=1 → +8\nBit 2=0 → +0\nBit 1=1 → +2\nBit 0=0 → +0\n\n128 + 32 + 8 + 2 = 170₁₀",
			"render_func": "render_bit_grid",
			"bits": [1, 0, 1, 0, 1, 0, 1, 0],
			"highlight_calc": true,
		},

		# ── ШАГ 5: Максимум 8-бит ────────────────────────────────────
		{
			"text": "Что если все биты равны 1?\n\n11111111₂ = 128+64+32+16+8+4+2+1\n\n= 255₁₀\n\nЭто максимальное значение одного байта.\n\nВ ЕНТ часто спрашивают:\n«Какое max значение может хранить N-битное число?»\nОтвет: 2ᴺ − 1",
			"render_func": "render_bit_grid",
			"bits": [1, 1, 1, 1, 1, 1, 1, 1],
			"highlight_calc": true,
		},

		# ── ШАГ 6: Типичная задача ЕНТ ──────────────────────────────
		{
			"text": "Типичный вопрос ЕНТ:\n\n«Переведите 01000001₂ в десятичную»\n\nАлгоритм:\n1. Запиши веса снизу: 128,64,32,16,8,4,2,1\n2. Умножь каждый на бит\n3. Сложи результаты\n\n0×128 + 1×64 + 0×32... + 0×2 + 1×1\n= 64 + 1 = 65₁₀\n\nИнтересный факт: 65 — это ASCII-код буквы 'A'",
			"render_func": "render_bit_grid",
			"bits": [0, 1, 0, 0, 0, 0, 0, 1],
			"highlight_calc": true,
		},

		# ── ШАГ 7: Диапазоны ─────────────────────────────────────────
		{
			"text": "Диапазоны часто встречаются в тестах ЕНТ:\n\n8 бит: 0 — 255  (256 значений = 2⁸)\n16 бит: 0 — 65535\n32 бита: 0 — 4 294 967 295\n\nФормула: N бит → 2ᴺ значений\nМаксимум: 2ᴺ − 1",
			"render_func": "render_ranges_table",
		},

		# ── ШАГ 8: Связь с игрой ─────────────────────────────────────
		{
			"text": "В квесте «Дешифратор» ты будешь:\n\n• Читать двоичные коды агентов\n• Переводить их в числа\n• Находить скрытые сообщения\n\nВсе коды уровня A — это 8-битные числа. Ты уже знаешь всё необходимое.\n\nГотов проверить себя?",
			"render_func": "render_quest_preview",
		},
	]

# ═══════════════════════════════════════════════════════════════
# RENDER FUNCTIONS
# ═══════════════════════════════════════════════════════════════

func render_voltage_demo(area: Control, _step: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	area.add_child(row)

	for bit_val in [0, 1]:
		var cell := PanelContainer.new()
		cell.custom_minimum_size = Vector2(120, 90)
		var cs := StyleBoxFlat.new()
		cs.corner_radius_top_left = 10
		cs.corner_radius_top_right = 10
		cs.corner_radius_bottom_left = 10
		cs.corner_radius_bottom_right = 10
		cs.set_border_width_all(2)
		if bit_val == 1:
			cs.bg_color = Color(0.05, 0.22, 0.14, 1.0)
			cs.border_color = Color(0.15, 0.85, 0.5, 1.0)
		else:
			cs.bg_color = Color(0.10, 0.10, 0.14, 1.0)
			cs.border_color = Color(0.25, 0.25, 0.35, 1.0)
		cell.add_theme_stylebox_override("panel", cs)
		row.add_child(cell)

		var vbox := VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 6)
		cell.add_child(vbox)

		var num_lbl := Label.new()
		num_lbl.text = str(bit_val)
		num_lbl.add_theme_font_size_override("font_size", 42)
		num_lbl.add_theme_color_override("font_color",
			Color(0.2, 1.0, 0.6, 1.0) if bit_val == 1 else Color(0.35, 0.35, 0.45, 1.0))
		num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(num_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = "ТОК ЕСТЬ" if bit_val == 1 else "НЕТ ТОКА"
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.add_theme_color_override("font_color",
			Color(0.15, 0.85, 0.5, 0.9) if bit_val == 1 else Color(0.45, 0.45, 0.55, 0.9))
		desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(desc_lbl)


func render_byte_structure(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	area.add_child(container)

	var bits_row := HBoxContainer.new()
	bits_row.add_theme_constant_override("separation", 3)
	bits_row.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_child(bits_row)

	for i in range(8):
		var cell := PanelContainer.new()
		cell.custom_minimum_size = Vector2(34, 40)
		var cs := StyleBoxFlat.new()
		cs.corner_radius_top_left = 5
		cs.corner_radius_top_right = 5
		cs.corner_radius_bottom_left = 5
		cs.corner_radius_bottom_right = 5
		cs.bg_color = Color(0.1, 0.1, 0.18, 1.0)
		cs.border_color = Color(0.3, 0.3, 0.5, 0.7)
		cs.set_border_width_all(1)
		cell.add_theme_stylebox_override("panel", cs)
		bits_row.add_child(cell)

		var lbl := Label.new()
		lbl.text = "b%d" % (7 - i)
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.7, 1.0))
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(lbl)

	var byte_label := Label.new()
	byte_label.text = "←──────── 8 бит = 1 байт ────────→"
	byte_label.add_theme_font_size_override("font_size", 12)
	byte_label.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0, 0.9))
	byte_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(byte_label)

	var range_panel := _make_info_panel("Диапазон 1 байта: 0 … 255  (2⁸ = 256 значений)", Color(0.1, 0.2, 0.35, 1.0), Color(0.2, 0.5, 0.9, 0.6))
	container.add_child(range_panel)


func render_weights_table(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	area.add_child(container)

	var weights := [128, 64, 32, 16, 8, 4, 2, 1]
	var exps := ["2⁷", "2⁶", "2⁵", "2⁴", "2³", "2²", "2¹", "2⁰"]

	container.add_child(_make_table_row_bg(["Позиция", "Степень", "Вес"], true))
	for i in range(8):
		container.add_child(_make_table_row_bg(
			["Бит %d" % (7 - i), exps[i], str(weights[i])],
			false
		))


func render_bit_grid(area: Control, step: Dictionary) -> void:
	var bits: Array = step.get("bits", [1, 0, 1, 0, 1, 0, 1, 0])
	var weights := [128, 64, 32, 16, 8, 4, 2, 1]
	var total := 0
	for i in range(8):
		if bits[i] == 1:
			total += weights[i]

	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	area.add_child(container)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_child(row)

	for i in range(8):
		var cell := PanelContainer.new()
		cell.custom_minimum_size = Vector2(38, 0)
		var cs := StyleBoxFlat.new()
		cs.corner_radius_top_left = 6
		cs.corner_radius_top_right = 6
		cs.corner_radius_bottom_left = 6
		cs.corner_radius_bottom_right = 6
		cs.content_margin_left = 4
		cs.content_margin_right = 4
		cs.content_margin_top = 5
		cs.content_margin_bottom = 5
		cs.set_border_width_all(1)
		if bits[i] == 1:
			cs.bg_color = Color(0.08, 0.24, 0.16, 1.0)
			cs.border_color = Color(0.15, 0.8, 0.5, 1.0)
		else:
			cs.bg_color = Color(0.09, 0.09, 0.14, 1.0)
			cs.border_color = Color(0.22, 0.22, 0.32, 1.0)
		cell.add_theme_stylebox_override("panel", cs)
		row.add_child(cell)

		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 1)
		cell.add_child(cv)

		var bit_lbl := Label.new()
		bit_lbl.text = str(bits[i])
		bit_lbl.add_theme_font_size_override("font_size", 22)
		bit_lbl.add_theme_color_override("font_color",
			Color(0.2, 1.0, 0.65, 1.0) if bits[i] == 1 else Color(0.3, 0.3, 0.42, 1.0))
		bit_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cv.add_child(bit_lbl)

		var exp_lbl := Label.new()
		exp_lbl.text = "2^%d" % (7 - i)
		exp_lbl.add_theme_font_size_override("font_size", 9)
		exp_lbl.add_theme_color_override("font_color", Color(0.38, 0.38, 0.52, 1.0))
		exp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cv.add_child(exp_lbl)

		var w_lbl := Label.new()
		w_lbl.text = str(weights[i])
		w_lbl.add_theme_font_size_override("font_size", 11)
		w_lbl.add_theme_color_override("font_color",
			Color(0.15, 0.85, 0.55, 1.0) if bits[i] == 1 else Color(0.25, 0.25, 0.38, 1.0))
		w_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cv.add_child(w_lbl)

	var parts: PackedStringArray = []
	for i in range(8):
		if bits[i] == 1:
			parts.append(str(weights[i]))
	var expr := " + ".join(parts) if parts.size() > 0 else "0"
	var calc_panel := _make_info_panel(expr + " = %d₁₀" % total, Color(0.08, 0.18, 0.12, 1.0), Color(0.2, 0.65, 0.42, 0.7))
	container.add_child(calc_panel)


func render_ranges_table(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	area.add_child(container)

	var data := [
		["4 бита", "2⁴ = 16", "0 … 15"],
		["8 бит", "2⁸ = 256", "0 … 255"],
		["16 бит", "2¹⁶ = 65536", "0 … 65535"],
		["32 бита", "2³² ≈ 4,3 млрд", "0 … 4 294 967 295"],
	]
	container.add_child(_make_table_row_bg(["Размер", "Значений", "Диапазон"], true))
	for row_data in data:
		container.add_child(_make_table_row_bg(row_data, false))


func render_quest_preview(area: Control, _step: Dictionary) -> void:
	var panel := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.07, 0.12, 0.18, 1.0)
	ps.border_color = Color(0.2, 0.5, 0.8, 0.6)
	ps.set_border_width_all(1)
	ps.corner_radius_top_left = 10
	ps.corner_radius_top_right = 10
	ps.corner_radius_bottom_left = 10
	ps.corner_radius_bottom_right = 10
	ps.content_margin_left = 14
	ps.content_margin_right = 14
	ps.content_margin_top = 12
	ps.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", ps)
	area.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.text = "🔓 ДЕШИФРАТОР — Уровень A"
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Color(0.4, 0.75, 1.0, 1.0))
	vbox.add_child(title_lbl)

	for hint in [
		"📥 Тебе дадут двоичный код",
		"🧮 Ты переводишь его в число",
		"🔍 Число расшифровывает символ",
		"✅ Верная цепочка = раскрытое дело",
	]:
		var hint_lbl := Label.new()
		hint_lbl.text = hint
		hint_lbl.add_theme_font_size_override("font_size", 13)
		hint_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85, 1.0))
		hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(hint_lbl)


# ═══════════════════════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════════════════════

func _make_info_panel(text: String, bg: Color, border: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = bg
	ps.border_color = border
	ps.set_border_width_all(1)
	ps.corner_radius_top_left = 6
	ps.corner_radius_top_right = 6
	ps.corner_radius_bottom_left = 6
	ps.corner_radius_bottom_right = 6
	ps.content_margin_left = 12
	ps.content_margin_right = 12
	ps.content_margin_top = 8
	ps.content_margin_bottom = 8
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
		cs.bg_color = Color(0.10, 0.12, 0.20, 1.0) if is_header else Color(0.07, 0.08, 0.12, 1.0)
		cs.border_color = Color(0.22, 0.35, 0.55, 0.7) if is_header else Color(0.15, 0.15, 0.22, 0.5)
		cs.set_border_width_all(1)
		cs.corner_radius_top_left = 4
		cs.corner_radius_top_right = 4
		cs.corner_radius_bottom_left = 4
		cs.corner_radius_bottom_right = 4
		cs.content_margin_left = 8
		cs.content_margin_right = 8
		cs.content_margin_top = 6
		cs.content_margin_bottom = 6
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
	if current_step_index >= tutorial_steps.size() - 1:
		return 3
	elif current_step_index >= tutorial_steps.size() / 2:
		return 2
	return 1
