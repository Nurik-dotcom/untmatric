extends Control

# --- CONSTANTS & CONFIG ---
const PHASE_TRAINING = "TRAINING"
const PHASE_TRANSLATION = "TRANSLATION"
const PHASE_DETECTION = "DETECTION"

const GATE_AND = "AND"
const GATE_OR = "OR"
const GATE_NOT = "NOT"
const GATE_XOR = "XOR"
const GATE_NAND = "NAND"
const GATE_NOR = "NOR"

const MAX_ATTEMPTS = 3
const VERDICT_LOCK_TIME = 2.0
const ANALYZE_COOLDOWN_SECONDS := 4.0
const QUICK_SOLVE_BONUS_STABILITY := 5.0

# Cases Data
const CASES = [
	{
		"id": "A1_01", "phase": PHASE_TRAINING, "gate": GATE_AND,
		"a_text": "ﾐ墟嶢ｮﾐｧ", "b_text": "ﾐ｡ﾐ｢ﾐ籍ﾐ｢",
		"witness_text": "ﾐ慴ｰﾑ威ｸﾐｽﾐｰ ﾐｷﾐｰﾐｲﾐｵﾐｴﾐｵﾑび・・ ﾐｵﾑ・ｻﾐｸ ﾐｵﾑ・び・ﾐ墟嶢ｮﾐｧ ﾐｸ ﾐｽﾐｰﾐｶﾐｰﾑひｰ ﾐｺﾐｽﾐｾﾐｿﾐｺﾐｰ ﾐ｡ﾐ｢ﾐ籍ﾐ｢.",
		"min_seen": 2, "hints": ["ﾐ旃σｶﾐｽﾑ・ﾐｾﾐｱﾐｰ ﾑτ・ｻﾐｾﾐｲﾐｸﾑ・", "ﾐｭﾑひｾ AND (ﾐ・."]
	},
	{
		"id": "A1_02", "phase": PHASE_TRAINING, "gate": GATE_OR,
		"a_text": "ﾐ頒榧孟頒ｬ", "b_text": "ﾐ｡ﾐ斷片・,
		"witness_text": "ﾐ柘・ﾐｿﾑﾐｾﾐｼﾐｾﾐｺﾐｽﾐｵﾑひｵ, ﾐｵﾑ・ｻﾐｸ ﾐｸﾐｴﾐｵﾑ・ﾐ頒榧孟頒ｬ ﾐｸﾐｻﾐｸ ﾐ｡ﾐ斷片・(ﾐｷﾐｾﾐｽﾑひｰ ﾐｽﾐｵﾑ・.",
		"min_seen": 2, "hints": ["ﾐ頒ｾﾑ・ひｰﾑひｾﾑ・ｽﾐｾ ﾐｾﾐｴﾐｽﾐｾﾐｳﾐｾ ﾑτ・ｻﾐｾﾐｲﾐｸﾑ・", "ﾐｭﾑひｾ OR (ﾐ侑嶢・."]
	},
	{
		"id": "A1_03", "phase": PHASE_TRAINING, "gate": GATE_AND,
		"a_text": "ﾐ渙籍ﾐ榧嶢ｬ", "b_text": "ﾐ｢ﾐ片嶢片､ﾐ榧・,
		"witness_text": "ﾐ柘・ｾﾐｴ ﾐｲ ﾐｿﾐｾﾑ・び・ﾑﾐｰﾐｷﾑﾐｵﾑ威ｵﾐｽ, ﾐｵﾑ・ｻﾐｸ ﾐｲﾐｲﾐｵﾐｴﾐｵﾐｽ ﾐ渙籍ﾐ榧嶢ｬ ﾐｸ ﾐｿﾑﾐｾﾐｹﾐｴﾐｵﾐｽ ﾐ｢ﾐ片嶢片､ﾐ榧・",
		"min_seen": 2, "hints": ["ﾐ旃σｶﾐｽﾑ・ﾐｾﾐｱﾐｰ ﾑτ・ｻﾐｾﾐｲﾐｸﾑ・", "ﾐｭﾑひｾ AND (ﾐ・."]
	},
	{
		"id": "A1_04", "phase": PHASE_TRAINING, "gate": GATE_OR,
		"a_text": "ﾐ漬ｫﾐ墟媽1", "b_text": "ﾐ漬ｫﾐ墟媽2",
		"witness_text": "ﾐ｡ﾐｲﾐｵﾑ・ﾐｲ ﾐｺﾐｾﾑﾐｸﾐｴﾐｾﾑﾐｵ ﾐｳﾐｾﾑﾐｸﾑ・ ﾐｵﾑ・ｻﾐｸ ﾐｲﾐｺﾐｻﾑ紗・ｵﾐｽ ﾐ漬ｫﾐ墟媽1 ﾐｸﾐｻﾐｸ ﾐ漬ｫﾐ墟媽2.",
		"min_seen": 2, "hints": ["ﾐ頒ｾﾑ・ひｰﾑひｾﾑ・ｽﾐｾ ﾐｾﾐｴﾐｽﾐｾﾐｳﾐｾ ﾐｲﾑ巾ｺﾐｻﾑ紗・ｰﾑひｵﾐｻﾑ・", "ﾐｭﾑひｾ OR (ﾐ侑嶢・."]
	},
	{
		"id": "A1_05", "phase": PHASE_TRAINING, "gate": GATE_NOT,
		"a_text": "ﾐ｡ﾐ侑寅斷籍・, "b_text": "---",
		"witness_text": "ﾐ頒ｵﾑひｵﾐｺﾑひｾﾑ ﾐｻﾐｶﾐｸ ﾐｸﾐｽﾐｲﾐｵﾑﾑひｸﾑﾑσｵﾑ・ﾑ・ｸﾐｳﾐｽﾐｰﾐｻ: ﾐｵﾑ・ｻﾐｸ ﾐｽﾐｰ ﾐｲﾑ・ｾﾐｴﾐｵ ﾐ斷片｢, ﾐｽﾐｰ ﾐｲﾑ錦・ｾﾐｴﾐｵ ﾐ頒・",
		"min_seen": 2, "hints": ["ﾐ侑ｽﾐｲﾐｵﾑﾑ・ｸﾑ・ 1->0, 0->1.", "ﾐｭﾑひｾ NOT (ﾐ斷・."]
	},
	{
		"id": "A2_01", "phase": PHASE_TRANSLATION, "gate": GATE_AND,
		"a_text": "A", "b_text": "B",
		"witness_text": "ﾐ嶢ｾﾐｳﾐｸﾑ・ｵﾑ・ｺﾐｾﾐｵ ﾐ・ﾐｾﾐｱﾐｾﾐｷﾐｽﾐｰﾑ・ｰﾐｵﾑび・・ﾑ・ｸﾐｼﾐｲﾐｾﾐｻﾐｾﾐｼ &. ﾐ斷ｰﾐｹﾐｴﾐｸﾑひｵ ﾐｵﾐｳﾐｾ.",
		"min_seen": 2, "hints": ["& ﾑ采ひｾ ﾐ・", "ﾐ墟ｾﾐｽﾑ貫社ｽﾐｺﾑ・ｸﾑ・"]
	},
	{
		"id": "A2_02", "phase": PHASE_TRANSLATION, "gate": GATE_OR,
		"a_text": "A", "b_text": "B",
		"witness_text": "ﾐ嶢ｾﾐｳﾐｸﾑ・ｵﾑ・ｺﾐｾﾐｵ ﾐ侑嶢・ﾐｾﾐｱﾐｾﾐｷﾐｽﾐｰﾑ・ｰﾐｵﾑび・・ﾑ・ｸﾐｼﾐｲﾐｾﾐｻﾐｾﾐｼ 竏ｨ. ﾐ斷ｰﾐｹﾐｴﾐｸﾑひｵ ﾐｵﾐｳﾐｾ.",
		"min_seen": 2, "hints": ["竏ｨ ﾑ采ひｾ ﾐ侑嶢・", "ﾐ頒ｸﾐｷﾑ貫社ｽﾐｺﾑ・ｸﾑ・"]
	},
	{
		"id": "A2_03", "phase": PHASE_TRANSLATION, "gate": GATE_NOT,
		"a_text": "A", "b_text": "---",
		"witness_text": "ﾐ侑ｽﾐｲﾐｵﾑﾑ・ｸﾑ・ﾐｾﾐｱﾐｾﾐｷﾐｽﾐｰﾑ・ｰﾐｵﾑび・・ﾑ・ｸﾐｼﾐｲﾐｾﾐｻﾐｾﾐｼ ﾂｬ. ﾐ斷ｰﾐｹﾐｴﾐｸﾑひｵ ﾐｵﾐｳﾐｾ.",
		"min_seen": 2, "hints": ["ﾂｬ ﾑ采ひｾ ﾐ斷・", "ﾐ樮びﾐｸﾑ・ｰﾐｽﾐｸﾐｵ."]
	},
	{
		"id": "A2_04", "phase": PHASE_TRANSLATION, "gate": GATE_XOR,
		"a_text": "A", "b_text": "B",
		"witness_text": "ﾐ佯・ｺﾐｻﾑ紗・ｰﾑ紗禍ｵﾐｵ ﾐ侑嶢・ﾐｾﾐｱﾐｾﾐｷﾐｽﾐｰﾑ・ｰﾐｵﾑび・・ﾑ・ｸﾐｼﾐｲﾐｾﾐｻﾐｾﾐｼ 竓・ ﾐ斷ｰﾐｹﾐｴﾐｸﾑひｵ ﾐｵﾐｳﾐｾ.",
		"min_seen": 2, "hints": ["竓・ﾑ采ひｾ XOR.", "ﾐ佯・ひｸﾐｽﾐｰ ﾐｿﾑﾐｸ ﾑﾐｰﾐｷﾐｽﾑ錦・ﾐｲﾑ・ｾﾐｴﾐｰﾑ・"]
	},
	{
		"id": "A2_05", "phase": PHASE_TRANSLATION, "gate": GATE_NOR,
		"a_text": "A", "b_text": "B",
		"witness_text": "ﾐ｡ﾑびﾐｵﾐｻﾐｺﾐｰ ﾐ渙ｸﾑﾑ・ｰ (ﾐ侑嶢・ﾐ斷・ ﾐｾﾐｱﾐｾﾐｷﾐｽﾐｰﾑ・ｰﾐｵﾑび・・ﾑ・ｸﾐｼﾐｲﾐｾﾐｻﾐｾﾐｼ 竓ｽ.",
		"min_seen": 2, "hints": ["ﾐｭﾑひｾ ﾐｸﾐｽﾐｲﾐｵﾑﾑ・ｸﾑ・ﾐ侑嶢・", "NOR."]
	},
	{
		"id": "A3_01", "phase": PHASE_DETECTION, "gate": GATE_NOR,
		"a_text": "ﾐ墟榧農1", "b_text": "ﾐ墟榧農2",
		"witness_text": "ﾐ｡ﾐｵﾐｹﾑ・ﾐｾﾑひｺﾑﾑ巾ｻﾑ・・(1), ﾐｺﾐｾﾐｳﾐｴﾐｰ ﾐｾﾐｱﾐｰ ﾐｺﾐｾﾐｴﾐｰ ﾐｱﾑ巾ｻﾐｸ ﾐｽﾐｵﾐｲﾐｵﾑﾐｽﾑ・(0,0).",
		"min_seen": 3, "hints": ["ﾐ柘錦・ｾﾐｴ 1 ﾑひｾﾐｻﾑ糊ｺﾐｾ ﾐｿﾑﾐｸ 0,0.", "ﾐｭﾑひｾ NOR."]
	},
	{
		"id": "A3_02", "phase": PHASE_DETECTION, "gate": GATE_XOR,
		"a_text": "ﾐ頒籍｢ﾐｧﾐ侑喟1", "b_text": "ﾐ頒籍｢ﾐｧﾐ侑喟2",
		"witness_text": "ﾐ｡ﾐｸﾐｳﾐｽﾐｰﾐｻﾐｸﾐｷﾐｰﾑ・ｸﾑ・ﾐｼﾐｾﾐｻﾑ・ｸﾑ・(0), ﾑひｾﾐｻﾑ糊ｺﾐｾ ﾐｺﾐｾﾐｳﾐｴﾐｰ ﾑ・ｸﾐｳﾐｽﾐｰﾐｻﾑ・ﾑ・ｾﾐｲﾐｿﾐｰﾐｴﾐｰﾑ紗・",
		"min_seen": 3, "hints": ["ﾐ佯・ひｸﾐｽﾐｰ ﾐｿﾑﾐｸ ﾑﾐｰﾐｷﾐｽﾑ錦・ﾐｲﾑ・ｾﾐｴﾐｰﾑ・", "ﾐｭﾑひｾ XOR."]
	},
	{
		"id": "A3_03", "phase": PHASE_DETECTION, "gate": GATE_NOR,
		"a_text": "ﾐﾐｫﾐｧﾐ籍点1", "b_text": "ﾐﾐｫﾐｧﾐ籍点2",
		"witness_text": "ﾐ厘ｰﾐｼﾐｾﾐｺ ﾐｷﾐｰﾐｺﾐｻﾐｸﾐｽﾐｸﾑ・(0), ﾐｵﾑ・ｻﾐｸ ﾐｽﾐｰﾐｶﾐｰﾑび・ﾑ・ｾﾑび・ﾐｱﾑ・ﾐｾﾐｴﾐｸﾐｽ ﾑﾑ錦・ｰﾐｳ.",
		"min_seen": 3, "hints": ["ﾐ柘錦・ｾﾐｴ 1 ﾑひｾﾐｻﾑ糊ｺﾐｾ ﾐｿﾑﾐｸ 0,0.", "ﾐｭﾑひｾ NOR."]
	},
	{
		"id": "A3_04", "phase": PHASE_DETECTION, "gate": GATE_XOR,
		"a_text": "ﾐｧﾐ籍｡ﾐ｢ﾐ榧｢ﾐ神1", "b_text": "ﾐｧﾐ籍｡ﾐ｢ﾐ榧｢ﾐ神2",
		"witness_text": "ﾐ渙ｵﾑﾐｵﾑ・ｲﾐｰﾑ・ﾐｴﾐｰﾐｽﾐｽﾑ錦・(1) ﾐｸﾐｴﾐｵﾑ・ﾑひｾﾐｻﾑ糊ｺﾐｾ ﾐｿﾑﾐｸ ﾑﾐｰﾐｷﾐｽﾑ錦・ﾑ・ｰﾑ・ひｾﾑひｰﾑ・",
		"min_seen": 3, "hints": ["ﾐﾐｰﾐｷﾐｽﾑ巾ｵ ﾐｲﾑ・ｾﾐｴﾑ・ﾐｴﾐｰﾑ紗・1.", "ﾐｭﾑひｾ XOR."]
	},
	{
		"id": "A3_05", "phase": PHASE_DETECTION, "gate": GATE_NAND,
		"a_text": "X", "b_text": "Y",
		"witness_text": "ﾐ旃σｶﾐｵﾐｽ ﾐｲﾐｵﾐｽﾑひｸﾐｻﾑ・ ﾐｴﾐｰﾑ紗禍ｸﾐｹ ﾐ嶢榧孟ｬ ﾑひｾﾐｻﾑ糊ｺﾐｾ ﾐｿﾑﾐｸ ﾐｴﾐｲﾑτ・ﾐ侑｡ﾐ｢ﾐ侑斷籍･.",
		"min_seen": 3, "hints": ["0 ﾑひｾﾐｻﾑ糊ｺﾐｾ ﾐｿﾑﾐｸ 1,1.", "ﾐｭﾑひｾ NAND."]
	}
]
# --- UI NODES ---
@onready var safe_area: MarginContainer = $SafeArea
@onready var main_layout: VBoxContainer = $SafeArea/MainLayout
@onready var content_split: SplitContainer = $SafeArea/MainLayout/ContentHSplit
@onready var interaction_row: HBoxContainer = $SafeArea/MainLayout/ContentHSplit/RightPane/InteractionRow
@onready var actions_row: HBoxContainer = $SafeArea/MainLayout/ContentHSplit/RightPane/Actions
@onready var gates_container: HBoxContainer = $SafeArea/MainLayout/ContentHSplit/RightPane/InventoryFrame/InventoryMargin/InventoryScroll/GatesContainer
@onready var clue_title_label: Label = $SafeArea/MainLayout/Header/LblClueTitle
@onready var session_label: Label = $SafeArea/MainLayout/Header/LblSessionId
@onready var facts_bar: ProgressBar = $SafeArea/MainLayout/BarsRow/FactsBar
@onready var energy_bar: ProgressBar = $SafeArea/MainLayout/BarsRow/EnergyBar
@onready var target_label: Label = $SafeArea/MainLayout/TargetDisplay/LblTarget
@onready var terminal_text: RichTextLabel = $SafeArea/MainLayout/ContentHSplit/LeftPane/TerminalFrame/TerminalScroll/TerminalRichText
@onready var stats_label: Label = $SafeArea/MainLayout/ContentHSplit/RightPane/StatusRow/StatsLabel
@onready var feedback_label: Label = $SafeArea/MainLayout/ContentHSplit/RightPane/StatusRow/FeedbackLabel

