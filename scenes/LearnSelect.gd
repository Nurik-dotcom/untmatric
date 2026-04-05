extends Control

const PHONE_LANDSCAPE_MAX_HEIGHT := 520.0
const MOBILE_BREAKPOINT := 840.0
const TABLET_BREAKPOINT := 1300.0

func _tr(key: String, default_text: String, params: Dictionary = {}) -> String:
	var merged: Dictionary = params.merged({"default": default_text})
	return I18n.tr_key(key, merged)

func _tr_compat(primary_key: String, legacy_key: String, default_text: String, params: Dictionary = {}) -> String:
	var sentinel: String = "__missing__%s__" % primary_key
	var primary_text: String = I18n.tr_key(primary_key, params.merged({"default": sentinel}))
	if primary_text != sentinel:
		return primary_text
	return _tr(legacy_key, default_text, params)

const LESSON_META: Array[Dictionary] = [
	{"id": "bin_basics", "group_key": "ui.learn_select.group.number", "icon": "#", "scene": "res://scenes/Tutorial/TutorialBinary.tscn", "difficulty": "A", "locked": false, "title_default": "Bits and Bytes", "subtitle_default": "What is a bit, byte, powers of two"},
	{"id": "bin_convert", "group_key": "ui.learn_select.group.number", "icon": "#", "scene": "res://scenes/Tutorial/TutorialBinConvert.tscn", "difficulty": "A", "locked": false, "title_default": "Binary Conversion", "subtitle_default": "2 to 10 and 10 to 2 conversion"},
	{"id": "hex_basics", "group_key": "ui.learn_select.group.number", "icon": "#", "scene": "res://scenes/Tutorial/TutorialHexadecimal.tscn", "difficulty": "B", "locked": false, "title_default": "Hexadecimal", "subtitle_default": "Digits 0-9 and A-F"},
	{"id": "hex_convert", "group_key": "ui.learn_select.group.number", "icon": "#", "scene": "res://scenes/Tutorial/TutorialHexConvert.tscn", "difficulty": "B", "locked": false, "title_default": "HEX BIN DEC Conversion", "subtitle_default": "Practice conversion table"},
	{"id": "xor_cipher", "group_key": "ui.learn_select.group.number", "icon": "#", "scene": "res://scenes/Tutorial/TutorialXOR.tscn", "difficulty": "C", "locked": false, "title_default": "XOR Encryption", "subtitle_default": "Bitwise operation and XOR key"},
	{"id": "data_transfer", "group_key": "ui.learn_select.group.number", "icon": "#", "scene": "res://scenes/Tutorial/TutorialDataTransfer.tscn", "difficulty": "B", "locked": false, "title_default": "Data Transfer Speed", "subtitle_default": "Bits bytes time formulas"},

	{"id": "comp_arch", "group_key": "ui.learn_select.group.encoding", "icon": "E", "scene": "res://scenes/Tutorial/TutorialComputerArch.tscn", "difficulty": "A", "locked": false, "title_default": "Computer Architecture", "subtitle_default": "Input Output Memory CPU"},
	{"id": "encode_ascii", "group_key": "ui.learn_select.group.encoding", "icon": "E", "scene": "res://scenes/Tutorial/TutorialASCII.tscn", "difficulty": "A", "locked": false, "title_default": "ASCII and Unicode", "subtitle_default": "Code table, characters"},
	{"id": "encode_freq", "group_key": "ui.learn_select.group.encoding", "icon": "E", "scene": "res://scenes/Tutorial/TutorialFreqAnalysis.tscn", "difficulty": "B", "locked": false, "title_default": "Frequency Analysis", "subtitle_default": "Decoding via letter frequencies"},
	{"id": "matrix_cipher", "group_key": "ui.learn_select.group.encoding", "icon": "E", "scene": "res://scenes/Tutorial/TutorialMatrix.tscn", "difficulty": "C", "locked": false, "title_default": "Matrix Ciphers", "subtitle_default": "Key matrix, permutations"},
	{"id": "file_systems", "group_key": "ui.learn_select.group.encoding", "icon": "E", "scene": "res://scenes/Tutorial/TutorialFileSystems.tscn", "difficulty": "A", "locked": false, "title_default": "File Systems", "subtitle_default": "FAT, NTFS, directory tree"},
	{"id": "html_basics", "group_key": "ui.learn_select.group.encoding", "icon": "E", "scene": "res://scenes/Tutorial/TutorialHTML.tscn", "difficulty": "B", "locked": false, "title_default": "HTML Basics", "subtitle_default": "Tags structure nesting"},
	{"id": "db_fundamentals", "group_key": "ui.learn_select.group.encoding", "icon": "E", "scene": "res://scenes/Tutorial/TutorialDBFundamentals.tscn", "difficulty": "A", "locked": false, "title_default": "Database Fundamentals", "subtitle_default": "Tables keys 1NF filtering"},
	{"id": "sql_basics", "group_key": "ui.learn_select.group.encoding", "icon": "E", "scene": "res://scenes/Tutorial/TutorialSQL.tscn", "difficulty": "C", "locked": false, "title_default": "Databases: SQL", "subtitle_default": "SELECT, WHERE, ORDER BY"},

	{"id": "logic_basic", "group_key": "ui.learn_select.group.logic", "icon": "L", "scene": "res://scenes/Tutorial/TutorialLogicGates.tscn", "difficulty": "A", "locked": false, "title_default": "AND OR NOT", "subtitle_default": "Three basic logic gates"},
	{"id": "logic_xor_nand", "group_key": "ui.learn_select.group.logic", "icon": "L", "scene": "res://scenes/Tutorial/TutorialLogicXOR.tscn", "difficulty": "A", "locked": false, "title_default": "XOR NAND NOR", "subtitle_default": "Derived logic gates"},
	{"id": "logic_tables", "group_key": "ui.learn_select.group.logic", "icon": "L", "scene": "res://scenes/Tutorial/TutorialLogicTables.tscn", "difficulty": "B", "locked": false, "title_default": "Truth Tables", "subtitle_default": "Complex expression tables"},
	{"id": "logic_circuits", "group_key": "ui.learn_select.group.logic", "icon": "L", "scene": "res://scenes/Tutorial/TutorialLogicCircuits.tscn", "difficulty": "C", "locked": false, "title_default": "Logic Circuits", "subtitle_default": "Combining gates"},

	{"id": "net_osi", "group_key": "ui.learn_select.group.networks", "icon": "N", "scene": "res://scenes/Tutorial/TutorialNetOSI.tscn", "difficulty": "A", "locked": false, "title_default": "OSI Model", "subtitle_default": "7 layers and functions"},
	{"id": "net_ip", "group_key": "ui.learn_select.group.networks", "icon": "N", "scene": "res://scenes/Tutorial/TutorialIPAddress.tscn", "difficulty": "B", "locked": false, "title_default": "IP Addressing", "subtitle_default": "IPv4 and address classes"},
	{"id": "net_mask", "group_key": "ui.learn_select.group.networks", "icon": "N", "scene": "res://scenes/Tutorial/TutorialNetMask.tscn", "difficulty": "B", "locked": false, "title_default": "Subnet Masks", "subtitle_default": "CIDR and ranges"},
	{"id": "net_diag", "group_key": "ui.learn_select.group.networks", "icon": "N", "scene": "res://scenes/Tutorial/TutorialNetDiag.tscn", "difficulty": "C", "locked": false, "title_default": "Network Diagnostics", "subtitle_default": "Errors topology tracing"},

	{"id": "graph_basics", "group_key": "ui.learn_select.group.algo", "icon": "A", "scene": "res://scenes/Tutorial/TutorialGraphs.tscn", "difficulty": "A", "locked": false, "title_default": "Graphs Basics", "subtitle_default": "Nodes edges graph types"},
	{"id": "graph_dijkstra", "group_key": "ui.learn_select.group.algo", "icon": "A", "scene": "res://scenes/Tutorial/TutorialDijkstra.tscn", "difficulty": "B", "locked": false, "title_default": "Dijkstra Algorithm", "subtitle_default": "Shortest path step by step"},
	{"id": "algo_sort", "group_key": "ui.learn_select.group.algo", "icon": "A", "scene": "res://scenes/Tutorial/TutorialSorting.tscn", "difficulty": "B", "locked": false, "title_default": "Sorting", "subtitle_default": "Bubble selection quick sort"},
	{"id": "algo_complexity", "group_key": "ui.learn_select.group.algo", "icon": "A", "scene": "res://scenes/Tutorial/TutorialBigO.tscn", "difficulty": "C", "locked": false, "title_default": "Complexity O(n)", "subtitle_default": "Big O notation"},
	{"id": "code_trace", "group_key": "ui.learn_select.group.algo", "icon": "A", "scene": "res://scenes/Tutorial/TutorialCodeTrace.tscn", "difficulty": "A", "locked": false, "title_default": "Code Tracing", "subtitle_default": "Variables loops conditions"},
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
	btn_back_to_menu.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	if not get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.connect(_on_viewport_size_changed)
	if not LessonProgress.progress_changed.is_connected(_on_progress_changed):
		LessonProgress.progress_changed.connect(_on_progress_changed)
	if not I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.connect(_on_language_changed)
	_apply_i18n()
	_on_viewport_size_changed()
	call_deferred("_animate_intro")

func _exit_tree() -> void:
	if LessonProgress.progress_changed.is_connected(_on_progress_changed):
		LessonProgress.progress_changed.disconnect(_on_progress_changed)
	if get_tree() and get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.disconnect(_on_viewport_size_changed)
	if I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.disconnect(_on_language_changed)

func _group_default(group_key: String) -> String:
	match group_key:
		"ui.learn_select.group.number":
			return "Number Systems"
		"ui.learn_select.group.logic":
			return "Logic"
		"ui.learn_select.group.networks":
			return "Networks"
		"ui.learn_select.group.algo":
			return "Algorithms"
		"ui.learn_select.group.encoding":
			return "Encoding"
		_:
			return "Group"

func _group_alias_key(group_key: String) -> String:
	match group_key:
		"ui.learn_select.group.number":
			return "ui.learn.group.number_systems"
		"ui.learn_select.group.logic":
			return "ui.learn.group.logic"
		"ui.learn_select.group.networks":
			return "ui.learn.group.networks"
		"ui.learn_select.group.algo":
			return "ui.learn.group.algorithms"
		"ui.learn_select.group.encoding":
			return "ui.learn.group.encoding"
		_:
			return ""

func _lesson_title(meta: Dictionary) -> String:
	var lesson_id: String = str(meta.get("id", ""))
	return _tr_compat(
		"ui.learn_select.lesson.%s.title" % lesson_id,
		"ui.learn.%s.title" % lesson_id,
		str(meta.get("title_default", lesson_id))
	)

func _lesson_subtitle(meta: Dictionary) -> String:
	var lesson_id: String = str(meta.get("id", ""))
	return _tr_compat(
		"ui.learn_select.lesson.%s.subtitle" % lesson_id,
		"ui.learn.%s.subtitle" % lesson_id,
		str(meta.get("subtitle_default", ""))
	)

func _apply_i18n() -> void:
	title_label.text = _tr_compat("ui.learn_select.title", "ui.learn.title", "LEARNING")
	btn_back_to_menu.text = _tr_compat("ui.learn_select.back_to_menu", "ui.learn.back_to_menu", "MENU")
	_build_cards()
	_update_progress()

func _on_language_changed(_new_language: String) -> void:
	_apply_i18n()

func _build_cards() -> void:
	for child in quest_grid.get_children():
		child.queue_free()
	_cards.clear()

	var card_scene := load("res://scenes/Tutorial/LessonCard.tscn")
	var current_group_key := ""
	var cols := quest_grid.columns

	for meta in LESSON_META:
		var group_key: String = str(meta.get("group_key", ""))
		if group_key != current_group_key:
			current_group_key = group_key
			_add_group_header(group_key, cols)

		var card: LessonCard = card_scene.instantiate()
		quest_grid.add_child(card)
		card.setup(
			str(meta.get("id", "")),
			str(meta.get("icon", "")),
			_lesson_title(meta),
			_lesson_subtitle(meta),
			str(meta.get("difficulty", "A")),
			bool(meta.get("locked", false))
		)
		if not bool(meta.get("locked", false)) and str(meta.get("scene", "")) != "":
			var scene_path: String = str(meta.get("scene", ""))
			card.card_pressed.connect(func(_lesson_id: String) -> void:
				_open_lesson(scene_path)
			)
		_cards.append(card)

func _add_group_header(group_key: String, cols: int) -> void:
	var header_label := Label.new()
	header_label.text = _tr_compat(group_key, _group_alias_key(group_key), _group_default(group_key))
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
	progress_label.text = _tr_compat(
		"ui.learn_select.progress",
		"ui.learn.progress",
		"{done} / {total} completed",
		{"done": done, "total": total}
	)

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
