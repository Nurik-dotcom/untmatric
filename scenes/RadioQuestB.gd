extends Control

enum Phase {
	CALC,
	SELECT,
	RESULT
}

const RadioLevels := preload("res://scripts/radio_intercept/RadioLevels.gd")

const FALLBACK_POOL_NORMAL: Array[int] = [64, 80, 100, 128, 256, 512, 1024]
const FALLBACK_POOL_ANCHOR: Array[int] = [75, 110, 125, 300, 750, 1000]
const FALLBACK_CAPACITY_STEPS_BITS: Array[int] = [128, 256, 512, 1024, 2048, 4096, 8192, 16384]
const FALLBACK_ANSWER_MODES: Array[String] = ["bits", "bytes"]
const SAMPLE_SLOTS: int = 7
const PHONE_LANDSCAPE_MAX_HEIGHT: float = 520.0
const PHONE_PORTRAIT_MAX_WIDTH: float = 900.0
const COMPACT_STACK_MAX_HEIGHT: float = 820.0
const COMPACT_STACK_MAX_WIDTH: float = 1500.0
const CONVERTER_LOCK_SECONDS: float = 3.0
const CONVERTER_COOLDOWN_SECONDS: float = 6.0

const COLOR_IDLE: Color = Color(0.18, 0.18, 0.18, 1.0)
const COLOR_GOOD: Color = Color(0.20, 0.90, 0.30, 1.0)
const COLOR_WARN: Color = Color(0.95, 0.75, 0.20, 1.0)
const COLOR_BAD: Color = Color(0.95, 0.25, 0.25, 1.0)



@onready var safe_area: MarginContainer = $SafeArea
@onready var root_vbox: VBoxContainer = $SafeArea/RootVBox
@onready var body_split: HSplitContainer = $SafeArea/RootVBox/BodyHSplit
@onready var left_pane: PanelContainer = $SafeArea/RootVBox/BodyHSplit/LeftPane
@onready var right_pane: PanelContainer = $SafeArea/RootVBox/BodyHSplit/RightPane
@onready var right_margin: MarginContainer = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin
@onready var right_vbox: VBoxContainer = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox
@onready var storage_grid: GridContainer = $SafeArea/RootVBox/BodyHSplit/LeftPane/LeftMargin/LeftVBox/StorageGrid

@onready var header_panel: PanelContainer = $SafeArea/RootVBox/Header
@onready var btn_back: Button = $SafeArea/RootVBox/Header/HeaderHBox/BtnBack
@onready var title_label: Label = $SafeArea/RootVBox/Header/HeaderHBox/TitleLabel
@onready var meta_label: Label = $SafeArea/RootVBox/Header/HeaderHBox/MetaLabel

@onready var storage_title: Label = $SafeArea/RootVBox/BodyHSplit/LeftPane/LeftMargin/LeftVBox/StorageTitle
@onready var storage_btns: Array[Button] = [
	$SafeArea/RootVBox/BodyHSplit/LeftPane/LeftMargin/LeftVBox/StorageGrid/StorageBtn1,
	$SafeArea/RootVBox/BodyHSplit/LeftPane/LeftMargin/LeftVBox/StorageGrid/StorageBtn2,
	$SafeArea/RootVBox/BodyHSplit/LeftPane/LeftMargin/LeftVBox/StorageGrid/StorageBtn3,
	$SafeArea/RootVBox/BodyHSplit/LeftPane/LeftMargin/LeftVBox/StorageGrid/StorageBtn4,
	$SafeArea/RootVBox/BodyHSplit/LeftPane/LeftMargin/LeftVBox/StorageGrid/StorageBtn5,
	$SafeArea/RootVBox/BodyHSplit/LeftPane/LeftMargin/LeftVBox/StorageGrid/StorageBtn6
]

@onready var context_title: Label = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/ContextCard/ContextMargin/ContextVBox/ContextTitle
@onready var i_info_label: Label = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/ContextCard/ContextMargin/ContextVBox/IInfoLabel
@onready var k_info_label: Label = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/ContextCard/ContextMargin/ContextVBox/KInfoLabel
@onready var task_label: Label = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/ContextCard/ContextMargin/ContextVBox/TaskLabel
@onready var context_card: PanelContainer = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/ContextCard

@onready var calc_title: Label = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/CalcCard/CalcMargin/CalcVBox/CalcTitle
@onready var btn_minus: Button = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/CalcCard/CalcMargin/CalcVBox/IBitsRow/BtnMinus
@onready var i_bits_value_label: Label = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/CalcCard/CalcMargin/CalcVBox/IBitsRow/IBitsValue
@onready var btn_plus: Button = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/CalcCard/CalcMargin/CalcVBox/IBitsRow/BtnPlus
@onready var btn_check_calc: Button = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/CalcCard/CalcMargin/CalcVBox/BtnCheckCalc
@onready var calc_card: PanelContainer = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/CalcCard
@onready var btn_toggle_calc: Button = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/BtnToggleCalc

@onready var preview_title: Label = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/PreviewCard/PreviewMargin/PreviewVBox/PreviewTitle
@onready var preview_calc_label: Label = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/PreviewCard/PreviewMargin/PreviewVBox/PreviewCalcLabel
@onready var preview_fit_label: Label = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/PreviewCard/PreviewMargin/PreviewVBox/PreviewFitLabel
@onready var preview_class_label: Label = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/PreviewCard/PreviewMargin/PreviewVBox/PreviewClassLabel
@onready var preview_card: PanelContainer = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/PreviewCard

@onready var btn_converter: Button = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/ActionsRow/BtnConverter
@onready var noir_overlay: CanvasLayer = $NoirOverlay
@onready var btn_capture: Button = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/ActionsRow/BtnCapture
@onready var btn_next: Button = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/NextRow/BtnNext
@onready var sample_strip: HBoxContainer = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/SampleStrip
@onready var status_label: Label = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/StatusLabel
@onready var btn_details: Button = $SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/BtnDetails
@onready var footer_label: Label = get_node_or_null("SafeArea/RootVBox/Footer/FooterMargin/FooterLabel") as Label

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
var converter_lock_active: bool = false
var converter_lock_until: float = 0.0
var converter_cooldown_until: float = 0.0
var converter_use_count: int = 0
var input_buffer: String = ""
var numpad_grid: GridContainer
var answer_unit_mode: String = "bits"
var answer_in_bytes: bool = false
var answer_unit_toggle: CheckButton
var answer_unit_banner_label: Label
var dependency_mode: String = "default_i"

var _pool_normal: Array[int] = []
var _pool_anchor: Array[int] = []
var _capacity_steps_bits: Array[int] = []
var _answer_unit_modes: Array[String] = []
var _anchor_every_min: int = 7
var _anchor_every_max: int = 10

var _current_stability: float = 100.0
var _ui_ready: bool = false
var _right_scroll_installed: bool = false
var _calc_panel_expanded: bool = false
var _status_i18n_key: String = ""
var _status_i18n_default: String = ""
var _status_i18n_params: Dictionary = {}
var _status_i18n_color: Color = Color(0.85, 0.85, 0.85, 1.0)

