extends "res://scenes/Tutorial/TutorialBase.gd"
# TutorialIPAddress.gd — IP-адресация IPv4
# Готовит к: NetworkTrace A/B

class_name TutorialIPAddress

func _initialize_tutorial() -> void:
	tutorial_id = "net_ip"
	tutorial_title = "IP-адресация"
	linked_quest_scene = "res://scenes/NetworkTraceQuestA.tscn"

	tutorial_steps = [
		{
			"text": "IP-адрес (Internet Protocol address) — уникальный адрес каждого устройства в сети.\n\nIPv4: четыре числа от 0 до 255, разделённые точками.\nПример: 192.168.1.1\n\nКаждое число — это один байт (8 бит).\nВсего: 4 байта = 32 бита.\n\nПолный диапазон IPv4: от 0.0.0.0 до 255.255.255.255 — около 4 миллиардов адресов.",
			"render_func": "render_ip_structure",
			"ip": [192, 168, 1, 1],
		},
		{
			"text": "IP-адрес делится на две части:\n\n• Сетевая часть — определяет сеть (как улица)\n• Хостовая часть — определяет устройство (как номер дома)\n\nГде заканчивается сеть и начинается хост — задаёт маска подсети.\n\nПример: 192.168.1.55/24\n• Маска /24 = первые 24 бита — сеть\n• Оставшиеся 8 бит — хост (0–255)",
			"render_func": "render_ip_split",
			"ip": [192, 168, 1, 55],
			"mask_bits": 24,
		},
		{
			"text": "Классы IP-адресов (старая система, но ЕНТ спрашивает):\n\nКласс A: 1–126.x.x.x  → маска 255.0.0.0 (/8)\nКласс B: 128–191.x.x.x → маска 255.255.0.0 (/16)\nКласс C: 192–223.x.x.x → маска 255.255.255.0 (/24)\n\nПо первому октету (числу до первой точки) можно определить класс.\n\nЗапомни диапазоны: A<128, B<192, C<224.",
			"render_func": "render_ip_classes",
		},
		{
			"text": "Специальные адреса — важны для ЕНТ:\n\n127.0.0.1 — loopback (сам компьютер, «localhost»)\n\n192.168.x.x — частная сеть класса C (домашние сети)\n10.x.x.x   — частная сеть класса A (корпоративные)\n172.16-31.x.x — частная сеть класса B\n\n255.255.255.255 — широковещательный адрес (broadcast)\n0.0.0.0         — «неизвестный адрес»\n\nЧастные адреса не маршрутизируются в интернете.",
			"render_func": "render_special_ips",
		},
		{
			"text": "Маска подсети — определяет границу сети/хоста.\n\n255.255.255.0 = /24 = 11111111.11111111.11111111.00000000\n\nЕдиницы в маске → биты сети\nНули в маске → биты хоста\n\nПодсчёт хостов: 2^(биты хоста) − 2\n(минус 2: один адрес сети, один broadcast)\n\nДля /24: 2^8 − 2 = 254 хоста",
			"render_func": "render_subnet_mask",
			"mask_bits": 24,
		},
		{
			"text": "Вычисление адреса сети:\n\nАдрес устройства: 192.168.1.55\nМаска:            255.255.255.0\n\nОперация: IP AND маска = адрес сети\n\n192 AND 255 = 192\n168 AND 255 = 168\n  1 AND 255 = 1\n 55 AND   0 = 0\n\nАдрес сети: 192.168.1.0\nBroadcast:  192.168.1.255\nХосты:      192.168.1.1 — 192.168.1.254",
			"render_func": "render_network_calc",
			"ip": [192, 168, 1, 55],
			"mask": [255, 255, 255, 0],
			"network": [192, 168, 1, 0],
			"broadcast": [192, 168, 1, 255],
		},
		{
			"text": "Задача ЕНТ на принадлежность сети:\n\n«Устройство A: 10.0.0.5/8, устройство B: 10.0.1.3/8. Они в одной сети?»\n\nМаска /8 = 255.0.0.0\nСеть A: 10.0.0.5 AND 255.0.0.0 = 10.0.0.0\nСеть B: 10.0.1.3 AND 255.0.0.0 = 10.0.0.0\n\nОба в сети 10.0.0.0 → ДА, в одной сети.\n\nПравило: если после AND маской оба адреса дают одинаковый результат — они в одной сети.",
			"render_func": "render_same_network_check",
		},
	]


# ══════════════════════════════════════════════════════════════
# RENDER FUNCTIONS
# ══════════════════════════════════════════════════════════════