@onready var input_a_frame: PanelContainer = $SafeArea/MainLayout/ContentHSplit/RightPane/InteractionRow/InputAFrame
@onready var input_b_frame: PanelContainer = $SafeArea/MainLayout/ContentHSplit/RightPane/InteractionRow/InputBFrame
@onready var gate_slot_frame: PanelContainer = $SafeArea/MainLayout/ContentHSplit/RightPane/InteractionRow/GateSlot
@onready var input_a_btn: Button = $SafeArea/MainLayout/ContentHSplit/RightPane/InteractionRow/InputAFrame/InputAVBox/InputA_Btn
@onready var input_b_btn: Button = $SafeArea/MainLayout/ContentHSplit/RightPane/InteractionRow/InputBFrame/InputBVBox/InputB_Btn
@onready var gate_label: Label = $SafeArea/MainLayout/ContentHSplit/RightPane/InteractionRow/GateSlot/GateVBox/GateLabel
@onready var output_value_label: Label = $SafeArea/MainLayout/ContentHSplit/RightPane/InteractionRow/OutputSlot/OutputVBox/OutputValueLabel
@onready var model_value_label: Label = $SafeArea/MainLayout/ContentHSplit/RightPane/InteractionRow/OutputSlot/OutputVBox/ModelValueLabel
@onready var match_label: Label = $SafeArea/MainLayout/ContentHSplit/RightPane/InteractionRow/OutputSlot/OutputVBox/MatchLabel
@onready var inventory_frame: PanelContainer = $SafeArea/MainLayout/ContentHSplit/RightPane/InventoryFrame

