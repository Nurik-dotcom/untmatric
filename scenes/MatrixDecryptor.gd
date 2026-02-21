extends Control

const STATE_UNSET := -1
const STATE_ZERO := 0
const STATE_ONE := 1

enum CellState { INACTIVE, ACTIVE, LOCKED }
enum MatrixMode { CLASSIC, LADDER }

const MATRIX_SIZE := 6
const MATRIX_WEIGHTS := [32, 16, 8, 4, 2, 1]
const LADDER_DATA_PATH := "res://data/matrix_ladder_levels.json"
const DEFAULT_LADDER_ID := "C_LADDER_001"

const COLOR_OK := Color("33ff66")
const COLOR_WARN := Color("ffcc00")
const COLOR_BAD := Color("ff5555")
const COLOR_DIM := Color(0.65, 0.65, 0.65)

const MIN_CELL_SIZE := 64
const DETAILS_SHEET_H := 360.0
const FREQ_WINDOW_SEC := 1.6
const FREQ_MAX_IN_WINDOW := 3

@onready var btn_back: Button = $UI/SafeArea/Main/HeaderBar/HeaderContent/BtnBack
@onready var btn_details: Button = $UI/SafeArea/Main/HeaderBar/HeaderContent/BtnDetails
@onready var btn_close_details: Button = $UI/DetailsSheet/DetailsContent/DetailsHeader/BtnCloseDetails
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

var mode: int = MatrixMode.LADDER
var ladder_id: String = DEFAULT_LADDER_ID
var _stages: Array = []
var _stage_index := 0
var _active_size := 2
var _active_base := "DEC"
var _active_targets: Array[int] = []
var _lock_previous := true

var _values: Array = []
var _states: Array = []
var _changed: Dictionary = {}

var _buttons: Array = []
var _row_nodes: Array = []
var _col_nodes: Array = []
var _target_nodes: Array = []
var _now_nodes: Array = []
var _state_nodes: Array = []
var _font: Font

var _input_locked := false
var _safe_mode := false
var _details_open := false
var _shield_token := 0

var _task_started_ms := 0
var _first_action_ms := -1
var _check_count := 0
var _actions_since_check := 0

var _check_times: Array[float] = []
var _lazy_streak := 0
var _blocked_until := 0.0
var _logs: Array[String] = []

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

	_setup_font()
	_build_row_labels()
	_build_col_labels()
	_build_grid()
	_build_targets_panel()
	toast_panel.visible = false
	details_sheet.visible = false
	_reset_shield_marks()

	await get_tree().process_frame
	_set_details_open(false, true)
	_start_run()

func _start_run() -> void:
	_safe_mode = false
	_input_locked = false
	_reset_trial_clock()
	_check_times.clear()
	_lazy_streak = 0
	_blocked_until = 0.0
	_changed.clear()
	GlobalMetrics.stability = 100.0
	GlobalMetrics.emit_signal("stability_changed", GlobalMetrics.stability, 0.0)
	if mode == MatrixMode.CLASSIC:
		mode = MatrixMode.LADDER
	if not _load_ladder_data():
		_use_fallback_ladder()
	_init_arrays()
	_apply_stage(0, true)
	_set_input_enabled(true)
	_refresh_stability(GlobalMetrics.stability)

