extends Control

enum Mode { CLASSIC, STAGES_RC }

const MATRIX_LIMIT := 6
const STAGES_DATA_PATH := "res://data/matrix_stages_levels.json"
const CLASSIC_DATA_PATH := "res://data/matrix_ladder_levels.json"
const DEFAULT_STAGE_LEVEL_ID := "C_STAGES_001"
const DEFAULT_CLASSIC_LEVEL_ID := "C_LADDER_001"

const COLOR_OK := Color("33ff66")
const COLOR_WARN := Color("ffcc00")
const COLOR_BAD := Color("ff5555")
const COLOR_TARGET_DEFAULT := Color(0.94, 0.94, 0.94, 1.0)

const MIN_CELL_SIZE := 64
const MIN_CELL_SIZE_TIGHT := 56
const DETAILS_SHEET_H := 360.0
const PHONE_LANDSCAPE_MAX_HEIGHT := 740.0
const PHONE_PORTRAIT_MAX_WIDTH := 520.0

const DEFAULT_HINT_LIMIT := 1
const DEFAULT_CHECK_COOLDOWN := 0.35

@export var mode: int = Mode.STAGES_RC
@export var level_id: String = DEFAULT_STAGE_LEVEL_ID
@export var classic_level_id: String = DEFAULT_CLASSIC_LEVEL_ID

@onready var btn_back: Button = $UI/SafeArea/Main/HeaderBar/HeaderContent/BtnBack
@onready var btn_details: Button = $UI/SafeArea/Main/HeaderBar/HeaderContent/BtnDetails
@onready var btn_close_details: Button = $UI/DetailsSheet/DetailsContent/DetailsHeader/BtnCloseDetails
@onready var safe_area: MarginContainer = $UI/SafeArea
@onready var main_root: VBoxContainer = $UI/SafeArea/Main
@onready var header_content: HBoxContainer = $UI/SafeArea/Main/HeaderBar/HeaderContent
@onready var content_split: HBoxContainer = $UI/SafeArea/Main/ContentSplit
@onready var left_panel: VBoxContainer = $UI/SafeArea/Main/ContentSplit/LeftPanel
@onready var right_panel: VBoxContainer = $UI/SafeArea/Main/ContentSplit/RightPanel
@onready var bottom_actions: HBoxContainer = $UI/SafeArea/Main/BottomBar/Actions
@onready var mode_chip_label: Label = $UI/SafeArea/Main/HeaderBar/HeaderContent/ModeChip/ModeLabel
@onready var level_label: Label = $UI/SafeArea/Main/HeaderBar/HeaderContent/LevelLabel
@onready var stability_text: Label = $UI/SafeArea/Main/HeaderBar/HeaderContent/StabilityGroup/StabilityText
@onready var progress_stability: ProgressBar = $UI/SafeArea/Main/HeaderBar/HeaderContent/StabilityGroup/StabilityBar
@onready var shield_freq: Label = $UI/SafeArea/Main/HeaderBar/HeaderContent/Shields/ShieldFreq
@onready var shield_lazy: Label = $UI/SafeArea/Main/HeaderBar/HeaderContent/Shields/ShieldLazy

@onready var matrix_title: Label = $UI/SafeArea/Main/ContentSplit/LeftPanel/MatrixPanel/MatrixContent/MatrixTitle
@onready var matrix_frame: PanelContainer = $UI/SafeArea/Main/ContentSplit/LeftPanel/MatrixPanel/MatrixContent/MatrixFrame
@onready var matrix_layout: GridContainer = $UI/SafeArea/Main/ContentSplit/LeftPanel/MatrixPanel/MatrixContent/MatrixFrame/MatrixLayout

@onready var btn_hint: Button = $UI/SafeArea/Main/BottomBar/Actions/BtnHint
@onready var btn_check: Button = $UI/SafeArea/Main/BottomBar/Actions/BtnCheck
@onready var btn_reset: Button = $UI/SafeArea/Main/BottomBar/Actions/BtnReset

@onready var progress_label: Label = $UI/SafeArea/Main/ContentSplit/RightPanel/StatusPanel/StatusContent/ProgressLabel
@onready var mode_state_label: Label = $UI/SafeArea/Main/ContentSplit/RightPanel/StatusPanel/StatusContent/ModeLabel
@onready var hint_text: Label = $UI/SafeArea/Main/ContentSplit/RightPanel/HintPanel/HintContent/HintText
@onready var live_log_text: RichTextLabel = $UI/SafeArea/Main/ContentSplit/RightPanel/LiveLogPanel/LiveLogContent/LiveLogText

@onready var toast_panel: PanelContainer = $UI/ToastLayer/Toast
@onready var toast_label: Label = $UI/ToastLayer/Toast/ToastLabel
@onready var details_sheet: PanelContainer = $UI/DetailsSheet
@onready var details_text: RichTextLabel = $UI/DetailsSheet/DetailsContent/DetailsScroll/DetailsText
@onready var noir_overlay = $UI/NoirOverlay

var stages: Array = []
var stage_index: int = 0
var stage_size: int = 2
var display_base: String = "DEC"
var solution_rows_num: PackedInt32Array = PackedInt32Array()
var row_targets_num: PackedInt32Array = PackedInt32Array()
var col_targets_num: PackedInt32Array = PackedInt32Array()