@onready var gate_and_btn: Button = $SafeArea/MainLayout/ContentHSplit/RightPane/InventoryFrame/InventoryMargin/InventoryScroll/GatesContainer/GateAndBtn
@onready var gate_or_btn: Button = $SafeArea/MainLayout/ContentHSplit/RightPane/InventoryFrame/InventoryMargin/InventoryScroll/GatesContainer/GateOrBtn
@onready var gate_not_btn: Button = $SafeArea/MainLayout/ContentHSplit/RightPane/InventoryFrame/InventoryMargin/InventoryScroll/GatesContainer/GateNotBtn
@onready var gate_xor_btn: Button = $SafeArea/MainLayout/ContentHSplit/RightPane/InventoryFrame/InventoryMargin/InventoryScroll/GatesContainer/GateXorBtn
@onready var gate_nand_btn: Button = $SafeArea/MainLayout/ContentHSplit/RightPane/InventoryFrame/InventoryMargin/InventoryScroll/GatesContainer/GateNandBtn
@onready var gate_nor_btn: Button = $SafeArea/MainLayout/ContentHSplit/RightPane/InventoryFrame/InventoryMargin/InventoryScroll/GatesContainer/GateNorBtn

@onready var btn_hint: Button = $SafeArea/MainLayout/ContentHSplit/RightPane/Actions/BtnHint
@onready var btn_probe: Button = $SafeArea/MainLayout/ContentHSplit/RightPane/Actions/BtnProbe
@onready var btn_verdict: Button = $SafeArea/MainLayout/ContentHSplit/RightPane/Actions/BtnVerdict
@onready var btn_next: Button = $SafeArea/MainLayout/ContentHSplit/RightPane/Actions/BtnNext
@onready var diagnostics_blocker: ColorRect = $DiagnosticsBlocker
@onready var diagnostics_panel: PanelContainer = $DiagnosticsPanelA
@onready var diagnostics_title: Label = $DiagnosticsPanelA/PopupMargin/PopupVBox/PopupTitle
@onready var diagnostics_text: RichTextLabel = $DiagnosticsPanelA/PopupMargin/PopupVBox/PopupText
@onready var diagnostics_next_button: Button = $DiagnosticsPanelA/PopupMargin/PopupVBox/PopupBtnNext
@onready var click_player: AudioStreamPlayer = $ClickPlayer

