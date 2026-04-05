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
	# --- 2 steps (warm-up) ---
	{
		"id": "B_01",
		"expression": "A AND (NOT B)",
		"values": {"A": 1, "B": 0},
		"steps": [
			{"desc": "NOT B", "op": "NOT", "inputs": ["B"], "correct": 1},
			{"desc": "A AND _", "op": "AND", "inputs": ["A", "step:0"], "correct": 1}
		],
		"story_key": "logic.v3.b.B_01.story",
		"story_default": "Main channel active, interference disabled."
	},
	{
		"id": "B_02",
		"expression": "(NOT A) OR B",
		"values": {"A": 1, "B": 0},
		"steps": [
			{"desc": "NOT A", "op": "NOT", "inputs": ["A"], "correct": 0},
			{"desc": "_ OR B", "op": "OR", "inputs": ["step:0", "B"], "correct": 0}
		],
		"story_key": "logic.v3.b.B_02.story",
		"story_default": "Inverted signal A combined with direct B."
	},
	{
		"id": "B_03",
		"expression": "A XOR (NOT B)",
		"values": {"A": 1, "B": 1},
		"steps": [
			{"desc": "NOT B", "op": "NOT", "inputs": ["B"], "correct": 0},
			{"desc": "A XOR _", "op": "XOR", "inputs": ["A", "step:0"], "correct": 1}
		],
		"story_key": "logic.v3.b.B_03.story",
		"story_default": "Difference check after signal inversion."
	},
	# --- 3 steps (core) ---
	{
		"id": "B_04",
		"expression": "(A AND B) OR (NOT C)",
		"values": {"A": 1, "B": 0, "C": 1},
		"steps": [
			{"desc": "A AND B", "op": "AND", "inputs": ["A", "B"], "correct": 0},
			{"desc": "NOT C", "op": "NOT", "inputs": ["C"], "correct": 0},
			{"desc": "_ OR _", "op": "OR", "inputs": ["step:0", "step:1"], "correct": 0}
		],
		"story_key": "logic.v3.b.B_04.story",
		"story_default": "Two sub-channels: match check and inversion."
	},
	{
		"id": "B_05",
		"expression": "(A OR B) AND (NOT C)",
		"values": {"A": 0, "B": 1, "C": 0},
		"steps": [
			{"desc": "A OR B", "op": "OR", "inputs": ["A", "B"], "correct": 1},
			{"desc": "NOT C", "op": "NOT", "inputs": ["C"], "correct": 1},
			{"desc": "_ AND _", "op": "AND", "inputs": ["step:0", "step:1"], "correct": 1}
		],
		"story_key": "logic.v3.b.B_05.story",
		"story_default": "At least one input present, no blocking signal."
	},
	{
		"id": "B_06",
		"expression": "NOT(A AND B) OR C",
		"values": {"A": 1, "B": 1, "C": 0},
		"steps": [
			{"desc": "A AND B", "op": "AND", "inputs": ["A", "B"], "correct": 1},
			{"desc": "NOT _", "op": "NOT", "inputs": ["step:0"], "correct": 0},
			{"desc": "_ OR C", "op": "OR", "inputs": ["step:1", "C"], "correct": 0}
		],
		"story_key": "logic.v3.b.B_06.story",
		"story_default": "Negation of full match, backup channel C."
	},
	{
		"id": "B_07",
		"expression": "(NOT A) AND (B OR C)",
		"values": {"A": 0, "B": 0, "C": 1},
		"steps": [
			{"desc": "NOT A", "op": "NOT", "inputs": ["A"], "correct": 1},
			{"desc": "B OR C", "op": "OR", "inputs": ["B", "C"], "correct": 1},
			{"desc": "_ AND _", "op": "AND", "inputs": ["step:0", "step:1"], "correct": 1}
		],
		"story_key": "logic.v3.b.B_07.story",
		"story_default": "Inverted primary with auxiliary channel."
	},
	# --- 4 steps (advanced) ---
	{
		"id": "B_08",
		"expression": "(A AND B) OR (C AND (NOT A))",
		"values": {"A": 0, "B": 1, "C": 1},
		"steps": [
			{"desc": "A AND B", "op": "AND", "inputs": ["A", "B"], "correct": 0},
			{"desc": "NOT A", "op": "NOT", "inputs": ["A"], "correct": 1},
			{"desc": "C AND _", "op": "AND", "inputs": ["C", "step:1"], "correct": 1},
			{"desc": "_ OR _", "op": "OR", "inputs": ["step:0", "step:2"], "correct": 1}
		],
		"story_key": "logic.v3.b.B_08.story",
		"story_default": "Dual path with inversion branch."
	},
	{
		"id": "B_09",
		"expression": "NOT((A OR B) AND C)",
		"values": {"A": 1, "B": 0, "C": 1},
		"steps": [
			{"desc": "A OR B", "op": "OR", "inputs": ["A", "B"], "correct": 1},
			{"desc": "_ AND C", "op": "AND", "inputs": ["step:0", "C"], "correct": 1},
			{"desc": "NOT _", "op": "NOT", "inputs": ["step:1"], "correct": 0}
		],
		"story_key": "logic.v3.b.B_09.story",
		"story_default": "Full negation of composite signal."
	},
	{
		"id": "B_10",
		"expression": "(NOT A) OR ((B AND C) XOR A)",
		"values": {"A": 1, "B": 1, "C": 0},
		"steps": [
			{"desc": "NOT A", "op": "NOT", "inputs": ["A"], "correct": 0},
			{"desc": "B AND C", "op": "AND", "inputs": ["B", "C"], "correct": 0},
			{"desc": "_ XOR A", "op": "XOR", "inputs": ["step:1", "A"], "correct": 1},
			{"desc": "_ OR _", "op": "OR", "inputs": ["step:0", "step:2"], "correct": 1}
		],
		"story_key": "logic.v3.b.B_10.story",
		"story_default": "Complex routing with XOR verification."
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
var steps_label: Label
var steps_grid: GridContainer
var explain_card: PanelContainer
var explain_label: Label
var status_label: Label
var btn_hint: Button
var btn_confirm: Button
var _expr_title_label: Label
var _values_title_label: Label
var _done_title_label: Label
var _done_body_label: Label

# Step state
var _step_answers: Array[int] = []
var _step_buttons: Array[Button] = []
var _step_desc_labels: Array[Label] = []

# Runtime state
var current_case_idx: int = 0
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
var _last_result_is_correct: bool = false
var _last_hint_step_idx: int = -1

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

	var steps_panel := _make_panel()
	steps_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(steps_panel)
	var steps_vbox := VBoxContainer.new()
	steps_vbox.add_theme_constant_override("separation", 8)
	steps_panel.add_child(steps_vbox)
	steps_label = _make_label("", 15)
	steps_vbox.add_child(steps_label)
	steps_grid = GridContainer.new()
	steps_grid.columns = 3
	steps_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	steps_grid.add_theme_constant_override("h_separation", 8)
	steps_grid.add_theme_constant_override("v_separation", 8)
	steps_vbox.add_child(steps_grid)

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

func _case_text(case_data: Dictionary, field_name: String) -> String:
	var key: String = str(case_data.get("%s_key" % field_name, ""))
	var default_text: String = str(case_data.get("%s_default" % field_name, case_data.get(field_name, "")))
	if key.is_empty():
		return default_text
	return _tr(key, default_text)

func _step_prefix(step_number: int) -> String:
	return _tr("logic.v3.b.step_prefix", "Step {n}:", {"n": step_number})

func _replace_first(text: String, needle: String, replacement: String) -> String:
	var idx: int = text.find(needle)
	if idx == -1:
		return text
	return text.substr(0, idx) + replacement + text.substr(idx + needle.length())

func _format_step_desc_from_answers(step: Dictionary, answers: Array) -> String:
	var desc: String = str(step.get("desc", ""))
	var inputs: Array = step.get("inputs", [])
	for input_ref in inputs:
		var ref: String = str(input_ref)
		if not ref.begins_with("step:"):
			continue
		var parts: PackedStringArray = ref.split(":")
		if parts.size() != 2:
			continue
		var ref_idx: int = int(parts[1])
		if ref_idx < 0 or ref_idx >= answers.size():
			continue
		var answer_val: int = int(answers[ref_idx])
		if answer_val == -1:
			continue
		desc = _replace_first(desc, "_", str(answer_val))
	return desc

func _format_step_desc(step: Dictionary) -> String:
	return _format_step_desc_from_answers(step, _step_answers)

func _build_explain_text(case_data: Dictionary) -> String:
	var steps: Array = case_data.get("steps", [])
	var resolved_answers: Array = []
	for step in steps:
		var step_dict: Dictionary = step
		resolved_answers.append(int(step_dict.get("correct", 0)))

	var lines: Array[String] = []
	for i in range(steps.size()):
		var step_dict: Dictionary = steps[i]
		var desc_text: String = _format_step_desc_from_answers(step_dict, resolved_answers)
		var correct_val: int = int(step_dict.get("correct", 0))
		lines.append("%s %s = %d" % [_step_prefix(i + 1), desc_text, correct_val])
	return "\n".join(lines)

func _apply_i18n() -> void:
	title_label.text = _tr("logic.v3.b.title", "INTERROGATION: EVALUATE")
	_expr_title_label.text = _tr_compat("logic.v2.b.expression", "logic.v2.b.expr_title", "EXPRESSION:")
	_values_title_label.text = _tr_compat("logic.v2.b.values", "logic.v2.b.val_title", "VALUES:")
	steps_label.text = _tr("logic.v3.b.steps_label", "Evaluate step by step:")
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
			_done_title_label.text = _tr("logic.v3.b.complete", "All levels complete!")
		if _done_body_label:
			_done_body_label.text = _tr(
				"logic.v3.b.complete_body",
				"All {n} step-by-step evaluations completed.\nYou can now solve multi-stage logic expressions.",
				{"n": CASES.size()}
			)
		return

	_refresh_case_i18n()
	_refresh_step_descriptions()
	if _active_explain_mode == "intro":
		_show_intro()
	elif _active_explain_mode == "hint" and _last_hint_step_idx >= 0:
		_show_hint_text(_last_hint_step_idx)
	elif _active_explain_mode == "case" and current_case_idx >= 0 and current_case_idx < CASES.size():
		_show_explain(_last_result_is_correct, _build_explain_text(CASES[current_case_idx]))

func _refresh_case_i18n() -> void:
	if _quest_done or current_case_idx < 0 or current_case_idx >= CASES.size():
		return
	var case_data: Dictionary = CASES[current_case_idx]
	story_label.text = _case_text(case_data, "story")

func _on_language_changed(_new_language: String) -> void:
	_apply_i18n()

func _set_step_button_text(step_idx: int) -> void:
	if step_idx < 0 or step_idx >= _step_buttons.size():
		return
	var btn: Button = _step_buttons[step_idx]
	match _step_answers[step_idx]:
		-1:
			btn.text = "?"
		0:
			btn.text = "0"
		1:
			btn.text = "1"

func _build_steps(case_data: Dictionary) -> void:
	for child in steps_grid.get_children():
		child.queue_free()
	_step_answers.clear()
	_step_buttons.clear()
	_step_desc_labels.clear()

	var steps: Array = case_data.get("steps", [])
	steps_grid.columns = 3

	for i in range(steps.size()):
		var step: Dictionary = steps[i]
		var desc_lbl := Label.new()
		desc_lbl.text = "%s %s" % [_step_prefix(i + 1), _format_step_desc(step)]
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc_lbl.add_theme_font_size_override("font_size", 16)
		steps_grid.add_child(desc_lbl)
		_step_desc_labels.append(desc_lbl)

		var eq_lbl := Label.new()
		eq_lbl.text = "="
		eq_lbl.add_theme_font_size_override("font_size", 18)
		eq_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		eq_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		steps_grid.add_child(eq_lbl)

		var btn := Button.new()
		btn.text = "?"
		btn.custom_minimum_size = Vector2(64, 48)
		btn.add_theme_font_size_override("font_size", 20)
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(_on_step_toggle.bind(i))
		steps_grid.add_child(btn)
		_step_buttons.append(btn)
		_step_answers.append(-1)

func _refresh_step_descriptions() -> void:
	if current_case_idx < 0 or current_case_idx >= CASES.size():
		return
	var case_data: Dictionary = CASES[current_case_idx]
	var steps: Array = case_data.get("steps", [])
	var visible_steps: int = mini(steps.size(), _step_desc_labels.size())
	for i in range(visible_steps):
		var step: Dictionary = steps[i]
		_step_desc_labels[i].text = "%s %s" % [_step_prefix(i + 1), _format_step_desc(step)]

func _show_intro() -> void:
	_active_explain_mode = "intro"
	_apply_semantic_style(explain_card, "info")
	explain_label.text = _tr(
		"logic.v3.b.intro",
		"TASK: Evaluate expression step by step.\n\nTap each [ ? ] and switch values (? -> 0 -> 1 -> ?).\nWhen early steps are filled, their results are auto-inserted into later steps.\n\nPress CONFIRM to check all steps at once."
	)
	explain_label.add_theme_color_override("font_color", Color(0.75, 0.82, 0.9))
	explain_card.visible = true

func _show_hint_text(step_idx: int) -> void:
	if current_case_idx < 0 or current_case_idx >= CASES.size():
		return
	var case_data: Dictionary = CASES[current_case_idx]
	var steps: Array = case_data.get("steps", [])
	if step_idx < 0 or step_idx >= steps.size():
		return
	var step: Dictionary = steps[step_idx]
	var value: int = int(step.get("correct", 0))
	_apply_semantic_style(explain_card, "hint")
	explain_label.text = _tr(
		"logic.v3.b.hint_text",
		"Hint: {prefix} {desc} = {value}",
		{
			"prefix": _step_prefix(step_idx + 1),
			"desc": _format_step_desc(step),
			"value": value
		}
	)
	explain_label.add_theme_color_override("font_color", Color(0.75, 0.82, 0.9))
	explain_card.visible = true

func _load_case(idx: int) -> void:
	current_case_idx = idx
	hint_used = false
	attempt_count = 0
	case_started_ms = Time.get_ticks_msec()
	_status_i18n_key = ""
	_status_i18n_default = ""
	_status_i18n_params = {}
	_active_explain_mode = ""
	_last_result_is_correct = false
	_last_hint_step_idx = -1
	_done_title_label = null
	_done_body_label = null

	var case_data: Dictionary = CASES[idx]
	progress_label.text = "%d/%d" % [idx + 1, CASES.size()]
	expression_label.text = str(case_data.get("expression", ""))
	explain_card.visible = false
	status_label.text = ""
	btn_confirm.disabled = false
	btn_hint.disabled = false

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

	_build_steps(case_data)
	_refresh_case_i18n()
	_refresh_step_descriptions()
	if idx == 0:
		_show_intro()

func _on_step_toggle(step_idx: int) -> void:
	if step_idx < 0 or step_idx >= _step_answers.size():
		return
	match _step_answers[step_idx]:
		-1:
			_step_answers[step_idx] = 0
		0:
			_step_answers[step_idx] = 1
		_:
			_step_answers[step_idx] = -1

	_set_step_button_text(step_idx)
	_step_buttons[step_idx].remove_theme_color_override("font_color")
	_refresh_step_descriptions()

func _on_hint_pressed() -> void:
	if current_case_idx < 0 or current_case_idx >= CASES.size():
		return
	var steps: Array = CASES[current_case_idx].get("steps", [])
	for i in range(steps.size()):
		if _step_answers[i] != -1:
			continue
		var step: Dictionary = steps[i]
		_step_answers[i] = int(step.get("correct", 0))
		_set_step_button_text(i)
		_step_buttons[i].add_theme_color_override("font_color", Color(0.5, 0.6, 0.85))
		hint_used = true
		_last_hint_step_idx = i
		_active_explain_mode = "hint"
		_refresh_step_descriptions()
		_show_hint_text(i)
		return

func _on_confirm_pressed() -> void:
	if current_case_idx < 0 or current_case_idx >= CASES.size():
		return
	var case_data: Dictionary = CASES[current_case_idx]
	var steps: Array = case_data.get("steps", [])

	var all_filled: bool = true
	for answer in _step_answers:
		if int(answer) == -1:
			all_filled = false
			break
	if not all_filled:
		_status_i18n_key = "logic.v3.b.fill_all"
		_status_i18n_default = "Fill all steps"
		_status_i18n_params = {}
		status_label.text = _tr(_status_i18n_key, _status_i18n_default)
		return

	attempt_count += 1

	var all_correct: bool = true
	var wrong_steps: Array[int] = []
	for i in range(steps.size()):
		var btn: Button = _step_buttons[i]
		btn.remove_theme_color_override("font_color")
		var correct: int = int(steps[i].get("correct", 0))
		if _step_answers[i] == correct:
			btn.add_theme_color_override("font_color", Color(0.35, 0.85, 0.45))
		else:
			btn.add_theme_color_override("font_color", Color(0.95, 0.3, 0.3))
			all_correct = false
			wrong_steps.append(i + 1)

	_last_result_is_correct = all_correct
	_active_explain_mode = "case"
	_show_explain(all_correct, _build_explain_text(case_data))
	_register_trial(all_correct, wrong_steps)

	if all_correct:
		_status_i18n_key = "logic.v2.b.correct"
		_status_i18n_default = "Correct!"
		_status_i18n_params = {}
		status_label.text = _tr(_status_i18n_key, _status_i18n_default)
		btn_confirm.disabled = true
		btn_hint.disabled = true
		await get_tree().create_timer(2.0).timeout
		_next_case()
		return

	var wrong_steps_joined: String = ""
	for i in range(wrong_steps.size()):
		if i > 0:
			wrong_steps_joined += ", "
		wrong_steps_joined += str(wrong_steps[i])
	_status_i18n_key = "logic.v3.b.wrong_steps"
	_status_i18n_default = "Errors in steps: {steps}"
	_status_i18n_params = {"steps": wrong_steps_joined}
	status_label.text = _tr(_status_i18n_key, _status_i18n_default, _status_i18n_params)

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

	_done_title_label = _make_label(_tr("logic.v3.b.complete", "All levels complete!"), 20)
	_done_title_label.add_theme_color_override("font_color", Color(0.7, 0.85, 0.7))
	_done_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	done_vbox.add_child(_done_title_label)

	_done_body_label = _make_label(
		_tr(
			"logic.v3.b.complete_body",
			"All {n} step-by-step evaluations completed.\nYou can now solve multi-stage logic expressions.",
			{"n": CASES.size()}
		),
		15
	)
	done_vbox.add_child(_done_body_label)

	btn_confirm.disabled = true
	btn_hint.disabled = true
	btn_back.text = _tr("logic.v2.common.btn_exit", "EXIT")

func _register_trial(is_correct: bool, wrong_steps: Array[int]) -> void:
	var case_data: Dictionary = CASES[current_case_idx]
	var payload: Dictionary = TrialV2.build("LOGIC_QUEST", STAGE_ID, str(case_data.get("id", "")), "STEP_EVAL")
	payload["is_correct"] = is_correct
	payload["is_fit"] = is_correct and not hint_used
	payload["stability_delta"] = 0.0 if is_correct else -10.0
	payload["elapsed_ms"] = Time.get_ticks_msec() - case_started_ms
	payload["duration"] = float(payload["elapsed_ms"]) / 1000.0
	payload["hint_used"] = hint_used
	payload["attempt_count"] = attempt_count
	payload["expression"] = str(case_data.get("expression", ""))
	payload["values"] = case_data.get("values", {}).duplicate(true)
	payload["step_answers"] = _step_answers.duplicate()

	var correct_answers: Array[int] = []
	var steps: Array = case_data.get("steps", [])
	for step in steps:
		var step_dict: Dictionary = step
		correct_answers.append(int(step_dict.get("correct", 0)))
	payload["correct_steps"] = correct_answers
	payload["wrong_steps"] = wrong_steps.duplicate()
	payload["case_index"] = current_case_idx
	payload["total_cases"] = CASES.size()
	payload["trial_seq"] = trial_seq
	trial_seq += 1
	GlobalMetrics.register_trial(payload)
	if not is_correct:
		GlobalMetrics.add_mistake(
			"case=%s expr=%s wrong_steps=%s answers=%s" % [
				str(case_data.get("id", "")),
				str(case_data.get("expression", "")),
				str(wrong_steps),
				str(_step_answers)
			]
		)

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
		btn_back.text = "<" if _is_compact else _tr_compat("logic.v2.common.back", "logic.v2.b.btn_back", "BACK")
	btn_hint.custom_minimum_size.y = 44.0
	btn_confirm.custom_minimum_size.y = 44.0
	expression_label.add_theme_font_size_override("font_size", 18 if _is_compact else 22)
	steps_label.add_theme_font_size_override("font_size", 14 if _is_compact else 15)
	for btn in _step_buttons:
		btn.custom_minimum_size = Vector2(54, 42) if _is_compact else Vector2(64, 48)

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
	_load_case(0)
	_apply_i18n()

func _exit_tree() -> void:
	if get_tree() and get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.disconnect(_on_viewport_size_changed)
	if GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.disconnect(_on_stability_changed)
	if I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.disconnect(_on_language_changed)
