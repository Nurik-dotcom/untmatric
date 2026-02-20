extends Control

enum Phase {
	CALC,
	SELECT,
	DONE
}

const POOL_NORMAL: Array[int] = [64, 80, 100, 128, 256, 512, 1024]
const POOL_ANCHOR: Array[int] = [75, 110, 125, 300, 750, 1000]
const SAMPLE_SLOTS: int = 7
const PHONE_LANDSCAPE_MAX_HEIGHT: float = 520.0

const COLOR_IDLE: Color = Color(0.18, 0.18, 0.18, 1.0)
const COLOR_GOOD: Color = Color(0.20, 0.90, 0.30, 1.0)
const COLOR_WARN: Color = Color(0.95, 0.75, 0.20, 1.0)
const COLOR_BAD: Color = Color(0.95, 0.25, 0.25, 1.0)

const TXT_TITLE: String = "\u0420\u0410\u0414\u0418\u041e\u041f\u0415\u0420\u0415\u0425\u0412\u0410\u0422 | B"
const TXT_BACK: String = "\u041d\u0410\u0417\u0410\u0414"
const TXT_STORAGE_TITLE: String = "\u0421\u041a\u041b\u0410\u0414 \u041d\u041e\u0421\u0418\u0422\u0415\u041b\u0415\u0419"
const TXT_CONTEXT_TITLE: String = "\u0422\u0415\u0420\u041c\u0418\u041d\u0410\u041b"
const TXT_TASK: String = "\u0412\u044b\u0447\u0438\u0441\u043b\u0438\u0442\u0435 I = K*i \u0438 \u0432\u044b\u0431\u0435\u0440\u0438\u0442\u0435 \u043e\u043f\u0442\u0438\u043c\u0430\u043b\u044c\u043d\u044b\u0439 \u043d\u043e\u0441\u0438\u0442\u0435\u043b\u044c."
const TXT_CALC_TITLE: String = "\u0420\u0410\u0421\u0427\u0401\u0422 I"
const TXT_BTN_CHECK: String = "\u041f\u0420\u041e\u0412\u0415\u0420\u0418\u0422\u042c"
const TXT_PREVIEW_TITLE: String = "\u0414\u0418\u0410\u0413\u041d\u041e\u0421\u0422\u0418\u041a\u0410"
const TXT_BTN_CONVERTER: String = "\u041a\u041e\u041d\u0412\u0415\u0420\u0422\u0415\u0420"
const TXT_BTN_CONFIRM: String = "\u041f\u041e\u0414\u0422\u0412\u0415\u0420\u0414\u0418\u0422\u042c"
const TXT_BTN_NEXT: String = "\u0414\u0410\u041b\u0415\u0415"
const TXT_BTN_DETAILS_CLOSED: String = "\u041f\u041e\u0414\u0420\u041e\u0411\u041d\u0415\u0415 \u25be"
const TXT_BTN_DETAILS_OPEN: String = "\u0421\u041a\u0420\u042b\u0422\u042c \u25b4"
const TXT_DETAILS_TITLE: String = "\u041f\u041e\u042f\u0421\u041d\u0415\u041d\u0418\u0415"
const TXT_DETAILS_CLOSE: String = "\u0417\u0410\u041a\u0420\u042b\u0422\u042c"

