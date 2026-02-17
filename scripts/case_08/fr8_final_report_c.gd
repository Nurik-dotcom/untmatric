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
const EXPLAIN_HINT := "\u0422\u0430\u043f\u043d\u0438\u0442\u0435 \u043f\u043e INSPECT \u0438 \u0432\u044b\u0431\u0435\u0440\u0438\u0442\u0435 \u0446\u0432\u0435\u0442 \u0438\u0442\u043e\u0433\u043e\u0432\u043e\u0433\u043e \u043f\u0440\u0430\u0432\u0438\u043b\u0430."

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

var level_solved: bool = false
var trial_locked: bool = false
var trace: Array = []

@onready var main_layout: VBoxContainer = $SafeArea/MainLayout
@onready var body: BoxContainer = $SafeArea/MainLayout/Body
@onready var code_card: PanelContainer = $SafeArea/MainLayout/Body/CodeCard
@onready var decrypt_card: PanelContainer = $SafeArea/MainLayout/Body/DecryptCard

@onready var btn_back: Button = $SafeArea/MainLayout/Header/BtnBack
@onready var title_label: Label = $SafeArea/MainLayout/Header/TitleLabel
@onready var level_label: Label = $SafeArea/MainLayout/Header/LevelLabel
@onready var stability_bar: ProgressBar = $SafeArea/MainLayout/Header/StabilityBar

@onready var briefing_label: Label = $SafeArea/MainLayout/BriefingCard/BriefingLabel
@onready var html_label: RichTextLabel = $SafeArea/MainLayout/Body/CodeCard/CodeVBox/HtmlLabel
@onready var css_label: RichTextLabel = $SafeArea/MainLayout/Body/CodeCard/CodeVBox/CssLabel
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

	_connect_ui_signals()
	_load_levels()
	if levels.is_empty():
		_show_error("\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u0437\u0430\u0433\u0440\u0443\u0437\u0438\u0442\u044c \u0443\u0440\u043e\u0432\u043d\u0438 Final Report C.")
		return

	title_label.text = TEXT_TITLE
	btn_back.text = TEXT_BACK
	btn_reset.text = TEXT_RESET
	btn_confirm.text = TEXT_CONFIRM
	btn_next.text = TEXT_NEXT

	var initial_index: int = clamp(GlobalMetrics.current_level_index, 0, max(0, levels.size() - 1))
	_start_level(initial_index)
	_apply_layout_mode()

func _exit_tree() -> void:
	if GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.disconnect(_on_stability_changed)

func _connect_ui_signals() -> void:
	btn_back.pressed.connect(_on_back_pressed)
	btn_reset.pressed.connect(_on_reset_pressed)
	btn_confirm.pressed.connect(_on_confirm_pressed)
	btn_next.pressed.connect(_on_next_pressed)
	html_label.meta_clicked.connect(_on_meta_clicked)
	css_label.meta_clicked.connect(_on_meta_clicked)

func _load_levels() -> void:
	levels = FR8CData.load_levels(LEVELS_PATH)
	if SESSION_LEVEL_COUNT > 0 and levels.size() > SESSION_LEVEL_COUNT:
		var limited: Array = []
		for i in range(SESSION_LEVEL_COUNT):
			limited.append(levels[i])
		levels = limited

func _start_level(index: int) -> void:
	if levels.is_empty():
		return

	current_level_index = clamp(index, 0, levels.size() - 1)
	GlobalMetrics.current_level_index = current_level_index
	level_data = (levels[current_level_index] as Dictionary).duplicate(true)

	selected_option_id = ""
	option_buttons.clear()
	option_by_id.clear()
	inspect_count = 0
	reset_count = 0
	attempts = 0
	trace.clear()
	start_time_ms = Time.get_ticks_msec()

	level_label.text = _build_level_label()
	briefing_label.text = str(level_data.get("briefing", ""))
	target_preview.text = str(level_data.get("target_text", "\u0421\u0435\u043a\u0440\u0435\u0442\u043d\u044b\u0439 \u043a\u043e\u0434"))
	target_preview.modulate = COLOR_INFO

	_build_option_buttons()
	_render_code_window()
	_log_event("LEVEL_START", {
		"level_id": str(level_data.get("id", "FR8-C")),
		"index": current_level_index
	})
	_reset_attempt(true)
	_update_stability_ui()
	_apply_layout_mode()

func _build_level_label() -> String:
	return "C | %s (%d/%d)" % [
		str(level_data.get("id", "FR8-C")),
		current_level_index + 1,
		levels.size()
	]

