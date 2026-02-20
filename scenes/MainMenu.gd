extends Control

@onready var menu_root: VBoxContainer = $Center/Menu
@onready var start_btn: Button = $Center/Menu/NotebookArea
@onready var learn_btn: Button = $Center/Menu/PapersArea

func _ready() -> void:
	start_btn.pressed.connect(_on_start_pressed)
	learn_btn.pressed.connect(_on_learn_pressed)
	_animate_intro()

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _on_learn_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/LearnSelect.tscn")

func _animate_intro() -> void:
	menu_root.modulate.a = 0.0
	menu_root.position.y += 32.0
	var tween: Tween = create_tween()
	tween.tween_property(menu_root, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(menu_root, "position:y", menu_root.position.y - 32.0, 0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
