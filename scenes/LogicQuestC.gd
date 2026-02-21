extends Control

const MAX_ATTEMPTS := 3

const CASES := [
	{
		"id": "C_01",
		"story": "Упростите формулу без изменения смысла: A AND (B OR C).",
		"vars": ["A", "B", "C"],
		"expr_start": ["OR", ["AND", "A", "B"], ["AND", "A", "C"]],
		"target_gates": 3,
		"options": [
			{
				"label": "A ∧ (B ∨ C)",
				"expr": ["AND", "A", ["OR", "B", "C"]],
				"explain": "Дистрибутивность: A∧B ∨ A∧C = A∧(B∨C)."
			},
			{
				"label": "(A ∨ B) ∧ C",
				"expr": ["AND", ["OR", "A", "B"], "C"],
				"explain": "Порядок переменных изменен некорректно."
			},
			{
				"label": "A ∨ (B ∧ C)",
				"expr": ["OR", "A", ["AND", "B", "C"]],
				"explain": "Это другая формула, не эквивалентная исходной."
			}
		]
	},
	{
		"id": "C_02",
		"story": "Проверьте поглощение: A OR (A AND B).",
		"vars": ["A", "B"],
		"expr_start": ["OR", "A", ["AND", "A", "B"]],
		"target_gates": 1,
		"options": [
			{
				"label": "A",
				"expr": "A",
				"explain": "Закон поглощения: A ∨ (A ∧ B) = A."
			},
			{
				"label": "A ∧ B",
				"expr": ["AND", "A", "B"],
				"explain": "Слишком сильное ограничение."
			},
			{
				"label": "A ∨ B",
				"expr": ["OR", "A", "B"],
				"explain": "Добавляет лишние истинные случаи."
			}
		]
	},
	{
		"id": "C_03",
		"story": "Примените закон де Моргана к NOT(A AND B).",
		"vars": ["A", "B"],
		"expr_start": ["NOT", ["AND", "A", "B"]],
		"target_gates": 3,
		"options": [
			{
				"label": "¬A ∨ ¬B",
				"expr": ["OR", ["NOT", "A"], ["NOT", "B"]],
				"explain": "Корректный закон де Моргана."
			},
			{
				"label": "¬A ∧ ¬B",
				"expr": ["AND", ["NOT", "A"], ["NOT", "B"]],
				"explain": "Это форма для NOT(A OR B), а не для AND."
			},
			{
				"label": "A ∨ B",
				"expr": ["OR", "A", "B"],
				"explain": "Инверсия полностью потеряна."
			}
		]
	},
	{
		"id": "C_04",
		"story": "Сократите двойное отрицание: NOT(NOT(A)).",
		"vars": ["A"],
		"expr_start": ["NOT", ["NOT", "A"]],
		"target_gates": 0,
		"options": [
			{
				"label": "A",
				"expr": "A",
				"explain": "Двойное отрицание убирается: ¬¬A = A."
			},
			{
				"label": "¬A",
				"expr": ["NOT", "A"],
				"explain": "Инверсия осталась, это другая формула."
			},
			{
				"label": "0",
				"expr": false,
				"explain": "Константа 0 не эквивалентна переменной A."
			}
		]
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

@onready var expr_value_label: RichTextLabel = $SafeArea/MainLayout/InteractionRow/ExprSlot/ExprVBox/ExprValue
@onready var patch_value_label: Label = $SafeArea/MainLayout/InteractionRow/PatchSlot/PatchVBox/PatchValue
@onready var load_bar: ProgressBar = $SafeArea/MainLayout/InteractionRow/LoadSlot/LoadVBox/LoadBar
@onready var load_label: Label = $SafeArea/MainLayout/InteractionRow/LoadSlot/LoadVBox/LoadLabel
@onready var patch_container: VBoxContainer = $SafeArea/MainLayout/InventoryFrame/InventoryMargin/InventoryScroll/PatchContainer

@onready var btn_hint: Button = $SafeArea/MainLayout/Actions/BtnHint
@onready var btn_scan: Button = $SafeArea/MainLayout/Actions/BtnScan
@onready var btn_next: Button = $SafeArea/MainLayout/Actions/BtnNext
@onready var btn_back: Button = $SafeArea/MainLayout/Header/BtnBack

@onready var diagnostics_blocker: ColorRect = $DiagnosticsBlocker
@onready var diagnostics_panel: PanelContainer = $DiagnosticsPanelC
@onready var diagnostics_title: Label = $DiagnosticsPanelC/PopupMargin/PopupVBox/PopupTitle
@onready var diagnostics_text: RichTextLabel = $DiagnosticsPanelC/PopupMargin/PopupVBox/PopupText
@onready var diagnostics_next_button: Button = $DiagnosticsPanelC/PopupMargin/PopupVBox/PopupBtnNext
@onready var click_player: AudioStreamPlayer = $ClickPlayer

var current_case_idx: int = 0
var current_case: Dictionary = {}
var attempts: int = 0
var hints_used: int = 0
var scan_count: int = 0
var selected_option_idx: int = -1
var is_complete: bool = false
var is_safe_mode: bool = false
var is_locked: bool = false
var case_started_ms: int = 0
var first_action_ms: int = -1
var patch_press_count: int = 0
var trace_lines: Array[String] = []
var patch_buttons: Array[Button] = []

func _ready() -> void:
	_connect_ui_signals()
	_update_stability_ui(GlobalMetrics.stability, 0.0)
	if not GlobalMetrics.stability_changed.is_connected(_update_stability_ui):
		GlobalMetrics.stability_changed.connect(_update_stability_ui)
	if not GlobalMetrics.game_over.is_connected(_on_game_over):
		GlobalMetrics.game_over.connect(_on_game_over)
	load_case(0)

func _connect_ui_signals() -> void:
	if not btn_back.pressed.is_connected(_on_back_pressed):
		btn_back.pressed.connect(_on_back_pressed)
	if not btn_hint.pressed.is_connected(_on_hint_pressed):
		btn_hint.pressed.connect(_on_hint_pressed)
	if not btn_scan.pressed.is_connected(_on_scan_pressed):
		btn_scan.pressed.connect(_on_scan_pressed)
	if not btn_next.pressed.is_connected(_on_next_pressed):
		btn_next.pressed.connect(_on_next_pressed)
	if not diagnostics_next_button.pressed.is_connected(_on_diagnostics_close_pressed):
		diagnostics_next_button.pressed.connect(_on_diagnostics_close_pressed)

func load_case(idx: int) -> void:
	if idx >= CASES.size():
		idx = 0

	current_case_idx = idx
	current_case = CASES[idx]
	attempts = 0
	hints_used = 0
	scan_count = 0
	selected_option_idx = -1
	is_complete = false
	is_safe_mode = false
	is_locked = false
	case_started_ms = Time.get_ticks_msec()
	first_action_ms = -1
	patch_press_count = 0
	trace_lines.clear()

	clue_title_label.text = "ДЕТЕКТОР ЛЖИ C-01"
	btn_hint.disabled = false
	btn_scan.disabled = true
	btn_next.visible = false
	feedback_label.visible = false
	feedback_label.text = ""
	_hide_diagnostics()

	expr_value_label.text = "[b]%s[/b]" % _format_expr(current_case.get("expr_start"))
	patch_value_label.text = "PATCH: EMPTY"
	var base_load := count_gates(current_case.get("expr_start"))
	load_bar.max_value = maxi(base_load, int(current_case.get("target_gates", 0))) + 2
	load_bar.value = base_load
	load_label.text = "LOAD: %d / %d" % [base_load, int(current_case.get("target_gates", 0))]
	_create_patch_buttons()

	_append_trace("Сценарий загружен. Выберите патч и запустите СКАН.")
	_update_terminal()
	_update_ui_state()
	_update_stats_ui()

func _create_patch_buttons() -> void:
	for child in patch_container.get_children():
		child.queue_free()
	patch_buttons.clear()

	var options: Array = current_case.get("options", [])
	for i in range(options.size()):
		var option: Dictionary = options[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 64)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.text = str(option.get("label", "PATCH"))
		btn.pressed.connect(_on_patch_pressed.bind(i))
		patch_container.add_child(btn)
		patch_buttons.append(btn)

func _on_patch_pressed(option_idx: int) -> void:
	if is_complete or is_safe_mode or is_locked:
		return
	_mark_first_action()
	selected_option_idx = option_idx
	patch_press_count += 1

	for i in range(patch_buttons.size()):
		patch_buttons[i].add_theme_color_override("font_color", Color(0.95, 0.95, 0.90, 1.0) if i == option_idx else Color(0.74, 0.74, 0.70, 1.0))

	var option: Dictionary = current_case.get("options", [])[option_idx]
	patch_value_label.text = "PATCH: %s" % str(option.get("label", ""))
	_append_trace("PATCH SELECTED: %s" % str(option.get("label", "")))
	_show_feedback("Патч выбран. Запустите СКАН.", Color(0.56, 0.78, 0.96))
	btn_scan.disabled = false
	_update_terminal()
	_update_ui_state()
	_play_click()

func _on_scan_pressed() -> void:
	if is_complete or is_safe_mode or is_locked:
		return
	if selected_option_idx < 0:
		return
	_mark_first_action()
	scan_count += 1

	var option: Dictionary = current_case.get("options", [])[selected_option_idx]
	var start_expr: Variant = current_case.get("expr_start")
	var selected_expr: Variant = option.get("expr")
	var vars: Array = current_case.get("vars", [])
	var eq_result: Dictionary = equivalent(start_expr, selected_expr, vars)

	_append_trace("SCAN #%d: %s" % [scan_count, str(option.get("label", ""))])

	if bool(eq_result.get("ok", false)):
		is_complete = true
		btn_next.visible = true
		btn_hint.disabled = true
		btn_scan.disabled = true
		for btn in patch_buttons:
			btn.disabled = true

		var new_load := count_gates(selected_expr)
		load_bar.value = new_load
		load_label.text = "LOAD: %d / %d" % [new_load, int(current_case.get("target_gates", 0))]
		expr_value_label.text = "[b]%s[/b]" % _format_expr(selected_expr)
		_show_feedback("EQUIVALENT: патч принят.", Color(0.45, 0.92, 0.62))
		_append_trace("RESULT: EQUIVALENT ✅")
		_register_trial("SUCCESS", true, {
			"selected_label": str(option.get("label", "")),
			"new_load": new_load,
			"target_load": int(current_case.get("target_gates", 0))
		})
	else:
		attempts += 1
		var penalty := 15.0 + float(attempts * 5)
		_apply_penalty(penalty)
		var counterexample: Dictionary = eq_result.get("counterexample", {})
		_show_feedback("NOT EQUIVALENT: найден контрпример (-%d)." % int(penalty), Color(1.0, 0.35, 0.32))
		_append_trace("RESULT: NOT EQUIVALENT ❌ %s | orig=%d new=%d" % [
			_format_counterexample(counterexample),
			1 if bool(eq_result.get("orig", false)) else 0,
			1 if bool(eq_result.get("new", false)) else 0
		])
		_register_trial("NOT_EQUIVALENT", false, {
			"selected_label": str(option.get("label", "")),
			"counterexample": counterexample,
			"orig_value": bool(eq_result.get("orig", false)),
			"new_value": bool(eq_result.get("new", false))
		})
		if attempts >= MAX_ATTEMPTS:
			_enter_safe_mode()
		else:
			_lock_controls(1.2)

	_update_terminal()
	_update_ui_state()
	_update_stats_ui()
	_play_click()

func _on_hint_pressed() -> void:
	if is_complete or is_safe_mode:
		return
	_mark_first_action()
	hints_used += 1
	_apply_penalty(5.0)

	var correct_idx := _find_correct_option_idx()
	if correct_idx >= 0:
		var option: Dictionary = current_case.get("options", [])[correct_idx]
		_show_feedback("Подсказка: ориентируйтесь на %s..." % str(option.get("label", "")).substr(0, 8), Color(0.56, 0.78, 0.96))
	else:
		_show_feedback("Подсказка недоступна.", Color(0.66, 0.66, 0.66))
	_append_trace("HINT: -5 stability.")
	_update_terminal()
	_update_ui_state()
	_update_stats_ui()

func _enter_safe_mode() -> void:
	is_safe_mode = true
	is_complete = true
	btn_next.visible = true
	btn_hint.disabled = true
	btn_scan.disabled = true

	var correct_idx := _find_correct_option_idx()
	if correct_idx >= 0:
		selected_option_idx = correct_idx
		for i in range(patch_buttons.size()):
			patch_buttons[i].disabled = true
			patch_buttons[i].add_theme_color_override("font_color", Color(0.45, 0.92, 0.62, 1.0) if i == correct_idx else Color(0.60, 0.60, 0.58, 1.0))
		var correct_option: Dictionary = current_case.get("options", [])[correct_idx]
		patch_value_label.text = "PATCH: %s" % str(correct_option.get("label", ""))
		_append_trace("SAFE MODE: правильный патч %s" % str(correct_option.get("label", "")))
		_show_feedback("SAFE MODE: правильный патч подставлен.", Color(1.0, 0.74, 0.32))
		_show_diagnostics("SAFE MODE", "Обнаружено превышение порога ошибок.\nПравильный патч подсвечен, изучите разбор и переходите далее.")
	else:
		for btn in patch_buttons:
			btn.disabled = true
		_show_feedback("SAFE MODE: патч заблокирован.", Color(1.0, 0.74, 0.32))

	_update_terminal()
	_update_ui_state()
	_update_stats_ui()

func _lock_controls(seconds: float) -> void:
	is_locked = true
	btn_scan.disabled = true
	var timer := get_tree().create_timer(seconds)
	await timer.timeout
	if is_complete or is_safe_mode:
		return
	is_locked = false
	btn_scan.disabled = selected_option_idx < 0

func _find_correct_option_idx() -> int:
	var options: Array = current_case.get("options", [])
	for i in range(options.size()):
		var option: Dictionary = options[i]
		var result: Dictionary = equivalent(current_case.get("expr_start"), option.get("expr"), current_case.get("vars", []))
		if bool(result.get("ok", false)):
			return i
	return -1

func _format_counterexample(env: Dictionary) -> String:
	if env.is_empty():
		return "N/A"
	var keys := env.keys()
	keys.sort()
	var parts: Array[String] = []
	for key in keys:
		parts.append("%s=%d" % [str(key), 1 if bool(env[key]) else 0])
	return ", ".join(parts)

func eval_expr(expr: Variant, env: Dictionary) -> bool:
	if typeof(expr) == TYPE_BOOL:
		return bool(expr)
	if typeof(expr) == TYPE_STRING:
		return bool(env.get(expr, false))
	if typeof(expr) == TYPE_ARRAY:
		var arr: Array = expr
		var op := str(arr[0])
		match op:
			"AND":
				for i in range(1, arr.size()):
					if not eval_expr(arr[i], env):
						return false
				return true
			"OR":
				for i in range(1, arr.size()):
					if eval_expr(arr[i], env):
						return true
				return false
			"NOT":
				return not eval_expr(arr[1], env)
			"XOR":
				return eval_expr(arr[1], env) != eval_expr(arr[2], env)
	return false

func count_gates(expr: Variant) -> int:
	if typeof(expr) != TYPE_ARRAY:
		return 0
	var arr: Array = expr
	var total := 1
	for i in range(1, arr.size()):
		total += count_gates(arr[i])
	return total

func equivalent(expr1: Variant, expr2: Variant, vars: Array) -> Dictionary:
	var combinations := 1 << vars.size()
	for i in range(combinations):
		var env := {}
		for bit in range(vars.size()):
			env[vars[bit]] = (i & (1 << bit)) != 0
		var val1 := eval_expr(expr1, env)
		var val2 := eval_expr(expr2, env)
		if val1 != val2:
			return {"ok": false, "counterexample": env, "orig": val1, "new": val2}
	return {"ok": true}

func _format_expr(expr: Variant) -> String:
	if typeof(expr) == TYPE_STRING:
		return str(expr)
	if typeof(expr) == TYPE_BOOL:
		return "1" if bool(expr) else "0"
	if typeof(expr) == TYPE_ARRAY:
		var arr: Array = expr
		var op := str(arr[0])
		match op:
			"NOT":
				return "¬%s" % _format_expr_sub(arr[1])
			"AND":
				var parts_and: Array[String] = []
				for i in range(1, arr.size()):
					parts_and.append(_format_expr_sub(arr[i]))
				return " ∧ ".join(parts_and)
			"OR":
				var parts_or: Array[String] = []
				for i in range(1, arr.size()):
					parts_or.append(_format_expr_sub(arr[i]))
				return " ∨ ".join(parts_or)
			"XOR":
				return "%s ⊕ %s" % [_format_expr_sub(arr[1]), _format_expr_sub(arr[2])]
	return "?"

func _format_expr_sub(expr: Variant) -> String:
	if typeof(expr) == TYPE_ARRAY and str((expr as Array)[0]) != "NOT":
		return "(%s)" % _format_expr(expr)
	return _format_expr(expr)

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
	if is_complete:
		target_label.text = "ШАГ 3/3: проверка завершена, переходите далее"
		facts_bar.value = 100.0
	elif selected_option_idx < 0:
		target_label.text = "ШАГ 1/3: выберите патч в инвентаре"
		facts_bar.value = 0.0
	else:
		target_label.text = "ШАГ 2/3: нажмите СКАН для проверки эквивалентности"
		facts_bar.value = 50.0
	energy_bar.value = clampf(GlobalMetrics.stability, 0.0, 100.0)
	btn_scan.disabled = is_complete or is_safe_mode or is_locked or selected_option_idx < 0

func _update_stats_ui() -> void:
	var case_id := str(current_case.get("id", "C_00"))
	session_label.text = "СЕССИЯ: %02d/%02d • CASE %s" % [current_case_idx + 1, CASES.size(), case_id]
	stats_label.text = "ПОП: %d/%d • СКАНЫ: %d • СТАБ: %d%%" % [
		attempts,
		MAX_ATTEMPTS,
		scan_count,
		int(GlobalMetrics.stability)
	]

func _apply_penalty(amount: float) -> void:
	GlobalMetrics.stability = max(0.0, GlobalMetrics.stability - amount)
	GlobalMetrics.stability_changed.emit(GlobalMetrics.stability, -amount)

func _update_stability_ui(val: float, _diff: float) -> void:
	energy_bar.value = clampf(val, 0.0, 100.0)
	_update_stats_ui()

func _show_diagnostics(title: String, message: String) -> void:
	diagnostics_title.text = title
	diagnostics_text.text = message
	diagnostics_blocker.visible = true
	diagnostics_panel.visible = true
	diagnostics_next_button.grab_focus()

func _hide_diagnostics() -> void:
	diagnostics_blocker.visible = false
	diagnostics_panel.visible = false

func _on_diagnostics_close_pressed() -> void:
	_hide_diagnostics()

func _on_next_pressed() -> void:
	_hide_diagnostics()
	load_case(current_case_idx + 1)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _on_game_over() -> void:
	_enter_safe_mode()

func _mark_first_action() -> void:
	if first_action_ms < 0:
		first_action_ms = Time.get_ticks_msec() - case_started_ms

func _register_trial(verdict_code: String, is_correct: bool, extra: Dictionary = {}) -> void:
	var case_id := str(current_case.get("id", "C_00"))
	var variant_hash := str(hash(JSON.stringify(current_case.get("expr_start", []))))
	var payload := TrialV2.build("LOGIC_QUEST", "C", case_id, "PATCH_SCAN", variant_hash)
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
	payload["scan_count"] = scan_count
	payload["patch_press_count"] = patch_press_count
	payload["selected_option_idx"] = selected_option_idx
	for key in extra.keys():
		payload[key] = extra[key]
	GlobalMetrics.register_trial(payload)

func _play_click() -> void:
	if click_player.stream:
		click_player.play()
