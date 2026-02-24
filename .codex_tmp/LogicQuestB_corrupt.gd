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
const ANALYZE_COOLDOWN_SECONDS := 4.0

const CASES := [
	{
		"id": "B_01",
		"layout": LAYOUT_CASCADE_TOP,
		"story": "ﾐ｡ﾐｾﾐｱﾐｵﾑﾐｸﾑひｵ ﾐｴﾐｲﾑτ・采ひｰﾐｿﾐｽﾑτ・ﾑ・・ｵﾐｼﾑ・ ﾑ・ｽﾐｰﾑ・ｰﾐｻﾐｰ ﾑσｷﾐｵﾐｻ A/B, ﾐｷﾐｰﾑひｵﾐｼ ﾑﾐｵﾐｷﾑσｻﾑ袴ひｰﾑ・ﾑ・C.",
		"labels": ["ﾐ頒籍｢ﾐｧﾐ侑・A", "ﾐ頒籍｢ﾐｧﾐ侑・B", "ﾐ頒籍｢ﾐｧﾐ侑・C"],
		"correct_gates": [GATE_OR, GATE_AND],
		"hint": "ﾐ｡ﾐｽﾐｰﾑ・ｰﾐｻﾐｰ ﾐｾﾐｱﾑ諌ｵﾐｴﾐｸﾐｽﾐｸﾑひｵ A ﾐｸ B ﾑ・ｵﾑﾐｵﾐｷ OR, ﾐｷﾐｰﾑひｵﾐｼ ﾐｿﾑﾐｸﾐｼﾐｵﾐｽﾐｸﾑひｵ AND ﾑ・C."
	},
	{
		"id": "B_02",
		"layout": LAYOUT_CASCADE_BOTTOM,
		"story": "ﾐ｡ﾑ・ｵﾐｼﾐｰ ﾐｿﾐｵﾑﾐｵﾑ・びﾐｾﾐｵﾐｽﾐｰ: ﾑ・ｽﾐｰﾑ・ｰﾐｻﾐｰ ﾐｾﾐｱﾑﾐｰﾐｱﾐｰﾑび巾ｲﾐｰﾐｵﾑび・・ﾐｿﾐｰﾑﾐｰ B/C, ﾐｷﾐｰﾑひｵﾐｼ ﾑσｷﾐｵﾐｻ A.",
		"labels": ["ﾐ墟嶢ｮﾐｧ A", "ﾐ墟嶢ｮﾐｧ B", "ﾐ墟嶢ｮﾐｧ C"],
		"correct_gates": [GATE_AND, GATE_OR],
		"hint": "ﾐ漬ｾ ﾐｲﾐｽﾑτびﾐｵﾐｽﾐｽﾐｵﾐｼ ﾑ・ｻﾐｾﾑひｵ ﾐｽﾑσｶﾐｵﾐｽ AND, ﾐｲﾐｾ ﾐｲﾐｽﾐｵﾑ威ｽﾐｵﾐｼ ﾑ・ｻﾐｾﾑひｵ - OR."
	},
	{
		"id": "B_03",
		"layout": LAYOUT_CASCADE_TOP,
		"story": "ﾐ旃σｶﾐｵﾐｽ ﾐｺﾐｰﾐｽﾐｰﾐｻ, ﾐｳﾐｴﾐｵ ﾐｿﾐｵﾑﾐｲﾑ巾ｹ ﾑ采ひｰﾐｿ ﾐｻﾐｾﾐｲﾐｸﾑ・ﾑﾐｰﾐｷﾐｻﾐｸﾑ・ｸﾐｵ A/B, ﾐｰ ﾐｲﾑひｾﾑﾐｾﾐｹ ﾑ・ｸﾐｻﾑ袴びﾑσｵﾑ・ﾑ・ｵﾑﾐｵﾐｷ C.",
		"labels": ["ﾐ墟籍斷籍・A", "ﾐ墟籍斷籍・B", "ﾐ､ﾐ侑嶢ｬﾐ｢ﾐ C"],
		"correct_gates": [GATE_XOR, GATE_AND],
		"hint": "ﾐﾐｰﾐｷﾐｻﾐｸﾑ・ｸﾐｵ ﾐｽﾐｰ ﾐｿﾐｵﾑﾐｲﾐｾﾐｼ ﾑ采ひｰﾐｿﾐｵ ﾐｴﾐｰﾑ帯・XOR."
	},
	{
		"id": "B_04",
		"layout": LAYOUT_CASCADE_BOTTOM,
		"story": "ﾐ｡ﾑ・ｵﾐｼﾐｰ ﾑ・ﾐｸﾐｽﾐｲﾐｵﾑﾑ・ｸﾐｵﾐｹ: ﾑ・ｽﾐｰﾑ・ｰﾐｻﾐｰ ﾐｸﾐｽﾐｲﾐｵﾑﾑひｸﾑﾑσｵﾑび・・B/C, ﾐｷﾐｰﾑひｵﾐｼ ﾐｾﾐｱﾑ諌ｵﾐｴﾐｸﾐｽﾑ紹ｵﾑび・・ﾑ・A.",
		"labels": ["ﾐ榧渙榧ﾐ斷ｫﾐ・A", "ﾐｨﾐ｣ﾐ・B", "ﾐｨﾐ｣ﾐ・C"],
		"correct_gates": [GATE_NOR, GATE_OR],
		"hint": "ﾐ漬ｽﾑτびﾐｵﾐｽﾐｽﾐｸﾐｹ ﾑ采ひｰﾐｿ - NOR, ﾐｲﾐｽﾐｵﾑ威ｽﾐｸﾐｹ - OR."
	},
	{
		"id": "B_05",
		"layout": LAYOUT_CASCADE_TOP,
		"story": "ﾐ｡ﾐｾﾐｱﾐｵﾑﾐｸﾑひｵ ﾑτ・ひｾﾐｹﾑ・ｸﾐｲﾑ巾ｹ ﾑびﾐｰﾐｺﾑ・ﾑ・ﾑ・ｸﾐｽﾐｰﾐｻﾑ糊ｽﾑ巾ｼ ﾐｾﾑびﾐｸﾑ・ｰﾐｽﾐｸﾐｵﾐｼ ﾑ・ｾﾐｲﾐｿﾐｰﾐｴﾐｵﾐｽﾐｸﾑ・",
		"labels": ["ﾐ嶢侑斷侑ｯ A", "ﾐ嶢侑斷侑ｯ B", "ﾐ嶢侑斷侑ｯ C"],
		"correct_gates": [GATE_AND, GATE_NAND],
		"hint": "ﾐ｡ﾐｽﾐｰﾑ・ｰﾐｻﾐｰ ﾐｽﾑσｶﾐｽﾐｾ ﾑ・ｾﾐｲﾐｿﾐｰﾐｴﾐｵﾐｽﾐｸﾐｵ A ﾐｸ B, ﾐｷﾐｰﾑひｵﾐｼ ﾐｾﾑびﾐｸﾑ・ｰﾐｽﾐｸﾐｵ ﾑ・C."
	}
]

