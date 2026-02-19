extends Control

const THEME_GREEN: Theme = preload("res://ui/theme_terminal_green.tres")
const THEME_AMBER: Theme = preload("res://ui/theme_terminal_amber.tres")
const ERROR_MAP = preload("res://scripts/ssot/network_trace_errors.gd")
const DEVICE_CARD_SCENE: PackedScene = preload("res://scenes/ui/network_trace/NetworkTraceDeviceCard.tscn")

const LEVELS_PATH := "res://data/network_trace_a_levels.json"
const MAX_ATTEMPTS := 3
const DEFAULT_TIME_LIMIT_SEC := 120
const RUN_COOLDOWN_MS := 500
const FAIL_STABILITY_DELTA := -10.0
const HINT_STABILITY_DELTA := -5.0
const PALETTE_GREEN_ID := 0
const PALETTE_AMBER_ID := 1

enum QuestState {
	INIT,
	BRIEFING,
	SOLVING,
	FEEDBACK_SUCCESS,
	FEEDBACK_FAIL,
	SAFE_MODE,
	DIAGNOSTIC
}

@onready var btn_back: Button = $Main/V/Header/BtnBack
@onready var lbl_title: Label = $Main/V/Header/LblTitle
@onready var lbl_meta: Label = $Main/V/Header/LblMeta
@onready var palette_select: OptionButton = $Main/V/Header/PaletteSelect
@onready var body: BoxContainer = $Main/V/Body
@onready var lbl_briefing: RichTextLabel = $Main/V/Body/TerminalPane/TerminalMargin/TerminalV/LblBriefing
@onready var lbl_prompt: RichTextLabel = $Main/V/Body/TerminalPane/TerminalMargin/TerminalV/LblPrompt
@onready var log_list: VBoxContainer = $Main/V/Body/TerminalPane/TerminalMargin/TerminalV/LogScroll/LogList
@onready var evidence_row: HBoxContainer = $Main/V/Body/TerminalPane/TerminalMargin/TerminalV/EvidenceRow
@onready var topology_board: NetworkTraceTopologyBoardA = $Main/V/Body/MapPane/MapMargin/MapV/TopologyBoard
@onready var palette_box: HBoxContainer = $Main/V/Body/MapPane/MapMargin/MapV/PaletteScroll/Palette
@onready var btn_analyze: Button = $Main/V/Body/MapPane/MapMargin/MapV/Actions/BtnAnalyze
@onready var btn_run_trace: Button = $Main/V/Body/MapPane/MapMargin/MapV/Actions/BtnRunTrace
@onready var btn_reset: Button = $Main/V/Body/MapPane/MapMargin/MapV/Actions/BtnReset
@onready var btn_next: Button = $Main/V/Body/MapPane/MapMargin/MapV/Actions/BtnNext
@onready var lbl_status: Label = $Main/V/Body/MapPane/MapMargin/MapV/LblStatus
@onready var diagnostics_panel: PanelContainer = $DiagnosticsPanel
@onready var crt_overlay: ColorRect = $CanvasLayer/CRT_Overlay

var levels: Array[Dictionary] = []
var current_level: Dictionary = {}
var current_level_index: int = 0

var state: int = QuestState.INIT
var wrong_count: int = 0
var safe_mode_used: bool = false
var hint_used: bool = false
var level_finished: bool = false
var result_sent: bool = false
var run_in_progress: bool = false
var run_cooldown_until_ms: int = 0
var spam_clicks: int = 0

var level_started_ms: int = 0
var first_action_ms: int = -1
var time_limit_sec: int = DEFAULT_TIME_LIMIT_SEC
var time_left_sec: float = float(DEFAULT_TIME_LIMIT_SEC)
var timer_running: bool = false

var required_evidence: int = 2
var selected_evidence_indices: Array[int] = []
var log_buttons: Array[Button] = []
var evidence_slot_labels: Array[Label] = []

var selected_device_id: String = ""
var selected_error_code: String = ""

var attempts: Array[Dictionary] = []
var task_session: Dictionary = {}
var variant_hash: String = ""

var palette_cards: Array[NetworkTraceDeviceCard] = []

func _ready() -> void:
	_setup_palette_controls()
	_connect_signals()
	_apply_palette(PALETTE_GREEN_ID)
	_apply_layout_mode()

	if GlobalMetrics != null and not GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.connect(_on_stability_changed)

	if not _load_levels():
		_show_boot_error("Данные Network Trace A отсутствуют или повреждены.")
		return

	_start_level(0)

