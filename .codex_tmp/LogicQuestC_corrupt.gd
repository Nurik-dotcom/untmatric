extends Control

const MAX_ATTEMPTS := 3
const ANALYZE_COOLDOWN_SECONDS := 4.0

const CASES := [
	{
		"id": "C_01",
		"story": "ﾐ｣ﾐｿﾑﾐｾﾑ・ひｸﾑひｵ ﾑ・ｾﾑﾐｼﾑσｻﾑ・ﾐｱﾐｵﾐｷ ﾐｸﾐｷﾐｼﾐｵﾐｽﾐｵﾐｽﾐｸﾑ・ﾑ・ｼﾑ錦・ｻﾐｰ: A AND (B OR C).",
		"vars": ["A", "B", "C"],
		"expr_start": ["OR", ["AND", "A", "B"], ["AND", "A", "C"]],
		"target_gates": 3,
		"options": [
			{
				"label": "A 竏ｧ (B 竏ｨ C)",
				"expr": ["AND", "A", ["OR", "B", "C"]],
				"explain": "ﾐ頒ｸﾑ・びﾐｸﾐｱﾑτひｸﾐｲﾐｽﾐｾﾑ・び・ A竏ｧB 竏ｨ A竏ｧC = A竏ｧ(B竏ｨC)."
			},
			{
				"label": "(A 竏ｨ B) 竏ｧ C",
				"expr": ["AND", ["OR", "A", "B"], "C"],
				"explain": "ﾐ渙ｾﾑﾑ紹ｴﾐｾﾐｺ ﾐｿﾐｵﾑﾐｵﾐｼﾐｵﾐｽﾐｽﾑ錦・ﾐｸﾐｷﾐｼﾐｵﾐｽﾐｵﾐｽ ﾐｽﾐｵﾐｺﾐｾﾑﾑﾐｵﾐｺﾑひｽﾐｾ."
			},
			{
				"label": "A 竏ｨ (B 竏ｧ C)",
				"expr": ["OR", "A", ["AND", "B", "C"]],
				"explain": "ﾐｭﾑひｾ ﾐｴﾑﾑσｳﾐｰﾑ・ﾑ・ｾﾑﾐｼﾑσｻﾐｰ, ﾐｽﾐｵ ﾑ災ｺﾐｲﾐｸﾐｲﾐｰﾐｻﾐｵﾐｽﾑひｽﾐｰﾑ・ﾐｸﾑ・・ｾﾐｴﾐｽﾐｾﾐｹ."
			}
		]
	},
	{
		"id": "C_02",
		"story": "ﾐ湲ﾐｾﾐｲﾐｵﾑﾑ袴ひｵ ﾐｿﾐｾﾐｳﾐｻﾐｾﾑ禍ｵﾐｽﾐｸﾐｵ: A OR (A AND B).",
		"vars": ["A", "B"],
		"expr_start": ["OR", "A", ["AND", "A", "B"]],
		"target_gates": 1,
		"options": [
			{
				"label": "A",
				"expr": "A",
				"explain": "ﾐ厘ｰﾐｺﾐｾﾐｽ ﾐｿﾐｾﾐｳﾐｻﾐｾﾑ禍ｵﾐｽﾐｸﾑ・ A 竏ｨ (A 竏ｧ B) = A."
			},
			{
				"label": "A 竏ｧ B",
				"expr": ["AND", "A", "B"],
				"explain": "ﾐ｡ﾐｻﾐｸﾑ威ｺﾐｾﾐｼ ﾑ・ｸﾐｻﾑ糊ｽﾐｾﾐｵ ﾐｾﾐｳﾑﾐｰﾐｽﾐｸﾑ・ｵﾐｽﾐｸﾐｵ."
			},
			{
				"label": "A 竏ｨ B",
				"expr": ["OR", "A", "B"],
				"explain": "ﾐ頒ｾﾐｱﾐｰﾐｲﾐｻﾑ紹ｵﾑ・ﾐｻﾐｸﾑ威ｽﾐｸﾐｵ ﾐｸﾑ・ひｸﾐｽﾐｽﾑ巾ｵ ﾑ・ｻﾑτ・ｰﾐｸ."
			}
		]
	},
	{
		"id": "C_03",
		"story": "ﾐ湲ﾐｸﾐｼﾐｵﾐｽﾐｸﾑひｵ ﾐｷﾐｰﾐｺﾐｾﾐｽ ﾐｴﾐｵ ﾐ慴ｾﾑﾐｳﾐｰﾐｽﾐｰ ﾐｺ NOT(A AND B).",
		"vars": ["A", "B"],
		"expr_start": ["NOT", ["AND", "A", "B"]],
		"target_gates": 3,
		"options": [
			{
				"label": "ﾂｬA 竏ｨ ﾂｬB",
				"expr": ["OR", ["NOT", "A"], ["NOT", "B"]],
				"explain": "ﾐ墟ｾﾑﾑﾐｵﾐｺﾑひｽﾑ巾ｹ ﾐｷﾐｰﾐｺﾐｾﾐｽ ﾐｴﾐｵ ﾐ慴ｾﾑﾐｳﾐｰﾐｽﾐｰ."
			},
			{
				"label": "ﾂｬA 竏ｧ ﾂｬB",
				"expr": ["AND", ["NOT", "A"], ["NOT", "B"]],
				"explain": "ﾐｭﾑひｾ ﾑ・ｾﾑﾐｼﾐｰ ﾐｴﾐｻﾑ・NOT(A OR B), ﾐｰ ﾐｽﾐｵ ﾐｴﾐｻﾑ・AND."
			},
			{
				"label": "A 竏ｨ B",
				"expr": ["OR", "A", "B"],
				"explain": "ﾐ侑ｽﾐｲﾐｵﾑﾑ・ｸﾑ・ﾐｿﾐｾﾐｻﾐｽﾐｾﾑ・び袴・ﾐｿﾐｾﾑひｵﾑﾑ紹ｽﾐｰ."
			}
		]
	},
	{
		"id": "C_04",
		"story": "ﾐ｡ﾐｾﾐｺﾑﾐｰﾑひｸﾑひｵ ﾐｴﾐｲﾐｾﾐｹﾐｽﾐｾﾐｵ ﾐｾﾑびﾐｸﾑ・ｰﾐｽﾐｸﾐｵ: NOT(NOT(A)).",
		"vars": ["A"],
		"expr_start": ["NOT", ["NOT", "A"]],
		"target_gates": 0,
		"options": [
			{
				"label": "A",
				"expr": "A",
				"explain": "ﾐ頒ｲﾐｾﾐｹﾐｽﾐｾﾐｵ ﾐｾﾑびﾐｸﾑ・ｰﾐｽﾐｸﾐｵ ﾑσｱﾐｸﾑﾐｰﾐｵﾑび・・ ﾂｬﾂｬA = A."
			},
			{
				"label": "ﾂｬA",
				"expr": ["NOT", "A"],
				"explain": "ﾐ侑ｽﾐｲﾐｵﾑﾑ・ｸﾑ・ﾐｾﾑ・ひｰﾐｻﾐｰﾑ・・ ﾑ采ひｾ ﾐｴﾑﾑσｳﾐｰﾑ・ﾑ・ｾﾑﾐｼﾑσｻﾐｰ."
			},
			{
				"label": "0",
				"expr": false,
				"explain": "ﾐ墟ｾﾐｽﾑ・ひｰﾐｽﾑひｰ 0 ﾐｽﾐｵ ﾑ災ｺﾐｲﾐｸﾐｲﾐｰﾐｻﾐｵﾐｽﾑひｽﾐｰ ﾐｿﾐｵﾑﾐｵﾐｼﾐｵﾐｽﾐｽﾐｾﾐｹ A."
			}
		]
	}
]

