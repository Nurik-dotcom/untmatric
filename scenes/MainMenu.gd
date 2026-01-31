extends Control

@onready var start_btn = $Center/Menu/NotebookArea # Start button
@onready var learn_btn = $Center/Menu/PapersArea   # Learn button

func _ready():
	start_btn.pressed.connect(_on_notebook_pressed)
	learn_btn.pressed.connect(_on_papers_pressed)

	# Fade-in animation (optional)
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1.0)

func _on_notebook_pressed():
	# Go to quest selection
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _on_papers_pressed():
	# Go to learning (Phase 1: Atlas) - Keep for now or disable
	# GlobalMetrics.current_mode = GlobalMetrics.Mode.LEARN # Removed in new logic
	# get_tree().change_scene_to_file("res://scenes/Atlas.tscn")
	print("Atlas/Learn mode not implemented yet.")
