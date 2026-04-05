extends Control

const THEME_NOIR: Theme = preload("res://ui/theme_noir_pencil.tres")
const TRACE_ROW_SCENE: PackedScene = preload("res://scenes/components/TraceRow.tscn")

const AUDIO_CLICK: AudioStream = preload("res://audio/click.wav")
const AUDIO_ERROR: AudioStream = preload("res://audio/error.wav")
const AUDIO_RELAY: AudioStream = preload("res://audio/relay.wav")

const LEVELS_PATH := "res://data/suspect_a_levels.json"
const MAX_ATTEMPTS := 3
const FX_ID_LOW := 0
const FX_ID_HIGH := 1
const OVERLAY_ID_PENCIL := 0
const OVERLAY_ID_CRT := 1
const PHONE_PORTRAIT_MAX_WIDTH := 560.0
const PHONE_LANDSCAPE_MAX_HEIGHT := 760.0

const STATUS_COLOR_NEUTRAL := Color(0.72, 0.72, 0.70)
const STATUS_COLOR_READY := Color(0.93, 0.93, 0.91)
const STATUS_COLOR_FAIL := Color(0.82, 0.82, 0.80)
const STATUS_COLOR_WARN := Color(0.78, 0.78, 0.76)
const STATUS_COLOR_SUCCESS := Color(0.97, 0.97, 0.95)

func _tr(key: String, default_text: String, params: Dictionary = {}) -> String:
	var merged: Dictionary = params.duplicate(true)
	merged["default"] = default_text
	return I18n.tr_key(key, merged)

enum QuestState {
	INTRO,
	READY,
	TRACE_GUIDED,
	TRACE_FULL,
	AWAIT_ANSWER,
	WRONG_RETRY,
	SUCCESS,
	EXPLANATION
}

@export_enum("low", "high") var fx_quality: String = "high"
@export_enum("pencil", "crt") var overlay_mode: String = "pencil"

@onready var safe_area: MarginContainer = $SafeArea
@onready var main_vbox: VBoxContainer = $SafeArea/MainVBox
@onready var header_bar: HBoxContainer = $SafeArea/MainVBox/HeaderBar
@onready var workspace_container: BoxContainer = $SafeArea/MainVBox/WorkspaceContainer
@onready var code_panel: PanelContainer = $SafeArea/MainVBox/WorkspaceContainer/CodePanel
@onready var trace_panel: PanelContainer = $SafeArea/MainVBox/WorkspaceContainer/TracePanel
@onready var solve_panel: PanelContainer = $SafeArea/MainVBox/SolvePanel

@onready var btn_quest_back: Button = $SafeArea/MainVBox/HeaderBar/BtnQuestBack
@onready var btn_settings: Button = $SafeArea/MainVBox/HeaderBar/BtnSettings
@onready var lbl_clue_title: Label = $SafeArea/MainVBox/HeaderBar/LblClueTitle
@onready var lbl_session: Label = $SafeArea/MainVBox/HeaderBar/LblSessionId

@onready var clue_label: Label = $SafeArea/MainVBox/CaseBriefPanel/BriefMargin/BriefVBox/ClueLabel
@onready var briefing_title: Label = $SafeArea/MainVBox/CaseBriefPanel/BriefMargin/BriefVBox/BriefingTitle
@onready var briefing_text: Label = $SafeArea/MainVBox/CaseBriefPanel/BriefMargin/BriefVBox/BriefingText
@onready var topic_hint_badge: Label = $SafeArea/MainVBox/CaseBriefPanel/BriefMargin/BriefVBox/TopicHintBadge

@onready var code_title: Label = $SafeArea/MainVBox/WorkspaceContainer/CodePanel/CodeMargin/CodeVBox/CodeHeader/CodeTitle
@onready var code_scroll: ScrollContainer = $SafeArea/MainVBox/WorkspaceContainer/CodePanel/CodeMargin/CodeVBox/CodeScroll
@onready var code_lines_container: VBoxContainer = $SafeArea/MainVBox/WorkspaceContainer/CodePanel/CodeMargin/CodeVBox/CodeScroll/CodeLines

@onready var trace_title: Label = $SafeArea/MainVBox/WorkspaceContainer/TracePanel/TraceMargin/TraceVBox/TraceHeader/TraceTitle
@onready var trace_mode_badge: Label = $SafeArea/MainVBox/WorkspaceContainer/TracePanel/TraceMargin/TraceVBox/TraceHeader/TraceModeBadge
@onready var toggle_trace_button: Button = $SafeArea/MainVBox/WorkspaceContainer/TracePanel/TraceMargin/TraceVBox/TraceHeader/ToggleTraceButton
@onready var trace_body: VBoxContainer = $SafeArea/MainVBox/WorkspaceContainer/TracePanel/TraceMargin/TraceVBox/TraceBody
@onready var trace_scroll: ScrollContainer = $SafeArea/MainVBox/WorkspaceContainer/TracePanel/TraceMargin/TraceVBox/TraceBody/TraceScroll
@onready var trace_rows_container: VBoxContainer = $SafeArea/MainVBox/WorkspaceContainer/TracePanel/TraceMargin/TraceVBox/TraceBody/TraceScroll/TraceRowsContainer
@onready var trace_controls: HBoxContainer = $SafeArea/MainVBox/WorkspaceContainer/TracePanel/TraceMargin/TraceVBox/TraceControls
@onready var step_prev_button: Button = $SafeArea/MainVBox/WorkspaceContainer/TracePanel/TraceMargin/TraceVBox/TraceControls/StepPrevButton
@onready var step_next_button: Button = $SafeArea/MainVBox/WorkspaceContainer/TracePanel/TraceMargin/TraceVBox/TraceControls/StepNextButton
@onready var show_all_button: Button = $SafeArea/MainVBox/WorkspaceContainer/TracePanel/TraceMargin/TraceVBox/TraceControls/ShowAllButton
@onready var reset_trace_button: Button = $SafeArea/MainVBox/WorkspaceContainer/TracePanel/TraceMargin/TraceVBox/TraceControls/ResetTraceButton
@onready var trace_collapsed_state: VBoxContainer = $SafeArea/MainVBox/WorkspaceContainer/TracePanel/TraceMargin/TraceVBox/TraceCollapsedState
@onready var trace_collapsed_title: Label = $SafeArea/MainVBox/WorkspaceContainer/TracePanel/TraceMargin/TraceVBox/TraceCollapsedState/CollapsedTitle
@onready var trace_collapsed_hint: Label = $SafeArea/MainVBox/WorkspaceContainer/TracePanel/TraceMargin/TraceVBox/TraceCollapsedState/CollapsedHint
@onready var trace_collapsed_legend: Label = $SafeArea/MainVBox/WorkspaceContainer/TracePanel/TraceMargin/TraceVBox/TraceCollapsedState/CollapsedLegend

@onready var answer_label: Label = $SafeArea/MainVBox/SolvePanel/SolveMargin/SolveVBox/AnswerLabel
@onready var answer_row: BoxContainer = $SafeArea/MainVBox/SolvePanel/SolveMargin/SolveVBox/AnswerRow
@onready var answer_input: LineEdit = $SafeArea/MainVBox/SolvePanel/SolveMargin/SolveVBox/AnswerRow/AnswerInput
@onready var primary_check_button: Button = $SafeArea/MainVBox/SolvePanel/SolveMargin/SolveVBox/AnswerRow/PrimaryCheckButton
@onready var btn_next: Button = $SafeArea/MainVBox/SolvePanel/SolveMargin/SolveVBox/AnswerRow/BtnNext
@onready var answer_hint_label: Label = $SafeArea/MainVBox/SolvePanel/SolveMargin/SolveVBox/AnswerHintLabel
@onready var step_analysis_button: Button = $SafeArea/MainVBox/SolvePanel/SolveMargin/SolveVBox/SolveActions/StepAnalysisButton
@onready var hint_button: Button = $SafeArea/MainVBox/SolvePanel/SolveMargin/SolveVBox/SolveActions/HintButton
@onready var why_button: Button = $SafeArea/MainVBox/SolvePanel/SolveMargin/SolveVBox/SolveActions/WhyButton

@onready var lbl_status: Label = $SafeArea/MainVBox/StatusBar/StatusMargin/StatusRow/LblStatus
@onready var lbl_attempts: Label = $SafeArea/MainVBox/StatusBar/StatusMargin/StatusRow/LblAttempts

