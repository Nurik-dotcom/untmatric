extends HBoxContainer

signal ip_entered(ip: String)

@onready var octet_1: LineEdit = $Octet1
@onready var octet_2: LineEdit = $Octet2
@onready var octet_3: LineEdit = $Octet3
@onready var octet_4: LineEdit = $Octet4

func _ready() -> void:
	for field in [octet_1, octet_2, octet_3, octet_4]:
		field.max_length = 3
		field.text_submitted.connect(_on_field_submitted)
	octet_1.text_changed.connect(_on_octet_text_changed.bind(octet_2))
	octet_2.text_changed.connect(_on_octet_text_changed.bind(octet_3))
	octet_3.text_changed.connect(_on_octet_text_changed.bind(octet_4))
	octet_4.text_changed.connect(_on_last_octet_changed)

func get_ip() -> String:
	return "%s.%s.%s.%s" % [octet_1.text, octet_2.text, octet_3.text, octet_4.text]

func set_ip(ip: String) -> void:
	var parts: PackedStringArray = ip.split(".")
	if parts.size() != 4:
		return
	octet_1.text = parts[0]
	octet_2.text = parts[1]
	octet_3.text = parts[2]
	octet_4.text = parts[3]

func clear() -> void:
	octet_1.text = ""
	octet_2.text = ""
	octet_3.text = ""
	octet_4.text = ""

func set_editable(editable: bool) -> void:
	for field in [octet_1, octet_2, octet_3, octet_4]:
		field.editable = editable

func _on_octet_text_changed(new_text: String, next_field: LineEdit) -> void:
	if new_text.length() >= 3:
		next_field.grab_focus()

func _on_last_octet_changed(new_text: String) -> void:
	if new_text.length() >= 1:
		emit_signal("ip_entered", get_ip())

func _on_field_submitted(_text: String) -> void:
	emit_signal("ip_entered", get_ip())