const TXT_STATUS_PLAN: String = "\u0421\u0422\u0410\u0422\u0423\u0421: \u0421\u043d\u0430\u0447\u0430\u043b\u0430 \u043f\u043e\u0441\u0447\u0438\u0442\u0430\u0439\u0442\u0435 I, \u0437\u0430\u0442\u0435\u043c \u0432\u044b\u0431\u0435\u0440\u0438\u0442\u0435 \u043d\u043e\u0441\u0438\u0442\u0435\u043b\u044c."
const TXT_STATUS_CALC_OK: String = "\u0421\u0422\u0410\u0422\u0423\u0421: \u0420\u0430\u0441\u0447\u0451\u0442 I \u0432\u0435\u0440\u043d\u044b\u0439. \u0412\u044b\u0431\u0435\u0440\u0438\u0442\u0435 \u043d\u043e\u0441\u0438\u0442\u0435\u043b\u044c."
const TXT_STATUS_CALC_WARN: String = "\u0421\u0422\u0410\u0422\u0423\u0421: \u0420\u0430\u0441\u0447\u0451\u0442 I \u043d\u0435\u0442\u043e\u0447\u043d\u044b\u0439. \u0412\u044b\u0431\u0435\u0440\u0438\u0442\u0435 \u043d\u043e\u0441\u0438\u0442\u0435\u043b\u044c \u043e\u0441\u043e\u0437\u043d\u0430\u043d\u043d\u043e."
const TXT_STATUS_CONVERTER: String = "\u0421\u0422\u0410\u0422\u0423\u0421: I = %d \u0431\u0438\u0442 (%d \u0431\u0430\u0439\u0442)."
const TXT_RESULT_BEST: String = "\u0421\u0422\u0410\u0422\u0423\u0421: \u041e\u0442\u043b\u0438\u0447\u043d\u043e. \u041e\u043f\u0442\u0438\u043c\u0430\u043b\u044c\u043d\u044b\u0439 \u043d\u043e\u0441\u0438\u0442\u0435\u043b\u044c."
const TXT_RESULT_UNDER: String = "\u0421\u0422\u0410\u0422\u0423\u0421: \u041d\u0435\u043f\u0440\u0430\u0432\u0438\u043b\u044c\u043d\u043e. \u041d\u043e\u0441\u0438\u0442\u0435\u043b\u044c \u043d\u0435 \u0432\u043c\u0435\u0449\u0430\u0435\u0442 \u0434\u0430\u043d\u043d\u044b\u0435."
const TXT_RESULT_CALC: String = "\u0421\u0422\u0410\u0422\u0423\u0421: \u0412\u044b\u0431\u043e\u0440 \u0441\u0434\u0435\u043b\u0430\u043d, \u043d\u043e \u0440\u0430\u0441\u0447\u0451\u0442 I \u0431\u044b\u043b \u043d\u0435\u0442\u043e\u0447\u043d\u044b\u043c."
const TXT_RESULT_UNIT: String = "\u0421\u0422\u0410\u0422\u0423\u0421: \u041f\u043e\u0445\u043e\u0436\u0435 \u043d\u0430 \u043f\u0443\u0442\u0430\u043d\u0438\u0446\u0443 \u0435\u0434\u0438\u043d\u0438\u0446 (\u0431\u0438\u0442/\u0431\u0430\u0439\u0442)."
const TXT_RESULT_OVER: String = "\u0421\u0422\u0410\u0422\u0423\u0421: \u0412\u0435\u0440\u043d\u043e, \u043d\u043e \u043d\u043e\u0441\u0438\u0442\u0435\u043b\u044c \u0438\u0437\u0431\u044b\u0442\u043e\u0447\u0435\u043d."

@onready var safe_area: MarginContainer = $SafeArea
@onready var root_vbox: VBoxContainer = $SafeArea/RootVBox
@onready var body_split: HSplitContainer = $SafeArea/RootVBox/BodyHSplit
@onready var left_pane: PanelContainer = $SafeArea/RootVBox/BodyHSplit/LeftPane
@onready var right_vbox: VBoxContainer = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox
@onready var storage_grid: GridContainer = $SafeArea/RootVBox/BodyHSplit/LeftPane/LeftMargin/LeftVBox/StorageGrid

@onready var btn_back: Button = $SafeArea/RootVBox/Header/HeaderHBox/BtnBack
@onready var title_label: Label = $SafeArea/RootVBox/Header/HeaderHBox/TitleLabel
@onready var meta_label: Label = $SafeArea/RootVBox/Header/HeaderHBox/MetaLabel