func _ready() -> void:
	randomize()
	_ensure_fullscreen_layout()
	_install_right_scroll()
	_load_level_config()
	_apply_i18n()
	if not I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.connect(_on_language_changed)
	_connect_signals()
	_configure_text_overflow()
	_install_numpad()
	btn_toggle_calc.visible = false
	_set_calc_panel_visible(true)
	_collect_sample_refs()
	_reset_sample_strip()
	_set_details_visible(false)
	_apply_safe_area_padding()
	_configure_layout()

	if not GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.connect(_on_stability_changed)
	_on_stability_changed(GlobalMetrics.stability, 0.0)

	anchor_countdown = _random_anchor_gap()
	_start_trial()
	_ui_ready = true

func _exit_tree() -> void:
	if I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.disconnect(_on_language_changed)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _ui_ready:
		_ensure_fullscreen_layout()
		_apply_safe_area_padding()
		_configure_layout()

func _process(_delta: float) -> void:
	var now_sec: float = Time.get_ticks_msec() / 1000.0
	if converter_lock_active:
		var left: float = maxf(0.0, converter_lock_until - now_sec)
		_set_status_i18n(
			"quest.radio.b.status.converter_locked",
			"STATUS: converter unavailable {left}s",
			COLOR_WARN,
			{"left": "%.1f" % left}
		)
		if now_sec < converter_lock_until:
			return
		converter_lock_active = false
		_apply_phase_controls()
		_set_status_i18n(
			"quest.radio.b.status.converter",
			"STATUS: hint: I = K * i; for bytes divide by 8.",
			Color(0.55, 0.85, 1.0, 1.0)
		)
		return

	if phase != Phase.RESULT:
		var cooldown_active: bool = now_sec < converter_cooldown_until
		if btn_converter.disabled != cooldown_active:
			_apply_phase_controls()
func _tr(key: String, default_text: String, params: Dictionary = {}) -> String:
	var merged: Dictionary = params.duplicate(true)
	merged["default"] = default_text
	return I18n.get_text(key, merged)

func _configure_text_overflow() -> void:
	for lbl in [task_label, preview_calc_label, preview_fit_label, preview_class_label, status_label]:
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	for btn in [btn_converter, btn_capture, btn_next, btn_toggle_calc, btn_details]:
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _apply_i18n() -> void:
	title_label.text = _tr("quest.radio.b.ui.title", "RADIO INTERCEPT | B")
	btn_back.text = _tr("quest.radio.common.btn.back", "BACK")
	storage_title.text = _tr("quest.radio.b.ui.storage_title", "STORAGE INVENTORY")
	context_title.text = _tr("quest.radio.b.ui.context_title", "TERMINAL")
	calc_title.text = _tr("quest.radio.b.ui.calc_title", "CALC I")
	btn_minus.text = "-8"
	btn_plus.text = "+8"
	btn_check_calc.text = _tr("quest.radio.b.ui.btn_check", "ENTER")
	preview_title.text = _tr("quest.radio.b.ui.preview_title", "DIAGNOSTICS")
	btn_converter.text = _tr("quest.radio.b.ui.btn_converter", "CONVERTER")
	btn_capture.text = _tr("quest.radio.btn.capture", "CAPTURE")
	btn_next.text = _tr("quest.radio.common.btn.next", "NEXT")
	btn_details.text = _tr("quest.radio.common.btn.details_open", "DETAILS v")
	details_title.text = _tr("quest.radio.b.ui.details_title", "EXPLANATION")
	btn_close_details.text = _tr("quest.radio.common.btn.details_close", "CLOSE")
	btn_toggle_calc.text = _tr("quest.radio.b.ui.btn_calc_close", "HIDE CALC TERMINAL") if _calc_panel_expanded else _tr("quest.radio.b.ui.btn_calc_open", "OPEN CALC TERMINAL")
	_refresh_dynamic_i18n()

func _refresh_dynamic_i18n() -> void:
	if k_symbols > 0:
		task_label.text = _build_task_text()
		i_info_label.text = _tr("quest.radio.b.ui.info_i", "i = {i} bit", {"i": i_bits})
		k_info_label.text = _tr("quest.radio.b.ui.info_k", "K = {k} chars", {"k": k_symbols})
	else:
		task_label.text = _tr("quest.radio.b.task", "Message length: %d chars. Calculate size (I=K*i) and select drive.") % 0
	for idx in range(storage_btns.size()):
		if idx < storage_options.size():
			storage_btns[idx].text = _format_storage_option(storage_options[idx])
	_update_required_unit_ui()
	_update_preview()
	_update_details_text()
	_update_header_meta()
	_apply_status_i18n()

func _on_language_changed(_code: String) -> void:
	_apply_i18n()

func _set_status_i18n(key: String, default_text: String, color: Color, params: Dictionary = {}) -> void:
	_status_i18n_key = key
	_status_i18n_default = default_text
	_status_i18n_params = params.duplicate(true)
	_status_i18n_color = color
	_apply_status_i18n()

func _apply_status_i18n() -> void:
	if _status_i18n_key.is_empty():
		return
	status_label.text = _tr(_status_i18n_key, _status_i18n_default, _status_i18n_params)
	status_label.add_theme_color_override("font_color", _status_i18n_color)

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
	btn_toggle_calc.pressed.connect(_on_toggle_calc_pressed)
	dimmer.gui_input.connect(_on_dimmer_gui_input)

	for idx in range(storage_btns.size()):
		storage_btns[idx].pressed.connect(_on_storage_selected.bind(idx))

func _install_numpad() -> void:
	var calc_vbox: VBoxContainer = btn_check_calc.get_parent() as VBoxContainer
	if calc_vbox == null:
		return
	btn_minus.visible = false
	btn_plus.visible = false

	answer_unit_banner_label = Label.new()
	answer_unit_banner_label.name = "AnswerUnitBanner"
	answer_unit_banner_label.text = _tr("quest.radio.b.ui.required_bits", "ANSWER UNIT: BITS")
	answer_unit_banner_label.theme = theme
	answer_unit_banner_label.add_theme_font_size_override("font_size", 18)
	answer_unit_banner_label.add_theme_color_override("font_color", Color(0.95, 0.90, 0.45, 1.0))
	answer_unit_banner_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	calc_vbox.add_child(answer_unit_banner_label)

	answer_unit_toggle = CheckButton.new()
	answer_unit_toggle.name = "AnswerUnitToggle"
	answer_unit_toggle.text = _tr("quest.radio.b.ui.toggle_bytes", "Answer in BYTES (/8)")
	answer_unit_toggle.custom_minimum_size = Vector2(0.0, 56.0)
	answer_unit_toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	answer_unit_toggle.toggled.connect(_on_answer_unit_toggled)
	calc_vbox.add_child(answer_unit_toggle)

	numpad_grid = GridContainer.new()
	numpad_grid.name = "NumpadGrid"
	numpad_grid.columns = 3
	numpad_grid.custom_minimum_size = Vector2(0.0, 220.0)
	numpad_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	numpad_grid.theme = theme
	numpad_grid.add_theme_constant_override("h_separation", 8)
	numpad_grid.add_theme_constant_override("v_separation", 8)

	var keys: Array[String] = ["7", "8", "9", "4", "5", "6", "1", "2", "3", "C", "0", "ENTER"]
	for key in keys:
		var btn: Button = Button.new()
		btn.text = key
		btn.custom_minimum_size = Vector2(0.0, 56.0)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_on_numpad_pressed.bind(key))
		numpad_grid.add_child(btn)

	calc_vbox.add_child(numpad_grid)
	calc_vbox.move_child(numpad_grid, calc_vbox.get_child_count() - 1)

