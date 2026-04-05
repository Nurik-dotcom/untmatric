extends Control

const TrialV2 = preload("res://scripts/TrialV2.gd")
const STAGE_ID: String = "C"

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
		"id": "C_01", "original": "(A AND B) OR (A AND C)",
		"law_key": "logic.v2.c.C_01.law", "law_default": "Distributivity",
		"law_hint_key": "logic.v2.c.C_01.law_hint", "law_hint_default": "Factor out common A",
		"options": [
			{"text": "A AND (B OR C)", "correct": true},
			{"text": "(A OR B) AND C", "correct": false},
			{"text": "A OR (B AND C)", "correct": false}
		],
		"explanation_key": "logic.v2.c.C_01.explanation", "explanation_default": "(A AND B) OR (A AND C) = A AND (B OR C)"
	},
	{
		"id": "C_02", "original": "(A OR B) AND (A OR C)",
		"law_key": "logic.v2.c.C_02.law", "law_default": "Distributivity",
		"law_hint_key": "logic.v2.c.C_02.law_hint", "law_hint_default": "Factor out common A",
		"options": [
			{"text": "A OR (B AND C)", "correct": true},
			{"text": "(A AND B) OR C", "correct": false},
			{"text": "A AND (B OR C)", "correct": false}
		],
		"explanation_key": "logic.v2.c.C_02.explanation", "explanation_default": "(A OR B) AND (A OR C) = A OR (B AND C)"
	},
	{
		"id": "C_03", "original": "A OR (A AND B)",
		"law_key": "logic.v2.c.C_03.law", "law_default": "Absorption",
		"law_hint_key": "logic.v2.c.C_03.law_hint", "law_hint_default": "A absorbs A AND B",
		"options": [
			{"text": "A", "correct": true},
			{"text": "A AND B", "correct": false},
			{"text": "A OR B", "correct": false}
		],
		"explanation_key": "logic.v2.c.C_03.explanation", "explanation_default": "A OR (A AND B) = A"
	},
	{
		"id": "C_04", "original": "A AND (A OR B)",
		"law_key": "logic.v2.c.C_04.law", "law_default": "Absorption",
		"law_hint_key": "logic.v2.c.C_04.law_hint", "law_hint_default": "A absorbs A OR B",
		"options": [
			{"text": "A", "correct": true},
			{"text": "A OR B", "correct": false},
			{"text": "B", "correct": false}
		],
		"explanation_key": "logic.v2.c.C_04.explanation", "explanation_default": "A AND (A OR B) = A"
	},
	{
		"id": "C_05", "original": "NOT(A AND B)",
		"law_key": "logic.v2.c.C_05.law", "law_default": "De Morgan",
		"law_hint_key": "logic.v2.c.C_05.law_hint", "law_hint_default": "NOT before AND -> OR and invert each input",
		"options": [
			{"text": "(NOT A) OR (NOT B)", "correct": true},
			{"text": "(NOT A) AND (NOT B)", "correct": false},
			{"text": "NOT A OR B", "correct": false}
		],
		"explanation_key": "logic.v2.c.C_05.explanation", "explanation_default": "NOT(A AND B) = (NOT A) OR (NOT B)"
	},
	{
		"id": "C_06", "original": "NOT(A OR B)",
		"law_key": "logic.v2.c.C_06.law", "law_default": "De Morgan",
		"law_hint_key": "logic.v2.c.C_06.law_hint", "law_hint_default": "NOT before OR -> AND and invert each input",
		"options": [
			{"text": "(NOT A) AND (NOT B)", "correct": true},
			{"text": "(NOT A) OR (NOT B)", "correct": false},
			{"text": "NOT(A AND B)", "correct": false}
		],
		"explanation_key": "logic.v2.c.C_06.explanation", "explanation_default": "NOT(A OR B) = (NOT A) AND (NOT B)"
	},
	{
		"id": "C_07", "original": "NOT(NOT A)",
		"law_key": "logic.v2.c.C_07.law", "law_default": "Double Negation",
		"law_hint_key": "logic.v2.c.C_07.law_hint", "law_hint_default": "Two NOTs cancel each other",
		"options": [
			{"text": "A", "correct": true},
			{"text": "NOT A", "correct": false},
			{"text": "0", "correct": false}
		],
		"explanation_key": "logic.v2.c.C_07.explanation", "explanation_default": "NOT(NOT A) = A"
	},
	{
		"id": "C_08", "original": "NOT(NOT(A OR B))",
		"law_key": "logic.v2.c.C_08.law", "law_default": "Double Negation",
		"law_hint_key": "logic.v2.c.C_08.law_hint", "law_hint_default": "Remove two outer NOTs",
		"options": [
			{"text": "A OR B", "correct": true},
			{"text": "A AND B", "correct": false},
			{"text": "NOT(A OR B)", "correct": false}
		],
		"explanation_key": "logic.v2.c.C_08.explanation", "explanation_default": "NOT(NOT(A OR B)) = A OR B"
	}
]