func _load_ladder_data() -> bool:
	var file := FileAccess.open(LADDER_DATA_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var levels = parsed.get("levels", [])
	if typeof(levels) != TYPE_ARRAY:
		return false
	for level in levels:
		if typeof(level) != TYPE_DICTIONARY:
			continue
		if str(level.get("id", "")) != ladder_id:
			continue
		var stages = level.get("stages", [])
		if typeof(stages) != TYPE_ARRAY or stages.is_empty():
			return false
		_stages = stages.duplicate(true)
		var options = level.get("options", {})
		_lock_previous = bool(options.get("lock_previous", true))
		return true
	return false

func _use_fallback_ladder() -> void:
	_stages = [
		{"size": 2, "base": "DEC", "row_targets": [3, 0]},
		{"size": 3, "base": "DEC", "row_targets": [3, 4, 2]},
		{"size": 4, "base": "OCT", "row_targets": ["13", "14", "02", "16"]},
		{"size": 5, "base": "OCT", "row_targets": ["13", "34", "22", "16", "05"]},
		{"size": 6, "base": "HEX", "row_targets": ["2B", "1C", "32", "0E", "25", "17"]}
	]
	_lock_previous = true

func _init_arrays() -> void:
	_values.clear()
	_states.clear()
	for _r in range(MATRIX_SIZE):
		var row_vals: Array = []
		var row_states: Array = []
		for _c in range(MATRIX_SIZE):
			row_vals.append(STATE_UNSET)
			row_states.append(CellState.INACTIVE)
		_values.append(row_vals)
		_states.append(row_states)

func _apply_stage(index: int, fresh: bool) -> void:
	if index < 0 or index >= _stages.size():
		return
	_stage_index = index
	var stage: Dictionary = _stages[index]
	_active_size = clampi(int(stage.get("size", 2)), 2, MATRIX_SIZE)
	_active_base = str(stage.get("base", "DEC")).to_upper()
	_active_targets = _parse_targets(stage.get("row_targets", []), _active_base, _active_size)
	if fresh:
		for r in range(MATRIX_SIZE):
			for c in range(MATRIX_SIZE):
				_values[r][c] = STATE_UNSET
				_states[r][c] = CellState.INACTIVE
	for r in range(MATRIX_SIZE):
		for c in range(MATRIX_SIZE):
			if int(_states[r][c]) != CellState.LOCKED:
				_states[r][c] = CellState.INACTIVE
	var col_start := _col_start(_active_size)
	for r in range(_active_size):
		for c in range(col_start, MATRIX_SIZE):
			if int(_states[r][c]) != CellState.LOCKED:
				_states[r][c] = CellState.ACTIVE
	_reset_trial_clock()
	_actions_since_check = 0
	_check_times.clear()
	_lazy_streak = 0
	_changed.clear()
	_refresh_header()
	_refresh_labels()
	_refresh_grid()
	_refresh_targets()
	_update_status()
	constraint_hint.text = "Match each row sum to target (%s)." % _active_base
	hint_text.text = "Fill active cells and press CHECK."
	_log("Stage %d/%d loaded (%dx%d %s)." % [_stage_index + 1, _stages.size(), _active_size, _active_size, _active_base], COLOR_OK)

func _parse_targets(raw: Variant, base_name: String, expected: int) -> Array[int]:
	var out: Array[int] = []
	if typeof(raw) != TYPE_ARRAY:
		for _i in range(expected):
			out.append(0)
		return out
	var arr: Array = raw
	for i in range(expected):
		out.append(_parse_target(arr[i] if i < arr.size() else 0, base_name))
	return out

func _parse_target(v: Variant, base_name: String) -> int:
	if base_name == "DEC":
		return int(v)
	var base := 8 if base_name == "OCT" else 16
	var text := str(v).strip_edges().to_upper()
	if text.begins_with("0X"):
		text = text.substr(2)
	if text.begins_with("0O"):
		text = text.substr(2)
	return _parse_base(text, base)

func _parse_base(text: String, base: int) -> int:
	var digits := "0123456789ABCDEF"
	var val := 0
	for i in range(text.length()):
		var ch := text.substr(i, 1)
		var n := digits.find(ch)
		if n < 0 or n >= base:
			return 0
		val = val * base + n
	return val

func _to_base(value: int, base: int) -> String:
	if value == 0:
		return "0"
	var digits := "0123456789ABCDEF"
	var v := value
	var out := ""
	while v > 0:
		var d := v % base
		out = digits.substr(d, 1) + out
		v = int(float(v) / float(base))
	return out

func _format_value(value: int) -> String:
	if _active_base == "DEC":
		return str(value)
	if _active_base == "OCT":
		var oct_text := _to_base(value, 8)
		if _active_size >= 4 and oct_text.length() < 2:
			oct_text = "0" + oct_text
		return oct_text
	return "%02X" % value

func _setup_font() -> void:
	var f = load("res://fonts/IBMPlexMono-Medium.ttf")
	if f:
		_font = f
	else:
		var fallback := SystemFont.new()
		fallback.font_names = PackedStringArray(["Courier New", "Consolas", "Liberation Mono"])
		_font = fallback

func _build_row_labels() -> void:
	_row_nodes.clear()
	for child in row_labels.get_children():
		child.queue_free()
	for _i in range(MATRIX_SIZE):
		var lbl := Label.new()
		lbl.custom_minimum_size = Vector2(92, MIN_CELL_SIZE)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_override("font", _font)
		lbl.add_theme_font_size_override("font_size", 20)
		lbl.add_theme_color_override("font_color", COLOR_DIM)
		row_labels.add_child(lbl)
		_row_nodes.append(lbl)

func _build_col_labels() -> void:
	_col_nodes.clear()
	for child in col_labels.get_children():
		child.queue_free()
	for _i in range(MATRIX_SIZE):
		var lbl := Label.new()
		lbl.custom_minimum_size = Vector2(MIN_CELL_SIZE, 42)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_override("font", _font)
		lbl.add_theme_font_size_override("font_size", 18)
		lbl.add_theme_color_override("font_color", COLOR_DIM)
		col_labels.add_child(lbl)
		_col_nodes.append(lbl)

func _build_grid() -> void:
	_buttons.clear()
	for child in grid.get_children():
		child.queue_free()
	grid.columns = MATRIX_SIZE
	for r in range(MATRIX_SIZE):
		var row_btns: Array = []
		for c in range(MATRIX_SIZE):
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(MIN_CELL_SIZE, MIN_CELL_SIZE)
			btn.focus_mode = Control.FOCUS_NONE
			btn.text = "."
			btn.add_theme_font_override("font", _font)
			btn.add_theme_font_size_override("font_size", 22)
			btn.pressed.connect(_on_cell_pressed.bind(r, c))
			grid.add_child(btn)
			row_btns.append(btn)
		_buttons.append(row_btns)

func _build_targets_panel() -> void:
	_target_nodes.clear()
	_now_nodes.clear()
	_state_nodes.clear()
	for child in targets_rows.get_children():
		child.queue_free()
	for i in range(MATRIX_SIZE):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var n := Label.new(); n.custom_minimum_size = Vector2(42, 28); n.text = "R%d" % i
		var t := Label.new(); t.custom_minimum_size = Vector2(90, 28); t.text = "target --"
		var cur := Label.new(); cur.custom_minimum_size = Vector2(80, 28); cur.text = "now --"
		var st := Label.new(); st.custom_minimum_size = Vector2(60, 28); st.text = "N/A"; st.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		for lbl in [n, t, cur, st]:
			lbl.add_theme_font_override("font", _font)
			lbl.add_theme_font_size_override("font_size", 18)
		row.add_child(n); row.add_child(t); row.add_child(cur); row.add_child(st)
		targets_rows.add_child(row)
		_target_nodes.append(t)
		_now_nodes.append(cur)
		_state_nodes.append(st)

func _refresh_header() -> void:
	level_label.text = "PROTOCOL C | LADDER %d/%d | %dx%d" % [_stage_index + 1, _stages.size(), _active_size, _active_size]
	matrix_title.text = "MATRIX LADDER"
	var c0 := _col_start(_active_size)
	inlet_tag.text = "IN [0,%d]" % c0
	outlet_tag.text = "OUT [%d,%d]" % [_active_size - 1, MATRIX_SIZE - 1]

func _refresh_stability(value: float) -> void:
	progress_stability.value = value
	stability_text.text = "Stability: %d%%" % int(value)

func _refresh_labels() -> void:
	for r in range(MATRIX_SIZE):
		if r < _active_size:
			_row_nodes[r].text = _format_value(_active_targets[r])
			_row_nodes[r].add_theme_color_override("font_color", COLOR_DIM)
		else:
			_row_nodes[r].text = "?"
			_row_nodes[r].add_theme_color_override("font_color", Color(0.38, 0.38, 0.38, 1.0))
	var c0 := _col_start(_active_size)
	for c in range(MATRIX_SIZE):
		if c >= c0:
			_col_nodes[c].text = str(MATRIX_WEIGHTS[c])
			_col_nodes[c].add_theme_color_override("font_color", COLOR_DIM)
		else:
			_col_nodes[c].text = "."
			_col_nodes[c].add_theme_color_override("font_color", Color(0.38, 0.38, 0.38, 1.0))

func _refresh_grid() -> void:
	if _buttons.size() != MATRIX_SIZE or _states.size() != MATRIX_SIZE or _values.size() != MATRIX_SIZE:
		return
	for r in range(MATRIX_SIZE):
		for c in range(MATRIX_SIZE):
			_draw_cell(r, c)

func _draw_cell(r: int, c: int) -> void:
	if r < 0 or r >= _buttons.size() or r >= _states.size() or r >= _values.size():
		return
	var row_buttons: Array = _buttons[r]
	var row_states: Array = _states[r]
	var row_values: Array = _values[r]
	if c < 0 or c >= row_buttons.size() or c >= row_states.size() or c >= row_values.size():
		return
	var btn: Button = row_buttons[c]
	var st := int(row_states[c])
	var v := int(row_values[c])
	btn.disabled = _input_locked or st != CellState.ACTIVE
	if st == CellState.INACTIVE:
		btn.text = "."
		btn.self_modulate = Color(0.62, 0.62, 0.62, 1.0)
		btn.add_theme_color_override("font_color", Color(0.42, 0.42, 0.42, 1.0))
	elif st == CellState.LOCKED:
		btn.text = _cell_text(v)
		btn.self_modulate = Color(0.72, 0.72, 0.72, 1.0)
		btn.add_theme_color_override("font_color", Color(0.82, 0.82, 0.82, 1.0))
	else:
		btn.text = _cell_text(v)
		btn.self_modulate = Color(1, 1, 1, 1)
		if v == STATE_ONE:
			btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		elif v == STATE_ZERO:
			btn.add_theme_color_override("font_color", Color(0.82, 0.82, 0.82, 1))
		else:
			btn.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55, 1))
	var in_col := _col_start(_active_size)
	if r == 0 and c == in_col:
		btn.text += "\nIN"
		btn.self_modulate = Color(0.78, 1.0, 0.82, 1.0)
	elif r == _active_size - 1 and c == MATRIX_SIZE - 1:
		btn.text += "\nOUT"
		btn.self_modulate = Color(0.78, 0.94, 1.0, 1.0)

