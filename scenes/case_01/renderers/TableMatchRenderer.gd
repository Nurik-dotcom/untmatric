extends PanelContainer

var _level_data: Dictionary = {}
var _controller: Node = null
var _selection: Dictionary = {}
var _selectors: Dictionary = {}
var _row_by_task: Dictionary = {}

@onready var briefing_label: Label = $VBox/BriefingLabel
@onready var table_grid: GridContainer = $VBox/TableScroll/TableGrid

func setup(level_data: Dictionary, controller: Node) -> void:
	_level_data = level_data.duplicate(true)
	_controller = controller
	_selection.clear()
	_selectors.clear()
	_row_by_task.clear()
	_apply_ui()

func apply_i18n() -> void:
	_apply_ui()

func reset() -> void:
	_selection.clear()
	for selector_v in _selectors.values():
		if selector_v is OptionButton:
			(selector_v as OptionButton).select(0)

func get_answers() -> Variant:
	return _selection.duplicate(true)

func show_result(result: Dictionary) -> void:
	for row_v in _row_by_task.values():
		if row_v is Control:
			(row_v as Control).modulate = Color(1, 1, 1, 1)
	for detail_v in result.get("details", []) as Array:
		if typeof(detail_v) != TYPE_DICTIONARY:
			continue
		var detail: Dictionary = detail_v as Dictionary
		var task_id: String = str(detail.get("task_id", ""))
		var row_node_v: Variant = _row_by_task.get(task_id, null)
		if row_node_v is Control:
			(row_node_v as Control).modulate = Color(0.96, 1.0, 0.96, 1.0) if bool(detail.get("correct", false)) else Color(1.0, 0.92, 0.92, 1.0)

func _apply_ui() -> void:
	briefing_label.text = I18n.resolve_field(_level_data, "briefing", {"default": str(_level_data.get("briefing", ""))})
	for child in table_grid.get_children():
		child.queue_free()
	_selectors.clear()
	_row_by_task.clear()
	_selection.clear()

	var configs: Array = _level_data.get("configs", []) as Array
	var config_ids: Array[String] = [""]
	var config_labels: Array[String] = [I18n.tr_key("resus.ui.unassigned", {"default": "---"})]

	# Section 1: Read-only PC configurations.
	for header_text in [
		I18n.tr_key("resus.ui.table.config", {"default": "Config"}),
		I18n.tr_key("resus.ui.table.cpu", {"default": "CPU"}),
		I18n.tr_key("resus.ui.table.ram", {"default": "RAM"}),
		I18n.tr_key("resus.ui.table.gpu", {"default": "GPU"}),
		I18n.tr_key("resus.ui.table.storage", {"default": "Storage"}),
		""
	]:
		var header: Label = Label.new()
		header.text = header_text
		header.add_theme_font_size_override("font_size", 13)
		header.modulate = Color(0.7, 0.75, 0.8, 1.0)
		table_grid.add_child(header)

	for config_v in configs:
		if typeof(config_v) != TYPE_DICTIONARY:
			continue
		var config: Dictionary = config_v as Dictionary
		var config_id: String = str(config.get("config_id", "")).strip_edges()
		if config_id == "":
			continue
		config_ids.append(config_id)
		var config_label_text: String = I18n.resolve_field(config, "label", {"default": config_id})
		var option_label: String = "%s (CPU: %s, RAM: %s, GPU: %s, Storage: %s)" % [
			config_label_text,
			str(config.get("cpu", "?")),
			str(config.get("ram", "?")),
			str(config.get("gpu", "?")),
			str(config.get("storage", "?"))
		]
		config_labels.append(option_label)

		var name_lbl: Label = Label.new()
		name_lbl.text = config_label_text
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.modulate = Color(0.95, 0.88, 0.6, 1.0)
		table_grid.add_child(name_lbl)

		for field in ["cpu", "ram", "gpu", "storage"]:
			var cell: Label = Label.new()
			cell.text = str(config.get(field, "-"))
			cell.add_theme_font_size_override("font_size", 13)
			table_grid.add_child(cell)

		var assign_placeholder: Label = Label.new()
		assign_placeholder.text = "-"
		assign_placeholder.modulate = Color(0.55, 0.55, 0.58, 1.0)
		table_grid.add_child(assign_placeholder)

	# Divider row (GridContainer has no colspan support).
	var separator: HSeparator = HSeparator.new()
	separator.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	table_grid.add_child(separator)
	for _i in range(5):
		var spacer: Control = Control.new()
		table_grid.add_child(spacer)

	# Section 2: Tasks assignment.
	var task_header: Label = Label.new()
	task_header.text = I18n.tr_key("resus.ui.table.task", {"default": "Task"})
	task_header.add_theme_font_size_override("font_size", 13)
	task_header.modulate = Color(0.7, 0.75, 0.8, 1.0)
	table_grid.add_child(task_header)
	for _i in range(4):
		table_grid.add_child(Control.new())
	var assign_header: Label = Label.new()
	assign_header.text = I18n.tr_key("resus.ui.table.assign", {"default": "Assign"})
	assign_header.add_theme_font_size_override("font_size", 13)
	assign_header.modulate = Color(0.7, 0.75, 0.8, 1.0)
	table_grid.add_child(assign_header)

	var tasks: Array = _level_data.get("tasks", []) as Array
	for task_v in tasks:
		if typeof(task_v) != TYPE_DICTIONARY:
			continue
		var task: Dictionary = task_v as Dictionary
		var task_id: String = str(task.get("task_id", "")).strip_edges()
		if task_id == "":
			continue
		var label: String = I18n.resolve_field(task, "label", {"default": task_id})
		_selection[task_id] = ""

		var task_label: Label = Label.new()
		task_label.text = label
		task_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		task_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		table_grid.add_child(task_label)

		for _i in range(4):
			table_grid.add_child(Control.new())

		var selector: OptionButton = OptionButton.new()
		selector.custom_minimum_size = Vector2(180, 0)
		for idx in range(config_ids.size()):
			selector.add_item(config_labels[idx])
		selector.item_selected.connect(_on_task_selected.bind(task_id, config_ids))
		table_grid.add_child(selector)
		_selectors[task_id] = selector
		_row_by_task[task_id] = task_label

func _on_task_selected(index: int, task_id: String, config_ids: Array[String]) -> void:
	var previous_value: String = str(_selection.get(task_id, ""))
	if index < 0 or index >= config_ids.size():
		_selection[task_id] = ""
		_notify_controller("step_selected", {
			"task_id": task_id,
			"config_id": "",
			"previous": previous_value
		})
		return
	var next_value: String = config_ids[index]
	_selection[task_id] = next_value
	_notify_controller("step_selected", {
		"task_id": task_id,
		"config_id": next_value,
		"previous": previous_value
	})
	if previous_value != "" and previous_value != next_value:
		_notify_controller("step_reordered", {
			"task_id": task_id,
			"from": previous_value,
			"to": next_value
		})

func _notify_controller(event_name: String, payload: Dictionary = {}) -> void:
	if _controller != null and _controller.has_method("on_renderer_event"):
		_controller.call("on_renderer_event", event_name, payload)
