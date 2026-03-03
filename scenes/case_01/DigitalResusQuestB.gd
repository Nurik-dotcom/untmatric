extends Control

const LEVELS_PATH: String = "res://data/clues_levels.json"
const FLOW_SCENE_PATH: String = "res://scenes/case_01/Case01Flow.tscn"
const QUEST_SELECT_SCENE: String = "res://scenes/QuestSelect.tscn"
const CASE_ID: String = "CASE_01_DIGITAL_RESUS"
const STAGE_ID: String = "B"
const ResusData = preload("res://scripts/case_01/ResusData.gd")
const ResusScoring = preload("res://scripts/case_01/ResusScoring.gd")
const TrialV2 = preload("res://scripts/TrialV2.gd")
const PHONE_LANDSCAPE_MAX_HEIGHT := 740.0
const PHONE_PORTRAIT_MAX_WIDTH := 520.0

const COLOR_OK: Color = Color(0.9, 0.93, 0.98, 1.0)
const COLOR_WARN: Color = Color(0.98, 0.8, 0.52, 1.0)
const COLOR_ERR: Color = Color(0.95, 0.36, 0.38, 1.0)

const CPU_ORDER: Array[String] = ["LOW", "MID", "HIGH"]
const RAM_ORDER: Array[String] = ["LOW", "GOOD", "TOP"]
const GPU_ORDER: Array[String] = ["NONE", "MID", "TOP"]
const RISK_BY_CLASS := {
	"OPTIMAL": 20,
	"BOTTLENECK_GPU": 68,
	"BOTTLENECK_CPU": 72,
	"BOTTLENECK_RAM": 78,
	"LOWPOWER": 84,
	"OVERBUDGET": 95
}

var levels: Array = []
var current_level_index: int = 0
var stage_b_data: Dictionary = {}
var trace: Array = []

var stage_started_ms: int = 0
var time_to_first_action_ms: int = -1
var tune_change_count: int = 0
var attempt_index: int = 0
var input_locked: bool = false
var loaded_preset_id: String = ""
var _option_cards_by_id: Dictionary = {}
var _last_result: Dictionary = {}
var _last_payload: Dictionary = {}

var snapshot_b: Dictionary = {
	"tuning": {"cpu": "MID", "ram": "GOOD", "gpu": "NONE"},
	"preview_metrics": {},
	"benchmark_ran": false,
	"classified_as": "UNKNOWN",
	"total_price": 0
}

@onready var noir_overlay: Node = $NoirOverlay
@onready var safe_area: MarginContainer = $SafeArea
@onready var main_vbox: VBoxContainer = $SafeArea/MainVBox
@onready var header: HBoxContainer = $SafeArea/MainVBox/Header
@onready var content_scroll: ScrollContainer = $SafeArea/MainVBox/ContentScroll
@onready var content_vbox: VBoxContainer = $SafeArea/MainVBox/ContentScroll/Content
@onready var bottom_bar: VBoxContainer = $SafeArea/MainVBox/BottomBar
@onready var title_label: Label = $SafeArea/MainVBox/Header/TitleLabel
@onready var stage_label: Label = $SafeArea/MainVBox/Header/StageLabel
@onready var stability_bar: ProgressBar = $SafeArea/MainVBox/Header/StabilityBar
@onready var btn_back: Button = $SafeArea/MainVBox/Header/BtnBack

@onready var context_label: Label = $SafeArea/MainVBox/ContentScroll/Content/ContextCard/ContextVBox/ContextLabel
@onready var budget_value: Label = $SafeArea/MainVBox/ContentScroll/Content/ContextCard/ContextVBox/BudgetRow/BudgetValue
@onready var options_list: VBoxContainer = $SafeArea/MainVBox/ContentScroll/Content/OptionsCard/OptionsVBox/OptionsScroll/OptionsList

@onready var cpu_level: OptionButton = $SafeArea/MainVBox/ContentScroll/Content/BiosCard/BiosVBox/TuneGrid/CpuLevel
@onready var ram_level: OptionButton = $SafeArea/MainVBox/ContentScroll/Content/BiosCard/BiosVBox/TuneGrid/RamLevel
@onready var gpu_level: OptionButton = $SafeArea/MainVBox/ContentScroll/Content/BiosCard/BiosVBox/TuneGrid/GpuLevel
@onready var used_budget_value: Label = $SafeArea/MainVBox/ContentScroll/Content/BiosCard/BiosVBox/TuneGrid/UsedBudgetValue
@onready var budget_bar: ProgressBar = $SafeArea/MainVBox/ContentScroll/Content/BiosCard/BiosVBox/BudgetBar
@onready var risk_value: Label = $SafeArea/MainVBox/ContentScroll/Content/BiosCard/BiosVBox/RiskRow/RiskValue
@onready var risk_bar: ProgressBar = $SafeArea/MainVBox/ContentScroll/Content/BiosCard/BiosVBox/RiskBar

