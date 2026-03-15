extends Control

const LEVELS_PATH := "res://data/quest_b_levels.json"
const CODE_BLOCK_SCENE := preload("res://scripts/ui/CodeBlock.gd")
const EVALUATOR_SCRIPT := preload("res://scripts/restore_b/RestoreBSemanticEvaluator.gd")
const MAX_ATTEMPTS := 3
const PHONE_PORTRAIT_MAX_WIDTH := 560.0
const LANDSCAPE_SPLIT_MIN_WIDTH := 980.0

const AUDIO_CLICK := preload("res://audio/click.wav")
const AUDIO_ERROR := preload("res://audio/error.wav")
const AUDIO_RELAY := preload("res://audio/relay.wav")

enum State {
	INIT,
	SOLVING_EMPTY,
	SOLVING_FILLED,
	PREVIEW_READY,
	SUBMITTING,
	FEEDBACK_SUCCESS,
	FEEDBACK_FAIL,
	REASONING,
	SAFE_MODE
}

@onready var safe_area: MarginContainer = $SafeArea
@onready var main_layout: VBoxContainer = $SafeArea/MainLayout
@onready var header_row: HBoxContainer = $SafeArea/MainLayout/Header
@onready var bars_row: HBoxContainer = $SafeArea/MainLayout/BarsRow
@onready var body_split: BoxContainer = $SafeArea/MainLayout/BodySplit
@onready var left_column: VBoxContainer = $SafeArea/MainLayout/BodySplit/LeftColumn
@onready var right_column: VBoxContainer = $SafeArea/MainLayout/BodySplit/RightColumn
@onready var slot_row: HBoxContainer = $SafeArea/MainLayout/BodySplit/LeftColumn/SlotRow
@onready var actions_row: HBoxContainer = $SafeArea/MainLayout/BodySplit/RightColumn/Actions

@onready var lbl_clue_title: Label = $SafeArea/MainLayout/Header/LblClueTitle
@onready var lbl_session: Label = $SafeArea/MainLayout/Header/LblSessionId
@onready var btn_back: Button = $SafeArea/MainLayout/Header/BtnBack

@onready var decrypt_bar: ProgressBar = $SafeArea/MainLayout/BarsRow/DecryptBar
@onready var energy_bar: ProgressBar = $SafeArea/MainLayout/BarsRow/EnergyBar

@onready var lbl_target: Label = $SafeArea/MainLayout/CaseBriefPanel/BriefMargin/BriefVBox/LblTarget
@onready var lbl_briefing: Label = $SafeArea/MainLayout/CaseBriefPanel/BriefMargin/BriefVBox/LblBriefing
@onready var lbl_focus: Label = $SafeArea/MainLayout/CaseBriefPanel/BriefMargin/BriefVBox/LblFocus

@onready var code_display: RichTextLabel = $SafeArea/MainLayout/BodySplit/LeftColumn/TerminalFrame/CodeScroll/CodeDisplay
@onready var drop_zone: PanelContainer = $SafeArea/MainLayout/BodySplit/LeftColumn/SlotRow/DropZone
@onready var lbl_slot_hint: Label = $SafeArea/MainLayout/BodySplit/LeftColumn/SlotRow/LblSlotHint
@onready var blocks_container: HBoxContainer = $SafeArea/MainLayout/BodySplit/LeftColumn/InventoryFrame/InventoryMargin/InventoryScroll/BlocksContainer

@onready var reasoning_title: Label = $SafeArea/MainLayout/BodySplit/RightColumn/ReasoningPanel/ReasoningMargin/ReasoningVBox/ReasoningTitle
@onready var lbl_predicted_title: Label = $SafeArea/MainLayout/BodySplit/RightColumn/ReasoningPanel/ReasoningMargin/ReasoningVBox/PredictedRow/LblPredictedTitle
@onready var lbl_predicted_value: Label = $SafeArea/MainLayout/BodySplit/RightColumn/ReasoningPanel/ReasoningMargin/ReasoningVBox/PredictedRow/LblPredictedValue
@onready var lbl_target_title: Label = $SafeArea/MainLayout/BodySplit/RightColumn/ReasoningPanel/ReasoningMargin/ReasoningVBox/TargetRow/LblTargetTitle
@onready var lbl_target_value: Label = $SafeArea/MainLayout/BodySplit/RightColumn/ReasoningPanel/ReasoningMargin/ReasoningVBox/TargetRow/LblTargetValue
@onready var lbl_delta_title: Label = $SafeArea/MainLayout/BodySplit/RightColumn/ReasoningPanel/ReasoningMargin/ReasoningVBox/DeltaRow/LblDeltaTitle
@onready var lbl_delta_value: Label = $SafeArea/MainLayout/BodySplit/RightColumn/ReasoningPanel/ReasoningMargin/ReasoningVBox/DeltaRow/LblDeltaValue
@onready var lbl_why_not: Label = $SafeArea/MainLayout/BodySplit/RightColumn/ReasoningPanel/ReasoningMargin/ReasoningVBox/LblWhyNot
@onready var mini_trace: RichTextLabel = $SafeArea/MainLayout/BodySplit/RightColumn/ReasoningPanel/ReasoningMargin/ReasoningVBox/MiniTrace

@onready var btn_analyze: Button = $SafeArea/MainLayout/BodySplit/RightColumn/Actions/BtnAnalyze
@onready var btn_reset: Button = $SafeArea/MainLayout/BodySplit/RightColumn/Actions/BtnReset
@onready var btn_submit: Button = $SafeArea/MainLayout/BodySplit/RightColumn/Actions/BtnSubmit
@onready var btn_next: Button = $SafeArea/MainLayout/BodySplit/RightColumn/Actions/BtnNext

@onready var diagnostics_blocker: ColorRect = $DiagnosticsBlocker
@onready var diag_panel: PanelContainer = $DiagnosticsPanelB

