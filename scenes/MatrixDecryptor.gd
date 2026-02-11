extends Control

const MATRIX_SIZE := GlobalMetrics.MATRIX_SIZE
const STATE_UNSET := -1
const STATE_ZERO := 0
const STATE_ONE := 1

const COLOR_NORMAL = Color("33ff33")
const COLOR_WARN = Color("ffcc00")
const COLOR_ERROR = Color("ff3333")
const COLOR_DIM = Color(0.7, 0.7, 0.7)

@onready var btn_menu = $MainLayout/TopBar/MenuButton
@onready var progress_stability = $MainLayout/TopBar/StabilityBar
@onready var row_labels = $MainLayout/Content/RowLabels
@onready var col_labels = $MainLayout/Content/MatrixArea/ColumnLabels
@onready var grid = $MainLayout/Content/MatrixArea/Grid
@onready var btn_check = $MainLayout/Actions/CheckButton
@onready var log_text = $MainLayout/FeedbackPanel/LogText

var _cell_buttons: Array = []
var _row_label_nodes: Array = []
var _col_label_nodes: Array = []
var _mono_font: Font
var _input_locked: bool = false
var _safe_mode_active: bool = false
var _last_row_ok: Array = []
var _last_col_ok: Array = []
var _flow_order: Array = []
var _current_frontier: int = -1

func _ready():
	GlobalMetrics.stability_changed.connect(_on_stability_changed)
	GlobalMetrics.shield_triggered.connect(_on_shield_triggered)

	btn_menu.pressed.connect(_on_menu_pressed)
	btn_check.pressed.connect(_on_check_pressed)

	_setup_fonts()
	_build_row_labels()
	_build_col_labels()
	_build_grid()
	_build_flow_order()

	GlobalMetrics.start_matrix_quest()
	_current_frontier = _calculate_frontier()
	_apply_constraints_to_labels()
	_refresh_grid_from_state()
	_update_status_highlights()
	log_message("Matrix initialized.", COLOR_NORMAL)

func _setup_fonts():
	var font = load("res://fonts/IBMPlexMono-Medium.ttf")
	if font:
		_mono_font = font
	else:
		var fallback = SystemFont.new()
		fallback.font_names = PackedStringArray(["Courier New", "Consolas", "Liberation Mono"])
		_mono_font = fallback

func _build_row_labels():
	_row_label_nodes.clear()
	for child in row_labels.get_children():
		child.queue_free()
	for _i in range(MATRIX_SIZE):
		var lbl = Label.new()
		lbl.custom_minimum_size = Vector2(84, 48)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_color_override("font_color", COLOR_DIM)
		lbl.add_theme_font_override("font", _mono_font)
		lbl.add_theme_font_size_override("font_size", 20)
		row_labels.add_child(lbl)
		_row_label_nodes.append(lbl)

func _build_col_labels():
	_col_label_nodes.clear()
	for child in col_labels.get_children():
		child.queue_free()
	for _i in range(MATRIX_SIZE):
		var lbl = Label.new()
		lbl.custom_minimum_size = Vector2(56, 48)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_color_override("font_color", COLOR_DIM)
		lbl.add_theme_font_override("font", _mono_font)
		lbl.add_theme_font_size_override("font_size", 18)
		col_labels.add_child(lbl)
		_col_label_nodes.append(lbl)

func _build_grid():
	_cell_buttons.clear()
	for child in grid.get_children():
		child.queue_free()
	grid.columns = MATRIX_SIZE
	for r in range(MATRIX_SIZE):
		var row_buttons: Array = []
		for c in range(MATRIX_SIZE):
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(72, 72)
			btn.text = "."
			btn.focus_mode = Control.FOCUS_NONE
			btn.add_theme_font_override("font", _mono_font)
			btn.add_theme_font_size_override("font_size", 22)
			btn.pressed.connect(_on_cell_pressed.bind(r, c))
			grid.add_child(btn)
			row_buttons.append(btn)
		_cell_buttons.append(row_buttons)

func _apply_constraints_to_labels():
	for r in range(MATRIX_SIZE):
		var constraint = GlobalMetrics.matrix_row_constraints[r]
		if constraint.is_hex_visible and _current_frontier >= r:
			_row_label_nodes[r].text = "%02X" % constraint.hex_value
		else:
			_row_label_nodes[r].text = "??"

	for c in range(MATRIX_SIZE):
		var constraint = GlobalMetrics.matrix_col_constraints[c]
		var parity = "0" if constraint.parity == 0 else "1"
		if _current_frontier >= c:
			_col_label_nodes[c].text = "%d%s" % [constraint.ones_count, parity]
		else:
			_col_label_nodes[c].text = "?%s" % parity

func _refresh_grid_from_state():
	for r in range(MATRIX_SIZE):
		for c in range(MATRIX_SIZE):
			_update_cell_visual(r, c)

