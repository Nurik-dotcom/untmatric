extends Control

const LAYOUT_CASCADE_TOP := "CASCADE_TOP" # (A op B) op C
const LAYOUT_CASCADE_BOTTOM := "CASCADE_BOTTOM" # A op (B op C)

const GATE_NONE := "NONE"
const GATE_AND := "AND"
const GATE_OR := "OR"
const GATE_NOT := "NOT"
const GATE_XOR := "XOR"
const GATE_NAND := "NAND"
const GATE_NOR := "NOR"

const MAX_ATTEMPTS := 3
const ANALYZE_COOLDOWN_SEC := 4.0

const DIAG_NONE := ""
const DIAG_NEXT := "NEXT_CASE"
const DIAG_EXIT := "EXIT_QUEST_SELECT"

const ACTION_HINT := "HINT"
const ACTION_TEST := "TEST"
const ACTION_NEXT := "NEXT"

enum UiState {
	STATE_EMPTY,
	STATE_SELECT_FIRST_SLOT,
	STATE_FILL_FIRST_SLOT,
	STATE_SELECT_SECOND_SLOT,
	STATE_FILL_SECOND_SLOT,
	STATE_READY_FOR_TEST,
	STATE_TEST_FAILED,
	STATE_SOLVED,
	STATE_SAFE_MODE
}

const COLOR_STATE_DEFAULT := Color(1.0, 1.0, 1.0, 1.0)
const COLOR_STATE_ACTIVE := Color(1.0, 0.95, 0.86, 1.0)
const COLOR_STATE_FILLED := Color(0.86, 0.93, 1.0, 1.0)
const COLOR_STATE_DISABLED := Color(0.70, 0.70, 0.72, 1.0)
const COLOR_STATE_SUCCESS := Color(0.82, 0.98, 0.88, 1.0)
const COLOR_STATE_ERROR := Color(1.0, 0.83, 0.83, 1.0)
const COLOR_STATE_SAFE := Color(0.96, 0.90, 0.78, 1.0)

const COLOR_TEXT_MAIN := Color(0.95, 0.95, 0.90, 1.0)
const COLOR_TEXT_MUTED := Color(0.68, 0.68, 0.70, 1.0)
const COLOR_TEXT_SUCCESS := Color(0.45, 0.92, 0.62, 1.0)
const COLOR_TEXT_ERROR := Color(1.0, 0.35, 0.32, 1.0)
const COLOR_TEXT_WARNING := Color(1.0, 0.78, 0.32, 1.0)
const COLOR_TEXT_INFO := Color(0.56, 0.78, 0.96, 1.0)

const CASES := [
	{
		"id": "B_01",
		"layout": LAYOUT_CASCADE_TOP,
		"story": "Соберите двухэтапную схему: сначала узел A/B, затем результат с C.",
		"labels": ["ДАТЧИК A", "ДАТЧИК B", "ДАТЧИК C"],
		"correct_gates": [GATE_OR, GATE_AND],
		"hint": "Для CASCADE_TOP сначала сопоставьте A и B, затем объедините INTER с C."
	},
	{
		"id": "B_02",
		"layout": LAYOUT_CASCADE_BOTTOM,
		"story": "Схема перестроена: сначала обрабатывается пара B/C, затем подключается A.",
		"labels": ["КЛЮЧ A", "КЛЮЧ B", "КЛЮЧ C"],
		"correct_gates": [GATE_AND, GATE_OR],
		"hint": "Для CASCADE_BOTTOM внутренний этап работает на B/C, внешний - на A и INTER."
	},
	{
		"id": "B_03",
		"layout": LAYOUT_CASCADE_TOP,
		"story": "Нужен канал, где первый этап ловит различие A/B, а второй фильтрует через C.",
		"labels": ["КАНАЛ A", "КАНАЛ B", "ФИЛЬТР C"],
		"correct_gates": [GATE_XOR, GATE_AND],
		"hint": "Если в первом этапе важна разница сигналов A/B, проверьте XOR."
	},
	{
		"id": "B_04",
		"layout": LAYOUT_CASCADE_BOTTOM,
		"story": "Схема с инверсией: сначала инвертируется B/C, затем объединяется с A.",
		"labels": ["ОПОРНЫЙ A", "ШУМ B", "ШУМ C"],
		"correct_gates": [GATE_NOR, GATE_OR],
		"hint": "При CASCADE_BOTTOM внимательно разделяйте внутренний и внешний этапы."
	},
	{
		"id": "B_05",
		"layout": LAYOUT_CASCADE_TOP,
		"story": "Соберите устойчивый тракт с финальным отрицанием совпадения.",
		"labels": ["ЛИНИЯ A", "ЛИНИЯ B", "ЛИНИЯ C"],
		"correct_gates": [GATE_AND, GATE_NAND],
		"hint": "Сначала оцените пару A/B, затем проверьте реакцию второго этапа на C."
	}
]

@onready var clue_title_label: Label = $SafeArea/MainLayout/Header/LblClueTitle
@onready var session_label: Label = $SafeArea/MainLayout/Header/LblSessionId
@onready var btn_back: Button = $SafeArea/MainLayout/Header/BtnBack

@onready var facts_bar_label: Label = $SafeArea/MainLayout/BarsRow/FactsBarLabel
@onready var facts_bar: ProgressBar = $SafeArea/MainLayout/BarsRow/FactsBar
@onready var energy_bar_label: Label = $SafeArea/MainLayout/BarsRow/EnergyBarLabel
@onready var energy_bar: ProgressBar = $SafeArea/MainLayout/BarsRow/EnergyBar

@onready var target_label: Label = $SafeArea/MainLayout/TargetDisplay/LblTarget
@onready var scheme_panel: PanelContainer = $SafeArea/MainLayout/SchemePanel
@onready var scheme_label: Label = $SafeArea/MainLayout/SchemePanel/LblScheme
@onready var validation_panel: PanelContainer = $SafeArea/MainLayout/ValidationPanel
@onready var validation_mode_label: Label = $SafeArea/MainLayout/ValidationPanel/LblValidationMode

@onready var terminal_frame: PanelContainer = $SafeArea/MainLayout/TerminalFrame
@onready var terminal_text: RichTextLabel = $SafeArea/MainLayout/TerminalFrame/TerminalScroll/TerminalRichText

@onready var interaction_row: GridContainer = $SafeArea/MainLayout/InteractionRow
@onready var actions_container: BoxContainer = $SafeArea/MainLayout/Actions
@onready var status_row: BoxContainer = $SafeArea/MainLayout/StatusRow
@onready var gates_container: GridContainer = $SafeArea/MainLayout/InventoryFrame/InventoryMargin/InventoryScroll/GatesContainer

@onready var input_a_frame: PanelContainer = $SafeArea/MainLayout/InteractionRow/InputAFrame
@onready var input_b_frame: PanelContainer = $SafeArea/MainLayout/InteractionRow/InputBFrame
@onready var input_c_frame: PanelContainer = $SafeArea/MainLayout/InteractionRow/InputCFrame
@onready var slot1_frame: PanelContainer = $SafeArea/MainLayout/InteractionRow/Slot1Frame
@onready var slot2_frame: PanelContainer = $SafeArea/MainLayout/InteractionRow/Slot2Frame
@onready var inter_frame: PanelContainer = $SafeArea/MainLayout/InteractionRow/InterSlot
@onready var output_frame: PanelContainer = $SafeArea/MainLayout/InteractionRow/OutputSlot
@onready var inventory_frame: PanelContainer = $SafeArea/MainLayout/InventoryFrame

@onready var input_a_title_label: Label = $SafeArea/MainLayout/InteractionRow/InputAFrame/InputAVBox/InputATitle
@onready var input_b_title_label: Label = $SafeArea/MainLayout/InteractionRow/InputBFrame/InputBVBox/InputBTitle
@onready var input_c_title_label: Label = $SafeArea/MainLayout/InteractionRow/InputCFrame/InputCVBox/InputCTitle
@onready var slot1_title_label: Label = $SafeArea/MainLayout/InteractionRow/Slot1Frame/Slot1VBox/Slot1Title
@onready var slot2_title_label: Label = $SafeArea/MainLayout/InteractionRow/Slot2Frame/Slot2VBox/Slot2Title
@onready var inter_title_label: Label = $SafeArea/MainLayout/InteractionRow/InterSlot/InterVBox/InterTitle
@onready var output_title_label: Label = $SafeArea/MainLayout/InteractionRow/OutputSlot/OutputVBox/OutputTitle

@onready var input_a_btn: Button = $SafeArea/MainLayout/InteractionRow/InputAFrame/InputAVBox/InputA_Btn
@onready var input_b_btn: Button = $SafeArea/MainLayout/InteractionRow/InputBFrame/InputBVBox/InputB_Btn
@onready var input_c_btn: Button = $SafeArea/MainLayout/InteractionRow/InputCFrame/InputCVBox/InputC_Btn
@onready var slot1_btn: Button = $SafeArea/MainLayout/InteractionRow/Slot1Frame/Slot1VBox/Slot1SelectBtn
@onready var slot2_btn: Button = $SafeArea/MainLayout/InteractionRow/Slot2Frame/Slot2VBox/Slot2SelectBtn
@onready var inter_value_label: Label = $SafeArea/MainLayout/InteractionRow/InterSlot/InterVBox/InterValueLabel
@onready var inter_hint_label: Label = $SafeArea/MainLayout/InteractionRow/InterSlot/InterVBox/InterHintLabel
@onready var output_value_label: Label = $SafeArea/MainLayout/InteractionRow/OutputSlot/OutputVBox/OutputValueLabel
@onready var output_hint_label: Label = $SafeArea/MainLayout/InteractionRow/OutputSlot/OutputVBox/OutputHintLabel

