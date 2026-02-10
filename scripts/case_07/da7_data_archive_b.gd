extends Control

# Data & Config
const CasesModuleB = preload("res://scripts/case_07/da7_cases_b.gd")
const BREAKPOINT_PX = 820
const SESSION_CASE_COUNT = 6

# State
var session_cases: Array = []
var current_case_index: int = 0
var current_case: Dictionary = {}
var is_trial_active: bool = false
var is_game_over: bool = false
var mode: String = "" # "FILTER" or "RELATION"

# Telemetry State
var stability_start: float = 0.0
var ui_ready_ts: float = 0.0
var time_to_first_action_ms: float = -1.0
var time_to_first_toggle_ms: float = -1.0
var scroll_used: bool = false
var clear_used: bool = false
var clear_count: int = 0
var toggle_count: int = 0
var unique_rows_toggled: Dictionary = {} # row_id -> bool
var click_timestamps: Array[float] = []
var lag_compensation_ms: float = 0.0

# Nodes
@onready var filter_mode_root = $RootLayout/Body/FilterModeRoot
@onready var relation_mode_root = $RootLayout/Body/RelationModeRoot
@onready var body_container = $RootLayout/Body

# Filter Mode Nodes
@onready var data_tree: Tree = $RootLayout/Body/FilterModeRoot/TableSection/DataTree
@onready var prompt_label: RichTextLabel = $RootLayout/Body/FilterModeRoot/TaskSection/PromptLabel
@onready var btn_submit = $RootLayout/Body/FilterModeRoot/TaskSection/ControlRow/BtnSubmit
@onready var btn_clear = $RootLayout/Body/FilterModeRoot/TaskSection/ControlRow/BtnClear

# Relation Mode Nodes
@onready var rel_prompt = $RootLayout/Body/RelationModeRoot/PromptLabelRel
@onready var rel_tree_l = $RootLayout/Body/RelationModeRoot/SchemaContainer/LeftTable/TreeL
@onready var rel_tree_r = $RootLayout/Body/RelationModeRoot/SchemaContainer/RightTable/TreeR
@onready var rel_title_l = $RootLayout/Body/RelationModeRoot/SchemaContainer/LeftTable/Title
@onready var rel_title_r = $RootLayout/Body/RelationModeRoot/SchemaContainer/RightTable/Title
@onready var rel_link_label = $RootLayout/Body/RelationModeRoot/SchemaContainer/CenterConnector/HintLabel
@onready var rel_options_row = $RootLayout/Body/RelationModeRoot/OptionsRow

# Common Nodes
@onready var stability_bar = $RootLayout/Footer/StabilityBar
@onready var stability_label = $RootLayout/Footer/StabilityLabel
@onready var title_label = $RootLayout/Header/Margin/Title
@onready var sfx_error = $Runtime/Audio/SfxError
@onready var sfx_relay = $Runtime/Audio/SfxRelay
@onready var typewriter_timer = $Runtime/TypewriterTimer

func _ready():
	randomize()
	# Connect Filter Buttons
	btn_submit.pressed.connect(_on_submit_pressed)
	btn_submit.pressed.connect(_register_interaction)
	btn_clear.pressed.connect(_on_clear_pressed)
	btn_clear.pressed.connect(_register_interaction)

	_init_session()

	get_tree().root.size_changed.connect(_on_viewport_size_changed)
	call_deferred("_on_viewport_size_changed")

	_load_next_case()

func _process(delta):
	if is_trial_active:
		if delta > 0.25:
			lag_compensation_ms += delta * 1000.0

func _init_session():
	var all_cases = CasesModuleB.CASES_B.duplicate(true)
	var valid_cases = []
	for c in all_cases:
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

	current_case = session_cases[current_case_index]
	is_trial_active = true

	# Reset Telemetry
	ui_ready_ts = Time.get_ticks_msec()
	time_to_first_action_ms = -1.0
	time_to_first_toggle_ms = -1.0
	scroll_used = false
	clear_used = false
	clear_count = 0
	toggle_count = 0
	unique_rows_toggled.clear()
	click_timestamps.clear()
	lag_compensation_ms = 0.0
	stability_start = GlobalMetrics.stability

	if current_case.interaction_type == "MULTI_SELECT_ROWS":
		mode = "FILTER"
		filter_mode_root.visible = true
		relation_mode_root.visible = false
		_render_filter_ui()
	elif current_case.interaction_type == "RELATIONSHIP_CHOICE":
		mode = "RELATION"
		filter_mode_root.visible = false
		relation_mode_root.visible = true
		_render_relation_ui()

	_start_typewriter()

