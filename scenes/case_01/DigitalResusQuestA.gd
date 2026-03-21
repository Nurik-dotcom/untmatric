extends Control

const LEVELS_PATH: String = "res://data/clues_levels.json"
const FLOW_SCENE_PATH: String = "res://scenes/case_01/Case01Flow.tscn"
const ITEM_SCENE: PackedScene = preload("res://scenes/ui/ResusPartItem.tscn")
const TABLE_RENDERER_SCENE_PATH: String = "res://scenes/case_01/renderers/TableMatchRenderer.tscn"
const ResusData = preload("res://scripts/case_01/ResusData.gd")
const ResusScoring = preload("res://scripts/case_01/ResusScoring.gd")
const TrialV2 = preload("res://scripts/TrialV2.gd")
const PHONE_LANDSCAPE_MAX_HEIGHT := 740.0
const PHONE_PORTRAIT_MAX_WIDTH := 520.0

const COLOR_OK: Color = Color(0.9, 0.93, 0.98, 1.0)
const COLOR_WARN: Color = Color(0.98, 0.8, 0.52, 1.0)
const COLOR_ERR: Color = Color(0.95, 0.36, 0.38, 1.0)

var levels: Array = []
var current_level_index: int = 0
var level_data: Dictionary = {}
var start_time_ms: int = 0
var attempt_index: int = 0
var trial_seq: int = 0
var task_session: Dictionary = {}
var drag_count: int = 0
var trace: Array = []
var item_nodes: Dictionary = {}
var item_contracts: Dictionary = {}
var bucket_labels_runtime: Dictionary = {}
var bucket_to_zone: Dictionary = {}
var input_locked: bool = false
var console_target_text: String = ""
var console_visible_chars: int = 0
var console_cps: float = 16.0
var console_accum: float = 0.0
var _last_state_key: String = ""
var _briefing_collapsed: bool = true
var _briefing_toggle_button: Button = null
var _last_result: Dictionary = {}
var _last_payload: Dictionary = {}
var _confirm_requires_force: bool = false
var _table_renderer: Node = null
var _table_renderer_scene: PackedScene = null

var drag_start_count: int = 0
var drop_count: int = 0
var replace_count: int = 0
var remove_count: int = 0
var unique_item_ids: Dictionary = {}

var bucket_switch_count: int = 0
var wrong_bucket_try_count: int = 0
var reset_count_local: int = 0
var confirm_attempt_count: int = 0

var changed_after_feedback: bool = false
var changed_after_fail: bool = false

var time_to_first_drag_ms: int = -1
var time_to_first_drop_ms: int = -1
var time_to_first_confirm_ms: int = -1
var time_from_last_edit_to_confirm_ms: int = -1

var last_edit_ms: int = -1
var last_bucket_id: String = ""
var _awaiting_edit_after_feedback: bool = false
var _awaiting_edit_after_fail: bool = false
var _selected_item_id: String = ""
var _bucket_popup: PanelContainer = null
var _bucket_popup_buttons: Dictionary = {}
var _popup_item_id: String = ""

@onready var noir_overlay: Node = $NoirOverlay
@onready var safe_area: MarginContainer = $SafeArea
@onready var main_vbox: VBoxContainer = $SafeArea/MainVBox
@onready var header: HBoxContainer = $SafeArea/MainVBox/Header
@onready var content_scroll: ScrollContainer = $SafeArea/MainVBox/ContentScroll
@onready var content_vbox: VBoxContainer = $SafeArea/MainVBox/ContentScroll/Content
@onready var bottom_bar: VBoxContainer = $SafeArea/MainVBox/BottomBar
@onready var briefing_card: PanelContainer = $SafeArea/MainVBox/ContentScroll/Content/BriefingCard
@onready var briefing_label: Label = $SafeArea/MainVBox/ContentScroll/Content/BriefingCard/BriefingLabel
@onready var system_card: PanelContainer = $SafeArea/MainVBox/ContentScroll/Content/SystemCard
@onready var zones_card: PanelContainer = $SafeArea/MainVBox/ContentScroll/Content/ZonesCard
@onready var parts_card: PanelContainer = $SafeArea/MainVBox/ContentScroll/Content/PartsPileCard
@onready var renderer_host: PanelContainer = $SafeArea/MainVBox/ContentScroll/Content/RendererHost
@onready var parts_grid: GridContainer = $SafeArea/MainVBox/ContentScroll/Content/PartsPileCard/VBox/Scroll/PartsGrid
@onready var title_label: Label = $SafeArea/MainVBox/Header/TitleLabel
@onready var stage_label: Label = $SafeArea/MainVBox/Header/StageLabel
@onready var stability_bar: ProgressBar = $SafeArea/MainVBox/Header/StabilityBar
@onready var monitor_screen: ColorRect = $SafeArea/MainVBox/ContentScroll/Content/SystemCard/SystemVBox/MonitorFrame/MonitorScreen
@onready var monitor_label: Label = $SafeArea/MainVBox/ContentScroll/Content/SystemCard/SystemVBox/MonitorFrame/MonitorLabel
@onready var boot_console: RichTextLabel = $SafeArea/MainVBox/ContentScroll/Content/SystemCard/SystemVBox/BootConsole
@onready var diag_video_value: Label = $SafeArea/MainVBox/ContentScroll/Content/SystemCard/SystemVBox/DiagPanel/DiagVBox/VideoRow/VideoValue
@onready var diag_memory_value: Label = $SafeArea/MainVBox/ContentScroll/Content/SystemCard/SystemVBox/DiagPanel/DiagVBox/MemoryRow/MemoryValue
@onready var diag_buffer_value: Label = $SafeArea/MainVBox/ContentScroll/Content/SystemCard/SystemVBox/DiagPanel/DiagVBox/BufferRow/BufferValue
@onready var pile_zone: Node = $SafeArea/MainVBox/ContentScroll/Content/PartsPileCard
@onready var zone_input: Node = $SafeArea/MainVBox/ContentScroll/Content/ZonesCard/ZonesVBox/ZoneInput
@onready var zone_output: Node = $SafeArea/MainVBox/ContentScroll/Content/ZonesCard/ZonesVBox/ZoneOutput
@onready var zone_memory: Node = $SafeArea/MainVBox/ContentScroll/Content/ZonesCard/ZonesVBox/ZoneMemory
@onready var status_label: Label = $SafeArea/MainVBox/BottomBar/StatusLabel
@onready var btn_reset: Button = $SafeArea/MainVBox/BottomBar/ActionsRow/BtnReset
@onready var btn_confirm: Button = $SafeArea/MainVBox/BottomBar/ActionsRow/BtnConfirm
@onready var btn_back: Button = $SafeArea/MainVBox/Header/BtnBack
@onready var dimmer: ColorRect = $Dimmer
@onready var result_popup: PanelContainer = $ResultPopup
@onready var result_verdict_label: Label = $ResultPopup/VBox/VerdictLabel
@onready var result_score_label: Label = $ResultPopup/VBox/ScoreLabel
@onready var result_stability_label: Label = $ResultPopup/VBox/StabilityLabel
@onready var result_details_label: RichTextLabel = $ResultPopup/VBox/ResultDetails
@onready var result_retry_button: Button = $ResultPopup/VBox/Buttons/BtnRetry
@onready var result_next_level_button: Button = $ResultPopup/VBox/Buttons/BtnNextLevel
@onready var result_back_button: Button = $ResultPopup/VBox/Buttons/BtnBack

func _tr(key: String, default_text: String, params: Dictionary = {}) -> String:
	var merged: Dictionary = params.duplicate(true)
	merged["default"] = default_text
	return I18n.tr_key(key, merged)

func _ready() -> void:
	add_to_group("resus_a_controller")
	if not GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.connect(_on_stability_changed)
	if not get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.connect(_on_viewport_size_changed)
	if not I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.connect(_on_language_changed)

	btn_back.pressed.connect(_on_back_pressed)
	btn_reset.pressed.connect(_on_reset_pressed)
	btn_confirm.pressed.connect(_on_confirm_pressed)
	result_retry_button.pressed.connect(_on_retry_pressed)
	result_next_level_button.pressed.connect(_on_next_level_pressed)
	result_back_button.pressed.connect(_on_back_pressed)

	_setup_collapsible_briefing()
	_connect_zone_signals()
	_load_levels()
	if levels.is_empty():
		_show_error(_tr("resus.a.error.load", "Stage A data is missing."))
		return
	_start_level(current_level_index)
	_on_viewport_size_changed()

func _exit_tree() -> void:
	if I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.disconnect(_on_language_changed)
	if get_tree() != null and get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.disconnect(_on_viewport_size_changed)

func _process(delta: float) -> void:
	_update_console(delta)

func is_input_locked() -> bool:
	return input_locked

func _load_levels() -> void:
	levels = ResusData.load_levels(LEVELS_PATH)

func _connect_zone_signals() -> void:
	if pile_zone.has_signal("item_placed") and not pile_zone.is_connected("item_placed", Callable(self, "_on_pile_item_placed")):
		pile_zone.connect("item_placed", Callable(self, "_on_pile_item_placed"))
	for zone in _socket_zones():
		if zone.has_signal("hint_requested") and not zone.is_connected("hint_requested", Callable(self, "_on_socket_hint_requested")):
			zone.connect("hint_requested", Callable(self, "_on_socket_hint_requested"))
		if zone.has_signal("drop_accepted") and not zone.is_connected("drop_accepted", Callable(self, "_on_socket_drop_accepted")):
			zone.connect("drop_accepted", Callable(self, "_on_socket_drop_accepted"))
		if zone.has_signal("drop_rejected") and not zone.is_connected("drop_rejected", Callable(self, "_on_socket_drop_rejected")):
			zone.connect("drop_rejected", Callable(self, "_on_socket_drop_rejected"))

