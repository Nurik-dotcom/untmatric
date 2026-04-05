extends Control

const PHONE_LANDSCAPE_MAX_HEIGHT := 520.0
const MOBILE_BREAKPOINT := 840.0
const TABLET_BREAKPOINT := 1300.0

@onready var safe_area: MarginContainer = $SafeArea
@onready var main_layout: VBoxContainer = $SafeArea/MainLayout
@onready var title_label: Label = $SafeArea/MainLayout/Title
@onready var quest_grid: GridContainer = $SafeArea/MainLayout/QuestGrid
@onready var modal: Panel = $ModalLayer/ModeSelectionModal
@onready var status_label: Label = $SafeArea/MainLayout/StatusLabel
@onready var btn_back_to_menu: Button = $SafeArea/MainLayout/Footer/BtnBackToMenu

@onready var btn_clues: Button = $SafeArea/MainLayout/QuestGrid/CluesButton
@onready var btn_radio: Button = $SafeArea/MainLayout/QuestGrid/RadioButton
@onready var btn_decryptor: Button = $SafeArea/MainLayout/QuestGrid/DecryptorButton
@onready var btn_lie: Button = $SafeArea/MainLayout/QuestGrid/LieDetectorButton
@onready var btn_script: Button = $SafeArea/MainLayout/QuestGrid/SuspectScriptButton
@onready var btn_city: Button = $SafeArea/MainLayout/QuestGrid/CityMapButton
@onready var btn_archive: Button = $SafeArea/MainLayout/QuestGrid/DataArchiveButton
@onready var btn_report: Button = $SafeArea/MainLayout/QuestGrid/FinalReportButton
@onready var btn_network_trace: Button = $SafeArea/MainLayout/QuestGrid/NetworkTraceButton

@onready var btn_complexity_a: Button = $ModalLayer/ModeSelectionModal/CenterContainer/VBoxContainer/BtnComplexityA
@onready var btn_complexity_b: Button = $ModalLayer/ModeSelectionModal/CenterContainer/VBoxContainer/BtnComplexityB
@onready var btn_complexity_c: Button = $ModalLayer/ModeSelectionModal/CenterContainer/VBoxContainer/BtnComplexityC
@onready var btn_close: Button = $ModalLayer/ModeSelectionModal/CenterContainer/VBoxContainer/BtnClose
@onready var modal_title: Label = $ModalLayer/ModeSelectionModal/CenterContainer/VBoxContainer/ModalTitle
@onready var modal_box: VBoxContainer = $ModalLayer/ModeSelectionModal/CenterContainer/VBoxContainer

const COLOR_READY := Color(0.88, 0.88, 0.88, 1.0)
const COLOR_LOCKED := Color(0.92, 0.36, 0.4, 1.0)

