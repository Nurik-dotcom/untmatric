extends RefCounted
class_name TrialV2

static func build(quest_id: String, stage_id: String, task_id: String, interaction_type: String, variant_hash: String = "") -> Dictionary:
	var normalized_task_id := task_id if task_id != "" else "unknown_task"
	var normalized_variant_hash := variant_hash
	if normalized_variant_hash == "":
		normalized_variant_hash = str(hash("%s|%s|%s|%s" % [quest_id, stage_id, normalized_task_id, interaction_type]))

	return {
		"schema_version": "trial.v2",
		"quest_id": quest_id,
		"stage": stage_id,
		"task_id": normalized_task_id,
		"interaction_type": interaction_type,
		"variant_hash": normalized_variant_hash,
		"match_key": "%s|%s|%s|v%s" % [quest_id, stage_id, normalized_task_id, normalized_variant_hash]
	}