@onready var gate_and_btn: Button = $SafeArea/MainLayout/InventoryFrame/InventoryMargin/InventoryScroll/GatesContainer/GateAndBtn
@onready var gate_or_btn: Button = $SafeArea/MainLayout/InventoryFrame/InventoryMargin/InventoryScroll/GatesContainer/GateOrBtn
@onready var gate_xor_btn: Button = $SafeArea/MainLayout/InventoryFrame/InventoryMargin/InventoryScroll/GatesContainer/GateXorBtn
@onready var gate_nand_btn: Button = $SafeArea/MainLayout/InventoryFrame/InventoryMargin/InventoryScroll/GatesContainer/GateNandBtn
@onready var gate_nor_btn: Button = $SafeArea/MainLayout/InventoryFrame/InventoryMargin/InventoryScroll/GatesContainer/GateNorBtn
@onready var gate_not_btn: Button = $SafeArea/MainLayout/InventoryFrame/InventoryMargin/InventoryScroll/GatesContainer/GateNotBtn

@onready var stats_label: Label = $SafeArea/MainLayout/StatusRow/StatsLabel
@onready var feedback_label: Label = $SafeArea/MainLayout/StatusRow/FeedbackLabel

@onready var btn_hint: Button = $SafeArea/MainLayout/Actions/BtnHint
@onready var btn_test: Button = $SafeArea/MainLayout/Actions/BtnTest
@onready var btn_next: Button = $SafeArea/MainLayout/Actions/BtnNext

@onready var diagnostics_blocker: ColorRect = $DiagnosticsBlocker
@onready var diagnostics_panel: PanelContainer = $DiagnosticsPanelB
@onready var diagnostics_title: Label = $DiagnosticsPanelB/PopupMargin/PopupVBox/PopupTitle
@onready var diagnostics_text: RichTextLabel = $DiagnosticsPanelB/PopupMargin/PopupVBox/PopupText
@onready var diagnostics_next_button: Button = $DiagnosticsPanelB/PopupMargin/PopupVBox/PopupBtnNext
@onready var click_player: AudioStreamPlayer = $ClickPlayer

var current_case_idx: int = 0
var current_case: Dictionary = {}
var _intro_briefing_shown: bool = false

var inputs: Array[bool] = [false, false, false]
var placed_gates: Array[String] = [GATE_NONE, GATE_NONE]
var selected_slot_idx: int = -1

var attempts: int = 0
var hints_used: int = 0
var test_count: int = 0
var analyze_count: int = 0
var is_complete: bool = false
var is_safe_mode: bool = false
var case_started_ms: int = 0
var first_action_ms: int = -1
var _last_stability_penalty: float = 0.0
var _body_scroll_installed: bool = false
var trial_seq: int = 0
var task_session: Dictionary = {}

var slot_select_count: int = 0
var slot_switch_count: int = 0
var gate_place_count: int = 0
var gate_replace_count: int = 0
var gate_clear_count: int = 0
var input_toggle_count: int = 0

var counterexample_seen_count: int = 0
var changed_after_counterexample: bool = false
var changed_after_analyze: bool = false
var test_without_full_assembly_count: int = 0

var time_to_first_slot_select_ms: int = -1
var time_to_first_test_ms: int = -1
var time_from_last_edit_to_test_ms: int = -1
var last_edit_ms: int = -1
var first_test_was_incomplete: bool = false

var trace_lines: Array[String] = []
var vector_cache: Array[Dictionary] = []
var last_counterexample: Dictionary = {}

var gate_buttons: Dictionary = {}
var analyze_timer: Timer = null
var diagnostics_action: String = DIAG_NONE
var is_landscape_layout: bool = true

func _tr(key: String, default_text: String, params: Dictionary = {}) -> String:
	var merged := params.duplicate(true)
	merged["default"] = default_text
	return I18n.tr_key(key, merged)

func _ready() -> void:
	_connect_ui_signals()
	_setup_gate_buttons()

	_update_stability_ui(GlobalMetrics.stability, 0.0)
	if not GlobalMetrics.stability_changed.is_connected(_update_stability_ui):
		GlobalMetrics.stability_changed.connect(_update_stability_ui)
	if not GlobalMetrics.game_over.is_connected(_on_game_over):
		GlobalMetrics.game_over.connect(_on_game_over)
	if not get_viewport().size_changed.is_connected(_on_viewport_resized):
		get_viewport().size_changed.connect(_on_viewport_resized)
	if not I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.connect(_on_language_changed)

	analyze_timer = Timer.new()
	analyze_timer.one_shot = true
	analyze_timer.timeout.connect(_on_analyze_unlock)
	add_child(analyze_timer)

	_apply_i18n_static()
	_install_body_scroll()
	_apply_responsive_layout()
	load_case(0)

func _exit_tree() -> void:
	if GlobalMetrics.stability_changed.is_connected(_update_stability_ui):
		GlobalMetrics.stability_changed.disconnect(_update_stability_ui)
	if GlobalMetrics.game_over.is_connected(_on_game_over):
		GlobalMetrics.game_over.disconnect(_on_game_over)
	if get_viewport() and get_viewport().size_changed.is_connected(_on_viewport_resized):
		get_viewport().size_changed.disconnect(_on_viewport_resized)
	if I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.disconnect(_on_language_changed)

func _connect_ui_signals() -> void:
	if not btn_back.pressed.is_connected(_on_back_button_pressed):
		btn_back.pressed.connect(_on_back_button_pressed)

	if not input_a_btn.toggled.is_connected(_on_input_a_toggled):
		input_a_btn.toggled.connect(_on_input_a_toggled)
	if not input_b_btn.toggled.is_connected(_on_input_b_toggled):
		input_b_btn.toggled.connect(_on_input_b_toggled)
	if not input_c_btn.toggled.is_connected(_on_input_c_toggled):
		input_c_btn.toggled.connect(_on_input_c_toggled)

	if not slot1_btn.pressed.is_connected(_on_slot1_pressed):
		slot1_btn.pressed.connect(_on_slot1_pressed)
	if not slot2_btn.pressed.is_connected(_on_slot2_pressed):
		slot2_btn.pressed.connect(_on_slot2_pressed)

	if not btn_hint.pressed.is_connected(_on_hint_pressed):
		btn_hint.pressed.connect(_on_hint_pressed)
	if not btn_test.pressed.is_connected(_on_test_pressed):
		btn_test.pressed.connect(_on_test_pressed)
	if not btn_next.pressed.is_connected(_on_next_button_pressed):
		btn_next.pressed.connect(_on_next_button_pressed)

	if not diagnostics_next_button.pressed.is_connected(_on_diagnostics_close_pressed):
		diagnostics_next_button.pressed.connect(_on_diagnostics_close_pressed)

func _setup_gate_buttons() -> void:
	gate_buttons = {
		GATE_AND: gate_and_btn,
		GATE_OR: gate_or_btn,
		GATE_XOR: gate_xor_btn,
		GATE_NAND: gate_nand_btn,
		GATE_NOR: gate_nor_btn
	}

	for gate_id in gate_buttons.keys():
		var gate_btn: Button = gate_buttons[gate_id]
		var call := Callable(self, "_on_gate_button_toggled").bind(gate_id)
		if not gate_btn.toggled.is_connected(call):
			gate_btn.toggled.connect(call)

	gate_not_btn.visible = false
	gate_not_btn.disabled = true
	_clear_gate_button_presses()

func _on_language_changed() -> void:
	_apply_i18n_static()
	_refresh_case_labels()
	_update_outputs()
	_update_terminal()
	_update_ui_state()

func _apply_i18n_static() -> void:
	clue_title_label.text = _tr("logic.b.ui.title", "ДЕТЕКТОР ЛЖИ")
	btn_back.text = _tr("logic.common.back", "НАЗАД")

	facts_bar_label.text = _tr("logic.b.ui.assembly_bar", "СБОРКА")
	energy_bar_label.text = _tr("logic.b.ui.stability_bar", "СТАБИЛЬНОСТЬ")

	slot1_title_label.text = _tr("logic.b.ui.slot1_title", "СЛОТ 1 · ЭТАП 1")
	slot2_title_label.text = _tr("logic.b.ui.slot2_title", "СЛОТ 2 · ЭТАП 2")
	inter_title_label.text = _tr("logic.b.ui.inter_title", "ПРОМЕЖУТОЧНЫЙ")
	output_title_label.text = _tr("logic.b.ui.output_title", "ВЫХОД")

	btn_hint.text = _tr("logic.b.ui.analyze_btn", "АНАЛИЗ")
	btn_test.text = _tr("logic.b.ui.test_btn", "ПРОВЕРИТЬ")
	btn_next.text = _tr("logic.common.next", "ДАЛЕЕ")

	validation_mode_label.text = _tr(
		"logic.b.ui.validation_note",
		"Текущие A/B/C показывают локальную симуляцию. Кнопка «ПРОВЕРИТЬ» запускает полную сверку по всем 8 комбинациям."
	)