func _exit_tree() -> void:
	if GlobalMetrics != null and GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.disconnect(_on_stability_changed)

func _process(delta: float) -> void:
	if state == QuestState.DIAGNOSTIC and not diagnostics_panel.visible and not level_finished:
		state = QuestState.SAFE_MODE if safe_mode_used else QuestState.SOLVING

	if timer_running and not level_finished:
		time_left_sec -= delta
		if time_left_sec <= 0.0:
			time_left_sec = 0.0
			_update_meta_label()
			_on_timeout()
		else:
			_update_meta_label()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		if not is_node_ready():
			return
		_apply_layout_mode()

func _setup_palette_controls() -> void:
	palette_select.clear()
	palette_select.add_item("ЗЕЛЁНЫЙ", PALETTE_GREEN_ID)
	palette_select.add_item("ЯНТАРНЫЙ", PALETTE_AMBER_ID)
	palette_select.select(PALETTE_GREEN_ID)

func _connect_signals() -> void:
	btn_back.pressed.connect(_on_back_pressed)
	btn_analyze.pressed.connect(_on_analyze_pressed)
	btn_run_trace.pressed.connect(_on_run_trace_pressed)
	btn_reset.pressed.connect(_on_reset_pressed)
	btn_next.pressed.connect(_on_next_pressed)
	palette_select.item_selected.connect(_on_palette_selected)
	
	topology_board.device_installed.connect(_on_device_installed)
	topology_board.device_removed.connect(_on_device_removed)

func _load_levels() -> bool:
	var file: FileAccess = FileAccess.open(LEVELS_PATH, FileAccess.READ)
	if file == null:
		push_error("Cannot open %s" % LEVELS_PATH)
		return false

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_error("Expected array in %s" % LEVELS_PATH)
		return false

	var raw_levels: Array = parsed
	levels.clear()
	for level_var in raw_levels:
		if typeof(level_var) != TYPE_DICTIONARY:
			continue
		var level: Dictionary = level_var
		if _validate_level(level):
			levels.append(level)
		elif OS.is_debug_build():
			push_error("Invalid Network Trace A level: %s" % str(level.get("id", "UNKNOWN")))
			return false
		else:
			push_warning("Skipping invalid level: %s" % str(level.get("id", "UNKNOWN")))

	return not levels.is_empty()

func _validate_level(level: Dictionary) -> bool:
	var required_keys: Array[String] = [
		"id", "incident_id", "briefing", "prompt", "required_evidence", "logs", "topology", "options", "correct_id", "explain_short", "explain_full", "tags"
	]
	for key in required_keys:
		if not level.has(key):
			return false

	if typeof(level.get("logs")) != TYPE_ARRAY:
		return false
	if typeof(level.get("options")) != TYPE_ARRAY:
		return false
	if typeof(level.get("topology")) != TYPE_DICTIONARY:
		return false

	var logs: Array = level.get("logs", [])
	if logs.size() < 3:
		return false

	var required_count: int = int(level.get("required_evidence", 0))
	if required_count <= 0 or required_count > logs.size():
		return false

	var options: Array = level.get("options", [])
	if options.size() < 4 or options.size() > 6:
		return false

	var ids: Dictionary = {}
	for option_var in options:
		if typeof(option_var) != TYPE_DICTIONARY:
			return false
		var option: Dictionary = option_var
		if not option.has("id") or not option.has("label") or not option.has("error_code"):
			return false
		var option_id: String = str(option.get("id", ""))
		if option_id.is_empty() or ids.has(option_id):
			return false
		ids[option_id] = true

	var correct_id: String = str(level.get("correct_id", ""))
	if not ids.has(correct_id):
		return false

	var topology: Dictionary = level.get("topology", {})
	if typeof(topology.get("nodes", [])) != TYPE_ARRAY:
		return false
	if typeof(topology.get("edges", [])) != TYPE_ARRAY:
		return false

	return true

func _show_boot_error(message: String) -> void:
	lbl_status.text = message
	lbl_status.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	btn_run_trace.disabled = true
	btn_analyze.disabled = true
	btn_reset.disabled = true
	btn_next.disabled = true
	timer_running = false