@onready var storage_title: Label = $SafeArea/RootVBox/BodyHSplit/LeftPane/LeftMargin/LeftVBox/StorageTitle
@onready var storage_btns: Array[Button] = [
	$SafeArea/RootVBox/BodyHSplit/LeftPane/LeftMargin/LeftVBox/StorageGrid/StorageBtn1,
	$SafeArea/RootVBox/BodyHSplit/LeftPane/LeftMargin/LeftVBox/StorageGrid/StorageBtn2,
	$SafeArea/RootVBox/BodyHSplit/LeftPane/LeftMargin/LeftVBox/StorageGrid/StorageBtn3,
	$SafeArea/RootVBox/BodyHSplit/LeftPane/LeftMargin/LeftVBox/StorageGrid/StorageBtn4
]

@onready var context_title: Label = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/ContextCard/ContextMargin/ContextVBox/ContextTitle
@onready var i_info_label: Label = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/ContextCard/ContextMargin/ContextVBox/IInfoLabel
@onready var k_info_label: Label = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/ContextCard/ContextMargin/ContextVBox/KInfoLabel
@onready var task_label: Label = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/ContextCard/ContextMargin/ContextVBox/TaskLabel

@onready var calc_title: Label = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/CalcCard/CalcMargin/CalcVBox/CalcTitle
@onready var btn_minus: Button = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/CalcCard/CalcMargin/CalcVBox/IBitsRow/BtnMinus
@onready var i_bits_value_label: Label = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/CalcCard/CalcMargin/CalcVBox/IBitsRow/IBitsValue
@onready var btn_plus: Button = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/CalcCard/CalcMargin/CalcVBox/IBitsRow/BtnPlus
@onready var btn_check_calc: Button = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/CalcCard/CalcMargin/CalcVBox/BtnCheckCalc

@onready var preview_title: Label = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/PreviewCard/PreviewMargin/PreviewVBox/PreviewTitle
@onready var preview_calc_label: Label = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/PreviewCard/PreviewMargin/PreviewVBox/PreviewCalcLabel
@onready var preview_fit_label: Label = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/PreviewCard/PreviewMargin/PreviewVBox/PreviewFitLabel
@onready var preview_class_label: Label = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/PreviewCard/PreviewMargin/PreviewVBox/PreviewClassLabel

@onready var btn_converter: Button = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/ActionsRow/BtnConverter
@onready var btn_capture: Button = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/ActionsRow/BtnCapture
@onready var btn_next: Button = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/ActionsRow/BtnNext
@onready var sample_strip: HBoxContainer = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/SampleStrip
@onready var status_label: Label = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/StatusLabel
@onready var btn_details: Button = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/BtnDetails
@onready var footer_label: Label = $SafeArea/RootVBox/Footer/FooterMargin/FooterLabel

@onready var dimmer: ColorRect = $Dimmer
@onready var details_sheet: PanelContainer = $DetailsSheet
@onready var details_title: Label = $DetailsSheet/DetailsMargin/DetailsVBox/DetailsTitle
@onready var details_text: RichTextLabel = $DetailsSheet/DetailsMargin/DetailsVBox/DetailsText
@onready var btn_close_details: Button = $DetailsSheet/DetailsMargin/DetailsVBox/BtnCloseDetails

var phase: Phase = Phase.CALC
var i_bits: int = 7
var k_symbols: int = 0
var i_bits_true: int = 0
var i_bits_user: int = 0
var calc_checked: bool = false
var selected_storage_idx: int = -1
var storage_options: Array[Dictionary] = []
var used_converter: bool = false
var forced_sampling: bool = false
var is_timed: bool = false

var start_ms: int = 0
var first_action_ms: int = -1
var current_trial_idx: int = 0
var anchor_countdown: int = 0
var pool_type: String = "NORMAL"
var sample_refs: Array[Dictionary] = []

var _current_stability: float = 100.0
var _ui_ready: bool = false

func _ready() -> void:
	randomize()
	_apply_static_texts()
	_connect_signals()
	_collect_sample_refs()
	_reset_sample_strip()
	_set_details_visible(false)
	_apply_safe_area_padding()
	_configure_layout()

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