# --- STATE ---
var current_case_index: int = 0
var current_case: Dictionary = {}

var input_a: bool = false
var input_b: bool = false
var selected_gate_guess: String = ""

var seen_combinations: Dictionary = {}
var seen_trace_entries: Array[Dictionary] = []
var case_attempts: int = 0
var hints_used: int = 0
var start_time_msec: int = 0
var first_action_ms: int = -1
var verdict_count: int = 0

var last_verdict_time: float = 0.0
var analyze_cooldown_until: float = 0.0
var verdict_timer: Timer = null
var is_safe_mode: bool = false
var gate_buttons: Dictionary = {}
var highlighted_step: int = -1
var highlighted_fact_idx: int = -1
var last_observed_output: bool = false

const COLOR_OUTPUT_ON = Color(0.95, 0.95, 0.90, 1.0)
const COLOR_OUTPUT_OFF = Color(0.55, 0.55, 0.55, 1.0)

func _ready() -> void:
	_setup_gate_buttons()
	_update_stability_ui(GlobalMetrics.stability, 0)
	if not GlobalMetrics.stability_changed.is_connected(_update_stability_ui):
		GlobalMetrics.stability_changed.connect(_update_stability_ui)
	if not GlobalMetrics.game_over.is_connected(_on_game_over):
		GlobalMetrics.game_over.connect(_on_game_over)

	verdict_timer = Timer.new()
	verdict_timer.one_shot = true
	verdict_timer.timeout.connect(_on_verdict_unlock)
	add_child(verdict_timer)

	load_case(0)
	_on_viewport_size_changed()
	if not get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.connect(_on_viewport_size_changed)

func _exit_tree() -> void:
	if get_tree() != null and get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.disconnect(_on_viewport_size_changed)

func _setup_gate_buttons() -> void:
	gate_buttons = {
		GATE_AND: gate_and_btn,
		GATE_OR: gate_or_btn,
		GATE_NOT: gate_not_btn,
		GATE_XOR: gate_xor_btn,
		GATE_NAND: gate_nand_btn,
		GATE_NOR: gate_nor_btn
	}
	_clear_gate_selection()

func load_case(idx: int) -> void:
	if idx >= CASES.size():
		idx = 0

	current_case_index = idx
	current_case = CASES[idx]

	input_a = false
	input_b = false
	selected_gate_guess = ""
	seen_combinations.clear()
	seen_trace_entries.clear()
	case_attempts = 0
	hints_used = 0
	start_time_msec = Time.get_ticks_msec()
	first_action_ms = -1
	verdict_count = 0
	last_verdict_time = 0.0
	analyze_cooldown_until = 0.0
	is_safe_mode = false
	highlighted_step = -1
	highlighted_fact_idx = -1

	clue_title_label.text = "ﾐ頒片｢ﾐ片墟｢ﾐ榧 ﾐ嶢孟・A-01"
	_update_stats_ui()
	_hide_diagnostics()

	input_a_btn.button_pressed = false
	input_b_btn.button_pressed = false
	input_a_btn.disabled = false
	input_b_btn.disabled = false
	btn_hint.text = "ANALYZE"
	btn_hint.disabled = false
	btn_probe.disabled = false
	btn_verdict.visible = true
	btn_verdict.disabled = true
	btn_next.visible = false
	feedback_label.visible = false
	feedback_label.text = ""

	if current_case.gate == GATE_NOT:
		input_b_frame.visible = false
	else:
		input_b_frame.visible = true

	_set_gate_buttons_enabled(true)
	_clear_gate_selection()
	_update_input_labels()
	_refresh_circuit_output()
	_update_terminal_text()
	_update_ui_state()

