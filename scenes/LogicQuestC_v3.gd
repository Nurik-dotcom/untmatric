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
		"id": "C_01",
		"original": "(A AND B) OR (A AND C)",
		"law_key": "logic.v3.c.C_01.law",
		"law_default": "Distributivity",
		"law_hint_key": "logic.v3.c.C_01.law_hint",
		"law_hint_default": "Factor out common A",
		"correct_sequence": ["A", "AND", "LP", "B", "OR", "C", "RP"],
		"correct_display": "A AND (B OR C)",
		"available_tokens": [
			{"id": "A", "text": "A"},
			{"id": "AND", "text": "AND"},
			{"id": "OR", "text": "OR"},
			{"id": "B", "text": "B"},
			{"id": "C", "text": "C"},
			{"id": "LP", "text": "("},
			{"id": "RP", "text": ")"},
			{"id": "NOT", "text": "NOT", "trap": true}
		],
		"explanation_key": "logic.v3.c.C_01.explanation",
		"explanation_default": "(A∧B)∨(A∧C) = A∧(B∨C)\nCommon factor A is extracted.\nAND and OR swap places inside brackets."
	},
	{
		"id": "C_02",
		"original": "(A OR B) AND (A OR C)",
		"law_key": "logic.v3.c.C_02.law",
		"law_default": "Distributivity",
		"law_hint_key": "logic.v3.c.C_02.law_hint",
		"law_hint_default": "Factor out common A",
		"correct_sequence": ["A", "OR", "LP", "B", "AND", "C", "RP"],
		"correct_display": "A OR (B AND C)",
		"available_tokens": [
			{"id": "A", "text": "A"},
			{"id": "AND", "text": "AND"},
			{"id": "OR", "text": "OR"},
			{"id": "B", "text": "B"},
			{"id": "C", "text": "C"},
			{"id": "LP", "text": "("},
			{"id": "RP", "text": ")"},
			{"id": "XOR", "text": "XOR", "trap": true}
		],
		"explanation_key": "logic.v3.c.C_02.explanation",
		"explanation_default": "(A∨B)∧(A∨C) = A∨(B∧C)\nReverse distributivity."
	},
	{
		"id": "C_03",
		"original": "A OR (A AND B)",
		"law_key": "logic.v3.c.C_03.law",
		"law_default": "Absorption",
		"law_hint_key": "logic.v3.c.C_03.law_hint",
		"law_hint_default": "A absorbs A AND B",
		"correct_sequence": ["A"],
		"correct_display": "A",
		"available_tokens": [
			{"id": "A", "text": "A"},
			{"id": "B", "text": "B", "trap": true},
			{"id": "AND", "text": "AND", "trap": true},
			{"id": "OR", "text": "OR", "trap": true}
		],
		"explanation_key": "logic.v3.c.C_03.explanation",
		"explanation_default": "A∨(A∧B) = A\nIf A=1, whole expression =1.\nIf A=0, A∧B=0 and 0∨0=0=A."
	},
	{
		"id": "C_04",
		"original": "A AND (A OR B)",
		"law_key": "logic.v3.c.C_04.law",
		"law_default": "Absorption",
		"law_hint_key": "logic.v3.c.C_04.law_hint",
		"law_hint_default": "A absorbs A OR B",
		"correct_sequence": ["A"],
		"correct_display": "A",
		"available_tokens": [
			{"id": "A", "text": "A"},
			{"id": "B", "text": "B", "trap": true},
			{"id": "AND", "text": "AND", "trap": true},
			{"id": "OR", "text": "OR", "trap": true}
		],
		"explanation_key": "logic.v3.c.C_04.explanation",
		"explanation_default": "A∧(A∨B) = A\nReverse absorption."
	},
	{
		"id": "C_05",
		"original": "NOT(A AND B)",
		"law_key": "logic.v3.c.C_05.law",
		"law_default": "De Morgan",
		"law_hint_key": "logic.v3.c.C_05.law_hint",
		"law_hint_default": "NOT before AND -> OR, invert each",
		"correct_sequence": ["LP", "NOT", "A", "RP", "OR", "LP", "NOT", "B", "RP"],
		"correct_display": "(NOT A) OR (NOT B)",
		"available_tokens": [
			{"id": "NOT", "text": "NOT"},
			{"id": "A", "text": "A"},
			{"id": "B", "text": "B"},
			{"id": "OR", "text": "OR"},
			{"id": "AND", "text": "AND", "trap": true},
			{"id": "LP", "text": "("},
			{"id": "LP2", "text": "("},
			{"id": "RP", "text": ")"},
			{"id": "RP2", "text": ")"},
			{"id": "NOT2", "text": "NOT"}
		],
		"explanation_key": "logic.v3.c.C_05.explanation",
		"explanation_default": "¬(A∧B) = ¬A∨¬B\nDe Morgan: AND→OR, invert each input."
	},
	{
		"id": "C_06",
		"original": "NOT(A OR B)",
		"law_key": "logic.v3.c.C_06.law",
		"law_default": "De Morgan",
		"law_hint_key": "logic.v3.c.C_06.law_hint",
		"law_hint_default": "NOT before OR -> AND, invert each",
		"correct_sequence": ["LP", "NOT", "A", "RP", "AND", "LP", "NOT", "B", "RP"],
		"correct_display": "(NOT A) AND (NOT B)",
		"available_tokens": [
			{"id": "NOT", "text": "NOT"},
			{"id": "NOT2", "text": "NOT"},
			{"id": "A", "text": "A"},
			{"id": "B", "text": "B"},
			{"id": "AND", "text": "AND"},
			{"id": "OR", "text": "OR", "trap": true},
			{"id": "LP", "text": "("},
			{"id": "LP2", "text": "("},
			{"id": "RP", "text": ")"},
			{"id": "RP2", "text": ")"}
		],
		"explanation_key": "logic.v3.c.C_06.explanation",
		"explanation_default": "¬(A∨B) = ¬A∧¬B\nDe Morgan: OR→AND, invert each input."
	},
	{
		"id": "C_07",
		"original": "NOT(NOT A)",
		"law_key": "logic.v3.c.C_07.law",
		"law_default": "Double Negation",
		"law_hint_key": "logic.v3.c.C_07.law_hint",
		"law_hint_default": "Two NOTs cancel out",
		"correct_sequence": ["A"],
		"correct_display": "A",
		"available_tokens": [
			{"id": "A", "text": "A"},
			{"id": "NOT", "text": "NOT", "trap": true},
			{"id": "B", "text": "B", "trap": true}
		],
		"explanation_key": "logic.v3.c.C_07.explanation",
		"explanation_default": "¬(¬A) = A\nTwo negations cancel each other."
	},
	{
		"id": "C_08",
		"original": "NOT(NOT(A OR B))",
		"law_key": "logic.v3.c.C_08.law",
		"law_default": "Double Negation",
		"law_hint_key": "logic.v3.c.C_08.law_hint",
		"law_hint_default": "Remove two outer NOTs",
		"correct_sequence": ["A", "OR", "B"],
		"correct_display": "A OR B",
		"available_tokens": [
			{"id": "A", "text": "A"},
			{"id": "OR", "text": "OR"},
			{"id": "B", "text": "B"},
			{"id": "NOT", "text": "NOT", "trap": true},
			{"id": "AND", "text": "AND", "trap": true},
			{"id": "LP", "text": "(", "trap": true},
			{"id": "RP", "text": ")", "trap": true}
		],
		"explanation_key": "logic.v3.c.C_08.explanation",
		"explanation_default": "¬(¬(A∨B)) = A∨B\nOuter double NOT removed, inner expression stays."
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
var code_area: HFlowContainer
var token_repo: GridContainer
var explain_card: PanelContainer
var explain_label: Label
var status_label: Label
var btn_clear: Button
var btn_hint: Button
var btn_confirm: Button
var _original_title_label: Label
var _law_prefix_label: Label
var _result_title_label: Label
var _available_title_label: Label
var _done_title_label: Label
var _done_body_label: Label

# Builder state
var _placed_tokens: Array[String] = []
var _repo_buttons: Dictionary = {}
var _token_text_by_instance: Dictionary = {}
var _token_canonical_by_instance: Dictionary = {}
var _token_trap_by_instance: Dictionary = {}
var _token_order: Array[String] = []
var _code_chips: Array[PanelContainer] = []

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
var _last_hint_token: String = ""

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

func _apply_chip_style(panel: PanelContainer, semantic: String) -> void:
	var s := StyleBoxFlat.new()
	match semantic:
		"correct":
			s.bg_color = Color(0.06, 0.1, 0.06, 0.95)
			s.border_color = Color(0.2, 0.55, 0.25, 0.8)
		"wrong":
			s.bg_color = Color(0.1, 0.06, 0.06, 0.95)
			s.border_color = Color(0.55, 0.2, 0.2, 0.8)
		"hint":
			s.bg_color = Color(0.06, 0.06, 0.1, 0.95)
			s.border_color = Color(0.35, 0.35, 0.6, 0.8)
		_:
			s.bg_color = Color(0.08, 0.08, 0.1, 0.95)
			s.border_color = Color(0.23, 0.23, 0.3, 0.7)
	s.set_border_width_all(1)
	s.corner_radius_top_left = 6
	s.corner_radius_top_right = 6
	s.corner_radius_bottom_left = 6
	s.corner_radius_bottom_right = 6
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 8
	s.content_margin_bottom = 8
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

	var original_panel := _make_panel()
	original_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(original_panel)
	var original_vbox := VBoxContainer.new()
	original_vbox.add_theme_constant_override("separation", 6)
	original_panel.add_child(original_vbox)
	_original_title_label = _make_label("", 13)
	_original_title_label.add_theme_color_override("font_color", Color(0.92, 0.2, 0.24))
	original_vbox.add_child(_original_title_label)
	original_label = Label.new()
	original_label.add_theme_font_size_override("font_size", 20)
	original_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	original_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	original_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	original_vbox.add_child(original_label)

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

	var result_panel := _make_panel()
	result_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(result_panel)
	var result_vbox := VBoxContainer.new()
	result_vbox.add_theme_constant_override("separation", 8)
	result_panel.add_child(result_vbox)
	_result_title_label = _make_label("", 13)
	_result_title_label.add_theme_color_override("font_color", Color(0.92, 0.2, 0.24))
	result_vbox.add_child(_result_title_label)
	var code_frame := _make_panel()
	code_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result_vbox.add_child(code_frame)
	code_area = HFlowContainer.new()
	code_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	code_area.add_theme_constant_override("h_separation", 8)
	code_area.add_theme_constant_override("v_separation", 8)
	code_frame.add_child(code_area)

	_available_title_label = _make_label("", 13)
	_available_title_label.add_theme_color_override("font_color", Color(0.92, 0.2, 0.24))
	content_vbox.add_child(_available_title_label)

	var repo_panel := _make_panel()
	repo_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(repo_panel)
	token_repo = GridContainer.new()
	token_repo.columns = 4
	token_repo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	token_repo.add_theme_constant_override("h_separation", 8)
	token_repo.add_theme_constant_override("v_separation", 8)
	repo_panel.add_child(token_repo)

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

	btn_clear = _make_button("")
	btn_clear.custom_minimum_size.y = 48
	actions.add_child(btn_clear)

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

func _derive_canonical_token_id(token_id: String, token_data: Dictionary, correct_seq: Array) -> String:
	if token_data.has("canonical"):
		return str(token_data.get("canonical", token_id))

	var correct_set: Dictionary = {}
	for token in correct_seq:
		correct_set[str(token)] = true

	if correct_set.has(token_id):
		return token_id

	var cut: int = token_id.length()
	while cut > 0:
		var code: int = token_id.unicode_at(cut - 1)
		if code >= 48 and code <= 57:
			cut -= 1
		else:
			break

	if cut < token_id.length():
		var base: String = token_id.substr(0, cut)
		if correct_set.has(base):
			return base

	return token_id

func _get_token_text(token_instance_id: String) -> String:
	return str(_token_text_by_instance.get(token_instance_id, token_instance_id))

func _get_token_canonical(token_instance_id: String) -> String:
	return str(_token_canonical_by_instance.get(token_instance_id, token_instance_id))

func _get_placed_canonical_sequence() -> Array[String]:
	var placed: Array[String] = []
	for token_id in _placed_tokens:
		placed.append(_get_token_canonical(token_id))
	return placed

func _clear_code_area() -> void:
	for child in code_area.get_children():
		child.queue_free()
	_code_chips.clear()

func _build_repository(case_data: Dictionary) -> void:
	for child in token_repo.get_children():
		child.queue_free()
	_repo_buttons.clear()
	_token_text_by_instance.clear()
	_token_canonical_by_instance.clear()
	_token_trap_by_instance.clear()
	_token_order.clear()
	_placed_tokens.clear()
	_clear_code_area()

	var tokens: Array = case_data.get("available_tokens", [])
	var correct_seq: Array = case_data.get("correct_sequence", [])
	for token_data in tokens:
		var token: Dictionary = token_data
		var tid: String = str(token.get("id", ""))
		if tid.is_empty():
			continue
		var text: String = str(token.get("text", tid))
		var canonical: String = _derive_canonical_token_id(tid, token, correct_seq)
		_token_text_by_instance[tid] = text
		_token_canonical_by_instance[tid] = canonical
		_token_trap_by_instance[tid] = bool(token.get("trap", false))
		_token_order.append(tid)

		var btn := Button.new()
		btn.text = text
		btn.custom_minimum_size = Vector2(56, 48)
		btn.add_theme_font_size_override("font_size", 18)
		btn.focus_mode = Control.FOCUS_NONE
		btn.set_meta("token_id", tid)
		btn.pressed.connect(_on_repo_token_pressed.bind(tid))
		token_repo.add_child(btn)
		_repo_buttons[tid] = btn

func _find_available_instance_for_canonical(canonical: String) -> String:
	for token_id in _token_order:
		if not _repo_buttons.has(token_id):
			continue
		var btn: Button = _repo_buttons[token_id]
		if not btn.visible:
			continue
		if _get_token_canonical(token_id) == canonical:
			return token_id
	return ""

func _rebuild_code_area() -> void:
	_clear_code_area()
	for i in range(_placed_tokens.size()):
		var token_id: String = _placed_tokens[i]
		var chip := PanelContainer.new()
		chip.custom_minimum_size = Vector2(0, 44)
		chip.set_meta("token_id", token_id)
		_apply_chip_style(chip, "neutral")

		var lbl := Label.new()
		lbl.text = _get_token_text(token_id)
		lbl.add_theme_font_size_override("font_size", 18)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chip.add_child(lbl)

		var click := Button.new()
		click.flat = true
		click.focus_mode = Control.FOCUS_NONE
		click.set_anchors_preset(Control.PRESET_FULL_RECT)
		click.modulate = Color(1, 1, 1, 0)
		click.pressed.connect(_on_code_chip_pressed.bind(i))
		chip.add_child(click)

		code_area.add_child(chip)
		_code_chips.append(chip)

func _check_sequence(case_data: Dictionary) -> bool:
	var correct_seq: Array = case_data.get("correct_sequence", [])
	var placed: Array[String] = _get_placed_canonical_sequence()
	return placed == correct_seq

func _show_intro() -> void:
	_active_explain_mode = "intro"
	_apply_semantic_style(explain_card, "info")
	explain_label.text = _tr(
		"logic.v3.c.intro",
		"TASK: Build the simplified expression from tokens.\n\nTap a token in AVAILABLE TOKENS to place it into RESULT.\nTap a token in RESULT to remove it.\nUse CLEAR to reset the line."
	)
	explain_label.add_theme_color_override("font_color", Color(0.75, 0.82, 0.9))
	explain_card.visible = true

func _show_hint_text(token_text: String) -> void:
	_apply_semantic_style(explain_card, "hint")
	explain_label.text = _tr("logic.v3.c.hint_text", "Hint token: {token}", {"token": token_text})
	explain_label.add_theme_color_override("font_color", Color(0.75, 0.82, 0.9))
	explain_card.visible = true

func _show_explain(is_correct: bool, text: String) -> void:
	explain_card.visible = true
	explain_label.text = text
	if is_correct:
		_apply_semantic_style(explain_card, "correct")
		explain_label.add_theme_color_override("font_color", Color(0.7, 0.85, 0.7))
	else:
		_apply_semantic_style(explain_card, "wrong")
		explain_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.6))

