extends Control

const LEVELS_PATH: String = "res://data/clues_levels.json"
const ResusData = preload("res://scripts/case_01/ResusData.gd")
const ResusScoring = preload("res://scripts/case_01/ResusScoring.gd")
const PHONE_LANDSCAPE_MAX_HEIGHT := 740.0
const PHONE_PORTRAIT_MAX_WIDTH := 520.0

const COLOR_OK: Color = Color(0.9, 0.93, 0.98, 1.0)
const COLOR_WARN: Color = Color(0.98, 0.8, 0.52, 1.0)
const COLOR_ERR: Color = Color(0.95, 0.36, 0.38, 1.0)

const CPU_ORDER: Array[String] = ["LOW", "MID", "HIGH"]
const RAM_ORDER: Array[String] = ["LOW", "GOOD", "TOP"]
const GPU_ORDER: Array[String] = ["NONE", "MID", "TOP"]

var levels: Array = []
var current_level_index: int = 0
var stage_b_data: Dictionary = {}
var trace: Array = []

var stage_started_ms: int = 0
var time_to_first_action_ms: int = -1
var tune_change_count: int = 0
var attempt_index: int = 0
var input_locked: bool = false

var _bottom_mobile_layout: VBoxContainer = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null
var _context_collapsed: bool = true
var _context_toggle_button: Button = null
var _option_cards_by_id: Dictionary = {}

var snapshot_b: Dictionary = {
	"tuning": {"cpu": "MID", "ram": "GOOD", "gpu": "NONE"},
	"selected_option_id": "UNKNOWN",
	"classified_as": "UNKNOWN",
	"total_price": 0,
	"benchmark_ran": false,
	"preview_metrics": {}
}

@onready var noir_overlay: Node = $NoirOverlay
@onready var safe_area: MarginContainer = $SafeArea
@onready var main_vbox: VBoxContainer = $SafeArea/MainVBox
@onready var header: HBoxContainer = $SafeArea/MainVBox/Header
@onready var bottom_bar: HBoxContainer = $SafeArea/MainVBox/BottomBar
@onready var tune_grid: GridContainer = $SafeArea/MainVBox/BiosCard/BiosVBox/TuneGrid
@onready var title_label: Label = $SafeArea/MainVBox/Header/TitleLabel
@onready var stage_label: Label = $SafeArea/MainVBox/Header/StageLabel
@onready var stability_bar: ProgressBar = $SafeArea/MainVBox/Header/StabilityBar
@onready var btn_back: Button = $SafeArea/MainVBox/Header/BtnBack

@onready var context_label: Label = $SafeArea/MainVBox/ContextCard/ContextVBox/ContextLabel
@onready var budget_row: HBoxContainer = $SafeArea/MainVBox/ContextCard/ContextVBox/BudgetRow
@onready var budget_value: Label = $SafeArea/MainVBox/ContextCard/ContextVBox/BudgetRow/BudgetValue
@onready var options_list: VBoxContainer = $SafeArea/MainVBox/OptionsCard/OptionsVBox/OptionsScroll/OptionsList

@onready var cpu_level: OptionButton = $SafeArea/MainVBox/BiosCard/BiosVBox/TuneGrid/CpuLevel
@onready var ram_level: OptionButton = $SafeArea/MainVBox/BiosCard/BiosVBox/TuneGrid/RamLevel
@onready var gpu_level: OptionButton = $SafeArea/MainVBox/BiosCard/BiosVBox/TuneGrid/GpuLevel
@onready var used_budget_value: Label = $SafeArea/MainVBox/BiosCard/BiosVBox/TuneGrid/UsedBudgetValue
@onready var budget_bar: ProgressBar = $SafeArea/MainVBox/BiosCard/BiosVBox/BudgetBar
@onready var risk_value: Label = $SafeArea/MainVBox/BiosCard/BiosVBox/RiskRow/RiskValue
@onready var risk_bar: ProgressBar = $SafeArea/MainVBox/BiosCard/BiosVBox/RiskBar