func _cell_text(v: int) -> String:
	if v == STATE_ZERO:
		return "0"
	if v == STATE_ONE:
		return "1"
	return "."

func _on_cell_pressed(r: int, c: int) -> void:
	if _input_locked or int(_states[r][c]) != CellState.ACTIVE:
		return
	if _first_action_ms < 0:
		_first_action_ms = Time.get_ticks_msec() - _task_started_ms
	AudioManager.play("click")
	var cur := int(_values[r][c])
	_values[r][c] = STATE_ZERO if cur == STATE_UNSET else (STATE_ONE if cur == STATE_ZERO else STATE_UNSET)
	_changed["%d,%d" % [r, c]] = true
	_actions_since_check += 1
	_draw_cell(r, c)
	_refresh_targets()
	_update_status()

func _col_start(size: int) -> int:
	return MATRIX_SIZE - size

func _row_sum(r: int) -> int:
	var sum := 0
	var c0 := _col_start(_active_size)
	for c in range(c0, MATRIX_SIZE):
		if int(_values[r][c]) == STATE_ONE:
			sum += int(MATRIX_WEIGHTS[c])
	return sum

func _eval_stage() -> Dictionary:
	var wrong := 0
	var delta := 0
	var first := -1
	var nows: Array = []
	var oks: Array = []
	for r in range(_active_size):
		var now := _row_sum(r)
		var target := int(_active_targets[r])
		var ok := now == target
		nows.append(now)
		oks.append(ok)
		if not ok:
			wrong += 1
			delta += abs(now - target)
			if first < 0:
				first = r
	return {"success": wrong == 0, "wrong": wrong, "delta": delta, "first": first, "nows": nows, "oks": oks}

