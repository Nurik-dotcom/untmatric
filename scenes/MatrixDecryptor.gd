extends Control

const STATE_UNSET := -1
const STATE_ZERO := 0
const STATE_ONE := 1

const COLOR_NORMAL = Color("33ff66")
const COLOR_WARN = Color("ffcc00")
const COLOR_ERROR = Color("ff5555")
const COLOR_DIM = Color(0.65, 0.65, 0.65)
const MIN_CELL_SIZE := 64

@onready var btn_back: Button = $UI/SafeArea/Main/HeaderBar/HeaderContent/BtnBack
@onready var btn_details: Button = $UI/SafeArea/Main/HeaderBar/HeaderContent/BtnDetails
@onready var btn_close_details: Button = $UI/DetailsSheet/DetailsContent/DetailsHeader/BtnCloseDetails
@onready var level_label: Label = $UI/SafeArea/Main/HeaderBar/HeaderContent/LevelLabel
@onready var stability_text: Label = $UI/SafeArea/Main/HeaderBar/HeaderContent/StabilityGroup/StabilityText
@onready var progress_stability: ProgressBar = $UI/SafeArea/Main/HeaderBar/HeaderContent/StabilityGroup/StabilityBar
@onready var shield_freq: Label = $UI/SafeArea/Main/HeaderBar/HeaderContent/Shields/ShieldFreq
@onready var shield_lazy: Label = $UI/SafeArea/Main/HeaderBar/HeaderContent/Shields/ShieldLazy

@onready var row_labels: VBoxContainer = $UI/SafeArea/Main/ContentSplit/LeftPanel/MatrixPanel/MatrixContent/MatrixBoard/RowLabels
@onready var col_labels: HBoxContainer = $UI/SafeArea/Main/ContentSplit/LeftPanel/MatrixPanel/MatrixContent/MatrixBoard/MatrixStack/ColumnLabels
@onready var grid: GridContainer = $UI/SafeArea/Main/ContentSplit/LeftPanel/MatrixPanel/MatrixContent/MatrixBoard/MatrixStack/Grid
@onready var inlet_tag: Label = $UI/SafeArea/Main/ContentSplit/LeftPanel/MatrixPanel/MatrixContent/InOutRow/InletTag
@onready var outlet_tag: Label = $UI/SafeArea/Main/ContentSplit/LeftPanel/MatrixPanel/MatrixContent/InOutRow/OutletTag

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

var _cell_buttons: Array = []
var _row_label_nodes: Array = []
var _col_label_nodes: Array = []
var _mono_font: Font

var _input_locked: bool = false
var _safe_mode_active: bool = false
var _details_open: bool = false

var _last_row_ok: Array = []
var _last_col_ok: Array = []
var _unlock_depth: int = 1

var _task_started_ms: int = 0
var _first_action_ms: int = -1
var _check_count: int = 0

var _log_lines: Array[String] = []

func _ready() -> void:
	if not GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.connect(_on_stability_changed)
	if not GlobalMetrics.shield_triggered.is_connected(_on_shield_triggered):
		GlobalMetrics.shield_triggered.connect(_on_shield_triggered)

	btn_back.pressed.connect(_on_menu_pressed)
	btn_details.pressed.connect(_on_details_pressed)
	btn_close_details.pressed.connect(_on_details_pressed)
	btn_hint.pressed.connect(_on_hint_pressed)
	btn_check.pressed.connect(_on_check_pressed)
	btn_reset.pressed.connect(_on_reset_pressed)

	_setup_fonts()
	_build_row_labels()
	_build_col_labels()
	_build_grid()
	_reset_shield_state()
	_hide_overlays()

	await get_tree().process_frame
	_set_details_open(false, true)

	_start_new_matrix()

func _matrix_size() -> int:
	return GlobalMetrics.MATRIX_SIZE

