extends "res://scenes/Tutorial/TutorialBase.gd"
# TutorialNetOSI.gd — Модель OSI: 7 уровней сети
# Готовит к: NetworkTrace A

class_name TutorialNetOSI

func _initialize_tutorial() -> void:
	tutorial_id = "net_osi"
	tutorial_title = "Модель OSI"
	linked_quest_scene = "res://scenes/NetworkTraceQuestA.tscn"

	tutorial_steps = [
		{
			"text": "OSI (Open Systems Interconnection) — стандартная модель, описывающая как данные передаются по сети.\n\nМодель разбита на 7 уровней.\nКаждый уровень отвечает за свою задачу и «общается» только с соседними.\n\nПредставь это как конверт внутри конверта: каждый уровень добавляет свою обёртку при отправке и снимает при получении.",
			"render_func": "render_osi_stack",
		},
		{
			"text": "Уровень 7 — Прикладной (Application)\n\nСамый близкий к пользователю уровень.\n\nЧто делает:\n• Предоставляет интерфейс для приложений\n• HTTP, FTP, DNS, SMTP работают здесь\n\nПример: когда ты открываешь браузер и набираешь URL — это уровень 7.",
			"render_func": "render_osi_level",
			"level": 7,
			"name": "Прикладной",
			"eng": "Application",
			"protocols": ["HTTP", "FTP", "DNS", "SMTP", "POP3"],
			"example": "Браузер, почта, FTP-клиент",
		},
		{
			"text": "Уровень 6 — Представления (Presentation)\n\nПереводит данные в понятный для приложения формат.\n\nЧто делает:\n• Шифрование и дешифрование (TLS/SSL)\n• Сжатие данных\n• Конвертация форматов (UTF-8, JPEG)\n\nПример: браузер получает зашифрованный HTTPS — уровень 6 расшифровывает.",
			"render_func": "render_osi_level",
			"level": 6,
			"name": "Представления",
			"eng": "Presentation",
			"protocols": ["SSL/TLS", "JPEG", "MPEG", "ASCII"],
			"example": "Шифрование, сжатие, форматы",
		},
		{
			"text": "Уровень 5 — Сеансовый (Session)\n\nУправляет сеансом (сессией) связи между двумя устройствами.\n\nЧто делает:\n• Открывает, поддерживает и закрывает соединения\n• Синхронизация при разрыве\n• Авторизация сессии\n\nПример: авторизация на сайте создаёт сессию — это уровень 5.",
			"render_func": "render_osi_level",
			"level": 5,
			"name": "Сеансовый",
			"eng": "Session",
			"protocols": ["NetBIOS", "RPC", "PPTP"],
			"example": "Сессии входа, управление соединением",
		},
		{
			"text": "Уровень 4 — Транспортный (Transport)\n\nОтвечает за надёжную доставку данных между устройствами.\n\nЧто делает:\n• Разбивает данные на сегменты\n• Управляет потоком данных\n• TCP (надёжно, с подтверждением)\n• UDP (быстро, без гарантий)\n\nПример: TCP гарантирует что все части файла дошли. UDP используется в видеозвонках где скорость важнее.",
			"render_func": "render_tcp_udp_compare",
		},
		{
			"text": "Уровень 3 — Сетевой (Network)\n\nОпределяет маршрут от отправителя к получателю.\n\nЧто делает:\n• IP-адресация\n• Маршрутизация через роутеры\n• Логическая адресация\n\nПример: твой пакет данных путешествует через 10 роутеров в разных странах — уровень 3 решает, куда идти дальше.",
			"render_func": "render_osi_level",
			"level": 3,
			"name": "Сетевой",
			"eng": "Network",
			"protocols": ["IP", "ICMP", "ARP", "RIP", "OSPF"],
			"example": "Роутеры, IP-пакеты",
		},
		{
			"text": "Уровень 2 — Канальный (Data Link)\n\nПередача данных внутри одной сети (от устройства к устройству).\n\nЧто делает:\n• MAC-адресация (физические адреса устройств)\n• Обнаружение ошибок в кадрах\n• Коммутаторы (switches) работают здесь\n\nПример: WiFi-роутер знает MAC-адреса всех устройств в домашней сети.",
			"render_func": "render_osi_level",
			"level": 2,
			"name": "Канальный",
			"eng": "Data Link",
			"protocols": ["Ethernet", "WiFi (802.11)", "PPP", "MAC"],
			"example": "Коммутаторы, MAC-адреса",
		},
		{
			"text": "Уровень 1 — Физический (Physical)\n\nФизическая передача битов через среду.\n\nЧто делает:\n• Кабели, разъёмы, электрические сигналы\n• Оптическое волокно, радиоволны\n• Нули и единицы в виде импульсов\n\nЭто самый «железный» уровень — провода, антенны, светодиоды.",
			"render_func": "render_osi_level",
			"level": 1,
			"name": "Физический",
			"eng": "Physical",
			"protocols": ["Ethernet-кабель", "Оптоволокно", "Bluetooth", "USB"],
			"example": "Кабели, хабы, WiFi-антенны",
		},
		{
			"text": "Мнемоника для запоминания (сверху вниз):\n\n7 Прикладной\n6 Представления\n5 Сеансовый\n4 Транспортный\n3 Сетевой\n2 Канальный\n1 Физический\n\nРусская фраза: «Папа Петя Сказал: Требуй Сетевой Кабель Физически»\n\nВ квесте «Сетевой след» ты будешь определять, на каком уровне произошла ошибка.",
			"render_func": "render_mnemonic",
		},
	]