@onready var preview_bottleneck: Label = $SafeArea/MainVBox/ContentScroll/Content/PreviewCard/PreviewVBox/BottleneckRow/BottleneckValue
@onready var preview_fps_value: Label = $SafeArea/MainVBox/ContentScroll/Content/PreviewCard/PreviewVBox/FpsRow/FpsValue
@onready var preview_fps_bar: ProgressBar = $SafeArea/MainVBox/ContentScroll/Content/PreviewCard/PreviewVBox/FpsBar
@onready var preview_cpu_value: Label = $SafeArea/MainVBox/ContentScroll/Content/PreviewCard/PreviewVBox/CpuRow/CpuLoadValue
@onready var preview_cpu_bar: ProgressBar = $SafeArea/MainVBox/ContentScroll/Content/PreviewCard/PreviewVBox/CpuBar
@onready var preview_ram_value: Label = $SafeArea/MainVBox/ContentScroll/Content/PreviewCard/PreviewVBox/RamRow/RamUsageValue
@onready var preview_ram_bar: ProgressBar = $SafeArea/MainVBox/ContentScroll/Content/PreviewCard/PreviewVBox/RamBar

@onready var terminal_output: RichTextLabel = $SafeArea/MainVBox/ContentScroll/Content/TerminalCard/TerminalVBox/TerminalOutput
@onready var diagnostic_card: PanelContainer = $SafeArea/MainVBox/ContentScroll/Content/DiagnosticCard
@onready var diagnostic_headline: Label = $SafeArea/MainVBox/ContentScroll/Content/DiagnosticCard/DiagnosticVBox/DiagnosticHeadline
@onready var diagnostic_details: RichTextLabel = $SafeArea/MainVBox/ContentScroll/Content/DiagnosticCard/DiagnosticVBox/DiagnosticDetails

@onready var status_label: Label = $SafeArea/MainVBox/BottomBar/StatusRow/StatusLabel
@onready var btn_benchmark: Button = $SafeArea/MainVBox/BottomBar/ActionsRow/BtnBenchmark
@onready var btn_reset: Button = $SafeArea/MainVBox/BottomBar/ActionsRow/BtnReset
@onready var btn_confirm: Button = $SafeArea/MainVBox/BottomBar/ActionsRow/BtnConfirm
@onready var btn_next_level: Button = $SafeArea/MainVBox/BottomBar/ActionsRow/BtnNextLevel

func _tr(key: String, default_text: String, params: Dictionary = {}) -> String:
	var merged: Dictionary = params.duplicate(true)
	merged["default"] = default_text
	return I18n.tr_key(key, merged)

func _ready() -> void:
	add_to_group("resus_b_controller")
	if not GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.connect(_on_stability_changed)
	if not get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.connect(_on_viewport_size_changed)
	if not I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.connect(_on_language_changed)

	btn_back.pressed.connect(_on_back_pressed)
	btn_benchmark.pressed.connect(_on_benchmark_pressed)
	btn_reset.pressed.connect(_on_reset_pressed)
	btn_confirm.pressed.connect(_on_confirm_pressed)
	btn_next_level.pressed.connect(_on_next_level_pressed)
	cpu_level.item_selected.connect(_on_cpu_changed)
	ram_level.item_selected.connect(_on_ram_changed)
	gpu_level.item_selected.connect(_on_gpu_changed)

	_fill_option_button(cpu_level, CPU_ORDER)
	_fill_option_button(ram_level, RAM_ORDER)
	_fill_option_button(gpu_level, GPU_ORDER)

	levels = ResusData.load_stage_levels(LEVELS_PATH, STAGE_ID)
	if levels.is_empty():
		_show_error(_tr("resus.b.error.load", "Stage B data is missing."))
		return

	_load_current_level(0)
	_on_viewport_size_changed()

func _exit_tree() -> void:
	if I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.disconnect(_on_language_changed)
	if get_tree() != null and get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.disconnect(_on_viewport_size_changed)

func _on_language_changed(_code: String) -> void:
	_apply_i18n()