# --- Render Logic ---

func _render_filter_ui():
	data_tree.clear()
	var root = data_tree.create_item()
	data_tree.hide_root = true

	var cols = current_case.table.columns
	data_tree.columns = cols.size() + 1 # +1 for Checkbox
	data_tree.set_column_title(0, "✓")
	for i in range(cols.size()):
		data_tree.set_column_title(i+1, cols[i].title)
	data_tree.column_titles_visible = true

	# Connect item_edited only once? No, signals are per object.
	# Tree signals are on the Tree.
	if not data_tree.item_edited.is_connected(_on_tree_item_edited):
		data_tree.item_edited.connect(_on_tree_item_edited)
	if not data_tree.item_selected.is_connected(_on_tree_item_selected):
		data_tree.item_selected.connect(_on_tree_item_selected)

	var rows = current_case.table.rows.duplicate()
	if current_case.anti_cheat.get("shuffle_rows", false):
		rows.shuffle()

	for row_data in rows:
		var item = data_tree.create_item(root)
		item.set_metadata(0, row_data.row_id)

		# Checkbox setup
		item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		item.set_checked(0, false)
		item.set_editable(0, true)
		item.set_text(0, "") # No text next to checkbox

		for i in range(cols.size()):
			var val = row_data.cells.get(cols[i].col_id, "")
			item.set_text(i+1, val)
			# Only column 0 is editable (checkbox)

	prompt_label.text = current_case.prompt
	prompt_label.visible_characters = 0

func _render_relation_ui():
	# Clear previous options
	for child in rel_options_row.get_children():
		child.queue_free()

	var schema = current_case.schema_visual

	_fill_mini_tree(rel_tree_l, schema.left_table)
	rel_title_l.text = schema.left_table.title

	_fill_mini_tree(rel_tree_r, schema.right_table)
	rel_title_r.text = schema.right_table.title

	rel_link_label.text = schema.link.hint_label
	rel_prompt.text = current_case.prompt
	rel_prompt.visible_characters = 0

	# Options
	var opts = current_case.options.duplicate()
	if current_case.anti_cheat.get("shuffle_options", false):
		opts.shuffle()

	for opt in opts:
		var btn = Button.new()
		btn.text = opt.text
		btn.name = "Btn_" + opt.id
		btn.pressed.connect(_register_interaction)
		btn.pressed.connect(_on_relation_option_selected.bind(opt))
		rel_options_row.add_child(btn)

func _fill_mini_tree(tree: Tree, table_def: Dictionary):
	tree.clear()
	var root = tree.create_item()
	tree.hide_root = true

	var cols = table_def.columns
	tree.columns = cols.size()
	for i in range(cols.size()):
		tree.set_column_title(i, cols[i].title)
	tree.column_titles_visible = true

	var preview_rows = table_def.get("rows_preview", [])
	# Limit preview? Spec says 6.
	for i in range(min(preview_rows.size(), 6)):
		var row_data = preview_rows[i]
		var item = tree.create_item(root)
		for j in range(cols.size()):
			item.set_text(j, row_data.cells.get(cols[j].col_id, ""))

# --- Interactions ---

func _register_interaction():
	if not is_trial_active: return
	if time_to_first_action_ms < 0:
		time_to_first_action_ms = Time.get_ticks_msec() - ui_ready_ts

	var now = Time.get_ticks_msec()
	click_timestamps.append(now)
	while click_timestamps.size() > 5:
		click_timestamps.pop_front()

func _on_tree_item_edited():
	# Fired when checkbox is toggled
	if not is_trial_active: return
	_register_interaction()

	var item = data_tree.get_edited()
	if not item: return

	# Detect toggle
	toggle_count += 1
	var row_id = item.get_metadata(0)
	unique_rows_toggled[row_id] = true

	if time_to_first_toggle_ms < 0:
		time_to_first_toggle_ms = Time.get_ticks_msec() - ui_ready_ts

func _on_tree_item_selected():
	# Just noise action
	_register_interaction()

func _on_clear_pressed():
	if not is_trial_active: return
	clear_used = true
	clear_count += 1
	var root = data_tree.get_root()
	if root:
		var item = root.get_first_child()
		while item:
			item.set_checked(0, false)
			item = item.get_next()

