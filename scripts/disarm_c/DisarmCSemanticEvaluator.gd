extends RefCounted
class_name DisarmCSemanticEvaluator

const STATUS_VALID_UNIQUE := "valid_unique"
const STATUS_INVALID_ACTUAL_MISMATCH := "invalid_actual_mismatch"
const STATUS_INVALID_OPTION_RESULT_MISMATCH := "invalid_option_result_mismatch"
const STATUS_INVALID_NO_SOLUTION := "invalid_no_solution"
const STATUS_INVALID_MULTIPLE_SOLUTIONS := "invalid_multiple_solutions"
const STATUS_INVALID_CORRECT_OPTION_MISMATCH := "invalid_correct_option_mismatch"
const STATUS_INVALID_REPLACE_LINE_SYNTAX := "invalid_replace_line_syntax"

const _FLOW_NORMAL := "normal"
const _FLOW_BREAK := "break"
const _FLOW_CONTINUE := "continue"

func evaluate_buggy(level: Dictionary) -> Dictionary:
	var code_lines: Array = level.get("code_lines", [])
	return _evaluate_code(code_lines)

func evaluate_patch(level: Dictionary, option_id: String) -> Dictionary:
	var bug: Dictionary = level.get("bug", {})
	var correct_line_index: int = int(bug.get("correct_line_index", -1))
	return evaluate_selected_patch(level, correct_line_index, option_id)

func evaluate_selected_patch(level: Dictionary, line_index: int, option_id: String) -> Dictionary:
	var fix: Dictionary = _get_option(level, option_id)
	if fix.is_empty():
		return {
			"ok": false,
			"error": "option_not_found",
			"option_id": option_id,
			"line_index": line_index,
			"rendered_code": level.get("code_lines", []),
			"trace": []
		}
	return evaluate_selected_line_replace(level, line_index, str(fix.get("replace_line", "")), str(fix.get("option_id", option_id)))

func evaluate_selected_line_replace(level: Dictionary, line_index: int, replace_line: String, option_id: String = "") -> Dictionary:
	var base_lines: Array = level.get("code_lines", [])
	if typeof(base_lines) != TYPE_ARRAY or base_lines.is_empty():
		return {
			"ok": false,
			"error": "code_lines_missing",
			"option_id": option_id,
			"line_index": line_index,
			"rendered_code": [],
			"trace": []
		}
	if line_index < 0 or line_index >= base_lines.size():
		return {
			"ok": false,
			"error": "line_index_out_of_range",
			"option_id": option_id,
			"line_index": line_index,
			"rendered_code": base_lines.duplicate(),
			"trace": []
		}

	var rendered_code: Array = base_lines.duplicate()
	rendered_code[line_index] = replace_line
	var result: Dictionary = _evaluate_code(rendered_code)
	result["option_id"] = option_id
	result["line_index"] = line_index
	result["replace_line"] = replace_line
	result["rendered_code"] = rendered_code
	return result

func semantic_solve(level: Dictionary) -> Dictionary:
	var bug_eval: Dictionary = evaluate_buggy(level)
	var expected_s: float = float(level.get("expected_s", 0))
	var option_results: Dictionary = {}
	var solved_option_ids: Array = []

	var fix_options: Array = level.get("bug", {}).get("fix_options", [])
	for fix_var in fix_options:
		if typeof(fix_var) != TYPE_DICTIONARY:
			continue
		var fix: Dictionary = fix_var
		var option_id: String = str(fix.get("option_id", "")).strip_edges().to_upper()
		var eval_result: Dictionary = evaluate_patch(level, option_id)
		option_results[option_id] = eval_result
		if bool(eval_result.get("ok", false)) and _num_equal(float(eval_result.get("result_s", 0.0)), expected_s):
			solved_option_ids.append(option_id)

	return {
		"expected_match_option_ids": solved_option_ids,
		"computed_actual_s": bug_eval.get("actual_s", null),
		"computed_options": option_results,
		"buggy": bug_eval
	}

