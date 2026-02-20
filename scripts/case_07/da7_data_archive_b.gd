extends Control

# Data & Config
const CasesHub = preload("res://scripts/case_07/da7_cases.gd")
const CasesModuleB = preload("res://scripts/case_07/da7_cases_b.gd")
const BREAKPOINT_PX = 800
const SESSION_CASE_COUNT = 6
const LAYOUT_MOBILE = "mobile"
const LAYOUT_DESKTOP = "desktop"
const TYPEWRITER_INTERVAL_SEC := 0.06
const SUBMIT_BASE_TEXT := "SUBMIT [ENTER]"

# State
var session_cases: Array = []
var current_case_index: int = 0
var current_case: Dictionary = {}
var is_trial_active: bool = false
var is_game_over: bool = false
var mode: String = "" # "FILTER" or "RELATION"

# Telemetry State
var stability_start: float = 0.0
var ui_ready_ts: int = 0
var time_to_first_action_ms: int = -1
var time_to_first_toggle_ms: int = -1
var scroll_used: bool = false
var table_has_scroll: bool = false
var clear_used: bool = false
var clear_count: int = 0
var toggle_count: int = 0
var unique_rows_toggled: Dictionary = {} # row_id -> bool
var click_timestamps: Array[float] = []
var lag_compensation_ms: float = 0.0
var current_layout_mode: String = LAYOUT_DESKTOP
var _suppress_tree_edited: bool = false
var _typewriter_active: bool = false
var _typewriter_accum: float = 0.0

# Nodes
@onready var filter_mode_root: HSplitContainer = $RootLayout/Body/FilterModeRoot
@onready var relation_mode_root: VBoxContainer = $RootLayout/Body/RelationModeRoot
@onready var body_container: VBoxContainer = $RootLayout/Body

# Filter Mode Nodes
@onready var data_tree: Tree = $RootLayout/Body/FilterModeRoot/TableSection/DataTree
@onready var prompt_label: RichTextLabel = $RootLayout/Body/FilterModeRoot/TaskSection/PromptLabel
@onready var btn_submit: Button = $RootLayout/Body/FilterModeRoot/TaskSection/ControlRow/BtnSubmit
@onready var btn_clear: Button = $RootLayout/Body/FilterModeRoot/TaskSection/ControlRow/BtnClear
@onready var filter_table_section: VBoxContainer = $RootLayout/Body/FilterModeRoot/TableSection
@onready var filter_task_section: VBoxContainer = $RootLayout/Body/FilterModeRoot/TaskSection
var filter_mobile_layout: VBoxContainer

# Relation Mode Nodes
@onready var rel_prompt: RichTextLabel = $RootLayout/Body/RelationModeRoot/PromptLabelRel
@onready var relation_schema_container: HBoxContainer = $RootLayout/Body/RelationModeRoot/SchemaContainer
@onready var rel_tree_l: Tree = $RootLayout/Body/RelationModeRoot/SchemaContainer/LeftTable/TreeL
@onready var rel_tree_r: Tree = $RootLayout/Body/RelationModeRoot/SchemaContainer/RightTable/TreeR
@onready var rel_title_l: Label = $RootLayout/Body/RelationModeRoot/SchemaContainer/LeftTable/Title
@onready var rel_title_r: Label = $RootLayout/Body/RelationModeRoot/SchemaContainer/RightTable/Title
@onready var rel_link_label: Label = $RootLayout/Body/RelationModeRoot/SchemaContainer/CenterConnector/HintLabel
@onready var rel_arrow_label: Label = $RootLayout/Body/RelationModeRoot/SchemaContainer/CenterConnector/ArrowLabel
@onready var rel_left_table: VBoxContainer = $RootLayout/Body/RelationModeRoot/SchemaContainer/LeftTable
@onready var rel_center_connector: VBoxContainer = $RootLayout/Body/RelationModeRoot/SchemaContainer/CenterConnector
@onready var rel_right_table: VBoxContainer = $RootLayout/Body/RelationModeRoot/SchemaContainer/RightTable
@onready var rel_options_row: HBoxContainer = $RootLayout/Body/RelationModeRoot/OptionsRow
@onready var connector_overlay: Control = $RootLayout/Body/RelationModeRoot/ConnectorOverlay
var relation_mobile_schema: VBoxContainer