func _tr(key: String, default_text: String, params: Dictionary = {}) -> String:
	var merged: Dictionary = params.duplicate(true)
	merged["default"] = default_text
	return I18n.tr_key(key, merged)

var evaluator = EVALUATOR_SCRIPT.new()
var levels: Array = []
var quarantined_levels: Array = []
var current_level_idx: int = 0
var current_task: Dictionary = {}
var state: State = State.INIT

var energy: float = 100.0
var wrong_count: int = 0
var task_started_at: int = 0
var t_start_ticks: int = 0
var paused_total_ms: int = 0
var pause_started_ticks: int = -1
var hint_total_ms: int = 0
var hint_open_time: int = 0
var switches_before_submit: int = 0
var is_safe_mode: bool = false
var variant_hash: String = ""
var level_result_sent: bool = false
var task_session: Dictionary = {}
var trial_seq: int = 0

var slot_select_count: int = 0
var slot_switch_count: int = 0
var gate_place_count: int = 0
var gate_replace_count: int = 0
var gate_clear_count: int = 0
var input_toggle_count: int = 0

var counterexample_seen_count: int = 0
var changed_after_counterexample: bool = false
var changed_after_analyze: bool = false
var test_without_full_assembly_count: int = 0

var time_to_first_slot_select_ms: int = -1
var time_to_first_test_ms: int = -1
var time_from_last_edit_to_test_ms: int = -1
var last_edit_ms: int = -1

var _await_change_after_counterexample: bool = false
var _await_change_after_analyze: bool = false
var last_counterexample: Dictionary = {}
var last_verdict_code: String = "INIT"

var current_variant_preview: Dictionary = {}
var variant_previews_by_block_id: Dictionary = {}
var semantic_validation_report: Dictionary = {}
var task_is_semantically_valid: bool = true

var tap_selected_block_data: Dictionary = {}
var block_buttons_by_id: Dictionary = {}
var preview_opened_for_task: bool = false
var _body_scroll_installed: bool = false

func _ready() -> void:
	_load_levels_from_json()
	if levels.is_empty():
		push_error("RestoreQuestB has no playable levels after semantic validation.")
		return

	if not I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.connect(_on_language_changed)

	_apply_i18n()
	_connect_signals()
	_install_body_scroll()

	diag_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	diagnostics_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	diagnostics_blocker.visible = false
	diag_panel.visible = false

	current_level_idx = GlobalMetrics.current_level_index
	if current_level_idx < 0 or current_level_idx >= levels.size():
		current_level_idx = 0

	_start_level(current_level_idx)
	_on_viewport_size_changed()
	if not get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.connect(_on_viewport_size_changed)

func _install_body_scroll() -> void:
	if _body_scroll_installed:
		return
	if main_layout == null or body_split == null:
		return
	var existing_scroll: ScrollContainer = main_layout.get_node_or_null("BodyScroll") as ScrollContainer
	if existing_scroll != null and existing_scroll.get_node_or_null("BodySplit") != null:
		_body_scroll_installed = true
		return
	var scroll := ScrollContainer.new()
	scroll.name = "BodyScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.follow_focus = true
	var idx: int = body_split.get_index()
	main_layout.add_child(scroll)
	main_layout.move_child(scroll, idx)
	body_split.reparent(scroll)
	_body_scroll_installed = true

func _exit_tree() -> void:
	if I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.disconnect(_on_language_changed)
	if get_tree() != null and get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.disconnect(_on_viewport_size_changed)

func _on_language_changed(_code: String) -> void:
	_apply_i18n()
	if not current_task.is_empty():
		_render_case_brief()
		_update_reasoning_panel_from_preview(current_variant_preview, "preview")

func _apply_i18n() -> void:
	btn_back.text = _tr("restore.b.btn.back", "НАЗАД")
	btn_analyze.text = _tr("restore.b.btn.reason", "ПОЧЕМУ ВАРИАНТ")
	btn_reset.text = _tr("restore.b.btn.reset", "СБРОСИТЬ ВЫБОР")
	btn_submit.text = _tr("restore.b.btn.submit", "ПРОВЕРИТЬ")
	btn_next.text = _tr("restore.b.btn.next", "ДАЛЕЕ")
	reasoning_title.text = _tr("restore.b.reason.title", "Диагностика варианта")
	lbl_predicted_title.text = _tr("restore.b.reason.predicted", "Прогноз s:")
	lbl_target_title.text = _tr("restore.b.reason.target", "Цель s:")
	lbl_delta_title.text = _tr("restore.b.reason.delta", "Отклонение:")
func _load_levels_from_json() -> void:
	levels.clear()
	quarantined_levels.clear()

	if not FileAccess.file_exists(LEVELS_PATH):
		push_error("Levels file not found: " + LEVELS_PATH)
		return

	var file := FileAccess.open(LEVELS_PATH, FileAccess.READ)
	if file == null:
		push_error("Unable to open levels file: " + LEVELS_PATH)
		return

	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("JSON parse error in quest_b_levels.json: " + json.get_error_message())
		return

	if typeof(json.data) != TYPE_ARRAY:
		push_error("quest_b_levels.json root must be an array.")
		return

	for raw_level in json.data:
		if typeof(raw_level) != TYPE_DICTIONARY:
			continue
		var level: Dictionary = (raw_level as Dictionary).duplicate(true)
		if not _validate_level_structure(level):
			push_warning("Skipping structurally invalid RestoreQuestB level: %s" % str(level.get("id", "UNKNOWN")))
			continue

		var report: Dictionary = evaluator.semantic_validate_level(level)
		level["_semantic_status"] = str(report.get("status", "unknown"))
		level["_semantic_report"] = report

		if bool(report.get("semantic_valid", false)):
			levels.append(level)
		else:
			quarantined_levels.append(level)
			push_warning("Quarantining semantically invalid RestoreQuestB level: %s (%s)" % [str(level.get("id", "UNKNOWN")), str(report.get("status", "unknown"))])

	if levels.is_empty() and not quarantined_levels.is_empty():
		push_warning("All RestoreQuestB levels are semantically invalid. Falling back to quarantined levels for debug play.")
		levels = quarantined_levels.duplicate(true)