# Layout nodes
var btn_back: Button
var title_label: Label
var progress_label: Label
var stability_bar: ProgressBar
var content_scroll: ScrollContainer
var content_vbox: VBoxContainer
var original_label: Label
var law_title_label: Label
var law_hint_label: Label
var options_container: VBoxContainer
var explain_card: PanelContainer
var explain_label: Label
var status_label: Label
var btn_hint: Button
var btn_confirm: Button
var _original_title_label: Label
var _law_prefix_label: Label
var _options_header_label: Label
var _done_title_label: Label
var _done_body_label: Label

# State
var current_case_idx: int = 0
var _selected_option_idx: int = -1
var _option_buttons: Array[Button] = []
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

	var orig_panel := _make_panel()
	orig_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(orig_panel)
	var orig_vbox := VBoxContainer.new()
	orig_vbox.add_theme_constant_override("separation", 6)
	orig_panel.add_child(orig_vbox)
	_original_title_label = _make_label("", 13)
	_original_title_label.add_theme_color_override("font_color", Color(0.92, 0.2, 0.24))
	orig_vbox.add_child(_original_title_label)
	original_label = Label.new()
	original_label.add_theme_font_size_override("font_size", 20)
	original_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	original_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	original_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	orig_vbox.add_child(original_label)

	var law_panel := _make_panel()
	law_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(law_panel)
	var law_vbox := VBoxContainer.new()
	law_vbox.add_theme_constant_override("separation", 4)
	law_panel.add_child(law_vbox)
	_law_prefix_label = _make_label("", 13)
	_law_prefix_label.add_theme_color_override("font_color", Color(0.92, 0.2, 0.24))
	_law_prefix_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	law_vbox.add_child(_law_prefix_label)
	law_title_label = Label.new()
	law_title_label.add_theme_font_size_override("font_size", 18)
	law_title_label.add_theme_color_override("font_color", Color(0.92, 0.2, 0.24))
	law_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	law_vbox.add_child(law_title_label)
	law_hint_label = _make_label("", 14)
	law_vbox.add_child(law_hint_label)

	_options_header_label = _make_label("", 14)
	content_vbox.add_child(_options_header_label)

	options_container = VBoxContainer.new()
	options_container.add_theme_constant_override("separation", 8)
	options_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(options_container)

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

# i18n
func _case_text(case_data: Dictionary, field_name: String) -> String:
	var key: String = str(case_data.get("%s_key" % field_name, ""))
	var default_text: String = str(case_data.get("%s_default" % field_name, case_data.get(field_name, "")))
	if key.is_empty():
		return default_text
	return _tr(key, default_text)

func _apply_i18n() -> void:
	title_label.text = _tr("logic.v2.c.title", "INTERROGATION: SIMPLIFY")
	_original_title_label.text = _tr_compat("logic.v2.c.original", "logic.v2.c.orig_title", "ORIGINAL EXPRESSION:")
	_law_prefix_label.text = _tr("logic.v2.c.law_prefix", "LAW:")
	_options_header_label.text = _tr_compat("logic.v2.c.choose", "logic.v2.c.opts_header", "CHOOSE THE SIMPLIFIED FORM:")
	btn_hint.text = _tr_compat("logic.v2.common.hint", "logic.v2.c.btn_hint", "HINT")
	btn_confirm.text = _tr_compat("logic.v2.common.confirm", "logic.v2.c.btn_confirm", "CONFIRM")

	if _quest_done:
		btn_back.text = _tr("logic.v2.common.btn_exit", "EXIT")
	else:
		btn_back.text = "<" if _is_compact else _tr_compat("logic.v2.common.back", "logic.v2.c.btn_back", "BACK")

	if _status_i18n_key != "":
		status_label.text = _tr(_status_i18n_key, _status_i18n_default, _status_i18n_params)

	if _quest_done:
		if _done_title_label:
			_done_title_label.text = _tr("logic.v2.c.complete", "All levels complete!")
		if _done_body_label:
			_done_body_label.text = _tr(
				"logic.v2.c.complete_body",
				"All {n} laws applied.\nBoolean algebra is the foundation of digital circuit optimization.",
				{"n": CASES.size()}
			)
		return

	_refresh_case_i18n()
	if _active_explain_mode == "intro":
		_show_intro()
	elif _active_explain_mode == "hint":
		_on_hint_pressed()
	elif _active_explain_mode == "case" and current_case_idx >= 0 and current_case_idx < CASES.size():
		explain_label.text = _case_text(CASES[current_case_idx], "explanation")

