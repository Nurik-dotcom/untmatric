extends PanelContainer

@onready var explain_label = $VBoxContainer/ExplainList
@onready var btn_close = $VBoxContainer/BtnClose

func _ready():
	btn_close.pressed.connect(_on_close_pressed)

func setup(explain_lines: Array):
	# Explain
	var txt = "[b]DEBUG REPORT:[/b]\n"
	for line in explain_lines:
		txt += "- " + str(line) + "\n"
	explain_label.text = txt

func _on_close_pressed():
	visible = false