# Common Nodes
@onready var stability_bar: ProgressBar = get_node_or_null("RootLayout/Footer/StabilityBar")
@onready var stability_label: Label = get_node_or_null("RootLayout/Footer/StabilityLabel")
@onready var title_label: RichTextLabel = $RootLayout/Header/Margin/Title
@onready var btn_back: Button = $RootLayout/BackRow/BtnBack
@onready var sfx_error: AudioStreamPlayer = $Runtime/Audio/SfxError
@onready var sfx_relay: AudioStreamPlayer = $Runtime/Audio/SfxRelay

func _ready():
	randomize()
	_build_mobile_containers()
	# Connect Filter Buttons
	btn_submit.pressed.connect(_on_submit_pressed)
	btn_submit.pressed.connect(_register_interaction)
	btn_clear.pressed.connect(_on_clear_pressed)
	btn_clear.pressed.connect(_register_interaction)
	btn_back.pressed.connect(_on_back_pressed)

	_init_session()

	get_tree().root.size_changed.connect(_on_viewport_size_changed)
	call_deferred("_on_viewport_size_changed")

	_load_next_case()

func _process(delta):
	if is_trial_active:
		if delta > 0.25:
			lag_compensation_ms += delta * 1000.0
	if _typewriter_active:
		_typewriter_accum += delta
		while _typewriter_accum >= TYPEWRITER_INTERVAL_SEC and _typewriter_active:
			_typewriter_accum -= TYPEWRITER_INTERVAL_SEC
			var lbl: RichTextLabel = _get_active_prompt_label()
			if lbl.visible_characters < lbl.get_total_character_count():
				lbl.visible_characters += 1
			else:
				lbl.visible_characters = -1
				_typewriter_active = false

func _init_session():
	var all_cases: Array = CasesHub.get_cases("B")
	var valid_cases: Array = []
	for c_v in all_cases:
		if typeof(c_v) != TYPE_DICTIONARY:
			continue
		var c: Dictionary = c_v as Dictionary
		if CasesModuleB.validate_case_b(c):
			valid_cases.append(c)

	valid_cases.shuffle()
	session_cases = valid_cases.slice(0, min(SESSION_CASE_COUNT, valid_cases.size()))
	current_case_index = -1

	GlobalMetrics.stability = 100.0
	_update_stability_ui()

func _load_next_case():
	current_case_index += 1
	if current_case_index >= session_cases.size():
		_finish_session()
		return

	current_case = session_cases[current_case_index] as Dictionary
	is_trial_active = true

	# Reset Telemetry
	ui_ready_ts = Time.get_ticks_msec()
	time_to_first_action_ms = -1
	time_to_first_toggle_ms = -1
	scroll_used = false
	table_has_scroll = false
	clear_used = false
	clear_count = 0
	toggle_count = 0
	unique_rows_toggled.clear()
	click_timestamps.clear()
	lag_compensation_ms = 0.0
	stability_start = GlobalMetrics.stability
	_suppress_tree_edited = false

	var interaction_type: String = str(current_case.get("interaction_type", ""))
	if interaction_type == "MULTI_SELECT_ROWS":
		mode = "FILTER"
		filter_mode_root.visible = true
		relation_mode_root.visible = false
		_set_filter_input_locked(false)
		_render_filter_ui()
	elif interaction_type == "RELATIONSHIP_CHOICE":
		mode = "RELATION"
		filter_mode_root.visible = false
		relation_mode_root.visible = true
		_render_relation_ui()

	_on_viewport_size_changed()
	_start_typewriter()

# --- Render Logic ---