func _validate_level_structure(level: Dictionary) -> bool:
	var slot: Dictionary = level.get("slot", {})
	var blocks: Array = level.get("blocks", [])
	var slot_type: String = str(slot.get("slot_type", ""))
	if slot_type != "INT" and slot_type != "OP":
		return false
	if blocks.is_empty():
		return false
	if not level.has("target_s"):
		return false
	if not level.has("code_template"):
		return false
	if not level.has("correct_block_id"):
		return false
	if typeof(level.get("code_template", [])) != TYPE_ARRAY:
		return false

	for b in blocks:
		if typeof(b) != TYPE_DICTIONARY:
			return false
		var block: Dictionary = b
		if str(block.get("slot_type", "")) != slot_type:
			return false
		if str(block.get("block_id", "")).is_empty():
			return false
		if str(block.get("insert", "")).is_empty():
			return false
	return true

func _connect_signals() -> void:
	drop_zone.block_dropped.connect(_on_block_dropped)
	if drop_zone.has_signal("slot_tapped"):
		drop_zone.connect("slot_tapped", Callable(self, "_on_drop_zone_tapped"))

	btn_back.pressed.connect(_on_back_pressed)
	btn_analyze.pressed.connect(_on_analyze_pressed)
	btn_reset.pressed.connect(_on_reset_pressed)
	btn_submit.pressed.connect(_on_submit_pressed)
	btn_next.pressed.connect(_on_next_pressed)
	diag_panel.visibility_changed.connect(_on_diag_visibility_changed)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func build_variant_key(task: Dictionary) -> String:
	var code: String = "\n".join(task.get("code_template", []))
	var target: String = str(task.get("target_s", ""))
	var slot: Dictionary = task.get("slot", {})
	var slot_type: String = str(slot.get("slot_type", ""))
	var ids: Array[String] = []
	for b in task.get("blocks", []):
		if typeof(b) == TYPE_DICTIONARY:
			ids.append(str((b as Dictionary).get("block_id", "")))
	ids.sort()
	return "%s|%s|%s|%s|%s" % [str(task.get("id", "")), code, target, slot_type, ",".join(ids)]

func _start_level(idx: int) -> void:
	if levels.is_empty():
		return
	if idx >= levels.size():
		idx = 0

	current_level_idx = idx
	current_task = (levels[idx] as Dictionary).duplicate(true)
	variant_hash = str(hash(build_variant_key(current_task)))
	t_start_ticks = Time.get_ticks_msec()
	task_started_at = t_start_ticks
	paused_total_ms = 0
	pause_started_ticks = -1
	level_result_sent = false
	hint_total_ms = 0
	hint_open_time = 0
	switches_before_submit = 0
	is_safe_mode = false
	wrong_count = 0
	energy = 100.0
	preview_opened_for_task = false
	trial_seq += 1
	slot_select_count = 0
	slot_switch_count = 0
	gate_place_count = 0
	gate_replace_count = 0
	gate_clear_count = 0
	input_toggle_count = 0
	counterexample_seen_count = 0
	changed_after_counterexample = false
	changed_after_analyze = false
	test_without_full_assembly_count = 0
	time_to_first_slot_select_ms = -1
	time_to_first_test_ms = -1
	time_from_last_edit_to_test_ms = -1
	last_edit_ms = -1
	_await_change_after_counterexample = false
	_await_change_after_analyze = false
	last_counterexample = {}
	last_verdict_code = "INIT"

	semantic_validation_report = evaluator.semantic_validate_level(current_task)
	task_is_semantically_valid = bool(semantic_validation_report.get("semantic_valid", false))
	variant_previews_by_block_id = evaluator.build_variant_previews(current_task)
	current_variant_preview = {}
	tap_selected_block_data = {}

	task_session = {
		"task_id": str(current_task.get("id", "B-00")),
		"variant_hash": variant_hash,
		"trial_seq": trial_seq,
		"started_at_ticks": t_start_ticks,
		"ended_at_ticks": 0,
		"attempts": [],
		"events": [],
		"hint_total_ms": 0,
		"paused_total_ms": 0,
		"wrong_count": 0,
		"semantic_status": str(semantic_validation_report.get("status", "unknown"))
	}

	state = State.SOLVING_EMPTY

	_render_case_brief()
	_render_code()
	_render_inventory()
	drop_zone.call("setup", str(current_task.get("slot", {}).get("slot_type", "INT")))
	drop_zone.modulate = Color(1, 1, 1, 1)

	btn_submit.disabled = true
	btn_reset.disabled = true
	btn_analyze.disabled = false
	btn_next.visible = false
	energy_bar.value = energy
	decrypt_bar.value = 0.0

	diagnostics_blocker.visible = false
	diag_panel.visible = false
	_reset_reasoning_panel()
	_highlight_inventory_block("")

	_log_event("task_start", {
		"bucket": str(current_task.get("bucket", "unknown")),
		"semantic_status": str(semantic_validation_report.get("status", "unknown"))
	})
	_log_event("trial_started", {
		"case_id": str(current_task.get("id", "B-00")),
		"layout": str(current_task.get("slot", {}).get("slot_type", "INT")),
		"correct_block_id": str(current_task.get("correct_block_id", ""))
	})
	if not task_is_semantically_valid:
		_log_event("semantic_level_invalid_detected", {
			"task_id": str(current_task.get("id", "B-00")),
			"status": str(semantic_validation_report.get("status", "unknown"))
		})