func _refresh_targets() -> void:
	var e := _eval_stage()
	var nows: Array = e.get("nows", [])
	var oks: Array = e.get("oks", [])
	for r in range(MATRIX_SIZE):
		if r < _active_size:
			_target_nodes[r].text = "target %s" % _format_value(_active_targets[r])
			_now_nodes[r].text = "now %s" % _format_value(int(nows[r]))
			var ok := bool(oks[r])
			_state_nodes[r].text = "OK" if ok else "ERR"
			_state_nodes[r].add_theme_color_override("font_color", COLOR_OK if ok else COLOR_BAD)
		else:
			_target_nodes[r].text = "target --"
			_now_nodes[r].text = "now --"
			_state_nodes[r].text = "N/A"
			_state_nodes[r].add_theme_color_override("font_color", Color(0.45, 0.45, 0.45, 1.0))

func _filled_count() -> int:
	var n := 0
	var c0 := _col_start(_active_size)
	for r in range(_active_size):
		for c in range(c0, MATRIX_SIZE):
			if int(_values[r][c]) != STATE_UNSET:
				n += 1
	return n

func _update_status() -> void:
	var e := _eval_stage()
	var cool := maxi(0.0, _blocked_until - (Time.get_ticks_msec() / 1000.0))
	progress_label.text = "STAGE %d/%d | BASE %s | FILLED %d/%d | WRONG %d" % [_stage_index + 1, _stages.size(), _active_base, _filled_count(), _active_size * _active_size, int(e.get("wrong", 0))]
	mode_state_label.text = "MODE: %s | SHIELD: %s" % ["SAFE" if _safe_mode else "RUN", "COOLDOWN %.1fs" % cool if cool > 0.0 else "READY"]

