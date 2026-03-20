extends Control

const LEVELS_PATH := "res://data/final_report_c_levels.json"
const SESSION_LEVEL_COUNT := 6
const FR8CData := preload("res://scripts/case_08/fr8c_data.gd")
const FR8CScoring := preload("res://scripts/case_08/fr8c_scoring.gd")

const COLOR_OK := Color(0.55, 0.95, 0.62, 1.0)
const COLOR_WARN := Color(1.0, 0.82, 0.35, 1.0)
const COLOR_ERR := Color(1.0, 0.45, 0.45, 1.0)
const COLOR_INFO := Color(0.84, 0.84, 0.84, 1.0)
const COLOR_SELECTED := Color(1.0, 0.9, 0.45, 1.0)

const TEXT_TITLE := "\u0414\u0415\u041b\u041e #8: \u0424\u0418\u041d\u0410\u041b\u042c\u041d\u042b\u0419 \u041e\u0422\u0427\u0415\u0422 [C]"
const TEXT_BACK := "\u041d\u0410\u0417\u0410\u0414"
const TEXT_RESET := "\u0421\u0411\u0420\u041e\u0421"
const TEXT_CONFIRM := "\u041f\u041e\u0414\u0422\u0412\u0415\u0420\u0414\u0418\u0422\u042c"
const TEXT_NEXT := "\u0414\u0410\u041b\u0415\u0415"
const TEXT_FINISH := "\u0417\u0410\u0412\u0415\u0420\u0428\u0418\u0422\u042c"

const STATUS_HINT := "\u0418\u0437\u0443\u0447\u0438\u0442\u0435 \u043a\u043e\u0434, \u0432\u044b\u0431\u0435\u0440\u0438\u0442\u0435 \u0438\u0442\u043e\u0433\u043e\u0432\u044b\u0439 \u0446\u0432\u0435\u0442 \u0438 \u043d\u0430\u0436\u043c\u0438\u0442\u0435 \u041f\u041e\u0414\u0422\u0412\u0415\u0420\u0414\u0418\u0422\u042c."
const STATUS_INSPECTED := "\u0414\u0430\u043d\u043d\u044b\u0435 \u0438\u0441\u0442\u043e\u0447\u043d\u0438\u043a\u0430 \u043e\u0442\u043a\u0440\u044b\u0442\u044b."
const STATUS_OPTION_SELECTED := "\u0412\u0430\u0440\u0438\u0430\u043d\u0442 \u0432\u044b\u0431\u0440\u0430\u043d. \u041c\u043e\u0436\u043d\u043e \u043f\u043e\u0434\u0442\u0432\u0435\u0440\u0436\u0434\u0430\u0442\u044c."
const STATUS_NEXT_HINT := "\u041a\u043e\u0434 \u0432\u0437\u043b\u043e\u043c\u0430\u043d. \u0416\u043c\u0438\u0442\u0435 \u0414\u0410\u041b\u0415\u0415."
const STATUS_SOLVE_FIRST := "\u0421\u043d\u0430\u0447\u0430\u043b\u0430 \u0440\u0435\u0448\u0438\u0442\u0435 \u0443\u0440\u043e\u0432\u0435\u043d\u044c."
const STATUS_INSPECT_UNAVAILABLE := "\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u043e\u0442\u043a\u0440\u044b\u0442\u044c \u0438\u0441\u0442\u043e\u0447\u043d\u0438\u043a."
const EXPLAIN_HINT := "\u0422\u0430\u043f\u043d\u0438\u0442\u0435 \u043f\u043e \u00ab\u043f\u0440\u043e\u0432\u0435\u0440\u0438\u0442\u044c\u00bb \u0438 \u0432\u044b\u0431\u0435\u0440\u0438\u0442\u0435 \u0446\u0432\u0435\u0442 \u0438\u0442\u043e\u0433\u043e\u0432\u043e\u0433\u043e \u043f\u0440\u0430\u0432\u0438\u043b\u0430."

var levels: Array = []
var current_level_index: int = 0
var level_data: Dictionary = {}

var selected_option_id: String = ""
var option_buttons: Dictionary = {}
var option_by_id: Dictionary = {}

var inspect_count: int = 0
var reset_count: int = 0
var attempts: int = 0
var start_time_ms: int = 0
var trial_seq: int = 0
var task_session: Dictionary = {}

var inspect_open_count: int = 0
var unique_inspected_source_ids: Dictionary = {}
var inspect_same_source_repeat_count: int = 0
var option_select_count: int = 0
var option_change_count: int = 0
var confirm_attempt_count: int = 0
var reset_count_local: int = 0
var highlight_winner_count: int = 0
var diagnostics_open_count: int = 0
var changed_after_inspect: bool = false
var changed_after_fail: bool = false
var time_to_first_action_ms: int = -1
var time_to_first_inspect_ms: int = -1
var time_to_first_option_ms: int = -1
var time_to_first_confirm_ms: int = -1
var time_from_last_inspect_to_confirm_ms: int = -1
var last_inspect_ms: int = -1
var last_option_change_ms: int = -1
var awaiting_change_after_fail: bool = false

var level_solved: bool = false
var trial_locked: bool = false
var trace: Array = []
var stage_run_history_start: int = 0
var stage_level_ids: Dictionary = {}
var _body_scroll_installed: bool = false

@onready var main_layout: VBoxContainer = $SafeArea/MainLayout
@onready var body: BoxContainer = $SafeArea/MainLayout/Body
@onready var code_card: PanelContainer = $SafeArea/MainLayout/Body/CodeCard
@onready var decrypt_card: PanelContainer = $SafeArea/MainLayout/Body/DecryptCard