func _on_toggle_calc_pressed() -> void:
	_set_calc_panel_visible(not _calc_panel_expanded)

func _set_calc_panel_visible(is_visible: bool) -> void:
	_calc_panel_expanded = is_visible
	calc_card.visible = is_visible
	btn_toggle_calc.text = _tr("quest.radio.b.ui.btn_calc_close", "HIDE CALC TERMINAL") if is_visible else _tr("quest.radio.b.ui.btn_calc_open", "OPEN CALC TERMINAL")

func _on_answer_unit_toggled(pressed: bool) -> void:
	if phase != Phase.CALC or converter_lock_active:
		if answer_unit_toggle != null:
			answer_unit_toggle.set_pressed_no_signal(answer_in_bytes)
		return
	if answer_unit_mode == "bits":
		if answer_unit_toggle != null:
			answer_unit_toggle.set_pressed_no_signal(false)
		answer_in_bytes = false
		return
	_register_action()
	answer_in_bytes = pressed
	_update_preview()
	_update_details_text()

func _on_numpad_pressed(key: String) -> void:
	if phase != Phase.CALC or converter_lock_active:
		return
	match key:
		"C":
			_register_action()
			input_buffer = ""
		"ENTER":
			_on_check_calc_pressed()
			return
		_:
			_register_action()
			if input_buffer.length() < 9:
				input_buffer += key
	_sync_input_buffer()

func _sync_input_buffer() -> void:
	if input_buffer.is_empty():
		i_bits_user = 0
	else:
		i_bits_user = input_buffer.to_int()
	i_bits_value_label.text = str(i_bits_user)
	_update_preview()
	_update_details_text()

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

func _resolve_i_bits_from_stage_a() -> Dictionary:
	for idx in range(GlobalMetrics.session_history.size() - 1, -1, -1):
		var entry: Variant = GlobalMetrics.session_history[idx]
		if not (entry is Dictionary):
			continue
		var row: Dictionary = entry as Dictionary
		if str(row.get("stage_id", "")) != "A":
			continue
		if not bool(row.get("is_fit", false)):
			continue
		var chosen_raw: Variant = row.get("chosen_i", null)
		if chosen_raw == null:
			continue
		var chosen_i: int = int(chosen_raw)
		if chosen_i > 0:
			return {"i_bits": chosen_i, "dependency_mode": "from_stage_a"}
	return {"i_bits": 7, "dependency_mode": "default_i"}

func _pick_k_for_trial(pool: Array[int]) -> int:
	if pool.is_empty():
		return 1
	if answer_unit_mode != "bytes":
		return pool[randi() % pool.size()]
	var solvable_pool: Array[int] = []
	for k_val in pool:
		if (k_val * i_bits) % 8 == 0:
			solvable_pool.append(k_val)
	if not solvable_pool.is_empty():
		return solvable_pool[randi() % solvable_pool.size()]
	answer_unit_mode = "bits"
	return pool[randi() % pool.size()]

func _update_required_unit_ui() -> void:
	var needs_bytes: bool = answer_unit_mode == "bytes"
	if answer_unit_banner_label != null:
		answer_unit_banner_label.text = _tr("quest.radio.b.ui.required_bytes", "ANSWER UNIT: BYTES") if needs_bytes else _tr("quest.radio.b.ui.required_bits", "ANSWER UNIT: BITS")
		answer_unit_banner_label.add_theme_color_override(
			"font_color",
			Color(0.95, 0.90, 0.45, 1.0) if needs_bytes else Color(0.75, 0.85, 1.0, 1.0)
		)
	if answer_unit_toggle != null:
		answer_unit_toggle.visible = true
		answer_unit_toggle.text = _tr("quest.radio.b.ui.toggle_bytes", "Answer in BYTES (/8)")
		if not needs_bytes:
			answer_in_bytes = false
			answer_unit_toggle.set_pressed_no_signal(false)

func _start_trial() -> void:
	phase = Phase.CALC
	calc_checked = false
	selected_storage_idx = -1
	_set_calc_panel_visible(true)
	used_converter = false
	converter_use_count = 0
	input_buffer = ""
	converter_lock_active = false
	converter_lock_until = 0.0
	converter_cooldown_until = 0.0
	i_bits_user = 0
	answer_unit_mode = _pick_answer_unit_mode()
	answer_in_bytes = false
	if answer_unit_toggle != null:
		answer_unit_toggle.set_pressed_no_signal(false)
	start_ms = Time.get_ticks_msec()
	first_action_ms = -1
	var dependency_data: Dictionary = _resolve_i_bits_from_stage_a()
	i_bits = maxi(1, int(dependency_data.get("i_bits", 7)))
	dependency_mode = str(dependency_data.get("dependency_mode", "default_i"))

	var source_pool: Array[int] = []
	if anchor_countdown <= 0:
		source_pool = _pool_anchor.duplicate()
		if source_pool.is_empty():
			source_pool.append_array(FALLBACK_POOL_ANCHOR)
		k_symbols = _pick_k_for_trial(source_pool)
		pool_type = "ANCHOR"
		anchor_countdown = _random_anchor_gap()
	else:
		source_pool = _pool_normal.duplicate()
		if source_pool.is_empty():
			source_pool.append_array(FALLBACK_POOL_NORMAL)
		k_symbols = _pick_k_for_trial(source_pool)
		pool_type = "NORMAL"
		anchor_countdown -= 1

	i_bits_true = k_symbols * i_bits
	_generate_storage_options()
	_normalize_storage_options(i_bits_true)
	_update_required_unit_ui()

	task_label.text = _build_task_text()
	i_info_label.text = _tr("quest.radio.b.ui.info_i", "i = {i} bit", {"i": i_bits})
	k_info_label.text = _tr("quest.radio.b.ui.info_k", "K = {k} chars", {"k": k_symbols})
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
		var opt: Dictionary = storage_options[idx] if idx < storage_options.size() else _make_auto_option(i_bits_true, "OVER", "fallback")
		btn.text = _format_storage_option(opt)
		btn.modulate = Color(1, 1, 1, 1)
	_apply_phase_controls()

	_set_status_i18n(
		"quest.radio.b.status.plan",
		"STATUS: enter I and press ENTER.",
		Color(0.85, 0.85, 0.85, 1.0)
	)
	if footer_label != null:
		footer_label.text = ""
	_update_preview()
	_update_header_meta()
	_update_details_text()

func _generate_storage_options() -> void:
	storage_options.clear()

	var best_cap: int = _find_best_fit_cap(i_bits_true)
	var under_near_cap: int = _find_underfit_cap(i_bits_true)
	var under_far_cap: int = _find_underfit_far_cap(i_bits_true, under_near_cap)
	var over_far_cap: int = _find_overkill_cap(best_cap, i_bits_true)
	var over_near_cap: int = _find_over_near_cap(best_cap, i_bits_true, over_far_cap)

	storage_options.append(_make_auto_option(best_cap, "BEST", "main"))
	storage_options.append(_make_auto_option(under_near_cap, "UNDER", "near"))
	storage_options.append(_make_auto_option(under_far_cap, "UNDER", "far"))

	if answer_unit_mode == "bytes":
		var true_bytes: int = i_bits_true / 8
		storage_options.append(_make_manual_option(true_bytes, true_bytes, "bit", "UNIT_TRAP", "unit"))
	else:
		storage_options.append(_make_manual_option(i_bits_true * 8, i_bits_true, "byte", "UNIT_TRAP", "unit"))

	storage_options.append(_make_auto_option(over_near_cap, "OVER", "near"))
	storage_options.append(_make_auto_option(over_far_cap, "OVER", "far"))

	_ensure_unique_storage_options(i_bits_true)
	storage_options.shuffle()