@onready var preview_bottleneck: Label = $SafeArea/MainVBox/PreviewCard/PreviewVBox/BottleneckRow/BottleneckValue
@onready var preview_fps_value: Label = $SafeArea/MainVBox/PreviewCard/PreviewVBox/FpsRow/FpsValue
@onready var preview_fps_bar: ProgressBar = $SafeArea/MainVBox/PreviewCard/PreviewVBox/FpsBar
@onready var preview_cpu_value: Label = $SafeArea/MainVBox/PreviewCard/PreviewVBox/CpuRow/CpuLoadValue
@onready var preview_cpu_bar: ProgressBar = $SafeArea/MainVBox/PreviewCard/PreviewVBox/CpuBar
@onready var preview_ram_value: Label = $SafeArea/MainVBox/PreviewCard/PreviewVBox/RamRow/RamUsageValue
@onready var preview_ram_bar: ProgressBar = $SafeArea/MainVBox/PreviewCard/PreviewVBox/RamBar

@onready var terminal_output: RichTextLabel = $SafeArea/MainVBox/TerminalCard/TerminalVBox/TerminalOutput
@onready var diagnostic_card: PanelContainer = $SafeArea/MainVBox/DiagnosticCard
@onready var diagnostic_headline: Label = $SafeArea/MainVBox/DiagnosticCard/DiagnosticVBox/DiagnosticHeadline
@onready var diagnostic_details: RichTextLabel = $SafeArea/MainVBox/DiagnosticCard/DiagnosticVBox/DiagnosticDetails

@onready var status_label: Label = $SafeArea/MainVBox/BottomBar/StatusLabel
@onready var btn_benchmark: Button = $SafeArea/MainVBox/BottomBar/BtnBenchmark
@onready var btn_reset: Button = $SafeArea/MainVBox/BottomBar/BtnReset
@onready var btn_confirm: Button = $SafeArea/MainVBox/BottomBar/BtnConfirm
@onready var btn_next_level: Button = $SafeArea/MainVBox/BottomBar/BtnNextLevel

func _tr(key: String, default_text: String, params: Dictionary = {}) -> String:
	var merged: Dictionary = params.duplicate(true)
	merged["default"] = default_text
	return I18n.tr_key(key, merged)

func _on_language_changed(_code: String) -> void:
	_apply_i18n()

func _apply_i18n() -> void:
	title_label.text = _tr("resus.title", "Кейс 01: Цифровая реанимация")
	if levels.size() > 0:
		stage_label.text = _tr("resus.b.stage", "ЭТАП Б {n}/{total}", {
			"n": current_level_index + 1, "total": levels.size()
		})
	btn_reset.text = _tr("resus.b.btn.reset", "СБРОС")
	btn_confirm.text = _tr("resus.b.btn.confirm", "ПОДТВЕРДИТЬ")
	btn_benchmark.text = _tr("resus.b.btn.benchmark", "ЗАПУСТИТЬ ЭТАЛОН")
	btn_next_level.text = _tr("resus.b.btn.next", "СЛЕД. ЭТАП")
	if not diagnostic_card.visible:
		diagnostic_headline.text = _tr("resus.b.diagnostic.waiting", "Жду эталона...")

func _ready() -> void:
	if not GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.connect(_on_stability_changed)

	btn_back.pressed.connect(_on_back_pressed)
	btn_benchmark.pressed.connect(_on_benchmark_pressed)
	btn_reset.pressed.connect(_on_reset_pressed)
	btn_confirm.pressed.connect(_on_confirm_pressed)
	btn_next_level.pressed.connect(_on_next_level_pressed)
	cpu_level.item_selected.connect(_on_cpu_changed)
	ram_level.item_selected.connect(_on_ram_changed)
	gpu_level.item_selected.connect(_on_gpu_changed)

	_ensure_scroll_layout()
	_setup_collapsible_context()
	_populate_levels()
	levels = ResusData.load_stage_levels(LEVELS_PATH, "B")
	if levels.is_empty():
		_show_error(_tr("resus.b.error.load", "Не удалось загрузить данные случая 01, этап B."))
		return
	if not I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.connect(_on_language_changed)

	_load_current_level(0)
	_on_viewport_size_changed()
	if not get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.connect(_on_viewport_size_changed)

func _exit_tree() -> void:
	if I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.disconnect(_on_language_changed)
	if get_tree() != null and get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.disconnect(_on_viewport_size_changed)

