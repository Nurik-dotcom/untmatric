extends "res://scenes/Tutorial/TutorialBase.gd"
# TutorialXOR.gd — XOR-шифрование
# Готовит к: MatrixDecryptor (уровень C), Decryptor B

class_name TutorialXOR

func _initialize_tutorial() -> void:
	tutorial_id = "xor_cipher"
	tutorial_title = "XOR-шифрование"
	linked_quest_scene = "res://scenes/MatrixDecryptor.tscn"

	tutorial_steps = [
		{
			"text": "XOR (eXclusive OR) — исключающее ИЛИ.\n\nПравило: результат 1 если биты РАЗНЫЕ, 0 если ОДИНАКОВЫЕ.\n\n0 XOR 0 = 0\n0 XOR 1 = 1\n1 XOR 0 = 1\n1 XOR 1 = 0\n\nГлавное свойство XOR-шифрования:\n(A XOR K) XOR K = A\n\nЗашифровал ключом K → расшифровал тем же ключом K.",
			"render_func": "render_xor_truth_table",
		},
		{
			"text": "Побитовый XOR двух чисел:\n\nВыполняется поразрядно — XOR каждой пары битов.\n\nПример: 13 XOR 10\n\n  13 = 1101\n  10 = 1010\n  ----------\nXOR  = 0111 = 7\n\nЭто основа большинства шифров — быстро, просто, обратимо.",
			"render_func": "render_bitwise_xor",
			"a": 13,
			"b": 10,
			"result": 7,
		},
		{
			"text": "XOR-шифрование текста:\n\nОткрытый текст: 'A' = 65 = 01000001\nКлюч:           'K' = 75 = 01001011\n\nXOR побитово:\n01000001\nXOR\n01001011\n--------\n00001010 = 10 (зашифрованный символ)\n\nРасшифровка: 10 XOR 75 = 65 = 'A'\n\nТот же ключ — тот же результат.",
			"render_func": "render_xor_encrypt",
			"plaintext": 65,
			"key": 75,
			"ciphertext": 10,
		},
		{
			"text": "Многобайтовый XOR — ключ повторяется:\n\nСообщение: 'HELLO' = [72, 69, 76, 76, 79]\nКлюч:       'AB'   = [65, 66]\n\nШифрование (ключ зацикливается):\n72 XOR 65 = 25\n69 XOR 66 = 7\n76 XOR 65 = 13\n76 XOR 66 = 14\n79 XOR 65 = 14\n\nЗашифровано: [25, 7, 13, 14, 14]\n\nТот же ключ [65, 66] расшифрует обратно.",
			"render_func": "render_multi_xor",
			"message": [72, 69, 76, 76, 79],
			"key": [65, 66],
			"encrypted": [25, 7, 13, 14, 14],
		},
		{
			"text": "Почему XOR используется в криптографии?\n\n✅ Скорость: одна операция на процессоре\n✅ Обратимость: один и тот же ключ для шифр./дешифр.\n✅ Простота реализации\n✅ При правильном ключе (одноразовый блокнот) — абсолютно стойкий\n\n⚠️ Слабость: если ключ короткий и повторяется — уязвим к частотному анализу.\n\nXOR лежит в основе AES, ChaCha20 и других современных шифров.",
			"render_func": "render_xor_properties",
		},
		{
			"text": "Типичная задача ЕНТ:\n\n«Число A зашифровано XOR с ключом K = 42. Получилось B = 57. Найти A.»\n\nРешение: A = B XOR K = 57 XOR 42\n\n57 = 00111001\n42 = 00101010\nXOR= 00010011 = 19\n\nA = 19\n\nПроверка: 19 XOR 42 = 57 ✓\n\nПравило: неважно что зашифровано — для нахождения A достаточно B XOR K.",
			"render_func": "render_ent_xor_task",
			"b_val": 57,
			"key": 42,
			"a_val": 19,
		},
		{
			"text": "В квесте MatrixDecryptor (уровень C):\n\n• Матрица содержит XOR-зашифрованные байты\n• Ты знаешь ключ (из предыдущих квестов)\n• Каждый байт: зашифрованный XOR ключ = открытый\n• Открытые байты → ASCII символы → сообщение\n\nЦепочка: матрица → XOR → DEC → ASCII → текст",
			"render_func": "render_quest_preview_xor",
		},
	]