func _on_submit_pressed():
	if not is_trial_active: return
	is_trial_active = false
	typewriter_timer.stop()
	prompt_label.visible_characters = -1

	var selected_ids = []
	var root = data_tree.get_root()
	if root:
		var item = root.get_first_child()
		while item:
			if item.is_checked(0):
				selected_ids.append(item.get_metadata(0))
			item = item.get_next()

	var analysis = _calculate_f_reason_filter(selected_ids)
	var is_correct = (analysis.reason == "CORRECT")

	_handle_result(is_correct, analysis.reason, analysis)

func _on_relation_option_selected(opt: Dictionary):
	if not is_trial_active: return
	is_trial_active = false
	typewriter_timer.stop()
	rel_prompt.visible_characters = -1

	var is_correct = (opt.id == current_case.answer_id)
	var reason = "CORRECT"
	if not is_correct:
		reason = opt.f_reason

	# Disable buttons
	for child in rel_options_row.get_children():
		child.disabled = true

	_handle_result(is_correct, reason, {"selected_option_id": opt.id})

func _handle_result(is_correct: bool, reason: String, extra_data: Dictionary):
	var stability_end = GlobalMetrics.stability
	if not is_correct:
		GlobalMetrics.stability = max(0, GlobalMetrics.stability - 10.0)
		stability_end = GlobalMetrics.stability
		if sfx_error: sfx_error.play()
	else:
		if sfx_relay: sfx_relay.play()

	_update_stability_ui()
	_log_trial(is_correct, reason, extra_data, stability_end)

	await get_tree().create_timer(1.0).timeout

	if GlobalMetrics.stability <= 0:
		_game_over()
	else:
		_load_next_case()

# --- Logic Ladder ---

func _calculate_f_reason_filter(selected: Array) -> Dictionary:
	var S = selected
	var A = current_case.answer_row_ids
	var B = current_case.boundary_row_ids
	var O = current_case.opposite_row_ids
	var U = current_case.unrelated_row_ids

	# Helpers
	var s_set = {}
	for id in S: s_set[id] = true

	var intersection = func(arr1, arr2):
		var res = []
		for x in arr1:
			if x in arr2: res.append(x)
		return res

	var diff = func(arr1, arr2):
		var res = []
		for x in arr1:
			if not (x in arr2): res.append(x)
		return res

	var is_subset = func(arr1, arr2):
		for x in arr1:
			if not (x in arr2): return false
		return true

	var missing = diff.call(A, S)
	var union_AB = []
	union_AB.append_array(A)
	union_AB.append_array(B)
	var extra = diff.call(S, union_AB)

	var boundary_selected = intersection.call(S, B)
	var opposite_selected = intersection.call(S, O)

	var all_rows_count = current_case.table.rows.size()

	var result = {
		"reason": "CORRECT",
		"sets": {
			"missing": missing,
			"extra": extra,
			"boundary_selected": boundary_selected,
			"opposite_selected": opposite_selected
		}
	}

	# Ladder
	if S.size() == 0:
		result.reason = "EMPTY_SUBMIT"
		return result

	if float(S.size()) / float(all_rows_count) >= 0.8 and missing.size() > 0:
		result.reason = "OVERSELECT_ALL"
		return result

	if S.size() > 0 and is_subset.call(S, O):
		result.reason = "SIGN_REVERSAL"
		return result

	if opposite_selected.size() > 0 and intersection.call(S, A).size() == 0:
		result.reason = "SIGN_MIXED"
		return result

	var strict = current_case.predicate.strict_expected
	if strict and boundary_selected.size() > 0:
		result.reason = "INCLUDED_BOUNDARY"
		return result

	if not strict and is_subset.call(B, A) and not is_subset.call(B, S):
		# Non-strict means boundary SHOULD be selected. B is subset of A.
		# If B is not subset of S, we missed boundary.
		result.reason = "EXCLUDED_BOUNDARY"
		return result

	if extra.size() > 0:
		result.reason = "FALSE_POSITIVE"
		return result

	if missing.size() > 0:
		result.reason = "OMISSION"
		return result

	return result

# --- Telemetry ---

