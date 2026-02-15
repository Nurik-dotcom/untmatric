extends Control

enum Phase {
	SETUP,
	PLAN,
	EXEC,
	RESULT
}

enum Decision {
	NONE,
	RISK,
	ABORT
}

enum Outcome {
	NONE,
	SUCCESS_SEND,
	INTERCEPTED,
	SAFE_ABORT,
	MISSED_WINDOW
}

const EPS: float = 0.05
const MIN_ESTIMATE: float = 0.0
const MAX_ESTIMATE: float = 600.0
const SAMPLE_SLOTS: int = 7

const POOL_MB_NORMAL := [1.0, 2.0, 4.0, 5.0, 8.0, 10.0, 12.0, 16.0, 20.0, 25.0, 40.0]
const POOL_GB_NORMAL := [0.5, 1.0, 1.5, 2.0]
const POOL_SPEED_INT := [1.0, 2.0, 4.0, 5.0, 8.0, 10.0, 16.0, 20.0, 25.0]
const POOL_SPEED_FRAC := [1.5, 2.5, 7.5, 12.5]

const COLOR_SAMPLE_IDLE := Color(0.18, 0.18, 0.18, 1.0)
const COLOR_SAMPLE_SUCCESS := Color(0.20, 0.90, 0.30, 1.0)
const COLOR_SAMPLE_FAIL := Color(0.95, 0.25, 0.25, 1.0)
const COLOR_SAMPLE_WARN := Color(0.95, 0.75, 0.20, 1.0)

@onready var btn_back: Button = $SafeArea/MainVBox/Header/BtnBack
@onready var mode_label: Label = $SafeArea/MainVBox/Header/ModeLabel
@onready var stability_label: Label = $SafeArea/MainVBox/Header/StabilityLabel

@onready var file_label: Label = $SafeArea/MainVBox/TaskCard/TaskVBox/FileLabel
@onready var speed_label: Label = $SafeArea/MainVBox/TaskCard/TaskVBox/SpeedLabel
@onready var detect_label: Label = $SafeArea/MainVBox/TaskCard/TaskVBox/DetectLabel

@onready var detection_timer: ProgressBar = $SafeArea/MainVBox/MonitorCard/MonVBox/DetectBlock/DetectionTimer
@onready var detect_countdown: Label = $SafeArea/MainVBox/MonitorCard/MonVBox/DetectBlock/DetectCountdown
@onready var transfer_progress: ProgressBar = $SafeArea/MainVBox/MonitorCard/MonVBox/TransferBlock/TransferProgress
@onready var transfer_countdown: Label = $SafeArea/MainVBox/MonitorCard/MonVBox/TransferBlock/TransferCountdown

@onready var est_value: Label = $SafeArea/MainVBox/EstimateCard/EstVBox/EstValue
@onready var btn_minus_1: Button = $SafeArea/MainVBox/EstimateCard/EstVBox/EstBtns/BtnMinus1
@onready var btn_minus_01: Button = $SafeArea/MainVBox/EstimateCard/EstVBox/EstBtns/BtnMinus01
@onready var btn_plus_01: Button = $SafeArea/MainVBox/EstimateCard/EstVBox/EstBtns/BtnPlus01
@onready var btn_plus_1: Button = $SafeArea/MainVBox/EstimateCard/EstVBox/EstBtns/BtnPlus1
@onready var btn_check: Button = $SafeArea/MainVBox/EstimateCard/EstVBox/BtnCheck

@onready var sample_strip: HBoxContainer = $SafeArea/MainVBox/Bottom/SampleStrip
@onready var btn_units: Button = $SafeArea/MainVBox/Bottom/ActionsRow/BtnUnits
@onready var btn_risk: Button = $SafeArea/MainVBox/Bottom/ActionsRow/BtnRisk
@onready var btn_abort: Button = $SafeArea/MainVBox/Bottom/ActionsRow/BtnAbort
@onready var btn_next: Button = $SafeArea/MainVBox/Bottom/ActionsRow/BtnNext
@onready var status_label: Label = $SafeArea/MainVBox/Bottom/StatusLabel