func _populate_levels() -> void:
	_fill_option_button(cpu_level, CPU_ORDER)
	_fill_option_button(ram_level, RAM_ORDER)
	_fill_option_button(gpu_level, GPU_ORDER)

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
	var level_id: String = str(stage_b_data.get("id", ""))
	context_label.text = _tr("resus.b.level.%s.context" % level_id, str(stage_b_data.get("context", "Настройте профиль и запустите тест")))
	budget_value.text = "%d$" % int(stage_b_data.get("budget", 0))
	btn_next_level.visible = false
	btn_next_level.disabled = true
	diagnostic_headline.text = _tr("resus.b.diagnostic.waiting", "Жду эталона...")
	diagnostic_details.text = ""
	diagnostic_card.visible = false
	_populate_option_cards()
	_update_stability_ui()

func _begin_attempt() -> void:
	trace.clear()
	tune_change_count = 0
	time_to_first_action_ms = -1
	input_locked = false
	stage_started_ms = Time.get_ticks_msec()
	btn_benchmark.disabled = false
	btn_confirm.disabled = true
	btn_next_level.visible = false
	btn_next_level.disabled = true
	cpu_level.disabled = false
	ram_level.disabled = false
	gpu_level.disabled = false
	diagnostic_card.visible = false

	var default_tuning: Dictionary = stage_b_data.get("default_tuning", {"cpu": "MID", "ram": "GOOD", "gpu": "NONE"}) as Dictionary
	_set_tuning(default_tuning, false)
	snapshot_b["selected_option_id"] = "UNKNOWN"
	snapshot_b["classified_as"] = "UNKNOWN"
	snapshot_b["benchmark_ran"] = false
	snapshot_b["preview_metrics"] = {}
	terminal_output.text = _tr("resus.b.terminal.ready", "[ГОТОВО] Выберите профиль BIOS и запустите тест.")
	status_label.text = _tr("resus.b.status.ready", "ГОТОВО")
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

	var tuning: Dictionary = _read_tuning_from_controls()
	snapshot_b["tuning"] = tuning
	snapshot_b["benchmark_ran"] = false
	snapshot_b["classified_as"] = "UNKNOWN"
	snapshot_b["selected_option_id"] = "UNKNOWN"
	btn_confirm.disabled = true
	btn_next_level.visible = false
	btn_next_level.disabled = true
	diagnostic_card.visible = false
	_recompute_preview()

	_log_event("OPTION_SELECTED", {
		"selected_option_id": str(snapshot_b.get("selected_option_id", "UNKNOWN")),
		"cpu": str(tuning.get("cpu", "")),
		"ram": str(tuning.get("ram", "")),
		"gpu": str(tuning.get("gpu", "")),
		"total_price": int(snapshot_b.get("total_price", 0))
	})
	_play_sfx("click")

func _on_benchmark_pressed() -> void:
	if input_locked:
		return
	_mark_first_action()
	var class_code: String = _classify_current_profile()
	snapshot_b["selected_option_id"] = class_code
	snapshot_b["classified_as"] = class_code
	snapshot_b["benchmark_ran"] = true
	btn_confirm.disabled = false

	var lines: Array[String] = _benchmark_lines(class_code)
	terminal_output.text = ""
	for line in lines:
		terminal_output.text += line + "\n"
	terminal_output.scroll_to_line(max(0, terminal_output.get_line_count() - 1))

	status_label.text = _tr("resus.b.status.benchmark_result", "ЭТАЛОН: {code}", {"code": class_code})
	status_label.modulate = COLOR_OK if class_code == str(stage_b_data.get("correct_option_id", "OPTIMAL")) else COLOR_WARN
	_log_event("BENCHMARK_RUN", {
		"selected_option_id": class_code,
		"preview_metrics": (snapshot_b.get("preview_metrics", {}) as Dictionary).duplicate(true)
	})
	_play_sfx("relay")

func _on_confirm_pressed() -> void:
	if input_locked:
		return
	if not bool(snapshot_b.get("benchmark_ran", false)):
		status_label.text = _tr("resus.b.status.no_benchmark", "ЗАПУСТИТЕ ЭТАЛОННЫЙ ПРОВЕРКА ПЕРЕД ПОДТВЕРЖДЕНИЕМ")
		status_label.modulate = COLOR_ERR
		return

	var class_code: String = str(snapshot_b.get("classified_as", "UNKNOWN"))
	_log_event("CONFIRM_PRESSED", {
		"selected_option_id": class_code
	})

	input_locked = true
	btn_confirm.disabled = true
	btn_benchmark.disabled = true
	cpu_level.disabled = true
	ram_level.disabled = true
	gpu_level.disabled = true

	var scoring_snapshot: Dictionary = {
		"selected_option_id": class_code,
		"classified_as": class_code
	}
	var result: Dictionary = ResusScoring.calculate_stage_b_result(stage_b_data, scoring_snapshot)
	_register_trial(result)
	attempt_index += 1
	_show_result(result)
	_update_stability_ui()

	var has_next: bool = _has_next_level()
	btn_next_level.visible = has_next
	btn_next_level.disabled = not has_next

	if bool(result.get("is_correct", false)):
		_play_sfx("relay")
	else:
		_play_sfx("error")