func _on_hint_pressed() -> void:
	if _input_locked:
		hint_text.text = "Input is locked."
		_show_toast("Input locked", COLOR_WARN)
		return
	var e := _eval_stage()
	if bool(e.get("success", false)):
		hint_text.text = "All rows match target. Press CHECK."
		_show_toast("Ready for check", COLOR_OK)
		return
	var r := int(e.get("first", -1))
	if r < 0:
		hint_text.text = "No hint available."
		return
	var t := int(_active_targets[r])
	var now := _row_sum(r)
	var best := _best_edit(r, t)
	if best.is_empty():
		hint_text.text = "Row %d mismatch. Edit active cells." % (r + 1)
	else:
		hint_text.text = "Row %d target %s now %s. Try weight %d -> %d." % [r + 1, _format_value(t), _format_value(now), int(best.get("weight", 0)), int(best.get("new_bit", 0))]
	_log("Hint requested for row %d." % (r + 1), COLOR_WARN)
	_show_toast("Hint updated", COLOR_WARN)

func _best_edit(r: int, target: int) -> Dictionary:
	var best: Dictionary = {}
	var best_score := 1_000_000
	var c0 := _col_start(_active_size)
	var sum := _row_sum(r)
	for c in range(c0, MATRIX_SIZE):
		if int(_states[r][c]) != CellState.ACTIVE:
			continue
		var cur_cell := int(_values[r][c])
		var cur_bit := 1 if cur_cell == STATE_ONE else 0
		for bit in [0, 1]:
			var bit_i: int = int(bit)
			if bit_i == cur_bit:
				continue
			var w := int(MATRIX_WEIGHTS[c])
			var ns: int = sum - cur_bit * w + bit_i * w
			var score: int = abs(target - ns)
			if score < best_score:
				best_score = score
				best = {"col": c, "weight": w, "new_bit": bit_i, "new_sum": ns}
	return best

func _on_check_pressed() -> void:
	if _input_locked:
		return
	_check_count += 1
	var now_sec := Time.get_ticks_msec() / 1000.0
	if now_sec < _blocked_until:
		_register({"success": false, "error": "SHIELD_ACTIVE", "penalty": 0.0, "stability_delta": 0.0, "wrong": 0, "delta": 0})
		hint_text.text = "Shield cooldown %.1fs" % maxi(0.0, _blocked_until - now_sec)
		_show_toast("SHIELD: COOLDOWN", COLOR_WARN)
		return
	_check_times.append(now_sec)
	var cut := now_sec - FREQ_WINDOW_SEC
	while _check_times.size() > 0 and _check_times[0] < cut:
		_check_times.pop_front()
	if _check_times.size() > FREQ_MAX_IN_WINDOW:
		_trigger_shield("FREQUENCY", 2.5, "Shield: too frequent checks.")
		_register({"success": false, "error": "SHIELD_FREQ", "penalty": 0.0, "stability_delta": 0.0, "wrong": 0, "delta": 0})
		_actions_since_check = 0
		_changed.clear()
		return

	var e := _eval_stage()
	var wrong := int(e.get("wrong", 0))
	if _actions_since_check <= 1 and wrong >= 2:
		_lazy_streak += 1
	else:
		_lazy_streak = 0
	if _lazy_streak >= 3:
		_trigger_shield("LAZY", 3.0, "Shield: brute-force behavior blocked.")
		_register({"success": false, "error": "SHIELD_LAZY", "penalty": 0.0, "stability_delta": 0.0, "wrong": wrong, "delta": int(e.get("delta", 0))})
		_actions_since_check = 0
		_changed.clear()
		return

	if bool(e.get("success", false)):
		AudioManager.play("relay")
		_overlay_glitch(0.12, 0.10)
		_register({"success": true, "error": "NONE", "penalty": 0.0, "stability_delta": 0.0, "wrong": 0, "delta": 0})
		_show_toast("STAGE PASS", COLOR_OK)
		_log("Stage %d solved." % (_stage_index + 1), COLOR_OK)
		_actions_since_check = 0
		_changed.clear()
		await _stage_pass()
		return

	var delta := int(e.get("delta", 0))
	var penalty := float(wrong * 6 + clampi(int(round(float(delta) / 4.0)), 0, 12))
	_register({"success": false, "error": "INCORRECT", "penalty": penalty, "stability_delta": -penalty, "wrong": wrong, "delta": delta})
	AudioManager.play("error")
	_overlay_glitch(0.55, 0.18)
	hint_text.text = "Wrong rows: %d | delta: %d | penalty: %d" % [wrong, delta, int(penalty)]
	_log("Check failed. wrong=%d delta=%d penalty=%d" % [wrong, delta, int(penalty)], COLOR_BAD)
	_show_toast("INCORRECT", COLOR_BAD)
	_actions_since_check = 0
	_changed.clear()
	_refresh_targets()
	_update_status()

