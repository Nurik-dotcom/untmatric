extends Control

enum Mode { CLASSIC, STAGES }

const MATRIX_LIMIT := 6
const STAGES_DATA_PATH := "res://data/matrix_stages_levels.json"
const CLASSIC_DATA_PATH := "res://data/matrix_ladder_levels.json"
const DEFAULT_STAGE_LEVEL_ID := "C_STAGES_001"
const DEFAULT_CLASSIC_LEVEL_ID := "C_LADDER_001"

const COLOR_OK := Color("33ff66")
const COLOR_WARN := Color("ffcc00")
const COLOR_BAD := Color("ff5555")

const MIN_CELL_SIZE := 64
const MIN_CELL_SIZE_TIGHT := 56
const DETAILS_SHEET_H := 360.0
const FREQ_WINDOW_SEC := 2.0
const FREQ_MAX_IN_WINDOW := 3
const FREQ_BLOCK_SEC := 2.5

@export var mode: int = Mode.STAGES
@export var level_id: String = DEFAULT_STAGE_LEVEL_ID
@export var classic_level_id: String = DEFAULT_CLASSIC_LEVEL_ID

@onready var btn_back: Button = $UI/SafeArea/Main/HeaderBar/HeaderContent/BtnBack
@onready var btn_details: Button = $UI/SafeArea/Main/HeaderBar/HeaderContent/BtnDetails
@onready var btn_close_details: Button = $UI/DetailsSheet/DetailsContent/DetailsHeader/BtnCloseDetails
@onready var mode_chip_label: Label = $UI/SafeArea/Main/HeaderBar/HeaderContent/ModeChip/ModeLabel
@onready var level_label: Label = $UI/SafeArea/Main/HeaderBar/HeaderContent/LevelLabel
@onready var stability_text: Label = $UI/SafeArea/Main/HeaderBar/HeaderContent/StabilityGroup/StabilityText
@onready var progress_stability: ProgressBar = $UI/SafeArea/Main/HeaderBar/HeaderContent/StabilityGroup/StabilityBar
@onready var shield_freq: Label = $UI/SafeArea/Main/HeaderBar/HeaderContent/Shields/ShieldFreq
@onready var shield_lazy: Label = $UI/SafeArea/Main/HeaderBar/HeaderContent/Shields/ShieldLazy

@onready var matrix_title: Label = $UI/SafeArea/Main/ContentSplit/LeftPanel/MatrixPanel/MatrixContent/MatrixTitle
@onready var row_labels: VBoxContainer = $UI/SafeArea/Main/ContentSplit/LeftPanel/MatrixPanel/MatrixContent/MatrixBoard/RowLabels
@onready var col_labels: HBoxContainer = $UI/SafeArea/Main/ContentSplit/LeftPanel/MatrixPanel/MatrixContent/MatrixBoard/MatrixStack/ColumnLabels
@onready var grid: GridContainer = $UI/SafeArea/Main/ContentSplit/LeftPanel/MatrixPanel/MatrixContent/MatrixBoard/MatrixStack/Grid
@onready var inlet_tag: Label = $UI/SafeArea/Main/ContentSplit/LeftPanel/MatrixPanel/MatrixContent/InOutRow/InletTag
@onready var outlet_tag: Label = $UI/SafeArea/Main/ContentSplit/LeftPanel/MatrixPanel/MatrixContent/InOutRow/OutletTag
@onready var constraint_hint: Label = $UI/SafeArea/Main/ContentSplit/LeftPanel/MatrixPanel/MatrixContent/ConstraintHint

@onready var btn_hint: Button = $UI/SafeArea/Main/BottomBar/Actions/BtnHint
@onready var btn_check: Button = $UI/SafeArea/Main/BottomBar/Actions/BtnCheck
@onready var btn_reset: Button = $UI/SafeArea/Main/BottomBar/Actions/BtnReset

@onready var progress_label: Label = $UI/SafeArea/Main/ContentSplit/RightPanel/StatusPanel/StatusContent/ProgressLabel
@onready var mode_state_label: Label = $UI/SafeArea/Main/ContentSplit/RightPanel/StatusPanel/StatusContent/ModeLabel
@onready var hint_text: Label = $UI/SafeArea/Main/ContentSplit/RightPanel/HintPanel/HintContent/HintText
@onready var live_log_text: RichTextLabel = $UI/SafeArea/Main/ContentSplit/RightPanel/LiveLogPanel/LiveLogContent/LiveLogText
@onready var targets_rows: VBoxContainer = $UI/SafeArea/Main/ContentSplit/RightPanel/TargetsPanel/TargetsContent/TargetsRows