func _apply_static_texts() -> void:
	title_label.text = TXT_TITLE
	btn_back.text = TXT_BACK
	storage_title.text = TXT_STORAGE_TITLE
	context_title.text = TXT_CONTEXT_TITLE
	task_label.text = TXT_TASK
	calc_title.text = TXT_CALC_TITLE
	btn_minus.text = "-8"
	btn_plus.text = "+8"
	btn_check_calc.text = TXT_BTN_CHECK
	preview_title.text = TXT_PREVIEW_TITLE
	btn_converter.text = TXT_BTN_CONVERTER
	btn_capture.text = TXT_BTN_CONFIRM
	btn_next.text = TXT_BTN_NEXT
	btn_details.text = TXT_BTN_DETAILS_CLOSED
	details_title.text = TXT_DETAILS_TITLE
	btn_close_details.text = TXT_DETAILS_CLOSE

func _connect_signals() -> void:
	btn_back.pressed.connect(_on_back_pressed)
	btn_minus.pressed.connect(_on_minus_pressed)
	btn_plus.pressed.connect(_on_plus_pressed)
	btn_check_calc.pressed.connect(_on_check_calc_pressed)
	btn_converter.pressed.connect(_on_converter_pressed)
	btn_capture.pressed.connect(_on_capture_pressed)
	btn_next.pressed.connect(_on_next_pressed)
	btn_details.pressed.connect(_on_details_pressed)
	btn_close_details.pressed.connect(_on_details_close_pressed)
	dimmer.gui_input.connect(_on_dimmer_gui_input)

	for idx in range(storage_btns.size()):
		storage_btns[idx].pressed.connect(_on_storage_selected.bind(idx))

func _collect_sample_refs() -> void:
	sample_refs.clear()
	for child_var in sample_strip.get_children():
		var child_node: Node = child_var as Node
		var bg_node: ColorRect = child_node.get_node_or_null("BG") as ColorRect
		var mark_node: Label = child_node.get_node_or_null("AnchorMark") as Label
		if bg_node != null and mark_node != null:
			sample_refs.append({"bg": bg_node, "mark": mark_node})

func _reset_sample_strip() -> void:
	for slot_var in sample_refs:
		var slot: Dictionary = slot_var as Dictionary
		var bg: ColorRect = slot["bg"] as ColorRect
		var mark: Label = slot["mark"] as Label
		bg.color = COLOR_IDLE
		mark.visible = false
	current_trial_idx = 0

func _start_trial() -> void:
	phase = Phase.CALC
	calc_checked = false
	selected_storage_idx = -1
	used_converter = false
	i_bits_user = 0
	start_ms = Time.get_ticks_msec()
	first_action_ms = -1

	if anchor_countdown <= 0:
		k_symbols = POOL_ANCHOR.pick_random()
		pool_type = "ANCHOR"
		anchor_countdown = randi_range(7, 10)
	else:
		k_symbols = POOL_NORMAL.pick_random()
		pool_type = "NORMAL"
		anchor_countdown -= 1

	i_bits_true = k_symbols * i_bits
	_generate_storage_options()

	i_info_label.text = "i = %d \u0431\u0438\u0442" % i_bits
	k_info_label.text = "K = %d \u0441\u0438\u043c\u0432\u043e\u043b\u043e\u0432" % k_symbols
	i_bits_value_label.text = str(i_bits_user)
	i_bits_value_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))

	btn_minus.disabled = false
	btn_plus.disabled = false
	btn_check_calc.disabled = false
	btn_capture.disabled = true
	btn_capture.visible = true
	btn_next.visible = false

	for idx in range(storage_btns.size()):
		var btn: Button = storage_btns[idx]
		btn.disabled = true
		btn.button_pressed = false
		btn.text = _format_storage_option(storage_options[idx])
		btn.modulate = Color(1, 1, 1, 1)

	status_label.text = TXT_STATUS_PLAN
	status_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1.0))
	footer_label.text = ""
	_update_preview()
	_update_header_meta()
	_update_details_text()