@onready var safe_area: MarginContainer = $SafeArea
@onready var main_layout: VBoxContainer = $SafeArea/MainLayout
@onready var interaction_row: HBoxContainer = $SafeArea/MainLayout/InteractionRow
@onready var actions_row: HBoxContainer = $SafeArea/MainLayout/Actions
@onready var expr_slot: PanelContainer = $SafeArea/MainLayout/InteractionRow/ExprSlot
@onready var patch_slot: PanelContainer = $SafeArea/MainLayout/InteractionRow/PatchSlot
@onready var load_slot: PanelContainer = $SafeArea/MainLayout/InteractionRow/LoadSlot
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
var analyze_cooldown_until: float = 0.0
var selected_option_idx: int = -1
var is_complete: bool = false
var is_safe_mode: bool = false
var is_locked: bool = false
var case_started_ms: int = 0
var first_action_ms: int = -1
var patch_press_count: int = 0
var trace_lines: Array[String] = []
var patch_buttons: Array[Button] = []
var _interaction_mobile_layout: VBoxContainer = null

func _ready() -> void:
	_connect_ui_signals()
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
	analyze_cooldown_until = 0.0
	selected_option_idx = -1
	is_complete = false
	is_safe_mode = false
	is_locked = false
	case_started_ms = Time.get_ticks_msec()
	first_action_ms = -1
	patch_press_count = 0
	trace_lines.clear()

	clue_title_label.text = "ﾐ頒片｢ﾐ片墟｢ﾐ榧 ﾐ嶢孟・C-01"
	btn_hint.disabled = false
	btn_hint.text = "ANALYZE"
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

	_append_trace("ﾐ｡ﾑ・ｵﾐｽﾐｰﾑﾐｸﾐｹ ﾐｷﾐｰﾐｳﾑﾑσｶﾐｵﾐｽ. ﾐ柘巾ｱﾐｵﾑﾐｸﾑひｵ ﾐｿﾐｰﾑび・ﾐｸ ﾐｷﾐｰﾐｿﾑτ・ひｸﾑひｵ ﾐ｡ﾐ墟籍・")
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
	_show_feedback("ﾐ渙ｰﾑび・ﾐｲﾑ巾ｱﾑﾐｰﾐｽ. ﾐ厘ｰﾐｿﾑτ・ひｸﾑひｵ ﾐ｡ﾐ墟籍・", Color(0.56, 0.78, 0.96))
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
		_show_feedback("EQUIVALENT: patch accepted.", Color(0.45, 0.92, 0.62))
		_append_trace("RESULT: EQUIVALENT")
		_register_trial("SUCCESS", true, {
			"selected_label": str(option.get("label", "")),
			"new_load": new_load,
			"target_load": int(current_case.get("target_gates", 0)),
			"mismatch_count": int(eq_result.get("mismatch_count", 0)),
			"total_vectors": int(eq_result.get("total_vectors", vars.size()))
		})
	else:
		attempts += 1
		var penalty := 15.0 + float(attempts * 5)
		_apply_penalty(penalty)
		var counterexample: Dictionary = eq_result.get("counterexample", {})
		var mismatch_count := int(eq_result.get("mismatch_count", 1))
		var total_vectors := int(eq_result.get("total_vectors", 1))
		_show_feedback("NOT EQUIVALENT: mismatch %d/%d vectors (-%d)." % [mismatch_count, total_vectors, int(penalty)], Color(1.0, 0.35, 0.32))
		_append_trace("RESULT: NOT EQUIVALENT | mismatch %d/%d | %s | orig=%d new=%d" % [
			mismatch_count,
			total_vectors,
			_format_counterexample(counterexample),
			1 if bool(eq_result.get("orig", false)) else 0,
			1 if bool(eq_result.get("new", false)) else 0
		])
		_register_trial("NOT_EQUIVALENT", false, {
			"selected_label": str(option.get("label", "")),
			"counterexample": counterexample,
			"orig_value": bool(eq_result.get("orig", false)),
			"new_value": bool(eq_result.get("new", false)),
			"mismatch_count": mismatch_count,
			"total_vectors": total_vectors
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
	var now_sec := Time.get_ticks_msec() / 1000.0
	if now_sec < analyze_cooldown_until:
		_show_feedback("ANALYZE OVERHEAT: wait %ds." % int(ceil(analyze_cooldown_until - now_sec)), Color(1.0, 0.78, 0.32))
		_update_ui_state()
		return

	_mark_first_action()
	hints_used += 1
	analyze_cooldown_until = now_sec + ANALYZE_COOLDOWN_SECONDS

	var correct_idx := _find_correct_option_idx()
	if correct_idx >= 0:
		var option: Dictionary = current_case.get("options", [])[correct_idx]
		_show_feedback("ANALYZE: consider %s..." % str(option.get("label", "")).substr(0, 12), Color(0.56, 0.78, 0.96))
	else:
		_show_feedback("ANALYZE: no stable recommendation yet.", Color(0.66, 0.66, 0.66))
	_append_trace("ANALYZE used.")
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
		_append_trace("SAFE MODE: ﾐｿﾑﾐｰﾐｲﾐｸﾐｻﾑ糊ｽﾑ巾ｹ ﾐｿﾐｰﾑび・%s" % str(correct_option.get("label", "")))
		_show_feedback("SAFE MODE: ﾐｿﾑﾐｰﾐｲﾐｸﾐｻﾑ糊ｽﾑ巾ｹ ﾐｿﾐｰﾑび・ﾐｿﾐｾﾐｴﾑ・ひｰﾐｲﾐｻﾐｵﾐｽ.", Color(1.0, 0.74, 0.32))
		_show_diagnostics("SAFE MODE", "ﾐ榧ｱﾐｽﾐｰﾑﾑσｶﾐｵﾐｽﾐｾ ﾐｿﾑﾐｵﾐｲﾑ錦威ｵﾐｽﾐｸﾐｵ ﾐｿﾐｾﾑﾐｾﾐｳﾐｰ ﾐｾﾑ威ｸﾐｱﾐｾﾐｺ.\nﾐ湲ﾐｰﾐｲﾐｸﾐｻﾑ糊ｽﾑ巾ｹ ﾐｿﾐｰﾑび・ﾐｿﾐｾﾐｴﾑ・ｲﾐｵﾑ・ｵﾐｽ, ﾐｸﾐｷﾑτ・ｸﾑひｵ ﾑﾐｰﾐｷﾐｱﾐｾﾑ ﾐｸ ﾐｿﾐｵﾑﾐｵﾑ・ｾﾐｴﾐｸﾑひｵ ﾐｴﾐｰﾐｻﾐｵﾐｵ.")
	else:
		for btn in patch_buttons:
			btn.disabled = true
		_show_feedback("SAFE MODE: ﾐｿﾐｰﾑび・ﾐｷﾐｰﾐｱﾐｻﾐｾﾐｺﾐｸﾑﾐｾﾐｲﾐｰﾐｽ.", Color(1.0, 0.74, 0.32))

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
	var mismatch_count := 0
	var first_mismatch: Dictionary = {}
	var first_orig := false
	var first_new := false
	for i in range(combinations):
		var env := {}
		for bit in range(vars.size()):
			env[vars[bit]] = (i & (1 << bit)) != 0
		var val1 := eval_expr(expr1, env)
		var val2 := eval_expr(expr2, env)
		if val1 != val2:
			mismatch_count += 1
			if first_mismatch.is_empty():
				first_mismatch = env.duplicate()
				first_orig = val1
				first_new = val2
	if mismatch_count > 0:
		return {
			"ok": false,
			"counterexample": first_mismatch,
			"orig": first_orig,
			"new": first_new,
			"mismatch_count": mismatch_count,
			"total_vectors": combinations
		}
	return {"ok": true, "mismatch_count": 0, "total_vectors": combinations}

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
				return "ﾂｬ%s" % _format_expr_sub(arr[1])
			"AND":
				var parts_and: Array[String] = []
				for i in range(1, arr.size()):
					parts_and.append(_format_expr_sub(arr[i]))
				return " 竏ｧ ".join(parts_and)
			"OR":
				var parts_or: Array[String] = []
				for i in range(1, arr.size()):
					parts_or.append(_format_expr_sub(arr[i]))
				return " 竏ｨ ".join(parts_or)
			"XOR":
				return "%s 竓・%s" % [_format_expr_sub(arr[1]), _format_expr_sub(arr[2])]
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
	if is_complete:
		target_label.text = "ﾐｨﾐ籍・3/3: ﾐｿﾑﾐｾﾐｲﾐｵﾑﾐｺﾐｰ ﾐｷﾐｰﾐｲﾐｵﾑﾑ威ｵﾐｽﾐｰ, ﾐｿﾐｵﾑﾐｵﾑ・ｾﾐｴﾐｸﾑひｵ ﾐｴﾐｰﾐｻﾐｵﾐｵ"
		facts_bar.value = 100.0
	elif selected_option_idx < 0:
		target_label.text = "ﾐｨﾐ籍・1/3: ﾐｲﾑ巾ｱﾐｵﾑﾐｸﾑひｵ ﾐｿﾐｰﾑび・ﾐｲ ﾐｸﾐｽﾐｲﾐｵﾐｽﾑひｰﾑﾐｵ"
		facts_bar.value = 0.0
	else:
		target_label.text = "ﾐｨﾐ籍・2/3: ﾐｽﾐｰﾐｶﾐｼﾐｸﾑひｵ ﾐ｡ﾐ墟籍・ﾐｴﾐｻﾑ・ﾐｿﾑﾐｾﾐｲﾐｵﾑﾐｺﾐｸ ﾑ災ｺﾐｲﾐｸﾐｲﾐｰﾐｻﾐｵﾐｽﾑひｽﾐｾﾑ・ひｸ"
		facts_bar.value = 50.0
	energy_bar.value = clampf(GlobalMetrics.stability, 0.0, 100.0)
	btn_scan.disabled = is_complete or is_safe_mode or is_locked or selected_option_idx < 0
	var cooldown_left: int = maxi(0, int(ceil(analyze_cooldown_until - (Time.get_ticks_msec() / 1000.0))))
	if is_complete or is_safe_mode:
		btn_hint.disabled = true
	elif cooldown_left > 0:
		btn_hint.disabled = true
		btn_hint.text = "OVERHEAT %ds" % cooldown_left
	else:
		btn_hint.disabled = false
		btn_hint.text = "ANALYZE"

func _update_stats_ui() -> void:
	var case_id := str(current_case.get("id", "C_00"))
	session_label.text = "ﾐ｡ﾐ片｡ﾐ｡ﾐ侑ｯ: %02d/%02d 窶｢ CASE %s" % [current_case_idx + 1, CASES.size(), case_id]
	stats_label.text = "ﾐ渙榧・ %d/%d 窶｢ ﾐ｡ﾐ墟籍斷ｫ: %d 窶｢ ﾐ｡ﾐ｢ﾐ籍・ %d%%" % [
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
	payload["analyze_count"] = hints_used
	payload["scan_count"] = scan_count
	payload["patch_press_count"] = patch_press_count
	payload["selected_option_idx"] = selected_option_idx
	for key in extra.keys():
		payload[key] = extra[key]
	GlobalMetrics.register_trial(payload)

func _on_viewport_size_changed() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var compact: bool = viewport_size.x < 980.0 or viewport_size.y < 760.0

	_apply_safe_area_padding(compact)
	main_layout.add_theme_constant_override("separation", 6 if compact else 8)
	interaction_row.add_theme_constant_override("separation", 8 if compact else 12)
	actions_row.add_theme_constant_override("separation", 10 if compact else 16)
	terminal_text.add_theme_font_size_override("normal_font_size", 18 if compact else 20)
	expr_value_label.add_theme_font_size_override("normal_font_size", 20 if compact else 24)
	stats_label.add_theme_font_size_override("font_size", 16 if compact else 18)
	feedback_label.add_theme_font_size_override("font_size", 16 if compact else 18)

	_set_interaction_mobile_mode(compact)
	expr_slot.custom_minimum_size = Vector2(220.0 if compact else 360.0, 100.0 if compact else 108.0)
	patch_slot.custom_minimum_size = Vector2(220.0 if compact else 360.0, 100.0 if compact else 108.0)
	load_slot.custom_minimum_size = Vector2(180.0 if compact else 280.0, 100.0 if compact else 108.0)

	var action_height: float = 52.0 if compact else 56.0
	btn_hint.custom_minimum_size.y = action_height
	btn_scan.custom_minimum_size.y = action_height
	btn_next.custom_minimum_size.y = action_height

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
	return [expr_slot, patch_slot, load_slot]

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

func _play_click() -> void:
	if click_player.stream:
		click_player.play()