@onready var alarm_flash: ColorRect = $AlarmFlash

var phase: Phase = Phase.SETUP
var decision: Decision = Decision.NONE
var outcome: Outcome = Outcome.NONE

var file_size_value: float = 0.0
var file_size_unit: String = "МБ"
var speed_mbit: float = 0.0
var t_detect: float = 0.0
var t_true: float = 0.0
var pool_type: String = "NORMAL"
var anchor_type: String = "none"

var t_est: float = 0.0
var used_units: bool = false

var detection_elapsed: float = 0.0
var transfer_elapsed: float = 0.0
var transfer_started: bool = false

var start_ms: int = 0
var first_action_ms: int = -1
var check_ms: int = -1
var decision_ms: int = -1

var sample_cursor: int = 0
var anchor_countdown: int = 0
var sample_cells: Array[ColorRect] = []

func _ready() -> void:
	randomize()
	_connect_signals()
	_collect_sample_cells()
	_reset_sample_strip()
	mode_label.text = "РЕЖИМ: C"
	anchor_countdown = randi_range(7, 10)

	if not GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.connect(_on_stability_changed)
	_on_stability_changed(GlobalMetrics.stability, 0.0)

	_start_new_trial()

func _process(delta: float) -> void:
	if phase != Phase.EXEC:
		return

	detection_elapsed += delta
	if decision == Decision.RISK and transfer_started:
		transfer_elapsed += delta

	_update_exec_ui()

	if decision == Decision.RISK:
		if transfer_elapsed >= t_true and detection_elapsed <= t_detect + EPS:
			_finalize_result(Outcome.SUCCESS_SEND, "RISK")
			return
		if detection_elapsed >= t_detect and transfer_elapsed < t_true - EPS:
			_play_alarm_flash()
			_finalize_result(Outcome.INTERCEPTED, "RISK")
			return
	else:
		if detection_elapsed >= t_detect:
			if decision_ms < 0:
				decision_ms = Time.get_ticks_msec()
			_play_alarm_flash()
			_finalize_result(Outcome.INTERCEPTED, "NONE")

func _connect_signals() -> void:
	btn_back.pressed.connect(_on_back_pressed)
	btn_minus_1.pressed.connect(_on_minus_1_pressed)
	btn_minus_01.pressed.connect(_on_minus_01_pressed)
	btn_plus_01.pressed.connect(_on_plus_01_pressed)
	btn_plus_1.pressed.connect(_on_plus_1_pressed)
	btn_check.pressed.connect(_on_check_pressed)
	btn_risk.pressed.connect(_on_risk_pressed)
	btn_abort.pressed.connect(_on_abort_pressed)
	btn_units.pressed.connect(_on_units_pressed)
	btn_next.pressed.connect(_on_next_pressed)

func _collect_sample_cells() -> void:
	sample_cells.clear()
	for child_var in sample_strip.get_children():
		var child_node: Node = child_var
		var bg: ColorRect = child_node.get_node_or_null("BG") as ColorRect
		if bg != null:
			sample_cells.append(bg)

func _reset_sample_strip() -> void:
	for cell in sample_cells:
		cell.color = COLOR_SAMPLE_IDLE

func _start_new_trial() -> void:
	phase = Phase.SETUP
	decision = Decision.NONE
	outcome = Outcome.NONE
	transfer_started = false
	used_units = false

	detection_elapsed = 0.0
	transfer_elapsed = 0.0
	t_est = 0.0

	start_ms = Time.get_ticks_msec()
	first_action_ms = -1
	check_ms = -1
	decision_ms = -1

	_generate_trial()
	_refresh_task_labels()
	_refresh_estimate_label()
	_reset_progress()
	_set_phase_plan_ui()
	phase = Phase.PLAN