func _generate_storage_options() -> void:
	storage_options.clear()

	var best_cap: int = 1
	while best_cap <= i_bits_true:
		best_cap *= 2
	if best_cap == i_bits_true:
		best_cap *= 2
	storage_options.append(_make_auto_option(best_cap, "BEST"))

	var under_cap: int = maxi(1, int(floor(float(i_bits_true) * 0.75)))
	storage_options.append(_make_auto_option(under_cap, "UNDER"))

	if i_bits_true % 8 == 0:
		storage_options.append({
			"capacity_bits": i_bits_true * 8,
			"display_size": i_bits_true,
			"display_unit": "\u0431\u0430\u0439\u0442",
			"tag": "UNIT_TRAP"
		})
	else:
		storage_options.append({
			"capacity_bits": i_bits_true * 8192,
			"display_size": i_bits_true,
			"display_unit": "\u041a\u0411",
			"tag": "UNIT_TRAP"
		})

	var over_cap: int = int(ceil((float(i_bits_true) * 4.0) / 100.0) * 100.0)
	storage_options.append(_make_auto_option(over_cap, "OVER"))

	storage_options.shuffle()

func _make_auto_option(capacity_bits: int, tag: String) -> Dictionary:
	var display_size: int = capacity_bits
	var display_unit: String = "\u0431\u0438\u0442"
	if capacity_bits >= 8192 and capacity_bits % 8192 == 0:
		display_size = capacity_bits / 8192
		display_unit = "\u041a\u0411"
	elif capacity_bits >= 8 and capacity_bits % 8 == 0:
		display_size = capacity_bits / 8
		display_unit = "\u0431\u0430\u0439\u0442"
	return {
		"capacity_bits": capacity_bits,
		"display_size": display_size,
		"display_unit": display_unit,
		"tag": tag
	}

func _format_storage_option(opt: Dictionary) -> String:
	return "%d %s" % [int(opt["display_size"]), str(opt["display_unit"])]

func _register_action() -> void:
	if first_action_ms < 0:
		first_action_ms = Time.get_ticks_msec()

func _on_minus_pressed() -> void:
	if phase != Phase.CALC:
		return
	_register_action()
	i_bits_user = maxi(0, i_bits_user - 8)
	i_bits_value_label.text = str(i_bits_user)
	_update_preview()
	_update_details_text()

func _on_plus_pressed() -> void:
	if phase != Phase.CALC:
		return
	_register_action()
	i_bits_user += 8
	i_bits_value_label.text = str(i_bits_user)
	_update_preview()
	_update_details_text()

func _on_check_calc_pressed() -> void:
	if phase != Phase.CALC:
		return
	_register_action()

	calc_checked = true
	phase = Phase.SELECT

	for btn in storage_btns:
		btn.disabled = false

	btn_minus.disabled = true
	btn_plus.disabled = true
	btn_check_calc.disabled = true

	if i_bits_user == i_bits_true:
		status_label.text = TXT_STATUS_CALC_OK
		status_label.add_theme_color_override("font_color", COLOR_GOOD)
		i_bits_value_label.add_theme_color_override("font_color", COLOR_GOOD)
	else:
		status_label.text = TXT_STATUS_CALC_WARN
		status_label.add_theme_color_override("font_color", COLOR_WARN)
		i_bits_value_label.add_theme_color_override("font_color", COLOR_WARN)

	_update_preview()
	_update_details_text()

func _on_storage_selected(idx: int) -> void:
	if phase != Phase.SELECT:
		return
	_register_action()

	selected_storage_idx = idx
	for i in range(storage_btns.size()):
		storage_btns[i].button_pressed = (i == idx)
		storage_btns[i].modulate = Color(1, 1, 0.75, 1) if i == idx else Color(1, 1, 1, 1)

	btn_capture.disabled = false
	_update_preview()
	_update_details_text()

func _on_converter_pressed() -> void:
	if phase == Phase.DONE:
		return
	_register_action()
	used_converter = true
	status_label.text = TXT_STATUS_CONVERTER % [i_bits_true, i_bits_true / 8]
	status_label.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0, 1.0))
	_update_preview()
	_update_details_text()