func _on_language_changed(_code: String) -> void:
	_apply_i18n()
	if _is_table_level() and _table_renderer != null and _table_renderer.has_method("apply_i18n"):
		_table_renderer.call("apply_i18n")
	if level_data.is_empty():
		return
	briefing_label.text = _resolve_briefing_text(level_data)
	if not _is_table_level():
		_configure_zones()
		_build_bucket_popup()
		_refresh_spawned_item_localization()
	_reset_confirm_warning_state()
	_last_state_key = ""
	if not _is_table_level():
		_refresh_system_state(_build_placements_snapshot())
	if result_popup.visible:
		if _is_table_level():
			result_details_label.text = _build_table_result_text(_last_result.get("details", []) as Array)
		else:
			result_details_label.text = _build_result_error_text(_last_payload.get("errors", []) as Array)

func _apply_i18n() -> void:
	title_label.text = _tr("resus.title", "Case 01: Digital Resus")
	_update_stage_label()
	btn_reset.text = _tr("resus.a.btn.reset", "RESET")
	if _confirm_requires_force:
		btn_confirm.text = _tr("resus.a.btn.force_confirm", "CONFIRM ANYWAY")
	else:
		btn_confirm.text = _tr("resus.a.btn.confirm", "CONFIRM")
	result_retry_button.text = _tr("resus.a.btn.retry", "RETRY")
	result_back_button.text = _tr("resus.a.btn.back", "BACK")
	if result_next_level_button != null:
		result_next_level_button.text = _next_level_button_text()

func _update_stage_label() -> void:
	var total_levels: int = max(1, levels.size())
	stage_label.text = _tr("resus.a.stage.progress", "STAGE A {n}/{total}", {
		"n": current_level_index + 1,
		"total": total_levels
	})

func _start_level(index: int) -> void:
	current_level_index = clamp(index, 0, max(0, levels.size() - 1))
	level_data = (levels[current_level_index] as Dictionary).duplicate(true)
	item_contracts = _item_contract_map(level_data.get("items", []) as Array)
	briefing_label.text = _resolve_briefing_text(level_data)
	_apply_i18n()
	if _is_table_level():
		_enable_table_mode()
		_hide_bucket_popup()
	else:
		_enable_matching_mode()
		_configure_zones()
		_build_bucket_popup()
	_reset_attempt()

func _enable_table_mode() -> void:
	system_card.visible = false
	zones_card.visible = false
	parts_card.visible = false
	renderer_host.visible = true
	if _table_renderer == null:
		var table_scene: PackedScene = _load_table_renderer_scene()
		if table_scene == null:
			renderer_host.visible = false
			push_error("DigitalResusQuestA: missing renderer scene at %s" % TABLE_RENDERER_SCENE_PATH)
			return
		_table_renderer = table_scene.instantiate()
		renderer_host.add_child(_table_renderer)
	if _table_renderer.has_method("setup"):
		_table_renderer.call("setup", level_data, self)

func _load_table_renderer_scene() -> PackedScene:
	if _table_renderer_scene != null:
		return _table_renderer_scene
	var loaded: Variant = load(TABLE_RENDERER_SCENE_PATH)
	if loaded is PackedScene:
		_table_renderer_scene = loaded as PackedScene
		return _table_renderer_scene
	return null

func _enable_matching_mode() -> void:
	system_card.visible = true
	zones_card.visible = true
	parts_card.visible = true
	renderer_host.visible = false
	if _table_renderer != null:
		_table_renderer.queue_free()
		_table_renderer = null

func _resolve_briefing_text(level: Dictionary) -> String:
	return I18n.resolve_field(level, "briefing", {
		"default": str(level.get("briefing", ""))
	})

func _refresh_spawned_item_localization() -> void:
	for item_id_v in item_nodes.keys():
		var item_id: String = str(item_id_v)
		var node_v: Variant = item_nodes.get(item_id, null)
		if not (node_v is Node):
			continue
		var contract_v: Variant = item_contracts.get(item_id, null)
		if not (contract_v is Dictionary):
			continue
		var node: Node = node_v as Node
		if node.has_method("refresh_localized_text"):
			node.call("refresh_localized_text", (contract_v as Dictionary).duplicate(true))

func _reset_confirm_warning_state() -> void:
	_confirm_requires_force = false
	btn_confirm.text = _tr("resus.a.btn.confirm", "CONFIRM")

func _configure_zones() -> void:
	var buckets: Array = level_data.get("buckets", []) as Array
	bucket_labels_runtime = _bucket_label_map(buckets)
	bucket_to_zone.clear()
	var bucket_ids: Array[String] = _bucket_ids(buckets)
	var zones: Array = _socket_zones()

	if pile_zone.has_method("setup"):
		pile_zone.call("setup", "PILE", _tr("resus.a.labels.pile", "PARTS"))

	var setup_count: int = int(min(bucket_ids.size(), zones.size()))
	for i in range(setup_count):
		var bucket_id: String = bucket_ids[i]
		var zone_node: Node = zones[i]
		bucket_to_zone[bucket_id] = zone_node
		if zone_node.has_method("setup"):
			var bucket_label: String = str(bucket_labels_runtime.get(bucket_id, bucket_id))
			if _is_cia_level():
				bucket_label = _tr("resus.a.labels.cia_folder", "FOLDER {label}", {"label": bucket_label})
			zone_node.call("setup", bucket_id, bucket_label, _accepted_item_ids_for_bucket(bucket_id))

func _reset_trial_runtime() -> void:
	drag_start_count = 0
	drop_count = 0
	replace_count = 0
	remove_count = 0
	unique_item_ids.clear()
	bucket_switch_count = 0
	wrong_bucket_try_count = 0
	reset_count_local = 0
	confirm_attempt_count = 0
	changed_after_feedback = false
	changed_after_fail = false
	time_to_first_drag_ms = -1
	time_to_first_drop_ms = -1
	time_to_first_confirm_ms = -1
	time_from_last_edit_to_confirm_ms = -1
	last_edit_ms = -1
	last_bucket_id = ""
	_awaiting_edit_after_feedback = false
	_awaiting_edit_after_fail = false

func _mark_edit_action() -> void:
	last_edit_ms = _elapsed_ms_now()
	if _awaiting_edit_after_feedback:
		changed_after_feedback = true
		_awaiting_edit_after_feedback = false
	if _awaiting_edit_after_fail:
		changed_after_fail = true
		_awaiting_edit_after_fail = false

func _begin_trial_session() -> void:
	trial_seq += 1
	task_session = {
		"events": [],
		"trial_seq": trial_seq
	}
	_reset_trial_runtime()
	var bucket_count: int = (level_data.get("buckets", []) as Array).size()
	var item_count: int = (level_data.get("items", []) as Array).size()
	if _is_table_level():
		bucket_count = (level_data.get("configs", []) as Array).size()
		item_count = (level_data.get("tasks", []) as Array).size()
	if bucket_count <= 0:
		bucket_count = bucket_to_zone.size()
	if item_count <= 0:
		item_count = item_contracts.size()
	_log_event("trial_started", {
		"level_id": str(level_data.get("id", "")),
		"briefing": str(level_data.get("briefing", "")),
		"bucket_count": bucket_count,
		"item_count": item_count
	})

func _reset_attempt() -> void:
	if _is_table_level():
		_reset_attempt_table()
		return
	attempt_index += 1
	start_time_ms = Time.get_ticks_msec()
	drag_count = 0
	trace.clear()
	_begin_trial_session()
	_hide_bucket_popup()
	item_nodes.clear()
	input_locked = false
	btn_confirm.disabled = false
	_reset_confirm_warning_state()
	dimmer.visible = false
	result_popup.visible = false
	result_next_level_button.visible = false
	_last_result.clear()
	_last_payload.clear()
	_last_state_key = ""
	_clear_socket_feedback()

	if pile_zone.has_method("clear_items"):
		pile_zone.call("clear_items")
	for zone in _socket_zones():
		if zone.has_method("clear_items"):
			zone.call("clear_items")

	_spawn_items()
	_refresh_system_state(_build_placements_snapshot())
	_update_stability_ui()

func _reset_attempt_table() -> void:
	attempt_index += 1
	start_time_ms = Time.get_ticks_msec()
	drag_count = 0
	trace.clear()
	_begin_trial_session()
	_hide_bucket_popup()
	item_nodes.clear()
	input_locked = false
	btn_confirm.disabled = false
	_reset_confirm_warning_state()
	dimmer.visible = false
	result_popup.visible = false
	result_next_level_button.visible = false
	_last_result.clear()
	_last_payload.clear()
	status_label.text = _tr("resus.a04.status.ready", "Assign each task to a PC, then confirm.")
	status_label.modulate = COLOR_OK
	if _table_renderer != null and _table_renderer.has_method("reset"):
		_table_renderer.call("reset")
	_update_stability_ui()