@onready var btn_back: Button = $SafeArea/MainLayout/Header/BtnBack
@onready var title_label: Label = $SafeArea/MainLayout/Header/TitleLabel
@onready var level_label: Label = $SafeArea/MainLayout/Header/LevelLabel
@onready var level_progress_bar: ProgressBar = $SafeArea/MainLayout/Header/LevelProgressBar
@onready var stability_bar: ProgressBar = $SafeArea/MainLayout/Header/StabilityBar

@onready var briefing_label: Label = $SafeArea/MainLayout/BriefingCard/BriefingLabel
@onready var code_title_label: Label = $SafeArea/MainLayout/Body/CodeCard/CodeVBox/CodeTitle
@onready var html_label: RichTextLabel = $SafeArea/MainLayout/Body/CodeCard/CodeVBox/HtmlLabel
@onready var css_label: RichTextLabel = $SafeArea/MainLayout/Body/CodeCard/CodeVBox/CssLabel
@onready var hint_line_label: Label = $SafeArea/MainLayout/Body/CodeCard/CodeVBox/HintRow/HintLine
@onready var decrypt_title_label: Label = $SafeArea/MainLayout/Body/DecryptCard/DecVBox/DecTitle
@onready var target_preview: Label = $SafeArea/MainLayout/Body/DecryptCard/DecVBox/TargetPreview
@onready var attack_bar: ProgressBar = $SafeArea/MainLayout/Body/DecryptCard/DecVBox/StrengthRow/AttackBar
@onready var defense_bar: ProgressBar = $SafeArea/MainLayout/Body/DecryptCard/DecVBox/StrengthRow/DefenseBar
@onready var options_vbox: VBoxContainer = $SafeArea/MainLayout/Body/DecryptCard/DecVBox/OptionsVBox
@onready var explain_label: Label = $SafeArea/MainLayout/Body/DecryptCard/DecVBox/ExplainLabel
@onready var status_label: Label = $SafeArea/MainLayout/StatusLabel

@onready var btn_reset: Button = $SafeArea/MainLayout/BottomBar/BtnReset
@onready var btn_confirm: Button = $SafeArea/MainLayout/BottomBar/BtnConfirm
@onready var btn_next: Button = $SafeArea/MainLayout/BottomBar/BtnNext
@onready var crt_overlay: ColorRect = $CanvasLayer/CRT_Overlay
@onready var inspector_popup: PopupPanel = $InspectorPopup

func _ready() -> void:
	if not GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.connect(_on_stability_changed)
	get_tree().root.size_changed.connect(_on_viewport_size_changed)
	if not I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.connect(_on_language_changed)

	_connect_ui_signals()
	_load_levels()
	if levels.is_empty():
		_show_error(_tr("case08.fr8c.load_error", "Не удалось загрузить уровни финального отчёта C."))
		return
	stage_run_history_start = GlobalMetrics.session_history.size()

	_apply_i18n()
	_install_body_scroll()

	var initial_index: int = clamp(GlobalMetrics.current_level_index, 0, max(0, levels.size() - 1))
	_start_level(initial_index)
	_apply_layout_mode()

func _exit_tree() -> void:
	if GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.disconnect(_on_stability_changed)
	if I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.disconnect(_on_language_changed)

func _connect_ui_signals() -> void:
	btn_back.pressed.connect(_on_back_pressed)
	btn_reset.pressed.connect(_on_reset_pressed)
	btn_confirm.pressed.connect(_on_confirm_pressed)
	btn_next.pressed.connect(_on_next_pressed)
	html_label.meta_clicked.connect(_on_meta_clicked)
	css_label.meta_clicked.connect(_on_meta_clicked)

func _on_language_changed(_code: String) -> void:
	_apply_i18n()
	_apply_runtime_i18n()

func _apply_i18n() -> void:
	title_label.text = _tr("case08.fr8c.title", TEXT_TITLE)
	btn_back.text = _tr("case08.common.back", TEXT_BACK)
	btn_reset.text = _tr("case08.common.reset", TEXT_RESET)
	btn_confirm.text = _tr("case08.common.confirm", TEXT_CONFIRM)
	if levels.is_empty():
		btn_next.text = _tr("case08.common.next", TEXT_NEXT)
	elif trial_locked and level_solved and btn_confirm.disabled and btn_reset.disabled and _is_last_level():
		btn_next.text = _tr("case08.common.exit", "ВЫХОД")
	else:
		btn_next.text = _tr("case08.common.finish", TEXT_FINISH) if _is_last_level() else _tr("case08.common.next", TEXT_NEXT)
	code_title_label.text = _tr("case08.fr8c.code_title", "КОД")
	decrypt_title_label.text = _tr("case08.fr8c.decrypt_title", "ДЕШИФРАТОР")
	hint_line_label.text = _tr("case08.fr8c.hint_line", "Нажмите по селектору для ПРОСМОТРА.")

func _apply_runtime_i18n() -> void:
	if levels.is_empty():
		return
	briefing_label.text = I18n.resolve_field(level_data, "briefing")
	target_preview.text = I18n.resolve_field(level_data, "target_text", {"default": _tr("case08.fr8c.target_default", "Секретный код")})
	_build_option_buttons()
	_render_code_window()

	if attempts > 0 and not selected_option_id.is_empty():
		var evaluation: Dictionary = FR8CScoring.evaluate(level_data, selected_option_id)
		var feedback_text: String = FR8CScoring.feedback_text(level_data, evaluation)
		var cascade_explanation: String = str(evaluation.get("cascade_explanation", "")).strip_edges()
		explain_label.text = cascade_explanation if not cascade_explanation.is_empty() else feedback_text
		_highlight_winning_rule(evaluation)
		if bool(evaluation.get("is_correct", false)):
			_set_status("%s %s" % [feedback_text, _tr("case08.fr8c.status.next_hint", STATUS_NEXT_HINT)], COLOR_OK)
		else:
			_set_status(
				_tr(
					"case08.fr8c.status.attack_vs_defense",
					"Ваш удар: {attack}, Щит: {defense}.",
					{
						"attack": int(evaluation.get("attack_strength", 0)),
						"defense": int(evaluation.get("defense_strength", 0))
					}
				),
				COLOR_ERR
			)
	elif not selected_option_id.is_empty():
		explain_label.text = _tr("case08.fr8c.explain_hint", EXPLAIN_HINT)
		_set_status(_tr("case08.fr8c.status.option_selected", STATUS_OPTION_SELECTED), COLOR_INFO)
	else:
		explain_label.text = _tr("case08.fr8c.explain_hint", EXPLAIN_HINT)
		_set_status(_tr("case08.fr8c.status.hint", STATUS_HINT), COLOR_INFO)

