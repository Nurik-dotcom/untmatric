extends Control

@export var complexity_name: String = "A"

@onready var title_label: Label = $MainLayout/Header/TitleLabel
@onready var btn_back: Button = $MainLayout/Header/BtnBack
@onready var placeholder_buttons: Array[Button] = [
	$MainLayout/PlaceholderGrid/ActionBtn1,
	$MainLayout/PlaceholderGrid/ActionBtn2,
	$MainLayout/PlaceholderGrid/ActionBtn3,
	$MainLayout/PlaceholderGrid/ActionBtn4,
	$MainLayout/PlaceholderGrid/ActionBtn5,
	$MainLayout/PlaceholderGrid/ActionBtn6
]

func _ready() -> void:
	title_label.text = "Сетевой след — Сложность %s" % complexity_name
	btn_back.pressed.connect(_on_back_pressed)
	for btn in placeholder_buttons:
		btn.text = ""
		btn.pressed.connect(_on_placeholder_pressed)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _on_placeholder_pressed() -> void:
	pass
