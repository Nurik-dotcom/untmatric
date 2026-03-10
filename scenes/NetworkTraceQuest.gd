extends Control

const THEME_NOIR: Theme = preload("res://ui/theme_noir_detective.tres")
const THEME_GREEN: Theme = preload("res://ui/theme_terminal_green.tres")
const THEME_AMBER: Theme = preload("res://ui/theme_terminal_amber.tres")
const ERROR_MAP = preload("res://scripts/ssot/network_trace_errors.gd")

const DATA_PATHS: Dictionary = {
	"A": "res://data/network_trace_a_levels.json",
	"B": "res://data/network_trace_b_levels.json",
	"C": "res://data/network_trace_c_levels.json"
}

const ACTION_BUTTON_NAMES: Array[String] = [
	"ActionBtn1",
	"ActionBtn2",
	"ActionBtn3",
	"ActionBtn4",
	"ActionBtn5",
	"ActionBtn6"
]

const MAX_ATTEMPTS := 3
const DEFAULT_TIME_LIMIT_SEC := 120
const OPTION_COOLDOWN_MS := 200
const HINT_STABILITY_PENALTY := -5.0
const FAIL_STABILITY_PENALTY := -10.0
const PALETTE_GREEN_ID := 0
const PALETTE_AMBER_ID := 1
const FX_LOW_ID := 0
const FX_HIGH_ID := 1

enum QuestState {
	INIT,
	BRIEFING,
	SOLVING,
	FEEDBACK_SUCCESS,
	FEEDBACK_FAIL,
	SAFE_MODE,
	DIAGNOSTIC
}

@export_enum("A", "B", "C") var complexity_name: String = "A"

@onready var main_layout: VBoxContainer = $MainMargin/MainLayout
@onready var btn_back: Button = $MainMargin/MainLayout/HeaderRow/BtnBack
@onready var lbl_case: Label = $MainMargin/MainLayout/HeaderRow/LblCase
@onready var lbl_session: Label = $MainMargin/MainLayout/HeaderRow/LblSession
@onready var palette_select: OptionButton = $MainMargin/MainLayout/SettingsRow/PaletteSelect
@onready var fx_select: OptionButton = $MainMargin/MainLayout/SettingsRow/FxSelect
@onready var lbl_timer: Label = $MainMargin/MainLayout/SettingsRow/LblTimer
@onready var progress_bar: ProgressBar = $MainMargin/MainLayout/BarsRow/ProgressBar
@onready var stability_bar: ProgressBar = $MainMargin/MainLayout/BarsRow/StabilityBar
@onready var lbl_attempts: Label = $MainMargin/MainLayout/BarsRow/LblAttempts
@onready var body_landscape: HBoxContainer = $MainMargin/MainLayout/BodyLandscape
@onready var body_portrait: VBoxContainer = $MainMargin/MainLayout/BodyPortrait
@onready var terminal_pane: PanelContainer = $MainMargin/MainLayout/BodyLandscape/TerminalPane
@onready var actions_pane: PanelContainer = $MainMargin/MainLayout/BodyLandscape/ActionsPane
@onready var terminal_scroll: ScrollContainer = $MainMargin/MainLayout/BodyLandscape/TerminalPane/TerminalMargin/TerminalScroll
@onready var terminal_text: RichTextLabel = $MainMargin/MainLayout/BodyLandscape/TerminalPane/TerminalMargin/TerminalScroll/TerminalText
@onready var options_grid: GridContainer = $MainMargin/MainLayout/BodyLandscape/ActionsPane/ActionsMargin/ActionsVBox/OptionsGrid
@onready var lbl_status: Label = $MainMargin/MainLayout/BodyLandscape/ActionsPane/ActionsMargin/ActionsVBox/LblStatus
@onready var btn_analyze: Button = $MainMargin/MainLayout/BodyLandscape/ActionsPane/ActionsMargin/ActionsVBox/BottomRow/BtnAnalyze
@onready var btn_hint: Button = $MainMargin/MainLayout/BodyLandscape/ActionsPane/ActionsMargin/ActionsVBox/BottomRow/BtnHint
@onready var btn_next: Button = $MainMargin/MainLayout/BodyLandscape/ActionsPane/ActionsMargin/ActionsVBox/BottomRow/BtnNext
@onready var diagnostics_panel: PanelContainer = $DiagnosticsPanel
@onready var crt_overlay: ColorRect = $CanvasLayer/CRT_Overlay

var action_buttons: Array[Button] = []
var levels: Array = []
var ordered_options: Array = []
var current_level: Dictionary = {}
var current_level_index := 0
var variant_hash := ""
var state: int = QuestState.INIT

var attempts: Array = []
var task_session: Dictionary = {}
var wrong_count := 0
var level_started_ms := 0
var first_action_ms := -1
var option_unlock_at_ms := 0
var time_limit_sec := DEFAULT_TIME_LIMIT_SEC
var time_left_sec := 0.0
var timer_running := false
var safe_mode := false
var hint_used := false
var level_finished := false
var last_error_code := ""
var current_layout := "landscape"
var topology_board: Node = null
var analyze_used := false

func _ready() -> void:
	
	complexity_name = complexity_name.to_upper()
	if not DATA_PATHS.has(complexity_name):
		complexity_name = "A"

	_collect_action_buttons()
	_setup_runtime_controls()
	_connect_runtime_signals()
	_apply_palette(PALETTE_GREEN_ID)
	_apply_fx_quality(FX_LOW_ID)
	_update_stability_bar()
	_apply_layout_mode()

	if GlobalMetrics != null and not GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.connect(_on_stability_changed)

	if not _load_levels_for_complexity(complexity_name):
		_show_boot_error("Данные уровней недоступны для сложности %s." % complexity_name)
		return

	if complexity_name == "A":
		_setup_optional_topology_board()

	_load_level(0)

func _exit_tree() -> void:
	if GlobalMetrics != null and GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.disconnect(_on_stability_changed)

