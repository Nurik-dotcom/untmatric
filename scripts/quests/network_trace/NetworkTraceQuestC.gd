extends Control

const THEME_GREEN: Theme = preload("res://ui/theme_terminal_green.tres")
const THEME_AMBER: Theme = preload("res://ui/theme_terminal_amber.tres")
const ERROR_MAP = preload("res://scripts/ssot/network_trace_errors.gd")
const BIT_CELL_SCENE: PackedScene = preload("res://scenes/ui/subnet/BitCell.tscn")

const LEVELS_PATH: String = "res://data/network_trace_c_levels.json"
const MAX_ATTEMPTS: int = 3
const DEFAULT_TIME_LIMIT_SEC: int = 120
const APPLY_COOLDOWN_MS: int = 400
const ANSWER_COOLDOWN_MS: int = 200
const FAIL_STABILITY_DELTA: float = -10.0
const HINT_STABILITY_DELTA: float = -5.0
const SPAM_STABILITY_DELTA: float = -2.0
const PALETTE_GREEN_ID: int = 0
const PALETTE_AMBER_ID: int = 1

enum QuestState { INIT, BOARD_LOCKED, MASK_PLACED, AND_APPLIED, ANSWERED, SAFE_MODE, DIAGNOSTIC, DONE }

@onready var btn_back: Button = $Main/V/Header/BtnBack
@onready var lbl_title: Label = $Main/V/Header/LblTitle
@onready var lbl_meta: Label = $Main/V/Header/LblMeta
@onready var palette_select: OptionButton = $Main/V/Header/PaletteSelect
@onready var body: BoxContainer = $Main/V/Body
@onready var lbl_briefing: RichTextLabel = $Main/V/Body/TerminalPane/TerminalMargin/TerminalV/LblBriefing
@onready var lbl_prompt: RichTextLabel = $Main/V/Body/TerminalPane/TerminalMargin/TerminalV/LblPrompt
@onready var lbl_target_ip: Label = $Main/V/Body/TerminalPane/TerminalMargin/TerminalV/TargetBox/LblTargetIp
@onready var lbl_target_cidr: Label = $Main/V/Body/TerminalPane/TerminalMargin/TerminalV/TargetBox/LblTargetCidr
@onready var lbl_target_ask: Label = $Main/V/Body/TerminalPane/TerminalMargin/TerminalV/TargetBox/LblTargetAsk
@onready var log_text: RichTextLabel = $Main/V/Body/TerminalPane/TerminalMargin/TerminalV/LogScroll/LogText
@onready var lock_indicator: NetworkLockIndicator = $Main/V/Body/BoardPane/BoardMargin/BoardV/LockIndicator
@onready var row_ip: HBoxContainer = $Main/V/Body/BoardPane/BoardMargin/BoardV/BitBoard/RowIpLine/RowIp
@onready var row_mask: HBoxContainer = $Main/V/Body/BoardPane/BoardMargin/BoardV/BitBoard/RowMaskLine/MaskDropTarget/RowMask
@onready var mask_drop_target: SubnetMaskDropTarget = $Main/V/Body/BoardPane/BoardMargin/BoardV/BitBoard/RowMaskLine/MaskDropTarget
@onready var row_res_line: HBoxContainer = $Main/V/Body/BoardPane/BoardMargin/BoardV/BitBoard/RowResLine
@onready var row_res: HBoxContainer = $Main/V/Body/BoardPane/BoardMargin/BoardV/BitBoard/RowResLine/RowRes
@onready var mask_overlay: SubnetMaskOverlay = $Main/V/Body/BoardPane/BoardMargin/BoardV/MaskTray/MaskOverlay
@onready var ruler: SubnetRulerControl = $Main/V/Body/BoardPane/BoardMargin/BoardV/Ruler
@onready var btn_analyze: Button = $Main/V/Body/BoardPane/BoardMargin/BoardV/BoardActions/BtnAnalyze
@onready var btn_apply_and: Button = $Main/V/Body/BoardPane/BoardMargin/BoardV/BoardActions/BtnApplyAnd
@onready var btn_reset: Button = $Main/V/Body/BoardPane/BoardMargin/BoardV/BoardActions/BtnReset
@onready var lbl_status: Label = $Main/V/Body/AnswersPane/AnswersMargin/AnswersV/LblStatus
@onready var btn_next: Button = $Main/V/Body/AnswersPane/AnswersMargin/AnswersV/BottomRow/BtnNext
@onready var diagnostics_panel: PanelContainer = $DiagnosticsPanel
@onready var crt_overlay: ColorRect = $CanvasLayer/CRT_Overlay