func _stage_pass() -> void:
	if _stage_index >= _stages.size() - 1:
		_show_toast("LADDER COMPLETE", COLOR_OK)
		_log("Ladder completed. Restarting run.", COLOR_OK)
		await get_tree().create_timer(1.2).timeout
		_start_run()
		return
	if _lock_previous:
		var c0 := _col_start(_active_size)
		for r in range(_active_size):
			for c in range(c0, MATRIX_SIZE):
				if int(_states[r][c]) == CellState.ACTIVE:
					_states[r][c] = CellState.LOCKED
	_apply_stage(_stage_index + 1, false)

func _trigger_shield(name: String, duration: float, msg: String) -> void:
	_blocked_until = (Time.get_ticks_msec() / 1000.0) + duration
	hint_text.text = msg
	_log(msg, COLOR_WARN)
	_show_toast("SHIELD: %s" % name, COLOR_WARN)
	GlobalMetrics.emit_signal("shield_triggered", name, duration)

func _on_reset_pressed() -> void:
	if _input_locked:
		return
	var c0 := _col_start(_active_size)
	for r in range(_active_size):
		for c in range(c0, MATRIX_SIZE):
			if int(_states[r][c]) == CellState.ACTIVE:
				_values[r][c] = STATE_UNSET
	_changed.clear()
	_actions_since_check = 0
	_lazy_streak = 0
	_reset_trial_clock()
	_refresh_grid()
	_refresh_targets()
	_update_status()
	hint_text.text = "Active stage reset."
	_log("Stage reset.", COLOR_WARN)
	_show_toast("RESET", COLOR_WARN)

func _on_shield_triggered(name: String, duration: float) -> void:
	if name != "FREQUENCY" and name != "LAZY":
		return
	AudioManager.play("error")
	_overlay_glitch(0.5, 0.16)
	if name == "FREQUENCY":
		_flash_mark(shield_freq)
	else:
		_flash_mark(shield_lazy)
	_shield_token += 1
	var token := _shield_token
	_set_input_enabled(false)
	await get_tree().create_timer(duration).timeout
	if token != _shield_token:
		return
	if not _safe_mode and (Time.get_ticks_msec() / 1000.0) >= _blocked_until:
		_set_input_enabled(true)
		_log("Shield released.", COLOR_OK)

func _on_stability_changed(new_val: float, _change: float) -> void:
	_refresh_stability(new_val)
	if new_val <= 0.0 and not _safe_mode:
		_safe_mode = true
		_set_input_enabled(false)
		_update_status()
		await _run_safe_mode()

func _run_safe_mode() -> void:
	_log("Safe mode: conflict analysis started.", COLOR_WARN)
	var e := _eval_stage()
	var r := int(e.get("first", -1))
	if r < 0:
		hint_text.text = "Safe mode: no direct conflict found."
	else:
		var t := int(_active_targets[r])
		var best := _best_edit(r, t)
		if best.is_empty():
			hint_text.text = "Safe mode: row %d mismatch. Check active bits." % (r + 1)
			_highlight(r, -1)
		else:
			var col := int(best.get("col", -1))
			hint_text.text = "Safe mode: row %d target %s now %s. Try weight %d." % [r + 1, _format_value(t), _format_value(_row_sum(r)), int(best.get("weight", 0))]
			_highlight(r, col)
	await get_tree().create_timer(6.0).timeout
	_clear_highlight()
	_safe_mode = false
	if (Time.get_ticks_msec() / 1000.0) >= _blocked_until:
		_set_input_enabled(true)
	_update_status()
	_log("Safe mode finished.", COLOR_OK)