# ══════════════════════════════════════════════════════════════
# RENDER FUNCTIONS
# ══════════════════════════════════════════════════════════════

func render_xor_truth_table(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var header_panel := PanelContainer.new()
	var hp := StyleBoxFlat.new()
	hp.bg_color = Color(0.08, 0.06, 0.20, 1.0)
	hp.border_color = Color(0.50, 0.25, 0.90, 0.8)
	hp.set_border_width_all(2)
	hp.corner_radius_top_left = 10; hp.corner_radius_top_right = 10
	hp.corner_radius_bottom_left = 10; hp.corner_radius_bottom_right = 10
	hp.content_margin_left = 14; hp.content_margin_right = 14
	hp.content_margin_top = 10; hp.content_margin_bottom = 10
	header_panel.add_theme_stylebox_override("panel", hp)
	container.add_child(header_panel)
	var htitle := Label.new()
	htitle.text = "XOR — таблица истинности"
	htitle.add_theme_font_size_override("font_size", 18)
	htitle.add_theme_color_override("font_color", Color(0.75, 0.50, 1.00, 1.0))
	htitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_panel.add_child(htitle)

	var table := VBoxContainer.new()
	table.add_theme_constant_override("separation", 4)
	container.add_child(table)

	table.add_child(_make_table_row_bg(["A", "B", "A XOR B", "Объяснение"], true))
	var rows := [
		[0, 0, 0, "Одинаковые → 0"],
		[0, 1, 1, "Разные → 1"],
		[1, 0, 1, "Разные → 1"],
		[1, 1, 0, "Одинаковые → 0"],
	]
	for r in rows:
		var row_hb := HBoxContainer.new()
		row_hb.add_theme_constant_override("separation", 4)
		table.add_child(row_hb)
		for j in range(4):
			var cell := PanelContainer.new()
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var cs := StyleBoxFlat.new()
			var is_result: bool = j == 2
			var val: int = r[j] if j < 3 else 0
			if is_result and val == 1:
				cs.bg_color = Color(0.06, 0.20, 0.10, 1.0)
				cs.border_color = Color(0.20, 0.70, 0.40, 0.8)
			elif is_result:
				cs.bg_color = Color(0.14, 0.06, 0.06, 1.0)
				cs.border_color = Color(0.55, 0.18, 0.18, 0.7)
			else:
				cs.bg_color = Color(0.07, 0.08, 0.12, 1.0)
				cs.border_color = Color(0.25, 0.25, 0.38, 0.5)
			cs.set_border_width_all(1)
			cs.corner_radius_top_left = 4; cs.corner_radius_top_right = 4
			cs.corner_radius_bottom_left = 4; cs.corner_radius_bottom_right = 4
			cs.content_margin_left = 8; cs.content_margin_right = 8
			cs.content_margin_top = 7; cs.content_margin_bottom = 7
			cell.add_theme_stylebox_override("panel", cs)
			row_hb.add_child(cell)
			var lbl := Label.new()
			lbl.text = str(r[j])
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.add_theme_font_size_override("font_size", 14 if j < 3 else 12)
			if is_result:
				lbl.add_theme_color_override("font_color",
					Color(0.25, 0.90, 0.55, 1.0) if val == 1 else Color(0.90, 0.30, 0.30, 1.0))
			else:
				lbl.add_theme_color_override("font_color", Color(0.80, 0.80, 0.90, 1.0))
			cell.add_child(lbl)


func render_bitwise_xor(area: Control, step: Dictionary) -> void:
	var a: int      = step.get("a", 13)
	var b: int      = step.get("b", 10)
	var result: int = step.get("result", 7)

	var bit_count: int = 4
	var a_bits: Array = _to_bits(a, bit_count)
	var b_bits: Array = _to_bits(b, bit_count)
	var r_bits: Array = _to_bits(result, bit_count)

	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 6)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	for row_data in [
		{"label": "%d =" % a, "bits": a_bits, "col": Color(0.35, 0.70, 1.00, 1.0)},
		{"label": "%d =" % b, "bits": b_bits, "col": Color(0.20, 0.85, 0.55, 1.0)},
	]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		container.add_child(row)
		var lbl := Label.new()
		lbl.text = row_data["label"]
		lbl.add_theme_font_size_override("font_size", 16)
		lbl.add_theme_color_override("font_color", row_data["col"])
		lbl.custom_minimum_size = Vector2(52, 0)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(lbl)
		for bit in row_data["bits"]:
			row.add_child(_bit_cell(bit, row_data["col"]))

	var sep_lbl := Label.new()
	sep_lbl.text = "XOR ─────────────"
	sep_lbl.add_theme_font_size_override("font_size", 13)
	sep_lbl.add_theme_color_override("font_color", Color(0.75, 0.50, 1.00, 1.0))
	sep_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(sep_lbl)

	var result_row := HBoxContainer.new()
	result_row.add_theme_constant_override("separation", 8)
	result_row.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_child(result_row)
	var rlbl := Label.new()
	rlbl.text = "%d =" % result
	rlbl.add_theme_font_size_override("font_size", 16)
	rlbl.add_theme_color_override("font_color", Color(0.90, 0.82, 0.25, 1.0))
	rlbl.custom_minimum_size = Vector2(52, 0)
	rlbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	result_row.add_child(rlbl)
	for bit in r_bits:
		result_row.add_child(_bit_cell(bit, Color(0.90, 0.82, 0.25, 1.0)))