func _on_viewport_resized() -> void:
	_apply_responsive_layout()

func _install_body_scroll() -> void:
	if _body_scroll_installed:
		return
	var main_layout: VBoxContainer = $SafeArea/MainLayout
	var header: HBoxContainer = $SafeArea/MainLayout/Header
	var actions: BoxContainer = $SafeArea/MainLayout/Actions
	var middle_nodes: Array[Node] = []
	var collecting: bool = false
	for child in main_layout.get_children():
		if child == header:
			collecting = true
			continue
		if child == actions:
			collecting = false
			continue
		if collecting:
			middle_nodes.append(child)
	if middle_nodes.is_empty():
		return
	var scroll := ScrollContainer.new()
	scroll.name = "BodyScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.follow_focus = true
	var body_content := VBoxContainer.new()
	body_content.name = "BodyContent"
	body_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_content.add_theme_constant_override("separation", 6)
	for node in middle_nodes:
		node.reparent(body_content)
		(node as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body_content)
	main_layout.add_child(scroll)
	main_layout.move_child(scroll, 1)
	_body_scroll_installed = true

func _apply_responsive_layout() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var landscape := viewport_size.x >= viewport_size.y
	var narrow := viewport_size.x < 980.0
	var very_narrow := viewport_size.x < 700.0
	var compact: bool = (landscape and viewport_size.y <= 420.0) or ((not landscape) and viewport_size.x <= 500.0)

	is_landscape_layout = landscape
	if landscape:
		terminal_frame.custom_minimum_size = Vector2(0, 260)
		terminal_frame.size_flags_vertical = 3
		interaction_row.columns = 7 if viewport_size.x >= 1550.0 else 4
		gates_container.columns = 5 if viewport_size.x >= 1550.0 else 3
		actions_container.vertical = false
		status_row.vertical = false
		inventory_frame.size_flags_stretch_ratio = 0.45
	else:
		terminal_frame.custom_minimum_size = Vector2(0, 170)
		terminal_frame.size_flags_vertical = 0
		interaction_row.columns = 2 if very_narrow else 3
		gates_container.columns = 2 if very_narrow else 3
		actions_container.vertical = true
		status_row.vertical = true
		inventory_frame.size_flags_stretch_ratio = 0.65
	if compact:
		terminal_text.add_theme_font_size_override("normal_font_size", 14)
		terminal_frame.custom_minimum_size = Vector2(0, 120)
		inventory_frame.custom_minimum_size = Vector2(0, 80)
		scheme_panel.custom_minimum_size.y = 44.0
		validation_panel.custom_minimum_size.y = 44.0
		for frame in [input_a_frame, input_b_frame, input_c_frame, slot1_frame, slot2_frame, inter_frame, output_frame]:
			(frame as PanelContainer).custom_minimum_size.y = 64.0
	elif landscape:
		terminal_text.add_theme_font_size_override("normal_font_size", 18 if narrow else 20)
		terminal_frame.custom_minimum_size = Vector2(0, 260)
		inventory_frame.custom_minimum_size = Vector2(0, 140)
		scheme_panel.custom_minimum_size.y = 80.0
		validation_panel.custom_minimum_size.y = 80.0
		for frame in [input_a_frame, input_b_frame, input_c_frame, slot1_frame, slot2_frame, inter_frame, output_frame]:
			(frame as PanelContainer).custom_minimum_size.y = 96.0
	else:
		terminal_text.add_theme_font_size_override("normal_font_size", 17 if very_narrow else 18)
		terminal_frame.custom_minimum_size = Vector2(0, 170)
		inventory_frame.custom_minimum_size = Vector2(0, 140)
		scheme_panel.custom_minimum_size.y = 80.0
		validation_panel.custom_minimum_size.y = 80.0
		for frame in [input_a_frame, input_b_frame, input_c_frame, slot1_frame, slot2_frame, inter_frame, output_frame]:
			(frame as PanelContainer).custom_minimum_size.y = 96.0

	interaction_row.add_theme_constant_override("h_separation", 10 if narrow else 12)
	interaction_row.add_theme_constant_override("v_separation", 10 if narrow else 12)
	btn_back.custom_minimum_size = Vector2(44.0 if compact else 64.0, 44.0 if compact else 64.0)

	for gate_btn in gate_buttons.values():
		(gate_btn as Button).custom_minimum_size = Vector2(0, 44 if compact else (54 if very_narrow else 60))

	for action_btn in [btn_hint, btn_test, btn_next]:
		action_btn.custom_minimum_size = Vector2(0, 44 if compact else (56 if very_narrow else 60))

	slot1_btn.custom_minimum_size = Vector2(0, 44 if compact else 56)
	slot2_btn.custom_minimum_size = Vector2(0, 44 if compact else 56)
	input_a_btn.custom_minimum_size.y = 44.0 if compact else (56.0 if very_narrow else 60.0)
	input_b_btn.custom_minimum_size.y = 44.0 if compact else (56.0 if very_narrow else 60.0)
	input_c_btn.custom_minimum_size.y = 44.0 if compact else (56.0 if very_narrow else 60.0)

func load_case(idx: int) -> void:
	if idx < 0:
		idx = 0
	if idx >= CASES.size():
		_show_completion_state()
		return

	current_case_idx = idx
	current_case = CASES[idx]
	if current_case_idx == 0:
		_show_intro_briefing()
	else:
		_hide_intro_briefing()

	inputs = [false, false, false]
	placed_gates = [GATE_NONE, GATE_NONE]
	selected_slot_idx = -1

	attempts = 0
	hints_used = 0
	test_count = 0
	analyze_count = 0
	is_complete = false
	is_safe_mode = false
	case_started_ms = Time.get_ticks_msec()
	first_action_ms = -1
	trial_seq += 1
	task_session = {"events": [], "trial_seq": trial_seq}
	slot_select_count = 0
	slot_switch_count = 0
	gate_place_count = 0
	gate_replace_count = 0
	gate_clear_count = 0
	input_toggle_count = 0
	counterexample_seen_count = 0
	changed_after_counterexample = false
	changed_after_analyze = false
	test_without_full_assembly_count = 0
	time_to_first_slot_select_ms = -1
	time_to_first_test_ms = -1
	time_from_last_edit_to_test_ms = -1
	last_edit_ms = -1
	first_test_was_incomplete = false

	trace_lines.clear()
	vector_cache = _build_control_vectors(current_case)
	last_counterexample.clear()

	if analyze_timer:
		analyze_timer.stop()

	_hide_diagnostics()
	_refresh_case_labels()

	input_a_btn.set_pressed_no_signal(false)
	input_b_btn.set_pressed_no_signal(false)
	input_c_btn.set_pressed_no_signal(false)

	_clear_gate_button_presses()
	_append_trace(_tr("logic.b.trace.case_loaded", "Кейс загружен. Выберите SLOT 1 и установите модуль."))
	_append_trace(_tr("logic.b.trace.full_validation", "ПРОВЕРИТЬ выполняет полную сверку по {count} векторам.", {"count": vector_cache.size()}))

	_update_outputs()
	_update_terminal()
	_update_ui_state()
	_log_event("trial_started", {
		"case_id": str(current_case.get("id", "B_00")),
		"layout": str(current_case.get("layout", "")),
		"correct_gates": current_case.get("correct_gates", []).duplicate()
	})
	_play_click()

func _refresh_case_labels() -> void:
	if current_case.is_empty():
		return

	var labels: Array = current_case.get("labels", ["A", "B", "C"])
	var a_label := str(labels[0])
	var b_label := str(labels[1])
	var c_label := str(labels[2])

	input_a_title_label.text = a_label
	input_b_title_label.text = b_label
	input_c_title_label.text = c_label

	input_a_btn.text = "%s\n[%d]" % [a_label, 1 if inputs[0] else 0]
	input_b_btn.text = "%s\n[%d]" % [b_label, 1 if inputs[1] else 0]
	input_c_btn.text = "%s\n[%d]" % [c_label, 1 if inputs[2] else 0]

	_update_slot_button_text(0)
	_update_slot_button_text(1)
	_set_layout_scheme_text()

func _on_input_a_toggled(pressed: bool) -> void:
	if is_complete or is_safe_mode:
		input_a_btn.set_pressed_no_signal(inputs[0])
		return
	_mark_first_action()
	inputs[0] = pressed
	input_toggle_count += 1
	last_edit_ms = _elapsed_ms_now()
	_log_event("input_toggled", {
		"input": "A",
		"inputs": [inputs[0], inputs[1], inputs[2]]
	})
	_refresh_case_labels()
	_append_trace(_local_simulation_trace("A"))
	_update_outputs()
	_update_terminal()
	_update_ui_state()
	_play_click()

