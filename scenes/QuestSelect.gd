extends Control

@onready var modal = $ModalLayer/ModeSelectionModal
@onready var status_label = $MainLayout/StatusLabel

@onready var btn_clues = $MainLayout/QuestGrid/CluesButton
@onready var btn_radio = $MainLayout/QuestGrid/RadioButton
@onready var btn_decryptor = $MainLayout/QuestGrid/DecryptorButton
@onready var btn_lie = $MainLayout/QuestGrid/LieDetectorButton
@onready var btn_script = $MainLayout/QuestGrid/SuspectScriptButton
@onready var btn_city = $MainLayout/QuestGrid/CityMapButton
@onready var btn_archive = $MainLayout/QuestGrid/DataArchiveButton
@onready var btn_report = $MainLayout/QuestGrid/FinalReportButton

@onready var btn_complexity_a = $ModalLayer/ModeSelectionModal/CenterContainer/VBoxContainer/BtnComplexityA
@onready var btn_complexity_b = $ModalLayer/ModeSelectionModal/CenterContainer/VBoxContainer/BtnComplexityB
@onready var btn_complexity_c = $ModalLayer/ModeSelectionModal/CenterContainer/VBoxContainer/BtnComplexityC
@onready var btn_close = $ModalLayer/ModeSelectionModal/CenterContainer/VBoxContainer/BtnClose
@onready var modal_title = $ModalLayer/ModeSelectionModal/CenterContainer/VBoxContainer/ModalTitle

enum QuestType { DECRYPTOR, LOGIC_GATE, RADIO, SUSPECT }
var selected_quest_type = QuestType.DECRYPTOR

const TITLE_TEXT = "\u0412\u044b\u0431\u043e\u0440 \u043a\u0432\u0435\u0441\u0442\u0430"
const STATUS_READY = "\u0412\u044b\u0431\u0435\u0440\u0438\u0442\u0435 \u043a\u0432\u0435\u0441\u0442"
const STATUS_LOCKED = "\u042d\u0442\u043e\u0442 \u043a\u0432\u0435\u0441\u0442 \u043f\u043e\u043a\u0430 \u043d\u0435 \u0433\u043e\u0442\u043e\u0432"

const BTN_CLUES_TEXT = "\u0423\u043b\u0438\u043a\u0438 (c\u043a\u043e\u0440\u043e)"
const BTN_RADIO_TEXT = "\u0420\u0430\u0434\u0438\u043e\u043f\u0435\u0440\u0435\u0445\u0432\u0430\u0442"
const BTN_DECRYPTOR_TEXT = "\u0414\u0435\u0448\u0438\u0444\u0440\u043e\u0432\u0430\u043d\u0438\u0435"
const BTN_LIE_TEXT = "\u0414\u0435\u0442\u0435\u043a\u0442\u043e\u0440 \u043b\u0436\u0438"
const BTN_SCRIPT_TEXT = "\u0421\u043a\u0440\u0438\u043f\u0442 \u043f\u043e\u0434\u043e\u0437\u0440\u0435\u0432\u0430\u0435\u043c\u043e\u0433\u043e"
const BTN_CITY_TEXT = "\u041a\u0430\u0440\u0442\u0430 \u0433\u043e\u0440\u043e\u0434\u0430 (c\u043a\u043e\u0440\u043e)"
const BTN_ARCHIVE_TEXT = "\u0410\u0440\u0445\u0438\u0432 \u0434\u0430\u043d\u043d\u044b\u0445 (c\u043a\u043e\u0440\u043e)"
const BTN_REPORT_TEXT = "\u0424\u0438\u043d\u0430\u043b\u044c\u043d\u044b\u0439 \u043e\u0442\u0447\u0435\u0442 (c\u043a\u043e\u0440\u043e)"

const MODAL_TITLE_TEXT = "\u0412\u044b\u0431\u043e\u0440 \u0441\u043b\u043e\u0436\u043d\u043e\u0441\u0442\u0438"
const COMPLEXITY_A_TEXT = "\u0421\u043b\u043e\u0436\u043d\u043e\u0441\u0442\u044c A"
const COMPLEXITY_B_TEXT = "\u0421\u043b\u043e\u0436\u043d\u043e\u0441\u0442\u044c B"
const COMPLEXITY_C_TEXT = "\u0421\u043b\u043e\u0436\u043d\u043e\u0441\u0442\u044c C"
const BTN_CLOSE_TEXT = "\u041d\u0430\u0437\u0430\u0434"