func render_xor_encrypt(area: Control, step: Dictionary) -> void:
	var plain: int  = step.get("plaintext", 65)
	var key: int    = step.get("key", 75)
	var cipher: int = step.get("ciphertext", 10)

	var p_bits := _to_bits(plain, 8)
	var k_bits := _to_bits(key, 8)
	var c_bits := _to_bits(cipher, 8)

	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 6)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	for row_data in [
		{"label": "Текст '%s' (%d):" % [char(plain), plain], "bits": p_bits, "col": Color(0.35, 0.70, 1.00, 1.0)},
		{"label": "Ключ  '%s' (%d):" % [char(key), key],    "bits": k_bits, "col": Color(0.20, 0.85, 0.55, 1.0)},
	]:
		var lbl := Label.new()
		lbl.text = row_data["label"]
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", row_data["col"])
		container.add_child(lbl)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		container.add_child(row)
		for bit in row_data["bits"]:
			row.add_child(_bit_cell(bit, row_data["col"]))

	var xor_lbl := Label.new()
	xor_lbl.text = "XOR ══════════════"
	xor_lbl.add_theme_color_override("font_color", Color(0.75, 0.50, 1.00, 1.0))
	xor_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(xor_lbl)

	var res_lbl := Label.new()
	res_lbl.text = "Шифр (%d):" % cipher
	res_lbl.add_theme_font_size_override("font_size", 12)
	res_lbl.add_theme_color_override("font_color", Color(0.90, 0.82, 0.25, 1.0))
	container.add_child(res_lbl)

	var res_row := HBoxContainer.new()
	res_row.add_theme_constant_override("separation", 3)
	res_row.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_child(res_row)
	for bit in c_bits:
		res_row.add_child(_bit_cell(bit, Color(0.90, 0.82, 0.25, 1.0)))

	area.add_child(_make_info_panel(
		"'%s'(%d) XOR '%s'(%d) = %d  →  расшифровка: %d XOR %d = %d" % [
			char(plain), plain, char(key), key, cipher, cipher, key, plain],
		Color(0.08, 0.18, 0.12, 1.0), Color(0.20, 0.65, 0.42, 0.7)))