func _start_level(index: int) -> void:
	if levels.is_empty():
		return

	if index >= levels.size():
		index = 0
	current_level_index = index
	current_level = levels[index].duplicate(true)
	variant_hash = str(hash(_build_variant_key(current_level)))

	state = QuestState.BRIEFING
	wrong_count = 0
	safe_mode_used = false
	hint_used = false
	level_finished = false
	result_sent = false
	run_in_progress = false
	run_cooldown_until_ms = 0
	spam_clicks = 0
	selected_device_id = ""
	selected_error_code = ""
	selected_evidence_indices.clear()
	attempts.clear()

	level_started_ms = Time.get_ticks_msec()
	first_action_ms = -1
	time_limit_sec = int(current_level.get("time_limit_sec", DEFAULT_TIME_LIMIT_SEC))
	time_left_sec = float(time_limit_sec)
	timer_running = true

	required_evidence = int(current_level.get("required_evidence", 2))

	task_session = {
		"task_id": str(current_level.get("id", "NT_A_UNKNOWN")),
		"variant_hash": variant_hash,
		"started_at_ticks": level_started_ms,
		"ended_at_ticks": 0,
		"attempts": [],
		"events": []
	}

	lbl_title.text = "СЕТЕВОЙ СЛЕД | A"
	btn_next.visible = false
	btn_next.disabled = false
	btn_analyze.text = "АНАЛИЗ"
	btn_analyze.disabled = true
	btn_run_trace.disabled = true
	btn_reset.disabled = true
	diagnostics_panel.visible = false

	_render_text_blocks()
	_build_log_items()
	_build_evidence_slots()
	_setup_topology()
	_build_palette()
	_set_tools_unlocked(false)

	lbl_status.text = "Соберите улики (%d/%d), чтобы разблокировать инструменты." % [selected_evidence_indices.size(), required_evidence]
	lbl_status.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

	_update_meta_label()
	_log_event("task_start", {"level": str(current_level.get("id", ""))})

func _render_text_blocks() -> void:
	lbl_briefing.clear()
	lbl_briefing.append_text("[color=#7a7a7a]ИНСТРУКТАЖ[/color]\n%s" % str(current_level.get("briefing", "")))

	lbl_prompt.clear()
	lbl_prompt.append_text("[color=#9de6b3]ЗАДАНИЕ[/color]\n%s" % str(current_level.get("prompt", "")))

func _build_log_items() -> void:
	for child in log_list.get_children():
		child.queue_free()
	log_buttons.clear()

	var logs: Array = current_level.get("logs", [])
	for idx in range(logs.size()):
		var log_line: String = str(logs[idx])
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(0, 48)
		btn.toggle_mode = true
		btn.text = "[%d] %s" % [idx + 1, log_line]
		btn.pressed.connect(_on_log_pressed.bind(idx))
		log_list.add_child(btn)
		log_buttons.append(btn)

func _build_evidence_slots() -> void:
	for child in evidence_row.get_children():
		child.queue_free()
	evidence_slot_labels.clear()

	for idx in range(required_evidence):
		var slot_panel: PanelContainer = PanelContainer.new()
		slot_panel.custom_minimum_size = Vector2(0, 54)
		slot_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var slot_label: Label = Label.new()
		slot_label.text = "УЛИКА %d" % (idx + 1)
		slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		slot_panel.add_child(slot_label)
		evidence_row.add_child(slot_panel)
		evidence_slot_labels.append(slot_label)

	_update_evidence_visuals()

func _setup_topology() -> void:
	var topology: Dictionary = current_level.get("topology", {})
	topology_board.setup_topology(topology)
	topology_board.set_tools_locked(true)

func _build_palette() -> void:
	for child in palette_box.get_children():
		child.queue_free()
	palette_cards.clear()

	var options: Array = current_level.get("options", [])
	for option_var in options:
		var option: Dictionary = option_var
		var card_node: Node = DEVICE_CARD_SCENE.instantiate()
		if card_node is NetworkTraceDeviceCard:
			var card: NetworkTraceDeviceCard = card_node
			card.setup(str(option.get("id", "")), str(option.get("label", "")), str(option.get("error_code", "")))
			card.disabled = true
			palette_box.add_child(card)
			palette_cards.append(card)

func _set_tools_unlocked(unlocked: bool) -> void:
	for card in palette_cards:
		card.disabled = not unlocked
	topology_board.set_tools_locked(not unlocked)

	if not unlocked:
		selected_device_id = ""
		selected_error_code = ""
		btn_run_trace.disabled = true
		btn_reset.disabled = true
		topology_board.clear_installed_device()
	else:
		btn_run_trace.disabled = selected_device_id.is_empty()
		btn_reset.disabled = selected_device_id.is_empty()