func _on_capture_pressed() -> void:
	if phase != Phase.SELECT or selected_storage_idx < 0:
		return
	_register_action()
	_finish_trial()

func _finish_trial() -> void:
	phase = Phase.DONE
	btn_capture.visible = false
	btn_next.visible = true

	var choice: Dictionary = storage_options[selected_storage_idx]
	var choice_cap: int = int(choice["capacity_bits"])
	var calc_correct: bool = (i_bits_user == i_bits_true)
	var is_fit: bool = choice_cap >= i_bits_true
	var is_best_fit: bool = false
	var is_overkill: bool = false
	var waste_ratio: float = 0.0
	if i_bits_true > 0:
		waste_ratio = float(choice_cap) / float(i_bits_true)

	var error_type: String = "unknown"
	if choice_cap < i_bits_true:
		error_type = "underfit"
	elif not calc_correct:
		error_type = "calc_wrong"
	elif str(choice["tag"]) == "UNIT_TRAP":
		error_type = "unit_confusion_bits_bytes"
	elif str(choice["tag"]) == "BEST":
		error_type = "best_fit"
		is_best_fit = true
	elif waste_ratio > 4.0:
		error_type = "overkill_hard"
		is_overkill = true
	else:
		error_type = "overkill_soft"
		is_overkill = true

	var valid_mastery: bool = (not used_converter) and calc_correct and is_best_fit

	if error_type == "best_fit":
		status_label.text = TXT_RESULT_BEST
		status_label.add_theme_color_override("font_color", COLOR_GOOD)
		_update_sample_slot(COLOR_GOOD)
	elif error_type == "underfit":
		status_label.text = TXT_RESULT_UNDER
		status_label.add_theme_color_override("font_color", COLOR_BAD)
		_update_sample_slot(COLOR_BAD)
	elif error_type == "calc_wrong":
		status_label.text = TXT_RESULT_CALC
		status_label.add_theme_color_override("font_color", COLOR_BAD)
		_update_sample_slot(COLOR_BAD)
	elif error_type == "unit_confusion_bits_bytes":
		status_label.text = TXT_RESULT_UNIT
		status_label.add_theme_color_override("font_color", COLOR_WARN)
		_update_sample_slot(COLOR_WARN)
	else:
		status_label.text = TXT_RESULT_OVER
		status_label.add_theme_color_override("font_color", COLOR_WARN)
		_update_sample_slot(COLOR_WARN)

	var payload: Dictionary = {
		"quest_id": "radio_intercept",
		"stage_id": "B",
		"match_key": "RI_B_%s" % ("TIMED" if is_timed else "UNTIMED"),
		"pool_type": pool_type,
		"dependency_mode": "default_i",
		"i_bits": i_bits,
		"K_symbols": k_symbols,
		"I_bits_true": i_bits_true,
		"I_bits_user": i_bits_user,
		"calc_correct": calc_correct,
		"used_converter": used_converter,
		"choice_capacity_bits": choice_cap,
		"choice_display_size": int(choice["display_size"]),
		"choice_display_unit": str(choice["display_unit"]),
		"is_fit": is_fit,
		"is_best_fit": is_best_fit,
		"is_overkill": is_overkill,
		"waste_ratio": waste_ratio,
		"error_type": error_type,
		"valid_for_mastery": valid_mastery,
		"valid_for_diagnostics": true,
		"elapsed_ms": Time.get_ticks_msec() - start_ms,
		"time_to_first_action_ms": (first_action_ms - start_ms) if first_action_ms > 0 else 0,
		"is_timed": is_timed,
		"forced_sampling": forced_sampling
	}
	GlobalMetrics.register_trial(payload)

	_update_preview()
	_update_details_text()

func _update_sample_slot(color: Color) -> void:
	if sample_refs.is_empty():
		return
	var slot: Dictionary = sample_refs[current_trial_idx] as Dictionary
	var bg: ColorRect = slot["bg"] as ColorRect
	var mark: Label = slot["mark"] as Label
	bg.color = color
	mark.visible = pool_type == "ANCHOR"
	current_trial_idx = (current_trial_idx + 1) % min(SAMPLE_SLOTS, sample_refs.size())