func _on_input_b_toggled(pressed: bool) -> void:
	if is_complete or is_safe_mode:
		input_b_btn.set_pressed_no_signal(inputs[1])
		return
	_mark_first_action()
	inputs[1] = pressed
	input_toggle_count += 1
	last_edit_ms = _elapsed_ms_now()
	_log_event("input_toggled", {
		"input": "B",
		"inputs": [inputs[0], inputs[1], inputs[2]]
	})
	_refresh_case_labels()
	_append_trace(_local_simulation_trace("B"))
	_update_outputs()
	_update_terminal()
	_update_ui_state()
	_play_click()

func _on_input_c_toggled(pressed: bool) -> void:
	if is_complete or is_safe_mode:
		input_c_btn.set_pressed_no_signal(inputs[2])
		return
	_mark_first_action()
	inputs[2] = pressed
	input_toggle_count += 1
	last_edit_ms = _elapsed_ms_now()
	_log_event("input_toggled", {
		"input": "C",
		"inputs": [inputs[0], inputs[1], inputs[2]]
	})
	_refresh_case_labels()
	_append_trace(_local_simulation_trace("C"))
	_update_outputs()
	_update_terminal()
	_update_ui_state()
	_play_click()

func _on_slot1_pressed() -> void:
	if is_complete or is_safe_mode:
		return
	_mark_first_action()
	var previous_slot := selected_slot_idx
	slot_select_count += 1
	if time_to_first_slot_select_ms < 0:
		time_to_first_slot_select_ms = _elapsed_ms_now()
	if previous_slot >= 0 and previous_slot != 0:
		slot_switch_count += 1
	selected_slot_idx = 0
	_log_event("slot_selected", {
		"slot_idx": selected_slot_idx,
		"previous_slot_idx": previous_slot,
		"slot_select_count": slot_select_count,
		"slot_switch_count": slot_switch_count
	})
	_append_trace(_tr("logic.b.trace.select_slot1", "Выбран SLOT 1 (этап 1)."))
	_show_feedback(_tr("logic.b.feedback.select_slot1", "Выбран SLOT 1. Установите модуль из инвентаря."), COLOR_TEXT_INFO)
	_update_ui_state()
	_play_click()

func _on_slot2_pressed() -> void:
	if is_complete or is_safe_mode:
		return
	_mark_first_action()
	var previous_slot := selected_slot_idx
	slot_select_count += 1
	if time_to_first_slot_select_ms < 0:
		time_to_first_slot_select_ms = _elapsed_ms_now()
	if previous_slot >= 0 and previous_slot != 1:
		slot_switch_count += 1
	selected_slot_idx = 1
	_log_event("slot_selected", {
		"slot_idx": selected_slot_idx,
		"previous_slot_idx": previous_slot,
		"slot_select_count": slot_select_count,
		"slot_switch_count": slot_switch_count
	})
	_append_trace(_tr("logic.b.trace.select_slot2", "Выбран SLOT 2 (этап 2)."))
	_show_feedback(_tr("logic.b.feedback.select_slot2", "Выбран SLOT 2. Установите модуль из инвентаря."), COLOR_TEXT_INFO)
	_update_ui_state()
	_play_click()

func _on_gate_button_toggled(pressed: bool, gate_id: String) -> void:
	if not pressed:
		return

	if is_complete or is_safe_mode:
		_clear_gate_button_presses()
		return

	if selected_slot_idx < 0:
		_clear_gate_button_presses()
		_show_feedback(_tr("logic.b.feedback.slot_required", "Сначала выберите SLOT 1 или SLOT 2."), COLOR_TEXT_WARNING)
		return

	_mark_first_action()
	var slot_idx := selected_slot_idx
	var previous_gate := placed_gates[slot_idx]
	var gate_changed := previous_gate != gate_id
	if gate_changed:
		if previous_gate == GATE_NONE:
			gate_place_count += 1
		else:
			gate_replace_count += 1
		if analyze_count > 0:
			changed_after_analyze = true
		if not last_counterexample.is_empty():
			changed_after_counterexample = true
		last_edit_ms = _elapsed_ms_now()
		_log_event("gate_placed" if previous_gate == GATE_NONE else "gate_replaced", {
			"slot_idx": slot_idx,
			"previous_gate": previous_gate,
			"gate_id": gate_id,
			"gate_place_count": gate_place_count,
			"gate_replace_count": gate_replace_count
		})
	_set_slot_filled(slot_idx, gate_id)
	_append_trace(_tr(
		"logic.b.trace.slot_filled",
		"SLOT {slot} <= {gate}",
		{"slot": selected_slot_idx + 1, "gate": _gate_symbol(gate_id)}
	))

	last_counterexample.clear()
	selected_slot_idx = -1
	_clear_gate_button_presses()

	_show_feedback(_tr("logic.b.feedback.module_set", "Модуль установлен. Продолжайте сборку схемы."), COLOR_TEXT_INFO)
	_update_outputs()
	_update_terminal()
	_update_ui_state()
	_play_click()

func _set_slot_filled(slot_idx: int, gate_id: String) -> void:
	if slot_idx < 0 or slot_idx >= placed_gates.size():
		return
	placed_gates[slot_idx] = gate_id
	_update_slot_button_text(slot_idx)

func _set_slot_empty(slot_idx: int) -> void:
	if slot_idx < 0 or slot_idx >= placed_gates.size():
		return
	var previous_gate := placed_gates[slot_idx]
	if previous_gate == GATE_NONE:
		return
	placed_gates[slot_idx] = GATE_NONE
	gate_clear_count += 1
	if analyze_count > 0:
		changed_after_analyze = true
	if not last_counterexample.is_empty():
		changed_after_counterexample = true
	last_edit_ms = _elapsed_ms_now()
	_log_event("gate_cleared", {
		"slot_idx": slot_idx,
		"previous_gate": previous_gate,
		"gate_clear_count": gate_clear_count
	})
	_update_slot_button_text(slot_idx)

func _update_slot_button_text(slot_idx: int) -> void:
	var btn := slot1_btn if slot_idx == 0 else slot2_btn
	var gate_id := placed_gates[slot_idx]
	if gate_id == GATE_NONE:
		btn.text = _tr("logic.b.ui.slot_empty", "УСТАНОВИТЬ\n?")
	else:
		btn.text = _tr(
			"logic.b.ui.slot_filled",
			"ЭТАП {slot}\n{gate}",
			{"slot": slot_idx + 1, "gate": _gate_symbol(gate_id)}
		)

func _calculate_circuit() -> Dictionary:
	var g1 := placed_gates[0]
	var g2 := placed_gates[1]

	var has_stage1 := g1 != GATE_NONE
	var has_stage2 := g2 != GATE_NONE

	var inter := false
	var final := false

	var layout := str(current_case.get("layout", LAYOUT_CASCADE_TOP))
	if layout == LAYOUT_CASCADE_TOP:
		if has_stage1:
			inter = _gate_op(inputs[0], inputs[1], g1)
		if has_stage1 and has_stage2:
			final = _gate_op(inter, inputs[2], g2)
	else:
		if has_stage1:
			inter = _gate_op(inputs[1], inputs[2], g1)
		if has_stage1 and has_stage2:
			final = _gate_op(inputs[0], inter, g2)

	return {
		"has_stage1": has_stage1,
		"has_stage2": has_stage2,
		"inter": inter,
		"final": final
	}

func _evaluate_with_gates(gates: Array, in_a: bool, in_b: bool, in_c: bool) -> Dictionary:
	var g1 := str(gates[0]) if gates.size() > 0 else GATE_NONE
	var g2 := str(gates[1]) if gates.size() > 1 else GATE_NONE

	var has_stage1 := g1 != GATE_NONE
	var has_stage2 := g2 != GATE_NONE

	var inter := false
	var final := false

	var layout := str(current_case.get("layout", LAYOUT_CASCADE_TOP))
	if layout == LAYOUT_CASCADE_TOP:
		if has_stage1:
			inter = _gate_op(in_a, in_b, g1)
		if has_stage1 and has_stage2:
			final = _gate_op(inter, in_c, g2)
	else:
		if has_stage1:
			inter = _gate_op(in_b, in_c, g1)
		if has_stage1 and has_stage2:
			final = _gate_op(in_a, inter, g2)

	return {
		"has_stage1": has_stage1,
		"has_stage2": has_stage2,
		"inter": inter,
		"final": final
	}

func _build_control_vectors(case_data: Dictionary) -> Array[Dictionary]:
	var vectors: Array[Dictionary] = []
	var correct: Array = case_data.get("correct_gates", [])

	for mask in range(8):
		var in_a := (mask & 1) != 0
		var in_b := (mask & 2) != 0
		var in_c := (mask & 4) != 0
		var expected := _evaluate_with_gates(correct, in_a, in_b, in_c)
		vectors.append({
			"index": mask,
			"a": in_a,
			"b": in_b,
			"c": in_c,
			"expected_inter": bool(expected.get("inter", false)),
			"expected_final": bool(expected.get("final", false))
		})

	return vectors