func semantic_validate_level(level: Dictionary) -> Dictionary:
	var issues: Array = []
	var solve_result: Dictionary = semantic_solve(level)
	var buggy: Dictionary = solve_result.get("buggy", {})
	var computed_options: Dictionary = solve_result.get("computed_options", {})
	var solved_option_ids: Array = solve_result.get("expected_match_option_ids", [])
	var declared_actual_s: float = float(level.get("actual_s", 0))
	var declared_expected_s: float = float(level.get("expected_s", 0))
	var declared_correct_option: String = str(level.get("bug", {}).get("correct_option_id", "")).strip_edges().to_upper()

	var has_syntax_error: bool = false
	var has_option_result_mismatch: bool = false
	var has_actual_mismatch: bool = false

	if not bool(buggy.get("ok", false)):
		has_syntax_error = true
		issues.append({
			"code": STATUS_INVALID_REPLACE_LINE_SYNTAX,
			"target": "buggy",
			"error": str(buggy.get("error", "unknown_buggy_error"))
		})
	else:
		var computed_actual: float = float(buggy.get("actual_s", 0.0))
		if not _num_equal(computed_actual, declared_actual_s):
			has_actual_mismatch = true
			issues.append({
				"code": STATUS_INVALID_ACTUAL_MISMATCH,
				"declared_actual_s": declared_actual_s,
				"computed_actual_s": computed_actual
			})

	for option_id_var in computed_options.keys():
		var option_id: String = str(option_id_var)
		var eval_result: Dictionary = computed_options.get(option_id_var, {})
		var declared_result: Variant = _declared_option_result(level, option_id)

		if not bool(eval_result.get("ok", false)):
			has_syntax_error = true
			issues.append({
				"code": STATUS_INVALID_REPLACE_LINE_SYNTAX,
				"target": "option",
				"option_id": option_id,
				"error": str(eval_result.get("error", "unknown_option_error"))
			})
			continue

		if declared_result == null:
			continue
		var declared_result_f: float = float(declared_result)
		var computed_result_f: float = float(eval_result.get("result_s", 0.0))
		if not _num_equal(computed_result_f, declared_result_f):
			has_option_result_mismatch = true
			issues.append({
				"code": STATUS_INVALID_OPTION_RESULT_MISMATCH,
				"option_id": option_id,
				"declared_result_s": declared_result_f,
				"computed_result_s": computed_result_f
			})

	var status: String = STATUS_VALID_UNIQUE
	if has_syntax_error:
		status = STATUS_INVALID_REPLACE_LINE_SYNTAX
	elif has_actual_mismatch:
		status = STATUS_INVALID_ACTUAL_MISMATCH
	elif has_option_result_mismatch:
		status = STATUS_INVALID_OPTION_RESULT_MISMATCH
	else:
		if solved_option_ids.is_empty():
			status = STATUS_INVALID_NO_SOLUTION
			issues.append({
				"code": STATUS_INVALID_NO_SOLUTION,
				"expected_s": declared_expected_s
			})
		elif solved_option_ids.size() > 1:
			status = STATUS_INVALID_MULTIPLE_SOLUTIONS
			issues.append({
				"code": STATUS_INVALID_MULTIPLE_SOLUTIONS,
				"solved_option_ids": solved_option_ids.duplicate()
			})
		elif solved_option_ids[0] != declared_correct_option:
			status = STATUS_INVALID_CORRECT_OPTION_MISMATCH
			issues.append({
				"code": STATUS_INVALID_CORRECT_OPTION_MISMATCH,
				"declared_correct_option_id": declared_correct_option,
				"computed_correct_option_id": solved_option_ids[0]
			})

	return {
		"status": status,
		"semantic_valid": status == STATUS_VALID_UNIQUE,
		"issues": issues,
		"solved_option_ids": solved_option_ids.duplicate(),
		"computed": {
			"buggy": buggy.duplicate(true),
			"options": computed_options.duplicate(true)
		}
	}

func _declared_option_result(level: Dictionary, option_id: String) -> Variant:
	var fix: Dictionary = _get_option(level, option_id)
	if fix.is_empty():
		return null
	return fix.get("result_s", null)

func _get_option(level: Dictionary, option_id: String) -> Dictionary:
	var normalized: String = str(option_id).strip_edges().to_upper()
	var fix_options: Array = level.get("bug", {}).get("fix_options", [])
	for fix_var in fix_options:
		if typeof(fix_var) != TYPE_DICTIONARY:
			continue
		var fix: Dictionary = fix_var
		if str(fix.get("option_id", "")).strip_edges().to_upper() == normalized:
			return fix
	return {}