var grid_values: Array = []
var cell_buttons: Array = []
var row_target_nodes: Array = []
var col_target_nodes: Array = []

var hint_limit_per_stage: int = DEFAULT_HINT_LIMIT
var hint_used_count: int = 0
var check_cooldown_sec: float = DEFAULT_CHECK_COOLDOWN
var check_blocked_until: float = 0.0

var last_wrong_rows: int = -1
var last_wrong_cols: int = -1

var _font: Font
var _input_locked: bool = false
var _is_transition: bool = false
var _details_open: bool = false

var _task_started_ms: int = 0
var _first_action_ms: int = -1
var _check_count: int = 0
var _changed: Dictionary = {}
var _logs: Array[String] = []
var _content_mobile_layout: VBoxContainer = null
var _details_sheet_height: float = DETAILS_SHEET_H

func _ready() -> void:
	if not GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.connect(_on_stability_changed)

		btn_back.pressed.connect(_on_menu_pressed)
	btn_details.pressed.connect(_on_details_pressed)
	btn_close_details.pressed.connect(_on_details_pressed)
	btn_hint.pressed.connect(_on_hint_pressed)
	btn_check.pressed.connect(_on_check_pressed)
	btn_reset.pressed.connect(_on_reset_pressed)

	_setup_font()
	_prepare_layout()
	toast_panel.visible = false
	details_sheet.visible = false

	await get_tree().process_frame
	_set_details_open(false, true)
	_start_run()
	_on_viewport_size_changed()
	if not get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.connect(_on_viewport_size_changed)

func _exit_tree() -> void:
	if get_tree() != null and get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.disconnect(_on_viewport_size_changed)

func _prepare_layout() -> void:
	shield_lazy.visible = false
	shield_freq.text = "C"
	shield_freq.modulate = Color(1, 1, 1, 0.25)
	mode_chip_label.text = _mode_name()

func _start_run() -> void:
	_is_transition = false
	_input_locked = false
	_changed.clear()
	GlobalMetrics.stability = 100.0
	GlobalMetrics.emit_signal("stability_changed", GlobalMetrics.stability, 0.0)

	var data_path: String = STAGES_DATA_PATH
	var selected_id: String = level_id
	if mode == Mode.CLASSIC:
		data_path = CLASSIC_DATA_PATH
		selected_id = classic_level_id

	var package: Dictionary = _load_level_package(data_path, selected_id)
	stages = package.get("stages", []) as Array
	_apply_rules(package.get("rules", {}) as Dictionary)

	if stages.is_empty():
		var fallback_package: Dictionary = _fallback_package(mode == Mode.CLASSIC)
		stages = fallback_package.get("stages", []) as Array
		_apply_rules(fallback_package.get("rules", {}) as Dictionary)

	stage_index = 0
	_apply_stage(stage_index)
	_set_input_enabled(true)
	_refresh_stability(GlobalMetrics.stability)
	hint_text.text = "Match targets on the left and top."
	_log("Run started: %s." % _mode_name(), COLOR_OK)

func _load_level_package(path: String, selected_id: String) -> Dictionary:
	var package: Dictionary = {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return package

	var parsed_variant: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed_variant) != TYPE_DICTIONARY:
		return package
	var parsed: Dictionary = parsed_variant as Dictionary

	var levels_variant: Variant = parsed.get("levels", [])
	if typeof(levels_variant) != TYPE_ARRAY:
		return package
	var levels: Array = levels_variant as Array

	for level_variant in levels:
		if typeof(level_variant) != TYPE_DICTIONARY:
			continue
		var level: Dictionary = level_variant as Dictionary
		if str(level.get("id", "")) != selected_id:
			continue
		package["rules"] = level.get("rules", {})
		package["stages"] = _normalize_stages(level.get("stages", []))
		return package

	return package

func _normalize_stages(raw_stages: Variant) -> Array:
	var out: Array = []
	if typeof(raw_stages) != TYPE_ARRAY:
		return out
	var src: Array = raw_stages as Array
	for stage_variant in src:
		if typeof(stage_variant) != TYPE_DICTIONARY:
			continue
		var stage_data: Dictionary = stage_variant as Dictionary
		var stage: Dictionary = _normalize_stage_entry(stage_data)
		if not stage.is_empty():
			out.append(stage)
	return out

func _normalize_stage_entry(stage_data: Dictionary) -> Dictionary:
	var size_value: int = clampi(int(stage_data.get("size", 2)), 2, MATRIX_LIMIT)
	var base_name: String = _sanitize_base(str(stage_data.get("base", "DEC")))
	var raw_solution: Variant = stage_data.get("solution_rows", stage_data.get("row_targets", []))

	var rows_num: PackedInt32Array = _parse_targets(raw_solution, base_name, size_value)
	var cols_num: PackedInt32Array = _compute_col_targets(rows_num, size_value)
	if not _validate_stage_solution(rows_num, cols_num, size_value):
		_log("Invalid stage %dx%d %s. Using fallback." % [size_value, size_value, base_name], COLOR_WARN)
		return _default_stage(size_value, base_name)

	return {
		"size": size_value,
		"base": base_name,
		"solution_rows_num": rows_num,
		"row_targets_num": rows_num,
		"col_targets_num": cols_num
	}