func render_multi_xor(area: Control, step: Dictionary) -> void:
	var message: Array   = step.get("message",   [72, 69, 76, 76, 79])
	var key: Array       = step.get("key",        [65, 66])
	var encrypted: Array = step.get("encrypted",  [25, 7, 13, 14, 14])

	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	container.add_child(_make_table_row_bg(["Символ", "DEC", "Ключ", "Ключ DEC", "XOR"], true))
	var msg_chars: Array[String] = ["H", "E", "L", "L", "O"]
	var key_chars: Array[String] = ["A", "B"]
	for i in range(message.size()):
		var ki: int = i % key.size()
		container.add_child(_make_table_row_bg([
			"'%s'" % msg_chars[i],
			str(message[i]),
			"'%s'" % key_chars[ki],
			str(key[ki]),
			str(encrypted[i])
		], false))


func render_xor_properties(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 6)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	for prop in [
		["✅ Обратимость",     "(A XOR K) XOR K = A",         Color(0.20, 0.85, 0.55, 1.0)],
		["✅ Коммутативность", "A XOR B = B XOR A",            Color(0.35, 0.70, 1.00, 1.0)],
		["✅ Ассоциативность", "(A XOR B) XOR C = A XOR (B XOR C)", Color(0.60, 0.85, 1.00, 1.0)],
		["✅ XOR с нулём",     "A XOR 0 = A",                 Color(0.80, 0.60, 0.20, 1.0)],
		["✅ XOR с собой",     "A XOR A = 0",                 Color(0.80, 0.50, 1.00, 1.0)],
	]:
		var panel := PanelContainer.new()
		var ps := StyleBoxFlat.new()
		ps.bg_color = prop[2] * Color(1, 1, 1, 0.09)
		ps.border_color = prop[2]
		ps.set_border_width_all(1)
		ps.corner_radius_top_left = 6; ps.corner_radius_top_right = 6
		ps.corner_radius_bottom_left = 6; ps.corner_radius_bottom_right = 6
		ps.content_margin_left = 12; ps.content_margin_right = 12
		ps.content_margin_top = 7; ps.content_margin_bottom = 7
		panel.add_theme_stylebox_override("panel", ps)
		container.add_child(panel)

		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 12)
		panel.add_child(hb)

		var name_lbl := Label.new()
		name_lbl.text = prop[0]
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.add_theme_color_override("font_color", prop[2])
		name_lbl.custom_minimum_size = Vector2(160, 0)
		hb.add_child(name_lbl)

		var formula_lbl := Label.new()
		formula_lbl.text = prop[1]
		formula_lbl.add_theme_font_size_override("font_size", 13)
		formula_lbl.add_theme_color_override("font_color", Color(0.78, 0.78, 0.88, 1.0))
		hb.add_child(formula_lbl)


func render_ent_xor_task(area: Control, step: Dictionary) -> void:
	var b_val: int = step.get("b_val", 57)
	var key: int   = step.get("key",   42)
	var a_val: int = step.get("a_val", 19)

	var b_bits := _to_bits(b_val, 8)
	var k_bits := _to_bits(key, 8)
	var a_bits := _to_bits(a_val, 8)

	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 6)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	for row_data in [
		{"label": "Шифр B = %d:" % b_val, "bits": b_bits, "col": Color(0.90, 0.55, 0.20, 1.0)},
		{"label": "Ключ K = %d:" % key,   "bits": k_bits, "col": Color(0.35, 0.70, 1.00, 1.0)},
	]:
		var lbl := Label.new()
		lbl.text = row_data["label"]
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", row_data["col"])
		container.add_child(lbl)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		container.add_child(row)
		for bit in row_data["bits"]:
			row.add_child(_bit_cell(bit, row_data["col"]))

	var xor_lbl := Label.new()
	xor_lbl.text = "XOR ══════════════"
	xor_lbl.add_theme_color_override("font_color", Color(0.75, 0.50, 1.00, 1.0))
	xor_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(xor_lbl)

	var rlbl := Label.new()
	rlbl.text = "A = %d:" % a_val
	rlbl.add_theme_font_size_override("font_size", 12)
	rlbl.add_theme_color_override("font_color", Color(0.20, 0.85, 0.55, 1.0))
	container.add_child(rlbl)
	var rrow := HBoxContainer.new()
	rrow.add_theme_constant_override("separation", 3)
	rrow.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_child(rrow)
	for bit in a_bits:
		rrow.add_child(_bit_cell(bit, Color(0.20, 0.85, 0.55, 1.0)))

	area.add_child(_make_info_panel("A = %d XOR %d = %d" % [b_val, key, a_val],
		Color(0.08, 0.18, 0.12, 1.0), Color(0.20, 0.65, 0.42, 0.7)))


