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

const CASES := [
	{
		"id": "B_01",
		"layout": LAYOUT_CASCADE_TOP,
		"story": "Соберите двухэтапную схему: сначала узел A/B, затем результат с C.",
		"labels": ["ДАТЧИК A", "ДАТЧИК B", "ДАТЧИК C"],
		"correct_gates": [GATE_OR, GATE_AND],
		"hint": "Сначала объедините A и B через OR, затем примените AND с C."
	},
	{
		"id": "B_02",
		"layout": LAYOUT_CASCADE_BOTTOM,
		"story": "Схема перестроена: сначала обрабатывается пара B/C, затем узел A.",
		"labels": ["КЛЮЧ A", "КЛЮЧ B", "КЛЮЧ C"],
		"correct_gates": [GATE_AND, GATE_OR],
		"hint": "Во внутреннем слоте нужен AND, во внешнем слоте - OR."
	},
	{
		"id": "B_03",
		"layout": LAYOUT_CASCADE_TOP,
		"story": "Нужен канал, где первый этап ловит различие A/B, а второй фильтрует через C.",
		"labels": ["КАНАЛ A", "КАНАЛ B", "ФИЛЬТР C"],
		"correct_gates": [GATE_XOR, GATE_AND],
		"hint": "Различие на первом этапе даёт XOR."
	},
	{
		"id": "B_04",
		"layout": LAYOUT_CASCADE_BOTTOM,
		"story": "Схема с инверсией: сначала инвертируется B/C, затем объединяется с A.",
		"labels": ["ОПОРНЫЙ A", "ШУМ B", "ШУМ C"],
		"correct_gates": [GATE_NOR, GATE_OR],
		"hint": "Внутренний этап - NOR, внешний - OR."
	},
	{
		"id": "B_05",
		"layout": LAYOUT_CASCADE_TOP,
		"story": "Соберите устойчивый тракт с финальным отрицанием совпадения.",
		"labels": ["ЛИНИЯ A", "ЛИНИЯ B", "ЛИНИЯ C"],
		"correct_gates": [GATE_AND, GATE_NAND],
		"hint": "Сначала нужно совпадение A и B, затем отрицание с C."
	}
]

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
var is_complete: bool = false
var is_safe_mode: bool = false
var case_started_ms: int = 0
var first_action_ms: int = -1
var trace_lines: Array[String] = []

var gate_buttons: Dictionary = {}

func _ready() -> void:
	_connect_ui_signals()
	_setup_gate_buttons()
	_update_stability_ui(GlobalMetrics.stability, 0.0)
	if not GlobalMetrics.stability_changed.is_connected(_update_stability_ui):
		GlobalMetrics.stability_changed.connect(_update_stability_ui)
	if not GlobalMetrics.game_over.is_connected(_on_game_over):
		GlobalMetrics.game_over.connect(_on_game_over)
	load_case(0)

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
	is_complete = false
	is_safe_mode = false
	case_started_ms = Time.get_ticks_msec()
	first_action_ms = -1
	trace_lines.clear()

	clue_title_label.text = "ДЕТЕКТОР ЛЖИ B-01"
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
	_append_trace("Сценарий загружен. Выберите слот и установите модуль.")
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
	_show_feedback("Выбран SLOT 1. Установите модуль из инвентаря.", Color(0.56, 0.78, 0.96))
	_play_click()