func render_ip_structure(area: Control, step: Dictionary) -> void:
	var ip: Array = step.get("ip", [192, 168, 1, 1])
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	area.add_child(row)

	var oct_cols := [
		Color(0.35, 0.70, 1.00, 1.0),
		Color(0.20, 0.85, 0.55, 1.0),
		Color(0.80, 0.60, 0.20, 1.0),
		Color(0.80, 0.35, 0.80, 1.0),
	]
	for i in range(4):
		var cell := PanelContainer.new()
		cell.custom_minimum_size = Vector2(68, 0)
		var cs := StyleBoxFlat.new()
		cs.bg_color = oct_cols[i] * Color(1, 1, 1, 0.12)
		cs.border_color = oct_cols[i]
		cs.set_border_width_all(2)
		cs.corner_radius_top_left    = 8; cs.corner_radius_top_right   = 8
		cs.corner_radius_bottom_left = 8; cs.corner_radius_bottom_right = 8
		cs.content_margin_left = 8; cs.content_margin_right = 8
		cs.content_margin_top  = 8; cs.content_margin_bottom = 8
		cell.add_theme_stylebox_override("panel", cs)
		row.add_child(cell)

		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 3)
		cell.add_child(vb)

		var val_lbl := Label.new()
		val_lbl.text = str(ip[i])
		val_lbl.add_theme_font_size_override("font_size", 28)
		val_lbl.add_theme_color_override("font_color", oct_cols[i])
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(val_lbl)

		var oct_lbl := Label.new()
		oct_lbl.text = "октет %d\n8 бит" % (i + 1)
		oct_lbl.add_theme_font_size_override("font_size", 10)
		oct_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.70, 1.0))
		oct_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(oct_lbl)

		if i < 3:
			var dot_lbl := Label.new()
			dot_lbl.text = "·"
			dot_lbl.add_theme_font_size_override("font_size", 30)
			dot_lbl.add_theme_color_override("font_color", Color(0.50, 0.50, 0.65, 1.0))
			dot_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			row.add_child(dot_lbl)


func render_ip_split(area: Control, step: Dictionary) -> void:
	var ip: Array     = step.get("ip", [192, 168, 1, 55])
	var mask_b: int   = step.get("mask_bits", 24)
	var net_octs: int = mask_b / 8
	var host_octs: int = 4 - net_octs

	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var ip_row := HBoxContainer.new()
	ip_row.add_theme_constant_override("separation", 4)
	ip_row.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_child(ip_row)

	for i in range(4):
		var is_net: bool = i < net_octs
		var cell := PanelContainer.new()
		cell.custom_minimum_size = Vector2(60, 0)
		var cs := StyleBoxFlat.new()
		cs.bg_color = Color(0.06, 0.16, 0.24, 1.0) if is_net else Color(0.18, 0.08, 0.06, 1.0)
		cs.border_color = Color(0.20, 0.55, 0.88, 0.9) if is_net else Color(0.85, 0.35, 0.18, 0.9)
		cs.set_border_width_all(2)
		cs.corner_radius_top_left    = 6; cs.corner_radius_top_right   = 6
		cs.corner_radius_bottom_left = 6; cs.corner_radius_bottom_right = 6
		cs.content_margin_left = 6; cs.content_margin_right = 6
		cs.content_margin_top  = 6; cs.content_margin_bottom = 6
		cell.add_theme_stylebox_override("panel", cs)
		ip_row.add_child(cell)

		var vb := VBoxContainer.new()
		cell.add_child(vb)
		var num := Label.new()
		num.text = str(ip[i])
		num.add_theme_font_size_override("font_size", 22)
		num.add_theme_color_override("font_color",
			Color(0.35, 0.75, 1.00, 1.0) if is_net else Color(1.00, 0.55, 0.25, 1.0))
		num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(num)

		var part := Label.new()
		part.text = "сеть" if is_net else "хост"
		part.add_theme_font_size_override("font_size", 10)
		part.add_theme_color_override("font_color", Color(0.50, 0.50, 0.65, 1.0))
		part.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(part)

		if i < 3:
			var dot := Label.new()
			dot.text = "."
			dot.add_theme_color_override("font_color", Color(0.45, 0.45, 0.60, 1.0))
			dot.add_theme_font_size_override("font_size", 22)
			dot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			ip_row.add_child(dot)

	area.add_child(_make_info_panel(
		"/%d: %d октетов сети, %d октет(а) хоста" % [mask_b, net_octs, host_octs],
		Color(0.08, 0.14, 0.22, 1.0), Color(0.20, 0.50, 0.82, 0.7)))


