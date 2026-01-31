extends Control

const TITLE_TEXT = "\u0412\u044b\u0431\u043e\u0440 \u043a\u0432\u0435\u0441\u0442\u0430"
const STATUS_TEXT = "\u0412\u044b\u0431\u0435\u0440\u0438\u0442\u0435 \u0442\u0435\u043c\u0443"

const TOPIC_CLUES = "\u0423\u043b\u0438\u043a\u0438"
const TOPIC_RADIO = "\u0420\u0430\u0434\u0438\u043e\u043f\u0435\u0440\u0435\u0445\u0432\u0430\u0442"
const TOPIC_DECRYPTOR = "\u0414\u0435\u0448\u0438\u0444\u0440\u043e\u0432\u0430\u043d\u0438\u0435"
const TOPIC_LIE = "\u0414\u0435\u0442\u0435\u043a\u0442\u043e\u0440 \u043b\u0436\u0438"
const TOPIC_SCRIPT = "\u0421\u043a\u0440\u0438\u043f\u0442 \u043f\u043e\u0434\u043e\u0437\u0440\u0435\u0432\u0430\u0435\u043c\u043e\u0433\u043e"
const TOPIC_CITY = "\u041a\u0430\u0440\u0442\u0430 \u0433\u043e\u0440\u043e\u0434\u0430"
const TOPIC_ARCHIVE = "\u0410\u0440\u0445\u0438\u0432 \u0434\u0430\u043d\u043d\u044b\u0445"
const TOPIC_REPORT = "\u0424\u0438\u043d\u0430\u043b\u044c\u043d\u044b\u0439 \u043e\u0442\u0447\u0435\u0442"

const STATUS_FORMAT = "\u00ab%s\u00bb \u043f\u043e\u043a\u0430 \u0432 \u0440\u0430\u0437\u0440\u0430\u0431\u043e\u0442\u043a\u0435."

const MODAL_TITLE = "\u0412\u044b\u0431\u043e\u0440 \u0441\u043b\u043e\u0436\u043d\u043e\u0441\u0442\u0438"
const MODAL_HINT_FORMAT = "\u0420\u0435\u043a\u043e\u043c\u0435\u043d\u0434\u0443\u0435\u043c: \u0441\u043b\u043e\u0436\u043d\u043e\u0441\u0442\u044c %s"
const COMPLEXITY_A_TEXT = "\u0421\u043b\u043e\u0436\u043d\u043e\u0441\u0442\u044c A"
const COMPLEXITY_B_TEXT = "\u0421\u043b\u043e\u0436\u043d\u043e\u0441\u0442\u044c B (\u0441\u043a\u043e\u0440\u043e)"
const COMPLEXITY_C_TEXT = "\u0421\u043b\u043e\u0436\u043d\u043e\u0441\u0442\u044c C (\u0441\u043a\u043e\u0440\u043e)"
const MODAL_BACK_TEXT = "\u041d\u0430\u0437\u0430\u0434"

@onready var title_label = $Main/Title
@onready var status_label = $Main/StatusLabel

@onready var btn_clues = $Main/GridCenter/Grid/CluesButton
@onready var btn_radio = $Main/GridCenter/Grid/RadioButton
@onready var btn_decryptor = $Main/GridCenter/Grid/DecryptorButton
@onready var btn_lie = $Main/GridCenter/Grid/LieDetectorButton
@onready var btn_script = $Main/GridCenter/Grid/SuspectScriptButton
@onready var btn_city = $Main/GridCenter/Grid/CityMapButton
@onready var btn_archive = $Main/GridCenter/Grid/DataArchiveButton
@onready var btn_report = $Main/GridCenter/Grid/FinalReportButton

@onready var modal = $ModeSelectionModal
@onready var modal_title = $ModeSelectionModal/ModalCenter/ModalBox/ModalTitle
@onready var modal_hint = $ModeSelectionModal/ModalCenter/ModalBox/ModalHint
@onready var btn_complexity_a = $ModeSelectionModal/ModalCenter/ModalBox/BtnComplexityA
@onready var btn_complexity_b = $ModeSelectionModal/ModalCenter/ModalBox/BtnComplexityB
@onready var btn_complexity_c = $ModeSelectionModal/ModalCenter/ModalBox/BtnComplexityC
@onready var btn_modal_close = $ModeSelectionModal/ModalCenter/ModalBox/BtnClose

var pending_topic: String = ""
var recommended_complexity: String = "A"

func _ready():
	title_label.text = TITLE_TEXT
	status_label.text = STATUS_TEXT

	btn_clues.text = TOPIC_CLUES
	btn_radio.text = TOPIC_RADIO
	btn_decryptor.text = TOPIC_DECRYPTOR
	btn_lie.text = TOPIC_LIE
	btn_script.text = TOPIC_SCRIPT
	btn_city.text = TOPIC_CITY
	btn_archive.text = TOPIC_ARCHIVE
	btn_report.text = TOPIC_REPORT

	modal_title.text = MODAL_TITLE
	btn_complexity_a.text = COMPLEXITY_A_TEXT
	btn_complexity_b.text = COMPLEXITY_B_TEXT
	btn_complexity_c.text = COMPLEXITY_C_TEXT
	btn_modal_close.text = MODAL_BACK_TEXT
	btn_complexity_b.disabled = true
	btn_complexity_c.disabled = true

	btn_clues.pressed.connect(_on_topic_pressed.bind(TOPIC_CLUES))
	btn_radio.pressed.connect(_on_topic_pressed.bind(TOPIC_RADIO))
	btn_decryptor.pressed.connect(_on_topic_pressed.bind(TOPIC_DECRYPTOR))
	btn_lie.pressed.connect(_on_topic_pressed.bind(TOPIC_LIE))
	btn_script.pressed.connect(_on_topic_pressed.bind(TOPIC_SCRIPT))
	btn_city.pressed.connect(_on_topic_pressed.bind(TOPIC_CITY))
	btn_archive.pressed.connect(_on_topic_pressed.bind(TOPIC_ARCHIVE))
	btn_report.pressed.connect(_on_topic_pressed.bind(TOPIC_REPORT))

	btn_complexity_a.pressed.connect(_on_complexity_pressed.bind("A"))
	btn_complexity_b.pressed.connect(_on_complexity_pressed.bind("B"))
	btn_complexity_c.pressed.connect(_on_complexity_pressed.bind("C"))
	btn_modal_close.pressed.connect(_hide_modal)

func _on_topic_pressed(topic_name: String):
	if topic_name == TOPIC_DECRYPTOR or topic_name == TOPIC_LIE:
		pending_topic = topic_name
		recommended_complexity = "A"
		_show_modal()
		return

	status_label.text = STATUS_FORMAT % topic_name

func _show_modal():
	modal_hint.text = MODAL_HINT_FORMAT % recommended_complexity
	modal.visible = true

func _hide_modal():
	modal.visible = false

func _on_complexity_pressed(level: String):
	GlobalMetrics.selected_complexity = level
	_hide_modal()
	if pending_topic == TOPIC_DECRYPTOR:
		get_tree().change_scene_to_file("res://scenes/Decryptor.tscn")
	elif pending_topic == TOPIC_LIE:
		get_tree().change_scene_to_file("res://scenes/LogicQuestA.tscn")
