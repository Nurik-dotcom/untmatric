extends PanelContainer

@onready var lbl_title: Label = $Root/LblTitle
@onready var text_body: RichTextLabel = $Root/Body
@onready var btn_close: Button = $Root/BtnClose

func _ready() -> void:
	btn_close.pressed.connect(_on_close_pressed)

func setup(title: String, lines: Array) -> void:
	lbl_title.text = title
	var out := ""
	for line_var in lines:
		out += "- %s\n" % str(line_var)
	text_body.text = out

func _on_close_pressed() -> void:
	visible = false
