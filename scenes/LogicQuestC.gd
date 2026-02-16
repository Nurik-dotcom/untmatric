extends Control

# --- CONSTANTS & DATA ---
const CASES_C := [
	{
		"id": "C1_01",
		"story": "Главный сервер шумит. Убери лишние вентили, иначе ИИ заметит патч.",
		"vars": ["A","B","C"],
		"expr_start": ["OR", ["AND","A","B"], ["AND","A","C"]],
		"target_gates": 3,
		"options": [
			{
				"label": "A ∧ (B ∨ C)",
				"expr": ["AND","A", ["OR","B","C"]],
				"explain": "Дистрибутивность: вынесли общий множитель A."
			},
			{
				"label": "(A ∨ B) ∧ C",
				"expr": ["AND", ["OR","A","B"], "C"],
				"explain": "Похоже по словам, но неэквивалентно исходнику."
			},
			{
				"label": "A ∨ (B ∧ C)",
				"expr": ["OR","A", ["AND","B","C"]],
				"explain": "Другая логика: здесь A может сделать истину без B."
			}
		]
	},

	{
		"id": "C1_02",
		"story": "Защита дублирует проверку. Иногда проще значит безопаснее.",
		"vars": ["A","B"],
		"expr_start": ["OR", "A", ["AND","A","B"]],
		"target_gates": 1,
		"options": [
			{
				"label": "A",
				"expr": "A",
				"explain": "Поглощение: A ∨ (A ∧ B) = A."
			},
			{
				"label": "A ∧ B",
				"expr": ["AND","A","B"],
				"explain": "Слишком строго: теряешь случаи, где A=1 и B=0."
			},
			{
				"label": "A ∨ B",
				"expr": ["OR","A","B"],
				"explain": "Слишком широко: добавляет случаи, где A=0 и B=1."
			}
		]
	},

	{
		"id": "C1_03",
		"story": "ИИ сервера любит отрицания. Сделай так, чтобы он запутался меньше.",
		"vars": ["A","B"],
		"expr_start": ["NOT", ["AND","A","B"]],
		"target_gates": 3,
		"options": [
			{
				"label": "¬A ∨ ¬B",
				"expr": ["OR", ["NOT","A"], ["NOT","B"]],
				"explain": "Закон де Моргана: ¬(A ∧ B) = ¬A ∨ ¬B."
			},
			{
				"label": "¬A ∧ ¬B",
				"expr": ["AND", ["NOT","A"], ["NOT","B"]],
				"explain": "Это де Морган, но для ¬(A ∨ B), а не для ∧."
			},
			{
				"label": "A ∨ B",
				"expr": ["OR","A","B"],
				"explain": "Вообще без отрицания. Контрпример поймает быстро."
			}
		]
	},

	{
		"id": "C1_04",
		"story": "Сканер защиты видит лишний шум в скобках. Упрости без потери смысла.",
		"vars": ["A","B"],
		"expr_start": ["NOT", ["OR","A","B"]],
		"target_gates": 3,
		"options": [
			{
				"label": "¬A ∧ ¬B",
				"expr": ["AND", ["NOT","A"], ["NOT","B"]],
				"explain": "Де Морган: ¬(A ∨ B) = ¬A ∧ ¬B."
			},
			{
				"label": "¬A ∨ ¬B",
				"expr": ["OR", ["NOT","A"], ["NOT","B"]],
				"explain": "Это де Морган, но для ¬(A ∧ B)."
			},
			{
				"label": "A ∧ B",
				"expr": ["AND","A","B"],
				"explain": "Потеря отрицания меняет смысл полностью."
			}
		]
	},

	{
		"id": "C1_05",
		"story": "Двойная маскировка всегда палится. Сними лишний слой.",
		"vars": ["A"],
		"expr_start": ["NOT", ["NOT","A"]],
		"target_gates": 0,
		"options": [
			{
				"label": "A",
				"expr": "A",
				"explain": "Двойное отрицание: ¬¬A = A."
			},
			{
				"label": "¬A",
				"expr": ["NOT","A"],
				"explain": "Ты снял только один слой. Это другое."
			},
			{
				"label": "0 (FALSE)",
				"expr": false,
				"explain": "Нет, ¬¬A не превращает всё в ложь."
			}
		]
	},

	{
		"id": "C1_06",
		"story": "Два разных пути защиты ведут к одному и тому же пропуску. Склей их.",
		"vars": ["A","B"],
		"expr_start": ["OR", ["AND","A","B"], ["AND", ["NOT","A"], "B"]],
		"target_gates": 1,
		"options": [
			{
				"label": "B",
				"expr": "B",
				"explain": "Склеивание: (A∧B) ∨ (¬A∧B) = B."
			},
			{
				"label": "A",
				"expr": "A",
				"explain": "Контрпример: при A=0, B=1 исходник даёт 1, а A даёт 0."
			},
			{
				"label": "A ∨ B",
				"expr": ["OR","A","B"],
				"explain": "Слишком широко: добавляет случаи, где B=0 и A=1."
			}
		]
	}
]

