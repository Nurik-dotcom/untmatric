extends PanelContainer

signal move_requested(stage_id: String, dir: int)
signal hint_requested(stage_id: String)

@onready var stage_title: Label = $Margin/VBox/Header/StageTitle
@onready var stage_hint_btn: Button = $Margin/VBox/Header/StageHintBtn
@onready var btn_left: Button = $Margin/VBox/Controls/BtnLeft
@onready var btn_right: Button = $Margin/VBox/Controls/BtnRight

var stage_id: String = ""
var hint_text: String = ""

func _ready() -> void:
	_apply_polaroid_style()
	btn_left.pressed.connect(_on_left_pressed)
	btn_right.pressed.connect(_on_right_pressed)
	stage_hint_btn.pressed.connect(_on_hint_pressed)

func setup(card_data: Dictionary) -> void:
	stage_id = str(card_data.get("stage_id", "")).strip_edges()
	hint_text = str(card_data.get("hint", "")).strip_edges()
	stage_title.text = str(card_data.get("title", stage_id))
	stage_hint_btn.disabled = hint_text.is_empty()
	var tilt_seed: int = abs(stage_id.hash()) % 5
	rotation_degrees = float(tilt_seed - 2)
	modulate = Color(1.0, 0.985, 0.95, 1.0)

func set_move_enabled(can_left: bool, can_right: bool) -> void:
	btn_left.disabled = not can_left
	btn_right.disabled = not can_right

func _apply_polaroid_style() -> void:
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.16, 0.145, 0.11, 0.96)
	panel_style.border_color = Color(0.05, 0.04, 0.03, 1.0)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 2
	panel_style.corner_radius_top_right = 2
	panel_style.corner_radius_bottom_left = 3
	panel_style.corner_radius_bottom_right = 3
	add_theme_stylebox_override("panel", panel_style)
	stage_title.add_theme_color_override("font_color", Color(0.95, 0.94, 0.85, 1.0))

func _on_left_pressed() -> void:
	move_requested.emit(stage_id, -1)

func _on_right_pressed() -> void:
	move_requested.emit(stage_id, 1)

func _on_hint_pressed() -> void:
	hint_requested.emit(stage_id)