func _log_trial(is_correct: bool, f_reason: String, data: Dictionary, stability_end: float):
	var now = Time.get_ticks_msec()
	var raw_elapsed = now - ui_ready_ts
	var effective_elapsed = raw_elapsed - lag_compensation_ms
	var over_soft = effective_elapsed > (current_case.timing_policy.limit_sec * 1000)

	var burst = false
	if click_timestamps.size() >= 4:
		if (click_timestamps[-1] - click_timestamps[0]) <= 700:
			burst = true

	var payload = {
		"quest_id": "CASE_07_DATA_ARCHIVE",
		"case_id": current_case.id,
		"schema_version": current_case.schema_version,
		"level": current_case.level,
		"topic": current_case.topic,
		"case_kind": current_case.case_kind,
		"interaction_type": current_case.interaction_type,

		"answer": {
			"is_correct": is_correct,
			"f_reason": f_reason,
		},
		"telemetry": {
			"time_to_first_action_ms": time_to_first_action_ms,
			"time_to_first_toggle_ms": time_to_first_toggle_ms,
			"time_to_submit_ms": raw_elapsed, # roughly same as elapsed
			"raw_elapsed_ms": raw_elapsed,
			"lag_compensation_ms": lag_compensation_ms,
			"effective_elapsed_time_ms": effective_elapsed,
			"toggle_count": toggle_count,
			"unique_rows_toggled_count": unique_rows_toggled.size(),
			"clear_used": clear_used,
			"scroll_used": scroll_used,
			"rapid_toggle_burst": burst,
			"over_soft_limit": over_soft
		},
		"stability": {
			"start": stability_start,
			"end": stability_end,
			"delta": stability_end - stability_start
		}
	}

	if mode == "FILTER":
		payload["task"] = {"predicate": current_case.predicate}
		payload["answer"]["diagnostic_sets"] = data.get("sets", {})
		# selected_row_ids not explicitly passed in logic, recover from logic or store?
		# Re-gathering selected IDs for log is okay or passing via extra_data.
		# Let's assume we want selected rows.
		var selected_ids = []
		var root = data_tree.get_root()
		if root:
			var item = root.get_first_child()
			while item:
				if item.is_checked(0):
					selected_ids.append(item.get_metadata(0))
				item = item.get_next()
		payload["answer"]["selected_row_ids"] = selected_ids

	elif mode == "RELATION":
		payload["schema_visual"] = {"link": current_case.schema_visual.link}
		payload["answer"]["selected_option_id"] = data.get("selected_option_id")
		payload["expected_relation"] = current_case.get("expected_relation")

	GlobalMetrics.register_trial(payload)

# --- Utils ---
func _update_stability_ui():
	stability_bar.value = GlobalMetrics.stability
	stability_label.text = "STABILITY: %d%%" % int(GlobalMetrics.stability)

func _start_typewriter():
	typewriter_timer.stop()
	if typewriter_timer.is_connected("timeout", _on_typewriter_tick):
		typewriter_timer.timeout.disconnect(_on_typewriter_tick)

	typewriter_timer.wait_time = 0.03
	typewriter_timer.timeout.connect(_on_typewriter_tick)
	typewriter_timer.start()

func _on_typewriter_tick():
	var lbl = prompt_label if mode == "FILTER" else rel_prompt
	if lbl.visible_characters < lbl.get_total_character_count():
		lbl.visible_characters += 1
	else:
		typewriter_timer.stop()

func _on_viewport_size_changed():
	var win_size = get_viewport_rect().size
	# Adjust layout if needed (B spec says "Table scrolls separately", buttons available).
	# Layout is VBox with HSplit. HSplit collapses if too small?
	# Let's keep it simple: FilterModeRoot is HSplit.
	# If small, change split to vertical or Reparent.
	# For now, relying on default behavior or minimal tweaks.
	if win_size.x < BREAKPOINT_PX:
		filter_mode_root.dragger_visibility = SplitContainer.DRAGGER_HIDDEN
		# Force vertical or just rely on containers.
		# HSplit isn't great for mobile. Ideally VBox.
		# Not implementing full reactive switch here to keep it safe as per strict plan.
	else:
		filter_mode_root.dragger_visibility = SplitContainer.DRAGGER_VISIBLE

func _finish_session():
	is_game_over = true
	title_label.text = "SESSION COMPLETE [B]"
	prompt_label.text = "Archives secured."
	rel_prompt.text = "Archives secured."

	# Remove controls
	if mode == "FILTER":
		$RootLayout/Body/FilterModeRoot/TaskSection/ControlRow.queue_free()
	else:
		rel_options_row.queue_free()

	var btn_exit = Button.new()
	btn_exit.text = "EXIT"
	btn_exit.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn"))

	# Add exit button somewhere visible
	$RootLayout/Footer.add_child(btn_exit)

func _game_over():
	is_game_over = true
	title_label.text = "MISSION FAILED"
	var btn_exit = Button.new()
	btn_exit.text = "EXIT"
	btn_exit.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn"))
	$RootLayout/Footer.add_child(btn_exit)