func _render_filter_ui():
	data_tree.clear()
	var root: TreeItem = data_tree.create_item()
	data_tree.hide_root = true

	var table_data: Dictionary = current_case.get("table", {}) as Dictionary
	var cols: Array = table_data.get("columns", []) as Array
	data_tree.columns = cols.size() + 1 # +1 for Checkbox
	data_tree.set_column_title(0, "SEL")
	for i in range(cols.size()):
		var col_def: Dictionary = cols[i]
		data_tree.set_column_title(i+1, str(col_def.get("title", "COL")))
	data_tree.column_titles_visible = true

	# Connect item_edited only once? No, signals are per object.
	# Tree signals are on the Tree.
	if not data_tree.item_edited.is_connected(_on_tree_item_edited):
		data_tree.item_edited.connect(_on_tree_item_edited)
	if not data_tree.item_selected.is_connected(_on_tree_item_selected):
		data_tree.item_selected.connect(_on_tree_item_selected)
	if not data_tree.gui_input.is_connected(_on_data_tree_gui_input):
		data_tree.gui_input.connect(_on_data_tree_gui_input)

	var rows: Array = (table_data.get("rows", []) as Array).duplicate()
	var anti_cheat: Dictionary = current_case.get("anti_cheat", {}) as Dictionary
	if bool(anti_cheat.get("shuffle_rows", false)):
		rows.shuffle()

	for row_data in rows:
		if typeof(row_data) != TYPE_DICTIONARY:
			continue
		var row_dict: Dictionary = row_data as Dictionary
		var item: TreeItem = data_tree.create_item(root)
		item.set_metadata(0, str(row_dict.get("row_id", "")))

		# Checkbox setup
		item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		item.set_checked(0, false)
		item.set_editable(0, true)
		item.set_text(0, "") # No text next to checkbox

		for i in range(cols.size()):
			var col_def: Dictionary = cols[i]
			var col_id: String = str(col_def.get("col_id", ""))
			var cells: Dictionary = row_dict.get("cells", {}) as Dictionary
			item.set_text(i+1, str(cells.get(col_id, "")))
			# Only column 0 is editable (checkbox)

	prompt_label.text = str(current_case.get("prompt", ""))
	prompt_label.visible_characters = 0
	_refresh_submit_enabled()
	call_deferred("_update_table_scroll_flag")

func _render_relation_ui():
	# Clear previous options
	for child in rel_options_row.get_children():
		child.queue_free()

	var schema: Dictionary = current_case.get("schema_visual", {}) as Dictionary
	var left_table: Dictionary = schema.get("left_table", {}) as Dictionary
	var right_table: Dictionary = schema.get("right_table", {}) as Dictionary
	var link: Dictionary = schema.get("link", {}) as Dictionary

	_fill_mini_tree(rel_tree_l, left_table)
	rel_title_l.text = str(left_table.get("title", "Левая"))

	_fill_mini_tree(rel_tree_r, right_table)
	rel_title_r.text = str(right_table.get("title", "Правая"))

	rel_link_label.text = str(link.get("hint_label", "FK ссылка"))
	rel_arrow_label.text = ""
	rel_prompt.text = str(current_case.get("prompt", ""))
	rel_prompt.visible_characters = 0
	_update_relation_connector()

	# Options
	var opts: Array = (current_case.get("options", []) as Array).duplicate()
	var anti_cheat: Dictionary = current_case.get("anti_cheat", {}) as Dictionary
	if bool(anti_cheat.get("shuffle_options", false)):
		opts.shuffle()

	for opt in opts:
		if typeof(opt) != TYPE_DICTIONARY:
			continue
		var opt_data: Dictionary = opt as Dictionary
		var btn: Button = Button.new()
		btn.text = str(opt_data.get("text", "ВАРИАНТ"))
		btn.name = "Btn_" + str(opt_data.get("id", ""))
		btn.custom_minimum_size = Vector2(0, 56)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_register_interaction)
		btn.pressed.connect(_on_relation_option_selected.bind(opt_data))
		rel_options_row.add_child(btn)

func _fill_mini_tree(tree: Tree, table_def: Dictionary):
	tree.clear()
	var root: TreeItem = tree.create_item()
	tree.hide_root = true

	var cols: Array = table_def.get("columns", []) as Array
	tree.columns = cols.size()
	for i in range(cols.size()):
		var col_def: Dictionary = cols[i]
		tree.set_column_title(i, str(col_def.get("title", "COL")))
	tree.column_titles_visible = true

	var preview_rows: Array = table_def.get("rows_preview", []) as Array
	# Limit preview? Spec says 6.
	for i in range(min(preview_rows.size(), 6)):
		if typeof(preview_rows[i]) != TYPE_DICTIONARY:
			continue
		var row_data: Dictionary = preview_rows[i] as Dictionary
		var item: TreeItem = tree.create_item(root)
		for j in range(cols.size()):
			var col_def: Dictionary = cols[j]
			var col_id: String = str(col_def.get("col_id", ""))
			var row_cells: Dictionary = row_data.get("cells", {}) as Dictionary
			item.set_text(j, str(row_cells.get(col_id, "")))