func _fallback_package(is_classic: bool) -> Dictionary:
	var fallback_stages: Array = []
	if is_classic:
		fallback_stages.append(_default_stage(2, "DEC", [3, 0]))
		fallback_stages.append(_default_stage(3, "DEC", [3, 4, 2]))
		fallback_stages.append(_default_stage(4, "OCT", ["13", "14", "02", "16"]))
		fallback_stages.append(_default_stage(5, "OCT", ["13", "34", "22", "16", "05"]))
		fallback_stages.append(_default_stage(6, "HEX", ["2B", "1C", "32", "0E", "25", "17"]))
	else:
		fallback_stages.append(_default_stage(2, "DEC", [2, 1]))
		fallback_stages.append(_default_stage(3, "DEC", [5, 7, 1]))
		fallback_stages.append(_default_stage(4, "OCT", ["13", "05", "07", "16"]))
		fallback_stages.append(_default_stage(5, "OCT", ["37", "10", "14", "05", "21"]))
		fallback_stages.append(_default_stage(6, "HEX", ["3F", "18", "07", "2A", "11", "0C"]))

	return {
		"rules": {
			"hint_limit_per_stage": DEFAULT_HINT_LIMIT,
			"check_cooldown": DEFAULT_CHECK_COOLDOWN
		},
		"stages": fallback_stages
	}

func _default_stage(size_value: int, base_name: String, raw_rows: Array = []) -> Dictionary:
	var source_rows: Array = raw_rows
	if source_rows.is_empty():
		match size_value:
			2:
				source_rows = [2, 1]
			3:
				source_rows = [5, 7, 1]
			4:
				source_rows = [11, 5, 7, 14] if base_name == "DEC" else ["13", "05", "07", "16"]
			5:
				source_rows = [31, 8, 12, 5, 17] if base_name == "DEC" else ["37", "10", "14", "05", "21"]
			6:
				source_rows = ["3F", "18", "07", "2A", "11", "0C"]
			_:
				source_rows = [0]

	var rows_num: PackedInt32Array = _parse_targets(source_rows, base_name, size_value)
	var cols_num: PackedInt32Array = _compute_col_targets(rows_num, size_value)
	return {
		"size": size_value,
		"base": base_name,
		"solution_rows_num": rows_num,
		"row_targets_num": rows_num,
		"col_targets_num": cols_num
	}
func _apply_rules(rules: Dictionary) -> void:
	hint_limit_per_stage = maxi(0, int(rules.get("hint_limit_per_stage", DEFAULT_HINT_LIMIT)))
	check_cooldown_sec = maxf(0.0, float(rules.get("check_cooldown", DEFAULT_CHECK_COOLDOWN)))

func _sanitize_base(base_name: String) -> String:
	var normalized: String = base_name.to_upper()
	if normalized != "DEC" and normalized != "OCT" and normalized != "HEX":
		return "DEC"
	return normalized

func _apply_stage(index: int) -> void:
	if index < 0 or index >= stages.size():
		return

	stage_index = index
	var stage: Dictionary = stages[index] as Dictionary
	stage_size = clampi(int(stage.get("size", 2)), 2, MATRIX_LIMIT)
	display_base = _sanitize_base(str(stage.get("base", "DEC")))
	solution_rows_num = stage.get("solution_rows_num", PackedInt32Array())
	row_targets_num = stage.get("row_targets_num", PackedInt32Array())
	col_targets_num = stage.get("col_targets_num", PackedInt32Array())

	if row_targets_num.size() != stage_size:
		row_targets_num = _parse_targets([], display_base, stage_size)
	if col_targets_num.size() != stage_size:
		col_targets_num = _compute_col_targets(row_targets_num, stage_size)
	if solution_rows_num.size() != stage_size:
		solution_rows_num = row_targets_num

	_rebuild_matrix_layout()
	_reset_grid_state(true)
	_update_headers()
	_update_status()
	hint_text.text = "Match targets on the left and top."
	_log("Stage %d/%d start (%dx%d %s)." % [stage_index + 1, stages.size(), stage_size, stage_size, display_base], COLOR_OK)

func _parse_targets(raw_values: Variant, base_name: String, expected_size: int) -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	out.resize(expected_size)
	var max_value: int = (1 << expected_size) - 1

	if typeof(raw_values) != TYPE_ARRAY:
		for i in range(expected_size):
			out[i] = 0
		return out

	var src: Array = raw_values as Array
	for i in range(expected_size):
		var value_variant: Variant = src[i] if i < src.size() else 0
		out[i] = _parse_target_value(value_variant, base_name, max_value)
	return out

func _parse_target_value(value_variant: Variant, base_name: String, max_value: int) -> int:
	if base_name == "DEC":
		return clampi(int(value_variant), 0, max_value)

	var num_base: int = 8 if base_name == "OCT" else 16
	var text: String = str(value_variant).strip_edges().to_upper()
	if text.begins_with("0X"):
		text = text.substr(2)
	if text.begins_with("0O"):
		text = text.substr(2)
	var parsed: int = _parse_base(text, num_base)
	return clampi(parsed, 0, max_value)

func _parse_base(text: String, num_base: int) -> int:
	if text.is_empty():
		return 0
	var digits: String = "0123456789ABCDEF"
	var value: int = 0
	for i in range(text.length()):
		var digit_text: String = text.substr(i, 1)
		var n: int = digits.find(digit_text)
		if n < 0 or n >= num_base:
			return 0
		value = value * num_base + n
	return value

