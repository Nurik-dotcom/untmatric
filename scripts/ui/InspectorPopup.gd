extends PopupPanel

@onready var lbl_title: Label = $Root/LblTitle
@onready var lbl_selector_key: Label = $Root/Info/LblSelectorKey
@onready var lbl_selector: Label = $Root/Info/LblSelectorValue
@onready var lbl_kind_key: Label = $Root/Info/LblKindKey
@onready var lbl_kind: Label = $Root/Info/LblKindValue
@onready var lbl_weight_key: Label = $Root/Info/LblWeightKey
@onready var lbl_weight: Label = $Root/Info/LblWeightValue
@onready var lbl_important_key: Label = $Root/Info/LblImportantKey
@onready var lbl_important: Label = $Root/Info/LblImportantValue
@onready var lbl_order_key: Label = $Root/Info/LblOrderKey
@onready var lbl_order: Label = $Root/Info/LblOrderValue
@onready var lbl_color_key: Label = $Root/Info/LblColorKey
@onready var lbl_color: Label = $Root/Info/LblColorValue
@onready var btn_close: Button = $Root/BtnClose

var _current_source_data: Dictionary = {}

func _ready() -> void:
	btn_close.pressed.connect(_on_close_pressed)
	if not I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.connect(_on_language_changed)
	_apply_i18n()

func _exit_tree() -> void:
	if I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.disconnect(_on_language_changed)

func _on_language_changed(_code: String) -> void:
	_apply_i18n()
	if not _current_source_data.is_empty():
		_apply_source_data(_current_source_data)

func show_inspection(source_data: Dictionary) -> void:
	_current_source_data = source_data.duplicate(true)
	_apply_source_data(_current_source_data)
	popup_centered_ratio(0.42)

func _apply_i18n() -> void:
	lbl_title.text = I18n.tr_key("ui.inspector_popup.popup_title", {"default": "ПРОСМОТР"})
	lbl_selector_key.text = I18n.tr_key("ui.inspector_popup.selector", {"default": "Селектор:"})
	lbl_kind_key.text = I18n.tr_key("ui.inspector_popup.kind", {"default": "Тип:"})
	lbl_weight_key.text = I18n.tr_key("ui.inspector_popup.weight", {"default": "Вес:"})
	lbl_important_key.text = I18n.tr_key("ui.inspector_popup.important", {"default": "!important:"})
	lbl_order_key.text = I18n.tr_key("ui.inspector_popup.order", {"default": "Порядок:"})
	lbl_color_key.text = I18n.tr_key("ui.inspector_popup.color", {"default": "Цвет:"})
	btn_close.text = I18n.tr_key("ui.inspector_popup.close", {"default": "ЗАКРЫТЬ"})

func _apply_source_data(source_data: Dictionary) -> void:
	var source_id: String = str(source_data.get("source_id", "UNKNOWN")).strip_edges()
	var selector: String = str(source_data.get("selector", "-")).strip_edges()
	var kind: String = str(source_data.get("kind", "-")).strip_edges()
	var weight: int = int(source_data.get("weight", 0))
	var important: bool = bool(source_data.get("important", false))
	var order: int = int(source_data.get("order", 0))
	var color_value: String = str(source_data.get("color", "")).strip_edges()

	lbl_title.text = I18n.tr_key("ui.inspector_popup.source_title", {
		"default": "ИСТОЧНИК | {source_id}",
		"source_id": source_id
	})
	lbl_selector.text = selector if not selector.is_empty() else "-"
	lbl_kind.text = kind if not kind.is_empty() else "-"
	lbl_weight.text = str(weight)
	lbl_important.text = I18n.tr_key("ui.inspector_popup.yes", {"default": "ДА"}) if important else I18n.tr_key("ui.inspector_popup.no", {"default": "НЕТ"})
	lbl_order.text = str(order)
	lbl_color.text = color_value if not color_value.is_empty() else "-"

	if not color_value.is_empty():
		lbl_color.modulate = Color.from_string(color_value, Color.WHITE)
	else:
		lbl_color.modulate = Color.WHITE

func _on_close_pressed() -> void:
	hide()
