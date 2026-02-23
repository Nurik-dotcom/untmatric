extends Control

const LEVELS_PATH: String = "res://data/clues_levels.json"
const ResusData = preload("res://scripts/case_01/ResusData.gd")
const ResusScoring = preload("res://scripts/case_01/ResusScoring.gd")

const COLOR_OK: Color = Color(0.9, 0.93, 0.98, 1.0)
const COLOR_WARN: Color = Color(0.98, 0.8, 0.52, 1.0)
const COLOR_ERR: Color = Color(0.95, 0.36, 0.38, 1.0)

const CPU_ORDER: Array[String] = ["LOW", "MID", "HIGH"]
const RAM_ORDER: Array[String] = ["LOW", "GOOD", "TOP"]
const GPU_ORDER: Array[String] = ["NONE", "MID", "TOP"]

var stage_b_data: Dictionary = {}
var trace: Array = []

var stage_started_ms: int = 0
var time_to_first_action_ms: int = -1
var tune_change_count: int = 0
var attempt_index: int = 0
var input_locked: bool = false

var snapshot_b: Dictionary = {
	"tuning": {"cpu": "MID", "ram": "GOOD", "gpu": "NONE"},
	"total_price": 0,
	"classified_as": "UNKNOWN",
	"benchmark_ran": false
}

@onready var noir_overlay: Node = $NoirOverlay
@onready var title_label: Label = $SafeArea/MainVBox/Header/TitleLabel
@onready var stage_label: Label = $SafeArea/MainVBox/Header/StageLabel
@onready var stability_bar: ProgressBar = $SafeArea/MainVBox/Header/StabilityBar
@onready var btn_back: Button = $SafeArea/MainVBox/Header/BtnBack

@onready var context_label: Label = $SafeArea/MainVBox/ContextCard/ContextVBox/ContextLabel
@onready var budget_value: Label = $SafeArea/MainVBox/ContextCard/ContextVBox/BudgetRow/BudgetValue

@onready var cpu_level: OptionButton = $SafeArea/MainVBox/BiosCard/BiosVBox/TuneGrid/CpuLevel
@onready var ram_level: OptionButton = $SafeArea/MainVBox/BiosCard/BiosVBox/TuneGrid/RamLevel
@onready var gpu_level: OptionButton = $SafeArea/MainVBox/BiosCard/BiosVBox/TuneGrid/GpuLevel
@onready var used_budget_value: Label = $SafeArea/MainVBox/BiosCard/BiosVBox/TuneGrid/UsedBudgetValue
@onready var budget_bar: ProgressBar = $SafeArea/MainVBox/BiosCard/BiosVBox/BudgetBar
@onready var risk_value: Label = $SafeArea/MainVBox/BiosCard/BiosVBox/RiskRow/RiskValue
@onready var risk_bar: ProgressBar = $SafeArea/MainVBox/BiosCard/BiosVBox/RiskBar

@onready var terminal_output: RichTextLabel = $SafeArea/MainVBox/TerminalCard/TerminalVBox/TerminalOutput

@onready var status_label: Label = $SafeArea/MainVBox/BottomBar/StatusLabel
@onready var btn_benchmark: Button = $SafeArea/MainVBox/BottomBar/BtnBenchmark
@onready var btn_reset: Button = $SafeArea/MainVBox/BottomBar/BtnReset
@onready var btn_confirm: Button = $SafeArea/MainVBox/BottomBar/BtnConfirm

func _ready() -> void:
	if not GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.connect(_on_stability_changed)

	btn_back.pressed.connect(_on_back_pressed)
	btn_benchmark.pressed.connect(_on_benchmark_pressed)
	btn_reset.pressed.connect(_on_reset_pressed)
	btn_confirm.pressed.connect(_on_confirm_pressed)
	cpu_level.item_selected.connect(_on_cpu_changed)
	ram_level.item_selected.connect(_on_ram_changed)
	gpu_level.item_selected.connect(_on_gpu_changed)

	stage_b_data = ResusData.load_stage_b(LEVELS_PATH)
	if stage_b_data.is_empty():
		_show_error("Failed to load Case 01 stage B data")
		return

	_setup_ui()
	_begin_attempt()