func _update_input_labels() -> void:
	input_a_btn.text = "%s\n[%s]" % [str(current_case.get("a_text", "A")), "1" if input_a else "0"]
	if current_case.gate != GATE_NOT:
		input_b_btn.text = "%s\n[%s]" % [str(current_case.get("b_text", "B")), "1" if input_b else "0"]

func _on_input_a_toggled(pressed: bool) -> void:
	_mark_first_action()
	input_a = pressed
	_play_click()
	_update_input_labels()
	_refresh_circuit_output()
	_update_terminal_text()

func _on_input_b_toggled(pressed: bool) -> void:
	_mark_first_action()
	input_b = pressed
	_play_click()
	_update_input_labels()
	_refresh_circuit_output()
	_update_terminal_text()

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

	if is_safe_mode:
		return
	if gate_and_btn.disabled:
		return
	if not pressed:
		if selected_gate_guess == gate_id:
			selected_gate_guess = ""
			_update_gate_slot_label()
			_refresh_circuit_output()
			_update_terminal_text()
		return

	_mark_first_action()
	for key in gate_buttons.keys():
		if key != gate_id:
			var btn_other: Button = gate_buttons[key]
			btn_other.set_pressed_no_signal(false)

	selected_gate_guess = gate_id
	_play_click()
	_update_gate_slot_label()
	_refresh_circuit_output()
	_update_terminal_text()

func _on_probe_pressed() -> void:
	if is_safe_mode or not btn_verdict.visible:
		return
	_mark_first_action()
	_play_click()
	var is_new_fact := _record_probe()
	var observed_text := "1" if last_observed_output else "0"
	if is_new_fact:
		_show_feedback("PROBE captured: F_box=%s" % observed_text, Color(0.56, 0.78, 0.96))
	else:
		_show_feedback("PROBE repeated current vector: F_box=%s" % observed_text, Color(0.76, 0.76, 0.72))
	_refresh_circuit_output()
	_update_terminal_text()
	_update_stats_ui()

func _record_probe() -> bool:
	var key := _current_vector_key()
	var observed := last_observed_output
	var existing_idx := _find_seen_entry_idx(key)
	if existing_idx >= 0:
		highlighted_fact_idx = existing_idx
		return false
	seen_combinations[key] = observed
	seen_trace_entries.append({
		"key": key,
		"a": 1 if input_a else 0,
		"b": -1 if current_case.gate == GATE_NOT else (1 if input_b else 0),
		"f": 1 if observed else 0
	})
	highlighted_fact_idx = seen_trace_entries.size() - 1
	return true

func _current_vector_key() -> String:
	if current_case.gate == GATE_NOT:
		return "A=%d" % [1 if input_a else 0]
	return "A=%d B=%d" % [1 if input_a else 0, 1 if input_b else 0]

func _find_seen_entry_idx(key: String) -> int:
	for i in range(seen_trace_entries.size()):
		if str(seen_trace_entries[i].get("key", "")) == key:
			return i
	return -1

func _refresh_circuit_output() -> void:
	last_observed_output = _calculate_gate_output(input_a, input_b, str(current_case.get("gate", "")))
	output_value_label.text = "F_box = %s" % ("1" if last_observed_output else "0")
	output_value_label.add_theme_color_override("font_color", COLOR_OUTPUT_ON if last_observed_output else COLOR_OUTPUT_OFF)

	if selected_gate_guess.is_empty():
		model_value_label.text = "F_model = ?"
		model_value_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.62, 1.0))
		match_label.text = "MATCH: --"
		match_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.62, 1.0))
	else:
		var model_output := _calculate_gate_output(input_a, input_b, selected_gate_guess)
		model_value_label.text = "F_model = %s" % ("1" if model_output else "0")
		var is_match := model_output == last_observed_output
		match_label.text = "MATCH: %s" % ("YES" if is_match else "NO")
		model_value_label.add_theme_color_override("font_color", COLOR_OUTPUT_ON if model_output else COLOR_OUTPUT_OFF)
		match_label.add_theme_color_override("font_color", Color(0.45, 0.92, 0.62, 1.0) if is_match else Color(1.0, 0.45, 0.35, 1.0))

	_update_target_and_bars()
	_update_ui_state()

func _calculate_gate_output(a: bool, b: bool, type: String) -> bool:
	match type:
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

func _update_terminal_text() -> void:
	var lines: Array[String] = []
	lines.append("[b]ﾐ岱ﾐ侑､ﾐ侑斷甜/b]")
	lines.append(str(current_case.get("witness_text", "")))
	lines.append("")
	lines.append("[b]FLOW[/b]")
	lines.append("1) Set inputs")
	lines.append("2) PROBE records observed F_box")
	lines.append("3) Pick a gate and run VERDICT")
	lines.append("")
	lines.append("[b]FACTS LOG[/b]")

	if seen_trace_entries.is_empty():
		lines.append("窶｢ ﾐ孟｣ﾐﾐ斷籍・ﾐ渙｣ﾐ｡ﾐ｢")
	else:
		var a_name := str(current_case.get("a_text", "A"))
		var b_name := str(current_case.get("b_text", "B"))
		for i in range(seen_trace_entries.size()):
			var entry: Dictionary = seen_trace_entries[i]
			var row := ""
			if int(entry.get("b", -1)) < 0:
				row = "窶｢ #%d | %s=%d -> F_box=%d" % [i + 1, a_name, int(entry.get("a", 0)), int(entry.get("f", 0))]
			else:
				row = "窶｢ #%d | %s=%d, %s=%d -> F_box=%d" % [
					i + 1,
					a_name,
					int(entry.get("a", 0)),
					b_name,
					int(entry.get("b", 0)),
					int(entry.get("f", 0))
				]
			if i == highlighted_fact_idx:
				row = "[color=#ff7a7a]> %s[/color]" % row
			elif i == seen_trace_entries.size() - 1:
				row = "[color=#f4f2e6]> %s[/color]" % row
			lines.append(row)

	lines.append("")
	lines.append("[b]CURRENT OUTPUT[/b]")
	lines.append("F_box = %s" % ("1" if last_observed_output else "0"))
	if selected_gate_guess.is_empty():
		lines.append("F_model = ?")
	else:
		var model_out := _calculate_gate_output(input_a, input_b, selected_gate_guess)
		lines.append("F_model = %s" % ("1" if model_out else "0"))
		lines.append("MATCH = %s" % ("YES" if model_out == last_observed_output else "NO"))

	terminal_text.text = "\n".join(lines)

