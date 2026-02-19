extends Control

enum State {
	TUNE,
	ANALYZED,
	EXEC,
	DONE
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
const MAX_ESTIMATE: float = 30.0
const SAMPLE_SLOTS: int = 7

const UNIT_MB := "\u041c\u0411"
const UNIT_GB := "\u0413\u0411"
const UNIT_MBIT_SEC := "\u041c\u0431\u0438\u0442/\u0441"
const SYMBOL_SEC := "\u0441"

const TXT_MODE := "\u0420\u0415\u0416\u0418\u041c: \u0411\u0415\u0417 \u0412\u0420\u0415\u041c\u0415\u041d\u0418"
const TXT_TITLE := "\u0420\u0410\u0414\u0418\u041e\u041f\u0415\u0420\u0415\u0425\u0412\u0410\u0422 \u2022 C"
const TXT_MISSION := "\u042d\u041a\u0421\u0422\u0420\u0415\u041d\u041d\u0410\u042f \u041f\u0415\u0420\u0415\u0414\u0410\u0427\u0410"
const TXT_HINT := "\u0421\u043d\u0430\u0447\u0430\u043b\u0430 \u043e\u0446\u0435\u043d\u0438 t. \u041f\u043e\u0442\u043e\u043c \u0410\u041d\u0410\u041b\u0418\u0417. \u041f\u043e\u0442\u043e\u043c \u0440\u0435\u0448\u0435\u043d\u0438\u0435."
const TXT_STEP_1 := "\u0428\u0410\u0413 1: \u041d\u0430\u0441\u0442\u0440\u043e\u0439\u0442\u0435 \u043e\u0446\u0435\u043d\u043a\u0443 \u0432\u0440\u0435\u043c\u0435\u043d\u0438"
const TXT_STEP_2 := "\u0428\u0410\u0413 2: \u041a\u043e\u043d\u0442\u0440\u043e\u043b\u044c \u0440\u0438\u0441\u043a\u0430"
const TXT_STEP_3 := "\u0428\u0410\u0413 3: \u041f\u0440\u0438\u043d\u044f\u0442\u044c \u0440\u0435\u0448\u0435\u043d\u0438\u0435"
const TXT_DETECT_TITLE := "\u041f\u0415\u041b\u0415\u041d\u0413\u0410\u0426\u0418\u042f"
const TXT_TRANSFER_TITLE := "\u041f\u0415\u0420\u0415\u0414\u0410\u0427\u0410"

const TXT_BTN_UNITS := "\u041f\u041e\u0414\u0421\u041a\u0410\u0417\u041a\u0410 (\u0435\u0434\u0438\u043d\u0438\u0446\u044b)"
const TXT_BTN_ANALYZE := "\u0410\u041d\u0410\u041b\u0418\u0417"
const TXT_BTN_RISK := "\u0420\u0418\u0421\u041a\u041d\u0423\u0422\u042c"
const TXT_BTN_ABORT := "\u0421\u0411\u0420\u041e\u0421"
const TXT_BTN_NEXT := "\u0414\u0410\u041b\u0415\u0415"
const TXT_BTN_DETAILS := "\u041f\u041e\u0414\u0420\u041e\u0411\u041d\u0415\u0415 \u25be"
const TXT_DETAILS_TITLE := "\u041f\u041e\u042f\u0421\u041d\u0415\u041d\u0418\u0415"
const TXT_DETAILS_CLOSE := "\u0417\u0410\u041a\u0420\u042b\u0422\u042c"

const TXT_RISK_UNKNOWN := "\u0420\u0438\u0441\u043a: \u041d\u0415\u0418\u0417\u0412\u0415\u0421\u0422\u0415\u041d"
const TXT_RISK_LOW := "\u041d\u0418\u0417\u041a\u0418\u0419"
const TXT_RISK_MID := "\u0421\u0420\u0415\u0414\u041d\u0418\u0419"
const TXT_RISK_HIGH := "\u0412\u042b\u0421\u041e\u041a\u0418\u0419"

const TXT_PLAN_STATUS := "\u0421\u0422\u0410\u0422\u0423\u0421: \u041d\u0430\u0441\u0442\u0440\u043e\u0439\u0442\u0435 \u043f\u0440\u043e\u0433\u043d\u043e\u0437 \u0438 \u043d\u0430\u0436\u043c\u0438\u0442\u0435 \u00ab\u0410\u041d\u0410\u041b\u0418\u0417\u00bb."
const TXT_ANALYZED_OK := "\u0421\u0422\u0410\u0422\u0423\u0421: \u041f\u0440\u043e\u0433\u043d\u043e\u0437 \u0442\u043e\u0447\u043d\u044b\u0439. \u0420\u0430\u0437\u0440\u0435\u0448\u0435\u043d\u043e \u0440\u0435\u0448\u0435\u043d\u0438\u0435."
const TXT_ANALYZED_MID := "\u0421\u0422\u0410\u0422\u0423\u0421: \u041f\u0440\u043e\u0433\u043d\u043e\u0437 \u0431\u043b\u0438\u0437\u043a\u0438\u0439. \u0420\u0435\u0448\u0435\u043d\u0438\u0435 \u0440\u0438\u0441\u043a\u043e\u0432\u0430\u043d\u043d\u043e."
const TXT_ANALYZED_BAD := "\u0421\u0422\u0410\u0422\u0423\u0421: \u041f\u0440\u043e\u0433\u043d\u043e\u0437 \u043d\u0435\u0442\u043e\u0447\u043d\u044b\u0439. \u0420\u0435\u0448\u0435\u043d\u0438\u0435 \u0440\u0438\u0441\u043a\u043e\u0432\u0430\u043d\u043d\u043e."
const TXT_EXEC_STARTED := "\u0421\u0422\u0410\u0422\u0423\u0421: \u041f\u0435\u0440\u0435\u0434\u0430\u0447\u0430 \u0437\u0430\u043f\u0443\u0449\u0435\u043d\u0430."
const TXT_UNITS_HINT := "\u0421\u0422\u0410\u0422\u0423\u0421: \u041c\u0411 -> \u041c\u0431\u0438\u0442: x8, \u0413\u0411 -> \u041c\u0411: x1024, t = I / v."

const TXT_OUT_SUCCESS := "\u0421\u0422\u0410\u0422\u0423\u0421: \u0423\u0421\u041f\u0415\u0425. \u041f\u0430\u043a\u0435\u0442 \u0443\u0448\u0451\u043b \u0434\u043e \u043f\u0435\u043b\u0435\u043d\u0433\u0430\u0446\u0438\u0438."
const TXT_OUT_INTERCEPT := "\u0421\u0422\u0410\u0422\u0423\u0421: \u041f\u0420\u041e\u0412\u0410\u041b. \u0412\u0430\u0441 \u0437\u0430\u0441\u0435\u043a\u043b\u0438."
const TXT_OUT_SAFE_ABORT := "\u0421\u0422\u0410\u0422\u0423\u0421: \u041f\u0420\u0410\u0412\u0418\u041b\u042c\u041d\u041e. \u041e\u0442\u043a\u0430\u0437 \u0441\u043f\u0430\u0441 \u043c\u0438\u0441\u0441\u0438\u044e."
const TXT_OUT_MISSED := "\u0421\u0422\u0410\u0422\u0423\u0421: \u0423\u041f\u0423\u0429\u0415\u041d\u041e. \u0412\u044b \u043c\u043e\u0433\u043b\u0438 \u0443\u0441\u043f\u0435\u0442\u044c."

const POOL_MB_NORMAL: Array[float] = [1.0, 2.0, 4.0, 5.0, 8.0, 10.0, 12.0, 16.0, 20.0, 25.0, 40.0]
const POOL_GB_NORMAL: Array[float] = [0.5, 1.0, 1.5, 2.0]
const POOL_SPEED_INT: Array[float] = [1.0, 2.0, 4.0, 5.0, 8.0, 10.0, 16.0, 20.0, 25.0]
const POOL_SPEED_FRAC: Array[float] = [1.5, 2.5, 7.5, 12.5]

const COLOR_SAMPLE_IDLE: Color = Color(0.18, 0.18, 0.18, 1.0)
const COLOR_SAMPLE_SUCCESS: Color = Color(0.20, 0.90, 0.30, 1.0)
const COLOR_SAMPLE_FAIL: Color = Color(0.95, 0.25, 0.25, 1.0)
const COLOR_SAMPLE_WARN: Color = Color(0.95, 0.75, 0.20, 1.0)

@onready var safe_area: MarginContainer = $SafeArea
@onready var body_split: HSplitContainer = $SafeArea/RootVBox/BodyHSplit

@onready var title_label: Label = $SafeArea/RootVBox/TopBar/TopBarHBox/TitleLabel
@onready var mode_chip: Label = $SafeArea/RootVBox/TopBar/TopBarHBox/ModeChip
@onready var stability_label: Label = $SafeArea/RootVBox/TopBar/TopBarHBox/StabilityLabel
@onready var btn_back: Button = $SafeArea/RootVBox/TopBar/TopBarHBox/BtnBack

@onready var mission_title: Label = $SafeArea/RootVBox/BodyHSplit/LeftCol/MissionCard/MissionMargin/MissionVBox/MissionTitle
@onready var task_line_1: Label = $SafeArea/RootVBox/BodyHSplit/LeftCol/MissionCard/MissionMargin/MissionVBox/TaskLine1
@onready var task_line_2: Label = $SafeArea/RootVBox/BodyHSplit/LeftCol/MissionCard/MissionMargin/MissionVBox/TaskLine2
@onready var task_line_3: Label = $SafeArea/RootVBox/BodyHSplit/LeftCol/MissionCard/MissionMargin/MissionVBox/TaskLine3
@onready var micro_hint: Label = $SafeArea/RootVBox/BodyHSplit/LeftCol/MissionCard/MissionMargin/MissionVBox/MicroHint

@onready var step_1_label: Label = $SafeArea/RootVBox/BodyHSplit/LeftCol/KnobCard/KnobMargin/KnobVBox/Step1Label
@onready var estimate_value_label: Label = $SafeArea/RootVBox/BodyHSplit/LeftCol/KnobCard/KnobMargin/KnobVBox/EstimateValue
@onready var time_knob: Control = $SafeArea/RootVBox/BodyHSplit/LeftCol/KnobCard/KnobMargin/KnobVBox/KnobCenter/TimeKnob
@onready var btn_minus_1: Button = $SafeArea/RootVBox/BodyHSplit/LeftCol/KnobCard/KnobMargin/KnobVBox/FineButtonsRow/BtnMinus1
@onready var btn_minus_01: Button = $SafeArea/RootVBox/BodyHSplit/LeftCol/KnobCard/KnobMargin/KnobVBox/FineButtonsRow/BtnMinus01
@onready var btn_plus_01: Button = $SafeArea/RootVBox/BodyHSplit/LeftCol/KnobCard/KnobMargin/KnobVBox/FineButtonsRow/BtnPlus01
@onready var btn_plus_1: Button = $SafeArea/RootVBox/BodyHSplit/LeftCol/KnobCard/KnobMargin/KnobVBox/FineButtonsRow/BtnPlus1
@onready var btn_analyze: Button = $SafeArea/RootVBox/BodyHSplit/LeftCol/KnobCard/KnobMargin/KnobVBox/BtnAnalyze

@onready var status_label: Label = $SafeArea/RootVBox/BodyHSplit/LeftCol/StatusCard/StatusMargin/StatusLabel

@onready var step_2_label: Label = $SafeArea/RootVBox/BodyHSplit/RightCol/RiskCard/RiskMargin/RiskVBox/Step2Label
@onready var detection_title: Label = $SafeArea/RootVBox/BodyHSplit/RightCol/RiskCard/RiskMargin/RiskVBox/DetectionTitle
@onready var detection_bar: ProgressBar = $SafeArea/RootVBox/BodyHSplit/RightCol/RiskCard/RiskMargin/RiskVBox/DetectionBar
@onready var detect_countdown: Label = $SafeArea/RootVBox/BodyHSplit/RightCol/RiskCard/RiskMargin/RiskVBox/DetectCountdown
@onready var transfer_title: Label = $SafeArea/RootVBox/BodyHSplit/RightCol/RiskCard/RiskMargin/RiskVBox/TransferTitle
@onready var transfer_bar: ProgressBar = $SafeArea/RootVBox/BodyHSplit/RightCol/RiskCard/RiskMargin/RiskVBox/TransferBar
@onready var transfer_countdown: Label = $SafeArea/RootVBox/BodyHSplit/RightCol/RiskCard/RiskMargin/RiskVBox/TransferCountdown
@onready var risk_label: Label = $SafeArea/RootVBox/BodyHSplit/RightCol/RiskCard/RiskMargin/RiskVBox/RiskLabel

@onready var step_3_label: Label = $SafeArea/RootVBox/BodyHSplit/RightCol/ActionsCard/ActionsMargin/ActionsVBox/Step3Label
@onready var btn_units: Button = $SafeArea/RootVBox/BodyHSplit/RightCol/ActionsCard/ActionsMargin/ActionsVBox/SecondaryActionsRow/BtnUnits
@onready var btn_details: Button = $SafeArea/RootVBox/BodyHSplit/RightCol/ActionsCard/ActionsMargin/ActionsVBox/SecondaryActionsRow/BtnDetails
@onready var btn_risk: Button = $SafeArea/RootVBox/BodyHSplit/RightCol/ActionsCard/ActionsMargin/ActionsVBox/PrimaryActionsRow/BtnRisk
@onready var btn_abort: Button = $SafeArea/RootVBox/BodyHSplit/RightCol/ActionsCard/ActionsMargin/ActionsVBox/PrimaryActionsRow/BtnAbort
@onready var btn_next: Button = $SafeArea/RootVBox/BodyHSplit/RightCol/ActionsCard/ActionsMargin/ActionsVBox/SecondaryActionsRow/BtnNext
@onready var sample_strip: HBoxContainer = $SafeArea/RootVBox/BodyHSplit/RightCol/ActionsCard/ActionsMargin/ActionsVBox/SampleStrip

@onready var details_overlay: Control = $DetailsOverlay
@onready var details_sheet_title: Label = $DetailsOverlay/BottomSheet/SheetMargin/SheetVBox/SheetTitle
@onready var details_sheet_text: RichTextLabel = $DetailsOverlay/BottomSheet/SheetMargin/SheetVBox/SheetText
@onready var btn_close_details: Button = $DetailsOverlay/BottomSheet/SheetMargin/SheetVBox/BtnCloseDetails

@onready var alarm_flash: ColorRect = $AlarmFlash

var state: State = State.TUNE
var decision: Decision = Decision.NONE
var outcome: Outcome = Outcome.NONE

var file_size_value: float = 0.0
var file_size_unit: String = UNIT_MB
var speed_mbit: float = 0.0
var t_detect: float = 0.0
var t_true: float = 0.0
var t_est: float = 0.0

var pool_type: String = "NORMAL"
var anchor_type: String = "none"
var anchor_countdown: int = 0

var detection_elapsed: float = 0.0
var transfer_elapsed: float = 0.0
var transfer_started: bool = false
var used_units: bool = false

var start_ms: int = 0
var first_action_ms: int = -1
var check_ms: int = -1
var decision_ms: int = -1

var analyze_count: int = 0
var knob_moves_count: int = 0
var direction_changes: int = 0
var _last_move_sign: int = 0

var sample_cursor: int = 0
var sample_refs: Array = []
var _ui_ready: bool = false

func _ready() -> void:
	randomize()
	_apply_static_texts()
	_connect_signals()
	_collect_sample_refs()
	_reset_sample_strip()
	_apply_safe_area_padding()
	_configure_layout()
	_set_details_visible(false)