@onready var safe_area: MarginContainer = $SafeArea
@onready var main_layout: VBoxContainer = $SafeArea/MainLayout
@onready var interaction_row: HBoxContainer = $SafeArea/MainLayout/InteractionRow
@onready var actions_row: HBoxContainer = $SafeArea/MainLayout/Actions
@onready var gates_container: HBoxContainer = $SafeArea/MainLayout/InventoryFrame/InventoryMargin/InventoryScroll/GatesContainer
@onready var input_a_frame: PanelContainer = $SafeArea/MainLayout/InteractionRow/InputAFrame
@onready var input_b_frame: PanelContainer = $SafeArea/MainLayout/InteractionRow/InputBFrame
@onready var input_c_frame: PanelContainer = $SafeArea/MainLayout/InteractionRow/InputCFrame
@onready var slot1_frame: PanelContainer = $SafeArea/MainLayout/InteractionRow/Slot1Frame
@onready var slot2_frame: PanelContainer = $SafeArea/MainLayout/InteractionRow/Slot2Frame
@onready var inter_slot: PanelContainer = $SafeArea/MainLayout/InteractionRow/InterSlot
@onready var output_slot: PanelContainer = $SafeArea/MainLayout/InteractionRow/OutputSlot
@onready var clue_title_label: Label = $SafeArea/MainLayout/Header/LblClueTitle
@onready var session_label: Label = $SafeArea/MainLayout/Header/LblSessionId
@onready var facts_bar: ProgressBar = $SafeArea/MainLayout/BarsRow/FactsBar
@onready var energy_bar: ProgressBar = $SafeArea/MainLayout/BarsRow/EnergyBar
@onready var target_label: Label = $SafeArea/MainLayout/TargetDisplay/LblTarget
@onready var terminal_text: RichTextLabel = $SafeArea/MainLayout/TerminalFrame/TerminalScroll/TerminalRichText
@onready var stats_label: Label = $SafeArea/MainLayout/StatusRow/StatsLabel
@onready var feedback_label: Label = $SafeArea/MainLayout/StatusRow/FeedbackLabel

@onready var input_a_btn: Button = $SafeArea/MainLayout/InteractionRow/InputAFrame/InputAVBox/InputA_Btn
@onready var input_b_btn: Button = $SafeArea/MainLayout/InteractionRow/InputBFrame/InputBVBox/InputB_Btn
@onready var input_c_btn: Button = $SafeArea/MainLayout/InteractionRow/InputCFrame/InputCVBox/InputC_Btn
@onready var slot1_btn: Button = $SafeArea/MainLayout/InteractionRow/Slot1Frame/Slot1VBox/Slot1SelectBtn
@onready var slot2_btn: Button = $SafeArea/MainLayout/InteractionRow/Slot2Frame/Slot2VBox/Slot2SelectBtn
@onready var inter_value_label: Label = $SafeArea/MainLayout/InteractionRow/InterSlot/InterVBox/InterValueLabel
@onready var output_value_label: Label = $SafeArea/MainLayout/InteractionRow/OutputSlot/OutputVBox/OutputValueLabel