func _refresh_case_i18n() -> void:
	if _quest_done or current_case_idx < 0 or current_case_idx >= CASES.size():
		return
	var case_data: Dictionary = CASES[current_case_idx]
	original_label.text = str(case_data.get("original", ""))
	law_title_label.text = _case_text(case_data, "law")
	law_hint_label.text = "\"%s\"" % _case_text(case_data, "law_hint")

func _on_language_changed(_new_language: String) -> void:
	_apply_i18n()

# Case loading
func _load_case(idx: int) -> void:
	current_case_idx = idx
	_selected_option_idx = -1
	hint_used = false
	attempt_count = 0
	case_started_ms = Time.get_ticks_msec()
	_status_i18n_key = ""
	_status_i18n_default = ""
	_status_i18n_params = {}
	_active_explain_mode = ""
	_done_title_label = null
	_done_body_label = null

	progress_label.text = "%d/%d" % [idx + 1, CASES.size()]
	explain_card.visible = false
	status_label.text = ""
	btn_confirm.disabled = false
	btn_hint.disabled = false

	_build_options()
	_refresh_case_i18n()
	if idx == 0:
		_show_intro()

func _show_intro() -> void:
	_active_explain_mode = "intro"
	_apply_semantic_style(explain_card, "info")
	explain_label.text = _tr(
		"logic.v2.c.intro",
		"TASK: Simplify the logical expression.\n\nApply the given law and choose one of three options.\n\nHINT shows how the law applies."
	)
	explain_label.add_theme_color_override("font_color", Color(0.75, 0.82, 0.9))
	explain_card.visible = true

func _build_options() -> void:
	for child in options_container.get_children():
		child.queue_free()
	_option_buttons.clear()

	var case_data: Dictionary = CASES[current_case_idx]
	var options: Array = case_data.get("options", [])

	for i in range(options.size()):
		var opt: Dictionary = options[i]
		var btn := Button.new()
		btn.text = "    %s" % str(opt.get("text", ""))
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(0, 60)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", 17)
		btn.focus_mode = Control.FOCUS_NONE
		btn.toggled.connect(_on_option_toggled.bind(i))
		options_container.add_child(btn)
		_option_buttons.append(btn)

# Interactions
func _on_option_toggled(pressed: bool, idx: int) -> void:
	if pressed:
		_selected_option_idx = idx
		for i in range(_option_buttons.size()):
			if i != idx:
				_option_buttons[i].button_pressed = false

func _on_hint_pressed() -> void:
	hint_used = true
	var case_data: Dictionary = CASES[current_case_idx]
	_active_explain_mode = "hint"
	_apply_semantic_style(explain_card, "info")
	explain_label.text = _tr(
		"logic.v2.c.hint_prefix",
		"Hint: {hint}\n\nRule: {law}",
		{"hint": _case_text(case_data, "law_hint"), "law": _case_text(case_data, "law")}
	)
	explain_label.add_theme_color_override("font_color", Color(0.75, 0.82, 0.9))
	explain_card.visible = true

