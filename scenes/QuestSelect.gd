extends Control

@onready var status_label = $Main/StatusLabel

@onready var btn_clues = $Main/Grid/CluesButton
@onready var btn_radio = $Main/Grid/RadioButton
@onready var btn_decryptor = $Main/Grid/DecryptorButton
@onready var btn_lie = $Main/Grid/LieDetectorButton
@onready var btn_script = $Main/Grid/SuspectScriptButton
@onready var btn_city = $Main/Grid/CityMapButton
@onready var btn_archive = $Main/Grid/DataArchiveButton
@onready var btn_report = $Main/Grid/FinalReportButton

func _ready():
	btn_clues.pressed.connect(_on_topic_pressed.bind("Улики"))
	btn_radio.pressed.connect(_on_topic_pressed.bind("Радиоперехват"))
	btn_decryptor.pressed.connect(_on_topic_pressed.bind("Дешифрование"))
	btn_lie.pressed.connect(_on_topic_pressed.bind("Детектор лжи"))
	btn_script.pressed.connect(_on_topic_pressed.bind("Скрипт подозреваемого"))
	btn_city.pressed.connect(_on_topic_pressed.bind("Карта города"))
	btn_archive.pressed.connect(_on_topic_pressed.bind("Архив данных"))
	btn_report.pressed.connect(_on_topic_pressed.bind("Финальный отчет"))

func _on_topic_pressed(topic_name: String):
	if topic_name == "Дешифрование":
		get_tree().change_scene_to_file("res://scenes/Decryptor.tscn")
		return

	status_label.text = "«%s» пока в разработке." % topic_name
