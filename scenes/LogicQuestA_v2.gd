extends Control

const TrialV2 = preload("res://scripts/TrialV2.gd")
const STAGE_ID: String = "A"

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
		"id": "A_01", "gate": "AND",
		"gate_label_key": "logic.v2.a.A_01.gate_label", "gate_label_default": "AND",
		"story_key": "logic.v2.a.A_01.story", "story_default": "Engine starts only if KEY is inserted AND START is pressed.",
		"inputs": [[0, 0], [0, 1], [1, 0], [1, 1]], "outputs": [0, 0, 0, 1],
		"revealed": [0],
		"explain_key": "logic.v2.a.A_01.explain", "explain_default": "AND gives 1 only when BOTH inputs are 1.\n0 AND 0 = 0,  0 AND 1 = 0,  1 AND 0 = 0,  1 AND 1 = 1"
	},
	{
		"id": "A_02", "gate": "OR",
		"gate_label_key": "logic.v2.a.A_02.gate_label", "gate_label_default": "OR",
		"story_key": "logic.v2.a.A_02.story", "story_default": "Alarm triggers if SMOKE or MOTION is detected.",
		"inputs": [[0, 0], [0, 1], [1, 0], [1, 1]], "outputs": [0, 1, 1, 1],
		"revealed": [0],
		"explain_key": "logic.v2.a.A_02.explain", "explain_default": "OR gives 1 when AT LEAST ONE input is 1.\n0 OR 0 = 0,  0 OR 1 = 1,  1 OR 0 = 1,  1 OR 1 = 1"
	},
	{
		"id": "A_03", "gate": "NOT",
		"gate_label_key": "logic.v2.a.A_03.gate_label", "gate_label_default": "NOT",
		"story_key": "logic.v2.a.A_03.story", "story_default": "Inverter: if signal is present, output is absent, and vice versa.",
		"inputs": [[0], [1]], "outputs": [1, 0],
		"revealed": [],
		"explain_key": "logic.v2.a.A_03.explain", "explain_default": "NOT inverts the input signal.\nNOT 0 = 1,  NOT 1 = 0"
	},
	{
		"id": "A_04", "gate": "XOR",
		"gate_label_key": "logic.v2.a.A_04.gate_label", "gate_label_default": "XOR (Exclusive OR)",
		"story_key": "logic.v2.a.A_04.story", "story_default": "Lamp toggles when ONE switch changes, but not both.",
		"inputs": [[0, 0], [0, 1], [1, 0], [1, 1]], "outputs": [0, 1, 1, 0],
		"revealed": [0, 3],
		"explain_key": "logic.v2.a.A_04.explain", "explain_default": "XOR gives 1 when inputs DIFFER.\n0 XOR 0 = 0,  0 XOR 1 = 1,  1 XOR 0 = 1,  1 XOR 1 = 0"
	},
	{
		"id": "A_05", "gate": "NAND",
		"gate_label_key": "logic.v2.a.A_05.gate_label", "gate_label_default": "NAND",
		"story_key": "logic.v2.a.A_05.story", "story_default": "Protection disables only if BOTH keys are turned simultaneously.",
		"inputs": [[0, 0], [0, 1], [1, 0], [1, 1]], "outputs": [1, 1, 1, 0],
		"revealed": [3],
		"explain_key": "logic.v2.a.A_05.explain", "explain_default": "NAND = NOT(AND). Gives 0 only when BOTH inputs = 1.\nAll other cases = 1."
	},
	{
		"id": "A_06", "gate": "NOR",
		"gate_label_key": "logic.v2.a.A_06.gate_label", "gate_label_default": "NOR",
		"story_key": "logic.v2.a.A_06.story", "story_default": "System is idle only when NO sensor is active.",
		"inputs": [[0, 0], [0, 1], [1, 0], [1, 1]], "outputs": [1, 0, 0, 0],
		"revealed": [0],
		"explain_key": "logic.v2.a.A_06.explain", "explain_default": "NOR = NOT(OR). Gives 1 only when BOTH inputs = 0.\nAny 1 gives output 0."
	},
	{
		"id": "A_07", "gate": "AND",
		"gate_label_key": "logic.v2.a.A_07.gate_label", "gate_label_default": "AND",
		"story_key": "logic.v2.a.A_07.story", "story_default": "Access granted: CARD applied AND PIN correct.",
		"inputs": [[0, 0], [0, 1], [1, 0], [1, 1]], "outputs": [0, 0, 0, 1],
		"revealed": [],
		"explain_key": "logic.v2.a.A_07.explain", "explain_default": "AND: both conditions must be true simultaneously."
	},
	{
		"id": "A_08", "gate": "OR",
		"gate_label_key": "logic.v2.a.A_08.gate_label", "gate_label_default": "OR",
		"story_key": "logic.v2.a.A_08.story", "story_default": "Notification: CALL or MESSAGE received.",
		"inputs": [[0, 0], [0, 1], [1, 0], [1, 1]], "outputs": [0, 1, 1, 1],
		"revealed": [],
		"explain_key": "logic.v2.a.A_08.explain", "explain_default": "OR: one condition is sufficient."
	},
	{
		"id": "A_09", "gate": "XOR",
		"gate_label_key": "logic.v2.a.A_09.gate_label", "gate_label_default": "XOR (Exclusive OR)",
		"story_key": "logic.v2.a.A_09.story", "story_default": "Toggle mode: press ONE switch, but not both.",
		"inputs": [[0, 0], [0, 1], [1, 0], [1, 1]], "outputs": [0, 1, 1, 0],
		"revealed": [],
		"explain_key": "logic.v2.a.A_09.explain", "explain_default": "XOR: inputs must differ. Same inputs give 0."
	},
	{
		"id": "A_10", "gate": "NAND",
		"gate_label_key": "logic.v2.a.A_10.gate_label", "gate_label_default": "NAND",
		"story_key": "logic.v2.a.A_10.story", "story_default": "Emergency lock: triggers if NOT all systems are active.",
		"inputs": [[0, 0], [0, 1], [1, 0], [1, 1]], "outputs": [1, 1, 1, 0],
		"revealed": [],
		"explain_key": "logic.v2.a.A_10.explain", "explain_default": "NAND: 0 only when both are 1, otherwise always 1."
	},
]

