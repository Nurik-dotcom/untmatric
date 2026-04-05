extends Control

const NOIR_THEME: Theme = preload("res://ui/theme_noir_detective.tres")
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

enum QuestState { INIT, BOARD_LOCKED, MASK_PLACED, AND_APPLIED, ANSWERED, SAFE_MODE, DIAGNOSTIC, DONE }

@onready var btn_back: Button = $SafeArea/Main/V/Header/BtnBack
@onready var safe_area: MarginContainer = $SafeArea
@onready var lbl_title: Label = $SafeArea/Main/V/Header/LblTitle
@onready var lbl_meta: Label = $SafeArea/Main/V/Header/LblMeta
@onready var palette_select: OptionButton = $SafeArea/Main/V/Header/PaletteSelect
@onready var body: BoxContainer = $SafeArea/Main/V/Body
@onready var terminal_pane: PanelContainer = $SafeArea/Main/V/Body/TerminalPane
@onready var board_pane: PanelContainer = $SafeArea/Main/V/Body/BoardPane
@onready var answers_pane: PanelContainer = $SafeArea/Main/V/Body/AnswersPane
@onready var lbl_briefing: RichTextLabel = $SafeArea/Main/V/Body/TerminalPane/TerminalMargin/TerminalV/LblBriefing
@onready var lbl_prompt: RichTextLabel = $SafeArea/Main/V/Body/TerminalPane/TerminalMargin/TerminalV/LblPrompt
@onready var lbl_target_ip: Label = $SafeArea/Main/V/Body/TerminalPane/TerminalMargin/TerminalV/TargetBox/LblTargetIp
@onready var lbl_target_cidr: Label = $SafeArea/Main/V/Body/TerminalPane/TerminalMargin/TerminalV/TargetBox/LblTargetCidr
@onready var lbl_target_ask: Label = $SafeArea/Main/V/Body/TerminalPane/TerminalMargin/TerminalV/TargetBox/LblTargetAsk
@onready var log_text: RichTextLabel = $SafeArea/Main/V/Body/TerminalPane/TerminalMargin/TerminalV/LogScroll/LogText
@onready var lock_indicator: NetworkLockIndicator = $SafeArea/Main/V/Body/BoardPane/BoardMargin/BoardV/LockIndicator
@onready var row_ip: HBoxContainer = $SafeArea/Main/V/Body/BoardPane/BoardMargin/BoardV/BitBoard/RowIpLine/RowIp
@onready var row_mask: HBoxContainer = $SafeArea/Main/V/Body/BoardPane/BoardMargin/BoardV/BitBoard/RowMaskLine/MaskDropTarget/RowMask
@onready var mask_drop_target: SubnetMaskDropTarget = $SafeArea/Main/V/Body/BoardPane/BoardMargin/BoardV/BitBoard/RowMaskLine/MaskDropTarget
@onready var row_res_line: HBoxContainer = $SafeArea/Main/V/Body/BoardPane/BoardMargin/BoardV/BitBoard/RowResLine
@onready var row_res: HBoxContainer = $SafeArea/Main/V/Body/BoardPane/BoardMargin/BoardV/BitBoard/RowResLine/RowRes
@onready var lbl_row_mask: Label = $SafeArea/Main/V/Body/BoardPane/BoardMargin/BoardV/BitBoard/RowMaskLine/LblRowMask
@onready var lbl_row_res: Label = $SafeArea/Main/V/Body/BoardPane/BoardMargin/BoardV/BitBoard/RowResLine/LblRowRes
@onready var lbl_mask_tray: Label = $SafeArea/Main/V/Body/BoardPane/BoardMargin/BoardV/MaskTray/LblMaskTray
@onready var mask_overlay: SubnetMaskOverlay = $SafeArea/Main/V/Body/BoardPane/BoardMargin/BoardV/MaskTray/MaskOverlay
@onready var ruler: SubnetRulerControl = $SafeArea/Main/V/Body/BoardPane/BoardMargin/BoardV/Ruler
@onready var btn_analyze: Button = $SafeArea/Main/V/Body/BoardPane/BoardMargin/BoardV/BoardActions/BtnAnalyze
@onready var btn_apply_and: Button = $SafeArea/Main/V/Body/BoardPane/BoardMargin/BoardV/BoardActions/BtnApplyAnd
@onready var btn_reset: Button = $SafeArea/Main/V/Body/BoardPane/BoardMargin/BoardV/BoardActions/BtnReset
@onready var lbl_status: Label = $SafeArea/Main/V/Body/AnswersPane/AnswersMargin/AnswersV/LblStatus
@onready var btn_next: Button = $SafeArea/Main/V/Body/AnswersPane/AnswersMargin/AnswersV/BottomRow/BtnNext
@onready var options_grid: GridContainer = $SafeArea/Main/V/Body/AnswersPane/AnswersMargin/AnswersV/OptionsGrid
@onready var diagnostics_panel: PanelContainer = $DiagnosticsPanel
@onready var crt_overlay: ColorRect = $NoirOverlay/CRT_Overlay