func _tr(key: String, default_text: String, params: Dictionary = {}) -> String:
	var merged: Dictionary = params.duplicate(true)
	if not merged.has("default"):
		merged["default"] = default_text
	return I18n.tr_key(key, merged)

func _load_levels() -> void:
	levels = FR8CData.load_levels(LEVELS_PATH)
	if SESSION_LEVEL_COUNT > 0 and levels.size() > SESSION_LEVEL_COUNT:
		var limited: Array = []
		for i in range(SESSION_LEVEL_COUNT):
			limited.append(levels[i])
		levels = limited
	stage_level_ids.clear()
	for level_var in levels:
		if typeof(level_var) != TYPE_DICTIONARY:
			continue
		var id_value: String = str((level_var as Dictionary).get("id", "")).strip_edges()
		if id_value.is_empty():
			continue
		stage_level_ids[id_value] = true

func _start_level(index: int) -> void:
	if levels.is_empty():
		return

	current_level_index = clamp(index, 0, levels.size() - 1)
	GlobalMetrics.current_level_index = current_level_index
	level_data = (levels[current_level_index] as Dictionary).duplicate(true)

	selected_option_id = ""
	option_buttons.clear()
	option_by_id.clear()
	_begin_trial_session()

	level_label.text = _build_level_label()
	_update_progress_ui()
	briefing_label.text = I18n.resolve_field(level_data, "briefing")
	target_preview.text = I18n.resolve_field(level_data, "target_text", {"default": _tr("case08.fr8c.target_default", "Секретный код")})
	target_preview.modulate = COLOR_INFO

	_build_option_buttons()
	_render_code_window()
	_reset_attempt(true)
	_update_stability_ui()
	_apply_layout_mode()

func _build_level_label() -> String:
	var progress_pct: int = int((float(current_level_index + 1) / maxf(1.0, float(levels.size()))) * 100.0)
	return "C | %s (%d/%d) — %d%%" % [
		str(level_data.get("id", "FR8-C")),
		current_level_index + 1,
		levels.size(),
		progress_pct
	]

func _update_progress_ui() -> void:
	if level_progress_bar == null:
		return
	var progress_pct: float = (float(current_level_index + 1) / maxf(1.0, float(levels.size()))) * 100.0
	level_progress_bar.value = progress_pct

func _is_last_level() -> bool:
	return current_level_index >= levels.size() - 1

func _begin_trial_session() -> void:
	trial_seq += 1
	start_time_ms = Time.get_ticks_msec()
	trace.clear()

	inspect_count = 0
	reset_count = 0
	attempts = 0
	inspect_open_count = 0
	unique_inspected_source_ids.clear()
	inspect_same_source_repeat_count = 0
	option_select_count = 0
	option_change_count = 0
	confirm_attempt_count = 0
	reset_count_local = 0
	highlight_winner_count = 0
	diagnostics_open_count = 0
	changed_after_inspect = false
	changed_after_fail = false
	time_to_first_action_ms = -1
	time_to_first_inspect_ms = -1
	time_to_first_option_ms = -1
	time_to_first_confirm_ms = -1
	time_from_last_inspect_to_confirm_ms = -1
	last_inspect_ms = -1
	last_option_change_ms = -1
	awaiting_change_after_fail = false

	var level_id: String = str(level_data.get("id", "FR8-C-00"))
	task_session = {
		"trial_seq": trial_seq,
		"quest_id": "CASE_08_FINAL_REPORT",
		"stage_id": "C",
		"task_id": level_id,
		"started_at_ticks": start_time_ms,
		"ended_at_ticks": 0,
		"events": []
	}
	_log_event("trial_started", {
		"trial_seq": trial_seq,
		"level_id": level_id,
		"target_default": str(I18n.resolve_field(level_data, "target_text", {"default": ""})),
		"rule_count": (level_data.get("rules", []) as Array).size(),
		"candidate_count": (level_data.get("options", []) as Array).size()
	})

func _elapsed_ms_now() -> int:
	if start_time_ms <= 0:
		return 0
	return maxi(0, Time.get_ticks_msec() - start_time_ms)

func _mark_first_action() -> void:
	if time_to_first_action_ms >= 0:
		return
	time_to_first_action_ms = _elapsed_ms_now()

func _build_option_buttons() -> void:
	for child in options_vbox.get_children():
		child.queue_free()
	option_buttons.clear()
	option_by_id.clear()

	for option_var in level_data.get("options", []) as Array:
		if typeof(option_var) != TYPE_DICTIONARY:
			continue
		var option_data: Dictionary = option_var as Dictionary
		var option_id: String = str(option_data.get("id", "")).strip_edges()
		if option_id.is_empty():
			continue

		option_by_id[option_id] = option_data

		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(0, 52)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var option_label: String = I18n.resolve_field(option_data, "label", {"default": str(option_data.get("label", option_id))})
		btn.text = "%s  [%s]" % [
			option_label,
			str(option_data.get("value", ""))
		]
		btn.pressed.connect(_on_option_pressed.bind(option_id))
		options_vbox.add_child(btn)
		option_buttons[option_id] = btn

	_refresh_option_state()
	_apply_compact_layout(_is_compact_phone())

