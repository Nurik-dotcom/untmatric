extends Control

const THEME_GREEN: Theme = preload("res://ui/theme_terminal_green.tres")
const THEME_AMBER: Theme = preload("res://ui/theme_terminal_amber.tres")
const ERROR_MAP = preload("res://scripts/ssot/network_trace_errors.gd")
const MODULE_CARD_SCENE: PackedScene = preload("res://scenes/ui/pipeline/ModuleCard.tscn")

const LEVELS_PATH: String = "res://data/network_trace_b_levels.json"
const MAX_ATTEMPTS: int = 3
const DEFAULT_TIME_LIMIT_SEC: int = 120
const RUN_COOLDOWN_MS: int = 450
const ANSWER_COOLDOWN_MS: int = 200
const FAIL_STABILITY_DELTA: float = -10.0
const HINT_STABILITY_DELTA: float = -5.0
const PIPELINE_MISMATCH_DELTA: float = -5.0

const PALETTE_GREEN_ID: int = 0
const PALETTE_AMBER_ID: int = 1
const SLOT_TYPES: Array[String] = ["kilo", "bit", "time", "out"]
const DEFAULT_MODULE_POOL: Array = [
	{"module_id": "KILO_1024", "slot_type": "kilo", "display": "x1024", "k": 1024, "is_trap": false},
	{"module_id": "KILO_1000", "slot_type": "kilo", "display": "x1000", "k": 1000, "is_trap": true},
	{"module_id": "BIT_X8", "slot_type": "bit", "display": "x8", "k": 8, "is_trap": false},
	{"module_id": "BIT_X1", "slot_type": "bit", "display": "x1", "k": 1, "is_trap": true},
	{"module_id": "TIME_DIV", "slot_type": "time", "display": "/t", "k": -1, "is_trap": false},
	{"module_id": "TIME_SKIP", "slot_type": "time", "display": "/1", "k": 1, "is_trap": true},
	{"module_id": "OUT_BPS", "slot_type": "out", "display": "bps", "out_unit": "bps", "is_trap": false},
	{"module_id": "OUT_KBPS", "slot_type": "out", "display": "kbps", "out_unit": "kbps", "is_trap": true}
]

enum QuestState { INIT, PIPELINE_BUILD, PIPELINE_READY, CALC_DONE, ANSWERING, FEEDBACK_SUCCESS, FEEDBACK_FAIL, SAFE_MODE, DIAGNOSTIC, DONE }

@onready var btn_back: Button = $SafeArea/Main/V/Header/BtnBack
@onready var lbl_title: Label = $SafeArea/Main/V/Header/LblTitle
@onready var lbl_meta: Label = $SafeArea/Main/V/Header/LblMeta
@onready var stability_bar: ProgressBar = $SafeArea/Main/V/Header/StabilityBar
@onready var palette_select: OptionButton = $SafeArea/Main/V/Header/PaletteSelect
@onready var body: BoxContainer = $SafeArea/Main/V/Body
@onready var lbl_briefing: RichTextLabel = $SafeArea/Main/V/Body/TerminalPane/TerminalMargin/TerminalV/LblBriefing
@onready var lbl_prompt: RichTextLabel = $SafeArea/Main/V/Body/TerminalPane/TerminalMargin/TerminalV/LblPrompt
@onready var lbl_payload: Label = $SafeArea/Main/V/Body/TerminalPane/TerminalMargin/TerminalV/InterceptBox/LblPayload
@onready var lbl_window: Label = $SafeArea/Main/V/Body/TerminalPane/TerminalMargin/TerminalV/InterceptBox/LblWindow
@onready var lbl_target_unit: Label = $SafeArea/Main/V/Body/TerminalPane/TerminalMargin/TerminalV/InterceptBox/LblTargetUnit
@onready var btn_analyze: Button = $SafeArea/Main/V/Body/TerminalPane/TerminalMargin/TerminalV/BtnAnalyze
@onready var log_text: RichTextLabel = $SafeArea/Main/V/Body/TerminalPane/TerminalMargin/TerminalV/LogScroll/LogText
@onready var slot_kilo: PipelineSlotControl = $SafeArea/Main/V/Body/ConsolePane/ConsoleMargin/ConsoleV/PipelineBoard/SlotKilo
@onready var slot_bit: PipelineSlotControl = $SafeArea/Main/V/Body/ConsolePane/ConsoleMargin/ConsoleV/PipelineBoard/SlotBit
@onready var slot_time: PipelineSlotControl = $SafeArea/Main/V/Body/ConsolePane/ConsoleMargin/ConsoleV/PipelineBoard/SlotTime
@onready var slot_out: PipelineSlotControl = $SafeArea/Main/V/Body/ConsolePane/ConsoleMargin/ConsoleV/PipelineBoard/SlotOut
@onready var module_tray: GridContainer = $SafeArea/Main/V/Body/ConsolePane/ConsoleMargin/ConsoleV/ModuleTrayScroll/ModuleTray
@onready var btn_run_calc: Button = $SafeArea/Main/V/Body/ConsolePane/ConsoleMargin/ConsoleV/BtnRunCalc
@onready var lbl_preview: Label = $SafeArea/Main/V/Body/ConsolePane/ConsoleMargin/ConsoleV/LblPreview
@onready var transfer_bar: ProgressBar = $SafeArea/Main/V/Body/ConsolePane/ConsoleMargin/ConsoleV/TransferBar
@onready var lbl_status: Label = $SafeArea/Main/V/Body/AnswersPane/AnswersMargin/AnswersV/LblStatus
@onready var btn_reset: Button = $SafeArea/Main/V/Body/AnswersPane/AnswersMargin/AnswersV/BottomRow/BtnReset
@onready var btn_next: Button = $SafeArea/Main/V/Body/AnswersPane/AnswersMargin/AnswersV/BottomRow/BtnNext
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