@onready var gate_and_btn: Button = $SafeArea/MainLayout/InventoryFrame/InventoryMargin/InventoryScroll/GatesContainer/GateAndBtn
@onready var gate_or_btn: Button = $SafeArea/MainLayout/InventoryFrame/InventoryMargin/InventoryScroll/GatesContainer/GateOrBtn
@onready var gate_not_btn: Button = $SafeArea/MainLayout/InventoryFrame/InventoryMargin/InventoryScroll/GatesContainer/GateNotBtn
@onready var gate_xor_btn: Button = $SafeArea/MainLayout/InventoryFrame/InventoryMargin/InventoryScroll/GatesContainer/GateXorBtn
@onready var gate_nand_btn: Button = $SafeArea/MainLayout/InventoryFrame/InventoryMargin/InventoryScroll/GatesContainer/GateNandBtn
@onready var gate_nor_btn: Button = $SafeArea/MainLayout/InventoryFrame/InventoryMargin/InventoryScroll/GatesContainer/GateNorBtn

@onready var btn_hint: Button = $SafeArea/MainLayout/Actions/BtnHint
@onready var btn_test: Button = $SafeArea/MainLayout/Actions/BtnTest
@onready var btn_next: Button = $SafeArea/MainLayout/Actions/BtnNext
@onready var btn_back: Button = $SafeArea/MainLayout/Header/BtnBack

@onready var diagnostics_blocker: ColorRect = $DiagnosticsBlocker
@onready var diagnostics_panel: PanelContainer = $DiagnosticsPanelB
@onready var diagnostics_title: Label = $DiagnosticsPanelB/PopupMargin/PopupVBox/PopupTitle
@onready var diagnostics_text: RichTextLabel = $DiagnosticsPanelB/PopupMargin/PopupVBox/PopupText
@onready var diagnostics_next_button: Button = $DiagnosticsPanelB/PopupMargin/PopupVBox/PopupBtnNext
@onready var click_player: AudioStreamPlayer = $ClickPlayer

var current_case_idx: int = 0
var current_case: Dictionary = {}

var inputs: Array[bool] = [false, false, false]
var placed_gates: Array[String] = [GATE_NONE, GATE_NONE]
var selected_slot_idx: int = -1

var attempts: int = 0
var hints_used: int = 0
var test_count: int = 0
var analyze_cooldown_until: float = 0.0
var is_complete: bool = false
var is_safe_mode: bool = false
var case_started_ms: int = 0
var first_action_ms: int = -1
var trace_lines: Array[String] = []
var last_counterexample: Dictionary = {}

var gate_buttons: Dictionary = {}
var _interaction_mobile_layout: VBoxContainer = null

func _ready() -> void:
	_connect_ui_signals()
	_setup_gate_buttons()
	_update_stability_ui(GlobalMetrics.stability, 0.0)
	if not GlobalMetrics.stability_changed.is_connected(_update_stability_ui):
		GlobalMetrics.stability_changed.connect(_update_stability_ui)
	if not GlobalMetrics.game_over.is_connected(_on_game_over):
		GlobalMetrics.game_over.connect(_on_game_over)
	load_case(0)
	_on_viewport_size_changed()
	if not get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.connect(_on_viewport_size_changed)

func _exit_tree() -> void:
	if get_tree() != null and get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.disconnect(_on_viewport_size_changed)

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

	var gate_callbacks: Dictionary = {
		gate_and_btn: Callable(self, "_on_gate_button_toggled").bind(GATE_AND),
		gate_or_btn: Callable(self, "_on_gate_button_toggled").bind(GATE_OR),
		gate_not_btn: Callable(self, "_on_gate_button_toggled").bind(GATE_NOT),
		gate_xor_btn: Callable(self, "_on_gate_button_toggled").bind(GATE_XOR),
		gate_nand_btn: Callable(self, "_on_gate_button_toggled").bind(GATE_NAND),
		gate_nor_btn: Callable(self, "_on_gate_button_toggled").bind(GATE_NOR)
	}
	for gate_btn_var in gate_callbacks.keys():
		var gate_btn: Button = gate_btn_var
		var cb: Callable = gate_callbacks[gate_btn]
		if not gate_btn.toggled.is_connected(cb):
			gate_btn.toggled.connect(cb)

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
		GATE_NOT: gate_not_btn,
		GATE_XOR: gate_xor_btn,
		GATE_NAND: gate_nand_btn,
		GATE_NOR: gate_nor_btn
	}
	_clear_gate_button_presses()

