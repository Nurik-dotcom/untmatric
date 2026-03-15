extends Control

const CasesHub = preload("res://scripts/case_07/da7_cases.gd")
const CasesModuleB = preload("res://scripts/case_07/da7_cases_b.gd")

const BREAKPOINT_PX := 800
const SESSION_CASE_COUNT := 6
const SUBMIT_BASE_TEXT := "SUBMIT"
const LAYOUT_MOBILE := "mobile"
const LAYOUT_DESKTOP := "desktop"

const MODE_FILTER := "FILTER"
const MODE_RELATION := "RELATION"

var session_cases: Array = []
var current_case_index := -1
var current_case: Dictionary = {}
var mode := ""
var is_trial_active := false

var trial_seq: int = 0
var task_session: Dictionary = {}
var mode_id: String = ""
var selection_toggle_count: int = 0
var selected_count_peak: int = 0
var submit_attempt_count: int = 0
var relation_drag_start_count: int = 0
var relation_drag_complete_count: int = 0
var relation_drag_fail_count: int = 0
var relation_wrong_origin_count: int = 0
var relation_duplicate_link_count: int = 0
var inspected_before_submit: bool = false
var changed_after_inspect: bool = false
var changed_after_error: bool = false
var time_to_first_toggle_ms: int = -1
var time_to_first_drag_ms: int = -1
var time_to_submit_ms: int = -1
var details_open_count: int = 0
var hint_open_count: int = 0

var ui_ready_ts := 0
var first_action_ts := -1
var scroll_used := false
var table_has_scroll := false

var row_item_by_id: Dictionary = {}
var row_crossed: Dictionary = {}
var cross_out_count := 0
var uncross_count := 0
var unique_rows_crossed: Dictionary = {}
var clear_used := false
var clear_count := 0

var rel_left_col_ids: Array[String] = []
var rel_right_col_ids: Array[String] = []
var rel_drag_active := false
var rel_drag_start_global := Vector2.ZERO
var rel_drag_started_ts := 0
var rel_cable_committed := false
var rel_connected_pk := ""
var rel_connected_fk := ""
var rel_committed: Array = []
var connect_attempts := 0
var miss_connects := 0
var drag_time_ms := 0
var relation_choice_id := ""
var rel_invalid_pair_count := 0
var rel_duplicate_pair_count := 0
var rel_last_invalid_fk_col_id := ""
var _transition_token := 0
var _body_scroll_installed: bool = false

var current_layout_mode := LAYOUT_DESKTOP
var exit_btn: Button

@onready var root_layout: VBoxContainer = $SafeArea/RootLayout
@onready var filter_mode_root: HSplitContainer = $SafeArea/RootLayout/Body/FilterModeRoot
@onready var relation_mode_root: VBoxContainer = $SafeArea/RootLayout/Body/RelationModeRoot
@onready var body_container: VBoxContainer = $SafeArea/RootLayout/Body

@onready var data_tree: Tree = $SafeArea/RootLayout/Body/FilterModeRoot/TableSection/DataTree
@onready var filter_table_title: Label = $SafeArea/RootLayout/Body/FilterModeRoot/TableSection/TableTitle
@onready var prompt_label: RichTextLabel = $SafeArea/RootLayout/Body/FilterModeRoot/TaskSection/PromptLabel
@onready var btn_submit: Button = $SafeArea/RootLayout/Body/FilterModeRoot/TaskSection/ControlRow/BtnSubmit
@onready var btn_clear: Button = $SafeArea/RootLayout/Body/FilterModeRoot/TaskSection/ControlRow/BtnClear
@onready var filter_table_section: VBoxContainer = $SafeArea/RootLayout/Body/FilterModeRoot/TableSection
@onready var filter_task_section: VBoxContainer = $SafeArea/RootLayout/Body/FilterModeRoot/TaskSection
var filter_mobile_layout: VBoxContainer

@onready var rel_prompt: RichTextLabel = $SafeArea/RootLayout/Body/RelationModeRoot/PromptLabelRel
@onready var relation_schema_container: HBoxContainer = $SafeArea/RootLayout/Body/RelationModeRoot/SchemaContainer
@onready var rel_tree_l: Tree = $SafeArea/RootLayout/Body/RelationModeRoot/SchemaContainer/LeftTable/TreeL
@onready var rel_tree_r: Tree = $SafeArea/RootLayout/Body/RelationModeRoot/SchemaContainer/RightTable/TreeR
@onready var rel_title_l: Label = $SafeArea/RootLayout/Body/RelationModeRoot/SchemaContainer/LeftTable/Title
@onready var rel_title_r: Label = $SafeArea/RootLayout/Body/RelationModeRoot/SchemaContainer/RightTable/Title
@onready var rel_link_label: Label = $SafeArea/RootLayout/Body/RelationModeRoot/SchemaContainer/CenterConnector/HintLabel
@onready var rel_arrow_label: Label = $SafeArea/RootLayout/Body/RelationModeRoot/SchemaContainer/CenterConnector/ArrowLabel
@onready var rel_left_table: VBoxContainer = $SafeArea/RootLayout/Body/RelationModeRoot/SchemaContainer/LeftTable
@onready var rel_center_connector: VBoxContainer = $SafeArea/RootLayout/Body/RelationModeRoot/SchemaContainer/CenterConnector
@onready var rel_right_table: VBoxContainer = $SafeArea/RootLayout/Body/RelationModeRoot/SchemaContainer/RightTable
@onready var rel_options_row: HBoxContainer = $SafeArea/RootLayout/Body/RelationModeRoot/OptionsRow
@onready var connector_overlay: Control = $SafeArea/RootLayout/Body/RelationModeRoot/ConnectorOverlay
var relation_mobile_schema: VBoxContainer

@onready var stability_bar: ProgressBar = get_node_or_null("SafeArea/RootLayout/Footer/StabilityBar")
@onready var stability_label: Label = get_node_or_null("SafeArea/RootLayout/Footer/StabilityLabel")
@onready var title_label: RichTextLabel = $SafeArea/RootLayout/Header/Margin/Title
@onready var btn_back: Button = $SafeArea/RootLayout/BackRow/BtnBack
@onready var sfx_click: AudioStreamPlayer = $Runtime/Audio/SfxClick
@onready var sfx_error: AudioStreamPlayer = $Runtime/Audio/SfxError
@onready var sfx_relay: AudioStreamPlayer = $Runtime/Audio/SfxRelay

func _exit_tree() -> void:
	_bump_transition_token()
	if I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.disconnect(_on_language_changed)
	var root := get_tree().root
	if root != null and root.size_changed.is_connected(_on_viewport_size_changed):
		root.size_changed.disconnect(_on_viewport_size_changed)
	if btn_submit.pressed.is_connected(_on_submit_pressed):
		btn_submit.pressed.disconnect(_on_submit_pressed)
	if btn_clear.pressed.is_connected(_on_clear_pressed):
		btn_clear.pressed.disconnect(_on_clear_pressed)
	if btn_back.pressed.is_connected(_on_back_pressed):
		btn_back.pressed.disconnect(_on_back_pressed)
	if data_tree.gui_input.is_connected(_on_filter_tree_gui_input):
		data_tree.gui_input.disconnect(_on_filter_tree_gui_input)
	if rel_tree_l.gui_input.is_connected(_on_relation_tree_l_gui_input):
		rel_tree_l.gui_input.disconnect(_on_relation_tree_l_gui_input)
	if rel_tree_r.gui_input.is_connected(_on_relation_tree_r_gui_input):
		rel_tree_r.gui_input.disconnect(_on_relation_tree_r_gui_input)