func _update_gate_slot_label() -> void:
	if selected_gate_guess.is_empty():
		gate_label.text = "GATE: ?"
		return
	gate_label.text = "GATE: %s (%s)" % [_gate_symbol(selected_gate_guess), _gate_title(selected_gate_guess)]

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

func _gate_title(gate_id: String) -> String:
	match gate_id:
		GATE_AND:
			return "AND"
		GATE_OR:
			return "OR"
		GATE_NOT:
			return "NOT"
		GATE_XOR:
			return "XOR"
		GATE_NAND:
			return "NAND"
		GATE_NOR:
			return "NOR"
		_:
			return "UNKNOWN"

func _set_gate_buttons_enabled(enabled: bool) -> void:
	for gate_id in gate_buttons.keys():
		var gate_btn: Button = gate_buttons[gate_id]
		gate_btn.disabled = not enabled

func _clear_gate_selection() -> void:
	for gate_id in gate_buttons.keys():
		var gate_btn: Button = gate_buttons[gate_id]
		gate_btn.set_pressed_no_signal(false)
	selected_gate_guess = ""
	_update_gate_slot_label()

func _select_gate_button(gate_id: String) -> void:
	_clear_gate_selection()
	if not gate_buttons.has(gate_id):
		return
	var gate_btn: Button = gate_buttons[gate_id]
	gate_btn.set_pressed_no_signal(true)
	selected_gate_guess = gate_id
	_update_gate_slot_label()

func _required_probe_count() -> int:
	return 2 if str(current_case.get("gate", "")) == GATE_NOT else 4

func _confidence_ratio() -> float:
	return clampf(float(seen_combinations.size()) / float(maxi(1, _required_probe_count())), 0.0, 1.0)

func _confidence_label() -> String:
	var ratio := _confidence_ratio()
	if ratio >= 0.75:
		return "HIGH"
	if ratio >= 0.40:
		return "MID"
	return "LOW"

func _update_target_and_bars() -> void:
	facts_bar.value = _confidence_ratio() * 100.0
	energy_bar.value = clampf(GlobalMetrics.stability, 0.0, 100.0)

func _update_ui_state() -> void:
	var seen_count: int = seen_combinations.size()
	var gate_ready := not selected_gate_guess.is_empty()
	var has_result := is_safe_mode or not btn_verdict.visible
	var cooldown_left: int = maxi(0, int(ceil(analyze_cooldown_until - (Time.get_ticks_msec() / 1000.0))))

	if has_result:
		target_label.text = "REPORT READY. Continue to the next file."
		btn_probe.disabled = true
		btn_verdict.disabled = true
		btn_hint.disabled = true
		_set_gate_buttons_enabled(false)
		_pulse_step(3)
		return

	_set_gate_buttons_enabled(true)
	btn_probe.disabled = false
	btn_verdict.disabled = not gate_ready

	if cooldown_left > 0:
		btn_hint.disabled = true
		btn_hint.text = "OVERHEAT %ds" % cooldown_left
	else:
		btn_hint.disabled = false
		btn_hint.text = "ANALYZE"

	var confidence := _confidence_label()
	if seen_count == 0:
		target_label.text = "Step 1/3: set inputs and press PROBE."
		_pulse_step(1)
	elif not gate_ready:
		target_label.text = "Step 2/3: pick a gate. Confidence: %s (%d/%d probes)." % [confidence, seen_count, _required_probe_count()]
		_pulse_step(2)
	else:
		target_label.text = "Step 3/3: VERDICT available. Confidence: %s (%d/%d probes)." % [confidence, seen_count, _required_probe_count()]
		_pulse_step(3)

func _pulse_step(step: int) -> void:
	if highlighted_step == step:
		return
	highlighted_step = step
	input_a_frame.modulate = Color(1, 1, 1, 1)
	input_b_frame.modulate = Color(1, 1, 1, 1)
	gate_slot_frame.modulate = Color(1, 1, 1, 1)
	inventory_frame.modulate = Color(1, 1, 1, 1)
	btn_verdict.modulate = Color(1, 1, 1, 1)

	var target: CanvasItem = input_a_frame
	if step == 2:
		target = inventory_frame
	elif step == 3:
		target = btn_verdict

	var tween := create_tween()
	tween.tween_property(target, "modulate", Color(1.08, 1.08, 1.04, 1.0), 0.18)
	tween.tween_property(target, "modulate", Color(1, 1, 1, 1), 0.22)