var levels: Array[Dictionary] = []
var current_level: Dictionary = {}
var current_level_index: int = 0
var state: int = QuestState.INIT
var wrong_count: int = 0
var level_started_ms: int = 0
var first_action_ms: int = -1
var time_left_sec: float = float(DEFAULT_TIME_LIMIT_SEC)
var timer_running: bool = false
var run_calc_cooldown_until_ms: int = 0
var answer_cooldown_until_ms: int = 0
var spam_clicks: int = 0
var calc_done: bool = false
var calc_bps: int = -1
var calc_display_value: float = 0.0
var calc_display_unit: String = "bps"
var selected_option_id: String = ""
var last_error_code: String = ""
var safe_mode_used: bool = false
var hint_used: bool = false
var logs_expanded: bool = false
var level_finished: bool = false
var result_sent: bool = false
var pipeline_slots_filled_at_ms: int = -1
var module_moves_count: int = 0
var pipeline_mismatch: bool = false
var selected_tray_module: Dictionary = {}
var selected_module_card: PipelineModuleCard = null
var module_cards: Array[PipelineModuleCard] = []
var attempts: Array[Dictionary] = []
var task_session: Dictionary = {}
var variant_hash: String = ""

func _ready() -> void:
	_setup_runtime_controls()
	_connect_signals()
	_apply_palette(PALETTE_GREEN_ID)
	_apply_layout_mode()
	if GlobalMetrics != null and not GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.connect(_on_stability_changed)
	if not _load_levels():
		_show_boot_error("Данные Network Trace B отсутствуют или повреждены.")
		return
	_start_level(0)

func _exit_tree() -> void:
	if GlobalMetrics != null and GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.disconnect(_on_stability_changed)

func _process(delta: float) -> void:
	if state == QuestState.DIAGNOSTIC and not diagnostics_panel.visible and not level_finished:
		state = QuestState.SAFE_MODE if safe_mode_used else QuestState.ANSWERING
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
	lbl_title.text = "СЕТЕВОЙ СЛЕД | B"
	palette_select.clear()
	palette_select.add_item("ЗЕЛЁНЫЙ", PALETTE_GREEN_ID)
	palette_select.add_item("ЯНТАРНЫЙ", PALETTE_AMBER_ID)
	palette_select.select(PALETTE_GREEN_ID)
	slot_kilo.setup("kilo", "БАЗА KILO")
	slot_bit.setup("bit", "БАЙТ В БИТ")
	slot_time.setup("time", "ВРЕМЯ")
	slot_out.setup("out", "ЕДИНИЦА ВЫВОДА")
	transfer_bar.value = 0.0
	btn_next.visible = false
	diagnostics_panel.visible = false
	btn_run_calc.disabled = true