func _render_case_brief() -> void:
	lbl_clue_title.text = _tr("restore.b.labels.clue_title", "ВОССТАНОВЛЕНИЕ {id}", {"id": str(current_task.get("id", "B-00"))})
	lbl_session.text = _tr("restore.b.labels.session", "СЕСС {n}", {"n": str(randi() % 9000 + 1000)})
	lbl_target.text = _tr("restore.b.labels.target", "ЦЕЛЬ: s = {val}", {"val": str(current_task.get("target_s", "?"))})
	lbl_briefing.text = str(current_task.get("briefing", "Восстановите недостающий фрагмент и проверьте поведение кода."))
	lbl_focus.text = _build_focus_hint()
	lbl_slot_hint.text = _tr("restore.b.status.drag_hint", "Перетащите блок в слот или выберите блок и нажмите слот.")

func _build_focus_hint() -> String:
	var slot_type: String = str(current_task.get("slot", {}).get("slot_type", "INT"))
	if slot_type == "OP":
		return _tr("restore.b.focus.op", "Фокус: оператор в условии меняет, какие итерации попадают в расчёт.")
	return _tr("restore.b.focus.int", "Фокус: числовой фрагмент влияет на шаг, границы цикла или вклад в s.")

func _render_code(selected_block_data: Dictionary = {}) -> void:
	var insert_text: String = ""
	if not selected_block_data.is_empty():
		insert_text = str(selected_block_data.get("insert", ""))

	var txt: String = ""
	var lines: Array = current_task.get("code_template", [])
	for idx in range(lines.size()):
		var line: String = str(lines[idx])
		if insert_text.is_empty():
			line = line.replace("[SLOT]", "[color=#EDECE8][SLOT][/color]")
		else:
			line = line.replace("[SLOT]", "[color=#FFD86A]%s[/color]" % insert_text)
		txt += "[color=#7A7A74]%02d[/color]  %s\n" % [idx + 1, line]
	code_display.text = txt

func _render_inventory() -> void:
	for child in blocks_container.get_children():
		child.queue_free()
	block_buttons_by_id.clear()

	for b_data in current_task.get("blocks", []):
		if typeof(b_data) != TYPE_DICTIONARY:
			continue
		var block: Dictionary = b_data
		var btn := Button.new()
		btn.set_script(CODE_BLOCK_SCENE)
		btn.call("setup", block)
		btn.custom_minimum_size = Vector2(140, 64)
		if btn.has_signal("block_tapped"):
			btn.connect("block_tapped", Callable(self, "_on_inventory_block_tapped"))
		blocks_container.add_child(btn)
		block_buttons_by_id[str(block.get("block_id", ""))] = btn

	_on_viewport_size_changed()

func _on_inventory_block_tapped(data: Dictionary) -> void:
	if typeof(data) != TYPE_DICTIONARY:
		return
	_play_sound(AUDIO_CLICK)
	input_toggle_count += 1
	tap_selected_block_data = data.duplicate(true)
	var selected_id: String = str(tap_selected_block_data.get("block_id", ""))
	_highlight_inventory_block(selected_id)
	lbl_slot_hint.text = _tr("restore.b.status.tap_to_place", "Блок выбран. Нажмите на слот, чтобы подставить.")
	_log_event("input_toggled", {"selected_block_id": selected_id, "count": input_toggle_count})
	_log_event("preview_changed", {"source": "tap_select", "block_id": selected_id})

func _on_drop_zone_tapped() -> void:
	slot_select_count += 1
	if time_to_first_slot_select_ms < 0:
		time_to_first_slot_select_ms = _elapsed_ms_now()
	_log_event("slot_selected", {"slot": 0, "count": slot_select_count})
	if tap_selected_block_data.is_empty():
		return
	drop_zone.call("place_block", tap_selected_block_data)

func _highlight_inventory_block(selected_id: String) -> void:
	for block_id_var in block_buttons_by_id.keys():
		var block_id: String = str(block_id_var)
		var btn: Button = block_buttons_by_id[block_id]
		if btn == null:
			continue
		if block_id == selected_id:
			btn.modulate = Color(1.0, 0.96, 0.78, 1.0)
		else:
			btn.modulate = Color(1, 1, 1, 1)

func _on_block_dropped(data: Dictionary) -> void:
	if typeof(data) != TYPE_DICTIONARY:
		return
	_play_sound(AUDIO_CLICK)
	slot_select_count += 1
	if time_to_first_slot_select_ms < 0:
		time_to_first_slot_select_ms = _elapsed_ms_now()

	var prev_id: Variant = drop_zone.call("get_last_prev_block_id")
	var new_id: String = str(data.get("block_id", ""))
	var prev_id_text: String = "" if prev_id == null else str(prev_id)
	if prev_id == null or prev_id_text.is_empty():
		if not new_id.is_empty():
			gate_place_count += 1
	elif prev_id_text != new_id:
		gate_replace_count += 1
		slot_switch_count += 1
	if prev_id != null and not new_id.is_empty() and str(prev_id) != new_id:
		switches_before_submit += 1

	_mark_edit_action()
	tap_selected_block_data = {}
	_update_selected_variant(new_id, data)
	_log_event("gate_placed", {
		"slot": 0,
		"gate": new_id,
		"placed_block_id": new_id,
		"gate_place_count": gate_place_count,
		"gate_replace_count": gate_replace_count
	})
	_log_event("slot_changed", {"prev": prev_id, "new": new_id})

