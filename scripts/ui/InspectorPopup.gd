extends PopupPanel

@onready var lbl_title: Label = $Root/LblTitle
@onready var lbl_selector: Label = $Root/Info/LblSelectorValue
@onready var lbl_kind: Label = $Root/Info/LblKindValue
@onready var lbl_weight: Label = $Root/Info/LblWeightValue
@onready var lbl_important: Label = $Root/Info/LblImportantValue
@onready var lbl_order: Label = $Root/Info/LblOrderValue
@onready var lbl_color: Label = $Root/Info/LblColorValue
@onready var btn_close: Button = $Root/BtnClose

func _ready() -> void:
	btn_close.pressed.connect(_on_close_pressed)

func show_inspection(source_data: Dictionary) -> void:
	var source_id: String = str(source_data.get("source_id", "UNKNOWN"))
	var selector: String = str(source_data.get("selector", "-"))
	var kind: String = str(source_data.get("kind", "-"))
	var weight: int = int(source_data.get("weight", 0))
	var important: bool = bool(source_data.get("important", false))
	var order: int = int(source_data.get("order", 0))
	var color_value: String = str(source_data.get("color", "")).strip_edges()

	lbl_title.text = "ПРОСМОТР | %s" % source_id
	lbl_selector.text = selector
	lbl_kind.text = kind
	lbl_weight.text = str(weight)
	lbl_important.text = "ДА" if important else "НЕТ"
	lbl_order.text = str(order)
	lbl_color.text = color_value if not color_value.is_empty() else "-"

	if not color_value.is_empty():
		lbl_color.modulate = Color.from_string(color_value, Color(1, 1, 1, 1))
	else:
		lbl_color.modulate = Color(1, 1, 1, 1)

	popup_centered_ratio(0.42)

func _on_close_pressed() -> void:
	hide()

