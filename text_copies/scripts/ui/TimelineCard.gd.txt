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
	btn_left.pressed.connect(_on_left_pressed)
	btn_right.pressed.connect(_on_right_pressed)
	stage_hint_btn.pressed.connect(_on_hint_pressed)

func setup(card_data: Dictionary) -> void:
	stage_id = str(card_data.get("stage_id", "")).strip_edges()
	hint_text = str(card_data.get("hint", "")).strip_edges()
	stage_title.text = str(card_data.get("title", stage_id))
	stage_hint_btn.disabled = hint_text.is_empty()

func set_move_enabled(can_left: bool, can_right: bool) -> void:
	btn_left.disabled = not can_left
	btn_right.disabled = not can_right

func _on_left_pressed() -> void:
	move_requested.emit(stage_id, -1)

func _on_right_pressed() -> void:
	move_requested.emit(stage_id, 1)

func _on_hint_pressed() -> void:
	hint_requested.emit(stage_id)