# Layout nodes
var btn_back: Button
var title_label: Label
var progress_label: Label
var stability_bar: ProgressBar
var content_scroll: ScrollContainer
var content_vbox: VBoxContainer
var question_label: Label
var table_grid: GridContainer
var explain_card: PanelContainer
var explain_label: Label
var status_label: Label
var btn_hint: Button
var btn_confirm: Button
var _gate_label_node: Label

# State
var current_case_idx: int = 0
var _user_answers: Array = []
var _answer_buttons: Dictionary = {}
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
var _active_explain_semantic: String = "info"
var _done_title_label: Label
var _done_body_label: Label

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

func _cell_style_flat(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.corner_radius_top_left = 4
	s.corner_radius_top_right = 4
	s.corner_radius_bottom_left = 4
	s.corner_radius_bottom_right = 4
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s

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

	var q_panel := _make_panel()
	q_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(q_panel)
	var q_inner := VBoxContainer.new()
	q_inner.add_theme_constant_override("separation", 6)
	q_panel.add_child(q_inner)
	_gate_label_node = Label.new()
	_gate_label_node.add_theme_font_size_override("font_size", 14)
	_gate_label_node.add_theme_color_override("font_color", Color(0.92, 0.2, 0.24))
	q_inner.add_child(_gate_label_node)
	question_label = _make_label("", 15)
	q_inner.add_child(question_label)

	var table_panel := _make_panel()
	table_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(table_panel)
	table_grid = GridContainer.new()
	table_grid.add_theme_constant_override("h_separation", 4)
	table_grid.add_theme_constant_override("v_separation", 4)
	table_panel.add_child(table_grid)

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

# Table
func _add_header(text: String) -> void:
	var cell := PanelContainer.new()
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.add_theme_stylebox_override("panel", _cell_style_flat(Color(0.08, 0.08, 0.09), Color(0.4, 0.4, 0.42)))
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", Color(0.92, 0.2, 0.24))
	cell.add_child(lbl)
	table_grid.add_child(cell)

func _add_fixed_cell(text: String) -> void:
	var cell := PanelContainer.new()
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.add_theme_stylebox_override("panel", _cell_style_flat(Color(0.07, 0.07, 0.08), Color(0.25, 0.25, 0.27)))
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 18)
	cell.add_child(lbl)
	table_grid.add_child(cell)