func _apply_i18n() -> void:
	title_label.text = _tr("resus.title", "Case 01: Digital Resus")
	stage_label.text = _tr("resus.b.stage.progress", "STAGE B {n}/{total}", {
		"n": current_level_index + 1,
		"total": max(1, levels.size())
	})
	btn_benchmark.text = _tr("resus.b.btn.benchmark", "RUN BENCHMARK")
	btn_reset.text = _tr("resus.b.btn.reset", "RESET")
	btn_confirm.text = _tr("resus.b.btn.confirm", "CONFIRM")
	btn_next_level.text = _next_level_button_text()

func _fill_option_button(button: OptionButton, ordered_ids: Array[String]) -> void:
	button.clear()
	for id in ordered_ids:
		button.add_item(id)

func _load_current_level(index: int) -> void:
	current_level_index = clamp(index, 0, max(0, levels.size() - 1))
	stage_b_data = (levels[current_level_index] as Dictionary).duplicate(true)
	_setup_level_ui()
	_begin_attempt()

func _setup_level_ui() -> void:
	_apply_i18n()
	var level_id: String = str(stage_b_data.get("id", "CASE01_B"))
	context_label.text = _tr("resus.b.level.%s.context" % level_id, str(stage_b_data.get("context", "")))
	budget_value.text = "%d$" % int(stage_b_data.get("budget", 0))
	terminal_output.text = _tr("resus.b.terminal.ready", "[READY] Load a preset or tune BIOS values, then run benchmark.")
	diagnostic_headline.text = _tr("resus.b.diagnostic.waiting", "Awaiting benchmark.")
	diagnostic_details.text = ""
	diagnostic_card.visible = false
	btn_next_level.visible = false
	btn_next_level.disabled = true
	_populate_option_cards()
	_update_stability_ui()

func _begin_attempt() -> void:
	trace.clear()
	tune_change_count = 0
	time_to_first_action_ms = -1
	input_locked = false
	stage_started_ms = Time.get_ticks_msec()
	loaded_preset_id = ""
	_last_result.clear()
	_last_payload.clear()

	btn_benchmark.disabled = false
	btn_confirm.disabled = true
	btn_next_level.visible = false
	btn_next_level.disabled = true
	cpu_level.disabled = false
	ram_level.disabled = false
	gpu_level.disabled = false
	diagnostic_card.visible = false

	var default_tuning: Dictionary = stage_b_data.get("default_tuning", {
		"cpu": "MID",
		"ram": "GOOD",
		"gpu": "NONE"
	}) as Dictionary
	_set_tuning(default_tuning, false)
	snapshot_b["benchmark_ran"] = false
	snapshot_b["classified_as"] = "UNKNOWN"
	snapshot_b["preview_metrics"] = {}
	snapshot_b["total_price"] = 0
	_recompute_preview()

	terminal_output.text = _tr("resus.b.terminal.ready", "[READY] Load a preset or tune BIOS values, then run benchmark.")
	status_label.text = _tr("resus.b.status.ready", "Tune the profile, then benchmark it.")
	status_label.modulate = COLOR_WARN

func _on_cpu_changed(_index: int) -> void:
	_on_tuning_changed()

func _on_ram_changed(_index: int) -> void:
	_on_tuning_changed()

func _on_gpu_changed(_index: int) -> void:
	_on_tuning_changed()

func _on_tuning_changed() -> void:
	if input_locked:
		return
	_mark_first_action()
	tune_change_count += 1
	loaded_preset_id = ""
	snapshot_b["tuning"] = _read_tuning_from_controls()
	snapshot_b["benchmark_ran"] = false
	snapshot_b["classified_as"] = "UNKNOWN"
	btn_confirm.disabled = true
	btn_next_level.visible = false
	btn_next_level.disabled = true
	diagnostic_card.visible = false
	_recompute_preview()

	_log_event("TUNING_CHANGED", {
		"cpu": str(snapshot_b["tuning"].get("cpu", "")),
		"ram": str(snapshot_b["tuning"].get("ram", "")),
		"gpu": str(snapshot_b["tuning"].get("gpu", "")),
		"total_price": int(snapshot_b.get("total_price", 0))
	})
	_play_sfx("click")

func _on_benchmark_pressed() -> void:
	if input_locked:
		return
	_mark_first_action()
	var class_code: String = _classify_current_profile()
	snapshot_b["classified_as"] = class_code
	snapshot_b["benchmark_ran"] = true
	btn_confirm.disabled = false

	var lines: Array[String] = _benchmark_lines(class_code)
	terminal_output.text = "\n".join(lines)
	terminal_output.scroll_to_line(max(0, terminal_output.get_line_count() - 1))

	status_label.text = _tr("resus.b.status.benchmark_result", "BENCHMARK: {code}", {"code": _display_class_label(class_code)})
	status_label.modulate = COLOR_OK if class_code == str(stage_b_data.get("correct_option_id", "OPTIMAL")) else COLOR_WARN
	_log_event("BENCHMARK_RUN", {
		"class_code": class_code,
		"preview_metrics": (snapshot_b.get("preview_metrics", {}) as Dictionary).duplicate(true)
	})
	_play_sfx("relay")