func _update_selected_variant(block_id: String, block_data: Dictionary) -> void:
	if not variant_previews_by_block_id.has(block_id):
		var fallback_preview: Dictionary = evaluator.evaluate_variant(current_task, block_data)
		variant_previews_by_block_id[block_id] = fallback_preview

	current_variant_preview = (variant_previews_by_block_id.get(block_id, {}) as Dictionary).duplicate(true)
	_render_code(block_data)
	_update_reasoning_panel_from_preview(current_variant_preview, "preview")

	state = State.PREVIEW_READY
	btn_submit.disabled = false
	btn_reset.disabled = false
	lbl_slot_hint.text = _tr("restore.b.status.preview_ready", "Прогноз готов. Проверьте ход вычисления перед подтверждением.")

	if not preview_opened_for_task:
		preview_opened_for_task = true
		_log_event("preview_opened", {"block_id": block_id})
	_log_event("preview_changed", {
		"source": "slot_update",
		"block_id": block_id,
		"predicted_s": int(current_variant_preview.get("computed_s", 0))
	})
	_log_event("selected_block_previewed", {
		"block_id": block_id,
		"predicted_s": int(current_variant_preview.get("computed_s", 0)),
		"target_s": int(current_task.get("target_s", 0))
	})
	_highlight_inventory_block(block_id)
func _on_submit_pressed() -> void:
	if state != State.PREVIEW_READY and state != State.SOLVING_FILLED:
		return

	state = State.SUBMITTING
	btn_submit.disabled = true

	var selected_id: String = str(drop_zone.call("get_block_id"))
	if time_to_first_test_ms < 0:
		time_to_first_test_ms = _elapsed_ms_now()
	if last_edit_ms >= 0:
		time_from_last_edit_to_test_ms = maxi(0, _elapsed_ms_now() - last_edit_ms)
	var has_preview: bool = not current_variant_preview.is_empty() and str(current_variant_preview.get("block_id", "")) == selected_id
	if not has_preview and variant_previews_by_block_id.has(selected_id):
		current_variant_preview = (variant_previews_by_block_id.get(selected_id, {}) as Dictionary).duplicate(true)
		has_preview = not current_variant_preview.is_empty()
	if not has_preview or selected_id.is_empty():
		test_without_full_assembly_count += 1
	_log_event("test_pressed", {"placed_block_id": selected_id, "has_preview": has_preview})

	if has_preview:
		_log_event("submit_after_preview", {"block_id": selected_id})
	else:
		_log_event("submit_without_preview", {"block_id": selected_id})

	var preview: Dictionary = current_variant_preview
	var is_correct: bool = bool(preview.get("is_target_match", false))
	var predicted_s: int = int(preview.get("computed_s", 0))
	var target_s: int = int(current_task.get("target_s", 0))

	var declared_correct_id: String = str(current_task.get("correct_block_id", ""))
	var declared_selected_match: bool = selected_id == declared_correct_id
	if declared_selected_match != is_correct:
		_log_event("semantic_declared_mismatch", {
			"task_id": str(current_task.get("id", "B-00")),
			"selected_block_id": selected_id,
			"declared_correct_id": declared_correct_id,
			"predicted_s": predicted_s,
			"target_s": target_s
		})
		push_warning("RestoreQuestB mismatch between declared correct id and semantic result for %s" % str(current_task.get("id", "B-00")))

	var end_ticks: int = Time.get_ticks_msec()
	var elapsed_input_ms: int = _effective_elapsed_ms(end_ticks)
	var is_terminal_fail: bool = (not is_correct) and (wrong_count + 1 >= MAX_ATTEMPTS)
	var state_after: String = "FEEDBACK_SUCCESS" if is_correct else ("SAFE_MODE" if is_terminal_fail else "FEEDBACK_FAIL")
	var verdict_code: String = "SUCCESS" if is_correct else ("SAFE_MODE" if is_terminal_fail else "FAIL_RETRY")
	last_verdict_code = verdict_code

	var attempt: Dictionary = {
		"kind": "block_selection",
		"selected_block_id": selected_id,
		"declared_correct_block_id": declared_correct_id,
		"computed_target_match": is_correct,
		"predicted_s": predicted_s,
		"target_s": target_s,
		"switches_before_submit": switches_before_submit,
		"duration_input_ms": elapsed_input_ms,
		"duration_input_ms_excluding_hint": elapsed_input_ms,
		"hint_open_at_submit": diag_panel.visible,
		"correct": is_correct,
		"state_after": state_after
	}
	(task_session["attempts"] as Array).append(attempt)
	_log_event("submit_pressed", {
		"correct": is_correct,
		"selected": selected_id,
		"predicted_s": predicted_s,
		"target_s": target_s
	})
	_log_event("test_result", {
		"verdict_code": verdict_code,
		"is_correct": is_correct,
		"counterexample_present": not is_correct
	})

	if is_correct:
		_handle_success(end_ticks)
	elif is_terminal_fail:
		wrong_count += 1
		_handle_fail_terminal(end_ticks)
	else:
		wrong_count += 1
		_handle_fail_retry(selected_id)

func _handle_success(end_ticks: int) -> void:
	state = State.FEEDBACK_SUCCESS
	_play_sound(AUDIO_RELAY)
	drop_zone.modulate = Color(0.96, 0.96, 0.94, 1.0)
	decrypt_bar.value += float(current_task.get("economy", {}).get("reward", 0))
	btn_submit.disabled = true
	btn_next.visible = true
	btn_analyze.disabled = false
	btn_reset.disabled = false

	_update_reasoning_panel_from_preview(current_variant_preview, "success")
	_log_event("reasoning_opened", {"source": "success_inline"})
	_register_result(true, end_ticks, "SUCCESS")

func _handle_fail_retry(selected_id: String) -> void:
	state = State.FEEDBACK_FAIL
	_play_sound(AUDIO_ERROR)
	energy = maxf(0.0, energy - float(current_task.get("economy", {}).get("wrong_penalty", 0)))
	energy_bar.value = energy
	drop_zone.modulate = Color(0.92, 0.88, 0.86, 1.0)

	btn_submit.disabled = false
	btn_reset.disabled = false
	state = State.PREVIEW_READY

	var predicted_s: int = int(current_variant_preview.get("computed_s", 0))
	var target_s: int = int(current_task.get("target_s", 0))
	last_counterexample = {
		"selected_block_id": selected_id,
		"predicted_s": predicted_s,
		"target_s": target_s
	}
	counterexample_seen_count += 1
	_await_change_after_counterexample = true
	_log_event("counterexample_shown", last_counterexample.duplicate(true))
	lbl_slot_hint.text = _tr("restore.b.status.fail_detail", "Этот блок даёт s={got}, а нужно s={need}.", {"got": str(predicted_s), "need": str(target_s)})
	_update_reasoning_panel_from_preview(current_variant_preview, "fail")
	_log_event("distractor_reason_seen", {"selected": selected_id, "predicted_s": predicted_s})

	if wrong_count >= 2:
		_open_reasoning_inspector("fail")

