extends "res://scenes/Tutorial/TutorialBase.gd"
# TutorialNetMask.gd — Маски подсетей и CIDR
# Готовит к: NetworkTrace B/C

class_name TutorialNetMask

func _initialize_tutorial() -> void:
	tutorial_id = "net_mask"
	tutorial_title = "Маски подсетей"
	linked_quest_scene = "res://scenes/NetworkTraceQuestB.tscn"

	tutorial_steps = [
		{
			"text": "Маска подсети — это 32-битное число, которое показывает какие биты IP-адреса относятся к сети, а какие к хосту.\n\nЕдиницы (1) → биты сети\nНули (0)    → биты хоста\n\nМаска всегда выглядит как блок единиц, затем блок нулей.\n255.255.255.0 = 11111111.11111111.11111111.00000000\n\nНикогда не бывает 11110111 — нули не могут быть внутри единиц.",
			"render_func": "render_mask_concept",
		},
		{
			"text": "CIDR-нотация — краткая запись маски:\n\n/N означает что первые N бит = единицы\n\n/8  = 255.0.0.0   (8 бит сети)\n/16 = 255.255.0.0  (16 бит сети)\n/24 = 255.255.255.0 (24 бита сети)\n/30 = 255.255.255.252 (30 бит сети, только 2 хоста)\n\nЧем больше число после /, тем меньше хостов в сети.",
			"render_func": "render_cidr_table",
		},
		{
			"text": "Вычисление количества хостов:\n\nФормула: 2^(32−N) − 2\nгде N — число бит в маске (CIDR)\n\nМинус 2 потому что:\n• Один адрес — адрес сети (все нули в хостовой части)\n• Один адрес — broadcast (все единицы в хостовой части)\n\nПример: /24 → 2^(32−24) − 2 = 2^8 − 2 = 256 − 2 = 254 хоста",
			"render_func": "render_hosts_calc",
		},
		{
			"text": "Вычисление адреса сети через AND:\n\nАдрес: 192.168.10.75/24\nМаска: 255.255.255.0\n\nAND каждого октета:\n192 AND 255 = 192\n168 AND 255 = 168\n 10 AND 255 = 10\n 75 AND   0 = 0\n\nАдрес сети: 192.168.10.0\nBroadcast:  192.168.10.255\nДиапазон хостов: 192.168.10.1 — 192.168.10.254",
			"render_func": "render_network_and",
			"ip": [192, 168, 10, 75],
			"mask": [255, 255, 255, 0],
			"network": [192, 168, 10, 0],
			"broadcast": [192, 168, 10, 255],
			"cidr": 24,
		},
		{
			"text": "Нестандартная маска /26:\n\n255.255.255.192 = 11111111.11111111.11111111.11000000\n\nПоследний октет: 11000000 = 192\n32 − 26 = 6 бит для хостов\n2^6 − 2 = 62 хоста\n\nАдресное пространство делится на 4 подсети:\n• .0–.63   (сеть .0,   broadcast .63)\n• .64–.127 (сеть .64,  broadcast .127)\n• .128–.191 (сеть .128, broadcast .191)\n• .192–.255 (сеть .192, broadcast .255)",
			"render_func": "render_slash26",
		},
		{
			"text": "Таблица популярных масок для ЕНТ:\n\nЗапомни /8, /16, /24, /30 — они встречаются в 90% задач.",
			"render_func": "render_mask_reference_table",
		},
		{
			"text": "Задача ЕНТ: «192.168.5.200/29. Сколько хостов? Какой адрес сети?»\n\n/29 → маска 255.255.255.248\nПоследний октет маски: 11111000 = 248\nБит хоста: 32−29 = 3 бита → 2³ − 2 = 6 хостов\n\nАдрес сети:\n200 AND 248:\n200 = 11001000\n248 = 11111000\nAND = 11001000 = 192\n\nСеть: 192.168.5.192\nBroadcast: 192.168.5.199\nХосты: 192.168.5.193 — 192.168.5.198",
			"render_func": "render_ent_mask_task",
			"ip": [192, 168, 5, 200],
			"cidr": 29,
			"mask_last": 248,
			"net_last": 192,
			"bc_last": 199,
			"hosts": 6,
		},
	]


# ══════════════════════════════════════════════════════════════
# RENDER FUNCTIONS
# ══════════════════════════════════════════════════════════════

