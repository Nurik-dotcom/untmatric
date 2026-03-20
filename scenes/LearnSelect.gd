# scenes/LearnSelect.gd
extends Control

const PHONE_LANDSCAPE_MAX_HEIGHT := 520.0
const MOBILE_BREAKPOINT := 840.0
const TABLET_BREAKPOINT := 1300.0

# Метаданные всех 21 уроков в 5 группах
const LESSON_META: Array[Dictionary] = [
	# ── ГРУППА 1: СИСТЕМЫ СЧИСЛЕНИЯ ──────────────────────────────
	{
		"id": "bin_basics",
		"group": "⬛ Системы счисления",
		"icon": "⚡",
		"title_ru": "Биты и байты",
		"subtitle_ru": "Что такое бит, байт, степени двойки",
		"scene": "res://scenes/Tutorial/TutorialBinary.tscn",
		"difficulty": "A",
		"quest_hint": "Дешифратор A",
		"locked": false,
	},
	{
		"id": "bin_convert",
		"group": "⬛ Системы счисления",
		"icon": "🔄",
		"title_ru": "Двоичный перевод",
		"subtitle_ru": "2→10 и 10→2, алгоритм деления",
		"scene": "res://scenes/Tutorial/TutorialBinConvert.tscn",
		"difficulty": "A",
		"quest_hint": "Дешифратор A",
		"locked": false,
	},
	{
		"id": "hex_basics",
		"group": "⬛ Системы счисления",
		"icon": "🔓",
		"title_ru": "Шестнадцатеричная",
		"subtitle_ru": "Цифры 0-9 и A-F, HEX логика",
		"scene": "res://scenes/Tutorial/TutorialHexadecimal.tscn",
		"difficulty": "B",
		"quest_hint": "Дешифратор B",
		"locked": false,
	},
	{
		"id": "hex_convert",
		"group": "⬛ Системы счисления",
		"icon": "↔️",
		"title_ru": "Перевод HEX↔BIN↔DEC",
		"subtitle_ru": "Таблица перевода, практика",
		"scene": "res://scenes/Tutorial/TutorialHexConvert.tscn",
		"difficulty": "B",
		"quest_hint": "Дешифратор B",
		"locked": false,
	},
	{
		"id": "xor_cipher",
		"group": "⬛ Системы счисления",
		"icon": "🔐",
		"title_ru": "XOR-шифрование",
		"subtitle_ru": "Побитовая операция, ключ XOR",
		"scene": "res://scenes/Tutorial/TutorialXOR.tscn",
		"difficulty": "C",
		"quest_hint": "Матрица-Дешифратор C",
		"locked": false,
	},

	# ── ГРУППА 2: ЛОГИКА ─────────────────────────────────────────
	{
		"id": "logic_basic",
		"group": "🔀 Логика",
		"icon": "🔀",
		"title_ru": "AND, OR, NOT",
		"subtitle_ru": "Три базовых вентиля, таблицы",
		"scene": "res://scenes/Tutorial/TutorialLogicGates.tscn",
		"difficulty": "A",
		"quest_hint": "Логические вентили A",
		"locked": false,
	},
	{
		"id": "logic_xor_nand",
		"group": "🔀 Логика",
		"icon": "⊕",
		"title_ru": "XOR, NAND, NOR",
		"subtitle_ru": "Производные вентили",
		"scene": "",
		"difficulty": "A",
		"quest_hint": "Логические вентили A/B",
		"locked": true,
	},
	{
		"id": "logic_tables",
		"group": "🔀 Логика",
		"icon": "📊",
		"title_ru": "Таблицы истинности",
		"subtitle_ru": "Составление для сложных выражений",
		"scene": "",
		"difficulty": "B",
		"quest_hint": "Логические вентили B",
		"locked": true,
	},
	{
		"id": "logic_circuits",
		"group": "🔀 Логика",
		"icon": "⚙️",
		"title_ru": "Логические схемы",
		"subtitle_ru": "Комбинирование вентилей",
		"scene": "",
		"difficulty": "C",
		"quest_hint": "Логические вентили C",
		"locked": true,
	},

	# ── ГРУППА 3: СЕТИ И ПРОТОКОЛЫ ───────────────────────────────
	{
		"id": "net_osi",
		"group": "🌐 Сети",
		"icon": "🌐",
		"title_ru": "Модель OSI",
		"subtitle_ru": "7 уровней, их функции",
		"scene": "res://scenes/Tutorial/TutorialNetOSI.tscn",
		"difficulty": "A",
		"quest_hint": "Сетевой след A",
		"locked": false,
	},
	{
		"id": "net_ip",
		"group": "🌐 Сети",
		"icon": "🔗",
		"title_ru": "IP-адресация",
		"subtitle_ru": "IPv4, классы адресов",
		"scene": "res://scenes/Tutorial/TutorialIPAddress.tscn",
		"difficulty": "B",
		"quest_hint": "Сетевой след A/B",
		"locked": false,
	},
	{
		"id": "net_mask",
		"group": "🌐 Сети",
		"icon": "🛡️",
		"title_ru": "Маски подсетей",
		"subtitle_ru": "CIDR, вычисление диапазонов",
		"scene": "res://scenes/Tutorial/TutorialNetMask.tscn",
		"difficulty": "B",
		"quest_hint": "Сетевой след B",
		"locked": false,
	},
	{
		"id": "net_diag",
		"group": "🌐 Сети",
		"icon": "🔍",
		"title_ru": "Диагностика сети",
		"subtitle_ru": "Ошибки, топология, трассировка",
		"scene": "",
		"difficulty": "C",
		"quest_hint": "Сетевой след C",
		"locked": true,
	},

	# ── ГРУППА 4: АЛГОРИТМЫ И ГРАФЫ ─────────────────────────────
	{
		"id": "graph_basics",
		"group": "🗺️ Алгоритмы",
		"icon": "🗺️",
		"title_ru": "Графы: основы",
		"subtitle_ru": "Узлы, рёбра, типы графов",
		"scene": "res://scenes/Tutorial/TutorialGraphs.tscn",
		"difficulty": "A",
		"quest_hint": "Карта города A",
		"locked": false,
	},
	{
		"id": "graph_dijkstra",
		"group": "🗺️ Алгоритмы",
		"icon": "📍",
		"title_ru": "Алгоритм Дейкстры",
		"subtitle_ru": "Кратчайший путь, шаг за шагом",
		"scene": "",
		"difficulty": "B",
		"quest_hint": "Карта города B/C",
		"locked": true,
	},
	{
		"id": "algo_sort",
		"group": "🗺️ Алгоритмы",
		"icon": "🔢",
		"title_ru": "Сортировка",
		"subtitle_ru": "Пузырёк, выборка, быстрая",
		"scene": "res://scenes/Tutorial/TutorialSorting.tscn",
		"difficulty": "B",
		"quest_hint": "Архив данных B",
		"locked": false,
	},
	{
		"id": "algo_complexity",
		"group": "🗺️ Алгоритмы",
		"icon": "📈",
		"title_ru": "Сложность O(n)",
		"subtitle_ru": "Big-O, O(n²), O(log n)",
		"scene": "res://scenes/Tutorial/TutorialBigO.tscn",
		"difficulty": "C",
		"quest_hint": "Финальный отчёт C",
		"locked": false,
	},

	# ── ГРУППА 5: КОДИРОВАНИЕ И ДАННЫЕ ───────────────────────────
	{
		"id": "encode_ascii",
		"group": "📡 Кодирование",
		"icon": "📡",
		"title_ru": "ASCII и Unicode",
		"subtitle_ru": "Таблица кодов, символы",
		"scene": "res://scenes/Tutorial/TutorialASCII.tscn",
		"difficulty": "A",
		"quest_hint": "Радиоперехват A",
		"locked": false,
	},
	{
		"id": "encode_freq",
		"group": "📡 Кодирование",
		"icon": "📻",
		"title_ru": "Частотный анализ",
		"subtitle_ru": "Дешифровка через частоты букв",
		"scene": "",
		"difficulty": "B",
		"quest_hint": "Радиоперехват B",
		"locked": true,
	},
	{
		"id": "matrix_cipher",
		"group": "📡 Кодирование",
		"icon": "🔢",
		"title_ru": "Матричные шифры",
		"subtitle_ru": "Матрица ключей, перестановки",
		"scene": "res://scenes/Tutorial/TutorialMatrix.tscn",
		"difficulty": "C",
		"quest_hint": "Матрица-Дешифратор C",
		"locked": false,
	},
	{
		"id": "file_systems",
		"group": "📡 Кодирование",
		"icon": "🗄️",
		"title_ru": "Файловые системы",
		"subtitle_ru": "FAT, NTFS, дерево каталогов",
		"scene": "",
		"difficulty": "A",
		"quest_hint": "Архив данных A",
		"locked": true,
	},
	{
		"id": "sql_basics",
		"group": "📡 Кодирование",
		"icon": "💾",
		"title_ru": "Базы данных: SQL",
		"subtitle_ru": "SELECT, WHERE, ORDER BY",
		"scene": "",
		"difficulty": "B",
		"quest_hint": "Архив данных B/C",
		"locked": true,
	},
]