func _add_revealed_cell(text: String) -> void:
	var cell := PanelContainer.new()
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.add_theme_stylebox_override("panel", _cell_style_flat(Color(0.08, 0.08, 0.09), Color(0.35, 0.35, 0.38)))
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.53))
	cell.add_child(lbl)
	table_grid.add_child(cell)

func _build_table() -> void:
	for child in table_grid.get_children():
		child.queue_free()
	_answer_buttons.clear()

	var case_data: Dictionary = CASES[current_case_idx]
	var inputs: Array = case_data.get("inputs", [])
	var outputs: Array = case_data.get("outputs", [])
	var revealed: Array = case_data.get("revealed", [])
	var in_count: int = int(inputs[0].size())
	table_grid.columns = in_count + 1

	for i in range(in_count):
		_add_header("ABCDEFGH"[i])
	_add_header("F")

	_user_answers.clear()
	for row_idx in range(inputs.size()):
		for val in inputs[row_idx]:
			_add_fixed_cell(str(val))

		if row_idx in revealed:
			_add_revealed_cell(str(outputs[row_idx]))
			_user_answers.append(outputs[row_idx])
		else:
			var btn := Button.new()
			btn.text = "?"
			btn.custom_minimum_size = Vector2(64, 52)
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.add_theme_font_size_override("font_size", 22)
			btn.focus_mode = Control.FOCUS_NONE
			btn.pressed.connect(_on_answer_toggle.bind(row_idx))
			table_grid.add_child(btn)
			_answer_buttons[row_idx] = btn
			_user_answers.append(-1)

# i18n
func _case_text(case_data: Dictionary, field_name: String) -> String:
	var key: String = str(case_data.get("%s_key" % field_name, ""))
	var default_text: String = str(case_data.get("%s_default" % field_name, case_data.get(field_name, "")))
	if key.is_empty():
		return default_text
	return _tr(key, default_text)

func _apply_i18n() -> void:
	title_label.text = _tr("logic.v2.a.title", "INTERROGATION: PROTOCOL")
	btn_hint.text = _tr_compat("logic.v2.common.hint", "logic.v2.a.btn_hint", "HINT")
	btn_confirm.text = _tr_compat("logic.v2.common.confirm", "logic.v2.a.btn_confirm", "CONFIRM")

	if _quest_done:
		btn_back.text = _tr("logic.v2.common.btn_exit", "EXIT")
	else:
		btn_back.text = "<" if _is_compact else _tr_compat("logic.v2.common.back", "logic.v2.a.btn_back", "BACK")

	if _status_i18n_key != "":
		status_label.text = _tr(_status_i18n_key, _status_i18n_default, _status_i18n_params)

	if _quest_done:
		if _done_title_label:
			_done_title_label.text = _tr("logic.v2.a.complete", "All levels complete!")
		if _done_body_label:
			_done_body_label.text = _tr(
				"logic.v2.a.complete_body",
				"All {n} protocols studied.\nTruth tables are the foundation of logic analysis.",
				{"n": CASES.size()}
			)
		return

	_refresh_case_i18n()
	if _active_explain_mode == "intro":
		_show_intro()
	elif _active_explain_mode == "case" and current_case_idx >= 0 and current_case_idx < CASES.size():
		explain_label.text = _case_text(CASES[current_case_idx], "explain")