func _tr(key: String, default_text: String, params: Dictionary = {}) -> String:
	var merged: Dictionary = params.duplicate(true)
	merged["default"] = default_text
	return I18n.tr_key(key, merged)

func _on_language_changed(_code: String) -> void:
	_apply_i18n()

func _apply_i18n() -> void:
	btn_back.text = _tr("da7.common.back", "BACK")
	btn_clear.text = _tr("da7.b.ui.clear", "CLEAR")
	if is_instance_valid(filter_table_title):
		filter_table_title.text = _tr("da7.b.ui.filter_mode_title", "FILTER MODE // MULTI-SELECT")
	_update_stability_ui()
	if not current_case.is_empty():
		_refresh_case_ui_i18n()

func _refresh_case_ui_i18n() -> void:
	title_label.text = _tr("da7.b.ui.title_running", "DATA ARCHIVE // CASE {current}/{total} [B]",
		{"current": current_case_index + 1, "total": session_cases.size()})
	var prompt_text: String = _case_prompt_text()
	if is_instance_valid(prompt_label):
		prompt_label.text = prompt_text
	if is_instance_valid(rel_prompt):
		rel_prompt.text = prompt_text

func _case_prompt_text() -> String:
	var case_id: String = str(current_case.get("id", ""))
	var raw: String = str(current_case.get("prompt", ""))
	return _tr("da7.b.case.%s.prompt" % case_id, raw)

func _set_relation_hint_i18n(key: String, default_text: String, params: Dictionary = {}) -> void:
	if is_instance_valid(rel_link_label):
		rel_link_label.text = _tr(key, default_text, params)

func _ready() -> void:
	randomize()
	_install_body_scroll()
	_build_mobile_containers()
	if not btn_submit.pressed.is_connected(_on_submit_pressed):
		btn_submit.pressed.connect(_on_submit_pressed)
	if not btn_clear.pressed.is_connected(_on_clear_pressed):
		btn_clear.pressed.connect(_on_clear_pressed)
	if not btn_back.pressed.is_connected(_on_back_pressed):
		btn_back.pressed.connect(_on_back_pressed)
	if not I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.connect(_on_language_changed)

	if not data_tree.gui_input.is_connected(_on_filter_tree_gui_input):
		data_tree.gui_input.connect(_on_filter_tree_gui_input)
	if not rel_tree_l.gui_input.is_connected(_on_relation_tree_l_gui_input):
		rel_tree_l.gui_input.connect(_on_relation_tree_l_gui_input)
	if not rel_tree_r.gui_input.is_connected(_on_relation_tree_r_gui_input):
		rel_tree_r.gui_input.connect(_on_relation_tree_r_gui_input)

	var root := get_tree().root
	if root != null and not root.size_changed.is_connected(_on_viewport_size_changed):
		root.size_changed.connect(_on_viewport_size_changed)
	_init_session()
	_apply_i18n()
	call_deferred("_on_viewport_size_changed")
	_load_next_case()

func _input(event: InputEvent) -> void:
	if mode != MODE_RELATION or not is_trial_active or not rel_drag_active:
		return
	if event is InputEventMouseMotion:
		_update_relation_drag(get_global_mouse_position())
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event
		_update_relation_drag(drag.position)
	elif event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed:
			_finish_relation_drag(get_global_mouse_position())
	elif event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if not touch.pressed:
			_finish_relation_drag(touch.position)

func _init_session() -> void:
	var all_cases: Array = CasesHub.get_cases("B")
	var valid_cases: Array = []
	for c_v in all_cases:
		if typeof(c_v) != TYPE_DICTIONARY:
			continue
		var c: Dictionary = c_v as Dictionary
		if CasesModuleB.validate_case_b(c):
			valid_cases.append(c)
	if valid_cases.is_empty():
		_show_fatal("No valid DA7 B cases found in scripts/case_07/da7_cases_b.gd")
		return

	valid_cases.shuffle()
	session_cases = valid_cases.slice(0, mini(SESSION_CASE_COUNT, valid_cases.size()))
	current_case_index = -1
	GlobalMetrics.stability = 100.0
	_update_stability_ui()

func _load_next_case() -> void:
	_bump_transition_token()
	current_case_index += 1
	if current_case_index >= session_cases.size():
		_finish_session()
		return

	current_case = (session_cases[current_case_index] as Dictionary).duplicate(true)
	is_trial_active = true
	ui_ready_ts = Time.get_ticks_msec()
	first_action_ts = -1
	scroll_used = false
	table_has_scroll = false
	mode_id = ""
	selection_toggle_count = 0
	selected_count_peak = 0
	submit_attempt_count = 0
	relation_drag_start_count = 0
	relation_drag_complete_count = 0
	relation_drag_fail_count = 0
	relation_wrong_origin_count = 0
	relation_duplicate_link_count = 0
	inspected_before_submit = false
	changed_after_inspect = false
	changed_after_error = false
	time_to_first_toggle_ms = -1
	time_to_first_drag_ms = -1
	time_to_submit_ms = -1
	details_open_count = 0
	hint_open_count = 0
	row_item_by_id.clear()
	row_crossed.clear()
	cross_out_count = 0
	uncross_count = 0
	unique_rows_crossed.clear()
	clear_used = false
	clear_count = 0
	rel_left_col_ids.clear()
	rel_right_col_ids.clear()
	rel_drag_active = false
	rel_drag_start_global = Vector2.ZERO
	rel_drag_started_ts = 0
	rel_cable_committed = false
	rel_connected_pk = ""
	rel_connected_fk = ""
	rel_committed.clear()
	connect_attempts = 0
	miss_connects = 0
	drag_time_ms = 0
	relation_choice_id = ""
	rel_invalid_pair_count = 0
	rel_duplicate_pair_count = 0
	rel_last_invalid_fk_col_id = ""

	if str(current_case.get("case_kind", "")) == "FILTER_ROWS":
		mode = MODE_FILTER
		mode_id = MODE_FILTER
		_render_filter_ui()
	else:
		mode = MODE_RELATION
		mode_id = MODE_RELATION
		_render_relation_ui()
	_begin_trial_session()

	_on_viewport_size_changed()
	_update_stability_ui()

func _begin_trial_session() -> void:
	trial_seq += 1
	var case_id := str(current_case.get("id", "DA7-B-00"))
	task_session = {
		"trial_seq": trial_seq,
		"quest_id": "DATA_ARCHIVE",
		"stage_id": "B",
		"task_id": case_id,
		"mode_id": mode_id,
		"started_at_ticks": ui_ready_ts,
		"ended_at_ticks": 0,
		"events": []
	}
	_log_event("trial_started", {
		"trial_seq": trial_seq,
		"case_id": case_id,
		"mode_id": mode_id,
		"prompt": str(current_case.get("prompt", ""))
	})