func load_case(idx: int) -> void:
	if idx >= CASES.size():
		idx = 0

	current_case_idx = idx
	current_case = CASES[idx]
	inputs = [false, false, false]
	placed_gates = [GATE_NONE, GATE_NONE]
	selected_slot_idx = -1
	attempts = 0
	hints_used = 0
	test_count = 0
	analyze_cooldown_until = 0.0
	is_complete = false
	is_safe_mode = false
	case_started_ms = Time.get_ticks_msec()
	first_action_ms = -1
	trace_lines.clear()
	last_counterexample.clear()

	clue_title_label.text = "ﾐ頒片｢ﾐ片墟｢ﾐ榧 ﾐ嶢孟・B-01"
	input_a_btn.text = "%s\n[0]" % str(current_case.get("labels", ["A"])[0])
	input_b_btn.text = "%s\n[0]" % str(current_case.get("labels", ["A", "B"])[1])
	input_c_btn.text = "%s\n[0]" % str(current_case.get("labels", ["A", "B", "C"])[2])
	input_a_btn.button_pressed = false
	input_b_btn.button_pressed = false
	input_c_btn.button_pressed = false
	input_a_btn.disabled = false
	input_b_btn.disabled = false
	input_c_btn.disabled = false

	btn_hint.disabled = false
	btn_hint.text = "ANALYZE"
	btn_test.disabled = true
	btn_next.visible = false
	feedback_label.visible = false
	feedback_label.text = ""
	_hide_diagnostics()
	_set_gate_buttons_enabled(false)
	_clear_gate_button_presses()

	_update_slot_visual(0)
	_update_slot_visual(1)
	_update_outputs()
	_append_trace("ﾐ｡ﾑ・ｵﾐｽﾐｰﾑﾐｸﾐｹ ﾐｷﾐｰﾐｳﾑﾑσｶﾐｵﾐｽ. ﾐ柘巾ｱﾐｵﾑﾐｸﾑひｵ ﾑ・ｻﾐｾﾑ・ﾐｸ ﾑτ・ひｰﾐｽﾐｾﾐｲﾐｸﾑひｵ ﾐｼﾐｾﾐｴﾑσｻﾑ・")
	_update_terminal()
	_update_stats_ui()
	_update_ui_state()

func _on_input_a_toggled(pressed: bool) -> void:
	_mark_first_action()
	inputs[0] = pressed
	input_a_btn.text = "%s\n[%d]" % [str(current_case.get("labels", ["A"])[0]), 1 if pressed else 0]
	_update_outputs()
	_update_terminal()
	_update_ui_state()
	_play_click()

func _on_input_b_toggled(pressed: bool) -> void:
	_mark_first_action()
	inputs[1] = pressed
	input_b_btn.text = "%s\n[%d]" % [str(current_case.get("labels", ["A", "B"])[1]), 1 if pressed else 0]
	_update_outputs()
	_update_terminal()
	_update_ui_state()
	_play_click()

func _on_input_c_toggled(pressed: bool) -> void:
	_mark_first_action()
	inputs[2] = pressed
	input_c_btn.text = "%s\n[%d]" % [str(current_case.get("labels", ["A", "B", "C"])[2]), 1 if pressed else 0]
	_update_outputs()
	_update_terminal()
	_update_ui_state()
	_play_click()

func _on_slot1_pressed() -> void:
	if is_complete:
		return
	_mark_first_action()
	selected_slot_idx = 0
	_update_slot_selection_visual()
	_set_gate_buttons_enabled(true)
	_show_feedback("ﾐ柘巾ｱﾑﾐｰﾐｽ SLOT 1. ﾐ｣ﾑ・ひｰﾐｽﾐｾﾐｲﾐｸﾑひｵ ﾐｼﾐｾﾐｴﾑσｻﾑ・ﾐｸﾐｷ ﾐｸﾐｽﾐｲﾐｵﾐｽﾑひｰﾑﾑ・", Color(0.56, 0.78, 0.96))
	_play_click()

func _on_slot2_pressed() -> void:
	if is_complete:
		return
	_mark_first_action()
	selected_slot_idx = 1
	_update_slot_selection_visual()
	_set_gate_buttons_enabled(true)
	_show_feedback("ﾐ柘巾ｱﾑﾐｰﾐｽ SLOT 2. ﾐ｣ﾑ・ひｰﾐｽﾐｾﾐｲﾐｸﾑひｵ ﾐｼﾐｾﾐｴﾑσｻﾑ・ﾐｸﾐｷ ﾐｸﾐｽﾐｲﾐｵﾐｽﾑひｰﾑﾑ・", Color(0.56, 0.78, 0.96))
	_play_click()

func _on_gate_button_toggled(arg1: Variant, arg2: Variant = null) -> void:
	var pressed := false
	var gate_id := ""
	if arg1 is bool:
		pressed = arg1
		gate_id = str(arg2)
	else:
		gate_id = str(arg1)
		pressed = bool(arg2)
	if gate_id.is_empty():
		return

	if not pressed:
		return
	if is_complete or is_safe_mode:
		_clear_gate_button_presses()
		return
	if selected_slot_idx < 0:
		_show_feedback("ﾐ｡ﾐｽﾐｰﾑ・ｰﾐｻﾐｰ ﾐｲﾑ巾ｱﾐｵﾑﾐｸﾑひｵ SLOT 1 ﾐｸﾐｻﾐｸ SLOT 2.", Color(1.0, 0.78, 0.32))
		_clear_gate_button_presses()
		return

	_mark_first_action()
	placed_gates[selected_slot_idx] = gate_id
	_update_slot_visual(selected_slot_idx)
	_append_trace("SLOT %d <= %s" % [selected_slot_idx + 1, _gate_symbol(gate_id)])
	selected_slot_idx = -1
	_update_slot_selection_visual()
	_set_gate_buttons_enabled(false)
	_clear_gate_button_presses()
	_update_outputs()
	_update_terminal()
	_update_ui_state()
	_play_click()