func _on_log_pressed(log_index: int) -> void:
	if level_finished:
		return
	_register_first_action()

	if selected_evidence_indices.has(log_index):
		selected_evidence_indices.erase(log_index)
	else:
		selected_evidence_indices.append(log_index)
	selected_evidence_indices.sort()

	for idx in range(log_buttons.size()):
		var btn: Button = log_buttons[idx]
		btn.button_pressed = selected_evidence_indices.has(idx)

	_update_evidence_visuals()
	_log_event("evidence_toggled", {"index": log_index, "count": selected_evidence_indices.size()})

	if selected_evidence_indices.size() >= required_evidence and state == QuestState.BRIEFING:
		state = QuestState.SOLVING
		_set_tools_unlocked(true)
		lbl_status.text = "Инструменты разблокированы. Перетащите устройство в слот и запустите трассировку."
		lbl_status.add_theme_color_override("font_color", Color(0.6, 0.95, 0.7))
	elif selected_evidence_indices.size() < required_evidence:
		state = QuestState.BRIEFING
		_set_tools_unlocked(false)
		lbl_status.text = "Соберите улики (%d/%d), чтобы разблокировать инструменты." % [selected_evidence_indices.size(), required_evidence]
		lbl_status.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

func _update_evidence_visuals() -> void:
	var logs: Array = current_level.get("logs", [])
	for slot_index in range(evidence_slot_labels.size()):
		var slot_label: Label = evidence_slot_labels[slot_index]
		if slot_index < selected_evidence_indices.size():
			var log_index: int = selected_evidence_indices[slot_index]
			if log_index >= 0 and log_index < logs.size():
				slot_label.text = str(logs[log_index])
			else:
				slot_label.text = "УЛИКА %d" % (slot_index + 1)
		else:
			slot_label.text = "УЛИКА %d" % (slot_index + 1)

func _on_device_installed(device_id: String, _label_text: String, error_code: String) -> void:
	selected_device_id = device_id
	selected_error_code = error_code
	btn_run_trace.disabled = selected_device_id.is_empty() or level_finished
	btn_reset.disabled = selected_device_id.is_empty() or level_finished
	lbl_status.text = "Устройство установлено. Нажмите ЗАПУСТИТЬ ТРАССИРОВКУ."
	lbl_status.add_theme_color_override("font_color", Color(0.75, 0.95, 0.8))
	_log_event("device_installed", {"device_id": device_id})

func _on_device_removed() -> void:
	selected_device_id = ""
	selected_error_code = ""
	btn_run_trace.disabled = true
	btn_reset.disabled = true
	_log_event("device_removed", {})

func _on_run_trace_pressed() -> void:
	if level_finished:
		return
	if run_in_progress:
		spam_clicks += 1
		return
	if selected_evidence_indices.size() < required_evidence:
		lbl_status.text = ERROR_MAP.get_error_tip("A_WRONG_EVIDENCE")
		lbl_status.add_theme_color_override("font_color", Color(1.0, 0.55, 0.45))
		return
	if selected_device_id.is_empty():
		lbl_status.text = "Сначала установите устройство в слот."
		lbl_status.add_theme_color_override("font_color", Color(1.0, 0.55, 0.45))
		return

	var now_ms: int = Time.get_ticks_msec()
	if now_ms < run_cooldown_until_ms:
		spam_clicks += 1
		return
	run_cooldown_until_ms = now_ms + RUN_COOLDOWN_MS

	_register_first_action()
	_play_audio("click")
	_lock_controls_for_trace(true)
	run_in_progress = true

	var is_correct: bool = selected_device_id == str(current_level.get("correct_id", ""))
	var error_code: String = "" if is_correct else selected_error_code
	if error_code.is_empty() and not is_correct:
		error_code = "UNKNOWN"

	var attempt: Dictionary = {
		"device_id": selected_device_id,
		"error_code": error_code,
		"correct": is_correct,
		"t_ms": now_ms - level_started_ms
	}
	attempts.append(attempt)
	var session_attempts: Array = task_session.get("attempts", [])
	session_attempts.append(attempt)
	task_session["attempts"] = session_attempts
	_log_event("run_trace", {
		"device_id": selected_device_id,
		"correct": is_correct,
		"error_code": error_code
	})

	await topology_board.play_trace_animation(is_correct)
	run_in_progress = false
	if level_finished:
		return

	if is_correct:
		_handle_success()
	else:
		_handle_failure(error_code)

	if not level_finished:
		_lock_controls_for_trace(false)
		btn_run_trace.disabled = selected_device_id.is_empty()
		btn_reset.disabled = selected_device_id.is_empty()