func _setup_fonts() -> void:
	var font = load("res://fonts/IBMPlexMono-Medium.ttf")
	if font:
		_mono_font = font
	else:
		var fallback := SystemFont.new()
		fallback.font_names = PackedStringArray(["Courier New", "Consolas", "Liberation Mono"])
		_mono_font = fallback

func _build_row_labels() -> void:
	_row_label_nodes.clear()
	for child in row_labels.get_children():
		child.queue_free()

	for _i in range(_matrix_size()):
		var lbl := Label.new()
		lbl.custom_minimum_size = Vector2(92, MIN_CELL_SIZE)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_color_override("font_color", COLOR_DIM)
		lbl.add_theme_font_override("font", _mono_font)
		lbl.add_theme_font_size_override("font_size", 20)
		row_labels.add_child(lbl)
		_row_label_nodes.append(lbl)

func _build_col_labels() -> void:
	_col_label_nodes.clear()
	for child in col_labels.get_children():
		child.queue_free()

	for _i in range(_matrix_size()):
		var lbl := Label.new()
		lbl.custom_minimum_size = Vector2(MIN_CELL_SIZE, 48)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_color_override("font_color", COLOR_DIM)
		lbl.add_theme_font_override("font", _mono_font)
		lbl.add_theme_font_size_override("font_size", 18)
		col_labels.add_child(lbl)
		_col_label_nodes.append(lbl)

func _build_grid() -> void:
	_cell_buttons.clear()
	for child in grid.get_children():
		child.queue_free()

	grid.columns = _matrix_size()
	for r in range(_matrix_size()):
		var row_buttons: Array = []
		for c in range(_matrix_size()):
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(MIN_CELL_SIZE, MIN_CELL_SIZE)
			btn.text = "."
			btn.focus_mode = Control.FOCUS_NONE
			btn.add_theme_font_override("font", _mono_font)
			btn.add_theme_font_size_override("font_size", 24)
			btn.pressed.connect(_on_cell_pressed.bind(r, c))
			grid.add_child(btn)
			row_buttons.append(btn)
		_cell_buttons.append(row_buttons)

func _start_new_matrix() -> void:
	GlobalMetrics.start_matrix_quest()
	_reset_trial_telemetry()
	_safe_mode_active = false
	_unlock_depth = 1
	_last_row_ok.clear()
	_last_col_ok.clear()
	_set_input_enabled(true)
	_refresh_header_labels()
	_apply_constraints_to_labels()
	_refresh_grid_from_state()
	_update_status_highlights()
	hint_text.text = "Диагностики пока нет."
	_log_message("Матрица инициализирована. Ограничения потока загружены.", COLOR_NORMAL)

func _refresh_header_labels() -> void:
	var edge = _matrix_size() - 1
	level_label.text = "ПРОТОКОЛ C | %dx%d" % [_matrix_size(), _matrix_size()]
	inlet_tag.text = "ВХОД [0,0]"
	outlet_tag.text = "ВЫХОД [%d,%d]" % [edge, edge]
	inlet_tag.add_theme_color_override("font_color", Color(0.6, 1.0, 0.7, 1.0))
	outlet_tag.add_theme_color_override("font_color", Color(0.6, 0.95, 1.0, 1.0))

func _apply_constraints_to_labels() -> void:
	for r in range(_matrix_size()):
		var constraint: Dictionary = GlobalMetrics.matrix_row_constraints[r]
		if bool(constraint.get("is_hex_visible", false)):
			_row_label_nodes[r].text = "%02X" % int(constraint.get("hex_value", 0))
		else:
			_row_label_nodes[r].text = "?"

	for c in range(_matrix_size()):
		var constraint: Dictionary = GlobalMetrics.matrix_col_constraints[c]
		var parity := "E" if int(constraint.get("parity", 0)) == 0 else "O"
		_col_label_nodes[c].text = "%d%s" % [int(constraint.get("ones_count", 0)), parity]

func _refresh_grid_from_state() -> void:
	for r in range(_matrix_size()):
		for c in range(_matrix_size()):
			_update_cell_visual(r, c)