@onready var toast_panel: PanelContainer = $UI/ToastLayer/Toast
@onready var toast_label: Label = $UI/ToastLayer/Toast/ToastLabel
@onready var details_sheet: PanelContainer = $UI/DetailsSheet
@onready var details_text: RichTextLabel = $UI/DetailsSheet/DetailsContent/DetailsScroll/DetailsText
@onready var noir_overlay = $UI/NoirOverlay

var stages: Array = []
var stage_index := 0
var stage_size := 2
var base := "DEC"
var row_targets_num: PackedInt32Array = PackedInt32Array()

var grid_values: Array = []
var button_rows: Array = []
var row_panels: Array = []
var target_nodes: Array = []
var now_nodes: Array = []
var state_nodes: Array = []
var side_target_nodes: Array = []
var row_wrong_flags: PackedByteArray = PackedByteArray()

var _font: Font
var _input_locked := false
var _is_transition := false
var _details_open := false
var _shield_token := 0
var _blocked_until := 0.0
var _check_times: Array[float] = []
var _logs: Array[String] = []

var _task_started_ms := 0
var _first_action_ms := -1
var _check_count := 0
var _actions_since_check := 0
var _changed: Dictionary = {}

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

func _prepare_layout() -> void:
	row_labels.visible = true
	col_labels.visible = false
	if inlet_tag.get_parent() != null:
		inlet_tag.get_parent().visible = false
	outlet_tag.visible = false
	constraint_hint.visible = false
	shield_lazy.visible = false
	shield_freq.modulate = Color(1, 1, 1, 0.25)
	mode_chip_label.text = _mode_name()

func _start_run() -> void:
	_is_transition = false
	_input_locked = false
	_blocked_until = 0.0
	_check_times.clear()
	_changed.clear()
	_actions_since_check = 0
	_reset_trial_clock()
	GlobalMetrics.stability = 100.0
	GlobalMetrics.emit_signal("stability_changed", GlobalMetrics.stability, 0.0)

	var data_path := STAGES_DATA_PATH
	var selected_id := level_id
	if mode == Mode.CLASSIC:
		data_path = CLASSIC_DATA_PATH
		selected_id = classic_level_id

	stages = _load_stages_from_file(data_path, selected_id)
	if stages.is_empty():
		stages = _fallback_stages(mode == Mode.CLASSIC)

	stage_index = 0
	_apply_stage(stage_index)
	_set_input_enabled(true)
	_refresh_stability(GlobalMetrics.stability)
	_update_status()
	hint_text.text = "Flip bits and press CHECK."
	_log("Run started: %s." % _mode_name(), COLOR_OK)

