extends Control

var current_case_data: Dictionary
var opened_evidences: Array[String] = []

func _ready():
	current_case_data = GlobalMetrics.load_level_data("hardware_01")
	var ideal_time = float(current_case_data.get("ideal_time", 100.0))
	GlobalMetrics.reset_metrics(ideal_time)

func _on_evidence_clicked(evidence_id: String):
	if not opened_evidences.has(evidence_id):
		opened_evidences.append(evidence_id)
	
	var required = current_case_data.get("evidence_required", [])
	var all_found = true
	for req in required:
		if not opened_evidences.has(req):
			all_found = false
			break
	
	if all_found:
		$UI/ActionBtn.disabled = false

func _on_action_btn_pressed():
	var required = current_case_data.get("evidence_required", [])
	if opened_evidences.size() < required.size():
		GlobalMetrics.t_penalty += 30.0
