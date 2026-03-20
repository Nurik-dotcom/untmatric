extends Control

const MAX_ATTEMPTS: int = 3

const DIAG_NONE: String = ""
const DIAG_NEXT_CASE: String = "NEXT_CASE"
const DIAG_EXIT_QUESTS: String = "EXIT_QUESTS"
const DIAG_SHOW_BREAKDOWN: String = "SHOW_BREAKDOWN"
const SAFE_MODE_REVEAL_VERDICT: String = "SAFE_MODE_REVEAL"

const LAW_DISTRIBUTION: String = "distribution"
const LAW_ABSORPTION: String = "absorption"
const LAW_DEMORGAN: String = "demorgan"
const LAW_DOUBLE_NEGATION: String = "double_negation"

const ACTION_HINT: String = "HINT"
const ACTION_APPLY: String = "APPLY"
const ACTION_VALIDATE: String = "VALIDATE"
const ACTION_NEXT: String = "NEXT"

enum QuestState {
	STATE_REVIEW_SOURCE,
	STATE_SELECT_LAW,
	STATE_SELECT_PATCH,
	STATE_PATCH_READY,
	STATE_PATCH_APPLIED,
	STATE_VALIDATING,
	STATE_VALIDATION_FAILED,
	STATE_VALIDATION_OVERLOAD,
	STATE_VALIDATION_PASSED,
	STATE_SAFE_MODE
}

const CASES := [
	{
		"id": "C_01",
		"title": "Distribution",
		"forensic_brief": "Node is overloaded. Factor A is duplicated in both branches.",
		"story": "Compress structure without changing truth profile.",
		"vars": ["A", "B", "C"],
		"expr_start": ["OR", ["AND", "A", "B"], ["AND", "A", "C"]],
		"focus_expr": "(A AND B) OR (A AND C)",
		"law_family": LAW_DISTRIBUTION,
		"law_label": "Distribution",
		"law_candidates": [
			{"id": LAW_DISTRIBUTION, "label": "Distribution", "note": "Factor out common A."},
			{"id": LAW_ABSORPTION, "label": "Absorption", "note": "Collapse A OR (A AND B)."},
			{"id": LAW_DEMORGAN, "label": "De Morgan", "note": "Push NOT into operation."}
		],
		"diagnostic_note": "Redundant duplication of A increases gate load.",
		"target_gates": 3,
		"target_reason": "Target form: A AND (B OR C), load 3.",
		"result_correct": ["AND", "A", ["OR", "B", "C"]],
		"safe_mode_explain": "Correct move: factor A out, keep logic, reduce load.",
		"options": [
			{"label": "A AND (B OR C)", "expr": ["AND", "A", ["OR", "B", "C"]], "explain": "Correct distribution collapse.", "law_family": LAW_DISTRIBUTION, "patch_note": "Collapse common factor", "is_correct": true, "is_equivalent": true, "expected_load": 3, "failure_reason": ""},
			{"label": "(A AND C) OR B", "expr": ["OR", ["AND", "A", "C"], "B"], "explain": "Breaks dependency of B on A.", "law_family": LAW_DISTRIBUTION, "patch_note": "False trail", "is_correct": false, "is_equivalent": false, "expected_load": 3, "failure_reason": "Not equivalent."},
			{"label": "A OR (B AND C)", "expr": ["OR", "A", ["AND", "B", "C"]], "explain": "Different function.", "law_family": LAW_ABSORPTION, "patch_note": "Compact but wrong", "is_correct": false, "is_equivalent": false, "expected_load": 2, "failure_reason": "Not equivalent."}
		]
	},
	{
		"id": "C_02",
		"title": "Absorption",
		"forensic_brief": "Logic is intact but has a redundant tail.",
		"story": "Remove excess branch without changing behavior.",
		"vars": ["A", "B"],
		"expr_start": ["OR", "A", ["AND", "A", "B"]],
		"focus_expr": "A OR (A AND B)",
		"law_family": LAW_ABSORPTION,
		"law_label": "Absorption",
		"law_candidates": [
			{"id": LAW_ABSORPTION, "label": "Absorption", "note": "Drop tail A AND B."},
			{"id": LAW_DISTRIBUTION, "label": "Distribution", "note": "Factor out common term."},
			{"id": LAW_DOUBLE_NEGATION, "label": "Double Negation", "note": "Remove NOT(NOT X)."}
		],
		"diagnostic_note": "Conjunctive tail costs gates and adds no truth cases.",
		"target_gates": 0,
		"target_reason": "Target form: plain A, load 0.",
		"result_correct": "A",
		"safe_mode_explain": "Correct move: A OR (A AND B) -> A.",
		"options": [
			{"label": "A", "expr": "A", "explain": "Canonical absorption.", "law_family": LAW_ABSORPTION, "patch_note": "Remove redundant tail", "is_correct": true, "is_equivalent": true, "expected_load": 0, "failure_reason": ""},
			{"label": "A OR (A AND B)", "expr": ["OR", "A", ["AND", "A", "B"]], "explain": "Equivalent but still heavy.", "law_family": LAW_ABSORPTION, "patch_note": "Overload remains", "is_correct": false, "is_equivalent": true, "expected_load": 2, "failure_reason": "Equivalent but above target load."},
			{"label": "A AND B", "expr": ["AND", "A", "B"], "explain": "Drops true cases for B=0.", "law_family": LAW_DISTRIBUTION, "patch_note": "Over-compressed", "is_correct": false, "is_equivalent": false, "expected_load": 1, "failure_reason": "Not equivalent."}
		]
	},
	{
		"id": "C_03",
		"title": "De Morgan",
		"forensic_brief": "Negation sits above an AND node and blocks simplification.",
		"story": "Move NOT inward with correct operator swap.",
		"vars": ["A", "B"],
		"expr_start": ["NOT", ["AND", "A", "B"]],
		"focus_expr": "NOT(A AND B)",
		"law_family": LAW_DEMORGAN,
		"law_label": "De Morgan",
		"law_candidates": [
			{"id": LAW_DEMORGAN, "label": "De Morgan", "note": "NOT over AND turns into OR of NOTs."},
			{"id": LAW_DOUBLE_NEGATION, "label": "Double Negation", "note": "Remove NOT(NOT X)."},
			{"id": LAW_ABSORPTION, "label": "Absorption", "note": "Collapse A OR (A AND B)."}
		],
		"diagnostic_note": "Repair requires pushing inversion into operands.",
		"target_gates": 3,
		"target_reason": "Target form: (NOT A) OR (NOT B), load 3.",
		"result_correct": ["OR", ["NOT", "A"], ["NOT", "B"]],
		"safe_mode_explain": "Correct move: NOT(A AND B) = (NOT A) OR (NOT B).",
		"options": [
			{"label": "(NOT A) OR (NOT B)", "expr": ["OR", ["NOT", "A"], ["NOT", "B"]], "explain": "Correct De Morgan transform.", "law_family": LAW_DEMORGAN, "patch_note": "Push inversion inside", "is_correct": true, "is_equivalent": true, "expected_load": 3, "failure_reason": ""},
			{"label": "NOT(A OR B)", "expr": ["NOT", ["OR", "A", "B"]], "explain": "This is NOR, not NAND.", "law_family": LAW_DEMORGAN, "patch_note": "Wrong operator swap", "is_correct": false, "is_equivalent": false, "expected_load": 2, "failure_reason": "Not equivalent."},
			{"label": "NOT(NOT((NOT A) OR (NOT B)))", "expr": ["NOT", ["NOT", ["OR", ["NOT", "A"], ["NOT", "B"]]]], "explain": "Equivalent but overloaded.", "law_family": LAW_DOUBLE_NEGATION, "patch_note": "Extra double inversion", "is_correct": false, "is_equivalent": true, "expected_load": 5, "failure_reason": "Equivalent but above target load."}
		]
	},
	{
		"id": "C_04",
		"title": "Double Negation",
		"forensic_brief": "Two serial inverters do not add information.",
		"story": "Remove double NOT and keep behavior.",
		"vars": ["A"],
		"expr_start": ["NOT", ["NOT", "A"]],
		"focus_expr": "NOT(NOT A)",
		"law_family": LAW_DOUBLE_NEGATION,
		"law_label": "Double Negation",
		"law_candidates": [
			{"id": LAW_DOUBLE_NEGATION, "label": "Double Negation", "note": "Remove NOT(NOT X)."},
			{"id": LAW_DEMORGAN, "label": "De Morgan", "note": "Works for NOT over AND/OR only."}
		],
		"diagnostic_note": "Paired NOTs consume load without changing output.",
		"target_gates": 0,
		"target_reason": "Target form: A, load 0.",
		"result_correct": "A",
		"safe_mode_explain": "Correct move: NOT(NOT A) = A.",
		"options": [
			{"label": "A", "expr": "A", "explain": "Minimal correct form.", "law_family": LAW_DOUBLE_NEGATION, "patch_note": "Remove two inverters", "is_correct": true, "is_equivalent": true, "expected_load": 0, "failure_reason": ""},
			{"label": "NOT(NOT A)", "expr": ["NOT", ["NOT", "A"]], "explain": "Equivalent but overloaded.", "law_family": LAW_DOUBLE_NEGATION, "patch_note": "Overload preserved", "is_correct": false, "is_equivalent": true, "expected_load": 2, "failure_reason": "Equivalent but above target load."},
			{"label": "NOT A", "expr": ["NOT", "A"], "explain": "Flips logic and breaks profile.", "law_family": LAW_DEMORGAN, "patch_note": "Wrong inversion", "is_correct": false, "is_equivalent": false, "expected_load": 1, "failure_reason": "Not equivalent."}
		]
	}
]