func _spawn_items() -> void:
	var items: Array = level_data.get("items", []) as Array
	for item_v in items:
		if typeof(item_v) != TYPE_DICTIONARY:
			continue
		var item_data: Dictionary = (item_v as Dictionary).duplicate(true)
		var item_node_v: Variant = ITEM_SCENE.instantiate()
		if not (item_node_v is Control):
			continue
		var item_node: Control = item_node_v as Control
		if item_node.has_method("setup"):
			item_node.call("setup", item_data)
		var item_id: String = str(item_data.get("item_id", ""))
		if item_node.has_signal("drag_started"):
			item_node.connect("drag_started", Callable(self, "_on_drag_started"))
		if item_node.has_signal("drag_cancelled"):
			item_node.connect("drag_cancelled", Callable(self, "_on_drag_cancelled"))
		if item_node is BaseButton and item_id != "":
			var item_button: BaseButton = item_node as BaseButton
			var pressed_cb: Callable = Callable(self, "_on_item_pressed").bind(item_id)
			if not item_button.pressed.is_connected(pressed_cb):
				item_button.pressed.connect(pressed_cb)
		if pile_zone.has_method("add_item_control"):
			pile_zone.call("add_item_control", item_node)
		if item_id != "":
			item_nodes[item_id] = item_node

func _on_drag_started(item_id: String, from_zone: String) -> void:
	if input_locked:
		return
	if not _selected_item_id.is_empty() or (_bucket_popup != null and _bucket_popup.visible):
		_hide_bucket_popup()
	drag_count += 1
	drag_start_count += 1
	if time_to_first_drag_ms < 0:
		time_to_first_drag_ms = _elapsed_ms_now()
	_log_event("DRAG_START", {"item_id": item_id, "from_zone": from_zone})
	_log_event("item_drag_started", {
		"item_id": item_id,
		"from_bucket": from_zone.to_upper(),
		"drag_count": drag_count
	})
	_set_socket_targets_for_item(item_id)

func _on_drag_cancelled(item_id: String, from_zone: String) -> void:
	if input_locked:
		return
	_log_event("DRAG_CANCEL", {"item_id": item_id, "from_zone": from_zone})
	_clear_socket_feedback()

func _on_item_pressed(item_id: String) -> void:
	if input_locked or item_id == "":
		return
	if _bucket_popup != null and _bucket_popup.visible and _popup_item_id == item_id:
		_hide_bucket_popup()
		return
	_popup_item_id = item_id
	_set_selected_item(item_id)
	_show_bucket_popup(item_id)

func _build_bucket_popup() -> void:
	if _bucket_popup == null:
		_bucket_popup = PanelContainer.new()
		_bucket_popup.name = "BucketPopup"
		_bucket_popup.visible = false
		_bucket_popup.z_index = 100
		_bucket_popup.mouse_filter = Control.MOUSE_FILTER_STOP

		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.09, 0.12, 0.95)
		style.border_color = Color(0.3, 0.35, 0.4, 0.8)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		_bucket_popup.add_theme_stylebox_override("panel", style)

		var margin := MarginContainer.new()
		margin.name = "PopupMargin"
		margin.add_theme_constant_override("margin_left", 16)
		margin.add_theme_constant_override("margin_right", 16)
		margin.add_theme_constant_override("margin_top", 12)
		margin.add_theme_constant_override("margin_bottom", 12)

		var vbox := VBoxContainer.new()
		vbox.name = "PopupVBox"
		vbox.add_theme_constant_override("separation", 8)

		var title := Label.new()
		title.name = "PopupTitle"
		title.text = _tr("resus.a.popup.title", "Куда разместить?")
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 18)
		vbox.add_child(title)

		var cancel_btn := Button.new()
		cancel_btn.name = "PopupBtnCancel"
		cancel_btn.text = _tr("resus.a.popup.cancel", "Отмена")
		cancel_btn.custom_minimum_size = Vector2(200.0, 44.0)
		cancel_btn.pressed.connect(_hide_bucket_popup)
		vbox.add_child(cancel_btn)

		margin.add_child(vbox)
		_bucket_popup.add_child(margin)
		add_child(_bucket_popup)

	_refresh_bucket_popup_buttons()

func _refresh_bucket_popup_buttons() -> void:
	if _bucket_popup == null:
		return
	var vbox_node: Variant = _bucket_popup.get_node_or_null("PopupMargin/PopupVBox")
	if not (vbox_node is VBoxContainer):
		return
	var vbox: VBoxContainer = vbox_node as VBoxContainer
	for old_btn_v in _bucket_popup_buttons.values():
		if not (old_btn_v is Button):
			continue
		var old_btn: Button = old_btn_v as Button
		if not is_instance_valid(old_btn):
			continue
		if old_btn.get_parent() == vbox:
			vbox.remove_child(old_btn)
		old_btn.queue_free()
	_bucket_popup_buttons.clear()

	for bucket_id in _bucket_ids(level_data.get("buckets", []) as Array):
		if not bucket_to_zone.has(bucket_id):
			continue
		var btn := Button.new()
		btn.name = "PopupBtn_%s" % bucket_id
		btn.text = str(bucket_labels_runtime.get(bucket_id, bucket_id))
		btn.custom_minimum_size = Vector2(200.0, 52.0)
		btn.pressed.connect(_on_popup_bucket_selected.bind(bucket_id))
		vbox.add_child(btn)
		_bucket_popup_buttons[bucket_id] = btn

	var cancel_btn_node: Variant = vbox.get_node_or_null("PopupBtnCancel")
	if cancel_btn_node is Control:
		vbox.move_child(cancel_btn_node as Control, vbox.get_child_count() - 1)

func _show_bucket_popup(item_id: String) -> void:
	if _bucket_popup == null:
		_build_bucket_popup()
	_popup_item_id = item_id
	_refresh_bucket_popup_buttons()

	var title_node_v: Variant = _bucket_popup.get_node_or_null("PopupMargin/PopupVBox/PopupTitle")
	if title_node_v is Label:
		var title_node: Label = title_node_v as Label
		var item_label: String = ""
		var item_node_v: Variant = item_nodes.get(item_id, null)
		if item_node_v is BaseButton:
			item_label = str((item_node_v as BaseButton).text)
		if item_label.strip_edges() == "":
			item_label = _item_display_name(item_id)
		if item_label.strip_edges() == "":
			item_label = item_id
		title_node.text = _tr("resus.a.popup.title_with_item", "Куда разместить «{item}»?", {"item": item_label})

	_bucket_popup.visible = true
	await get_tree().process_frame
	var viewport_size: Vector2 = get_viewport_rect().size
	var popup_size: Vector2 = _bucket_popup.size
	_bucket_popup.position = (viewport_size - popup_size) * 0.5
	status_label.text = _tr("resus.a.status.choose_bucket", "Выберите зону для размещения.")
	status_label.modulate = COLOR_OK

func _hide_bucket_popup() -> void:
	if _bucket_popup != null:
		_bucket_popup.visible = false
	_popup_item_id = ""
	_clear_selected_item()

func _on_popup_bucket_selected(bucket_id: String) -> void:
	if _popup_item_id.is_empty():
		_hide_bucket_popup()
		return
	var saved_item_id: String = _popup_item_id
	_hide_bucket_popup()
	_set_selected_item(saved_item_id)
	_on_bucket_tapped(bucket_id)

func _on_bucket_tapped(bucket_id: String) -> void:
	if input_locked or _selected_item_id.is_empty():
		return
	var normalized_bucket: String = bucket_id.to_upper()
	if normalized_bucket == "":
		return
	var item_node_v: Variant = item_nodes.get(_selected_item_id, null)
	if not (item_node_v is Node):
		_clear_selected_item()
		return
	var item_node: Node = item_node_v as Node
	if not is_instance_valid(item_node):
		_clear_selected_item()
		return
	var payload: Dictionary = {
		"kind": "RESUS_PART",
		"item_id": _selected_item_id,
		"node_path": str(item_node.get_path()),
		"from_zone": str(item_node.get_meta("zone_id", "PILE")).to_upper()
	}
	var accepted: bool = _accepted_item_ids_for_bucket(normalized_bucket).has(_selected_item_id)
	var zone: Node = _zone_for_socket(normalized_bucket)
	if zone != null:
		if accepted and zone.has_signal("drop_accepted"):
			zone.emit_signal("drop_accepted", _selected_item_id, normalized_bucket)
		elif not accepted and zone.has_signal("drop_rejected"):
			zone.emit_signal("drop_rejected", _selected_item_id, normalized_bucket)
	on_socket_drop(payload, normalized_bucket, accepted)
	if accepted:
		_clear_selected_item(false)

func _set_selected_item(item_id: String) -> void:
	_clear_selected_item(false)
	_selected_item_id = item_id
	_set_item_touch_selected(item_id, true)
	_set_socket_targets_for_item(item_id)

func _clear_selected_item(clear_feedback: bool = true) -> void:
	if not _selected_item_id.is_empty():
		_set_item_touch_selected(_selected_item_id, false)
	_selected_item_id = ""
	if clear_feedback:
		_clear_socket_feedback()

func _set_item_touch_selected(item_id: String, selected: bool) -> void:
	if item_id == "":
		return
	var item_node_v: Variant = item_nodes.get(item_id, null)
	if not (item_node_v is Node):
		return
	var item_node: Node = item_node_v as Node
	if not is_instance_valid(item_node):
		return
	if item_node.has_method("set_touch_selected"):
		item_node.call("set_touch_selected", selected)

func _on_socket_hint_requested(item_id: String, socket_id: String) -> void:
	if input_locked:
		return
	_log_event("SOCKET_HINT", {"item_id": item_id, "hinted_socket": socket_id})

func _on_socket_drop_accepted(item_id: String, socket_id: String) -> void:
	if input_locked:
		return
	_log_event("DROP_OK", {"item_id": item_id, "socket": socket_id})