func _make_auto_option(capacity_bits: int, tag: String, variant: String = "") -> Dictionary:
	var display_size: int = capacity_bits
	var display_unit: String = "bit"
	if capacity_bits >= 8192 and capacity_bits % 8192 == 0:
		display_size = capacity_bits / 8192
		display_unit = "KB"
	elif capacity_bits >= 8 and capacity_bits % 8 == 0:
		display_size = capacity_bits / 8
		display_unit = "byte"
	return {
		"capacity_bits": capacity_bits,
		"display_size": display_size,
		"display_unit": display_unit,
		"tag": tag,
		"variant": variant
	}

func _make_manual_option(
	capacity_bits: int,
	display_size: int,
	display_unit: String,
	tag: String,
	variant: String = ""
) -> Dictionary:
	return {
		"capacity_bits": maxi(1, capacity_bits),
		"display_size": maxi(1, display_size),
		"display_unit": display_unit,
		"tag": tag,
		"variant": variant
	}

func _normalize_storage_options(required_bits: int) -> void:
	var target_count: int = storage_btns.size()
	if target_count <= 0:
		storage_options.clear()
		return
	while storage_options.size() > target_count:
		storage_options.pop_back()
	while storage_options.size() < target_count:
		var fallback_best: int = _find_best_fit_cap(required_bits)
		var fallback_cap: int = _find_overkill_cap(fallback_best, required_bits) + storage_options.size() * 8
		storage_options.append(_make_auto_option(fallback_cap, "OVER", "fallback"))
	_ensure_unique_storage_options(required_bits)

func _ensure_unique_storage_options(required_bits: int) -> void:
	var seen_labels: Dictionary = {}
	var near_under_limit: int = maxi(1, _find_underfit_cap(required_bits) - 1)
	for idx in range(storage_options.size()):
		var option: Dictionary = storage_options[idx]
		var label: String = _format_storage_option(option)
		var guard: int = 0
		while seen_labels.has(label) and guard < 12:
			guard += 1
			var tag: String = str(option.get("tag", ""))
			var variant: String = str(option.get("variant", ""))
			if tag == "OVER":
				var current_over: int = int(option.get("capacity_bits", required_bits))
				if variant == "far":
					var far_cap: int = maxi(current_over * 2, required_bits * 4)
					option = _make_auto_option(far_cap, "OVER", variant)
				else:
					var near_cap: int = maxi(required_bits, current_over + maxi(1, required_bits / 8))
					var near_ceiling: int = maxi(required_bits, required_bits * 4 - 1)
					option = _make_auto_option(mini(near_cap, near_ceiling), "OVER", variant)
			elif tag == "UNDER":
				var current_under: int = int(option.get("capacity_bits", required_bits - 1))
				var lowered_under: int = maxi(1, current_under - maxi(1, required_bits / 10))
				lowered_under = mini(lowered_under, required_bits - 1)
				if variant == "far":
					lowered_under = mini(lowered_under, near_under_limit)
				option = _make_auto_option(lowered_under, "UNDER", variant)
			elif tag == "UNIT_TRAP":
				option["display_size"] = int(option.get("display_size", 1)) + 1
			else:
				option["capacity_bits"] = int(option.get("capacity_bits", 1)) + 1
				option["display_size"] = int(option.get("display_size", 1)) + 1
			label = _format_storage_option(option)
		seen_labels[label] = true
		storage_options[idx] = option

func _format_storage_option(opt: Dictionary) -> String:
	var unit_token: String = str(opt["display_unit"])
	var unit_text: String = unit_token
	match unit_token:
		"bit":
			unit_text = _tr("quest.radio.common.unit.bit", "bit")
		"byte":
			unit_text = _tr("quest.radio.common.unit.byte", "byte")
		"KB":
			unit_text = _tr("quest.radio.common.unit.kb", "KB")
	return "%d %s" % [int(opt["display_size"]), unit_text]

func _register_action() -> void:
	if first_action_ms < 0:
		first_action_ms = Time.get_ticks_msec()

func _on_minus_pressed() -> void:
	if phase != Phase.CALC or converter_lock_active:
		return
	_register_action()
	i_bits_user = maxi(0, i_bits_user - 8)
	input_buffer = str(i_bits_user)
	i_bits_value_label.text = str(i_bits_user)
	_update_preview()
	_update_details_text()

func _on_plus_pressed() -> void:
	if phase != Phase.CALC or converter_lock_active:
		return
	_register_action()
	i_bits_user += 8
	input_buffer = str(i_bits_user)
	i_bits_value_label.text = str(i_bits_user)
	_update_preview()
	_update_details_text()

func _on_check_calc_pressed() -> void:
	if phase != Phase.CALC or converter_lock_active:
		return
	if input_buffer.is_empty():
		_set_status_i18n("quest.radio.b.status.need_input", "STATUS: enter value I.", COLOR_WARN)
		return
	i_bits_user = input_buffer.to_int()
	if i_bits_user <= 0:
		_set_status_i18n("quest.radio.b.status.need_input", "STATUS: enter value I.", COLOR_WARN)
		return
	i_bits_value_label.text = str(i_bits_user)
	_register_action()

	calc_checked = true
	phase = Phase.SELECT

	_apply_phase_controls()
	_set_status_i18n(
		"quest.radio.b.status.select",
		"STATUS: choose storage medium.",
		Color(0.85, 0.85, 0.85, 1.0)
	)
	i_bits_value_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))

	_update_preview()
	_update_details_text()

func _on_storage_selected(idx: int) -> void:
	if phase != Phase.SELECT or converter_lock_active:
		return
	_register_action()

	selected_storage_idx = idx
	for i in range(storage_btns.size()):
		storage_btns[i].button_pressed = (i == idx)
		storage_btns[i].modulate = Color(1, 1, 0.75, 1) if i == idx else Color(1, 1, 1, 1)

	_apply_phase_controls()
	_set_status_i18n(
		"quest.radio.b.status.confirm",
		"STATUS: press CAPTURE.",
		Color(0.85, 0.85, 0.85, 1.0)
	)
	_update_preview()
	_update_details_text()

func _on_converter_pressed() -> void:
	if phase == Phase.RESULT:
		return
	if converter_lock_active:
		return
	_register_action()
	var now_sec: float = Time.get_ticks_msec() / 1000.0
	if now_sec < converter_cooldown_until:
		var left: float = converter_cooldown_until - now_sec
		_set_status_i18n(
			"quest.radio.b.status.converter_cooldown",
			"STATUS: converter cooldown {left}s",
			COLOR_WARN,
			{"left": "%.1f" % left}
		)
		return
	used_converter = true
	converter_use_count += 1
	converter_lock_active = true
	converter_lock_until = now_sec + CONVERTER_LOCK_SECONDS
	converter_cooldown_until = now_sec + CONVERTER_COOLDOWN_SECONDS
	_set_status_i18n(
		"quest.radio.b.status.converter",
		"STATUS: hint: I = K * i; for bytes divide by 8.",
		Color(0.55, 0.85, 1.0, 1.0)
	)
	_apply_phase_controls()
	_update_preview()
	_update_details_text()

