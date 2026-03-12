extends RefCounted
class_name RestoreBSemanticEvaluator

const STATUS_VALID_UNIQUE := "valid_unique_solution"
const STATUS_VALID_MULTIPLE := "valid_multiple_solutions"
const STATUS_INVALID_NO_SOLUTION := "invalid_no_solution"
const STATUS_INVALID_CORRECT_ID := "invalid_correct_id_mismatch"
const STATUS_INVALID_TRACE := "invalid_trace_mismatch"
const STATUS_INVALID_EXPLAIN := "invalid_explain_mismatch"

const _EXPLAIN_DEBUG_MARKERS: Array[String] = [
	"debug",
	"note:",
	"let's",
	"wait",
	"fix expectation",
	"none of the options"
]

func build_variant_previews(level: Dictionary) -> Dictionary:
	var previews: Dictionary = {}
	var blocks: Array = level.get("blocks", [])
	for block_var in blocks:
		if typeof(block_var) != TYPE_DICTIONARY:
			continue
		var block: Dictionary = block_var
		var preview: Dictionary = evaluate_variant(level, block)
		previews[str(block.get("block_id", ""))] = preview
	return previews

func evaluate_variant(level: Dictionary, block: Dictionary) -> Dictionary:
	var block_id: String = str(block.get("block_id", ""))
	var insert_text: String = str(block.get("insert", ""))
	var rendered_code: Array = _render_variant_code(level.get("code_template", []), insert_text)
	var target_value: int = int(level.get("target_s", 0))

	var result: Dictionary = {
		"block_id": block_id,
		"insert": insert_text,
		"rendered_code": rendered_code,
		"computed_s": 0,
		"trace": [],
		"is_target_match": false,
		"semantic_valid": false,
		"error": ""
	}

	if rendered_code.is_empty():
		result["error"] = "empty_code_template"
		return result

	var parse_result: Dictionary = _parse_program(rendered_code)
	if not bool(parse_result.get("ok", false)):
		result["error"] = str(parse_result.get("error", "parse_error"))
		return result

	var execution: Dictionary = _execute_program(parse_result.get("program", {}))
	if not bool(execution.get("ok", false)):
		result["error"] = str(execution.get("error", "execution_error"))
		return result

	var computed_s: int = int(execution.get("computed_s", 0))
	result["computed_s"] = computed_s
	result["trace"] = execution.get("trace", [])
	result["semantic_valid"] = true
	result["is_target_match"] = computed_s == target_value
	return result

func semantic_validate_level(level: Dictionary, previews_by_block: Dictionary = {}) -> Dictionary:
	var previews: Dictionary = previews_by_block
	if previews.is_empty():
		previews = build_variant_previews(level)

	var target_value: int = int(level.get("target_s", 0))
	var declared_correct_id: String = str(level.get("correct_block_id", ""))
	var solved_block_ids: Array = []
	var issues: Array = []

	for block_id_var in previews.keys():
		var preview: Dictionary = previews.get(block_id_var, {})
		if not bool(preview.get("semantic_valid", false)):
			issues.append({
				"code": "variant_error",
				"block_id": str(block_id_var),
				"error": str(preview.get("error", ""))
			})
			continue
		if int(preview.get("computed_s", 0)) == target_value:
			solved_block_ids.append(str(block_id_var))

	var status: String = STATUS_VALID_UNIQUE
	if solved_block_ids.is_empty():
		status = STATUS_INVALID_NO_SOLUTION
	elif solved_block_ids.size() > 1:
		status = STATUS_VALID_MULTIPLE

	if solved_block_ids.size() == 1 and declared_correct_id != solved_block_ids[0]:
		status = _choose_more_severe_status(status, STATUS_INVALID_CORRECT_ID)
		issues.append({
			"code": STATUS_INVALID_CORRECT_ID,
			"declared_correct_id": declared_correct_id,
			"computed_correct_id": solved_block_ids[0]
		})

	var trace_validation: Dictionary = _validate_declared_trace(level, solved_block_ids, previews)
	if not bool(trace_validation.get("ok", true)):
		status = _choose_more_severe_status(status, STATUS_INVALID_TRACE)
		issues.append({
			"code": STATUS_INVALID_TRACE,
			"message": str(trace_validation.get("message", "trace mismatch"))
		})

	var explain_lines: Array = level.get("explain_short", [])
	if _has_explain_debug_markers(explain_lines):
		status = _choose_more_severe_status(status, STATUS_INVALID_EXPLAIN)
		issues.append({
			"code": STATUS_INVALID_EXPLAIN,
			"message": "explain_short contains debug/editorial markers"
		})

	return {
		"status": status,
		"variants": previews,
		"solved_block_ids": solved_block_ids,
		"declared_correct_id": declared_correct_id,
		"target_s": target_value,
		"semantic_valid": status == STATUS_VALID_UNIQUE,
		"issues": issues
	}