func _compute_col_targets(rows_num: PackedInt32Array, size_value: int) -> PackedInt32Array:
	var cols: PackedInt32Array = PackedInt32Array()
	cols.resize(size_value)
	for c in range(size_value):
		var col_value: int = 0
		for r in range(size_value):
			var row_value: int = int(rows_num[r]) if r < rows_num.size() else 0
			var bit: int = (row_value >> (size_value - 1 - c)) & 1
			if bit == 1:
				col_value += 1 << (size_value - 1 - r)
		cols[c] = col_value
	return cols

func _validate_stage_solution(rows_num: PackedInt32Array, cols_num: PackedInt32Array, size_value: int) -> bool:
	if rows_num.size() != size_value:
		return false
	if cols_num.size() != size_value:
		return false

	var max_value: int = (1 << size_value) - 1
	var row_zero_count: int = 0
	var row_max_count: int = 0
	var col_zero_count: int = 0
	var col_max_count: int = 0
	var ones_count: int = 0

	for r in range(size_value):
		var row_value: int = int(rows_num[r])
		if row_value == 0:
			row_zero_count += 1
		if row_value == max_value:
			row_max_count += 1
		ones_count += _popcount(row_value)

	for c in range(size_value):
		var col_value: int = int(cols_num[c])
		if col_value == 0:
			col_zero_count += 1
		if col_value == max_value:
			col_max_count += 1

	if row_zero_count > 1 or row_max_count > 1:
		return false
	if col_zero_count > 1 or col_max_count > 1:
		return false

	var density: float = float(ones_count) / float(size_value * size_value)
	if density < 0.25 or density > 0.75:
		return false
	return true

func _popcount(value: int) -> int:
	var x: int = value
	var count: int = 0
	while x > 0:
		count += 1
		x &= x - 1
	return count

func _to_base(value: int, num_base: int) -> String:
	if value == 0:
		return "0"
	var digits: String = "0123456789ABCDEF"
	var out: String = ""
	var v: int = value
	while v > 0:
		var digit: int = v % num_base
		out = digits.substr(digit, 1) + out
		v = int(float(v) / float(num_base))
	return out

func _format_value(value: int) -> String:
	if display_base == "DEC":
		return str(value)
	if display_base == "OCT":
		return _to_base(value, 8)
	if stage_size == 6:
		return "%02X" % value
	return "%X" % value

func _setup_font() -> void:
	var loaded: Variant = load("res://fonts/IBMPlexMono-Medium.ttf")
	if loaded != null:
		_font = loaded as Font
		return
	var fallback: SystemFont = SystemFont.new()
	fallback.font_names = PackedStringArray(["Courier New", "Consolas", "Liberation Mono"])
	_font = fallback

func _cell_size_for_stage() -> float:
	return MIN_CELL_SIZE_TIGHT if stage_size >= 6 else MIN_CELL_SIZE

func _label_size_for_stage() -> float:
	return 64.0 if stage_size >= 6 else 72.0
func _rebuild_matrix_layout() -> void:
	row_target_nodes.clear()
	col_target_nodes.clear()
	cell_buttons.clear()
	grid_values.clear()

	for child in matrix_layout.get_children():
		child.free()

	matrix_layout.columns = stage_size + 1
	var tight: bool = stage_size >= 6
	matrix_layout.add_theme_constant_override("h_separation", 6 if tight else 8)
	matrix_layout.add_theme_constant_override("v_separation", 6 if tight else 8)

	var cell_size: float = _cell_size_for_stage()
	var label_size: float = _label_size_for_stage()

	var corner: Label = _make_corner_label(label_size, cell_size)
	matrix_layout.add_child(corner)

	for c in range(stage_size):
		var col_label: Label = _make_target_label(_format_value(int(col_targets_num[c])), false, cell_size, cell_size)
		matrix_layout.add_child(col_label)
		col_target_nodes.append(col_label)

	for r in range(stage_size):
		var row_label: Label = _make_target_label(_format_value(int(row_targets_num[r])), true, label_size, cell_size)
		matrix_layout.add_child(row_label)
		row_target_nodes.append(row_label)

		var row_buttons: Array = []
		var row_values: Array = []
		for c in range(stage_size):
			var btn: Button = _make_cell_button(r, c, cell_size)
			matrix_layout.add_child(btn)
			row_buttons.append(btn)
			row_values.append(0)
		cell_buttons.append(row_buttons)
		grid_values.append(row_values)

func _make_corner_label(width: float, height: float) -> Label:
	var lbl: Label = Label.new()
	lbl.custom_minimum_size = Vector2(width, height)
	lbl.text = ""
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return lbl

func _make_target_label(text_value: String, is_row: bool, width: float, height: float) -> Label:
	var lbl: Label = Label.new()
	lbl.custom_minimum_size = Vector2(width, height)
	lbl.text = text_value
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if is_row else HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", _font)
	lbl.add_theme_font_size_override("font_size", 20 if stage_size <= 4 else 18)
	lbl.add_theme_color_override("font_color", COLOR_TARGET_DEFAULT)
	return lbl

func _make_cell_button(r: int, c: int, size_px: float) -> Button:
	var btn: Button = Button.new()
	btn.custom_minimum_size = Vector2(size_px, size_px)
	btn.focus_mode = Control.FOCUS_NONE
	btn.text = "0"
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_override("font", _font)
	btn.add_theme_font_size_override("font_size", 24 if stage_size <= 4 else 21)
	btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	btn.pressed.connect(_on_cell_pressed.bind(r, c))
	return btn