func _generate_trial() -> void:
	var generated: Dictionary = {}
	if anchor_countdown <= 0:
		pool_type = "ANCHOR"
		var anchor_pick: int = randi() % 3
		if anchor_pick == 0:
			generated = _generate_anchor_forgot_x8()
		elif anchor_pick == 1:
			generated = _generate_anchor_boundary()
		else:
			generated = _generate_anchor_gb_1024()
		if generated.is_empty():
			generated = _generate_normal_trial()
			pool_type = "NORMAL"
		anchor_countdown = randi_range(7, 10)
	else:
		pool_type = "NORMAL"
		generated = _generate_normal_trial()
		anchor_countdown -= 1

	file_size_value = float(generated["size_value"])
	file_size_unit = str(generated["size_unit"])
	speed_mbit = float(generated["speed_mbit"])
	t_detect = float(generated["t_detect"])
	t_true = float(generated["t_true"])
	anchor_type = str(generated["anchor_type"])

func _generate_normal_trial() -> Dictionary:
	for _i in range(400):
		var use_gb: bool = randf() < 0.10
		var size_value: float = 0.0
		var size_unit: String = "МБ"
		if use_gb:
			size_value = POOL_GB_NORMAL[randi() % POOL_GB_NORMAL.size()]
			size_unit = "ГБ"
		else:
			size_value = POOL_MB_NORMAL[randi() % POOL_MB_NORMAL.size()]
			size_unit = "МБ"

		var speed: float = _pick_speed()
		var true_time: float = _compute_true_time(size_value, size_unit, speed)
		if true_time < 2.0 or true_time > 20.0:
			continue

		var detect_time: float = clampf(true_time + randf_range(-3.0, 3.0), 0.8, 24.0)
		if absf(true_time - detect_time) < 0.2:
			detect_time = clampf(detect_time + 0.4, 0.8, 24.0)

		return {
			"size_value": size_value,
			"size_unit": size_unit,
			"speed_mbit": speed,
			"t_detect": detect_time,
			"t_true": true_time,
			"anchor_type": "none"
		}

	return {
		"size_value": 10.0,
		"size_unit": "МБ",
		"speed_mbit": 16.0,
		"t_detect": 6.0,
		"t_true": 5.0,
		"anchor_type": "none"
	}

func _generate_anchor_forgot_x8() -> Dictionary:
	for _i in range(500):
		var size_value: float = POOL_MB_NORMAL[randi() % POOL_MB_NORMAL.size()]
		var speed: float = _pick_speed()
		var true_time: float = _compute_true_time(size_value, "МБ", speed)
		if true_time < 4.0 or true_time > 20.0:
			continue

		var fake_time: float = size_value / speed
		if fake_time >= true_time - 0.2:
			continue

		var detect_low: float = maxf(fake_time + 0.2, 0.6)
		var detect_high: float = true_time - 0.2
		if detect_high <= detect_low:
			continue

		return {
			"size_value": size_value,
			"size_unit": "МБ",
			"speed_mbit": speed,
			"t_detect": randf_range(detect_low, detect_high),
			"t_true": true_time,
			"anchor_type": "forgot_x8"
		}

	return {}

func _generate_anchor_gb_1024() -> Dictionary:
	for _i in range(500):
		var size_value: float = POOL_GB_NORMAL[randi() % POOL_GB_NORMAL.size()]
		var speed: float = _pick_speed()
		var true_time: float = _compute_true_time(size_value, "ГБ", speed)
		if true_time < 6.0 or true_time > 20.0:
			continue

		var fake_time: float = (size_value * 8.0) / speed
		var detect_low: float = fake_time + 0.1
		var detect_high: float = true_time - 0.3
		if detect_high <= detect_low:
			continue

		return {
			"size_value": size_value,
			"size_unit": "ГБ",
			"speed_mbit": speed,
			"t_detect": randf_range(detect_low, detect_high),
			"t_true": true_time,
			"anchor_type": "forgot_x1024"
		}

	return {}