func _is_cell_unlocked(row: int, col: int) -> bool:
	return row <= _unlock_depth and col <= _unlock_depth

func _update_cell_visual(row: int, col: int) -> void:
	var state = int(GlobalMetrics.matrix_current[row][col])
	var btn: Button = _cell_buttons[row][col]
	var unlocked = _is_cell_unlocked(row, col)
	btn.disabled = _input_locked or not unlocked

	if not unlocked:
		btn.text = "·" if state == STATE_UNSET else str(state)
		btn.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45, 1.0))
		btn.self_modulate = Color(0.65, 0.65, 0.65, 1.0)
		return

	match state:
		STATE_UNSET:
			btn.text = "."
			btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1.0))
		STATE_ZERO:
			btn.text = "0"
			btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
		STATE_ONE:
			btn.text = "1"
			btn.add_theme_color_override("font_color", Color(1, 1, 1, 1.0))

	var edge = _matrix_size() - 1
	if row == 0 and col == 0:
		btn.self_modulate = Color(0.78, 1.0, 0.82, 1.0)
	elif row == edge and col == edge:
		btn.self_modulate = Color(0.78, 0.94, 1.0, 1.0)
	else:
		btn.self_modulate = Color(1, 1, 1, 1)

func _on_cell_pressed(row: int, col: int) -> void:
	if _input_locked or not _is_cell_unlocked(row, col):
		return
	if _first_action_ms < 0:
		_first_action_ms = Time.get_ticks_msec() - _task_started_ms
	AudioManager.play("click")
	var current = int(GlobalMetrics.matrix_current[row][col])
	var next_state = STATE_ZERO if current == STATE_UNSET else (STATE_ONE if current == STATE_ZERO else STATE_UNSET)
	GlobalMetrics.matrix_current[row][col] = next_state
	GlobalMetrics.record_matrix_change(row, col)
	_update_cell_visual(row, col)
	_update_status_highlights()

func _update_status_highlights() -> void:
	var result: Dictionary = GlobalMetrics.validate_matrix_logic()
	var row_ok: Array = result.get("row_ok", [])
	var col_ok: Array = result.get("col_ok", [])
	var play_ok_sound := false

	var visible_rows := 0
	var solved_visible_rows := 0
	for r in range(_matrix_size()):
		var constraint: Dictionary = GlobalMetrics.matrix_row_constraints[r]
		var visible = bool(constraint.get("is_hex_visible", false))
		if visible:
			visible_rows += 1
		if visible and bool(row_ok[r]):
			solved_visible_rows += 1
			_row_label_nodes[r].add_theme_color_override("font_color", COLOR_NORMAL)
			if _last_row_ok.size() == _matrix_size() and not bool(_last_row_ok[r]):
				play_ok_sound = true
		else:
			_row_label_nodes[r].add_theme_color_override("font_color", COLOR_DIM)

	var solved_cols := 0
	for c in range(_matrix_size()):
		if bool(col_ok[c]):
			solved_cols += 1
			_col_label_nodes[c].add_theme_color_override("font_color", COLOR_NORMAL)
			if _last_col_ok.size() == _matrix_size() and not bool(_last_col_ok[c]):
				play_ok_sound = true
		else:
			_col_label_nodes[c].add_theme_color_override("font_color", COLOR_DIM)

	_last_row_ok = row_ok.duplicate()
	_last_col_ok = col_ok.duplicate()
	if play_ok_sound:
		AudioManager.play("click")

	var frontier_side = _unlock_depth + 1
	var frontier_total = frontier_side * frontier_side
	var frontier_filled = 0
	for r in range(frontier_side):
		for c in range(frontier_side):
			if int(GlobalMetrics.matrix_current[r][c]) != STATE_UNSET:
				frontier_filled += 1

	if frontier_filled >= frontier_total and _unlock_depth < _matrix_size() - 1:
		_unlock_depth += 1
		_refresh_grid_from_state()
		_log_message("Поток открыт до зоны %dx%d." % [_unlock_depth + 1, _unlock_depth + 1], COLOR_NORMAL)
		frontier_side = _unlock_depth + 1
		frontier_total = frontier_side * frontier_side
		frontier_filled = 0
		for r in range(frontier_side):
			for c in range(frontier_side):
				if int(GlobalMetrics.matrix_current[r][c]) != STATE_UNSET:
					frontier_filled += 1

	progress_label.text = "Открытая зона: %dx%d | Фронт: %d/%d | Строки: %d/%d | Столбцы: %d/%d" % [
		_unlock_depth + 1,
		_unlock_depth + 1,
		frontier_filled,
		frontier_total,
		solved_visible_rows,
		maxi(1, visible_rows),
		solved_cols,
		_matrix_size()
	]
	mode_state_label.text = "Безопасный режим: %s" % ("ВКЛ" if _safe_mode_active else "ВЫКЛ")