func _on_confirm_pressed() -> void:
	if input_locked:
		return
	if not bool(snapshot_b.get("benchmark_ran", false)):
		status_label.text = _tr("resus.b.status.no_benchmark", "Run benchmark before confirm.")
		status_label.modulate = COLOR_ERR
		return

	var class_code: String = str(snapshot_b.get("classified_as", "UNKNOWN"))
	_log_event("CONFIRM_PRESSED", {"class_code": class_code})

	input_locked = true
	btn_confirm.disabled = true
	btn_benchmark.disabled = true
	cpu_level.disabled = true
	ram_level.disabled = true
	gpu_level.disabled = true

	var result: Dictionary = ResusScoring.calculate_stage_b_result(stage_b_data, {
		"selected_option_id": class_code,
		"classified_as": class_code
	})
	_register_trial(result)
	attempt_index += 1
	_show_result(result)
	_update_stability_ui()

	var can_advance: bool = bool(result.get("is_correct", false)) and (_has_next_level() or _is_flow_active())
	btn_next_level.visible = can_advance
	btn_next_level.disabled = not can_advance
	btn_next_level.text = _next_level_button_text()

	_play_sfx("relay" if bool(result.get("is_correct", false)) else "error")

func _show_result(result: Dictionary) -> void:
	var headline: String = str(result.get("diagnostic_headline", _tr("resus.b.diagnostic.fallback", "Classification complete.")))
	var details: Array[String] = _to_string_array(result.get("diagnostic_details", []))
	var detail_lines: Array[String] = []
	for detail in details:
		detail_lines.append("- %s" % detail)

	diagnostic_headline.text = headline
	diagnostic_details.text = "\n".join(detail_lines)
	diagnostic_card.visible = true

	status_label.text = _tr("resus.b.status.blocked", "{code} | review the diagnosis", {
		"code": str(result.get("classified_as", "UNKNOWN"))
	})
	status_label.modulate = COLOR_OK if bool(result.get("is_correct", false)) else COLOR_ERR

func _on_reset_pressed() -> void:
	_log_event("RESET_PRESSED", {
		"classified_as": str(snapshot_b.get("classified_as", "UNKNOWN"))
	})
	_begin_attempt()
	_play_sfx("click")

func _on_next_level_pressed() -> void:
	if _last_result.is_empty() or not bool(_last_result.get("is_correct", false)):
		return
	if _has_next_level():
		_load_current_level(current_level_index + 1)
		_play_sfx("click")
		return
	if _is_flow_active():
		GlobalMetrics.record_case_stage_result(STAGE_ID, _build_flow_stage_summary())
		get_tree().change_scene_to_file(FLOW_SCENE_PATH)

func _has_next_level() -> bool:
	return current_level_index < levels.size() - 1

func _set_tuning(tuning: Dictionary, emit_event: bool) -> void:
	_set_option_button_value(cpu_level, CPU_ORDER, str(tuning.get("cpu", "MID")))
	_set_option_button_value(ram_level, RAM_ORDER, str(tuning.get("ram", "GOOD")))
	_set_option_button_value(gpu_level, GPU_ORDER, str(tuning.get("gpu", "NONE")))
	snapshot_b["tuning"] = _read_tuning_from_controls()
	if emit_event:
		_on_tuning_changed()
	else:
		_recompute_preview()

func _set_option_button_value(button: OptionButton, order: Array[String], value: String) -> void:
	var target_idx: int = 0
	for i in range(order.size()):
		if order[i] == value:
			target_idx = i
			break
	button.select(target_idx)

func _read_tuning_from_controls() -> Dictionary:
	return {
		"cpu": cpu_level.get_item_text(cpu_level.selected),
		"ram": ram_level.get_item_text(ram_level.selected),
		"gpu": gpu_level.get_item_text(gpu_level.selected)
	}