enum QuestType { DECRYPTOR, LOGIC_GATE, RADIO, SUSPECT, CITY_MAP, DATA_ARCHIVE, FINAL_REPORT, NETWORK_TRACE, CLUES }
const QUEST_BRIEFINGS: Dictionary = {
	QuestType.CLUES: {
		"title_key": "story.case1.title",
		"title_default": "CASE #1: CRIME SCENE",
		"briefing_key": "story.case1.briefing",
		"briefing_default": "A server was found hacked at the city data center. Equipment fragments are scattered. Classify each device — input, output, memory — to reconstruct how the attack happened."
	},
	QuestType.RADIO: {
		"title_key": "story.case2.title",
		"title_default": "CASE #2: INTERCEPT",
		"briefing_key": "story.case2.briefing",
		"briefing_default": "We've detected Phantom's radio signal. Decode the frequency and intercept the data transmission before he switches channels."
	},
	QuestType.DECRYPTOR: {
		"title_key": "story.case3.title",
		"title_default": "CASE #3: CIPHER",
		"briefing_key": "story.case3.briefing",
		"briefing_default": "The intercepted message is encrypted. Toggle the bits to crack the key and read Phantom's orders."
	},
	QuestType.LOGIC_GATE: {
		"title_key": "story.case4.title",
		"title_default": "CASE #4: INTERROGATION",
		"briefing_key": "story.case4.briefing",
		"briefing_default": "Three suspects detained. Each answers through logic gates. Fill the interrogation protocol — figure out who's lying."
	},
	QuestType.SUSPECT: {
		"title_key": "story.case5.title",
		"title_default": "CASE #5: SERVER BREACH",
		"briefing_key": "story.case5.briefing",
		"briefing_default": "We've located Phantom's server, but it's protected by scripts. Analyze the code, restore the algorithm, and disarm the trap."
	},
	QuestType.CITY_MAP: {
		"title_key": "story.case6.title",
		"title_default": "CASE #6: PURSUIT",
		"briefing_key": "story.case6.briefing",
		"briefing_default": "Phantom is moving through the city. Find the shortest route between his waypoints — before he disappears."
	},
	QuestType.NETWORK_TRACE: {
		"title_key": "story.case7.title",
		"title_default": "CASE #7: DIGITAL TRACE",
		"briefing_key": "story.case7.briefing",
		"briefing_default": "Phantom left digital footprints. Identify the network topology, calculate throughput, and pinpoint his subnet."
	},
	QuestType.DATA_ARCHIVE: {
		"title_key": "story.case8.title",
		"title_default": "CASE #8: SHADOW ARCHIVE",
		"briefing_key": "story.case8.briefing",
		"briefing_default": "We've gained access to Phantom's database. Parse the structure, filter the records, and extract evidence with SQL."
	},
	QuestType.FINAL_REPORT: {
		"title_key": "story.case9.title",
		"title_default": "CASE #9: THE TRIAL",
		"briefing_key": "story.case9.briefing",
		"briefing_default": "All evidence collected. Prepare the final HTML report and submit the case to court."
	}
}

var selected_quest_type := QuestType.DECRYPTOR
var _scene_transition_in_progress := false
var briefing_label: RichTextLabel = null
var difficulty_label: Label = null

const TITLE_TEXT := "Выбор квеста"
const STATUS_READY := "Выберите модуль и уровень сложности."
const STATUS_LOCKED := "Режим недоступен"

const BTN_CLUES_TEXT := "Сбор улик"
const BTN_RADIO_TEXT := "Радиоперехват"
const BTN_DECRYPTOR_TEXT := "Дешифратор"
const BTN_LIE_TEXT := "Детектор лжи"
const BTN_SCRIPT_TEXT := "Сценарий подозреваемого"
const BTN_CITY_TEXT := "Карта города"
const BTN_ARCHIVE_TEXT := "Архив данных"
const BTN_REPORT_TEXT := "Финальный отчет"
const BTN_NETWORK_TRACE_TEXT := "Сетевой след"
const BTN_BACK_TO_MENU_TEXT := "BACK TO MENU"

const MODAL_TITLE_TEXT := "Выбор сложности"
const COMPLEXITY_A_TEXT := "Сложность A"
const COMPLEXITY_B_TEXT := "Сложность B"
const COMPLEXITY_C_TEXT := "Сложность C"
const BTN_CLOSE_TEXT := "Закрыть"

func _ready() -> void:
	modal.visible = false

	briefing_label = RichTextLabel.new()
	briefing_label.name = "BriefingLabel"
	briefing_label.fit_content = true
	briefing_label.bbcode_enabled = true
	briefing_label.scroll_active = false
	briefing_label.custom_minimum_size = Vector2(0, 60)
	briefing_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	briefing_label.add_theme_font_size_override("normal_font_size", 14)
	briefing_label.add_theme_color_override("default_color", Color(0.72, 0.72, 0.75))
	briefing_label.visible = false

	difficulty_label = Label.new()
	difficulty_label.name = "DifficultyLabel"
	difficulty_label.add_theme_font_size_override("font_size", 13)
	difficulty_label.add_theme_color_override("font_color", Color(0.45, 0.45, 0.48))
	difficulty_label.visible = false

	modal_box.add_child(briefing_label)
	modal_box.move_child(briefing_label, 1)
	modal_box.add_child(difficulty_label)
	modal_box.move_child(difficulty_label, 2)

	_apply_i18n()
	_connect_buttons()
	_disable_unready()
	_on_viewport_size_changed()
	if not get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.connect(_on_viewport_size_changed)
	if not I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.connect(_on_language_changed)
	call_deferred("_animate_intro")