func _update_slot_visual(idx: int) -> void:
	var gate_id := placed_gates[idx]
	var slot_btn := slot1_btn if idx == 0 else slot2_btn
	if gate_id == GATE_NONE:
		slot_btn.text = "ﾐ｣ﾐ｡ﾐ｢ﾐ籍斷榧漬侑｢ﾐｬ\n?"
	else:
		slot_btn.text = "ﾐ｣ﾐ｡ﾐ｢ﾐ籍斷榧漬嶢片斷杤n%s" % _gate_symbol(gate_id)

func _update_slot_selection_visual() -> void:
	slot1_btn.add_theme_color_override("font_color", Color(0.95, 0.95, 0.90, 1.0) if selected_slot_idx == 0 else Color(0.74, 0.74, 0.70, 1.0))
	slot2_btn.add_theme_color_override("font_color", Color(0.95, 0.95, 0.90, 1.0) if selected_slot_idx == 1 else Color(0.74, 0.74, 0.70, 1.0))

func _update_outputs() -> void:
	var result := _calculate_circuit()
	inter_value_label.text = "I = %d" % (1 if bool(result.get("inter", false)) else 0)
	output_value_label.text = "F = %d" % (1 if bool(result.get("final", false)) else 0)
	inter_value_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.90, 1.0) if bool(result.get("inter", false)) else Color(0.55, 0.55, 0.55, 1.0))
	output_value_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.90, 1.0) if bool(result.get("final", false)) else Color(0.55, 0.55, 0.55, 1.0))

func _calculate_circuit() -> Dictionary:
	return _calculate_circuit_for(inputs, placed_gates)

func _calculate_circuit_for(in_vals: Array[bool], gate_vals: Array[String]) -> Dictionary:
	var g1 := gate_vals[0]
	var g2 := gate_vals[1]
	var inter := false
	var final := false

	if str(current_case.get("layout", LAYOUT_CASCADE_TOP)) == LAYOUT_CASCADE_TOP:
		if g1 != GATE_NONE:
			inter = _gate_op(in_vals[0], in_vals[1], g1)
		if g2 != GATE_NONE:
			final = _gate_op(inter, in_vals[2], g2)
	else:
		if g1 != GATE_NONE:
			inter = _gate_op(in_vals[1], in_vals[2], g1)
		if g2 != GATE_NONE:
			final = _gate_op(in_vals[0], inter, g2)

	return {"inter": inter, "final": final}

func _evaluate_control_vectors() -> Dictionary:
	var correct: Array = current_case.get("correct_gates", [])
	if correct.size() < 2:
		return {"ok": false}
	var expected_gates: Array[String] = [str(correct[0]), str(correct[1])]
	var vectors: Array = [
		[false, false, false],
		[false, false, true],
		[false, true, false],
		[false, true, true],
		[true, false, false],
		[true, false, true],
		[true, true, false],
		[true, true, true]
	]
	for vector in vectors:
		var bool_vector: Array[bool] = [bool(vector[0]), bool(vector[1]), bool(vector[2])]
		var expected := _calculate_circuit_for(bool_vector, expected_gates)
		var actual := _calculate_circuit_for(bool_vector, placed_gates)
		if bool(actual.get("final", false)) != bool(expected.get("final", false)):
			return {
				"ok": false,
				"counterexample": {
					"a": 1 if bool_vector[0] else 0,
					"b": 1 if bool_vector[1] else 0,
					"c": 1 if bool_vector[2] else 0,
					"expected_f": 1 if bool(expected.get("final", false)) else 0,
					"actual_f": 1 if bool(actual.get("final", false)) else 0,
					"expected_i": 1 if bool(expected.get("inter", false)) else 0,
					"actual_i": 1 if bool(actual.get("inter", false)) else 0
				}
			}
	return {"ok": true}

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

	if placed_gates[0] == GATE_NONE or placed_gates[1] == GATE_NONE:
		_show_feedback("Fill both slots before TEST.", Color(1.0, 0.78, 0.32))
		return

	test_count += 1
	var result := _calculate_circuit()
	_append_trace("TEST #%d | A=%d B=%d C=%d | I=%d F=%d" % [
		test_count, 1 if inputs[0] else 0, 1 if inputs[1] else 0, 1 if inputs[2] else 0,
		1 if bool(result.get("inter", false)) else 0,
		1 if bool(result.get("final", false)) else 0
	])

	var evaluation := _evaluate_control_vectors()
	var is_correct := bool(evaluation.get("ok", false))
	last_counterexample.clear()

	if is_correct:
		is_complete = true
		btn_next.visible = true
		btn_hint.disabled = true
		btn_test.disabled = true
		_disable_controls()
		_show_feedback("PASS: control vectors satisfied.", Color(0.45, 0.92, 0.62))
		_register_trial("SUCCESS", true)
	else:
		attempts += 1
		var penalty := 15.0 + float(attempts * 5)
		_apply_penalty(penalty)
		var counterexample: Dictionary = evaluation.get("counterexample", {})
		last_counterexample = counterexample.duplicate()
		if not counterexample.is_empty():
			var fail_msg := "FAIL: A=%d B=%d C=%d -> expected F=%d, got F=%d (-%d)." % [
				int(counterexample.get("a", 0)),
				int(counterexample.get("b", 0)),
				int(counterexample.get("c", 0)),
				int(counterexample.get("expected_f", 0)),
				int(counterexample.get("actual_f", 0)),
				int(penalty)
			]
			_show_feedback(fail_msg, Color(1.0, 0.35, 0.32))
			_append_trace("COUNTEREXAMPLE | A=%d B=%d C=%d | I expected=%d got=%d | F expected=%d got=%d" % [
				int(counterexample.get("a", 0)),
				int(counterexample.get("b", 0)),
				int(counterexample.get("c", 0)),
				int(counterexample.get("expected_i", 0)),
				int(counterexample.get("actual_i", 0)),
				int(counterexample.get("expected_f", 0)),
				int(counterexample.get("actual_f", 0))
			])
		else:
			_show_feedback("FAIL: control vectors mismatch (-%d)." % int(penalty), Color(1.0, 0.35, 0.32))
		_register_trial("WRONG_GATE", false)
		if attempts >= MAX_ATTEMPTS:
			_enter_safe_mode()

	_update_terminal()
	_update_ui_state()

