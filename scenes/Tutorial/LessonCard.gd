# scenes/Tutorial/LessonCard.gd
extends PanelContainer

class_name LessonCard

signal card_pressed(lesson_id: String)

@onready var icon_label: Label = $MarginContainer/VBox/TopRow/IconLabel
@onready var title_label: Label = $MarginContainer/VBox/TopRow/TitleLabel
@onready var subtitle_label: Label = $MarginContainer/VBox/SubtitleLabel
@onready var stars_row: HBoxContainer = $MarginContainer/VBox/StarsRow
@onready var status_badge: Label = $MarginContainer/VBox/TopRow/StatusBadge

var _lesson_id: String = ""
var _locked: bool = false

const COLOR_DONE := Color(0.2, 0.6, 0.3)
const COLOR_PROGRESS := Color(0.5, 0.35, 0.75)
const COLOR_EMPTY := Color(0.22, 0.22, 0.32)
const COLOR_LOCKED := Color(0.18, 0.18, 0.24)

func setup(lesson_id: String, icon: String, title: String, subtitle: String, difficulty: String = "A", locked: bool = false) -> void:
    _lesson_id = lesson_id
    _locked = locked
    icon_label.text = icon
    title_label.text = title
    subtitle_label.text = subtitle
    _render_difficulty_badge(difficulty)
    _refresh_from_progress()
    if not LessonProgress.progress_changed.is_connected(_on_progress_changed):
        LessonProgress.progress_changed.connect(_on_progress_changed)

func _render_difficulty_badge(difficulty: String) -> void:
    var badge_colors := {
        "A": Color(0.2, 0.7, 0.3, 1.0),
        "B": Color(0.7, 0.55, 0.1, 1.0),
        "C": Color(0.7, 0.2, 0.2, 1.0),
    }
    if not _locked:
        var col: Color = badge_colors.get(difficulty, Color(0.5, 0.5, 0.5))
        if not has_node("MarginContainer/VBox/TopRow/DiffBadge"):
            var diff_lbl := Label.new()
            diff_lbl.name = "DiffBadge"
            diff_lbl.add_theme_font_size_override("font_size", 10)
            $MarginContainer/VBox/TopRow.add_child(diff_lbl)
        var diff_label := $MarginContainer/VBox/TopRow/DiffBadge as Label
        diff_label.text = difficulty
        diff_label.add_theme_color_override("font_color", col)

func _ready() -> void:
    gui_input.connect(_on_gui_input)
    mouse_entered.connect(_on_hover_enter)
    mouse_exited.connect(_on_hover_exit)
    pivot_offset = size * 0.5
    get_tree().root.size_changed.connect(_on_viewport_size_changed)
    _on_viewport_size_changed()

func _exit_tree() -> void:
    if get_tree() and get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
        get_tree().root.size_changed.disconnect(_on_viewport_size_changed)
    if LessonProgress.progress_changed.is_connected(_on_progress_changed):
        LessonProgress.progress_changed.disconnect(_on_progress_changed)

func _on_viewport_size_changed() -> void:
    var vp := get_viewport_rect().size
    var is_landscape := vp.x > vp.y and vp.y <= 520.0
    subtitle_label.visible = not is_landscape
    stars_row.custom_minimum_size.y = 4.0 if is_landscape else 5.0
    if icon_label != null:
        icon_label.add_theme_font_size_override("font_size", 16 if is_landscape else 24)
    if title_label != null:
        title_label.add_theme_font_size_override("font_size", 12 if is_landscape else 15)

func _on_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        if not _locked:
            card_pressed.emit(_lesson_id)

func _on_hover_enter() -> void:
    if not _locked:
        var tw := create_tween()
        tw.tween_property(self, "scale", Vector2(1.02, 1.02), 0.12).set_trans(Tween.TRANS_CUBIC)

func _on_hover_exit() -> void:
    var tw := create_tween()
    tw.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_CUBIC)

func _on_progress_changed(changed_id: String) -> void:
    if changed_id == _lesson_id:
        _refresh_from_progress()

func _refresh_from_progress() -> void:
    var stars := LessonProgress.get_stars(_lesson_id)
    var completed := LessonProgress.is_completed(_lesson_id)
    var phase := LessonProgress.get_phase(_lesson_id)
    _render_stars(stars)
    _update_style(completed, phase)
    _update_badge(completed, phase)

func _render_stars(count: int) -> void:
    for child in stars_row.get_children():
        child.queue_free()
    for i in range(3):
        var dot := Panel.new()
        var style := StyleBoxFlat.new()
        style.corner_radius_top_left = 6
        style.corner_radius_top_right = 6
        style.corner_radius_bottom_left = 6
        style.corner_radius_bottom_right = 6
        style.bg_color = Color(1.0, 0.85, 0.1) if i < count else Color(0.2, 0.2, 0.3)
        dot.add_theme_stylebox_override("panel", style)
        dot.custom_minimum_size = Vector2(16, 5)
        stars_row.add_child(dot)

func _update_style(completed: bool, phase: int) -> void:
    var style := StyleBoxFlat.new()
    style.corner_radius_top_left = 10
    style.corner_radius_top_right = 10
    style.corner_radius_bottom_left = 10
    style.corner_radius_bottom_right = 10
    style.border_width_left = 2
    style.border_width_right = 2
    style.border_width_top = 2
    style.border_width_bottom = 2
    if _locked:
        style.bg_color = COLOR_LOCKED
        style.border_color = Color(0.22, 0.22, 0.28)
        modulate.a = 0.6
    elif completed:
        style.bg_color = Color(0.05, 0.14, 0.08)
        style.border_color = COLOR_DONE
    elif phase > 0:
        style.bg_color = Color(0.1, 0.07, 0.16)
        style.border_color = COLOR_PROGRESS
    else:
        style.bg_color = Color(0.08, 0.08, 0.12)
        style.border_color = COLOR_EMPTY
    add_theme_stylebox_override("panel", style)

func _update_badge(completed: bool, phase: int) -> void:
    if _locked:
        status_badge.text = "скоро"
        status_badge.modulate = Color(0.5, 0.5, 0.5)
    elif completed:
        status_badge.text = "✓"
        status_badge.modulate = COLOR_DONE
    elif phase > 0:
        status_badge.text = "..."
        status_badge.modulate = COLOR_PROGRESS
    else:
        status_badge.text = ""