# --- NODES ---
@onready var stats_label = $MainLayout/HeaderPanel/HeaderMargin/HeaderHBox/StatsLabel
@onready var stability_label = $MainLayout/HeaderPanel/HeaderMargin/HeaderHBox/StabilityLabel
@onready var story_text = $MainLayout/StoryPanel/Margin/StoryText

@onready var expr_panel = $MainLayout/ExprPanel
@onready var expr_text = $MainLayout/ExprPanel/Margin/VBox/ExprText
@onready var load_label = $MainLayout/ExprPanel/Margin/VBox/LoadHBox/LoadLabel
@onready var load_bar = $MainLayout/ExprPanel/Margin/VBox/LoadHBox/LoadBar

@onready var patch_list = $MainLayout/PatchPanel/Margin/VBox/PatchList
@onready var feedback_panel = $MainLayout/FeedbackPanel
@onready var feedback_text = $MainLayout/FeedbackPanel/Margin/FeedbackText

@onready var btn_hint = $MainLayout/BottomBar/BtnHint
@onready var btn_next = $MainLayout/BottomBar/BtnNext

@onready var safe_overlay = $SafeModeOverlay
@onready var safe_label = $SafeModeOverlay/Label
@onready var lock_overlay = $LockOverlay
@onready var game_over_panel = $GameOverPanel
@onready var audio_player = $AudioStreamPlayer

# --- STATE ---
var current_case_idx := 0
var current_case := {}
var attempts := 0
var is_locked := false
var is_complete := false
var case_started_ms: int = 0
var first_action_ms: int = -1
var patch_press_count: int = 0
var hints_used: int = 0

func _ready():
	GlobalMetrics.stability_changed.connect(_update_stability_ui)
	_update_stability_ui(GlobalMetrics.stability, 0)
	load_case(0)

# --- LOADING CASE ---
func load_case(idx: int):
	if idx >= CASES_C.size():
		idx = 0 # Loop or finish? Let's loop for now.

	current_case_idx = idx
	current_case = CASES_C[idx]
	attempts = 0
	is_complete = false
	is_locked = false
	case_started_ms = Time.get_ticks_msec()
	first_action_ms = -1
	patch_press_count = 0
	hints_used = 0

	# Reset UI
	stats_label.text = "CASE: %02d" % (idx + 1)
	story_text.text = current_case.story

	# Expression
	var start_expr = current_case.expr_start
	expr_text.text = _format_expr(start_expr)

	# Load
	var current_load = count_gates(start_expr)
	var target_load = current_case.target_gates
	load_bar.max_value = max(current_load, target_load) + 2 # Some headroom
	load_bar.value = current_load
	load_label.text = "LOAD: %d / %d" % [current_load, target_load]

	# Patches
	_create_patch_buttons(current_case.options)

	# Feedback
	feedback_panel.visible = true
	feedback_text.text = "[center]Select a patch to minimize load.[/center]"
	feedback_text.modulate = Color(0.7, 0.7, 0.7)

	btn_next.visible = false
	btn_hint.disabled = false
	safe_overlay.visible = false
	lock_overlay.visible = false

	# Reset visual styles
	expr_panel.modulate = Color.WHITE

func _create_patch_buttons(options: Array):
	for child in patch_list.get_children():
		child.queue_free()

	for i in range(options.size()):
		var opt = options[i]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 72)
		btn.text_overrun_behavior = TextServer.OVERRUN_NO_TRIM
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

		# Multi-line text: Expression (Big) \n Label (Small)
		# Since button text styling is limited, we'll just use text.
		# Ideally we'd use rich text or a container, but plain button is robust.
		btn.text = opt.label

		# Store data
		btn.set_meta("option_idx", i)
		btn.pressed.connect(_on_patch_pressed.bind(btn))

		# Theme overrides for larger font
		btn.add_theme_font_size_override("font_size", 20)
		# Could add a StyleBox here if needed

		patch_list.add_child(btn)

# --- INTERACTION ---
func _on_patch_pressed(btn: Button):
	if is_locked or is_complete: return
	_mark_first_action()
	patch_press_count += 1

	_lock_ui(1.0) # Short lock to prevent double clicks

	var opt_idx = btn.get_meta("option_idx")
	var option = current_case.options[opt_idx]
	var chosen_expr = option.expr

	# 1. Check Equivalence
	var eq_res = equivalent(current_case.expr_start, chosen_expr, current_case.vars)

	if not eq_res.ok:
		_handle_fail(eq_res, option)
	else:
		_handle_success(chosen_expr, option)