func _on_hint_pressed() -> void:
	if is_complete or is_safe_mode:
		return
	var now_sec := Time.get_ticks_msec() / 1000.0
	if now_sec < analyze_cooldown_until:
		_show_feedback("ANALYZE OVERHEAT: wait %ds." % int(ceil(analyze_cooldown_until - now_sec)), Color(1.0, 0.78, 0.32))
		_update_ui_state()
		return

	_mark_first_action()
	hints_used += 1
	analyze_cooldown_until = now_sec + ANALYZE_COOLDOWN_SECONDS

	if not last_counterexample.is_empty():
		_show_feedback("ANALYZE: mismatch at A=%d B=%d C=%d (expected F=%d, got F=%d)." % [
			int(last_counterexample.get("a", 0)),
			int(last_counterexample.get("b", 0)),
			int(last_counterexample.get("c", 0)),
			int(last_counterexample.get("expected_f", 0)),
			int(last_counterexample.get("actual_f", 0))
		], Color(0.56, 0.78, 0.96))
	else:
		_show_feedback("ANALYZE: " + str(current_case.get("hint", "Run TEST for a counterexample.")), Color(0.56, 0.78, 0.96))
	_append_trace("ANALYZE used.")
	_update_terminal()
	_update_ui_state()
	_update_stats_ui()

func _enter_safe_mode() -> void:
	is_safe_mode = true
	is_complete = true
	btn_next.visible = true
	btn_test.disabled = true
	btn_hint.disabled = true

	var correct: Array = current_case.get("correct_gates", [])
	placed_gates[0] = str(correct[0])
	placed_gates[1] = str(correct[1])
	_update_slot_visual(0)
	_update_slot_visual(1)
	_update_outputs()
	_disable_controls()
	_set_gate_buttons_enabled(false)
	_clear_gate_button_presses()

	var safe_msg := "SAFE MODE: SLOT1=%s, SLOT2=%s" % [_gate_symbol(placed_gates[0]), _gate_symbol(placed_gates[1])]
	_show_feedback(safe_msg, Color(1.0, 0.74, 0.32))
	_append_trace(safe_msg)
	_show_diagnostics("SAFE MODE", "ﾐ湲ﾐｰﾐｲﾐｸﾐｻﾑ糊ｽﾐｰﾑ・ﾐｺﾐｾﾐｽﾑ・ｸﾐｳﾑτﾐｰﾑ・ｸﾑ・ﾐｿﾐｾﾐｴﾑ・ひｰﾐｲﾐｻﾐｵﾐｽﾐｰ ﾐｰﾐｲﾑひｾﾐｼﾐｰﾑひｸﾑ・ｵﾑ・ｺﾐｸ.\nﾐ侑ｷﾑτ・ｸﾑひｵ ﾑ・ｱﾐｾﾑﾐｺﾑ・ﾐｸ ﾐｿﾐｵﾑﾐｵﾑ・ｾﾐｴﾐｸﾑひｵ ﾐｴﾐｰﾐｻﾐｵﾐｵ.")
	_update_terminal()
	_update_ui_state()

func _disable_controls() -> void:
	input_a_btn.disabled = true
	input_b_btn.disabled = true
	input_c_btn.disabled = true
	slot1_btn.disabled = true
	slot2_btn.disabled = true

func _on_game_over() -> void:
	_enter_safe_mode()

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _on_next_button_pressed() -> void:
	_hide_diagnostics()
	load_case(current_case_idx + 1)

func _on_diagnostics_close_pressed() -> void:
	_hide_diagnostics()

func _show_diagnostics(title: String, message: String) -> void:
	diagnostics_title.text = title
	diagnostics_text.text = message
	diagnostics_blocker.visible = true
	diagnostics_panel.visible = true
	diagnostics_next_button.grab_focus()

func _hide_diagnostics() -> void:
	diagnostics_blocker.visible = false
	diagnostics_panel.visible = false

func _set_gate_buttons_enabled(enabled: bool) -> void:
	for gate_id in gate_buttons.keys():
		var gate_btn: Button = gate_buttons[gate_id]
		gate_btn.disabled = not enabled

func _clear_gate_button_presses() -> void:
	for gate_id in gate_buttons.keys():
		var gate_btn: Button = gate_buttons[gate_id]
		gate_btn.set_pressed_no_signal(false)

