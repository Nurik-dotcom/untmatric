extends Control

@onready var status_label = $MainLayout/StatusLabel

@onready var btn_clues = $MainLayout/QuestGrid/CluesButton
@onready var btn_radio = $MainLayout/QuestGrid/RadioButton
@onready var btn_decryptor = $MainLayout/QuestGrid/DecryptorButton
@onready var btn_lie = $MainLayout/QuestGrid/LieDetectorButton
@onready var btn_script = $MainLayout/QuestGrid/SuspectScriptButton
@onready var btn_city = $MainLayout/QuestGrid/CityMapButton
@onready var btn_archive = $MainLayout/QuestGrid/DataArchiveButton
@onready var btn_report = $MainLayout/QuestGrid/FinalReportButton
@onready var btn_network_trace = $MainLayout/QuestGrid/NetworkTraceButton

const TITLE_TEXT = "Обучение"
const STATUS_READY = "Выберите модуль обучения"
const STATUS_LOCKED = "Этот модуль пока не готов"

const BTN_CLUES_TEXT = "Улики (скоро)"
const BTN_RADIO_TEXT = "Радиоперехват A"
const BTN_DECRYPTOR_TEXT = "Дешифрование A"
const BTN_LIE_TEXT = "Детектор лжи A"
const BTN_SCRIPT_TEXT = "Скрипт подозреваемого (скоро)"
const BTN_CITY_TEXT = "Карта города (скоро)"
const BTN_ARCHIVE_TEXT = "Архив данных (скоро)"
const BTN_REPORT_TEXT = "Финальный отчет (скоро)"
const BTN_NETWORK_TRACE_TEXT = "Сетевой след (скоро)"

func _ready():
	$MainLayout/Title.text = TITLE_TEXT
	status_label.text = STATUS_READY
	_set_button_labels()
	_connect_buttons()
	_disable_unready()

func _set_button_labels():
	btn_clues.text = BTN_CLUES_TEXT
	btn_radio.text = BTN_RADIO_TEXT
	btn_decryptor.text = BTN_DECRYPTOR_TEXT
	btn_lie.text = BTN_LIE_TEXT
	btn_script.text = BTN_SCRIPT_TEXT
	btn_city.text = BTN_CITY_TEXT
	btn_archive.text = BTN_ARCHIVE_TEXT
	btn_report.text = BTN_REPORT_TEXT
	btn_network_trace.text = BTN_NETWORK_TRACE_TEXT

func _connect_buttons():
	btn_decryptor.pressed.connect(_on_decryptor_pressed)
	btn_lie.pressed.connect(_on_lie_detector_pressed)
	btn_radio.pressed.connect(_on_radio_pressed)
	btn_clues.pressed.connect(_on_locked_pressed)
	btn_script.pressed.connect(_on_locked_pressed)
	btn_city.pressed.connect(_on_locked_pressed)
	btn_archive.pressed.connect(_on_locked_pressed)
	btn_report.pressed.connect(_on_locked_pressed)
	btn_network_trace.pressed.connect(_on_locked_pressed)

func _disable_unready():
	btn_clues.disabled = true
	btn_radio.disabled = false
	btn_script.disabled = true
	btn_city.disabled = true
	btn_archive.disabled = true
	btn_report.disabled = true
	btn_network_trace.disabled = true

func _on_decryptor_pressed():
	GlobalMetrics.current_level_index = 0
	get_tree().change_scene_to_file("res://scenes/Decryptor.tscn")

func _on_lie_detector_pressed():
	get_tree().change_scene_to_file("res://scenes/LogicQuestA.tscn")

func _on_radio_pressed():
	get_tree().change_scene_to_file("res://scenes/radio_intercept/RadioQuestA.tscn")

func _on_locked_pressed():
	status_label.text = STATUS_LOCKED