@onready var action_buttons: Array[Button] = [
	$SafeArea/Main/V/Body/AnswersPane/AnswersMargin/AnswersV/OptionsGrid/ActionBtn1,
	$SafeArea/Main/V/Body/AnswersPane/AnswersMargin/AnswersV/OptionsGrid/ActionBtn2,
	$SafeArea/Main/V/Body/AnswersPane/AnswersMargin/AnswersV/OptionsGrid/ActionBtn3,
	$SafeArea/Main/V/Body/AnswersPane/AnswersMargin/AnswersV/OptionsGrid/ActionBtn4,
	$SafeArea/Main/V/Body/AnswersPane/AnswersMargin/AnswersV/OptionsGrid/ActionBtn5,
	$SafeArea/Main/V/Body/AnswersPane/AnswersMargin/AnswersV/OptionsGrid/ActionBtn6
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
var level_mode: String = "EXAM"
var level_mask_editable: bool = false
var trial_seq: int = 0

var mask_select_count: int = 0
var mask_place_count: int = 0
var mask_replace_count: int = 0
var apply_and_count: int = 0
var answer_select_count: int = 0
var board_reset_count: int = 0

var bit_toggle_count: int = 0
var bit_diff_seen_count: int = 0
var cidr_fixed_mode: bool = false

var diagnostics_open_count: int = 0
var safe_mode_open_count: int = 0
var changed_after_bit_diff: bool = false
var changed_after_safe_mode: bool = false

var time_to_first_mask_ms: int = -1
var time_to_first_apply_ms: int = -1
var time_to_first_answer_ms: int = -1
var time_from_mask_to_apply_ms: int = -1
var time_from_apply_to_answer_ms: int = -1

var last_mask_edit_ms: int = -1
var last_apply_ms: int = -1
var selected_mask_value: int = -1

var _pending_change_after_bit_diff: bool = false
var _pending_change_after_safe_mode: bool = false

func _ready() -> void:
	_setup_runtime_controls()
	_connect_signals()
	_apply_noir_theme()
	_apply_safe_area_padding()
	_apply_layout_mode()
	_build_bit_rows()

	if GlobalMetrics != null and not GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.connect(_on_stability_changed)

	if not I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.connect(_on_language_changed)
	_apply_i18n()

	if not _load_levels():
		_show_boot_error(_tr("nt.c.ui.boot_error", "Failed to load Network Trace C levels."))
		return

	_start_level(0)

func _exit_tree() -> void:
	if GlobalMetrics != null and GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.disconnect(_on_stability_changed)
	if I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.disconnect(_on_language_changed)

func _tr(key: String, default_text: String, params: Dictionary = {}) -> String:
	var merged: Dictionary = params.duplicate(true)
	merged["default"] = default_text
	return I18n.tr_key(key, merged)

func _on_language_changed(_code: String) -> void:
	_apply_i18n()

func _apply_i18n() -> void:
	btn_back.text = _tr("nt.common.back", "BACK")
	btn_apply_and.text = _tr("nt.c.ui.btn_apply_and", "IP \u2227 \u041c\u0410\u0421\u041a\u0410")
	btn_reset.text = _tr("nt.common.reset", "RESET")
	btn_next.text = _tr("nt.common.next", "NEXT")
	btn_analyze.text = _tr("nt.common.analyze", "Diagnostics")
	lbl_row_mask.text = _tr("nt.c.ui.lbl_row_mask", "MASK")
	lbl_row_res.text = _tr("nt.c.ui.lbl_row_res", "RESULT")
	lbl_mask_tray.text = _tr("nt.c.ui.lbl_mask_tray", "MASK SELECTION")
	lbl_title.text = _tr("nt.c.ui.title", "NETWORK TRACE | C")
	if current_level != null and not current_level.is_empty():
		_refresh_level_ui_i18n()

func _refresh_level_ui_i18n() -> void:
	_render_terminal()
	_update_meta_label()

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
		_apply_safe_area_padding()
		_apply_layout_mode()

func _setup_runtime_controls() -> void:
	palette_select.visible = false
	palette_select.disabled = true
	palette_select.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn_next.visible = false
	btn_analyze.disabled = true
	btn_apply_and.disabled = true
	diagnostics_panel.visible = false

func _connect_signals() -> void:
	btn_back.pressed.connect(_on_back_pressed)
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
	if level.has("mode"):
		var mode: String = str(level.get("mode", "EXAM")).to_upper()
		if mode != "TRAIN" and mode != "EXAM":
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
	trial_seq += 1
	if index >= levels.size():
		index = 0

	current_level_index = index
	current_level = levels[index].duplicate(true)
	variant_hash = str(hash(_build_variant_key(current_level)))
	level_mode = str(current_level.get("mode", "EXAM")).to_upper()
	level_mask_editable = bool(current_level.get("mask_editable", level_mode == "TRAIN"))
	cidr_fixed_mode = not level_mask_editable

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
	mask_select_count = 0
	mask_place_count = 0
	mask_replace_count = 0
	apply_and_count = 0
	answer_select_count = 0
	board_reset_count = 0
	bit_toggle_count = 0
	bit_diff_seen_count = 0
	diagnostics_open_count = 0
	safe_mode_open_count = 0
	changed_after_bit_diff = false
	changed_after_safe_mode = false
	time_to_first_mask_ms = -1
	time_to_first_apply_ms = -1
	time_to_first_answer_ms = -1
	time_from_mask_to_apply_ms = -1
	time_from_apply_to_answer_ms = -1
	last_mask_edit_ms = -1
	last_apply_ms = -1
	selected_mask_value = -1
	_pending_change_after_bit_diff = false
	_pending_change_after_safe_mode = false

	task_session = {
		"trial_seq": trial_seq,
		"task_id": str(current_level.get("id", "NT_C_UNKNOWN")),
		"variant_hash": variant_hash,
		"started_at_ticks": level_started_ms,
		"ended_at_ticks": 0,
		"attempts": [],
		"events": []
	}

	mask_overlay.setup(int(current_level.get("cidr", 26)), int(current_level.get("mask_last", 192)))
	mask_overlay.set_selected(false)
	mask_overlay.mouse_filter = Control.MOUSE_FILTER_STOP if level_mask_editable else Control.MOUSE_FILTER_IGNORE
	mask_drop_target.mouse_filter = Control.MOUSE_FILTER_STOP if level_mask_editable else Control.MOUSE_FILTER_IGNORE
	lock_indicator.set_locked()
	ruler.configure(int(current_level.get("step", 64)), int(current_level.get("ip_last", 0)))
	ruler.reset_state()
	row_res_line.visible = false

	_set_row_bits(row_ip_cells, int(current_level.get("ip_last", 0)))
	if level_mask_editable:
		_clear_row(row_mask_cells)
	else:
		_set_row_bits(row_mask_cells, int(current_level.get("mask_last", 0)))
		mask_placed = true
		selected_mask_value = int(current_level.get("mask_last", 0))
		last_mask_edit_ms = 0
	_clear_row(row_res_cells)

	btn_next.visible = false
	btn_analyze.disabled = true
	btn_analyze.text = _tr("nt.common.analyze", "Diagnostics")
	btn_apply_and.disabled = true
	diagnostics_panel.visible = false

	_render_terminal()
	_render_options()
	_enable_answer_buttons(false)

	state = QuestState.BOARD_LOCKED
	lbl_status.text = _tr("nt.c.ui.status_place_mask", "Place mask, apply AND, then select network ID.")
	lbl_status.add_theme_color_override("font_color", Color(0.82, 0.84, 0.82))
	if not level_mask_editable:
		state = QuestState.MASK_PLACED
		btn_apply_and.disabled = false
		lock_indicator.set_ready()
		lbl_status.text = _tr("nt.c.ui.status_mask_cidr", "Mask is CIDR-preset. Press APPLY AND.")
		lbl_status.add_theme_color_override("font_color", Color(0.72, 0.9, 0.82))
	_update_meta_label()
	_log_event("trial_started", {
		"level_id": str(current_level.get("id", "")),
		"target_ip": str(current_level.get("target_ip", "")),
		"target_cidr": int(current_level.get("cidr", 0)),
		"cidr_fixed_mode": cidr_fixed_mode
	})
	_log_event("task_start", {"level": str(current_level.get("id", ""))})

func _render_terminal() -> void:
	var level_id: String = str(current_level.get("id", ""))
	lbl_briefing.clear()
	lbl_briefing.append_text("[color=#7a7a7a]%s[/color]\n%s" % [
		_tr("nt.a.ui.lbl_objective", "OBJECTIVE"),
		_tr("nt.c.level.%s.briefing" % level_id, str(current_level.get("briefing", "")))
	])
	lbl_briefing.append_text(_tr("nt.c.step_guide",
		"\n\n[color=#8888aa]Шаги:[/color]\n" +
		"[color=#aaaacc]1. Маска выставлена по CIDR — проверьте биты[/color]\n" +
		"[color=#aaaacc]2. Нажмите «IP ∧ МАСКА» для побитового AND[/color]\n" +
		"[color=#aaaacc]3. Результат = идентификатор сети[/color]\n" +
		"[color=#aaaacc]4. Выберите правильный вариант из кандидатов[/color]"
	))
	lbl_prompt.clear()
	lbl_prompt.append_text("[color=#9de6b3]%s[/color]\n%s" % [
		_tr("nt.a.ui.lbl_task", "TASK"),
		_tr("nt.c.level.%s.prompt" % level_id, str(current_level.get("prompt", "")))
	])
	lbl_target_ip.text = _tr("nt.c.ui.lbl_target_ip", "IP: {value}", {"value": str(current_level.get("target_ip", "--"))})
	lbl_target_cidr.text = _tr("nt.c.ui.lbl_target_cidr", "CIDR: /{value}", {"value": int(current_level.get("cidr", 0))})
	lbl_target_ask.text = _tr("nt.c.ui.lbl_target_ask", "CANDIDATES: Network ID (last octet)")

	var lines: Array[String] = []
	lines.append(_tr("nt.c.ui.log_network_id", "Network ID — segment start. A segment is a range of addresses."))
	lines.append("IP: %s" % str(current_level.get("target_ip", "--")))
	lines.append("CIDR: /%d" % int(current_level.get("cidr", 0)))
	lines.append(_tr("nt.c.ui.log_apply_hint", "First press APPLY AND, then select the network ID."))
	lines.append(_tr("nt.c.ui.log_step", "Step: {value}", {"value": int(current_level.get("step", 0))}))
	var expected_last: int = int(current_level.get("expected_network_last", 0))
	lines.append(_tr("nt.c.ui.log_segment_end", "Expected segment ends at .{value}", {
		"value": mini(255, expected_last + int(current_level.get("step", 0)) - 1)
	}))

	var text_value: String = ""
	for line in lines:
		text_value += "- %s\n" % line
	log_text.text = text_value.strip_edges()
	_sync_terminal_text_heights(_current_layout_mode())

func _render_options() -> void:
	var options_var: Variant = current_level.get("options", [])
	if typeof(options_var) != TYPE_ARRAY:
		return
	var options: Array = options_var
	var level_id: String = str(current_level.get("id", ""))
	for idx in range(action_buttons.size()):
		var btn: Button = action_buttons[idx]
		if idx < options.size():
			var option_var: Variant = options[idx]
			if typeof(option_var) != TYPE_DICTIONARY:
				btn.visible = false
				btn.disabled = true
				continue
			var option: Dictionary = option_var
			var opt_id: String = str(option.get("id", ""))
			btn.visible = true
			btn.text = _tr("nt.c.level.%s.option.%s.label" % [level_id, opt_id], str(option.get("label", "")))
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
	if not level_mask_editable:
		return
	_register_first_action()
	mask_select_count += 1
	if time_to_first_mask_ms < 0:
		time_to_first_mask_ms = _elapsed_ms_now()
	last_mask_edit_ms = _elapsed_ms_now()
	pending_mask_data = mask_data.duplicate(true)
	mask_overlay.set_selected(sender == mask_overlay)
	_play_audio("click")
	lbl_status.text = _tr("nt.c.ui.status_mask_selected", "Mask selected. Place it in the target area.")
	lbl_status.add_theme_color_override("font_color", Color(0.82, 0.9, 1.0))
	_log_event("mask_selected", {"cidr": int(mask_data.get("cidr", 0))})

func _on_mask_drag_started(mask_data: Dictionary) -> void:
	if level_finished:
		return
	if not level_mask_editable:
		return
	_register_first_action()
	last_mask_edit_ms = _elapsed_ms_now()
	pending_mask_data = mask_data.duplicate(true)
	mask_overlay.set_selected(false)
	_log_event("mask_drag_started", {"cidr": int(mask_data.get("cidr", 0))})

func _on_mask_target_tapped() -> void:
	if level_finished:
		return
	if not level_mask_editable:
		return
	_register_first_action()
	if pending_mask_data.is_empty():
		lbl_status.text = _tr("nt.c.ui.status_select_mask_first", "Select a mask first.")
		lbl_status.add_theme_color_override("font_color", Color(0.95, 0.84, 0.6))
		return
	_apply_mask_placement(pending_mask_data, "tap")

func _on_mask_dropped(mask_data: Dictionary) -> void:
	if level_finished:
		return
	if not level_mask_editable:
		return
	_register_first_action()
	_apply_mask_placement(mask_data, "drag")

func _on_mask_bad_drop(_data: Dictionary) -> void:
	if level_finished:
		return
	if not level_mask_editable:
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

	var had_mask_before: bool = mask_placed
	var previous_mask_value: int = selected_mask_value
	mask_placed = true
	and_applied = false
	and_result_last = -1
	mask_moves_count += 1
	if had_mask_before:
		mask_replace_count += 1
	else:
		mask_place_count += 1
	if time_to_first_mask_ms < 0:
		time_to_first_mask_ms = _elapsed_ms_now()
	last_mask_edit_ms = _elapsed_ms_now()
	if had_mask_before and previous_mask_value >= 0:
		bit_toggle_count += _count_bit_flips(previous_mask_value, mask_last_value)
	selected_mask_value = mask_last_value
	_mark_post_feedback_adjustment("mask_placed")
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
	lbl_status.text = _tr("nt.c.ui.status_mask_placed", "Mask placed. Press APPLY AND.")
	lbl_status.add_theme_color_override("font_color", Color(0.72, 0.95, 0.86))
	_log_event("mask_placed", {
		"source": source,
		"mask_last": mask_last_value,
		"replaced": had_mask_before
	})

func _on_apply_and_pressed() -> void:
	if level_finished:
		return
	var now_ms: int = Time.get_ticks_msec()
	apply_and_count += 1
	if time_to_first_apply_ms < 0:
		time_to_first_apply_ms = _elapsed_ms_now()
	time_from_mask_to_apply_ms = -1 if last_mask_edit_ms < 0 else maxi(0, _elapsed_ms_now() - last_mask_edit_ms)
	last_apply_ms = _elapsed_ms_now()
	_log_event("apply_and_pressed", {
		"mask_placed": mask_placed,
		"time_from_mask_to_apply_ms": time_from_mask_to_apply_ms
	})
	if now_ms < apply_cooldown_until_ms:
		spam_clicks += 1
		return
	apply_cooldown_until_ms = now_ms + APPLY_COOLDOWN_MS
	_register_first_action()
	if not mask_placed:
		last_error_code = "C_NOT_APPLIED"
		lbl_status.text = ERROR_MAP.get_error_tip("C_NOT_APPLIED")
		lbl_status.add_theme_color_override("font_color", Color(1.0, 0.56, 0.46))
		_log_event("and_result", {
			"mask_value": selected_mask_value,
			"ip_bits": _byte_to_binary(int(current_level.get("ip_last", 0))),
			"result_bits": "",
			"candidate_count": int(current_level.get("options", []).size()),
			"error_code": "C_NOT_APPLIED"
		})
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
	lbl_status.text = _tr("nt.c.ui.status_and_done", "AND done. Now select the network ID.")
	lbl_status.add_theme_color_override("font_color", Color(0.66, 0.95, 0.74))
	_log_event("and_applied", {"result": and_result_last})
	_log_event("and_result", {
		"mask_value": int(current_level.get("mask_last", 0)),
		"ip_bits": _byte_to_binary(int(current_level.get("ip_last", 0))),
		"result_bits": _byte_to_binary(and_result_last),
		"candidate_count": int(current_level.get("options", []).size()),
		"error_code": ""
	})

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
	var previous_option_id: String = selected_option_id
	selected_option_id = str(btn.get_meta("option_id", ""))
	if selected_option_id.is_empty():
		return
	answer_select_count += 1
	if time_to_first_answer_ms < 0:
		time_to_first_answer_ms = _elapsed_ms_now()
	time_from_apply_to_answer_ms = -1 if last_apply_ms < 0 else maxi(0, _elapsed_ms_now() - last_apply_ms)
	if previous_option_id != selected_option_id:
		_mark_post_feedback_adjustment("answer_changed")

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
	_log_event("network_id_selected", {
		"answer_id": selected_option_id,
		"time_from_apply_to_answer_ms": time_from_apply_to_answer_ms
	})

	if is_correct:
		_handle_success()
	else:
		_handle_failure(error_code)

func _handle_success() -> void:
	state = QuestState.ANSWERED
	lock_indicator.set_open()
	var level_id: String = str(current_level.get("id", ""))
	lbl_status.text = _tr("nt.c.ui.status_network_confirmed", "Network ID confirmed. {result}", {
		"result": _tr("nt.c.level.%s.explain_short" % level_id, str(current_level.get("explain_short", "")))
	})
	lbl_status.add_theme_color_override("font_color", Color(0.35, 1.0, 0.48))
	_play_audio("relay")
	_finish_level(true, "success")

func _handle_failure(error_code: String) -> void:
	wrong_count += 1
	state = QuestState.ANSWERED
	lock_indicator.set_error()
	_play_audio("error")
	_trigger_glitch()

	var status_line: String = "%s: %s" % [ERROR_MAP.get_error_title(error_code), ERROR_MAP.get_error_tip(error_code)]
	var selected_last: int = int(selected_option_id) if selected_option_id.is_valid_int() else -1
	var expected_last: int = int(current_level.get("expected_network_last", -1))
	if selected_last >= 0 and expected_last >= 0:
		var diff_bit: int = _first_diff_bit(expected_last, selected_last)
		if diff_bit >= 0:
			bit_diff_seen_count += 1
			_pending_change_after_bit_diff = true
			status_line += _tr("nt.c.ui.status_bit_diff", "DIFFERENCE DETECTED: BIT {bit}.", {"bit": diff_bit})
			_log_event("bit_difference_shown", {"bit": diff_bit, "expected_last": expected_last, "selected_last": selected_last})
	lbl_status.text = status_line
	lbl_status.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	_update_meta_label()
	_log_event("answer_fail", {"error_code": error_code, "wrong_count": wrong_count})

	if wrong_count >= 1:
		btn_analyze.disabled = false
	if wrong_count >= 2 and not safe_mode_used:
		safe_mode_used = true
		_pending_change_after_safe_mode = true
		state = QuestState.SAFE_MODE
		btn_analyze.text = _tr("nt.common.safe_mode", "Safe Diagnostics")
		lbl_status.text = _tr("nt.c.ui.status_safe_unlocked", "Safe mode unlocked. Open diagnostics for guided review.")
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
		lbl_status.text = _tr("nt.c.ui.status_safe_locked", "Diagnostics unlocks after first wrong answer.")
		lbl_status.add_theme_color_override("font_color", Color(0.92, 0.84, 0.58))
		return

	_register_first_action()
	analyze_count += 1
	hint_used = true
	_play_audio("click")
	_show_diagnostics("manual")
	state = QuestState.DIAGNOSTIC

func _show_diagnostics(reason: String) -> void:
	diagnostics_open_count += 1
	if safe_mode_used:
		safe_mode_open_count += 1
		_pending_change_after_safe_mode = true
	var ip_last: int = int(current_level.get("ip_last", 0))
	var mask_last: int = int(current_level.get("mask_last", 0))
	var and_value: int = ip_last & mask_last
	var step: int = int(current_level.get("step", 64))
	var network_last: int = ip_last - (ip_last % step)
	var range_end: int = mini(255, network_last + step - 1)

	var lines: Array[String] = []
	lines.append(_tr("nt.c.log.level", "Level: {id}", {"id": str(current_level.get("id", ""))}))
	lines.append(_tr("nt.c.log.reason", "Reason: {reason}", {"reason": reason}))
	lines.append(_tr("nt.c.log.ip_last", "Last IP: {dec} ({bin})", {"dec": ip_last, "bin": _byte_to_binary(ip_last)}))
	lines.append(_tr("nt.c.log.mask_last", "Last MASK: {dec} ({bin})", {"dec": mask_last, "bin": _byte_to_binary(mask_last)}))
	lines.append(_tr("nt.c.log.and_result", "AND RESULT: {dec} ({bin})", {"dec": and_value, "bin": _byte_to_binary(and_value)}))
	lines.append(_tr("nt.c.log.step", "Step: {value}", {"value": step}))
	lines.append(_tr("nt.c.log.segment", "SEGMENT: {start}..{end}", {"start": network_last, "end": range_end}))
	lines.append(_tr("nt.c.log.expected_network", "Expected network identifier: {value}", {"value": int(current_level.get("expected_network_last", 0))}))
	if not last_error_code.is_empty():
		lines.append(_tr("nt.c.log.last_error", "Last error: {code}", {"code": last_error_code}))
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
		diagnostics_panel.call("setup", {
			"mode": "text_only",
			"title": _tr("nt.common.safe_mode", "Safe Diagnostics"),
			"reasoning_lines": lines
		})
	diagnostics_panel.visible = true
	_log_event("diagnostics_open", {"reason": reason})

func _on_reset_pressed() -> void:
	if level_finished:
		return
	_register_first_action()
	reset_count += 1
	board_reset_count += 1
	mask_placed = not level_mask_editable
	and_applied = false
	and_result_last = -1
	pending_mask_data.clear()
	selected_mask_value = -1
	last_apply_ms = -1
	time_from_apply_to_answer_ms = -1
	mask_overlay.set_selected(false)
	if level_mask_editable:
		_clear_row(row_mask_cells)
		last_mask_edit_ms = -1
	else:
		_set_row_bits(row_mask_cells, int(current_level.get("mask_last", 0)))
		selected_mask_value = int(current_level.get("mask_last", 0))
		last_mask_edit_ms = 0
	_clear_row(row_res_cells)
	row_res_line.visible = false
	btn_apply_and.disabled = level_mask_editable
	_enable_answer_buttons(false)
	if level_mask_editable:
		lock_indicator.set_locked()
	else:
		lock_indicator.set_ready()
	ruler.reset_state()
	diagnostics_panel.visible = false
	state = QuestState.BOARD_LOCKED if level_mask_editable else QuestState.MASK_PLACED
	_play_audio("click")
	if level_mask_editable:
		lbl_status.text = _tr("nt.c.ui.status_board_reset", "Board reset. Place mask again.")
	else:
		lbl_status.text = _tr("nt.c.ui.status_board_reset_cidr", "Board reset. Mask is CIDR-fixed, press APPLY AND.")
	lbl_status.add_theme_color_override("font_color", Color(0.82, 0.86, 0.95))
	_mark_post_feedback_adjustment("board_reset")
	_log_event("board_reset", {"cidr_fixed_mode": cidr_fixed_mode})
	_log_event("reset_pressed", {})

func _on_next_pressed() -> void:
	if not level_finished:
		return
	_log_event("next_pressed", {"from": str(current_level.get("id", ""))})
	_start_level(current_level_index + 1)

func _on_back_pressed() -> void:
	_play_audio("click")
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _apply_noir_theme() -> void:
	theme = NOIR_THEME
	var shader_material: ShaderMaterial = crt_overlay.material as ShaderMaterial
	if shader_material != null:
		shader_material.set_shader_parameter("tint_color", Color(0.93, 0.93, 0.93, 1.0))
		shader_material.set_shader_parameter("intensity", 0.18)
	if has_node("CanvasModulate"):
		var neutral_tint: CanvasModulate = $CanvasModulate
		neutral_tint.color = Color(1.0, 1.0, 1.0, 1.0)

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
	lbl_meta.text = _tr("nt.common.meta", "CASE {cur}/{total} | FAIL {fails}/{max} | {min}:{sec}", {
		"cur": current_level_index + 1,
		"total": levels.size(),
		"fails": wrong_count,
		"max": MAX_ATTEMPTS,
		"min": "%02d" % int(total_seconds / 60.0),
		"sec": "%02d" % (total_seconds % 60)
	})

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
		var level_id: String = str(current_level.get("id", ""))
		lbl_status.text = _tr("nt.c.level.%s.explain_short" % level_id, str(current_level.get("explain_short", _tr("nt.c.ui.status_fallback", "Review AND result and segment boundaries."))))
		lbl_status.add_theme_color_override("font_color", Color(1.0, 0.62, 0.45))

	var elapsed_ms: int = end_tick - level_started_ms
	var stability_delta: float = float(wrong_count) * FAIL_STABILITY_DELTA
	if not is_correct and wrong_count == 0:
		stability_delta += FAIL_STABILITY_DELTA
	if hint_used:
		stability_delta += HINT_STABILITY_DELTA
	if spam_clicks >= 4:
		stability_delta += SPAM_STABILITY_DELTA
	var outcome_code: String = _outcome_code_for_c(is_correct, reason)
	var mastery_block_reason: String = _mastery_block_reason_for_c(is_correct, outcome_code)
	var viewport_size: Vector2 = get_viewport_rect().size
	var layout_mode: String = "portrait" if viewport_size.x < viewport_size.y else "landscape"
	var and_result_payload: Dictionary = {
		"value": and_result_last,
		"ip_bits": _byte_to_binary(int(current_level.get("ip_last", 0))),
		"mask_bits": _byte_to_binary(int(current_level.get("mask_last", 0))),
		"result_bits": _byte_to_binary(and_result_last if and_result_last >= 0 else 0)
	}

	var payload: Dictionary = {
		"quest": "network_trace",
		"quest_id": "NETWORK_TRACE",
		"stage": "C",
		"task_id": str(current_level.get("id", "")),
		"match_key": "NETTRACE_C|%s" % str(current_level.get("id", "")),
		"variant_hash": variant_hash,
		"target_ip": str(current_level.get("target_ip", "")),
		"mode": level_mode,
		"trial_seq": trial_seq,
		"outcome_code": outcome_code,
		"mastery_block_reason": mastery_block_reason,
		"error_code": "" if is_correct else last_error_code,
		"mask_editable": level_mask_editable,
		"cidr": int(current_level.get("cidr", 0)),
		"ip_last": int(current_level.get("ip_last", 0)),
		"mask_last": int(current_level.get("mask_last", 0)),
		"step": int(current_level.get("step", 0)),
		"expected_network_last": int(current_level.get("expected_network_last", 0)),
		"mask_placed": mask_placed,
		"and_applied": and_applied,
		"and_result_last": and_result_last,
		"mask_select_count": mask_select_count,
		"mask_place_count": mask_place_count,
		"mask_replace_count": mask_replace_count,
		"apply_and_count": apply_and_count,
		"answer_select_count": answer_select_count,
		"board_reset_count": board_reset_count,
		"bit_toggle_count": bit_toggle_count,
		"bit_diff_seen_count": bit_diff_seen_count,
		"cidr_fixed_mode": cidr_fixed_mode,
		"diagnostics_open_count": diagnostics_open_count,
		"safe_mode_open_count": safe_mode_open_count,
		"changed_after_bit_diff": changed_after_bit_diff,
		"changed_after_safe_mode": changed_after_safe_mode,
		"time_to_first_mask_ms": time_to_first_mask_ms,
		"time_to_first_apply_ms": time_to_first_apply_ms,
		"time_to_first_answer_ms": time_to_first_answer_ms,
		"time_from_mask_to_apply_ms": time_from_mask_to_apply_ms,
		"time_from_apply_to_answer_ms": time_from_apply_to_answer_ms,
		"selected_mask": selected_mask_value,
		"and_result": and_result_payload,
		"selected_network_id": selected_option_id,
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
		"safe_mode": safe_mode_used,
		"safe_mode_used": safe_mode_used,
		"time_to_first_action_ms": first_action_ms,
		"hint_used": hint_used,
		"timed_out": reason == "timeout",
		"spam_clicks": spam_clicks,
		"stability_delta": stability_delta,
		"layout": layout_mode,
		"ui_vw": int(viewport_size.x),
		"ui_vh": int(viewport_size.y),
		"task_session": task_session
	}
	GlobalMetrics.register_trial(payload)

func _enable_answer_buttons(enabled: bool) -> void:
	for btn in action_buttons:
		if btn.visible:
			btn.disabled = not enabled or level_finished

func _outcome_code_for_c(is_correct: bool, finish_reason: String) -> String:
	if is_correct:
		return "SUCCESS"
	if finish_reason == "timeout" or last_error_code == "TIMEOUT":
		return "TIMEOUT"
	if safe_mode_used and not is_correct and finish_reason == "attempt_limit":
		return "SAFE_MODE"
	if not mask_placed:
		return "MASK_NOT_PLACED"
	if not and_applied or last_error_code == "C_NOT_APPLIED":
		return "AND_NOT_APPLIED"
	if bit_diff_seen_count > 0 and not is_correct:
		return "BIT_DIFF_MISMATCH"
	return "WRONG_NETWORK_ID"

func _mastery_block_reason_for_c(is_correct: bool, outcome_code: String) -> String:
	if outcome_code == "SAFE_MODE":
		return "SAFE_MODE_TRIGGERED"
	if board_reset_count >= 3:
		return "RESET_OVERUSE"
	if answer_select_count >= 3:
		return "MULTI_ANSWER_GUESSING"
	if outcome_code == "AND_NOT_APPLIED":
		return "AND_STEP_SKIPPED"
	if bit_diff_seen_count > 0 and not changed_after_bit_diff:
		return "BIT_DIFF_IGNORED"
	if mask_replace_count > 0 or mask_select_count >= 3:
		return "MASK_SELECTION_UNSTABLE"
	if not is_correct:
		return "MASK_SELECTION_UNSTABLE"
	return "NONE"

func _mark_post_feedback_adjustment(_source: String) -> void:
	if _pending_change_after_bit_diff:
		changed_after_bit_diff = true
		_pending_change_after_bit_diff = false
	if _pending_change_after_safe_mode:
		changed_after_safe_mode = true
		_pending_change_after_safe_mode = false

func _elapsed_ms_now() -> int:
	if level_started_ms <= 0:
		return 0
	return maxi(0, Time.get_ticks_msec() - level_started_ms)

func _log_event(event_name: String, payload: Dictionary = {}) -> void:
	if task_session.is_empty():
		return
	var events: Array = task_session.get("events", [])
	events.append({
		"name": event_name,
		"t_ms": _elapsed_ms_now(),
		"payload": payload.duplicate(true)
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

func _count_bit_flips(previous_value: int, next_value: int) -> int:
	var diff: int = clampi(previous_value, 0, 255) ^ clampi(next_value, 0, 255)
	var count: int = 0
	for _bit in range(8):
		count += diff & 1
		diff >>= 1
	return count

func _first_diff_bit(expected_value: int, selected_value: int) -> int:
	var diff: int = clampi(expected_value, 0, 255) ^ clampi(selected_value, 0, 255)
	if diff == 0:
		return -1
	for shift in range(7, -1, -1):
		if ((diff >> shift) & 1) == 1:
			return shift
	return -1

func _byte_to_binary(value: int) -> String:
	var bits: Array[int] = _byte_to_bits(value)
	var parts: PackedStringArray = PackedStringArray()
	for bit in bits:
		parts.append(str(bit))
	return "".join(parts)

func _current_layout_mode() -> String:
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x < viewport_size.y:
		return "portrait"
	if viewport_size.y <= 900.0 or viewport_size.x <= 1440.0:
		return "landscape_dense"
	return "landscape_standard"

func _sync_terminal_text_heights(mode: String) -> void:
	lbl_briefing.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var viewport_size: Vector2 = get_viewport_rect().size
	var briefing_height: float = clampf(float(lbl_briefing.get_content_height()) + 12.0, 96.0, viewport_size.y * 0.28)
	var prompt_height: float = clampf(float(lbl_prompt.get_content_height()) + 12.0, 108.0, viewport_size.y * 0.34)
	if mode == "portrait":
		briefing_height = maxf(briefing_height, 96.0)
		prompt_height = maxf(prompt_height, 108.0)
	lbl_briefing.custom_minimum_size.y = briefing_height
	lbl_prompt.custom_minimum_size.y = prompt_height

func _apply_safe_area_padding() -> void:
	if safe_area == null:
		return
	var left: float = 8.0
	var top: float = 44.0
	var right: float = 8.0
	var bottom: float = 8.0
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

func _apply_layout_mode() -> void:
	_apply_safe_area_padding()
	var mode: String = _current_layout_mode()
	var portrait: bool = mode == "portrait"
	var dense_landscape: bool = mode == "landscape_dense"
	body.vertical = portrait
	options_grid.columns = 1 if portrait else 2
	if portrait:
		terminal_pane.size_flags_stretch_ratio = 1.4
		board_pane.size_flags_stretch_ratio = 1.25
		answers_pane.size_flags_stretch_ratio = 1.0
		lbl_meta.custom_minimum_size.x = 330.0
		log_text.custom_minimum_size.y = 140.0
		btn_analyze.custom_minimum_size.y = 72.0
		btn_apply_and.custom_minimum_size.y = 72.0
		btn_reset.custom_minimum_size.y = 72.0
		btn_next.custom_minimum_size.y = 72.0
		lbl_status.custom_minimum_size.y = 78.0
	elif dense_landscape:
		terminal_pane.size_flags_stretch_ratio = 1.68
		board_pane.size_flags_stretch_ratio = 1.22
		answers_pane.size_flags_stretch_ratio = 0.90
		lbl_meta.custom_minimum_size.x = 220.0
		log_text.custom_minimum_size.y = 112.0
		btn_analyze.custom_minimum_size.y = 48.0
		btn_apply_and.custom_minimum_size.y = 48.0
		btn_reset.custom_minimum_size.y = 48.0
		btn_next.custom_minimum_size.y = 48.0
		lbl_status.custom_minimum_size.y = 60.0
	else:
		terminal_pane.size_flags_stretch_ratio = 1.56
		board_pane.size_flags_stretch_ratio = 1.24
		answers_pane.size_flags_stretch_ratio = 0.96
		lbl_meta.custom_minimum_size.x = 300.0
		log_text.custom_minimum_size.y = 172.0
		btn_analyze.custom_minimum_size.y = 58.0
		btn_apply_and.custom_minimum_size.y = 58.0
		btn_reset.custom_minimum_size.y = 58.0
		btn_next.custom_minimum_size.y = 58.0
		lbl_status.custom_minimum_size.y = 72.0
	for btn in action_buttons:
		btn.custom_minimum_size.y = 72.0 if portrait else (60.0 if dense_landscape else 72.0)
	_sync_terminal_text_heights(mode)
	var vp_size: Vector2 = get_viewport_rect().size
	var compact: bool = vp_size.x < 740.0 or vp_size.y < 420.0
	btn_back.custom_minimum_size = Vector2(56.0 if compact else 118.0, 44.0 if compact else 58.0)
	btn_back.text = "<" if compact else _tr("nt.common.back", "НАЗАД")
	lbl_meta.custom_minimum_size.x = 0.0 if compact else lbl_meta.custom_minimum_size.x
	lbl_meta.visible = not compact
	palette_select.visible = false