# ═══ RENDER FUNCTIONS ═══════════════════════════════════════════════════════

const OSI_COLORS := [
	Color(0.65, 0.20, 0.20, 1.0),  # 1 Physical
	Color(0.65, 0.40, 0.10, 1.0),  # 2 Data Link
	Color(0.55, 0.55, 0.10, 1.0),  # 3 Network
	Color(0.20, 0.55, 0.20, 1.0),  # 4 Transport
	Color(0.15, 0.50, 0.65, 1.0),  # 5 Session
	Color(0.25, 0.35, 0.75, 1.0),  # 6 Presentation
	Color(0.50, 0.25, 0.75, 1.0),  # 7 Application
]

const OSI_NAMES := [
	"1 · Физический",
	"2 · Канальный",
	"3 · Сетевой",
	"4 · Транспортный",
	"5 · Сеансовый",
	"6 · Представления",
	"7 · Прикладной",
]


func render_osi_stack(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	for lvl in range(7, 0, -1):
		var idx: int = lvl - 1
		var cell := PanelContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cs := StyleBoxFlat.new()
		cs.bg_color = OSI_COLORS[idx] * Color(1, 1, 1, 0.18)
		cs.border_color = OSI_COLORS[idx]
		cs.set_border_width_all(1)
		cs.corner_radius_top_left    = 6; cs.corner_radius_top_right   = 6
		cs.corner_radius_bottom_left = 6; cs.corner_radius_bottom_right = 6
		cs.content_margin_left = 10; cs.content_margin_right = 10
		cs.content_margin_top  = 7;  cs.content_margin_bottom = 7
		cell.add_theme_stylebox_override("panel", cs)
		container.add_child(cell)

		var lbl := Label.new()
		lbl.text = OSI_NAMES[idx]
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", OSI_COLORS[idx])
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(lbl)


func render_osi_level(area: Control, step: Dictionary) -> void:
	var lvl: int     = step.get("level", 7)
	var name: String = step.get("name", "")
	var eng: String  = step.get("eng", "")
	var protocols    = step.get("protocols", [])
	var example      = step.get("example", "")
	var idx: int     = lvl - 1
	var col: Color   = OSI_COLORS[idx]

	var panel := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = col * Color(1, 1, 1, 0.12)
	ps.border_color = col
	ps.set_border_width_all(2)
	ps.corner_radius_top_left    = 10; ps.corner_radius_top_right   = 10
	ps.corner_radius_bottom_left = 10; ps.corner_radius_bottom_right = 10
	ps.content_margin_left = 14; ps.content_margin_right = 14
	ps.content_margin_top  = 12; ps.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", ps)
	area.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)

	var title := Label.new()
	title.text = "Уровень %d — %s (%s)" % [lvl, name, eng]
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", col)
	vb.add_child(title)

	var proto_row := HBoxContainer.new()
	proto_row.add_theme_constant_override("separation", 6)
	vb.add_child(proto_row)

	for proto in protocols:
		var badge := PanelContainer.new()
		var bs := StyleBoxFlat.new()
		bs.bg_color = col * Color(1, 1, 1, 0.20)
		bs.border_color = col * Color(1, 1, 1, 0.60)
		bs.set_border_width_all(1)
		bs.corner_radius_top_left    = 4; bs.corner_radius_top_right   = 4
		bs.corner_radius_bottom_left = 4; bs.corner_radius_bottom_right = 4
		bs.content_margin_left = 8; bs.content_margin_right = 8
		bs.content_margin_top  = 3; bs.content_margin_bottom = 3
		badge.add_theme_stylebox_override("panel", bs)
		proto_row.add_child(badge)
		var bl := Label.new()
		bl.text = proto
		bl.add_theme_font_size_override("font_size", 12)
		bl.add_theme_color_override("font_color", col)
		badge.add_child(bl)

	var ex_lbl := Label.new()
	ex_lbl.text = "💡 " + example
	ex_lbl.add_theme_font_size_override("font_size", 13)
	ex_lbl.add_theme_color_override("font_color", Color(0.70, 0.70, 0.80, 1.0))
	ex_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	vb.add_child(ex_lbl)