@onready var clue_title_label: Label = $SafeArea/MainLayout/Header/LblClueTitle
@onready var session_label: Label = $SafeArea/MainLayout/Header/LblSessionId
@onready var btn_back: Button = $SafeArea/MainLayout/Header/BtnBack
@onready var bars_row: HBoxContainer = $SafeArea/MainLayout/BarsRow
@onready var facts_bar_label: Label = $SafeArea/MainLayout/BarsRow/FactsBarLabel
@onready var facts_bar: ProgressBar = $SafeArea/MainLayout/BarsRow/FactsBar
@onready var energy_bar_label: Label = $SafeArea/MainLayout/BarsRow/EnergyBarLabel
@onready var energy_bar: ProgressBar = $SafeArea/MainLayout/BarsRow/EnergyBar
@onready var target_display: PanelContainer = $SafeArea/MainLayout/TargetDisplay
@onready var target_label: Label = $SafeArea/MainLayout/TargetDisplay/LblTarget
@onready var workbench_row: BoxContainer = $SafeArea/MainLayout/WorkbenchRow
@onready var source_title_label: Label = $SafeArea/MainLayout/WorkbenchRow/SourcePanel/SourceMargin/SourceVBox/SourceTitle
@onready var source_expr_label: RichTextLabel = $SafeArea/MainLayout/WorkbenchRow/SourcePanel/SourceMargin/SourceVBox/SourceExpr
@onready var source_focus_label: Label = $SafeArea/MainLayout/WorkbenchRow/SourcePanel/SourceMargin/SourceVBox/SourceFocus
@onready var patch_title_label: Label = $SafeArea/MainLayout/WorkbenchRow/PatchPanel/PatchMargin/PatchVBox/PatchTitle
@onready var patch_law_label: Label = $SafeArea/MainLayout/WorkbenchRow/PatchPanel/PatchMargin/PatchVBox/PatchLaw
@onready var patch_value_label: Label = $SafeArea/MainLayout/WorkbenchRow/PatchPanel/PatchMargin/PatchVBox/PatchValue
@onready var patch_note_label: Label = $SafeArea/MainLayout/WorkbenchRow/PatchPanel/PatchMargin/PatchVBox/PatchNote
@onready var result_title_label: Label = $SafeArea/MainLayout/WorkbenchRow/ResultPanel/ResultMargin/ResultVBox/ResultTitle
@onready var result_value_label: RichTextLabel = $SafeArea/MainLayout/WorkbenchRow/ResultPanel/ResultMargin/ResultVBox/ResultValue
@onready var result_status_label: Label = $SafeArea/MainLayout/WorkbenchRow/ResultPanel/ResultMargin/ResultVBox/ResultStatus
@onready var load_diag_row: BoxContainer = $SafeArea/MainLayout/LoadDiagRow
@onready var load_title_label: Label = $SafeArea/MainLayout/LoadDiagRow/LoadPanel/LoadMargin/LoadVBox/LoadTitle
@onready var load_bar: ProgressBar = $SafeArea/MainLayout/LoadDiagRow/LoadPanel/LoadMargin/LoadVBox/LoadBar
@onready var load_label: Label = $SafeArea/MainLayout/LoadDiagRow/LoadPanel/LoadMargin/LoadVBox/LoadLabel
@onready var diag_summary_panel: PanelContainer = $SafeArea/MainLayout/LoadDiagRow/DiagnosticSummaryPanel
@onready var summary_title_label: Label = $SafeArea/MainLayout/LoadDiagRow/DiagnosticSummaryPanel/SummaryMargin/SummaryVBox/SummaryTitle
@onready var summary_label: RichTextLabel = $SafeArea/MainLayout/LoadDiagRow/DiagnosticSummaryPanel/SummaryMargin/SummaryVBox/SummaryText
@onready var law_frame: PanelContainer = $SafeArea/MainLayout/LawFrame
@onready var law_title_label: Label = $SafeArea/MainLayout/LawFrame/LawMargin/LawVBox/LawTitle
@onready var law_description_label: Label = $SafeArea/MainLayout/LawFrame/LawMargin/LawVBox/LawDescription
@onready var law_cards_grid: GridContainer = $SafeArea/MainLayout/LawFrame/LawMargin/LawVBox/LawCardsGrid
@onready var patch_inventory_frame: PanelContainer = $SafeArea/MainLayout/PatchInventoryFrame
@onready var patch_cards_scroll: ScrollContainer = $SafeArea/MainLayout/PatchInventoryFrame/PatchInventoryMargin/PatchInventoryVBox/PatchCardsScroll
@onready var patch_inventory_title_label: Label = $SafeArea/MainLayout/PatchInventoryFrame/PatchInventoryMargin/PatchInventoryVBox/PatchInventoryTitle
@onready var patch_inventory_desc_label: Label = $SafeArea/MainLayout/PatchInventoryFrame/PatchInventoryMargin/PatchInventoryVBox/PatchInventoryDescription
@onready var patch_cards_grid: GridContainer = $SafeArea/MainLayout/PatchInventoryFrame/PatchInventoryMargin/PatchInventoryVBox/PatchCardsScroll/PatchCardsGrid
@onready var source_panel: PanelContainer = $SafeArea/MainLayout/WorkbenchRow/SourcePanel
@onready var patch_panel: PanelContainer = $SafeArea/MainLayout/WorkbenchRow/PatchPanel
@onready var result_panel: PanelContainer = $SafeArea/MainLayout/WorkbenchRow/ResultPanel
@onready var load_panel: PanelContainer = $SafeArea/MainLayout/LoadDiagRow/LoadPanel
@onready var terminal_frame: PanelContainer = $SafeArea/MainLayout/TerminalFrame
@onready var terminal_scroll: ScrollContainer = $SafeArea/MainLayout/TerminalFrame/TerminalMargin/TerminalScroll
@onready var terminal_text: RichTextLabel = $SafeArea/MainLayout/TerminalFrame/TerminalMargin/TerminalScroll/TerminalRichText
@onready var status_row: HBoxContainer = $SafeArea/MainLayout/StatusRow
@onready var stats_label: Label = $SafeArea/MainLayout/StatusRow/StatsLabel
@onready var feedback_label: Label = $SafeArea/MainLayout/StatusRow/FeedbackLabel
@onready var actions_container: BoxContainer = $SafeArea/MainLayout/Actions
@onready var btn_hint: Button = $SafeArea/MainLayout/Actions/BtnHint
@onready var btn_apply_patch: Button = $SafeArea/MainLayout/Actions/BtnApplyPatch
@onready var btn_scan: Button = $SafeArea/MainLayout/Actions/BtnScan
@onready var btn_next: Button = $SafeArea/MainLayout/Actions/BtnNext
@onready var diagnostics_blocker: ColorRect = $DiagnosticsBlocker
@onready var diagnostics_panel: PanelContainer = $DiagnosticsPanelC
@onready var diagnostics_title: Label = $DiagnosticsPanelC/PopupMargin/PopupVBox/PopupTitle
@onready var diagnostics_text: RichTextLabel = $DiagnosticsPanelC/PopupMargin/PopupVBox/PopupText
@onready var diagnostics_next_button: Button = $DiagnosticsPanelC/PopupMargin/PopupVBox/PopupBtnNext
@onready var click_player: AudioStreamPlayer = $ClickPlayer

var _body_scroll_installed: bool = false
var _body_scroll: ScrollContainer = null
var _body_content: VBoxContainer = null

var current_case_idx: int = 0
var current_case: Dictionary = {}
var current_state: int = QuestState.STATE_REVIEW_SOURCE

var attempts: int = 0
var hints_used: int = 0
var scan_count: int = 0
var analyze_count: int = 0
var patch_press_count: int = 0
var trial_seq: int = 0
var _last_stability_penalty: float = 0.0
var task_session: Dictionary = {}

var law_select_count: int = 0
var patch_select_count: int = 0
var patch_apply_count: int = 0
var validation_count: int = 0
var counterexample_seen_count: int = 0

var changed_after_validation_fail: bool = false
var changed_after_overload: bool = false

var time_to_first_analyze_ms: int = -1
var time_to_first_patch_ms: int = -1
var time_to_first_validation_ms: int = -1
var time_from_patch_to_validation_ms: int = -1