func _update_cell_visual(row: int, col: int):
	var state = GlobalMetrics.matrix_current[row][col]
	var btn = _cell_buttons[row][col]
	btn.self_modulate = Color(1, 1, 1) 
	match state:
		STATE_UNSET:
			btn.text = "."
			btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		STATE_ZERO:
			btn.text = "0"
			btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		STATE_ONE:
			btn.text = "1"
			btn.add_theme_color_override("font_color", Color(1, 1, 1))
	if row == 0 and col == 0:
		btn.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
	elif row == MATRIX_SIZE - 1 and col == MATRIX_SIZE - 1:
		btn.add_theme_color_override("font_color", Color(1.0, 0.82, 0.5))

func _on_cell_pressed(row: int, col: int):
	if _input_locked:
		return
	if row + col > _current_frontier + 1:
		return
	AudioManager.play("click")
	var current = GlobalMetrics.matrix_current[row][col]
	var next_state = STATE_ZERO if current == STATE_UNSET else (STATE_ONE if current == STATE_ZERO else STATE_UNSET)
	GlobalMetrics.matrix_current[row][col] = next_state
	GlobalMetrics.record_matrix_change(row, col)
	_update_cell_visual(row, col)
	_update_status_highlights()

func _update_status_highlights():
	var result = GlobalMetrics.validate_matrix_logic()
	var row_ok = result.row_ok
	var col_ok = result.col_ok
	var play_ok_sound = false
	_current_frontier = _calculate_frontier()
	_update_frontier_lock()
	_apply_constraints_to_labels()

	for r in range(MATRIX_SIZE):
		var constraint = GlobalMetrics.matrix_row_constraints[r]
		if constraint.is_hex_visible and _current_frontier >= r and row_ok[r]:
			_row_label_nodes[r].add_theme_color_override("font_color", COLOR_NORMAL)
			if _last_row_ok.size() == MATRIX_SIZE and not _last_row_ok[r]:
				play_ok_sound = true
		else:
			_row_label_nodes[r].add_theme_color_override("font_color", COLOR_DIM)

	for c in range(MATRIX_SIZE):
		if _current_frontier >= c and col_ok[c]:
			_col_label_nodes[c].add_theme_color_override("font_color", COLOR_NORMAL)
			if _last_col_ok.size() == MATRIX_SIZE and not _last_col_ok[c]:
				play_ok_sound = true
		else:
			_col_label_nodes[c].add_theme_color_override("font_color", COLOR_DIM)

	_last_row_ok = row_ok.duplicate()
	_last_col_ok = col_ok.duplicate()
	if play_ok_sound:
		AudioManager.play("click")

func _on_check_pressed():
	if _input_locked:
		return
	var result = GlobalMetrics.check_matrix_solution()
	if result.success:
		log_message("ACCESS GRANTED.", COLOR_NORMAL)
		await get_tree().create_timer(1.0).timeout
		GlobalMetrics.start_matrix_quest()
		_apply_constraints_to_labels()
		_refresh_grid_from_state()
		_update_status_highlights()
		log_message("New matrix loaded.", COLOR_NORMAL)
	else:
		if result.has("error"):
			if result.error == "SHIELD_FREQ" or result.error == "SHIELD_ACTIVE" or result.error == "SHIELD_LAZY":
				log_message(result.message, COLOR_WARN)
			else:
				log_message(result.message, COLOR_ERROR)

func _on_shield_triggered(name, duration):
	AudioManager.play("error")
	log_message("SHIELD: %s. WAIT %s s." % [name, duration], COLOR_WARN)
	_set_input_enabled(false)
	await get_tree().create_timer(duration).timeout
	if not _safe_mode_active:
		_set_input_enabled(true)
		log_message("SHIELD OFF.", COLOR_NORMAL)

func _on_stability_changed(new_val, _change):
	progress_stability.value = new_val
	if new_val <= 0 and not _safe_mode_active:
		_safe_mode_active = true
		_set_input_enabled(false)
		await _start_safe_mode_analysis()

func _start_safe_mode_analysis():
	log_message("SAFE MODE: analysis started.", COLOR_WARN)
	var conflict = _find_flow_break_cell()
	if conflict.size() == 2:
		var row = conflict[0]
		var col = conflict[1]
		_highlight_conflict(row, col)
		log_message("CRITICAL FAILURE: Stream broken at [R%d, C%d]. Check HEX/Count integrity." % [row + 1, col + 1], COLOR_ERROR)
	else:
		log_message("ANALYSIS: Conflict not found.", COLOR_WARN)

	await get_tree().create_timer(10.0).timeout
	_clear_conflict_highlight()
	_safe_mode_active = false
	_set_input_enabled(true)
	log_message("SAFE MODE: input restored.", COLOR_NORMAL)