func _find_counterexample() -> Dictionary:
	for vector in vector_cache:
		var in_a := bool(vector.get("a", false))
		var in_b := bool(vector.get("b", false))
		var in_c := bool(vector.get("c", false))

		var actual := _evaluate_with_gates(placed_gates, in_a, in_b, in_c)
		var expected_final := bool(vector.get("expected_final", false))
		var actual_final := bool(actual.get("final", false))

		if expected_final != actual_final:
			var mismatch := {
				"index": int(vector.get("index", 0)),
				"a": in_a,
				"b": in_b,
				"c": in_c,
				"expected_inter": bool(vector.get("expected_inter", false)),
				"actual_inter": bool(actual.get("inter", false)),
				"expected_final": expected_final,
				"actual_final": actual_final
			}
			mismatch["human"] = _format_counterexample(mismatch)
			return mismatch

	return {}

func _format_counterexample(mismatch: Dictionary) -> String:
	return "A=%d, B=%d, C=%d | ЭТАЛОН F=%d | ВАША СХЕМА F=%d" % [
		1 if bool(mismatch.get("a", false)) else 0,
		1 if bool(mismatch.get("b", false)) else 0,
		1 if bool(mismatch.get("c", false)) else 0,
		1 if bool(mismatch.get("expected_final", false)) else 0,
		1 if bool(mismatch.get("actual_final", false)) else 0
	]

func _format_counterexample_multiline(mismatch: Dictionary) -> Array[String]:
	return [
		"A=%d, B=%d, C=%d" % [
			1 if bool(mismatch.get("a", false)) else 0,
			1 if bool(mismatch.get("b", false)) else 0,
			1 if bool(mismatch.get("c", false)) else 0
		],
		"ЭТАЛОН: F=%d" % [1 if bool(mismatch.get("expected_final", false)) else 0],
		"ВАША СХЕМА: F=%d" % [1 if bool(mismatch.get("actual_final", false)) else 0]
	]

func _gate_op(a: bool, b: bool, gate_id: String) -> bool:
	match gate_id:
		GATE_AND:
			return a and b
		GATE_OR:
			return a or b
		GATE_NOT:
			return not a
		GATE_XOR:
			return a != b
		GATE_NAND:
			return not (a and b)
		GATE_NOR:
			return not (a or b)
	return false

func _on_test_pressed() -> void:
	if is_complete or is_safe_mode:
		return

	_mark_first_action()
	if time_to_first_test_ms < 0:
		time_to_first_test_ms = _elapsed_ms_now()
	if last_edit_ms >= 0:
		time_from_last_edit_to_test_ms = maxi(0, _elapsed_ms_now() - last_edit_ms)
	else:
		time_from_last_edit_to_test_ms = -1

	var assembled := _filled_slots_count() == 2
	_log_event("test_pressed", {
		"assembled": assembled,
		"test_count": test_count + 1 if assembled else test_count,
		"time_from_last_edit_to_test_ms": time_from_last_edit_to_test_ms
	})
	if not assembled:
		test_without_full_assembly_count += 1
		if test_count == 0 and test_without_full_assembly_count == 1:
			first_test_was_incomplete = true
		_show_feedback(_tr("logic.b.feedback.incomplete", "Проверка недоступна: заполните оба слота."), COLOR_TEXT_WARNING)
		_append_trace(_tr("logic.b.trace.incomplete_test", "ПРОВЕРИТЬ отклонено: схема собрана не полностью."))
		_log_event("test_result", {
			"is_correct": false,
			"verdict_code": "INCOMPLETE_ASSEMBLY",
			"test_count": test_count,
			"counterexample_present": false
		})
		_update_terminal()
		_update_ui_state()
		return

	test_count += 1
	_append_trace(_tr("logic.b.trace.test_start", "ПРОВЕРКА #{n}: запущена полная валидация по {count} векторам.", {"n": test_count, "count": vector_cache.size()}))

	last_counterexample = _find_counterexample()

	if last_counterexample.is_empty():
		is_complete = true
		_append_trace(_tr("logic.b.trace.test_success", "ВАЛИДАЦИЯ УСПЕШНА: схема совпадает с эталоном на всех 8 векторах."))
		_show_feedback(_tr("logic.b.feedback.test_success", "СХЕМА ПОДТВЕРЖДЕНА ПО ВСЕМ 8 ВЕКТОРАМ."), COLOR_TEXT_SUCCESS)
		_log_event("test_result", {
			"is_correct": true,
			"verdict_code": "SUCCESS",
			"test_count": test_count,
			"counterexample_present": false
		})
		_register_trial("SUCCESS", true)
		GlobalMetrics.finish_quest(str(current_case.get("id", "B_00")), 100, true)
	else:
		attempts += 1
		var penalty := 12.0 + float(attempts * 4)
		_apply_penalty(penalty)

		var mismatch_line := _format_counterexample(last_counterexample)
		counterexample_seen_count += 1
		_log_event("counterexample_shown", {
			"counterexample": last_counterexample.duplicate(true),
			"counterexample_seen_count": counterexample_seen_count
		})
		_append_trace("КОНТРПРИМЕР: %s" % mismatch_line)
		_show_feedback(
			"НАЙДЕНО РАСХОЖДЕНИЕ: %s (-%d)." % [mismatch_line, int(penalty)],
			COLOR_TEXT_ERROR
		)

		var verdict_code := "COUNTEREXAMPLE_FAIL"
		if attempts >= MAX_ATTEMPTS:
			verdict_code = "SAFE_MODE_TRIGGERED"
		_log_event("test_result", {
			"is_correct": false,
			"verdict_code": verdict_code,
			"test_count": test_count,
			"counterexample_present": not last_counterexample.is_empty()
		})
		_register_trial(verdict_code, false)

		if attempts >= MAX_ATTEMPTS:
			GlobalMetrics.finish_quest(str(current_case.get("id", "B_00")), 0, false)
			_enter_safe_mode()

	_update_outputs()
	_update_terminal()
	_update_ui_state()
	_play_click()

func _analysis_text() -> String:
	var layout := str(current_case.get("layout", LAYOUT_CASCADE_TOP))
	var prefix := _tr("logic.b.analysis.prefix", "АНАЛИЗ: ")

	if _filled_slots_count() == 0:
		if layout == LAYOUT_CASCADE_TOP:
			return prefix + _tr("logic.b.analysis.start_top", "Для CASCADE_TOP сначала выберите SLOT 1: он обрабатывает пару A/B.")
		return prefix + _tr("logic.b.analysis.start_bottom", "Для CASCADE_BOTTOM сначала выберите SLOT 1: он обрабатывает пару B/C.")

	if placed_gates[0] == GATE_NONE:
		return prefix + _tr("logic.b.analysis.need_slot1", "Сначала заполните SLOT 1: без внутреннего этапа не появится INTER.")

	if placed_gates[1] == GATE_NONE:
		if layout == LAYOUT_CASCADE_TOP:
			return prefix + _tr("logic.b.analysis.need_slot2_top", "Теперь заполните SLOT 2: он объединяет INTER с входом C.")
		return prefix + _tr("logic.b.analysis.need_slot2_bottom", "Теперь заполните SLOT 2: он объединяет вход A с промежуточным INTER.")

	if last_counterexample.is_empty():
		return prefix + _tr("logic.b.analysis.ready", "Схема собрана. Нажмите ПРОВЕРИТЬ для полной сверки по 8 векторам.")

	var mismatch := _format_counterexample(last_counterexample)
	return prefix + _tr("logic.b.analysis.counterexample", "Есть расхождение: {mismatch}. Перепроверьте этапы каскада.", {"mismatch": mismatch})

func _on_hint_pressed() -> void:
	if is_complete or is_safe_mode:
		return

	if analyze_timer and not analyze_timer.is_stopped():
		_show_feedback(
			_tr("logic.b.feedback.analyze_cooldown", "Анализ недоступен: перегрев {left}с.", {"left": "%.1f" % analyze_timer.time_left}),
			COLOR_TEXT_WARNING
		)
		return

	_mark_first_action()
	analyze_count += 1
	hints_used += 1
	_log_event("analyze_pressed", {
		"analyze_count": analyze_count,
		"filled_slots": _filled_slots_count(),
		"placed_gates": placed_gates.duplicate()
	})

	var analysis := _analysis_text()
	_show_feedback(analysis, COLOR_TEXT_INFO)
	_append_trace("АНАЛИЗ #%d: %s" % [analyze_count, analysis])

	if analyze_timer:
		analyze_timer.start(ANALYZE_COOLDOWN_SEC)

	_update_terminal()
	_update_ui_state()
	_play_click()

func _enter_safe_mode() -> void:
	if is_safe_mode:
		return

	is_safe_mode = true
	is_complete = true
	selected_slot_idx = -1

	var correct: Array = current_case.get("correct_gates", [])
	placed_gates[0] = str(correct[0]) if correct.size() > 0 else GATE_NONE
	placed_gates[1] = str(correct[1]) if correct.size() > 1 else GATE_NONE

	_update_slot_button_text(0)
	_update_slot_button_text(1)
	_clear_gate_button_presses()
	_append_trace(_tr("logic.b.trace.safe_mode", "SAFE MODE: верная сборка подставлена автоматически."))

	_show_feedback(
		_tr("logic.b.feedback.safe_mode", "SAFE MODE: кейс завершён в режиме диагностики. Изучите сборку и переходите далее."),
		COLOR_TEXT_WARNING
	)

	_show_diagnostics(
		_tr("logic.b.safe.title", "SAFE MODE"),
		_tr("logic.b.safe.body", "Система зафиксировала серию ошибок и подставила верную конфигурацию для обучения.\n\nSLOT 1: {slot1}\nSLOT 2: {slot2}", {
			"slot1": _gate_symbol(placed_gates[0]),
			"slot2": _gate_symbol(placed_gates[1])
		}),
		_tr("logic.b.safe.next", "К СЛЕДУЮЩЕМУ КЕЙСУ"),
		DIAG_NEXT
	)

	_update_outputs()
	_update_terminal()
	_update_ui_state()