func _show_result(result: Dictionary) -> void:
	var headline: String = str(result.get("diagnostic_headline", _tr("resus.b.fallback.classified", "Классификация завершена")))
	var details: Array = result.get("diagnostic_details", []) as Array
	var detail_lines: Array[String] = []
	for detail_v in details:
		detail_lines.append("- %s" % str(detail_v))
	diagnostic_headline.text = headline
	diagnostic_details.text = "\n".join(detail_lines)
	diagnostic_card.visible = true

	status_label.text = _tr("resus.b.status.blocked", "ЗАБЛОКИРОВАНО | {code}", {"code": str(result.get("verdict_code", "WRONG"))})
	status_label.modulate = COLOR_OK if bool(result.get("is_correct", false)) else COLOR_ERR

func _on_reset_pressed() -> void:
	_log_event("RESET_PRESSED", {
		"selected_option_id": str(snapshot_b.get("selected_option_id", "UNKNOWN"))
	})
	_begin_attempt()
	_play_sfx("click")

func _on_next_level_pressed() -> void:
	if not _has_next_level():
		return
	_load_current_level(current_level_index + 1)
	_play_sfx("click")

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
	var class_code: String = _classify_profile(tuning, metrics)
	_set_option_card_selected(class_code)
	metrics = _apply_preview_override(class_code, metrics)

	var total_price: int = int(metrics.get("total_price", 0))
	var risk_score: int = int(metrics.get("risk_score", 0))
	var budget: int = int(stage_b_data.get("budget", 0))

	snapshot_b["selected_option_id"] = class_code
	snapshot_b["total_price"] = total_price
	snapshot_b["preview_metrics"] = metrics.duplicate(true)

	used_budget_value.text = "%d$" % total_price
	budget_bar.max_value = max(1.0, float(budget))
	budget_bar.value = float(total_price)
	risk_bar.value = float(risk_score)
	risk_value.text = _risk_label(risk_score)
	risk_value.modulate = _risk_color(risk_score)

	preview_bottleneck.text = str(metrics.get("bottleneck", "OK"))
	preview_bottleneck.modulate = _bottleneck_color(str(metrics.get("bottleneck", "OK")))
	preview_fps_value.text = str(int(metrics.get("fps", 0)))
	preview_fps_bar.value = float(int(metrics.get("fps", 0)))
	preview_cpu_value.text = "%d%%" % int(metrics.get("cpu_load", 0))
	preview_cpu_bar.value = float(int(metrics.get("cpu_load", 0)))
	preview_ram_value.text = "%d%%" % int(metrics.get("ram_usage", 0))
	preview_ram_bar.value = float(int(metrics.get("ram_usage", 0)))

	if not bool(snapshot_b.get("benchmark_ran", false)):
		status_label.text = _tr("resus.b.status.profile_ready", "ПРОФИЛЬ ГОТОВ | использовано {used}$ / {budget}$", {"used": total_price, "budget": budget})
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

	var risk_score: int = 20
	if total_price > budget:
		risk_score = 95
	elif cpu_id == "HIGH" and ram_id == "LOW":
		risk_score = 78
	elif perf_score <= int((stage_b_data.get("classifier_thresholds", {}) as Dictionary).get("lowpower_perf_max", 4)):
		risk_score = 68

	var fps: int = clampi(18 + cpu_perf * 12 + ram_perf * 9 + gpu_perf * 12 - int(float(max(0, total_price - budget)) / 20.0), 8, 100)
	var cpu_load: int = clampi(96 - cpu_perf * 14 + (12 if ram_perf <= 1 else 0), 20, 99)
	var ram_usage: int = clampi(88 - ram_perf * 15 + (8 if gpu_perf >= 2 else 0), 16, 99)
	var bottleneck: String = "OK"

	if total_price > budget:
		bottleneck = "BUDGET"
	elif ram_perf <= 1 and cpu_perf >= 3:
		bottleneck = "RAM"
	elif gpu_perf <= 0:
		bottleneck = "GPU"
	elif cpu_perf <= 1 and ram_perf >= 2 and gpu_perf >= 2:
		bottleneck = "CPU"

	return {
		"total_price": total_price,
		"perf_score": perf_score,
		"risk_score": risk_score,
		"fps": fps,
		"cpu_load": cpu_load,
		"ram_usage": ram_usage,
		"bottleneck": bottleneck
	}