func _connect_signals() -> void:
	btn_back.pressed.connect(_on_back_pressed)
	btn_analyze.pressed.connect(_on_analyze_pressed)
	btn_run_calc.pressed.connect(_on_run_calc_pressed)
	btn_reset.pressed.connect(_on_reset_pressed)
	btn_next.pressed.connect(_on_next_pressed)
	palette_select.item_selected.connect(_on_palette_selected)
	var slots: Array[PipelineSlotControl] = [slot_kilo, slot_bit, slot_time, slot_out]
	for slot in slots:
		slot.module_dropped.connect(_on_slot_module_dropped)
		slot.slot_tapped.connect(_on_slot_tapped)
		slot.clear_pressed.connect(_on_slot_clear_pressed)
		slot.bad_drop.connect(_on_slot_bad_drop)
	for idx in range(action_buttons.size()):
		action_buttons[idx].pressed.connect(_on_answer_pressed.bind(idx))

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
	for key in ["id", "briefing", "prompt", "payload_value", "payload_unit", "time_sec", "ask_unit", "expected_bps", "options", "correct_id", "explain_short", "explain_full", "tags"]:
		if not level.has(key):
			return false
	var payload_unit: String = str(level.get("payload_unit", ""))
	if payload_unit != "KB" and payload_unit != "MB":
		return false
	var ask_unit: String = str(level.get("ask_unit", ""))
	if ask_unit != "bps" and ask_unit != "kbps":
		return false
	if int(level.get("payload_value", 0)) <= 0 or int(level.get("time_sec", 0)) <= 0:
		return false
	var options_var: Variant = level.get("options", [])
	if typeof(options_var) != TYPE_ARRAY:
		return false
	var options: Array = options_var
	if options.size() != 6:
		return false
	var ids: Dictionary = {}
	for option_var in options:
		if typeof(option_var) != TYPE_DICTIONARY:
			return false
		var option: Dictionary = option_var
		var option_id: String = str(option.get("id", ""))
		if option_id.is_empty() or ids.has(option_id):
			return false
		if not option.has("label") or not option.has("error_code"):
			return false
		ids[option_id] = true
	if not ids.has(str(level.get("correct_id", ""))):
		return false
	var modules_var: Variant = level.get("modules_pool", DEFAULT_MODULE_POOL)
	if typeof(modules_var) != TYPE_ARRAY:
		return false
	var modules: Array = modules_var
	var coverage: Dictionary = {"kilo": false, "bit": false, "time": false, "out": false}
	var module_ids: Dictionary = {}
	for module_var in modules:
		if typeof(module_var) != TYPE_DICTIONARY:
			return false
		var module_data: Dictionary = module_var
		if not module_data.has("module_id") or not module_data.has("slot_type") or not module_data.has("display"):
			return false
		var module_id: String = str(module_data.get("module_id", ""))
		if module_id.is_empty() or module_ids.has(module_id):
			return false
		module_ids[module_id] = true
		var slot_type: String = str(module_data.get("slot_type", ""))
		if not coverage.has(slot_type):
			return false
		coverage[slot_type] = true
		if slot_type == "out":
			var out_unit: String = str(module_data.get("out_unit", ""))
			if out_unit != "bps" and out_unit != "kbps":
				return false
		elif not module_data.has("k"):
			return false
	for slot_key in coverage.keys():
		if not bool(coverage[slot_key]):
			return false
	return true

func _show_boot_error(message: String) -> void:
	lbl_status.text = message
	lbl_status.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	for btn in action_buttons:
		btn.disabled = true
	btn_analyze.disabled = true
	btn_run_calc.disabled = true
	btn_reset.disabled = true
	timer_running = false

func _start_level(index: int) -> void:
	if index >= levels.size():
		index = 0
	current_level_index = index
	current_level = levels[index].duplicate(true)
	variant_hash = str(hash(_build_variant_key(current_level)))
	wrong_count = 0
	safe_mode_used = false
	hint_used = false
	logs_expanded = false
	level_finished = false
	result_sent = false
	calc_done = false
	calc_bps = -1
	calc_display_value = 0.0
	calc_display_unit = "bps"
	selected_option_id = ""
	last_error_code = ""
	pipeline_slots_filled_at_ms = -1
	module_moves_count = 0
	pipeline_mismatch = false
	selected_tray_module.clear()
	_set_selected_module_card(null)
	attempts.clear()
	level_started_ms = Time.get_ticks_msec()
	first_action_ms = -1
	time_left_sec = float(int(current_level.get("time_limit_sec", DEFAULT_TIME_LIMIT_SEC)))
	timer_running = true
	task_session = {"task_id": str(current_level.get("id", "NT_B_UNKNOWN")), "variant_hash": variant_hash, "started_at_ticks": level_started_ms, "ended_at_ticks": 0, "attempts": [], "events": []}
	btn_next.visible = false
	btn_analyze.text = "АНАЛИЗ"
	btn_analyze.disabled = false
	diagnostics_panel.visible = false
	_render_terminal_panel()
	_render_options()
	_build_module_tray()
	_reset_pipeline_state()
	lbl_status.text = "Соберите конвейер, запустите расчёт, затем выберите ответ."
	lbl_status.add_theme_color_override("font_color", Color(0.82, 0.82, 0.82))
	state = QuestState.PIPELINE_BUILD
	_update_meta_label()
	_log_event("task_start", {"level": str(current_level.get("id", ""))})

func _render_terminal_panel() -> void:
	lbl_briefing.clear()
	lbl_briefing.append_text("[color=#7a7a7a]ИНСТРУКТАЖ[/color]\n%s" % str(current_level.get("briefing", "")))
	lbl_prompt.clear()
	lbl_prompt.append_text("[color=#9de6b3]ЗАДАНИЕ[/color]\n%s" % str(current_level.get("prompt", "")))
	lbl_payload.text = "Данные: %s %s" % [str(current_level.get("payload_value", 0)), str(current_level.get("payload_unit", "KB"))]
	lbl_window.text = "Окно: %s с" % str(current_level.get("time_sec", 0))
	lbl_target_unit.text = "Целевая единица: %s" % str(current_level.get("ask_unit", "bps"))
	_render_log_text()