@onready var explanation_overlay: PanelContainer = $ExplanationOverlay
@onready var explanation_title: Label = $ExplanationOverlay/OverlayMargin/OverlayCenter/OverlayCard/OverlayCardMargin/OverlayVBox/ExplanationTitle
@onready var explanation_text: RichTextLabel = $ExplanationOverlay/OverlayMargin/OverlayCenter/OverlayCard/OverlayCardMargin/OverlayVBox/ExplanationText
@onready var btn_close_overlay: Button = $ExplanationOverlay/OverlayMargin/OverlayCenter/OverlayCard/OverlayCardMargin/OverlayVBox/OverlayButtons/BtnCloseOverlay
@onready var btn_open_steps: Button = $ExplanationOverlay/OverlayMargin/OverlayCenter/OverlayCard/OverlayCardMargin/OverlayVBox/OverlayButtons/BtnOpenSteps
@onready var btn_overlay_next: Button = $ExplanationOverlay/OverlayMargin/OverlayCenter/OverlayCard/OverlayCardMargin/OverlayVBox/OverlayButtons/BtnOverlayNext

@onready var inspector_popup: PopupPanel = $InspectorPopup
@onready var popup_fx_select: OptionButton = $InspectorPopup/Root/SettingsGrid/FxSelect
@onready var popup_overlay_select: OptionButton = $InspectorPopup/Root/SettingsGrid/OverlaySelect
@onready var popup_close: Button = $InspectorPopup/Root/BtnClose

@onready var noir_overlay: CanvasLayer = $NoirOverlay

var levels: Array = []
var current_level_idx: int = 0
var current_level: Dictionary = {}

var current_state: int = QuestState.INTRO
var previous_state_before_overlay: int = QuestState.READY

var trace_steps: Array = []
var current_trace_index: int = -1
var trace_mode: String = "collapsed"
var used_guided_trace: bool = false
var used_full_trace: bool = false
var shown_auto_help: bool = false
var attempts_used: int = 0
var answer_locked: bool = false
var trace_steps_revealed_count: int = 0
var topic_hint_used_count: int = 0

var code_line_rows: Array[Control] = []
var code_line_number_labels: Array[Label] = []
var code_line_text_labels: Array[Label] = []
var trace_row_nodes: Array[Control] = []
var current_highlight_line: int = -1

var is_compact_layout: bool = false

var task_started_at: int = 0
var task_finished: bool = false
var task_result_sent: bool = false
var partial_trial_sent: bool = false
var variant_hash: String = ""
var task_session: Dictionary = {}
var trial_seq: int = 0

var answer_change_count: int = 0
var invalid_format_count: int = 0
var enter_press_count: int = 0

var analyze_press_count: int = 0
var guided_trace_open_count: int = 0
var full_trace_open_count: int = 0
var trace_step_reveal_count_local: int = 0
var trace_scroll_count: int = 0

var topic_hint_open_count: int = 0
var settings_open_count: int = 0
var diagnostics_open_count: int = 0
var overlay_toggle_count: int = 0
var effects_toggle_count: int = 0

var changed_after_guided_trace: bool = false
var changed_after_full_trace: bool = false
var changed_after_topic_hint: bool = false

var time_to_first_answer_input_ms: int = -1
var time_to_first_enter_ms: int = -1
var time_to_first_analyze_ms: int = -1
var time_to_first_topic_hint_ms: int = -1
var time_from_last_analysis_to_enter_ms: int = -1

var last_answer_edit_ms: int = -1
var last_analysis_ms: int = -1

var _await_answer_change_after_guided_trace: bool = false
var _await_answer_change_after_full_trace: bool = false
var _await_answer_change_after_topic_hint: bool = false
var _suppress_answer_change_signal: bool = false

var sfx_player: AudioStreamPlayer

func _ready() -> void:
	_apply_theme()
	_configure_overlay_shader()
	_init_audio_player()
	_connect_signals()
	for btn in [btn_quest_back, btn_settings, primary_check_button, btn_next, step_analysis_button, hint_button, why_button, toggle_trace_button, step_prev_button, step_next_button, show_all_button, reset_trace_button, btn_close_overlay, btn_open_steps, btn_overlay_next, popup_close]:
		if btn != null:
			btn.focus_mode = Control.FOCUS_NONE
	answer_input.focus_mode = Control.FOCUS_ALL
	if not I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.connect(_on_language_changed)
	_apply_i18n()
	_setup_runtime_controls()
	_apply_layout_mode()

	if not _load_levels_from_json():
		_show_boot_error(_tr("suspect.a.status.boot_error", "Не удалось загрузить уровни квеста подозреваемого."))
		return

	if levels.size() != 18:
		push_warning("Suspect levels expected 18, got %d" % levels.size())

	GlobalMetrics.current_level_index = 0
	_load_case(0)

func _exit_tree() -> void:
	_register_partial_trial("EXIT_WITHOUT_ANSWER")
	if I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.disconnect(_on_language_changed)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_apply_layout_mode()

func _on_language_changed(_code: String) -> void:
	_apply_i18n()
	if not current_level.is_empty():
		_render_case_brief()
		if explanation_overlay.visible:
			_render_explanation_overlay()

func _apply_theme() -> void:
	theme = THEME_NOIR

func _setup_runtime_controls() -> void:
	popup_fx_select.select(FX_ID_HIGH if fx_quality == "high" else FX_ID_LOW)
	popup_overlay_select.select(OVERLAY_ID_PENCIL if overlay_mode == "pencil" else OVERLAY_ID_CRT)

func _apply_i18n() -> void:
	btn_quest_back.text = _tr("suspect.a.btn.back", "НАЗАД")
	if btn_settings != null:
		btn_settings.visible = false
	code_title.text = _tr("suspect.a.ui.code_title", "КОД")
	trace_title.text = _tr("suspect.a.ui.trace_title", "ЖУРНАЛ ВЫПОЛНЕНИЯ")
	answer_label.text = _tr("suspect.a.ui.answer", "Итоговое значение s")
	answer_input.placeholder_text = _tr("suspect.a.ui.answer_placeholder", "Введите целое число")
	answer_hint_label.text = _tr("suspect.a.ui.answer_hint", "Сначала проследите ход выполнения, затем подтвердите итог.")
	primary_check_button.text = _tr("suspect.a.btn.check", "Проверить")
	btn_next.text = _tr("suspect.a.btn.next", "ДАЛЕЕ")
	step_analysis_button.text = _tr("suspect.a.btn.analyze", "АНАЛИЗ")
	hint_button.text = _tr("suspect.a.btn.hint", "ПОДСКАЗКА")
	why_button.text = _tr("suspect.a.btn.verify", "ПРОВЕРИТЬ")
	toggle_trace_button.text = _tr("suspect.a.btn.trace_open", "Открыть")
	step_prev_button.text = _tr("suspect.a.btn.prev", "Назад")
	step_next_button.text = _tr("suspect.a.btn.next_step", "Следующий шаг")
	show_all_button.text = _tr("suspect.a.btn.show_all", "Показать всё")
	reset_trace_button.text = _tr("suspect.a.btn.reset_trace", "Сброс")
	trace_mode_badge.text = _tr("suspect.a.trace.collapsed", "Свернуто")
	trace_collapsed_title.text = _tr("suspect.a.trace.collapsed_title", "Журнал выполнения скрыт.")
	trace_collapsed_hint.text = _tr("suspect.a.trace.collapsed_hint", "Откройте его, чтобы увидеть, как меняется s по шагам.")
	trace_collapsed_legend.text = _tr("suspect.a.trace.collapsed_legend", "шаг | i | s до -> s после")

	explanation_title.text = _tr("suspect.a.overlay.title", "Почему итог именно такой")
	btn_close_overlay.text = _tr("suspect.a.btn.close", "Закрыть")
	btn_open_steps.text = _tr("suspect.a.btn.open_steps", "Открыть шаги")
	btn_overlay_next.text = _tr("suspect.a.btn.next", "ДАЛЕЕ")

	popup_close.text = _tr("suspect.a.btn.close", "Закрыть")
	var popup_title: Label = inspector_popup.get_node_or_null("Root/LblTitle") as Label
	if popup_title != null:
		popup_title.text = _tr("suspect.a.ui.settings_title", "НАСТРОЙКИ")
	var popup_fx_title: Label = inspector_popup.get_node_or_null("Root/SettingsGrid/LblFx") as Label
	if popup_fx_title != null:
		popup_fx_title.text = _tr("suspect.a.ui.effects", "ЭФФЕКТЫ")
	var popup_overlay_title: Label = inspector_popup.get_node_or_null("Root/SettingsGrid/LblOverlay") as Label
	if popup_overlay_title != null:
		popup_overlay_title.text = _tr("suspect.a.ui.overlay", "НАЛОЖЕНИЕ")

	popup_fx_select.clear()
	popup_fx_select.add_item(_tr("suspect.a.settings.fx_low", "Низко"), FX_ID_LOW)
	popup_fx_select.add_item(_tr("suspect.a.settings.fx_high", "Высоко"), FX_ID_HIGH)
	popup_fx_select.select(FX_ID_HIGH if fx_quality == "high" else FX_ID_LOW)

	popup_overlay_select.clear()
	popup_overlay_select.add_item(_tr("suspect.a.settings.overlay_pencil", "Карандаш"), OVERLAY_ID_PENCIL)
	popup_overlay_select.add_item("CRT", OVERLAY_ID_CRT)
	popup_overlay_select.select(OVERLAY_ID_PENCIL if overlay_mode == "pencil" else OVERLAY_ID_CRT)

	if is_node_ready():
		_set_trace_mode(trace_mode)
		_update_attempts_label()

