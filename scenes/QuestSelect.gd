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
var selected_quest_type := QuestType.DECRYPTOR

const TITLE_TEXT := "ВЫБОР КВЕСТА"
const STATUS_READY := "Выберите квест"
const STATUS_LOCKED := "Этот квест пока не готов"

const BTN_CLUES_TEXT := "Цифровая реанимация"
const BTN_RADIO_TEXT := "Радиоперехват"
const BTN_DECRYPTOR_TEXT := "Дешифрование"
const BTN_LIE_TEXT := "Детектор лжи"
const BTN_SCRIPT_TEXT := "Скрипт подозреваемого"
const BTN_CITY_TEXT := "Карта города"
const BTN_ARCHIVE_TEXT := "Архив данных"
const BTN_REPORT_TEXT := "Финальный отчет"
const BTN_NETWORK_TRACE_TEXT := "Сетевой след"

const MODAL_TITLE_TEXT := "ВЫБОР СЛОЖНОСТИ"
const COMPLEXITY_A_TEXT := "СЛОЖНОСТЬ A"
const COMPLEXITY_B_TEXT := "СЛОЖНОСТЬ B"
const COMPLEXITY_C_TEXT := "СЛОЖНОСТЬ C"
const BTN_CLOSE_TEXT := "НАЗАД"

func _ready() -> void:
	modal.visible = false
	title_label.text = TITLE_TEXT
	status_label.text = STATUS_READY
	status_label.modulate = COLOR_READY

	_set_button_labels()
	_set_modal_labels()
	_connect_buttons()
	_disable_unready()
	_on_viewport_size_changed()
	if not get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.connect(_on_viewport_size_changed)
	call_deferred("_animate_intro")

func _set_button_labels() -> void:
	btn_clues.text = BTN_CLUES_TEXT
	btn_radio.text = BTN_RADIO_TEXT
	btn_decryptor.text = BTN_DECRYPTOR_TEXT
	btn_lie.text = BTN_LIE_TEXT
	btn_script.text = BTN_SCRIPT_TEXT
	btn_city.text = BTN_CITY_TEXT
	btn_archive.text = BTN_ARCHIVE_TEXT
	btn_report.text = BTN_REPORT_TEXT
	btn_network_trace.text = BTN_NETWORK_TRACE_TEXT

func _set_modal_labels() -> void:
	modal_title.text = MODAL_TITLE_TEXT
	btn_complexity_a.text = COMPLEXITY_A_TEXT
	btn_complexity_b.text = COMPLEXITY_B_TEXT
	btn_complexity_c.text = COMPLEXITY_C_TEXT
	btn_close.text = BTN_CLOSE_TEXT

func _connect_buttons() -> void:
	btn_decryptor.pressed.connect(_on_decryptor_pressed)
	btn_lie.pressed.connect(_on_lie_detector_pressed)
	btn_radio.pressed.connect(_on_radio_pressed)
	btn_clues.pressed.connect(_on_clues_pressed)
	btn_script.pressed.connect(_on_script_pressed)
	btn_city.pressed.connect(_on_city_pressed)
	btn_archive.pressed.connect(_on_archive_pressed)
	btn_report.pressed.connect(_on_report_pressed)
	btn_network_trace.pressed.connect(_on_network_trace_pressed)

	btn_complexity_a.pressed.connect(_on_complexity_a_pressed)
	btn_complexity_b.pressed.connect(_on_complexity_b_pressed)
	btn_complexity_c.pressed.connect(_on_complexity_c_pressed)
	btn_close.pressed.connect(_on_close_modal_pressed)

func _disable_unready() -> void:
	btn_clues.disabled = false
	btn_radio.disabled = false
	btn_script.disabled = false
	btn_city.disabled = false
	btn_archive.disabled = false
	btn_report.disabled = false
	btn_network_trace.disabled = false
	btn_complexity_c.disabled = true

func _on_decryptor_pressed() -> void:
	selected_quest_type = QuestType.DECRYPTOR
	_set_complexity_enabled(true, true)
	modal.visible = true

func _on_lie_detector_pressed() -> void:
	selected_quest_type = QuestType.LOGIC_GATE
	_set_complexity_enabled(true, true)
	modal.visible = true

func _on_radio_pressed() -> void:
	selected_quest_type = QuestType.RADIO
	_set_complexity_enabled(true, true)
	modal.visible = true

func _on_clues_pressed() -> void:
	selected_quest_type = QuestType.CLUES
	_set_complexity_enabled(true, true)
	modal.visible = true

func _on_script_pressed() -> void:
	selected_quest_type = QuestType.SUSPECT
	_set_complexity_enabled(true, true)
	modal.visible = true

func _on_city_pressed() -> void:
	selected_quest_type = QuestType.CITY_MAP
	_set_complexity_enabled(true, true)
	modal.visible = true

func _on_archive_pressed() -> void:
	selected_quest_type = QuestType.DATA_ARCHIVE
	_set_complexity_enabled(true, true)
	modal.visible = true

func _on_report_pressed() -> void:
	selected_quest_type = QuestType.FINAL_REPORT
	_set_complexity_enabled(true, true)
	modal.visible = true

func _on_network_trace_pressed() -> void:
	selected_quest_type = QuestType.NETWORK_TRACE
	_set_complexity_enabled(true, true)
	modal.visible = true

func _on_complexity_a_pressed() -> void:
	GlobalMetrics.current_level_index = 0
	match selected_quest_type:
		QuestType.DECRYPTOR:
			get_tree().change_scene_to_file("res://scenes/Decryptor.tscn")
		QuestType.LOGIC_GATE:
			get_tree().change_scene_to_file("res://scenes/LogicQuestA.tscn")
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
			get_tree().change_scene_to_file("res://scenes/case_01/DigitalResusQuestA.tscn")

func _on_complexity_b_pressed() -> void:
	if selected_quest_type == QuestType.FINAL_REPORT:
		GlobalMetrics.current_level_index = 0
		get_tree().change_scene_to_file("res://scenes/case_08/fr8_final_report_b.tscn")
		return
	if selected_quest_type == QuestType.DECRYPTOR:
		GlobalMetrics.current_level_index = 15
		get_tree().change_scene_to_file("res://scenes/Decryptor.tscn")
	elif selected_quest_type == QuestType.LOGIC_GATE:
		get_tree().change_scene_to_file("res://scenes/LogicQuestB.tscn")
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
		get_tree().change_scene_to_file("res://scenes/LogicQuestC.tscn")
	elif selected_quest_type == QuestType.RADIO:
		get_tree().change_scene_to_file("res://scenes/RadioQuestC.tscn")
	elif selected_quest_type == QuestType.SUSPECT:
		get_tree().change_scene_to_file("res://scenes/DisarmQuestC.tscn")
	elif selected_quest_type == QuestType.CITY_MAP:
		get_tree().change_scene_to_file("res://scenes/CityMapQuestC.tscn")
	elif selected_quest_type == QuestType.DATA_ARCHIVE:
		get_tree().change_scene_to_file("res://scenes/case_07/da7_data_archive_c.tscn")
	elif selected_quest_type == QuestType.NETWORK_TRACE:
		get_tree().change_scene_to_file("res://scenes/NetworkTraceQuestC.tscn")
	elif selected_quest_type == QuestType.CLUES:
		get_tree().change_scene_to_file("res://scenes/case_01/DigitalResusQuestC.tscn")

func _on_close_modal_pressed() -> void:
	modal.visible = false

func _set_complexity_enabled(enable_b: bool, enable_c: bool) -> void:
	btn_complexity_b.disabled = not enable_b
	btn_complexity_c.disabled = not enable_c

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
