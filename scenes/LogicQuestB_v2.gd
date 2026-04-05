extends Control

const TrialV2 = preload("res://scripts/TrialV2.gd")
const STAGE_ID: String = "B"

func _tr(key: String, default_text: String, params: Dictionary = {}) -> String:
	var merged: Dictionary = params.merged({"default": default_text})
	return I18n.tr_key(key, merged)

func _tr_compat(primary_key: String, legacy_key: String, default_text: String, params: Dictionary = {}) -> String:
	var sentinel: String = "__missing__%s__" % primary_key
	var primary_text: String = I18n.tr_key(primary_key, params.merged({"default": sentinel}))
	if primary_text != sentinel:
		return primary_text
	return _tr(legacy_key, default_text, params)

const CASES: Array[Dictionary] = [
	{
		"id": "B_01", "expression_display": "A AND B",
		"values": {"A": 1, "B": 1}, "correct": 1,
		"steps": ["A AND B = 1 AND 1 = 1"],
		"story_key": "logic.v2.b.B_01.story", "story_default": "Both sensors are active. What will the system show?"
	},
	{
		"id": "B_02", "expression_display": "A OR B",
		"values": {"A": 0, "B": 1}, "correct": 1,
		"steps": ["A OR B = 0 OR 1 = 1"],
		"story_key": "logic.v2.b.B_02.story", "story_default": "One of the channels is transmitting a signal."
	},
	{
		"id": "B_03", "expression_display": "NOT A",
		"values": {"A": 1}, "correct": 0,
		"steps": ["NOT A = NOT 1 = 0"],
		"story_key": "logic.v2.b.B_03.story", "story_default": "Inverter received a signal."
	},
	{
		"id": "B_04", "expression_display": "A XOR B",
		"values": {"A": 1, "B": 1}, "correct": 0,
		"steps": ["A XOR B = 1 XOR 1 = 0  (same inputs -> 0)"],
		"story_key": "logic.v2.b.B_04.story", "story_default": "Both switches are in the same position."
	},
	{
		"id": "B_05", "expression_display": "A AND (NOT B)",
		"values": {"A": 1, "B": 0}, "correct": 1,
		"steps": ["NOT B = NOT 0 = 1", "A AND 1 = 1 AND 1 = 1"],
		"story_key": "logic.v2.b.B_05.story", "story_default": "Main channel is active, interference is disabled."
	},
	{
		"id": "B_06", "expression_display": "(A OR B) AND C",
		"values": {"A": 0, "B": 0, "C": 1}, "correct": 0,
		"steps": ["A OR B = 0 OR 0 = 0", "0 AND C = 0 AND 1 = 0"],
		"story_key": "logic.v2.b.B_06.story", "story_default": "Filter is active but input data is empty."
	},
	{
		"id": "B_07", "expression_display": "(NOT A) OR B",
		"values": {"A": 1, "B": 0}, "correct": 0,
		"steps": ["NOT A = NOT 1 = 0", "0 OR B = 0 OR 0 = 0"],
		"story_key": "logic.v2.b.B_07.story", "story_default": "Inverted signal A and direct signal B."
	},
	{
		"id": "B_08", "expression_display": "(A AND B) OR (NOT C)",
		"values": {"A": 1, "B": 0, "C": 1}, "correct": 0,
		"steps": ["A AND B = 1 AND 0 = 0", "NOT C = NOT 1 = 0", "0 OR 0 = 0"],
		"story_key": "logic.v2.b.B_08.story", "story_default": "Two sub-channels: A/B match and C inversion."
	},
	{
		"id": "B_09", "expression_display": "(A OR B) AND (NOT C)",
		"values": {"A": 0, "B": 1, "C": 0}, "correct": 1,
		"steps": ["A OR B = 0 OR 1 = 1", "NOT C = NOT 0 = 1", "1 AND 1 = 1"],
		"story_key": "logic.v2.b.B_09.story", "story_default": "At least one input and absence of blocking."
	},
	{
		"id": "B_10", "expression_display": "NOT(A AND B) OR C",
		"values": {"A": 1, "B": 1, "C": 0}, "correct": 0,
		"steps": ["A AND B = 1 AND 1 = 1", "NOT(1) = 0", "0 OR C = 0 OR 0 = 0"],
		"story_key": "logic.v2.b.B_10.story", "story_default": "Negation of match combined with backup channel C."
	},
]