func render_mask_concept(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var masks := [
		{"label": "/8  = 255.0.0.0",    "ones": 8,  "col": Color(0.35, 0.70, 1.00, 1.0)},
		{"label": "/16 = 255.255.0.0",  "ones": 16, "col": Color(0.20, 0.85, 0.55, 1.0)},
		{"label": "/24 = 255.255.255.0","ones": 24, "col": Color(0.80, 0.60, 0.20, 1.0)},
	]
	for m in masks:
		var lbl := Label.new()
		lbl.text = m["label"]
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", m["col"])
		container.add_child(lbl)

		var bits_row := HBoxContainer.new()
		bits_row.add_theme_constant_override("separation", 2)
		bits_row.alignment = BoxContainer.ALIGNMENT_CENTER
		container.add_child(bits_row)

		for i in range(32):
			var is_net: bool = i < m["ones"]
			var cell := PanelContainer.new()
			cell.custom_minimum_size = Vector2(14, 18)
			var cs := StyleBoxFlat.new()
			cs.bg_color     = Color(0.06, 0.16, 0.24, 1.0) if is_net else Color(0.18, 0.08, 0.06, 1.0)
			cs.border_color = m["col"] * Color(1, 1, 1, 0.6) if is_net else Color(0.85, 0.35, 0.18, 0.5)
			cs.set_border_width_all(1)
			cs.corner_radius_top_left = 2; cs.corner_radius_top_right = 2
			cs.corner_radius_bottom_left = 2; cs.corner_radius_bottom_right = 2
			cell.add_theme_stylebox_override("panel", cs)
			bits_row.add_child(cell)
			var bit_lbl := Label.new()
			bit_lbl.text = "1" if is_net else "0"
			bit_lbl.add_theme_font_size_override("font_size", 9)
			bit_lbl.add_theme_color_override("font_color",
				m["col"] if is_net else Color(1.00, 0.45, 0.20, 0.8))
			bit_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cell.add_child(bit_lbl)


func render_cidr_table(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var data := [
		["/8",  "255.0.0.0",       "16 777 214", "Класс A"],
		["/16", "255.255.0.0",     "65 534",     "Класс B"],
		["/24", "255.255.255.0",   "254",        "Класс C"],
		["/25", "255.255.255.128", "126",        "Половина C"],
		["/26", "255.255.255.192", "62",         "Четверть C"],
		["/27", "255.255.255.224", "30",         ""],
		["/28", "255.255.255.240", "14",         ""],
		["/29", "255.255.255.248", "6",          ""],
		["/30", "255.255.255.252", "2",          "P-t-P линк"],
	]
	container.add_child(_make_table_row_bg(["CIDR", "Маска", "Хостов", "Заметка"], true))
	for row_data in data:
		container.add_child(_make_table_row_bg(row_data, false))


func render_hosts_calc(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 5)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var data := [
		["/24", 8, 256, 254],
		["/25", 7, 128, 126],
		["/26", 6, 64,  62],
		["/27", 5, 32,  30],
		["/28", 4, 16,  14],
		["/29", 3, 8,   6],
		["/30", 2, 4,   2],
	]
	container.add_child(_make_table_row_bg(["Маска", "Бит хоста", "2^N", "Хостов (−2)"], true))
	for r in data:
		container.add_child(_make_table_row_bg([r[0], str(r[1]), str(r[2]), str(r[3])], false))


func render_network_and(area: Control, step: Dictionary) -> void:
	var ip: Array        = step.get("ip",        [192, 168, 10, 75])
	var mask: Array      = step.get("mask",      [255, 255, 255, 0])
	var network: Array   = step.get("network",   [192, 168, 10, 0])
	var broadcast: Array = step.get("broadcast", [192, 168, 10, 255])
	var cidr: int        = step.get("cidr",      24)

	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 6)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	container.add_child(_make_table_row_bg(["", "Окт.1", "Окт.2", "Окт.3", "Окт.4"], true))

	for row_info in [
		["IP /%d" % cidr, ip,        Color(0.35, 0.70, 1.00, 1.0)],
		["Маска",         mask,      Color(0.75, 0.75, 0.85, 1.0)],
		["AND=Сеть",      network,   Color(0.20, 0.85, 0.55, 1.0)],
		["Broadcast",     broadcast, Color(0.90, 0.55, 0.20, 1.0)],
	]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		container.add_child(row)

		var label_cell := PanelContainer.new()
		label_cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var lcs := StyleBoxFlat.new()
		lcs.bg_color = Color(0.07, 0.08, 0.12, 1.0)
		lcs.border_color = Color(0.15, 0.15, 0.22, 0.5)
		lcs.set_border_width_all(1)
		lcs.corner_radius_top_left = 4; lcs.corner_radius_top_right = 4
		lcs.corner_radius_bottom_left = 4; lcs.corner_radius_bottom_right = 4
		lcs.content_margin_left = 8; lcs.content_margin_right = 8
		lcs.content_margin_top = 6; lcs.content_margin_bottom = 6
		label_cell.add_theme_stylebox_override("panel", lcs)
		row.add_child(label_cell)
		var llbl := Label.new()
		llbl.text = str(row_info[0])
		llbl.add_theme_font_size_override("font_size", 12)
		llbl.add_theme_color_override("font_color", row_info[2])
		label_cell.add_child(llbl)

		for oct in row_info[1]:
			var cell := PanelContainer.new()
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var cs := StyleBoxFlat.new()
			cs.bg_color = Color(0.07, 0.08, 0.12, 1.0)
			cs.border_color = row_info[2] * Color(1, 1, 1, 0.40)
			cs.set_border_width_all(1)
			cs.corner_radius_top_left = 4; cs.corner_radius_top_right = 4
			cs.corner_radius_bottom_left = 4; cs.corner_radius_bottom_right = 4
			cs.content_margin_left = 6; cs.content_margin_right = 6
			cs.content_margin_top = 6; cs.content_margin_bottom = 6
			cell.add_theme_stylebox_override("panel", cs)
			row.add_child(cell)
			var lbl := Label.new()
			lbl.text = str(oct)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.add_theme_font_size_override("font_size", 14)
			lbl.add_theme_color_override("font_color", row_info[2])
			cell.add_child(lbl)


func render_slash26(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 5)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var subnets := [
		["192.168.1.0/26",   ".0",   ".63",  ".1–.62",   Color(0.35, 0.70, 1.00, 1.0)],
		["192.168.1.64/26",  ".64",  ".127", ".65–.126",  Color(0.20, 0.85, 0.55, 1.0)],
		["192.168.1.128/26", ".128", ".191", ".129–.190", Color(0.80, 0.60, 0.20, 1.0)],
		["192.168.1.192/26", ".192", ".255", ".193–.254", Color(0.80, 0.50, 1.00, 1.0)],
	]
	container.add_child(_make_table_row_bg(["Подсеть", "Сеть", "Broadcast", "Хосты"], true))
	for r in subnets:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		container.add_child(row)
		for j in range(4):
			var cell := PanelContainer.new()
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var cs := StyleBoxFlat.new()
			cs.bg_color     = r[4] * Color(1, 1, 1, 0.08)
			cs.border_color = r[4] * Color(1, 1, 1, 0.40)
			cs.set_border_width_all(1)
			cs.corner_radius_top_left = 4; cs.corner_radius_top_right = 4
			cs.corner_radius_bottom_left = 4; cs.corner_radius_bottom_right = 4
			cs.content_margin_left = 6; cs.content_margin_right = 6
			cs.content_margin_top = 6; cs.content_margin_bottom = 6
			cell.add_theme_stylebox_override("panel", cs)
			row.add_child(cell)
			var lbl := Label.new()
			lbl.text = str(r[j])
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.add_theme_font_size_override("font_size", 12)
			lbl.add_theme_color_override("font_color", r[4])
			lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
			cell.add_child(lbl)


func render_mask_reference_table(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var data := [
		["/8",  "255.0.0.0",       "16 млн", "1 октет сети"],
		["/16", "255.255.0.0",     "65 534", "2 октета сети"],
		["/24", "255.255.255.0",   "254",    "3 октета сети"],
		["/30", "255.255.255.252", "2",      "точка-точка"],
		["/32", "255.255.255.255", "0",      "один хост"],
	]
	container.add_child(_make_table_row_bg(["CIDR", "Маска", "Хостов", "Запомнить"], true))
	for row_data in data:
		container.add_child(_make_table_row_bg(row_data, false))


func render_ent_mask_task(area: Control, step: Dictionary) -> void:
	var ip: Array      = step.get("ip",       [192, 168, 5, 200])
	var cidr: int      = step.get("cidr",     29)
	var mask_last: int = step.get("mask_last",248)
	var net_last: int  = step.get("net_last", 192)
	var bc_last: int   = step.get("bc_last",  199)
	var hosts: int     = step.get("hosts",    6)

	var host_bits: int = 32 - cidr
	var ip_str: String = "%d.%d.%d.%d/%d" % [ip[0], ip[1], ip[2], ip[3], cidr]
	area.add_child(_make_info_panel("Задача: %s" % ip_str,
		Color(0.08, 0.10, 0.18, 1.0), Color(0.25, 0.38, 0.60, 0.7)))

	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	container.add_child(_make_table_row_bg(["Шаг", "Вычисление"], true))
	for row_data in [
		["Бит хоста",        "32 − %d = %d" % [cidr, host_bits]],
		["Хостов",           "2^%d − 2 = %d" % [host_bits, hosts]],
		["Маска (4й октет)", str(mask_last)],
		["Сеть (4й октет)",  "%d AND %d = %d" % [ip[3], mask_last, net_last]],
		["Broadcast",        str(bc_last)],
	]:
		container.add_child(_make_table_row_bg(row_data, false))


# ══════════════════════════════════════════════════════════════
# HELPERS
# ══════════════════════════════════════════════════════════════

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
		cs.content_margin_top = 5; cs.content_margin_bottom = 5
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