func _apply_preview_override(class_code: String, metrics: Dictionary) -> Dictionary:
	var out: Dictionary = metrics.duplicate(true)
	var override_profile: Dictionary = _preview_metrics_for_option(class_code)
	if override_profile.is_empty():
		return out

	for key in ["fps", "cpu_load", "ram_usage", "total_price", "bottleneck"]:
		if override_profile.has(key):
			out[key] = override_profile.get(key)

	var budget: int = int(stage_b_data.get("budget", 0))
	var total_price: int = int(out.get("total_price", 0))
	out["risk_score"] = int(out.get("risk_score", 20))
	if total_price > budget:
		out["risk_score"] = 95
	return out

func _preview_metrics_for_option(option_id: String) -> Dictionary:
	var option_data: Dictionary = _option_data_by_id(option_id)
	var option_preview: Dictionary = option_data.get("preview_metrics", {}) as Dictionary
	if not option_preview.is_empty():
		return option_preview
	var preview_profiles: Dictionary = stage_b_data.get("preview_profiles", {}) as Dictionary
	return preview_profiles.get(option_id, {}) as Dictionary

func _classify_current_profile() -> String:
	var tuning: Dictionary = snapshot_b.get("tuning", {}) as Dictionary
	var metrics: Dictionary = snapshot_b.get("preview_metrics", {}) as Dictionary
	if metrics.is_empty():
		metrics = _calculate_metrics(tuning)
	return _classify_profile(tuning, metrics)

func _classify_profile(tuning: Dictionary, metrics: Dictionary) -> String:
	var total_price: int = int(metrics.get("total_price", 0))
	var perf_score: int = int(metrics.get("perf_score", 0))
	var budget: int = int(stage_b_data.get("budget", 0))
	var thresholds: Dictionary = stage_b_data.get("classifier_thresholds", {}) as Dictionary

	if total_price > budget:
		return "OVERBUDGET"
	if str(tuning.get("cpu", "")) == str(thresholds.get("bottleneck_cpu", "HIGH")) and str(tuning.get("ram", "")) == str(thresholds.get("bottleneck_ram", "LOW")):
		return "BOTTLENECK"
	if perf_score <= int(thresholds.get("lowpower_perf_max", 4)):
		return "LOWPOWER"
	return "OPTIMAL"

func _benchmark_lines(class_code: String) -> Array[String]:
	var outputs: Dictionary = stage_b_data.get("benchmark_lines", stage_b_data.get("benchmark_outputs", {})) as Dictionary
	var lines: Array[String] = _to_string_array(outputs.get(class_code, []))
	if lines.is_empty():
		lines.append(_tr("resus.b.terminal.result_fallback", "[RESULT] {code}", {"code": class_code}))
	return lines

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

func _bottleneck_color(code: String) -> Color:
	if code == "OK":
		return COLOR_OK
	if code == "RAM" or code == "CPU" or code == "GPU":
		return COLOR_WARN
	return COLOR_ERR