func _update_preview() -> void:
	if i_bits_user <= 0:
		preview_calc_label.text = "\u0420\u0430\u0441\u0447\u0451\u0442 I: \u043d\u0435 \u0432\u044b\u043f\u043e\u043b\u043d\u0435\u043d"
		preview_calc_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 1.0))
	elif i_bits_user == i_bits_true:
		preview_calc_label.text = "\u0420\u0430\u0441\u0447\u0451\u0442 I: \u0432\u0435\u0440\u043d\u043e (%d \u0431\u0438\u0442)" % i_bits_true
		preview_calc_label.add_theme_color_override("font_color", COLOR_GOOD)
	else:
		preview_calc_label.text = "\u0420\u0430\u0441\u0447\u0451\u0442 I: \u043e\u0442\u043a\u043b\u043e\u043d\u0435\u043d\u0438\u0435 (%d vs %d)" % [i_bits_user, i_bits_true]
		preview_calc_label.add_theme_color_override("font_color", COLOR_WARN)

	if selected_storage_idx < 0:
		preview_fit_label.text = "\u041d\u043e\u0441\u0438\u0442\u0435\u043b\u044c: \u043d\u0435 \u0432\u044b\u0431\u0440\u0430\u043d"
		preview_class_label.text = "\u041a\u043b\u0430\u0441\u0441: \u2014"
		preview_fit_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 1.0))
		preview_class_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 1.0))
		return

	var opt: Dictionary = storage_options[selected_storage_idx]
	var cap: int = int(opt["capacity_bits"])
	var tag: String = str(opt["tag"])

	if cap < i_bits_true:
		preview_fit_label.text = "\u041d\u043e\u0441\u0438\u0442\u0435\u043b\u044c: \u043d\u0435 \u043f\u043e\u043c\u0435\u0449\u0430\u0435\u0442"
		preview_fit_label.add_theme_color_override("font_color", COLOR_BAD)
		preview_class_label.text = "\u041a\u043b\u0430\u0441\u0441: UNDERFIT"
		preview_class_label.add_theme_color_override("font_color", COLOR_BAD)
	elif tag == "BEST":
		preview_fit_label.text = "\u041d\u043e\u0441\u0438\u0442\u0435\u043b\u044c: \u043f\u043e\u0434\u0445\u043e\u0434\u0438\u0442"
		preview_fit_label.add_theme_color_override("font_color", COLOR_GOOD)
		preview_class_label.text = "\u041a\u043b\u0430\u0441\u0441: BEST FIT"
		preview_class_label.add_theme_color_override("font_color", COLOR_GOOD)
	elif tag == "UNIT_TRAP":
		preview_fit_label.text = "\u041d\u043e\u0441\u0438\u0442\u0435\u043b\u044c: \u043f\u0440\u043e\u0432\u0435\u0440\u044c\u0442\u0435 \u0435\u0434\u0438\u043d\u0438\u0446\u044b"
		preview_fit_label.add_theme_color_override("font_color", COLOR_WARN)
		preview_class_label.text = "\u041a\u043b\u0430\u0441\u0441: UNIT CONFUSION"
		preview_class_label.add_theme_color_override("font_color", COLOR_WARN)
	elif cap >= i_bits_true * 4:
		preview_fit_label.text = "\u041d\u043e\u0441\u0438\u0442\u0435\u043b\u044c: \u043f\u043e\u0434\u0445\u043e\u0434\u0438\u0442"
		preview_fit_label.add_theme_color_override("font_color", COLOR_WARN)
		preview_class_label.text = "\u041a\u043b\u0430\u0441\u0441: OVERKILL"
		preview_class_label.add_theme_color_override("font_color", COLOR_WARN)
	else:
		preview_fit_label.text = "\u041d\u043e\u0441\u0438\u0442\u0435\u043b\u044c: \u043f\u043e\u0434\u0445\u043e\u0434\u0438\u0442"
		preview_fit_label.add_theme_color_override("font_color", COLOR_WARN)
		preview_class_label.text = "\u041a\u043b\u0430\u0441\u0441: SOFT OVERKILL"
		preview_class_label.add_theme_color_override("font_color", COLOR_WARN)

