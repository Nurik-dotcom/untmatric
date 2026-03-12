extends PanelContainer

@onready var trace_label: RichTextLabel = $VBoxContainer/TraceList
@onready var explain_label: RichTextLabel = $VBoxContainer/ExplainList
@onready var btn_close: Button = $VBoxContainer/BtnClose
@onready var title_label: Label = $VBoxContainer/Title

func _ready() -> void:
	btn_close.text = "Close"
	btn_close.pressed.connect(_on_close_pressed)

func setup(payload_or_lines: Variant, trace_steps: Array = []) -> void:
	if typeof(payload_or_lines) == TYPE_DICTIONARY:
		_setup_from_payload(payload_or_lines)
		return

	# Legacy compatibility path.
	var explain_lines: Array = payload_or_lines if typeof(payload_or_lines) == TYPE_ARRAY else []
	_setup_from_payload({
		"mode": "legacy",
		"selected_block_id": "",
		"rendered_code": [],
		"predicted_s": 0,
		"target_s": 0,
		"delta": 0,
		"trace": trace_steps,
		"explain_lines": explain_lines,
		"why_not_lines": []
	})

func _setup_from_payload(payload: Dictionary) -> void:
	var mode: String = str(payload.get("mode", "preview"))
	var selected_block_id: String = str(payload.get("selected_block_id", ""))
	var predicted_s: int = int(payload.get("predicted_s", 0))
	var target_s: int = int(payload.get("target_s", 0))
	var delta: int = int(payload.get("delta", predicted_s - target_s))

	var explain_lines: Array = payload.get("explain_lines", [])
	var why_not_lines: Array = payload.get("why_not_lines", [])
	var rendered_code: Array = payload.get("rendered_code", [])
	var trace_steps: Array = payload.get("trace", [])
	var correct_preview: Dictionary = payload.get("correct_preview", {})

	title_label.text = _title_for_mode(mode)

	var explain_text: String = ""
	explain_text += "[b]Selected block:[/b] %s\n" % (selected_block_id if not selected_block_id.is_empty() else "-")
	explain_text += "[b]Predicted:[/b] s=%d | [b]Target:[/b] s=%d | [b]Delta:[/b] %+d\n\n" % [predicted_s, target_s, delta]

	if not rendered_code.is_empty():
		explain_text += "[b]Rendered code:[/b]\n"
		for idx in range(rendered_code.size()):
			explain_text += "%02d  %s\n" % [idx + 1, str(rendered_code[idx])]
		explain_text += "\n"

	if not why_not_lines.is_empty():
		explain_text += "[b]Why this variant:[/b]\n"
		for line in why_not_lines:
			explain_text += "- %s\n" % str(line)
		explain_text += "\n"

	if not explain_lines.is_empty():
		explain_text += "[b]Level notes:[/b]\n"
		for line in explain_lines:
			explain_text += "- %s\n" % str(line)

	if not correct_preview.is_empty():
		explain_text += "\n[b]Correct variant:[/b] %s | s=%d\n" % [
			str(correct_preview.get("block_id", "?")),
			int(correct_preview.get("computed_s", 0))
		]

	explain_label.bbcode_enabled = true
	explain_label.text = explain_text

	trace_label.bbcode_enabled = true
	trace_label.text = _format_trace(trace_steps, predicted_s, target_s)

func _format_trace(trace_steps: Array, predicted_s: int, target_s: int) -> String:
	if trace_steps.is_empty():
		return "Compact deterministic summary only. Predicted s=%d, target s=%d." % [predicted_s, target_s]

	var trace_text: String = ""
	for idx in range(trace_steps.size()):
		if typeof(trace_steps[idx]) != TYPE_DICTIONARY:
			continue
		var step: Dictionary = trace_steps[idx]
		trace_text += "#%d  i=%s | s: %s -> %s | %s\n" % [
			idx + 1,
			str(step.get("i", "?")),
			str(step.get("s_before", "?")),
			str(step.get("s_after", "?")),
			str(step.get("event", ""))
		]
	return trace_text

func _title_for_mode(mode: String) -> String:
	match mode:
		"fail":
			return "Reasoning: mismatch"
		"success":
			return "Reasoning: success"
		"safe_mode":
			return "Safe review"
		_:
			return "Variant reasoning"

func _on_close_pressed() -> void:
	visible = false