func _apply_i18n() -> void:
	title_label.text = _tr("logic.v3.c.title", "INTERROGATION: SIMPLIFY")
	_original_title_label.text = _tr("logic.v3.c.original_label", "ORIGINAL:")
	_law_prefix_label.text = _tr("logic.v2.c.law_prefix", "LAW:")
	_result_title_label.text = _tr("logic.v3.c.result_label", "RESULT:")
	_available_title_label.text = _tr("logic.v3.c.available_label", "AVAILABLE TOKENS:")
	btn_clear.text = _tr("logic.v3.c.btn_clear", "CLEAR")
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
			_done_title_label.text = _tr("logic.v3.c.complete", "All levels complete!")
		if _done_body_label:
			_done_body_label.text = _tr(
				"logic.v3.c.complete_body",
				"All {n} simplification constructors completed.\nYou can now transform logic expressions token by token.",
				{"n": CASES.size()}
			)
		return

	_refresh_case_i18n()
	if _active_explain_mode == "intro":
		_show_intro()
	elif _active_explain_mode == "hint" and _last_hint_token != "":
		_show_hint_text(_last_hint_token)
	elif _active_explain_mode == "case" and current_case_idx >= 0 and current_case_idx < CASES.size():
		_show_explain(_last_result_is_correct, _case_text(CASES[current_case_idx], "explanation"))