# --- Interactions ---

func _register_interaction():
	if not is_trial_active: return
	if time_to_first_action_ms < 0:
		time_to_first_action_ms = Time.get_ticks_msec() - ui_ready_ts

	var now: float = float(Time.get_ticks_msec())
	click_timestamps.append(now)
	while click_timestamps.size() > 5:
		click_timestamps.pop_front()

func _on_tree_item_edited():
	# Fired when checkbox is toggled
	if not is_trial_active:
		return
	if _suppress_tree_edited:
		return
	var edited_column: int = data_tree.get_edited_column()
	if edited_column != 0:
		return

	var item: TreeItem = data_tree.get_edited()
	if not item:
		return
	_register_interaction()

	# Detect toggle
	toggle_count += 1
	var row_id: String = str(item.get_metadata(0))
	unique_rows_toggled[row_id] = true

	if time_to_first_toggle_ms < 0:
		time_to_first_toggle_ms = Time.get_ticks_msec() - ui_ready_ts
	_refresh_submit_enabled()

func _on_tree_item_selected():
	pass

func _on_data_tree_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP or mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scroll_used = true
	elif event is InputEventScreenDrag:
		scroll_used = true

func _on_clear_pressed():
	if not is_trial_active:
		return
	var cleared_any: bool = false
	_suppress_tree_edited = true
	var root: TreeItem = data_tree.get_root()
	if root:
		var item: TreeItem = root.get_first_child()
		while item:
			if item.is_checked(0):
				cleared_any = true
				item.set_checked(0, false)
			item = item.get_next()
	_suppress_tree_edited = false
	if cleared_any:
		clear_used = true
		clear_count += 1
	_refresh_submit_enabled()

func _on_submit_pressed():
	if not is_trial_active:
		return
	is_trial_active = false
	_set_filter_input_locked(true)
	_stop_typewriter()

	var selected_ids: Array = []
	var root: TreeItem = data_tree.get_root()
	if root:
		var item: TreeItem = root.get_first_child()
		while item:
			if item.is_checked(0):
				selected_ids.append(str(item.get_metadata(0)))
			item = item.get_next()

	var analysis: Dictionary = _calculate_f_reason_filter(selected_ids)
	analysis["selected_row_ids"] = selected_ids
	var is_correct: bool = str(analysis.get("reason", "MIXED_ERROR")) == "NONE"
	var reason_value: Variant = null if is_correct else str(analysis.get("reason", "MIXED_ERROR"))
	_handle_result(is_correct, reason_value, analysis)

func _on_relation_option_selected(opt: Dictionary):
	if not is_trial_active:
		return
	is_trial_active = false
	_stop_typewriter()

	var selected_option_id: String = str(opt.get("id", ""))
	var answer_id: String = str(current_case.get("answer_id", ""))
	var is_correct: bool = selected_option_id == answer_id
	var reason: Variant = null
	if not is_correct:
		reason = str(opt.get("f_reason", "WRONG_RELATION"))

	# Disable buttons
	for child in rel_options_row.get_children():
		if child is Button:
			(child as Button).disabled = true

	_handle_result(is_correct, reason, {"selected_option_id": selected_option_id})

func _handle_result(is_correct: bool, reason: Variant, extra_data: Dictionary):
	if not is_correct:
		if sfx_error:
			sfx_error.play()
	else:
		if sfx_relay:
			sfx_relay.play()

	_log_trial(is_correct, reason, extra_data)
	_update_stability_ui()

	await get_tree().create_timer(1.0).timeout

	if GlobalMetrics.stability <= 0:
		_game_over()
	else:
		_load_next_case()

# --- Logic Ladder ---