func _setup_ui() -> void:
	title_label.text = "Case 01: Digital Reanimation"
	stage_label.text = "STAGE B"
	context_label.text = str(stage_b_data.get("context", "Tune profile and run benchmark"))
	budget_value.text = "%d$" % int(stage_b_data.get("budget", 0))
	btn_reset.text = "RESET"
	btn_confirm.text = "CONFIRM"
	btn_benchmark.text = "RUN BENCHMARK"
	_populate_levels()
	_update_stability_ui()

func _begin_attempt() -> void:
	trace.clear()
	tune_change_count = 0
	time_to_first_action_ms = -1
	input_locked = false
	stage_started_ms = Time.get_ticks_msec()
	btn_benchmark.disabled = false
	btn_confirm.disabled = true
	_set_tuning({"cpu": "MID", "ram": "GOOD", "gpu": "NONE"}, false)
	snapshot_b["classified_as"] = "UNKNOWN"
	snapshot_b["benchmark_ran"] = false
	terminal_output.text = "[READY] Select tuning profile and run benchmark."
	status_label.text = "READY"
	status_label.modulate = COLOR_WARN

func _populate_levels() -> void:
	_fill_option_button(cpu_level, CPU_ORDER)
	_fill_option_button(ram_level, RAM_ORDER)
	_fill_option_button(gpu_level, GPU_ORDER)