func _on_verdict_pressed() -> void:
	if is_safe_mode:
		return
	if btn_verdict.disabled:
		return
	_mark_first_action()
	verdict_count += 1

	var current_time: float = Time.get_ticks_msec() / 1000.0
	if current_time - last_verdict_time < 0.8:
		_show_feedback("Slow down before next VERDICT.", Color(1.0, 0.62, 0.28))
		_lock_verdict(3.0)
		_register_trial("RATE_LIMITED", false)
		return
	last_verdict_time = current_time

	if selected_gate_guess.is_empty():
		_show_feedback("Select a gate before VERDICT.", Color(1.0, 0.86, 0.32))
		_register_trial("EMPTY_SELECTION", false)
		return

	highlighted_fact_idx = -1
	if selected_gate_guess == current_case.gate:
		var confidence := _confidence_label()
		var seen_count := seen_combinations.size()
		var bonus := 0.0
		if seen_count <= 2:
			bonus = QUICK_SOLVE_BONUS_STABILITY
			var old_stability := GlobalMetrics.stability
			GlobalMetrics.stability = clampf(GlobalMetrics.stability + bonus, 0.0, 100.0)
			GlobalMetrics.stability_changed.emit(GlobalMetrics.stability, GlobalMetrics.stability - old_stability)
		var success_msg := "VERDICT confirmed. Confidence: %s." % confidence
		if bonus > 0.0:
			success_msg += " Quick solve bonus +%d stability." % int(bonus)
		_show_feedback(success_msg, Color(0.45, 0.92, 0.62))
		btn_verdict.visible = false
		btn_next.visible = true
		_disable_controls()
		_register_trial("SUCCESS", true)
	else:
		case_attempts += 1

		var penalty := 10.0
		if case_attempts == 2:
			penalty = 15.0
		elif case_attempts >= 3:
			penalty = 25.0

		_apply_penalty(penalty)
		var contradiction := _find_first_contradiction(selected_gate_guess)
		if not contradiction.is_empty():
			highlighted_fact_idx = int(contradiction.get("index", -1))
			if int(contradiction.get("b", -1)) < 0:
				_show_feedback("%s contradicts probe #%d: %s=%d, F_box=%d, F_model=%d (-%d)." % [
					_gate_title(selected_gate_guess),
					int(contradiction.get("index", 0)) + 1,
					str(current_case.get("a_text", "A")),
					int(contradiction.get("a", 0)),
					int(contradiction.get("f", 0)),
					int(contradiction.get("model", 0)),
					int(penalty)
				], Color(1.0, 0.35, 0.32))
			else:
				_show_feedback("%s contradicts probe #%d: %s=%d, %s=%d, F_box=%d, F_model=%d (-%d)." % [
					_gate_title(selected_gate_guess),
					int(contradiction.get("index", 0)) + 1,
					str(current_case.get("a_text", "A")),
					int(contradiction.get("a", 0)),
					str(current_case.get("b_text", "B")),
					int(contradiction.get("b", 0)),
					int(contradiction.get("f", 0)),
					int(contradiction.get("model", 0)),
					int(penalty)
				], Color(1.0, 0.35, 0.32))
		else:
			_show_feedback("Wrong gate verdict (-%d)." % int(penalty), Color(1.0, 0.35, 0.32))
		var verdict_code := "WRONG_GATE"
		if case_attempts >= MAX_ATTEMPTS:
			_enter_safe_mode()
			verdict_code = "SAFE_MODE_TRIGGERED"
		_register_trial(verdict_code, false)

	_refresh_circuit_output()
	_update_terminal_text()
	_update_stats_ui()

func _find_first_contradiction(gate_id: String) -> Dictionary:
	for i in range(seen_trace_entries.size()):
		var entry: Dictionary = seen_trace_entries[i]
		var a_val := int(entry.get("a", 0)) == 1
		var b_idx := int(entry.get("b", -1))
		var b_val := b_idx == 1
		var predicted := _calculate_gate_output(a_val, b_val, gate_id)
		var observed := int(entry.get("f", 0)) == 1
		if predicted != observed:
			return {
				"index": i,
				"a": int(entry.get("a", 0)),
				"b": b_idx,
				"f": int(entry.get("f", 0)),
				"model": 1 if predicted else 0
			}
	return {}

func _lock_verdict(duration: float) -> void:
	if is_safe_mode:
		return
	btn_verdict.disabled = true
	verdict_timer.start(duration)

func _on_verdict_unlock() -> void:
	if is_safe_mode:
		return
	if GlobalMetrics.stability > 0.0 and btn_verdict.visible:
		btn_verdict.disabled = selected_gate_guess.is_empty()

func _enter_safe_mode() -> void:
	is_safe_mode = true
	_disable_controls()
	btn_verdict.disabled = true
	btn_next.visible = true

	_set_gate_buttons_enabled(false)
	_select_gate_button(str(current_case.get("gate", "")))

	var gate_symbol := _gate_symbol(str(current_case.get("gate", "")))
	var gate_title := _gate_title(str(current_case.get("gate", "")))
	var safe_msg := "ﾐ岱片厘榧渙籍｡ﾐ斷ｫﾐ・ﾐﾐ片孟侑・ ﾐｿﾑﾐｰﾐｲﾐｸﾐｻﾑ糊ｽﾑ巾ｹ ﾐｲﾐｵﾐｽﾑひｸﾐｻﾑ・%s (%s)." % [gate_symbol, gate_title]
	_show_feedback(safe_msg, Color(1.0, 0.74, 0.32))
	_show_diagnostics("SAFE MODE", "%s\nﾐ柘巾ｿﾐｾﾐｻﾐｽﾐｵﾐｽ ﾐｰﾐｲﾑひｾﾑﾐｰﾐｷﾐｱﾐｾﾑ, ﾐｸﾐｷﾑτ・ｸﾑひｵ ﾐｶﾑτﾐｽﾐｰﾐｻ ﾐｸ ﾐｿﾐｵﾑﾐｵﾑ・ｾﾐｴﾐｸﾑひｵ ﾐｴﾐｰﾐｻﾐｵﾐｵ." % safe_msg)
	_update_ui_state()

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

func _show_feedback(msg: String, col: Color) -> void:
	feedback_label.text = msg
	feedback_label.add_theme_color_override("font_color", col)
	feedback_label.visible = true
	_update_ui_state()

func _apply_penalty(amount: float) -> void:
	GlobalMetrics.stability = max(0.0, GlobalMetrics.stability - amount)
	GlobalMetrics.stability_changed.emit(GlobalMetrics.stability, -amount)

func _update_stability_ui(val: float, _change: float) -> void:
	energy_bar.value = clampf(val, 0.0, 100.0)
	_update_stats_ui()
	_update_ui_state()

func _update_stats_ui() -> void:
	var required := _required_probe_count()
	var confidence := _confidence_label()
	var case_id := str(current_case.get("id", "A_00"))
	session_label.text = "ﾐ｡ﾐ片｡ﾐ｡ﾐ侑ｯ: %02d/%02d 窶｢ CASE %s" % [current_case_index + 1, CASES.size(), case_id]
	stats_label.text = "Attempts %d/%d | Probes %d/%d | Confidence %s | Stability %d%%" % [
		case_attempts,
		MAX_ATTEMPTS,
		seen_combinations.size(),
		required,
		confidence,
		int(GlobalMetrics.stability)
	]
	_update_target_and_bars()
	_update_ui_state()

func _on_game_over() -> void:
	_enter_safe_mode()

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _on_next_button_pressed() -> void:
	_hide_diagnostics()
	load_case(current_case_index + 1)