func _exit_tree() -> void:
	if I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.disconnect(_on_language_changed)

func _on_language_changed(_code: String) -> void:
	_apply_i18n()

func _apply_i18n() -> void:
	title_label.text = I18n.tr_key("ui.quest_select.title", {"default": TITLE_TEXT})
	status_label.text = I18n.tr_key("ui.quest_select.status_ready", {"default": STATUS_READY})
	btn_back_to_menu.text = I18n.tr_key("ui.quest_select.back_to_menu", {"default": BTN_BACK_TO_MENU_TEXT})
	status_label.modulate = COLOR_READY
	_set_button_labels()
	_set_modal_labels()
	if modal.visible:
		_show_modal_for_quest(selected_quest_type)

func _set_button_labels() -> void:
	btn_clues.text = I18n.tr_key("ui.quest_select.btn_clues", {"default": BTN_CLUES_TEXT})
	btn_radio.text = I18n.tr_key("ui.quest_select.btn_radio", {"default": BTN_RADIO_TEXT})
	btn_decryptor.text = I18n.tr_key("ui.quest_select.btn_decryptor", {"default": BTN_DECRYPTOR_TEXT})
	btn_lie.text = I18n.tr_key("ui.quest_select.btn_lie", {"default": BTN_LIE_TEXT})
	btn_script.text = I18n.tr_key("ui.quest_select.btn_script", {"default": BTN_SCRIPT_TEXT})
	btn_city.text = I18n.tr_key("ui.quest_select.btn_city", {"default": BTN_CITY_TEXT})
	btn_archive.text = I18n.tr_key("ui.quest_select.btn_archive", {"default": BTN_ARCHIVE_TEXT})
	btn_report.text = I18n.tr_key("ui.quest_select.btn_report", {"default": BTN_REPORT_TEXT})
	btn_network_trace.text = I18n.tr_key("ui.quest_select.btn_network_trace", {"default": BTN_NETWORK_TRACE_TEXT})

func _set_modal_labels() -> void:
	modal_title.text = I18n.tr_key("ui.quest_select.modal_title", {"default": MODAL_TITLE_TEXT})
	btn_complexity_a.text = I18n.tr_key("ui.quest_select.complexity_a", {"default": COMPLEXITY_A_TEXT})
	btn_complexity_b.text = I18n.tr_key("ui.quest_select.complexity_b", {"default": COMPLEXITY_B_TEXT})
	btn_complexity_c.text = I18n.tr_key("ui.quest_select.complexity_c", {"default": COMPLEXITY_C_TEXT})
	btn_close.text = I18n.tr_key("ui.quest_select.modal_back", {"default": BTN_CLOSE_TEXT})
	if difficulty_label != null:
		var select_difficulty_text: String = I18n.tr_key("story.common.select_difficulty", {"default": "Select difficulty:"})
		var divider: String = char(0x2500).repeat(3)
		difficulty_label.text = "%s %s %s" % [divider, select_difficulty_text, divider]