func _append_trace(line: String) -> void:
	trace_lines.append(line)
	if trace_lines.size() > 12:
		trace_lines.remove_at(0)

func _update_terminal() -> void:
	var lines: Array[String] = []
	lines.append("[b]ﾐ岱ﾐ侑､ﾐ侑斷甜/b]")
	lines.append(str(current_case.get("story", "")))
	lines.append("")
	lines.append("[b]TRACE[/b]")
	if trace_lines.is_empty():
		lines.append("窶｢ ﾐ孟｣ﾐﾐ斷籍・ﾐ渙｣ﾐ｡ﾐ｢")
	else:
		for i in range(trace_lines.size()):
			var row := "窶｢ " + trace_lines[i]
			if i == trace_lines.size() - 1:
				row = "[color=#f4f2e6]> %s[/color]" % row
			lines.append(row)
	terminal_text.text = "\n".join(lines)

func _show_feedback(msg: String, col: Color) -> void:
	feedback_label.text = msg
	feedback_label.add_theme_color_override("font_color", col)
	feedback_label.visible = true

func _update_ui_state() -> void:
	var filled_slots := 0
	if placed_gates[0] != GATE_NONE:
		filled_slots += 1
	if placed_gates[1] != GATE_NONE:
		filled_slots += 1

	var step_text := ""
	if is_complete:
		step_text = "ﾐｨﾐ籍・3/3: ﾐｿﾑﾐｾﾐｲﾐｵﾑﾐｺﾐｰ ﾐｷﾐｰﾐｲﾐｵﾑﾑ威ｵﾐｽﾐｰ, ﾐｿﾐｵﾑﾐｵﾑ・ｾﾐｴﾐｸﾑひｵ ﾐｴﾐｰﾐｻﾐｵﾐｵ"
	elif filled_slots < 2:
		step_text = "ﾐｨﾐ籍・1/3: ﾐｲﾑ巾ｱﾐｵﾑﾐｸﾑひｵ ﾑ・ｻﾐｾﾑ・ﾐｸ ﾑτ・ひｰﾐｽﾐｾﾐｲﾐｸﾑひｵ 2 ﾐｼﾐｾﾐｴﾑσｻﾑ・
	else:
		step_text = "ﾐｨﾐ籍・2/3: ﾐｽﾐｰﾐｶﾐｼﾐｸﾑひｵ ﾐ渙ﾐ榧漬片ﾐ侑｢ﾐｬ"

	target_label.text = step_text
	facts_bar.value = 100.0 if is_complete else float(filled_slots) * 50.0
	energy_bar.value = clampf(GlobalMetrics.stability, 0.0, 100.0)
	btn_test.disabled = is_complete or is_safe_mode or filled_slots < 2
	var cooldown_left: int = maxi(0, int(ceil(analyze_cooldown_until - (Time.get_ticks_msec() / 1000.0))))
	if is_complete or is_safe_mode:
		btn_hint.disabled = true
	elif cooldown_left > 0:
		btn_hint.disabled = true
		btn_hint.text = "OVERHEAT %ds" % cooldown_left
	else:
		btn_hint.disabled = false
		btn_hint.text = "ANALYZE"
	_update_stats_ui()

func _update_stats_ui() -> void:
	var case_id := str(current_case.get("id", "B_00"))
	session_label.text = "ﾐ｡ﾐ片｡ﾐ｡ﾐ侑ｯ: %02d/%02d 窶｢ CASE %s" % [current_case_idx + 1, CASES.size(), case_id]
	stats_label.text = "ﾐ渙榧・ %d/%d 窶｢ ﾐ｢ﾐ片｡ﾐ｢ﾐｫ: %d 窶｢ ﾐ｡ﾐ｢ﾐ籍・ %d%%" % [
		attempts,
		MAX_ATTEMPTS,
		test_count,
		int(GlobalMetrics.stability)
	]

func _apply_penalty(amount: float) -> void:
	GlobalMetrics.stability = max(0.0, GlobalMetrics.stability - amount)
	GlobalMetrics.stability_changed.emit(GlobalMetrics.stability, -amount)

func _update_stability_ui(val: float, _diff: float) -> void:
	energy_bar.value = clampf(val, 0.0, 100.0)
	_update_stats_ui()

func _mark_first_action() -> void:
	if first_action_ms < 0:
		first_action_ms = Time.get_ticks_msec() - case_started_ms

func _register_trial(verdict_code: String, is_correct: bool) -> void:
	var case_id := str(current_case.get("id", "B_00"))
	var variant_hash := str(hash("%s|%s|%s" % [str(current_case.get("layout", "")), placed_gates[0], placed_gates[1]]))
	var payload := TrialV2.build("LOGIC_QUEST", "B", case_id, "MODULE_ASSEMBLY", variant_hash)
	var elapsed_ms := maxi(0, Time.get_ticks_msec() - case_started_ms)
	payload["elapsed_ms"] = elapsed_ms
	payload["duration"] = float(elapsed_ms) / 1000.0
	payload["time_to_first_action_ms"] = first_action_ms if first_action_ms >= 0 else elapsed_ms
	payload["is_correct"] = is_correct
	payload["is_fit"] = is_correct
	payload["stability_delta"] = 0
	payload["verdict_code"] = verdict_code
	payload["attempts"] = attempts
	payload["hints_used"] = hints_used
	payload["analyze_count"] = hints_used
	payload["test_count"] = test_count
	payload["placed_gates"] = placed_gates.duplicate()
	payload["correct_gates"] = current_case.get("correct_gates", []).duplicate()
	payload["inputs"] = [inputs[0], inputs[1], inputs[2]]
	if not last_counterexample.is_empty():
		payload["counterexample"] = last_counterexample.duplicate()
	GlobalMetrics.register_trial(payload)

