extends PanelContainer

signal all_rounds_complete

const IP_INPUT_SCENE: PackedScene = preload("res://scenes/ui/IpInput.tscn")

var _level_data: Dictionary = {}
var _controller: Node = null
var _rounds: Array = []
var _answers: Array = []
var _round_index: int = 0
var _awaiting_next: bool = false

@onready var progress_label: Label = $VBox/ProgressLabel
@onready var info_label: Label = $VBox/InfoLabel
@onready var binary_label: RichTextLabel = $VBox/BinaryLabel
@onready var network_row: HBoxContainer = $VBox/NetworkRow
@onready var broadcast_row: HBoxContainer = $VBox/BroadcastRow
@onready var network_label: Label = $VBox/NetworkRow/NetworkLabel
@onready var broadcast_label: Label = $VBox/BroadcastRow/BroadcastLabel
@onready var hosts_label: Label = $VBox/HostsRow/HostsLabel
@onready var hosts_edit: LineEdit = $VBox/HostsRow/HostsEdit
@onready var btn_check: Button = $VBox/BtnCheck
@onready var explain_label: RichTextLabel = $VBox/ExplainLabel

var _network_input: Node = null
var _broadcast_input: Node = null

func _ready() -> void:
	btn_check.pressed.connect(_on_check_pressed)

func setup(level_data: Dictionary, controller: Node) -> void:
	_level_data = level_data.duplicate(true)
	_controller = controller
	_rounds = _level_data.get("rounds", []) as Array
	_round_index = 0
	_answers.clear()
	_awaiting_next = false
	_ensure_inputs()
	_render_round()

func apply_i18n() -> void:
	_render_round()

func reset() -> void:
	_round_index = 0
	_answers.clear()
	_awaiting_next = false
	_render_round()

func get_answers() -> Variant:
	return _answers.duplicate(true)

func show_result(result: Dictionary) -> void:
	explain_label.text = "[b]%s[/b] %d/%d" % [str(result.get("verdict_code", "")), int(result.get("correct_count", 0)), int(result.get("total", 0))]

func _ensure_inputs() -> void:
	if _network_input == null:
		_network_input = IP_INPUT_SCENE.instantiate()
		network_row.add_child(_network_input)
	if _broadcast_input == null:
		_broadcast_input = IP_INPUT_SCENE.instantiate()
		broadcast_row.add_child(_broadcast_input)

func _render_round() -> void:
	if _rounds.is_empty():
		progress_label.text = "0/0"
		info_label.text = ""
		btn_check.disabled = true
		return

	var idx: int = clampi(_round_index, 0, _rounds.size() - 1)
	var round_data: Dictionary = _rounds[idx] as Dictionary
	progress_label.text = "%d/%d" % [idx + 1, _rounds.size()]
	var ip: String = str(round_data.get("ip", ""))
	var mask: String = str(round_data.get("mask", ""))
	var prefix: int = int(round_data.get("prefix", 0))
	info_label.text = "IP: %s    MASK: %s (/%d)" % [ip, mask, prefix]
	binary_label.text = _binary_info(ip, mask, prefix)
	_apply_question_labels(round_data.get("questions", []) as Array)
	btn_check.text = I18n.tr_key("resus.btn.confirm", {"default": "CONFIRM"})
	btn_check.disabled = false
	hosts_edit.text = ""
	explain_label.text = ""
	_awaiting_next = false
	_set_inputs_editable(true)
	_reset_input_highlights()
	if _network_input != null and _network_input.has_method("clear"):
		_network_input.call("clear")
	if _broadcast_input != null and _broadcast_input.has_method("clear"):
		_broadcast_input.call("clear")

func _on_check_pressed() -> void:
	if _rounds.is_empty():
		return

	if _awaiting_next:
		_awaiting_next = false
		if _round_index < _rounds.size() - 1:
			_round_index += 1
			_render_round()
		else:
			all_rounds_complete.emit()
		return

	var idx: int = clampi(_round_index, 0, _rounds.size() - 1)
	var answer: Dictionary = {
		"network": _network_input.call("get_ip") if _network_input != null else "",
		"broadcast": _broadcast_input.call("get_ip") if _broadcast_input != null else "",
		"hosts": hosts_edit.text.strip_edges()
	}
	if _answers.size() <= idx:
		_answers.resize(idx + 1)
	_answers[idx] = answer

	var round_data: Dictionary = _rounds[idx] as Dictionary
	var check: Dictionary = _check_round_answers(round_data, answer)
	_apply_check_highlights(check)
	explain_label.text = _build_round_explain(round_data)

	_set_inputs_editable(false)
	_awaiting_next = true
	btn_check.disabled = false
	btn_check.text = I18n.tr_key("resus.btn.next_round", {"default": "NEXT ->"}) if _round_index < _rounds.size() - 1 else I18n.tr_key("resus.btn.finish_quiz", {"default": "FINISH"})