func _process(delta: float) -> void:
	if state == QuestState.DIAGNOSTIC and not diagnostics_panel.visible:
		if level_finished:
			state = QuestState.FEEDBACK_FAIL
		elif safe_mode:
			state = QuestState.SAFE_MODE
		else:
			state = QuestState.SOLVING

	if timer_running and not level_finished:
		time_left_sec -= delta
		if time_left_sec <= 0.0:
			time_left_sec = 0.0
			_update_timer_label()
			_on_timeout()
		else:
			_update_timer_label()

	if option_unlock_at_ms > 0 and Time.get_ticks_msec() >= option_unlock_at_ms:
		option_unlock_at_ms = 0
		if _can_pick_option():
			_set_option_buttons_enabled(true)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		if not is_node_ready():
			return
		_apply_layout_mode()

func _collect_action_buttons() -> void:
	action_buttons.clear()
	for button_name in ACTION_BUTTON_NAMES:
		var node: Node = options_grid.get_node(button_name)
		if node is Button:
			action_buttons.append(node as Button)

func _setup_runtime_controls() -> void:
	palette_select.clear()
	palette_select.add_item("ЗЕЛЁНЫЙ", PALETTE_GREEN_ID)
	palette_select.add_item("ЯНТАРНЫЙ", PALETTE_AMBER_ID)
	palette_select.select(PALETTE_GREEN_ID)

	fx_select.clear()
	fx_select.add_item("FX НИЗКИЙ", FX_LOW_ID)
	fx_select.add_item("FX ВЫСОКИЙ", FX_HIGH_ID)
	fx_select.select(FX_LOW_ID)

	btn_next.visible = false
	diagnostics_panel.visible = false

func _connect_runtime_signals() -> void:
	btn_back.pressed.connect(_on_back_pressed)
	btn_analyze.pressed.connect(_on_analyze_pressed)
	btn_hint.pressed.connect(_on_hint_pressed)
	btn_next.pressed.connect(_on_next_pressed)
	palette_select.item_selected.connect(_on_palette_selected)
	fx_select.item_selected.connect(_on_fx_selected)

	for idx in range(action_buttons.size()):
		action_buttons[idx].pressed.connect(_on_action_pressed.bind(idx))

func _setup_optional_topology_board() -> void:
	topology_board = get_node_or_null("MainMargin/MainLayout/BodyLandscape/TerminalPane/TopologyBoard")
	if topology_board == null:
		for node in get_tree().get_nodes_in_group("topology_board"):
			topology_board = node
			break
	if topology_board != null and topology_board.has_signal("device_installed"):
		var callback := Callable(self, "_on_topology_device_installed")
		if not topology_board.is_connected("device_installed", callback):
			topology_board.connect("device_installed", callback)

func _load_levels_for_complexity(level_key: String) -> bool:
	var path: String = str(DATA_PATHS[level_key])
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("NetworkTrace missing data file: %s" % path)
		return false

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	var raw_levels: Array = []
	if typeof(parsed) == TYPE_ARRAY:
		raw_levels = parsed
	elif typeof(parsed) == TYPE_DICTIONARY:
		var parsed_dict: Dictionary = parsed
		raw_levels = parsed_dict.get("levels", [])
	else:
		push_error("NetworkTrace invalid JSON shape: %s" % path)
		return false

	var valid_levels: Array = []
	for level_var in raw_levels:
		if typeof(level_var) != TYPE_DICTIONARY:
			continue
		var level: Dictionary = level_var
		if validate_level(level):
			valid_levels.append(level)
		elif OS.is_debug_build():
			push_error("Invalid NetworkTrace level: %s" % str(level.get("id", "UNKNOWN")))
			return false
		else:
			push_warning("Skipping invalid NetworkTrace level: %s" % str(level.get("id", "UNKNOWN")))

	levels = valid_levels
	return levels.size() > 0

func validate_levels(levels_to_check: Array) -> bool:
	for level_var in levels_to_check:
		if typeof(level_var) != TYPE_DICTIONARY:
			return false
		if not validate_level(level_var):
			return false
	return true

func validate_level(level: Dictionary) -> bool:
	var required_keys: Array[String] = ["id", "briefing", "prompt", "options", "correct_id", "explain_short", "explain_full", "tags"]
	for key in required_keys:
		if not level.has(key):
			return false

	if typeof(level.get("options")) != TYPE_ARRAY:
		return false
	if typeof(level.get("tags")) != TYPE_ARRAY:
		return false

	var options: Array = level.get("options", [])
	if options.size() < 4 or options.size() > 6:
		return false

	var option_ids: Dictionary = {}
	for option_var in options:
		if typeof(option_var) != TYPE_DICTIONARY:
			return false
		var option: Dictionary = option_var
		var option_required: Array[String] = ["id", "label", "error_code"]
		for option_key in option_required:
			if not option.has(option_key):
				return false
		var option_id: String = str(option.get("id", ""))
		if option_id.is_empty() or option_ids.has(option_id):
			return false
		option_ids[option_id] = true

	var correct_id: String = str(level.get("correct_id", ""))
	if not option_ids.has(correct_id):
		return false

	if level.has("ui_order"):
		if typeof(level.get("ui_order")) != TYPE_ARRAY:
			return false
		var order: Array = level.get("ui_order", [])
		for id_var in order:
			var id_str: String = str(id_var)
			if not option_ids.has(id_str):
				return false

	if level.has("time_limit_sec"):
		var limit_val: int = int(level.get("time_limit_sec", DEFAULT_TIME_LIMIT_SEC))
		if limit_val <= 0:
			return false

	return true

func _show_boot_error(message: String) -> void:
	lbl_status.text = message
	lbl_status.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	_set_option_buttons_enabled(false)
	btn_analyze.disabled = true
	btn_hint.disabled = true
	btn_next.disabled = true
	timer_running = false