func _reset_grid_state(reset_hint_counter: bool) -> void:
	for r in range(stage_size):
		for c in range(stage_size):
			grid_values[r][c] = 0
			_draw_cell(r, c)

	_clear_target_highlights()
	last_wrong_rows = -1
	last_wrong_cols = -1
	check_blocked_until = 0.0
	if reset_hint_counter:
		hint_used_count = 0
	_changed.clear()
	_reset_trial_clock()

func _draw_cell(r: int, c: int) -> void:
	if r < 0 or r >= cell_buttons.size():
		return
	var row: Array = cell_buttons[r] as Array
	if c < 0 or c >= row.size():
		return
	var btn: Button = row[c] as Button
	var bit: int = int(grid_values[r][c])
	btn.disabled = _input_locked or _is_transition
	if bit == 1:
		btn.text = "1"
		btn.self_modulate = Color(0.37, 0.88, 0.65, 1.0)
	else:
		btn.text = "0"
		btn.self_modulate = Color(0.20, 0.22, 0.27, 1.0)
	btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))

func _refresh_grid() -> void:
	for r in range(stage_size):
		for c in range(stage_size):
			_draw_cell(r, c)

func _on_cell_pressed(r: int, c: int) -> void:
	if _input_locked or _is_transition:
		return
	if _first_action_ms < 0:
		_first_action_ms = Time.get_ticks_msec() - _task_started_ms

	AudioManager.play("click")
	grid_values[r][c] = 1 - int(grid_values[r][c])
	_changed["%d,%d" % [r, c]] = true
	_draw_cell(r, c)
	_clear_target_highlights()
	last_wrong_rows = -1
	last_wrong_cols = -1
	_update_status()

func _row_value(row_index: int) -> int:
	var value: int = 0
	for c in range(stage_size):
		if int(grid_values[row_index][c]) == 1:
			value += 1 << (stage_size - 1 - c)
	return value

func _col_value(col_index: int) -> int:
	var value: int = 0
	for r in range(stage_size):
		if int(grid_values[r][col_index]) == 1:
			value += 1 << (stage_size - 1 - r)
	return value

func _evaluate_stage() -> Dictionary:
	var row_values: Array = []
	var col_values: Array = []
	var wrong_rows: Array = []
	var wrong_cols: Array = []
	var delta_sum: int = 0

	for r in range(stage_size):
		var row_now: int = _row_value(r)
		row_values.append(row_now)
		var row_target: int = int(row_targets_num[r])
		if row_now != row_target:
			wrong_rows.append(r)
			delta_sum += abs(row_target - row_now)

	for c in range(stage_size):
		var col_now: int = _col_value(c)
		col_values.append(col_now)
		var col_target: int = int(col_targets_num[c])
		if col_now != col_target:
			wrong_cols.append(c)
			delta_sum += abs(col_target - col_now)

	return {
		"success": wrong_rows.is_empty() and wrong_cols.is_empty(),
		"row_values": row_values,
		"col_values": col_values,
		"wrong_rows": wrong_rows,
		"wrong_cols": wrong_cols,
		"delta_sum": delta_sum
	}

func _clear_target_highlights() -> void:
	for row_node_variant in row_target_nodes:
		var row_lbl: Label = row_node_variant as Label
		if row_lbl != null:
			row_lbl.add_theme_color_override("font_color", COLOR_TARGET_DEFAULT)
			row_lbl.modulate = Color(1, 1, 1, 1)
	for col_node_variant in col_target_nodes:
		var col_lbl: Label = col_node_variant as Label
		if col_lbl != null:
			col_lbl.add_theme_color_override("font_color", COLOR_TARGET_DEFAULT)
			col_lbl.modulate = Color(1, 1, 1, 1)

func _highlight_wrong_targets(wrong_rows: Array, wrong_cols: Array) -> void:
	_clear_target_highlights()
	for row_index_variant in wrong_rows:
		var row_index: int = int(row_index_variant)
		if row_index >= 0 and row_index < row_target_nodes.size():
			var row_lbl: Label = row_target_nodes[row_index] as Label
			if row_lbl != null:
				row_lbl.add_theme_color_override("font_color", COLOR_BAD)
	for col_index_variant in wrong_cols:
		var col_index: int = int(col_index_variant)
		if col_index >= 0 and col_index < col_target_nodes.size():
			var col_lbl: Label = col_target_nodes[col_index] as Label
			if col_lbl != null:
				col_lbl.add_theme_color_override("font_color", COLOR_BAD)

func _mismatch_summary(wrong_rows: Array, wrong_cols: Array) -> String:
	var parts: Array[String] = []
	for row_index_variant in wrong_rows:
		parts.append("R%d" % (int(row_index_variant) + 1))
	for col_index_variant in wrong_cols:
		parts.append("C%d" % (int(col_index_variant) + 1))
	if parts.is_empty():
		return "Mismatch: none"
	return "Mismatch: %s" % ", ".join(parts)