func render_ip_classes(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 5)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var data := [
		["A", "1–126.x.x.x",   "/8",  "255.0.0.0",     "16M сетей, 16M хостов", Color(0.35, 0.70, 1.00, 1.0)],
		["B", "128–191.x.x.x", "/16", "255.255.0.0",   "65K сетей, 65K хостов", Color(0.20, 0.85, 0.55, 1.0)],
		["C", "192–223.x.x.x", "/24", "255.255.255.0", "2M сетей, 254 хоста",   Color(0.80, 0.60, 0.20, 1.0)],
	]
	for row_data in data:
		var panel := PanelContainer.new()
		var ps := StyleBoxFlat.new()
		ps.bg_color = row_data[5] * Color(1, 1, 1, 0.10)
		ps.border_color = row_data[5]
		ps.set_border_width_all(1)
		ps.corner_radius_top_left    = 8; ps.corner_radius_top_right   = 8
		ps.corner_radius_bottom_left = 8; ps.corner_radius_bottom_right = 8
		ps.content_margin_left = 12; ps.content_margin_right = 12
		ps.content_margin_top  = 7;  ps.content_margin_bottom = 7
		panel.add_theme_stylebox_override("panel", ps)
		container.add_child(panel)

		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 8)
		panel.add_child(hb)

		var class_lbl := Label.new()
		class_lbl.text = "Класс %s" % row_data[0]
		class_lbl.add_theme_font_size_override("font_size", 16)
		class_lbl.add_theme_color_override("font_color", row_data[5])
		class_lbl.custom_minimum_size = Vector2(80, 0)
		hb.add_child(class_lbl)

		var range_lbl := Label.new()
		range_lbl.text = row_data[1]
		range_lbl.add_theme_font_size_override("font_size", 13)
		range_lbl.add_theme_color_override("font_color", Color(0.80, 0.80, 0.90, 1.0))
		range_lbl.custom_minimum_size = Vector2(110, 0)
		hb.add_child(range_lbl)

		var mask_lbl := Label.new()
		mask_lbl.text = row_data[2]
		mask_lbl.add_theme_font_size_override("font_size", 14)
		mask_lbl.add_theme_color_override("font_color", row_data[5])
		hb.add_child(mask_lbl)


func render_special_ips(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var data := [
		["127.0.0.1",        "Loopback (localhost)", Color(0.80, 0.50, 1.00, 1.0)],
		["192.168.0.0/16",   "Частная сеть (класс C)", Color(0.20, 0.85, 0.55, 1.0)],
		["10.0.0.0/8",       "Частная сеть (класс A)", Color(0.35, 0.70, 1.00, 1.0)],
		["172.16.0.0/12",    "Частная сеть (класс B)", Color(0.60, 0.85, 1.00, 1.0)],
		["255.255.255.255",  "Broadcast (всем)", Color(0.90, 0.55, 0.20, 1.0)],
		["0.0.0.0",          "Неизвестный адрес", Color(0.55, 0.55, 0.70, 1.0)],
	]
	container.add_child(_make_table_row_bg(["Адрес", "Назначение"], true))
	for row_data in data:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		container.add_child(row)
		for j in range(2):
			var cell := PanelContainer.new()
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var cs := StyleBoxFlat.new()
			cs.bg_color = row_data[2] * Color(1, 1, 1, 0.08)
			cs.border_color = row_data[2] * Color(1, 1, 1, 0.40)
			cs.set_border_width_all(1)
			cs.corner_radius_top_left    = 4; cs.corner_radius_top_right   = 4
			cs.corner_radius_bottom_left = 4; cs.corner_radius_bottom_right = 4
			cs.content_margin_left = 8; cs.content_margin_right = 8
			cs.content_margin_top  = 6; cs.content_margin_bottom = 6
			cell.add_theme_stylebox_override("panel", cs)
			row.add_child(cell)
			var lbl := Label.new()
			lbl.text = str(row_data[j])
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.add_theme_font_size_override("font_size", 13)
			lbl.add_theme_color_override("font_color", row_data[2])
			cell.add_child(lbl)


func render_subnet_mask(area: Control, step: Dictionary) -> void:
	var mask_bits: int = step.get("mask_bits", 24)
	var host_bits: int = 32 - mask_bits
	var hosts: int     = (1 << host_bits) - 2

	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	# Визуализация битов маски
	var bits_row := HBoxContainer.new()
	bits_row.add_theme_constant_override("separation", 2)
	bits_row.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_child(bits_row)

	for i in range(32):
		var is_net: bool = i < mask_bits
		var cell := PanelContainer.new()
		cell.custom_minimum_size = Vector2(16, 22)
		var cs := StyleBoxFlat.new()
		cs.bg_color = Color(0.06, 0.16, 0.24, 1.0) if is_net else Color(0.18, 0.08, 0.06, 1.0)
		cs.border_color = Color(0.20, 0.55, 0.88, 0.6) if is_net else Color(0.85, 0.35, 0.18, 0.6)
		cs.set_border_width_all(1)
		cs.corner_radius_top_left    = 2; cs.corner_radius_top_right   = 2
		cs.corner_radius_bottom_left = 2; cs.corner_radius_bottom_right = 2
		cell.add_theme_stylebox_override("panel", cs)
		bits_row.add_child(cell)

		var lbl := Label.new()
		lbl.text = "1" if is_net else "0"
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color",
			Color(0.35, 0.75, 1.00, 1.0) if is_net else Color(1.00, 0.55, 0.25, 1.0))
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(lbl)

	area.add_child(_make_info_panel(
		"/%d: %d бит сети + %d бит хоста = %d адресов (хостов: %d)" % [
			mask_bits, mask_bits, host_bits, (1 << host_bits), hosts],
		Color(0.08, 0.14, 0.22, 1.0), Color(0.20, 0.50, 0.82, 0.7)))