func _is_last_level() -> bool:
	return current_level_index >= levels.size() - 1

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
		btn.text = "%s  [%s]" % [
			str(option_data.get("label", option_id)),
			str(option_data.get("value", ""))
		]
		btn.pressed.connect(_on_option_pressed.bind(option_id))
		options_vbox.add_child(btn)
		option_buttons[option_id] = btn

	_refresh_option_state()

func _render_code_window() -> void:
	var html_lines: Array[String] = []
	for line_var in level_data.get("html", []) as Array:
		html_lines.append("[color=#d2d2d2]%s[/color]" % _escape_bbcode(str(line_var)))

	var inline_var: Variant = level_data.get("inline_decl", null)
	if inline_var != null and typeof(inline_var) == TYPE_DICTIONARY:
		html_lines.append("[url=inspect:inline][color=#ffca5f]style=\"color:...\" (inspect)[/color][/url]")

	if html_lines.is_empty():
		html_lines.append("-")
	html_label.text = "\n".join(html_lines)

	var css_lines: Array[String] = []
	var rules: Array = level_data.get("rules", []) as Array
	for i in range(rules.size()):
		var rule_var: Variant = rules[i]
		if typeof(rule_var) != TYPE_DICTIONARY:
			continue
		var rule: Dictionary = rule_var as Dictionary
		var source_id: String = str(rule.get("source_id", "R%s" % str(i + 1))).strip_edges()
		var selector: String = _selector_of(rule)
		var decl: Dictionary = rule.get("decl", {}) as Dictionary
		var color_value: String = str(decl.get("value", "")).strip_edges().to_lower()
		var bb_color: String = _bbcode_color(color_value)
		var important_suffix: String = " !important" if bool(rule.get("important", false)) else ""
		var order_value: int = int(rule.get("order", i + 1))
		var weight_value: int = int(rule.get("weight", 0))

		css_lines.append(
			"[url=inspect:%s][color=#ffca5f]%s[/color][/url] { color: [color=%s]%s[/color]%s; } [color=#8d8d8d]w:%d o:%d[/color]" % [
				source_id,
				_escape_bbcode(selector),
				bb_color,
				_escape_bbcode(color_value),
				important_suffix,
				weight_value,
				order_value
			]
		)

	if css_lines.is_empty():
		css_lines.append("-")
	css_label.text = "\n".join(css_lines)

func _reset_attempt(is_level_start: bool = false) -> void:
	if not is_level_start:
		reset_count += 1
	_log_event("RESET", {"level_start": is_level_start})

	selected_option_id = ""
	level_solved = false
	trial_locked = false

	attack_bar.value = 0
	defense_bar.value = 0
	btn_confirm.disabled = true
	btn_next.disabled = true
	btn_next.text = TEXT_FINISH if _is_last_level() else TEXT_NEXT
	target_preview.modulate = COLOR_INFO
	explain_label.text = EXPLAIN_HINT

	_refresh_option_state()
	_set_status(STATUS_HINT, COLOR_INFO)

func _on_option_pressed(option_id: String) -> void:
	if trial_locked:
		return
	if not option_buttons.has(option_id):
		return

	selected_option_id = option_id
	attack_bar.value = FR8CScoring.preview_attack_strength(level_data, selected_option_id)
	_refresh_option_state()
	_set_status(STATUS_OPTION_SELECTED, COLOR_INFO)
	_log_event("OPTION_SELECTED", {"option_id": option_id})
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

	var source_id: String = meta_value.substr("inspect:".length())
	if source_id.is_empty():
		return

	var source_data: Dictionary = FR8CScoring.inspect_source(level_data, source_id)
	if source_data.is_empty():
		_set_status(STATUS_INSPECT_UNAVAILABLE, COLOR_WARN)
		return

	inspect_count += 1
	_log_event("INSPECT", {"source_id": source_id})
	if inspector_popup != null and inspector_popup.has_method("show_inspection"):
		inspector_popup.call("show_inspection", source_data)
	_set_status(STATUS_INSPECTED, COLOR_INFO)
	if AudioManager != null:
		AudioManager.play("click")