var last_edit_ms: int = -1

var selected_law_family: String = ""
var selected_option_idx: int = -1
var applied_option_idx: int = -1
var applied_expr: Variant = null
var applied_load: int = -1

var validation_passed: bool = false
var validation_failed: bool = false
var validation_overloaded: bool = false

var is_complete: bool = false
var is_safe_mode: bool = false
var is_locked: bool = false

var trace_lines: Array[String] = []
var law_buttons: Array[Button] = []
var patch_buttons: Array[Button] = []
var last_validation_summary: Dictionary = {}
var last_equivalence_result: Dictionary = {}

var diagnostics_action: String = DIAG_NONE
var case_started_ms: int = 0

var session_total_attempts: int = 0
var session_total_analyzes: int = 0
var session_safe_mode_count: int = 0

func _tr(key: String, default_text: String, params: Dictionary = {}) -> String:
	var merged: Dictionary = params.duplicate(true)
	merged["default"] = default_text
	return I18n.tr_key(key, merged)

func _ready() -> void:
	btn_back.text = _tr("logic.c.ui.back", "BACK")
	btn_hint.text = _tr("logic.c.ui.analyze", "ANALYZE")
	btn_apply_patch.text = _tr("logic.c.ui.apply", "APPLY PATCH")
	btn_scan.text = _tr("logic.c.ui.validate", "VALIDATE PATCH")
	btn_next.text = _tr("logic.c.ui.next", "NEXT")
	facts_bar_label.text = _tr("logic.c.ui.facts", "PROGRESS")
	energy_bar_label.text = _tr("logic.c.ui.energy", "STABILITY")
	source_title_label.text = _tr("logic.c.ui.source_title", "SOURCE PANEL")
	patch_title_label.text = _tr("logic.c.ui.patch_title", "PATCH PANEL")
	result_title_label.text = _tr("logic.c.ui.result_title", "RESULT PANEL")
	load_title_label.text = _tr("logic.c.ui.load_title", "LOAD")
	summary_title_label.text = _tr("logic.c.ui.summary_title", "VALIDATION SUMMARY")
	law_title_label.text = _tr("logic.c.ui.law_title", "LAW FAMILY")
	law_description_label.text = _tr("logic.c.ui.law_desc", "Choose law family before choosing patch proposal.")
	patch_inventory_title_label.text = _tr("logic.c.ui.patch_inventory", "PATCH PROPOSALS")
	patch_inventory_desc_label.text = _tr("logic.c.ui.patch_inventory_desc", "Select a law, then pick one patch.")
	terminal_text.fit_content = false
	terminal_text.scroll_active = true
	summary_label.fit_content = false
	summary_label.scroll_active = false

	if not btn_back.pressed.is_connected(_on_back_pressed):
		btn_back.pressed.connect(_on_back_pressed)
	if not btn_hint.pressed.is_connected(_on_hint_pressed):
		btn_hint.pressed.connect(_on_hint_pressed)
	if not btn_apply_patch.pressed.is_connected(_on_apply_patch_pressed):
		btn_apply_patch.pressed.connect(_on_apply_patch_pressed)
	if not btn_scan.pressed.is_connected(_on_scan_pressed):
		btn_scan.pressed.connect(_on_scan_pressed)
	if not btn_next.pressed.is_connected(_on_next_pressed):
		btn_next.pressed.connect(_on_next_pressed)
	if not diagnostics_next_button.pressed.is_connected(_on_diagnostics_close_pressed):
		diagnostics_next_button.pressed.connect(_on_diagnostics_close_pressed)
	if not get_viewport().size_changed.is_connected(_on_viewport_resized):
		get_viewport().size_changed.connect(_on_viewport_resized)
	if not GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.connect(_on_stability_changed)

	_on_stability_changed(GlobalMetrics.stability, 0.0)
	_install_body_scroll()
	_apply_responsive_layout()
	load_case(0)

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

	_body_scroll = ScrollContainer.new()
	_body_scroll.name = "BodyScroll"
	_body_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_body_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_body_scroll.follow_focus = true

	_body_content = VBoxContainer.new()
	_body_content.name = "BodyContent"
	_body_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body_content.add_theme_constant_override("separation", 6)

	for node in middle_nodes:
		node.reparent(_body_content)

	_body_scroll.add_child(_body_content)
	main_layout.add_child(_body_scroll)
	main_layout.move_child(_body_scroll, 1)

	_body_scroll_installed = true

func _apply_responsive_layout() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var portrait: bool = viewport_size.y > viewport_size.x
	var landscape: bool = not portrait
	var compact: bool = (landscape and viewport_size.y <= 420.0) or (portrait and viewport_size.x <= 500.0)

	workbench_row.vertical = portrait
	load_diag_row.vertical = portrait
	actions_container.vertical = portrait

	if portrait:
		law_cards_grid.columns = 1 if viewport_size.x < 680.0 else 2
		patch_cards_grid.columns = 1 if viewport_size.x < 680.0 else 2
		terminal_frame.custom_minimum_size = Vector2(0.0, 140.0)
		terminal_frame.size_flags_stretch_ratio = 0.42
	else:
		law_cards_grid.columns = 3
		patch_cards_grid.columns = 2
		terminal_frame.custom_minimum_size = Vector2(0.0, 220.0)
		terminal_frame.size_flags_stretch_ratio = 0.70
	if compact:
		terminal_text.add_theme_font_size_override("normal_font_size", 14)

		bars_row.custom_minimum_size.y = 16.0
		target_display.custom_minimum_size.y = 24.0
		workbench_row.custom_minimum_size.y = 80.0
		source_panel.custom_minimum_size = Vector2(0, 80)
		patch_panel.custom_minimum_size = Vector2(0, 80)
		result_panel.custom_minimum_size = Vector2(0, 80)
		load_diag_row.custom_minimum_size.y = 56.0
		load_panel.custom_minimum_size = Vector2(0, 56)
		diag_summary_panel.custom_minimum_size = Vector2(0, 56)
		law_frame.custom_minimum_size.y = 100.0
		patch_inventory_frame.custom_minimum_size.y = 100.0
		patch_cards_scroll.custom_minimum_size.y = 52.0
		status_row.custom_minimum_size.y = 20.0
		source_expr_label.custom_minimum_size.y = 24.0
		source_expr_label.fit_content = true
		result_value_label.custom_minimum_size.y = 24.0
		result_value_label.fit_content = true

		terminal_frame.custom_minimum_size = Vector2(0.0, 100.0)
		terminal_frame.size_flags_stretch_ratio = 0.35

		law_cards_grid.columns = 3
		for child in law_cards_grid.get_children():
			if child is Button:
				(child as Button).custom_minimum_size.y = 48.0
				(child as Button).add_theme_font_size_override("font_size", 12)

		patch_cards_grid.columns = 2
		for child in patch_cards_grid.get_children():
			if child is Button:
				(child as Button).custom_minimum_size.y = 44.0
				(child as Button).add_theme_font_size_override("font_size", 12)

		stats_label.add_theme_font_size_override("font_size", 12)
		feedback_label.add_theme_font_size_override("font_size", 12)
		facts_bar_label.visible = false
		energy_bar_label.visible = false
		target_label.add_theme_font_size_override("font_size", 13)
		source_title_label.add_theme_font_size_override("font_size", 12)
		patch_title_label.add_theme_font_size_override("font_size", 12)
		result_title_label.add_theme_font_size_override("font_size", 12)
		source_focus_label.add_theme_font_size_override("font_size", 11)
		patch_law_label.add_theme_font_size_override("font_size", 11)
		patch_value_label.add_theme_font_size_override("font_size", 11)
		result_status_label.add_theme_font_size_override("font_size", 11)
	elif portrait:
		terminal_text.add_theme_font_size_override("normal_font_size", 16)
	else:
		terminal_text.add_theme_font_size_override("normal_font_size", 19)

		bars_row.custom_minimum_size.y = 24.0
		target_display.custom_minimum_size.y = 32.0
		workbench_row.custom_minimum_size.y = 160.0
		law_cards_grid.columns = 3
		patch_cards_grid.columns = 2
		terminal_frame.custom_minimum_size = Vector2(0.0, 220.0)
		terminal_frame.size_flags_stretch_ratio = 0.70
		source_panel.custom_minimum_size = Vector2(280, 160)
		patch_panel.custom_minimum_size = Vector2(280, 160)
		result_panel.custom_minimum_size = Vector2(280, 160)
		load_diag_row.custom_minimum_size.y = 112.0
		load_panel.custom_minimum_size = Vector2(280, 112)
		diag_summary_panel.custom_minimum_size = Vector2(280, 112)
		law_frame.custom_minimum_size.y = 120.0
		patch_inventory_frame.custom_minimum_size.y = 120.0
		patch_cards_scroll.custom_minimum_size.y = 80.0
		status_row.custom_minimum_size.y = 24.0
		source_expr_label.custom_minimum_size.y = 40.0
		source_expr_label.fit_content = true
		result_value_label.custom_minimum_size.y = 40.0
		result_value_label.fit_content = true
		facts_bar_label.visible = true
		energy_bar_label.visible = true

	terminal_text.fit_content = false
	terminal_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn_back.custom_minimum_size = Vector2(44.0 if compact else 64.0, 44.0 if compact else 64.0)
	for action_btn in [btn_hint, btn_apply_patch, btn_scan, btn_next]:
		action_btn.custom_minimum_size.y = 44.0 if compact else 56.0
	if not compact:
		for child in law_cards_grid.get_children():
			if child is Button:
				(child as Button).custom_minimum_size.y = 48.0 if compact else 60.0
		for child in patch_cards_grid.get_children():
			if child is Button:
				(child as Button).custom_minimum_size.y = 44.0 if compact else 56.0