func _load_level(index: int) -> void:
	if levels.is_empty():
		return

	if index >= levels.size():
		_show_session_summary()
		return
	current_level_index = index
	current_level = (levels[index] as Dictionary).duplicate(true)
	variant_hash = str(hash(_build_variant_key(current_level)))
	level_started_ms = Time.get_ticks_msec()
	first_action_ms = -1
	option_unlock_at_ms = 0
	wrong_count = 0
	safe_mode = false
	hint_used = false
	analyze_used = false
	level_finished = false
	last_error_code = ""
	attempts = []

	time_limit_sec = int(current_level.get("time_limit_sec", DEFAULT_TIME_LIMIT_SEC))
	time_left_sec = float(time_limit_sec)
	timer_running = true

	state = QuestState.BRIEFING

	var level_id: String = str(current_level.get("id", "NT_UNKNOWN"))
	task_session = {
		"task_id": level_id,
		"variant_hash": variant_hash,
		"started_at_ticks": level_started_ms,
		"ended_at_ticks": 0,
		"attempts": [],
		"events": []
	}

	lbl_case.text = "\u0421\u0415\u0422\u0415\u0412\u041e\u0419 \u0421\u041b\u0415\u0414 | %s" % complexity_name
	lbl_session.text = "\u0414\u0415\u041b\u041e %04d" % (randi() % 10000)
	lbl_attempts.text = "\u041e\u0428 0/%d" % MAX_ATTEMPTS
	btn_next.visible = false
	btn_next.disabled = false
	btn_next.text = "\u0414\u0410\u041b\u0415\u0415"
	btn_analyze.disabled = true
	btn_hint.disabled = false
	diagnostics_panel.visible = false

	if levels.size() <= 1:
		progress_bar.value = 100.0
	else:
		progress_bar.value = (float(current_level_index) / float(levels.size() - 1)) * 100.0

	_update_timer_label()
	_update_stability_bar()
	_render_terminal_content()
	_setup_option_buttons()
	if topology_board != null and topology_board.has_method("setup_topology"):
		var topology_data: Variant = current_level.get("topology", {})
		if typeof(topology_data) == TYPE_DICTIONARY:
			topology_board.call("setup_topology", topology_data)
			if topology_board.has_method("set_tools_locked"):
				topology_board.call("set_tools_locked", false)
	_set_option_buttons_enabled(true)

	lbl_status.text = "\u0412\u044b\u0431\u0435\u0440\u0438\u0442\u0435 \u0443\u0441\u0442\u0440\u043e\u0439\u0441\u0442\u0432\u043e."
	lbl_status.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

	state = QuestState.SOLVING
	_log_event("task_start", {
		"complexity": complexity_name,
		"layout": current_layout
	})

