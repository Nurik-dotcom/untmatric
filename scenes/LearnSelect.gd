extends Control

const PHONE_LANDSCAPE_MAX_HEIGHT := 520.0
const MOBILE_BREAKPOINT := 840.0
const TABLET_BREAKPOINT := 1300.0

@onready var safe_area: MarginContainer = $SafeArea
@onready var main_layout: VBoxContainer = $SafeArea/MainLayout
@onready var title_label: Label = $SafeArea/MainLayout/Title
@onready var quest_grid: GridContainer = $SafeArea/MainLayout/QuestGrid
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

const COLOR_READY := Color(0.88, 0.88, 0.88, 1.0)
const COLOR_LOCKED := Color(0.92, 0.36, 0.4, 1.0)

const TITLE_TEXT := "ОБУЧЕНИЕ"
const STATUS_READY := "Выберите учебный модуль"
const STATUS_LOCKED := "Этот модуль пока не готов"

const BTN_CLUES_TEXT := "Цифровая реанимация (скоро)"
const BTN_RADIO_TEXT := "Радиоперехват A"
const BTN_DECRYPTOR_TEXT := "Дешифрование A"
const BTN_LIE_TEXT := "Детектор лжи A"
const BTN_SCRIPT_TEXT := "Скрипт подозреваемого (скоро)"
const BTN_CITY_TEXT := "Карта города (скоро)"
const BTN_ARCHIVE_TEXT := "Архив данных (скоро)"
const BTN_REPORT_TEXT := "Финальный отчет (скоро)"
const BTN_NETWORK_TRACE_TEXT := "Сетевой след (скоро)"

func _ready() -> void:
	title_label.text = TITLE_TEXT
	status_label.text = STATUS_READY
	status_label.modulate = COLOR_READY

	_set_button_labels()
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

func _connect_buttons() -> void:
	btn_decryptor.pressed.connect(_on_decryptor_pressed)
	btn_lie.pressed.connect(_on_lie_detector_pressed)
	btn_radio.pressed.connect(_on_radio_pressed)
	btn_clues.pressed.connect(_on_locked_pressed)
	btn_script.pressed.connect(_on_locked_pressed)
	btn_city.pressed.connect(_on_locked_pressed)
	btn_archive.pressed.connect(_on_locked_pressed)
	btn_report.pressed.connect(_on_locked_pressed)
	btn_network_trace.pressed.connect(_on_locked_pressed)

func _disable_unready() -> void:
	btn_clues.disabled = true
	btn_radio.disabled = false
	btn_script.disabled = true
	btn_city.disabled = true
	btn_archive.disabled = true
	btn_report.disabled = true
	btn_network_trace.disabled = true

func _on_decryptor_pressed() -> void:
	GlobalMetrics.current_level_index = 0
	get_tree().change_scene_to_file("res://scenes/Decryptor.tscn")

func _on_lie_detector_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/LogicQuestA.tscn")

func _on_radio_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/RadioQuestA.tscn")

func _on_locked_pressed() -> void:
	status_label.text = STATUS_LOCKED
	status_label.modulate = COLOR_LOCKED

func _on_viewport_size_changed() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var width: float = viewport_size.x
	if _is_phone_landscape(viewport_size):
		quest_grid.columns = 3
		_apply_layout_profile(38, 15, 70, 8, 10, 6)
	elif width < MOBILE_BREAKPOINT:
		quest_grid.columns = 1
		_apply_layout_profile(48, 18, 100, 12, 16, 12)
	elif width < TABLET_BREAKPOINT:
		quest_grid.columns = 2
		_apply_layout_profile(54, 19, 108, 14, 20, 14)
	else:
		quest_grid.columns = 3
		_apply_layout_profile(58, 20, 118, 14, 24, 16)

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
	for btn in _all_module_buttons():
		btn.custom_minimum_size = Vector2(0.0, button_height)
		btn.add_theme_font_size_override("font_size", clamp(info_size + 1, 16, 20))

func _animate_intro() -> void:
	title_label.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(title_label, "modulate:a", 1.0, 0.3)

	for i in range(_all_module_buttons().size()):
		var btn: Button = _all_module_buttons()[i]
		btn.modulate.a = 0.0
		btn.scale = Vector2(0.97, 0.97)
		btn.pivot_offset = btn.size * 0.5
		var item_tween: Tween = create_tween()
		var delay: float = 0.06 * float(i)
		item_tween.tween_property(btn, "modulate:a", 1.0, 0.2).set_delay(delay)
		item_tween.parallel().tween_property(btn, "scale", Vector2.ONE, 0.24).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _all_module_buttons() -> Array[Button]:
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