func _register_trial(result: Dictionary) -> void:
	var elapsed_ms: int = Time.get_ticks_msec() - stage_started_ms
	var tuning: Dictionary = snapshot_b.get("tuning", {}) as Dictionary
	var class_code: String = str(snapshot_b.get("classified_as", "UNKNOWN"))
	var payload: Dictionary = {
		"quest_id": "CASE_01_DIGITAL_RESUS",
		"stage": "B",
		"format": "SINGLE_CHOICE_CONTEXT",
		"level_id": str(stage_b_data.get("id", "CASE01_B_01")),
		"level_index": current_level_index,
		"match_key": "CASE01_B_%d_%d" % [current_level_index, attempt_index],
		"context": str(stage_b_data.get("context", "")),
		"budget": int(stage_b_data.get("budget", 0)),
		"selected_option_id": class_code,
		"classified_as": class_code,
		"tuning_state": tuning.duplicate(true),
		"preview_metrics": (snapshot_b.get("preview_metrics", {}) as Dictionary).duplicate(true),
		"total_price": int(snapshot_b.get("total_price", 0)),
		"selection_count": tune_change_count,
		"time_to_first_select_ms": max(-1, time_to_first_action_ms),
		"elapsed_ms": elapsed_ms,
		"points": int(result.get("points", 0)),
		"max_points": int(result.get("max_points", 2)),
		"is_correct": bool(result.get("is_correct", false)),
		"is_fit": bool(result.get("is_fit", false)),
		"stability_delta": int(result.get("stability_delta", 0)),
		"verdict_code": str(result.get("verdict_code", "WRONG")),
		"error_code": str(result.get("error_code", "UNKNOWN")),
		"diagnostic_headline": str(result.get("diagnostic_headline", "")),
		"diagnostic_details": (result.get("diagnostic_details", []) as Array).duplicate(),
		"benchmark_done": bool(snapshot_b.get("benchmark_ran", false)),
		"benchmark_ran": bool(snapshot_b.get("benchmark_ran", false)),
		"trace": trace.duplicate(true)
	}
	GlobalMetrics.register_trial(payload)

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
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

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
	if options_list == null:
		return
	for child in options_list.get_children():
		child.queue_free()
	_option_cards_by_id.clear()

	var options: Array = stage_b_data.get("options", []) as Array
	for option_v in options:
		if typeof(option_v) != TYPE_DICTIONARY:
			continue
		var option_data: Dictionary = option_v as Dictionary
		var option_id: String = str(option_data.get("option_id", "")).strip_edges()
		if option_id == "":
			continue

		var btn: Button = Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0.0, 62.0)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.text = "%s | %s$ | %s" % [
			str(option_data.get("title", option_id)),
			str(option_data.get("total_price", 0)),
			option_id
		]
		btn.pressed.connect(_on_option_card_pressed.bind(option_id))
		options_list.add_child(btn)
		_option_cards_by_id[option_id] = btn

func _on_option_card_pressed(option_id: String) -> void:
	if input_locked:
		return
	var option_data: Dictionary = _option_data_by_id(option_id)
	if option_data.is_empty():
		return
	var tuning: Dictionary = _tuning_from_option(option_data)
	_set_tuning(tuning, true)

func _option_data_by_id(option_id: String) -> Dictionary:
	var options: Array = stage_b_data.get("options", []) as Array
	for option_v in options:
		if typeof(option_v) != TYPE_DICTIONARY:
			continue
		var option_data: Dictionary = option_v as Dictionary
		if str(option_data.get("option_id", "")) == option_id:
			return option_data
	return {}

func _tuning_from_option(option_data: Dictionary) -> Dictionary:
	var tuning: Dictionary = {"cpu": "LOW", "ram": "LOW", "gpu": "NONE"}
	var parts: Array = option_data.get("parts", []) as Array
	for part_v in parts:
		if typeof(part_v) != TYPE_DICTIONARY:
			continue
		var part: Dictionary = part_v as Dictionary
		var k: String = str(part.get("k", "")).to_upper()
		var v: String = str(part.get("v", "")).to_upper()
		match k:
			"CPU":
				tuning["cpu"] = v
			"RAM":
				tuning["ram"] = v
			"GPU":
				tuning["gpu"] = v
	return tuning

func _set_option_card_selected(option_id: String) -> void:
	for id_v in _option_cards_by_id.keys():
		var id: String = str(id_v)
		var btn_v: Variant = _option_cards_by_id.get(id, null)
		if not (btn_v is Button):
			continue
		var btn: Button = btn_v as Button
		var selected: bool = id == option_id
		btn.modulate = Color(1.08, 1.08, 1.08, 1.0) if selected else Color(1.0, 1.0, 1.0, 1.0)

func _ensure_scroll_layout() -> void:
	if _content_scroll != null and is_instance_valid(_content_scroll):
		return

	_content_scroll = ScrollContainer.new()
	_content_scroll.name = "КонтентПрокрутка"
	_content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	_content_vbox = VBoxContainer.new()
	_content_vbox.name = "КонтентВБокс"
	_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_vbox.add_theme_constant_override("separation", 10)
	_content_scroll.add_child(_content_vbox)

	var move_nodes: Array[Node] = []
	for child in main_vbox.get_children():
		if child == header or child == bottom_bar:
			continue
		move_nodes.append(child)

	for node in move_nodes:
		node.reparent(_content_vbox)

	main_vbox.add_child(_content_scroll)
	var bottom_index: int = main_vbox.get_children().find(bottom_bar)
	if bottom_index >= 0:
		main_vbox.move_child(_content_scroll, bottom_index)