func _calculate_f_reason_filter(selected: Array) -> Dictionary:
	var S: Array = selected.duplicate()
	var A: Array = current_case.get("answer_row_ids", []) as Array
	var B: Array = current_case.get("boundary_row_ids", []) as Array
	var O: Array = current_case.get("opposite_row_ids", []) as Array
	var U: Array = current_case.get("unrelated_row_ids", []) as Array
	var D: Array = current_case.get("decoy_row_ids", []) as Array
	var predicate: Dictionary = current_case.get("predicate", {}) as Dictionary
	var strict_expected: bool = bool(predicate.get("strict_expected", false))

	var missing_ids: Array = _array_diff(A, S)
	var extra_ids: Array = _array_diff(S, A)
	var boundary_selected: Array = _array_intersection(S, B)
	var opposite_selected: Array = _array_intersection(S, O)
	var decoy_selected: Array = _array_intersection(S, D)
	var unrelated_selected: Array = _array_intersection(S, U)
	var extra_outside_main: Array = _array_diff(_array_diff(_array_diff(_array_diff(S, A), B), O), D)

	var has_omission: bool = missing_ids.size() > 0
	var reason: String = "NONE"

	if S.is_empty():
		reason = "EMPTY_SELECTION"
	elif _is_subset(S, O):
		reason = "PURE_OPPOSITE"
	elif strict_expected and boundary_selected.size() > 0:
		reason = "INCLUDED_BOUNDARY"
	elif decoy_selected.size() > 0:
		reason = "OVERSELECT_DECOY"
	elif unrelated_selected.size() > 0 or extra_outside_main.size() > 0:
		reason = "FALSE_POSITIVE"
	elif has_omission:
		reason = "OMISSION"
	elif _sets_equal(S, A):
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

# --- Telemetry ---

func _log_trial(is_correct: bool, f_reason: Variant, data: Dictionary):
	var now_ms: int = Time.get_ticks_msec()
	var raw_elapsed_ms: int = now_ms - ui_ready_ts
	var effective_elapsed_ms: int = int(max(0.0, raw_elapsed_ms - lag_compensation_ms))
	var timing_policy: Dictionary = current_case.get("timing_policy", {}) as Dictionary
	var limit_sec: int = int(timing_policy.get("limit_sec", 120))
	var over_soft: bool = effective_elapsed_ms > (limit_sec * 1000)

	var burst: bool = false
	if click_timestamps.size() >= 4 and (click_timestamps[-1] - click_timestamps[0]) <= 700.0:
		burst = true

	var case_id: String = str(current_case.get("id", "DA7-B-00"))
	var schema_version: String = str(current_case.get("schema_version", "DA7.B.v1"))
	var estimated_end_stability: float = stability_start if is_correct else max(0.0, stability_start - 10.0)
	var payload: Dictionary = {
		"question_id": case_id,
		"case_id": case_id,
		"quest_id": "DA7",
		"quest": "data_archive",
		"stage": "B",
		"level": str(current_case.get("level", "B")),
		"schema_version": schema_version,
		"topic": str(current_case.get("topic", "DB_FILTERING")),
		"case_kind": str(current_case.get("case_kind", "")),
		"interaction_type": str(current_case.get("interaction_type", "")),
		"match_key": "DA7_B|%s|%s" % [case_id, mode],
		"is_correct": is_correct,
		"f_reason": f_reason,
		"elapsed_ms": effective_elapsed_ms,
		"duration": float(effective_elapsed_ms) / 1000.0,
		"timing": {
			"effective_elapsed_ms": effective_elapsed_ms,
			"time_to_first_action_ms": time_to_first_action_ms,
			"time_to_first_toggle_ms": time_to_first_toggle_ms,
			"policy_mode": str(timing_policy.get("mode", "LEARNING")),
			"limit_sec": limit_sec
		},
		"answer": {},
		"expected": {},
		"flags": {
			"silent_reading_possible": (time_to_first_action_ms >= 30000 and not scroll_used and not table_has_scroll),
			"had_scroll": scroll_used,
			"table_has_scroll": table_has_scroll
		},
		"anti_cheat": current_case.get("anti_cheat", {}),
		"layout_mode": current_layout_mode,
		"telemetry": {
			"time_to_first_action_ms": time_to_first_action_ms,
			"time_to_first_toggle_ms": time_to_first_toggle_ms,
			"time_to_submit_ms": raw_elapsed_ms,
			"raw_elapsed_ms": raw_elapsed_ms,
			"lag_compensation_ms": lag_compensation_ms,
			"effective_elapsed_ms": effective_elapsed_ms,
			"toggle_count": toggle_count,
			"unique_rows_toggled_count": unique_rows_toggled.size(),
			"clear_used": clear_used,
			"clear_count": clear_count,
			"scroll_used": scroll_used,
			"rapid_toggle_burst": burst,
			"over_soft_limit": over_soft
		},
		"stability": {
			"start": stability_start,
			"end": estimated_end_stability,
			"delta": estimated_end_stability - stability_start
		}
	}

	if mode == "FILTER":
		var sets: Dictionary = data.get("sets", {}) as Dictionary
		var selected_ids: Array = data.get("selected_row_ids", []) as Array
		payload["task"] = {"predicate": current_case.get("predicate", {})}
		payload["answer"] = {
			"selected_row_ids": selected_ids,
			"diagnostic_sets": sets,
			"missing_ids": sets.get("missing_ids", []),
			"extra_ids": sets.get("extra_ids", []),
			"boundary_selected": sets.get("boundary_selected", []),
			"opposite_selected": sets.get("opposite_selected", []),
			"decoy_selected": sets.get("decoy_selected", []),
			"unrelated_selected": sets.get("unrelated_selected", []),
			"extra_outside_main": sets.get("extra_outside_main", [])
		}
		payload["expected"] = {
			"answer_row_ids": current_case.get("answer_row_ids", []),
			"boundary_row_ids": current_case.get("boundary_row_ids", []),
			"opposite_row_ids": current_case.get("opposite_row_ids", []),
			"unrelated_row_ids": current_case.get("unrelated_row_ids", []),
			"decoy_row_ids": current_case.get("decoy_row_ids", [])
		}

	elif mode == "RELATION":
		var schema_visual: Dictionary = current_case.get("schema_visual", {}) as Dictionary
		payload["schema_visual"] = {"link": schema_visual.get("link", {})}
		payload["answer"] = {
			"selected_option_id": str(data.get("selected_option_id", ""))
		}
		payload["expected"] = {
			"answer_id": str(current_case.get("answer_id", "")),
			"expected_relation": str(current_case.get("expected_relation", ""))
		}

	GlobalMetrics.register_trial(payload)