func _check_round_answers(round_data: Dictionary, answer: Dictionary) -> Dictionary:
	var expected: Dictionary = {"network": "", "broadcast": "", "hosts": ""}
	for question_v in round_data.get("questions", []) as Array:
		if typeof(question_v) != TYPE_DICTIONARY:
			continue
		var question: Dictionary = question_v as Dictionary
		var q_type: String = _normalize_question_type(str(question.get("type", "")))
		if q_type == "":
			continue
		expected[q_type] = _normalize_value(q_type, str(question.get("correct", "")))

	var network_given: String = _normalize_value("network", str(answer.get("network", "")))
	var broadcast_given: String = _normalize_value("broadcast", str(answer.get("broadcast", "")))
	var hosts_given: String = _normalize_value("hosts", str(answer.get("hosts", "")))
	return {
		"network_ok": network_given == str(expected.get("network", "")),
		"broadcast_ok": broadcast_given == str(expected.get("broadcast", "")),
		"hosts_ok": hosts_given == str(expected.get("hosts", ""))
	}

func _apply_check_highlights(check: Dictionary) -> void:
	_apply_input_highlight(_network_input, bool(check.get("network_ok", false)))
	_apply_input_highlight(_broadcast_input, bool(check.get("broadcast_ok", false)))
	hosts_edit.modulate = _ok_color(bool(check.get("hosts_ok", false)))

func _apply_input_highlight(input_node: Node, ok: bool) -> void:
	if input_node is Control:
		(input_node as Control).modulate = _ok_color(ok)

func _reset_input_highlights() -> void:
	if _network_input is Control:
		(_network_input as Control).modulate = Color(1, 1, 1, 1)
	if _broadcast_input is Control:
		(_broadcast_input as Control).modulate = Color(1, 1, 1, 1)
	hosts_edit.modulate = Color(1, 1, 1, 1)

func _ok_color(ok: bool) -> Color:
	return Color(0.72, 1.0, 0.74, 1.0) if ok else Color(1.0, 0.74, 0.74, 1.0)

func _set_inputs_editable(editable: bool) -> void:
	if _network_input != null and _network_input.has_method("set_editable"):
		_network_input.call("set_editable", editable)
	if _broadcast_input != null and _broadcast_input.has_method("set_editable"):
		_broadcast_input.call("set_editable", editable)
	hosts_edit.editable = editable

func _build_round_explain(round_data: Dictionary) -> String:
	var lines: Array[String] = []
	var round_explain: String = _resolve_explain(round_data)
	if round_explain.strip_edges() != "":
		lines.append(round_explain)
	for question_v in round_data.get("questions", []) as Array:
		if typeof(question_v) != TYPE_DICTIONARY:
			continue
		var question: Dictionary = question_v as Dictionary
		var q_explain: String = _resolve_explain(question)
		if q_explain.strip_edges() != "":
			lines.append(q_explain)
	return "\n".join(lines)

func _resolve_explain(item_data: Dictionary) -> String:
	var key: String = str(item_data.get("explain_key", ""))
	var fallback: String = str(item_data.get("explain", ""))
	if key != "":
		return I18n.tr_key(key, {"default": fallback})
	return fallback

func _apply_question_labels(questions: Array) -> void:
	network_label.text = I18n.tr_key("resus.c03.q.network", {"default": "Network address"})
	broadcast_label.text = I18n.tr_key("resus.c03.q.broadcast", {"default": "Broadcast"})
	hosts_label.text = I18n.tr_key("resus.c03.q.hosts", {"default": "Host count"})
	for question_v in questions:
		if typeof(question_v) != TYPE_DICTIONARY:
			continue
		var question: Dictionary = question_v as Dictionary
		var q_type: String = _normalize_question_type(str(question.get("type", "")))
		var prompt: String = I18n.resolve_field(question, "prompt", {"default": q_type})
		match q_type:
			"network":
				network_label.text = prompt
			"broadcast":
				broadcast_label.text = prompt
			"hosts":
				hosts_label.text = prompt

func _normalize_question_type(raw_type: String) -> String:
	var q_type: String = raw_type.strip_edges().to_lower()
	match q_type:
		"network", "network_address":
			return "network"
		"broadcast":
			return "broadcast"
		"hosts", "host_count":
			return "hosts"
		_:
			return ""

func _normalize_value(q_type: String, raw: String) -> String:
	var trimmed: String = raw.strip_edges()
	if q_type == "network" or q_type == "broadcast":
		return _normalize_ip_answer(trimmed)
	if q_type == "hosts":
		if trimmed == "":
			return ""
		return str(int(trimmed)) if trimmed.is_valid_int() else trimmed
	return trimmed

func _normalize_ip_answer(raw: String) -> String:
	var parts: PackedStringArray = raw.strip_edges().split(".")
	if parts.size() != 4:
		return raw.strip_edges()
	var out: PackedStringArray = PackedStringArray()
	for part in parts:
		var token: String = part.strip_edges()
		if token == "" or not token.is_valid_int():
			return raw.strip_edges()
		out.append(str(int(token)))
	return ".".join(out)

func _binary_info(ip: String, mask: String, prefix: int) -> String:
	return "IP: %s\nMASK: %s\n/%d" % [_to_binary_ip(ip), _to_binary_ip(mask), prefix]

func _to_binary_ip(ip: String) -> String:
	var parts: PackedStringArray = ip.split(".")
	if parts.size() != 4:
		return ip
	var out: PackedStringArray = PackedStringArray()
	for part in parts:
		var value: int = int(part)
		out.append(_to_binary_octet(value))
	return ".".join(out)

func _to_binary_octet(value: int) -> String:
	var safe_value: int = clampi(value, 0, 255)
	var bits: PackedStringArray = PackedStringArray()
	for shift in range(7, -1, -1):
		bits.append(str((safe_value >> shift) & 1))
	return "".join(bits)