func _evaluate_code(code_lines_variant: Variant) -> Dictionary:
	var prepared: Dictionary = _prepare_lines(code_lines_variant)
	if not bool(prepared.get("ok", false)):
		return {
			"ok": false,
			"error": str(prepared.get("error", "prepare_failed")),
			"trace": []
		}
	var lines: Array = prepared.get("lines", [])

	var parse: Dictionary = _parse_block(lines, 0, 0)
	if not bool(parse.get("ok", false)):
		return {
			"ok": false,
			"error": str(parse.get("error", "parse_failed")),
			"trace": []
		}
	if int(parse.get("next", 0)) != lines.size():
		return {
			"ok": false,
			"error": "unexpected_trailing_statements",
			"trace": []
		}

	var program: Array = parse.get("statements", [])
	var ctx := {
		"s": 0.0,
		"i": 0
	}
	var trace: Array = []

	var exec_result: Dictionary = _execute_block(program, ctx, trace, false)
	if not bool(exec_result.get("ok", false)):
		return {
			"ok": false,
			"error": str(exec_result.get("error", "execution_failed")),
			"trace": trace
		}

	return {
		"ok": true,
		"actual_s": float(ctx.get("s", 0.0)),
		"result_s": float(ctx.get("s", 0.0)),
		"trace": trace
	}

func _prepare_lines(code_lines_variant: Variant) -> Dictionary:
	var raw_lines: Array = code_lines_variant if typeof(code_lines_variant) == TYPE_ARRAY else []
	if raw_lines.is_empty():
		return {"ok": false, "error": "empty_code"}

	var lines: Array = []
	for idx in range(raw_lines.size()):
		var raw_line: String = str(raw_lines[idx]).rstrip("\r\n")
		if raw_line.strip_edges().is_empty():
			continue
		lines.append({
			"line_ref": idx + 1,
			"indent": _indent_size(raw_line),
			"text": raw_line.strip_edges()
		})
	return {"ok": true, "lines": lines}

func _parse_block(lines: Array, start_index: int, indent: int) -> Dictionary:
	var statements: Array = []
	var idx: int = start_index
	while idx < lines.size():
		var line: Dictionary = lines[idx]
		var line_indent: int = int(line.get("indent", 0))
		if line_indent < indent:
			break
		if line_indent > indent:
			return {"ok": false, "error": "unexpected_indent_at_line_%d" % int(line.get("line_ref", -1))}

		var text: String = str(line.get("text", ""))
		var line_ref: int = int(line.get("line_ref", -1))

		if _is_for_stmt(text):
			var range_parse: Dictionary = _parse_for_stmt(text)
			if not bool(range_parse.get("ok", false)):
				return {"ok": false, "error": str(range_parse.get("error", "invalid_for_stmt"))}
			var body_parse: Dictionary = _parse_block(lines, idx + 1, indent + 4)
			if not bool(body_parse.get("ok", false)):
				return body_parse
			if (body_parse.get("statements", []) as Array).is_empty():
				return {"ok": false, "error": "empty_for_body_at_line_%d" % line_ref}
			statements.append({
				"type": "for",
				"line_ref": line_ref,
				"range_args": range_parse.get("range_args", []),
				"body": body_parse.get("statements", [])
			})
			idx = int(body_parse.get("next", idx + 1))
			continue

		if _is_if_stmt(text):
			var if_parse: Dictionary = _parse_if_stmt(text)
			if not bool(if_parse.get("ok", false)):
				return {"ok": false, "error": str(if_parse.get("error", "invalid_if_stmt"))}
			var if_body_parse: Dictionary = _parse_block(lines, idx + 1, indent + 4)
			if not bool(if_body_parse.get("ok", false)):
				return if_body_parse
			if (if_body_parse.get("statements", []) as Array).is_empty():
				return {"ok": false, "error": "empty_if_body_at_line_%d" % line_ref}
			statements.append({
				"type": "if",
				"line_ref": line_ref,
				"cond": if_parse.get("cond", ""),
				"body": if_body_parse.get("statements", [])
			})
			idx = int(if_body_parse.get("next", idx + 1))
			continue

		if text == "continue":
			statements.append({"type": "continue", "line_ref": line_ref})
			idx += 1
			continue
		if text == "break":
			statements.append({"type": "break", "line_ref": line_ref})
			idx += 1
			continue
		if text == "pass":
			statements.append({"type": "pass", "line_ref": line_ref})
			idx += 1
			continue

		var assign_parse: Dictionary = _parse_assign_stmt(text)
		if bool(assign_parse.get("ok", false)):
			statements.append({
				"type": "assign",
				"line_ref": line_ref,
				"op": assign_parse.get("op", "="),
				"expr": assign_parse.get("expr", "")
			})
			idx += 1
			continue

		return {"ok": false, "error": "unsupported_stmt_at_line_%d:%s" % [line_ref, text]}
	return {"ok": true, "statements": statements, "next": idx}