func _render_code_window() -> void:
	var html_lines: Array[String] = []
	var html_raw: Array = level_data.get("html", []) as Array
	var html_keys: Array = level_data.get("html_keys", []) as Array
	var html_count: int = max(html_raw.size(), html_keys.size())
	for i in range(html_count):
		var fallback_line: String = str(html_raw[i]) if i < html_raw.size() else ""
		var line_text: String = fallback_line
		if i < html_keys.size():
			var key: String = str(html_keys[i]).strip_edges()
			if not key.is_empty():
				line_text = I18n.tr_key(key, {"default": fallback_line})
		if line_text.is_empty():
			continue
		html_lines.append("[color=#d2d2d2]%s[/color]" % _escape_bbcode(line_text))

	var inline_var: Variant = level_data.get("inline_decl", null)
	if inline_var != null and typeof(inline_var) == TYPE_DICTIONARY:
		html_lines.append("[url=inspect:inline][color=#ffca5f]%s[/color][/url]" % _escape_bbcode(_tr("case08.fr8c.inspect_inline", "style=\"color:...\" (проверить)")))

	if html_lines.is_empty():
		html_lines.append("-")
	html_label.text = "\n".join(html_lines)

	var css_lines: Array[String] = []
	var rules: Array = level_data.get("rules", []) as Array
	for i in range(rules.size()):
		var rule_var: Variant = rules[i]
		if typeof(rule_var) != TYPE_DICTIONARY:
			continue
		css_lines.append(_render_css_rule_bbcode(rule_var as Dictionary, i))

	if css_lines.is_empty():
		css_lines.append("-")
	css_label.text = "\n".join(css_lines)

func _reset_attempt(is_level_start: bool = false) -> void:
	if not is_level_start:
		_mark_first_action()
		reset_count_local += 1
		reset_count = reset_count_local
		_log_event("reset_pressed", {"reset_count": reset_count_local})
	_log_event("attempt_reset", {"level_start": is_level_start})
	_log_event("СБРОС", {"level_start": is_level_start})

	selected_option_id = ""
	level_solved = false
	trial_locked = false
	awaiting_change_after_fail = false

	attack_bar.value = 0
	defense_bar.value = 0
	btn_confirm.disabled = true
	btn_next.disabled = true
	btn_next.text = _tr("case08.common.finish", TEXT_FINISH) if _is_last_level() else _tr("case08.common.next", TEXT_NEXT)
	target_preview.modulate = COLOR_INFO
	explain_label.text = _tr("case08.fr8c.explain_hint", EXPLAIN_HINT)

	_refresh_option_state()
	_set_status(_tr("case08.fr8c.status.hint", STATUS_HINT), COLOR_INFO)