func _on_socket_drop_rejected(item_id: String, socket_id: String) -> void:
	if input_locked:
		return
	wrong_bucket_try_count += 1
	_awaiting_edit_after_feedback = true
	_awaiting_edit_after_fail = true
	_log_event("DROP_BOUNCE", {"item_id": item_id, "attempted_socket": socket_id})

func on_socket_drop(payload: Dictionary, socket_id: String, accepted: bool) -> void:
	if input_locked:
		return
	var item_id: String = str(payload.get("item_id", ""))
	var to_bucket: String = socket_id.to_upper()
	var from_bucket: String = str(payload.get("from_zone", "PILE")).to_upper()
	var source_path: String = str(payload.get("node_path", ""))
	if source_path == "":
		return
	var source_node: Node = get_node_or_null(source_path)
	if source_node == null or not (source_node is Control):
		return
	var item_control: Control = source_node as Control

	if accepted:
		var zone: Node = _zone_for_socket(socket_id)
		if zone != null and zone.has_method("add_item_control"):
			zone.call("add_item_control", item_control)
		drop_count += 1
		unique_item_ids[item_id] = true
		if time_to_first_drop_ms < 0:
			time_to_first_drop_ms = _elapsed_ms_now()
		var replaced_existing: bool = from_bucket != "PILE" and from_bucket != to_bucket
		if replaced_existing:
			replace_count += 1
		if last_bucket_id != "" and last_bucket_id != to_bucket:
			bucket_switch_count += 1
		last_bucket_id = to_bucket
		_mark_edit_action()
		_log_event("ITEM_PLACED", {
			"item_id": item_id,
			"to_bucket": to_bucket,
			"from_bucket": from_bucket
		})
		_log_event("item_dropped", {
			"item_id": item_id,
			"bucket_id": to_bucket,
			"replaced": replaced_existing,
			"drag_count": drag_count
		})
		_reset_confirm_warning_state()
		_refresh_system_state(_build_placements_snapshot())
		_play_sfx("click")
		_clear_socket_feedback()
		return

	_restore_item_to_source(item_control, str(payload.get("from_zone", "PILE")))
	_reset_confirm_warning_state()
	_refresh_system_state(_build_placements_snapshot())
	_bounce_node(item_control)
	_flash_rejected_socket(socket_id)
	_show_socket_error(_tr("resus.a.status.invalid_socket", "Wrong socket for this part."))
	_play_sfx("error")
	if item_id != "":
		_set_socket_targets_for_item(item_id)

func _restore_item_to_source(item_control: Control, source_bucket: String) -> void:
	var normalized_source: String = source_bucket.to_upper()
	if normalized_source == "PILE":
		if pile_zone.has_method("add_item_control"):
			pile_zone.call("add_item_control", item_control)
		return
	var source_zone: Node = _zone_for_socket(normalized_source)
	if source_zone != null and source_zone.has_method("add_item_control"):
		source_zone.call("add_item_control", item_control)
	else:
		pile_zone.call("add_item_control", item_control)

func _on_pile_item_placed(item_id: String, _to_bucket: String, from_bucket: String) -> void:
	if input_locked:
		return
	var normalized_from: String = from_bucket.to_upper()
	if normalized_from != "PILE":
		remove_count += 1
		_mark_edit_action()
	_log_event("ITEM_PLACED", {
		"item_id": item_id,
		"to_bucket": "PILE",
		"from_bucket": normalized_from
	})
	_log_event("item_removed", {
		"item_id": item_id,
		"from_bucket": normalized_from
	})
	_reset_confirm_warning_state()
	_refresh_system_state(_build_placements_snapshot())
	_clear_socket_feedback()

func _build_placements_snapshot() -> Dictionary:
	var placements: Dictionary = {}
	for item_id_v in item_nodes.keys():
		var item_id: String = str(item_id_v)
		var item_node_v: Variant = item_nodes.get(item_id, null)
		if not (item_node_v is Node):
			placements[item_id] = "PILE"
			continue
		placements[item_id] = str((item_node_v as Node).get_meta("zone_id", "PILE")).to_upper()
	return placements

func _count_placed(placements: Dictionary) -> int:
	var count: int = 0
	for zone_v in placements.values():
		if str(zone_v).to_upper() != "PILE":
			count += 1
	return count

func _evaluate_system_state(placements: Dictionary) -> Dictionary:
	if _is_cia_level():
		return {
			"gpu_ok": true,
			"ram_ok": true,
			"cache_ok": true,
			"monitor_on": true,
			"fast_type": true
		}

	var rules: Dictionary = level_data.get("system_state_rules", {}) as Dictionary
	var fx_rules: Dictionary = level_data.get("fx_rules", {}) as Dictionary
	var monitor_rule: Dictionary = fx_rules.get("gpu_on", rules.get("monitor_on_if", {})) as Dictionary
	var ram_rule: Dictionary = fx_rules.get("ram_ok", rules.get("ram_ok_if", {})) as Dictionary
	var cache_rule: Dictionary = fx_rules.get("cache_ok", rules.get("fast_type_if", {})) as Dictionary

	var gpu_ok: bool = _rule_holds(placements, monitor_rule)
	var ram_ok: bool = _rule_holds(placements, ram_rule)
	var cache_ok: bool = _rule_holds(placements, cache_rule)

	return {
		"gpu_ok": gpu_ok,
		"ram_ok": ram_ok,
		"cache_ok": cache_ok,
		"monitor_on": gpu_ok,
		"fast_type": cache_ok
	}

func _rule_holds(placements: Dictionary, rule_v: Variant) -> bool:
	if typeof(rule_v) != TYPE_DICTIONARY:
		return false
	var rule: Dictionary = rule_v as Dictionary
	var item_id: String = str(rule.get("item_id", "")).strip_edges()
	var zone_id: String = str(rule.get("bucket_id", rule.get("zone_id", ""))).to_upper()
	if item_id == "" or zone_id == "":
		return false
	return str(placements.get(item_id, "PILE")).to_upper() == zone_id

func _refresh_system_state(placements: Dictionary) -> void:
	var state: Dictionary = _evaluate_system_state(placements)
	var gpu_ok: bool = bool(state.get("gpu_ok", false))
	var ram_ok: bool = bool(state.get("ram_ok", false))
	var cache_ok: bool = bool(state.get("cache_ok", false))
	var hid_connected: bool = _input_devices_connected(placements)
	var cia_progress: int = _count_placed(placements) if _is_cia_level() else 0
	var state_key: String = "%s|%s|%s|%s|%d" % [str(gpu_ok), str(ram_ok), str(cache_ok), str(hid_connected), cia_progress]
	if _last_state_key == state_key:
		return
	_last_state_key = state_key

	_update_monitor(gpu_ok)
	_update_diag_panel(gpu_ok, ram_ok, cache_ok)
	console_cps = 42.0 if cache_ok else 16.0
	var console_text: String = "\n".join(_build_console_lines(gpu_ok, ram_ok, hid_connected))
	_set_console_target(console_text)

	if _is_cia_level():
		status_label.text = _tr("resus.a.status.cia_placed", "CIA folders placed: {n}/{total}", {
			"n": cia_progress,
			"total": max(1, item_nodes.size())
		})
		status_label.modulate = COLOR_OK
	else:
		status_label.text = _tr("resus.a.status.hw_state", "VIDEO {gpu} | MEMORY {ram} | BUFFER {buf}", {
			"gpu": "OK" if gpu_ok else "FAIL",
			"ram": "OK" if ram_ok else "FAIL",
			"buf": "FAST" if cache_ok else "SLOW"
		})
		status_label.modulate = COLOR_OK if gpu_ok and ram_ok and cache_ok else (COLOR_ERR if not gpu_ok or not ram_ok else COLOR_WARN)
		_update_diagnostic_hints(state, placements)

	_log_event("DIAG_STATE", {
		"gpu_ok": gpu_ok,
		"ram_ok": ram_ok,
		"cache_ok": cache_ok,
		"hid_connected": hid_connected
	})

func _update_diagnostic_hints(state: Dictionary, placements: Dictionary) -> void:
	var gpu_ok: bool = bool(state.get("gpu_ok", false))
	var ram_ok: bool = bool(state.get("ram_ok", false))
	var cache_ok: bool = bool(state.get("cache_ok", false))
	var placed_count: int = _count_placed(placements)

	if placed_count == 0:
		status_label.text = _tr("resus.a.hint.start", "Drag parts into sockets. Watch diagnostics.")
		status_label.modulate = COLOR_OK
	elif not gpu_ok and placed_count >= 2:
		status_label.text = _tr("resus.a.hint.no_video", "DIAGNOSTICS: No video signal. Is the video card misplaced?")
		status_label.modulate = COLOR_WARN
	elif not ram_ok and placed_count >= 4:
		status_label.text = _tr("resus.a.hint.no_ram", "DIAGNOSTICS: Memory read error. Is RAM disconnected?")
		status_label.modulate = COLOR_WARN
	elif gpu_ok and ram_ok and cache_ok:
		status_label.text = _tr("resus.a.hint.all_ok", "All critical systems online. Finish sorting.")
		status_label.modulate = COLOR_OK