	if not GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.connect(_on_stability_changed)
	_on_stability_changed(GlobalMetrics.stability, 0.0)

	anchor_countdown = randi_range(7, 10)
	_start_trial()
	_ui_ready = true

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _ui_ready:
		_apply_safe_area_padding()
		_configure_layout()

func _process(delta: float) -> void:
	if state != State.ANALYZED and state != State.EXEC:
		return

	detection_elapsed += delta
	if decision == Decision.RISK and transfer_started:
		transfer_elapsed += delta

	_update_runtime_ui()

	if decision == Decision.RISK:
		if transfer_elapsed >= t_true and detection_elapsed <= t_detect + EPS:
			_finalize_trial(Outcome.SUCCESS_SEND, "RISK")
			return
		if detection_elapsed >= t_detect and transfer_elapsed < t_true - EPS:
			_play_alarm_flash()
			_finalize_trial(Outcome.INTERCEPTED, "RISK")
			return
	else:
		if detection_elapsed >= t_detect:
			if decision_ms < 0:
				decision_ms = Time.get_ticks_msec()
			_play_alarm_flash()
			_finalize_trial(Outcome.INTERCEPTED, "NONE")

func _apply_static_texts() -> void:
	title_label.text = TXT_TITLE
	mode_chip.text = TXT_MODE
	mission_title.text = TXT_MISSION
	micro_hint.text = TXT_HINT
	step_1_label.text = TXT_STEP_1
	step_2_label.text = TXT_STEP_2
	step_3_label.text = TXT_STEP_3
	detection_title.text = TXT_DETECT_TITLE
	transfer_title.text = TXT_TRANSFER_TITLE

