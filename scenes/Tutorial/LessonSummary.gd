# scenes/Tutorial/LessonSummary.gd
extends Control

signal retry_requested
signal quest_requested(quest_scene_path: String)
signal home_requested

@onready var stars_container: HBoxContainer = $SafeArea/VBox/StarsRow
@onready var title_label: Label = $SafeArea/VBox/TitleLabel
@onready var subtitle_label: Label = $SafeArea/VBox/SubtitleLabel
@onready var btn_retry: Button = $SafeArea/VBox/Buttons/BtnRetry
@onready var btn_quest: Button = $SafeArea/VBox/Buttons/BtnQuest
@onready var btn_home: Button = $SafeArea/VBox/Buttons/BtnHome

var lesson_id: String = ""
var quest_scene_path: String = ""

func setup(p_lesson_id: String, p_stars: int, p_quest_path: String) -> void:
    lesson_id = p_lesson_id
    quest_scene_path = p_quest_path
    LessonProgress.mark_phase(lesson_id, 3, p_stars)
    _render_stars(p_stars)
    _set_text_by_stars(p_stars)
    _animate_in()

func _ready() -> void:
    btn_retry.pressed.connect(func(): retry_requested.emit())
    btn_home.pressed.connect(func(): home_requested.emit())
    btn_quest.pressed.connect(func():
        if quest_scene_path != "":
            quest_requested.emit(quest_scene_path)
    )
    btn_quest.visible = quest_scene_path != ""

func _render_stars(count: int) -> void:
    for child in stars_container.get_children():
        child.queue_free()
    for i in range(3):
        var star := Label.new()
        star.text = "★" if i < count else "☆"
        star.add_theme_font_size_override("font_size", 48)
        var color := Color(1.0, 0.85, 0.1) if i < count else Color(0.35, 0.35, 0.35)
        star.add_theme_color_override("font_color", color)
        stars_container.add_child(star)

func _set_text_by_stars(count: int) -> void:
    match count:
        3:
            title_label.text = "Отлично!"
            subtitle_label.text = "Все ответы правильные. Ты готов к квесту."
        2:
            title_label.text = "Хорошо!"
            subtitle_label.text = "Почти всё верно. Попробуй ещё раз для 3 звёзд."
        1:
            title_label.text = "Неплохо"
            subtitle_label.text = "Стоит повторить материал и попробовать снова."
        _:
            title_label.text = "Урок пройден"
            subtitle_label.text = "Попробуй ещё раз для получения звёзд."

func _animate_in() -> void:
    modulate.a = 0.0
    var tw := create_tween()
    tw.tween_property(self, "modulate:a", 1.0, 0.4)
    for i in range(stars_container.get_child_count()):
        var star := stars_container.get_child(i)
        star.scale = Vector2(0.5, 0.5)
        var st := create_tween()
        st.tween_property(star, "scale", Vector2.ONE, 0.3).set_delay(0.1 * i).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