func _render_terminal_content() -> void:
	var briefing: String = _tr_level("briefing")
	var prompt: String = _tr_level("prompt")
	var tags_arr: Array = current_level.get("tags", [])
	var tag_line: String = ""
	if not tags_arr.is_empty():
		tag_line = "\n[color=#6f8f6f]\u0422\u0415\u0413\u0418[/color] %s" % ", ".join(_stringify_array(tags_arr))

	terminal_text.clear()
	terminal_text.append_text("[color=#7a7a7a]\u041e\u0411\u042a\u0415\u041a\u0422\u0418\u0412[/color]\n")
	terminal_text.append_text("%s\n\n" % briefing)
	terminal_text.append_text("[color=#9de6b3]\u0417\u0410\u0414\u0410\u041d\u0418\u0415[/color]\n")
	terminal_text.append_text("%s\n" % prompt)

	if complexity_name == "A":
		var pois_variant: Variant = current_level.get("pois", [])
		if typeof(pois_variant) == TYPE_ARRAY:
			var pois: Array = pois_variant
			if not pois.is_empty():
				terminal_text.append_text("\n[color=#7a7a7a]\u0416\u0423\u0420\u041d\u0410\u041b \u0421\u041e\u0411\u042b\u0422\u0418\u0419[/color]\n")
				for poi_var in pois:
					if typeof(poi_var) != TYPE_DICTIONARY:
						continue
					var poi: Dictionary = poi_var
					var log_line: String = str(poi.get("log_line", ""))
					if log_line.is_empty():
						continue
					var hint_layer: String = str(poi.get("hint_layer", ""))
					var tag: String = str(poi.get("tag", ""))
					var layer_color: String = "#ff9999"
					if hint_layer == "L1":
						layer_color = "#ffcc66"
					elif hint_layer == "L2":
						layer_color = "#66ccff"
					elif hint_layer == "L3":
						layer_color = "#66ff99"
					terminal_text.append_text("[color=%s][%s][/color] %s [color=#6f6f6f][%s][/color]\n" % [
						layer_color, hint_layer, log_line, tag
					])

	if complexity_name == "B":
		var logs_variant: Variant = current_level.get("logs", [])
		if typeof(logs_variant) == TYPE_ARRAY:
			var logs: Array = logs_variant
			if not logs.is_empty():
				terminal_text.append_text("\n[color=#7a7a7a]\u041b\u041e\u0413\u0418 \u0421\u0418\u0421\u0422\u0415\u041c\u042b[/color]\n")
				for log_line_var in logs:
					terminal_text.append_text("> %s\n" % str(log_line_var))

		var modules_variant: Variant = current_level.get("modules_pool", [])
		if typeof(modules_variant) == TYPE_ARRAY:
			var modules: Array = modules_variant
			if not modules.is_empty():
				terminal_text.append_text("\n[color=#7a7a7a]\u0414\u041e\u0421\u0422\u0423\u041f\u041d\u042b\u0415 \u041c\u041e\u0414\u0423\u041b\u0418[/color]\n")
				for module_var in modules:
					if typeof(module_var) != TYPE_DICTIONARY:
						continue
					var module: Dictionary = module_var
					var display: String = str(module.get("display", ""))
					var slot: String = str(module.get("slot_type", ""))
					var is_trap: bool = bool(module.get("is_trap", false))
					var meaning: String = str(module.get("meaning", ""))
					var details: String = meaning if (not is_trap and not meaning.is_empty()) else "\u041f\u0440\u043e\u0432\u0435\u0440\u0438\u0442\u044c \u0432\u0440\u0443\u0447\u043d\u0443\u044e."
					var color: String = "#9de6b3" if not is_trap else "#e6c89d"
					terminal_text.append_text("[color=%s][%s][/color] \u0441\u043b\u043e\u0442: %s - %s\n" % [color, display, slot, details])
				terminal_text.append_text("\n[color=#6f8f6f]\u041a\u043e\u043d\u0432\u0435\u0439\u0435\u0440: payload -> [kilo] -> [bit] -> [time] -> [out][/color]\n")

		var benchmark_variant: Variant = current_level.get("benchmark_lines", [])
		if typeof(benchmark_variant) == TYPE_ARRAY:
			var benchmark: Array = benchmark_variant
			if not benchmark.is_empty():
				terminal_text.append_text("\n[color=#7a7a7a]\u0424\u041e\u0420\u041c\u0423\u041b\u0410[/color]\n")
				for line_var in benchmark:
					terminal_text.append_text("%s\n" % str(line_var))

		var metrics_variant: Variant = current_level.get("preview_metrics", {})
		if typeof(metrics_variant) == TYPE_DICTIONARY:
			var metrics: Dictionary = metrics_variant
			if not metrics.is_empty():
				terminal_text.append_text("\n[color=#7a7a7a]\u0421\u0418\u0421\u0422\u0415\u041c\u041d\u042b\u0419 \u041c\u041e\u041d\u0418\u0422\u041e\u0420[/color]\n")
				terminal_text.append_text("CPU: %d%% | RAM: %d%% | FPS: %d\n" % [
					int(metrics.get("cpu_load", 0)),
					int(metrics.get("ram_usage", 0)),
					int(metrics.get("fps", 0))
				])

	if complexity_name == "C":
		var ip_last: int = int(current_level.get("ip_last", 0))
		var mask_last: int = int(current_level.get("mask_last", 0))
		var cidr: int = int(current_level.get("cidr", 24))
		var step: int = int(current_level.get("step", 0))
		var target_ip: String = str(current_level.get("target_ip", ""))
		terminal_text.append_text("\n[color=#7a7a7a]\u0414\u0410\u041d\u041d\u042b\u0415 \u0414\u041b\u042f \u0420\u0410\u0421\u0427\u0401\u0422\u0410[/color]\n")
		terminal_text.append_text("IP: %s\n" % target_ip)
		terminal_text.append_text("CIDR: /%d\n" % cidr)
		terminal_text.append_text("\u041f\u043e\u0441\u043b\u0435\u0434\u043d\u0438\u0439 \u043e\u043a\u0442\u0435\u0442 IP: %s (\u0434\u0432\u043e\u0438\u0447\u043d\u044b\u0439: %s)\n" % [str(ip_last), _to_binary_8bit(ip_last)])
		terminal_text.append_text("\u041f\u043e\u0441\u043b\u0435\u0434\u043d\u0438\u0439 \u043e\u043a\u0442\u0435\u0442 \u043c\u0430\u0441\u043a\u0438: %s (\u0434\u0432\u043e\u0438\u0447\u043d\u044b\u0439: %s)\n" % [str(mask_last), _to_binary_8bit(mask_last)])
		terminal_text.append_text("\u0428\u0430\u0433 \u0441\u0435\u0433\u043c\u0435\u043d\u0442\u0430: %d\n" % step)
		terminal_text.append_text("\n[color=#6f8f6f]\u041f\u043e\u0434\u0441\u043a\u0430\u0437\u043a\u0430: ID \u0441\u0435\u0442\u0438 = IP_last AND mask_last[/color]\n")

	if level_finished:
		var explain_short: String = _tr_level("explain_short")
		if not explain_short.is_empty():
			terminal_text.append_text("\n[color=#a1a1a1]\u0420\u0410\u0417\u0411\u041e\u0420[/color]\n%s\n" % explain_short)

	if not tag_line.is_empty():
		terminal_text.append_text(tag_line)
	terminal_scroll.scroll_vertical = 0
func _setup_option_buttons() -> void:
	ordered_options = _ordered_options_for_level(current_level)
	for reset_btn in action_buttons:
		reset_btn.remove_theme_color_override("font_color")
		reset_btn.remove_theme_color_override("font_hover_color")

	for idx in range(action_buttons.size()):
		var btn: Button = action_buttons[idx]
		if idx < ordered_options.size():
			var option: Dictionary = ordered_options[idx]
			var option_id: String = str(option.get("id", ""))
			btn.visible = true
			btn.disabled = false
			btn.text = _tr_level_option(option_id, str(option.get("label", "")))
			btn.set_meta("option_id", option_id)
			btn.set_meta("option_error", str(option.get("error_code", "")))
		else:
			btn.visible = false
			btn.disabled = true
			btn.text = ""
			btn.set_meta("option_id", "")
			btn.set_meta("option_error", "")

func _ordered_options_for_level(level: Dictionary) -> Array:
	var options: Array = level.get("options", [])
	var ordered: Array = []

	if level.has("ui_order"):
		var option_map: Dictionary = {}
		for option_var in options:
			if typeof(option_var) == TYPE_DICTIONARY:
				var option_dict: Dictionary = option_var
				option_map[str(option_dict.get("id", ""))] = option_dict
		var id_order: Array = level.get("ui_order", [])
		for id_var in id_order:
			var option_id: String = str(id_var)
			if option_map.has(option_id):
				ordered.append(option_map[option_id])
		for option_var in options:
			var option_dict: Dictionary = option_var
			if not ordered.has(option_dict):
				ordered.append(option_dict)
	else:
		for option_var in options:
			ordered.append(option_var)
		ordered.shuffle()

	return ordered

