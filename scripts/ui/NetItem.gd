extends Button

signal drag_started(module_id: String, source: String, from_slot: int)

var module_id: String = ""
var module_label: String = ""
var source: String = "PALETTE"
var from_slot: int = -1

var _locked: bool = false
var _feedback_state: String = "neutral"

func setup(option_data: Dictionary) -> void:
	module_id = str(option_data.get("module_id", option_data.get("option_id", ""))).strip_edges()
	module_label = str(option_data.get("label", module_id))
	text = module_label
	tooltip_text = "MODULE %s\n%s" % [module_label, str(option_data.get("why", ""))]
	custom_minimum_size = Vector2(0, 88)
	set_source("PALETTE", -1)
	set_feedback_state("neutral")
	set_locked(false)

func set_source(p_source: String, p_from_slot: int) -> void:
	source = p_source
	from_slot = p_from_slot

func set_locked(locked: bool) -> void:
	_locked = locked
	disabled = locked
	_apply_visual_state()

func set_feedback_state(state: String) -> void:
	_feedback_state = state
	_apply_visual_state()

func _get_drag_data(_at_position: Vector2) -> Variant:
	if _locked or module_id == "":
		return null

	drag_started.emit(module_id, source, from_slot)

	var preview: Button = duplicate() as Button
	preview.disabled = true
	preview.modulate.a = 0.9
	var holder: Control = Control.new()
	holder.add_child(preview)
	preview.position = -0.5 * preview.size
	set_drag_preview(holder)

	return {
		"kind": "NET_MODULE",
		"module_id": module_id,
		"from": source,
		"from_slot": from_slot,
		"node_path": str(get_path()),
		"label": module_label
	}

func _apply_visual_state() -> void:
	var tone: Color = Color(1.0, 1.0, 1.0, 1.0)
	match _feedback_state:
		"correct":
			tone = Color(1.05, 1.05, 1.05, 1.0)
		"wrong":
			tone = Color(1.12, 0.84, 0.86, 1.0)
		"missing":
			tone = Color(1.08, 0.98, 0.9, 1.0)
		_:
			tone = Color(1.0, 1.0, 1.0, 1.0)

	if _locked and _feedback_state == "neutral":
		tone = Color(0.82, 0.82, 0.82, 1.0)

	self_modulate = tone