func _generate_anchor_boundary() -> Dictionary:
	for _i in range(400):
		var use_gb: bool = randf() < 0.30
		var size_value: float = 0.0
		var size_unit: String = "МБ"
		if use_gb:
			size_value = POOL_GB_NORMAL[randi() % POOL_GB_NORMAL.size()]
			size_unit = "ГБ"
		else:
			size_value = POOL_MB_NORMAL[randi() % POOL_MB_NORMAL.size()]
			size_unit = "МБ"

		var speed: float = _pick_speed()
		var true_time: float = _compute_true_time(size_value, size_unit, speed)
		if true_time < 2.0 or true_time > 20.0:
			continue

		var detect_time: float = clampf(true_time + randf_range(-0.18, 0.18), 0.8, 24.0)
		if absf(true_time - detect_time) <= 0.2:
			return {
				"size_value": size_value,
				"size_unit": size_unit,
				"speed_mbit": speed,
				"t_detect": detect_time,
				"t_true": true_time,
				"anchor_type": "boundary"
			}

	return {}

func _pick_speed() -> float:
	if randf() < 0.30:
		return POOL_SPEED_FRAC[randi() % POOL_SPEED_FRAC.size()]
	return POOL_SPEED_INT[randi() % POOL_SPEED_INT.size()]

func _compute_true_time(size_value: float, size_unit: String, speed: float) -> float:
	var i_mbit: float = 0.0
	if size_unit == "ГБ":
		i_mbit = size_value * 1024.0 * 8.0
	else:
		i_mbit = size_value * 8.0
	return i_mbit / speed

func _refresh_task_labels() -> void:
	file_label.text = "ОБЪЁМ ПАКЕТА: %s %s" % [_format_num(file_size_value), file_size_unit]
	speed_label.text = "СКОРОСТЬ КАНАЛА: %s Мбит/с" % _format_num(speed_mbit)
	detect_label.text = "ДО ПЕЛЕНГАЦИИ: %s с" % _format_num(t_detect)
	detect_countdown.text = "%s с" % _format_num(t_detect)
	transfer_countdown.text = "—"

func _refresh_estimate_label() -> void:
	est_value.text = "%s с" % _format_num(t_est)

func _reset_progress() -> void:
	detection_timer.value = 0.0
	transfer_progress.value = 0.0

func _set_phase_plan_ui() -> void:
	btn_check.disabled = false
	btn_risk.disabled = true
	btn_abort.disabled = true
	btn_units.disabled = false
	btn_next.visible = false
	status_label.text = "СТАТУС: Сначала рассчитайте время и нажмите «ПРОВЕРИТЬ ПРОГНОЗ»."

func _set_phase_exec_ui() -> void:
	btn_check.disabled = true
	btn_risk.disabled = false
	btn_abort.disabled = false
	btn_units.disabled = false
	btn_next.visible = false
	status_label.text = "СТАТУС: Прогноз принят. Решайте: запуск или сброс."

func _set_phase_result_ui() -> void:
	btn_check.disabled = true
	btn_risk.disabled = true
	btn_abort.disabled = true
	btn_units.disabled = true
	btn_next.visible = true

func _register_first_action() -> void:
	if first_action_ms < 0:
		first_action_ms = Time.get_ticks_msec()

func _on_minus_1_pressed() -> void:
	_register_first_action()
	if phase != Phase.PLAN:
		return
	t_est = clampf(t_est - 1.0, MIN_ESTIMATE, MAX_ESTIMATE)
	_refresh_estimate_label()

func _on_minus_01_pressed() -> void:
	_register_first_action()
	if phase != Phase.PLAN:
		return
	t_est = clampf(t_est - 0.1, MIN_ESTIMATE, MAX_ESTIMATE)
	_refresh_estimate_label()

func _on_plus_01_pressed() -> void:
	_register_first_action()
	if phase != Phase.PLAN:
		return
	t_est = clampf(t_est + 0.1, MIN_ESTIMATE, MAX_ESTIMATE)
	_refresh_estimate_label()

func _on_plus_1_pressed() -> void:
	_register_first_action()
	if phase != Phase.PLAN:
		return
	t_est = clampf(t_est + 1.0, MIN_ESTIMATE, MAX_ESTIMATE)
	_refresh_estimate_label()