func _option(idx: int) -> Dictionary:
	var options: Array = current_case.get("options", [])
	if idx < 0 or idx >= options.size():
		return {}
	return options[idx] as Dictionary

func _law_candidates() -> Array:
	return current_case.get("law_candidates", [])

func load_case(idx: int) -> void:
	if idx < 0:
		idx = 0
	if idx >= CASES.size():
		_show_completion_popup()
		return

	current_case_idx = idx
	current_case = (CASES[idx] as Dictionary).duplicate(true)
	_prepare_case_options()

	current_state = QuestState.STATE_REVIEW_SOURCE
	attempts = 0
	hints_used = 0
	scan_count = 0
	analyze_count = 0
	patch_press_count = 0
	trial_seq += 1
	task_session = {"events": [], "trial_seq": trial_seq}
	law_select_count = 0
	patch_select_count = 0
	patch_apply_count = 0
	validation_count = 0
	counterexample_seen_count = 0
	changed_after_validation_fail = false
	changed_after_overload = false
	time_to_first_analyze_ms = -1
	time_to_first_patch_ms = -1
	time_to_first_validation_ms = -1
	time_from_patch_to_validation_ms = -1
	last_edit_ms = -1
	selected_law_family = ""
	selected_option_idx = -1
	applied_option_idx = -1
	applied_expr = null
	applied_load = -1
	validation_passed = false
	validation_failed = false
	validation_overloaded = false
	is_complete = false
	is_safe_mode = false
	is_locked = false
	last_equivalence_result.clear()
	last_validation_summary.clear()
	trace_lines.clear()
	case_started_ms = Time.get_ticks_msec()

	_hide_diagnostics()
	_build_law_buttons()
	_build_patch_buttons()
	_append_trace("Case loaded. Inspect source formula.")
	_show_feedback("Step 1: choose a law family.", Color(0.60, 0.80, 0.96, 1.0))
	_log_event("trial_started", {
		"case_id": str(current_case.get("id", "C_00")),
		"source_expr": _format_expr(current_case.get("expr_start")),
		"target_gates": int(current_case.get("target_gates", 0)),
		"current_state": _state_name(current_state)
	})
	_refresh_ui()

func _prepare_case_options() -> void:
	var options: Array = current_case.get("options", [])
	var vars: Array = current_case.get("vars", [])
	var source_expr: Variant = current_case.get("expr_start")
	for i in range(options.size()):
		var option: Dictionary = options[i] as Dictionary
		var expr: Variant = option.get("expr")
		var eq_result: Dictionary = equivalent(source_expr, expr, vars)
		option["is_equivalent"] = bool(option.get("is_equivalent", bool(eq_result.get("ok", false))))
		option["expected_load"] = int(option.get("expected_load", count_gates(expr)))
		if not option.has("failure_reason"):
			if bool(eq_result.get("ok", false)):
				var expected_load: int = int(option.get("expected_load", 0))
				var target: int = int(current_case.get("target_gates", 0))
				option["failure_reason"] = "Equivalent but above target load." if expected_load > target else ""
			else:
				option["failure_reason"] = "Not equivalent."
		options[i] = option
	current_case["options"] = options

func _build_law_buttons() -> void:
	for child in law_cards_grid.get_children():
		child.queue_free()
	law_buttons.clear()

	var laws: Array = _law_candidates()
	for i in range(laws.size()):
		var law: Dictionary = laws[i] as Dictionary
		var btn: Button = Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0.0, 66.0)
		btn.text = "%s\n%s" % [str(law.get("label", "")), str(law.get("note", ""))]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.pressed.connect(_on_law_selected.bind(str(law.get("id", ""))))
		law_cards_grid.add_child(btn)
		law_buttons.append(btn)

func _build_patch_buttons() -> void:
	for child in patch_cards_grid.get_children():
		child.queue_free()
	patch_buttons.clear()

	var options: Array = current_case.get("options", [])
	for i in range(options.size()):
		var option: Dictionary = options[i] as Dictionary
		var btn: Button = Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0.0, 72.0)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.text = "%s\n%s" % [str(option.get("label", "")), str(option.get("patch_note", ""))]
		btn.pressed.connect(_on_patch_pressed.bind(i))
		patch_cards_grid.add_child(btn)
		patch_buttons.append(btn)

func _on_law_selected(law_id: String) -> void:
	if is_complete or is_safe_mode or is_locked:
		return
	if law_id.is_empty():
		return

	if validation_failed:
		changed_after_validation_fail = true
	if validation_overloaded:
		changed_after_overload = true
	law_select_count += 1
	last_edit_ms = _elapsed_ms_now()
	selected_law_family = law_id
	if selected_option_idx >= 0:
		selected_option_idx = -1
	applied_option_idx = -1
	applied_expr = null
	applied_load = -1
	validation_passed = false
	validation_failed = false
	validation_overloaded = false
	last_equivalence_result.clear()
	last_validation_summary.clear()
	current_state = QuestState.STATE_SELECT_PATCH
	_log_event("law_selected", {
		"law_id": law_id,
		"law_select_count": law_select_count,
		"state": _state_name(current_state)
	})

	_append_trace("Law selected: %s." % _law_name(law_id))
	_show_feedback("Law selected. Choose patch proposal.", Color(0.60, 0.80, 0.96, 1.0))
	_refresh_ui()
	_play_click()

func _on_patch_pressed(idx: int) -> void:
	if is_complete or is_safe_mode or is_locked:
		return
	if selected_law_family.is_empty():
		_show_feedback("Select law family first.", Color(1.0, 0.74, 0.62, 1.0))
		return

	var option: Dictionary = _option(idx)
	var option_law: String = str(option.get("law_family", ""))
	if option_law != selected_law_family:
		_show_feedback("This patch belongs to another law family.", Color(1.0, 0.74, 0.62, 1.0))
		return

	if validation_failed:
		changed_after_validation_fail = true
	if validation_overloaded:
		changed_after_overload = true
	selected_option_idx = idx
	patch_press_count += 1
	patch_select_count += 1
	last_edit_ms = _elapsed_ms_now()
	applied_option_idx = -1
	applied_expr = null
	applied_load = -1
	validation_passed = false
	validation_failed = false
	validation_overloaded = false
	last_equivalence_result.clear()
	last_validation_summary.clear()
	current_state = QuestState.STATE_PATCH_READY
	_log_event("patch_selected", {
		"selected_option_idx": selected_option_idx,
		"selected_law_family": selected_law_family,
		"patch_select_count": patch_select_count
	})

	_append_trace("Patch selected: %s." % str(option.get("label", "")))
	_show_feedback("Patch loaded. Apply patch next.", Color(0.60, 0.80, 0.96, 1.0))
	_refresh_ui()
	_play_click()

func _on_apply_patch_pressed() -> void:
	if is_complete or is_safe_mode or is_locked:
		return
	if selected_law_family.is_empty():
		_show_feedback("Select law family first.", Color(1.0, 0.74, 0.62, 1.0))
		return
	if selected_option_idx < 0:
		_show_feedback("Select patch first.", Color(1.0, 0.74, 0.62, 1.0))
		return

	if validation_failed:
		changed_after_validation_fail = true
	if validation_overloaded:
		changed_after_overload = true
	patch_apply_count += 1
	if time_to_first_patch_ms < 0:
		time_to_first_patch_ms = _elapsed_ms_now()
	var option: Dictionary = _option(selected_option_idx)
	applied_option_idx = selected_option_idx
	applied_expr = option.get("expr")
	applied_load = count_gates(applied_expr)
	last_edit_ms = _elapsed_ms_now()
	validation_passed = false
	validation_failed = false
	validation_overloaded = false
	last_equivalence_result.clear()
	last_validation_summary.clear()
	current_state = QuestState.STATE_PATCH_APPLIED
	_log_event("patch_applied", {
		"selected_option_idx": selected_option_idx,
		"selected_law_family": selected_law_family,
		"applied_option_idx": applied_option_idx,
		"applied_load": applied_load,
		"patch_apply_count": patch_apply_count
	})

	_append_trace("Patch applied. Result expression assembled.")
	_show_feedback("Result assembled. Run full validation.", Color(0.60, 0.80, 0.96, 1.0))
	_refresh_ui()
	_play_click()