func _configure_overlay_shader() -> void:
	if noir_overlay != null and noir_overlay.has_method("set_overlay_mode"):
		noir_overlay.call("set_overlay_mode", "PENCIL" if overlay_mode == "pencil" else "CRT")

	var overlay_rect: ColorRect = noir_overlay.get_node_or_null("CRT_Overlay") as ColorRect
	if overlay_rect == null:
		return
	var shader_mat: ShaderMaterial = overlay_rect.material as ShaderMaterial
	if shader_mat == null:
		return

	var high_fx: bool = fx_quality == "high"
	if overlay_mode == "pencil":
		_set_overlay_param(shader_mat, "intensity", 0.35)
		_set_overlay_param(shader_mat, "fx_quality", 1 if high_fx else 0)
		_set_overlay_param(shader_mat, "grain_strength", 0.36 if high_fx else 0.24)
		_set_overlay_param(shader_mat, "hatch_strength", 0.30 if high_fx else 0.14)
		_set_overlay_param(shader_mat, "vignette_strength", 0.44)
		_set_overlay_param(shader_mat, "jitter_strength", 0.0)
		_set_overlay_param(shader_mat, "pulse", 0.0)
		_set_overlay_param(shader_mat, "glitch_strength", 0.0)
	else:
		_set_overlay_param(shader_mat, "tint_color", Color(0.93, 0.93, 0.93, 1.0))
		_set_overlay_param(shader_mat, "intensity", 0.18)
		_set_overlay_param(shader_mat, "fx_quality", 1 if high_fx else 0)
		_set_overlay_param(shader_mat, "jitter_strength", 0.0)
		_set_overlay_param(shader_mat, "pulse", 0.0)
		_set_overlay_param(shader_mat, "glitch_strength", 0.0)

func _set_overlay_param(shader_mat: ShaderMaterial, param_name: String, value: Variant) -> void:
	if shader_mat == null:
		return
	var shader: Shader = shader_mat.shader
	if shader == null:
		return
	for uniform_var in shader.get_shader_uniform_list():
		if typeof(uniform_var) != TYPE_DICTIONARY:
			continue
		var uniform: Dictionary = uniform_var
		if str(uniform.get("name", "")) == param_name:
			shader_mat.set_shader_parameter(param_name, value)
			return

func _init_audio_player() -> void:
	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SfxPlayer"
	add_child(sfx_player)