func _render_variant_code(template_variant: Variant, insert_text: String) -> Array:
	var template_lines: Array = template_variant if typeof(template_variant) == TYPE_ARRAY else []
	var rendered: Array = []
	for raw_line in template_lines:
		var line: String = str(raw_line)
		rendered.append(line.replace("[SLOT]", insert_text))
	return rendered

func _parse_program(rendered_lines_variant: Variant) -> Dictionary:
	var rendered_lines: Array = rendered_lines_variant if typeof(rendered_lines_variant) == TYPE_ARRAY else []
	if rendered_lines.size() < 3:
		return {"ok": false, "error": "program_too_short"}

	var lines: Array = []
	for idx in range(rendered_lines.size()):
		var line_text: String = str(rendered_lines[idx]).rstrip("\r\n")
		if line_text.strip_edges().is_empty():
			continue
		lines.append({"text": line_text, "line_ref": idx + 1})

	if lines.size() < 3 or lines.size() > 4:
		return {"ok": false, "error": "unsupported_statement_count"}

	var init_line: String = str(lines[0]["text"]).strip_edges()
	var init_match := RegEx.new()
	init_match.compile("^s\\s*=\\s*(-?\\d+)\\s*$")
	var init_result: RegExMatch = init_match.search(init_line)
	if init_result == null:
		return {"ok": false, "error": "invalid_initial_assignment"}
	var init_value: int = int(init_result.get_string(1))

	var for_line_raw: String = str(lines[1]["text"]).strip_edges()
	var for_match := RegEx.new()
	for_match.compile("^for\\s+i\\s+in\\s+range\\(([^)]*)\\):\\s*$")
	var for_result: RegExMatch = for_match.search(for_line_raw)
	if for_result == null:
		return {"ok": false, "error": "invalid_for_statement"}

	var range_args_text: String = for_result.get_string(1)
	var range_args: Array = []
	for arg in range_args_text.split(","):
		var token: String = str(arg).strip_edges()
		if not token.is_empty():
			range_args.append(token)
	if range_args.size() < 1 or range_args.size() > 3:
		return {"ok": false, "error": "unsupported_range_signature"}

	var cond_expr: String = ""
	var cond_line_ref: int = -1
	var update_line_ref: int = -1
	var update_line_text: String = ""

	if lines.size() == 3:
		update_line_ref = int(lines[2]["line_ref"])
		update_line_text = str(lines[2]["text"])
		if _indent_size(update_line_text) != 4:
			return {"ok": false, "error": "invalid_update_indent_for_for_body"}
	elif lines.size() == 4:
		var if_line_ref: int = int(lines[2]["line_ref"])
		var if_line_text: String = str(lines[2]["text"])
		if _indent_size(if_line_text) != 4:
			return {"ok": false, "error": "invalid_if_indent"}
		var if_match := RegEx.new()
		if_match.compile("^\\s*if\\s+(.+):\\s*$")
		var if_result: RegExMatch = if_match.search(if_line_text)
		if if_result == null:
			return {"ok": false, "error": "invalid_if_statement"}
		cond_expr = str(if_result.get_string(1)).strip_edges()
		cond_line_ref = if_line_ref
		update_line_ref = int(lines[3]["line_ref"])
		update_line_text = str(lines[3]["text"])
		if _indent_size(update_line_text) != 8:
			return {"ok": false, "error": "invalid_update_indent_for_if_body"}

	var update_parse: Dictionary = _parse_update_statement(update_line_text)
	if not bool(update_parse.get("ok", false)):
		return {"ok": false, "error": str(update_parse.get("error", "invalid_update_statement"))}

	var program: Dictionary = {
		"init_value": init_value,
		"range_args": range_args,
		"cond_expr": cond_expr,
		"cond_line_ref": cond_line_ref,
		"update_line_ref": update_line_ref,
		"update_op": str(update_parse.get("op", "+=")),
		"update_expr": str(update_parse.get("expr", "0"))
	}
	return {"ok": true, "program": program}

