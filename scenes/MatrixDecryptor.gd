extends Control

const MATRIX_SIZE := 5
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
var _task_started_ms: int = 0
var _first_action_ms: int = -1
var _check_count: int = 0

func _ready():
	GlobalMetrics.stability_changed.connect(_on_stability_changed)
	GlobalMetrics.shield_triggered.connect(_on_shield_triggered)

	btn_menu.pressed.connect(_on_menu_pressed)
	btn_check.pressed.connect(_on_check_pressed)

	_setup_fonts()
	_build_row_labels()
	_build_col_labels()
	_build_grid()

	GlobalMetrics.start_matrix_quest()
	_reset_trial_telemetry()
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
	for _i in range(MATRIX_SIZE):
		var lbl = Label.new()
		lbl.custom_minimum_size = Vector2(70, 44)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_color_override("font_color", COLOR_DIM)
		lbl.add_theme_font_override("font", _mono_font)
		lbl.add_theme_font_size_override("font_size", 20)
		row_labels.add_child(lbl)
		_row_label_nodes.append(lbl)

func _build_col_labels():
	_col_label_nodes.clear()
	for _i in range(MATRIX_SIZE):
		var lbl = Label.new()
		lbl.custom_minimum_size = Vector2(48, 44)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_color_override("font_color", COLOR_DIM)
		lbl.add_theme_font_override("font", _mono_font)
		lbl.add_theme_font_size_override("font_size", 18)
		col_labels.add_child(lbl)
		_col_label_nodes.append(lbl)

func _build_grid():
	_cell_buttons.clear()
	for r in range(MATRIX_SIZE):
		var row_buttons: Array = []
		for c in range(MATRIX_SIZE):
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(48, 48)
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
		if constraint.is_hex_visible:
			_row_label_nodes[r].text = "%02X" % constraint.hex_value
		else:
			_row_label_nodes[r].text = "?"

	for c in range(MATRIX_SIZE):
		var constraint = GlobalMetrics.matrix_col_constraints[c]
		var parity = "E" if constraint.parity == 0 else "O"
		_col_label_nodes[c].text = "%d%s" % [constraint.ones_count, parity]

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

func _on_cell_pressed(row: int, col: int):
	if _input_locked:
		return
	if _first_action_ms < 0:
		_first_action_ms = Time.get_ticks_msec() - _task_started_ms
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

	for r in range(MATRIX_SIZE):
		var constraint = GlobalMetrics.matrix_row_constraints[r]
		if constraint.is_hex_visible and row_ok[r]:
			_row_label_nodes[r].add_theme_color_override("font_color", COLOR_NORMAL)
			if _last_row_ok.size() == MATRIX_SIZE and not _last_row_ok[r]:
				play_ok_sound = true
		else:
			_row_label_nodes[r].add_theme_color_override("font_color", COLOR_DIM)

	for c in range(MATRIX_SIZE):
		if col_ok[c]:
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
	_check_count += 1
	var changed_cells_count := GlobalMetrics.matrix_changed_cells.size()
	var result = GlobalMetrics.check_matrix_solution()
	_register_trial(result, changed_cells_count)
	if result.success:
		log_message("ACCESS GRANTED.", COLOR_NORMAL)
		await get_tree().create_timer(1.0).timeout
		GlobalMetrics.start_matrix_quest()
		_reset_trial_telemetry()
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
	var conflict = _find_conflict_cell()
	if conflict.size() == 2:
		var row = conflict[0]
		var col = conflict[1]
		_highlight_conflict(row, col)
		log_message("ANALYSIS: Conflict at [%d, %d]. Value 1 invalid: column limit exceeded." % [row + 1, col + 1], COLOR_ERROR)
	else:
		log_message("ANALYSIS: Conflict not found.", COLOR_WARN)

	await get_tree().create_timer(10.0).timeout
	_clear_conflict_highlight()
	_safe_mode_active = false
	_set_input_enabled(true)
	log_message("SAFE MODE: input restored.", COLOR_NORMAL)

func _find_conflict_cell() -> Array:
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

	for r in range(MATRIX_SIZE):
		for c in range(MATRIX_SIZE):
			if GlobalMetrics.matrix_current[r][c] != 1:
				continue
			var row_constraint = GlobalMetrics.matrix_row_constraints[r]
			var col_constraint = GlobalMetrics.matrix_col_constraints[c]
			var row_over = row_values[r] > row_constraint.hex_value
			var col_over = col_counts[c] > col_constraint.ones_count
			if row_over and col_over:
				return [r, c]

	for r in range(MATRIX_SIZE):
		for c in range(MATRIX_SIZE):
			if GlobalMetrics.matrix_current[r][c] != 1:
				continue
			var row_constraint = GlobalMetrics.matrix_row_constraints[r]
			var col_constraint = GlobalMetrics.matrix_col_constraints[c]
			var row_bad = row_has_unset[r] or row_values[r] != row_constraint.hex_value
			var col_bad = col_has_unset[c] or col_counts[c] != col_constraint.ones_count
			if row_bad and col_bad:
				return [r, c]

	for r in range(MATRIX_SIZE):
		for c in range(MATRIX_SIZE):
			if GlobalMetrics.matrix_current[r][c] == 1:
				var col_constraint = GlobalMetrics.matrix_col_constraints[c]
				if col_counts[c] > col_constraint.ones_count:
					return [r, c]

	return []

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

func _reset_trial_telemetry() -> void:
	_task_started_ms = Time.get_ticks_msec()
	_first_action_ms = -1
	_check_count = 0

func _register_trial(result: Dictionary, changed_cells_count: int) -> void:
	var variant_hash := str(hash(JSON.stringify(GlobalMetrics.matrix_quest)))
	var payload := TrialV2.build("MATRIX_DECRYPTOR", "C", "MATRIX_01", "GRID_CHECK", variant_hash)
	var elapsed_ms := max(0, Time.get_ticks_msec() - _task_started_ms)
	var is_success := bool(result.get("success", false))
	payload["elapsed_ms"] = elapsed_ms
	payload["duration"] = float(elapsed_ms) / 1000.0
	payload["time_to_first_action_ms"] = _first_action_ms if _first_action_ms >= 0 else elapsed_ms
	payload["is_correct"] = is_success
	payload["is_fit"] = is_success
	payload["stability_delta"] = 0
	payload["error_type"] = str(result.get("error", "NONE"))
	payload["penalty_reported"] = float(result.get("penalty", 0.0))
	payload["hamming"] = int(result.get("hamming", -1))
	payload["changed_cells_count"] = changed_cells_count
	payload["check_count"] = _check_count
	GlobalMetrics.register_trial(payload)

func log_message(msg: String, color: Color):
	var time_str = Time.get_time_string_from_system()
	log_text.push_color(color)
	log_text.add_text("[%s] %s\n" % [time_str, msg])
	log_text.pop()

func _on_menu_pressed():
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")