func _on_hint_pressed() -> void:
	if _input_locked:
		hint_text.text = "Ввод заблокирован щитом или безопасным режимом."
		_show_toast("ВВОД ЗАБЛОКИРОВАН", COLOR_WARN)
		return
	var logic: Dictionary = GlobalMetrics.validate_matrix_logic()
	var hd_val = int(logic.get("hd", 0))
	hint_text.text = "HD: %d | Сосредоточьтесь на видимых HEX-строках и совпадении чётности столбцов." % hd_val
	_log_message("Запрошена подсказка. HD=%d" % hd_val, COLOR_WARN)
	_show_toast("ПОДСКАЗКА ПОКАЗАНА", COLOR_WARN)

func _on_check_pressed() -> void:
	if _input_locked:
		return
	_check_count += 1
	var changed_cells_count: int = GlobalMetrics.matrix_changed_cells.size()
	var result: Dictionary = GlobalMetrics.check_matrix_solution()
	_register_trial(result, changed_cells_count)

	if bool(result.get("success", false)):
		AudioManager.play("relay")
		_overlay_glitch(0.15, 0.12)
		_show_toast("ДОСТУП РАЗРЕШЁН", COLOR_NORMAL)
		_log_message("ДОСТУП РАЗРЕШЁН. Матрица решена.", COLOR_NORMAL)
		await get_tree().create_timer(1.0).timeout
		_start_new_matrix()
		return

	AudioManager.play("error")
	_overlay_glitch(0.6, 0.2)
	var message := str(result.get("message", "Неверно"))
	hint_text.text = message
	if str(result.get("error", "")) in ["SHIELD_FREQ", "SHIELD_ACTIVE", "SHIELD_LAZY"]:
		_log_message(message, COLOR_WARN)
	else:
		_log_message(message, COLOR_ERROR)
	_show_toast("НЕВЕРНО", COLOR_ERROR)

func _on_reset_pressed() -> void:
	for r in range(_matrix_size()):
		for c in range(_matrix_size()):
			GlobalMetrics.matrix_current[r][c] = STATE_UNSET
	GlobalMetrics.matrix_changed_cells.clear()
	_unlock_depth = 1
	_reset_trial_telemetry()
	_refresh_grid_from_state()
	_update_status_highlights()
	hint_text.text = "Ввод матрицы сброшен."
	_log_message("Матрица сброшена в неопределённое состояние.", COLOR_WARN)
	_show_toast("СБРОС", COLOR_WARN)

func _on_shield_triggered(name: String, duration: float) -> void:
	AudioManager.play("error")
	_overlay_glitch(0.6, 0.2)
	if name == "FREQUENCY":
		_flash_shield(shield_freq)
	elif name == "LAZY":
		_flash_shield(shield_lazy)
	_log_message("ЩИТ %s активен %.1f c." % [name, duration], COLOR_WARN)
	_set_input_enabled(false)
	await get_tree().create_timer(duration).timeout
	if not _safe_mode_active:
		_set_input_enabled(true)
		_log_message("Кулдаун щита завершён.", COLOR_NORMAL)