func _update_details_text() -> void:
	var lines: Array[String] = []
	lines.append("i: %d" % i_bits)
	lines.append("K: %d" % k_symbols)
	lines.append("I_true: %d" % i_bits_true)
	lines.append("I_user: %d" % i_bits_user)
	lines.append("pool: %s" % pool_type)
	if selected_storage_idx >= 0:
		var opt: Dictionary = storage_options[selected_storage_idx]
		lines.append("choice: %d %s" % [int(opt["display_size"]), str(opt["display_unit"])])
		lines.append("choice_bits: %d" % int(opt["capacity_bits"]))
	if used_converter:
		lines.append("converter: used")
	details_text.text = "\n".join(lines)

func _on_next_pressed() -> void:
	_start_trial()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _on_details_pressed() -> void:
	_set_details_visible(true)

func _on_details_close_pressed() -> void:
	_set_details_visible(false)

func _on_dimmer_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		_set_details_visible(false)

func _set_details_visible(visible: bool) -> void:
	details_sheet.visible = visible
	dimmer.visible = visible
	btn_details.text = TXT_BTN_DETAILS_OPEN if visible else TXT_BTN_DETAILS_CLOSED

func _update_header_meta() -> void:
	var mode_text: String = "\u0411\u0415\u0417 \u0422\u0410\u0419\u041c\u0415\u0420\u0410"
	meta_label.text = "\u0420\u0415\u0416\u0418\u041c: %s | \u0421\u0422\u0410\u0411: %d%%" % [mode_text, int(_current_stability)]

func _on_stability_changed(new_value: float, _delta: float) -> void:
	_current_stability = new_value
	_update_header_meta()

func _apply_safe_area_padding() -> void:
	var left: float = 16.0
	var top: float = 12.0
	var right: float = 16.0
	var bottom: float = 12.0

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

func _configure_layout() -> void:
	var size: Vector2 = get_viewport_rect().size
	var phone_landscape: bool = size.x > size.y and size.y <= PHONE_LANDSCAPE_MAX_HEIGHT

	if phone_landscape:
		body_split.split_offset = int(size.x * 0.52)
		root_vbox.add_theme_constant_override("separation", 8)
		storage_grid.columns = 2
		for btn in storage_btns:
			btn.custom_minimum_size.y = 80
		for btn in [btn_back, btn_minus, btn_plus, btn_check_calc, btn_converter, btn_capture, btn_next, btn_details, btn_close_details]:
			btn.custom_minimum_size.y = 56
		meta_label.add_theme_font_size_override("font_size", 16)
		status_label.add_theme_font_size_override("font_size", 16)
	elif size.x < 1280.0:
		body_split.split_offset = int(size.x * 0.54)
		root_vbox.add_theme_constant_override("separation", 10)
		storage_grid.columns = 2
		for btn in storage_btns:
			btn.custom_minimum_size.y = 88
		for btn in [btn_back, btn_minus, btn_plus, btn_check_calc, btn_converter, btn_capture, btn_next, btn_details, btn_close_details]:
			btn.custom_minimum_size.y = 58
		meta_label.add_theme_font_size_override("font_size", 17)
		status_label.add_theme_font_size_override("font_size", 18)
	else:
		body_split.split_offset = int(size.x * 0.55)
		root_vbox.add_theme_constant_override("separation", 10)
		storage_grid.columns = 2
		for btn in storage_btns:
			btn.custom_minimum_size.y = 92
		for btn in [btn_back, btn_minus, btn_plus, btn_check_calc, btn_converter, btn_capture, btn_next, btn_details, btn_close_details]:
			btn.custom_minimum_size.y = 58
		meta_label.add_theme_font_size_override("font_size", 18)
		status_label.add_theme_font_size_override("font_size", 18)