func _parse_update_statement(update_line_text: String) -> Dictionary:
	var stripped: String = update_line_text.strip_edges()
	var plus_re := RegEx.new()
	plus_re.compile("^s\\s*\\+=\\s*(.+)$")
	var plus_match: RegExMatch = plus_re.search(stripped)
	if plus_match != null:
		return {"ok": true, "op": "+=", "expr": str(plus_match.get_string(1)).strip_edges()}

	var set_re := RegEx.new()
	set_re.compile("^s\\s*=\\s*(.+)$")
	var set_match: RegExMatch = set_re.search(stripped)
	if set_match != null:
		return {"ok": true, "op": "=", "expr": str(set_match.get_string(1)).strip_edges()}

	return {"ok": false, "error": "unsupported_update_statement"}

func _execute_program(program_variant: Variant) -> Dictionary:
	if typeof(program_variant) != TYPE_DICTIONARY:
		return {"ok": false, "error": "program_type_error"}
	var program: Dictionary = program_variant

	var range_values: Dictionary = _resolve_range_values(program.get("range_args", []))
	if not bool(range_values.get("ok", false)):
		return {"ok": false, "error": str(range_values.get("error", "range_resolve_error"))}

	var start_value: int = int(range_values.get("start", 0))
	var stop_value: int = int(range_values.get("stop", 0))
	var step_value: int = int(range_values.get("step", 1))
	if step_value == 0:
		return {"ok": false, "error": "range_step_zero"}

	var cond_expr: String = str(program.get("cond_expr", ""))
	var update_expr: String = str(program.get("update_expr", "0"))
	var update_op: String = str(program.get("update_op", "+="))
	var update_line_ref: int = int(program.get("update_line_ref", -1))
	var cond_line_ref: int = int(program.get("cond_line_ref", -1))

	var s_value: int = int(program.get("init_value", 0))
	var trace: Array = []
	var step_index: int = 0

	for i_value in range(start_value, stop_value, step_value):
		step_index += 1
		var s_before: int = s_value
		var cond_ok: bool = true
		if not cond_expr.is_empty():
			var cond_result: Dictionary = _eval_condition(cond_expr, i_value)
			if not bool(cond_result.get("ok", false)):
				return {"ok": false, "error": str(cond_result.get("error", "condition_eval_error"))}
			cond_ok = bool(cond_result.get("value", false))

		var event_text: String = "condition skipped"
		var line_ref: int = cond_line_ref
		if cond_ok:
			var expr_result: Dictionary = _eval_numeric_expr(update_expr, i_value)
			if not bool(expr_result.get("ok", false)):
				return {"ok": false, "error": str(expr_result.get("error", "update_eval_error"))}
			var expr_value: int = int(expr_result.get("value", 0))
			if update_op == "+=":
				s_value += expr_value
				event_text = "s += %s" % update_expr
			else:
				s_value = expr_value
				event_text = "s = %s" % update_expr
			line_ref = update_line_ref

		trace.append({
			"step": step_index,
			"i": i_value,
			"s_before": s_before,
			"s_after": s_value,
			"cond": "pass" if cond_ok else "skip",
			"event": event_text,
			"line_ref": line_ref
		})

	return {"ok": true, "computed_s": s_value, "trace": trace}