func _highlight(r: int, c: int) -> void:
	for rr in range(MATRIX_SIZE):
		for cc in range(MATRIX_SIZE):
			var btn: Button = _buttons[rr][cc]
			if rr == r or (c >= 0 and cc == c):
				btn.self_modulate = Color(1.0, 0.45, 0.45, 1.0)
			elif int(_states[rr][cc]) == CellState.INACTIVE:
				btn.self_modulate = Color(0.62, 0.62, 0.62, 1.0)
			else:
				btn.self_modulate = Color(0.84, 0.84, 0.84, 1.0)
	if r >= 0 and r < _row_nodes.size():
		_row_nodes[r].add_theme_color_override("font_color", COLOR_BAD)
	if r >= 0 and r < _state_nodes.size():
		_state_nodes[r].add_theme_color_override("font_color", COLOR_BAD)

func _clear_highlight() -> void:
	_refresh_labels()
	_refresh_grid()
	_refresh_targets()

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

func _register(result: Dictionary) -> void:
	var hash_key := str(hash("%s|%d|%s" % [ladder_id, _stage_index, _active_base]))
	var payload := TrialV2.build("MATRIX_DECRYPTOR", "C", "MATRIX_LADDER", "GRID_CHECK", hash_key)
	var elapsed_ms: int = maxi(0, Time.get_ticks_msec() - _task_started_ms)
	payload["elapsed_ms"] = elapsed_ms
	payload["duration"] = float(elapsed_ms) / 1000.0
	payload["time_to_first_action_ms"] = _first_action_ms if _first_action_ms >= 0 else elapsed_ms
	payload["is_correct"] = bool(result.get("success", false))
	payload["is_fit"] = bool(result.get("success", false))
	payload["stability_delta"] = float(result.get("stability_delta", 0.0))
	payload["error_type"] = str(result.get("error", "NONE"))
	payload["penalty_reported"] = float(result.get("penalty", 0.0))
	payload["changed_cells_count"] = _changed.size()
	payload["check_count"] = _check_count
	payload["stage_index"] = _stage_index + 1
	payload["stage_total"] = _stages.size()
	payload["stage_size"] = _active_size
	payload["stage_base"] = _active_base
	payload["wrong_rows"] = int(result.get("wrong", 0))
	payload["delta_sum"] = int(result.get("delta", 0))
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
	var tw := create_tween()
	tw.tween_property(toast_panel, "modulate", Color(1, 1, 1, 1), 0.15)
	tw.tween_interval(0.9)
	tw.tween_property(toast_panel, "modulate", Color(1, 1, 1, 0), 0.25)
	tw.tween_callback(func() -> void: toast_panel.visible = false)

func _flash_mark(label: Label) -> void:
	label.modulate = Color(1, 1, 1, 1)
	var tw := create_tween()
	tw.tween_property(label, "modulate", Color(1, 1, 1, 0.25), 0.6)

func _reset_shield_marks() -> void:
	shield_freq.modulate = Color(1, 1, 1, 0.25)
	shield_lazy.modulate = Color(1, 1, 1, 0.25)

func _on_details_pressed() -> void:
	_set_details_open(not _details_open, false)

func _set_details_open(open: bool, immediate: bool) -> void:
	_details_open = open
	if open:
		details_sheet.visible = true
	var t_top := -DETAILS_SHEET_H if open else 0.0
	var t_bottom := 0.0 if open else DETAILS_SHEET_H
	if immediate:
		details_sheet.offset_top = t_top
		details_sheet.offset_bottom = t_bottom
		if not open:
			details_sheet.visible = false
		return
	var tw := create_tween()
	tw.tween_property(details_sheet, "offset_top", t_top, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(details_sheet, "offset_bottom", t_bottom, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if not open:
		tw.tween_callback(func() -> void: details_sheet.visible = false)

func _overlay_glitch(strength: float, duration: float) -> void:
	if noir_overlay != null and noir_overlay.has_method("glitch_burst"):
		noir_overlay.call("glitch_burst", strength, duration)

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")