func _refresh_case_i18n() -> void:
	if _quest_done or current_case_idx < 0 or current_case_idx >= CASES.size():
		return
	var case_data: Dictionary = CASES[current_case_idx]
	original_label.text = str(case_data.get("original", ""))
	law_title_label.text = _case_text(case_data, "law")
	law_hint_label.text = "\"%s\"" % _case_text(case_data, "law_hint")

func _on_language_changed(_new_language: String) -> void:
	_apply_i18n()

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
	_last_hint_token = ""
	_done_title_label = null
	_done_body_label = null

	progress_label.text = "%d/%d" % [idx + 1, CASES.size()]
	explain_card.visible = false
	status_label.text = ""
	btn_confirm.disabled = false
	btn_hint.disabled = false
	btn_clear.disabled = false

	var case_data: Dictionary = CASES[idx]
	_build_repository(case_data)
	_refresh_case_i18n()
	if idx == 0:
		_show_intro()

func _on_repo_token_pressed(token_id: String) -> void:
	if not _repo_buttons.has(token_id):
		return
	var btn: Button = _repo_buttons[token_id]
	if not btn.visible:
		return
	_placed_tokens.append(token_id)
	btn.visible = false
	_rebuild_code_area()

func _on_code_chip_pressed(index: int) -> void:
	if index < 0 or index >= _placed_tokens.size():
		return
	var token_id: String = _placed_tokens[index]
	_placed_tokens.remove_at(index)
	if _repo_buttons.has(token_id):
		_repo_buttons[token_id].visible = true
	_rebuild_code_area()