func _on_option_pressed(option_id: String) -> void:
	if trial_locked:
		return
	if not option_buttons.has(option_id):
		return

	_mark_first_action()
	option_select_count += 1
	var previous_option_id: String = selected_option_id
	if previous_option_id != option_id and not previous_option_id.is_empty():
		option_change_count += 1
	if time_to_first_option_ms < 0:
		time_to_first_option_ms = _elapsed_ms_now()
	selected_option_id = option_id
	last_option_change_ms = _elapsed_ms_now()
	if inspect_open_count > 0 and previous_option_id != option_id:
		changed_after_inspect = true
	if awaiting_change_after_fail and previous_option_id != option_id:
		changed_after_fail = true
		awaiting_change_after_fail = false
	var projected_attack: int = FR8CScoring.preview_attack_strength(level_data, selected_option_id)
	var attack_tween: Tween = create_tween()
	attack_tween.tween_property(attack_bar, "value", projected_attack, 0.4).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)

	var selected_button: Button = option_buttons.get(option_id, null) as Button
	if selected_button != null:
		selected_button.pivot_offset = selected_button.size / 2.0
		var button_tween: Tween = create_tween()
		button_tween.tween_property(selected_button, "scale", Vector2(0.9, 0.9), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		button_tween.tween_property(selected_button, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	_refresh_option_state()
	_set_status(_tr("case08.fr8c.status.option_selected", STATUS_OPTION_SELECTED), COLOR_INFO)
	var option_data: Dictionary = option_by_id.get(option_id, {}) as Dictionary
	_log_event("option_selected", {
		"option_id": option_id,
		"color_value": str(option_data.get("value", "")),
		"change_count": option_change_count
	})
	if AudioManager != null:
		AudioManager.play("click")

func _refresh_option_state() -> void:
	for option_id_var in option_buttons.keys():
		var option_id: String = str(option_id_var)
		var button: Button = option_buttons.get(option_id, null) as Button
		if button == null:
			continue
		button.modulate = COLOR_SELECTED if option_id == selected_option_id else Color(1, 1, 1, 1)

	var preview_color: Color = COLOR_INFO
	if option_by_id.has(selected_option_id):
		var option: Dictionary = option_by_id.get(selected_option_id, {}) as Dictionary
		preview_color = _color_from_hex(str(option.get("value", "")), COLOR_INFO)
	target_preview.modulate = preview_color

	btn_confirm.disabled = trial_locked or selected_option_id.is_empty()

func _on_meta_clicked(meta: Variant) -> void:
	var meta_value: String = str(meta).strip_edges()
	if not meta_value.begins_with("inspect:"):
		return
	_mark_first_action()

	var source_id: String = meta_value.substr("inspect:".length())
	if source_id.is_empty():
		return

	var source_data: Dictionary = FR8CScoring.inspect_source(level_data, source_id)
	if source_data.is_empty():
		_set_status(_tr("case08.fr8c.status.inspect_unavailable", STATUS_INSPECT_UNAVAILABLE), COLOR_WARN)
		return

	inspect_open_count += 1
	inspect_count = inspect_open_count
	if unique_inspected_source_ids.has(source_id):
		inspect_same_source_repeat_count += 1
	unique_inspected_source_ids[source_id] = true
	if time_to_first_inspect_ms < 0:
		time_to_first_inspect_ms = _elapsed_ms_now()
	last_inspect_ms = _elapsed_ms_now()
	_log_event("source_inspected", {
		"source_id": source_id,
		"selector": str(source_data.get("selector", "")),
		"weight": int(source_data.get("weight", 0)),
		"order": int(source_data.get("order", 0)),
		"important": bool(source_data.get("important", false)),
		"color": str(source_data.get("color", ""))
	})
	_show_inspector(source_data, get_viewport().get_mouse_position())
	_set_status(_tr("case08.fr8c.status.inspected", STATUS_INSPECTED), COLOR_INFO)
	if AudioManager != null:
		AudioManager.play("click")

func _show_inspector(source_data: Dictionary, at_position: Vector2) -> void:
	if inspector_popup == null or not inspector_popup.has_method("show_inspection"):
		return
	diagnostics_open_count += 1
	_log_event("diagnostics_opened", {"source_id": str(source_data.get("source_id", ""))})
	inspector_popup.call("show_inspection", source_data)
	var vp_size: Vector2 = get_viewport_rect().size
	inspector_popup.max_size = Vector2i(
		int(min(400.0, vp_size.x - 32.0)),
		int(min(300.0, vp_size.y - 64.0))
	)
	call_deferred("_position_inspector_popup", at_position)

func _position_inspector_popup(at_position: Vector2) -> void:
	if inspector_popup == null or not inspector_popup.visible:
		return
	var vp_size: Vector2 = get_viewport_rect().size
	var popup_size: Vector2 = Vector2(inspector_popup.size)
	if popup_size.x <= 0.0 or popup_size.y <= 0.0:
		popup_size = inspector_popup.get_contents_minimum_size()
	var safe_pos: Vector2 = Vector2(
		clampf(at_position.x, 8.0, maxf(8.0, vp_size.x - popup_size.x - 8.0)),
		clampf(at_position.y, 8.0, maxf(8.0, vp_size.y - popup_size.y - 8.0))
	)
	inspector_popup.position = Vector2i(int(safe_pos.x), int(safe_pos.y))

func _on_confirm_pressed() -> void:
	if trial_locked:
		return
	_mark_first_action()

	if selected_option_id.is_empty():
		_set_status(FR8CScoring.feedback_text(level_data, {"error_code": FR8CScoring.ERROR_EMPTY_CHOICE}), COLOR_WARN)
		return

	trial_locked = true
	btn_confirm.disabled = true
	confirm_attempt_count += 1
	attempts = confirm_attempt_count
	if time_to_first_confirm_ms < 0:
		time_to_first_confirm_ms = _elapsed_ms_now()
	if last_inspect_ms >= 0:
		time_from_last_inspect_to_confirm_ms = maxi(0, _elapsed_ms_now() - last_inspect_ms)
	else:
		time_from_last_inspect_to_confirm_ms = -1
	_log_event("confirm_pressed", {
		"selected_option_id": selected_option_id,
		"attempt": confirm_attempt_count,
		"time_from_last_inspect_to_confirm_ms": time_from_last_inspect_to_confirm_ms
	})

	var evaluation: Dictionary = FR8CScoring.evaluate(level_data, selected_option_id)
	var feedback_text: String = FR8CScoring.feedback_text(level_data, evaluation)
	var cascade_explanation: String = str(evaluation.get("cascade_explanation", "")).strip_edges()
	_highlight_winning_rule(evaluation)
	var winning_source_id: String = str(evaluation.get("winner_source_id", evaluation.get("winning_source_id", ""))).strip_edges()
	if not winning_source_id.is_empty():
		highlight_winner_count += 1
	var elapsed_ms: int = _elapsed_ms_now()
	var tffa_ms: int = elapsed_ms if time_to_first_action_ms < 0 else time_to_first_action_ms
	var level_id: String = str(level_data.get("id", "FR8-C-00"))
	var match_key: String = "FR8_C|%s|%d" % [level_id, GlobalMetrics.session_history.size()]
	var is_correct: bool = bool(evaluation.get("is_correct", false))
	var error_code: String = str(evaluation.get("error_code", FR8CScoring.ERROR_SPECIFICITY))
	var outcome_code: String = _outcome_code_for_c(is_correct, error_code)
	var mastery_block_reason: String = _mastery_block_reason_for_c(is_correct, outcome_code)

	_log_event("confirm_result", {
		"is_correct": is_correct,
		"error_type": error_code,
		"winning_source_id": winning_source_id,
		"winner_reason": cascade_explanation,
		"selected_option": selected_option_id,
		"outcome_code": outcome_code
	})
	task_session["ended_at_ticks"] = Time.get_ticks_msec()

	var payload: Dictionary = {
		"quest_id": "CASE_08_FINAL_REPORT",
		"stage": "C",
		"level_id": level_id,
		"format": "CSS_CASCADE",
		"match_key": match_key,
		"trial_seq": trial_seq,
		"selected": (evaluation.get("selected", {}) as Dictionary).duplicate(true),
		"selected_option_id": selected_option_id,
		"correct_option_id": str(evaluation.get("correct_option_id", "")),
		"winner_source_id": winning_source_id,
		"winner": (evaluation.get("winner", {}) as Dictionary).duplicate(true),
		"winner_source": winning_source_id,
		"winner_reason": cascade_explanation,
		"cascade_explanation": cascade_explanation,
		"elapsed_ms": elapsed_ms,
		"time_to_first_action_ms": tffa_ms,
		"inspect_count": inspect_open_count,
		"reset_count": reset_count_local,
		"attempts": confirm_attempt_count,
		"confirm_attempt_count": confirm_attempt_count,
		"inspect_open_count": inspect_open_count,
		"unique_inspected_source_count": unique_inspected_source_ids.size(),
		"inspect_same_source_repeat_count": inspect_same_source_repeat_count,
		"option_select_count": option_select_count,
		"option_change_count": option_change_count,
		"highlight_winner_count": highlight_winner_count,
		"diagnostics_open_count": diagnostics_open_count,
		"changed_after_inspect": changed_after_inspect,
		"changed_after_fail": changed_after_fail,
		"time_to_first_inspect_ms": time_to_first_inspect_ms,
		"time_to_first_option_ms": time_to_first_option_ms,
		"time_to_first_confirm_ms": time_to_first_confirm_ms,
		"time_from_last_inspect_to_confirm_ms": time_from_last_inspect_to_confirm_ms,
		"winning_source_id": winning_source_id,
		"selected_option": selected_option_id,
		"points": int(evaluation.get("points", 0)),
		"max_points": int(evaluation.get("max_points", 2)),
		"is_fit": bool(evaluation.get("is_fit", false)),
		"is_correct": is_correct,
		"stability_delta": int(evaluation.get("stability_delta", -25)),
		"verdict_code": str(evaluation.get("verdict_code", "FAIL")),
		"error_code": error_code,
		"outcome_code": outcome_code,
		"mastery_block_reason": mastery_block_reason,
		"trace": trace.duplicate(true),
		"task_session": task_session.duplicate(true)
	}

	var actual_attack: int = int(evaluation.get("attack_strength", 0))
	var actual_defense: int = int(evaluation.get("defense_strength", 0))
	var bars_tween: Tween = create_tween()
	bars_tween.set_parallel(true)
	bars_tween.tween_property(attack_bar, "value", actual_attack, 0.6).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	bars_tween.tween_property(defense_bar, "value", actual_defense, 0.6).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	if AudioManager != null:
		AudioManager.play("relay" if is_correct else "click")
	await get_tree().create_timer(0.6).timeout

	GlobalMetrics.register_trial(payload)
	_update_stability_ui()

	explain_label.text = cascade_explanation if not cascade_explanation.is_empty() else feedback_text

	if is_correct:
		level_solved = true
		trial_locked = true
		awaiting_change_after_fail = false
		btn_confirm.disabled = true
		btn_next.disabled = false
		btn_next.text = _tr("case08.common.finish", TEXT_FINISH) if _is_last_level() else _tr("case08.common.next", TEXT_NEXT)
		_set_status("%s %s" % [feedback_text, _tr("case08.fr8c.status.next_hint", STATUS_NEXT_HINT)], COLOR_OK)

		var winner_data: Dictionary = evaluation.get("winner", {}) as Dictionary
		var winner_color: Color = _color_from_hex(str(winner_data.get("color", "")), COLOR_OK)
		var flash_tween: Tween = create_tween()
		flash_tween.tween_property(target_preview, "modulate", Color(3.0, 3.0, 3.0, 1.0), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		flash_tween.tween_property(target_preview, "modulate", winner_color, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		level_solved = false
		trial_locked = false
		awaiting_change_after_fail = true
		btn_next.disabled = true
		btn_confirm.disabled = false
		_set_status(
			"%s %s" % [
				feedback_text,
				_tr(
					"case08.fr8c.status.attack_vs_defense",
					"Ваш удар: {attack}, Щит: {defense}.",
					{
						"attack": actual_attack,
						"defense": actual_defense
					}
				)
			],
			COLOR_ERR
		)
		var defense_flash: Tween = create_tween()
		defense_flash.tween_property(defense_bar, "modulate", Color(2.0, 0.25, 0.25, 1.0), 0.12)
		defense_flash.tween_property(defense_bar, "modulate", Color.WHITE, 0.16)
		defense_flash.tween_property(defense_bar, "modulate", Color(2.0, 0.25, 0.25, 1.0), 0.12)
		defense_flash.tween_property(defense_bar, "modulate", Color.WHITE, 0.16)
		_trigger_glitch()
		_shake_main_layout()
		if AudioManager != null:
			AudioManager.play("error")

func _on_next_pressed() -> void:
	if not level_solved:
		_set_status(_tr("case08.fr8c.status.solve_first", STATUS_SOLVE_FIRST), COLOR_WARN)
		return

	if _is_last_level():
		if btn_next.text == _tr("case08.common.exit", "ВЫХОД"):
			GlobalMetrics.current_level_index = 0
			get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")
			return
		_show_session_summary()
		return

	var from_level_id: String = str(level_data.get("id", "FR8-C-00"))
	var from_index: int = current_level_index
	var to_index: int = current_level_index + 1
	_log_event("NEXT_PRESSED", {
		"from_level_id": from_level_id,
		"from_index": from_index,
		"to_index": to_index
	})
	_start_level(to_index)

func _show_session_summary() -> void:
	trial_locked = true
	level_solved = true
	btn_confirm.disabled = true
	btn_reset.disabled = true
	btn_next.text = _tr("case08.common.exit", "ВЫХОД")
	btn_next.disabled = false
	level_label.text = "C | ИТОГИ"
	if level_progress_bar != null:
		level_progress_bar.value = 100.0

	var latest_by_level: Dictionary = {}
	for idx in range(stage_run_history_start, GlobalMetrics.session_history.size()):
		var entry_var: Variant = GlobalMetrics.session_history[idx]
		if typeof(entry_var) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_var as Dictionary
		if str(entry.get("quest_id", "")) != "CASE_08_FINAL_REPORT":
			continue
		if str(entry.get("stage", "")) != "C":
			continue
		var level_id: String = str(entry.get("level_id", "")).strip_edges()
		if level_id.is_empty() or not stage_level_ids.has(level_id):
			continue
		latest_by_level[level_id] = entry

	var total: int = levels.size()
	var correct: int = 0
	var total_ms: int = 0
	for level_var in levels:
		if typeof(level_var) != TYPE_DICTIONARY:
			continue
		var level_id: String = str((level_var as Dictionary).get("id", "")).strip_edges()
		if level_id.is_empty():
			continue
		if not latest_by_level.has(level_id):
			continue
		var row: Dictionary = latest_by_level[level_id] as Dictionary
		if bool(row.get("is_correct", false)):
			correct += 1
		total_ms += int(row.get("elapsed_ms", 0))

	var pct: int = int((float(correct) / maxf(1.0, float(total))) * 100.0)
	var avg_sec: float = (float(total_ms) / 1000.0) / maxf(1.0, float(total))

	briefing_label.text = "СЕССИЯ ЗАВЕРШЕНА\n\nПравильно: %d / %d (%d%%)\nСреднее время: %.1f с\n" % [correct, total, pct, avg_sec]
	explain_label.text = ""
	target_preview.text = "ИТОГ"
	target_preview.modulate = COLOR_INFO
	attack_bar.value = 0.0
	defense_bar.value = 0.0
	for child in options_vbox.get_children():
		child.queue_free()
	css_label.text = "-"

	if pct >= 90:
		_set_status("Сессия пройдена успешно.", COLOR_OK)
	elif pct >= 60:
		_set_status("Рекомендуется повторить.", COLOR_WARN)
	else:
		_set_status("Нужно повторить материал.", COLOR_ERR)

func _on_back_pressed() -> void:
	GlobalMetrics.current_level_index = 0
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _on_reset_pressed() -> void:
	_reset_attempt(false)
	if AudioManager != null:
		AudioManager.play("click")

func _on_viewport_size_changed() -> void:
	_apply_layout_mode()
	if inspector_popup != null and inspector_popup.visible:
		_position_inspector_popup(Vector2(inspector_popup.position))

func _install_body_scroll() -> void:
	if _body_scroll_installed:
		return
	if main_layout == null or body == null:
		return
	var existing_scroll: ScrollContainer = main_layout.get_node_or_null("BodyScroll") as ScrollContainer
	if existing_scroll != null and existing_scroll.get_node_or_null("Body") != null:
		_body_scroll_installed = true
		return
	var scroll := ScrollContainer.new()
	scroll.name = "BodyScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.follow_focus = true
	var idx: int = body.get_index()
	main_layout.add_child(scroll)
	main_layout.move_child(scroll, idx)
	body.reparent(scroll)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body_scroll_installed = true

func _is_compact_phone() -> bool:
	var size: Vector2 = get_viewport_rect().size
	return (size.x >= size.y and size.y <= 420.0) or (size.y > size.x and size.x <= 520.0)

func _apply_compact_layout(compact: bool) -> void:
	code_card.custom_minimum_size.y = 120.0 if compact else 0.0
	decrypt_card.custom_minimum_size.y = 120.0 if compact else 0.0
	html_label.custom_minimum_size.y = 84.0 if compact else 120.0
	css_label.custom_minimum_size.y = 110.0 if compact else 170.0
	target_preview.custom_minimum_size.y = 44.0 if compact else 56.0
	target_preview.add_theme_font_size_override("font_size", 22 if compact else 26)
	explain_label.custom_minimum_size.y = 44.0 if compact else 58.0
	btn_back.custom_minimum_size = Vector2(96.0 if compact else 116.0, 44.0 if compact else 56.0)
	btn_reset.custom_minimum_size.y = 44.0 if compact else 56.0
	btn_confirm.custom_minimum_size.y = 44.0 if compact else 56.0
	btn_next.custom_minimum_size.y = 44.0 if compact else 56.0
	for option_button in option_buttons.values():
		if option_button is Button:
			(option_button as Button).custom_minimum_size.y = 44.0 if compact else 52.0

func _apply_layout_mode() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var landscape: bool = viewport_size.x > viewport_size.y
	var compact: bool = _is_compact_phone()
	body.vertical = not landscape

	if landscape:
		if body.get_child(0) != code_card:
			body.move_child(code_card, 0)
			body.move_child(decrypt_card, 1)
	else:
		if body.get_child(0) != code_card:
			body.move_child(code_card, 0)
			body.move_child(decrypt_card, 1)
	_apply_compact_layout(compact)

func _set_status(text_value: String, color_value: Color) -> void:
	status_label.text = text_value
	status_label.modulate = color_value

func _trigger_glitch() -> void:
	var shader_material: ShaderMaterial = crt_overlay.material as ShaderMaterial
	if shader_material == null:
		return
	shader_material.set_shader_parameter("glitch_strength", 1.0)
	var tween: Tween = create_tween()
	tween.tween_method(func(value: float) -> void: shader_material.set_shader_parameter("glitch_strength", value), 1.0, 0.0, 0.25)

func _shake_main_layout() -> void:
	var origin: Vector2 = main_layout.position
	var tween: Tween = create_tween()
	for _i in 4:
		tween.tween_property(main_layout, "position", origin + Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0)), 0.03)
	tween.tween_property(main_layout, "position", origin, 0.04)

func _outcome_code_for_c(is_correct: bool, error_code: String) -> String:
	if is_correct:
		return "SUCCESS"
	var normalized_error: String = error_code.strip_edges().to_upper()
	match normalized_error:
		"SPECIFICITY_ERROR":
			return "SPECIFICITY_ERROR"
		"ORDER_TIE":
			return "ORDER_TIE_ERROR"
		"IMPORTANT_MISSED":
			return "IMPORTANT_ERROR"
		"INLINE_OVERRIDE":
			return "INLINE_ERROR"
		"EMPTY_CHOICE":
			return "EMPTY_CHOICE"
		_:
			return "CASCADE_CONFUSION"

func _mastery_block_reason_for_c(is_correct: bool, outcome_code: String) -> String:
	if reset_count_local >= 3:
		return "RESET_OVERUSE"
	if confirm_attempt_count >= 3:
		return "MULTI_CONFIRM_GUESSING"
	if not is_correct:
		if inspect_open_count > 0 and not changed_after_inspect:
			return "INSPECT_DEPENDENCY"
		if outcome_code in ["SPECIFICITY_ERROR", "ORDER_TIE_ERROR", "IMPORTANT_ERROR", "INLINE_ERROR", "CASCADE_CONFUSION"]:
			if option_change_count >= 2:
				return "SPECIFICITY_UNSTABLE"
			return "CASCADE_RULE_CONFUSION"
	return "NONE"

func _log_event(event_name: String, data: Dictionary = {}) -> void:
	var t_ms: int = _elapsed_ms_now()
	var event_payload: Dictionary = data.duplicate(true)
	var event_row: Dictionary = {
		"name": event_name,
		"event": event_name,
		"t_ms": t_ms,
		"payload": event_payload.duplicate(true),
		"data": event_payload.duplicate(true)
	}
	trace.append(event_row)
	if task_session.is_empty():
		return
	var events: Array = task_session.get("events", [])
	events.append({
		"name": event_name,
		"t_ms": t_ms,
		"payload": event_payload.duplicate(true)
	})
	task_session["events"] = events

func _show_error(message: String) -> void:
	_set_status(message, COLOR_ERR)
	btn_confirm.disabled = true
	btn_reset.disabled = true
	btn_next.disabled = true

func _on_stability_changed(_new_value: float, _delta: float) -> void:
	_update_stability_ui()

func _update_stability_ui() -> void:
	stability_bar.value = GlobalMetrics.stability
	var overlay_controller: Node = get_node_or_null("CanvasLayer")
	if overlay_controller != null and overlay_controller.has_method("set_danger_level"):
		overlay_controller.call("set_danger_level", GlobalMetrics.stability)
		return
	var shared_overlay: Node = get_tree().get_first_node_in_group("noir_overlay")
	if shared_overlay != null and shared_overlay.has_method("set_danger_level"):
		shared_overlay.call("set_danger_level", GlobalMetrics.stability)

func _render_css_rule_bbcode(rule: Dictionary, index: int) -> String:
	var source_id_raw: String = str(rule.get("source_id", "R%s" % str(index + 1))).strip_edges()
	var source_id: String = _safe_inspect_source_id(source_id_raw)
	if source_id.is_empty():
		source_id = "R%s" % str(index + 1)
	var selector: String = _selector_of(rule)
	var decl: Dictionary = rule.get("decl", {}) as Dictionary
	var prop_value: String = str(decl.get("prop", "color")).strip_edges().to_lower()
	var color_value: String = str(decl.get("value", "")).strip_edges().to_lower()
	var bb_color: String = _bbcode_color(color_value)
	var important_suffix: String = " !important" if bool(rule.get("important", false)) else ""
	var order_value: int = int(rule.get("order", index + 1))
	var weight_value: int = int(rule.get("weight", 0))
	return (
		"[url=inspect:%s][color=#ffca5f]%s[/color][/url] { %s: [color=%s]%s[/color]%s; } [color=#8d8d8d]w:%d o:%d[/color]"
		% [
			source_id,
			_escape_bbcode(selector),
			_escape_bbcode(prop_value),
			bb_color,
			_escape_bbcode(color_value),
			important_suffix,
			weight_value,
			order_value
		]
	)

func _safe_inspect_source_id(source_id: String) -> String:
	return source_id.replace("[", "").replace("]", "").replace("\"", "").strip_edges()

func _highlight_winning_rule(evaluation: Dictionary) -> void:
	var winning_source_id: String = str(
		evaluation.get("winning_source_id", evaluation.get("winner_source_id", ""))
	).strip_edges()
	if winning_source_id.is_empty():
		return

	var rules: Array = level_data.get("rules", []) as Array
	var css_lines: Array[String] = []
	for i in range(rules.size()):
		var rule_var: Variant = rules[i]
		if typeof(rule_var) != TYPE_DICTIONARY:
			continue
		var rule: Dictionary = rule_var as Dictionary
		var source_id: String = str(rule.get("source_id", "R%s" % str(i + 1))).strip_edges()
		var selector: String = _selector_of(rule)
		var decl: Dictionary = rule.get("decl", {}) as Dictionary
		var prop: String = str(decl.get("prop", "color")).strip_edges()
		var value: String = str(decl.get("value", "")).strip_edges()
		var important: bool = bool(rule.get("important", false))
		var weight: int = int(rule.get("weight", 0))
		var imp_text: String = " !important" if important else ""
		var line: String = "%s { %s: %s%s; } /* w=%d */" % [selector, prop, value, imp_text, weight]
		if source_id == winning_source_id:
			css_lines.append("[color=#4eff6a][b]-> %s[/b][/color]" % _escape_bbcode(line))
		else:
			css_lines.append("[color=#888888]  %s[/color]" % _escape_bbcode(line))

	if css_lines.is_empty():
		css_lines.append("-")
	css_label.text = "\n".join(css_lines)

func _selector_of(rule: Dictionary) -> String:
	var selector: String = str(rule.get("selector", "")).strip_edges()
	if not selector.is_empty():
		return selector
	return str(rule.get(".selector", "")).strip_edges()

func _escape_bbcode(text_value: String) -> String:
	return text_value.replace("[", "[lb]").replace("]", "[rb]")

func _color_from_hex(hex_value: String, fallback: Color) -> Color:
	var value: String = hex_value.strip_edges()
	if value.is_empty():
		return fallback
	return Color.from_string(value, fallback)

func _bbcode_color(color_value: String) -> String:
	var value: String = color_value.strip_edges()
	if value.begins_with("#") and (value.length() == 4 or value.length() == 7 or value.length() == 9):
		return value
	return "#ffffff"
