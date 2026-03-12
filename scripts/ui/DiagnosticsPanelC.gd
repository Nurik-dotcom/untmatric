extends PanelContainer

@onready var lbl_title: Label = $Root/LblTitle
@onready var text_body: RichTextLabel = $Root/Body
@onready var btn_close: Button = $Root/BtnClose

func _ready() -> void:
	btn_close.pressed.connect(_on_close_pressed)
	btn_close.text = "Close"
	text_body.bbcode_enabled = true

func setup(payload: Dictionary) -> void:
	var mode: String = str(payload.get("mode", "text_only"))
	var title: String = str(payload.get("title", "")).strip_edges()
	lbl_title.text = title if not title.is_empty() else _title_for_mode(mode)
	text_body.text = _build_body(payload, mode)

func _build_body(payload: Dictionary, mode: String) -> String:
	if mode == "text_only":
		return _section_list("Details", payload.get("reasoning_lines", []))

	var lines: Array[String] = []
	var task_id: String = str(payload.get("task_id", "")).strip_edges()
	if not task_id.is_empty():
		lines.append("[b]Task:[/b] %s" % task_id)

	var has_expected: bool = payload.has("expected_s")
	var has_actual: bool = payload.has("actual_s")
	if has_expected or has_actual:
		var expected_value: Variant = payload.get("expected_s", "?")
		var actual_value: Variant = payload.get("actual_s", "?")
		var delta_text := "?"
		if _is_numeric(expected_value) and _is_numeric(actual_value):
			delta_text = _num_to_text(float(actual_value) - float(expected_value))
		lines.append("[b]Mismatch:[/b] expected=%s, actual=%s, delta=%s" % [
			_num_to_text(expected_value),
			_num_to_text(actual_value),
			delta_text
		])

	var selected_line_index: int = int(payload.get("selected_line_index", -1))
	var selected_patch_id: String = str(payload.get("selected_patch_id", "")).strip_edges()
	if selected_line_index >= 0 or not selected_patch_id.is_empty():
		lines.append("[b]Selection:[/b] line=%s, patch=%s" % [
			"?" if selected_line_index < 0 else str(selected_line_index + 1),
			"-" if selected_patch_id.is_empty() else selected_patch_id
		])

	var selected_patch_line: String = str(payload.get("selected_patch_line", "")).strip_edges()
	if not selected_patch_line.is_empty():
		lines.append("[b]Patch:[/b] %s" % selected_patch_line)

	if payload.has("selected_result_s"):
		lines.append("[b]Patched actual:[/b] s=%s" % _num_to_text(payload.get("selected_result_s", "?")))

	_append_section(lines, "Reasoning", payload.get("reasoning_lines", []))
	_append_section(lines, "Why Not", payload.get("why_not_lines", []))
	_append_section(lines, "Trace", _format_trace(payload.get("trace", [])))

	var action_hint: String = str(payload.get("action_hint", "")).strip_edges()
	if not action_hint.is_empty():
		lines.append("")
		lines.append("[b]Action:[/b] %s" % action_hint)

	return "\n".join(lines)

func _append_section(lines: Array[String], title: String, values: Variant) -> void:
	var list: Array = values if typeof(values) == TYPE_ARRAY else []
	if list.is_empty():
		return
	lines.append("")
	lines.append(_section_list(title, list))

func _section_list(title: String, entries_variant: Variant) -> String:
	var entries: Array = entries_variant if typeof(entries_variant) == TYPE_ARRAY else []
	var out: Array[String] = []
	out.append("[b]%s[/b]" % title)
	if entries.is_empty():
		out.append("-")
		return "\n".join(out)
	for line_var in entries:
		out.append("- %s" % str(line_var))
	return "\n".join(out)

func _format_trace(trace_variant: Variant) -> Array:
	var trace: Array = trace_variant if typeof(trace_variant) == TYPE_ARRAY else []
	var out: Array[String] = []
	for step_var in trace:
		if typeof(step_var) != TYPE_DICTIONARY:
			out.append(str(step_var))
			continue
		var step: Dictionary = step_var
		out.append("#%s i=%s | s: %s -> %s | %s" % [
			str(step.get("step", "?")),
			str(step.get("i", "?")),
			_num_to_text(step.get("s_before", "?")),
			_num_to_text(step.get("s_after", "?")),
			str(step.get("event", ""))
		])
	return out

func _is_numeric(value: Variant) -> bool:
	var t: int = typeof(value)
	return t == TYPE_INT or t == TYPE_FLOAT

func _num_to_text(value: Variant) -> String:
	if not _is_numeric(value):
		return str(value)
	var as_float: float = float(value)
	var as_int: int = int(round(as_float))
	if absf(as_float - float(as_int)) <= 0.00001:
		return str(as_int)
	return str(as_float)

func _title_for_mode(mode: String) -> String:
	match mode:
		"preverify":
			return "Forensic diagnostics (pre-verify)"
		"wrong_line":
			return "Forensic diagnostics (wrong line)"
		"wrong_patch":
			return "Forensic diagnostics (wrong patch)"
		"success":
			return "Forensic diagnostics (success)"
		"safe_review":
			return "Safe review"
		_:
			return "Diagnostics"

func _on_close_pressed() -> void:
	visible = false