func _render_log_text() -> void:
	var lines: Array[String] = []
	var logs_var: Variant = current_level.get("logs", [])
	if typeof(logs_var) == TYPE_ARRAY:
		for line_var in logs_var:
			lines.append(str(line_var))
	if logs_expanded:
		var extra_var: Variant = current_level.get("analyze_lines", [])
		if typeof(extra_var) == TYPE_ARRAY:
			for line_var in extra_var:
				lines.append(str(line_var))
	var text: String = ""
	for line in lines:
		text += "- %s\n" % line
	log_text.text = text

func _render_options() -> void:
	var options_variant: Variant = current_level.get("options", [])
	if typeof(options_variant) != TYPE_ARRAY:
		return
	var options: Array = options_variant
	for idx in range(action_buttons.size()):
		var btn: Button = action_buttons[idx]
		var option: Dictionary = options[idx]
		btn.text = str(option.get("label", ""))
		btn.set_meta("option_id", str(option.get("id", "")))
		btn.set_meta("error_code", str(option.get("error_code", "")))
		btn.disabled = true

func _build_module_tray() -> void:
	for card in module_cards:
		if is_instance_valid(card):
			card.queue_free()
	module_cards.clear()
	var modules: Array[Dictionary] = _get_module_pool_for_level()
	for module_data in modules:
		var card_variant: Variant = MODULE_CARD_SCENE.instantiate()
		var card: PipelineModuleCard = card_variant as PipelineModuleCard
		if card == null:
			continue
		module_tray.add_child(card)
		card.setup(module_data)
		card.module_selected.connect(_on_module_card_selected)
		card.module_drag_started.connect(_on_module_drag_started)
		module_cards.append(card)

func _get_module_pool_for_level() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var modules_var: Variant = current_level.get("modules_pool", null)
	if typeof(modules_var) == TYPE_ARRAY:
		var modules: Array = modules_var
		for module_var in modules:
			if typeof(module_var) == TYPE_DICTIONARY:
				var module_data: Dictionary = module_var
				out.append(module_data.duplicate(true))
	if out.is_empty():
		for module_var in DEFAULT_MODULE_POOL:
			var module_data: Dictionary = module_var
			out.append(module_data.duplicate(true))
	return out

func _reset_pipeline_state() -> void:
	slot_kilo.clear_module()
	slot_bit.clear_module()
	slot_time.clear_module()
	slot_out.clear_module()
	calc_done = false
	calc_bps = -1
	calc_display_value = 0.0
	calc_display_unit = "bps"
	selected_option_id = ""
	last_error_code = ""
	selected_tray_module.clear()
	_set_selected_module_card(null)
	lbl_preview.text = "СКОРОСТЬ = ???"
	transfer_bar.value = 0.0
	btn_run_calc.disabled = true
	_enable_answer_buttons(false)
	state = QuestState.PIPELINE_BUILD

func _on_module_card_selected(module_data: Dictionary, sender: Node) -> void:
	if level_finished:
		return
	_register_first_action()
	_play_audio("click")
	selected_tray_module = module_data.duplicate(true)
	_set_selected_module_card(sender as PipelineModuleCard)
	lbl_status.text = "Модуль выбран. Нажмите подходящий слот."
	lbl_status.add_theme_color_override("font_color", Color(0.84, 0.91, 1.0))
	_log_event("module_selected", {"module_id": str(module_data.get("module_id", ""))})

func _on_module_drag_started(module_data: Dictionary) -> void:
	if level_finished:
		return
	_register_first_action()
	selected_tray_module = module_data.duplicate(true)
	_set_selected_module_card(null)
	_log_event("module_drag_started", {"module_id": str(module_data.get("module_id", ""))})

func _on_slot_tapped(slot_type: String) -> void:
	if level_finished:
		return
	_register_first_action()
	if selected_tray_module.is_empty():
		lbl_status.text = "Сначала выберите модуль из лотка."
		lbl_status.add_theme_color_override("font_color", Color(0.95, 0.86, 0.68))
		return
	_place_module_into_slot(slot_type, selected_tray_module, "tap")

func _on_slot_module_dropped(slot_type: String, module_data: Dictionary) -> void:
	if level_finished:
		return
	_register_first_action()
	_place_module_into_slot(slot_type, module_data, "drag")

func _on_slot_bad_drop(slot_type: String, module_data: Dictionary) -> void:
	if level_finished:
		return
	_register_first_action()
	var slot: PipelineSlotControl = _get_slot(slot_type)
	if slot != null:
		slot.flash_bad_drop()
	_play_audio("error")
	last_error_code = "B_PIPELINE_BAD_DROP"
	lbl_status.text = "Неверный разъём для этого модуля."
	lbl_status.add_theme_color_override("font_color", Color(1.0, 0.55, 0.45))
	_log_event("pipeline_bad_drop", {"slot": slot_type, "module_id": str(module_data.get("module_id", ""))})