func _on_hint_pressed() -> void:
	if is_safe_mode or not btn_verdict.visible:
		return
	var now_sec := Time.get_ticks_msec() / 1000.0
	if now_sec < analyze_cooldown_until:
		_show_feedback("ANALYZE OVERHEAT: wait %ds." % int(ceil(analyze_cooldown_until - now_sec)), Color(1.0, 0.78, 0.32))
		_update_ui_state()
		return

	_mark_first_action()
	hints_used += 1
	analyze_cooldown_until = now_sec + ANALYZE_COOLDOWN_SECONDS

	if selected_gate_guess.is_empty():
		if seen_trace_entries.is_empty():
			_show_feedback("ANALYZE: run at least one PROBE first.", Color(0.56, 0.78, 0.96))
		else:
			var hint_idx := (hints_used - 1) % maxi(1, current_case.hints.size())
			var h := str(current_case.hints[hint_idx]) if current_case.hints.size() > 0 else "Capture contrasting probes."
			_show_feedback("ANALYZE: " + h, Color(0.56, 0.78, 0.96))
	else:
		var contradiction := _find_first_contradiction(selected_gate_guess)
		if contradiction.is_empty():
			_show_feedback("ANALYZE: no contradictions in captured probes for selected gate.", Color(0.56, 0.78, 0.96))
		elif int(contradiction.get("b", -1)) < 0:
			_show_feedback("ANALYZE: probe #%d contradicts %s at %s=%d." % [
				int(contradiction.get("index", 0)) + 1,
				_gate_title(selected_gate_guess),
				str(current_case.get("a_text", "A")),
				int(contradiction.get("a", 0))
			], Color(0.56, 0.78, 0.96))
		else:
			_show_feedback("ANALYZE: probe #%d contradicts %s at %s=%d, %s=%d." % [
				int(contradiction.get("index", 0)) + 1,
				_gate_title(selected_gate_guess),
				str(current_case.get("a_text", "A")),
				int(contradiction.get("a", 0)),
				str(current_case.get("b_text", "B")),
				int(contradiction.get("b", 0))
			], Color(0.56, 0.78, 0.96))
			highlighted_fact_idx = int(contradiction.get("index", -1))
	_update_terminal_text()
	_update_stats_ui()

func _mark_first_action() -> void:
	if first_action_ms < 0:
		first_action_ms = Time.get_ticks_msec() - start_time_msec

func _register_trial(verdict_code: String, is_correct: bool) -> void:
	var case_id := str(current_case.get("id", "A_00"))
	var payload := TrialV2.build("LOGIC_QUEST", "A", case_id, "GATE_IDENTIFY")
	var elapsed_ms: int = maxi(0, Time.get_ticks_msec() - start_time_msec)
	payload["elapsed_ms"] = elapsed_ms
	payload["duration"] = float(elapsed_ms) / 1000.0
	payload["time_to_first_action_ms"] = first_action_ms if first_action_ms >= 0 else elapsed_ms
	payload["is_correct"] = is_correct
	payload["is_fit"] = is_correct
	payload["stability_delta"] = 0
	payload["verdict_code"] = verdict_code
	payload["selected_gate_id"] = selected_gate_guess
	payload["correct_gate_id"] = str(current_case.get("gate", ""))
	payload["seen_combinations"] = seen_combinations.size()
	payload["hints_used"] = hints_used
	payload["analyze_count"] = hints_used
	payload["probe_count"] = seen_trace_entries.size()
	payload["confidence_ratio"] = _confidence_ratio()
	payload["confidence_level"] = _confidence_label()
	payload["attempts"] = case_attempts
	payload["verdict_count"] = verdict_count
	GlobalMetrics.register_trial(payload)

func _play_click() -> void:
	if click_player.stream:
		click_player.play()

func _disable_controls() -> void:
	input_a_btn.disabled = true
	input_b_btn.disabled = true
	_set_gate_buttons_enabled(false)
	btn_probe.disabled = true
	btn_hint.disabled = true

func _on_viewport_size_changed() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var is_landscape: bool = viewport_size.x > viewport_size.y
	var compact: bool = viewport_size.x < 980.0 or viewport_size.y < 760.0

	_apply_safe_area_padding(compact)
	main_layout.add_theme_constant_override("separation", 6 if compact else 8)
	interaction_row.add_theme_constant_override("separation", 8 if compact else 12)
	actions_row.add_theme_constant_override("separation", 10 if compact else 16)
	gates_container.add_theme_constant_override("separation", 10 if compact else 14)

	if not is_landscape:
		content_split.split_offset = int(viewport_size.x * 0.50)
	elif compact:
		content_split.split_offset = int(viewport_size.x * 0.54)
	else:
		content_split.split_offset = int(viewport_size.x * 0.56)

	terminal_text.add_theme_font_size_override("normal_font_size", 18 if compact else 20)
	stats_label.add_theme_font_size_override("font_size", 16 if compact else 18)
	feedback_label.add_theme_font_size_override("font_size", 16 if compact else 18)
	output_value_label.add_theme_font_size_override("font_size", 38 if compact else 48)
	model_value_label.add_theme_font_size_override("font_size", 22 if compact else 26)
	match_label.add_theme_font_size_override("font_size", 18 if compact else 20)

	var ctl_button_height: float = 56.0 if compact else 64.0
	input_a_btn.custom_minimum_size.y = ctl_button_height
	input_b_btn.custom_minimum_size.y = ctl_button_height
	btn_hint.custom_minimum_size.y = ctl_button_height
	btn_probe.custom_minimum_size.y = ctl_button_height
	btn_verdict.custom_minimum_size.y = ctl_button_height
	btn_next.custom_minimum_size.y = ctl_button_height
	for gate_button in [gate_and_btn, gate_or_btn, gate_not_btn, gate_xor_btn, gate_nand_btn, gate_nor_btn]:
		gate_button.custom_minimum_size = Vector2(112.0, 56.0) if compact else Vector2(128.0, 64.0)

	var popup_width: float = clampf(viewport_size.x - (24.0 if compact else 120.0), 300.0, 760.0)
	var popup_height: float = clampf(viewport_size.y - (24.0 if compact else 120.0), 220.0, 440.0)
	diagnostics_panel.offset_left = -popup_width * 0.5
	diagnostics_panel.offset_top = -popup_height * 0.5
	diagnostics_panel.offset_right = popup_width * 0.5
	diagnostics_panel.offset_bottom = popup_height * 0.5

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