	btn_units.text = TXT_BTN_UNITS
	btn_details.text = TXT_BTN_DETAILS
	btn_analyze.text = TXT_BTN_ANALYZE
	btn_risk.text = TXT_BTN_RISK
	btn_abort.text = TXT_BTN_ABORT
	btn_next.text = TXT_BTN_NEXT
	details_sheet_title.text = TXT_DETAILS_TITLE
	btn_close_details.text = TXT_DETAILS_CLOSE

func _connect_signals() -> void:
	btn_back.pressed.connect(_on_back_pressed)
	btn_minus_1.pressed.connect(_on_minus_1_pressed)
	btn_minus_01.pressed.connect(_on_minus_01_pressed)
	btn_plus_01.pressed.connect(_on_plus_01_pressed)
	btn_plus_1.pressed.connect(_on_plus_1_pressed)
	btn_units.pressed.connect(_on_units_pressed)
	btn_details.pressed.connect(_on_details_pressed)
	btn_close_details.pressed.connect(_on_details_close_pressed)
	btn_analyze.pressed.connect(_on_analyze_pressed)
	btn_risk.pressed.connect(_on_risk_pressed)
	btn_abort.pressed.connect(_on_abort_pressed)
	btn_next.pressed.connect(_on_next_pressed)

	var knob_callback: Callable = Callable(self, "_on_knob_value_changed")
	if not time_knob.is_connected("value_changed", knob_callback):
		time_knob.connect("value_changed", knob_callback)

func _apply_safe_area_padding() -> void:
	if safe_area == null:
		return