func _on_check_pressed() -> void:
	_register_first_action()
	if phase != Phase.PLAN:
		return
	check_ms = Time.get_ticks_msec()
	phase = Phase.EXEC
	decision = Decision.NONE
	detection_elapsed = 0.0
	transfer_elapsed = 0.0
	transfer_started = false
	_set_phase_exec_ui()
	_update_exec_ui()

func _on_risk_pressed() -> void:
	_register_first_action()
	if phase != Phase.EXEC:
		return
	if decision == Decision.RISK:
		return

	decision = Decision.RISK
	if decision_ms < 0:
		decision_ms = Time.get_ticks_msec()
	transfer_started = true
	status_label.text = "СТАТУС: Передача запущена. Держим канал."

func _on_abort_pressed() -> void:
	_register_first_action()
	if phase != Phase.EXEC:
		return
	decision = Decision.ABORT
	if decision_ms < 0:
		decision_ms = Time.get_ticks_msec()

	if t_true > t_detect + EPS:
		_finalize_result(Outcome.SAFE_ABORT, "ABORT")
	else:
		_finalize_result(Outcome.MISSED_WINDOW, "ABORT")

func _on_units_pressed() -> void:
	_register_first_action()
	if phase == Phase.RESULT:
		return
	used_units = true
	status_label.text = "СТАТУС: МБ→Мбит: ×8, ГБ→МБ: ×1024, t = I / v."

func _on_next_pressed() -> void:
	_start_new_trial()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _update_exec_ui() -> void:
	var detect_ratio: float = 0.0
	if t_detect > 0.0:
		detect_ratio = clampf(detection_elapsed / t_detect, 0.0, 1.0)
	detection_timer.value = detect_ratio * 100.0
	detect_countdown.text = "%s с" % _format_num(maxf(0.0, t_detect - detection_elapsed))

	if decision == Decision.RISK and t_true > 0.0:
		var transfer_ratio: float = clampf(transfer_elapsed / t_true, 0.0, 1.0)
		transfer_progress.value = transfer_ratio * 100.0
		transfer_countdown.text = "%s с" % _format_num(maxf(0.0, t_true - transfer_elapsed))
	else:
		transfer_progress.value = 0.0
		transfer_countdown.text = "ожидание"

func _finalize_result(result_outcome: Outcome, decision_label: String) -> void:
	if phase == Phase.RESULT:
		return

	phase = Phase.RESULT
	outcome = result_outcome
	_set_phase_result_ui()

	var is_success: bool = (outcome == Outcome.SUCCESS_SEND or outcome == Outcome.SAFE_ABORT)
	var color: Color = COLOR_SAMPLE_FAIL
	match outcome:
		Outcome.SUCCESS_SEND:
			status_label.text = "СТАТУС: УСПЕХ. Пакет ушел до пеленгации."
			color = COLOR_SAMPLE_SUCCESS
		Outcome.INTERCEPTED:
			status_label.text = "СТАТУС: ПРОВАЛ. Вас засекли."
			color = COLOR_SAMPLE_FAIL
		Outcome.SAFE_ABORT:
			status_label.text = "СТАТУС: ПРАВИЛЬНО. Отказ спас миссию."
			color = COLOR_SAMPLE_SUCCESS
		Outcome.MISSED_WINDOW:
			status_label.text = "СТАТУС: УПУЩЕНО. Вы могли успеть."
			color = COLOR_SAMPLE_WARN
		_:
			status_label.text = "СТАТУС: Завершено."
			color = COLOR_SAMPLE_FAIL

	_mark_sample(color)
	_send_trial_payload(is_success, decision_label)

func _mark_sample(color: Color) -> void:
	if sample_cells.is_empty():
		return
	sample_cells[sample_cursor].color = color
	sample_cursor = (sample_cursor + 1) % min(SAMPLE_SLOTS, sample_cells.size())