func render_quest_preview_xor(area: Control, _step: Dictionary) -> void:
	var panel := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.08, 0.06, 0.18, 1.0)
	ps.border_color = Color(0.50, 0.25, 0.90, 0.6)
	ps.set_border_width_all(1)
	ps.corner_radius_top_left = 10; ps.corner_radius_top_right = 10
	ps.corner_radius_bottom_left = 10; ps.corner_radius_bottom_right = 10
	ps.content_margin_left = 14; ps.content_margin_right = 14
	ps.content_margin_top = 12; ps.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", ps)
	area.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)

	var title := Label.new()
	title.text = "МАТРИЦА-ДЕШИФРАТОР — Уровень C"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.75, 0.50, 1.00, 1.0))
	vb.add_child(title)

	for hint in [
		"Матрица → находишь скрытые числа",
		"Каждое число XOR ключ = открытый байт",
		"Открытый байт → ASCII символ",
		"Собираешь символы → секретное сообщение",
	]:
		var lbl := Label.new()
		lbl.text = hint
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85, 1.0))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		vb.add_child(lbl)


# ══════════════════════════════════════════════════════════════
# HELPERS
# ══════════════════════════════════════════════════════════════

func _to_bits(value: int, count: int) -> Array:
	var bits: Array = []
	for i in range(count - 1, -1, -1):
		bits.append((value >> i) & 1)
	return bits

func _bit_cell(bit: int, col: Color) -> PanelContainer:
	var cell := PanelContainer.new()
	cell.custom_minimum_size = Vector2(28, 30)
	var cs := StyleBoxFlat.new()
	cs.bg_color     = col * Color(1, 1, 1, 0.15) if bit == 1 else Color(0.09, 0.09, 0.14, 1.0)
	cs.border_color = col if bit == 1 else Color(0.22, 0.22, 0.32, 1.0)
	cs.set_border_width_all(1)
	cs.corner_radius_top_left = 4; cs.corner_radius_top_right = 4
	cs.corner_radius_bottom_left = 4; cs.corner_radius_bottom_right = 4
	cell.add_theme_stylebox_override("panel", cs)
	var lbl := Label.new()
	lbl.text = str(bit)
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", col if bit == 1 else Color(0.30, 0.30, 0.42, 1.0))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cell.add_child(lbl)
	return cell

func _make_info_panel(text: String, bg: Color, border: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = bg; ps.border_color = border
	ps.set_border_width_all(1)
	ps.corner_radius_top_left = 6; ps.corner_radius_top_right = 6
	ps.corner_radius_bottom_left = 6; ps.corner_radius_bottom_right = 6
	ps.content_margin_left = 12; ps.content_margin_right = 12
	ps.content_margin_top = 8; ps.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", ps)
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 14)
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
		cs.corner_radius_top_left = 4; cs.corner_radius_top_right = 4
		cs.corner_radius_bottom_left = 4; cs.corner_radius_bottom_right = 4
		cs.content_margin_left = 8; cs.content_margin_right = 8
		cs.content_margin_top = 6; cs.content_margin_bottom = 6
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