func _setup_collapsible_context() -> void:
	if budget_row == null or _context_toggle_button != null:
		_apply_context_collapse_state()
		return

	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	budget_row.add_child(spacer)

	_context_toggle_button = Button.new()
	_context_toggle_button.name = "КонтекстToggleButton"
	_context_toggle_button.text = "?"
	_context_toggle_button.custom_minimum_size = Vector2(40.0, 34.0)
	_context_toggle_button.pressed.connect(_on_context_toggle_pressed)
	budget_row.add_child(_context_toggle_button)
	_apply_context_collapse_state()

func _on_context_toggle_pressed() -> void:
	_context_collapsed = not _context_collapsed
	_apply_context_collapse_state()

func _apply_context_collapse_state() -> void:
	if context_label == null:
		return
	context_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	context_label.max_lines_visible = 2 if _context_collapsed else 0
	if _context_toggle_button != null:
		_context_toggle_button.text = "?" if _context_collapsed else "x"

func _on_viewport_size_changed() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var is_landscape: bool = viewport_size.x >= viewport_size.y
	var phone_landscape: bool = is_landscape and viewport_size.y <= PHONE_LANDSCAPE_MAX_HEIGHT
	var phone_portrait: bool = (not is_landscape) and viewport_size.x <= PHONE_PORTRAIT_MAX_WIDTH
	var compact: bool = phone_landscape or phone_portrait

	_apply_safe_area_padding(compact)
	main_vbox.add_theme_constant_override("separation", 8 if compact else 10)
	if _content_vbox != null:
		_content_vbox.add_theme_constant_override("separation", 8 if compact else 10)
	header.add_theme_constant_override("separation", 8 if compact else 10)
	bottom_bar.add_theme_constant_override("separation", 8 if compact else 10)
	tune_grid.columns = 1 if phone_portrait else 2

	btn_back.custom_minimum_size = Vector2(56.0 if compact else 72.0, 56.0 if compact else 72.0)
	stability_bar.custom_minimum_size.x = 160.0 if compact else 220.0
	status_label.custom_minimum_size.y = 60.0 if compact else 72.0
	btn_benchmark.custom_minimum_size = Vector2(0.0 if compact else 190.0, 60.0 if compact else 72.0)
	btn_reset.custom_minimum_size = Vector2(0.0 if compact else 150.0, 60.0 if compact else 72.0)
	btn_confirm.custom_minimum_size = Vector2(0.0 if compact else 160.0, 60.0 if compact else 72.0)
	btn_next_level.custom_minimum_size = Vector2(0.0 if compact else 170.0, 60.0 if compact else 72.0)
	for node in [btn_benchmark, btn_reset, btn_confirm, btn_next_level]:
		node.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_set_bottom_mobile_mode(phone_portrait)

func _set_bottom_mobile_mode(use_mobile: bool) -> void:
	var mobile_layout: VBoxContainer = _ensure_bottom_mobile_layout()
	if use_mobile:
		if bottom_bar.visible:
			for node in [status_label, btn_benchmark, btn_reset, btn_confirm, btn_next_level]:
				if node.get_parent() != mobile_layout:
					node.reparent(mobile_layout)
		bottom_bar.visible = false
		mobile_layout.visible = true
	else:
		if not bottom_bar.visible:
			for node in [status_label, btn_benchmark, btn_reset, btn_confirm, btn_next_level]:
				if node.get_parent() != bottom_bar:
					node.reparent(bottom_bar)
		mobile_layout.visible = false
		bottom_bar.visible = true

func _ensure_bottom_mobile_layout() -> VBoxContainer:
	if _bottom_mobile_layout != null and is_instance_valid(_bottom_mobile_layout):
		return _bottom_mobile_layout
	_bottom_mobile_layout = VBoxContainer.new()
	_bottom_mobile_layout.name = "НижнийБарМобильныйМакет"
	_bottom_mobile_layout.visible = false
	_bottom_mobile_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bottom_mobile_layout.add_theme_constant_override("separation", 8)
	main_vbox.add_child(_bottom_mobile_layout)
	main_vbox.move_child(_bottom_mobile_layout, main_vbox.get_children().find(bottom_bar) + 1)
	return _bottom_mobile_layout

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