	var base_left: float = 16.0
	var base_top: float = 12.0
	var base_right: float = 16.0
	var base_bottom: float = 12.0

	var safe_rect: Rect2i = DisplayServer.get_display_safe_area()
	if safe_rect.size.x > 0 and safe_rect.size.y > 0:
		var viewport_size: Vector2 = get_viewport_rect().size
		base_left = maxf(base_left, float(safe_rect.position.x))
		base_top = maxf(base_top, float(safe_rect.position.y))
		base_right = maxf(base_right, viewport_size.x - float(safe_rect.position.x + safe_rect.size.x))
		base_bottom = maxf(base_bottom, viewport_size.y - float(safe_rect.position.y + safe_rect.size.y))

	safe_area.add_theme_constant_override("margin_left", int(round(base_left)))
	safe_area.add_theme_constant_override("margin_top", int(round(base_top)))
	safe_area.add_theme_constant_override("margin_right", int(round(base_right)))
	safe_area.add_theme_constant_override("margin_bottom", int(round(base_bottom)))

func _configure_layout() -> void:
	if body_split == null or time_knob == null:
		return

	var size: Vector2 = get_viewport_rect().size
	body_split.split_offset = int(size.x * 0.56)
	if size.x < 1500.0:
		time_knob.custom_minimum_size = Vector2(280, 280)
	else:
		time_knob.custom_minimum_size = Vector2(320, 320)

func _collect_sample_refs() -> void:
	sample_refs.clear()
	for child_var in sample_strip.get_children():
		var child_node: Node = child_var as Node
		var bg_node: ColorRect = child_node.get_node_or_null("BG") as ColorRect
		var mark_node: Label = child_node.get_node_or_null("AnchorMark") as Label
		if bg_node != null and mark_node != null:
			mark_node.text = "\u042f"
			sample_refs.append({"bg": bg_node, "mark": mark_node})

func _reset_sample_strip() -> void:
	for slot_var in sample_refs:
		var slot: Dictionary = slot_var as Dictionary
		var bg: ColorRect = slot["bg"] as ColorRect
		var mark: Label = slot["mark"] as Label
		bg.color = COLOR_SAMPLE_IDLE
		mark.visible = false

func _start_trial() -> void:
	state = State.TUNE
	decision = Decision.NONE
	outcome = Outcome.NONE
	transfer_started = false
	used_units = false

