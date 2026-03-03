extends Control

const CASE_ID := "CASE_01_DIGITAL_RESUS"
const QUEST_SELECT_SCENE := "res://scenes/QuestSelect.tscn"
const STAGE_ORDER: Array[String] = ["A", "B", "C"]
const STAGE_SCENES := {
	"A": "res://scenes/case_01/DigitalResusQuestA.tscn",
	"B": "res://scenes/case_01/DigitalResusQuestB.tscn",
	"C": "res://scenes/case_01/DigitalResusQuestC.tscn"
}

var _routing: bool = false

@onready var title_label: Label = $SafeArea/MainVBox/Header/TitleLabel
@onready var run_label: Label = $SafeArea/MainVBox/Header/RunLabel
@onready var body_label: RichTextLabel = $SafeArea/MainVBox/BodyCard/BodyVBox/BodyLabel
@onready var summary_label: RichTextLabel = $SafeArea/MainVBox/SummaryCard/SummaryVBox/SummaryLabel
@onready var btn_abort: Button = $SafeArea/MainVBox/Footer/BtnAbort
@onready var btn_close: Button = $SafeArea/MainVBox/Footer/BtnClose
@onready var summary_card: PanelContainer = $SafeArea/MainVBox/SummaryCard
@onready var noir_overlay: Node = $NoirOverlay

func _ready() -> void:
	btn_abort.pressed.connect(_on_abort_pressed)
	btn_close.pressed.connect(_on_close_pressed)
	if not GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.connect(_on_stability_changed)
	_bootstrap_flow()

func _exit_tree() -> void:
	if GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.disconnect(_on_stability_changed)

func _bootstrap_flow() -> void:
	var flow: Dictionary = GlobalMetrics.get_case_flow()
	if not bool(flow.get("is_active", false)) or str(flow.get("case_id", "")) != CASE_ID:
		GlobalMetrics.start_case_flow(CASE_ID, STAGE_ORDER)
		flow = GlobalMetrics.get_case_flow()
	_refresh_ui(flow)

func _refresh_ui(flow: Dictionary) -> void:
	title_label.text = "Case 01 Flow"
	run_label.text = "RUN %s" % str(flow.get("case_run_id", ""))
	if _is_complete(flow):
		_routing = false
		btn_abort.visible = false
		btn_close.visible = true
		summary_card.visible = true
		body_label.text = _build_progress_text(flow)
		summary_label.text = _build_summary_text(flow)
		return

	btn_abort.visible = true
	btn_close.visible = false
	summary_card.visible = false
	body_label.text = _build_progress_text(flow)
	if not _routing:
		_routing = true
		call_deferred("_route_to_next_stage")

func _route_to_next_stage() -> void:
	var flow: Dictionary = GlobalMetrics.get_case_flow()
	var next_stage: String = _next_stage(flow)
	if next_stage == "":
		_routing = false
		_refresh_ui(flow)
		return
	var scene_path: String = str(STAGE_SCENES.get(next_stage, QUEST_SELECT_SCENE))
	get_tree().change_scene_to_file(scene_path)

func _build_progress_text(flow: Dictionary) -> String:
	var completed: Array = flow.get("completed_stages", []) as Array
	var lines: Array[String] = []
	lines.append("Case: %s" % CASE_ID)
	lines.append("Stages: %s" % " -> ".join(STAGE_ORDER))
	lines.append("")
	for stage_id in STAGE_ORDER:
		var done: bool = completed.has(stage_id)
		lines.append("[%s] Stage %s" % ["x" if done else " ", stage_id])
	lines.append("")
	var next_stage: String = _next_stage(flow)
	if next_stage == "":
		lines.append("All stages completed. Closing case...")
	else:
		lines.append("Routing to Stage %s..." % next_stage)
	return "\n".join(lines)

func _build_summary_text(flow: Dictionary) -> String:
	var case_run_id: String = str(flow.get("case_run_id", ""))
	var total_points: int = 0
	var total_stability_delta: int = 0
	var stage_lines: Array[String] = []

	for stage_id in STAGE_ORDER:
		var summary: Dictionary = (flow.get("stage_results", {}) as Dictionary).get(stage_id, {}) as Dictionary
		stage_lines.append("Stage %s | points %d | stability %d | last %s" % [
			stage_id,
			int(summary.get("points", 0)),
			int(summary.get("stability_delta", 0)),
			str(summary.get("last_level_id", "-"))
		])

	for entry_v in GlobalMetrics.session_history:
		if typeof(entry_v) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_v as Dictionary
		if str(entry.get("quest_id", "")) != CASE_ID:
			continue
		if str(entry.get("case_run_id", "")) != case_run_id:
			continue
		total_points += int(entry.get("points", 0))
		total_stability_delta += int(entry.get("stability_delta", 0))

	var lines: Array[String] = []
	lines.append("CASE CLOSED")
	lines.append("")
	lines.append_array(stage_lines)
	lines.append("")
	lines.append("Total points: %d" % total_points)
	lines.append("Total stability delta: %d" % total_stability_delta)
	lines.append("Stability now: %d" % int(round(GlobalMetrics.stability)))
	return "\n".join(lines)

func _next_stage(flow: Dictionary) -> String:
	var completed: Array = flow.get("completed_stages", []) as Array
	for stage_id in STAGE_ORDER:
		if not completed.has(stage_id):
			return stage_id
	return ""

func _is_complete(flow: Dictionary) -> bool:
	return _next_stage(flow) == ""

func _on_abort_pressed() -> void:
	GlobalMetrics.clear_case_flow()
	get_tree().change_scene_to_file(QUEST_SELECT_SCENE)

func _on_close_pressed() -> void:
	GlobalMetrics.clear_case_flow()
	get_tree().change_scene_to_file(QUEST_SELECT_SCENE)

func _on_stability_changed(_new_value: float, _delta: float) -> void:
	if noir_overlay != null and noir_overlay.has_method("set_danger_level"):
		noir_overlay.call("set_danger_level", float(GlobalMetrics.stability))