func _recompute_preview() -> void:
	var tuning: Dictionary = snapshot_b.get("tuning", {}) as Dictionary
	var metrics: Dictionary = _calculate_metrics(tuning)
	var class_code: String = _classify_profile(metrics)
	var preview_override: Dictionary = _preview_metrics_for_class(class_code)
	if not preview_override.is_empty():
		for key in preview_override.keys():
			metrics[key] = preview_override.get(key)

	metrics["class_code"] = class_code
	metrics["risk_score"] = int(RISK_BY_CLASS.get(class_code, 84))
	snapshot_b["preview_metrics"] = metrics.duplicate(true)
	snapshot_b["classified_as"] = class_code if bool(snapshot_b.get("benchmark_ran", false)) else "UNKNOWN"
	snapshot_b["total_price"] = int(metrics.get("total_price", 0))
	_set_option_card_selected(loaded_preset_id)

	var budget: int = int(stage_b_data.get("budget", 0))
	used_budget_value.text = "%d$" % int(metrics.get("total_price", 0))
	budget_bar.max_value = max(1.0, float(budget))
	budget_bar.value = float(int(metrics.get("total_price", 0)))
	risk_bar.value = float(int(metrics.get("risk_score", 0)))
	risk_value.text = _risk_label(int(metrics.get("risk_score", 0)))
	risk_value.modulate = _risk_color(int(metrics.get("risk_score", 0)))

	preview_bottleneck.text = _display_class_label(class_code)
	preview_bottleneck.modulate = _bottleneck_color(class_code)
	preview_fps_value.text = str(int(metrics.get("fps", 0)))
	preview_fps_bar.value = float(int(metrics.get("fps", 0)))
	preview_cpu_value.text = "%d%%" % int(metrics.get("cpu_load", 0))
	preview_cpu_bar.value = float(int(metrics.get("cpu_load", 0)))
	preview_ram_value.text = "%d%%" % int(metrics.get("ram_usage", 0))
	preview_ram_bar.value = float(int(metrics.get("ram_usage", 0)))

	if not bool(snapshot_b.get("benchmark_ran", false)):
		status_label.text = _tr("resus.b.status.profile_ready", "Preview ready | {used}$ / {budget}$", {
			"used": int(metrics.get("total_price", 0)),
			"budget": budget
		})
		status_label.modulate = COLOR_WARN

func _calculate_metrics(tuning: Dictionary) -> Dictionary:
	var tuning_model: Dictionary = stage_b_data.get("tuning_model", {}) as Dictionary
	var cpu_id: String = str(tuning.get("cpu", "MID"))
	var ram_id: String = str(tuning.get("ram", "GOOD"))
	var gpu_id: String = str(tuning.get("gpu", "NONE"))

	var cpu_data: Dictionary = (tuning_model.get("cpu", {}) as Dictionary).get(cpu_id, {}) as Dictionary
	var ram_data: Dictionary = (tuning_model.get("ram", {}) as Dictionary).get(ram_id, {}) as Dictionary
	var gpu_data: Dictionary = (tuning_model.get("gpu", {}) as Dictionary).get(gpu_id, {}) as Dictionary

	var cpu_perf: int = int(cpu_data.get("perf", 0))
	var ram_perf: int = int(ram_data.get("perf", 0))
	var gpu_perf: int = int(gpu_data.get("perf", 0))
	var budget: int = int(stage_b_data.get("budget", 0))
	var total_price: int = int(cpu_data.get("price", 0)) + int(ram_data.get("price", 0)) + int(gpu_data.get("price", 0))
	var perf_score: int = cpu_perf + ram_perf + gpu_perf
	var overbudget_penalty: int = max(0, total_price - budget)
	var fps: int = clampi(12 + cpu_perf * 14 + ram_perf * 9 + gpu_perf * 16 - int(float(overbudget_penalty) / 18.0), 6, 100)
	var cpu_load: int = clampi(94 - cpu_perf * 16 + (12 if ram_perf <= 1 else 0) + (10 if gpu_perf <= 0 else 0), 16, 99)
	var ram_usage: int = clampi(92 - ram_perf * 18 + (6 if gpu_perf >= 2 else 0), 14, 99)

	return {
		"cpu_perf": cpu_perf,
		"ram_perf": ram_perf,
		"gpu_perf": gpu_perf,
		"total_price": total_price,
		"perf_score": perf_score,
		"fps": fps,
		"cpu_load": cpu_load,
		"ram_usage": ram_usage
	}

func _classify_current_profile() -> String:
	var metrics: Dictionary = snapshot_b.get("preview_metrics", {}) as Dictionary
	if metrics.is_empty():
		metrics = _calculate_metrics(snapshot_b.get("tuning", {}) as Dictionary)
	return _classify_profile(metrics)