# Layout nodes
var btn_back: Button
var title_label: Label
var progress_label: Label
var stability_bar: ProgressBar
var content_scroll: ScrollContainer
var content_vbox: VBoxContainer
var story_label: Label
var expression_label: Label
var values_box: HBoxContainer
var explain_card: PanelContainer
var explain_label: Label
var status_label: Label
var btn_hint: Button
var btn_confirm: Button
var btn_answer_0: Button
var btn_answer_1: Button
var _expr_title_label: Label
var _values_title_label: Label
var _question_title_label: Label
var _done_title_label: Label
var _done_body_label: Label

# State
var current_case_idx: int = 0
var _selected_answer: int = -1
var hint_used: bool = false
var attempt_count: int = 0
var trial_seq: int = 0
var case_started_ms: int = 0
var _quest_done: bool = false
var _is_compact: bool = false
var _status_i18n_key: String = ""
var _status_i18n_default: String = ""
var _status_i18n_params: Dictionary = {}
var _active_explain_mode: String = ""

# Helpers
func _make_panel() -> PanelContainer:
	return PanelContainer.new()

func _make_semantic_panel(semantic: String) -> PanelContainer:
	var p := PanelContainer.new()
	var s := StyleBoxFlat.new()
	match semantic:
		"correct":
			s.bg_color = Color(0.06, 0.09, 0.06, 0.96)
			s.border_color = Color(0.2, 0.5, 0.25, 0.7)
		"wrong":
			s.bg_color = Color(0.09, 0.06, 0.06, 0.96)
			s.border_color = Color(0.5, 0.2, 0.2, 0.7)
		"hint", "info":
			s.bg_color = Color(0.06, 0.06, 0.09, 0.96)
			s.border_color = Color(0.3, 0.3, 0.5, 0.7)
		_:
			return p
	s.set_border_width_all(1)
	s.corner_radius_top_left = 8
	s.corner_radius_top_right = 8
	s.corner_radius_bottom_left = 8
	s.corner_radius_bottom_right = 8
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	p.add_theme_stylebox_override("panel", s)
	return p

func _apply_semantic_style(panel: PanelContainer, semantic: String) -> void:
	var s := StyleBoxFlat.new()
	match semantic:
		"correct":
			s.bg_color = Color(0.06, 0.09, 0.06, 0.96)
			s.border_color = Color(0.2, 0.5, 0.25, 0.7)
		"wrong":
			s.bg_color = Color(0.09, 0.06, 0.06, 0.96)
			s.border_color = Color(0.5, 0.2, 0.2, 0.7)
		"hint", "info":
			s.bg_color = Color(0.06, 0.06, 0.09, 0.96)
			s.border_color = Color(0.3, 0.3, 0.5, 0.7)
	s.set_border_width_all(1)
	s.corner_radius_top_left = 8
	s.corner_radius_top_right = 8
	s.corner_radius_bottom_left = 8
	s.corner_radius_bottom_right = 8
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", s)

func _make_button(text_val: String) -> Button:
	var btn := Button.new()
	btn.text = text_val
	btn.focus_mode = Control.FOCUS_NONE
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return btn

func _make_label(text_val: String, size: int = 0) -> Label:
	var l := Label.new()
	l.text = text_val
	if size > 0:
		l.add_theme_font_size_override("font_size", size)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

func _make_sep() -> Panel:
	var sep := Panel.new()
	sep.custom_minimum_size.y = 1
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.2, 0.2, 0.22)
	sep.add_theme_stylebox_override("panel", s)
	return sep