func _on_capture_pressed() -> void:
	if phase != Phase.SELECT or selected_storage_idx < 0 or converter_lock_active:
		return
	_register_action()
	_finish_trial()

func _finish_trial() -> void:
	phase = Phase.RESULT
	btn_capture.visible = false
	btn_next.visible = true
	_apply_phase_controls()

	var result: Dictionary = _evaluate_selection()
	var choice: Dictionary = result.get("choice", {}) as Dictionary
	var choice_cap: int = int(result.get("choice_cap", 0))
	var user_bits: int = int(result.get("user_bits", 0))
	var unit_mode_correct: bool = bool(result.get("unit_mode_correct", false))
	var calc_correct: bool = bool(result.get("calc_correct", false))
	var is_fit: bool = bool(result.get("is_fit", false))
	var is_best_fit: bool = bool(result.get("is_best_fit", false))
	var is_overkill: bool = bool(result.get("is_overkill", false))
	var waste_ratio: float = float(result.get("waste_ratio", 0.0))
	var unit_confusion: bool = bool(result.get("unit_confusion", false))
	var error_type: String = str(result.get("error_type", "calc_wrong"))
	var selected_display: String = str(result.get("selected_display", "\u2014"))

	var valid_mastery: bool = (error_type == "best_fit") and calc_correct and (not used_converter)

	if error_type == "best_fit":
		_set_status_i18n("quest.radio.b.result.best", "STATUS: excellent. Optimal storage selected.", COLOR_GOOD)
		_update_sample_slot(COLOR_GOOD)
	elif error_type == "underfit":
		_set_status_i18n("quest.radio.b.result.under", "STATUS: incorrect. Storage does not fit data.", COLOR_BAD)
		_update_sample_slot(COLOR_BAD)
	elif error_type == "calc_wrong":
		_set_status_i18n("quest.radio.b.result.calc", "STATUS: storage picked, but I calculation is wrong.", COLOR_BAD)
		_update_sample_slot(COLOR_BAD)
	elif error_type == "unit_confusion":
		_set_status_i18n("quest.radio.b.result.unit", "STATUS: likely unit confusion (bit/byte).", COLOR_WARN)
		_update_sample_slot(COLOR_WARN)
	else:
		_set_status_i18n("quest.radio.b.result.over", "STATUS: valid but storage is overkill.", COLOR_WARN)
		_update_sample_slot(COLOR_WARN)

	var mode_token: String = "TIMED" if is_timed else "UNTIMED"
	var required_unit: String = answer_unit_mode
	var user_unit_mode: String = "bytes" if answer_in_bytes else "bits"
	var match_key: String = "RI_B_%s_K%d_i%d_unit%s_%s" % [mode_token, k_symbols, i_bits, required_unit, pool_type]
	var payload: Dictionary = {
		"quest_id": "radio_intercept",
		"stage_id": "B",
		"match_key": match_key,
		"pool_type": pool_type,
		"dependency_mode": dependency_mode,
		"K_symbols": k_symbols,
		"i_bits": i_bits,
		"I_true_bits": i_bits_true,
		"required_unit": required_unit,
		"I_user_entered": i_bits_user,
		"user_unit_mode": user_unit_mode,
		"calc_correct": calc_correct,
		"selected_storage_capacity_bits": choice_cap,
		"selected_display": selected_display,
		"is_fit": is_fit,
		"is_correct": is_fit,
		"is_best_fit": is_best_fit,
		"is_overkill": is_overkill,
		"waste_ratio": waste_ratio,
		"error_type": error_type,
		"valid_for_mastery": valid_mastery,
		"valid_for_diagnostics": true,
		"elapsed_ms": Time.get_ticks_msec() - start_ms,
		"time_to_first_action_ms": (first_action_ms - start_ms) if first_action_ms > 0 else 0,
		"is_timed": is_timed,
		"forced_sampling": forced_sampling,
		"used_converter": used_converter,
		"converter_use_count": converter_use_count,
		"unit_confusion": unit_confusion,

		# Compatibility fields (legacy readers)
		"I_bits_true": i_bits_true,
		"I_bits_user": i_bits_user,
		"I_bits_user_interpreted": user_bits,
		"required_answer_unit": answer_unit_mode,
		"answer_interpretation": user_unit_mode,
		"unit_mode_correct": unit_mode_correct,
		"choice_capacity_bits": choice_cap,
		"choice_display_size": int(choice.get("display_size", 0)),
		"choice_display_unit": str(choice.get("display_unit", "")),
		"choice_tag": str(choice.get("tag", ""))
	}
	var stability_delta: float = 0.0
	if not is_fit:
		stability_delta -= 10.0
	if converter_use_count > 0:
		stability_delta -= 5.0 * float(converter_use_count)
	payload["stability_delta"] = stability_delta
	GlobalMetrics.register_trial(payload)

	_update_preview()
	_update_details_text()