func _on_stability_changed(new_val: float, _change: float) -> void:
	progress_stability.value = new_val
	stability_text.text = "СТАБИЛЬНОСТЬ: %d%%" % int(new_val)
	if new_val <= 0.0 and not _safe_mode_active:
		_safe_mode_active = true
		mode_state_label.text = "Безопасный режим: ВКЛ"
		_set_input_enabled(false)
		await _start_safe_mode_analysis()

func _start_safe_mode_analysis() -> void:
	_log_message("БЕЗОПАСНЫЙ РЕЖИМ: анализ запущен.", COLOR_WARN)
	var conflict = _find_conflict_cell()
	if conflict.size() == 2:
		var row = int(conflict[0])
		var col = int(conflict[1])
		_highlight_conflict(row, col)
		hint_text.text = "Конфликт около [%d, %d]. Проверьте HEX строки и количество/чётность столбцов." % [row + 1, col + 1]
		_log_message("Конфликт обнаружен в [%d, %d]." % [row + 1, col + 1], COLOR_ERROR)
	else:
		hint_text.text = "Конфликт не локализован. Сначала проверьте нерешённые строки/столбцы."
		_log_message("Конфликт не локализован.", COLOR_WARN)

	await get_tree().create_timer(8.0).timeout
	_clear_conflict_highlight()
	_safe_mode_active = false
	mode_state_label.text = "Безопасный режим: ВЫКЛ"
	_set_input_enabled(true)
	_log_message("БЕЗОПАСНЫЙ РЕЖИМ: ввод восстановлен.", COLOR_NORMAL)

func _find_conflict_cell() -> Array:
	var row_values: Array = []
	var row_has_unset: Array = []
	for r in range(_matrix_size()):
		var value = 0
		var has_unset = false
		for c in range(_matrix_size()):
			var cell = int(GlobalMetrics.matrix_current[r][c])
			if cell == STATE_UNSET:
				has_unset = true
			elif cell == STATE_ONE:
				value += GlobalMetrics.MATRIX_WEIGHTS[c]
		row_values.append(value)
		row_has_unset.append(has_unset)

	var col_counts: Array = []
	var col_has_unset: Array = []
	for c in range(_matrix_size()):
		var ones = 0
		var has_unset = false
		for r in range(_matrix_size()):
			var cell = int(GlobalMetrics.matrix_current[r][c])
			if cell == STATE_UNSET:
				has_unset = true
			elif cell == STATE_ONE:
				ones += 1
		col_counts.append(ones)
		col_has_unset.append(has_unset)

	for r in range(_matrix_size()):
		for c in range(_matrix_size()):
			if int(GlobalMetrics.matrix_current[r][c]) != STATE_ONE:
				continue
			var row_constraint: Dictionary = GlobalMetrics.matrix_row_constraints[r]
			var col_constraint: Dictionary = GlobalMetrics.matrix_col_constraints[c]
			var row_over = row_values[r] > int(row_constraint.get("hex_value", 0))
			var col_over = col_counts[c] > int(col_constraint.get("ones_count", 0))
			if row_over and col_over:
				return [r, c]

	for r in range(_matrix_size()):
		for c in range(_matrix_size()):
			if int(GlobalMetrics.matrix_current[r][c]) != STATE_ONE:
				continue
			var row_constraint: Dictionary = GlobalMetrics.matrix_row_constraints[r]
			var col_constraint: Dictionary = GlobalMetrics.matrix_col_constraints[c]
			var row_bad = bool(row_has_unset[r]) or row_values[r] != int(row_constraint.get("hex_value", 0))
			var col_bad = bool(col_has_unset[c]) or col_counts[c] != int(col_constraint.get("ones_count", 0))
			if row_bad and col_bad:
				return [r, c]

	for r in range(_matrix_size()):
		for c in range(_matrix_size()):
			if int(GlobalMetrics.matrix_current[r][c]) == STATE_ONE:
				var col_constraint: Dictionary = GlobalMetrics.matrix_col_constraints[c]
				if col_counts[c] > int(col_constraint.get("ones_count", 0)):
					return [r, c]

	return []