func _update_monitor(monitor_on: bool) -> void:
	if _is_cia_level():
		monitor_screen.color = Color(0.08, 0.2, 0.12, 1.0)
		monitor_label.text = _tr("resus.a.monitor.cia", "CIA TRIAD READY")
		monitor_label.modulate = COLOR_OK
		return
	if monitor_on:
		monitor_screen.color = Color(0.08, 0.2, 0.12, 1.0)
		monitor_label.text = _tr("resus.a.monitor.signal_on", "VIDEO ONLINE")
		monitor_label.modulate = COLOR_OK
	else:
		monitor_screen.color = Color(0.03, 0.03, 0.03, 1.0)
		monitor_label.text = _tr("resus.a.monitor.signal_off", "NO SIGNAL")
		monitor_label.modulate = COLOR_ERR

func _update_diag_panel(gpu_ok: bool, ram_ok: bool, cache_ok: bool) -> void:
	var diag: Dictionary = level_data.get("diag_panel", {}) as Dictionary
	var gpu_diag: Dictionary = diag.get("GPU", {}) as Dictionary
	var ram_diag: Dictionary = diag.get("RAM", {}) as Dictionary
	var cache_diag: Dictionary = diag.get("CACHE", {}) as Dictionary
	diag_video_value.text = str(gpu_diag.get("ok", "VIDEO: ONLINE")) if gpu_ok else str(gpu_diag.get("bad", "VIDEO: NO SIGNAL"))
	diag_memory_value.text = str(ram_diag.get("ok", "MEMORY: OK")) if ram_ok else str(ram_diag.get("bad", "MEMORY: READ ERROR"))
	diag_buffer_value.text = str(cache_diag.get("ok", "BUFFER: FAST")) if cache_ok else str(cache_diag.get("bad", "BUFFER: SLOW"))
	diag_video_value.modulate = COLOR_OK if gpu_ok else COLOR_ERR
	diag_memory_value.modulate = COLOR_OK if ram_ok else COLOR_ERR
	diag_buffer_value.modulate = COLOR_OK if cache_ok else COLOR_WARN

func _build_console_lines(gpu_ok: bool, ram_ok: bool, hid_connected: bool) -> Array[String]:
	if _is_cia_level():
		return [
			_tr("resus.a.console.cia_case", "[CASE] CIA folder classification live"),
			_tr("resus.a.console.cia_conf", "[HINT] CONF handles leaks and secrecy"),
			_tr("resus.a.console.cia_inte", "[HINT] INTE handles tampering and integrity"),
			_tr("resus.a.console.cia_avai", "[HINT] AVAI handles reachability and uptime")
		]

	var feedback_rules: Dictionary = level_data.get("feedback_rules", {}) as Dictionary
	var system_rules: Dictionary = level_data.get("system_state_rules", {}) as Dictionary
	var fx_rules: Dictionary = level_data.get("fx_rules", {}) as Dictionary
	if not ram_ok:
		var no_ram: Dictionary = feedback_rules.get("NO_RAM", {}) as Dictionary
		return _string_array(no_ram.get("console_lines", []))

	var lines: Array[String] = _string_array(system_rules.get("boot_ok_lines", []))
	if hid_connected:
		lines.append_array(_string_array(fx_rules.get("hid_lines_on_input", [])))
	if not gpu_ok:
		lines.append(_tr("resus.a.console.warn_gpu", "[WARN] video path still offline"))
	if lines.is_empty():
		lines.append(_tr("resus.a.console.boot_fallback", "[BOOT] ..."))
	return lines

func _input_devices_connected(placements: Dictionary) -> bool:
	for item_id in _accepted_item_ids_for_bucket("INPUT"):
		if str(placements.get(item_id, "PILE")).to_upper() == "INPUT":
			return true
	return false

func _set_console_target(text: String) -> void:
	if console_target_text == text:
		return
	console_target_text = text
	console_visible_chars = 0
	console_accum = 0.0
	boot_console.text = ""

func _update_console(delta: float) -> void:
	if console_target_text.is_empty():
		return
	if console_visible_chars >= console_target_text.length():
		return
	console_accum += delta * console_cps
	var advance: int = int(floor(console_accum))
	if advance <= 0:
		return
	console_accum -= float(advance)
	console_visible_chars = min(console_target_text.length(), console_visible_chars + advance)
	boot_console.text = console_target_text.substr(0, console_visible_chars)

func _on_confirm_pressed() -> void:
	if input_locked:
		return
	confirm_attempt_count += 1
	if time_to_first_confirm_ms < 0:
		time_to_first_confirm_ms = _elapsed_ms_now()
	if last_edit_ms >= 0:
		time_from_last_edit_to_confirm_ms = maxi(0, _elapsed_ms_now() - last_edit_ms)
	_log_event("confirm_pressed", {
		"attempt": confirm_attempt_count,
		"mode": "TABLE" if _is_table_level() else "MATCHING"
	})
	if _is_table_level():
		_confirm_table()
		return
	var placements: Dictionary = _build_placements_snapshot()
	var placed_count: int = _count_placed(placements)
	var total_items: int = item_nodes.size()
	if placed_count < total_items and not _confirm_requires_force:
		_show_incomplete_warning(placed_count, total_items)
		return

	_reset_confirm_warning_state()
	_execute_confirm(placements, placed_count)

func _show_incomplete_warning(placed: int, total: int) -> void:
	status_label.text = _tr("resus.a.status.not_all_placed",
		"Placed {placed} of {total} parts. Press confirm again to continue.",
		{"placed": placed, "total": total})
	status_label.modulate = COLOR_WARN
	_play_sfx("error")
	_awaiting_edit_after_feedback = true
	_awaiting_edit_after_fail = false
	_log_event("feedback_incomplete", {
		"placed": placed,
		"total": total
	})
	_confirm_requires_force = true
	btn_confirm.text = _tr("resus.a.btn.force_confirm", "CONFIRM ANYWAY")

func _execute_confirm(placements: Dictionary, placed_count: int) -> void:
	_log_event("CONFIRM_PRESSED", {"placed_count": placed_count})
	input_locked = true
	btn_confirm.disabled = true

	var result: Dictionary = ResusScoring.score(level_data, placements, placed_count)
	var errors: Array = _build_errors(placements)
	var system_state: Dictionary = _evaluate_system_state(placements)
	var hid_connected: bool = _input_devices_connected(placements)
	var elapsed_ms: int = _elapsed_ms_now()
	var total_items: int = int(result.get("total_items", item_contracts.size()))
	var wrong_bucket_count: int = errors.size()
	var unplaced_count: int = maxi(0, total_items - placed_count)
	var outcome_code: String = _resolve_outcome_code_a(
		bool(result.get("is_correct", false)),
		wrong_bucket_count,
		unplaced_count,
		int(result.get("correct_count", 0))
	)
	var mastery_block_reason: String = _resolve_mastery_block_reason_a(outcome_code)
	_log_event("confirm_result", {
		"is_correct": bool(result.get("is_correct", false)),
		"score": int(result.get("points", 0)),
		"wrong_bucket_count": wrong_bucket_count,
		"unplaced_count": unplaced_count,
		"outcome_code": outcome_code
	})
	_awaiting_edit_after_feedback = true
	_awaiting_edit_after_fail = not bool(result.get("is_correct", false))
	var payload: Dictionary = TrialV2.build(
		"CASE_01_DIGITAL_RESUS",
		"A",
		str(level_data.get("id", "RESUS-A")),
		"SOCKET_REPAIR",
		str(attempt_index)
	)
	var snapshot_a: Dictionary = {
		"placements": placements.duplicate(true),
		"system_state": system_state.duplicate(true),
		"hid_connected": hid_connected,
		"placed_count": placed_count
	}
	payload.merge({
		"case_run_id": _case_run_id(),
		"level_id": str(level_data.get("id", "RESUS-A")),
		"format": str(level_data.get("format", "MATCHING")),
		"snapshot": snapshot_a,
		"placements": placements.duplicate(true),
		"bucket_labels": bucket_labels_runtime.duplicate(true),
		"trace": trace.duplicate(true),
		"task_session": task_session.duplicate(true),
		"trial_seq": trial_seq,
		"elapsed_ms": elapsed_ms,
		"time_to_first_action_ms": _resolve_time_to_first_action_ms(),
		"time_to_first_drag_ms": time_to_first_drag_ms,
		"time_to_first_drop_ms": time_to_first_drop_ms,
		"time_to_first_confirm_ms": time_to_first_confirm_ms,
		"time_from_last_edit_to_confirm_ms": time_from_last_edit_to_confirm_ms,
		"drag_count": drag_count,
		"drag_start_count": drag_start_count,
		"drop_count": drop_count,
		"replace_count": replace_count,
		"remove_count": remove_count,
		"unique_item_count": unique_item_ids.size(),
		"bucket_switch_count": bucket_switch_count,
		"wrong_bucket_try_count": wrong_bucket_try_count,
		"reset_count": reset_count_local,
		"confirm_attempt_count": confirm_attempt_count,
		"changed_after_feedback": changed_after_feedback,
		"changed_after_fail": changed_after_fail,
		"placed_count": placed_count,
		"correct_count": int(result.get("correct_count", 0)),
		"total_items": total_items,
		"points": int(result.get("points", 0)),
		"max_points": int(result.get("max_points", 2)),
		"is_fit": bool(result.get("is_fit", false)),
		"is_correct": bool(result.get("is_correct", false)),
		"stability_delta": int(result.get("stability_delta", 0)),
		"verdict_code": str(result.get("verdict_code", "FAIL")),
		"rule_code": str(result.get("rule_code", "SCORING_RULE")),
		"outcome_code": outcome_code,
		"mastery_block_reason": mastery_block_reason,
		"errors": errors.duplicate(true),
		"system_state": system_state.duplicate(true)
	}, true)
	GlobalMetrics.register_trial(payload)
	_last_result = result.duplicate(true)
	_last_payload = payload.duplicate(true)
	_update_stability_ui()
	_show_result(result, errors)

	if bool(result.get("is_correct", false)):
		_play_sfx("relay")
	elif bool(result.get("is_fit", false)):
		_play_sfx("click")
	else:
		_play_sfx("error")