	detection_elapsed = 0.0
	transfer_elapsed = 0.0

	analyze_count = 0
	knob_moves_count = 0
	direction_changes = 0
	_last_move_sign = 0

	start_ms = Time.get_ticks_msec()
	first_action_ms = -1
	check_ms = -1
	decision_ms = -1

	_generate_trial()
	_refresh_task_labels()
	_reset_runtime_ui()
	_set_tune_state_ui()

	time_knob.call("set_knob_value", 0.0, false)
	_set_estimate(0.0)
	_update_details_text()

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
			generated = _generate_anchor_gb()
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
	for _i in range(500):
		var use_gb: bool = randf() < 0.10
		var size_value: float = 0.0
		var size_unit: String = UNIT_MB
		if use_gb:
			size_value = POOL_GB_NORMAL[randi() % POOL_GB_NORMAL.size()]
			size_unit = UNIT_GB
		else:
			size_value = POOL_MB_NORMAL[randi() % POOL_MB_NORMAL.size()]
			size_unit = UNIT_MB

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
		"size_unit": UNIT_MB,
		"speed_mbit": 16.0,
		"t_detect": 6.0,
		"t_true": 5.0,
		"anchor_type": "none"
	}

func _generate_anchor_forgot_x8() -> Dictionary:
	for _i in range(500):
		var size_value: float = POOL_MB_NORMAL[randi() % POOL_MB_NORMAL.size()]
		var speed: float = _pick_speed()
		var true_time: float = _compute_true_time(size_value, UNIT_MB, speed)
		if true_time < 4.0 or true_time > 20.0:
			continue

		var fake_time: float = size_value / speed
		var detect_low: float = maxf(fake_time + 0.2, 0.6)
		var detect_high: float = true_time - 0.2
		if detect_high <= detect_low:
			continue

		return {
			"size_value": size_value,
			"size_unit": UNIT_MB,
			"speed_mbit": speed,
			"t_detect": randf_range(detect_low, detect_high),
			"t_true": true_time,
			"anchor_type": "forgot_x8"
		}
	return {}

func _generate_anchor_boundary() -> Dictionary:
	for _i in range(500):
		var use_gb: bool = randf() < 0.30
		var size_value: float = 0.0
		var size_unit: String = UNIT_MB
		if use_gb:
			size_value = POOL_GB_NORMAL[randi() % POOL_GB_NORMAL.size()]
			size_unit = UNIT_GB
		else:
			size_value = POOL_MB_NORMAL[randi() % POOL_MB_NORMAL.size()]
			size_unit = UNIT_MB

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

func _generate_anchor_gb() -> Dictionary:
	for _i in range(500):
		var size_value: float = POOL_GB_NORMAL[randi() % POOL_GB_NORMAL.size()]
		var speed: float = _pick_speed()
		var true_time: float = _compute_true_time(size_value, UNIT_GB, speed)
		if true_time < 6.0 or true_time > 20.0:
			continue

		var fake_time: float = (size_value * 8.0) / speed
		var detect_low: float = fake_time + 0.1
		var detect_high: float = true_time - 0.3
		if detect_high <= detect_low:
			continue

		return {
			"size_value": size_value,
			"size_unit": UNIT_GB,
			"speed_mbit": speed,
			"t_detect": randf_range(detect_low, detect_high),
			"t_true": true_time,
			"anchor_type": "forgot_x1024"
		}
	return {}

func _pick_speed() -> float:
	if randf() < 0.30:
		return POOL_SPEED_FRAC[randi() % POOL_SPEED_FRAC.size()]
	return POOL_SPEED_INT[randi() % POOL_SPEED_INT.size()]

func _compute_true_time(size_value: float, size_unit: String, speed: float) -> float:
	var i_mbit: float = size_value * 8.0
	if size_unit == UNIT_GB:
		i_mbit = size_value * 1024.0 * 8.0
	return i_mbit / speed