func _on_scan_pressed() -> void:
	if is_complete or is_safe_mode or is_locked:
		return
	if applied_expr == null:
		_show_feedback("Validation is available only after Apply Patch.", Color(1.0, 0.74, 0.62, 1.0))
		return

	current_state = QuestState.STATE_VALIDATING
	scan_count += 1
	validation_count += 1
	if time_to_first_validation_ms < 0:
		time_to_first_validation_ms = _elapsed_ms_now()
	if last_edit_ms >= 0:
		time_from_patch_to_validation_ms = maxi(0, _elapsed_ms_now() - last_edit_ms)
	else:
		time_from_patch_to_validation_ms = -1
	_append_trace("Full validation started on all vectors.")
	_log_event("validation_started", {
		"validation_count": validation_count,
		"time_from_patch_to_validation_ms": time_from_patch_to_validation_ms,
		"state": _state_name(current_state)
	})

	var source_expr: Variant = current_case.get("expr_start")
	var vars: Array = current_case.get("vars", [])
	var eq_result: Dictionary = equivalent(source_expr, applied_expr, vars)
	last_equivalence_result = eq_result.duplicate(true)

	var target_load: int = int(current_case.get("target_gates", 0))
	var base_load: int = count_gates(source_expr)
	var is_equivalent: bool = bool(eq_result.get("ok", false))

	validation_passed = false
	validation_failed = false
	validation_overloaded = false

	last_validation_summary = {
		"equivalent": is_equivalent,
		"mismatch_count": int(eq_result.get("mismatch_count", 0)),
		"total_vectors": int(eq_result.get("total_vectors", 0)),
		"counterexample": eq_result.get("counterexample", {}),
		"source_load": base_load,
		"applied_load": applied_load,
		"target_load": target_load
	}

	if is_equivalent and applied_load <= target_load:
		validation_passed = true
		is_complete = true
		current_state = QuestState.STATE_VALIDATION_PASSED
		_append_trace("Node restored. Equivalence confirmed.")
		_show_feedback("Node restored. Equivalence confirmed.", Color(0.45, 0.92, 0.62, 1.0))
		_log_event("validation_result", {
			"validation_passed": validation_passed,
			"validation_failed": validation_failed,
			"validation_overloaded": validation_overloaded,
			"applied_load": applied_load,
			"target_gates": target_load
		})
		_register_trial("SUCCESS", true)
	elif is_equivalent:
		validation_overloaded = true
		current_state = QuestState.STATE_VALIDATION_OVERLOAD
		attempts += 1
		session_total_attempts += 1
		_apply_penalty(8.0)
		_append_trace("Equivalent patch, but load exceeds target.")
		_show_feedback("Equivalent but overloaded. Pick a lighter patch.", Color(1.0, 0.78, 0.32, 1.0))
		_log_event("validation_result", {
			"validation_passed": validation_passed,
			"validation_failed": validation_failed,
			"validation_overloaded": validation_overloaded,
			"applied_load": applied_load,
			"target_gates": target_load
		})
		_register_trial("OVERLOAD", false)
	else:
		validation_failed = true
		current_state = QuestState.STATE_VALIDATION_FAILED
		attempts += 1
		session_total_attempts += 1
		_apply_penalty(15.0)
		var counterexample: Dictionary = eq_result.get("counterexample", {})
		counterexample_seen_count += 1
		var counterexample_payload: Dictionary = counterexample.duplicate(true)
		_append_trace("Mismatch found: %s." % _format_counterexample(counterexample))
		_log_event("counterexample_shown", {
			"counterexample": counterexample_payload,
			"counterexample_seen_count": counterexample_seen_count
		})
		_show_feedback("Mismatch detected. Inspect counterexample.", Color(1.0, 0.35, 0.32, 1.0))
		_log_event("validation_result", {
			"validation_passed": validation_passed,
			"validation_failed": validation_failed,
			"validation_overloaded": validation_overloaded,
			"applied_load": applied_load,
			"target_gates": target_load
		})
		_register_trial("MISMATCH", false)

	if not is_complete and attempts >= MAX_ATTEMPTS:
		_enter_safe_mode()
	elif not is_complete:
		_lock_controls(0.6)

	_refresh_ui()
	_play_click()

func _on_hint_pressed() -> void:
	if is_complete and not is_safe_mode:
		return
	if is_safe_mode:
		_show_feedback("Safe mode active. Review breakdown and continue.", Color(1.0, 0.78, 0.32, 1.0))
		return

	hints_used += 1
	analyze_count += 1
	session_total_analyzes += 1
	if time_to_first_analyze_ms < 0:
		time_to_first_analyze_ms = _elapsed_ms_now()
	_log_event("analyze_pressed", {
		"current_state": _state_name(current_state),
		"selected_law_family": selected_law_family,
		"analyze_count": analyze_count
	})

	var msg: String = ""
	match current_state:
		QuestState.STATE_REVIEW_SOURCE, QuestState.STATE_SELECT_LAW:
			msg = "Inspect focus fragment and choose law family."
		QuestState.STATE_SELECT_PATCH, QuestState.STATE_PATCH_READY:
			msg = "Choose patch, then apply it before validation."
		QuestState.STATE_PATCH_APPLIED:
			msg = "Validation checks all combinations, not a single sample."
		QuestState.STATE_VALIDATION_FAILED:
			msg = "Counterexample is the exact vector where formulas diverge."
		QuestState.STATE_VALIDATION_OVERLOAD:
			msg = "Patch is logically valid, but too expensive by target load."
		_:
			msg = "Follow current target step."

	_append_trace("Analyze requested.")
	_show_feedback(msg, Color(0.56, 0.78, 0.96, 1.0))
	_refresh_ui()

func _enter_safe_mode() -> void:
	is_safe_mode = true
	is_complete = true
	current_state = QuestState.STATE_SAFE_MODE
	session_safe_mode_count += 1

	var correct_idx: int = _find_correct_option_idx()
	if correct_idx >= 0:
		selected_option_idx = correct_idx
		applied_option_idx = correct_idx
		var option: Dictionary = _option(correct_idx)
		selected_law_family = str(option.get("law_family", ""))
		applied_expr = option.get("expr")
		applied_load = count_gates(applied_expr)

	validation_passed = false
	validation_failed = false
	validation_overloaded = false
	last_equivalence_result = equivalent(current_case.get("expr_start"), applied_expr, current_case.get("vars", []))
	last_validation_summary = {
		"equivalent": true,
		"mismatch_count": 0,
		"total_vectors": int(last_equivalence_result.get("total_vectors", 0)),
		"counterexample": {},
		"source_load": count_gates(current_case.get("expr_start")),
		"applied_load": applied_load,
		"target_load": int(current_case.get("target_gates", 0)),
		"safe_mode": true
	}

	_append_trace("SAFE MODE: correct patch revealed for review.")
	_show_feedback("SAFE MODE: correct patch revealed for review.", Color(1.0, 0.74, 0.32, 1.0))
	_register_trial(SAFE_MODE_REVEAL_VERDICT, false)

	var safe_msg: String = "%s\n\nLaw: %s\nPatch: %s\nResult: %s\nLoad: before %d, after %d, target %d" % [
		str(current_case.get("safe_mode_explain", "")),
		_law_name(selected_law_family),
		str(_option(selected_option_idx).get("label", "--")),
		_format_expr(applied_expr),
		count_gates(current_case.get("expr_start")),
		applied_load,
		int(current_case.get("target_gates", 0))
	]
	_show_diagnostics("SAFE MODE", safe_msg, "SHOW BREAKDOWN", DIAG_SHOW_BREAKDOWN)
	_refresh_ui()

func _find_correct_option_idx() -> int:
	var options: Array = current_case.get("options", [])
	var target: int = int(current_case.get("target_gates", 0))
	var source_expr: Variant = current_case.get("expr_start")
	var vars: Array = current_case.get("vars", [])
	for i in range(options.size()):
		var option: Dictionary = options[i] as Dictionary
		var expr: Variant = option.get("expr")
		var eq_result: Dictionary = equivalent(source_expr, expr, vars)
		if bool(eq_result.get("ok", false)) and count_gates(expr) <= target:
			return i
	return -1

func _update_ui_state() -> void:
	_refresh_ui()

func _refresh_ui() -> void:
	current_state = _derive_state()
	clue_title_label.text = "LIE DETECTOR | COMPLEXITY C | %s" % str(current_case.get("id", "C_00"))
	session_label.text = "SESSION: %d/%d | CASE %s" % [current_case_idx + 1, CASES.size(), str(current_case.get("id", "C_00"))]

	_update_source_panel()
	_update_patch_panel()
	_update_result_panel()
	_update_load_panel()
	_update_summary_panel()
	_update_law_cards_visual()
	_update_patch_cards_visual()
	_update_actions_state()
	_set_target_by_state()
	_update_terminal()
	_update_stats_ui()