# --- Utils ---
func _update_stability_ui():
	if is_instance_valid(stability_bar):
		stability_bar.value = GlobalMetrics.stability
	if is_instance_valid(stability_label):
		stability_label.text = "СТАБИЛЬНОСТЬ: %d%%" % int(GlobalMetrics.stability)

func _start_typewriter():
	var lbl: RichTextLabel = _get_active_prompt_label()
	lbl.visible_characters = 0
	_typewriter_accum = 0.0
	_typewriter_active = true

func _stop_typewriter() -> void:
	_typewriter_active = false
	_typewriter_accum = 0.0
	var lbl: RichTextLabel = _get_active_prompt_label()
	lbl.visible_characters = -1

func _get_active_prompt_label() -> RichTextLabel:
	return prompt_label if mode == "FILTER" else rel_prompt

func _on_viewport_size_changed():
	var win_size: Vector2 = get_viewport_rect().size
	var is_mobile: bool = win_size.x < BREAKPOINT_PX
	current_layout_mode = LAYOUT_MOBILE if is_mobile else LAYOUT_DESKTOP
	filter_mode_root.split_offset = int(win_size.x * 0.48)
	filter_mode_root.dragger_visibility = SplitContainer.DRAGGER_HIDDEN if is_mobile else SplitContainer.DRAGGER_VISIBLE
	_apply_filter_layout_mode(is_mobile)
	_apply_relation_layout_mode(is_mobile)
	if mode == "FILTER":
		call_deferred("_update_table_scroll_flag")

func _finish_session():
	is_game_over = true
	title_label.text = "СЕССИЯ ЗАВЕРШЕНА [B]"
	prompt_label.text = "Архивы защищены."
	rel_prompt.text = "Архивы защищены."

	# Remove controls
	if mode == "FILTER":
		$RootLayout/Body/FilterModeRoot/TaskSection/ControlRow.queue_free()
	else:
		rel_options_row.queue_free()

	var btn_exit: Button = Button.new()
	btn_exit.text = "ВЫХОД"
	btn_exit.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn"))

	# Add exit button somewhere visible
	$RootLayout/Footer.add_child(btn_exit)