@onready var action_buttons: Array[Button] = [
	$Main/V/Body/AnswersPane/AnswersMargin/AnswersV/OptionsGrid/ActionBtn1,
	$Main/V/Body/AnswersPane/AnswersMargin/AnswersV/OptionsGrid/ActionBtn2,
	$Main/V/Body/AnswersPane/AnswersMargin/AnswersV/OptionsGrid/ActionBtn3,
	$Main/V/Body/AnswersPane/AnswersMargin/AnswersV/OptionsGrid/ActionBtn4,
	$Main/V/Body/AnswersPane/AnswersMargin/AnswersV/OptionsGrid/ActionBtn5,
	$Main/V/Body/AnswersPane/AnswersMargin/AnswersV/OptionsGrid/ActionBtn6
]

var row_ip_cells: Array[SubnetBitCell] = []
var row_mask_cells: Array[SubnetBitCell] = []
var row_res_cells: Array[SubnetBitCell] = []

var levels: Array[Dictionary] = []
var current_level: Dictionary = {}
var current_level_index: int = 0
var state: int = QuestState.INIT

var level_started_ms: int = 0
var first_action_ms: int = -1
var time_left_sec: float = float(DEFAULT_TIME_LIMIT_SEC)
var timer_running: bool = false

var wrong_count: int = 0
var level_finished: bool = false
var result_sent: bool = false
var safe_mode_used: bool = false
var hint_used: bool = false

var mask_placed: bool = false
var and_applied: bool = false
var and_result_last: int = -1
var pending_mask_data: Dictionary = {}

var mask_moves_count: int = 0
var apply_count: int = 0
var reset_count: int = 0
var analyze_count: int = 0
var not_applied_clicks: int = 0
var spam_clicks: int = 0

var apply_cooldown_until_ms: int = 0
var answer_cooldown_until_ms: int = 0

var selected_option_id: String = ""
var last_error_code: String = ""
var attempts: Array[Dictionary] = []
var task_session: Dictionary = {}
var variant_hash: String = ""

func _ready() -> void:
	_setup_runtime_controls()
	_connect_signals()
	_apply_palette(PALETTE_GREEN_ID)
	_apply_layout_mode()
	_build_bit_rows()

	if GlobalMetrics != null and not GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.connect(_on_stability_changed)

	if not _load_levels():
		_show_boot_error("Network Trace C data is missing or invalid.")
		return

	_start_level(0)

func _exit_tree() -> void:
	if GlobalMetrics != null and GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.disconnect(_on_stability_changed)

func _process(delta: float) -> void:
	if state == QuestState.DIAGNOSTIC and not diagnostics_panel.visible and not level_finished:
		state = QuestState.SAFE_MODE if safe_mode_used else QuestState.AND_APPLIED

	if timer_running and not level_finished:
		time_left_sec -= delta
		if time_left_sec <= 0.0:
			time_left_sec = 0.0
			_update_meta_label()
			_on_timeout()
		else:
			_update_meta_label()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_apply_layout_mode()

func _setup_runtime_controls() -> void:
	lbl_title.text = "NETWORK TRACE | C"
	palette_select.clear()
	palette_select.add_item("GREEN", PALETTE_GREEN_ID)
	palette_select.add_item("AMBER", PALETTE_AMBER_ID)
	palette_select.select(PALETTE_GREEN_ID)
	btn_next.visible = false
	btn_analyze.disabled = true
	btn_apply_and.disabled = true
	diagnostics_panel.visible = false

func _connect_signals() -> void:
	btn_back.pressed.connect(_on_back_pressed)
	palette_select.item_selected.connect(_on_palette_selected)
	btn_analyze.pressed.connect(_on_analyze_pressed)
	btn_apply_and.pressed.connect(_on_apply_and_pressed)
	btn_reset.pressed.connect(_on_reset_pressed)
	btn_next.pressed.connect(_on_next_pressed)

	mask_overlay.mask_selected.connect(_on_mask_selected)
	mask_overlay.mask_drag_started.connect(_on_mask_drag_started)
	mask_drop_target.mask_dropped.connect(_on_mask_dropped)
	mask_drop_target.bad_drop.connect(_on_mask_bad_drop)
	mask_drop_target.target_tapped.connect(_on_mask_target_tapped)

	for idx in range(action_buttons.size()):
		action_buttons[idx].pressed.connect(_on_answer_pressed.bind(idx))

func _build_bit_rows() -> void:
	row_ip_cells = _create_row_cells(row_ip)
	row_mask_cells = _create_row_cells(row_mask)
	row_res_cells = _create_row_cells(row_res)