func _refresh_task_labels() -> void:
	task_line_1.text = "\u041e\u0431\u044a\u0451\u043c \u043f\u0430\u043a\u0435\u0442\u0430: %s %s" % [_format_num(file_size_value), file_size_unit]
	task_line_2.text = "\u0421\u043a\u043e\u0440\u043e\u0441\u0442\u044c \u043a\u0430\u043d\u0430\u043b\u0430: %s %s" % [_format_num(speed_mbit), UNIT_MBIT_SEC]
	task_line_3.text = "\u0414\u043e \u043f\u0435\u043b\u0435\u043d\u0433\u0430\u0446\u0438\u0438: %s %s" % [_format_num(t_detect), SYMBOL_SEC]

func _reset_runtime_ui() -> void:
	detection_bar.value = 0.0
	transfer_bar.value = 0.0
	detect_countdown.text = "%s %s" % [_format_num(t_detect), SYMBOL_SEC]
	transfer_countdown.text = "\u2014"
	risk_label.text = TXT_RISK_UNKNOWN
	alarm_flash.color = Color(1.0, 0.05, 0.05, 0.0)

func _set_tune_state_ui() -> void:
	state = State.TUNE
	_set_knob_interactive(true)
	btn_analyze.disabled = false
	btn_risk.disabled = true
	btn_abort.disabled = true
	btn_units.disabled = false
	btn_next.visible = false
	status_label.text = TXT_PLAN_STATUS

func _set_analyzed_state_ui() -> void:
	state = State.ANALYZED
	_set_knob_interactive(false)
	btn_analyze.disabled = true
	btn_risk.disabled = false
	btn_abort.disabled = false
	btn_units.disabled = false
	btn_next.visible = false

	var abs_error: float = absf(t_est - t_true)
	if abs_error <= 0.3:
		status_label.text = TXT_ANALYZED_OK
	elif abs_error <= 1.0:
		status_label.text = TXT_ANALYZED_MID
	else:
		status_label.text = TXT_ANALYZED_BAD

	risk_label.text = "\u0420\u0438\u0441\u043a: %s" % _estimate_risk_text()

func _set_exec_state_ui() -> void:
	state = State.EXEC
	_set_knob_interactive(false)
	btn_analyze.disabled = true
	btn_risk.disabled = true
	btn_abort.disabled = true
	btn_units.disabled = true
	btn_next.visible = false

func _set_done_state_ui() -> void:
	state = State.DONE
	_set_knob_interactive(false)
	btn_analyze.disabled = true
	btn_risk.disabled = true
	btn_abort.disabled = true
	btn_units.disabled = true
	btn_next.visible = true

func _set_knob_interactive(is_enabled: bool) -> void:
	time_knob.mouse_filter = Control.MOUSE_FILTER_STOP if is_enabled else Control.MOUSE_FILTER_IGNORE
	btn_minus_1.disabled = not is_enabled
	btn_minus_01.disabled = not is_enabled
	btn_plus_01.disabled = not is_enabled
	btn_plus_1.disabled = not is_enabled

func _on_knob_value_changed(new_value: float, delta: float) -> void:
	if state != State.TUNE:
		return
	_register_first_action()
	_set_estimate(new_value)
	_register_knob_move(delta)

func _on_minus_01_pressed() -> void:
	if state != State.TUNE:
		return
	_register_first_action()
	_apply_estimate_delta(-0.1)

func _on_plus_01_pressed() -> void:
	if state != State.TUNE:
		return
	_register_first_action()
	_apply_estimate_delta(0.1)

func _on_minus_1_pressed() -> void:
	if state != State.TUNE:
		return
	_register_first_action()
	_apply_estimate_delta(-1.0)

func _on_plus_1_pressed() -> void:
	if state != State.TUNE:
		return
	_register_first_action()
	_apply_estimate_delta(1.0)

func _apply_estimate_delta(delta: float) -> void:
	var next_value: float = clampf(t_est + delta, MIN_ESTIMATE, MAX_ESTIMATE)
	if is_equal_approx(next_value, t_est):
		return
	time_knob.call("set_knob_value", next_value, false)
	_set_estimate(next_value)
	_register_knob_move(delta)

func _set_estimate(value_sec: float) -> void:
	t_est = clampf(value_sec, MIN_ESTIMATE, MAX_ESTIMATE)
	estimate_value_label.text = "t = %s %s" % [_format_num(t_est), SYMBOL_SEC]
	_update_details_text()

func _register_first_action() -> void:
	if first_action_ms < 0:
		first_action_ms = Time.get_ticks_msec()

func _register_knob_move(delta: float) -> void:
	if is_zero_approx(delta):
		return
	knob_moves_count += 1
	var sign: int = 1 if delta > 0.0 else -1
	if _last_move_sign != 0 and sign != _last_move_sign:
		direction_changes += 1
	_last_move_sign = sign

func _on_analyze_pressed() -> void:
	if state != State.TUNE:
		return
	_register_first_action()
	analyze_count += 1
	if check_ms < 0:
		check_ms = Time.get_ticks_msec()
	detection_elapsed = 0.0
	transfer_elapsed = 0.0
	_set_analyzed_state_ui()
	_update_details_text()