func _fill_option_button(button: OptionButton, ordered_ids: Array[String]) -> void:
	button.clear()
	for id in ordered_ids:
		button.add_item(id)

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
	btn_confirm.disabled = true
	_recompute_preview()

	_log_event("TUNE_CHANGED", {
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
	snapshot_b["classified_as"] = class_code
	snapshot_b["benchmark_ran"] = true
	btn_confirm.disabled = false

	var lines: Array[String] = _benchmark_lines(class_code)
	terminal_output.text = ""
	for line in lines:
		terminal_output.text += line + "\n"
	terminal_output.scroll_to_line(max(0, terminal_output.get_line_count() - 1))

	status_label.text = "RESULT: %s" % class_code
	status_label.modulate = COLOR_OK if class_code == "OPTIMAL" else COLOR_WARN
	_log_event("BENCHMARK_RUN", {
		"class": class_code,
		"result_lines_count": lines.size()
	})
	_play_sfx("relay")

func _on_confirm_pressed() -> void:
	if input_locked:
		return

	var class_code: String = str(snapshot_b.get("classified_as", ""))
	_log_event("CONFIRM_PRESSED", {"class": class_code})

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

	if bool(result.get("is_correct", false)):
		_play_sfx("relay")
	else:
		_play_sfx("error")

func _show_result(result: Dictionary) -> void:
	var headline: String = str(result.get("diagnostic_headline", "Classification complete"))
	var details: Array = result.get("diagnostic_details", []) as Array
	var report_lines: Array[String] = [
		headline,
		"",
		"CLASS: %s" % str(snapshot_b.get("classified_as", "UNKNOWN")),
		"USED: %d$ / %d$" % [int(snapshot_b.get("total_price", 0)), int(stage_b_data.get("budget", 0))],
		""
	]
	for detail_v in details:
		report_lines.append("- %s" % str(detail_v))
	terminal_output.text = "\n".join(report_lines)

	status_label.text = "LOCKED | %s" % str(result.get("verdict_code", "WRONG"))
	status_label.modulate = COLOR_OK if bool(result.get("is_correct", false)) else COLOR_ERR

func _on_reset_pressed() -> void:
	_log_event("RESET_PRESSED", {
		"classified_as": str(snapshot_b.get("classified_as", "UNKNOWN"))
	})
	cpu_level.disabled = false
	ram_level.disabled = false
	gpu_level.disabled = false
	_begin_attempt()
	_play_sfx("click")

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
	var total_price: int = int(metrics.get("total_price", 0))
	var risk_score: int = int(metrics.get("risk_score", 0))
	var budget: int = int(stage_b_data.get("budget", 0))

	snapshot_b["total_price"] = total_price
	used_budget_value.text = "%d$" % total_price
	budget_bar.max_value = max(1.0, float(budget))
	budget_bar.value = float(total_price)
	risk_bar.value = float(risk_score)
	risk_value.text = _risk_label(risk_score)
	risk_value.modulate = _risk_color(risk_score)

	status_label.text = "PROFILE READY | used %d$ / %d$" % [total_price, budget]
	status_label.modulate = COLOR_WARN

func _calculate_metrics(tuning: Dictionary) -> Dictionary:
	var tuning_model: Dictionary = stage_b_data.get("tuning_model", {}) as Dictionary
	var cpu_id: String = str(tuning.get("cpu", "MID"))
	var ram_id: String = str(tuning.get("ram", "GOOD"))
	var gpu_id: String = str(tuning.get("gpu", "NONE"))

	var cpu_data: Dictionary = (tuning_model.get("cpu", {}) as Dictionary).get(cpu_id, {}) as Dictionary
	var ram_data: Dictionary = (tuning_model.get("ram", {}) as Dictionary).get(ram_id, {}) as Dictionary
	var gpu_data: Dictionary = (tuning_model.get("gpu", {}) as Dictionary).get(gpu_id, {}) as Dictionary

	var total_price: int = int(cpu_data.get("price", 0)) + int(ram_data.get("price", 0)) + int(gpu_data.get("price", 0))
	var perf_score: int = int(cpu_data.get("perf", 0)) + int(ram_data.get("perf", 0)) + int(gpu_data.get("perf", 0))

	var risk_score: int = 20
	if total_price > int(stage_b_data.get("budget", 0)):
		risk_score = 95
	elif cpu_id == "HIGH" and ram_id == "LOW":
		risk_score = 78
	elif perf_score <= int((stage_b_data.get("classifier_thresholds", {}) as Dictionary).get("lowpower_perf_max", 4)):
		risk_score = 68

	return {
		"total_price": total_price,
		"perf_score": perf_score,
		"risk_score": risk_score
	}

func _classify_current_profile() -> String:
	var tuning: Dictionary = snapshot_b.get("tuning", {}) as Dictionary
	var metrics: Dictionary = _calculate_metrics(tuning)
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
	var outputs: Dictionary = stage_b_data.get("benchmark_outputs", {}) as Dictionary
	var lines: Array[String] = _to_string_array(outputs.get(class_code, []))
	if lines.is_empty():
		lines.append("[RESULT] %s" % class_code)
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

func _register_trial(result: Dictionary) -> void:
	var elapsed_ms: int = Time.get_ticks_msec() - stage_started_ms
	var tuning: Dictionary = snapshot_b.get("tuning", {}) as Dictionary
	var class_code: String = str(snapshot_b.get("classified_as", "UNKNOWN"))
	var payload: Dictionary = {
		"quest_id": "CASE_01_DIGITAL_RESUS",
		"stage": "B",
		"format": "SINGLE_CHOICE_CONTEXT",
		"level_id": str(stage_b_data.get("id", "CASE01_B_01")),
		"match_key": "CASE01_B_%d" % attempt_index,
		"context": str(stage_b_data.get("context", "")),
		"budget": int(stage_b_data.get("budget", 0)),
		"selected_option_id": class_code,
		"classified_as": class_code,
		"tuning_state": tuning.duplicate(true),
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
		"benchmark_ran": bool(snapshot_b.get("benchmark_ran", false)),
		"trace": trace.duplicate(true)
	}
	GlobalMetrics.register_trial(payload)

func _mark_first_action() -> void:
	if time_to_first_action_ms < 0:
		time_to_first_action_ms = Time.get_ticks_msec() - stage_started_ms

func _log_event(name: String, data: Dictionary = {}) -> void:
	trace.append({
		"t_ms": Time.get_ticks_msec() - stage_started_ms,
		"event": name,
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
