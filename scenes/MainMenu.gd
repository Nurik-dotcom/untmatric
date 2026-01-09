extends Control

@onready var start_btn = $NotebookArea # Notebook button
@onready var learn_btn = $PapersArea   # Magnifier button

func _ready():
	# Fade-in animation (optional)
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1.0)

func _on_notebook_pressed():
	# Go to investigation list (Exam mode)
	GlobalMetrics.current_mode = GlobalMetrics.Mode.EXAM
	get_tree().change_scene_to_file("res://scenes/QuestStage.tscn")

func _on_papers_pressed():
	# Go to learning (Phase 1: Atlas)
	GlobalMetrics.current_mode = GlobalMetrics.Mode.LEARN
	get_tree().change_scene_to_file("res://scenes/Atlas.tscn")