func _confirm_table() -> void:
	if _table_renderer == null or not _table_renderer.has_method("get_answers"):
		return
	var answers: Dictionary = _table_renderer.call("get_answers") as Dictionary
	var total_tasks: int = (level_data.get("tasks", []) as Array).size()
	var assigned_count: int = 0
	for chosen_v in answers.values():
		if str(chosen_v).strip_edges() != "":
			assigned_count += 1
	if assigned_count < total_tasks and not _confirm_requires_force:
		_show_incomplete_warning(assigned_count, total_tasks)
		return
	_reset_confirm_warning_state()
	input_locked = true
	btn_confirm.disabled = true

	var result: Dictionary = ResusScoring.calculate_matching_table_result(level_data, answers)
	var elapsed_ms: int = _elapsed_ms_now()
	var details: Array = (result.get("details", []) as Array).duplicate(true)
	var wrong_bucket_count: int = 0
	for detail_v in details:
		if typeof(detail_v) != TYPE_DICTIONARY:
			continue
		if not bool((detail_v as Dictionary).get("correct", false)):
			wrong_bucket_count += 1
	var unassigned_count: int = maxi(0, total_tasks - assigned_count)
	var outcome_code: String = _resolve_outcome_code_a(
		bool(result.get("is_correct", false)),
		wrong_bucket_count,
		unassigned_count,
		int(result.get("correct_count", 0))
	)
	var mastery_block_reason: String = _resolve_mastery_block_reason_a(outcome_code)
	_log_event("confirm_result", {
		"is_correct": bool(result.get("is_correct", false)),
		"score": int(result.get("points", 0)),
		"wrong_bucket_count": wrong_bucket_count,
		"unplaced_count": unassigned_count,
		"outcome_code": outcome_code
	})
	_awaiting_edit_after_feedback = true
	_awaiting_edit_after_fail = not bool(result.get("is_correct", false))
	var payload: Dictionary = TrialV2.build(
		"CASE_01_DIGITAL_RESUS",
		"A",
		str(level_data.get("id", "RESUS-A-04")),
		"MATCHING_TABLE",
		str(attempt_index)
	)
	payload.merge({
		"case_run_id": _case_run_id(),
		"level_id": str(level_data.get("id", "RESUS-A-04")),
		"format": str(level_data.get("format", "MATCHING_TABLE")),
		"snapshot": answers.duplicate(true),
		"trace": trace.duplicate(true),
		"task_session": task_session.duplicate(true),
		"trial_seq": trial_seq,
		"elapsed_ms": elapsed_ms,
		"time_to_first_action_ms": _resolve_time_to_first_action_ms(),
		"time_to_first_drag_ms": time_to_first_drag_ms,
		"time_to_first_drop_ms": time_to_first_drop_ms,
		"time_to_first_confirm_ms": time_to_first_confirm_ms,
		"time_from_last_edit_to_confirm_ms": time_from_last_edit_to_confirm_ms,
		"drag_count": drag_count,
		"drag_start_count": drag_start_count,
		"drop_count": drop_count,
		"replace_count": replace_count,
		"remove_count": remove_count,
		"unique_item_count": unique_item_ids.size(),
		"bucket_switch_count": bucket_switch_count,
		"wrong_bucket_try_count": wrong_bucket_try_count,
		"reset_count": reset_count_local,
		"confirm_attempt_count": confirm_attempt_count,
		"changed_after_feedback": changed_after_feedback,
		"changed_after_fail": changed_after_fail,
		"correct_count": int(result.get("correct_count", 0)),
		"total_items": int(result.get("total", 0)),
		"points": int(result.get("points", 0)),
		"max_points": int(result.get("max_points", 2)),
		"is_fit": bool(result.get("is_fit", false)),
		"is_correct": bool(result.get("is_correct", false)),
		"stability_delta": int(result.get("stability_delta", 0)),
		"verdict_code": str(result.get("verdict_code", "FAIL")),
		"outcome_code": outcome_code,
		"mastery_block_reason": mastery_block_reason,
		"details": details
	}, true)
	GlobalMetrics.register_trial(payload)
	_last_result = result.duplicate(true)
	_last_payload = payload.duplicate(true)
	_update_stability_ui()
	if _table_renderer.has_method("show_result"):
		_table_renderer.call("show_result", result)
	_show_result(result, [])
	_play_sfx("relay" if bool(result.get("is_correct", false)) else "error")

func on_renderer_event(event_name: String, payload: Dictionary = {}) -> void:
	match event_name:
		"step_selected":
			var item_id: String = str(payload.get("item_id", payload.get("task_id", ""))).strip_edges()
			var previous_bucket: String = str(payload.get("previous", "PILE")).strip_edges().to_upper()
			var bucket_id: String = str(payload.get("bucket_id", payload.get("config_id", "PILE"))).strip_edges().to_upper()
			if bucket_id == "":
				bucket_id = "PILE"
			if previous_bucket == "":
				previous_bucket = "PILE"
			if bucket_id == "PILE":
				if previous_bucket != "PILE":
					remove_count += 1
					_mark_edit_action()
					_log_event("item_removed", {
						"item_id": item_id,
						"from_bucket": previous_bucket
					})
			else:
				drop_count += 1
				if time_to_first_drop_ms < 0:
					time_to_first_drop_ms = _elapsed_ms_now()
				if item_id != "":
					unique_item_ids[item_id] = true
				var replaced_existing: bool = previous_bucket != "PILE" and previous_bucket != bucket_id
				if replaced_existing:
					replace_count += 1
				if previous_bucket != "PILE" and previous_bucket != bucket_id:
					bucket_switch_count += 1
				last_bucket_id = bucket_id
				_mark_edit_action()
				_log_event("item_dropped", {
					"item_id": item_id,
					"bucket_id": bucket_id,
					"replaced": replaced_existing,
					"drag_count": drag_count
				})
			_log_event("step_selected", payload)
			_reset_confirm_warning_state()
		"step_reordered":
			var from_bucket: String = str(payload.get("from", "")).strip_edges().to_upper()
			var to_bucket: String = str(payload.get("to", "")).strip_edges().to_upper()
			if from_bucket != "" and to_bucket != "" and from_bucket != to_bucket:
				bucket_switch_count += 1
			_mark_edit_action()
			_log_event("step_reordered", payload)
			_reset_confirm_warning_state()
		"toggle_changed":
			_mark_edit_action()
			_log_event("toggle_changed", payload)
			_reset_confirm_warning_state()
		"hint_opened":
			_awaiting_edit_after_feedback = true
			_log_event("hint_opened", payload)
		"inspect_opened":
			_log_event("inspect_opened", payload)
		_:
			_log_event(event_name, payload)

func _show_result(result: Dictionary, errors: Array) -> void:
	var verdict_code: String = str(result.get("verdict_code", "FAIL"))
	result_verdict_label.text = verdict_code
	result_score_label.text = "%d/%d | %d/%d" % [
		int(result.get("correct_count", 0)),
		int(result.get("total_items", result.get("total", item_nodes.size()))),
		int(result.get("points", 0)),
		int(result.get("max_points", 2))
	]
	result_stability_label.text = _tr("resus.a.result.stability", "Stability delta {n}", {"n": int(result.get("stability_delta", 0))})
	if _is_table_level():
		result_details_label.text = _build_table_result_text(result.get("details", []) as Array)
	else:
		result_details_label.text = _build_result_error_text(errors)
	for error_v in errors:
		if typeof(error_v) != TYPE_DICTIONARY:
			continue
		var error_data: Dictionary = error_v as Dictionary
		var item_id: String = str(error_data.get("item_id", ""))
		var item_node_v: Variant = item_nodes.get(item_id, null)
		if item_node_v is Node and (item_node_v as Node).has_method("reveal_correct_color"):
			(item_node_v as Node).call("reveal_correct_color")

	if verdict_code == "PERFECT":
		result_verdict_label.modulate = COLOR_OK
	elif verdict_code == "PARTIAL" or verdict_code == "GOOD":
		result_verdict_label.modulate = COLOR_WARN
	else:
		result_verdict_label.modulate = COLOR_ERR

	var can_advance: bool = bool(result.get("is_correct", false)) and (_has_next_level() or _is_flow_active())
	result_next_level_button.visible = can_advance
	result_next_level_button.text = _next_level_button_text()
	dimmer.visible = true
	result_popup.visible = true

func _next_level_button_text() -> String:
	if not _has_next_level() and _is_flow_active():
		return _tr("resus.a.btn.next_stage", "NEXT STAGE")
	return _tr("resus.a.btn.next_level", "NEXT LEVEL")

func _on_reset_pressed() -> void:
	reset_count_local += 1
	_log_event("RESET_PRESSED", {"placed_count": _count_placed(_build_placements_snapshot())})
	_log_event("reset_pressed", {"count": reset_count_local})
	_apply_retry_floor()
	_reset_attempt()
	_play_sfx("click")

func _on_retry_pressed() -> void:
	_apply_retry_floor()
	_reset_attempt()