func _refresh_case_i18n() -> void:
	if _quest_done or current_case_idx < 0 or current_case_idx >= CASES.size():
		return
	var case_data: Dictionary = CASES[current_case_idx]
	var gate_label: String = _case_text(case_data, "gate_label")
	_gate_label_node.text = _tr("logic.v2.a.operation", "OPERATION: {gate}", {"gate": gate_label})
	question_label.text = _case_text(case_data, "story")

func _on_language_changed(_new_language: String) -> void:
	_apply_i18n()

# Case loading
func _load_case(idx: int) -> void:
	current_case_idx = idx
	_done_title_label = null
	_done_body_label = null
	hint_used = false
	attempt_count = 0
	case_started_ms = Time.get_ticks_msec()
	_active_explain_mode = ""
	_status_i18n_key = ""
	_status_i18n_default = ""
	_status_i18n_params = {}

	progress_label.text = "%d/%d" % [idx + 1, CASES.size()]
	explain_card.visible = false
	status_label.text = ""
	btn_confirm.disabled = false
	btn_hint.disabled = false

	_build_table()
	_refresh_case_i18n()

	if idx == 0:
		_show_intro()

func _show_intro() -> void:
	_active_explain_mode = "intro"
	_active_explain_semantic = "info"
	_apply_semantic_style(explain_card, "info")
	explain_label.text = _tr(
		"logic.v2.a.intro",
		"TASK: Fill the truth table.\n\nTap cells with '?' to toggle: ? -> 0 -> 1 -> ?\nThen press CONFIRM.\n\nHINT will reveal one correct cell."
	)
	explain_label.add_theme_color_override("font_color", Color(0.75, 0.82, 0.9))
	explain_card.visible = true

# Interactions
func _on_answer_toggle(row_idx: int) -> void:
	var cur: int = int(_user_answers[row_idx])
	match cur:
		-1:
			_user_answers[row_idx] = 0
		0:
			_user_answers[row_idx] = 1
		1:
			_user_answers[row_idx] = -1
	var btn: Button = _answer_buttons.get(row_idx)
	if btn:
		match int(_user_answers[row_idx]):
			-1:
				btn.text = "?"
			0:
				btn.text = "0"
			1:
				btn.text = "1"

func _on_hint_pressed() -> void:
	hint_used = true
	var case_data: Dictionary = CASES[current_case_idx]
	var outputs: Array = case_data.get("outputs", [])
	for row_idx in _answer_buttons:
		if int(_user_answers[row_idx]) == -1:
			_user_answers[row_idx] = outputs[row_idx]
			var btn: Button = _answer_buttons[row_idx]
			btn.text = str(outputs[row_idx])
			btn.add_theme_color_override("font_color", Color(0.55, 0.65, 0.85))
			break