func _on_hint_pressed() -> void:
	if _input_locked or _is_transition:
		hint_text.text = "Input is locked."
		return
	if hint_used_count >= hint_limit_per_stage:
		hint_text.text = "Hint limit reached for this stage."
		_show_toast("HINT LIMIT", COLOR_WARN)
		return

	var eval: Dictionary = _evaluate_stage()
	if bool(eval.get("success", false)):
		hint_text.text = "Targets already match. Press CHECK."
		_show_toast("READY", COLOR_OK)
		return

	var wrong_rows: Array = eval.get("wrong_rows", []) as Array
	var wrong_cols: Array = eval.get("wrong_cols", []) as Array
	if wrong_rows.is_empty() and wrong_cols.is_empty():
		hint_text.text = "No hint available."
		return

	hint_used_count += 1
	var choose_row: bool = not wrong_rows.is_empty() and (wrong_cols.is_empty() or (hint_used_count % 2 == 1))
	if choose_row:
		var row_index: int = int(wrong_rows[0])
		_pulse_target_label(true, row_index)
		hint_text.text = "Hint %d/%d: inspect row target R%d." % [hint_used_count, hint_limit_per_stage, row_index + 1]
		_log("Hint used: focus row R%d." % (row_index + 1), COLOR_WARN)
	else:
		var col_index: int = int(wrong_cols[0])
		_pulse_target_label(false, col_index)
		hint_text.text = "Hint %d/%d: inspect column target C%d." % [hint_used_count, hint_limit_per_stage, col_index + 1]
		_log("Hint used: focus column C%d." % (col_index + 1), COLOR_WARN)

	_show_toast("HINT", COLOR_WARN)
	_update_status()

func _pulse_target_label(is_row: bool, index: int) -> void:
	var node_list: Array = row_target_nodes if is_row else col_target_nodes
	if index < 0 or index >= node_list.size():
		return
	var lbl: Label = node_list[index] as Label
	if lbl == null:
		return
	var tw: Tween = create_tween()
	tw.tween_property(lbl, "modulate", Color(1.0, 0.92, 0.5, 1.0), 0.12)
	tw.tween_property(lbl, "modulate", Color(1, 1, 1, 1), 0.18)
	tw.tween_property(lbl, "modulate", Color(1.0, 0.92, 0.5, 1.0), 0.12)
	tw.tween_property(lbl, "modulate", Color(1, 1, 1, 1), 0.18)

func _on_check_pressed() -> void:
	if _is_transition or _input_locked:
		return

	var now_sec: float = Time.get_ticks_msec() / 1000.0
	if now_sec < check_blocked_until:
		var cooldown: float = maxf(0.0, check_blocked_until - now_sec)
		hint_text.text = "CHECK COOLDOWN: %.2fs" % cooldown
		_show_toast("SHIELD: COOLDOWN", COLOR_WARN)
		_log("Check blocked by cooldown %.2fs." % cooldown, COLOR_WARN)
		_register_result(false, "CHECK_COOLDOWN", 0.0, 0, [], [])
		_update_status()
		return

	if _first_action_ms < 0:
		_first_action_ms = Time.get_ticks_msec() - _task_started_ms

	check_blocked_until = now_sec + check_cooldown_sec
	_check_count += 1

	var eval: Dictionary = _evaluate_stage()
	var wrong_rows: Array = eval.get("wrong_rows", []) as Array
	var wrong_cols: Array = eval.get("wrong_cols", []) as Array
	var delta_sum: int = int(eval.get("delta_sum", 0))

	if bool(eval.get("success", false)):
		_register_result(true, "NONE", 0.0, 0, [], [])
		await _stage_success()
		return

	last_wrong_rows = wrong_rows.size()
	last_wrong_cols = wrong_cols.size()
	_highlight_wrong_targets(wrong_rows, wrong_cols)

	var penalty: float = float(wrong_rows.size() * 5 + wrong_cols.size() * 5 + clampi(int(round(float(delta_sum) / 4.0)), 0, 15))
	AudioManager.play("error")
	_overlay_glitch(0.22, 0.18)
	hint_text.text = "Wrong rows: %d | Wrong cols: %d" % [last_wrong_rows, last_wrong_cols]
	_log(_mismatch_summary(wrong_rows, wrong_cols), COLOR_BAD)
	_show_toast("INCORRECT", COLOR_BAD)
	_register_result(false, "INCORRECT", penalty, delta_sum, wrong_rows, wrong_cols)
	_update_status()

func _stage_success() -> void:
	_is_transition = true
	_set_input_enabled(false)
	AudioManager.play("relay")
	_overlay_glitch(0.12, 0.10)
	_pulse_matrix_frame()
	_show_toast("STAGE COMPLETE", COLOR_OK)
	hint_text.text = "Stage %d/%d complete." % [stage_index + 1, stages.size()]
	_log("Stage %d complete." % (stage_index + 1), COLOR_OK)
	await get_tree().create_timer(0.55).timeout

	var next_stage: int = stage_index + 1
	if next_stage >= stages.size():
		await _complete_run()
		return

	_apply_stage(next_stage)
	_is_transition = false
	_set_input_enabled(true)

func _pulse_matrix_frame() -> void:
	var tw: Tween = create_tween()
	tw.tween_property(matrix_frame, "modulate", Color(0.80, 1.0, 0.85, 1.0), 0.16)
	tw.tween_property(matrix_frame, "modulate", Color(1, 1, 1, 1), 0.20)