func _apply_retry_floor() -> void:
	if GlobalMetrics.stability < 20.0:
		var previous_stability: float = float(GlobalMetrics.stability)
		GlobalMetrics.stability = 20.0
		GlobalMetrics.emit_signal("stability_changed", GlobalMetrics.stability, GlobalMetrics.stability - previous_stability)

func _on_next_level_pressed() -> void:
	if _last_result.is_empty() or not bool(_last_result.get("is_correct", false)):
		return
	if _has_next_level():
		_start_level(current_level_index + 1)
		_play_sfx("click")
		return
	if _is_flow_active():
		GlobalMetrics.record_case_stage_result("A", _build_flow_stage_summary())
		get_tree().change_scene_to_file(FLOW_SCENE_PATH)

func _on_back_pressed() -> void:
	if _is_flow_active():
		GlobalMetrics.clear_case_flow()
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _build_flow_stage_summary() -> Dictionary:
	var case_run_id: String = _case_run_id()
	var total_points: int = 0
	var total_stability_delta: int = 0
	for entry_v in GlobalMetrics.session_history:
		if typeof(entry_v) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_v as Dictionary
		if str(entry.get("quest_id", "")) != "CASE_01_DIGITAL_RESUS":
			continue
		if str(entry.get("stage", "")) != "A":
			continue
		if str(entry.get("case_run_id", "")) != case_run_id:
			continue
		total_points += int(entry.get("points", 0))
		total_stability_delta += int(entry.get("stability_delta", 0))
	return {
		"stage": "A",
		"case_run_id": case_run_id,
		"levels_completed": levels.size(),
		"last_level_id": str(level_data.get("id", "")),
		"points": total_points,
		"stability_delta": total_stability_delta,
		"completed_at_unix": Time.get_unix_time_from_system()
	}

func _set_socket_targets_for_item(item_id: String) -> void:
	var target_socket: String = _expected_socket_for_item(item_id)
	for zone in _socket_zones():
		if zone == null or not zone.has_method("set_feedback_mode"):
			continue
		var zone_id: String = str(zone.get("socket_id")).to_upper()
		if target_socket != "" and zone_id == target_socket:
			zone.call("set_feedback_mode", "target_valid")
		else:
			zone.call("set_feedback_mode", "target_invalid")

func _clear_socket_feedback() -> void:
	for zone in _socket_zones():
		if zone != null and zone.has_method("set_feedback_mode"):
			zone.call("set_feedback_mode", "neutral")

func _flash_rejected_socket(socket_id: String) -> void:
	var zone: Node = _zone_for_socket(socket_id)
	if zone != null and zone.has_method("flash_reject"):
		zone.call("flash_reject")

func _expected_socket_for_item(item_id: String) -> String:
	var item_contract_v: Variant = item_contracts.get(item_id, null)
	if item_contract_v is Dictionary:
		var item_contract: Dictionary = item_contract_v as Dictionary
		var expected_bucket_id: String = str(item_contract.get("correct_bucket_id", "")).to_upper()
		if expected_bucket_id != "":
			return expected_bucket_id

	var socket_map: Dictionary = level_data.get("socket_map", {}) as Dictionary
	for socket_id_v in socket_map.keys():
		var socket_id: String = str(socket_id_v).to_upper()
		var accepted_ids: Array[String] = _string_array(socket_map.get(socket_id, []))
		if accepted_ids.has(item_id):
			return socket_id
	return ""

func _bounce_node(node: Control) -> void:
	var tween: Tween = create_tween()
	node.scale = Vector2(1.12, 1.12)
	tween.tween_property(node, "scale", Vector2.ONE, 0.2)

func _socket_zones() -> Array:
	return [zone_input, zone_output, zone_memory]

func _zone_for_socket(socket_id: String) -> Node:
	var normalized_socket_id: String = socket_id.to_upper()
	var dynamic_zone_v: Variant = bucket_to_zone.get(normalized_socket_id, null)
	if dynamic_zone_v is Node:
		return dynamic_zone_v as Node
	match normalized_socket_id:
		"INPUT":
			return zone_input
		"OUTPUT":
			return zone_output
		"MEMORY":
			return zone_memory
		_:
			return null

func _bucket_label_map(buckets: Array) -> Dictionary:
	var out: Dictionary = {}
	for bucket_v in buckets:
		if typeof(bucket_v) != TYPE_DICTIONARY:
			continue
		var bucket: Dictionary = bucket_v as Dictionary
		var bucket_id: String = str(bucket.get("bucket_id", "")).to_upper()
		if bucket_id != "":
			out[bucket_id] = I18n.resolve_field(bucket, "label", {"default": bucket_id})
	return out

func _bucket_ids(buckets: Array) -> Array[String]:
	var out: Array[String] = []
	for bucket_v in buckets:
		if typeof(bucket_v) != TYPE_DICTIONARY:
			continue
		var bucket: Dictionary = bucket_v as Dictionary
		var bucket_id: String = str(bucket.get("bucket_id", "")).to_upper()
		if bucket_id != "" and not out.has(bucket_id):
			out.append(bucket_id)
	return out

func _item_contract_map(items: Array) -> Dictionary:
	var out: Dictionary = {}
	for item_v in items:
		if typeof(item_v) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = item_v as Dictionary
		var item_id: String = str(item.get("item_id", ""))
		if item_id != "":
			out[item_id] = item
	return out

func _accepted_item_ids_for_bucket(bucket_id: String) -> Array[String]:
	var out: Array[String] = []
	var normalized_bucket: String = bucket_id.to_upper()
	var known_item_ids: Dictionary = {}
	for item_v in level_data.get("items", []) as Array:
		if typeof(item_v) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = item_v as Dictionary
		var item_id: String = str(item.get("item_id", ""))
		if item_id == "":
			continue
		known_item_ids[item_id] = true
		if str(item.get("correct_bucket_id", "")).to_upper() == normalized_bucket and not out.has(item_id):
			out.append(item_id)
	var socket_map: Dictionary = level_data.get("socket_map", {}) as Dictionary
	for mapped_id in _string_array(socket_map.get(normalized_bucket, [])):
		if known_item_ids.has(mapped_id) and not out.has(mapped_id):
			out.append(mapped_id)
	return out

func _bucket_label(bucket_id: String) -> String:
	var normalized_bucket: String = bucket_id.to_upper()
	if normalized_bucket == "PILE":
		return _tr("resus.a.labels.pile_default", "PARTS")
	return str(bucket_labels_runtime.get(normalized_bucket, normalized_bucket))

func _is_cia_level() -> bool:
	return str(level_data.get("format", "")).to_upper() == "MATCHING_CIA"

func _is_table_level() -> bool:
	return str(level_data.get("format", "")).to_upper() == "MATCHING_TABLE"

func _build_errors(placements: Dictionary) -> Array:
	var errors: Array = []
	for item_v in level_data.get("items", []) as Array:
		if typeof(item_v) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = item_v as Dictionary
		var item_id: String = str(item.get("item_id", ""))
		if item_id == "":
			continue
		var chosen_bucket: String = str(placements.get(item_id, "PILE")).to_upper()
		var correct_bucket: String = str(item.get("correct_bucket_id", "")).to_upper()
		if chosen_bucket == correct_bucket:
			continue
		errors.append({
			"item_id": item_id,
			"chosen": chosen_bucket,
			"correct": correct_bucket,
			"explain_short": str(item.get("explain_short", "")),
			"explain_short_key": str(item.get("explain_short_key", ""))
		})
	return errors

func _build_result_error_text(errors: Array) -> String:
	if errors.is_empty():
		return _tr("resus.a.result.no_errors", "No placement errors detected.")
	var lines: Array[String] = []
	for error_v in errors:
		if typeof(error_v) != TYPE_DICTIONARY:
			continue
		var error_data: Dictionary = error_v as Dictionary
		var item_id: String = str(error_data.get("item_id", ""))
		lines.append(_tr("resus.a.result.error_line", "{item} -> chose {chosen}, expected {correct}", {
			"item": _item_display_name(item_id),
			"chosen": _bucket_label(str(error_data.get("chosen", "PILE"))),
			"correct": _bucket_label(str(error_data.get("correct", "")))
		}))
		var explain_key: String = str(error_data.get("explain_short_key", ""))
		var explain_fallback: String = str(error_data.get("explain_short", ""))
		var explain_text: String = ""
		if explain_key != "":
			explain_text = I18n.tr_key(explain_key, {"default": explain_fallback})
		elif explain_fallback != "":
			explain_text = explain_fallback
		explain_text = explain_text.strip_edges()
		if explain_text != "":
			lines.append("  -> " + explain_text)
		lines.append("")
	return "\n".join(lines)

func _build_table_result_text(details: Array) -> String:
	if details.is_empty():
		return _tr("resus.a.result.no_errors", "No placement errors detected.")
	var lines: Array[String] = []
	for detail_v in details:
		if typeof(detail_v) != TYPE_DICTIONARY:
			continue
		var detail: Dictionary = detail_v as Dictionary
		var task_id: String = str(detail.get("task_id", "")).strip_edges()
		if task_id == "":
			continue
		var expected: String = str(detail.get("expected", "")).strip_edges()
		var given: String = str(detail.get("given", "")).strip_edges()
		var task_text: String = task_id
		for task_v in level_data.get("tasks", []) as Array:
			if typeof(task_v) != TYPE_DICTIONARY:
				continue
			var task_data: Dictionary = task_v as Dictionary
			if str(task_data.get("task_id", "")).strip_edges() != task_id:
				continue
			task_text = I18n.resolve_field(task_data, "label", {"default": task_id})
			break
		var ok: bool = bool(detail.get("correct", false))
		if ok:
			lines.append(_tr("resus.a04.result.line_ok", "{task}: OK ({cfg})", {
				"task": task_text,
				"cfg": expected
			}))
		else:
			lines.append(_tr("resus.a04.result.line_fail", "{task}: chose {given}, expected {expected}", {
				"task": task_text,
				"given": given if given != "" else _tr("resus.ui.unassigned", "UNASSIGNED"),
				"expected": expected
			}))
			var explain_key: String = str(detail.get("explain_key", "")).strip_edges()
			if explain_key != "":
				var explain_text: String = I18n.tr_key(explain_key, {"default": ""}).strip_edges()
				if explain_text != "":
					lines.append("  -> " + explain_text)
	return "\n".join(lines)