func _on_clear_pressed() -> void:
	for token_id in _placed_tokens:
		if _repo_buttons.has(token_id):
			_repo_buttons[token_id].visible = true
	_placed_tokens.clear()
	_rebuild_code_area()

func _on_hint_pressed() -> void:
	if current_case_idx < 0 or current_case_idx >= CASES.size():
		return
	var case_data: Dictionary = CASES[current_case_idx]
	var correct_seq: Array = case_data.get("correct_sequence", [])
	var next_idx: int = _placed_tokens.size()
	if next_idx >= correct_seq.size():
		return
	var next_token: String = str(correct_seq[next_idx])
	var next_instance: String = _find_available_instance_for_canonical(next_token)
	if next_instance.is_empty():
		return
	hint_used = true
	_last_hint_token = next_token
	_active_explain_mode = "hint"
	_on_repo_token_pressed(next_instance)
	_show_hint_text(next_token)

func _on_confirm_pressed() -> void:
	if current_case_idx < 0 or current_case_idx >= CASES.size():
		return
	if _placed_tokens.is_empty():
		_status_i18n_key = "logic.v3.c.place_tokens"
		_status_i18n_default = "Place tokens to build expression"
		_status_i18n_params = {}
		status_label.text = _tr(_status_i18n_key, _status_i18n_default)
		return

	var case_data: Dictionary = CASES[current_case_idx]
	var correct_seq: Array = case_data.get("correct_sequence", [])
	var placed_canonical: Array[String] = _get_placed_canonical_sequence()
	var is_correct: bool = placed_canonical == correct_seq
	attempt_count += 1

	if is_correct:
		for chip in _code_chips:
			_apply_chip_style(chip, "correct")
	else:
		for i in range(_code_chips.size()):
			if i < placed_canonical.size() and i < correct_seq.size() and placed_canonical[i] == str(correct_seq[i]):
				_apply_chip_style(_code_chips[i], "correct")
			else:
				_apply_chip_style(_code_chips[i], "wrong")

	_last_result_is_correct = is_correct
	_active_explain_mode = "case"
	_show_explain(is_correct, _case_text(case_data, "explanation"))
	_register_trial(is_correct)

	if is_correct:
		_status_i18n_key = "logic.v2.c.correct"
		_status_i18n_default = "Correct!"
		_status_i18n_params = {}
		status_label.text = _tr(_status_i18n_key, _status_i18n_default)
		btn_confirm.disabled = true
		btn_hint.disabled = true
		btn_clear.disabled = true
		await get_tree().create_timer(2.0).timeout
		_next_case()
	else:
		_status_i18n_key = "logic.v2.c.wrong"
		_status_i18n_default = "Wrong. Read the explanation."
		_status_i18n_params = {}
		status_label.text = _tr(_status_i18n_key, _status_i18n_default)

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

	_done_title_label = _make_label(_tr("logic.v3.c.complete", "All levels complete!"), 20)
	_done_title_label.add_theme_color_override("font_color", Color(0.7, 0.85, 0.7))
	_done_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	done_vbox.add_child(_done_title_label)

	_done_body_label = _make_label(
		_tr(
			"logic.v3.c.complete_body",
			"All {n} simplification constructors completed.\nYou can now transform logic expressions token by token.",
			{"n": CASES.size()}
		),
		15
	)
	done_vbox.add_child(_done_body_label)

	btn_confirm.disabled = true
	btn_hint.disabled = true
	btn_clear.disabled = true
	btn_back.text = _tr("logic.v2.common.btn_exit", "EXIT")