func _on_action_pressed(button_index: int) -> void:
	if not _can_pick_option():
		return
	if button_index < 0 or button_index >= action_buttons.size():
		return

	var btn: Button = action_buttons[button_index]
	var option_id: String = str(btn.get_meta("option_id", ""))
	if option_id.is_empty():
		return

	_register_first_action()
	_play_audio("click")

	_set_option_buttons_enabled(false)
	option_unlock_at_ms = Time.get_ticks_msec() + OPTION_COOLDOWN_MS

	var option: Dictionary = _find_option(option_id)
	var is_correct: bool = option_id == str(current_level.get("correct_id", ""))
	if is_correct:
		btn.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
		btn.add_theme_color_override("font_hover_color", Color(0.2, 1.0, 0.3))
	else:
		btn.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 0.3, 0.3))
	var error_code: String = "" if is_correct else str(option.get("error_code", "UNKNOWN"))
	last_error_code = error_code

	var now_ms: int = Time.get_ticks_msec()
	var attempt_entry: Dictionary = {
		"id": option_id,
		"label": str(option.get("label", "")),
		"correct": is_correct,
		"error_code": error_code,
		"t_ms": now_ms - level_started_ms
	}
	attempts.append(attempt_entry)
	var session_attempts: Array = task_session.get("attempts", [])
	session_attempts.append(attempt_entry)
	task_session["attempts"] = session_attempts

	_log_event("answer_selected", {
		"option_id": option_id,
		"correct": is_correct,
		"error_code": error_code
	})

	if is_correct:
		_handle_success()
	else:
		_handle_failure(error_code)
func _handle_success() -> void:
	state = QuestState.FEEDBACK_SUCCESS
	lbl_status.text = "Верно. Путь связи подтверждён."
	lbl_status.add_theme_color_override("font_color", Color(0.35, 1.0, 0.45))
	_set_option_buttons_enabled(false)
	btn_analyze.disabled = true
	btn_hint.disabled = true
	btn_next.visible = true
	_play_audio("relay")
	_finish_level(true, "success")


func _handle_failure(error_code: String) -> void:
	wrong_count += 1
	lbl_attempts.text = "?? %d/%d" % [wrong_count, MAX_ATTEMPTS]
	state = QuestState.FEEDBACK_FAIL

	var short_message: String = ERROR_MAP.short_message(error_code)
	lbl_status.text = "\u041e\u0448\u0438\u0431\u043a\u0430: %s" % short_message
	if complexity_name == "B" and current_level.has("feedback"):
		var fb_variant: Variant = current_level.get("feedback", {})
		if typeof(fb_variant) == TYPE_DICTIONARY:
			var fb: Dictionary = fb_variant
			var fb_headline: String = str(fb.get("headline", ""))
			if not fb_headline.is_empty():
				lbl_status.text = fb_headline
	lbl_status.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))

	_play_audio("error")
	_trigger_glitch()
	_shake_main_layout()

	if _is_train_mode():
		_finish_level(false, "train_error")
		return

	if wrong_count >= 2 and not safe_mode:
		_enter_safe_mode()

	if wrong_count >= MAX_ATTEMPTS:
		_finish_level(false, "attempt_limit")
	elif safe_mode:
		state = QuestState.SAFE_MODE
	else:
		state = QuestState.SOLVING

func _enter_safe_mode() -> void:
	safe_mode = true
	state = QuestState.SAFE_MODE
	btn_analyze.disabled = false
	var required_poi: int = int(current_level.get("required_poi", 0))
	if required_poi > 0 and not analyze_used:
		lbl_status.text = "\u041f\u0435\u0440\u0435\u0434 \u043e\u0442\u0432\u0435\u0442\u043e\u043c \u0440\u0435\u043a\u043e\u043c\u0435\u043d\u0434\u0443\u0435\u0442\u0441\u044f ANALYZE: \u043f\u0440\u043e\u0432\u0435\u0440\u044c\u0442\u0435 \u0436\u0443\u0440\u043d\u0430\u043b \u0443\u043b\u0438\u043a."
	else:
		lbl_status.text = "\u0411\u0435\u0437\u043e\u043f\u0430\u0441\u043d\u044b\u0439 \u0440\u0435\u0436\u0438\u043c \u0432\u043a\u043b\u044e\u0447\u0451\u043d. \u041d\u0430\u0436\u043c\u0438\u0442\u0435 ANALYZE."
	lbl_status.add_theme_color_override("font_color", Color(1.0, 0.7, 0.35))
	_log_event("safe_mode_enabled", {"wrong_count": wrong_count, "required_poi": required_poi})

func _on_analyze_pressed() -> void:
	if level_finished:
		return
	analyze_used = true

	if not safe_mode:
		lbl_status.text = "ANALYZE \u043e\u0442\u043a\u0440\u043e\u0435\u0442\u0441\u044f \u043f\u043e\u0441\u043b\u0435 2 \u043e\u0448\u0438\u0431\u043e\u043a."
		lbl_status.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))
		return

	_register_first_action()
	if not hint_used:
		hint_used = true
		_log_event("hint_used", {"source": "analyze"})

	var lines: Array[String] = []
	lines.append("\u0423\u0440\u043e\u0432\u0435\u043d\u044c: %s" % str(current_level.get("id", "UNKNOWN")))
	if not last_error_code.is_empty():
		lines.append("\u041f\u043e\u0441\u043b\u0435\u0434\u043d\u0438\u0439 \u043a\u043e\u0434 \u043e\u0448\u0438\u0431\u043a\u0438: %s" % last_error_code)
		lines.append(ERROR_MAP.short_message(last_error_code))
		for detail_line in ERROR_MAP.detail_messages(last_error_code):
			lines.append(detail_line)

	if complexity_name == "B":
		var analyze_variant: Variant = current_level.get("analyze_lines", [])
		if typeof(analyze_variant) == TYPE_ARRAY:
			for al_var in analyze_variant:
				lines.append(str(al_var))

	var full_explain: String = _tr_level("explain_full")
	if not full_explain.is_empty():
		for explain_line in full_explain.split("\n"):
			var trimmed: String = explain_line.strip_edges()
			if not trimmed.is_empty():
				lines.append(trimmed)

	_show_diagnostics(lines)
	state = QuestState.DIAGNOSTIC
	_log_event("diagnostic_open", {"error_code": last_error_code})