func _on_confirm_pressed() -> void:
	var case_data: Dictionary = CASES[current_case_idx]
	var outputs: Array = case_data.get("outputs", [])

	var all_filled: bool = true
	var all_correct: bool = true
	var wrong_indices: Array = []

	for row_idx in range(outputs.size()):
		if int(_user_answers[row_idx]) == -1:
			all_filled = false
			continue
		var btn: Button = _answer_buttons.get(row_idx)
		if btn == null:
			continue
		if int(_user_answers[row_idx]) == int(outputs[row_idx]):
			btn.add_theme_color_override("font_color", Color(0.7, 0.85, 0.7))
		else:
			btn.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
			all_correct = false
			wrong_indices.append(row_idx)

	if not all_filled:
		_status_i18n_key = "logic.v2.a.fill_all"
		_status_i18n_default = "Fill all cells with '?'."
		_status_i18n_params = {}
		status_label.text = _tr(_status_i18n_key, _status_i18n_default)
		return

	attempt_count += 1
	var is_correct: bool = all_correct
	_show_explain(is_correct, _case_text(case_data, "explain"))
	_register_trial(is_correct, wrong_indices)

	if is_correct:
		_status_i18n_key = "logic.v2.a.correct"
		_status_i18n_default = "Correct!"
		_status_i18n_params = {}
		status_label.text = _tr(_status_i18n_key, _status_i18n_default)
		btn_confirm.disabled = true
		btn_hint.disabled = true
		await get_tree().create_timer(1.8).timeout
		_next_case()
	else:
		_status_i18n_key = "logic.v2.a.wrong"
		_status_i18n_default = "Some errors. Try again."
		_status_i18n_params = {}
		status_label.text = _tr(_status_i18n_key, _status_i18n_default)

func _show_explain(is_correct: bool, text: String) -> void:
	_active_explain_mode = "case"
	_active_explain_semantic = "correct" if is_correct else "wrong"
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
	GlobalMetrics.finish_quest("LOGIC_QUEST_A", 100, true)

	for child in content_vbox.get_children():
		child.queue_free()

	var done_panel := _make_semantic_panel("correct")
	done_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(done_panel)
	var done_vbox := VBoxContainer.new()
	done_vbox.add_theme_constant_override("separation", 12)
	done_panel.add_child(done_vbox)

	_done_title_label = _make_label(_tr("logic.v2.a.complete", "All levels complete!"), 20)
	_done_title_label.add_theme_color_override("font_color", Color(0.7, 0.85, 0.7))
	_done_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	done_vbox.add_child(_done_title_label)

	_done_body_label = _make_label(
		_tr(
			"logic.v2.a.complete_body",
			"All {n} protocols studied.\nTruth tables are the foundation of logic analysis.",
			{"n": CASES.size()}
		),
		15
	)
	done_vbox.add_child(_done_body_label)

	btn_confirm.disabled = true
	btn_hint.disabled = true
	btn_back.text = _tr("logic.v2.common.btn_exit", "EXIT")

# Metrics
func _register_trial(is_correct: bool, wrong_indices: Array = []) -> void:
	var case_data: Dictionary = CASES[current_case_idx]
	var payload: Dictionary = TrialV2.build("LOGIC_QUEST", "A", str(case_data.get("id", "")), "TRUTH_TABLE_FILL")
	payload["is_correct"] = is_correct
	payload["is_fit"] = is_correct and not hint_used
	payload["stability_delta"] = 0.0 if is_correct else -10.0
	payload["elapsed_ms"] = Time.get_ticks_msec() - case_started_ms
	payload["duration"] = float(payload["elapsed_ms"]) / 1000.0
	payload["hint_used"] = hint_used
	payload["attempt_count"] = attempt_count
	payload["gate"] = str(case_data.get("gate", ""))
	payload["case_index"] = current_case_idx
	payload["total_cases"] = CASES.size()
	payload["wrong_cells"] = wrong_indices
	payload["trial_seq"] = trial_seq
	trial_seq += 1
	GlobalMetrics.register_trial(payload)
	if not is_correct:
		GlobalMetrics.add_mistake(
			"case=%s gate=%s wrong_rows=%s" % [
				str(case_data.get("id", "")),
				str(case_data.get("gate", "")),
				str(wrong_indices)
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
		btn_back.text = "<" if _is_compact else _tr_compat("logic.v2.common.back", "logic.v2.a.btn_back", "BACK")
	btn_hint.custom_minimum_size.y = 44.0
	btn_confirm.custom_minimum_size.y = 44.0
	question_label.add_theme_font_size_override("font_size", 14 if _is_compact else 15)

func _ready() -> void:
	_build_ui()
	_connect_signals()
	GlobalMetrics.start_quest("LOGIC_QUEST_A")
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