func _load_stages_from_file(path: String, selected_id: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return []
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return []
	var levels = parsed.get("levels", [])
	if typeof(levels) != TYPE_ARRAY:
		return []
	for level in levels:
		if typeof(level) != TYPE_DICTIONARY:
			continue
		if str(level.get("id", "")) != selected_id:
			continue
		return _normalize_stages(level.get("stages", []))
	return []

func _normalize_stages(raw_stages: Variant) -> Array:
	var out: Array = []
	if typeof(raw_stages) != TYPE_ARRAY:
		return out
	for item in raw_stages:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var stage: Dictionary = item
		var stage_size := clampi(int(stage.get("size", 2)), 2, MATRIX_LIMIT)
		var stage_base := str(stage.get("base", "DEC")).to_upper()
		if stage_base != "DEC" and stage_base != "OCT" and stage_base != "HEX":
			stage_base = "DEC"
		out.append({
			"size": stage_size,
			"base": stage_base,
			"row_targets_num": _parse_targets(stage.get("row_targets", []), stage_base, stage_size)
		})
	return out

func _fallback_stages(is_classic: bool) -> Array:
	if is_classic:
		return _normalize_stages([
			{"size": 2, "base": "DEC", "row_targets": [3, 0]},
			{"size": 3, "base": "DEC", "row_targets": [3, 4, 2]},
			{"size": 4, "base": "OCT", "row_targets": ["13", "14", "02", "16"]},
			{"size": 5, "base": "OCT", "row_targets": ["13", "34", "22", "16", "05"]},
			{"size": 6, "base": "HEX", "row_targets": ["2B", "1C", "32", "0E", "25", "17"]}
		])
	return _normalize_stages([
		{"size": 2, "base": "DEC", "row_targets": [2, 1]},
		{"size": 3, "base": "DEC", "row_targets": [5, 7, 1]},
		{"size": 4, "base": "OCT", "row_targets": ["13", "05", "07", "16"]},
		{"size": 5, "base": "OCT", "row_targets": ["37", "10", "14", "05", "21"]},
		{"size": 6, "base": "HEX", "row_targets": ["3F", "18", "07", "2A", "11", "0C"]}
	])

func _apply_stage(index: int) -> void:
	if index < 0 or index >= stages.size():
		return
	stage_index = index
	var stage: Dictionary = stages[index]
	stage_size = clampi(int(stage.get("size", 2)), 2, MATRIX_LIMIT)
	base = str(stage.get("base", "DEC")).to_upper()
	row_targets_num = stage.get("row_targets_num", PackedInt32Array())
	if row_targets_num.size() != stage_size:
		row_targets_num = _parse_targets([], base, stage_size)

	_rebuild_grid(stage_size)
	_rebuild_side_targets()
	_rebuild_targets(stage_size)
	_clear_stage()
	_update_headers()
	_update_status()
	hint_text.text = "Stage start. Fill bits to match row targets."
	_log("Stage %d/%d start (%dx%d %s)." % [stage_index + 1, stages.size(), stage_size, stage_size, base], COLOR_OK)

func _parse_targets(raw: Variant, base_name: String, expected: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	out.resize(expected)
	var max_value := (1 << expected) - 1
	if typeof(raw) != TYPE_ARRAY:
		for i in range(expected):
			out[i] = 0
		return out
	var src: Array = raw
	for i in range(expected):
		var v = src[i] if i < src.size() else 0
		out[i] = _parse_target(v, base_name, max_value)
	return out

func _parse_target(v: Variant, base_name: String, max_value: int) -> int:
	var parsed := 0
	if base_name == "DEC":
		parsed = int(v)
	else:
		var num_base := 8 if base_name == "OCT" else 16
		var text := str(v).strip_edges().to_upper()
		if text.begins_with("0X"):
			text = text.substr(2)
		if text.begins_with("0O"):
			text = text.substr(2)
		parsed = _parse_base(text, num_base)
	return clampi(parsed, 0, max_value)

func _parse_base(text: String, num_base: int) -> int:
	if text.is_empty():
		return 0
	var digits := "0123456789ABCDEF"
	var value := 0
	for i in range(text.length()):
		var n := digits.find(text.substr(i, 1))
		if n < 0 or n >= num_base:
			return 0
		value = value * num_base + n
	return value

func _to_base(value: int, num_base: int) -> String:
	if value == 0:
		return "0"
	var digits := "0123456789ABCDEF"
	var v := value
	var out := ""
	while v > 0:
		var d := v % num_base
		out = digits.substr(d, 1) + out
		v = int(v / num_base)
	return out

func _format_value(value: int) -> String:
	if base == "DEC":
		return str(value)
	if base == "OCT":
		return _to_base(value, 8)
	if stage_size == 6:
		return "%02X" % value
	return "%X" % value

func _setup_font() -> void:
	var loaded = load("res://fonts/IBMPlexMono-Medium.ttf")
	if loaded != null:
		_font = loaded
		return
	var fallback := SystemFont.new()
	fallback.font_names = PackedStringArray(["Courier New", "Consolas", "Liberation Mono"])
	_font = fallback

func _cell_size_for_stage() -> float:
	return MIN_CELL_SIZE_TIGHT if stage_size >= 6 else MIN_CELL_SIZE

func _rebuild_grid(stage_size: int) -> void:
	button_rows.clear()
	grid_values.clear()
	for child in grid.get_children():
		child.queue_free()

	grid.columns = stage_size
	var tight := stage_size >= 6
	grid.add_theme_constant_override("h_separation", 6 if tight else 8)
	grid.add_theme_constant_override("v_separation", 6 if tight else 8)
	var cell_size := _cell_size_for_stage()

	for r in range(stage_size):
		var button_row: Array = []
		var value_row: Array = []
		for c in range(stage_size):
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(cell_size, cell_size)
			btn.focus_mode = Control.FOCUS_NONE
			btn.text = "0"
			btn.add_theme_font_override("font", _font)
			btn.add_theme_font_size_override("font_size", 24 if stage_size <= 4 else 21)
			btn.pressed.connect(_on_cell_pressed.bind(r, c))
			grid.add_child(btn)
			button_row.append(btn)
			value_row.append(0)
		button_rows.append(button_row)
		grid_values.append(value_row)

func _rebuild_targets(stage_size: int) -> void:
	row_panels.clear()
	target_nodes.clear()
	now_nodes.clear()
	state_nodes.clear()
	for child in targets_rows.get_children():
		child.queue_free()

	row_wrong_flags = PackedByteArray()
	row_wrong_flags.resize(stage_size)
	var cell_size := _cell_size_for_stage()

	for r in range(stage_size):
		var row_panel := PanelContainer.new()
		row_panel.custom_minimum_size = Vector2(0, cell_size)
		var row_box := HBoxContainer.new()
		row_box.layout_mode = 2
		row_box.add_theme_constant_override("separation", 8)
		row_panel.add_child(row_box)

		var idx := Label.new()
		idx.custom_minimum_size = Vector2(40, 28)
		idx.text = "R%d" % (r + 1)

		var target := Label.new()
		target.custom_minimum_size = Vector2(96, 28)
		target.text = "target --"

		var now := Label.new()
		now.custom_minimum_size = Vector2(88, 28)
		now.text = "now --"

		var state := Label.new()
		state.custom_minimum_size = Vector2(60, 28)
		state.text = "..."
		state.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

		for lbl in [idx, target, now, state]:
			lbl.add_theme_font_override("font", _font)
			lbl.add_theme_font_size_override("font_size", 17)
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		row_box.add_child(idx)
		row_box.add_child(target)
		row_box.add_child(now)
		row_box.add_child(state)

		targets_rows.add_child(row_panel)
		row_panels.append(row_panel)
		target_nodes.append(target)
		now_nodes.append(now)
		state_nodes.append(state)

func _rebuild_side_targets() -> void:
	side_target_nodes.clear()
	for child in row_labels.get_children():
		child.queue_free()

	row_labels.alignment = BoxContainer.ALIGNMENT_BEGIN
	var cell_size := _cell_size_for_stage()
	row_labels.add_theme_constant_override("separation", 6 if stage_size >= 6 else 8)
	for r in range(stage_size):
		var lbl := Label.new()
		lbl.custom_minimum_size = Vector2(92, cell_size)
		lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.text = _format_value(int(row_targets_num[r]))
		lbl.add_theme_font_override("font", _font)
		lbl.add_theme_font_size_override("font_size", 19 if stage_size <= 4 else 17)
		lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		row_labels.add_child(lbl)
		side_target_nodes.append(lbl)

func _clear_stage() -> void:
	for r in range(stage_size):
		for c in range(stage_size):
			grid_values[r][c] = 0
			_draw_cell(r, c)
	for r in range(stage_size):
		row_wrong_flags[r] = 0
	_actions_since_check = 0
	_changed.clear()
	_check_times.clear()
	_blocked_until = 0.0
	_refresh_targets_all()
	_reset_trial_clock()

func _draw_cell(r: int, c: int) -> void:
	if r < 0 or r >= button_rows.size():
		return
	var row: Array = button_rows[r]
	if c < 0 or c >= row.size():
		return
	var btn: Button = row[c]
	var bit := int(grid_values[r][c])
	btn.disabled = _input_locked or _is_transition
	if bit == 1:
		btn.text = "1"
		btn.self_modulate = Color(0.36, 0.92, 0.63, 1.0)
		btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	else:
		btn.text = "0"
		btn.self_modulate = Color(0.23, 0.25, 0.29, 1.0)
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
	row_wrong_flags[r] = 0
	_changed["%d,%d" % [r, c]] = true
	_actions_since_check += 1

	_draw_cell(r, c)
	_update_row_now(r)
	_update_status()

func _row_sum(row_index: int) -> int:
	var sum := 0
	for c in range(stage_size):
		if int(grid_values[row_index][c]) == 1:
			sum += _weight(c)
	return sum

func _weight(col: int) -> int:
	return 1 << (stage_size - 1 - col)

func _evaluate_stage() -> Dictionary:
	var wrong_rows: Array = []
	var nows: Array = []
	var delta_sum := 0
	for r in range(stage_size):
		var now := _row_sum(r)
		var target := int(row_targets_num[r])
		nows.append(now)
		if now != target:
			wrong_rows.append(r)
			delta_sum += abs(now - target)
	return {
		"success": wrong_rows.is_empty(),
		"wrong_rows": wrong_rows,
		"wrong_count": wrong_rows.size(),
		"delta_sum": delta_sum,
		"nows": nows
	}

func _refresh_targets_all() -> void:
	var eval := _evaluate_stage()
	var nows: Array = eval.get("nows", [])
	for r in range(stage_size):
		_update_row_ui(r, int(nows[r]))

func _update_row_now(r: int) -> void:
	if r < 0 or r >= stage_size:
		return
	_update_row_ui(r, _row_sum(r))

func _update_row_ui(r: int, now_value: int) -> void:
	var target_value := int(row_targets_num[r])
	var ok := now_value == target_value
	target_nodes[r].text = "target %s" % _format_value(target_value)
	now_nodes[r].text = "now %s" % _format_value(now_value)
	state_nodes[r].text = "OK" if ok else "ERR"
	state_nodes[r].add_theme_color_override("font_color", COLOR_OK if ok else COLOR_BAD)

	if row_wrong_flags[r] == 1 and not ok:
		row_panels[r].modulate = Color(1.0, 0.74, 0.74, 1.0)
	else:
		row_panels[r].modulate = Color(1, 1, 1, 1)

func _update_headers() -> void:
	mode_chip_label.text = _mode_name()
	level_label.text = "PROTOCOL C | MATRIX CLASSIC" if mode == Mode.CLASSIC else "PROTOCOL C | MATRIX STAGES"
	matrix_title.text = "\u042D\u0442\u0430\u043F %d/%d | %dx%d | %s" % [stage_index + 1, stages.size(), stage_size, stage_size, base]

func _update_status() -> void:
	var eval: Dictionary = _evaluate_stage()
	var cooldown: float = maxf(0.0, _blocked_until - (Time.get_ticks_msec() / 1000.0))
	progress_label.text = "STAGE %d/%d | BASE %s | WRONG %d" % [stage_index + 1, stages.size(), base, int(eval.get("wrong_count", 0))]
	mode_state_label.text = "MODE: %s | SHIELD: %s" % [_mode_name(), "COOLDOWN %.1fs" % cooldown if cooldown > 0.0 else "READY"]
	shield_freq.modulate = Color(1, 1, 1, 1.0 if cooldown > 0.0 else 0.25)

func _on_hint_pressed() -> void:
	if _input_locked or _is_transition:
		hint_text.text = "Input is locked."
		return
	var eval: Dictionary = _evaluate_stage()
	if bool(eval.get("success", false)):
		hint_text.text = "All rows match target. Press CHECK."
		_show_toast("READY", COLOR_OK)
		return
	var wrong_rows: Array = eval.get("wrong_rows", [])
	if wrong_rows.is_empty():
		hint_text.text = "No hint available."
		return
	var r := int(wrong_rows[0])
	var target := int(row_targets_num[r])
	var now := _row_sum(r)
	var best := _best_flip_for_row(r, target)
	if best.is_empty():
		hint_text.text = "Row %d mismatch. Flip one bit." % (r + 1)
		return
	var need := target - now
	var sign := "+" if need >= 0 else ""
	var weight := int(best.get("weight", 0))
	hint_text.text = "Row %d: need %s%d (flip weight %d)." % [r + 1, sign, need, weight]
	_log("Hint: row %d need %s%d (flip weight %d)." % [r + 1, sign, need, weight], COLOR_WARN)
	_blink_hint_cell(r, int(best.get("col", -1)))
	_show_toast("HINT", COLOR_WARN)

func _best_flip_for_row(r: int, target: int) -> Dictionary:
	var best: Dictionary = {}
	var best_score: int = 1_000_000
	var current_sum: int = _row_sum(r)
	for c in range(stage_size):
		var cur: int = int(grid_values[r][c])
		var next_bit: int = 1 - cur
		var new_sum: int = current_sum + (next_bit - cur) * _weight(c)
		var score: int = abs(target - new_sum)
		if score < best_score:
			best_score = score
			best = {
				"col": c,
				"weight": _weight(c),
				"new_sum": new_sum,
				"new_bit": next_bit
			}
	return best

func _blink_hint_cell(r: int, c: int) -> void:
	if r < 0 or r >= button_rows.size():
		return
	if c < 0 or c >= button_rows[r].size():
		return
	var btn: Button = button_rows[r][c]
	var base_modulate: Color = btn.self_modulate
	var tw: Tween = create_tween()
	tw.tween_property(btn, "self_modulate", Color(1.0, 0.88, 0.35, 1.0), 0.12)
	tw.tween_property(btn, "self_modulate", base_modulate, 0.16)
	tw.tween_property(btn, "self_modulate", Color(1.0, 0.88, 0.35, 1.0), 0.12)
	tw.tween_property(btn, "self_modulate", base_modulate, 0.16)

func _on_check_pressed() -> void:
	if _is_transition:
		return
	var now_sec: float = Time.get_ticks_msec() / 1000.0
	if now_sec < _blocked_until:
		var cooldown: float = maxf(0.0, _blocked_until - now_sec)
		hint_text.text = "SHIELD: COOLDOWN %.1fs" % cooldown
		_show_toast("SHIELD: COOLDOWN", COLOR_WARN)
		_register_result(false, "SHIELD_ACTIVE", 0.0, 0, [])
		_update_status()
		return
	if _input_locked:
		return

	_check_count += 1
	_check_times.append(now_sec)
	var cutoff: float = now_sec - FREQ_WINDOW_SEC
	while _check_times.size() > 0 and _check_times[0] < cutoff:
		_check_times.pop_front()
	if _check_times.size() > FREQ_MAX_IN_WINDOW:
		await _trigger_frequency_shield()
		_register_result(false, "SHIELD_FREQ", 0.0, 0, [])
		return

	var eval: Dictionary = _evaluate_stage()
	var wrong_rows: Array = eval.get("wrong_rows", [])
	var wrong_count: int = int(eval.get("wrong_count", 0))
	var delta_sum: int = int(eval.get("delta_sum", 0))

	if bool(eval.get("success", false)):
		_register_result(true, "NONE", 0.0, 0, [])
		await _stage_success()
		return

	for r in range(stage_size):
		row_wrong_flags[r] = 1 if wrong_rows.has(r) else 0
	_refresh_targets_all()
	_highlight_wrong_rows(wrong_rows)

	var penalty := float(wrong_count * 5 + clampi(int(round(float(delta_sum) / 4.0)), 0, 15))

	AudioManager.play("error")
	_overlay_glitch(0.45, 0.16)
	hint_text.text = "Wrong rows: %d | delta: %d | penalty: %d" % [wrong_count, delta_sum, int(penalty)]
	_log("Check failed. wrong=%d delta=%d penalty=%d" % [wrong_count, delta_sum, int(penalty)], COLOR_BAD)
	_show_toast("INCORRECT", COLOR_BAD)
	_register_result(false, "INCORRECT", penalty, delta_sum, wrong_rows)
	_actions_since_check = 0
	_changed.clear()
	_update_status()

func _trigger_frequency_shield() -> void:
	_blocked_until = (Time.get_ticks_msec() / 1000.0) + FREQ_BLOCK_SEC
	_shield_token += 1
	var token := _shield_token
	AudioManager.play("error")
	_overlay_glitch(0.32, 0.14)
	_show_toast("SHIELD: COOLDOWN", COLOR_WARN)
	hint_text.text = "SHIELD: COOLDOWN %.1fs" % FREQ_BLOCK_SEC
	_log("Frequency shield activated.", COLOR_WARN)
	GlobalMetrics.emit_signal("shield_triggered", "FREQUENCY", FREQ_BLOCK_SEC)
	_set_input_enabled(false)
	_update_status()
	await get_tree().create_timer(FREQ_BLOCK_SEC).timeout
	if token != _shield_token:
		return
	if _is_transition:
		return
	if (Time.get_ticks_msec() / 1000.0) >= _blocked_until:
		_set_input_enabled(true)
		_update_status()
		_log("Shield released.", COLOR_OK)

func _highlight_wrong_rows(wrong_rows: Array) -> void:
	for row_index in wrong_rows:
		var r := int(row_index)
		if r < 0 or r >= button_rows.size():
			continue
		for c in range(stage_size):
			button_rows[r][c].self_modulate = Color(1.0, 0.48, 0.48, 1.0)
		var row_id := r
		var tw := create_tween()
		tw.tween_interval(0.16)
		tw.tween_callback(func() -> void:
			for c in range(stage_size):
				_draw_cell(row_id, c)
		)

func _stage_success() -> void:
	_is_transition = true
	_set_input_enabled(false)
	AudioManager.play("relay")
	_overlay_glitch(0.12, 0.1)
	_show_toast("STAGE COMPLETE", COLOR_OK)
	hint_text.text = "Stage complete."
	_log("Stage %d complete." % (stage_index + 1), COLOR_OK)
	_actions_since_check = 0
	_changed.clear()
	await get_tree().create_timer(0.55).timeout

	var next_stage := stage_index + 1
	if next_stage >= stages.size():
		await _complete_run()
		return
	_apply_stage(next_stage)
	_is_transition = false
	_set_input_enabled(true)

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
	_clear_stage()
	_update_status()
	hint_text.text = "Stage cleared."
	_log("Stage reset.", COLOR_WARN)
	_show_toast("RESET", COLOR_WARN)

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

func _register_result(success: bool, error_type: String, penalty: float, delta_sum: int, wrong_rows: Array) -> void:
	var run_id: String = classic_level_id if mode == Mode.CLASSIC else level_id
	var hash_key: String = str(hash("%s|%d|%s" % [run_id, stage_index, base]))
	var mode_key: String = "MATRIX_CLASSIC" if mode == Mode.CLASSIC else "MATRIX_STAGES"
	var payload_variant: Variant = TrialV2.build("MATRIX_DECRYPTOR", "C", mode_key, "GRID_CHECK", hash_key)
	if typeof(payload_variant) != TYPE_DICTIONARY:
		return
	var payload: Dictionary = payload_variant
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
	payload["stage_base"] = base
	payload["wrong_rows"] = wrong_rows.size()
	payload["delta_sum"] = delta_sum
	GlobalMetrics.register_trial(payload)

func _log(msg: String, color: Color) -> void:
	var line := "[%s] %s" % [Time.get_time_string_from_system(), msg]
	_logs.append(line)
	if _logs.size() > 220:
		_logs.remove_at(0)
	details_text.text = "\n".join(_logs)
	var tail = _logs.slice(maxi(0, _logs.size() - 18), _logs.size())
	live_log_text.text = "\n".join(tail)
	live_log_text.add_theme_color_override("default_color", color)

func _show_toast(msg: String, color: Color) -> void:
	toast_label.text = msg
	toast_label.add_theme_color_override("font_color", color)
	toast_panel.visible = true
	toast_panel.modulate = Color(1, 1, 1, 0)
	var tw: Tween = create_tween()
	tw.tween_property(toast_panel, "modulate", Color(1, 1, 1, 1), 0.15)
	tw.tween_interval(0.9)
	tw.tween_property(toast_panel, "modulate", Color(1, 1, 1, 0), 0.25)
	tw.tween_callback(func() -> void: toast_panel.visible = false)

func _on_details_pressed() -> void:
	_set_details_open(not _details_open, false)

func _set_details_open(open: bool, immediate: bool) -> void:
	_details_open = open
	if open:
		details_sheet.visible = true
	var t_top: float = -DETAILS_SHEET_H if open else 0.0
	var t_bottom: float = 0.0 if open else DETAILS_SHEET_H
	if immediate:
		details_sheet.offset_top = t_top
		details_sheet.offset_bottom = t_bottom
		if not open:
			details_sheet.visible = false
		return
	var tw: Tween = create_tween()
	tw.tween_property(details_sheet, "offset_top", t_top, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(details_sheet, "offset_bottom", t_bottom, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if not open:
		tw.tween_callback(func() -> void: details_sheet.visible = false)

func _overlay_glitch(strength: float, duration: float) -> void:
	if noir_overlay != null and noir_overlay.has_method("glitch_burst"):
		noir_overlay.call("glitch_burst", strength, duration)

func _mode_name() -> String:
	return "CLASSIC" if mode == Mode.CLASSIC else "STAGES"

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")