func _evaluate_selection() -> Dictionary:
	if selected_storage_idx < 0 or selected_storage_idx >= storage_options.size():
		return {}
	var choice: Dictionary = storage_options[selected_storage_idx]
	var choice_cap: int = int(choice.get("capacity_bits", 0))
	var user_bits: int = _get_user_answer_bits()
	var unit_mode_correct: bool = _is_unit_mode_correct()
	var calc_correct: bool = (i_bits_user > 0) and (user_bits == i_bits_true) and unit_mode_correct
	var is_fit: bool = choice_cap >= i_bits_true
	var waste_ratio: float = 0.0
	if i_bits_true > 0:
		waste_ratio = float(choice_cap) / float(i_bits_true)
	var tag: String = str(choice.get("tag", ""))
	var unit_confusion: bool = (user_bits == i_bits_true and not unit_mode_correct) or tag == "UNIT_TRAP"
	var error_type: String = "overkill"
	var is_best_fit: bool = false
	var is_overkill: bool = false

	# Priority: underfit -> unit_confusion -> calc_wrong -> best_fit -> overkill
	if not is_fit:
		error_type = "underfit"
	elif unit_confusion:
		error_type = "unit_confusion"
	elif not calc_correct:
		error_type = "calc_wrong"
	elif tag == "BEST":
		error_type = "best_fit"
		is_best_fit = true
	else:
		error_type = "overkill"
		is_overkill = true

	return {
		"choice": choice,
		"choice_cap": choice_cap,
		"user_bits": user_bits,
		"unit_mode_correct": unit_mode_correct,
		"calc_correct": calc_correct,
		"is_fit": is_fit,
		"is_best_fit": is_best_fit,
		"is_overkill": is_overkill,
		"waste_ratio": waste_ratio,
		"unit_confusion": unit_confusion,
		"error_type": error_type,
		"selected_display": _format_storage_option(choice)
	}

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
	var user_unit_mode: String = "bytes" if answer_in_bytes else "bits"
	var entered_text: String = "\u2014"
	if i_bits_user > 0:
		entered_text = "%d %s" % [i_bits_user, _tr("quest.radio.common.unit.byte", "byte") if user_unit_mode == "bytes" else _tr("quest.radio.common.unit.bit", "bit")]
	preview_calc_label.text = _tr("quest.radio.b.preview.entered", "Entered I: {value}", {"value": entered_text})
	preview_calc_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1.0))

	if phase == Phase.CALC:
		preview_fit_label.text = _tr("quest.radio.b.preview.input_mode", "Input mode: {mode}", {
			"mode": _tr("quest.radio.common.unit.bytes", "bytes") if user_unit_mode == "bytes" else _tr("quest.radio.common.unit.bits", "bits")
		})
		preview_class_label.text = _tr("quest.radio.b.preview.wait_result", "Evaluation appears after CAPTURE.")
		preview_fit_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 1.0))
		preview_class_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 1.0))
		return

	if phase == Phase.SELECT:
		if selected_storage_idx < 0:
			preview_fit_label.text = _tr("quest.radio.b.preview.storage_none", "Storage: not selected")
		else:
			preview_fit_label.text = _tr("quest.radio.b.preview.storage_selected", "Selected storage: {storage}", {
				"storage": _format_storage_option(storage_options[selected_storage_idx])
			})
		preview_class_label.text = _tr("quest.radio.b.preview.wait_result", "Evaluation appears after CAPTURE.")
		preview_fit_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 1.0))
		preview_class_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 1.0))
		return

	var result: Dictionary = _evaluate_selection()
	if result.is_empty():
		preview_fit_label.text = _tr("quest.radio.b.preview.storage_empty", "Storage: -")
		preview_class_label.text = _tr("quest.radio.b.preview.class_empty", "Class: -")
		return
	var is_fit: bool = bool(result.get("is_fit", false))
	var error_type: String = str(result.get("error_type", "calc_wrong"))
	preview_fit_label.text = _tr("quest.radio.b.preview.storage_fit", "Storage: {fit}", {
		"fit": _tr("quest.radio.b.preview.fit_yes", "fits") if is_fit else _tr("quest.radio.b.preview.fit_no", "does not fit")
	})
	preview_fit_label.add_theme_color_override("font_color", COLOR_GOOD if is_fit else COLOR_BAD)
	match error_type:
		"best_fit":
			preview_class_label.text = _tr("quest.radio.b.preview.class_best", "Class: BEST FIT")
			preview_class_label.add_theme_color_override("font_color", COLOR_GOOD)
		"underfit":
			preview_class_label.text = _tr("quest.radio.b.preview.class_under", "Class: UNDERFIT")
			preview_class_label.add_theme_color_override("font_color", COLOR_BAD)
		"unit_confusion":
			preview_class_label.text = _tr("quest.radio.b.preview.class_unit", "Class: UNIT CONFUSION")
			preview_class_label.add_theme_color_override("font_color", COLOR_WARN)
		"calc_wrong":
			preview_class_label.text = _tr("quest.radio.b.preview.class_calc", "Class: CALC WRONG")
			preview_class_label.add_theme_color_override("font_color", COLOR_BAD)
		_:
			preview_class_label.text = _tr("quest.radio.b.preview.class_over", "Class: OVERKILL")
			preview_class_label.add_theme_color_override("font_color", COLOR_WARN)

func _update_details_text() -> void:
	var lines: Array[String] = []
	if phase != Phase.RESULT:
		lines.append(_tr("quest.radio.b.details.rule", "Rule: I = K * i."))
		lines.append(_tr("quest.radio.b.details.input", "Enter I in required units and choose storage."))
		lines.append(_tr("quest.radio.b.details.bytes_note", "If answer is in bytes, divide by 8."))
		lines.append(_tr("quest.radio.b.details.after_capture", "Breakdown appears after CAPTURE."))
		details_text.text = "\n".join(lines)
		return

	var result: Dictionary = _evaluate_selection()
	if result.is_empty():
		details_text.text = _tr("quest.radio.b.details.unavailable", "Breakdown unavailable.")
		return
	var error_type: String = str(result.get("error_type", "calc_wrong"))
	var selected_display: String = str(result.get("selected_display", "\u2014"))
	var user_unit_mode: String = "bytes" if answer_in_bytes else "bits"
	var user_bits: int = int(result.get("user_bits", 0))
	var choice_cap: int = int(result.get("choice_cap", 0))
	lines.append(_tr("quest.radio.b.details.given", "Given: K = {k}, i = {i}.", {"k": k_symbols, "i": i_bits}))
	lines.append(_tr("quest.radio.b.details.calc", "Calculation: I = K * i = {k} * {i} = {bits} bit.", {
		"k": k_symbols,
		"i": i_bits,
		"bits": i_bits_true
	}))
	if answer_unit_mode == "bytes":
		lines.append(_tr("quest.radio.b.details.required_bytes", "Required in bytes: {bits}/8 = {bytes} byte.", {
			"bits": i_bits_true,
			"bytes": i_bits_true / 8
		}))
	else:
		lines.append(_tr("quest.radio.b.details.required_bits", "Required in bits."))
	lines.append(_tr("quest.radio.b.details.user_input", "Your input: I = {value} {unit} ({bits} bit).", {
		"value": i_bits_user,
		"unit": _tr("quest.radio.common.unit.byte", "byte") if user_unit_mode == "bytes" else _tr("quest.radio.common.unit.bit", "bit"),
		"bits": user_bits
	}))
	lines.append(_tr("quest.radio.b.details.storage", "Selected storage: {storage} ({bits} bit).", {
		"storage": selected_display,
		"bits": choice_cap
	}))
	match error_type:
		"best_fit":
			lines.append(_tr("quest.radio.b.details.outcome_best", "Outcome: BEST FIT. Minimal storage that fits packet."))
		"underfit":
			lines.append(_tr("quest.radio.b.details.outcome_under", "Outcome: UNDERFIT. Selected storage is too small."))
		"unit_confusion":
			lines.append(_tr("quest.radio.b.details.outcome_unit", "Outcome: UNIT CONFUSION. Value entered in wrong units."))
		"calc_wrong":
			lines.append(_tr("quest.radio.b.details.outcome_calc", "Outcome: CALC WRONG. Error in I calculation."))
		_:
			lines.append(_tr("quest.radio.b.details.outcome_over", "Outcome: OVERKILL. Storage fits but has unnecessary overhead."))
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
	btn_details.text = _tr("quest.radio.common.btn.details_close", "CLOSE ^") if visible else _tr("quest.radio.common.btn.details_open", "DETAILS v")

func _update_header_meta() -> void:
	var mode_text: String = _tr("quest.radio.b.meta.mode_no_timer", "NO TIMER")
	meta_label.text = _tr("quest.radio.b.meta.main", "MODE: {mode} | STAB: {stability}%", {
		"mode": mode_text,
		"stability": int(_current_stability)
	})

func _on_stability_changed(new_value: float, _delta: float) -> void:
	_current_stability = new_value
	if noir_overlay != null and noir_overlay.has_method("set_danger_level"):
		noir_overlay.call("set_danger_level", new_value)
	_update_header_meta()

