extends PopupPanel

signal option_selected(option_id)

@onready var root_container = $Root
@onready var lbl_title = $Root/LblTitle
@onready var lbl_original = $Root/LblOriginal
@onready var options_container = $Root/Options
@onready var btn_apply = $Root/BtnApply
@onready var btn_close = $Root/BtnClose

var current_options = []
var selected_option_id = null

func _ready():
	btn_close.pressed.connect(_on_close_pressed)
	btn_apply.pressed.connect(_on_apply_pressed)
	btn_apply.disabled = true

func setup(original_line: String, options: Array):
	lbl_original.text = "ORIGINAL: " + original_line
	current_options = options
	selected_option_id = null
	btn_apply.disabled = true

	# Clear old options
	for child in options_container.get_children():
		child.queue_free()

	# Create buttons for options
	for opt in options:
		var btn = Button.new()
		btn.text = opt.option_id + ") " + opt.replace_line
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(0, 40)
		# Connect press
		btn.pressed.connect(func(): _on_option_pressed(btn, opt.option_id))
		options_container.add_child(btn)

func _on_option_pressed(btn: Button, opt_id):
	# Manual radio behavior: unpress others
	for child in options_container.get_children():
		if child != btn:
			child.set_pressed_no_signal(false)

	# Ensure self is pressed (toggle mode could unpress)
	btn.set_pressed_no_signal(true)

	selected_option_id = opt_id
	btn_apply.disabled = false

func _on_apply_pressed():
	if selected_option_id:
		option_selected.emit(selected_option_id)
		visible = false

func _on_close_pressed():
	visible = false