func _execute_block(statements: Array, ctx: Dictionary, trace: Array, in_loop: bool) -> Dictionary:
	var last_event: String = "no-op"
	var last_line_ref: int = -1
	for stmt_var in statements:
		if typeof(stmt_var) != TYPE_DICTIONARY:
			return {"ok": false, "error": "stmt_type_error"}
		var stmt: Dictionary = stmt_var
		var stmt_type: String = str(stmt.get("type", ""))
		var line_ref: int = int(stmt.get("line_ref", -1))

		match stmt_type:
			"assign":
				var eval_result: Dictionary = _eval_numeric_expr(str(stmt.get("expr", "")), ctx)
				if not bool(eval_result.get("ok", false)):
					return {"ok": false, "error": str(eval_result.get("error", "expr_eval_failed"))}
				var value: float = float(eval_result.get("value", 0.0))
				var op: String = str(stmt.get("op", "="))
				match op:
					"+=":
						ctx["s"] = float(ctx.get("s", 0.0)) + value
					"-=":
						ctx["s"] = float(ctx.get("s", 0.0)) - value
					"*=":
						ctx["s"] = float(ctx.get("s", 0.0)) * value
					"=":
						ctx["s"] = value
					_:
						return {"ok": false, "error": "unsupported_assign_op:%s" % op}
				last_event = "s %s %s" % [op, str(stmt.get("expr", ""))]
				last_line_ref = line_ref
			"pass":
				last_event = "pass"
				last_line_ref = line_ref
			"continue":
				if not in_loop:
					return {"ok": false, "error": "continue_outside_loop_at_line_%d" % line_ref}
				return {"ok": true, "flow": _FLOW_CONTINUE, "event": "continue", "line_ref": line_ref}
			"break":
				if not in_loop:
					return {"ok": false, "error": "break_outside_loop_at_line_%d" % line_ref}
				return {"ok": true, "flow": _FLOW_BREAK, "event": "break", "line_ref": line_ref}
			"if":
				var cond_result: Dictionary = _eval_bool_expr(str(stmt.get("cond", "")), ctx)
				if not bool(cond_result.get("ok", false)):
					return {"ok": false, "error": str(cond_result.get("error", "cond_eval_failed"))}
				if bool(cond_result.get("value", false)):
					var child_result: Dictionary = _execute_block(stmt.get("body", []), ctx, trace, in_loop)
					if not bool(child_result.get("ok", false)):
						return child_result
					var child_flow: String = str(child_result.get("flow", _FLOW_NORMAL))
					last_event = str(child_result.get("event", "if true"))
					last_line_ref = int(child_result.get("line_ref", line_ref))
					if child_flow == _FLOW_BREAK or child_flow == _FLOW_CONTINUE:
						return child_result
				else:
					last_event = "if skipped"
					last_line_ref = line_ref
			"for":
				var range_resolve: Dictionary = _resolve_range(stmt.get("range_args", []), ctx)
				if not bool(range_resolve.get("ok", false)):
					return {"ok": false, "error": str(range_resolve.get("error", "range_resolve_failed"))}
				var start_v: int = int(range_resolve.get("start", 0))
				var stop_v: int = int(range_resolve.get("stop", 0))
				var step_v: int = int(range_resolve.get("step", 1))
				if step_v == 0:
					return {"ok": false, "error": "range_step_zero_at_line_%d" % line_ref}
				for i_value in range(start_v, stop_v, step_v):
					var s_before: float = float(ctx.get("s", 0.0))
					ctx["i"] = i_value
					var body_result: Dictionary = _execute_block(stmt.get("body", []), ctx, trace, true)
					if not bool(body_result.get("ok", false)):
						return body_result

					var flow: String = str(body_result.get("flow", _FLOW_NORMAL))
					var event_label: String = str(body_result.get("event", "iteration"))
					var event_line_ref: int = int(body_result.get("line_ref", line_ref))
					trace.append({
						"step": trace.size() + 1,
						"i": i_value,
						"s_before": s_before,
						"s_after": float(ctx.get("s", 0.0)),
						"event": event_label,
						"line_ref": event_line_ref
					})
					if flow == _FLOW_BREAK:
						break
					if flow == _FLOW_CONTINUE:
						continue
				last_event = "for completed"
				last_line_ref = line_ref
			_:
				return {"ok": false, "error": "unsupported_stmt_type:%s" % stmt_type}
	return {
		"ok": true,
		"flow": _FLOW_NORMAL,
		"event": last_event,
		"line_ref": last_line_ref
	}