func _connect_buttons() -> void:
	btn_clues.pressed.connect(_show_modal_for_quest.bind(QuestType.CLUES))
	btn_radio.pressed.connect(_show_modal_for_quest.bind(QuestType.RADIO))
	btn_decryptor.pressed.connect(_show_modal_for_quest.bind(QuestType.DECRYPTOR))
	btn_lie.pressed.connect(_show_modal_for_quest.bind(QuestType.LOGIC_GATE))
	btn_script.pressed.connect(_show_modal_for_quest.bind(QuestType.SUSPECT))
	btn_city.pressed.connect(_show_modal_for_quest.bind(QuestType.CITY_MAP))
	btn_network_trace.pressed.connect(_show_modal_for_quest.bind(QuestType.NETWORK_TRACE))
	btn_archive.pressed.connect(_show_modal_for_quest.bind(QuestType.DATA_ARCHIVE))
	btn_report.pressed.connect(_show_modal_for_quest.bind(QuestType.FINAL_REPORT))

	btn_complexity_a.pressed.connect(_on_complexity_a_pressed)
	btn_complexity_b.pressed.connect(_on_complexity_b_pressed)
	btn_complexity_c.pressed.connect(_on_complexity_c_pressed)
	btn_close.pressed.connect(_on_close_modal_pressed)
	btn_back_to_menu.pressed.connect(_on_back_to_menu_pressed)

func _disable_unready() -> void:
	btn_clues.disabled = false
	btn_radio.disabled = false
	btn_script.disabled = false
	btn_city.disabled = false
	btn_archive.disabled = false
	btn_report.disabled = false
	btn_network_trace.disabled = false

func _show_modal_for_quest(quest_type: QuestType) -> void:
	selected_quest_type = quest_type
	_set_complexity_enabled(true, true)

	var info: Dictionary = QUEST_BRIEFINGS.get(quest_type, {})
	if not info.is_empty():
		modal_title.text = I18n.tr_key(
			str(info.get("title_key", "")),
			{"default": str(info.get("title_default", "SELECT DIFFICULTY"))}
		)
		if briefing_label != null:
			briefing_label.text = I18n.tr_key(
				str(info.get("briefing_key", "")),
				{"default": str(info.get("briefing_default", ""))}
			)
			briefing_label.visible = true
		if difficulty_label != null:
			var select_difficulty_text: String = I18n.tr_key("story.common.select_difficulty", {"default": "Select difficulty:"})
			var divider: String = char(0x2500).repeat(3)
			difficulty_label.text = "%s %s %s" % [divider, select_difficulty_text, divider]
			difficulty_label.visible = true
	else:
		modal_title.text = I18n.tr_key("ui.quest_select.modal_title", {"default": "SELECT DIFFICULTY"})
		if briefing_label != null:
			briefing_label.visible = false
		if difficulty_label != null:
			difficulty_label.visible = false

	modal.visible = true

func _on_complexity_a_pressed() -> void:
	GlobalMetrics.current_level_index = 0
	match selected_quest_type:
		QuestType.DECRYPTOR:
			get_tree().change_scene_to_file("res://scenes/Decryptor.tscn")
		QuestType.LOGIC_GATE:
			get_tree().change_scene_to_file("res://scenes/LogicQuestA_v2.tscn")
		QuestType.RADIO:
			get_tree().change_scene_to_file("res://scenes/RadioQuestA.tscn")
		QuestType.SUSPECT:
			get_tree().change_scene_to_file("res://scenes/SuspectQuestA.tscn")
		QuestType.CITY_MAP:
			get_tree().change_scene_to_file("res://scenes/CityMapQuestA.tscn")
		QuestType.DATA_ARCHIVE:
			get_tree().change_scene_to_file("res://scenes/case_07/da7_data_archive_a.tscn")
		QuestType.FINAL_REPORT:
			get_tree().change_scene_to_file("res://scenes/case_08/fr8_final_report_a.tscn")
		QuestType.NETWORK_TRACE:
			get_tree().change_scene_to_file("res://scenes/NetworkTraceQuestA.tscn")
		QuestType.CLUES:
			get_tree().change_scene_to_file("res://scenes/case_01/Case01Flow.tscn")