func _on_risk_pressed() -> void:
	if state != State.ANALYZED and state != State.EXEC:
		return
	_register_first_action()
	if decision == Decision.RISK:
		return

	if decision_ms < 0:
		decision_ms = Time.get_ticks_msec()
	decision = Decision.RISK
	transfer_started = true
	transfer_elapsed = 0.0
	_set_exec_state_ui()
	status_label.text = TXT_EXEC_STARTED
	_update_details_text()

func _on_abort_pressed() -> void:
	if state != State.ANALYZED and state != State.EXEC:
		return
	_register_first_action()
	if decision_ms < 0:
		decision_ms = Time.get_ticks_msec()
	decision = Decision.ABORT

	if t_true > t_detect + EPS:
		_finalize_trial(Outcome.SAFE_ABORT, "ABORT")
	else:
		_finalize_trial(Outcome.MISSED_WINDOW, "ABORT")

func _on_units_pressed() -> void:
	if state == State.DONE:
		return
	_register_first_action()
	used_units = true
	status_label.text = TXT_UNITS_HINT
	_update_details_text()

func _on_details_pressed() -> void:
	_set_details_visible(true)

func _on_details_close_pressed() -> void:
	_set_details_visible(false)

func _set_details_visible(is_visible: bool) -> void:
	details_overlay.visible = is_visible

func _on_next_pressed() -> void:
	_start_trial()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _update_runtime_ui() -> void:
	var detect_ratio: float = 0.0
	if t_detect > 0.0:
		detect_ratio = clampf(detection_elapsed / t_detect, 0.0, 1.0)
	detection_bar.value = detect_ratio * 100.0
	detect_countdown.text = "%s %s" % [_format_num(maxf(0.0, t_detect - detection_elapsed)), SYMBOL_SEC]

	if decision == Decision.RISK and transfer_started and t_true > 0.0:
		var transfer_ratio: float = clampf(transfer_elapsed / t_true, 0.0, 1.0)
		transfer_bar.value = transfer_ratio * 100.0
		transfer_countdown.text = "%s %s" % [_format_num(maxf(0.0, t_true - transfer_elapsed)), SYMBOL_SEC]
	else:
		transfer_bar.value = 0.0
		transfer_countdown.text = "\u043e\u0436\u0438\u0434\u0430\u043d\u0438\u0435"

func _estimate_risk_text() -> String:
	if t_est <= t_detect - 0.5:
		return TXT_RISK_LOW
	if t_est <= t_detect + 0.5:
		return TXT_RISK_MID
	return TXT_RISK_HIGH

func _finalize_trial(result: Outcome, decision_label: String) -> void:
	if state == State.DONE:
		return

	outcome = result
	_set_done_state_ui()

	var is_success: bool = (outcome == Outcome.SUCCESS_SEND or outcome == Outcome.SAFE_ABORT)
	var sample_color: Color = COLOR_SAMPLE_FAIL
	match outcome:
		Outcome.SUCCESS_SEND:
			status_label.text = TXT_OUT_SUCCESS
			sample_color = COLOR_SAMPLE_SUCCESS
		Outcome.INTERCEPTED:
			status_label.text = TXT_OUT_INTERCEPT
			sample_color = COLOR_SAMPLE_FAIL
		Outcome.SAFE_ABORT:
			status_label.text = TXT_OUT_SAFE_ABORT
			sample_color = COLOR_SAMPLE_SUCCESS
		Outcome.MISSED_WINDOW:
			status_label.text = TXT_OUT_MISSED
			sample_color = COLOR_SAMPLE_WARN
		_:
			status_label.text = "\u0421\u0422\u0410\u0422\u0423\u0421: \u0437\u0430\u0432\u0435\u0440\u0448\u0435\u043d\u043e"
			sample_color = COLOR_SAMPLE_FAIL

	_update_sample_slot(sample_color)
	_send_trial_payload(is_success, decision_label)
	_update_details_text()

func _update_sample_slot(color: Color) -> void:
	if sample_refs.is_empty():
		return
	var slot: Dictionary = sample_refs[sample_cursor] as Dictionary
	var bg: ColorRect = slot["bg"] as ColorRect
	var mark: Label = slot["mark"] as Label
	bg.color = color
	mark.visible = (pool_type == "ANCHOR")
	sample_cursor = (sample_cursor + 1) % min(SAMPLE_SLOTS, sample_refs.size())

