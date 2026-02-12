extends Control

func _ready():
	$Center/Menu/NotebookArea.pressed.connect(_on_start_pressed)
	$Center/Menu/PapersArea.pressed.connect(_on_learn_pressed)

	if $Center/Menu.has_node("QuestBBtn"):
		$Center/Menu/QuestBBtn.pressed.connect(_on_quest_b_pressed)

func _on_start_pressed():
	get_tree().change_scene_to_file("res://scenes/radio_intercept/RadioQuestA.tscn")

func _on_learn_pressed():
	# Placeholder
	pass

func _on_quest_b_pressed():
	get_tree().change_scene_to_file("res://scenes/radio_intercept/RadioQuestB.tscn")