func _resolve_range_values(args_variant: Variant) -> Dictionary:
	var args: Array = args_variant if typeof(args_variant) == TYPE_ARRAY else []
	if args.size() < 1 or args.size() > 3:
		return {"ok": false, "error": "invalid_range_arity"}

	var parsed: Array = []
	for token_var in args:
		var token_result: Dictionary = _eval_numeric_expr(str(token_var), 0)
		if not bool(token_result.get("ok", false)):
			return {"ok": false, "error": str(token_result.get("error", "range_arg_error"))}
		parsed.append(int(token_result.get("value", 0)))

	if parsed.size() == 1:
		return {"ok": true, "start": 0, "stop": parsed[0], "step": 1}
	if parsed.size() == 2:
		return {"ok": true, "start": parsed[0], "stop": parsed[1], "step": 1}
	return {"ok": true, "start": parsed[0], "stop": parsed[1], "step": parsed[2]}

func _eval_numeric_expr(expr: String, i_value: int) -> Dictionary:
	var trimmed: String = expr.strip_edges()
	if trimmed == "i":
		return {"ok": true, "value": i_value}

	var int_re := RegEx.new()
	int_re.compile("^-?\\d+$")
	if int_re.search(trimmed) != null:
		return {"ok": true, "value": int(trimmed)}

	var plus_re := RegEx.new()
	plus_re.compile("^i\\s*\\+\\s*(-?\\d+)$")
	var plus_match: RegExMatch = plus_re.search(trimmed)
	if plus_match != null:
		return {"ok": true, "value": i_value + int(plus_match.get_string(1))}

	var minus_re := RegEx.new()
	minus_re.compile("^i\\s*-\\s*(-?\\d+)$")
	var minus_match: RegExMatch = minus_re.search(trimmed)
	if minus_match != null:
		return {"ok": true, "value": i_value - int(minus_match.get_string(1))}

	return {"ok": false, "error": "unsupported_numeric_expr:%s" % trimmed}

func _eval_condition(cond_expr: String, i_value: int) -> Dictionary:
	var or_parts: Array[String] = _split_condition(cond_expr, " or ")
	var has_true: bool = false
	for or_part in or_parts:
		var and_parts: Array[String] = _split_condition(or_part, " and ")
		var all_true: bool = true
		for and_part in and_parts:
			var atom_result: Dictionary = _eval_condition_atom(and_part, i_value)
			if not bool(atom_result.get("ok", false)):
				return atom_result
			if not bool(atom_result.get("value", false)):
				all_true = false
				break
		if all_true:
			has_true = true
			break
	return {"ok": true, "value": has_true}

func _split_condition(text: String, delimiter: String) -> Array[String]:
	var raw: PackedStringArray = text.split(delimiter, false)
	var result: Array[String] = []
	for part in raw:
		result.append(str(part).strip_edges())
	return result

func _eval_condition_atom(atom: String, i_value: int) -> Dictionary:
	var expr: String = atom.strip_edges()

	var mod_re := RegEx.new()
	mod_re.compile("^i\\s*%\\s*(-?\\d+)\\s*(==|!=)\\s*(-?\\d+)$")
	var mod_match: RegExMatch = mod_re.search(expr)
	if mod_match != null:
		var divisor: int = int(mod_match.get_string(1))
		if divisor == 0:
			return {"ok": false, "error": "modulo_by_zero"}
		var lhs: int = i_value % divisor
		var op: String = mod_match.get_string(2)
		var rhs: int = int(mod_match.get_string(3))
		return {"ok": true, "value": lhs == rhs if op == "==" else lhs != rhs}

	var cmp_re := RegEx.new()
	cmp_re.compile("^i\\s*(<=|>=|==|!=|<|>)\\s*(-?\\d+)$")
	var cmp_match: RegExMatch = cmp_re.search(expr)
	if cmp_match != null:
		var cmp_op: String = cmp_match.get_string(1)
		var cmp_rhs: int = int(cmp_match.get_string(2))
		var cmp_value: bool = false
		match cmp_op:
			"<":
				cmp_value = i_value < cmp_rhs
			">":
				cmp_value = i_value > cmp_rhs
			"==":
				cmp_value = i_value == cmp_rhs
			"!=":
				cmp_value = i_value != cmp_rhs
			"<=":
				cmp_value = i_value <= cmp_rhs
			">=":
				cmp_value = i_value >= cmp_rhs
			_:
				return {"ok": false, "error": "unsupported_comparator:%s" % cmp_op}
		return {"ok": true, "value": cmp_value}

	return {"ok": false, "error": "unsupported_condition_atom:%s" % expr}