# Build UI
func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.06)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var safe := MarginContainer.new()
	safe.set_anchors_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", 14)
	safe.add_theme_constant_override("margin_right", 14)
	safe.add_theme_constant_override("margin_top", 44)
	safe.add_theme_constant_override("margin_bottom", 10)
	add_child(safe)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 8)
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	safe.add_child(main_vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	header.custom_minimum_size.y = 44.0
	main_vbox.add_child(header)

	btn_back = _make_button("")
	btn_back.custom_minimum_size = Vector2(80, 44)
	header.add_child(btn_back)

	title_label = Label.new()
	title_label.text = ""
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.clip_text = true
	header.add_child(title_label)

	progress_label = Label.new()
	progress_label.text = "1/%d" % CASES.size()
	progress_label.add_theme_font_size_override("font_size", 15)
	progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(progress_label)

	stability_bar = ProgressBar.new()
	stability_bar.custom_minimum_size = Vector2(90, 18)
	stability_bar.max_value = 100.0
	stability_bar.value = float(GlobalMetrics.stability)
	stability_bar.show_percentage = false
	stability_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(stability_bar)

	main_vbox.add_child(_make_sep())

	content_scroll = ScrollContainer.new()
	content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(content_scroll)

	content_vbox = VBoxContainer.new()
	content_vbox.add_theme_constant_override("separation", 12)
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_scroll.add_child(content_vbox)

	var story_panel := _make_panel()
	story_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(story_panel)
	story_label = _make_label("", 15)
	story_panel.add_child(story_label)

	var expr_panel := _make_panel()
	expr_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(expr_panel)
	var expr_vbox := VBoxContainer.new()
	expr_vbox.add_theme_constant_override("separation", 6)
	expr_panel.add_child(expr_vbox)
	_expr_title_label = _make_label("", 13)
	_expr_title_label.add_theme_color_override("font_color", Color(0.92, 0.2, 0.24))
	_expr_title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	expr_vbox.add_child(_expr_title_label)
	expression_label = Label.new()
	expression_label.add_theme_font_size_override("font_size", 22)
	expression_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	expression_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	expression_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	expr_vbox.add_child(expression_label)

	var val_panel := _make_panel()
	val_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(val_panel)
	var val_vbox := VBoxContainer.new()
	val_vbox.add_theme_constant_override("separation", 6)
	val_panel.add_child(val_vbox)
	_values_title_label = _make_label("", 13)
	_values_title_label.add_theme_color_override("font_color", Color(0.92, 0.2, 0.24))
	val_vbox.add_child(_values_title_label)
	values_box = HBoxContainer.new()
	values_box.add_theme_constant_override("separation", 10)
	val_vbox.add_child(values_box)

	_question_title_label = _make_label("", 15)
	_question_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_vbox.add_child(_question_title_label)

	var ans_box := HBoxContainer.new()
	ans_box.add_theme_constant_override("separation", 16)
	content_vbox.add_child(ans_box)

	btn_answer_0 = _make_answer_btn("0")
	btn_answer_1 = _make_answer_btn("1")
	ans_box.add_child(btn_answer_0)
	ans_box.add_child(btn_answer_1)

	explain_card = _make_semantic_panel("info")
	explain_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	explain_card.visible = false
	content_vbox.add_child(explain_card)
	explain_label = _make_label("")
	explain_card.add_child(explain_label)

	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_vbox.add_child(status_label)

	main_vbox.add_child(_make_sep())
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	main_vbox.add_child(actions)

	btn_hint = _make_button("")
	btn_hint.custom_minimum_size.y = 48
	actions.add_child(btn_hint)

	btn_confirm = _make_button("")
	btn_confirm.custom_minimum_size.y = 48
	actions.add_child(btn_confirm)

func _make_answer_btn(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.toggle_mode = true
	btn.custom_minimum_size = Vector2(120, 68)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 32)
	btn.focus_mode = Control.FOCUS_NONE
	return btn

# i18n
func _case_text(case_data: Dictionary, field_name: String) -> String:
	var key: String = str(case_data.get("%s_key" % field_name, ""))
	var default_text: String = str(case_data.get("%s_default" % field_name, case_data.get(field_name, "")))
	if key.is_empty():
		return default_text
	return _tr(key, default_text)

func _build_explain_text(case_data: Dictionary) -> String:
	var steps: Array = case_data.get("steps", [])
	var lines: Array[String] = []
	for i in range(steps.size()):
		lines.append(
			_tr(
				"logic.v2.b.step",
				"Step {n}: {text}",
				{"n": i + 1, "text": str(steps[i])}
			)
		)
	lines.append("")
	lines.append(
		_tr(
			"logic.v2.b.answer",
			"Answer: {value}",
			{"value": int(case_data.get("correct", 0))}
		)
	)
	return "\n".join(lines)

func _apply_i18n() -> void:
	title_label.text = _tr("logic.v2.b.title", "INTERROGATION: EVALUATE")
	_expr_title_label.text = _tr_compat("logic.v2.b.expression", "logic.v2.b.expr_title", "EXPRESSION:")
	_values_title_label.text = _tr_compat("logic.v2.b.values", "logic.v2.b.val_title", "VALUES:")
	_question_title_label.text = _tr_compat("logic.v2.b.question", "logic.v2.b.q_lbl", "WHAT IS THE RESULT?")
	btn_hint.text = _tr_compat("logic.v2.common.hint", "logic.v2.b.btn_hint", "HINT")
	btn_confirm.text = _tr_compat("logic.v2.common.confirm", "logic.v2.b.btn_confirm", "CONFIRM")

	if _quest_done:
		btn_back.text = _tr("logic.v2.common.btn_exit", "EXIT")
	else:
		btn_back.text = "<" if _is_compact else _tr_compat("logic.v2.common.back", "logic.v2.b.btn_back", "BACK")

	if _status_i18n_key != "":
		status_label.text = _tr(_status_i18n_key, _status_i18n_default, _status_i18n_params)

	if _quest_done:
		if _done_title_label:
			_done_title_label.text = _tr("logic.v2.b.complete", "All levels complete!")
		if _done_body_label:
			_done_body_label.text = _tr(
				"logic.v2.b.complete_body",
				"All {n} calculations done.\nEvaluating logic expressions is key to circuit analysis.",
				{"n": CASES.size()}
			)
		return

	_refresh_case_i18n()
	if _active_explain_mode == "intro":
		_show_intro()
	elif _active_explain_mode == "hint" and current_case_idx >= 0 and current_case_idx < CASES.size():
		_on_hint_pressed()
	elif _active_explain_mode == "case" and current_case_idx >= 0 and current_case_idx < CASES.size():
		explain_label.text = _build_explain_text(CASES[current_case_idx])

func _refresh_case_i18n() -> void:
	if _quest_done or current_case_idx < 0 or current_case_idx >= CASES.size():
		return
	var case_data: Dictionary = CASES[current_case_idx]
	story_label.text = _case_text(case_data, "story")

func _on_language_changed(_new_language: String) -> void:
	_apply_i18n()

# Case loading
func _load_case(idx: int) -> void:
	current_case_idx = idx
	_selected_answer = -1
	hint_used = false
	attempt_count = 0
	case_started_ms = Time.get_ticks_msec()
	_status_i18n_key = ""
	_status_i18n_default = ""
	_status_i18n_params = {}
	_active_explain_mode = ""
	_done_title_label = null
	_done_body_label = null

	var case_data: Dictionary = CASES[idx]
	progress_label.text = "%d/%d" % [idx + 1, CASES.size()]
	expression_label.text = str(case_data.get("expression_display", ""))
	explain_card.visible = false
	status_label.text = ""
	btn_confirm.disabled = false
	btn_hint.disabled = false

	btn_answer_0.button_pressed = false
	btn_answer_1.button_pressed = false
	btn_answer_0.remove_theme_color_override("font_color")
	btn_answer_1.remove_theme_color_override("font_color")

	for child in values_box.get_children():
		child.queue_free()
	var values: Dictionary = case_data.get("values", {})
	var keys: Array = values.keys()
	keys.sort()
	for key in keys:
		var chip := _make_panel()
		var chip_lbl := Label.new()
		chip_lbl.text = "%s = %d" % [str(key), int(values[key])]
		chip_lbl.add_theme_font_size_override("font_size", 18)
		chip.add_child(chip_lbl)
		values_box.add_child(chip)

	_refresh_case_i18n()
	if idx == 0:
		_show_intro()

func _show_intro() -> void:
	_active_explain_mode = "intro"
	_apply_semantic_style(explain_card, "info")
	explain_label.text = _tr(
		"logic.v2.b.intro",
		"TASK: Calculate the result of the logical expression.\n\nSubstitute values A, B, C into the expression.\nChoose 0 or 1, then press CONFIRM.\n\nHINT shows the first step."
	)
	explain_label.add_theme_color_override("font_color", Color(0.75, 0.82, 0.9))
	explain_card.visible = true

# Interactions
func _on_answer_0_toggled(pressed: bool) -> void:
	if pressed:
		_selected_answer = 0
		btn_answer_1.button_pressed = false

func _on_answer_1_toggled(pressed: bool) -> void:
	if pressed:
		_selected_answer = 1
		btn_answer_0.button_pressed = false

func _on_hint_pressed() -> void:
	hint_used = true
	var case_data: Dictionary = CASES[current_case_idx]
	var steps: Array = case_data.get("steps", [])
	if steps.size() > 0:
		_active_explain_mode = "hint"
		_apply_semantic_style(explain_card, "info")
		explain_label.text = "%s\n..." % _tr(
			"logic.v2.b.step",
			"Step {n}: {text}",
			{"n": 1, "text": str(steps[0])}
		)
		explain_label.add_theme_color_override("font_color", Color(0.75, 0.82, 0.9))
		explain_card.visible = true

func _on_confirm_pressed() -> void:
	if _selected_answer == -1:
		_status_i18n_key = "logic.v2.b.pick_answer"
		_status_i18n_default = "Select 0 or 1"
		_status_i18n_params = {}
		status_label.text = _tr(_status_i18n_key, _status_i18n_default)
		return

	var case_data: Dictionary = CASES[current_case_idx]
	var correct: int = int(case_data.get("correct", 0))
	var is_correct: bool = _selected_answer == correct
	attempt_count += 1

	if is_correct:
		if _selected_answer == 0:
			btn_answer_0.add_theme_color_override("font_color", Color(0.7, 0.85, 0.7))
		else:
			btn_answer_1.add_theme_color_override("font_color", Color(0.7, 0.85, 0.7))
	else:
		if _selected_answer == 0:
			btn_answer_0.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
		else:
			btn_answer_1.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
		if correct == 0:
			btn_answer_0.add_theme_color_override("font_color", Color(0.7, 0.85, 0.7))
		else:
			btn_answer_1.add_theme_color_override("font_color", Color(0.7, 0.85, 0.7))

	_active_explain_mode = "case"
	_show_explain(is_correct, _build_explain_text(case_data))
	_register_trial(is_correct)

	if is_correct:
		_status_i18n_key = "logic.v2.b.correct"
		_status_i18n_default = "Correct!"
		_status_i18n_params = {}
		status_label.text = _tr(_status_i18n_key, _status_i18n_default)
		btn_confirm.disabled = true
		btn_hint.disabled = true
		await get_tree().create_timer(2.0).timeout
		_next_case()
	else:
		_status_i18n_key = "logic.v2.b.wrong"
		_status_i18n_default = "Wrong. Check the steps."
		_status_i18n_params = {}
		status_label.text = _tr(_status_i18n_key, _status_i18n_default)

func _show_explain(is_correct: bool, text: String) -> void:
	explain_card.visible = true
	explain_label.text = text
	if is_correct:
		_apply_semantic_style(explain_card, "correct")
		explain_label.add_theme_color_override("font_color", Color(0.7, 0.85, 0.7))
	else:
		_apply_semantic_style(explain_card, "wrong")
		explain_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.6))