func render_tcp_udp_compare(area: Control, _step: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	area.add_child(row)

	for info in [
		{
			"name": "TCP",
			"points": ["Надёжная доставка", "Подтверждение (ACK)", "Упорядочивание", "Медленнее"],
			"use": "Файлы, почта, HTTP",
			"col": Color(0.25, 0.65, 1.00, 1.0),
		},
		{
			"name": "UDP",
			"points": ["Без гарантий", "Нет подтверждений", "Может теряться", "Быстрее"],
			"use": "Видео, игры, DNS",
			"col": Color(0.90, 0.55, 0.20, 1.0),
		},
	]:
		var cell := PanelContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cs := StyleBoxFlat.new()
		cs.bg_color = info["col"] * Color(1, 1, 1, 0.12)
		cs.border_color = info["col"]
		cs.set_border_width_all(2)
		cs.corner_radius_top_left    = 10; cs.corner_radius_top_right   = 10
		cs.corner_radius_bottom_left = 10; cs.corner_radius_bottom_right = 10
		cs.content_margin_left = 12; cs.content_margin_right = 12
		cs.content_margin_top  = 10; cs.content_margin_bottom = 10
		cell.add_theme_stylebox_override("panel", cs)
		row.add_child(cell)

		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 6)
		cell.add_child(vb)

		var name_lbl := Label.new()
		name_lbl.text = info["name"]
		name_lbl.add_theme_font_size_override("font_size", 24)
		name_lbl.add_theme_color_override("font_color", info["col"])
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(name_lbl)

		for pt in info["points"]:
			var pt_lbl := Label.new()
			pt_lbl.text = "• " + pt
			pt_lbl.add_theme_font_size_override("font_size", 13)
			pt_lbl.add_theme_color_override("font_color", Color(0.78, 0.78, 0.88, 1.0))
			vb.add_child(pt_lbl)

		var use_lbl := Label.new()
		use_lbl.text = "Используется:\n" + info["use"]
		use_lbl.add_theme_font_size_override("font_size", 12)
		use_lbl.add_theme_color_override("font_color", info["col"] * Color(1, 1, 1, 0.80))
		use_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		vb.add_child(use_lbl)


func render_mnemonic(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var words := ["Папа", "Петя", "Сказал:", "Требуй", "Сетевой", "Кабель", "Физически"]
	for i in range(7):
		var lvl: int = 7 - i
		var idx: int = lvl - 1
		var col: Color = OSI_COLORS[idx]

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		container.add_child(row)

		var num_lbl := Label.new()
		num_lbl.text = str(lvl)
		num_lbl.add_theme_font_size_override("font_size", 16)
		num_lbl.add_theme_color_override("font_color", col)
		num_lbl.custom_minimum_size = Vector2(22, 0)
		num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(num_lbl)

		var name_lbl := Label.new()
		name_lbl.text = OSI_NAMES[idx].substr(4)
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.add_theme_color_override("font_color", col)
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_lbl)

		var word_lbl := Label.new()
		word_lbl.text = words[i]
		word_lbl.add_theme_font_size_override("font_size", 14)
		word_lbl.add_theme_color_override("font_color", Color(0.70, 0.70, 0.80, 1.0))
		word_lbl.custom_minimum_size = Vector2(110, 0)
		row.add_child(word_lbl)


func _calculate_stars() -> int:
	return 3 if current_step_index >= tutorial_steps.size() - 1 else 2