func _handle_fail(eq_res, option):
	attempts += 1
	var penalty = 10.0 + (attempts * 5.0) # 15, 20, 25...

	# Feedback
	var env_str = ""
	for k in eq_res.counterexample:
		env_str += "%s=%d " % [k, 1 if eq_res.counterexample[k] else 0]

	feedback_text.text = "[color=#E24B4B]NOT EQUIVALENT[/color]\nCounter-example: %s\nOrig: %s | Patch: %s" % [
		env_str,
		"1" if eq_res.orig else "0",
		"1" if eq_res.new else "0"
	]

	# Shake effect
	var tween = create_tween()
	tween.tween_property(feedback_panel, "position:x", feedback_panel.position.x + 10, 0.05)
	tween.tween_property(feedback_panel, "position:x", feedback_panel.position.x - 10, 0.05)
	tween.tween_property(feedback_panel, "position:x", feedback_panel.position.x, 0.05)

	_apply_penalty(penalty)
	_register_trial("NOT_EQUIVALENT", false, {
		"selected_label": str(option.get("label", "")),
		"counterexample": eq_res.counterexample,
		"orig_value": bool(eq_res.orig),
		"new_value": bool(eq_res.new)
	})

	if attempts >= 3:
		_enter_safe_mode()
	else:
		_lock_ui(2.0) # Penalty lock

func _handle_success(new_expr, option):
	is_complete = true

	# Load check (optional strictness)
	var new_load = count_gates(new_expr)
	load_bar.value = new_load
	load_label.text = "LOAD: %d / %d" % [new_load, current_case.target_gates]

	# Visual Success
	feedback_text.text = "[color=#38E06B]PATCH APPLIED: EQUIVALENT[/color]\n%s" % option.explain
	expr_text.text = _format_expr(new_expr) # Update main display

	var tween = create_tween()
	tween.tween_property(expr_panel, "modulate", Color(0.5, 1.5, 0.5), 0.2)
	tween.tween_property(expr_panel, "modulate", Color.WHITE, 0.3)

	# Disable buttons visually
	for child in patch_list.get_children():
		child.disabled = true

	btn_next.visible = true
	btn_hint.disabled = true
	_register_trial("SUCCESS", true, {
		"selected_label": str(option.get("label", "")),
		"new_load": count_gates(new_expr),
		"target_load": int(current_case.get("target_gates", 0))
	})

func _enter_safe_mode():
	is_complete = true # Treat as done but failed
	safe_overlay.visible = true

	# Find correct option
	var correct_idx = -1
	for i in range(current_case.options.size()):
		var opt = current_case.options[i]
		# We assume there is at least one correct answer.
		# Ideally we check data, but for now we run check or rely on knowledge.
		# The Prompt data implies one correct answer usually.
		# Let's brute force check again to find the correct one or trust data?
		# Trust data: usually the first one or we scan.
		var res = equivalent(current_case.expr_start, opt.expr, current_case.vars)
		if res.ok:
			correct_idx = i
			break

	# Highlight correct
	if correct_idx != -1:
		var btn = patch_list.get_child(correct_idx)
		btn.modulate = Color(0, 1, 0)
		feedback_text.text = "[color=#FFFF00]SAFE MODE[/color]\nCorrect patch: %s\n%s" % [
			current_case.options[correct_idx].label,
			current_case.options[correct_idx].explain
		]

	# Disable others
	for child in patch_list.get_children():
		child.disabled = true

	btn_next.visible = true

func _lock_ui(time: float):
	is_locked = true
	lock_overlay.visible = true
	lock_overlay.text = "SYSTEM LOCKED\n%.1fs" % time

	var timer = get_tree().create_timer(time)
	await timer.timeout

	if not is_complete: # Only unlock if not finished
		is_locked = false
		lock_overlay.visible = false

# --- LOGIC ENGINE ---

# Recursive Evaluation
func eval_expr(expr, env: Dictionary) -> bool:
	# 1. Boolean constant
	if typeof(expr) == TYPE_BOOL:
		return expr

	# 2. Variable (String)
	if typeof(expr) == TYPE_STRING:
		return env.get(expr, false)

	# 3. Array ["OP", arg1, ...]
	if typeof(expr) == TYPE_ARRAY:
		var op = expr[0]
		match op:
			"AND":
				# Can handle multiple args: ["AND", A, B, C]
				for i in range(1, expr.size()):
					if not eval_expr(expr[i], env):
						return false
				return true
			"OR":
				for i in range(1, expr.size()):
					if eval_expr(expr[i], env):
						return true
				return false
			"NOT":
				return not eval_expr(expr[1], env)
			"XOR":
				# Binary usually
				return eval_expr(expr[1], env) != eval_expr(expr[2], env)

	return false