func _on_hint_pressed() -> void:
	if level_finished:
		return

	_register_first_action()
	if not hint_used:
		hint_used = true
		_log_event("hint_used", {"source": "hint_button"})

	var hint_text: String = str(current_level.get("hint", current_level.get("explain_short", "\u041f\u043e\u0434\u0441\u043a\u0430\u0437\u043a\u0430 \u043d\u0435\u0434\u043e\u0441\u0442\u0443\u043f\u043d\u0430.")))
	hint_text = _tr_level("hint", hint_text)
	lbl_status.text = "\u041f\u043e\u0434\u0441\u043a\u0430\u0437\u043a\u0430: %s" % hint_text
	lbl_status.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))


func _on_next_pressed() -> void:
	if not level_finished:
		return
	if btn_next.text == "\u0412\u042b\u0425\u041e\u0414":
		get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")
		return
	_log_event("next_pressed", {"from": str(current_level.get("id", "UNKNOWN"))})
	_load_level(current_level_index + 1)

func _show_session_summary() -> void:
	state = QuestState.FEEDBACK_SUCCESS
	timer_running = false
	level_finished = true
	_set_option_buttons_enabled(false)
	btn_analyze.disabled = true
	btn_hint.disabled = true
	btn_next.visible = true
	btn_next.text = "\u0412\u042b\u0425\u041e\u0414"
	if topology_board != null and topology_board.has_method("set_tools_locked"):
		topology_board.call("set_tools_locked", true)

	var total: int = levels.size()
	var correct_count: int = 0
	var total_time_ms: int = 0
	var hints_count: int = 0

	var history_variant: Variant = []
	if GlobalMetrics != null:
		history_variant = GlobalMetrics.get("session_history")
	if typeof(history_variant) == TYPE_ARRAY:
		var history: Array = history_variant
		for entry_var in history:
			if typeof(entry_var) != TYPE_DICTIONARY:
				continue
			var entry: Dictionary = entry_var
			if str(entry.get("quest", "")) != "network_trace":
				continue
			if str(entry.get("stage", "")) != complexity_name:
				continue
			if bool(entry.get("is_correct", false)):
				correct_count += 1
			total_time_ms += int(entry.get("elapsed_ms", 0))
			if bool(entry.get("hint_used", false)):
				hints_count += 1

	var avg_time_sec: float = (float(total_time_ms) / 1000.0) / maxf(1.0, float(total))
	var pct: int = int((float(correct_count) / maxf(1.0, float(total))) * 100.0)

	terminal_text.clear()
	terminal_text.append_text("[color=#9de6b3]\u0421\u0415\u0421\u0421\u0418\u042f \u0417\u0410\u0412\u0415\u0420\u0428\u0415\u041d\u0410[/color]\n\n")
	terminal_text.append_text("\u0421\u043b\u043e\u0436\u043d\u043e\u0441\u0442\u044c: %s\n" % complexity_name)
	terminal_text.append_text("\u041f\u0440\u0430\u0432\u0438\u043b\u044c\u043d\u043e: %d / %d (%d%%)\n" % [correct_count, total, pct])
	terminal_text.append_text("\u0421\u0440\u0435\u0434\u043d\u0435\u0435 \u0432\u0440\u0435\u043c\u044f: %.1f \u0441\n" % avg_time_sec)
	terminal_text.append_text("\u041f\u043e\u0434\u0441\u043a\u0430\u0437\u043a\u0438 \u0438\u0441\u043f\u043e\u043b\u044c\u0437\u043e\u0432\u0430\u043d\u044b: %d\n\n" % hints_count)

	if pct >= 90:
		terminal_text.append_text("[color=#4eff6a]\u041e\u0442\u043b\u0438\u0447\u043d\u044b\u0439 \u0440\u0435\u0437\u0443\u043b\u044c\u0442\u0430\u0442. \u0422\u0440\u0430\u0441\u0441\u0438\u0440\u043e\u0432\u043a\u0430 \u0437\u0430\u0432\u0435\u0440\u0448\u0435\u043d\u0430.[/color]\n")
		lbl_status.text = "\u0421\u0435\u0441\u0441\u0438\u044f \u043f\u0440\u043e\u0439\u0434\u0435\u043d\u0430 \u0443\u0441\u043f\u0435\u0448\u043d\u043e."
		lbl_status.add_theme_color_override("font_color", Color(0.35, 1.0, 0.45))
	elif pct >= 60:
		terminal_text.append_text("[color=#f0c040]\u041d\u0435\u043f\u043b\u043e\u0445\u043e, \u043d\u043e \u0435\u0441\u0442\u044c \u043f\u0440\u043e\u0431\u0435\u043b\u044b. \u0420\u0435\u043a\u043e\u043c\u0435\u043d\u0434\u0443\u0435\u0442\u0441\u044f \u043f\u043e\u0432\u0442\u043e\u0440\u0438\u0442\u044c.[/color]\n")
		lbl_status.text = "\u0420\u0435\u043a\u043e\u043c\u0435\u043d\u0434\u0443\u0435\u0442\u0441\u044f \u043f\u043e\u0432\u0442\u043e\u0440\u0438\u0442\u044c \u0441\u0435\u0441\u0441\u0438\u044e."
		lbl_status.add_theme_color_override("font_color", Color(0.95, 0.75, 0.2))
	else:
		terminal_text.append_text("[color=#ff5555]\u0422\u0440\u0435\u0431\u0443\u0435\u0442\u0441\u044f \u0434\u043e\u043f\u043e\u043b\u043d\u0438\u0442\u0435\u043b\u044c\u043d\u0430\u044f \u043f\u043e\u0434\u0433\u043e\u0442\u043e\u0432\u043a\u0430.[/color]\n")
		lbl_status.text = "\u041d\u0443\u0436\u043d\u043e \u043f\u043e\u0432\u0442\u043e\u0440\u0438\u0442\u044c \u043c\u0430\u0442\u0435\u0440\u0438\u0430\u043b."
		lbl_status.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))

	lbl_case.text = "\u0421\u0415\u0422\u0415\u0412\u041e\u0419 \u0421\u041b\u0415\u0414 | %s | \u0418\u0422\u041e\u0413\u0418" % complexity_name
	progress_bar.value = 100.0