func _render_filter_ui() -> void:
	filter_mode_root.visible = true
	relation_mode_root.visible = false
	title_label.text = _tr("da7.b.ui.title_running", "DATA ARCHIVE // CASE {current}/{total} [B]",
		{"current": current_case_index + 1, "total": session_cases.size()})
	btn_submit.disabled = false
	btn_submit.text = _tr("da7.b.ui.submit", "SUBMIT")
	btn_clear.disabled = false

	data_tree.clear()
	row_item_by_id.clear()
	row_crossed.clear()

	var table_data: Dictionary = current_case.get("table", {}) as Dictionary
	var cols: Array = table_data.get("columns", []) as Array
	var rows: Array = (table_data.get("rows", []) as Array).duplicate(true)
	var anti_cheat: Dictionary = current_case.get("anti_cheat", {}) as Dictionary
	if bool(anti_cheat.get("shuffle_rows", false)):
		rows.shuffle()

	var root: TreeItem = data_tree.create_item()
	data_tree.hide_root = true
	data_tree.select_mode = Tree.SELECT_ROW
	data_tree.columns = cols.size()
	for i in range(cols.size()):
		if typeof(cols[i]) != TYPE_DICTIONARY:
			continue
		var col_def: Dictionary = cols[i] as Dictionary
		data_tree.set_column_title(i, str(col_def.get("title", "COL")))
	data_tree.column_titles_visible = true

	for row_v in rows:
		if typeof(row_v) != TYPE_DICTIONARY:
			continue
		var row_dict: Dictionary = row_v as Dictionary
		var row_id := str(row_dict.get("row_id", ""))
		if row_id.is_empty():
			continue
		var item: TreeItem = data_tree.create_item(root)
		item.set_metadata(0, row_id)
		item.set_metadata(1, false)
		row_item_by_id[row_id] = item
		row_crossed[row_id] = false
		var cells: Dictionary = row_dict.get("cells", {}) as Dictionary
		for i in range(cols.size()):
			if typeof(cols[i]) != TYPE_DICTIONARY:
				continue
			var col_def: Dictionary = cols[i] as Dictionary
			var col_id := str(col_def.get("col_id", ""))
			item.set_text(i, str(cells.get(col_id, "")))
		_apply_redaction_style(item, false)

	prompt_label.text = _case_prompt_text()
	call_deferred("_update_table_scroll_flag")

func _render_relation_ui() -> void:
	filter_mode_root.visible = false
	relation_mode_root.visible = true
	title_label.text = _tr("da7.b.ui.title_running", "DATA ARCHIVE // CASE {current}/{total} [B]",
		{"current": current_case_index + 1, "total": session_cases.size()})

	for child in rel_options_row.get_children():
		child.queue_free()

	var left_table: Dictionary = current_case.get("left_table", {}) as Dictionary
	var right_table: Dictionary = current_case.get("right_table", {}) as Dictionary
	rel_left_col_ids = _fill_relation_tree(rel_tree_l, left_table)
	rel_right_col_ids = _fill_relation_tree(rel_tree_r, right_table)
	rel_title_l.text = str(left_table.get("title", "Left"))
	rel_title_r.text = str(right_table.get("title", "Right"))
	rel_prompt.text = _case_prompt_text()
	rel_arrow_label.text = ""
	_set_relation_hint_i18n("da7.b.ui.rel.drag_hint", "Drag cable from PK to FK")
	rel_committed.clear()
	rel_cable_committed = false
	rel_connected_pk = ""
	rel_connected_fk = ""
	rel_invalid_pair_count = 0
	rel_duplicate_pair_count = 0
	rel_last_invalid_fk_col_id = ""

	if is_instance_valid(connector_overlay):
		if connector_overlay.has_method("clear_all"):
			connector_overlay.call("clear_all")
		elif connector_overlay.has_method("clear_connection"):
			connector_overlay.call("clear_connection")
		if connector_overlay.has_method("set_anchor_mode"):
			connector_overlay.call("set_anchor_mode", "edge", "auto")

	var options: Array = current_case.get("options", []) as Array
	for opt_v in options:
		if typeof(opt_v) != TYPE_DICTIONARY:
			continue
		var opt: Dictionary = opt_v as Dictionary
		var btn := Button.new()
		btn.text = str(opt.get("text", "Option"))
		btn.custom_minimum_size = Vector2(0, 56)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.disabled = true
		btn.pressed.connect(_on_relation_option_selected.bind(opt))
		rel_options_row.add_child(btn)
	_apply_compact_layout(_is_compact_phone(), current_layout_mode == LAYOUT_MOBILE)

	if options.is_empty():
		_set_relation_hint_i18n("da7.b.ui.rel.connect_hint", "Connect cable to submit")

func _fill_relation_tree(tree: Tree, table_def: Dictionary) -> Array[String]:
	tree.clear()
	var root: TreeItem = tree.create_item()
	tree.hide_root = true

	var col_ids: Array[String] = []
	var cols: Array = table_def.get("columns", []) as Array
	tree.columns = cols.size()
	for i in range(cols.size()):
		if typeof(cols[i]) != TYPE_DICTIONARY:
			continue
		var col_def: Dictionary = cols[i] as Dictionary
		col_ids.append(str(col_def.get("col_id", "")))
		tree.set_column_title(i, str(col_def.get("title", "COL")))
	tree.column_titles_visible = true

	var rows_preview: Array = table_def.get("rows_preview", []) as Array
	for i in range(mini(rows_preview.size(), 6)):
		if typeof(rows_preview[i]) != TYPE_DICTIONARY:
			continue
		var row_data: Dictionary = rows_preview[i] as Dictionary
		var item: TreeItem = tree.create_item(root)
		item.set_metadata(0, str(row_data.get("row_id", "")))
		var cells: Dictionary = row_data.get("cells", {}) as Dictionary
		for j in range(cols.size()):
			if typeof(cols[j]) != TYPE_DICTIONARY:
				continue
			var col_def: Dictionary = cols[j] as Dictionary
			item.set_text(j, str(cells.get(str(col_def.get("col_id", "")), "")))
	return col_ids

func _on_filter_tree_gui_input(event: InputEvent) -> void:
	if mode != MODE_FILTER or not is_trial_active:
		return
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP or mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scroll_used = true
			return
		if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
			return
		var item: TreeItem = data_tree.get_item_at_position(mouse_event.position)
		if item == null:
			return
		_register_first_action()
		_toggle_redaction(item)
		_play_sound("click", sfx_click)
	elif event is InputEventScreenDrag:
		scroll_used = true

func _toggle_redaction(item: TreeItem) -> void:
	var row_id := str(item.get_metadata(0))
	if row_id.is_empty():
		return
	if time_to_first_toggle_ms < 0:
		time_to_first_toggle_ms = Time.get_ticks_msec() - ui_ready_ts
	var crossed := not bool(item.get_metadata(1))
	item.set_metadata(1, crossed)
	row_crossed[row_id] = crossed
	if crossed:
		cross_out_count += 1
		unique_rows_crossed[row_id] = true
	else:
		uncross_count += 1
	selection_toggle_count += 1
	var selected_count := _selected_crossed_count()
	selected_count_peak = maxi(selected_count_peak, selected_count)
	_apply_redaction_style(item, crossed)
	_refresh_submit_enabled()
	_log_event("selection_changed", {
		"mode_id": MODE_FILTER,
		"row_id": row_id,
		"is_selected": crossed,
		"selected_count": selected_count
	})
	_log_event("filter_toggle", {
		"row_id": row_id,
		"is_selected": crossed,
		"selected_count": selected_count
	})

func _apply_redaction_style(item: TreeItem, crossed: bool) -> void:
	for col_idx in range(data_tree.columns):
		if crossed:
			item.set_custom_bg_color(col_idx, Color(0.17, 0.17, 0.17, 0.9))
			item.set_custom_color(col_idx, Color(0.55, 0.55, 0.55, 1.0))
		else:
			item.set_custom_bg_color(col_idx, Color(0, 0, 0, 0))
			item.set_custom_color(col_idx, Color(1, 1, 1, 1))