func _handle_fail_terminal(end_ticks: int) -> void:
	_play_sound(AUDIO_ERROR)
	energy = maxf(0.0, energy - float(current_task.get("economy", {}).get("wrong_penalty", 0)))
	energy_bar.value = energy
	var selected_id: String = str(drop_zone.call("get_block_id"))
	last_counterexample = {
		"selected_block_id": selected_id,
		"predicted_s": int(current_variant_preview.get("computed_s", 0)),
		"target_s": int(current_task.get("target_s", 0))
	}
	counterexample_seen_count += 1
	_await_change_after_counterexample = true
	_log_event("counterexample_shown", last_counterexample.duplicate(true))
	_trigger_safe_mode(end_ticks)

func _trigger_safe_mode(end_ticks: int) -> void:
	state = State.SAFE_MODE
	is_safe_mode = true
	btn_submit.disabled = true
	btn_next.visible = true
	btn_analyze.disabled = false
	btn_reset.disabled = false

	var correct_preview: Dictionary = _get_computed_correct_preview()
	if not correct_preview.is_empty():
		current_variant_preview = correct_preview.duplicate(true)
		_update_reasoning_panel_from_preview(correct_preview, "safe_mode")

	_open_reasoning_inspector("safe_mode", correct_preview)
	_log_event("auto_safe_review_opened", {})
	_register_result(false, end_ticks, "SAFE_MODE")

func _on_analyze_pressed() -> void:
	_await_change_after_analyze = true
	_log_event("analyze_pressed", {
		"selected_block_id": str(drop_zone.call("get_block_id")),
		"preview_available": not current_variant_preview.is_empty()
	})
	_open_reasoning_inspector("preview")

func _on_reset_pressed() -> void:
	if state == State.SUBMITTING:
		return
	var prev_block_id: String = str(drop_zone.call("get_block_id"))
	drop_zone.call("reset")
	if not prev_block_id.is_empty():
		gate_clear_count += 1
		_mark_edit_action()
		_log_event("gate_cleared", {"slot": 0, "previous_block_id": prev_block_id})
	drop_zone.modulate = Color(1, 1, 1, 1)
	tap_selected_block_data = {}
	current_variant_preview = {}
	state = State.SOLVING_EMPTY
	btn_submit.disabled = true
	btn_reset.disabled = true
	lbl_slot_hint.text = _tr("restore.b.status.drag_hint", "Перетащите блок в слот или выберите блок и нажмите слот.")
	_render_code()
	_reset_reasoning_panel()
	_highlight_inventory_block("")
	_log_event("preview_reset", {})

func _open_reasoning_inspector(mode: String, forced_preview: Dictionary = {}) -> void:
	if diag_panel.visible:
		return
	var payload: Dictionary = _build_diagnostics_payload(mode, forced_preview)
	diag_panel.call("setup", payload)
	diag_panel.visible = true
	state = State.REASONING
	_log_event("reasoning_opened", {"mode": mode})

func _build_diagnostics_payload(mode: String, forced_preview: Dictionary = {}) -> Dictionary:
	var preview: Dictionary = forced_preview
	if preview.is_empty():
		preview = current_variant_preview
	if preview.is_empty():
		preview = _get_computed_correct_preview()

	var predicted_s: int = int(preview.get("computed_s", 0))
	var target_s: int = int(current_task.get("target_s", 0))
	var delta: int = predicted_s - target_s
	var selected_id: String = str(preview.get("block_id", drop_zone.call("get_block_id")))

	var explain_lines: Array = _get_explain_lines(current_task)
	var why_not_lines: Array = _build_why_not_lines(preview)

	var payload: Dictionary = {
		"mode": mode,
		"selected_block_id": selected_id,
		"rendered_code": preview.get("rendered_code", current_task.get("code_template", [])),
		"predicted_s": predicted_s,
		"target_s": target_s,
		"delta": delta,
		"trace": preview.get("trace", []),
		"explain_lines": explain_lines,
		"why_not_lines": why_not_lines
	}

	if mode == "safe_mode" or mode == "success":
		payload["correct_preview"] = _get_correct_preview_summary()

	return payload

func _get_correct_preview_summary() -> Dictionary:
	var preview: Dictionary = _get_computed_correct_preview()
	if preview.is_empty():
		return {}
	return {
		"block_id": str(preview.get("block_id", "")),
		"computed_s": int(preview.get("computed_s", 0)),
		"trace": preview.get("trace", [])
	}

func _get_computed_correct_preview() -> Dictionary:
	var solved_ids: Array = semantic_validation_report.get("solved_block_ids", [])
	if solved_ids.size() == 1:
		var solved_id: String = str(solved_ids[0])
		if variant_previews_by_block_id.has(solved_id):
			return (variant_previews_by_block_id.get(solved_id, {}) as Dictionary).duplicate(true)

	var declared_id: String = str(current_task.get("correct_block_id", ""))
	if variant_previews_by_block_id.has(declared_id):
		return (variant_previews_by_block_id.get(declared_id, {}) as Dictionary).duplicate(true)

	return {}
func _reset_reasoning_panel() -> void:
	lbl_predicted_value.text = "?"
	lbl_target_value.text = str(current_task.get("target_s", "?"))
	lbl_delta_value.text = "?"
	lbl_why_not.text = _tr("restore.b.reason.placeholder", "Выберите блок, чтобы увидеть прогноз поведения и расхождение с целью.")
	mini_trace.text = _tr("restore.b.reason.trace_placeholder", "Трассировка появится после выбора блока.")