func _on_slot_clear_pressed(slot_type: String) -> void:
	if level_finished:
		return
	_register_first_action()
	var slot: PipelineSlotControl = _get_slot(slot_type)
	if slot == null or not slot.has_module():
		return
	var removed_id: String = slot.get_module_id()
	slot.clear_module()
	module_moves_count += 1
	_play_audio("click")
	if calc_done:
		calc_done = false
		calc_bps = -1
		lbl_preview.text = "СКОРОСТЬ = ???"
		_enable_answer_buttons(false)
	lbl_status.text = "Конвейер изменён. Запустите расчёт снова."
	lbl_status.add_theme_color_override("font_color", Color(0.92, 0.88, 0.62))
	_log_event("pipeline_clear", {"slot": slot_type, "module_id": removed_id})
	_update_pipeline_gate()

func _place_module_into_slot(slot_type: String, module_data: Dictionary, source: String) -> void:
	var target_slot: PipelineSlotControl = _get_slot(slot_type)
	if target_slot == null:
		return
	if str(module_data.get("slot_type", "")) != slot_type:
		target_slot.flash_bad_drop()
		_on_slot_bad_drop(slot_type, module_data)
		return
	target_slot.set_module(module_data)
	module_moves_count += 1
	selected_tray_module.clear()
	_set_selected_module_card(null)
	_play_audio("click")
	if calc_done:
		calc_done = false
		calc_bps = -1
		lbl_preview.text = "СКОРОСТЬ = ???"
		_enable_answer_buttons(false)
	lbl_status.text = "Модуль установлен. Продолжайте сборку."
	lbl_status.add_theme_color_override("font_color", Color(0.82, 0.92, 0.86))
	_log_event("pipeline_set", {"slot": slot_type, "module_id": str(module_data.get("module_id", "")), "source": source})
	_update_pipeline_gate()

func _set_selected_module_card(card: PipelineModuleCard) -> void:
	selected_module_card = card
	for module_card in module_cards:
		if is_instance_valid(module_card):
			module_card.set_selected(module_card == selected_module_card)

func _get_slot(slot_type: String) -> PipelineSlotControl:
	match slot_type:
		"kilo":
			return slot_kilo
		"bit":
			return slot_bit
		"time":
			return slot_time
		"out":
			return slot_out
		_:
			return null

func _update_pipeline_gate() -> void:
	var ready: bool = _pipeline_ready()
	btn_run_calc.disabled = (not ready) or level_finished
	if ready and pipeline_slots_filled_at_ms < 0:
		pipeline_slots_filled_at_ms = Time.get_ticks_msec() - level_started_ms
		lbl_status.text = "КОНВЕЙЕР ЗАФИКСИРОВАН. Запустите расчёт."
		lbl_status.add_theme_color_override("font_color", Color(0.72, 0.95, 0.86))
		_log_event("pipeline_complete", {"t_ms": pipeline_slots_filled_at_ms})
	if not calc_done:
		state = QuestState.PIPELINE_READY if ready else QuestState.PIPELINE_BUILD

func _pipeline_ready() -> bool:
	return slot_kilo.has_module() and slot_bit.has_module() and slot_time.has_module() and slot_out.has_module()

func _on_run_calc_pressed() -> void:
	if level_finished:
		return
	var now_ms: int = Time.get_ticks_msec()
	if now_ms < run_calc_cooldown_until_ms:
		spam_clicks += 1
		_log_event("run_calc_spam", {})
		return
	if not _pipeline_ready():
		_record_pipeline_incomplete("run_calc_without_pipeline")
		lbl_status.text = ERROR_MAP.get_error_tip("B_PIPELINE_INCOMPLETE")
		lbl_status.add_theme_color_override("font_color", Color(1.0, 0.55, 0.45))
		return
	run_calc_cooldown_until_ms = now_ms + RUN_COOLDOWN_MS
	_register_first_action()
	_play_audio("click")
	calc_bps = _calculate_bps_from_pipeline()
	calc_display_unit = _current_output_unit()
	calc_display_value = float(calc_bps) / 1000.0 if calc_display_unit == "kbps" else float(calc_bps)
	calc_done = true
	lbl_preview.text = "СКОРОСТЬ = %s" % _format_rate(calc_bps, calc_display_unit)
	lbl_status.text = "Расчёт завершён. Выберите финальный ответ."
	lbl_status.add_theme_color_override("font_color", Color(0.68, 0.95, 0.72))
	_enable_answer_buttons(true)
	state = QuestState.ANSWERING
	_log_event("run_calc", {"calc_bps": calc_bps, "display_unit": calc_display_unit, "display_value": calc_display_value, "pipeline_correct": _is_pipeline_correct(), "pipeline_error": _derive_pipeline_error_code()})

func _calculate_bps_from_pipeline() -> int:
	var payload_value: int = int(current_level.get("payload_value", 0))
	var payload_unit: String = str(current_level.get("payload_unit", "KB"))
	var kilo_base: int = int(slot_kilo.get_module().get("k", 1024))
	var bit_mult: int = int(slot_bit.get_module().get("k", 8))
	var use_time_division: bool = _time_division_enabled(slot_time.get_module())
	var time_sec: int = int(current_level.get("time_sec", 1))
	var bytes_total: int = payload_value * kilo_base
	if payload_unit == "MB":
		bytes_total *= kilo_base
	var bits_total: int = bytes_total * bit_mult
	var divisor: int = time_sec if use_time_division else 1
	if divisor <= 0:
		divisor = 1
	return int(round(float(bits_total) / float(divisor)))