func _find_flow_break_cell() -> Array:
	var stats = _compute_matrix_stats()
	var row_values: Array = stats.row_values
	var row_has_unset: Array = stats.row_has_unset
	var col_counts: Array = stats.col_counts
	var col_has_unset: Array = stats.col_has_unset

	_current_frontier = _calculate_frontier()
	for entry in _flow_order:
		var r = entry[0]
		var c = entry[1]
		var cell = GlobalMetrics.matrix_current[r][c]
		if r + c <= _current_frontier and cell == STATE_UNSET:
			return [r, c]
		if cell == STATE_ONE:
			var row_constraint = GlobalMetrics.matrix_row_constraints[r]
			var col_constraint = GlobalMetrics.matrix_col_constraints[c]
			if row_values[r] > row_constraint.hex_value or col_counts[c] > col_constraint.ones_count:
				return [r, c]

	for r in range(MATRIX_SIZE):
		for c in range(MATRIX_SIZE):
			if GlobalMetrics.matrix_current[r][c] != STATE_ONE:
				continue
			var row_constraint = GlobalMetrics.matrix_row_constraints[r]
			var col_constraint = GlobalMetrics.matrix_col_constraints[c]
			var row_bad = row_has_unset[r] or row_values[r] != row_constraint.hex_value
			var col_bad = col_has_unset[c] or col_counts[c] != col_constraint.ones_count
			if row_bad and col_bad:
				return [r, c]
	return []

func _compute_matrix_stats() -> Dictionary:
	var row_values: Array = []
	var row_has_unset: Array = []
	for r in range(MATRIX_SIZE):
		var value = 0
		var has_unset = false
		for c in range(MATRIX_SIZE):
			var cell = GlobalMetrics.matrix_current[r][c]
			if cell == -1:
				has_unset = true
			elif cell == 1:
				value += GlobalMetrics.MATRIX_WEIGHTS[c]
		row_values.append(value)
		row_has_unset.append(has_unset)

	var col_counts: Array = []
	var col_has_unset: Array = []
	for c in range(MATRIX_SIZE):
		var ones = 0
		var has_unset = false
		for r in range(MATRIX_SIZE):
			var cell = GlobalMetrics.matrix_current[r][c]
			if cell == -1:
				has_unset = true
			elif cell == 1:
				ones += 1
		col_counts.append(ones)
		col_has_unset.append(has_unset)

	return {
		"row_values": row_values,
		"row_has_unset": row_has_unset,
		"col_counts": col_counts,
		"col_has_unset": col_has_unset
	}

func _highlight_conflict(row: int, col: int):
	for r in range(MATRIX_SIZE):
		for c in range(MATRIX_SIZE):
			var btn = _cell_buttons[r][c]
			if r == row or c == col:
				btn.self_modulate = Color(1, 0.4, 0.4)
			else:
				btn.self_modulate = Color(1, 1, 1)
	_row_label_nodes[row].add_theme_color_override("font_color", COLOR_ERROR)
	_col_label_nodes[col].add_theme_color_override("font_color", COLOR_ERROR)
	_flash_cell(row, col)

func _clear_conflict_highlight():
	for r in range(MATRIX_SIZE):
		for c in range(MATRIX_SIZE):
			_cell_buttons[r][c].self_modulate = Color(1, 1, 1)
	_update_status_highlights()

func _set_input_enabled(enabled: bool):
	_input_locked = not enabled
	btn_check.disabled = not enabled
	for r in range(MATRIX_SIZE):
		for c in range(MATRIX_SIZE):
			_cell_buttons[r][c].disabled = not enabled

func log_message(msg: String, color: Color):
	var time_str = Time.get_time_string_from_system()
	log_text.push_color(color)
	log_text.add_text("[%s] %s\n" % [time_str, msg])
	log_text.pop()

func _on_menu_pressed():
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _build_flow_order() -> void:
	_flow_order.clear()
	for d in range(2 * MATRIX_SIZE - 1):
		for r in range(MATRIX_SIZE):
			var c = d - r
			if c >= 0 and c < MATRIX_SIZE:
				_flow_order.append([r, c])

func _calculate_frontier() -> int:
	var frontier = -1
	for d in range(2 * MATRIX_SIZE - 1):
		var all_set = true
		for r in range(MATRIX_SIZE):
			var c = d - r
			if c < 0 or c >= MATRIX_SIZE:
				continue
			if GlobalMetrics.matrix_current[r][c] == STATE_UNSET:
				all_set = false
				break
		if not all_set:
			break
		frontier = d
	return frontier

func _update_frontier_lock() -> void:
	for r in range(MATRIX_SIZE):
		for c in range(MATRIX_SIZE):
			var btn = _cell_buttons[r][c]
			var locked = (r + c) > _current_frontier + 1
			btn.disabled = _input_locked or locked
			if locked:
				btn.self_modulate = Color(0.6, 0.6, 0.6)
			else:
				btn.self_modulate = Color(1, 1, 1)

func _flash_cell(row: int, col: int) -> void:
	var btn = _cell_buttons[row][col]
	btn.self_modulate = Color(1, 0.3, 0.3)
	var tween = create_tween()
	tween.tween_property(btn, "self_modulate", Color(1, 1, 1), 0.25)
	tween.tween_property(btn, "self_modulate", Color(1, 0.3, 0.3), 0.25)
	tween.tween_property(btn, "self_modulate", Color(1, 1, 1), 0.25)
