extends Control

@onready var start_btn = $Center/Menu/NotebookArea
@onready var learn_btn = $Center/Menu/PapersArea

func _ready():
	start_btn.pressed.connect(_on_start_pressed)
	learn_btn.pressed.connect(_on_learn_pressed)

func _on_start_pressed():
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _on_learn_pressed():
	print("Learn mode not implemented yet.")