func _classify_profile(metrics: Dictionary) -> String:
	var thresholds: Dictionary = stage_b_data.get("classifier_thresholds", {}) as Dictionary
	var budget: int = int(stage_b_data.get("budget", 0))
	var total_price: int = int(metrics.get("total_price", 0))
	var perf_score: int = int(metrics.get("perf_score", 0))
	var cpu_perf: int = int(metrics.get("cpu_perf", 0))
	var ram_perf: int = int(metrics.get("ram_perf", 0))
	var gpu_perf: int = int(metrics.get("gpu_perf", 0))

	if total_price > budget:
		return "OVERBUDGET"
	if perf_score <= int(thresholds.get("lowpower_perf_max", 4)):
		return "LOWPOWER"
	if gpu_perf <= int(thresholds.get("gpu_low_max", 0)) and cpu_perf >= int(thresholds.get("cpu_mid_min", 2)) and ram_perf >= int(thresholds.get("ram_good_min", 2)):
		return "BOTTLENECK_GPU"
	if cpu_perf <= int(thresholds.get("cpu_low_max", 1)) and ram_perf >= int(thresholds.get("ram_good_min", 2)) and gpu_perf >= int(thresholds.get("gpu_good_min", 2)):
		return "BOTTLENECK_CPU"
	if ram_perf <= int(thresholds.get("ram_low_max", 1)) and cpu_perf >= int(thresholds.get("cpu_high_min", 3)):
		return "BOTTLENECK_RAM"
	return "OPTIMAL"

func _benchmark_lines(class_code: String) -> Array[String]:
	var outputs: Dictionary = stage_b_data.get("benchmark_lines", stage_b_data.get("benchmark_outputs", {})) as Dictionary
	var lines: Array[String] = _to_string_array(outputs.get(class_code, []))
	if lines.is_empty():
		lines.append(_tr("resus.b.terminal.result_fallback", "[RESULT] {code}", {"code": class_code}))
	return lines

func _preview_metrics_for_class(class_code: String) -> Dictionary:
	var option_data: Dictionary = _option_data_by_id(class_code)
	if not option_data.is_empty():
		var option_preview: Dictionary = option_data.get("preview_metrics", {}) as Dictionary
		if not option_preview.is_empty():
			return option_preview
	var preview_profiles: Dictionary = stage_b_data.get("preview_profiles", {}) as Dictionary
	return preview_profiles.get(class_code, {}) as Dictionary

func _risk_label(score: int) -> String:
	if score >= 80:
		return "HIGH"
	if score >= 50:
		return "MID"
	return "LOW"

func _risk_color(score: int) -> Color:
	if score >= 80:
		return COLOR_ERR
	if score >= 50:
		return COLOR_WARN
	return COLOR_OK

func _display_class_label(class_code: String) -> String:
	match class_code:
		"BOTTLENECK_GPU":
			return "GPU BOTTLENECK"
		"BOTTLENECK_CPU":
			return "CPU BOTTLENECK"
		"BOTTLENECK_RAM":
			return "RAM BOTTLENECK"
		"LOWPOWER":
			return "LOW POWER"
		"OVERBUDGET":
			return "OVER BUDGET"
		_:
			return "OPTIMAL"

func _bottleneck_color(class_code: String) -> Color:
	if class_code == "OPTIMAL":
		return COLOR_OK
	if class_code == "OVERBUDGET" or class_code == "LOWPOWER":
		return COLOR_ERR
	return COLOR_WARN

func _register_trial(result: Dictionary) -> void:
	var elapsed_ms: int = Time.get_ticks_msec() - stage_started_ms
	var level_id: String = str(stage_b_data.get("id", "CASE01_B_01"))
	var payload: Dictionary = TrialV2.build(
		CASE_ID,
		STAGE_ID,
		level_id,
		"BIOS_TUNING",
		str(attempt_index)
	)
	var snapshot: Dictionary = {
		"tuning": (snapshot_b.get("tuning", {}) as Dictionary).duplicate(true),
		"preview_metrics": (snapshot_b.get("preview_metrics", {}) as Dictionary).duplicate(true),
		"benchmark_ran": bool(snapshot_b.get("benchmark_ran", false)),
		"classified_as": str(snapshot_b.get("classified_as", "UNKNOWN")),
		"total_price": int(snapshot_b.get("total_price", 0))
	}
	payload.merge({
		"case_run_id": _case_run_id(),
		"level_id": level_id,
		"format": str(stage_b_data.get("format", "SINGLE_CHOICE_CONTEXT")),
		"budget": int(stage_b_data.get("budget", 0)),
		"snapshot": snapshot,
		"points": int(result.get("points", 0)),
		"max_points": int(result.get("max_points", 2)),
		"is_correct": bool(result.get("is_correct", false)),
		"is_fit": bool(result.get("is_fit", false)),
		"stability_delta": int(result.get("stability_delta", 0)),
		"verdict_code": str(result.get("verdict_code", "WRONG")),
		"error_code": str(result.get("error_code", "UNKNOWN")),
		"classified_as": str(result.get("classified_as", snapshot.get("classified_as", "UNKNOWN"))),
		"diagnostic_headline": str(result.get("diagnostic_headline", "")),
		"diagnostic_details": _to_string_array(result.get("diagnostic_details", [])),
		"selected_preset_id": loaded_preset_id,
		"selection_count": tune_change_count,
		"time_to_first_action_ms": max(-1, time_to_first_action_ms),
		"elapsed_ms": elapsed_ms,
		"trace": trace.duplicate(true)
	}, true)
	GlobalMetrics.register_trial(payload)
	_last_result = result.duplicate(true)
	_last_payload = payload.duplicate(true)

