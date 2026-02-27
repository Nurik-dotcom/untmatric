extends Control

const LANGUAGE_CODES: Array[String] = ["ru", "kk", "en"]

@onready var menu_root: VBoxContainer = $Center/Menu
@onready var title_label: Label = $Center/Menu/Title
@onready var subtitle_label: Label = $Center/Menu/Subtitle
@onready var start_btn: Button = $Center/Menu/NotebookArea
@onready var learn_btn: Button = $Center/Menu/PapersArea
@onready var lab_btn: Button = $Center/Menu/LaptopArea
@onready var lang_label: Label = $Center/Menu/LangRow/LangLabel
@onready var lang_select: OptionButton = $Center/Menu/LangRow/LangSelect
@onready var version_label: Label = $Center/Menu/Version

var _syncing_lang_select: bool = false

func _ready() -> void:
	start_btn.pressed.connect(_on_start_pressed)
	learn_btn.pressed.connect(_on_learn_pressed)
	lang_select.item_selected.connect(_on_language_selected)
	if not I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.connect(_on_language_changed)
	_apply_i18n()
	_animate_intro()

func _exit_tree() -> void:
	if I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.disconnect(_on_language_changed)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _on_learn_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/LearnSelect.tscn")

func _on_language_selected(index: int) -> void:
	if _syncing_lang_select:
		return
	if index < 0 or index >= LANGUAGE_CODES.size():
		return
	I18n.set_language(LANGUAGE_CODES[index])

func _on_language_changed(_code: String) -> void:
	_apply_i18n()

func _apply_i18n() -> void:
	title_label.text = I18n.tr_key("ui.main_menu.title", {"default": "UNTformatic"})
	subtitle_label.text = I18n.tr_key("ui.main_menu.subtitle", {"default": "NOIR PROTOCOL"})
	start_btn.text = I18n.tr_key("ui.main_menu.quests", {"default": "КВЕСТЫ"})
	learn_btn.text = I18n.tr_key("ui.main_menu.learn", {"default": "ОБУЧЕНИЕ"})
	lab_btn.text = I18n.tr_key("ui.main_menu.lab_soon", {"default": "ЛАБОРАТОРИЯ (СКОРО)"})
	lang_label.text = I18n.tr_key("ui.main_menu.language_label", {"default": "Язык"})
	version_label.text = I18n.tr_key("ui.main_menu.version", {"default": "v1.0.0 • Godot 4.5"})
	_refresh_language_select()

func _refresh_language_select() -> void:
	_syncing_lang_select = true
	lang_select.clear()
	lang_select.add_item(I18n.tr_key("ui.main_menu.language_ru", {"default": "Русский"}))
	lang_select.add_item(I18n.tr_key("ui.main_menu.language_kk", {"default": "Қазақша"}))
	lang_select.add_item(I18n.tr_key("ui.main_menu.language_en", {"default": "English"}))
	var current_code: String = I18n.get_language()
	var current_idx: int = max(0, LANGUAGE_CODES.find(current_code))
	lang_select.select(current_idx)
	_syncing_lang_select = false

func _animate_intro() -> void:
	menu_root.modulate.a = 0.0
	menu_root.position.y += 32.0
	var tween: Tween = create_tween()
	tween.tween_property(menu_root, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(menu_root, "position:y", menu_root.position.y - 32.0, 0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