func _highlight_conflict(row: int, col: int) -> void:
	for r in range(_matrix_size()):
		for c in range(_matrix_size()):
			var btn: Button = _cell_buttons[r][c]
			if r == row or c == col:
				btn.self_modulate = Color(1.0, 0.4, 0.4, 1.0)
			else:
				btn.self_modulate = Color(0.85, 0.85, 0.85, 1.0)
	_row_label_nodes[row].add_theme_color_override("font_color", COLOR_ERROR)
	_col_label_nodes[col].add_theme_color_override("font_color", COLOR_ERROR)

func _clear_conflict_highlight() -> void:
	_refresh_grid_from_state()
	_update_status_highlights()

func _set_input_enabled(enabled: bool) -> void:
	_input_locked = not enabled
	btn_check.disabled = not enabled
	btn_hint.disabled = not enabled
	btn_reset.disabled = not enabled
	_refresh_grid_from_state()

func _reset_trial_telemetry() -> void:
	_task_started_ms = Time.get_ticks_msec()
	_first_action_ms = -1
	_check_count = 0

func _register_trial(result: Dictionary, changed_cells_count: int) -> void:
	var variant_hash := str(hash(JSON.stringify(GlobalMetrics.matrix_quest)))
	var payload := TrialV2.build("MATRIX_DECRYPTOR", "C", "MATRIX_01", "GRID_CHECK", variant_hash)
	var elapsed_ms: int = maxi(0, Time.get_ticks_msec() - _task_started_ms)
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

func _log_message(msg: String, color: Color) -> void:
	var time_str = Time.get_time_string_from_system()
	var line = "[%s] %s" % [time_str, msg]
	_log_lines.append(line)
	if _log_lines.size() > 220:
		_log_lines.remove_at(0)
	var all_text = "\n".join(_log_lines)
	details_text.text = all_text
	var tail = _log_lines.slice(maxi(0, _log_lines.size() - 18), _log_lines.size())
	live_log_text.text = "\n".join(tail)
	live_log_text.add_theme_color_override("default_color", color)

func _show_toast(msg: String, color: Color) -> void:
	toast_label.text = msg
	toast_label.add_theme_color_override("font_color", color)
	toast_panel.visible = true
	toast_panel.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(toast_panel, "modulate", Color(1, 1, 1, 1), 0.15)
	tween.tween_interval(0.9)
	tween.tween_property(toast_panel, "modulate", Color(1, 1, 1, 0), 0.25)
	tween.tween_callback(func() -> void: toast_panel.visible = false)

func _flash_shield(label: Label) -> void:
	label.modulate = Color(1, 1, 1, 1)
	var tween := create_tween()
	tween.tween_property(label, "modulate", Color(1, 1, 1, 0.25), 0.6)

func _reset_shield_state() -> void:
	shield_freq.modulate = Color(1, 1, 1, 0.25)
	shield_lazy.modulate = Color(1, 1, 1, 0.25)

func _hide_overlays() -> void:
	toast_panel.visible = false
	details_sheet.visible = false

func _on_details_pressed() -> void:
	_set_details_open(not _details_open, false)

func _set_details_open(open: bool, immediate: bool) -> void:
	_details_open = open
	if open:
		details_sheet.visible = true

	var target_offset = -details_sheet.size.y if open else 0.0
	if immediate:
		details_sheet.offset_top = target_offset
		if not open:
			details_sheet.visible = false
		return

	var tween := create_tween()
	tween.tween_property(details_sheet, "offset_top", target_offset, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if not open:
		tween.tween_callback(func() -> void: details_sheet.visible = false)

func _overlay_glitch(strength: float, duration: float) -> void:
	if noir_overlay != null and noir_overlay.has_method("glitch_burst"):
		noir_overlay.call("glitch_burst", strength, duration)

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")