func _on_slot2_pressed() -> void:
	if is_complete:
		return
	_mark_first_action()
	selected_slot_idx = 1
	_update_slot_selection_visual()
	_set_gate_buttons_enabled(true)
	_show_feedback("Выбран SLOT 2. Установите модуль из инвентаря.", Color(0.56, 0.78, 0.96))
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
		_show_feedback("Сначала выберите SLOT 1 или SLOT 2.", Color(1.0, 0.78, 0.32))
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
		slot_btn.text = "УСТАНОВИТЬ\n?"
	else:
		slot_btn.text = "УСТАНОВЛЕНО\n%s" % _gate_symbol(gate_id)

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
	var g1 := placed_gates[0]
	var g2 := placed_gates[1]
	var inter := false
	var final := false

	if str(current_case.get("layout", LAYOUT_CASCADE_TOP)) == LAYOUT_CASCADE_TOP:
		if g1 != GATE_NONE:
			inter = _gate_op(inputs[0], inputs[1], g1)
		if g2 != GATE_NONE:
			final = _gate_op(inter, inputs[2], g2)
	else:
		if g1 != GATE_NONE:
			inter = _gate_op(inputs[1], inputs[2], g1)
		if g2 != GATE_NONE:
			final = _gate_op(inputs[0], inter, g2)

	return {"inter": inter, "final": final}

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
		_show_feedback("Заполните оба слота перед проверкой.", Color(1.0, 0.78, 0.32))
		return

	test_count += 1
	var result := _calculate_circuit()
	_append_trace("TEST #%d | A=%d B=%d C=%d | I=%d F=%d" % [
		test_count, 1 if inputs[0] else 0, 1 if inputs[1] else 0, 1 if inputs[2] else 0,
		1 if bool(result.get("inter", false)) else 0,
		1 if bool(result.get("final", false)) else 0
	])

	var correct: Array = current_case.get("correct_gates", [])
	var is_correct := placed_gates[0] == str(correct[0]) and placed_gates[1] == str(correct[1])

	if is_correct:
		is_complete = true
		btn_next.visible = true
		btn_hint.disabled = true
		btn_test.disabled = true
		_disable_controls()
		_show_feedback("PASS: конфигурация подтверждена.", Color(0.45, 0.92, 0.62))
		_register_trial("SUCCESS", true)
	else:
		attempts += 1
		var penalty := 15.0 + float(attempts * 5)
		_apply_penalty(penalty)
		_show_feedback("FAIL: схема не прошла проверку (-%d)." % int(penalty), Color(1.0, 0.35, 0.32))
		_register_trial("WRONG_GATE", false)
		if attempts >= MAX_ATTEMPTS:
			_enter_safe_mode()

	_update_terminal()
	_update_ui_state()

func _on_hint_pressed() -> void:
	if is_complete:
		return
	_mark_first_action()
	hints_used += 1
	_apply_penalty(5.0)
	_show_feedback("Подсказка: %s" % str(current_case.get("hint", "")), Color(0.56, 0.78, 0.96))
	_append_trace("HINT: -5 stability.")
	_update_terminal()
	_update_ui_state()

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
	_show_diagnostics("SAFE MODE", "Правильная конфигурация подставлена автоматически.\nИзучите сборку и переходите далее.")
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
	lines.append("[b]БРИФИНГ[/b]")
	lines.append(str(current_case.get("story", "")))
	lines.append("")
	lines.append("[b]TRACE[/b]")
	if trace_lines.is_empty():
		lines.append("• ЖУРНАЛ ПУСТ")
	else:
		for i in range(trace_lines.size()):
			var row := "• " + trace_lines[i]
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
		step_text = "ШАГ 3/3: проверка завершена, переходите далее"
	elif filled_slots < 2:
		step_text = "ШАГ 1/3: выберите слот и установите 2 модуля"
	else:
		step_text = "ШАГ 2/3: нажмите ПРОВЕРИТЬ"

	target_label.text = step_text
	facts_bar.value = 100.0 if is_complete else float(filled_slots) * 50.0
	energy_bar.value = clampf(GlobalMetrics.stability, 0.0, 100.0)
	btn_test.disabled = is_complete or is_safe_mode or filled_slots < 2
	_update_stats_ui()

func _update_stats_ui() -> void:
	var case_id := str(current_case.get("id", "B_00"))
	session_label.text = "СЕССИЯ: %02d/%02d • CASE %s" % [current_case_idx + 1, CASES.size(), case_id]
	stats_label.text = "ПОП: %d/%d • ТЕСТЫ: %d • СТАБ: %d%%" % [
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
	payload["test_count"] = test_count
	payload["placed_gates"] = placed_gates.duplicate()
	payload["correct_gates"] = current_case.get("correct_gates", []).duplicate()
	payload["inputs"] = [inputs[0], inputs[1], inputs[2]]
	GlobalMetrics.register_trial(payload)

func _play_click() -> void:
	if click_player.stream:
		click_player.play()

func _gate_symbol(gate_id: String) -> String:
	match gate_id:
		GATE_AND:
			return "∧"
		GATE_OR:
			return "∨"
		GATE_NOT:
			return "¬"
		GATE_XOR:
			return "⊕"
		GATE_NAND:
			return "⊼"
		GATE_NOR:
			return "⊽"
		_:
			return "?"
