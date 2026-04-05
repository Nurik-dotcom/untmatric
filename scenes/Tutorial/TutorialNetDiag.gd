extends "res://scenes/Tutorial/TutorialBase.gd"
# Диагностика сети: ping, tracert, ipconfig, DNS
# Готовит к: NetworkTrace C

class_name TutorialNetDiag

func _initialize_tutorial() -> void:
	tutorial_id = "net_diag"
	tutorial_title = "Диагностика сети"
	linked_quest_scene = "res://scenes/NetworkTraceQuestC.tscn"

	tutorial_steps = [
		{
			"text": "Диагностика сети — это последовательная проверка цепочки:\nПК → роутер → провайдер → интернет-сервис.\n\nЕсли идти по шагам, источник ошибки обычно находится быстро.\n\nГлавные инструменты в ЕНТ и квестах: ping, tracert/traceroute, ipconfig/ifconfig, nslookup.",
			"render_func": "render_diag_chain",
		},
		{
			"text": "Ping проверяет доступность узла и задержку.\n\nЧто смотреть:\n• Reply from ... — узел отвечает\n• Request timed out — нет ответа\n• Average time — средняя задержка\n• Packet loss — потеря пакетов\n\nПотеря > 0% уже признак проблемы.",
			"render_func": "render_ping_panel",
		},
		{
			"text": "Traceroute (tracert) показывает маршрут по хопам.\n\nКаждая строка — промежуточный маршрутизатор.\nЗвёздочки * * * означают, что хоп не ответил вовремя.\n\nЕсли маршрут рвётся на раннем хопе — проблема ближе к локальной сети.",
			"render_func": "render_traceroute_panel",
		},
		{
			"text": "ipconfig/ifconfig показывает сетевые параметры хоста:\n• IP-адрес\n• Маска\n• Шлюз\n• DNS\n\nЧастая ошибка: неверный шлюз или адрес не из той подсети.",
			"render_func": "render_ipconfig_panel",
		},
		{
			"text": "Типовые симптомы и причины:\n\n1) Пингуется шлюз, но не пингуется домен → чаще DNS\n2) Не пингуется даже шлюз → локальная сеть/кабель/Wi‑Fi\n3) Высокий ping и потери → перегрузка канала или плохой линк\n4) Домен пингуется, сайт не открывается → проблема сервиса/порта/HTTPS",
			"render_func": "render_symptoms_table",
		},
		{
			"text": "Алгоритм проверки (рабочий порядок):\n\n1) Проверить IP/маску/шлюз\n2) Ping 127.0.0.1 (локальный стек)\n3) Ping шлюза\n4) Ping внешнего IP (например 8.8.8.8)\n5) Ping домена\n6) Traceroute до домена\n\nТак ты сразу отделяешь DNS-проблемы от маршрутизации.",
			"render_func": "render_algo",
		},
		{
			"text": "Задачи ЕНТ по диагностике:\n• По выводу ping определить, есть ли потери\n• По tracert определить, где обрыв\n• По ipconfig выявить ошибку в адресации\n• По условию выбрать правильный инструмент\n\nПравило: сначала интерпретируй симптомы, потом выбирай действие.",
			"render_func": "render_ent_tasks",
		},
	]


func render_diag_chain(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 6)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	for row_data in [
		["ПК", "Проверка: ipconfig, ping 127.0.0.1", Color(0.35,0.70,1.00,1.0)],
		["Роутер", "Проверка: ping шлюза", Color(0.20,0.85,0.55,1.0)],
		["Провайдер", "Проверка: tracert, потери", Color(0.80,0.60,0.20,1.0)],
		["DNS/Сервис", "Проверка: nslookup, ping домена", Color(0.80,0.50,1.00,1.0)],
	]:
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", _flat_style(row_data[2]*Color(1,1,1,0.09), row_data[2], 1, 7))
		container.add_child(panel)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		panel.add_child(hb)

		var left := Label.new()
		left.text = row_data[0]
		left.custom_minimum_size = Vector2(90, 0)
		left.add_theme_font_size_override("font_size", 14)
		left.add_theme_color_override("font_color", row_data[2])
		hb.add_child(left)

		var right := Label.new()
		right.text = row_data[1]
		right.add_theme_font_size_override("font_size", 13)
		right.add_theme_color_override("font_color", Color(0.80,0.80,0.90,1.0))
		right.autowrap_mode = TextServer.AUTOWRAP_WORD
		right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(right)


func render_ping_panel(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 3)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	container.add_child(_make_row_bg(["Пакеты", "Отправлено", "Получено", "Потеря"], true))
	container.add_child(_make_row_bg(["4", "4", "4", "0%"], false))
	container.add_child(_make_row_bg(["4", "4", "3", "25%"], false))

	var metrics := PanelContainer.new()
	metrics.add_theme_stylebox_override("panel", _flat_style(Color(0.08,0.10,0.20,1.0), Color(0.25,0.45,0.85,0.7), 1, 7))
	container.add_child(metrics)

	var lbl := Label.new()
	lbl.text = "Минимум/Среднее/Максимум: 15ms / 22ms / 40ms"
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.55,0.75,1.0,1.0))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	metrics.add_child(lbl)