func _on_clear_pressed() -> void:
	if mode != MODE_FILTER or not is_trial_active:
		return
	_register_first_action()
	clear_used = true
	clear_count += 1
	for row_id_v in row_item_by_id.keys():
		var row_id := str(row_id_v)
		var item: TreeItem = row_item_by_id[row_id] as TreeItem
		item.set_metadata(1, false)
		row_crossed[row_id] = false
		_apply_redaction_style(item, false)
	_refresh_submit_enabled()
	_log_event("clear_pressed", {
		"mode_id": MODE_FILTER,
		"clear_count": clear_count
	})

func _on_submit_pressed() -> void:
	if mode != MODE_FILTER or not is_trial_active:
		return
	_register_first_action()
	submit_attempt_count += 1
	if time_to_submit_ms < 0:
		time_to_submit_ms = Time.get_ticks_msec() - ui_ready_ts
	_log_event("submit_pressed", {
		"mode_id": MODE_FILTER,
		"attempt": submit_attempt_count,
		"selected_count": _selected_crossed_count()
	})
	is_trial_active = false

	var crossed_ids: Array = []
	var all_row_ids: Array = []
	for row_id_v in row_item_by_id.keys():
		var row_id := str(row_id_v)
		all_row_ids.append(row_id)
		if bool(row_crossed.get(row_id, false)):
			crossed_ids.append(row_id)
	var kept_ids := _array_diff(all_row_ids, crossed_ids)
	var analysis := _calculate_f_reason_filter(kept_ids)
	analysis["crossed_ids"] = crossed_ids
	analysis["kept_ids"] = kept_ids
	var reason := str(analysis.get("reason", "MIXED_ERROR"))
	var is_correct := reason == "NONE"
	var reason_value: Variant = null
	if not is_correct:
		reason_value = reason
	_handle_result(is_correct, reason_value, analysis)

func _calculate_f_reason_filter(kept_set: Array) -> Dictionary:
	var s: Array = kept_set.duplicate()
	var a: Array = current_case.get("answer_row_ids", []) as Array
	var b: Array = current_case.get("boundary_row_ids", []) as Array
	var o: Array = current_case.get("opposite_row_ids", []) as Array
	var u: Array = current_case.get("unrelated_row_ids", []) as Array
	var d: Array = current_case.get("decoy_row_ids", []) as Array
	var predicate: Dictionary = current_case.get("predicate", {}) as Dictionary
	var strict_expected := bool(predicate.get("strict_expected", false))

	var missing_ids := _array_diff(a, s)
	var extra_ids := _array_diff(s, a)
	var boundary_selected := _array_intersection(s, b)
	var opposite_selected := _array_intersection(s, o)
	var decoy_selected := _array_intersection(s, d)
	var unrelated_selected := _array_intersection(s, u)
	var extra_outside_main := _array_diff(_array_diff(_array_diff(_array_diff(s, a), b), o), d)

	var reason := "MIXED_ERROR"
	if s.is_empty():
		reason = "EMPTY_SELECTION"
	elif _is_subset(s, o):
		reason = "PURE_OPPOSITE"
	elif strict_expected and boundary_selected.size() > 0:
		reason = "INCLUDED_BOUNDARY"
	elif decoy_selected.size() > 0:
		reason = "OVERSELECT_DECOY"
	elif unrelated_selected.size() > 0 or extra_outside_main.size() > 0:
		reason = "FALSE_POSITIVE"
	elif missing_ids.size() > 0:
		reason = "OMISSION"
	elif _sets_equal(s, a):
		reason = "NONE"

	return {
		"reason": reason,
		"sets": {
			"missing_ids": missing_ids,
			"extra_ids": extra_ids,
			"boundary_selected": boundary_selected,
			"opposite_selected": opposite_selected,
			"decoy_selected": decoy_selected,
			"unrelated_selected": unrelated_selected,
			"extra_outside_main": extra_outside_main
		}
	}

func _on_relation_tree_l_gui_input(event: InputEvent) -> void:
	if mode != MODE_RELATION or not is_trial_active:
		return
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
			return
		_try_start_relation_drag(rel_tree_l, mouse_event.position)
	elif event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed:
			_try_start_relation_drag(rel_tree_l, touch.position)

func _on_relation_tree_r_gui_input(event: InputEvent) -> void:
	if mode != MODE_RELATION or not is_trial_active:
		return
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP or mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scroll_used = true
	elif event is InputEventScreenDrag:
		scroll_used = true

func _try_start_relation_drag(tree: Tree, local_pos: Vector2) -> void:
	_register_first_action()
	relation_drag_start_count += 1
	connect_attempts += 1
	var hit := _resolve_tree_hit(tree, local_pos, rel_left_col_ids)
	if hit.is_empty():
		miss_connects += 1
		relation_drag_fail_count += 1
		_log_event("relation_drag_failed", {"reason": "no_pk_hit"})
		return
	var hit_col := str(hit.get("col_id", ""))
	var allowed_pk: Dictionary = {}
	for pair_v in _get_required_connections():
		if typeof(pair_v) != TYPE_DICTIONARY:
			continue
		var pair: Dictionary = pair_v as Dictionary
		var pk_col := str(pair.get("pk_col_id", ""))
		if not pk_col.is_empty():
			allowed_pk[pk_col] = true
	if not allowed_pk.has(hit_col):
		miss_connects += 1
		relation_wrong_origin_count += 1
		relation_drag_fail_count += 1
		_set_relation_hint_i18n("da7.b.ui.rel.start_from_pk", "Start cable from PK column")
		hint_open_count += 1
		_log_event("hint_opened", {
			"context": "relation",
			"reason": "start_from_pk"
		})
		_log_event("relation_wrong_origin", {"col_id": hit_col})
		return

	rel_drag_active = true
	if time_to_first_drag_ms < 0:
		time_to_first_drag_ms = Time.get_ticks_msec() - ui_ready_ts
	rel_drag_started_ts = Time.get_ticks_msec()
	rel_drag_start_global = hit.get("center_global", Vector2.ZERO)
	rel_connected_pk = hit_col
	rel_connected_fk = ""
	_log_event("selection_changed", {
		"mode_id": MODE_RELATION,
		"pk_col_id": rel_connected_pk
	})
	_log_event("relation_drag_started", {"pk_col_id": rel_connected_pk})
	if is_instance_valid(connector_overlay) and connector_overlay.has_method("start_drag"):
		connector_overlay.call("start_drag", _global_to_overlay(rel_drag_start_global))
	_play_sound("click", sfx_click)

func _update_relation_drag(global_pos: Vector2) -> void:
	if not rel_drag_active:
		return
	if is_instance_valid(connector_overlay) and connector_overlay.has_method("update_drag"):
		connector_overlay.call("update_drag", _global_to_overlay(global_pos))

