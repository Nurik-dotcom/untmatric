extends Control

@onready var start_btn = $NotebookArea # Notebook button
@onready var learn_btn = $PapersArea   # Magnifier button

func _ready():
	# Fade-in animation (optional)
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1.0)

func _on_notebook_pressed():
	# Start the Decryptor game
	get_tree().change_scene_to_file("res://scenes/Decryptor.tscn")

func _on_papers_pressed():
	# Go to learning (Phase 1: Atlas) - Keep for now or disable
	# GlobalMetrics.current_mode = GlobalMetrics.Mode.LEARN # Removed in new logic
	# get_tree().change_scene_to_file("res://scenes/Atlas.tscn")
	print("Atlas/Learn mode not implemented yet.")