func _lock_controls_for_trace(locked: bool) -> void:
	btn_run_trace.disabled = locked
	btn_reset.disabled = locked
	for card in palette_cards:
		card.disabled = locked or state == QuestState.BRIEFING
	topology_board.set_tools_locked(locked or state == QuestState.BRIEFING)

func _handle_success() -> void:
	state = QuestState.FEEDBACK_SUCCESS
	lbl_status.text = "ТРАССИРОВКА OK: путь установлен."
	lbl_status.add_theme_color_override("font_color", Color(0.35, 1.0, 0.45))
	_play_audio("relay")
	_log_event("trace_success", {"device_id": selected_device_id})
	_finish_level(true, "success")

func _handle_failure(error_code: String) -> void:
	state = QuestState.FEEDBACK_FAIL
	wrong_count += 1
	_play_audio("error")
	_trigger_glitch()

	var title: String = ERROR_MAP.get_error_title(error_code)
	var tip: String = ERROR_MAP.get_error_tip(error_code)
	lbl_status.text = "%s: %s" % [title, tip]
	lbl_status.add_theme_color_override("font_color", Color(1.0, 0.38, 0.38))
	_update_meta_label()

	_log_event("trace_fail", {"error_code": error_code, "wrong_count": wrong_count})

	if wrong_count >= 2 and not safe_mode_used:
		safe_mode_used = true
		state = QuestState.SAFE_MODE
		btn_analyze.disabled = false
		btn_analyze.text = "ДИАГНОСТИКА"
		lbl_status.text = "Безопасный режим включён. Откройте диагностику для полного разбора."
		lbl_status.add_theme_color_override("font_color", Color(1.0, 0.75, 0.45))

	if wrong_count >= MAX_ATTEMPTS:
		_show_safe_mode_diagnostics("Достигнут лимит попыток")
		_finish_level(false, "attempt_limit")

func _on_analyze_pressed() -> void:
	if level_finished:
		return
	if not safe_mode_used:
		lbl_status.text = "Анализ открывается после 2 неудачных трассировок."
		lbl_status.add_theme_color_override("font_color", Color(0.9, 0.8, 0.45))
		return

	_register_first_action()
	if not hint_used:
		hint_used = true

	_show_safe_mode_diagnostics("Ручная диагностика")

func _show_safe_mode_diagnostics(trigger_reason: String) -> void:
	var lines: Array[String] = []
	lines.append("Дело: %s" % str(current_level.get("id", "UNKNOWN")))
	lines.append("Причина: %s" % trigger_reason)
	if not selected_error_code.is_empty():
		lines.append("Ошибка: %s" % selected_error_code)
		lines.append(ERROR_MAP.get_error_tip(selected_error_code))

	var explain_full: String = str(current_level.get("explain_full", ""))
	if not explain_full.is_empty():
		for line_var in explain_full.split("\n"):
			var text_line: String = line_var.strip_edges()
			if not text_line.is_empty():
				lines.append(text_line)

	if diagnostics_panel.has_method("setup"):
		diagnostics_panel.call("setup", "ДИАГНОСТИКА", lines)
	diagnostics_panel.visible = true
	state = QuestState.DIAGNOSTIC
	_log_event("diagnostics_open", {"reason": trigger_reason})

func _on_reset_pressed() -> void:
	if level_finished or run_in_progress:
		return
	_register_first_action()
	topology_board.clear_installed_device()
	lbl_status.text = "Слот очищен. Перетащите новое устройство."
	lbl_status.add_theme_color_override("font_color", Color(0.8, 0.86, 0.95))
	_log_event("reset_pressed", {})

func _on_next_pressed() -> void:
	if not level_finished:
		return
	_log_event("next_pressed", {"from": str(current_level.get("id", ""))})
	_start_level(current_level_index + 1)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _on_palette_selected(index: int) -> void:
	var palette_id: int = palette_select.get_item_id(index)
	_apply_palette(palette_id)

func _apply_palette(palette_id: int) -> void:
	var shader_material: ShaderMaterial = crt_overlay.material as ShaderMaterial
	if palette_id == PALETTE_AMBER_ID:
		theme = THEME_AMBER
		if shader_material != null:
			shader_material.set_shader_parameter("tint_color", Color(1.0, 0.7, 0.1, 1.0))
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
	var minutes: int = total_seconds / 60
	var seconds: int = total_seconds % 60
	lbl_meta.text = "ДЕЛО %s | ОШ %d/%d | %02d:%02d" % [
		str(current_level.get("id", "--")),
		wrong_count,
		MAX_ATTEMPTS,
		minutes,
		seconds
	]