func _game_over():
	is_game_over = true
	title_label.text = "МИССИЯ ПРОВАЛЕНА"
	var btn_exit: Button = Button.new()
	btn_exit.text = "ВЫХОД"
	btn_exit.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn"))
	$RootLayout/Footer.add_child(btn_exit)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

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
		filter_mobile_layout.visible = (mode == "FILTER")
	else:
		if filter_table_section.get_parent() != filter_mode_root:
			filter_table_section.reparent(filter_mode_root)
		if filter_task_section.get_parent() != filter_mode_root:
			filter_task_section.reparent(filter_mode_root)
		filter_mode_root.move_child(filter_table_section, 0)
		filter_mode_root.move_child(filter_task_section, 1)
		filter_mode_root.visible = (mode == "FILTER")
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
		relation_mobile_schema.visible = (mode == "RELATION")
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
		relation_schema_container.visible = (mode == "RELATION")
		relation_mobile_schema.visible = false
	_update_relation_connector()

func _update_relation_connector() -> void:
	if not is_instance_valid(connector_overlay):
		return
	if mode != "RELATION":
		connector_overlay.visible = false
		return
	connector_overlay.visible = true
	var orientation: String = "vertical" if current_layout_mode == LAYOUT_MOBILE else "horizontal"
	var schema_visual: Dictionary = current_case.get("schema_visual", {}) as Dictionary
	var links_config: Array = schema_visual.get("links", []) as Array
	if links_config.size() > 0 and connector_overlay.has_method("set_links"):
		var overlay_links: Array = []
		for _link in links_config:
			overlay_links.append({"from": rel_left_table, "to": rel_right_table})
		connector_overlay.call_deferred("set_links", overlay_links, relation_mode_root, "edge", orientation)
	elif connector_overlay.has_method("set_endpoints"):
		if connector_overlay.has_method("set_anchor_mode"):
			connector_overlay.call("set_anchor_mode", "edge", orientation)
		connector_overlay.call_deferred("set_endpoints", rel_left_table, rel_right_table, relation_mode_root)

func _set_filter_input_locked(locked: bool) -> void:
	if locked:
		btn_submit.disabled = true
	else:
		_refresh_submit_enabled()
	btn_clear.disabled = locked
	var root: TreeItem = data_tree.get_root()
	if root:
		var item: TreeItem = root.get_first_child()
		while item:
			item.set_editable(0, not locked)
			item = item.get_next()

func _refresh_submit_enabled() -> void:
	if mode != "FILTER" or not is_trial_active:
		btn_submit.disabled = true
		btn_submit.text = SUBMIT_BASE_TEXT
		return
	var selected_count: int = _selected_count()
	btn_submit.disabled = selected_count == 0
	btn_submit.text = "%s (%d)" % [SUBMIT_BASE_TEXT, selected_count]

func _selected_count() -> int:
	var count: int = 0
	var root: TreeItem = data_tree.get_root()
	if root:
		var item: TreeItem = root.get_first_child()
		while item:
			if item.is_checked(0):
				count += 1
			item = item.get_next()
	return count

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

func _array_intersection(arr1: Array, arr2: Array) -> Array:
	var lookup: Dictionary = {}
	for x in arr2:
		lookup[x] = true
	var out: Array = []
	for x in arr1:
		if lookup.has(x):
			out.append(x)
	return out

func _array_diff(arr1: Array, arr2: Array) -> Array:
	var lookup: Dictionary = {}
	for x in arr2:
		lookup[x] = true
	var out: Array = []
	for x in arr1:
		if not lookup.has(x):
			out.append(x)
	return out

func _is_subset(subset_arr: Array, set_arr: Array) -> bool:
	var lookup: Dictionary = {}
	for x in set_arr:
		lookup[x] = true
	for x in subset_arr:
		if not lookup.has(x):
			return false
	return true

func _sets_equal(arr1: Array, arr2: Array) -> bool:
	if arr1.size() != arr2.size():
		return false
	return _is_subset(arr1, arr2) and _is_subset(arr2, arr1)