func _send_trial_payload(is_success: bool, decision_label: String) -> void:
	var now_ms: int = Time.get_ticks_msec()
	var elapsed_ms: int = now_ms - start_ms
	var time_to_first_action_ms: int = 0
	if first_action_ms >= 0:
		time_to_first_action_ms = first_action_ms - start_ms

	var time_to_check_ms: int = 0
	if check_ms >= 0:
		time_to_check_ms = check_ms - start_ms

	var time_to_decision_ms: int = elapsed_ms
	if decision_ms >= 0:
		time_to_decision_ms = decision_ms - start_ms

	var error_abs: float = absf(t_est - t_true)
	var error_rel: float = 0.0
	if t_true > 0.0:
		error_rel = error_abs / t_true

	var low_certainty: bool = (knob_moves_count >= 6 or direction_changes >= 2)
	var error_type: String = _classify_error_type(time_to_decision_ms)

	var payload: Dictionary = {
		"quest_id": "radio_intercept",
		"stage_id": "C",
		"match_key": _build_match_key(),
		"pool_type": pool_type,
		"anchor_type": anchor_type,
		"anchor": (pool_type == "ANCHOR"),
		"file_size_value": file_size_value,
		"file_size_unit": file_size_unit,
		"speed_mbit": speed_mbit,
		"t_detect": t_detect,
		"t_true": t_true,
		"t_est": t_est,
		"estimate_sec": t_est,
		"true_sec": t_true,
		"error_sec_abs": error_abs,
		"error_sec_rel": error_rel,
		"decision": decision_label,
		"outcome": _outcome_to_text(outcome),
		"used_units": used_units,
		"error_type": error_type,
		"knob_moves_count": knob_moves_count,
		"direction_changes": direction_changes,
		"analyze_count": analyze_count,
		"low_certainty": low_certainty,
		"valid_for_diagnostics": true,
		"valid_for_mastery": (not used_units) and (outcome == Outcome.SUCCESS_SEND or outcome == Outcome.SAFE_ABORT),
		"is_correct": is_success,
		"is_fit": is_success,
		"elapsed_ms": elapsed_ms,
		"time_to_first_action_ms": time_to_first_action_ms,
		"time_to_check_ms": time_to_check_ms,
		"time_to_decision_ms": time_to_decision_ms
	}
	GlobalMetrics.register_trial(payload)

func _classify_error_type(time_to_decision_ms: int) -> String:
	if used_units:
		return "assisted"
	if t_true <= 0.0:
		return "arithmetic_error"

	var rel_x8: float = absf((t_est * 8.0) - t_true) / t_true
	if rel_x8 < 0.15:
		return "forgot_x8"

	if file_size_unit == UNIT_GB:
		var rel_x1024: float = absf((t_est * 1024.0) - t_true) / t_true
		if rel_x1024 < 0.15:
			return "forgot_x1024"

	var rel_error: float = absf(t_est - t_true) / t_true
	if rel_error > 0.25:
		return "arithmetic_error"
	if time_to_decision_ms > 15000:
		return "hesitation"
	return "none"

func _build_match_key() -> String:
	var unit_token: String = "MB"
	if file_size_unit == UNIT_GB:
		unit_token = "GB"
	return "RI_C_%s%s_v%s_T%s_%s" % [
		unit_token,
		_format_key_num(file_size_value),
		_format_key_num(speed_mbit),
		_format_key_num(t_detect),
		pool_type
	]

func _outcome_to_text(current_outcome: Outcome) -> String:
	match current_outcome:
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

func _update_details_text() -> void:
	var lines: Array[String] = []
	lines.append("\u0424\u043e\u0440\u043c\u0443\u043b\u0430: t = I / v")
	lines.append("I (%s): %s" % [file_size_unit, _format_num(file_size_value)])
	lines.append("v (%s): %s" % [UNIT_MBIT_SEC, _format_num(speed_mbit)])
	lines.append("T_detect: %s %s" % [_format_num(t_detect), SYMBOL_SEC])
	lines.append("t_est: %s %s" % [_format_num(t_est), SYMBOL_SEC])
	if used_units:
		lines.append("\u041f\u043e\u0434\u0441\u043a\u0430\u0437\u043a\u0430 \u0435\u0434\u0438\u043d\u0438\u0446 \u0438\u0441\u043f\u043e\u043b\u044c\u0437\u043e\u0432\u0430\u043d\u0430.")
	if state == State.DONE:
		lines.append("t_true: %s %s" % [_format_num(t_true), SYMBOL_SEC])
		lines.append("outcome: %s" % _outcome_to_text(outcome))
	else:
		lines.append("t_true: \u0441\u043a\u0440\u044b\u0442\u043e \u0434\u043e \u0437\u0430\u0432\u0435\u0440\u0448\u0435\u043d\u0438\u044f")
	lines.append("якорь: %s (%s)" % ["да" if pool_type == "ANCHOR" else "нет", anchor_type])
	details_sheet_text.text = "\n".join(lines)

func _format_num(value: float) -> String:
	return "%.1f" % value

func _format_key_num(value: float) -> String:
	var text_value: String = "%.2f" % value
	while text_value.ends_with("0"):
		text_value = text_value.substr(0, text_value.length() - 1)
	if text_value.ends_with("."):
		text_value = text_value.substr(0, text_value.length() - 1)
	return text_value

func _play_alarm_flash() -> void:
	alarm_flash.color = Color(1.0, 0.05, 0.05, 0.0)
	var tw: Tween = create_tween()
	tw.tween_property(alarm_flash, "color:a", 0.35, 0.10)
	tw.tween_property(alarm_flash, "color:a", 0.0, 0.24)

func _on_stability_changed(new_value: float, _change: float) -> void:
	stability_label.text = "\u0421\u0422\u0410\u0411\u0418\u041b\u042c\u041d\u041e\u0421\u0422\u042c: %d%%" % int(new_value)