func _on_stability_changed(_new_value: float, _delta: float) -> void:
	# Meta label is refreshed in timer tick and state transitions.
	pass

func _register_first_action() -> void:
	if first_action_ms < 0:
		first_action_ms = Time.get_ticks_msec() - level_started_ms

func _on_timeout() -> void:
	if level_finished:
		return
	selected_error_code = "TIMEOUT"
	var timeout_attempt: Dictionary = {
		"device_id": selected_device_id,
		"error_code": "TIMEOUT",
		"correct": false,
		"t_ms": Time.get_ticks_msec() - level_started_ms
	}
	attempts.append(timeout_attempt)
	var session_attempts: Array = task_session.get("attempts", [])
	session_attempts.append(timeout_attempt)
	task_session["attempts"] = session_attempts
	_show_safe_mode_diagnostics("Тайм-аут")
	_finish_level(false, "timeout")

func _finish_level(is_correct: bool, reason: String) -> void:
	if result_sent:
		return
	result_sent = true
	level_finished = true
	timer_running = false
	btn_run_trace.disabled = true
	btn_reset.disabled = true
	btn_analyze.disabled = true
	btn_next.visible = true
	for card in palette_cards:
		card.disabled = true
	topology_board.set_tools_locked(true)

	var end_tick: int = Time.get_ticks_msec()
	task_session["ended_at_ticks"] = end_tick
	_log_event("task_end", {"reason": reason, "is_correct": is_correct})

	if not is_correct and reason != "timeout":
		lbl_status.text = str(current_level.get("explain_short", "Проверьте диагностику для деталей."))
		lbl_status.add_theme_color_override("font_color", Color(1.0, 0.62, 0.45))

	var elapsed_ms: int = end_tick - level_started_ms
	var stability_delta: float = float(wrong_count) * FAIL_STABILITY_DELTA
	if not is_correct and wrong_count == 0:
		stability_delta += FAIL_STABILITY_DELTA
	if hint_used:
		stability_delta += HINT_STABILITY_DELTA

	var evidence_lines: Array[String] = _collect_selected_evidence_lines()
	var payload: Dictionary = {
		"quest": "network_trace",
		"stage": "A",
		"task_id": str(current_level.get("id", "")),
		"incident_id": str(current_level.get("incident_id", "")),
		"match_key": "NETTRACE_A|%s" % str(current_level.get("id", "")),
		"variant_hash": variant_hash,
		"is_correct": is_correct,
		"is_fit": is_correct,
		"error_code_last": selected_error_code,
		"attempts_count": attempts.size(),
		"attempts": attempts,
		"evidence_selected": evidence_lines,
		"elapsed_ms": elapsed_ms,
		"duration": float(elapsed_ms) / 1000.0,
		"safe_mode_used": safe_mode_used,
		"spam_clicks": spam_clicks,
		"time_to_first_action_ms": first_action_ms,
		"hint_used": hint_used,
		"timed_out": reason == "timeout",
		"stability_delta": stability_delta,
		"task_session": task_session
	}
	GlobalMetrics.register_trial(payload)

func _collect_selected_evidence_lines() -> Array[String]:
	var logs: Array = current_level.get("logs", [])
	var out: Array[String] = []
	for index in selected_evidence_indices:
		if index >= 0 and index < logs.size():
			out.append(str(logs[index]))
	return out

func _log_event(name: String, payload: Dictionary) -> void:
	var events: Array = task_session.get("events", [])
	events.append({
		"name": name,
		"t_ms": Time.get_ticks_msec() - level_started_ms,
		"payload": payload
	})
	task_session["events"] = events

func _build_variant_key(level: Dictionary) -> String:
	var option_ids: Array[String] = []
	var options: Array = level.get("options", [])
	for option_var in options:
		var option: Dictionary = option_var
		option_ids.append(str(option.get("id", "")))
	option_ids.sort()
	return "%s|%s|%s|%s" % [
		str(level.get("id", "")),
		str(level.get("prompt", "")),
		str(level.get("correct_id", "")),
		",".join(option_ids)
	]

func _apply_layout_mode() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	body.vertical = viewport_size.x < viewport_size.y