func _finish_relation_drag(global_pos: Vector2) -> void:
	if not rel_drag_active:
		return
	rel_drag_active = false
	drag_time_ms += maxi(0, Time.get_ticks_msec() - rel_drag_started_ts)
	var hit := _resolve_tree_hit_global(rel_tree_r, global_pos, rel_right_col_ids)
	var fk_col := str(hit.get("col_id", ""))
	if not hit.is_empty() and _is_valid_relation_pair(rel_connected_pk, fk_col):
		if _is_pair_already_committed(rel_connected_pk, fk_col):
			rel_duplicate_pair_count += 1
			relation_duplicate_link_count += 1
			_clear_relation_drag_overlay()
			_set_relation_hint_i18n("da7.b.ui.rel.pair_already_linked", "Pair already linked")
			_set_relation_options_enabled(_is_relation_ready_to_submit())
			hint_open_count += 1
			_log_event("hint_opened", {
				"context": "relation",
				"reason": "pair_already_linked"
			})
			_log_event("relation_duplicate", {
				"pk_col_id": rel_connected_pk,
				"fk_col_id": fk_col
			})
			return

		rel_cable_committed = true
		relation_drag_complete_count += 1
		rel_connected_fk = fk_col
		var to_overlay := _global_to_overlay(hit.get("center_global", global_pos))
		if is_instance_valid(connector_overlay):
			if connector_overlay.has_method("commit_cable"):
				connector_overlay.call("commit_cable", _global_to_overlay(rel_drag_start_global), to_overlay)
			elif connector_overlay.has_method("commit_connection"):
				connector_overlay.call("commit_connection", _global_to_overlay(rel_drag_start_global), to_overlay)
		rel_committed.append({
			"pk_col_id": rel_connected_pk,
			"fk_col_id": rel_connected_fk,
			"from_global": rel_drag_start_global,
			"to_global": hit.get("center_global", global_pos)
		})

		var needed := _get_required_connections().size()
		var linked := rel_committed.size()
		if relation_drag_fail_count > 0 or relation_wrong_origin_count > 0:
			changed_after_error = true
		_set_relation_hint_i18n("da7.b.ui.rel.pair_linked", "Cable linked ({done}/{total})", {"done": linked, "total": maxi(1, needed)})
		var ready := _is_relation_ready_to_submit()
		_log_event("relation_linked", {
			"pk_col_id": rel_connected_pk,
			"fk_col_id": rel_connected_fk,
			"done": linked,
			"total": maxi(1, needed)
		})
		_set_relation_options_enabled(ready)
		if (current_case.get("options", []) as Array).is_empty() and ready:
			submit_attempt_count += 1
			if time_to_submit_ms < 0:
				time_to_submit_ms = Time.get_ticks_msec() - ui_ready_ts
			_log_event("submit_pressed", {
				"mode_id": MODE_RELATION,
				"attempt": submit_attempt_count,
				"source": "auto_ready"
			})
			_handle_result(true, null, {
				"connected_pk": rel_connected_pk,
				"connected_fk": rel_connected_fk,
				"relation_choice": "",
				"committed_connections": rel_committed.duplicate(true)
			})
	else:
		miss_connects += 1
		rel_invalid_pair_count += 1
		relation_drag_fail_count += 1
		rel_last_invalid_fk_col_id = fk_col
		_clear_relation_drag_overlay()
		_set_relation_hint_i18n("da7.b.ui.rel.missed_fk", "Missed FK target")
		_set_relation_options_enabled(_is_relation_ready_to_submit())
		hint_open_count += 1
		_log_event("hint_opened", {
			"context": "relation",
			"reason": "missed_fk"
		})
		_log_event("relation_drag_failed", {
			"reason": "missed_fk",
			"pk_col_id": rel_connected_pk,
			"fk_col_id": fk_col
		})

func _on_relation_option_selected(opt: Dictionary) -> void:
	if mode != MODE_RELATION or not is_trial_active:
		return
	_register_first_action()
	submit_attempt_count += 1
	if time_to_submit_ms < 0:
		time_to_submit_ms = Time.get_ticks_msec() - ui_ready_ts
	is_trial_active = false
	var selected_id := str(opt.get("id", ""))
	relation_choice_id = selected_id
	_log_event("submit_pressed", {
		"mode_id": MODE_RELATION,
		"attempt": submit_attempt_count,
		"selected_option_id": selected_id
	})
	var relation_ready := _is_relation_ready_to_submit()
	var is_correct := relation_ready and selected_id == str(current_case.get("answer_id", ""))
	var reason: Variant = null
	if not relation_ready:
		reason = "FK_DIRECTION_SWAP"
	elif not is_correct:
		reason = opt.get("f_reason", "WRONG_RELATION")
	_handle_result(is_correct, reason, {
		"selected_option_id": selected_id,
		"connected_pk": rel_connected_pk,
		"connected_fk": rel_connected_fk,
		"relation_choice": selected_id,
		"committed_connections": rel_committed.duplicate(true)
	})

func _set_relation_options_enabled(enabled: bool) -> void:
	for child in rel_options_row.get_children():
		if child is Button:
			(child as Button).disabled = not enabled

func _get_required_connections() -> Array:
	var pairs: Array = []
	var required: Array = current_case.get("required_connections", []) as Array
	for pair_v in required:
		if typeof(pair_v) != TYPE_DICTIONARY:
			continue
		var pair: Dictionary = pair_v as Dictionary
		var pk_col := str(pair.get("pk_col_id", ""))
		var fk_col := str(pair.get("fk_col_id", ""))
		if pk_col.is_empty() or fk_col.is_empty():
			continue
		pairs.append({"pk_col_id": pk_col, "fk_col_id": fk_col})
	if not pairs.is_empty():
		return pairs

	var fallback_pk: Dictionary = current_case.get("pk_target", {}) as Dictionary
	var fallback_fk: Dictionary = current_case.get("fk_target", {}) as Dictionary
	var fallback_pk_id := str(fallback_pk.get("col_id", ""))
	var fallback_fk_id := str(fallback_fk.get("col_id", ""))
	if not fallback_pk_id.is_empty() and not fallback_fk_id.is_empty():
		pairs.append({"pk_col_id": fallback_pk_id, "fk_col_id": fallback_fk_id})
	return pairs

func _is_valid_relation_pair(pk_col_id: String, fk_col_id: String) -> bool:
	for pair_v in _get_required_connections():
		if typeof(pair_v) != TYPE_DICTIONARY:
			continue
		var pair: Dictionary = pair_v as Dictionary
		if str(pair.get("pk_col_id", "")) == pk_col_id and str(pair.get("fk_col_id", "")) == fk_col_id:
			return true
	return false

func _is_pair_already_committed(pk_col_id: String, fk_col_id: String) -> bool:
	for row_v in rel_committed:
		if typeof(row_v) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = row_v as Dictionary
		if str(row.get("pk_col_id", "")) == pk_col_id and str(row.get("fk_col_id", "")) == fk_col_id:
			return true
	return false

func _is_relation_ready_to_submit() -> bool:
	var required := _get_required_connections()
	if required.is_empty():
		return rel_cable_committed or not rel_committed.is_empty()
	for pair_v in required:
		if typeof(pair_v) != TYPE_DICTIONARY:
			continue
		var pair: Dictionary = pair_v as Dictionary
		if not _is_pair_already_committed(str(pair.get("pk_col_id", "")), str(pair.get("fk_col_id", ""))):
			return false
	return true

func _handle_result(is_correct: bool, reason: Variant, extra_data: Dictionary) -> void:
	is_trial_active = false
	btn_submit.disabled = true
	btn_clear.disabled = true
	rel_drag_active = false
	_set_relation_options_enabled(false)
	if not is_correct:
		_play_sound("error", sfx_error)
	else:
		_play_sound("relay", sfx_relay)
	var error_type: String = "NONE" if is_correct else str(reason)
	_log_event("submit_result", {
		"is_correct": is_correct,
		"error_type": error_type,
		"mode_id": mode_id
	})
	task_session["ended_at_ticks"] = Time.get_ticks_msec()
	_log_event("trial_finished", {
		"is_correct": is_correct,
		"error_type": error_type
	})
	_log_trial(is_correct, reason, extra_data)
	_update_stability_ui()
	var transition_token := _transition_token
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree():
		return
	if transition_token != _transition_token:
		return
	if current_case_index >= session_cases.size():
		return
	if GlobalMetrics.stability <= 0.0:
		_game_over()
	else:
		_load_next_case()