func _send_trial_payload(is_success: bool, decision_label: String) -> void:
	var now_ms: int = Time.get_ticks_msec()
	var elapsed_ms: int = now_ms - start_ms
	var t_first_ms: int = 0
	if first_action_ms >= 0:
		t_first_ms = first_action_ms - start_ms

	var t_check_ms: int = 0
	if check_ms >= 0:
		t_check_ms = check_ms - start_ms

	var t_decision_ms: int = elapsed_ms
	if decision_ms >= 0:
		t_decision_ms = decision_ms - start_ms

	var error_type: String = _classify_error_type(t_decision_ms)
	var outcome_text: String = _outcome_to_text(outcome)
	var match_key: String = _build_match_key()
	var valid_for_mastery: bool = (not used_units) and (outcome == Outcome.SUCCESS_SEND or outcome == Outcome.SAFE_ABORT)

	var payload: Dictionary = {
		"quest_id": "radio_intercept",
		"stage_id": "C",
		"match_key": match_key,
		"pool_type": pool_type,
		"anchor_type": anchor_type,
		"file_size_value": file_size_value,
		"file_size_unit": file_size_unit,
		"speed_mbit": speed_mbit,
		"T_detect": t_detect,
		"t_true": t_true,
		"t_est": t_est,
		"decision": decision_label,
		"used_units": used_units,
		"outcome": outcome_text,
		"error_type": error_type,
		"valid_for_diagnostics": true,
		"valid_for_mastery": valid_for_mastery,
		"is_correct": is_success,
		"is_fit": is_success,
		"elapsed_ms": elapsed_ms,
		"time_to_first_action_ms": t_first_ms,
		"time_to_check_ms": t_check_ms,
		"time_to_decision_ms": t_decision_ms
	}
	GlobalMetrics.register_trial(payload)

func _classify_error_type(time_to_decision_ms: int) -> String:
	if used_units:
		return "assisted"
	if t_true <= 0.0:
		return "arithmetic_error"

	var rel_current: float = absf(t_est - t_true) / t_true
	var rel_x8: float = absf((t_est * 8.0) - t_true) / t_true
	if rel_x8 < 0.15:
		return "forgot_x8"

	if file_size_unit == "ГБ":
		var rel_x1024: float = absf((t_est * 1024.0) - t_true) / t_true
		if rel_x1024 < 0.15:
			return "forgot_x1024"

	if rel_current > 0.25:
		return "arithmetic_error"
	if time_to_decision_ms > 15000:
		return "hesitation"
	return "none"

func _outcome_to_text(value: Outcome) -> String:
	match value:
		Outcome.SUCCESS_SEND:
			return "SUCCESS_SEND"
		Outcome.INTERCEPTED:
			return "INTERCEPTED"
		Outcome.SAFE_ABORT:
			return "SAFE_ABORT"
		Outcome.MISSED_WINDOW:
			return "MISSED_WINDOW"
		_:
			return "NONE"

func _build_match_key() -> String:
	var unit_token: String = "MB"
	if file_size_unit == "ГБ":
		unit_token = "GB"
	return "RI_C_%s%s_v%s_T%s_%s" % [
		unit_token,
		_format_key_num(file_size_value),
		_format_key_num(speed_mbit),
		_format_key_num(t_detect),
		pool_type
	]

func _format_num(value: float) -> String:
	return "%.1f" % value

func _format_key_num(value: float) -> String:
	var raw: String = "%.2f" % value
	while raw.ends_with("0"):
		raw = raw.substr(0, raw.length() - 1)
	if raw.ends_with("."):
		raw = raw.substr(0, raw.length() - 1)
	return raw

func _play_alarm_flash() -> void:
	alarm_flash.color = Color(1.0, 0.05, 0.05, 0.0)
	var tw: Tween = create_tween()
	tw.tween_property(alarm_flash, "color:a", 0.35, 0.10)
	tw.tween_property(alarm_flash, "color:a", 0.0, 0.24)

func _on_stability_changed(new_value: float, _change: float) -> void:
	stability_label.text = "СТАБИЛЬНОСТЬ: %d%%" % int(new_value)