func _on_complexity_b_pressed() -> void:
	if selected_quest_type == QuestType.FINAL_REPORT:
		GlobalMetrics.current_level_index = 0
		get_tree().change_scene_to_file("res://scenes/case_08/fr8_final_report_b.tscn")
		return
	if selected_quest_type == QuestType.DECRYPTOR:
		GlobalMetrics.current_level_index = 15
		get_tree().change_scene_to_file("res://scenes/Decryptor.tscn")
	elif selected_quest_type == QuestType.LOGIC_GATE:
		get_tree().change_scene_to_file("res://scenes/LogicQuestB_v3.tscn")
	elif selected_quest_type == QuestType.RADIO:
		get_tree().change_scene_to_file("res://scenes/RadioQuestB.tscn")
	elif selected_quest_type == QuestType.SUSPECT:
		get_tree().change_scene_to_file("res://scenes/RestoreQuestB.tscn")
	elif selected_quest_type == QuestType.CITY_MAP:
		get_tree().change_scene_to_file("res://scenes/CityMapQuestB.tscn")
	elif selected_quest_type == QuestType.DATA_ARCHIVE:
		get_tree().change_scene_to_file("res://scenes/case_07/da7_data_archive_b.tscn")
	elif selected_quest_type == QuestType.NETWORK_TRACE:
		get_tree().change_scene_to_file("res://scenes/NetworkTraceQuestB.tscn")
	elif selected_quest_type == QuestType.CLUES:
		get_tree().change_scene_to_file("res://scenes/case_01/DigitalResusQuestB.tscn")

func _on_complexity_c_pressed() -> void:
	if selected_quest_type == QuestType.FINAL_REPORT:
		GlobalMetrics.current_level_index = 0
		get_tree().change_scene_to_file("res://scenes/case_08/fr8_final_report_c.tscn")
		return
	if selected_quest_type == QuestType.DECRYPTOR:
		get_tree().change_scene_to_file("res://scenes/MatrixDecryptor.tscn")
	elif selected_quest_type == QuestType.LOGIC_GATE:
		get_tree().change_scene_to_file("res://scenes/LogicQuestC_v3.tscn")
	elif selected_quest_type == QuestType.RADIO:
		get_tree().change_scene_to_file("res://scenes/RadioQuestC.tscn")
	elif selected_quest_type == QuestType.SUSPECT:
		get_tree().change_scene_to_file("res://scenes/DisarmQuestC.tscn")
	elif selected_quest_type == QuestType.CITY_MAP:
		get_tree().change_scene_to_file("res://scenes/CityMapQuestC.tscn")
	elif selected_quest_type == QuestType.DATA_ARCHIVE:
		get_tree().change_scene_to_file("res://scenes/case_07/da7_data_archive_c.tscn")
	elif selected_quest_type == QuestType.NETWORK_TRACE:
		get_tree().change_scene_to_file("res://scenes/NetworkTraceQuestC_v2.tscn")
	elif selected_quest_type == QuestType.CLUES:
		get_tree().change_scene_to_file("res://scenes/case_01/DigitalResusQuestC.tscn")

func _change_scene_safe(path: String) -> void:
	if _scene_transition_in_progress:
		return
	_scene_transition_in_progress = true
	modal.visible = false
	var err: int = get_tree().change_scene_to_file(path)
	if err != OK:
		_scene_transition_in_progress = false
		status_label.modulate = COLOR_LOCKED
		status_label.text = "Transition error (%d). Try again." % err
		push_warning("Scene change failed for %s with err=%d" % [path, err])

func _on_close_modal_pressed() -> void:
	modal.visible = false

func _on_back_to_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _set_complexity_enabled(enable_b: bool, enable_c: bool, show_b: bool = true, show_c: bool = true) -> void:
	btn_complexity_b.disabled = not enable_b
	btn_complexity_c.disabled = not enable_c
	btn_complexity_b.visible = show_b
	btn_complexity_c.visible = show_c