func _log_trial(is_correct: bool, f_reason: Variant, extra_data: Dictionary) -> void:
	var now_ms := Time.get_ticks_msec()
	var elapsed_ms := now_ms - ui_ready_ts
	var first_action_ms := elapsed_ms
	if first_action_ts >= ui_ready_ts:
		first_action_ms = first_action_ts - ui_ready_ts
	var case_id := str(current_case.get("id", "DA7-B-00"))
	var timing_policy: Dictionary = current_case.get("timing_policy", {}) as Dictionary
	var interaction_type := str(current_case.get("interaction_type", ""))
	var interaction_variant := str(current_case.get("interaction_variant", ""))
	var schema_version := str(current_case.get("schema_version", "DA7.B.v2"))
	var variant_hash := str(hash("%s|%s|%s|%s|%s" % [case_id, mode_id, interaction_type, interaction_variant, schema_version]))
	var payload: Dictionary = TrialV2.build("DATA_ARCHIVE", "B", case_id, interaction_type, variant_hash)
	var error_type: String = "NONE" if is_correct else str(f_reason)
	var outcome_code: String = _outcome_code_for_b(is_correct, f_reason)
	var mastery_block_reason: String = _mastery_block_reason_for_b(is_correct, outcome_code)
	var valid_for_mastery: bool = mastery_block_reason == "NONE"
	var effective_submit_ms := time_to_submit_ms
	if effective_submit_ms < 0:
		effective_submit_ms = elapsed_ms

	payload.merge({
		"question_id": case_id,
		"case_id": case_id,
		"quest": "data_archive",
		"stage_id": "B",
		"level": "B",
		"topic": str(current_case.get("topic", "DB_FILTERING")),
		"case_kind": str(current_case.get("case_kind", "")),
		"mode_id": mode_id,
		"interaction_variant": interaction_variant,
		"schema_version": schema_version,
		"is_correct": is_correct,
		"is_fit": is_correct,
		"f_reason": f_reason,
		"error_type": error_type,
		"outcome_code": outcome_code,
		"mastery_block_reason": mastery_block_reason,
		"valid_for_diagnostics": true,
		"valid_for_mastery": valid_for_mastery,
		"elapsed_ms": elapsed_ms,
		"duration": float(elapsed_ms) / 1000.0,
		"time_to_first_action_ms": first_action_ms,
		"time_to_first_toggle_ms": time_to_first_toggle_ms,
		"time_to_first_drag_ms": time_to_first_drag_ms,
		"time_to_submit_ms": effective_submit_ms,
		"check_attempt_count": submit_attempt_count,
		"hint_used": hint_open_count > 0,
		"details_used": details_open_count > 0,
		"inspect_used": inspected_before_submit,
		"selection_toggle_count": selection_toggle_count,
		"selected_count_peak": selected_count_peak,
		"clear_count": clear_count,
		"submit_attempt_count": submit_attempt_count,
		"relation_drag_start_count": relation_drag_start_count,
		"relation_drag_complete_count": relation_drag_complete_count,
		"relation_drag_fail_count": relation_drag_fail_count,
		"relation_wrong_origin_count": relation_wrong_origin_count,
		"relation_duplicate_link_count": relation_duplicate_link_count,
		"inspected_before_submit": inspected_before_submit,
		"changed_after_inspect": changed_after_inspect,
		"changed_after_error": changed_after_error,
		"timing": {
			"effective_elapsed_ms": elapsed_ms,
			"time_to_first_action_ms": first_action_ms,
			"time_to_first_toggle_ms": time_to_first_toggle_ms,
			"time_to_first_drag_ms": time_to_first_drag_ms,
			"time_to_submit_ms": effective_submit_ms,
			"policy_mode": str(timing_policy.get("mode", "LEARNING")),
			"limit_sec": int(timing_policy.get("limit_sec", 120))
		},
		"flags": {
			"silent_reading_possible": (first_action_ms >= 30000 and not scroll_used and not table_has_scroll),
			"scroll_used": scroll_used,
			"table_has_scroll": table_has_scroll
		},
		"answer": {},
		"telemetry": {},
		"task_session": task_session.duplicate(true)
	}, true)

	if mode == MODE_FILTER:
		var sets: Dictionary = extra_data.get("sets", {}) as Dictionary
		payload["answer"] = {
			"crossed_out_ids": extra_data.get("crossed_ids", []),
			"kept_ids": extra_data.get("kept_ids", [])
		}
		payload["expected"] = {
			"answer_row_ids": current_case.get("answer_row_ids", []),
			"boundary_row_ids": current_case.get("boundary_row_ids", []),
			"opposite_row_ids": current_case.get("opposite_row_ids", []),
			"unrelated_row_ids": current_case.get("unrelated_row_ids", []),
			"decoy_row_ids": current_case.get("decoy_row_ids", [])
		}
		payload["diagnostic_sets"] = sets
		payload["telemetry"] = {
			"cross_out_count": cross_out_count,
			"uncross_count": uncross_count,
			"unique_rows_crossed": unique_rows_crossed.size(),
			"selection_toggle_count": selection_toggle_count,
			"selected_count_peak": selected_count_peak,
			"clear_used": clear_used,
			"clear_count": clear_count,
			"time_to_first_toggle_ms": time_to_first_toggle_ms
		}
	else:
		payload["answer"] = {
			"connected_pk": str(extra_data.get("connected_pk", "")),
			"connected_fk": str(extra_data.get("connected_fk", "")),
			"relation_choice": str(extra_data.get("relation_choice", "")),
			"committed_connections": extra_data.get("committed_connections", rel_committed.duplicate(true))
		}
		payload["expected"] = {
			"pk_target": current_case.get("pk_target", {}),
			"fk_target": current_case.get("fk_target", {}),
			"expected_relation": str(current_case.get("expected_relation", "")),
			"answer_id": str(current_case.get("answer_id", "")),
			"required_connections": _get_required_connections(),
			"decoy_fk_col_ids": current_case.get("decoy_fk_col_ids", [])
		}
		payload["telemetry"] = {
			"connect_attempts": connect_attempts,
			"miss_connects": miss_connects,
			"drag_time_ms": drag_time_ms,
			"required_connection_count": _get_required_connections().size(),
			"invalid_pair_count": rel_invalid_pair_count,
			"duplicate_pair_count": rel_duplicate_pair_count,
			"last_invalid_fk_col_id": rel_last_invalid_fk_col_id,
			"relation_drag_start_count": relation_drag_start_count,
			"relation_drag_complete_count": relation_drag_complete_count,
			"relation_drag_fail_count": relation_drag_fail_count,
			"relation_wrong_origin_count": relation_wrong_origin_count,
			"relation_duplicate_link_count": relation_duplicate_link_count,
			"time_to_first_drag_ms": time_to_first_drag_ms
		}

	payload["stability_delta"] = -15.0 if not is_correct else 0.0
	GlobalMetrics.register_trial(payload)