func render_network_calc(area: Control, step: Dictionary) -> void:
	var ip: Array        = step.get("ip",        [192, 168, 1, 55])
	var mask: Array      = step.get("mask",      [255, 255, 255, 0])
	var network: Array   = step.get("network",   [192, 168, 1, 0])
	var broadcast: Array = step.get("broadcast", [192, 168, 1, 255])

	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 6)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	container.add_child(_make_table_row_bg(["", "Октет 1", "Октет 2", "Октет 3", "Октет 4"], true))
	container.add_child(_make_table_row_bg(["IP"] + ip.map(func(x): return str(x)), false))
	container.add_child(_make_table_row_bg(["Маска"] + mask.map(func(x): return str(x)), false))
	container.add_child(_make_table_row_bg(["AND=Сеть"] + network.map(func(x): return str(x)), false))
	container.add_child(_make_table_row_bg(["Broadcast"] + broadcast.map(func(x): return str(x)), false))


func render_same_network_check(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var rows := [
		["Устройство A", "10.0.0.5", "AND 255.0.0.0", "= 10.0.0.0", Color(0.35, 0.70, 1.00, 1.0)],
		["Устройство B", "10.0.1.3", "AND 255.0.0.0", "= 10.0.0.0", Color(0.20, 0.85, 0.55, 1.0)],
	]
	for row_data in rows:
		var panel := PanelContainer.new()
		var ps := StyleBoxFlat.new()
		ps.bg_color = row_data[4] * Color(1, 1, 1, 0.10)
		ps.border_color = row_data[4]
		ps.set_border_width_all(1)
		ps.corner_radius_top_left    = 6; ps.corner_radius_top_right   = 6
		ps.corner_radius_bottom_left = 6; ps.corner_radius_bottom_right = 6
		ps.content_margin_left = 10; ps.content_margin_right = 10
		ps.content_margin_top  = 7;  ps.content_margin_bottom = 7
		panel.add_theme_stylebox_override("panel", ps)
		container.add_child(panel)

		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 8)
		panel.add_child(hb)
		for j in range(4):
			var lbl := Label.new()
			lbl.text = row_data[j]
			lbl.add_theme_font_size_override("font_size", 13)
			lbl.add_theme_color_override("font_color",
				row_data[4] if j == 3 else Color(0.78, 0.78, 0.88, 1.0))
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL if j != 0 else Control.SIZE_SHRINK_BEGIN
			if j == 0:
				lbl.custom_minimum_size = Vector2(110, 0)
			hb.add_child(lbl)

	area.add_child(_make_info_panel(
		"Оба устройства в сети 10.0.0.0 → ДА, одна сеть ✓",
		Color(0.06, 0.18, 0.10, 1.0), Color(0.18, 0.65, 0.35, 0.8)))


# ══════════════════════════════════════════════════════════════
# HELPERS
# ══════════════════════════════════════════════════════════════

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
		cs.corner_radius_top_left    = 4; cs.corner_radius_top_right   = 4
		cs.corner_radius_bottom_left = 4; cs.corner_radius_bottom_right = 4
		cs.content_margin_left = 6;  cs.content_margin_right = 6
		cs.content_margin_top  = 5;  cs.content_margin_bottom = 5
		cell.add_theme_stylebox_override("panel", cs)
		row.add_child(cell)
		var lbl := Label.new()
		lbl.text = str(val)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color",
			Color(0.5, 0.7, 1.0, 1.0) if is_header else Color(0.8, 0.8, 0.9, 1.0))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		cell.add_child(lbl)
	return row

func _calculate_stars() -> int:
	return 3 if current_step_index >= tutorial_steps.size() - 1 else 2