func _resolve_range(range_args_variant: Variant, ctx: Dictionary) -> Dictionary:
	var range_args: Array = range_args_variant if typeof(range_args_variant) == TYPE_ARRAY else []
	if range_args.size() < 1 or range_args.size() > 3:
		return {"ok": false, "error": "range_arity_error"}
	var values: Array = []
	for arg_var in range_args:
		var eval_result: Dictionary = _eval_numeric_expr(str(arg_var), ctx)
		if not bool(eval_result.get("ok", false)):
			return {"ok": false, "error": str(eval_result.get("error", "range_arg_eval_failed"))}
		values.append(int(eval_result.get("value", 0)))
	if values.size() == 1:
		return {"ok": true, "start": 0, "stop": values[0], "step": 1}
	if values.size() == 2:
		return {"ok": true, "start": values[0], "stop": values[1], "step": 1}
	return {"ok": true, "start": values[0], "stop": values[1], "step": values[2]}

func _eval_numeric_expr(expr: String, ctx: Dictionary) -> Dictionary:
	var expression := Expression.new()
	var parse_code: int = expression.parse(expr, PackedStringArray(["s", "i"]))
	if parse_code != OK:
		return {"ok": false, "error": "expr_parse_error:%s" % expr}
	var result: Variant = expression.execute([ctx.get("s", 0.0), ctx.get("i", 0)], self, false)
	if expression.has_execute_failed():
		return {"ok": false, "error": "expr_exec_error:%s" % expr}
	var t: int = typeof(result)
	if t == TYPE_INT or t == TYPE_FLOAT:
		return {"ok": true, "value": float(result)}
	if t == TYPE_BOOL:
		return {"ok": true, "value": 1.0 if bool(result) else 0.0}
	return {"ok": false, "error": "expr_non_numeric:%s" % expr}

func _eval_bool_expr(expr: String, ctx: Dictionary) -> Dictionary:
	var expression := Expression.new()
	var parse_code: int = expression.parse(expr, PackedStringArray(["s", "i"]))
	if parse_code != OK:
		return {"ok": false, "error": "cond_parse_error:%s" % expr}
	var result: Variant = expression.execute([ctx.get("s", 0.0), ctx.get("i", 0)], self, false)
	if expression.has_execute_failed():
		return {"ok": false, "error": "cond_exec_error:%s" % expr}
	return {"ok": true, "value": bool(result)}

func _is_for_stmt(text: String) -> bool:
	return text.begins_with("for i in range(") and text.ends_with("):")

func _is_if_stmt(text: String) -> bool:
	return text.begins_with("if ") and text.ends_with(":")

func _parse_for_stmt(text: String) -> Dictionary:
	var regex := RegEx.new()
	regex.compile("^for\\s+i\\s+in\\s+range\\((.*)\\):$")
	var match: RegExMatch = regex.search(text)
	if match == null:
		return {"ok": false, "error": "invalid_for_syntax"}
	var args_blob: String = str(match.get_string(1))
	var args: Array = []
	for raw_part in args_blob.split(","):
		var part: String = str(raw_part).strip_edges()
		if not part.is_empty():
			args.append(part)
	if args.is_empty() or args.size() > 3:
		return {"ok": false, "error": "invalid_range_args"}
	return {"ok": true, "range_args": args}

func _parse_if_stmt(text: String) -> Dictionary:
	var regex := RegEx.new()
	regex.compile("^if\\s+(.+):$")
	var match: RegExMatch = regex.search(text)
	if match == null:
		return {"ok": false, "error": "invalid_if_syntax"}
	var cond: String = str(match.get_string(1)).strip_edges()
	if cond.is_empty():
		return {"ok": false, "error": "empty_if_condition"}
	return {"ok": true, "cond": cond}

func _parse_assign_stmt(text: String) -> Dictionary:
	var regex := RegEx.new()
	regex.compile("^s\\s*(\\+=|-=|\\*=|=)\\s*(.+)$")
	var match: RegExMatch = regex.search(text)
	if match == null:
		return {"ok": false}
	var expr: String = str(match.get_string(2)).strip_edges()
	if expr.is_empty():
		return {"ok": false}
	return {
		"ok": true,
		"op": str(match.get_string(1)),
		"expr": expr
	}

func _indent_size(line: String) -> int:
	var count: int = 0
	for idx in range(line.length()):
		var code: int = line.unicode_at(idx)
		if code == 32:
			count += 1
		elif code == 9:
			count += 4
		else:
			break
	return count

func _num_equal(a: float, b: float) -> bool:
	return absf(a - b) <= 0.00001