func _register_trial(is_correct: bool) -> void:
	var case_data: Dictionary = CASES[current_case_idx]
	var placed_canonical: Array[String] = _get_placed_canonical_sequence()
	var trap_tokens_used: Array[String] = []
	for token_id in _placed_tokens:
		if bool(_token_trap_by_instance.get(token_id, false)):
			trap_tokens_used.append(token_id)

	var payload: Dictionary = TrialV2.build("LOGIC_QUEST", STAGE_ID, str(case_data.get("id", "")), "TOKEN_BUILD")
	payload["is_correct"] = is_correct
	payload["is_fit"] = is_correct and not hint_used
	payload["stability_delta"] = 0.0 if is_correct else -10.0
	payload["elapsed_ms"] = Time.get_ticks_msec() - case_started_ms
	payload["duration"] = float(payload["elapsed_ms"]) / 1000.0
	payload["hint_used"] = hint_used
	payload["attempt_count"] = attempt_count
	payload["law"] = _case_text(case_data, "law")
	payload["original"] = str(case_data.get("original", ""))
	payload["placed_tokens"] = _placed_tokens.duplicate()
	payload["placed_sequence"] = placed_canonical
	payload["correct_sequence"] = case_data.get("correct_sequence", []).duplicate()
	payload["trap_tokens_used"] = trap_tokens_used
	payload["case_index"] = current_case_idx
	payload["total_cases"] = CASES.size()
	payload["trial_seq"] = trial_seq
	trial_seq += 1
	GlobalMetrics.register_trial(payload)
	if not is_correct:
		GlobalMetrics.add_mistake(
			"case=%s law=%s placed=%s" % [
				str(case_data.get("id", "")),
				_case_text(case_data, "law"),
				str(placed_canonical)
			]
		)

func _connect_signals() -> void:
	btn_back.pressed.connect(_on_back_pressed)
	btn_clear.pressed.connect(_on_clear_pressed)
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
	btn_clear.custom_minimum_size.y = 44.0
	btn_hint.custom_minimum_size.y = 44.0
	btn_confirm.custom_minimum_size.y = 44.0
	original_label.add_theme_font_size_override("font_size", 16 if _is_compact else 20)
	token_repo.columns = 4 if _is_compact else 5
	for token_id in _token_order:
		if _repo_buttons.has(token_id):
			var btn: Button = _repo_buttons[token_id]
			btn.custom_minimum_size = Vector2(52, 42) if _is_compact else Vector2(56, 48)

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