@onready var safe_area: MarginContainer = $SafeArea
@onready var main_layout: VBoxContainer = $SafeArea/MainLayout
@onready var title_label: Label = $SafeArea/MainLayout/Title
@onready var progress_bar: ProgressBar = $SafeArea/MainLayout/ProgressBar
@onready var progress_label: Label = $SafeArea/MainLayout/ProgressLabel
@onready var quest_grid: GridContainer = $SafeArea/MainLayout/GridScroll/QuestGrid
@onready var btn_back_to_menu: Button = $SafeArea/MainLayout/Footer/BtnBackToMenu

var _cards: Array[LessonCard] = []

func _ready() -> void:
	title_label.text = I18n.tr_key("ui.learn_select.title", {"default": "ОБУЧЕНИЕ"})
	btn_back_to_menu.text = I18n.tr_key("ui.learn_select.back_to_menu", {"default": "← МЕНЮ"})
	btn_back_to_menu.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	_build_cards()
	_update_progress()
	_on_viewport_size_changed()
	if not get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.connect(_on_viewport_size_changed)
	LessonProgress.progress_changed.connect(_on_progress_changed)
	call_deferred("_animate_intro")

func _exit_tree() -> void:
	if LessonProgress.progress_changed.is_connected(_on_progress_changed):
		LessonProgress.progress_changed.disconnect(_on_progress_changed)