func _on_topology_device_installed(device_id: String, _label_text: String, _error_code: String) -> void:
	for idx in range(action_buttons.size()):
		if idx >= ordered_options.size():
			continue
		var option: Dictionary = ordered_options[idx]
		if str(option.get("id", "")) == device_id:
			_on_action_pressed(idx)
			return

func _is_train_mode() -> bool:
	if complexity_name != "C":
		return false
	return str(current_level.get("mode", "EXAM")).to_upper() == "TRAIN"

func _tr_level(field: String, fallback: String = "") -> String:
	var level_id: String = str(current_level.get("id", "UNKNOWN"))
	var key: String = "quest.network_trace.%s.%s" % [level_id, field]
	var raw: String = str(current_level.get(field, fallback))
	if _i18n_has_key(key):
		return I18n.get_text(key, {"default": raw})
	return raw

func _tr_level_option(option_id: String, fallback: String) -> String:
	var level_id: String = str(current_level.get("id", "UNKNOWN"))
	var key: String = "quest.network_trace.%s.option.%s" % [level_id, option_id]
	if _i18n_has_key(key):
		return I18n.get_text(key, {"default": fallback})
	return fallback

func _i18n_has_key(key: String) -> bool:
	if I18n == null:
		return false
	var marker: String = "__MISSING_%s__" % key
	var resolved: String = I18n.get_text(key, {"default": marker})
	return resolved != marker
func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _on_palette_selected(index: int) -> void:
	var item_id: int = palette_select.get_item_id(index)
	_apply_palette(item_id)

func _on_fx_selected(index: int) -> void:
	var item_id: int = fx_select.get_item_id(index)
	_apply_fx_quality(item_id)

func _apply_palette(palette_id: int) -> void:
	if palette_id == PALETTE_AMBER_ID:
		theme = THEME_AMBER
		_set_overlay_tint(Color(1.0, 0.69, 0.0, 1.0))
	else:
		theme = THEME_GREEN
		_set_overlay_tint(Color(0.0, 1.0, 0.25, 1.0))

func _apply_fx_quality(fx_id: int) -> void:
	var shader_material: ShaderMaterial = crt_overlay.material as ShaderMaterial
	if shader_material == null:
		return
	shader_material.set_shader_parameter("fx_quality", 1 if fx_id == FX_HIGH_ID else 0)
	shader_material.set_shader_parameter("glitch_strength", 0.0)

func _set_overlay_tint(color: Color) -> void:
	var shader_material: ShaderMaterial = crt_overlay.material as ShaderMaterial
	if shader_material == null:
		return
	shader_material.set_shader_parameter("tint_color", color)

func _update_timer_label() -> void:
	var total_seconds: int = maxi(0, int(ceil(time_left_sec)))
	var minutes: int = int(total_seconds / 60.0)
	var seconds: int = total_seconds % 60
	lbl_timer.text = "%02d:%02d" % [minutes, seconds]

func _update_stability_bar() -> void:
	if GlobalMetrics != null:
		stability_bar.value = float(GlobalMetrics.stability)

func _on_stability_changed(_new_value: float, _delta: float) -> void:
	_update_stability_bar()

func _set_option_buttons_enabled(enabled: bool) -> void:
	for btn in action_buttons:
		if btn.visible:
			btn.disabled = not enabled

func _can_pick_option() -> bool:
	if level_finished:
		return false
	if option_unlock_at_ms > 0:
		return false
	return state == QuestState.SOLVING or state == QuestState.SAFE_MODE

func _find_option(option_id: String) -> Dictionary:
	var options: Array = current_level.get("options", [])
	for option_var in options:
		if typeof(option_var) != TYPE_DICTIONARY:
			continue
		var option: Dictionary = option_var
		if str(option.get("id", "")) == option_id:
			return option
	return {}

func _register_first_action() -> void:
	if first_action_ms < 0:
		first_action_ms = Time.get_ticks_msec() - level_started_ms