func _mark_first_action() -> void:
	if time_to_first_action_ms < 0:
		time_to_first_action_ms = Time.get_ticks_msec() - stage_started_ms

func _log_event(event_name: String, data: Dictionary = {}) -> void:
	trace.append({
		"t_ms": Time.get_ticks_msec() - stage_started_ms,
		"event": event_name,
		"data": data.duplicate(true)
	})

func _to_string_array(values: Variant) -> Array[String]:
	var out: Array[String] = []
	if typeof(values) != TYPE_ARRAY:
		return out
	for value_v in values as Array:
		out.append(str(value_v))
	return out

func _play_sfx(event_name: String) -> void:
	if has_node("/root/AudioManager"):
		AudioManager.play(event_name)

func _on_back_pressed() -> void:
	if _is_flow_active():
		GlobalMetrics.clear_case_flow()
	get_tree().change_scene_to_file(QUEST_SELECT_SCENE)

func _on_stability_changed(_new_value: float, _delta: float) -> void:
	_update_stability_ui()

func _update_stability_ui() -> void:
	stability_bar.value = GlobalMetrics.stability
	if noir_overlay != null and noir_overlay.has_method("set_danger_level"):
		noir_overlay.call("set_danger_level", float(GlobalMetrics.stability))

func _show_error(message: String) -> void:
	status_label.text = message
	status_label.modulate = COLOR_ERR
	btn_confirm.disabled = true
	btn_reset.disabled = true
	btn_benchmark.disabled = true
	btn_next_level.disabled = true

func _populate_option_cards() -> void:
	for child in options_list.get_children():
		child.queue_free()
	_option_cards_by_id.clear()

	var index: int = 1
	for option_v in stage_b_data.get("options", []) as Array:
		if typeof(option_v) != TYPE_DICTIONARY:
			continue
		var option_data: Dictionary = option_v as Dictionary
		var option_id: String = str(option_data.get("option_id", "")).strip_edges()
		if option_id == "":
			continue

		var btn: Button = Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0.0, 72.0)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.text = "%s | %s" % [_preset_label(option_data, index), _preset_parts_summary(option_data)]
		btn.tooltip_text = _preset_tooltip(option_data, index)
		btn.pressed.connect(_on_option_card_pressed.bind(option_id))
		options_list.add_child(btn)
		_option_cards_by_id[option_id] = btn
		index += 1

func _preset_label(option_data: Dictionary, index: int) -> String:
	var title: String = str(option_data.get("title", "")).strip_edges()
	if title != "":
		return title
	return "Preset Rig %d" % index

func _preset_parts_summary(option_data: Dictionary) -> String:
	var parts: Array = option_data.get("parts", []) as Array
	var tokens: Array[String] = []
	for part_v in parts:
		if typeof(part_v) != TYPE_DICTIONARY:
			continue
		var part: Dictionary = part_v as Dictionary
		tokens.append("%s=%s" % [str(part.get("k", "")), str(part.get("v", ""))])
	return ", ".join(tokens)

func _preset_tooltip(option_data: Dictionary, index: int) -> String:
	return "%s\n%s$\n%s" % [
		_preset_label(option_data, index),
		str(option_data.get("total_price", 0)),
		_preset_parts_summary(option_data)
	]

func _on_option_card_pressed(option_id: String) -> void:
	if input_locked:
		return
	var option_data: Dictionary = _option_data_by_id(option_id)
	if option_data.is_empty():
		return
	loaded_preset_id = option_id
	_log_event("PRESET_LOADED", {"preset_id": option_id})
	_set_tuning(_tuning_from_option(option_data), true)