func _validate_declared_trace(level: Dictionary, solved_ids: Array, previews: Dictionary) -> Dictionary:
	var raw_trace: Array = level.get("trace_correct", [])
	if raw_trace.is_empty():
		return {"ok": true, "message": ""}
	if solved_ids.size() != 1:
		return {"ok": true, "message": ""}

	var solved_id: String = str(solved_ids[0])
	var preview: Dictionary = previews.get(solved_id, {})
	var computed_trace: Array = preview.get("trace", [])
	var expected_rows: Array = _normalize_changed_trace_rows(raw_trace)
	var computed_rows: Array = _normalize_changed_trace_rows(computed_trace)

	if expected_rows.size() != computed_rows.size():
		return {"ok": false, "message": "trace length mismatch"}
	for idx in range(expected_rows.size()):
		var e: Dictionary = expected_rows[idx]
		var c: Dictionary = computed_rows[idx]
		if int(e.get("i", 0)) != int(c.get("i", 0)):
			return {"ok": false, "message": "trace i mismatch at index %d" % idx}
		if int(e.get("s_before", 0)) != int(c.get("s_before", 0)):
			return {"ok": false, "message": "trace s_before mismatch at index %d" % idx}
		if int(e.get("s_after", 0)) != int(c.get("s_after", 0)):
			return {"ok": false, "message": "trace s_after mismatch at index %d" % idx}
	return {"ok": true, "message": ""}

func _normalize_trace_rows(trace_variant: Variant) -> Array:
	var trace: Array = trace_variant if typeof(trace_variant) == TYPE_ARRAY else []
	var rows: Array = []
	for step_var in trace:
		if typeof(step_var) != TYPE_DICTIONARY:
			continue
		var step: Dictionary = step_var
		rows.append({
			"i": int(step.get("i", 0)),
			"s_before": int(step.get("s_before", 0)),
			"s_after": int(step.get("s_after", 0))
		})
	return rows

func _normalize_changed_trace_rows(trace_variant: Variant) -> Array:
	var trace: Array = trace_variant if typeof(trace_variant) == TYPE_ARRAY else []
	var rows: Array = []
	for step_var in trace:
		if typeof(step_var) != TYPE_DICTIONARY:
			continue
		var step: Dictionary = step_var
		var before_val: int = int(step.get("s_before", 0))
		var after_val: int = int(step.get("s_after", 0))
		if before_val == after_val:
			continue
		rows.append({
			"i": int(step.get("i", 0)),
			"s_before": before_val,
			"s_after": after_val
		})
	return rows

func _has_explain_debug_markers(lines_variant: Variant) -> bool:
	var lines: Array = lines_variant if typeof(lines_variant) == TYPE_ARRAY else []
	for line_var in lines:
		var line_text: String = str(line_var).to_lower()
		for marker in _EXPLAIN_DEBUG_MARKERS:
			if line_text.find(marker) >= 0:
				return true
	return false

func _choose_more_severe_status(a: String, b: String) -> String:
	if _status_rank(b) > _status_rank(a):
		return b
	return a

func _status_rank(status: String) -> int:
	match status:
		STATUS_VALID_UNIQUE:
			return 0
		STATUS_VALID_MULTIPLE:
			return 1
		STATUS_INVALID_NO_SOLUTION:
			return 2
		STATUS_INVALID_CORRECT_ID:
			return 3
		STATUS_INVALID_TRACE:
			return 4
		STATUS_INVALID_EXPLAIN:
			return 5
		_:
			return -1

func _indent_size(line: String) -> int:
	var count: int = 0
	for idx in range(line.length()):
		var ch_code: int = line.unicode_at(idx)
		if ch_code == 32:
			count += 1
		elif ch_code == 9:
			count += 4
		else:
			break
	return count