func _ready():
	modal.visible = false
	status_label.text = STATUS_READY
	_set_button_labels()
	_set_modal_labels()
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

func _set_modal_labels():
	modal_title.text = MODAL_TITLE_TEXT
	btn_complexity_a.text = COMPLEXITY_A_TEXT
	btn_complexity_b.text = COMPLEXITY_B_TEXT
	btn_complexity_c.text = COMPLEXITY_C_TEXT
	btn_close.text = BTN_CLOSE_TEXT

func _connect_buttons():
	btn_decryptor.pressed.connect(_on_decryptor_pressed)
	btn_lie.pressed.connect(_on_lie_detector_pressed)
	btn_radio.pressed.connect(_on_radio_pressed)
	btn_clues.pressed.connect(_on_locked_pressed)
	btn_script.pressed.connect(_on_script_pressed)
	btn_city.pressed.connect(_on_locked_pressed)
	btn_archive.pressed.connect(_on_locked_pressed)
	btn_report.pressed.connect(_on_locked_pressed)

	btn_complexity_a.pressed.connect(_on_complexity_a_pressed)
	btn_complexity_b.pressed.connect(_on_complexity_b_pressed)
	btn_complexity_c.pressed.connect(_on_complexity_c_pressed)
	btn_close.pressed.connect(_on_close_modal_pressed)

func _disable_unready():
	btn_clues.disabled = true
	btn_radio.disabled = false
	btn_script.disabled = false
	btn_city.disabled = true
	btn_archive.disabled = true
	btn_report.disabled = true
	btn_complexity_c.disabled = true

func _on_decryptor_pressed():
	selected_quest_type = QuestType.DECRYPTOR
	btn_complexity_b.disabled = false
	btn_complexity_c.disabled = false
	modal.visible = true

func _on_lie_detector_pressed():
	selected_quest_type = QuestType.LOGIC_GATE
	btn_complexity_b.disabled = false
	btn_complexity_c.disabled = false
	modal.visible = true

func _on_radio_pressed():
	selected_quest_type = QuestType.RADIO
	btn_complexity_b.disabled = true
	btn_complexity_c.disabled = true
	modal.visible = true

func _on_script_pressed():
	selected_quest_type = QuestType.SUSPECT
	btn_complexity_b.disabled = false
	btn_complexity_c.disabled = true
	modal.visible = true

func _on_locked_pressed():
	status_label.text = STATUS_LOCKED

func _on_complexity_a_pressed():
	GlobalMetrics.current_level_index = 0
	if selected_quest_type == QuestType.DECRYPTOR:
		get_tree().change_scene_to_file("res://scenes/Decryptor.tscn")
	elif selected_quest_type == QuestType.LOGIC_GATE:
		get_tree().change_scene_to_file("res://scenes/LogicQuestA.tscn")
	elif selected_quest_type == QuestType.RADIO:
		get_tree().change_scene_to_file("res://scenes/RadioQuestA.tscn")
	elif selected_quest_type == QuestType.SUSPECT:
		get_tree().change_scene_to_file("res://scenes/SuspectQuestA.tscn")

func _on_complexity_b_pressed():
	if selected_quest_type == QuestType.DECRYPTOR:
		GlobalMetrics.current_level_index = 15
		get_tree().change_scene_to_file("res://scenes/Decryptor.tscn")
	elif selected_quest_type == QuestType.LOGIC_GATE:
		get_tree().change_scene_to_file("res://scenes/LogicQuestB.tscn")
	elif selected_quest_type == QuestType.SUSPECT:
		get_tree().change_scene_to_file("res://scenes/RestoreQuestB.tscn")

func _on_complexity_c_pressed():
	if selected_quest_type == QuestType.DECRYPTOR:
		get_tree().change_scene_to_file("res://scenes/MatrixDecryptor.tscn")
	elif selected_quest_type == QuestType.LOGIC_GATE:
		get_tree().change_scene_to_file("res://scenes/LogicQuestC.tscn")
	elif selected_quest_type == QuestType.SUSPECT:
		get_tree().change_scene_to_file("res://scenes/DisarmQuestC.tscn")

func _on_close_modal_pressed():
	modal.visible = false