func _option_data_by_id(option_id: String) -> Dictionary:
	for option_v in stage_b_data.get("options", []) as Array:
		if typeof(option_v) != TYPE_DICTIONARY:
			continue
		var option_data: Dictionary = option_v as Dictionary
		if str(option_data.get("option_id", "")) == option_id:
			return option_data
	return {}

func _tuning_from_option(option_data: Dictionary) -> Dictionary:
	var tuning: Dictionary = {"cpu": "LOW", "ram": "LOW", "gpu": "NONE"}
	for part_v in option_data.get("parts", []) as Array:
		if typeof(part_v) != TYPE_DICTIONARY:
			continue
		var part: Dictionary = part_v as Dictionary
		match str(part.get("k", "")).to_upper():
			"CPU":
				tuning["cpu"] = str(part.get("v", "LOW")).to_upper()
			"RAM":
				tuning["ram"] = str(part.get("v", "LOW")).to_upper()
			"GPU":
				tuning["gpu"] = str(part.get("v", "NONE")).to_upper()
	return tuning

func _set_option_card_selected(option_id: String) -> void:
	for id_v in _option_cards_by_id.keys():
		var id: String = str(id_v)
		var btn_v: Variant = _option_cards_by_id.get(id, null)
		if not (btn_v is Button):
			continue
		var btn: Button = btn_v as Button
		var selected: bool = id == option_id and option_id != ""
		btn.modulate = Color(1.08, 1.08, 1.08, 1.0) if selected else Color(1.0, 1.0, 1.0, 1.0)

func _on_viewport_size_changed() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var is_landscape: bool = viewport_size.x >= viewport_size.y
	var phone_landscape: bool = is_landscape and viewport_size.y <= PHONE_LANDSCAPE_MAX_HEIGHT
	var phone_portrait: bool = (not is_landscape) and viewport_size.x <= PHONE_PORTRAIT_MAX_WIDTH
	var compact: bool = phone_landscape or phone_portrait

	_apply_safe_area_padding(compact)
	main_vbox.add_theme_constant_override("separation", 8 if compact else 10)
	content_vbox.add_theme_constant_override("separation", 8 if compact else 10)
	header.add_theme_constant_override("separation", 8 if compact else 10)
	bottom_bar.add_theme_constant_override("separation", 8 if compact else 10)
	stability_bar.custom_minimum_size.x = 160.0 if compact else 220.0
	btn_back.custom_minimum_size = Vector2(56.0 if compact else 72.0, 56.0 if compact else 72.0)
	btn_benchmark.custom_minimum_size = Vector2(0.0, 60.0 if compact else 72.0)
	btn_reset.custom_minimum_size = Vector2(0.0, 60.0 if compact else 72.0)
	btn_confirm.custom_minimum_size = Vector2(0.0, 60.0 if compact else 72.0)
	btn_next_level.custom_minimum_size = Vector2(0.0, 60.0 if compact else 72.0)
	status_label.custom_minimum_size.y = 44.0 if compact else 56.0

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

func _build_flow_stage_summary() -> Dictionary:
	var case_run_id: String = _case_run_id()
	var total_points: int = 0
	var total_stability_delta: int = 0
	for entry_v in GlobalMetrics.session_history:
		if typeof(entry_v) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_v as Dictionary
		if str(entry.get("quest_id", "")) != CASE_ID:
			continue
		if str(entry.get("stage", "")) != STAGE_ID:
			continue
		if str(entry.get("case_run_id", "")) != case_run_id:
			continue
		total_points += int(entry.get("points", 0))
		total_stability_delta += int(entry.get("stability_delta", 0))
	return {
		"stage": STAGE_ID,
		"case_run_id": case_run_id,
		"levels_completed": levels.size(),
		"last_level_id": str(stage_b_data.get("id", "")),
		"points": total_points,
		"stability_delta": total_stability_delta,
		"completed_at_unix": Time.get_unix_time_from_system()
	}

func _next_level_button_text() -> String:
	if not _has_next_level() and _is_flow_active():
		return _tr("resus.b.btn.next_stage", "NEXT STAGE")
	return _tr("resus.b.btn.next_level", "NEXT LEVEL")

func _is_flow_active() -> bool:
	var flow: Dictionary = GlobalMetrics.get_case_flow()
	return bool(flow.get("is_active", false)) and str(flow.get("case_id", "")) == CASE_ID

func _case_run_id() -> String:
	var flow: Dictionary = GlobalMetrics.get_case_flow()
	return str(flow.get("case_run_id", ""))