func _derive_state() -> int:
	if is_safe_mode:
		return QuestState.STATE_SAFE_MODE
	if validation_passed:
		return QuestState.STATE_VALIDATION_PASSED
	if validation_overloaded:
		return QuestState.STATE_VALIDATION_OVERLOAD
	if validation_failed:
		return QuestState.STATE_VALIDATION_FAILED
	if applied_expr != null:
		return QuestState.STATE_PATCH_APPLIED
	if selected_option_idx >= 0:
		return QuestState.STATE_PATCH_READY
	if not selected_law_family.is_empty():
		return QuestState.STATE_SELECT_PATCH
	return QuestState.STATE_REVIEW_SOURCE

func _set_target_by_state() -> void:
	match current_state:
		QuestState.STATE_REVIEW_SOURCE, QuestState.STATE_SELECT_LAW:
			target_label.text = "STEP 1/5: inspect source and choose law family"
			facts_bar.value = 0.0
		QuestState.STATE_SELECT_PATCH:
			target_label.text = "STEP 2/5: choose patch proposal"
			facts_bar.value = 25.0
		QuestState.STATE_PATCH_READY:
			target_label.text = "STEP 3/5: apply selected patch"
			facts_bar.value = 50.0
		QuestState.STATE_PATCH_APPLIED:
			target_label.text = "STEP 4/5: run full validation on all vectors"
			facts_bar.value = 75.0
		QuestState.STATE_VALIDATION_FAILED:
			target_label.text = "STEP 4/5: mismatch found, inspect counterexample"
			facts_bar.value = 75.0
		QuestState.STATE_VALIDATION_OVERLOAD:
			target_label.text = "STEP 4/5: equivalent but overloaded, optimize patch"
			facts_bar.value = 75.0
		QuestState.STATE_VALIDATION_PASSED:
			target_label.text = "STEP 5/5: node restored, continue"
			facts_bar.value = 100.0
		QuestState.STATE_SAFE_MODE:
			target_label.text = "SAFE MODE: solution revealed for breakdown"
			facts_bar.value = 100.0
		_:
			target_label.text = "Follow current objective."

func _update_source_panel() -> void:
	var source_expr: Variant = current_case.get("expr_start")
	source_expr_label.text = "[b]%s[/b]" % _format_expr(source_expr)
	source_focus_label.text = "FOCUS: %s" % str(current_case.get("focus_expr", "--"))

func _update_patch_panel() -> void:
	patch_law_label.text = "LAW: %s" % (_law_name(selected_law_family) if not selected_law_family.is_empty() else "NOT SELECTED")

	if selected_option_idx < 0:
		patch_value_label.text = "PATCH: NOT SELECTED"
		patch_note_label.text = "Select law family, then choose patch card."
		return

	var option: Dictionary = _option(selected_option_idx)
	patch_value_label.text = "PATCH: %s" % str(option.get("label", "--"))
	var state_note: String = str(option.get("patch_note", ""))
	if applied_option_idx == selected_option_idx and applied_expr != null:
		patch_note_label.text = "%s | STATUS: APPLIED" % state_note
	else:
		patch_note_label.text = "%s | STATUS: READY" % state_note

func _update_result_panel() -> void:
	if applied_expr == null:
		result_value_label.text = "[b]RESULT NOT BUILT[/b]"
		result_status_label.text = "STATUS: NOT VALIDATED"
		result_status_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.78, 1.0))
		return

	result_value_label.text = "[b]%s[/b]" % _format_expr(applied_expr)

	if is_safe_mode:
		result_status_label.text = "STATUS: SAFE MODE REVEAL"
		result_status_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.32, 1.0))
	elif validation_passed:
		result_status_label.text = "STATUS: SUCCESS"
		result_status_label.add_theme_color_override("font_color", Color(0.45, 0.92, 0.62, 1.0))
	elif validation_overloaded:
		result_status_label.text = "STATUS: EQUIVALENT, OVERLOADED"
		result_status_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.32, 1.0))
	elif validation_failed:
		result_status_label.text = "STATUS: MISMATCH"
		result_status_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.32, 1.0))
	else:
		result_status_label.text = "STATUS: APPLIED, WAITING VALIDATION"
		result_status_label.add_theme_color_override("font_color", Color(0.60, 0.80, 0.96, 1.0))

func _update_load_panel() -> void:
	var source_expr: Variant = current_case.get("expr_start")
	var base_load: int = count_gates(source_expr)
	var target_load: int = int(current_case.get("target_gates", 0))
	var after_load_text: String = "--"
	var display_load: int = base_load
	if applied_load >= 0:
		after_load_text = str(applied_load)
		display_load = applied_load

	load_bar.max_value = float(max(base_load, target_load, display_load) + 1)
	load_bar.value = float(display_load)
	load_label.text = "BEFORE: %d | AFTER: %s | TARGET: %d" % [base_load, after_load_text, target_load]

	if applied_load < 0:
		load_label.add_theme_color_override("font_color", Color(0.74, 0.74, 0.76, 1.0))
	elif applied_load <= target_load:
		load_label.add_theme_color_override("font_color", Color(0.45, 0.92, 0.62, 1.0))
	else:
		load_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.32, 1.0))

func _update_summary_panel() -> void:
	if last_validation_summary.is_empty():
		summary_label.text = "VALIDATION NOT RUN."
		return

	var equivalent_text: String = "YES" if bool(last_validation_summary.get("equivalent", false)) else "NO"
	var mismatch_count: int = int(last_validation_summary.get("mismatch_count", 0))
	var total_vectors: int = int(last_validation_summary.get("total_vectors", 0))
	var counterexample_text: String = _format_counterexample(last_validation_summary.get("counterexample", {}))
	var src_load: int = int(last_validation_summary.get("source_load", 0))
	var out_load: int = int(last_validation_summary.get("applied_load", -1))
	var target_load: int = int(last_validation_summary.get("target_load", 0))

	var status_line: String = "STATUS: NOT PASSED"
	if is_safe_mode:
		status_line = "STATUS: SAFE MODE"
	elif validation_passed:
		status_line = "STATUS: SUCCESS"
	elif validation_overloaded:
		status_line = "STATUS: OVERLOAD"
	elif validation_failed:
		status_line = "STATUS: MISMATCH"

	summary_label.text = "EQUIVALENT: %s\nMISMATCH: %d/%d\nCOUNTEREXAMPLE: %s\nLOAD: %d -> %d (TARGET %d)\n%s" % [
		equivalent_text, mismatch_count, total_vectors, counterexample_text, src_load, out_load, target_load, status_line
	]

func _update_actions_state() -> void:
	btn_next.visible = current_state == QuestState.STATE_VALIDATION_PASSED or current_state == QuestState.STATE_SAFE_MODE
	btn_next.disabled = not btn_next.visible

	btn_hint.disabled = false
	btn_apply_patch.disabled = true
	btn_scan.disabled = true

	match current_state:
		QuestState.STATE_REVIEW_SOURCE, QuestState.STATE_SELECT_LAW:
			btn_apply_patch.disabled = true
			btn_scan.disabled = true
			_set_primary_action(ACTION_HINT)
		QuestState.STATE_SELECT_PATCH:
			btn_apply_patch.disabled = true
			btn_scan.disabled = true
			_set_primary_action(ACTION_HINT)
		QuestState.STATE_PATCH_READY:
			btn_apply_patch.disabled = false
			btn_scan.disabled = true
			_set_primary_action(ACTION_APPLY)
		QuestState.STATE_PATCH_APPLIED:
			btn_apply_patch.disabled = false
			btn_scan.disabled = false
			_set_primary_action(ACTION_VALIDATE)
		QuestState.STATE_VALIDATION_FAILED, QuestState.STATE_VALIDATION_OVERLOAD:
			btn_apply_patch.disabled = false
			btn_scan.disabled = false
			_set_primary_action(ACTION_VALIDATE)
		QuestState.STATE_VALIDATION_PASSED, QuestState.STATE_SAFE_MODE:
			btn_hint.disabled = true
			btn_apply_patch.disabled = true
			btn_scan.disabled = true
			_set_primary_action(ACTION_NEXT)
		_:
			_set_primary_action(ACTION_HINT)

	if is_locked and not is_complete and not is_safe_mode:
		btn_scan.disabled = true
		btn_apply_patch.disabled = true

func _update_law_cards_visual() -> void:
	var laws: Array = _law_candidates()
	for i in range(law_buttons.size()):
		var btn: Button = law_buttons[i]
		var law: Dictionary = {}
		if i < laws.size():
			law = laws[i] as Dictionary
		var law_id: String = str(law.get("id", ""))
		btn.disabled = is_complete or is_safe_mode
		if law_id == selected_law_family:
			btn.add_theme_color_override("font_color", Color(1.0, 0.92, 0.58, 1.0))
		else:
			btn.add_theme_color_override("font_color", Color(0.78, 0.78, 0.80, 1.0))