func _time_division_enabled(time_module: Dictionary) -> bool:
	if str(time_module.get("module_id", "")) == "TIME_DIV":
		return true
	return int(time_module.get("k", 1)) < 0

func _current_output_unit() -> String:
	var out_unit: String = str(slot_out.get_module().get("out_unit", "bps"))
	return "kbps" if out_unit == "kbps" else "bps"

func _derive_pipeline_error_code() -> String:
	if not _pipeline_ready():
		return "B_PIPELINE_INCOMPLETE"
	if int(slot_bit.get_module().get("k", 8)) != 8:
		return "B_MATH_X8"
	if int(slot_kilo.get_module().get("k", 1024)) != 1024:
		return "B_MATH_1024"
	if not _time_division_enabled(slot_time.get_module()):
		return "B_MATH_DIV"
	if _current_output_unit() != str(current_level.get("ask_unit", "bps")):
		return "B_UNIT_TRAP"
	return ""

func _is_pipeline_correct() -> bool:
	return _derive_pipeline_error_code().is_empty()

func _on_answer_pressed(index: int) -> void:
	if level_finished or index < 0 or index >= action_buttons.size():
		return
	var now_ms: int = Time.get_ticks_msec()
	if now_ms < answer_cooldown_until_ms:
		spam_clicks += 1
		return
	answer_cooldown_until_ms = now_ms + ANSWER_COOLDOWN_MS
	_register_first_action()
	if state != QuestState.ANSWERING or not calc_done:
		_record_pipeline_incomplete("answer_before_calc")
		lbl_status.text = ERROR_MAP.get_error_tip("B_PIPELINE_INCOMPLETE")
		lbl_status.add_theme_color_override("font_color", Color(1.0, 0.55, 0.45))
		return
	var btn: Button = action_buttons[index]
	selected_option_id = str(btn.get_meta("option_id", ""))
	if selected_option_id.is_empty():
		return
	_play_audio("click")
	_enable_answer_buttons(false)
	var answer_correct: bool = selected_option_id == str(current_level.get("correct_id", ""))
	var pipeline_correct: bool = _is_pipeline_correct()
	pipeline_mismatch = answer_correct and not pipeline_correct
	if answer_correct:
		last_error_code = "B_PIPELINE_MISMATCH" if pipeline_mismatch else ""
	else:
		last_error_code = str(btn.get_meta("error_code", "UNKNOWN"))
		if last_error_code.is_empty():
			last_error_code = _derive_pipeline_error_code()
	var attempt: Dictionary = {"option_id": selected_option_id, "error_code": last_error_code, "correct": answer_correct, "pipeline_correct": pipeline_correct, "pipeline_mismatch": pipeline_mismatch, "calc_bps": calc_bps, "t_ms": now_ms - level_started_ms}
	attempts.append(attempt)
	var session_attempts: Array = task_session.get("attempts", [])
	session_attempts.append(attempt)
	task_session["attempts"] = session_attempts
	_log_event("answer_selected", attempt)
	await _simulate_transfer(answer_correct)
	if answer_correct:
		_handle_success(pipeline_mismatch)
	else:
		_handle_failure(last_error_code)
	if not level_finished and (state == QuestState.ANSWERING or state == QuestState.SAFE_MODE):
		_enable_answer_buttons(true)

func _simulate_transfer(success: bool) -> void:
	transfer_bar.value = 0.0
	var expected_bps: int = int(current_level.get("expected_bps", 1))
	var target: float = 100.0
	if not success:
		var ratio: float = float(calc_bps) / maxf(1.0, float(expected_bps))
		target = clampf(ratio * 100.0, 40.0, 80.0)
	var tween: Tween = create_tween()
	tween.tween_property(transfer_bar, "value", target, 1.2)
	await tween.finished

func _handle_success(has_pipeline_mismatch: bool) -> void:
	state = QuestState.FEEDBACK_SUCCESS
	if has_pipeline_mismatch:
		lbl_status.text = "Ответ принят. Отмечено расхождение в конвейере."
		lbl_status.add_theme_color_override("font_color", Color(0.98, 0.82, 0.56))
	else:
		lbl_status.text = "ЗАГРУЗКА ЗАВЕРШЕНА. %s" % str(current_level.get("explain_short", ""))
		lbl_status.add_theme_color_override("font_color", Color(0.35, 1.0, 0.45))
	_play_audio("relay")
	_finish_level(true, "success_with_mismatch" if has_pipeline_mismatch else "success")