func _update_reasoning_panel_from_preview(preview: Dictionary, mode: String) -> void:
	if preview.is_empty():
		_reset_reasoning_panel()
		return

	var predicted_s: int = int(preview.get("computed_s", 0))
	var target_s: int = int(current_task.get("target_s", 0))
	var delta: int = predicted_s - target_s
	lbl_predicted_value.text = str(predicted_s)
	lbl_target_value.text = str(target_s)
	lbl_delta_value.text = "%+d" % delta

	var why_lines: Array = _build_why_not_lines(preview)
	if mode == "success":
		lbl_why_not.text = _tr("restore.b.reason.success", "Цель достигнута. Этот блок восстанавливает поведение корректно.")
	elif mode == "safe_mode":
		lbl_why_not.text = _tr("restore.b.reason.safe", "Система открыла корректный разбор после нескольких попыток.")
	elif why_lines.is_empty():
		lbl_why_not.text = _tr("restore.b.reason.neutral", "Проверьте трассировку и сравните прогноз с целью.")
	else:
		lbl_why_not.text = "\n".join(why_lines)

	mini_trace.text = _format_trace(preview.get("trace", []), 8)

func _format_trace(trace_variant: Variant, max_rows: int) -> String:
	var trace: Array = trace_variant if typeof(trace_variant) == TYPE_ARRAY else []
	if trace.is_empty():
		return _tr("restore.b.reason.trace_compact", "Доступен краткий расчёт без подробной трассировки.")

	var lines: Array = []
	var limit: int = mini(trace.size(), max_rows)
	for idx in range(limit):
		var step: Dictionary = trace[idx] if typeof(trace[idx]) == TYPE_DICTIONARY else {}
		lines.append(
			"#%d i=%s | s: %s -> %s | %s" % [
				idx + 1,
				str(step.get("i", "?")),
				str(step.get("s_before", "?")),
				str(step.get("s_after", "?")),
				str(step.get("event", ""))
			]
		)
	if trace.size() > max_rows:
		lines.append(_tr("restore.b.reason.trace_more", "... ещё {n} шаг(ов)", {"n": str(trace.size() - max_rows)}))
	return "\n".join(lines)

func _build_why_not_lines(preview: Dictionary) -> Array:
	var lines: Array = []
	if preview.is_empty():
		return lines

	var predicted_s: int = int(preview.get("computed_s", 0))
	var target_s: int = int(current_task.get("target_s", 0))
	var selected_id: String = str(preview.get("block_id", ""))

	if bool(preview.get("is_target_match", false)):
		lines.append(_tr("restore.b.reason.match", "Вариант совпадает с целью: s = {val}.", {"val": str(target_s)}))
	else:
		lines.append(_tr("restore.b.reason.mismatch", "Этот блок даёт s={got}, а цель s={need}.", {"got": str(predicted_s), "need": str(target_s)}))

	var distractor_map: Variant = current_task.get("distractor_feedback", {})
	if typeof(distractor_map) == TYPE_DICTIONARY and (distractor_map as Dictionary).has(selected_id):
		var hint_entry: Variant = (distractor_map as Dictionary).get(selected_id)
		if typeof(hint_entry) == TYPE_DICTIONARY:
			var hint_text: String = str((hint_entry as Dictionary).get("hint", "")).strip_edges()
			if not hint_text.is_empty():
				lines.append(hint_text)

	return lines

func _get_explain_lines(task: Dictionary) -> Array:
	var raw_lines: Variant = task.get("explain_short", [])
	if typeof(raw_lines) != TYPE_ARRAY:
		return []
	var result: Array = []
	for line_var in raw_lines:
		result.append(str(line_var))
	return result

func _on_diag_visibility_changed() -> void:
	if diag_panel.visible:
		diagnostics_blocker.visible = true
		if pause_started_ticks == -1:
			hint_open_time = Time.get_ticks_msec()
		_log_event("reasoning_opened", {"source": "inspector"})
	else:
		diagnostics_blocker.visible = false
		var duration: int = _consume_open_hint_duration(Time.get_ticks_msec())
		if duration > 0:
			_log_event("reasoning_closed", {"duration_ms": duration})
		if state == State.REASONING:
			state = State.PREVIEW_READY if not current_variant_preview.is_empty() else State.SOLVING_EMPTY

func _notification(what: int) -> void:
	if t_start_ticks <= 0:
		return
	if what == MainLoop.NOTIFICATION_APPLICATION_PAUSED:
		_on_app_paused()
	elif what == MainLoop.NOTIFICATION_APPLICATION_RESUMED:
		_on_app_resumed()

func _on_app_paused() -> void:
	if pause_started_ticks != -1:
		return
	var now_ticks: int = Time.get_ticks_msec()
	pause_started_ticks = now_ticks
	_consume_open_hint_duration(now_ticks)
	_log_event("app_paused", {})

func _on_app_resumed() -> void:
	if pause_started_ticks == -1:
		return
	var now_ticks: int = Time.get_ticks_msec()
	var paused_ms: int = maxi(0, now_ticks - pause_started_ticks)
	paused_total_ms += paused_ms
	task_session["paused_total_ms"] = paused_total_ms
	pause_started_ticks = -1
	_log_event("app_resumed", {"paused_ms": paused_ms})

func _on_next_pressed() -> void:
	if diag_panel.visible:
		diag_panel.visible = false
	_log_event("next_pressed", {"from_task": str(current_task.get("id", "B-00"))})
	_start_level(current_level_idx + 1)