func _update_patch_cards_visual() -> void:
	for i in range(patch_buttons.size()):
		var btn: Button = patch_buttons[i]
		var option: Dictionary = _option(i)
		var option_law: String = str(option.get("law_family", ""))
		var law_match: bool = selected_law_family.is_empty() or option_law == selected_law_family
		btn.disabled = is_complete or is_safe_mode or is_locked or selected_law_family.is_empty() or not law_match

		if i == applied_option_idx and applied_expr != null:
			btn.add_theme_color_override("font_color", Color(0.45, 0.92, 0.62, 1.0))
		elif i == selected_option_idx:
			btn.add_theme_color_override("font_color", Color(1.0, 0.92, 0.58, 1.0))
		elif law_match:
			btn.add_theme_color_override("font_color", Color(0.78, 0.78, 0.80, 1.0))
		else:
			btn.add_theme_color_override("font_color", Color(0.56, 0.56, 0.58, 1.0))

func _set_primary_action(action_id: String) -> void:
	var muted: Color = Color(0.74, 0.74, 0.76, 1.0)
	var normal: Color = Color(0.92, 0.92, 0.90, 1.0)
	var primary: Color = Color(1.0, 0.92, 0.58, 1.0)

	btn_hint.add_theme_color_override("font_color", normal)
	btn_apply_patch.add_theme_color_override("font_color", normal)
	btn_scan.add_theme_color_override("font_color", normal)
	btn_next.add_theme_color_override("font_color", normal)

	if btn_hint.disabled:
		btn_hint.add_theme_color_override("font_color", muted)
	if btn_apply_patch.disabled:
		btn_apply_patch.add_theme_color_override("font_color", muted)
	if btn_scan.disabled:
		btn_scan.add_theme_color_override("font_color", muted)
	if btn_next.disabled:
		btn_next.add_theme_color_override("font_color", muted)

	match action_id:
		ACTION_HINT:
			if not btn_hint.disabled:
				btn_hint.add_theme_color_override("font_color", primary)
		ACTION_APPLY:
			if not btn_apply_patch.disabled:
				btn_apply_patch.add_theme_color_override("font_color", primary)
		ACTION_VALIDATE:
			if not btn_scan.disabled:
				btn_scan.add_theme_color_override("font_color", primary)
		ACTION_NEXT:
			if not btn_next.disabled:
				btn_next.add_theme_color_override("font_color", primary)

func _update_terminal() -> void:
	var lines: Array[String] = []
	lines.append("[b]BRIEFING[/b]")
	lines.append(str(current_case.get("title", "")))
	lines.append(str(current_case.get("forensic_brief", "")))
	lines.append(str(current_case.get("story", "")))
	lines.append("")
	lines.append("[b]DIAGNOSIS[/b]")
	lines.append(str(current_case.get("diagnostic_note", "")))
	lines.append("TARGET: %s" % str(current_case.get("target_reason", "")))
	lines.append("")
	lines.append("[b]SOURCE[/b]")
	lines.append(_format_expr(current_case.get("expr_start")))
	lines.append("FOCUS FRAGMENT: %s" % str(current_case.get("focus_expr", "--")))
	lines.append("")
	lines.append("[b]CURRENT TOOL[/b]")
	lines.append("LAW: %s" % (_law_name(selected_law_family) if not selected_law_family.is_empty() else "NOT SELECTED"))
	lines.append("PATCH: %s" % (str(_option(selected_option_idx).get("label", "NOT SELECTED")) if selected_option_idx >= 0 else "NOT SELECTED"))
	lines.append("APPLIED: %s" % ("YES" if applied_expr != null else "NO"))
	lines.append("")
	lines.append("[b]VALIDATION[/b]")
	if last_validation_summary.is_empty():
		lines.append("Validation not executed yet.")
	else:
		lines.append("EQUIVALENT: %s" % ("YES" if bool(last_validation_summary.get("equivalent", false)) else "NO"))
		lines.append("MISMATCH: %d/%d" % [int(last_validation_summary.get("mismatch_count", 0)), int(last_validation_summary.get("total_vectors", 0))])
		lines.append("COUNTEREXAMPLE: %s" % _format_counterexample(last_validation_summary.get("counterexample", {})))
		lines.append("LOAD: %d -> %d (TARGET %d)" % [
			int(last_validation_summary.get("source_load", 0)),
			int(last_validation_summary.get("applied_load", -1)),
			int(last_validation_summary.get("target_load", 0))
		])
	lines.append("")
	lines.append("[b]TRACE[/b]")
	if trace_lines.is_empty():
		lines.append("- empty")
	else:
		for i in range(trace_lines.size()):
			lines.append("#%d: %s" % [i + 1, trace_lines[i]])

	terminal_text.text = "\n".join(lines)

func _update_stats_ui() -> void:
	var mismatch_text: String = "--"
	if not last_validation_summary.is_empty():
		mismatch_text = "%d/%d" % [
			int(last_validation_summary.get("mismatch_count", 0)),
			int(last_validation_summary.get("total_vectors", 0))
		]

	stats_label.text = "ATTEMPTS: %d/%d | CHECKS: %d | MISMATCH: %s | ANALYZE: %d | STABILITY: %d%%" % [
		attempts, MAX_ATTEMPTS, scan_count, mismatch_text, analyze_count, int(GlobalMetrics.stability)
	]

func _state_name(state: int) -> String:
	match state:
		QuestState.STATE_REVIEW_SOURCE:
			return "REVIEW_SOURCE"
		QuestState.STATE_SELECT_LAW:
			return "SELECT_LAW"
		QuestState.STATE_SELECT_PATCH:
			return "SELECT_PATCH"
		QuestState.STATE_PATCH_READY:
			return "PATCH_READY"
		QuestState.STATE_PATCH_APPLIED:
			return "PATCH_APPLIED"
		QuestState.STATE_VALIDATING:
			return "VALIDATING"
		QuestState.STATE_VALIDATION_FAILED:
			return "VALIDATION_FAILED"
		QuestState.STATE_VALIDATION_OVERLOAD:
			return "VALIDATION_OVERLOAD"
		QuestState.STATE_VALIDATION_PASSED:
			return "VALIDATION_PASSED"
		QuestState.STATE_SAFE_MODE:
			return "SAFE_MODE"
		_:
			return "UNKNOWN"

func _append_trace(line: String) -> void:
	trace_lines.append(line)
	if trace_lines.size() > 20:
		trace_lines.remove_at(0)

func _show_feedback(msg: String, color: Color) -> void:
	feedback_label.text = msg
	feedback_label.add_theme_color_override("font_color", color)
	feedback_label.visible = true

func _apply_penalty(amount: float) -> void:
	_last_stability_penalty = amount
	GlobalMetrics.stability = max(0.0, GlobalMetrics.stability - amount)
	GlobalMetrics.stability_changed.emit(GlobalMetrics.stability, -amount)

func _on_stability_changed(value: float, _diff: float) -> void:
	energy_bar.value = clampf(value, 0.0, 100.0)
	_update_stats_ui()

func _show_diagnostics(title: String, message: String, button_text: String, action: String) -> void:
	diagnostics_title.text = title
	diagnostics_text.text = message
	diagnostics_next_button.text = button_text
	diagnostics_action = action
	diagnostics_blocker.visible = true
	diagnostics_panel.visible = true

func _hide_diagnostics() -> void:
	diagnostics_blocker.visible = false
	diagnostics_panel.visible = false
	diagnostics_action = DIAG_NONE

func _on_diagnostics_close_pressed() -> void:
	if diagnostics_action == DIAG_NEXT_CASE:
		_hide_diagnostics()
		_advance_case_or_finish()
		return
	if diagnostics_action == DIAG_EXIT_QUESTS:
		_hide_diagnostics()
		get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")
		return
	_hide_diagnostics()

func _on_next_pressed() -> void:
	_hide_diagnostics()
	if is_complete or is_safe_mode:
		_advance_case_or_finish()

func _advance_case_or_finish() -> void:
	var next_idx: int = current_case_idx + 1
	if next_idx < CASES.size():
		load_case(next_idx)
	else:
		_show_completion_popup()

func _show_completion_popup() -> void:
	var msg: String = "COMPLEXITY C COMPLETE\n\nAttempts: %d\nAnalyze calls: %d\nSafe mode uses: %d\nStability: %d%%" % [
		session_total_attempts, session_total_analyzes, session_safe_mode_count, int(GlobalMetrics.stability)
	]
	_show_diagnostics("COMPLETED", msg, "TO QUEST SELECT", DIAG_EXIT_QUESTS)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _mark_first_action() -> void:
	pass

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
	if verdict_code == SAFE_MODE_REVEAL_VERDICT or is_safe_mode:
		return "USED_SAFE_MODE"
	if validation_count <= 0:
		return "NO_FINAL_VALIDATION"
	if counterexample_seen_count > 0 and not changed_after_validation_fail and not is_correct:
		return "MISMATCH_IGNORED"
	if validation_overloaded and not changed_after_overload and not is_correct:
		return "OVERLOAD_IGNORED"
	if validation_count > 1 and is_correct:
		return "MULTI_VALIDATION_GUESSING"
	if analyze_count > 0:
		return "ANALYZE_DEPENDENCY"
	return "NONE"

