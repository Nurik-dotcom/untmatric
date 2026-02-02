extends Control

@onready var modal = $ModalLayer/ModeSelectionModal

enum QuestType { DECRYPTOR, LOGIC_GATE, RADIO_INTERCEPT }
var selected_quest_type = QuestType.DECRYPTOR

func _ready():
	modal.visible = false

func _on_quest_button_pressed():
	# Decryptor
	selected_quest_type = QuestType.DECRYPTOR
	modal.visible = true

func _on_lie_detector_pressed():
	# Logic Gate / Lie Detector
	selected_quest_type = QuestType.LOGIC_GATE
	modal.visible = true

func _on_radio_intercept_pressed():
	# Radio Intercept
	selected_quest_type = QuestType.RADIO_INTERCEPT
	# Radio Intercept uses its own logic or maybe starts directly?
	# Assuming it uses the same complexity modal for consistency, or starts directly.
	# The plan implies we route it. Let's start it directly or via modal A.
	# "Route it to scenes/radio_intercept/RadioQuestA.tscn" implies direct start or via "Protocol A".
	modal.visible = true

func _on_complexity_a_pressed():
	# Start the game with Complexity A (Level 0)
	GlobalMetrics.current_level_index = 0

	if selected_quest_type == QuestType.DECRYPTOR:
		get_tree().change_scene_to_file("res://scenes/Decryptor.tscn")
	elif selected_quest_type == QuestType.LOGIC_GATE:
		get_tree().change_scene_to_file("res://scenes/LogicQuestA.tscn")
	elif selected_quest_type == QuestType.RADIO_INTERCEPT:
		get_tree().change_scene_to_file("res://scenes/radio_intercept/RadioQuestA.tscn")

func _on_complexity_b_pressed():
	pass # Disabled

func _on_complexity_c_pressed():
	pass # Disabled

func _on_close_modal_pressed():
	modal.visible = false