func _outcome_code_for_b(is_correct: bool, f_reason: Variant) -> String:
	var reason := str(f_reason)
	if mode_id == MODE_FILTER:
		if is_correct:
			return "FILTER_SUCCESS"
		match reason:
			"OVERSELECT_DECOY", "FALSE_POSITIVE":
				return "FILTER_OVERSELECT"
			"OMISSION", "EMPTY_SELECTION":
				return "FILTER_UNDERSELECT"
			"PURE_OPPOSITE":
				return "FILTER_NEGATION_CONFUSION"
			"INCLUDED_BOUNDARY":
				return "FILTER_WRONG_BOUNDARY"
		if reason.find("OPPOSITE") >= 0 or reason.find("NEGATION") >= 0:
			return "FILTER_NEGATION_CONFUSION"
		if reason.find("OMISSION") >= 0 or reason.find("EMPTY") >= 0:
			return "FILTER_UNDERSELECT"
		if reason.find("BOUNDARY") >= 0:
			return "FILTER_WRONG_BOUNDARY"
		return "FILTER_OVERSELECT"

	if is_correct:
		return "REL_SUCCESS"
	if relation_duplicate_link_count > 0:
		return "REL_DUPLICATE_LINK"
	if relation_wrong_origin_count > 0 or reason == "FK_DIRECTION_SWAP":
		return "REL_WRONG_PK_START"
	if relation_drag_fail_count > 0 or rel_invalid_pair_count > 0:
		return "REL_MISSED_FK"
	return "REL_WRONG_MAPPING"

func _mastery_block_reason_for_b(is_correct: bool, outcome_code: String) -> String:
	if hint_open_count > 0:
		return "USED_HINT"
	if clear_count >= 2:
		return "USED_CLEAR_TOO_MUCH"
	if inspected_before_submit:
		return "USED_INSPECT_HEAVILY"
	if submit_attempt_count >= 2:
		return "MULTI_SUBMIT_GUESSING"
	if outcome_code == "FILTER_NEGATION_CONFUSION":
		return "NEGATION_CONFUSION"
	if mode_id == MODE_RELATION and (relation_drag_fail_count + relation_wrong_origin_count + relation_duplicate_link_count) >= 2:
		return "RELATION_MAPPING_UNSTABLE"
	if not is_correct:
		return "RELATION_MAPPING_UNSTABLE" if mode_id == MODE_RELATION else "NEGATION_CONFUSION"
	return "NONE"

func _log_event(event_name: String, payload: Dictionary = {}) -> void:
	if task_session.is_empty():
		return
	var events: Array = task_session.get("events", [])
	events.append({
		"name": event_name,
		"t_ms": _trial_elapsed_ms(Time.get_ticks_msec()),
		"payload": payload
	})
	task_session["events"] = events

func _trial_elapsed_ms(now_ms: int) -> int:
	if ui_ready_ts <= 0:
		return 0
	return maxi(0, now_ms - ui_ready_ts)

func _register_first_action() -> void:
	if first_action_ts < 0:
		first_action_ts = Time.get_ticks_msec()

func _selected_crossed_count() -> int:
	var count := 0
	for row_id_v in row_crossed.keys():
		if bool(row_crossed[row_id_v]):
			count += 1
	return count

func _refresh_submit_enabled() -> void:
	if mode != MODE_FILTER or not is_trial_active:
		btn_submit.disabled = true
		btn_submit.text = _tr("da7.b.ui.submit", "SUBMIT")
		return
	var crossed_count := _selected_crossed_count()
	btn_submit.disabled = false
	btn_submit.text = _tr("da7.b.ui.submit_with_count", "SUBMIT ({count})", {"count": crossed_count})

func _resolve_tree_hit(tree: Tree, local_pos: Vector2, col_ids: Array[String]) -> Dictionary:
	var item: TreeItem = tree.get_item_at_position(local_pos)
	if item == null:
		return {}
	for col_idx in range(col_ids.size()):
		var rect := tree.get_item_area_rect(item, col_idx)
		if rect.has_point(local_pos):
			return {
				"item": item,
				"row_id": str(item.get_metadata(0)),
				"col_idx": col_idx,
				"col_id": col_ids[col_idx],
				"center_global": tree.get_global_transform_with_canvas() * rect.get_center()
			}
	return {}

func _resolve_tree_hit_global(tree: Tree, global_pos: Vector2, col_ids: Array[String]) -> Dictionary:
	var local_pos := tree.get_global_transform_with_canvas().affine_inverse() * global_pos
	return _resolve_tree_hit(tree, local_pos, col_ids)

func _global_to_overlay(global_pos: Vector2) -> Vector2:
	if not is_instance_valid(connector_overlay):
		return global_pos
	return connector_overlay.get_global_transform_with_canvas().affine_inverse() * global_pos

func _update_table_scroll_flag() -> void:
	table_has_scroll = _tree_has_vertical_scroll(data_tree)

func _tree_has_vertical_scroll(tree: Tree) -> bool:
	if not is_instance_valid(tree):
		return false
	var stack: Array = [tree]
	while not stack.is_empty():
		var node: Node = stack.pop_back() as Node
		if node is VScrollBar:
			var bar: VScrollBar = node as VScrollBar
			return bar.max_value > 0.0 and bar.page < bar.max_value
		for child in node.get_children():
			stack.append(child)
	return false

func _update_stability_ui() -> void:
	if is_instance_valid(stability_bar):
		stability_bar.value = GlobalMetrics.stability
	if is_instance_valid(stability_label):
		stability_label.text = _tr("da7.common.stability", "STABILITY: {value}%", {"value": int(GlobalMetrics.stability)})

func _on_viewport_size_changed() -> void:
	var win_size := get_viewport_rect().size
	var is_mobile := win_size.x < BREAKPOINT_PX
	var compact: bool = (win_size.x >= win_size.y and win_size.y <= 420.0) or (win_size.y > win_size.x and win_size.x <= 520.0)
	current_layout_mode = LAYOUT_MOBILE if is_mobile else LAYOUT_DESKTOP
	filter_mode_root.split_offset = int(win_size.x * 0.48)
	filter_mode_root.dragger_visibility = SplitContainer.DRAGGER_HIDDEN if is_mobile else SplitContainer.DRAGGER_VISIBLE
	_apply_filter_layout_mode(is_mobile)
	_apply_relation_layout_mode(is_mobile)
	_apply_compact_layout(compact, is_mobile)
	if mode == MODE_FILTER:
		call_deferred("_update_table_scroll_flag")

func _is_compact_phone() -> bool:
	var size: Vector2 = get_viewport_rect().size
	return (size.x >= size.y and size.y <= 420.0) or (size.y > size.x and size.x <= 520.0)

func _install_body_scroll() -> void:
	if _body_scroll_installed:
		return
	if root_layout == null or body_container == null:
		return
	var existing_scroll: ScrollContainer = root_layout.get_node_or_null("BodyScroll") as ScrollContainer
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
	var idx: int = body_container.get_index()
	root_layout.add_child(scroll)
	root_layout.move_child(scroll, idx)
	body_container.reparent(scroll)
	_body_scroll_installed = true

func _apply_compact_layout(compact: bool, is_mobile: bool) -> void:
	btn_back.custom_minimum_size = Vector2(100.0 if compact else 120.0, 44.0 if compact else 48.0)
	btn_clear.custom_minimum_size = Vector2(110.0 if compact else 140.0, 44.0 if compact else 56.0)
	btn_submit.custom_minimum_size = Vector2(150.0 if compact else 180.0, 44.0 if compact else 56.0)
	prompt_label.custom_minimum_size.y = 56.0 if compact else 100.0
	rel_prompt.custom_minimum_size.y = 52.0 if compact else 80.0
	var tree_min_height: float = 120.0 if compact else (160.0 if is_mobile else 200.0)
	data_tree.custom_minimum_size.y = tree_min_height
	rel_tree_l.custom_minimum_size.y = tree_min_height
	rel_tree_r.custom_minimum_size.y = tree_min_height
	if is_instance_valid(connector_overlay):
		connector_overlay.custom_minimum_size.y = tree_min_height + 40.0
	for child in rel_options_row.get_children():
		if child is Button:
			(child as Button).custom_minimum_size.y = 44.0 if compact else 56.0