func _apply_phase_controls() -> void:
	var now_sec: float = Time.get_ticks_msec() / 1000.0
	var cooldown_active: bool = now_sec < converter_cooldown_until
	var numpad_enabled: bool = (phase == Phase.CALC) and (not converter_lock_active)
	_update_required_unit_ui()
	if answer_unit_toggle != null:
		var requires_bytes: bool = answer_unit_mode == "bytes"
		answer_unit_toggle.disabled = (phase != Phase.CALC) or converter_lock_active or (not requires_bytes)
	if numpad_grid != null:
		for child in numpad_grid.get_children():
			var key_btn: Button = child as Button
			if key_btn != null:
				key_btn.disabled = not numpad_enabled

	if phase == Phase.CALC:
		btn_minus.disabled = converter_lock_active
		btn_plus.disabled = converter_lock_active
		btn_check_calc.disabled = converter_lock_active
		for btn in storage_btns:
			btn.disabled = true
		btn_capture.disabled = true
	elif phase == Phase.SELECT:
		btn_minus.disabled = true
		btn_plus.disabled = true
		btn_check_calc.disabled = true
		for btn in storage_btns:
			btn.disabled = converter_lock_active
		btn_capture.disabled = converter_lock_active or selected_storage_idx < 0
	else:
		btn_minus.disabled = true
		btn_plus.disabled = true
		btn_check_calc.disabled = true
		for btn in storage_btns:
			btn.disabled = true
		btn_capture.disabled = true

	btn_converter.disabled = (phase == Phase.RESULT) or converter_lock_active or cooldown_active

func _pick_answer_unit_mode() -> String:
	if _answer_unit_modes.is_empty():
		return "bits"
	var mode: String = _answer_unit_modes[randi() % _answer_unit_modes.size()]
	return "bytes" if mode == "bytes" else "bits"

func _build_task_text() -> String:
	var suffix: String = _tr("quest.radio.b.ui.task_suffix_bits", "Answer in BITS.")
	if answer_unit_mode == "bytes":
		suffix = _tr("quest.radio.b.ui.task_suffix_bytes", "Answer in BYTES.")
	return "%s %s" % [_tr("quest.radio.b.task", "Message length: %d chars. Calculate size (I=K*i) and select drive.") % k_symbols, suffix]

func _get_user_answer_bits() -> int:
	var raw_value: int = maxi(i_bits_user, 0)
	if answer_in_bytes:
		return raw_value * 8
	return raw_value

func _is_unit_mode_correct() -> bool:
	var selected_mode: String = "bytes" if answer_in_bytes else "bits"
	return selected_mode == answer_unit_mode

func _find_best_fit_cap(required_bits: int) -> int:
	var best: int = 0
	for step in _capacity_steps_bits:
		if step >= required_bits:
			best = step
			break
	if best <= 0:
		best = 1
		while best <= required_bits:
			best *= 2
		if best == required_bits:
			best *= 2
	return best

func _find_underfit_cap(required_bits: int) -> int:
	var candidate: int = 0
	for step in _capacity_steps_bits:
		if step < required_bits:
			candidate = step
		else:
			break
	if candidate <= 0:
		candidate = maxi(1, int(floor(float(required_bits) * 0.75)))
	if candidate >= required_bits:
		candidate = maxi(1, required_bits - 1)
	return candidate

func _find_underfit_far_cap(required_bits: int, near_cap: int) -> int:
	var candidate: int = 0
	var far_target: int = maxi(1, int(floor(float(required_bits) * 0.5)))
	for step in _capacity_steps_bits:
		if step < required_bits and step <= far_target:
			candidate = step
	if candidate <= 0:
		candidate = far_target
	candidate = maxi(1, candidate)
	candidate = maxi(1, mini(candidate, near_cap - 1))
	if candidate >= required_bits:
		candidate = maxi(1, required_bits - 1)
	return candidate

func _find_over_near_cap(best_cap: int, required_bits: int, over_far_cap: int) -> int:
	var candidate: int = 0
	for step in _capacity_steps_bits:
		if step > best_cap:
			candidate = step
			break
	if candidate <= 0:
		candidate = best_cap + maxi(1, int(ceil(float(required_bits) * 0.25)))
	var near_ceiling: int = maxi(required_bits, over_far_cap - 1)
	candidate = mini(candidate, near_ceiling)
	candidate = maxi(candidate, required_bits)
	return candidate

func _find_overkill_cap(best_cap: int, required_bits: int) -> int:
	var threshold: int = maxi(required_bits * 4, best_cap + 1)
	for step in _capacity_steps_bits:
		if step >= threshold:
			return step
	var cap: int = maxi(1, best_cap)
	while cap < threshold:
		cap *= 2
	return cap

func _load_level_config() -> void:
	_pool_normal = _to_int_array(RadioLevels.get_pool("B", "K_pool_normal", FALLBACK_POOL_NORMAL), FALLBACK_POOL_NORMAL)
	_pool_anchor = _to_int_array(RadioLevels.get_pool("B", "K_pool_anchor", FALLBACK_POOL_ANCHOR), FALLBACK_POOL_ANCHOR)
	_capacity_steps_bits = _to_int_array(
		RadioLevels.get_pool("B", "capacity_steps_bits", FALLBACK_CAPACITY_STEPS_BITS),
		FALLBACK_CAPACITY_STEPS_BITS
	)
	_capacity_steps_bits.sort()
	_answer_unit_modes = _to_string_array(
		RadioLevels.get_pool("B", "answer_unit_modes", FALLBACK_ANSWER_MODES),
		FALLBACK_ANSWER_MODES
	)
	_anchor_every_min = int(RadioLevels.get_value("B", "anchor_every_min", 7))
	_anchor_every_max = int(RadioLevels.get_value("B", "anchor_every_max", 10))
	if _anchor_every_min <= 0:
		_anchor_every_min = 7
	if _anchor_every_max < _anchor_every_min:
		_anchor_every_max = _anchor_every_min

func _to_int_array(raw: Array, fallback: Array[int]) -> Array[int]:
	var result: Array[int] = []
	for value_var in raw:
		var typed: Variant = value_var
		match typeof(typed):
			TYPE_INT:
				result.append(int(typed))
			TYPE_FLOAT:
				result.append(int(round(float(typed))))
			TYPE_STRING:
				var text: String = String(typed).strip_edges()
				if text.is_valid_int():
					result.append(text.to_int())
	if result.is_empty():
		result.append_array(fallback)
	return result

func _to_string_array(raw: Array, fallback: Array[String]) -> Array[String]:
	var result: Array[String] = []
	for value_var in raw:
		var text: String = String(value_var).strip_edges().to_lower()
		if not text.is_empty():
			result.append(text)
	if result.is_empty():
		result.append_array(fallback)
	return result

func _random_anchor_gap() -> int:
	return randi_range(_anchor_every_min, _anchor_every_max)

func _random_from_int_pool(pool: Array[int], fallback_value: int) -> int:
	if pool.is_empty():
		return fallback_value
	return pool[randi() % pool.size()]

func _ensure_fullscreen_layout() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	safe_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	safe_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_split.size_flags_vertical = Control.SIZE_EXPAND_FILL

func _install_right_scroll() -> void:
	if _right_scroll_installed:
		return
	if right_margin == null or right_vbox == null:
		return

	var right_scroll: ScrollContainer = ScrollContainer.new()
	right_scroll.name = "RightScroll"
	right_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	right_scroll.follow_focus = true

	right_margin.remove_child(right_vbox)
	right_margin.add_child(right_scroll)
	right_scroll.add_child(right_vbox)

	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_right_scroll_installed = true