func _handle_failure(error_code: String) -> void:
	state = QuestState.FEEDBACK_FAIL
	wrong_count += 1
	_play_audio("error")
	_trigger_glitch()
	lbl_status.text = "%s: %s" % [ERROR_MAP.get_error_title(error_code), ERROR_MAP.get_error_tip(error_code)]
	lbl_status.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	_update_meta_label()
	if wrong_count >= 2 and not safe_mode_used:
		safe_mode_used = true
		btn_analyze.text = "ДИАГНОСТИКА"
		lbl_status.text = "Безопасный режим разблокирован. Откройте диагностику."
		lbl_status.add_theme_color_override("font_color", Color(1.0, 0.75, 0.45))
	if wrong_count >= MAX_ATTEMPTS:
		_show_diagnostics("attempt_limit")
		_finish_level(false, "attempt_limit")
	else:
		state = QuestState.SAFE_MODE if safe_mode_used else QuestState.ANSWERING

func _on_analyze_pressed() -> void:
	if level_finished:
		return
	_register_first_action()
	_play_audio("click")
	if safe_mode_used:
		if not hint_used:
			hint_used = true
		_show_diagnostics("manual")
		state = QuestState.DIAGNOSTIC
		return
	if logs_expanded:
		lbl_status.text = "Строки анализа уже раскрыты."
		lbl_status.add_theme_color_override("font_color", Color(0.9, 0.85, 0.65))
		return
	logs_expanded = true
	hint_used = true
	_render_log_text()
	lbl_status.text = "Дополнительная телеметрия разблокирована."
	lbl_status.add_theme_color_override("font_color", Color(0.72, 0.95, 0.86))
	_log_event("analyze_reveal", {})

func _show_diagnostics(reason: String) -> void:
	var lines: Array[String] = []
	lines.append("Дело: %s" % str(current_level.get("id", "")))
	lines.append("Причина: %s" % reason)
	lines.append("Конвейер собран к: %d мс" % pipeline_slots_filled_at_ms)
	lines.append("Перемещений модулей: %d" % module_moves_count)
	lines.append("Кило: %s" % slot_kilo.get_module_id())
	lines.append("Бит: %s" % slot_bit.get_module_id())
	lines.append("Время: %s" % slot_time.get_module_id())
	lines.append("Выход: %s" % slot_out.get_module_id())
	if calc_bps >= 0:
		lines.append("Рассчитано: %s" % _format_rate(calc_bps, calc_display_unit))
	lines.append("Ожидается: %d bps" % int(current_level.get("expected_bps", 0)))
	lines.append("Конвейер корректен: %s" % ("да" if _is_pipeline_correct() else "нет"))
	var pipeline_error: String = _derive_pipeline_error_code()
	if not pipeline_error.is_empty():
		lines.append("Ошибка конвейера: %s" % pipeline_error)
		lines.append(ERROR_MAP.get_error_tip(pipeline_error))
	if not last_error_code.is_empty():
		lines.append("Ошибка ответа: %s" % last_error_code)
		lines.append(ERROR_MAP.get_error_tip(last_error_code))
		for detail in ERROR_MAP.detail_messages(last_error_code):
			lines.append(detail)
	var explain_full: String = str(current_level.get("explain_full", ""))
	if not explain_full.is_empty():
		for explain_line_var in explain_full.split("\n"):
			var explain_line: String = explain_line_var.strip_edges()
			if not explain_line.is_empty():
				lines.append(explain_line)
	if diagnostics_panel.has_method("setup"):
		diagnostics_panel.call("setup", "ДИАГНОСТИКА", lines)
	diagnostics_panel.visible = true
	_log_event("diagnostics_open", {"reason": reason})

func _on_reset_pressed() -> void:
	if level_finished:
		return
	_register_first_action()
	_play_audio("click")
	_reset_pipeline_state()
	lbl_status.text = "Конвейер сброшен. Соберите и запустите снова."
	lbl_status.add_theme_color_override("font_color", Color(0.82, 0.86, 0.96))
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
			shader_material.set_shader_parameter("tint_color", Color(1.0, 0.69, 0.0, 1.0))
	else:
		theme = THEME_GREEN
		if shader_material != null:
			shader_material.set_shader_parameter("tint_color", Color(0.0, 1.0, 0.25, 1.0))

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
	var stability_value: float = 100.0
	if GlobalMetrics != null:
		stability_value = float(GlobalMetrics.stability)
	lbl_meta.text = "ДЕЛО %s | ОШ %d/%d | T-%02d:%02d" % [str(current_level.get("id", "--")), wrong_count, MAX_ATTEMPTS, total_seconds / 60, total_seconds % 60]
	stability_bar.value = stability_value

func _on_stability_changed(_new_value: float, _delta: float) -> void:
	_update_meta_label()

func _register_first_action() -> void:
	if first_action_ms < 0:
		first_action_ms = Time.get_ticks_msec() - level_started_ms