func _build_cards() -> void:
	for child in quest_grid.get_children():
		child.queue_free()
	_cards.clear()

	var card_scene := load("res://scenes/Tutorial/LessonCard.tscn")
	var current_group := ""
	var cols := quest_grid.columns

	for meta in LESSON_META:
		if meta["group"] != current_group:
			current_group = meta["group"]
			_add_group_header(current_group, cols)

		var card: LessonCard = card_scene.instantiate()
		quest_grid.add_child(card)
		card.setup(
			meta["id"],
			meta["icon"],
			meta["title_ru"],
			meta["subtitle_ru"],
			meta.get("difficulty", "A"),
			meta["locked"]
		)
		if not meta["locked"] and meta["scene"] != "":
			var scene_path: String = meta["scene"]
			card.card_pressed.connect(func(_lesson_id: String):
				_open_lesson(scene_path)
			)
		_cards.append(card)

func _add_group_header(group_name: String, cols: int) -> void:
	var header_label := Label.new()
	header_label.text = group_name
	header_label.add_theme_font_size_override("font_size", 11)
	header_label.add_theme_color_override("font_color", Color(0.45, 0.45, 0.6, 1.0))
	header_label.custom_minimum_size = Vector2(0, 28)
	header_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	quest_grid.add_child(header_label)
	for i in range(cols - 1):
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(0, 28)
		quest_grid.add_child(spacer)

func _open_lesson(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)

func _on_progress_changed(_id: String) -> void:
	_update_progress()

func _update_progress() -> void:
	var total := LESSON_META.size()
	var done := LessonProgress.get_total_completed()
	progress_bar.max_value = total
	progress_bar.value = done
	progress_label.text = "%d / %d завершено" % [done, total]

func _animate_intro() -> void:
	title_label.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(title_label, "modulate:a", 1.0, 0.3)
	for i in range(_cards.size()):
		var card := _cards[i]
		card.modulate.a = 0.0
		card.scale = Vector2(0.96, 0.96)
		var ct := create_tween()
		ct.tween_property(card, "modulate:a", 1.0, 0.2).set_delay(0.05 * i)
		ct.parallel().tween_property(card, "scale", Vector2.ONE, 0.25).set_delay(0.05 * i).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_viewport_size_changed() -> void:
	var vp := get_viewport_rect().size
	var is_landscape := vp.x > vp.y and vp.y <= PHONE_LANDSCAPE_MAX_HEIGHT
	var new_cols: int
	if is_landscape:
		new_cols = 3
		_apply_margins(6, 8, 4)
		_set_card_min_height(72.0)
	elif vp.x < MOBILE_BREAKPOINT:
		new_cols = 1
		_apply_margins(12, 16, 12)
		_set_card_min_height(110.0)
	elif vp.x < TABLET_BREAKPOINT:
		new_cols = 2
		_apply_margins(14, 20, 14)
		_set_card_min_height(110.0)
	else:
		new_cols = 3
		_apply_margins(14, 24, 16)
		_set_card_min_height(110.0)

	if quest_grid.columns != new_cols:
		quest_grid.columns = new_cols
		_build_cards()

	title_label.visible = not is_landscape
	progress_label.visible = not is_landscape
	progress_bar.custom_minimum_size.y = 4.0 if is_landscape else 6.0

func _set_card_min_height(h: float) -> void:
	for card in _cards:
		card.custom_minimum_size.y = h

func _apply_margins(gap: int, margin_side: int, margin_vertical: int) -> void:
	quest_grid.add_theme_constant_override("h_separation", gap)
	quest_grid.add_theme_constant_override("v_separation", gap)
	safe_area.add_theme_constant_override("margin_left", margin_side)
	safe_area.add_theme_constant_override("margin_right", margin_side)
	safe_area.add_theme_constant_override("margin_top", margin_vertical)
	safe_area.add_theme_constant_override("margin_bottom", margin_vertical)