func _next_case() -> void:
	if current_case_idx + 1 >= CASES.size():
		_show_complete()
	else:
		_load_case(current_case_idx + 1)

func _show_complete() -> void:
	if _quest_done:
		return
	_quest_done = true
	GlobalMetrics.finish_quest("LOGIC_QUEST_B", 100, true)

	for child in content_vbox.get_children():
		child.queue_free()

	var done_panel := _make_semantic_panel("correct")
	done_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(done_panel)
	var done_vbox := VBoxContainer.new()
	done_vbox.add_theme_constant_override("separation", 12)
	done_panel.add_child(done_vbox)

	_done_title_label = _make_label(_tr("logic.v2.b.complete", "All levels complete!"), 20)
	_done_title_label.add_theme_color_override("font_color", Color(0.7, 0.85, 0.7))
	_done_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	done_vbox.add_child(_done_title_label)

	_done_body_label = _make_label(
		_tr(
			"logic.v2.b.complete_body",
			"All {n} calculations done.\nEvaluating logic expressions is key to circuit analysis.",
			{"n": CASES.size()}
		),
		15
	)
	done_vbox.add_child(_done_body_label)

	btn_confirm.disabled = true
	btn_hint.disabled = true
	btn_back.text = _tr("logic.v2.common.btn_exit", "EXIT")