func _play_click() -> void:
	if click_player.stream:
		click_player.play()

func _on_viewport_size_changed() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var compact: bool = viewport_size.x < 980.0 or viewport_size.y < 760.0

	_apply_safe_area_padding(compact)
	main_layout.add_theme_constant_override("separation", 6 if compact else 8)
	interaction_row.add_theme_constant_override("separation", 8 if compact else 12)
	actions_row.add_theme_constant_override("separation", 10 if compact else 16)
	gates_container.add_theme_constant_override("separation", 10 if compact else 14)
	terminal_text.add_theme_font_size_override("normal_font_size", 18 if compact else 20)
	stats_label.add_theme_font_size_override("font_size", 16 if compact else 18)
	feedback_label.add_theme_font_size_override("font_size", 16 if compact else 18)

	_set_interaction_mobile_mode(compact)
	var frame_width: float = 160.0 if compact else 200.0
	var slot_width: float = 132.0 if compact else 160.0
	for frame in [input_a_frame, input_b_frame, input_c_frame, slot1_frame, slot2_frame]:
		frame.custom_minimum_size.x = frame_width
	for frame in [inter_slot, output_slot]:
		frame.custom_minimum_size.x = slot_width

	var ctl_button_height: float = 52.0 if compact else 56.0
	input_a_btn.custom_minimum_size.y = ctl_button_height
	input_b_btn.custom_minimum_size.y = ctl_button_height
	input_c_btn.custom_minimum_size.y = ctl_button_height
	slot1_btn.custom_minimum_size.y = ctl_button_height
	slot2_btn.custom_minimum_size.y = ctl_button_height
	btn_hint.custom_minimum_size.y = ctl_button_height
	btn_test.custom_minimum_size.y = ctl_button_height
	btn_next.custom_minimum_size.y = ctl_button_height
	for gate_button in [gate_and_btn, gate_or_btn, gate_not_btn, gate_xor_btn, gate_nand_btn, gate_nor_btn]:
		gate_button.custom_minimum_size = Vector2(108.0, 56.0) if compact else Vector2(128.0, 64.0)

	var popup_width: float = clampf(viewport_size.x - (24.0 if compact else 120.0), 300.0, 760.0)
	var popup_height: float = clampf(viewport_size.y - (24.0 if compact else 120.0), 220.0, 440.0)
	diagnostics_panel.offset_left = -popup_width * 0.5
	diagnostics_panel.offset_top = -popup_height * 0.5
	diagnostics_panel.offset_right = popup_width * 0.5
	diagnostics_panel.offset_bottom = popup_height * 0.5

func _set_interaction_mobile_mode(use_mobile: bool) -> void:
	var mobile_layout: VBoxContainer = _ensure_interaction_mobile_layout()
	if use_mobile:
		if interaction_row.visible:
			for panel in _interaction_panels():
				if panel.get_parent() != mobile_layout:
					panel.reparent(mobile_layout)
				panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		interaction_row.visible = false
		mobile_layout.visible = true
	else:
		if not interaction_row.visible:
			for panel in _interaction_panels():
				if panel.get_parent() != interaction_row:
					panel.reparent(interaction_row)
				panel.size_flags_horizontal = Control.SIZE_FILL
		mobile_layout.visible = false
		interaction_row.visible = true

func _ensure_interaction_mobile_layout() -> VBoxContainer:
	if _interaction_mobile_layout != null and is_instance_valid(_interaction_mobile_layout):
		return _interaction_mobile_layout
	_interaction_mobile_layout = VBoxContainer.new()
	_interaction_mobile_layout.name = "InteractionMobileLayout"
	_interaction_mobile_layout.visible = false
	_interaction_mobile_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_interaction_mobile_layout.add_theme_constant_override("separation", 8)
	main_layout.add_child(_interaction_mobile_layout)
	main_layout.move_child(_interaction_mobile_layout, main_layout.get_children().find(interaction_row) + 1)
	return _interaction_mobile_layout

func _interaction_panels() -> Array[Control]:
	return [
		input_a_frame,
		input_b_frame,
		input_c_frame,
		slot1_frame,
		slot2_frame,
		inter_slot,
		output_slot
	]

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

func _gate_symbol(gate_id: String) -> String:
	match gate_id:
		GATE_AND:
			return "竏ｧ"
		GATE_OR:
			return "竏ｨ"
		GATE_NOT:
			return "ﾂｬ"
		GATE_XOR:
			return "竓・
		GATE_NAND:
			return "竓ｼ"
		GATE_NOR:
			return "竓ｽ"
		_:
			return "?"