func _build_mobile_containers() -> void:
	filter_mobile_layout = VBoxContainer.new()
	filter_mobile_layout.name = "FilterMobileLayout"
	filter_mobile_layout.visible = false
	filter_mobile_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filter_mobile_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	filter_mobile_layout.set("theme_override_constants/separation", 10)
	body_container.add_child(filter_mobile_layout)

	relation_mobile_schema = VBoxContainer.new()
	relation_mobile_schema.name = "RelationMobileSchema"
	relation_mobile_schema.visible = false
	relation_mobile_schema.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	relation_mobile_schema.size_flags_vertical = Control.SIZE_EXPAND_FILL
	relation_mobile_schema.set("theme_override_constants/separation", 8)
	relation_mode_root.add_child(relation_mobile_schema)
	relation_mode_root.move_child(relation_mobile_schema, 1)

func _apply_filter_layout_mode(is_mobile: bool) -> void:
	if is_mobile:
		if filter_table_section.get_parent() != filter_mobile_layout:
			filter_table_section.reparent(filter_mobile_layout)
		if filter_task_section.get_parent() != filter_mobile_layout:
			filter_task_section.reparent(filter_mobile_layout)
		filter_mobile_layout.move_child(filter_table_section, 0)
		filter_mobile_layout.move_child(filter_task_section, 1)
		filter_mode_root.visible = false
		filter_mobile_layout.visible = (mode == MODE_FILTER)
	else:
		if filter_table_section.get_parent() != filter_mode_root:
			filter_table_section.reparent(filter_mode_root)
		if filter_task_section.get_parent() != filter_mode_root:
			filter_task_section.reparent(filter_mode_root)
		filter_mode_root.move_child(filter_table_section, 0)
		filter_mode_root.move_child(filter_task_section, 1)
		filter_mode_root.visible = (mode == MODE_FILTER)
		filter_mobile_layout.visible = false

func _apply_relation_layout_mode(is_mobile: bool) -> void:
	if is_mobile:
		if rel_left_table.get_parent() != relation_mobile_schema:
			rel_left_table.reparent(relation_mobile_schema)
		if rel_center_connector.get_parent() != relation_mobile_schema:
			rel_center_connector.reparent(relation_mobile_schema)
		if rel_right_table.get_parent() != relation_mobile_schema:
			rel_right_table.reparent(relation_mobile_schema)
		relation_mobile_schema.move_child(rel_left_table, 0)
		relation_mobile_schema.move_child(rel_center_connector, 1)
		relation_mobile_schema.move_child(rel_right_table, 2)
		relation_schema_container.visible = false
		relation_mobile_schema.visible = (mode == MODE_RELATION)
	else:
		if rel_left_table.get_parent() != relation_schema_container:
			rel_left_table.reparent(relation_schema_container)
		if rel_center_connector.get_parent() != relation_schema_container:
			rel_center_connector.reparent(relation_schema_container)
		if rel_right_table.get_parent() != relation_schema_container:
			rel_right_table.reparent(relation_schema_container)
		relation_schema_container.move_child(rel_left_table, 0)
		relation_schema_container.move_child(rel_center_connector, 1)
		relation_schema_container.move_child(rel_right_table, 2)
		relation_schema_container.visible = (mode == MODE_RELATION)
		relation_mobile_schema.visible = false

func _array_intersection(arr1: Array, arr2: Array) -> Array:
	var lookup: Dictionary = {}
	for v in arr2:
		lookup[v] = true
	var out: Array = []
	for v in arr1:
		if lookup.has(v):
			out.append(v)
	return out

func _array_diff(arr1: Array, arr2: Array) -> Array:
	var lookup: Dictionary = {}
	for v in arr2:
		lookup[v] = true
	var out: Array = []
	for v in arr1:
		if not lookup.has(v):
			out.append(v)
	return out

func _is_subset(subset_arr: Array, set_arr: Array) -> bool:
	var lookup: Dictionary = {}
	for v in set_arr:
		lookup[v] = true
	for v in subset_arr:
		if not lookup.has(v):
			return false
	return true

func _sets_equal(arr1: Array, arr2: Array) -> bool:
	if arr1.size() != arr2.size():
		return false
	return _is_subset(arr1, arr2) and _is_subset(arr2, arr1)

func _finish_session() -> void:
	_bump_transition_token()
	_teardown_interaction(true)
	title_label.text = _tr("da7.b.ui.title_complete", "DATA ARCHIVE // SESSION COMPLETE [B]")
	prompt_label.text = _tr("da7.b.ui.complete_message", "Investigation complete.")
	rel_prompt.text = _tr("da7.b.ui.complete_message", "Investigation complete.")
	_ensure_exit_button()

func _game_over() -> void:
	_bump_transition_token()
	_teardown_interaction(true)
	title_label.text = _tr("da7.b.ui.title_locked", "DATA ARCHIVE // SYSTEM LOCK [B]")
	prompt_label.text = _tr("da7.b.ui.lock_message", "Stability dropped to zero.")
	rel_prompt.text = _tr("da7.b.ui.lock_message", "Stability dropped to zero.")
	_ensure_exit_button()

func _ensure_exit_button() -> void:
	if exit_btn != null and is_instance_valid(exit_btn):
		return
	exit_btn = Button.new()
	exit_btn.text = _tr("da7.common.exit", "EXIT")
	exit_btn.custom_minimum_size = Vector2(140, 48)
	exit_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")
	)
	$SafeArea/RootLayout/Footer.add_child(exit_btn)

func _show_fatal(text: String) -> void:
	_bump_transition_token()
	prompt_label.text = text
	rel_prompt.text = text
	_teardown_interaction(true)

func _teardown_interaction(clear_overlay: bool) -> void:
	is_trial_active = false
	rel_drag_active = false
	btn_submit.disabled = true
	btn_clear.disabled = true
	_set_relation_options_enabled(false)
	if not clear_overlay or not is_instance_valid(connector_overlay):
		return
	if connector_overlay.has_method("clear_all"):
		connector_overlay.call("clear_all")
	elif connector_overlay.has_method("clear_drag"):
		connector_overlay.call("clear_drag")
	elif connector_overlay.has_method("clear_connection"):
		connector_overlay.call("clear_connection")

func _play_sound(sound_name: String, fallback: AudioStreamPlayer) -> void:
	var manager := get_node_or_null("/root/AudioManager")
	if manager != null and manager.has_method("play"):
		manager.call("play", sound_name)
		return
	if is_instance_valid(fallback):
		fallback.play()

func _on_back_pressed() -> void:
	_bump_transition_token()
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _clear_relation_drag_overlay() -> void:
	if not is_instance_valid(connector_overlay):
		return
	if connector_overlay.has_method("clear_drag"):
		connector_overlay.call("clear_drag")
	elif connector_overlay.has_method("clear_connection"):
		connector_overlay.call("clear_connection")

func _bump_transition_token() -> void:
	_transition_token += 1