func _connect_signals() -> void:
	btn_quest_back.pressed.connect(_on_back_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	popup_close.pressed.connect(_on_settings_close_pressed)
	popup_fx_select.item_selected.connect(_on_popup_fx_selected)
	popup_overlay_select.item_selected.connect(_on_popup_overlay_selected)

	primary_check_button.pressed.connect(_on_primary_check_pressed)
	btn_next.pressed.connect(_on_next_pressed)
	answer_input.text_submitted.connect(_on_answer_submitted)
	answer_input.text_changed.connect(_on_answer_text_changed)

	step_analysis_button.pressed.connect(_on_step_analysis_pressed)
	hint_button.pressed.connect(_on_hint_pressed)
	why_button.pressed.connect(_on_why_pressed)

	toggle_trace_button.pressed.connect(_on_toggle_trace_pressed)
	step_prev_button.pressed.connect(_on_step_prev_pressed)
	step_next_button.pressed.connect(_on_step_next_pressed)
	show_all_button.pressed.connect(_on_show_all_pressed)
	reset_trace_button.pressed.connect(_on_reset_trace_pressed)

	btn_close_overlay.pressed.connect(_on_close_overlay_pressed)
	btn_open_steps.pressed.connect(_on_overlay_open_steps_pressed)
	btn_overlay_next.pressed.connect(_on_overlay_next_pressed)

func _on_settings_pressed() -> void:
	settings_open_count += 1
	_log_event("settings_opened", {"count": settings_open_count})
	inspector_popup.popup_centered_ratio(0.38)

func _on_settings_close_pressed() -> void:
	inspector_popup.hide()

func _on_popup_fx_selected(index: int) -> void:
	var item_id: int = popup_fx_select.get_item_id(index)
	fx_quality = "high" if item_id == FX_ID_HIGH else "low"
	if inspector_popup.visible:
		effects_toggle_count += 1
		_log_event("effects_toggled", {"count": effects_toggle_count, "mode": fx_quality})
	_configure_overlay_shader()

func _on_popup_overlay_selected(index: int) -> void:
	var item_id: int = popup_overlay_select.get_item_id(index)
	overlay_mode = "pencil" if item_id == OVERLAY_ID_PENCIL else "crt"
	if inspector_popup.visible:
		overlay_toggle_count += 1
		_log_event("overlay_toggled", {"count": overlay_toggle_count, "mode": overlay_mode})
	_configure_overlay_shader()

func _apply_layout_mode() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var portrait: bool = viewport_size.x < viewport_size.y
	var compact: bool = (portrait and viewport_size.x <= PHONE_PORTRAIT_MAX_WIDTH) or ((not portrait) and viewport_size.y <= PHONE_LANDSCAPE_MAX_HEIGHT)
	is_compact_layout = compact

	safe_area.add_theme_constant_override("margin_left", 10 if compact else 16)
	safe_area.add_theme_constant_override("margin_top", 8 if compact else 12)
	safe_area.add_theme_constant_override("margin_right", 10 if compact else 16)
	safe_area.add_theme_constant_override("margin_bottom", 8 if compact else 12)

	main_vbox.add_theme_constant_override("separation", 6 if compact else 8)
	header_bar.add_theme_constant_override("separation", 6 if compact else 8)
	workspace_container.add_theme_constant_override("separation", 8 if compact else 10)

	var mobile_portrait: bool = portrait and viewport_size.x <= PHONE_PORTRAIT_MAX_WIDTH
	workspace_container.vertical = mobile_portrait
	if mobile_portrait:
		code_panel.custom_minimum_size = Vector2(0, 210 if compact else 240)
		trace_panel.custom_minimum_size = Vector2(0, 170 if compact else 210)
		code_panel.size_flags_stretch_ratio = 1.25
		trace_panel.size_flags_stretch_ratio = 1.0
	else:
		code_panel.custom_minimum_size = Vector2(0, 220 if compact else 250)
		trace_panel.custom_minimum_size = Vector2(320 if compact else 380, 0)
		code_panel.size_flags_stretch_ratio = 1.4
		trace_panel.size_flags_stretch_ratio = 1.0

	var clue_font: int = 13 if compact else 14
	var title_font: int = 18 if compact else 20
	var body_font: int = 15 if compact else 16
	clue_label.add_theme_font_size_override("font_size", clue_font)
	briefing_title.add_theme_font_size_override("font_size", title_font)
	briefing_text.add_theme_font_size_override("font_size", body_font)
	topic_hint_badge.add_theme_font_size_override("font_size", body_font)
	var compact_briefing: bool = viewport_size.y < 700.0 or (portrait and viewport_size.x < 500.0)
	briefing_title.visible = not compact_briefing
	topic_hint_badge.visible = not compact_briefing
	briefing_text.max_lines_visible = 2 if compact_briefing else 0
	answer_label.add_theme_font_size_override("font_size", body_font)
	answer_hint_label.add_theme_font_size_override("font_size", 13 if compact else 14)

	# Keep answer row readable in compact mode when "Next" appears.
	var compact_next_layout: bool = compact and portrait and btn_next.visible
	answer_row.vertical = compact_next_layout
	answer_row.add_theme_constant_override("separation", 6 if compact else 8)
	primary_check_button.theme_type_variation = &""
	primary_check_button.custom_minimum_size = Vector2(0, 42 if compact else 46)
	btn_next.custom_minimum_size = Vector2(0, 42 if compact else 46)

	for idx in range(code_line_rows.size()):
		_apply_code_line_style(idx, current_highlight_line == idx + 1)

func _load_levels_from_json() -> bool:
	var file: FileAccess = FileAccess.open(LEVELS_PATH, FileAccess.READ)
	if file == null:
		push_error("Cannot open %s" % LEVELS_PATH)
		return false

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_error("%s is not an array" % LEVELS_PATH)
		return false

	var loaded_levels: Array = parsed
	var valid_levels: Array = []
	for item_var in loaded_levels:
		if typeof(item_var) != TYPE_DICTIONARY:
			continue
		var level: Dictionary = item_var
		if _validate_level(level):
			valid_levels.append(level)
		else:
			push_error("Invalid suspect level: %s" % str(level.get("id", "UNKNOWN")))

	levels = valid_levels
	return levels.size() > 0

func _validate_level(level: Dictionary) -> bool:
	var required_keys: Array[String] = ["id", "bucket", "briefing", "code", "expected", "trace", "topic_tags", "explain_short"]
	for key in required_keys:
		if not level.has(key):
			return false

	if typeof(level.get("code")) != TYPE_ARRAY:
		return false
	if typeof(level.get("trace")) != TYPE_ARRAY:
		return false
	if typeof(level.get("topic_tags")) != TYPE_ARRAY:
		return false
	if typeof(level.get("explain_short")) != TYPE_ARRAY:
		return false

	return true

func _show_boot_error(text: String) -> void:
	_update_status(text, STATUS_COLOR_FAIL)
	primary_check_button.disabled = true
	step_analysis_button.disabled = true
	show_all_button.disabled = true

func _load_case(case_idx: int) -> void:
	if levels.is_empty():
		return

	if case_idx >= levels.size():
		case_idx = 0
	current_level_idx = case_idx
	GlobalMetrics.current_level_index = current_level_idx

	current_level = (levels[case_idx] as Dictionary).duplicate(true)
	trace_steps = _normalize_trace(current_level.get("trace", []))
	current_trace_index = -1
	trace_mode = "collapsed"
	used_guided_trace = false
	used_full_trace = false
	shown_auto_help = false
	attempts_used = 0
	answer_locked = false
	trace_steps_revealed_count = 0
	topic_hint_used_count = 0
	current_highlight_line = -1
	btn_next.visible = false
	btn_overlay_next.visible = false

	task_started_at = Time.get_ticks_msec()
	task_finished = false
	task_result_sent = false
	partial_trial_sent = false
	variant_hash = str(hash(JSON.stringify(current_level)))
	var bucket: String = str(current_level.get("bucket", "unknown"))
	task_session = {
		"task_id": str(current_level.get("id", "A-00")),
		"variant_hash": variant_hash,
		"started_at_ticks": task_started_at,
		"ended_at_ticks": 0,
		"attempts": [],
		"events": []
	}
	trial_seq += 1
	task_session["trial_seq"] = trial_seq
	task_session["bucket"] = bucket
	task_session["topic_tags"] = (current_level.get("topic_tags", []) as Array).duplicate(true)
	task_session["trace_steps_total"] = trace_steps.size()

	answer_change_count = 0
	invalid_format_count = 0
	enter_press_count = 0
	analyze_press_count = 0
	guided_trace_open_count = 0
	full_trace_open_count = 0
	trace_step_reveal_count_local = 0
	trace_scroll_count = 0
	topic_hint_open_count = 0
	settings_open_count = 0
	diagnostics_open_count = 0
	overlay_toggle_count = 0
	effects_toggle_count = 0
	changed_after_guided_trace = false
	changed_after_full_trace = false
	changed_after_topic_hint = false
	time_to_first_answer_input_ms = -1
	time_to_first_enter_ms = -1
	time_to_first_analyze_ms = -1
	time_to_first_topic_hint_ms = -1
	time_from_last_analysis_to_enter_ms = -1
	last_answer_edit_ms = -1
	last_analysis_ms = -1
	_await_answer_change_after_guided_trace = false
	_await_answer_change_after_full_trace = false
	_await_answer_change_after_topic_hint = false

	lbl_clue_title.text = _tr("suspect.a.labels.clue_title", "УЛИКА #{id}", {"id": str(current_level.get("id", "A-00"))})
	lbl_session.text = _tr("suspect.a.labels.session", "СЕССИЯ {n}", {"n": "%04d" % (randi() % 10000)})

	explanation_overlay.visible = false
	_render_case_brief()
	_render_code_immediate()
	_build_trace_panel()
	_reset_answer_ui()
	_set_state(QuestState.READY)
	_update_status_learning_focus()
	_update_attempts_label()
	_apply_layout_mode()
	_log_event("task_start", {
		"level_id": str(current_level.get("id", "")),
		"bucket": bucket,
		"trace_len": trace_steps.size(),
		"topic_tags": (current_level.get("topic_tags", []) as Array).duplicate(true)
	})

func _localized_briefing_text(level: Dictionary) -> String:
	var source: String = str(level.get("briefing", "")).strip_edges()
	var level_id: String = str(level.get("id", "unknown"))
	return _tr("suspect.a.level.%s.briefing" % level_id, source)

func _render_case_brief() -> void:
	var case_id: String = str(current_level.get("id", "A-00"))
	clue_label.text = _tr("suspect.a.brief.clue", "На что смотреть: трассировка цикла")
	briefing_title.text = _tr("suspect.a.brief.title", "Шифрблок %s" % case_id)
	briefing_text.text = _localized_briefing_text(current_level)
	topic_hint_badge.text = _build_topic_hint_badge(current_level.get("topic_tags", []))

func _build_topic_hint_badge(tags_variant: Variant) -> String:
	var tags: Array = tags_variant if typeof(tags_variant) == TYPE_ARRAY else []
	return _tr("suspect.a.brief.topic_hint", "На что смотреть: {hint}", {"hint": _topic_hint_sentence(tags)})

func _topic_hint_sentence(tags: Array) -> String:
	if tags.is_empty():
		return _tr("suspect.a.hint.general", "Проверьте границы цикла и обновления аккумулятора.")

	for tag_var in tags:
		var tag: String = str(tag_var)
		match tag:
			"range_stop_exclusive":
				return _tr("suspect.a.hint.range_stop", "Значение stop в range не включается.")
			"while_boundary":
				return _tr("suspect.a.hint.while_boundary", "Проверяйте границу while на каждой итерации.")
			"break_flow":
				return _tr("suspect.a.hint.break_flow", "Отследите, где break завершает цикл.")
			"continue_flow":
				return _tr("suspect.a.hint.continue_flow", "Отследите, как continue пропускает обновление s.")
			"list_iteration":
				return _tr("suspect.a.hint.list_iteration", "Порядок списка задан явно и фиксирован.")
			"step_trap":
				return _tr("suspect.a.hint.step_trap", "Внимательно проверьте шаг цикла.")
			"condition_filter":
				return _tr("suspect.a.hint.condition_filter", "Проверьте, какие итерации проходят условие.")
			"boundary_count":
				return _tr("suspect.a.hint.boundary_count", "Корректно посчитайте итерации от start до stop.")
			_:
				continue

	return _tr("suspect.a.hint.fallback", "Смотрите на шаги, где меняется s.")

func _show_learning_hint() -> void:
	var hint_text: String = _topic_hint_sentence(current_level.get("topic_tags", []))
	topic_hint_used_count += 1
	topic_hint_open_count += 1
	_await_answer_change_after_topic_hint = true
	if time_to_first_topic_hint_ms < 0:
		time_to_first_topic_hint_ms = _elapsed_ms_now()
	_log_event("topic_hint_opened", {"count": topic_hint_open_count})
	_log_event("topic_hint_used", {"count": topic_hint_used_count, "hint": hint_text})
	_update_status(hint_text, STATUS_COLOR_WARN)

func _update_status_learning_focus() -> void:
	_update_status(_tr("suspect.a.status.learning_focus", "Код готов. При необходимости откройте журнал выполнения и проследите изменение s."), STATUS_COLOR_READY)

func _render_code_immediate() -> void:
	for child in code_lines_container.get_children():
		child.queue_free()
	code_line_rows.clear()
	code_line_number_labels.clear()
	code_line_text_labels.clear()

	var lines: Array = current_level.get("code", [])
	for idx in range(lines.size()):
		var row := PanelContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.custom_minimum_size = Vector2(0, 28)

		var row_margin := MarginContainer.new()
		row_margin.add_theme_constant_override("margin_left", 6)
		row_margin.add_theme_constant_override("margin_top", 2)
		row_margin.add_theme_constant_override("margin_right", 6)
		row_margin.add_theme_constant_override("margin_bottom", 2)

		var line_box := HBoxContainer.new()
		line_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line_box.add_theme_constant_override("separation", 10)

		var number_label := Label.new()
		number_label.custom_minimum_size = Vector2(40, 0)
		number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		number_label.text = "%2d" % (idx + 1)

		var code_label := Label.new()
		code_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		code_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		code_label.text = str(lines[idx])

		line_box.add_child(number_label)
		line_box.add_child(code_label)
		row_margin.add_child(line_box)
		row.add_child(row_margin)
		code_lines_container.add_child(row)

		code_line_rows.append(row)
		code_line_number_labels.append(number_label)
		code_line_text_labels.append(code_label)
		_apply_code_line_style(idx, false)

	current_highlight_line = -1
	call_deferred("_scroll_code_to_top")
	_log_event("code_shown", {"line_count": lines.size()})

func _apply_code_line_style(index: int, is_active: bool) -> void:
	if index < 0 or index >= code_line_rows.size():
		return

	var row: Control = code_line_rows[index]
	var number_label: Label = code_line_number_labels[index]
	var code_label: Label = code_line_text_labels[index]
	var font_size: int = 22 if is_compact_layout else 25

	var fill: Color = Color(0.17, 0.17, 0.15, 0.65) if is_active else Color(0.0, 0.0, 0.0, 0.0)
	var border: Color = Color(0.93, 0.87, 0.56, 0.95) if is_active else Color(0.24, 0.24, 0.24, 0.0)
	var number_color: Color = Color(0.94, 0.90, 0.72) if is_active else Color(0.56, 0.56, 0.56)
	var code_color: Color = Color(0.98, 0.97, 0.95) if is_active else Color(0.79, 0.79, 0.77)

	row.add_theme_stylebox_override("panel", _make_row_style(fill, border))
	number_label.add_theme_color_override("font_color", number_color)
	code_label.add_theme_color_override("font_color", code_color)
	number_label.add_theme_font_size_override("font_size", font_size - 2)
	code_label.add_theme_font_size_override("font_size", font_size)

func _make_row_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style

func _scroll_code_to_top() -> void:
	code_scroll.scroll_vertical = 0

func _scroll_code_to_line(line_idx: int) -> void:
	if line_idx <= 0 or line_idx > code_line_rows.size():
		return
	var row: Control = code_line_rows[line_idx - 1]
	var target: int = int(maxf(0.0, row.position.y - 20.0))
	var tw: Tween = create_tween()
	tw.tween_property(code_scroll, "scroll_vertical", target, 0.14)

func _highlight_code_line(line_idx: int) -> void:
	if current_highlight_line == line_idx:
		return

	if current_highlight_line > 0 and current_highlight_line <= code_line_rows.size():
		_apply_code_line_style(current_highlight_line - 1, false)

	current_highlight_line = line_idx
	if current_highlight_line > 0 and current_highlight_line <= code_line_rows.size():
		_apply_code_line_style(current_highlight_line - 1, true)
		call_deferred("_scroll_code_to_line", current_highlight_line)

func _build_trace_panel() -> void:
	for child in trace_rows_container.get_children():
		child.queue_free()
	trace_row_nodes.clear()

	for step_var in trace_steps:
		if typeof(step_var) != TYPE_DICTIONARY:
			continue
		var step: Dictionary = step_var
		var row_instance: Control = TRACE_ROW_SCENE.instantiate() as Control
		if row_instance == null:
			continue
		trace_rows_container.add_child(row_instance)
		if row_instance.has_method("set_step_data"):
			row_instance.call_deferred("set_step_data", step)
		trace_row_nodes.append(row_instance)

	_set_trace_mode("collapsed")
	_update_trace_controls()

func _normalize_trace(raw_trace_variant: Variant) -> Array:
	var raw_trace: Array = raw_trace_variant if typeof(raw_trace_variant) == TYPE_ARRAY else []
	var normalized: Array = []
	for idx in range(raw_trace.size()):
		if typeof(raw_trace[idx]) != TYPE_DICTIONARY:
			continue
		var step_src: Dictionary = raw_trace[idx]
		var step_index: int = idx + 1
		var cond_text: String = str(step_src.get("cond", step_src.get("event", "loop")))
		var event_text: String = str(step_src.get("event", "")).strip_edges()
		if event_text.is_empty():
			event_text = "итерация цикла" if cond_text == "loop" else cond_text

		var step: Dictionary = {
			"step": step_index,
			"i": step_src.get("i", "?"),
			"cond": cond_text,
			"s_before": step_src.get("s_before", step_src.get("before", 0)),
			"s_after": step_src.get("s_after", step_src.get("after", 0)),
			"event": event_text,
			"line_ref": int(step_src.get("line_ref", -1))
		}

		if int(step.get("line_ref", -1)) <= 0:
			step["line_ref"] = _derive_line_ref(step, idx)

		normalized.append(step)

	return normalized

func _derive_line_ref(step: Dictionary, step_idx: int) -> int:
	var accumulator_line: int = _find_code_line(["s =", "s+=", "s *=", "s -=", "s /="])
	var loop_line: int = _find_code_line(["for ", "while "])
	var condition_line: int = _find_code_line(["if ", "elif "])

	var cond_text: String = str(step.get("cond", "")).to_lower()
	var before_val: Variant = step.get("s_before", null)
	var after_val: Variant = step.get("s_after", null)
	var value_changed: bool = before_val != null and after_val != null and str(before_val) != str(after_val)

	if cond_text == "true" or cond_text == "false":
		if condition_line > 0:
			return condition_line

	if value_changed and accumulator_line > 0:
		return accumulator_line
	if loop_line > 0:
		return loop_line
	if condition_line > 0:
		return condition_line

	var code_lines: Array = current_level.get("code", [])
	if code_lines.is_empty():
		return -1
	return clampi(step_idx + 1, 1, code_lines.size())

func _find_code_line(patterns: Array[String]) -> int:
	var code_lines: Array = current_level.get("code", [])
	for idx in range(code_lines.size()):
		var line_lower: String = str(code_lines[idx]).to_lower()
		for pattern in patterns:
			if line_lower.find(pattern.to_lower()) != -1:
				return idx + 1
	return -1

func _set_trace_mode(mode: String) -> void:
	trace_mode = mode
	match trace_mode:
		"guided":
			trace_mode_badge.text = _tr("suspect.a.trace.guided", "Пошагово")
		"full":
			trace_mode_badge.text = _tr("suspect.a.trace.full", "Полный")
		_:
			trace_mode_badge.text = _tr("suspect.a.trace.collapsed", "Свернуто")

	var collapsed: bool = trace_mode == "collapsed"
	trace_collapsed_state.visible = collapsed
	trace_body.visible = not collapsed
	trace_controls.visible = not collapsed
	toggle_trace_button.text = _tr("suspect.a.btn.trace_collapse", "Свернуть") if not collapsed else _tr("suspect.a.btn.trace_open", "Открыть")

	if collapsed:
		current_trace_index = -1
		for row in trace_row_nodes:
			_set_trace_row_mode(row, "hidden")
		_highlight_code_line(-1)

	_update_trace_controls()

func _set_trace_row_mode(row: Control, mode: String) -> void:
	if row == null:
		return
	if row.has_method("set_row_mode"):
		row.call("set_row_mode", mode)
	else:
		row.visible = mode != "hidden"

func _enter_guided_trace_mode() -> void:
	if trace_steps.is_empty():
		_update_status(_tr("suspect.a.trace.missing", "Для этого кейса нет данных журнала выполнения."), STATUS_COLOR_WARN)
		return

	guided_trace_open_count += 1
	analyze_press_count += 1
	if time_to_first_analyze_ms < 0:
		time_to_first_analyze_ms = _elapsed_ms_now()
	last_analysis_ms = _elapsed_ms_now()
	_await_answer_change_after_guided_trace = true
	_log_event("analyze_pressed", {"mode": "guided", "count": analyze_press_count})

	if trace_mode != "guided":
		used_guided_trace = true
		_log_event("opened_guided_trace", {"level_id": str(current_level.get("id", ""))})

	_set_trace_mode("guided")
	_set_state(QuestState.TRACE_GUIDED)
	_reveal_guided_trace_index(0)
	_update_status(_tr("suspect.a.trace.guided_intro", "Пошаговый разбор открыт. Переходите по шагам и следите, где меняется s."), STATUS_COLOR_READY)

func _reveal_guided_trace_index(index: int) -> void:
	if trace_steps.is_empty():
		return

	var clamped: int = clampi(index, 0, trace_steps.size() - 1)
	current_trace_index = clamped
	for row_idx in range(trace_row_nodes.size()):
		var mode: String = "hidden"
		if row_idx < clamped:
			mode = "completed"
		elif row_idx == clamped:
			mode = "active"
		_set_trace_row_mode(trace_row_nodes[row_idx], mode)

	trace_steps_revealed_count = maxi(trace_steps_revealed_count, clamped + 1)
	trace_step_reveal_count_local = maxi(trace_step_reveal_count_local, clamped + 1)
	_log_event("trace_steps_revealed_count", {"count": trace_steps_revealed_count})

	var step: Dictionary = trace_steps[clamped]
	_highlight_code_line(int(step.get("line_ref", -1)))
	call_deferred("_scroll_trace_to_index", clamped)
	_update_trace_controls()

func _scroll_trace_to_index(index: int) -> void:
	if index < 0 or index >= trace_row_nodes.size():
		return
	trace_scroll_count += 1
	var row: Control = trace_row_nodes[index]
	var target: int = int(maxf(0.0, row.position.y - 20.0))
	var tw: Tween = create_tween()
	tw.tween_property(trace_scroll, "scroll_vertical", target, 0.14)

func _show_next_trace_step() -> void:
	if trace_steps.is_empty():
		return

	if trace_mode != "guided":
		_enter_guided_trace_mode()
		return

	if current_trace_index < trace_steps.size() - 1:
		_reveal_guided_trace_index(current_trace_index + 1)
		if current_trace_index == trace_steps.size() - 1:
			_update_status(_tr("suspect.a.trace.guided_done", "Разбор завершен. Теперь подтвердите итоговое s."), STATUS_COLOR_READY)
	else:
		_update_status(_tr("suspect.a.trace.end", "Вы уже на последнем шаге журнала."), STATUS_COLOR_NEUTRAL)

func _show_prev_trace_step() -> void:
	if trace_mode != "guided":
		return
	if current_trace_index > 0:
		_reveal_guided_trace_index(current_trace_index - 1)
	else:
		_update_status(_tr("suspect.a.trace.start", "Вы уже на первом шаге журнала."), STATUS_COLOR_NEUTRAL)

func _show_full_trace() -> void:
	if trace_steps.is_empty():
		_update_status(_tr("suspect.a.trace.missing", "Для этого кейса нет данных журнала выполнения."), STATUS_COLOR_WARN)
		return

	full_trace_open_count += 1
	analyze_press_count += 1
	if time_to_first_analyze_ms < 0:
		time_to_first_analyze_ms = _elapsed_ms_now()
	last_analysis_ms = _elapsed_ms_now()
	_await_answer_change_after_full_trace = true
	_log_event("analyze_pressed", {"mode": "full", "count": analyze_press_count})

	if trace_mode != "full":
		used_full_trace = true
		_log_event("opened_full_trace", {"level_id": str(current_level.get("id", ""))})

	_set_trace_mode("full")
	_set_state(QuestState.TRACE_FULL)

	for idx in range(trace_row_nodes.size()):
		var row: Control = trace_row_nodes[idx]
		var step: Dictionary = trace_steps[idx]
		var mode: String = "revealed"
		if idx < trace_row_nodes.size() - 1 and str(step.get("s_before", "")) != str(step.get("s_after", "")):
			mode = "completed"
		if idx == trace_row_nodes.size() - 1:
			mode = "active"
		_set_trace_row_mode(row, mode)

	current_trace_index = trace_steps.size() - 1
	trace_steps_revealed_count = maxi(trace_steps_revealed_count, trace_steps.size())
	trace_step_reveal_count_local = maxi(trace_step_reveal_count_local, trace_steps.size())
	_log_event("trace_steps_revealed_count", {"count": trace_steps_revealed_count})
	_highlight_code_line(int(trace_steps[current_trace_index].get("line_ref", -1)))
	call_deferred("_scroll_trace_to_index", current_trace_index)
	_update_trace_controls()
	_update_status(_tr("suspect.a.trace.full_opened", "Полный журнал выполнения открыт."), STATUS_COLOR_READY)

func _reset_trace_panel() -> void:
	_set_trace_mode("collapsed")
	if not task_finished:
		_set_state(QuestState.READY)
		_update_status_learning_focus()

func _update_trace_controls() -> void:
	var has_trace: bool = not trace_steps.is_empty()
	toggle_trace_button.disabled = not has_trace
	step_prev_button.disabled = trace_mode != "guided" or current_trace_index <= 0
	step_next_button.disabled = trace_mode != "guided" or current_trace_index >= trace_steps.size() - 1
	show_all_button.disabled = not has_trace or trace_mode == "full"
	reset_trace_button.disabled = trace_mode == "collapsed"

func _reset_answer_ui() -> void:
	_suppress_answer_change_signal = true
	answer_input.text = ""
	_suppress_answer_change_signal = false
	answer_input.editable = true
	answer_locked = false
	primary_check_button.disabled = false
	btn_next.visible = false
	_apply_layout_mode()

func _parse_answer() -> Dictionary:
	var stripped: String = answer_input.text.strip_edges().replace(" ", "")
	if stripped.is_empty():
		return {"ok": false, "error": "EMPTY"}
	if not stripped.is_valid_int():
		return {"ok": false, "error": "NAN"}
	return {"ok": true, "value": int(stripped), "str": stripped}

func _on_answer_text_changed(text: String) -> void:
	if _suppress_answer_change_signal:
		return
	if task_started_at <= 0 or task_finished:
		return

	var elapsed_ms: int = _elapsed_ms_now()
	if time_to_first_answer_input_ms < 0:
		time_to_first_answer_input_ms = elapsed_ms
	answer_change_count += 1
	last_answer_edit_ms = elapsed_ms

	if _await_answer_change_after_guided_trace:
		changed_after_guided_trace = true
		_await_answer_change_after_guided_trace = false
	if _await_answer_change_after_full_trace:
		changed_after_full_trace = true
		_await_answer_change_after_full_trace = false
	if _await_answer_change_after_topic_hint:
		changed_after_topic_hint = true
		_await_answer_change_after_topic_hint = false

	_log_event("answer_changed", {"value": text, "length": text.length()})

func _on_primary_check_pressed() -> void:
	_check_answer("button")

func _on_answer_submitted(_text: String) -> void:
	_check_answer("enter")

func _check_answer(source: String = "unknown") -> void:
	if answer_locked or task_finished or explanation_overlay.visible:
		return

	enter_press_count += 1
	if time_to_first_enter_ms < 0:
		time_to_first_enter_ms = _elapsed_ms_now()
	if last_analysis_ms >= 0:
		time_from_last_analysis_to_enter_ms = maxi(0, _elapsed_ms_now() - last_analysis_ms)
	_log_event("enter_pressed", {"count": enter_press_count, "source": source})

	var normalized: Dictionary = _parse_answer()
	if not bool(normalized.get("ok", false)):
		invalid_format_count += 1
		_play_sfx(AUDIO_ERROR)
		_trigger_glitch()
		_shake_screen()
		_log_event("invalid_format", {"value": answer_input.text})
		_update_status(_tr("suspect.a.status.invalid_format", "Некорректный формат ввода."), STATUS_COLOR_FAIL)
		return

	var user_answer: int = int(normalized.get("value", 0))
	var expected: int = int(current_level.get("expected", 0))
	var is_correct: bool = user_answer == expected
	_log_event("answer_result", {
		"is_correct": is_correct,
		"expected": expected,
		"answer_value": user_answer,
		"attempts_used": attempts_used
	})

	_record_attempt(user_answer, is_correct)
	if is_correct:
		if not used_guided_trace and not used_full_trace:
			_log_event("answered_without_trace", {})
		else:
			_log_event("answered_after_trace", {"guided": used_guided_trace, "full": used_full_trace})
		_handle_success()
	else:
		_handle_wrong_answer()

func _record_attempt(user_answer: int, is_correct: bool) -> void:
	var now: int = Time.get_ticks_msec()
	var attempts: Array = task_session.get("attempts", [])
	attempts.append({
		"kind": "line_edit",
		"raw": answer_input.text,
		"norm": str(user_answer),
		"duration_input_ms": now - task_started_at,
		"hint_open_at_enter": explanation_overlay.visible,
		"correct": is_correct,
		"state_after": current_state,
		"wrong_count_after": attempts_used
	})
	task_session["attempts"] = attempts

func _handle_wrong_answer() -> void:
	attempts_used += 1
	_set_state(QuestState.WRONG_RETRY)
	_update_attempts_label()
	_log_event("wrong_attempt_count", {"count": attempts_used})

	_play_sfx(AUDIO_ERROR)
	_trigger_glitch()
	_shake_screen()

	if attempts_used == 1:
		_update_status(_tr("suspect.a.status.wrong_soft", "Ответ не совпадает. Проверьте, как меняется s по шагам."), STATUS_COLOR_FAIL)
	elif attempts_used == 2 and not shown_auto_help:
		shown_auto_help = true
		_update_status(_tr("suspect.a.status.wrong_guided", "Похоже, здесь ловушка цикла. Пошаговый разбор уже открыт."), STATUS_COLOR_WARN)
		_offer_guided_trace()
	else:
		_update_status(_tr("suspect.a.status.wrong_explain", "Откройте полный журнал и объяснение, чтобы найти расхождение."), STATUS_COLOR_WARN)
		_offer_explanation_and_trace()

	answer_input.select_all()

func _offer_guided_trace() -> void:
	if trace_mode == "collapsed":
		_enter_guided_trace_mode()

func _offer_explanation_and_trace() -> void:
	if trace_mode == "collapsed":
		_show_full_trace()
	_open_explanation_overlay()

func _handle_success() -> void:
	answer_locked = true
	_set_state(QuestState.SUCCESS)
	_update_status(_tr("suspect.a.status.correct", "Верно. Итоговое значение подтверждено."), STATUS_COLOR_SUCCESS)
	btn_next.visible = true
	btn_overlay_next.visible = true
	answer_input.editable = false
	primary_check_button.disabled = true
	_apply_layout_mode()
	_play_sfx(AUDIO_RELAY)
	_play_success_clean_effect()
	_finalize_task_result(true, "SUCCESS")

func _open_explanation_overlay() -> void:
	if explanation_overlay.visible:
		return
	diagnostics_open_count += 1
	previous_state_before_overlay = current_state
	explanation_overlay.visible = true
	_set_state(QuestState.EXPLANATION)
	_render_explanation_overlay()
	_log_event("diagnostics_opened", {"count": diagnostics_open_count})
	_log_event("explanation_opened", {"state_before": previous_state_before_overlay})

func _render_explanation_overlay() -> void:
	if current_level.is_empty():
		return

	explanation_title.text = _tr("suspect.a.overlay.title", "Почему итог именно такой")
	var short_lines: Array = current_level.get("explain_short", [])
	var full_lines: Array = current_level.get("explain", [])
	if short_lines.is_empty():
		short_lines = full_lines
	if full_lines.is_empty():
		full_lines = short_lines

	var final_value: int = int(current_level.get("expected", 0))
	var trap_text: String = _topic_hint_sentence(current_level.get("topic_tags", []))
	var summary_line: String = ""
	if not trace_steps.is_empty():
		var last_step: Dictionary = trace_steps[trace_steps.size() - 1]
		summary_line = "s %s -> %s" % [str(last_step.get("s_before", "?")), str(last_step.get("s_after", "?"))]

	var level_id: String = str(current_level.get("id", "A-00"))
	var body: String = "[b]%s[/b]\n- %s\n\n[b]%s[/b]\n" % [
		_tr("suspect.a.overlay.key_trap", "Ключевая ловушка"),
		trap_text,
		_tr("suspect.a.overlay.reasoning", "Ход рассуждения")
	]

	for line_idx in range(short_lines.size()):
		var default_line: String = str(short_lines[line_idx])
		var key: String = "suspect.a.level.%s.explain.%d" % [level_id, line_idx]
		body += "- %s\n" % _tr(key, default_line)

	if not summary_line.is_empty():
		body += "\n[b]%s[/b]\n- %s\n" % [_tr("suspect.a.overlay.trace_summary", "Сводка журнала"), summary_line]

	body += "\n[b]%s[/b]\n- %d" % [_tr("suspect.a.overlay.final_s", "Итоговое s"), final_value]
	explanation_text.text = body

func _close_explanation_overlay() -> void:
	if not explanation_overlay.visible:
		return
	explanation_overlay.visible = false
	if task_finished:
		_set_state(QuestState.SUCCESS)
	elif trace_mode == "guided":
		_set_state(QuestState.TRACE_GUIDED)
	elif trace_mode == "full":
		_set_state(QuestState.TRACE_FULL)
	else:
		_set_state(QuestState.READY)

func _on_toggle_trace_pressed() -> void:
	_play_sfx(AUDIO_CLICK)
	if trace_mode == "collapsed":
		_enter_guided_trace_mode()
	else:
		_reset_trace_panel()

func _on_step_prev_pressed() -> void:
	_play_sfx(AUDIO_CLICK)
	_show_prev_trace_step()

func _on_step_next_pressed() -> void:
	_play_sfx(AUDIO_CLICK)
	_show_next_trace_step()

func _on_show_all_pressed() -> void:
	_play_sfx(AUDIO_CLICK)
	_show_full_trace()

func _on_reset_trace_pressed() -> void:
	_play_sfx(AUDIO_CLICK)
	_reset_trace_panel()

func _on_step_analysis_pressed() -> void:
	_play_sfx(AUDIO_CLICK)
	if trace_mode == "guided":
		_show_next_trace_step()
	else:
		_enter_guided_trace_mode()

func _on_hint_pressed() -> void:
	_play_sfx(AUDIO_CLICK)
	_show_learning_hint()

func _on_why_pressed() -> void:
	_play_sfx(AUDIO_CLICK)
	_open_explanation_overlay()

func _on_close_overlay_pressed() -> void:
	_play_sfx(AUDIO_CLICK)
	_close_explanation_overlay()

func _on_overlay_open_steps_pressed() -> void:
	_play_sfx(AUDIO_CLICK)
	explanation_overlay.visible = false
	_show_full_trace()

func _on_overlay_next_pressed() -> void:
	_play_sfx(AUDIO_CLICK)
	if task_finished:
		_on_next_pressed()
	else:
		_close_explanation_overlay()

func _on_next_pressed() -> void:
	if not task_finished:
		return
	_log_event("next_pressed", {"from_task": str(current_level.get("id", "A-00"))})
	_load_case(current_level_idx + 1)

func _on_back_pressed() -> void:
	_register_partial_trial("BACK_PRESSED")
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _register_partial_trial(reason: String) -> void:
	if partial_trial_sent:
		return
	if task_finished or task_result_sent:
		return
	if current_level.is_empty() or task_started_at <= 0:
		return

	partial_trial_sent = true
	var ended: int = Time.get_ticks_msec()
	var elapsed_ms: int = maxi(0, ended - task_started_at)
	var level_id: String = str(current_level.get("id", "A-00"))
	var bucket: String = str(current_level.get("bucket", "unknown"))
	task_session["ended_at_ticks"] = ended
	_log_event("task_end_partial", {"reason": reason})

	var result_data: Dictionary = {
		"quest": "suspect_script",
		"quest_id": "SUSPECT_SCRIPT",
		"stage": "A",
		"stage_id": "A",
		"match_key": "SUSPECT_A|%s|PARTIAL" % level_id,
		"task_id": level_id,
		"bucket": bucket,
		"variant_hash": variant_hash,
		"is_correct": false,
		"is_fit": false,
		"safe_mode": false,
		"elapsed_ms": elapsed_ms,
		"duration": float(elapsed_ms) / 1000.0,
		"stability_delta": 0.0,
		"outcome_code": reason,
		"trial_seq": trial_seq,
		"enter_press_count": enter_press_count,
		"analyze_press_count": analyze_press_count,
		"hint_open_count": guided_trace_open_count + full_trace_open_count + topic_hint_open_count,
		"partial": true,
		"task_session": task_session
	}
	GlobalMetrics.register_trial(result_data)

func _set_state(new_state: int) -> void:
	current_state = new_state

	var answer_enabled: bool = not answer_locked and not task_finished and current_state != QuestState.EXPLANATION
	answer_input.editable = answer_enabled
	primary_check_button.disabled = not answer_enabled
	step_analysis_button.disabled = trace_steps.is_empty()
	show_all_button.disabled = trace_steps.is_empty() or trace_mode == "full"
	why_button.disabled = current_level.is_empty()
	btn_next.visible = task_finished

func _update_status(text: String, color: Color = STATUS_COLOR_NEUTRAL) -> void:
	lbl_status.text = text
	lbl_status.add_theme_color_override("font_color", color)

func _update_attempts_label() -> void:
	var shown_attempts: int = mini(attempts_used, MAX_ATTEMPTS)
	lbl_attempts.text = _tr("suspect.a.labels.attempts", "ПОПЫТКИ: {n}/{max}", {"n": shown_attempts, "max": MAX_ATTEMPTS})

func _finalize_task_result(is_correct: bool, reason: String) -> void:
	if task_result_sent:
		return

	task_result_sent = true
	task_finished = true
	var ended: int = Time.get_ticks_msec()
	task_session["ended_at_ticks"] = ended
	_log_event("task_end", {"reason": reason, "is_correct": is_correct})

	var level_id: String = str(current_level.get("id", "A-00"))
	var bucket: String = str(current_level.get("bucket", "unknown"))
	var elapsed_ms: int = ended - task_started_at

	var result_data: Dictionary = {
		"quest": "suspect_script",
		"quest_id": "SUSPECT_SCRIPT",
		"stage": "A",
		"stage_id": "A",
		"match_key": "SUSPECT_A|%s" % level_id,
		"task_id": level_id,
		"bucket": bucket,
		"variant_hash": variant_hash,
		"is_correct": is_correct,
		"is_fit": is_correct,
		"safe_mode": false,
		"elapsed_ms": elapsed_ms,
		"duration": float(elapsed_ms) / 1000.0,
		"used_guided_trace": used_guided_trace,
		"used_full_trace": used_full_trace,
		"trace_steps_revealed_count": trace_steps_revealed_count,
		"topic_hint_used": topic_hint_used_count > 0,
		"wrong_attempt_count": attempts_used,
		"trial_seq": trial_seq,
		"answer_change_count": answer_change_count,
		"invalid_format_count": invalid_format_count,
		"enter_press_count": enter_press_count,
		"analyze_press_count": analyze_press_count,
		"guided_trace_open_count": guided_trace_open_count,
		"full_trace_open_count": full_trace_open_count,
		"trace_step_reveal_count": trace_step_reveal_count_local,
		"trace_steps_total": trace_steps.size(),
		"topic_hint_open_count": topic_hint_open_count,
		"settings_open_count": settings_open_count,
		"diagnostics_open_count": diagnostics_open_count,
		"overlay_toggle_count": overlay_toggle_count,
		"effects_toggle_count": effects_toggle_count,
		"changed_after_guided_trace": changed_after_guided_trace,
		"changed_after_full_trace": changed_after_full_trace,
		"changed_after_topic_hint": changed_after_topic_hint,
		"time_to_first_answer_input_ms": time_to_first_answer_input_ms,
		"time_to_first_enter_ms": time_to_first_enter_ms,
		"time_to_first_analyze_ms": time_to_first_analyze_ms,
		"time_to_first_topic_hint_ms": time_to_first_topic_hint_ms,
		"time_from_last_analysis_to_enter_ms": time_from_last_analysis_to_enter_ms,
		"topic_tags": (current_level.get("topic_tags", []) as Array).duplicate(true),
		"concept_family": _concept_family_from_bucket(bucket),
		"outcome_code": _build_outcome_code_for_a(is_correct),
		"mastery_block_reason": _build_mastery_block_reason_for_a(is_correct),
		"task_session": task_session,
		"stability_delta": -15.0 if not is_correct else 0.0
	}

	GlobalMetrics.register_trial(result_data)

func _play_sfx(stream: AudioStream) -> void:
	if sfx_player == null:
		return
	sfx_player.stop()
	sfx_player.stream = stream
	sfx_player.play()

func _trigger_glitch() -> void:
	var overlay_rect: ColorRect = noir_overlay.get_node_or_null("CRT_Overlay") as ColorRect
	if overlay_rect == null:
		return
	var shader_mat: ShaderMaterial = overlay_rect.material as ShaderMaterial
	if shader_mat == null:
		return
	var high_fx: bool = fx_quality == "high"
	_set_overlay_param(shader_mat, "pulse", 1.0 if high_fx else 0.65)
	_set_overlay_param(shader_mat, "jitter_strength", 0.8 if high_fx else 0.35)
	_set_overlay_param(shader_mat, "glitch_strength", 0.9 if high_fx else 0.55)
	var tw: Tween = create_tween()
	tw.tween_method(func(v: float) -> void: _set_overlay_param(shader_mat, "pulse", v), 1.0 if high_fx else 0.65, 0.0, 0.26)
	tw.parallel().tween_method(func(v: float) -> void: _set_overlay_param(shader_mat, "jitter_strength", v), 0.8 if high_fx else 0.35, 0.0, 0.22)
	tw.parallel().tween_method(func(v: float) -> void: _set_overlay_param(shader_mat, "glitch_strength", v), 0.9 if high_fx else 0.55, 0.0, 0.22)

func _shake_screen() -> void:
	var original_pos: Vector2 = main_vbox.position
	var tw: Tween = create_tween()
	for _i in range(4):
		tw.tween_property(main_vbox, "position", original_pos + Vector2(randf_range(-2.0, 2.0), randf_range(-1.5, 1.5)), 0.04)
	tw.tween_property(main_vbox, "position", original_pos, 0.05)

func _play_success_clean_effect() -> void:
	var overlay_rect: ColorRect = noir_overlay.get_node_or_null("CRT_Overlay") as ColorRect
	if overlay_rect == null:
		return
	var shader_mat: ShaderMaterial = overlay_rect.material as ShaderMaterial
	if shader_mat == null:
		return
	var tw: Tween = create_tween()
	tw.tween_method(func(v: float) -> void: _set_overlay_param(shader_mat, "grain_strength", v), 0.32, 0.16, 0.20)
	tw.parallel().tween_method(func(v: float) -> void: _set_overlay_param(shader_mat, "hatch_strength", v), 0.24, 0.10, 0.20)
	tw.tween_interval(0.12)
	tw.tween_method(func(v: float) -> void: _set_overlay_param(shader_mat, "grain_strength", v), 0.16, 0.32, 0.28)
	tw.parallel().tween_method(func(v: float) -> void: _set_overlay_param(shader_mat, "hatch_strength", v), 0.10, 0.24, 0.28)

func _log_event(name: String, payload: Dictionary) -> void:
	var elapsed: int = _elapsed_ms_now()
	var events: Array = task_session.get("events", [])
	events.append({
		"name": name,
		"t_ms": elapsed,
		"payload": payload
	})
	task_session["events"] = events

func _elapsed_ms_now() -> int:
	return maxi(0, Time.get_ticks_msec() - task_started_at)

func _concept_family_from_bucket(bucket_value: String) -> String:
	var bucket_norm: String = bucket_value.strip_edges().to_lower()
	if bucket_norm.find("loop") != -1:
		return "loop_flow"
	if bucket_norm.find("branch") != -1 or bucket_norm.find("cond") != -1:
		return "branch_logic"
	if bucket_norm.is_empty():
		return "unknown"
	return bucket_norm

func _build_outcome_code_for_a(is_correct: bool) -> String:
	if is_correct:
		return "A_CORRECT"
	if invalid_format_count > 0 and attempts_used == 0:
		return "A_INVALID_FORMAT"
	if attempts_used >= MAX_ATTEMPTS:
		return "A_MAX_ATTEMPTS"
	return "A_INCORRECT"

func _build_mastery_block_reason_for_a(is_correct: bool) -> String:
	if not is_correct:
		if invalid_format_count > 0:
			return "blocked_invalid_format"
		return "incorrect_answer"
	if used_full_trace:
		return "solved_after_full_trace"
	if used_guided_trace:
		return "solved_after_guided_trace"
	if topic_hint_open_count > 0:
		return "solved_after_topic_hint"
	return "solved_without_support"