func _lock_controls(seconds: float) -> void:
	is_locked = true
	btn_apply_patch.disabled = true
	btn_scan.disabled = true
	var timer: SceneTreeTimer = get_tree().create_timer(seconds)
	await timer.timeout
	if is_complete or is_safe_mode:
		return
	is_locked = false
	_refresh_ui()

func _register_trial(verdict_code: String, is_correct: bool) -> void:
	var case_id: String = str(current_case.get("id", "C_00"))
	var variant_hash: String = str(hash(JSON.stringify(current_case.get("expr_start", []))))
	var payload: Dictionary = TrialV2.build("LOGIC_QUEST", "C", case_id, "PATCH_SCAN", variant_hash)
	var safe_mode_used: bool = verdict_code == SAFE_MODE_REVEAL_VERDICT or is_safe_mode

	payload["is_correct"] = is_correct and not safe_mode_used
	payload["is_fit"] = is_correct and not safe_mode_used
	payload["verdict_code"] = verdict_code
	payload["attempts"] = attempts
	payload["hints_used"] = hints_used
	payload["analyze_count"] = analyze_count
	payload["scan_count"] = scan_count
	payload["patch_press_count"] = patch_press_count
	payload["selected_option_idx"] = selected_option_idx
	payload["selected_law_family"] = selected_law_family
	payload["applied_option_idx"] = applied_option_idx
	payload["applied_load"] = applied_load
	payload["target_gates"] = int(current_case.get("target_gates", 0))
	payload["validation_passed"] = validation_passed
	payload["validation_failed"] = validation_failed
	payload["validation_overloaded"] = validation_overloaded
	payload["current_state_at_verdict"] = _state_name(current_state)
	payload["safe_mode_used"] = safe_mode_used
	payload["source_expr_formatted"] = _format_expr(current_case.get("expr_start"))
	payload["result_expr_formatted"] = _format_expr(applied_expr) if applied_expr != null else ""
	payload["trial_seq"] = trial_seq
	payload["law_select_count"] = law_select_count
	payload["patch_select_count"] = patch_select_count
	payload["patch_apply_count"] = patch_apply_count
	payload["validation_count"] = validation_count
	payload["counterexample_seen_count"] = counterexample_seen_count
	payload["changed_after_validation_fail"] = changed_after_validation_fail
	payload["changed_after_overload"] = changed_after_overload
	payload["time_to_first_analyze_ms"] = time_to_first_analyze_ms
	payload["time_to_first_patch_ms"] = time_to_first_patch_ms
	payload["time_to_first_validation_ms"] = time_to_first_validation_ms
	payload["time_from_patch_to_validation_ms"] = time_from_patch_to_validation_ms
	payload["task_session"] = task_session.duplicate(true)
	payload["outcome_code"] = verdict_code
	payload["mastery_block_reason"] = _mastery_block_reason(verdict_code, is_correct)
	payload["stability_delta"] = 0.0 if is_correct else -_last_stability_penalty
	_last_stability_penalty = 0.0
	GlobalMetrics.register_trial(payload)

func _format_counterexample(counterexample: Dictionary) -> String:
	if counterexample.is_empty():
		return "--"
	var env: Dictionary = counterexample.get("env", {})
	if env.is_empty():
		return "--"
	var keys: Array = env.keys()
	keys.sort()
	var parts: Array[String] = []
	for key_value in keys:
		var key: String = str(key_value)
		parts.append("%s=%d" % [key, 1 if bool(env[key]) else 0])
	var orig: int = 1 if bool(counterexample.get("orig", false)) else 0
	var new_val: int = 1 if bool(counterexample.get("new", false)) else 0
	return "%s | REF=%d | PATCH=%d" % [", ".join(parts), orig, new_val]

func _law_name(law_id: String) -> String:
	match law_id:
		LAW_DISTRIBUTION:
			return "Distribution"
		LAW_ABSORPTION:
			return "Absorption"
		LAW_DEMORGAN:
			return "De Morgan"
		LAW_DOUBLE_NEGATION:
			return "Double Negation"
		_:
			return "Not selected"

func _format_expr(expr: Variant) -> String:
	return _format_expr_sub(expr)

func _format_expr_sub(expr: Variant) -> String:
	if expr == null:
		return "--"
	if expr is bool:
		return "1" if bool(expr) else "0"
	if expr is int:
		return "1" if int(expr) != 0 else "0"
	if expr is String:
		return str(expr)
	if expr is Array:
		var arr: Array = expr
		if arr.is_empty():
			return "--"
		var op: String = str(arr[0]).to_upper()
		match op:
			"NOT":
				if arr.size() > 1:
					return "NOT(%s)" % _format_expr_sub(arr[1])
				return "NOT(?)"
			"AND":
				if arr.size() > 2:
					return "(%s AND %s)" % [_format_expr_sub(arr[1]), _format_expr_sub(arr[2])]
				return "(? AND ?)"
			"OR":
				if arr.size() > 2:
					return "(%s OR %s)" % [_format_expr_sub(arr[1]), _format_expr_sub(arr[2])]
				return "(? OR ?)"
			"XOR":
				if arr.size() > 2:
					return "(%s XOR %s)" % [_format_expr_sub(arr[1]), _format_expr_sub(arr[2])]
				return "(? XOR ?)"
			"NAND":
				if arr.size() > 2:
					return "NOT(%s AND %s)" % [_format_expr_sub(arr[1]), _format_expr_sub(arr[2])]
				return "NOT(? AND ?)"
			"NOR":
				if arr.size() > 2:
					return "NOT(%s OR %s)" % [_format_expr_sub(arr[1]), _format_expr_sub(arr[2])]
				return "NOT(? OR ?)"
			_:
				return str(arr)
	return str(expr)

func eval_expr(expr: Variant, env: Dictionary) -> bool:
	if expr is bool:
		return bool(expr)
	if expr is int:
		return int(expr) != 0
	if expr is String:
		var key: String = str(expr)
		if env.has(key):
			return bool(env[key])
		return false
	if expr is Array:
		var arr: Array = expr
		if arr.is_empty():
			return false
		var op: String = str(arr[0]).to_upper()
		match op:
			"NOT":
				return not eval_expr(arr[1], env) if arr.size() > 1 else false
			"AND":
				return eval_expr(arr[1], env) and eval_expr(arr[2], env) if arr.size() > 2 else false
			"OR":
				return eval_expr(arr[1], env) or eval_expr(arr[2], env) if arr.size() > 2 else false
			"XOR":
				if arr.size() > 2:
					var left: bool = eval_expr(arr[1], env)
					var right: bool = eval_expr(arr[2], env)
					return left != right
				return false
			"NAND":
				return not (eval_expr(arr[1], env) and eval_expr(arr[2], env)) if arr.size() > 2 else false
			"NOR":
				return not (eval_expr(arr[1], env) or eval_expr(arr[2], env)) if arr.size() > 2 else false
	return false

func count_gates(expr: Variant) -> int:
	if expr is Array:
		var arr: Array = expr
		if arr.is_empty():
			return 0
		var op: String = str(arr[0]).to_upper()
		var gate_weight: int = 1 if op in ["NOT", "AND", "OR", "XOR", "NAND", "NOR"] else 0
		if arr.size() == 2:
			return gate_weight + count_gates(arr[1])
		if arr.size() > 2:
			return gate_weight + count_gates(arr[1]) + count_gates(arr[2])
	return 0

func equivalent(expr1: Variant, expr2: Variant, vars: Array) -> Dictionary:
	var var_count: int = vars.size()
	var total_vectors: int = 1 << var_count
	var mismatch_count: int = 0
	var first_counterexample: Dictionary = {}

	for mask in range(total_vectors):
		var env: Dictionary = {}
		for i in range(var_count):
			var var_name: String = str(vars[i])
			env[var_name] = ((mask >> i) & 1) == 1

		var orig_value: bool = eval_expr(expr1, env)
		var new_value: bool = eval_expr(expr2, env)
		if orig_value != new_value:
			mismatch_count += 1
			if first_counterexample.is_empty():
				first_counterexample = {
					"env": env.duplicate(true),
					"orig": orig_value,
					"new": new_value
				}

	return {
		"ok": mismatch_count == 0,
		"mismatch_count": mismatch_count,
		"total_vectors": total_vectors,
		"counterexample": first_counterexample
	}

func _play_click() -> void:
	if click_player == null:
		return
	if click_player.stream == null:
		return
	click_player.pitch_scale = randf_range(0.98, 1.03)
	click_player.play()