# Gate Counting
func count_gates(expr) -> int:
	if typeof(expr) == TYPE_ARRAY:
		var count = 1 # The operator itself
		for i in range(1, expr.size()):
			count += count_gates(expr[i])
		return count
	return 0 # Vars/Consts don't count

# Brute-force Equivalence
func equivalent(expr1, expr2, vars: Array) -> Dictionary:
	var num_vars = vars.size()
	var combinations = 1 << num_vars # 2^n

	for i in range(combinations):
		var env = {}
		for bit in range(num_vars):
			# If bit is set, var is true
			env[vars[bit]] = (i & (1 << bit)) != 0

		var val1 = eval_expr(expr1, env)
		var val2 = eval_expr(expr2, env)

		if val1 != val2:
			return {
				"ok": false,
				"counterexample": env,
				"orig": val1,
				"new": val2
			}

	return {"ok": true}

# Formatting
func _format_expr(expr) -> String:
	if typeof(expr) == TYPE_STRING:
		return "[b]%s[/b]" % expr
	if typeof(expr) == TYPE_BOOL:
		return "1" if expr else "0"
	if typeof(expr) == TYPE_ARRAY:
		var op = expr[0]
		match op:
			"NOT":
				return "¬%s" % _format_sub(expr[1])
			"AND":
				var s = ""
				for i in range(1, expr.size()):
					if i > 1: s += " ∧ "
					s += _format_sub(expr[i])
				return s
			"OR":
				var s = ""
				for i in range(1, expr.size()):
					if i > 1: s += " ∨ "
					s += _format_sub(expr[i])
				return s
	return "?"

func _format_sub(expr) -> String:
	# Add parens if it's a complex op
	if typeof(expr) == TYPE_ARRAY and expr[0] != "NOT": # NOT usually binds tight
		return "(%s)" % _format_expr(expr)
	return _format_expr(expr)

# --- GLOBAL HELPERS ---
func _apply_penalty(amt: float):
	GlobalMetrics.stability = max(0.0, GlobalMetrics.stability - amt)
	GlobalMetrics.stability_changed.emit(GlobalMetrics.stability, -amt)
	if GlobalMetrics.stability <= 0:
		_game_over()

func _update_stability_ui(val, _diff):
	stability_label.text = "STABILITY: %d%%" % int(val)
	if val < 40:
		stability_label.add_theme_color_override("font_color", Color.RED)
	else:
		stability_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.4))

func _game_over():
	game_over_panel.visible = true

func _on_next_pressed():
	load_case(current_case_idx + 1)

func _on_hint_pressed():
	_mark_first_action()
	hints_used += 1
	_apply_penalty(5.0)
	# Just highlight the correct answer slightly or give text hint?
	# Let's give text hint from logic
	var correct_opt = null
	for opt in current_case.options:
		if equivalent(current_case.expr_start, opt.expr, current_case.vars).ok:
			correct_opt = opt
			break

	if correct_opt:
		feedback_text.text = "[color=#88CCFF]HINT: Look for %s[/color]" % correct_opt.label.substr(0, 5) + "..."

func _mark_first_action() -> void:
	if first_action_ms < 0:
		first_action_ms = Time.get_ticks_msec() - case_started_ms

func _register_trial(verdict_code: String, is_correct: bool, extra: Dictionary = {}) -> void:
	var case_id: String = str(current_case.get("id", "C_00"))
	var variant_hash: String = str(hash(JSON.stringify(current_case.get("expr_start", []))))
	var payload: Dictionary = TrialV2.build("LOGIC_QUEST", "C", case_id, "PATCH_SELECT", variant_hash)
	var elapsed_ms: int = int(max(0, Time.get_ticks_msec() - case_started_ms))
	payload["elapsed_ms"] = elapsed_ms
	payload["duration"] = float(elapsed_ms) / 1000.0
	payload["time_to_first_action_ms"] = first_action_ms if first_action_ms >= 0 else elapsed_ms
	payload["is_correct"] = is_correct
	payload["is_fit"] = is_correct
	payload["stability_delta"] = 0
	payload["verdict_code"] = verdict_code
	payload["attempts"] = attempts
	payload["patch_press_count"] = patch_press_count
	payload["hints_used"] = hints_used
	payload["target_gates"] = int(current_case.get("target_gates", 0))
	for key in extra.keys():
		payload[key] = extra[key]
	GlobalMetrics.register_trial(payload)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _on_restart_pressed():
	GlobalMetrics.stability = 100.0
	GlobalMetrics.stability_changed.emit(100.0, 0)
	game_over_panel.visible = false
	load_case(current_case_idx)
