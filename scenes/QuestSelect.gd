extends Control

@onready var modal = $ModalLayer/ModeSelectionModal

func _ready():
	modal.visible = false

func _on_quest_button_pressed():
	# Show the difficulty selection modal
	modal.visible = true

func _on_complexity_a_pressed():
	# Start the game with Complexity A (Level 0)
	GlobalMetrics.current_level_index = 0
	get_tree().change_scene_to_file("res://scenes/Decryptor.tscn")

func _on_complexity_b_pressed():
	pass # Disabled

func _on_complexity_c_pressed():
	pass # Disabled

func _on_close_modal_pressed():
	modal.visible = false