func render_traceroute_panel(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 3)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	container.add_child(_make_row_bg(["Hop", "RTT", "Узел"], true))
	for r in [
		["1", "1 ms", "192.168.1.1"],
		["2", "8 ms", "10.0.0.1"],
		["3", "15 ms", "100.64.0.1"],
		["4", "* * *", "Timeout"],
		["5", "42 ms", "8.8.8.8"],
	]:
		container.add_child(_make_row_bg(r, false))

	var note := Label.new()
	note.text = "Если звёздочки начинаются рано и далее везде — ищи обрыв ближе к источнику."
	note.add_theme_font_size_override("font_size", 12)
	note.add_theme_color_override("font_color", Color(0.80,0.80,0.90,1.0))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD
	container.add_child(note)


func render_ipconfig_panel(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 3)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	container.add_child(_make_row_bg(["Параметр", "Значение", "Проверка"], true))
	for row_data in [
		["IPv4", "192.168.1.37", "В своей подсети"],
		["Mask", "255.255.255.0", "Совпадает с сетью"],
		["Gateway", "192.168.1.1", "Пингуется"],
		["DNS", "8.8.8.8", "Разрешает домены"],
	]:
		container.add_child(_make_row_bg(row_data, false))


func render_symptoms_table(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 3)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	container.add_child(_make_row_bg(["Симптом", "Вероятная причина", "Первый шаг"], true))
	for s in [
		["Пингуется IP, не пингуется домен", "DNS", "nslookup + сменить DNS"],
		["Не пингуется шлюз", "Локальная сеть", "Проверить кабель/Wi‑Fi"],
		["Большая задержка и потери", "Канал/линк", "Сделать серию ping"],
		["Сайт не открывается, ping есть", "Порт/HTTP/сервис", "Проверить браузер/порт"],
	]:
		container.add_child(_make_row_bg(s, false))


func render_algo(area: Control, _step: Dictionary) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _flat_style(Color(0.07,0.10,0.06,1.0), Color(0.25,0.60,0.20,0.6), 1, 9))
	area.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 5)
	panel.add_child(vb)

	for i in range(6):
		var line := [
			"1) ipconfig/ifconfig",
			"2) ping 127.0.0.1",
			"3) ping gateway",
			"4) ping внешнего IP",
			"5) ping домена",
			"6) tracert/traceroute",
		][i]
		var lbl := Label.new()
		lbl.text = line
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.78,0.84,0.90,1.0))
		vb.add_child(lbl)


func render_ent_tasks(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 6)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	for t in [
		["Тип 1", "Интерпретация ping", Color(0.35,0.70,1.00,1.0)],
		["Тип 2", "Поиск проблемного hop в tracert", Color(0.20,0.85,0.55,1.0)],
		["Тип 3", "Ошибка адресации в ipconfig", Color(0.80,0.60,0.20,1.0)],
	]:
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", _flat_style(t[2]*Color(1,1,1,0.09), t[2], 1, 7))
		container.add_child(p)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		p.add_child(hb)

		var k := Label.new()
		k.text = t[0]
		k.custom_minimum_size = Vector2(58, 0)
		k.add_theme_font_size_override("font_size", 14)
		k.add_theme_color_override("font_color", t[2])
		hb.add_child(k)

		var d := Label.new()
		d.text = t[1]
		d.add_theme_font_size_override("font_size", 13)
		d.add_theme_color_override("font_color", Color(0.80,0.80,0.90,1.0))
		hb.add_child(d)


# HELPERS ─────────────────────────────────────────────────────
func _flat_style(bg: Color, border: Color, bw: int = 1, radius: int = 6) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s

func _make_cell(text: String, fsize: int, fcol: Color, bg: Color, border: Color) -> PanelContainer:
	var cell := PanelContainer.new()
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cs := StyleBoxFlat.new()
	cs.bg_color = bg
	cs.border_color = border
	cs.set_border_width_all(1)
	cs.corner_radius_top_left = 3
	cs.corner_radius_top_right = 3
	cs.corner_radius_bottom_left = 3
	cs.corner_radius_bottom_right = 3
	cs.content_margin_left = 6
	cs.content_margin_right = 6
	cs.content_margin_top = 5
	cs.content_margin_bottom = 5
	cell.add_theme_stylebox_override("panel", cs)
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", fsize)
	lbl.add_theme_color_override("font_color", fcol)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	cell.add_child(lbl)
	return cell

func _make_row_bg(values: Array, is_header: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	for val in values:
		row.add_child(_make_cell(str(val), 12,
			Color(0.5,0.7,1.0,1.0) if is_header else Color(0.8,0.8,0.9,1.0),
			Color(0.10,0.12,0.20,1.0) if is_header else Color(0.07,0.08,0.12,1.0),
			Color(0.22,0.35,0.55,0.7) if is_header else Color(0.15,0.15,0.22,0.5)))
	return row

func _calculate_stars() -> int:
	return 3 if current_step_index >= tutorial_steps.size() - 1 else 2