func _finish_level(is_correct: bool, end_reason: String) -> void:
	if level_finished and task_session.get("ended_at_ticks", 0) != 0:
		return

	level_finished = true
	timer_running = false
	_set_option_buttons_enabled(false)
	btn_analyze.disabled = not safe_mode
	btn_hint.disabled = true
	btn_next.visible = true
	if topology_board != null and topology_board.has_method("set_tools_locked"):
		topology_board.call("set_tools_locked", true)

	if not is_correct:
		var correct_id: String = str(current_level.get("correct_id", ""))
		for action_btn in action_buttons:
			if str(action_btn.get_meta("option_id", "")) == correct_id:
				action_btn.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
				action_btn.add_theme_color_override("font_hover_color", Color(0.2, 1.0, 0.3))
		var explain_short: String = _tr_level("explain_short")
		if not explain_short.is_empty():
			lbl_status.text = explain_short
			lbl_status.add_theme_color_override("font_color", Color(1.0, 0.6, 0.45))

	if end_reason == "timeout":
		lbl_status.text = "\u0412\u0440\u0435\u043c\u044f \u0432\u044b\u0448\u043b\u043e. \u041f\u043e\u0432\u0442\u043e\u0440\u0438\u0442\u0435 \u0443\u0440\u043e\u0432\u0435\u043d\u044c."
		lbl_status.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))

	_render_terminal_content()

	var end_tick: int = Time.get_ticks_msec()
	task_session["ended_at_ticks"] = end_tick
	_log_event("task_end", {
		"is_correct": is_correct,
		"reason": end_reason,
		"safe_mode": safe_mode
	})

	var elapsed_ms: int = end_tick - level_started_ms
	var stability_delta: float = 0.0
	if not _is_train_mode():
		if not is_correct:
			stability_delta += FAIL_STABILITY_PENALTY
		if hint_used:
			stability_delta += HINT_STABILITY_PENALTY

	var level_id: String = str(current_level.get("id", "NT_UNKNOWN"))
	var payload: Dictionary = {
		"quest": "network_trace",
		"stage": complexity_name,
		"mode": str(current_level.get("mode", "EXAM")),
		"match_key": "NETTRACE_%s|%s" % [complexity_name, level_id],
		"task_id": level_id,
		"variant_hash": variant_hash,
		"is_correct": is_correct,
		"is_fit": is_correct,
		"safe_mode": safe_mode,
		"elapsed_ms": elapsed_ms,
		"duration": float(elapsed_ms) / 1000.0,
		"error_code": "" if is_correct else last_error_code,
		"attempts": attempts,
		"task_session": task_session,
		"stability_delta": stability_delta,
		"hint_used": hint_used,
		"timed_out": end_reason == "timeout",
		"time_to_first_action_ms": first_action_ms,
		"layout": current_layout,
		"ui_vw": int(size.x),
		"ui_vh": int(size.y)
	}
	GlobalMetrics.register_trial(payload)
func _on_timeout() -> void:
	if level_finished:
		return

	last_error_code = "TIMEOUT"
	var timeout_attempt: Dictionary = {
		"id": "TIMEOUT",
		"label": "TIMEOUT",
		"correct": false,
		"error_code": "TIMEOUT",
		"t_ms": Time.get_ticks_msec() - level_started_ms
	}
	attempts.append(timeout_attempt)
	var session_attempts: Array = task_session.get("attempts", [])
	session_attempts.append(timeout_attempt)
	task_session["attempts"] = session_attempts
	_play_audio("error")
	_trigger_glitch()
	_finish_level(false, "timeout")

func _show_diagnostics(lines: Array[String]) -> void:
	if diagnostics_panel.has_method("setup"):
		diagnostics_panel.call("setup", "\u0414\u0418\u0410\u0413\u041d\u041e\u0421\u0422\u0418\u041a\u0410", lines)
	diagnostics_panel.visible = true
func _trigger_glitch() -> void:
	var shader_material: ShaderMaterial = crt_overlay.material as ShaderMaterial
	if shader_material == null:
		return
	shader_material.set_shader_parameter("glitch_strength", 1.0)
	var tween: Tween = create_tween()
	tween.tween_method(func(v: float) -> void: shader_material.set_shader_parameter("glitch_strength", v), 1.0, 0.0, 0.25)

func _shake_main_layout() -> void:
	var origin: Vector2 = main_layout.position
	var tween: Tween = create_tween()
	for i in range(4):
		tween.tween_property(main_layout, "position", origin + Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0)), 0.03)
	tween.tween_property(main_layout, "position", origin, 0.04)

func _play_audio(sound_key: String) -> void:
	if AudioManager != null:
		AudioManager.play(sound_key)

func _log_event(event_name: String, data: Dictionary) -> void:
	var events: Array = task_session.get("events", [])
	events.append({
		"name": event_name,
		"t_ms": Time.get_ticks_msec() - level_started_ms,
		"payload": data
	})
	task_session["events"] = events

func _build_variant_key(level: Dictionary) -> String:
	var ids: Array[String] = []
	var options: Array = level.get("options", [])
	for option_var in options:
		var option: Dictionary = option_var
		ids.append(str(option.get("id", "")))
	ids.sort()
	return "%s|%s|%s|%s" % [
		str(level.get("id", "NT_UNKNOWN")),
		str(level.get("prompt", "")),
		str(level.get("correct_id", "")),
		",".join(ids)
	]


func _stringify_array(input: Array) -> Array[String]:
	var out: Array[String] = []
	for value in input:
		out.append(str(value))
	return out

func _to_binary_8bit(value: int) -> String:
	var result: String = ""
	var safe_value: int = clampi(value, 0, 255)
	for i in range(7, -1, -1):
		result += "1" if ((safe_value >> i) & 1) == 1 else "0"
	return result
func _apply_layout_mode() -> void:
	if terminal_pane == null or actions_pane == null:
		return
	if body_landscape == null or body_portrait == null:
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	var portrait: bool = viewport_size.x < viewport_size.y

	if portrait:
		if terminal_pane.get_parent() != body_portrait:
			var parent_a: Node = terminal_pane.get_parent()
			if parent_a != null:
				parent_a.remove_child(terminal_pane)
			body_portrait.add_child(terminal_pane)
		if actions_pane.get_parent() != body_portrait:
			var parent_b: Node = actions_pane.get_parent()
			if parent_b != null:
				parent_b.remove_child(actions_pane)
			body_portrait.add_child(actions_pane)
		body_landscape.visible = false
		body_portrait.visible = true
		current_layout = "portrait"
	else:
		if terminal_pane.get_parent() != body_landscape:
			var parent_c: Node = terminal_pane.get_parent()
			if parent_c != null:
				parent_c.remove_child(terminal_pane)
			body_landscape.add_child(terminal_pane)
		if actions_pane.get_parent() != body_landscape:
			var parent_d: Node = actions_pane.get_parent()
			if parent_d != null:
				parent_d.remove_child(actions_pane)
			body_landscape.add_child(actions_pane)
		body_portrait.visible = false
		body_landscape.visible = true
		current_layout = "landscape"

	terminal_pane.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions_pane.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	terminal_pane.size_flags_vertical = Control.SIZE_EXPAND_FILL
	actions_pane.size_flags_vertical = Control.SIZE_EXPAND_FILL