# Metrics
func _register_trial(is_correct: bool) -> void:
	var case_data: Dictionary = CASES[current_case_idx]
	var payload: Dictionary = TrialV2.build("LOGIC_QUEST", "B", str(case_data.get("id", "")), "EXPRESSION_EVAL")
	payload["is_correct"] = is_correct
	payload["is_fit"] = is_correct and not hint_used
	payload["stability_delta"] = 0.0 if is_correct else -10.0
	payload["elapsed_ms"] = Time.get_ticks_msec() - case_started_ms
	payload["duration"] = float(payload["elapsed_ms"]) / 1000.0
	payload["hint_used"] = hint_used
	payload["attempt_count"] = attempt_count
	payload["selected_answer"] = _selected_answer
	payload["correct_answer"] = int(case_data.get("correct", 0))
	payload["expression"] = str(case_data.get("expression_display", ""))
	payload["case_index"] = current_case_idx
	payload["total_cases"] = CASES.size()
	payload["trial_seq"] = trial_seq
	trial_seq += 1
	GlobalMetrics.register_trial(payload)
	if not is_correct:
		GlobalMetrics.add_mistake(
			"case=%s expr=%s selected=%d correct=%d" % [
				str(case_data.get("id", "")),
				str(case_data.get("expression_display", "")),
				_selected_answer,
				int(case_data.get("correct", 0))
			]
		)