func _complete_run() -> void:
	_show_toast("LEVEL COMPLETE", COLOR_OK)
	hint_text.text = "All stages complete."
	_log("Stage ladder complete.", COLOR_OK)
	await get_tree().create_timer(1.1).timeout
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _on_reset_pressed() -> void:
	if _input_locked or _is_transition:
		return
	AudioManager.play("click")
	_reset_grid_state(false)
	hint_text.text = "Stage reset."
	_log("Stage reset.", COLOR_WARN)
	_show_toast("RESET", COLOR_WARN)
	_update_status()

func _update_headers() -> void:
	mode_chip_label.text = _mode_name()
	level_label.text = "PROTOCOL C | MATRIX CLASSIC" if mode == Mode.CLASSIC else "PROTOCOL C | MATRIX STAGES RC"
	matrix_title.text = "Stage %d/%d | %dx%d | %s" % [stage_index + 1, stages.size(), stage_size, stage_size, display_base]

func _update_status() -> void:
	var cooldown: float = maxf(0.0, check_blocked_until - (Time.get_ticks_msec() / 1000.0))
	var wrong_rows_text: String = "-" if last_wrong_rows < 0 else str(last_wrong_rows)
	var wrong_cols_text: String = "-" if last_wrong_cols < 0 else str(last_wrong_cols)

	progress_label.text = "STAGE %d/%d | BASE %s | HINT %d/%d" % [stage_index + 1, stages.size(), display_base, hint_used_count, hint_limit_per_stage]
	mode_state_label.text = "WRONG ROWS: %s | WRONG COLS: %s" % [wrong_rows_text, wrong_cols_text]
	if cooldown > 0.0:
		mode_state_label.text += " | CD %.2fs" % cooldown

	shield_freq.modulate = Color(1, 1, 1, 1.0 if cooldown > 0.0 else 0.25)

func _on_stability_changed(new_val: float, _change: float) -> void:
	_refresh_stability(new_val)

func _refresh_stability(value: float) -> void:
	progress_stability.value = value
	stability_text.text = "Stability: %d%%" % int(value)

func _set_input_enabled(enabled: bool) -> void:
	_input_locked = not enabled
	btn_check.disabled = not enabled
	btn_hint.disabled = not enabled
	btn_reset.disabled = not enabled
	_refresh_grid()

func _reset_trial_clock() -> void:
	_task_started_ms = Time.get_ticks_msec()
	_first_action_ms = -1
	_check_count = 0

func _register_result(success: bool, error_type: String, penalty: float, delta_sum: int, wrong_rows: Array, wrong_cols: Array) -> void:
	var run_id: String = classic_level_id if mode == Mode.CLASSIC else level_id
	var hash_key: String = str(hash("%s|%d|%s" % [run_id, stage_index, display_base]))
	var mode_key: String = "MATRIX_CLASSIC" if mode == Mode.CLASSIC else "MATRIX_STAGES_RC"
	var payload_variant: Variant = TrialV2.build("MATRIX_DECRYPTOR", "C", mode_key, "GRID_CHECK", hash_key)
	if typeof(payload_variant) != TYPE_DICTIONARY:
		return

	var payload: Dictionary = payload_variant as Dictionary
	var elapsed_ms: int = maxi(0, Time.get_ticks_msec() - _task_started_ms)
	payload["elapsed_ms"] = elapsed_ms
	payload["duration"] = float(elapsed_ms) / 1000.0
	payload["time_to_first_action_ms"] = _first_action_ms if _first_action_ms >= 0 else elapsed_ms
	payload["is_correct"] = success
	payload["is_fit"] = success
	payload["stability_delta"] = -penalty if not success else 0.0
	payload["error_type"] = error_type
	payload["penalty_reported"] = penalty
	payload["changed_cells_count"] = _changed.size()
	payload["check_count"] = _check_count
	payload["stage_index"] = stage_index + 1
	payload["stage_total"] = stages.size()
	payload["stage_size"] = stage_size
	payload["stage_base"] = display_base
	payload["wrong_rows"] = wrong_rows.size()
	payload["wrong_cols"] = wrong_cols.size()
	payload["wrong_row_indices"] = wrong_rows
	payload["wrong_col_indices"] = wrong_cols
	payload["delta_sum"] = delta_sum
	payload["hint_used_count"] = hint_used_count
	payload["hint_limit_per_stage"] = hint_limit_per_stage
	payload["check_cooldown_sec"] = check_cooldown_sec
	GlobalMetrics.register_trial(payload)

func _log(msg: String, color: Color) -> void:
	var line: String = "[%s] %s" % [Time.get_time_string_from_system(), msg]
	_logs.append(line)
	if _logs.size() > 220:
		_logs.remove_at(0)
	details_text.text = "\n".join(_logs)
	var start_index: int = maxi(0, _logs.size() - 18)
	var tail: Array = _logs.slice(start_index, _logs.size())
	live_log_text.text = "\n".join(tail)
	live_log_text.add_theme_color_override("default_color", color)

func _show_toast(msg: String, color: Color) -> void:
	toast_label.text = msg
	toast_label.add_theme_color_override("font_color", color)
	toast_panel.visible = true
	toast_panel.modulate = Color(1, 1, 1, 0)
	var tw: Tween = create_tween()
	tw.tween_property(toast_panel, "modulate", Color(1, 1, 1, 1), 0.15)
	tw.tween_interval(0.85)
	tw.tween_property(toast_panel, "modulate", Color(1, 1, 1, 0), 0.20)
	tw.tween_callback(func() -> void: toast_panel.visible = false)