func _show_completion_state() -> void:
	is_complete = true
	is_safe_mode = false
	selected_slot_idx = -1
	btn_hint.disabled = true
	btn_test.disabled = true
	_set_gate_buttons_enabled(false)

	_show_feedback(_tr("logic.b.feedback.finished", "СЛОЖНОСТЬ B ЗАВЕРШЕНА. Возврат к выбору квестов."), COLOR_TEXT_SUCCESS)
	_show_diagnostics(
		_tr("logic.b.finish.title", "СЛОЖНОСТЬ B ЗАВЕРШЕНА"),
		_tr("logic.b.finish.body", "Все кейсы сложности B закрыты. Возвращайтесь в меню выбора квестов."),
		_tr("logic.b.finish.button", "К ВЫБОРУ КВЕСТОВ"),
		DIAG_EXIT
	)
	_append_trace(_tr("logic.b.trace.finish", "Сложность B завершена."))
	_update_terminal()
	_update_ui_state()
	target_label.text = _tr("logic.b.target.finished", "СЛОЖНОСТЬ B ЗАВЕРШЕНА")
	btn_next.visible = false

func _advance_case_or_exit() -> void:
	_hide_diagnostics()
	var next_idx := current_case_idx + 1
	if next_idx < CASES.size():
		load_case(next_idx)
		return
	_show_completion_state()

func _on_next_button_pressed() -> void:
	_advance_case_or_exit()

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _on_game_over() -> void:
	if is_safe_mode or is_complete:
		return
	GlobalMetrics.finish_quest(str(current_case.get("id", "B_00")), 0, false)
	_enter_safe_mode()

func _on_diagnostics_close_pressed() -> void:
	if diagnostics_action == DIAG_NEXT:
		_advance_case_or_exit()
		return

	if diagnostics_action == DIAG_EXIT:
		_hide_diagnostics()
		get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")
		return

	_hide_diagnostics()

func _on_analyze_unlock() -> void:
	_update_ui_state()

func _show_diagnostics(title: String, message: String, button_text: String, action: String) -> void:
	diagnostics_title.text = title
	diagnostics_text.text = message
	diagnostics_next_button.text = button_text
	diagnostics_action = action
	diagnostics_blocker.visible = true
	diagnostics_panel.visible = true
	diagnostics_next_button.grab_focus()

func _hide_diagnostics() -> void:
	diagnostics_blocker.visible = false
	diagnostics_panel.visible = false
	diagnostics_action = DIAG_NONE

func _show_feedback(msg: String, col: Color) -> void:
	feedback_label.text = msg
	feedback_label.add_theme_color_override("font_color", col)
	feedback_label.visible = true

func _set_gate_buttons_enabled(enabled: bool) -> void:
	for gate_id in gate_buttons.keys():
		var btn: Button = gate_buttons[gate_id]
		btn.disabled = not enabled

func _clear_gate_button_presses() -> void:
	for gate_id in gate_buttons.keys():
		var btn: Button = gate_buttons[gate_id]
		btn.set_pressed_no_signal(false)

func _append_trace(line: String) -> void:
	var trimmed := line.strip_edges()
	if trimmed.is_empty():
		return
	trace_lines.append(trimmed)
	if trace_lines.size() > 18:
		trace_lines.remove_at(0)

func _show_intro_briefing() -> void:
	_intro_briefing_shown = true

func _hide_intro_briefing() -> void:
	_intro_briefing_shown = false

func _intro_briefing_text() -> String:
	return _tr(
		"logic.b.intro",
		"TASK: Assemble the logic circuit.\n\n"
		+ "1. The scheme is shown above: (A, B) -> SLOT 1 -> INTER -> SLOT 2 + C -> F.\n"
		+ "2. Select a SLOT, then place a gate from inventory.\n"
		+ "3. Toggle sensors A/B/C to test behavior.\n"
		+ "4. Press TEST for full validation.\n\n"
		+ "Goal: build a circuit that produces correct F for all combinations."
	)

func _layout_scheme_text() -> String:
	var labels: Array = current_case.get("labels", ["A", "B", "C"])
	var a_label := str(labels[0])
	var b_label := str(labels[1])
	var c_label := str(labels[2])

	if str(current_case.get("layout", LAYOUT_CASCADE_TOP)) == LAYOUT_CASCADE_TOP:
		return "СХЕМА: (%s, %s) -> SLOT 1 -> INTER -> SLOT 2 + %s -> F" % [a_label, b_label, c_label]
	return "СХЕМА: (%s, %s) -> SLOT 1 -> INTER -> SLOT 2 + %s -> F" % [b_label, c_label, a_label]

func _set_layout_scheme_text() -> void:
	scheme_label.text = _layout_scheme_text()

func _local_simulation_values() -> Dictionary:
	var result := _calculate_circuit()

	var inter_text := "—"
	if bool(result.get("has_stage1", false)):
		inter_text = str(1 if bool(result.get("inter", false)) else 0)

	var final_text := "—"
	if bool(result.get("has_stage1", false)) and bool(result.get("has_stage2", false)):
		final_text = str(1 if bool(result.get("final", false)) else 0)

	return {"inter": inter_text, "final": final_text}

func _local_simulation_trace(source: String) -> String:
	var local_vals := _local_simulation_values()
	return "%s изменён: A=%d, B=%d, C=%d -> I=%s, F=%s (локальная симуляция)." % [
		source,
		1 if inputs[0] else 0,
		1 if inputs[1] else 0,
		1 if inputs[2] else 0,
		str(local_vals.get("inter", "—")),
		str(local_vals.get("final", "—"))
	]

func _confidence_ratio() -> float:
	var ratio := float(_filled_slots_count()) / 2.0
	if not last_counterexample.is_empty() and ratio > 0.0:
		ratio -= 0.2
	if is_complete:
		ratio = 1.0
	return clampf(ratio, 0.0, 1.0)

func _confidence_label() -> String:
	var ratio := _confidence_ratio()
	if ratio >= 0.85:
		return "высокая"
	if ratio >= 0.5:
		return "средняя"
	return "низкая"

func _update_terminal() -> void:
	var lines: Array[String] = []
	if _intro_briefing_shown:
		lines.append("[b]%s[/b]" % _tr("logic.common.intro_title", "INSTRUCTION"))
		lines.append(_intro_briefing_text())
		lines.append("")
	lines.append("[b]БРИФИНГ[/b]")
	lines.append(str(current_case.get("story", "")))
	lines.append("Кейс: %s | Тип каскада: %s" % [
		str(current_case.get("id", "B_00")),
		_layout_label(str(current_case.get("layout", LAYOUT_CASCADE_TOP)))
	])
	lines.append("")

	lines.append("[b]СХЕМА СИГНАЛА[/b]")
	lines.append(_layout_scheme_text())
	lines.append("")

	lines.append("[b]РЕЖИМ ПРОВЕРКИ[/b]")
	lines.append("Локальная симуляция: текущие A/B/C показывают I и F на экране.")
	lines.append("Полная проверка: кнопка «ПРОВЕРИТЬ» сверяет схему по всем 8 комбинациям.")
	var local_vals := _local_simulation_values()
	lines.append("СЕЙЧАС: A=%d, B=%d, C=%d -> I=%s, F=%s" % [
		1 if inputs[0] else 0,
		1 if inputs[1] else 0,
		1 if inputs[2] else 0,
		str(local_vals.get("inter", "—")),
		str(local_vals.get("final", "—"))
	])
	lines.append("")

	lines.append("[b]ЖУРНАЛ ДЕЙСТВИЙ[/b]")
	if trace_lines.is_empty():
		lines.append("- Журнал пуст")
	else:
		for i in range(trace_lines.size()):
			var row := "#%d: %s" % [i + 1, trace_lines[i]]
			if i == trace_lines.size() - 1:
				row = "[color=#f4f2e6]> %s[/color]" % row
			lines.append(row)
	lines.append("")

	lines.append("[b]ГИПОТЕЗА[/b]")
	lines.append("SLOT 1: %s" % _gate_symbol(placed_gates[0]))
	lines.append("SLOT 2: %s" % _gate_symbol(placed_gates[1]))
	lines.append("УВЕРЕННОСТЬ: %s (%d/2)" % [_confidence_label(), _filled_slots_count()])

	if not last_counterexample.is_empty():
		lines.append("")
		lines.append("[b]КОНТРПРИМЕР[/b]")
		for row in _format_counterexample_multiline(last_counterexample):
			lines.append(row)

	if is_safe_mode:
		lines.append("")
		lines.append("[color=#ffd084]SAFE MODE: корректная сборка подставлена автоматически.[/color]")

	terminal_text.text = "\n".join(lines)