func _on_confirm_pressed() -> void:
	if _selected_option_idx == -1:
		_status_i18n_key = "logic.v2.c.pick"
		_status_i18n_default = "Select an answer option"
		_status_i18n_params = {}
		status_label.text = _tr(_status_i18n_key, _status_i18n_default)
		return

	var case_data: Dictionary = CASES[current_case_idx]
	var options: Array = case_data.get("options", [])
	var selected_opt: Dictionary = options[_selected_option_idx]
	var is_correct: bool = bool(selected_opt.get("correct", false))
	attempt_count += 1

	for i in range(options.size()):
		var opt: Dictionary = options[i]
		var btn: Button = _option_buttons[i]
		if bool(opt.get("correct", false)):
			btn.add_theme_color_override("font_color", Color(0.7, 0.85, 0.7))
		elif i == _selected_option_idx:
			btn.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
		btn.disabled = true

	_active_explain_mode = "case"
	_show_explain(is_correct, _case_text(case_data, "explanation"))
	_register_trial(is_correct, str(selected_opt.get("text", "")))

	if is_correct:
		_status_i18n_key = "logic.v2.c.correct"
		_status_i18n_default = "Correct!"
		_status_i18n_params = {}
		status_label.text = _tr(_status_i18n_key, _status_i18n_default)
		btn_confirm.disabled = true
		btn_hint.disabled = true
		await get_tree().create_timer(2.0).timeout
		_next_case()
	else:
		_status_i18n_key = "logic.v2.c.wrong"
		_status_i18n_default = "Wrong. Read the explanation."
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
	GlobalMetrics.finish_quest("LOGIC_QUEST_C", 100, true)

	for child in content_vbox.get_children():
		child.queue_free()

	var done_panel := _make_semantic_panel("correct")
	done_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(done_panel)
	var done_vbox := VBoxContainer.new()
	done_vbox.add_theme_constant_override("separation", 12)
	done_panel.add_child(done_vbox)

	_done_title_label = _make_label(_tr("logic.v2.c.complete", "All levels complete!"), 20)
	_done_title_label.add_theme_color_override("font_color", Color(0.7, 0.85, 0.7))
	_done_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	done_vbox.add_child(_done_title_label)

	_done_body_label = _make_label(
		_tr(
			"logic.v2.c.complete_body",
			"All {n} laws applied.\nBoolean algebra is the foundation of digital circuit optimization.",
			{"n": CASES.size()}
		),
		15
	)
	done_vbox.add_child(_done_body_label)

	btn_confirm.disabled = true
	btn_hint.disabled = true
	btn_back.text = _tr("logic.v2.common.btn_exit", "EXIT")

# Metrics
func _register_trial(is_correct: bool, selected_text: String) -> void:
	var case_data: Dictionary = CASES[current_case_idx]
	var payload: Dictionary = TrialV2.build("LOGIC_QUEST", "C", str(case_data.get("id", "")), "SIMPLIFY_CHOICE")
	payload["is_correct"] = is_correct
	payload["is_fit"] = is_correct and not hint_used
	payload["stability_delta"] = 0.0 if is_correct else -10.0
	payload["elapsed_ms"] = Time.get_ticks_msec() - case_started_ms
	payload["duration"] = float(payload["elapsed_ms"]) / 1000.0
	payload["hint_used"] = hint_used
	payload["attempt_count"] = attempt_count
	payload["law"] = _case_text(case_data, "law")
	payload["original"] = str(case_data.get("original", ""))
	payload["selected_option"] = selected_text
	payload["option_index"] = _selected_option_idx
	payload["case_index"] = current_case_idx
	payload["total_cases"] = CASES.size()
	payload["trial_seq"] = trial_seq
	trial_seq += 1
	GlobalMetrics.register_trial(payload)
	if not is_correct:
		GlobalMetrics.add_mistake(
			"case=%s law=%s selected=%s" % [
				str(case_data.get("id", "")),
				_case_text(case_data, "law"),
				selected_text
			]
		)

# Signals and lifecycle
func _connect_signals() -> void:
	btn_back.pressed.connect(_on_back_pressed)
	btn_hint.pressed.connect(_on_hint_pressed)
	btn_confirm.pressed.connect(_on_confirm_pressed)

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
		btn_back.text = "<" if _is_compact else _tr_compat("logic.v2.common.back", "logic.v2.c.btn_back", "BACK")
	btn_hint.custom_minimum_size.y = 44.0
	btn_confirm.custom_minimum_size.y = 44.0
	original_label.add_theme_font_size_override("font_size", 16 if _is_compact else 20)

func _ready() -> void:
	_build_ui()
	_connect_signals()
	GlobalMetrics.start_quest("LOGIC_QUEST_C")
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
