extends PanelContainer

var _level_data: Dictionary = {}
var _controller: Node = null
var _selection: Dictionary = {}
var _selectors: Dictionary = {}
var _row_by_item: Dictionary = {}

@onready var briefing_label: Label = $VBox/BriefingLabel
@onready var items_box: VBoxContainer = $VBox/Scroll/ItemsBox

func setup(level_data: Dictionary, controller: Node) -> void:
	_level_data = level_data.duplicate(true)
	_controller = controller
	_selection.clear()
	_selectors.clear()
	_row_by_item.clear()
	_apply_ui()

func apply_i18n() -> void:
	_apply_ui()

func reset() -> void:
	_selection.clear()
	for selector_v in _selectors.values():
		if selector_v is OptionButton:
			(selector_v as OptionButton).select(0)

func get_answers() -> Variant:
	var out: Dictionary = {}
	for item_v in _selection.keys():
		out[str(item_v)] = str(_selection[item_v])
	return out

func show_result(result: Dictionary) -> void:
	var details: Array = result.get("details", []) as Array
	for detail_v in details:
		if typeof(detail_v) != TYPE_DICTIONARY:
			continue
		var detail: Dictionary = detail_v as Dictionary
		var item_id: String = str(detail.get("item_id", detail.get("task_id", "")))
		var row_v: Variant = _row_by_item.get(item_id, null)
		if row_v is Control:
			(row_v as Control).modulate = Color(0.96, 1.0, 0.96, 1.0) if bool(detail.get("correct", false)) else Color(1.0, 0.92, 0.92, 1.0)

func _apply_ui() -> void:
	briefing_label.text = I18n.resolve_field(_level_data, "briefing", {"default": str(_level_data.get("briefing", ""))})
	for child in items_box.get_children():
		child.queue_free()
	_selectors.clear()
	_row_by_item.clear()

	var buckets: Array = _level_data.get("buckets", []) as Array
	var bucket_ids: Array[String] = [""]
	var bucket_labels: Array[String] = [I18n.tr_key("resus.ui.unassigned", {"default": "UNASSIGNED"})]
	for bucket_v in buckets:
		if typeof(bucket_v) != TYPE_DICTIONARY:
			continue
		var bucket: Dictionary = bucket_v as Dictionary
		var bucket_id: String = str(bucket.get("bucket_id", "")).to_upper()
		if bucket_id == "":
			continue
		bucket_ids.append(bucket_id)
		var localized_label: String = I18n.resolve_field(bucket, "label", {"default": bucket_id})
		bucket_labels.append("%s (%s)" % [localized_label, bucket_id])

	var row_index: int = 0
	for item_v in _level_data.get("items", []) as Array:
		if typeof(item_v) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = item_v as Dictionary
		var item_id: String = str(item.get("item_id", "")).strip_edges()
		if item_id == "":
			continue
		var row: HBoxContainer = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.custom_minimum_size = Vector2(0, 48)
		row.modulate = Color(1.0, 1.0, 1.0, 1.0) if row_index % 2 == 0 else Color(0.97, 0.97, 1.0, 1.0)
		var label: Label = Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = I18n.resolve_field(item, "label", {"default": item_id})
		row.add_child(label)
		var selector: OptionButton = OptionButton.new()
		selector.custom_minimum_size = Vector2(220, 0)
		for idx in range(bucket_ids.size()):
			selector.add_item(bucket_labels[idx])
		selector.item_selected.connect(_on_item_selected.bind(item_id, bucket_ids))
		row.add_child(selector)
		items_box.add_child(row)
		_selectors[item_id] = selector
		_row_by_item[item_id] = row
		_selection[item_id] = "PILE"
		row_index += 1

func _on_item_selected(index: int, item_id: String, bucket_ids: Array[String]) -> void:
	if index < 0 or index >= bucket_ids.size():
		_selection[item_id] = "PILE"
		return
	var bucket_id: String = bucket_ids[index]
	_selection[item_id] = bucket_id if bucket_id != "" else "PILE"