func _item_display_name(item_id: String) -> String:
	var contract: Variant = item_contracts.get(item_id, null)
	if contract is Dictionary:
		var contract_data: Dictionary = contract as Dictionary
		var label_key: String = str(contract_data.get("label_key", ""))
		var label_fallback: String = str(contract_data.get("label", item_id))
		if label_key != "":
			return I18n.tr_key(label_key, {"default": label_fallback})
		return label_fallback
	return item_id

func _string_array(values: Variant) -> Array[String]:
	var out: Array[String] = []
	if typeof(values) != TYPE_ARRAY:
		return out
	for value_v in values as Array:
		out.append(str(value_v))
	return out

func _elapsed_ms_now() -> int:
	return maxi(0, Time.get_ticks_msec() - start_time_ms)

func _resolve_time_to_first_action_ms() -> int:
	var candidates: Array[int] = []
	if time_to_first_drag_ms >= 0:
		candidates.append(time_to_first_drag_ms)
	if time_to_first_drop_ms >= 0:
		candidates.append(time_to_first_drop_ms)
	if time_to_first_confirm_ms >= 0:
		candidates.append(time_to_first_confirm_ms)
	if candidates.is_empty():
		return -1
	var min_value: int = candidates[0]
	for value in candidates:
		min_value = mini(min_value, value)
	return min_value

func _resolve_outcome_code_a(is_correct: bool, wrong_bucket_count: int, unplaced_count: int, correct_count: int) -> String:
	if is_correct:
		return "SUCCESS"
	if reset_count_local >= 3:
		return "RESET_OVERUSE"
	if unplaced_count > 0:
		return "INCOMPLETE_SORT"
	if wrong_bucket_count > 0 and correct_count > 0:
		return "PARTIAL_MATCH"
	if wrong_bucket_count > 0:
		return "WRONG_BUCKET"
	return "PARTIAL_MATCH"

func _resolve_mastery_block_reason_a(outcome_code: String) -> String:
	if outcome_code == "SUCCESS":
		return "NONE"
	if confirm_attempt_count >= 3:
		return "MULTI_CONFIRM_GUESSING"
	if changed_after_feedback:
		return "FEEDBACK_DEPENDENCY"
	if drag_start_count >= max(10, item_contracts.size() * 3):
		return "EXCESSIVE_REDRAG"
	if wrong_bucket_try_count > 0:
		return "BUCKET_CONFUSION"
	return "NONE"

func _log_event(event_name: String, data: Dictionary = {}) -> void:
	var elapsed: int = _elapsed_ms_now()
	var safe_payload: Dictionary = data.duplicate(true)
	trace.append({
		"t_ms": elapsed,
		"event": event_name,
		"data": safe_payload
	})
	var events: Array = task_session.get("events", []) as Array
	events.append({
		"name": event_name,
		"t_ms": elapsed,
		"payload": safe_payload
	})
	task_session["events"] = events

func _play_sfx(event_name: String) -> void:
	if has_node("/root/AudioManager"):
		AudioManager.play(event_name)

func _on_stability_changed(_new_value: float, _delta: float) -> void:
	_update_stability_ui()

func _update_stability_ui() -> void:
	stability_bar.value = GlobalMetrics.stability
	if noir_overlay != null and noir_overlay.has_method("set_danger_level"):
		noir_overlay.call("set_danger_level", float(GlobalMetrics.stability))

func _show_error(message: String) -> void:
	status_label.text = message
	status_label.modulate = COLOR_ERR
	btn_confirm.disabled = true

func _show_socket_error(message: String) -> void:
	status_label.text = message
	status_label.modulate = COLOR_ERR

func _setup_collapsible_briefing() -> void:
	if briefing_card == null or briefing_label == null:
		return
	if briefing_label.get_parent() == briefing_card:
		var wrapper: VBoxContainer = VBoxContainer.new()
		wrapper.name = "BriefingVBox"
		wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		wrapper.add_theme_constant_override("separation", 6)
		var top_row: HBoxContainer = HBoxContainer.new()
		top_row.add_theme_constant_override("separation", 8)
		var title: Label = Label.new()
		title.text = _tr("resus.a.labels.briefing_title", "BRIEFING")
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top_row.add_child(title)
		_briefing_toggle_button = Button.new()
		_briefing_toggle_button.name = "BriefingToggleButton"
		_briefing_toggle_button.text = "?"
		_briefing_toggle_button.custom_minimum_size = Vector2(40.0, 36.0)
		_briefing_toggle_button.pressed.connect(_on_briefing_toggle_pressed)
		top_row.add_child(_briefing_toggle_button)
		briefing_card.remove_child(briefing_label)
		wrapper.add_child(top_row)
		wrapper.add_child(briefing_label)
		briefing_card.add_child(wrapper)
	_apply_briefing_state()

func _on_briefing_toggle_pressed() -> void:
	_briefing_collapsed = not _briefing_collapsed
	_apply_briefing_state()

func _apply_briefing_state() -> void:
	if briefing_label == null:
		return
	briefing_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	briefing_label.max_lines_visible = 2 if _briefing_collapsed else 0
	if _briefing_toggle_button != null:
		_briefing_toggle_button.text = "?" if _briefing_collapsed else "x"

func _on_viewport_size_changed() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var is_landscape: bool = viewport_size.x >= viewport_size.y
	var phone_landscape: bool = is_landscape and viewport_size.y <= PHONE_LANDSCAPE_MAX_HEIGHT
	var phone_portrait: bool = (not is_landscape) and viewport_size.x <= PHONE_PORTRAIT_MAX_WIDTH
	var compact: bool = phone_landscape or phone_portrait

	_apply_safe_area_padding(compact)
	main_vbox.add_theme_constant_override("separation", 8 if compact else 10)
	content_vbox.add_theme_constant_override("separation", 8 if compact else 10)
	header.add_theme_constant_override("separation", 8 if compact else 10)
	bottom_bar.add_theme_constant_override("separation", 8 if compact else 10)
	stability_bar.custom_minimum_size.x = 160.0 if compact else 220.0
	btn_back.custom_minimum_size = Vector2(56.0 if compact else 72.0, 56.0 if compact else 72.0)
	btn_reset.custom_minimum_size = Vector2(120.0 if compact else 160.0, 60.0 if compact else 72.0)
	btn_confirm.custom_minimum_size = Vector2(140.0 if compact else 180.0, 60.0 if compact else 72.0)
	status_label.custom_minimum_size.y = 56.0 if compact else 72.0
	parts_grid.columns = 1 if phone_portrait else 2

	var popup_width: float = clampf(viewport_size.x - (24.0 if compact else 120.0), 320.0, 520.0)
	var popup_height: float = clampf(viewport_size.y - (24.0 if compact else 120.0), 320.0, 620.0)
	result_popup.offset_left = -popup_width * 0.5
	result_popup.offset_top = -popup_height * 0.5
	result_popup.offset_right = popup_width * 0.5
	result_popup.offset_bottom = popup_height * 0.5
	if _bucket_popup != null and _bucket_popup.visible:
		_bucket_popup.position = (viewport_size - _bucket_popup.size) * 0.5

func _apply_safe_area_padding(compact: bool) -> void:
	var left: float = 8.0 if compact else 16.0
	var top: float = 8.0 if compact else 12.0
	var right: float = 8.0 if compact else 16.0
	var bottom: float = 8.0 if compact else 12.0
	var safe_rect: Rect2i = DisplayServer.get_display_safe_area()
	if safe_rect.size.x > 0 and safe_rect.size.y > 0:
		var viewport_size: Vector2 = get_viewport_rect().size
		left = maxf(left, float(safe_rect.position.x))
		top = maxf(top, float(safe_rect.position.y))
		right = maxf(right, viewport_size.x - float(safe_rect.position.x + safe_rect.size.x))
		bottom = maxf(bottom, viewport_size.y - float(safe_rect.position.y + safe_rect.size.y))
	safe_area.add_theme_constant_override("margin_left", int(round(left)))
	safe_area.add_theme_constant_override("margin_top", int(round(top)))
	safe_area.add_theme_constant_override("margin_right", int(round(right)))
	safe_area.add_theme_constant_override("margin_bottom", int(round(bottom)))

func _has_next_level() -> bool:
	return current_level_index < levels.size() - 1

func _is_flow_active() -> bool:
	var flow: Dictionary = GlobalMetrics.get_case_flow()
	return bool(flow.get("is_active", false)) and str(flow.get("case_id", "")) == "CASE_01_DIGITAL_RESUS"

func _case_run_id() -> String:
	var flow: Dictionary = GlobalMetrics.get_case_flow()
	return str(flow.get("case_run_id", ""))