func _on_confirm_pressed() -> void:
	if trial_locked:
		return

	if selected_option_id.is_empty():
		_set_status(FR8CScoring.feedback_text(level_data, {"error_code": FR8CScoring.ERROR_EMPTY_CHOICE}), COLOR_WARN)
		return

	attempts += 1
	_log_event("CONFIRM_PRESSED", {
		"selected_option_id": selected_option_id,
		"attempt": attempts
	})

	var evaluation: Dictionary = FR8CScoring.evaluate(level_data, selected_option_id)
	var feedback_text: String = FR8CScoring.feedback_text(level_data, evaluation)
	var elapsed_ms: int = Time.get_ticks_msec() - start_time_ms
	var level_id: String = str(level_data.get("id", "FR8-C-00"))
	var match_key: String = "FR8_C|%s|%d" % [level_id, GlobalMetrics.session_history.size()]

	var payload: Dictionary = {
		"quest_id": "CASE_08_FINAL_REPORT",
		"stage": "C",
		"level_id": level_id,
		"format": "CSS_CASCADE",
		"match_key": match_key,
		"selected_option_id": selected_option_id,
		"correct_option_id": str(evaluation.get("correct_option_id", "")),
		"winner_source_id": str(evaluation.get("winner_source_id", "")),
		"winner": (evaluation.get("winner", {}) as Dictionary).duplicate(true),
		"elapsed_ms": elapsed_ms,
		"inspect_count": inspect_count,
		"reset_count": reset_count,
		"attempts": attempts,
		"points": int(evaluation.get("points", 0)),
		"max_points": int(evaluation.get("max_points", 2)),
		"is_fit": bool(evaluation.get("is_fit", false)),
		"is_correct": bool(evaluation.get("is_correct", false)),
		"stability_delta": int(evaluation.get("stability_delta", -25)),
		"verdict_code": str(evaluation.get("verdict_code", "FAIL")),
		"error_code": str(evaluation.get("error_code", FR8CScoring.ERROR_SPECIFICITY)),
		"trace": trace.duplicate(true)
	}
	GlobalMetrics.register_trial(payload)
	_update_stability_ui()

	attack_bar.value = int(evaluation.get("attack_strength", 0))
	defense_bar.value = int(evaluation.get("defense_strength", 0))
	explain_label.text = feedback_text

	if bool(evaluation.get("is_correct", false)):
		level_solved = true
		trial_locked = true
		btn_confirm.disabled = true
		btn_next.disabled = false
		btn_next.text = TEXT_FINISH if _is_last_level() else TEXT_NEXT
		_set_status("%s %s" % [feedback_text, STATUS_NEXT_HINT], COLOR_OK)

		var winner_data: Dictionary = evaluation.get("winner", {}) as Dictionary
		target_preview.modulate = _color_from_hex(str(winner_data.get("color", "")), COLOR_OK)
		if AudioManager != null:
			AudioManager.play("relay")
	else:
		level_solved = false
		trial_locked = false
		btn_next.disabled = true
		btn_confirm.disabled = false
		_set_status(feedback_text, COLOR_ERR)
		_trigger_glitch()
		_shake_main_layout()
		if AudioManager != null:
			AudioManager.play("error")

func _on_next_pressed() -> void:
	if not level_solved:
		_set_status(STATUS_SOLVE_FIRST, COLOR_WARN)
		return

	var from_level_id: String = str(level_data.get("id", "FR8-C-00"))
	var from_index: int = current_level_index
	if _is_last_level():
		_log_event("NEXT_PRESSED", {
			"from_level_id": from_level_id,
			"from_index": from_index,
			"to_index": -1
		})
		GlobalMetrics.current_level_index = 0
		get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")
		return

	var to_index: int = current_level_index + 1
	_log_event("NEXT_PRESSED", {
		"from_level_id": from_level_id,
		"from_index": from_index,
		"to_index": to_index
	})
	_start_level(to_index)

func _on_back_pressed() -> void:
	GlobalMetrics.current_level_index = 0
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _on_reset_pressed() -> void:
	_reset_attempt(false)
	if AudioManager != null:
		AudioManager.play("click")

func _on_viewport_size_changed() -> void:
	_apply_layout_mode()

func _apply_layout_mode() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var landscape: bool = viewport_size.x > viewport_size.y
	body.vertical = not landscape

	if landscape:
		if body.get_child(0) != code_card:
			body.move_child(code_card, 0)
			body.move_child(decrypt_card, 1)
	else:
		if body.get_child(0) != code_card:
			body.move_child(code_card, 0)
			body.move_child(decrypt_card, 1)

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

func _log_event(event_name: String, data: Dictionary = {}) -> void:
	trace.append({
		"t_ms": Time.get_ticks_msec() - start_time_ms,
		"event": event_name,
		"data": data.duplicate(true)
	})

func _show_error(message: String) -> void:
	_set_status(message, COLOR_ERR)
	btn_confirm.disabled = true
	btn_reset.disabled = true
	btn_next.disabled = true

func _on_stability_changed(_new_value: float, _delta: float) -> void:
	_update_stability_ui()

func _update_stability_ui() -> void:
	stability_bar.value = GlobalMetrics.stability

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