func _derive_ui_state() -> int:
	if is_safe_mode:
		return UiState.STATE_SAFE_MODE
	if is_complete:
		return UiState.STATE_SOLVED

	var slot1_filled := placed_gates[0] != GATE_NONE
	var slot2_filled := placed_gates[1] != GATE_NONE

	if not slot1_filled and not slot2_filled:
		if selected_slot_idx == 0:
			return UiState.STATE_FILL_FIRST_SLOT
		return UiState.STATE_EMPTY

	if slot1_filled and not slot2_filled:
		if selected_slot_idx == 1:
			return UiState.STATE_FILL_SECOND_SLOT
		return UiState.STATE_SELECT_SECOND_SLOT

	if not slot1_filled and slot2_filled:
		if selected_slot_idx == 0:
			return UiState.STATE_FILL_FIRST_SLOT
		return UiState.STATE_SELECT_FIRST_SLOT

	if not last_counterexample.is_empty():
		return UiState.STATE_TEST_FAILED

	return UiState.STATE_READY_FOR_TEST

func _update_ui_state() -> void:
	var state := _derive_ui_state()
	var has_full_assembly := _filled_slots_count() == 2
	var controls_locked := is_complete or is_safe_mode
	var analyze_cooldown := analyze_timer and not analyze_timer.is_stopped()

	input_a_btn.disabled = controls_locked
	input_b_btn.disabled = controls_locked
	input_c_btn.disabled = controls_locked
	slot1_btn.disabled = controls_locked
	slot2_btn.disabled = controls_locked

	btn_hint.disabled = controls_locked or analyze_cooldown
	btn_test.visible = not (is_complete or is_safe_mode)
	btn_test.disabled = controls_locked or not has_full_assembly
	btn_next.visible = is_complete or is_safe_mode
	if diagnostics_action == DIAG_EXIT:
		btn_next.visible = false

	_set_gate_buttons_enabled(not controls_locked and selected_slot_idx >= 0)
	_update_slot_selection_visual()
	_update_inventory_visual(not controls_locked and selected_slot_idx >= 0)

	_set_target_text_by_state(state)
	_set_primary_action(_primary_action_for_state(state, has_full_assembly))

	facts_bar.max_value = 2
	facts_bar.value = float(_filled_slots_count())
	energy_bar.value = clampf(GlobalMetrics.stability, 0.0, 100.0)

	_update_panel_states(state)
	_update_stats_ui()

func _update_panel_states(state: int) -> void:
	_set_panel_state(input_a_frame, "active" if not is_complete and not is_safe_mode else "disabled")
	_set_panel_state(input_b_frame, "active" if not is_complete and not is_safe_mode else "disabled")
	_set_panel_state(input_c_frame, "active" if not is_complete and not is_safe_mode else "disabled")

	var slot1_filled := placed_gates[0] != GATE_NONE
	var slot2_filled := placed_gates[1] != GATE_NONE

	if is_safe_mode:
		_set_panel_state(slot1_frame, "safe")
		_set_panel_state(slot2_frame, "safe")
	else:
		_set_panel_state(slot1_frame, "active" if selected_slot_idx == 0 else ("filled" if slot1_filled else "default"))
		_set_panel_state(slot2_frame, "active" if selected_slot_idx == 1 else ("filled" if slot2_filled else "default"))

	if state == UiState.STATE_READY_FOR_TEST:
		_set_panel_state(output_frame, "active")
	elif state == UiState.STATE_TEST_FAILED:
		_set_panel_state(output_frame, "error")
	elif state == UiState.STATE_SOLVED:
		_set_panel_state(output_frame, "success")
	elif state == UiState.STATE_SAFE_MODE:
		_set_panel_state(output_frame, "safe")

func _set_panel_state(panel: PanelContainer, mode: String) -> void:
	match mode:
		"active":
			panel.self_modulate = COLOR_STATE_ACTIVE
		"filled":
			panel.self_modulate = COLOR_STATE_FILLED
		"disabled":
			panel.self_modulate = COLOR_STATE_DISABLED
		"success":
			panel.self_modulate = COLOR_STATE_SUCCESS
		"error":
			panel.self_modulate = COLOR_STATE_ERROR
		"safe":
			panel.self_modulate = COLOR_STATE_SAFE
		_:
			panel.self_modulate = COLOR_STATE_DEFAULT

func _set_target_text_by_state(state: int) -> void:
	match state:
		UiState.STATE_EMPTY:
			target_label.text = _tr("logic.b.target.empty", "ШАГ 1/3: выберите SLOT 1 и установите первый модуль")
		UiState.STATE_SELECT_FIRST_SLOT:
			target_label.text = _tr("logic.b.target.select_first", "ШАГ 1/3: выберите SLOT 1, чтобы заполнить внутренний этап")
		UiState.STATE_FILL_FIRST_SLOT:
			target_label.text = _tr("logic.b.target.fill_first", "ШАГ 1/3: выберите модуль для SLOT 1")
		UiState.STATE_SELECT_SECOND_SLOT:
			target_label.text = _tr("logic.b.target.select_second", "ШАГ 1/3: выберите SLOT 2 и установите второй модуль")
		UiState.STATE_FILL_SECOND_SLOT:
			target_label.text = _tr("logic.b.target.fill_second", "ШАГ 1/3: выберите модуль для SLOT 2")
		UiState.STATE_READY_FOR_TEST:
			target_label.text = _tr("logic.b.target.ready", "ШАГ 2/3: запустите полную проверку по всем 8 контрольным векторам")
		UiState.STATE_TEST_FAILED:
			target_label.text = _tr("logic.b.target.failed", "ШАГ 2/3: найдена ошибка, изучите контрпример и исправьте схему")
		UiState.STATE_SOLVED:
			target_label.text = _tr("logic.b.target.solved", "ШАГ 3/3: схема подтверждена, переходите далее")
		UiState.STATE_SAFE_MODE:
			target_label.text = _tr("logic.b.target.safe", "SAFE MODE: верная сборка подставлена автоматически")

func _primary_action_for_state(state: int, has_full_assembly: bool) -> String:
	if state == UiState.STATE_SOLVED or state == UiState.STATE_SAFE_MODE:
		return ACTION_NEXT
	if has_full_assembly:
		return ACTION_TEST
	return ACTION_HINT

func _set_primary_action(action_id: String) -> void:
	btn_hint.modulate = Color(0.84, 0.84, 0.86, 1.0)
	btn_test.modulate = Color(0.84, 0.84, 0.86, 1.0)
	btn_next.modulate = Color(0.84, 0.84, 0.86, 1.0)

	if action_id == ACTION_HINT and not btn_hint.disabled:
		btn_hint.modulate = Color(0.90, 0.93, 0.98, 1.0)
	elif action_id == ACTION_TEST and not btn_test.disabled:
		btn_test.modulate = Color(1.0, 0.92, 0.78, 1.0)
	elif action_id == ACTION_NEXT and btn_next.visible:
		btn_next.modulate = Color(0.84, 0.98, 0.88, 1.0)

func _update_slot_selection_visual() -> void:
	_update_slot_button_text(0)
	_update_slot_button_text(1)

	var slot1_filled := placed_gates[0] != GATE_NONE
	var slot2_filled := placed_gates[1] != GATE_NONE

	slot1_btn.add_theme_color_override(
		"font_color",
		COLOR_TEXT_MAIN if selected_slot_idx == 0 else (COLOR_TEXT_INFO if slot1_filled else COLOR_TEXT_MUTED)
	)
	slot2_btn.add_theme_color_override(
		"font_color",
		COLOR_TEXT_MAIN if selected_slot_idx == 1 else (COLOR_TEXT_INFO if slot2_filled else COLOR_TEXT_MUTED)
	)

func _update_inventory_visual(enabled: bool) -> void:
	_set_panel_state(inventory_frame, "active" if enabled else "default")

	for gate_id in gate_buttons.keys():
		var gate_btn: Button = gate_buttons[gate_id]
		if gate_btn.disabled:
			gate_btn.modulate = Color(0.65, 0.65, 0.67, 1.0)
		elif enabled:
			gate_btn.modulate = Color(0.94, 0.92, 0.86, 1.0)
		else:
			gate_btn.modulate = Color(0.78, 0.78, 0.80, 1.0)

func _update_outputs() -> void:
	var result := _calculate_circuit()
	var has_stage1 := bool(result.get("has_stage1", false))
	var has_stage2 := bool(result.get("has_stage2", false))

	if has_stage1:
		inter_value_label.text = "I_local = %d" % [1 if bool(result.get("inter", false)) else 0]
		inter_value_label.add_theme_color_override("font_color", COLOR_TEXT_MAIN)
	else:
		inter_value_label.text = "I = —"
		inter_value_label.add_theme_color_override("font_color", COLOR_TEXT_MUTED)

	if has_stage1 and has_stage2:
		output_value_label.text = "F_local = %d" % [1 if bool(result.get("final", false)) else 0]
		output_value_label.add_theme_color_override("font_color", COLOR_TEXT_MAIN)
	else:
		output_value_label.text = "F = —"
		output_value_label.add_theme_color_override("font_color", COLOR_TEXT_MUTED)

	if is_safe_mode:
		_set_inter_state("safe" if has_stage1 else "empty")
		_set_output_state("safe")
		return

	if is_complete:
		_set_inter_state("success" if has_stage1 else "empty")
		_set_output_state("success")
		return

	if not last_counterexample.is_empty():
		_set_inter_state("mismatch" if has_stage1 else "partial")
		_set_output_state("mismatch")
		return

	if not has_stage1 and not has_stage2:
		_set_inter_state("empty")
		_set_output_state("empty")
	elif has_stage1 and not has_stage2:
		_set_inter_state("partial")
		_set_output_state("partial")
	elif not has_stage1 and has_stage2:
		_set_inter_state("partial")
		_set_output_state("partial")
	else:
		_set_inter_state("local")
		_set_output_state("local")