func _on_viewport_size_changed() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var width: float = viewport_size.x
	if _is_phone_landscape(viewport_size):
		quest_grid.columns = 3
		_apply_layout_profile(38, 15, 70, 8, 10, 6)
		_apply_modal_profile(28, 19, clampf(viewport_size.x - 40.0, 320.0, 480.0), clampf(viewport_size.y - 24.0, 220.0, 320.0))
	elif width < MOBILE_BREAKPOINT:
		quest_grid.columns = 1
		_apply_layout_profile(48, 18, 100, 12, 16, 12)
		_apply_modal_profile(36, 24, clampf(viewport_size.x - 40.0, 320.0, 560.0), clampf(viewport_size.y - 60.0, 260.0, 420.0))
	elif width < TABLET_BREAKPOINT:
		quest_grid.columns = 2
		_apply_layout_profile(54, 19, 108, 14, 20, 14)
		_apply_modal_profile(40, 27, 560.0, 400.0)
	else:
		quest_grid.columns = 3
		_apply_layout_profile(58, 20, 118, 14, 24, 16)
		_apply_modal_profile(44, 30, 620.0, 420.0)

func _is_phone_landscape(size: Vector2) -> bool:
	return size.x > size.y and size.y <= PHONE_LANDSCAPE_MAX_HEIGHT

func _apply_layout_profile(title_size: int, info_size: int, button_height: float, gap: int, margin_side: int, margin_vertical: int) -> void:
	title_label.add_theme_font_size_override("font_size", title_size)
	status_label.add_theme_font_size_override("font_size", info_size)
	status_label.custom_minimum_size.y = max(32.0, button_height * 0.4)
	main_layout.add_theme_constant_override("separation", gap + 6)
	quest_grid.add_theme_constant_override("h_separation", gap)
	quest_grid.add_theme_constant_override("v_separation", gap)
	safe_area.add_theme_constant_override("margin_left", margin_side)
	safe_area.add_theme_constant_override("margin_right", margin_side)
	safe_area.add_theme_constant_override("margin_top", margin_vertical)
	safe_area.add_theme_constant_override("margin_bottom", margin_vertical)
	for btn in _all_quest_buttons():
		btn.custom_minimum_size = Vector2(0.0, button_height)
		btn.add_theme_font_size_override("font_size", clamp(info_size + 1, 16, 20))
	btn_back_to_menu.custom_minimum_size = Vector2(0.0, max(48.0, button_height * 0.68))
	btn_back_to_menu.add_theme_font_size_override("font_size", clamp(info_size + 1, 16, 20))

func _apply_modal_profile(modal_title_size: int, button_font_size: int, min_width: float, min_height: float) -> void:
	modal_box.custom_minimum_size = Vector2(min_width, min_height)
	modal_title.add_theme_font_size_override("font_size", modal_title_size)
	btn_complexity_a.add_theme_font_size_override("font_size", button_font_size)
	btn_complexity_b.add_theme_font_size_override("font_size", button_font_size)
	btn_complexity_c.add_theme_font_size_override("font_size", button_font_size)
	btn_complexity_a.custom_minimum_size.y = max(56.0, float(button_font_size) * 2.25)
	btn_complexity_b.custom_minimum_size.y = max(56.0, float(button_font_size) * 2.25)
	btn_complexity_c.custom_minimum_size.y = max(56.0, float(button_font_size) * 2.25)
	btn_close.add_theme_font_size_override("font_size", max(18, button_font_size - 5))
	btn_close.custom_minimum_size.y = max(48.0, float(button_font_size) * 2.0)

func _animate_intro() -> void:
	title_label.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(title_label, "modulate:a", 1.0, 0.3)

	for i in range(_all_quest_buttons().size()):
		var btn: Button = _all_quest_buttons()[i]
		btn.modulate.a = 0.0
		btn.scale = Vector2(0.97, 0.97)
		btn.pivot_offset = btn.size * 0.5
		var item_tween: Tween = create_tween()
		var delay: float = 0.06 * float(i)
		item_tween.tween_property(btn, "modulate:a", 1.0, 0.2).set_delay(delay)
		item_tween.parallel().tween_property(btn, "scale", Vector2.ONE, 0.24).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _all_quest_buttons() -> Array[Button]:
	return [
		btn_clues,
		btn_radio,
		btn_decryptor,
		btn_lie,
		btn_script,
		btn_city,
		btn_archive,
		btn_report,
		btn_network_trace
	]