func _on_details_pressed() -> void:
	_set_details_open(not _details_open, false)

func _set_details_open(open: bool, immediate: bool) -> void:
	_details_open = open
	if open:
		details_sheet.visible = true

	var target_top: float = -_details_sheet_height if open else 0.0
	var target_bottom: float = 0.0 if open else _details_sheet_height
	if immediate:
		details_sheet.offset_top = target_top
		details_sheet.offset_bottom = target_bottom
		if not open:
			details_sheet.visible = false
		return

	var tw: Tween = create_tween()
	tw.tween_property(details_sheet, "offset_top", target_top, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(details_sheet, "offset_bottom", target_bottom, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if not open:
		tw.tween_callback(func() -> void: details_sheet.visible = false)

func _on_viewport_size_changed() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var is_landscape: bool = viewport_size.x >= viewport_size.y
	var phone_landscape: bool = is_landscape and viewport_size.y <= PHONE_LANDSCAPE_MAX_HEIGHT
	var phone_portrait: bool = (not is_landscape) and viewport_size.x <= PHONE_PORTRAIT_MAX_WIDTH
	var compact: bool = phone_landscape or phone_portrait

	_apply_safe_area_padding(compact)
	main_root.add_theme_constant_override("separation", 8 if compact else 12)
	header_content.add_theme_constant_override("separation", 6 if compact else 8)
	content_split.add_theme_constant_override("separation", 8 if compact else 12)
	bottom_actions.add_theme_constant_override("separation", 8 if compact else 10)
	_set_content_mobile_mode(phone_portrait)

	btn_back.custom_minimum_size = Vector2(56.0 if compact else 72.0, 56.0 if compact else 72.0)
	btn_details.custom_minimum_size = Vector2(64.0 if compact else 72.0, 44.0 if compact else 48.0)
	btn_hint.custom_minimum_size = Vector2(96.0 if compact else 120.0, 52.0 if compact else 56.0)
	btn_check.custom_minimum_size = Vector2(132.0 if compact else 180.0, 52.0 if compact else 56.0)
	btn_reset.custom_minimum_size = Vector2(96.0 if compact else 120.0, 52.0 if compact else 56.0)
	progress_stability.custom_minimum_size.x = 140.0 if compact else 170.0

	_details_sheet_height = clampf(viewport_size.y * (0.62 if compact else 0.55), 220.0, DETAILS_SHEET_H)
	if _details_open:
		_set_details_open(true, true)

	var toast_half_width: float = clampf(viewport_size.x * 0.34, 130.0, 240.0)
	toast_panel.offset_left = -toast_half_width
	toast_panel.offset_right = toast_half_width

func _set_content_mobile_mode(use_mobile: bool) -> void:
	var mobile_layout: VBoxContainer = _ensure_content_mobile_layout()
	if use_mobile:
		if content_split.visible:
			if left_panel.get_parent() != mobile_layout:
				left_panel.reparent(mobile_layout)
			if right_panel.get_parent() != mobile_layout:
				right_panel.reparent(mobile_layout)
		content_split.visible = false
		mobile_layout.visible = true
	else:
		if not content_split.visible:
			if left_panel.get_parent() != content_split:
				left_panel.reparent(content_split)
			if right_panel.get_parent() != content_split:
				right_panel.reparent(content_split)
		mobile_layout.visible = false
		content_split.visible = true

func _ensure_content_mobile_layout() -> VBoxContainer:
	if _content_mobile_layout != null and is_instance_valid(_content_mobile_layout):
		return _content_mobile_layout
	_content_mobile_layout = VBoxContainer.new()
	_content_mobile_layout.name = "ContentMobileLayout"
	_content_mobile_layout.visible = false
	_content_mobile_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_mobile_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_mobile_layout.add_theme_constant_override("separation", 8)
	main_root.add_child(_content_mobile_layout)
	main_root.move_child(_content_mobile_layout, main_root.get_children().find(content_split) + 1)
	return _content_mobile_layout

func _apply_safe_area_padding(compact: bool) -> void:
	var left: float = 8.0 if compact else 16.0
	var top: float = 8.0 if compact else 12.0
	var right: float = 8.0 if compact else 16.0
	var bottom: float = 8.0 if compact else 12.0

	var safe_rect: Rect2i = DisplayServer.get_display_safe_area()
	if safe_rect.size.x > 0 and safe_rect.size.y > 0:
		var viewport_size: Vector2 = get_viewport_rect().size
		left = maxf(left, float(safe_rect.position.x))
		top = maxf(top, float(safe_rect.position.y))
		right = maxf(right, viewport_size.x - float(safe_rect.position.x + safe_rect.size.x))
		bottom = maxf(bottom, viewport_size.y - float(safe_rect.position.y + safe_rect.size.y))

	safe_area.add_theme_constant_override("margin_left", int(round(left)))
	safe_area.add_theme_constant_override("margin_top", int(round(top)))
	safe_area.add_theme_constant_override("margin_right", int(round(right)))
	safe_area.add_theme_constant_override("margin_bottom", int(round(bottom)))

func _overlay_glitch(strength: float, duration: float) -> void:
	if noir_overlay != null and noir_overlay.has_method("glitch_burst"):
		noir_overlay.call("glitch_burst", strength, duration)

func _mode_name() -> String:
	return "CLASSIC" if mode == Mode.CLASSIC else "STAGES_RC"

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")