func _set_inter_state(mode: String) -> void:
	match mode:
		"local":
			_set_panel_state(inter_frame, "filled")
			inter_hint_label.text = "INTER вычислен по текущим входам"
			inter_hint_label.add_theme_color_override("font_color", COLOR_TEXT_INFO)
		"partial":
			_set_panel_state(inter_frame, "active")
			inter_hint_label.text = "INTER доступен после заполнения SLOT 1"
			inter_hint_label.add_theme_color_override("font_color", COLOR_TEXT_WARNING)
		"mismatch":
			_set_panel_state(inter_frame, "error")
			inter_hint_label.text = "Есть расхождение на полной проверке"
			inter_hint_label.add_theme_color_override("font_color", COLOR_TEXT_WARNING)
		"success":
			_set_panel_state(inter_frame, "success")
			inter_hint_label.text = "INTER подтвержден в валидной схеме"
			inter_hint_label.add_theme_color_override("font_color", COLOR_TEXT_SUCCESS)
		"safe":
			_set_panel_state(inter_frame, "safe")
			inter_hint_label.text = "SAFE MODE: эталонный INTER"
			inter_hint_label.add_theme_color_override("font_color", COLOR_TEXT_WARNING)
		_:
			_set_panel_state(inter_frame, "default")
			inter_hint_label.text = "INTER появится после этапа 1"
			inter_hint_label.add_theme_color_override("font_color", COLOR_TEXT_MUTED)

func _set_output_state(mode: String) -> void:
	match mode:
		"local":
			_set_panel_state(output_frame, "filled")
			output_hint_label.text = "Локальный результат по текущим A/B/C"
			output_hint_label.add_theme_color_override("font_color", COLOR_TEXT_INFO)
		"partial":
			_set_panel_state(output_frame, "active")
			output_hint_label.text = "Соберите оба этапа, чтобы получить F"
			output_hint_label.add_theme_color_override("font_color", COLOR_TEXT_WARNING)
		"mismatch":
			_set_panel_state(output_frame, "error")
			output_hint_label.text = "Последняя полная проверка выявила контрпример"
			output_hint_label.add_theme_color_override("font_color", COLOR_TEXT_ERROR)
		"success":
			_set_panel_state(output_frame, "success")
			output_hint_label.text = "Схема подтверждена по всем 8 векторам"
			output_hint_label.add_theme_color_override("font_color", COLOR_TEXT_SUCCESS)
		"safe":
			_set_panel_state(output_frame, "safe")
			output_hint_label.text = "SAFE MODE: показана верная сборка"
			output_hint_label.add_theme_color_override("font_color", COLOR_TEXT_WARNING)
		_:
			_set_panel_state(output_frame, "default")
			output_hint_label.text = "F появится после полной сборки"
			output_hint_label.add_theme_color_override("font_color", COLOR_TEXT_MUTED)

func _filled_slots_count() -> int:
	var filled := 0
	if placed_gates[0] != GATE_NONE:
		filled += 1
	if placed_gates[1] != GATE_NONE:
		filled += 1
	return filled

func _update_stats_ui() -> void:
	var case_id := str(current_case.get("id", "B_00"))
	session_label.text = "СЕССИЯ: %d/%d | КЕЙС %s" % [current_case_idx + 1, CASES.size(), case_id]

	stats_label.text = "ПОПЫТКИ: %d/%d | ПРОВЕРКИ: %d | ВЕКТОРЫ: %d | АНАЛИЗ: %d | СТАБИЛЬНОСТЬ: %d%%" % [
		attempts,
		MAX_ATTEMPTS,
		test_count,
		vector_cache.size(),
		analyze_count,
		int(GlobalMetrics.stability)
	]

func _apply_penalty(amount: float) -> void:
	_last_stability_penalty = amount
	GlobalMetrics.stability = max(0.0, GlobalMetrics.stability - amount)
	GlobalMetrics.stability_changed.emit(GlobalMetrics.stability, -amount)

func _update_stability_ui(val: float, _diff: float) -> void:
	energy_bar.value = clampf(val, 0.0, 100.0)
	_update_stats_ui()

func _mark_first_action() -> void:
	if first_action_ms < 0:
		first_action_ms = Time.get_ticks_msec() - case_started_ms

func _elapsed_ms_now() -> int:
	if case_started_ms <= 0:
		return 0
	return maxi(0, Time.get_ticks_msec() - case_started_ms)

func _log_event(event_name: String, data: Dictionary = {}) -> void:
	var events: Array = task_session.get("events", [])
	events.append({
		"name": event_name,
		"t_ms": _elapsed_ms_now(),
		"payload": data.duplicate(true)
	})
	task_session["events"] = events

func _mastery_block_reason(verdict_code: String, is_correct: bool) -> String:
	if verdict_code == "SAFE_MODE_TRIGGERED":
		return "SAFE_MODE_TRIGGERED"
	if counterexample_seen_count > 0 and not changed_after_counterexample and not is_correct:
		return "COUNTEREXAMPLE_IGNORED"
	if first_test_was_incomplete:
		return "INCOMPLETE_FIRST_TEST"
	if gate_replace_count >= 4:
		return "TOO_MANY_REPLACEMENTS"
	if test_count > 1 and is_correct:
		return "MULTI_TEST_GUESSING"
	if analyze_count > 0:
		return "USED_ANALYZE"
	return "NONE"

func _register_trial(verdict_code: String, is_correct: bool) -> void:
	var case_id := str(current_case.get("id", "B_00"))
	var variant_hash := str(hash("%s|%s|%s" % [
		str(current_case.get("layout", "")),
		placed_gates[0],
		placed_gates[1]
	]))

	var payload := TrialV2.build("LOGIC_QUEST", "B", case_id, "MODULE_ASSEMBLY", variant_hash)
	var elapsed_ms := _elapsed_ms_now()

	payload["elapsed_ms"] = elapsed_ms
	payload["duration"] = float(elapsed_ms) / 1000.0
	payload["time_to_first_action_ms"] = first_action_ms if first_action_ms >= 0 else elapsed_ms
	payload["is_correct"] = is_correct
	payload["is_fit"] = is_correct
	payload["stability_delta"] = 0.0 if is_correct else -_last_stability_penalty
	_last_stability_penalty = 0.0
	payload["verdict_code"] = verdict_code

	payload["attempts"] = attempts
	payload["hints_used"] = hints_used
	payload["analyze_count"] = analyze_count
	payload["test_count"] = test_count
	payload["vector_count"] = vector_cache.size()

	payload["inputs"] = [inputs[0], inputs[1], inputs[2]]
	payload["placed_gates"] = placed_gates.duplicate()
	payload["correct_gates"] = current_case.get("correct_gates", []).duplicate()
	payload["trial_seq"] = trial_seq
	payload["slot_select_count"] = slot_select_count
	payload["slot_switch_count"] = slot_switch_count
	payload["gate_place_count"] = gate_place_count
	payload["gate_replace_count"] = gate_replace_count
	payload["gate_clear_count"] = gate_clear_count
	payload["input_toggle_count"] = input_toggle_count
	payload["counterexample_seen_count"] = counterexample_seen_count
	payload["changed_after_counterexample"] = changed_after_counterexample
	payload["changed_after_analyze"] = changed_after_analyze
	payload["test_without_full_assembly_count"] = test_without_full_assembly_count
	payload["time_to_first_slot_select_ms"] = time_to_first_slot_select_ms
	payload["time_to_first_test_ms"] = time_to_first_test_ms
	payload["time_from_last_edit_to_test_ms"] = time_from_last_edit_to_test_ms
	payload["task_session"] = task_session.duplicate(true)
	payload["outcome_code"] = verdict_code
	payload["mastery_block_reason"] = _mastery_block_reason(verdict_code, is_correct)

	if not last_counterexample.is_empty():
		payload["counterexample"] = last_counterexample.duplicate(true)

	GlobalMetrics.register_trial(payload)

func _layout_label(layout: String) -> String:
	if layout == LAYOUT_CASCADE_BOTTOM:
		return "CASCADE_BOTTOM"
	return "CASCADE_TOP"

func _gate_symbol(gate_id: String) -> String:
	match gate_id:
		GATE_AND:
			return "И"
		GATE_OR:
			return "ИЛИ"
		GATE_NOT:
			return "НЕ"
		GATE_XOR:
			return "ИСКЛ-ИЛИ"
		GATE_NAND:
			return "И-НЕ"
		GATE_NOR:
			return "ИЛИ-НЕ"
		GATE_NONE:
			return "—"
		_:
			return "?"

func _play_click() -> void:
	if click_player.stream:
		click_player.play()