func _create_row_cells(container: HBoxContainer) -> Array[SubnetBitCell]:
	for child in container.get_children():
		child.queue_free()
	var out: Array[SubnetBitCell] = []
	for _i in range(8):
		var cell_variant: Variant = BIT_CELL_SCENE.instantiate()
		var cell: SubnetBitCell = cell_variant as SubnetBitCell
		if cell == null:
			continue
		container.add_child(cell)
		cell.set_empty()
		out.append(cell)
	return out

func _load_levels() -> bool:
	var file: FileAccess = FileAccess.open(LEVELS_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		return false
	levels.clear()
	var raw_levels: Array = parsed
	for level_var in raw_levels:
		if typeof(level_var) != TYPE_DICTIONARY:
			continue
		var level: Dictionary = level_var
		if _validate_level(level):
			levels.append(level)
	return not levels.is_empty()

func _validate_level(level: Dictionary) -> bool:
	var required_keys: Array[String] = [
		"id", "briefing", "prompt", "target_ip", "cidr", "ip_last", "mask_last", "step", "expected_network_last", "options", "correct_id", "explain_short", "explain_full", "tags"
	]
	for key in required_keys:
		if not level.has(key):
			return false

	var cidr: int = int(level.get("cidr", 0))
	if cidr < 25 or cidr > 28:
		return false

	var ip_last: int = int(level.get("ip_last", -1))
	var mask_last: int = int(level.get("mask_last", -1))
	var step: int = int(level.get("step", 0))
	var expected_last: int = int(level.get("expected_network_last", -1))
	if ip_last < 0 or ip_last > 255:
		return false
	if mask_last < 0 or mask_last > 255:
		return false
	if expected_last < 0 or expected_last > 255:
		return false

	var mask_from_cidr: int = _mask_last_from_cidr(cidr)
	if mask_last != mask_from_cidr:
		return false
	var expected_step: int = 256 - mask_last
	if step != expected_step:
		return false
	if (ip_last & mask_last) != expected_last:
		return false

	var options_var: Variant = level.get("options", [])
	if typeof(options_var) != TYPE_ARRAY:
		return false
	var options: Array = options_var
	if options.size() < 4 or options.size() > 6:
		return false

	var ids_seen: Dictionary = {}
	for option_var in options:
		if typeof(option_var) != TYPE_DICTIONARY:
			return false
		var option: Dictionary = option_var
		if not option.has("id") or not option.has("label") or not option.has("error_code"):
			return false
		var option_id: String = str(option.get("id", ""))
		if option_id.is_empty() or ids_seen.has(option_id):
			return false
		ids_seen[option_id] = true

	if not ids_seen.has(str(level.get("correct_id", ""))):
		return false

	if typeof(level.get("tags", [])) != TYPE_ARRAY:
		return false

	return true

func _show_boot_error(message: String) -> void:
	lbl_status.text = message
	lbl_status.add_theme_color_override("font_color", Color(1.0, 0.32, 0.32))
	btn_analyze.disabled = true
	btn_apply_and.disabled = true
	btn_reset.disabled = true
	_enable_answer_buttons(false)
	timer_running = false

func _start_level(index: int) -> void:
	if levels.is_empty():
		return
	if index >= levels.size():
		index = 0

	current_level_index = index
	current_level = levels[index].duplicate(true)
	variant_hash = str(hash(_build_variant_key(current_level)))

	level_started_ms = Time.get_ticks_msec()
	first_action_ms = -1
	time_left_sec = float(int(current_level.get("time_limit_sec", DEFAULT_TIME_LIMIT_SEC)))
	timer_running = true

	wrong_count = 0
	level_finished = false
	result_sent = false
	safe_mode_used = false
	hint_used = false
	mask_placed = false
	and_applied = false
	and_result_last = -1
	pending_mask_data.clear()
	mask_moves_count = 0
	apply_count = 0
	reset_count = 0
	analyze_count = 0
	not_applied_clicks = 0
	spam_clicks = 0
	apply_cooldown_until_ms = 0
	answer_cooldown_until_ms = 0
	selected_option_id = ""
	last_error_code = ""
	attempts.clear()

	task_session = {
		"task_id": str(current_level.get("id", "NT_C_UNKNOWN")),
		"variant_hash": variant_hash,
		"started_at_ticks": level_started_ms,
		"ended_at_ticks": 0,
		"attempts": [],
		"events": []
	}

	mask_overlay.setup(int(current_level.get("cidr", 26)), int(current_level.get("mask_last", 192)))
	mask_overlay.set_selected(false)
	mask_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	mask_drop_target.mouse_filter = Control.MOUSE_FILTER_STOP
	lock_indicator.set_locked()
	ruler.configure(int(current_level.get("step", 64)), int(current_level.get("ip_last", 0)))
	ruler.reset_state()
	row_res_line.visible = false

	_set_row_bits(row_ip_cells, int(current_level.get("ip_last", 0)))
	_clear_row(row_mask_cells)
	_clear_row(row_res_cells)

	btn_next.visible = false
	btn_analyze.disabled = true
	btn_analyze.text = "ANALYZE"
	btn_apply_and.disabled = true
	diagnostics_panel.visible = false

	_render_terminal()
	_render_options()
	_enable_answer_buttons(false)

	state = QuestState.BOARD_LOCKED
	lbl_status.text = "Place mask and press APPLY AND."
	lbl_status.add_theme_color_override("font_color", Color(0.82, 0.84, 0.82))
	_update_meta_label()
	_log_event("task_start", {"level": str(current_level.get("id", ""))})

func _render_terminal() -> void:
	lbl_briefing.clear()
	lbl_briefing.append_text("[color=#7a7a7a]BRIEFING[/color]\n%s" % str(current_level.get("briefing", "")))
	lbl_prompt.clear()
	lbl_prompt.append_text("[color=#9de6b3]PROMPT[/color]\n%s" % str(current_level.get("prompt", "")))
	lbl_target_ip.text = "IP: %s" % str(current_level.get("target_ip", "--"))
	lbl_target_cidr.text = "CIDR: /%d" % int(current_level.get("cidr", 0))
	lbl_target_ask.text = "ASK: Network ID (last octet)"

	var lines: Array[String] = []
	lines.append("ACCESS DENIED: wrong segment")
	lines.append("Host trace: %s" % str(current_level.get("target_ip", "--")))
	lines.append("Mask profile: /%d" % int(current_level.get("cidr", 0)))
	lines.append("Use bitwise AND to unlock network lock")
	lines.append("Segment step: %d" % int(current_level.get("step", 0)))
	var expected_last: int = int(current_level.get("expected_network_last", 0))
	lines.append("Target network ends at .%d" % (mini(255, expected_last + int(current_level.get("step", 0)) - 1)))

	var text_value: String = ""
	for line in lines:
		text_value += "- %s\n" % line
	log_text.text = text_value

func _render_options() -> void:
	var options_var: Variant = current_level.get("options", [])
	if typeof(options_var) != TYPE_ARRAY:
		return
	var options: Array = options_var
	for idx in range(action_buttons.size()):
		var btn: Button = action_buttons[idx]
		if idx < options.size():
			var option_var: Variant = options[idx]
			if typeof(option_var) != TYPE_DICTIONARY:
				btn.visible = false
				btn.disabled = true
				continue
			var option: Dictionary = option_var
			btn.visible = true
			btn.text = str(option.get("label", ""))
			btn.set_meta("option_id", str(option.get("id", "")))
			btn.set_meta("error_code", str(option.get("error_code", "")))
			btn.disabled = true
		else:
			btn.visible = false
			btn.disabled = true
			btn.text = ""
			btn.set_meta("option_id", "")
			btn.set_meta("error_code", "")

func _on_mask_selected(mask_data: Dictionary, sender: Node) -> void:
	if level_finished:
		return
	_register_first_action()
	pending_mask_data = mask_data.duplicate(true)
	mask_overlay.set_selected(sender == mask_overlay)
	_play_audio("click")
	lbl_status.text = "Mask selected. Tap mask row or drag onto mask row."
	lbl_status.add_theme_color_override("font_color", Color(0.82, 0.9, 1.0))
	_log_event("mask_selected", {"cidr": int(mask_data.get("cidr", 0))})

func _on_mask_drag_started(mask_data: Dictionary) -> void:
	if level_finished:
		return
	_register_first_action()
	pending_mask_data = mask_data.duplicate(true)
	mask_overlay.set_selected(false)
	_log_event("mask_drag_started", {"cidr": int(mask_data.get("cidr", 0))})

func _on_mask_target_tapped() -> void:
	if level_finished:
		return
	_register_first_action()
	if pending_mask_data.is_empty():
		lbl_status.text = "Select mask first."
		lbl_status.add_theme_color_override("font_color", Color(0.95, 0.84, 0.6))
		return
	_apply_mask_placement(pending_mask_data, "tap")

func _on_mask_dropped(mask_data: Dictionary) -> void:
	if level_finished:
		return
	_register_first_action()
	_apply_mask_placement(mask_data, "drag")

func _on_mask_bad_drop(_data: Dictionary) -> void:
	if level_finished:
		return
	_register_first_action()
	mask_drop_target.flash_bad_drop()
	last_error_code = "C_BAD_DROP"
	_play_audio("error")
	lbl_status.text = ERROR_MAP.get_error_tip("C_BAD_DROP")
	lbl_status.add_theme_color_override("font_color", Color(1.0, 0.56, 0.46))
	_log_event("mask_bad_drop", {})

func _apply_mask_placement(mask_data: Dictionary, source: String) -> void:
	var cidr_value: int = int(mask_data.get("cidr", -1))
	var mask_last_value: int = int(mask_data.get("mask_last", -1))
	if cidr_value != int(current_level.get("cidr", -2)) or mask_last_value != int(current_level.get("mask_last", -3)):
		_on_mask_bad_drop({})
		return

	mask_placed = true
	and_applied = false
	and_result_last = -1
	mask_moves_count += 1
	pending_mask_data.clear()
	mask_overlay.set_selected(false)
	_set_row_bits(row_mask_cells, mask_last_value)
	_clear_row(row_res_cells)
	row_res_line.visible = false
	ruler.reset_state()
	lock_indicator.set_ready()
	btn_apply_and.disabled = false
	_enable_answer_buttons(false)
	state = QuestState.MASK_PLACED
	_play_audio("click")
	lbl_status.text = "Mask placed. Press APPLY AND."
	lbl_status.add_theme_color_override("font_color", Color(0.72, 0.95, 0.86))
	_log_event("mask_placed", {"source": source, "mask_last": mask_last_value})

func _on_apply_and_pressed() -> void:
	if level_finished:
		return
	var now_ms: int = Time.get_ticks_msec()
	if now_ms < apply_cooldown_until_ms:
		spam_clicks += 1
		return
	apply_cooldown_until_ms = now_ms + APPLY_COOLDOWN_MS
	_register_first_action()
	if not mask_placed:
		last_error_code = "C_NOT_APPLIED"
		lbl_status.text = ERROR_MAP.get_error_tip("C_NOT_APPLIED")
		lbl_status.add_theme_color_override("font_color", Color(1.0, 0.56, 0.46))
		return

	apply_count += 1
	_play_audio("click")
	await _play_and_animation()
	and_result_last = int(current_level.get("ip_last", 0)) & int(current_level.get("mask_last", 0))
	and_applied = true
	state = QuestState.AND_APPLIED
	row_res_line.visible = true
	ruler.configure(int(current_level.get("step", 64)), int(current_level.get("ip_last", 0)))
	ruler.set_result(and_result_last)
	ruler.pulse_marker(1000)
	lock_indicator.set_applied()
	_enable_answer_buttons(true)
	lbl_status.text = "AND complete. Choose network id."
	lbl_status.add_theme_color_override("font_color", Color(0.66, 0.95, 0.74))
	_log_event("and_applied", {"result": and_result_last})

func _play_and_animation() -> void:
	var ip_bits: Array[int] = _byte_to_bits(int(current_level.get("ip_last", 0)))
	var mask_bits: Array[int] = _byte_to_bits(int(current_level.get("mask_last", 0)))
	for idx in range(mini(8, row_res_cells.size())):
		row_ip_cells[idx].pulse(Color(1.0, 1.0, 0.72, 1.0), 0.1)
		row_mask_cells[idx].pulse(Color(0.92, 0.95, 1.0, 1.0), 0.1)
		var result_bit: int = ip_bits[idx] & mask_bits[idx]
		row_res_cells[idx].set_bit(result_bit)
		row_res_cells[idx].pulse(Color(0.55, 1.0, 0.68, 1.0), 0.12)
		await get_tree().create_timer(0.035).timeout

func _on_answer_pressed(index: int) -> void:
	if level_finished or index < 0 or index >= action_buttons.size():
		return
	var now_ms: int = Time.get_ticks_msec()
	if now_ms < answer_cooldown_until_ms:
		spam_clicks += 1
		return
	answer_cooldown_until_ms = now_ms + ANSWER_COOLDOWN_MS

	if not and_applied:
		not_applied_clicks += 1
		last_error_code = "C_NOT_APPLIED"
		lbl_status.text = ERROR_MAP.get_error_tip("C_NOT_APPLIED")
		lbl_status.add_theme_color_override("font_color", Color(1.0, 0.56, 0.46))
		_log_event("answer_before_apply", {"count": not_applied_clicks})
		return

	_register_first_action()
	var btn: Button = action_buttons[index]
	selected_option_id = str(btn.get_meta("option_id", ""))
	if selected_option_id.is_empty():
		return

	_play_audio("click")
	var is_correct: bool = selected_option_id == str(current_level.get("correct_id", ""))
	var error_code: String = ""
	if not is_correct:
		error_code = str(btn.get_meta("error_code", ""))
		if error_code.is_empty():
			error_code = "UNKNOWN"
	last_error_code = error_code

	var attempt: Dictionary = {
		"option_id": selected_option_id,
		"error_code": error_code,
		"correct": is_correct,
		"t_ms": now_ms - level_started_ms
	}
	attempts.append(attempt)
	var session_attempts: Array = task_session.get("attempts", [])
	session_attempts.append(attempt)
	task_session["attempts"] = session_attempts
	_log_event("answer_selected", attempt)

	if is_correct:
		_handle_success()
	else:
		_handle_failure(error_code)

func _handle_success() -> void:
	state = QuestState.ANSWERED
	lock_indicator.set_open()
	lbl_status.text = "LOCK OPEN. %s" % str(current_level.get("explain_short", ""))
	lbl_status.add_theme_color_override("font_color", Color(0.35, 1.0, 0.48))
	_play_audio("relay")
	_finish_level(true, "success")

func _handle_failure(error_code: String) -> void:
	wrong_count += 1
	state = QuestState.ANSWERED
	lock_indicator.set_error()
	_play_audio("error")
	_trigger_glitch()

	lbl_status.text = "%s: %s" % [ERROR_MAP.get_error_title(error_code), ERROR_MAP.get_error_tip(error_code)]
	lbl_status.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	_update_meta_label()
	_log_event("answer_fail", {"error_code": error_code, "wrong_count": wrong_count})

	if wrong_count >= 1:
		btn_analyze.disabled = false
	if wrong_count >= 2 and not safe_mode_used:
		safe_mode_used = true
		state = QuestState.SAFE_MODE
		btn_analyze.text = "DIAGNOSTICS"
		lbl_status.text = "Safe mode unlocked. Open diagnostics."
		lbl_status.add_theme_color_override("font_color", Color(1.0, 0.74, 0.44))

	if wrong_count >= MAX_ATTEMPTS:
		_show_diagnostics("attempt_limit")
		_finish_level(false, "attempt_limit")
	else:
		state = QuestState.SAFE_MODE if safe_mode_used else QuestState.AND_APPLIED

func _on_analyze_pressed() -> void:
	if level_finished:
		return
	if wrong_count < 1 and not safe_mode_used:
		lbl_status.text = "Analyze unlocks after first error."
		lbl_status.add_theme_color_override("font_color", Color(0.92, 0.84, 0.58))
		return

	_register_first_action()
	analyze_count += 1
	hint_used = true
	_play_audio("click")
	_show_diagnostics("manual")
	state = QuestState.DIAGNOSTIC

func _show_diagnostics(reason: String) -> void:
	var ip_last: int = int(current_level.get("ip_last", 0))
	var mask_last: int = int(current_level.get("mask_last", 0))
	var and_value: int = ip_last & mask_last
	var step: int = int(current_level.get("step", 64))
	var network_last: int = ip_last - (ip_last % step)
	var range_end: int = mini(255, network_last + step - 1)

	var lines: Array[String] = []
	lines.append("Case: %s" % str(current_level.get("id", "")))
	lines.append("Reason: %s" % reason)
	lines.append("IP last: %d (%s)" % [ip_last, _byte_to_binary(ip_last)])
	lines.append("MASK last: %d (%s)" % [mask_last, _byte_to_binary(mask_last)])
	lines.append("AND result: %d (%s)" % [and_value, _byte_to_binary(and_value)])
	lines.append("Step: %d" % step)
	lines.append("Segment: %d..%d" % [network_last, range_end])
	lines.append("Expected network: %d" % int(current_level.get("expected_network_last", 0)))
	if not last_error_code.is_empty():
		lines.append("Last error: %s" % last_error_code)
		lines.append(ERROR_MAP.get_error_tip(last_error_code))
		for detail in ERROR_MAP.detail_messages(last_error_code):
			lines.append(detail)

	var explain_full: String = str(current_level.get("explain_full", ""))
	if not explain_full.is_empty():
		for line_var in explain_full.split("\n"):
			var line_text: String = line_var.strip_edges()
			if not line_text.is_empty():
				lines.append(line_text)

	if diagnostics_panel.has_method("setup"):
		diagnostics_panel.call("setup", "DIAGNOSTICS", lines)
	diagnostics_panel.visible = true
	_log_event("diagnostics_open", {"reason": reason})

func _on_reset_pressed() -> void:
	if level_finished:
		return
	_register_first_action()
	reset_count += 1
	mask_placed = false
	and_applied = false
	and_result_last = -1
	pending_mask_data.clear()
	mask_overlay.set_selected(false)
	_clear_row(row_mask_cells)
	_clear_row(row_res_cells)
	row_res_line.visible = false
	btn_apply_and.disabled = true
	_enable_answer_buttons(false)
	lock_indicator.set_locked()
	ruler.reset_state()
	diagnostics_panel.visible = false
	state = QuestState.BOARD_LOCKED
	_play_audio("click")
	lbl_status.text = "Board reset. Place mask and apply AND."
	lbl_status.add_theme_color_override("font_color", Color(0.82, 0.86, 0.95))
	_log_event("reset_pressed", {})

func _on_next_pressed() -> void:
	if not level_finished:
		return
	_log_event("next_pressed", {"from": str(current_level.get("id", ""))})
	_start_level(current_level_index + 1)

func _on_back_pressed() -> void:
	_play_audio("click")
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _on_palette_selected(index: int) -> void:
	_apply_palette(palette_select.get_item_id(index))

func _apply_palette(palette_id: int) -> void:
	var shader_material: ShaderMaterial = crt_overlay.material as ShaderMaterial
	if palette_id == PALETTE_AMBER_ID:
		theme = THEME_AMBER
		if shader_material != null:
			shader_material.set_shader_parameter("tint_color", Color(1.0, 0.7, 0.08, 1.0))
		if has_node("CanvasModulate"):
			var tint_amber: CanvasModulate = $CanvasModulate
			tint_amber.color = Color(1.0, 0.95, 0.9, 1.0)
	else:
		theme = THEME_GREEN
		if shader_material != null:
			shader_material.set_shader_parameter("tint_color", Color(0.0, 1.0, 0.25, 1.0))
		if has_node("CanvasModulate"):
			var tint_green: CanvasModulate = $CanvasModulate
			tint_green.color = Color(0.9, 1.0, 0.94, 1.0)

func _trigger_glitch() -> void:
	var shader_material: ShaderMaterial = crt_overlay.material as ShaderMaterial
	if shader_material == null:
		return
	shader_material.set_shader_parameter("glitch_strength", 1.0)
	var tween: Tween = create_tween()
	tween.tween_method(func(value: float) -> void: shader_material.set_shader_parameter("glitch_strength", value), 1.0, 0.0, 0.25)

func _play_audio(sound_name: String) -> void:
	if AudioManager != null:
		AudioManager.play(sound_name)

func _update_meta_label() -> void:
	var total_seconds: int = maxi(0, int(ceil(time_left_sec)))
	lbl_meta.text = "CASE %s | ERR %d/%d | T-%02d:%02d" % [
		str(current_level.get("id", "--")),
		wrong_count,
		MAX_ATTEMPTS,
		total_seconds / 60,
		total_seconds % 60
	]

func _on_stability_changed(_new_value: float, _delta: float) -> void:
	_update_meta_label()

func _register_first_action() -> void:
	if first_action_ms < 0:
		first_action_ms = Time.get_ticks_msec() - level_started_ms

func _on_timeout() -> void:
	if level_finished:
		return
	last_error_code = "TIMEOUT"
	var timeout_attempt: Dictionary = {
		"option_id": "TIMEOUT",
		"error_code": "TIMEOUT",
		"correct": false,
		"t_ms": Time.get_ticks_msec() - level_started_ms
	}
	attempts.append(timeout_attempt)
	var session_attempts: Array = task_session.get("attempts", [])
	session_attempts.append(timeout_attempt)
	task_session["attempts"] = session_attempts
	_show_diagnostics("timeout")
	_finish_level(false, "timeout")

func _finish_level(is_correct: bool, reason: String) -> void:
	if result_sent:
		return
	result_sent = true
	level_finished = true
	timer_running = false
	state = QuestState.DONE

	btn_analyze.disabled = true
	btn_apply_and.disabled = true
	btn_reset.disabled = true
	_enable_answer_buttons(false)
	btn_next.visible = true
	mask_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mask_drop_target.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var end_tick: int = Time.get_ticks_msec()
	task_session["ended_at_ticks"] = end_tick
	_log_event("task_end", {"reason": reason, "is_correct": is_correct})

	if not is_correct and reason != "timeout":
		lbl_status.text = str(current_level.get("explain_short", "Check diagnostics."))
		lbl_status.add_theme_color_override("font_color", Color(1.0, 0.62, 0.45))

	var elapsed_ms: int = end_tick - level_started_ms
	var stability_delta: float = float(wrong_count) * FAIL_STABILITY_DELTA
	if not is_correct and wrong_count == 0:
		stability_delta += FAIL_STABILITY_DELTA
	if hint_used:
		stability_delta += HINT_STABILITY_DELTA
	if spam_clicks >= 4:
		stability_delta += SPAM_STABILITY_DELTA

	var payload: Dictionary = {
		"quest": "network_trace",
		"stage": "C",
		"task_id": str(current_level.get("id", "")),
		"match_key": "NETTRACE_C|%s" % str(current_level.get("id", "")),
		"variant_hash": variant_hash,
		"target_ip": str(current_level.get("target_ip", "")),
		"cidr": int(current_level.get("cidr", 0)),
		"ip_last": int(current_level.get("ip_last", 0)),
		"mask_last": int(current_level.get("mask_last", 0)),
		"step": int(current_level.get("step", 0)),
		"expected_network_last": int(current_level.get("expected_network_last", 0)),
		"mask_placed": mask_placed,
		"and_applied": and_applied,
		"and_result_last": and_result_last,
		"board_actions": {
			"mask_moves_count": mask_moves_count,
			"apply_count": apply_count,
			"reset_count": reset_count,
			"analyze_count": analyze_count,
			"not_applied_clicks": not_applied_clicks
		},
		"attempts": attempts,
		"selected_option_id": selected_option_id,
		"is_correct": is_correct,
		"is_fit": is_correct,
		"error_code_last": "" if is_correct else last_error_code,
		"attempts_count": attempts.size(),
		"elapsed_ms": elapsed_ms,
		"duration": float(elapsed_ms) / 1000.0,
		"safe_mode_used": safe_mode_used,
		"time_to_first_action_ms": first_action_ms,
		"hint_used": hint_used,
		"timed_out": reason == "timeout",
		"spam_clicks": spam_clicks,
		"stability_delta": stability_delta,
		"task_session": task_session
	}
	GlobalMetrics.register_trial(payload)

func _enable_answer_buttons(enabled: bool) -> void:
	for btn in action_buttons:
		if btn.visible:
			btn.disabled = not enabled or level_finished

func _log_event(name: String, payload: Dictionary) -> void:
	var events: Array = task_session.get("events", [])
	events.append({
		"name": name,
		"t_ms": Time.get_ticks_msec() - level_started_ms,
		"payload": payload
	})
	task_session["events"] = events

func _build_variant_key(level: Dictionary) -> String:
	var ids: Array[String] = []
	var options_var: Variant = level.get("options", [])
	if typeof(options_var) == TYPE_ARRAY:
		var options: Array = options_var
		for option_var in options:
			if typeof(option_var) != TYPE_DICTIONARY:
				continue
			var option: Dictionary = option_var
			ids.append(str(option.get("id", "")))
	ids.sort()
	return "%s|%s|%s|%s|%s|%s" % [
		str(level.get("id", "")),
		str(level.get("target_ip", "")),
		str(level.get("cidr", 0)),
		str(level.get("ip_last", 0)),
		str(level.get("mask_last", 0)),
		",".join(ids)
	]

func _mask_last_from_cidr(cidr: int) -> int:
	var host_bits: int = 32 - cidr
	if host_bits < 0 or host_bits > 8:
		return -1
	var value: int = 256 - int(pow(2.0, float(host_bits)))
	return clampi(value, 0, 255)

func _set_row_bits(cells: Array[SubnetBitCell], octet_value: int) -> void:
	var bits: Array[int] = _byte_to_bits(octet_value)
	for idx in range(mini(cells.size(), bits.size())):
		cells[idx].set_bit(bits[idx])

func _clear_row(cells: Array[SubnetBitCell]) -> void:
	for cell in cells:
		cell.set_empty()

func _byte_to_bits(value: int) -> Array[int]:
	var safe_value: int = clampi(value, 0, 255)
	var bits: Array[int] = []
	for shift in range(7, -1, -1):
		bits.append((safe_value >> shift) & 1)
	return bits

func _byte_to_binary(value: int) -> String:
	var bits: Array[int] = _byte_to_bits(value)
	var parts: PackedStringArray = PackedStringArray()
	for bit in bits:
		parts.append(str(bit))
	return "".join(parts)

func _apply_layout_mode() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	body.vertical = viewport_size.x < viewport_size.y