func _apply_safe_area_padding() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var portrait_phone: bool = viewport_size.x < viewport_size.y and viewport_size.x <= PHONE_PORTRAIT_MAX_WIDTH
	var compact_landscape: bool = viewport_size.x > viewport_size.y and viewport_size.y <= COMPACT_STACK_MAX_HEIGHT and viewport_size.x <= COMPACT_STACK_MAX_WIDTH
	var compact_layout: bool = portrait_phone or compact_landscape
	var left: float = 10.0 if portrait_phone else 16.0
	var top: float = 8.0 if portrait_phone else 12.0
	var right: float = 10.0 if portrait_phone else 16.0
	var bottom: float = 8.0 if portrait_phone else 12.0
	if compact_layout:
		left = minf(left, 10.0)
		right = minf(right, 10.0)
		top = minf(top, 8.0)
		bottom = minf(bottom, 8.0)

	var safe_rect: Rect2i = DisplayServer.get_display_safe_area()
	if safe_rect.size.x > 0 and safe_rect.size.y > 0:
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
	var portrait_phone: bool = size.x < size.y and size.x <= PHONE_PORTRAIT_MAX_WIDTH
	var compact_landscape: bool = size.x > size.y and size.y <= COMPACT_STACK_MAX_HEIGHT and size.x <= COMPACT_STACK_MAX_WIDTH
	var compact_stack: bool = portrait_phone or compact_landscape
	var phone_landscape: bool = size.x > size.y and size.y <= PHONE_LANDSCAPE_MAX_HEIGHT

	storage_grid.columns = 2

	if compact_stack:
		var landscape_stack: bool = size.x > size.y
		body_split.split_offset = _clamp_split_offset(int(size.x * (0.54 if landscape_stack else 0.56)), 400, 380)
		root_vbox.add_theme_constant_override("separation", 8)
		right_vbox.add_theme_constant_override("separation", 8)
		left_pane.size_flags_stretch_ratio = 0.8 if landscape_stack else 1.15
		right_pane.size_flags_stretch_ratio = 1.45
		storage_grid.size_flags_vertical = Control.SIZE_FILL
		header_panel.custom_minimum_size.y = 54
		title_label.add_theme_font_size_override("font_size", 22)
		meta_label.visible = false
		context_title.add_theme_font_size_override("font_size", 18)
		task_label.add_theme_font_size_override("font_size", 15)
		calc_title.add_theme_font_size_override("font_size", 18)
		preview_title.add_theme_font_size_override("font_size", 18)
		status_label.add_theme_font_size_override("font_size", 15)
		context_card.custom_minimum_size.y = 94 if landscape_stack else 108
		calc_card.custom_minimum_size.y = 96 if landscape_stack else 108
		preview_card.custom_minimum_size.y = 90 if landscape_stack else 102
		for btn in storage_btns:
			btn.custom_minimum_size.y = 58 if landscape_stack else 62
		for btn in [btn_back, btn_minus, btn_plus, btn_check_calc, btn_converter, btn_capture, btn_next, btn_details, btn_close_details, btn_toggle_calc]:
			btn.custom_minimum_size.y = 58 if landscape_stack else 64
		if numpad_grid != null:
			numpad_grid.custom_minimum_size.y = 146 if landscape_stack else 188
	elif phone_landscape:
		body_split.split_offset = _clamp_split_offset(int(size.x * 0.52), 420, 400)
		root_vbox.add_theme_constant_override("separation", 8)
		right_vbox.add_theme_constant_override("separation", 8)
		left_pane.size_flags_stretch_ratio = 1.0
		right_pane.size_flags_stretch_ratio = 1.0
		storage_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
		header_panel.custom_minimum_size.y = 58
		title_label.add_theme_font_size_override("font_size", 24)
		meta_label.visible = true
		meta_label.custom_minimum_size.x = 180.0
		context_title.add_theme_font_size_override("font_size", 19)
		task_label.add_theme_font_size_override("font_size", 16)
		calc_title.add_theme_font_size_override("font_size", 19)
		preview_title.add_theme_font_size_override("font_size", 19)
		status_label.add_theme_font_size_override("font_size", 16)
		context_card.custom_minimum_size.y = 106
		calc_card.custom_minimum_size.y = 102
		preview_card.custom_minimum_size.y = 98
		for btn in storage_btns:
			btn.custom_minimum_size.y = 64
		for btn in [btn_back, btn_minus, btn_plus, btn_check_calc, btn_converter, btn_capture, btn_next, btn_details, btn_close_details, btn_toggle_calc]:
			btn.custom_minimum_size.y = 56
		if numpad_grid != null:
			numpad_grid.custom_minimum_size.y = 210
		meta_label.add_theme_font_size_override("font_size", 15)
	elif size.x < 1280.0:
		body_split.split_offset = _clamp_split_offset(int(size.x * 0.53), 460, 420)
		root_vbox.add_theme_constant_override("separation", 10)
		right_vbox.add_theme_constant_override("separation", 10)
		left_pane.size_flags_stretch_ratio = 1.0
		right_pane.size_flags_stretch_ratio = 1.0
		storage_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
		header_panel.custom_minimum_size.y = 62
		title_label.add_theme_font_size_override("font_size", 28)
		meta_label.visible = true
		meta_label.custom_minimum_size.x = 260.0
		context_title.add_theme_font_size_override("font_size", 22)
		task_label.add_theme_font_size_override("font_size", 18)
		calc_title.add_theme_font_size_override("font_size", 20)
		preview_title.add_theme_font_size_override("font_size", 20)
		context_card.custom_minimum_size.y = 112
		calc_card.custom_minimum_size.y = 106
		preview_card.custom_minimum_size.y = 100
		for btn in storage_btns:
			btn.custom_minimum_size.y = 74
		for btn in [btn_back, btn_minus, btn_plus, btn_check_calc, btn_converter, btn_capture, btn_next, btn_details, btn_close_details, btn_toggle_calc]:
			btn.custom_minimum_size.y = 58
		meta_label.add_theme_font_size_override("font_size", 17)
		status_label.add_theme_font_size_override("font_size", 18)
		if numpad_grid != null:
			numpad_grid.custom_minimum_size.y = 220
	else:
		body_split.split_offset = _clamp_split_offset(int(size.x * 0.54), 500, 460)
		root_vbox.add_theme_constant_override("separation", 10)
		right_vbox.add_theme_constant_override("separation", 10)
		left_pane.size_flags_stretch_ratio = 1.0
		right_pane.size_flags_stretch_ratio = 1.0
		storage_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
		header_panel.custom_minimum_size.y = 62
		title_label.add_theme_font_size_override("font_size", 28)
		meta_label.visible = true
		meta_label.custom_minimum_size.x = 360.0
		context_title.add_theme_font_size_override("font_size", 22)
		task_label.add_theme_font_size_override("font_size", 18)
		calc_title.add_theme_font_size_override("font_size", 20)
		preview_title.add_theme_font_size_override("font_size", 20)
		context_card.custom_minimum_size.y = 114
		calc_card.custom_minimum_size.y = 108
		preview_card.custom_minimum_size.y = 102
		for btn in storage_btns:
			btn.custom_minimum_size.y = 78
		for btn in [btn_back, btn_minus, btn_plus, btn_check_calc, btn_converter, btn_capture, btn_next, btn_details, btn_close_details, btn_toggle_calc]:
			btn.custom_minimum_size.y = 58
		meta_label.add_theme_font_size_override("font_size", 18)
		status_label.add_theme_font_size_override("font_size", 18)
		if numpad_grid != null:
			numpad_grid.custom_minimum_size.y = 220

func _clamp_split_offset(target_offset: int, min_left: int, min_right: int) -> int:
	var viewport_width: int = int(get_viewport_rect().size.x)
	return clampi(target_offset, min_left, max(min_left, viewport_width - min_right))