func _register_result(is_correct: bool, end_ticks: int, reason: String) -> void:
	if level_result_sent:
		return
	level_result_sent = true

	var elapsed_ms: int = _effective_elapsed_ms(end_ticks)
	task_session["ended_at_ticks"] = end_ticks
	task_session["hint_total_ms"] = hint_total_ms
	task_session["paused_total_ms"] = paused_total_ms
	task_session["wrong_count"] = wrong_count
	_log_event("task_end", {"reason": reason, "is_correct": is_correct})

	var payload: Dictionary = {
		"quest_id": "RESTORE_QUEST",
		"stage_id": "B",
		"match_key": "RESTORE_B|%s" % str(current_task.get("id", "B-00")),
		"is_correct": is_correct,
		"is_fit": is_correct,
		"elapsed_ms": elapsed_ms,
		"duration": float(elapsed_ms) / 1000.0,
		"task_id": str(current_task.get("id", "B-00")),
		"variant_hash": variant_hash,
		"trial_seq": trial_seq,
		"slot_select_count": slot_select_count,
		"slot_switch_count": slot_switch_count,
		"gate_place_count": gate_place_count,
		"gate_replace_count": gate_replace_count,
		"gate_clear_count": gate_clear_count,
		"input_toggle_count": input_toggle_count,
		"counterexample_seen_count": counterexample_seen_count,
		"counterexample": last_counterexample.duplicate(true),
		"changed_after_counterexample": changed_after_counterexample,
		"changed_after_analyze": changed_after_analyze,
		"test_without_full_assembly_count": test_without_full_assembly_count,
		"time_to_first_slot_select_ms": time_to_first_slot_select_ms,
		"time_to_first_test_ms": time_to_first_test_ms,
		"time_from_last_edit_to_test_ms": time_from_last_edit_to_test_ms,
		"outcome_code": last_verdict_code,
		"mastery_block_reason": _build_mastery_block_reason_for_b(last_verdict_code, is_correct),
		"task_session": task_session,
		"stability_delta": -15.0 if not is_correct else 0.0
	}
	GlobalMetrics.register_trial(payload)

func _log_event(event_name: String, payload: Dictionary) -> void:
	if task_session.is_empty():
		return
	var events: Array = task_session.get("events", [])
	events.append({
		"name": event_name,
		"t_ms": _effective_elapsed_ms(Time.get_ticks_msec()),
		"payload": payload
	})
	task_session["events"] = events

func _effective_elapsed_ms(now_ticks: int) -> int:
	return maxi(0, (now_ticks - t_start_ticks) - paused_total_ms - hint_total_ms)

func _elapsed_ms_now() -> int:
	return _effective_elapsed_ms(Time.get_ticks_msec())

func _mark_edit_action() -> void:
	last_edit_ms = _elapsed_ms_now()
	if _await_change_after_analyze:
		changed_after_analyze = true
		_await_change_after_analyze = false
	if _await_change_after_counterexample:
		changed_after_counterexample = true
		_await_change_after_counterexample = false

func _build_mastery_block_reason_for_b(verdict_code: String, is_correct: bool) -> String:
	if is_correct:
		if changed_after_counterexample:
			return "solved_after_counterexample"
		if changed_after_analyze:
			return "solved_after_analyze"
		return "solved_direct"
	if verdict_code == "SAFE_MODE":
		return "safe_mode_triggered"
	if test_without_full_assembly_count > 0:
		return "tested_without_full_assembly"
	return "incorrect_submission"

func _consume_open_hint_duration(until_ticks: int) -> int:
	if hint_open_time <= 0:
		return 0
	var duration: int = maxi(0, until_ticks - hint_open_time)
	hint_total_ms += duration
	task_session["hint_total_ms"] = hint_total_ms
	hint_open_time = 0
	return duration

func _play_sound(stream: AudioStream) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

func _on_viewport_size_changed() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var is_landscape: bool = viewport_size.x >= viewport_size.y
	var compact: bool = (not is_landscape and viewport_size.x <= PHONE_PORTRAIT_MAX_WIDTH) or (is_landscape and viewport_size.y <= 760.0)
	var split_landscape: bool = is_landscape and viewport_size.x >= LANDSCAPE_SPLIT_MIN_WIDTH

	_apply_safe_area_padding(compact)
	body_split.vertical = not split_landscape
	body_split.add_theme_constant_override("separation", 10 if compact else 14)

	main_layout.add_theme_constant_override("separation", 8 if compact else 10)
	header_row.add_theme_constant_override("separation", 8 if compact else 10)
	bars_row.add_theme_constant_override("separation", 8 if compact else 10)
	slot_row.add_theme_constant_override("separation", 8 if compact else 12)
	actions_row.add_theme_constant_override("separation", 8 if compact else 12)
	blocks_container.add_theme_constant_override("separation", 8 if compact else 12)

	code_display.add_theme_font_size_override("normal_font_size", 18 if compact else 20)
	lbl_slot_hint.add_theme_font_size_override("font_size", 14 if compact else 16)
	mini_trace.add_theme_font_size_override("normal_font_size", 14 if compact else 15)

	drop_zone.custom_minimum_size = Vector2(180.0 if compact else 240.0, 80.0 if compact else 96.0)
	btn_back.custom_minimum_size = Vector2(100.0 if compact else 120.0, 48.0 if compact else 56.0)
	btn_analyze.custom_minimum_size.y = 48.0 if compact else 56.0
	btn_reset.custom_minimum_size.y = 48.0 if compact else 56.0
	btn_submit.custom_minimum_size.y = 48.0 if compact else 56.0
	btn_next.custom_minimum_size.y = 48.0 if compact else 56.0

	for child in blocks_container.get_children():
		if child is Button:
			var item_btn: Button = child
			item_btn.custom_minimum_size = Vector2(120.0 if compact else 150.0, 56.0 if compact else 68.0)

func _apply_safe_area_padding(compact: bool) -> void:
	var left: float = 8.0 if compact else 16.0
	var top: float = 8.0 if compact else 12.0
	var right: float = 8.0 if compact else 16.0
	var bottom: float = 8.0 if compact else 12.0

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