# Signals and lifecycle
func _connect_signals() -> void:
	btn_back.pressed.connect(_on_back_pressed)
	btn_hint.pressed.connect(_on_hint_pressed)
	btn_confirm.pressed.connect(_on_confirm_pressed)
	btn_answer_0.toggled.connect(_on_answer_0_toggled)
	btn_answer_1.toggled.connect(_on_answer_1_toggled)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _on_stability_changed(new_val: float, _delta: float) -> void:
	stability_bar.value = new_val

func _on_viewport_size_changed() -> void:
	var vp: Vector2 = get_viewport_rect().size
	_is_compact = vp.y <= 420.0 or vp.x <= 500.0
	btn_back.custom_minimum_size = Vector2(48.0 if _is_compact else 80.0, 44.0)
	if _quest_done:
		btn_back.text = _tr("logic.v2.common.btn_exit", "EXIT")
	else:
		btn_back.text = "<" if _is_compact else _tr_compat("logic.v2.common.back", "logic.v2.b.btn_back", "BACK")
	btn_hint.custom_minimum_size.y = 44.0
	btn_confirm.custom_minimum_size.y = 44.0
	expression_label.add_theme_font_size_override("font_size", 18 if _is_compact else 22)

func _ready() -> void:
	_build_ui()
	_connect_signals()
	GlobalMetrics.start_quest("LOGIC_QUEST_B")
	if not GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.connect(_on_stability_changed)
	if not get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.connect(_on_viewport_size_changed)
	if not I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.connect(_on_language_changed)
	call_deferred("_on_viewport_size_changed")
	_apply_i18n()
	_load_case(0)

func _exit_tree() -> void:
	if get_tree() and get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.disconnect(_on_viewport_size_changed)
	if GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.disconnect(_on_stability_changed)
	if I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.disconnect(_on_language_changed)