func _record_pipeline_incomplete(source: String) -> void:
	var attempt: Dictionary = {"option_id": "", "error_code": "B_PIPELINE_INCOMPLETE", "correct": false, "pipeline_correct": false, "pipeline_mismatch": false, "calc_bps": calc_bps, "t_ms": Time.get_ticks_msec() - level_started_ms, "source": source}
	attempts.append(attempt)
	var session_attempts: Array = task_session.get("attempts", [])
	session_attempts.append(attempt)
	task_session["attempts"] = session_attempts
	_log_event("pipeline_incomplete", {"source": source})

func _on_timeout() -> void:
	if level_finished:
		return
	last_error_code = "TIMEOUT"
	var timeout_attempt: Dictionary = {"option_id": "TIMEOUT", "error_code": "TIMEOUT", "correct": false, "pipeline_correct": _is_pipeline_correct(), "pipeline_mismatch": false, "calc_bps": calc_bps, "t_ms": Time.get_ticks_msec() - level_started_ms}
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
	btn_run_calc.disabled = true
	btn_reset.disabled = true
	_enable_answer_buttons(false)
	btn_next.visible = true
	for card in module_cards:
		if is_instance_valid(card):
			card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var end_tick: int = Time.get_ticks_msec()
	task_session["ended_at_ticks"] = end_tick
	_log_event("task_end", {"is_correct": is_correct, "reason": reason})
	if not is_correct and reason != "timeout":
		lbl_status.text = str(current_level.get("explain_short", "Проверьте диагностику."))
		lbl_status.add_theme_color_override("font_color", Color(1.0, 0.62, 0.45))
	var elapsed_ms: int = end_tick - level_started_ms
	var stability_delta: float = float(wrong_count) * FAIL_STABILITY_DELTA
	if not is_correct and wrong_count == 0:
		stability_delta += FAIL_STABILITY_DELTA
	if hint_used:
		stability_delta += HINT_STABILITY_DELTA
	if pipeline_mismatch:
		stability_delta += PIPELINE_MISMATCH_DELTA
	var payload: Dictionary = {
		"quest": "network_trace",
		"stage": "B",
		"task_id": str(current_level.get("id", "")),
		"match_key": "NETTRACE_B|%s" % str(current_level.get("id", "")),
		"variant_hash": variant_hash,
		"is_correct": is_correct,
		"is_fit": is_correct,
		"payload_value": int(current_level.get("payload_value", 0)),
		"payload_unit": str(current_level.get("payload_unit", "KB")),
		"time_sec": int(current_level.get("time_sec", 0)),
		"ask_unit": str(current_level.get("ask_unit", "bps")),
		"expected_bps": int(current_level.get("expected_bps", 0)),
		"pipeline_slots_filled_at_ms": pipeline_slots_filled_at_ms,
		"module_moves_count": module_moves_count,
		"pipeline_selected": {"kilo_module_id": slot_kilo.get_module_id(), "bit_module_id": slot_bit.get_module_id(), "time_module_id": slot_time.get_module_id(), "out_module_id": slot_out.get_module_id()},
		"pipeline_correct": _is_pipeline_correct(),
		"pipeline_mismatch": pipeline_mismatch,
		"calc_bps": calc_bps,
		"calc_display_value": calc_display_value,
		"calc_display_unit": calc_display_unit,
		"selected_option_id": selected_option_id,
		"error_code_last": last_error_code,
		"attempts": attempts,
		"attempts_count": attempts.size(),
		"elapsed_ms": elapsed_ms,
		"duration": float(elapsed_ms) / 1000.0,
		"safe_mode_used": safe_mode_used,
		"time_to_first_action_ms": first_action_ms,
		"spam_clicks": spam_clicks,
		"hint_used": hint_used,
		"timed_out": reason == "timeout",
		"stability_delta": stability_delta,
		"task_session": task_session
	}
	GlobalMetrics.register_trial(payload)

func _enable_answer_buttons(enabled: bool) -> void:
	for btn in action_buttons:
		btn.disabled = not enabled or level_finished

func _log_event(name: String, payload: Dictionary) -> void:
	var events: Array = task_session.get("events", [])
	events.append({"name": name, "t_ms": Time.get_ticks_msec() - level_started_ms, "payload": payload})
	task_session["events"] = events

func _build_variant_key(level: Dictionary) -> String:
	var option_ids: Array[String] = []
	var options_var: Variant = level.get("options", [])
	if typeof(options_var) == TYPE_ARRAY:
		var options: Array = options_var
		for option_var in options:
			var option: Dictionary = option_var
			option_ids.append(str(option.get("id", "")))
	option_ids.sort()
	return "%s|%s|%s|%s|%s|%s" % [str(level.get("id", "")), str(level.get("payload_value", 0)), str(level.get("payload_unit", "KB")), str(level.get("time_sec", 0)), str(level.get("ask_unit", "bps")), ",".join(option_ids)]

func _format_rate(value_bps: int, ask_unit: String) -> String:
	if ask_unit == "kbps":
		return "%.3f kbps" % (float(value_bps) / 1000.0)
	return "%d bps" % value_bps

func _apply_layout_mode() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	body.vertical = viewport_size.x < viewport_size.y
	module_tray.columns = 2 if body.vertical else 4


