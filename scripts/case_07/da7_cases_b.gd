extends Node

const SCHEMA_VERSION := "DA7.B.v2"
const LEVEL := "B"

const CASES_B: Array = [
	{
		"id": "DA7-B2-01",
		"schema_version": SCHEMA_VERSION,
		"level": LEVEL,
		"topic": "DB_FILTERING",
		"case_kind": "FILTER_ROWS",
		"interaction_type": "MULTI_SELECT_ROWS",
		"interaction_variant": "REDACTION",
		"prompt": "Redact all rows that do NOT match Access > 3.",
		"predicate": {"field_col_id": "acc", "operator": ">", "value": "3", "value_type": "INT", "strict_expected": true},
		"table": {
			"columns": [
				{"col_id": "id", "title": "ID"},
				{"col_id": "name", "title": "Name"},
				{"col_id": "acc", "title": "Access"}
			],
			"rows": [
				{"row_id": "r1", "cells": {"id": "101", "name": "Alpha", "acc": "2"}},
				{"row_id": "r2", "cells": {"id": "102", "name": "Beta", "acc": "5"}},
				{"row_id": "r3", "cells": {"id": "103", "name": "Gamma", "acc": "3"}},
				{"row_id": "r4", "cells": {"id": "104", "name": "Delta", "acc": "4"}},
				{"row_id": "r5", "cells": {"id": "???", "name": "CORRUPT", "acc": "N/A"}}
			]
		},
		"answer_row_ids": ["r2", "r4"],
		"boundary_row_ids": ["r3"],
		"opposite_row_ids": ["r1"],
		"unrelated_row_ids": ["r5"],
		"decoy_row_ids": [],
		"anti_cheat": {"shuffle_rows": true},
		"timing_policy": {"mode": "LEARNING", "limit_sec": 120}
	},
	{
		"id": "DA7-B2-02",
		"schema_version": SCHEMA_VERSION,
		"level": LEVEL,
		"topic": "DB_FILTERING",
		"case_kind": "FILTER_ROWS",
		"interaction_type": "MULTI_SELECT_ROWS",
		"interaction_variant": "REDACTION",
		"prompt": "Redact incidents that do NOT satisfy Sev >= 2.",
		"predicate": {"field_col_id": "sev", "operator": ">=", "value": "2", "value_type": "INT", "strict_expected": false},
		"table": {
			"columns": [
				{"col_id": "iid", "title": "INC_ID"},
				{"col_id": "sev", "title": "Sev"}
			],
			"rows": [
				{"row_id": "r1", "cells": {"iid": "201", "sev": "1"}},
				{"row_id": "r2", "cells": {"iid": "202", "sev": "2"}},
				{"row_id": "r3", "cells": {"iid": "203", "sev": "3"}},
				{"row_id": "r4", "cells": {"iid": "204", "sev": "0"}},
				{"row_id": "r5", "cells": {"iid": "205", "sev": "?"}}
			]
		},
		"answer_row_ids": ["r2", "r3"],
		"boundary_row_ids": ["r2"],
		"opposite_row_ids": ["r1", "r4"],
		"unrelated_row_ids": ["r5"],
		"decoy_row_ids": [],
		"anti_cheat": {"shuffle_rows": true},
		"timing_policy": {"mode": "LEARNING", "limit_sec": 120}
	},
	{
		"id": "DA7-B2-03",
		"schema_version": SCHEMA_VERSION,
		"level": LEVEL,
		"topic": "DB_FILTERING",
		"case_kind": "FILTER_ROWS",
		"interaction_type": "MULTI_SELECT_ROWS",
		"interaction_variant": "REDACTION",
		"prompt": "Redact rows that are NOT status ERROR.",
		"predicate": {"field_col_id": "stat", "operator": "==", "value": "ERROR", "value_type": "TEXT", "strict_expected": true},
		"table": {
			"columns": [
				{"col_id": "ts", "title": "Time"},
				{"col_id": "stat", "title": "Status"}
			],
			"rows": [
				{"row_id": "r1", "cells": {"ts": "09:00", "stat": "OK"}},
				{"row_id": "r2", "cells": {"ts": "09:05", "stat": "ERROR"}},
				{"row_id": "r3", "cells": {"ts": "09:10", "stat": "WARN"}},
				{"row_id": "r4", "cells": {"ts": "09:15", "stat": "ERROR"}},
				{"row_id": "r5", "cells": {"ts": "??:??", "stat": "???"}}
			]
		},
		"answer_row_ids": ["r2", "r4"],
		"boundary_row_ids": [],
		"opposite_row_ids": ["r1", "r3"],
		"unrelated_row_ids": ["r5"],
		"decoy_row_ids": [],
		"anti_cheat": {"shuffle_rows": true},
		"timing_policy": {"mode": "LEARNING", "limit_sec": 120}
	},
	{
		"id": "DA7-B2-R3",
		"schema_version": SCHEMA_VERSION,
		"level": LEVEL,
		"topic": "DB_RELATIONSHIPS",
		"case_kind": "RELATIONSHIP",
		"interaction_type": "RELATIONSHIP_CHOICE",
		"interaction_variant": "PATCH_CABLE_MULTI",
		"prompt": "Patch cable: connect TWO valid PK to FK links. One port is a decoy.",
		"left_table": {
			"title": "Users",
			"columns": [
				{"col_id": "u_id", "title": "ID (PK)"},
				{"col_id": "u_name", "title": "Name"}
			],
			"rows_preview": [
				{"row_id": "u1", "cells": {"u_id": "1", "u_name": "Alice"}},
				{"row_id": "u2", "cells": {"u_id": "2", "u_name": "Bob"}}
			]
		},
		"right_table": {
			"title": "Posts",
			"columns": [
				{"col_id": "p_id", "title": "PostID"},
				{"col_id": "p_uid", "title": "UserID (FK)"},
				{"col_id": "editor_uid", "title": "EditorID (FK)"},
				{"col_id": "ghost_uid", "title": "GhostID (??)"}
			],
			"rows_preview": [
				{"row_id": "p1", "cells": {"p_id": "10", "p_uid": "1", "editor_uid": "2", "ghost_uid": "-"}},
				{"row_id": "p2", "cells": {"p_id": "11", "p_uid": "1", "editor_uid": "1", "ghost_uid": "-"}}
			]
		},
		"pk_target": {"table": "left", "col_id": "u_id"},
		"required_connections": [
			{"pk_col_id": "u_id", "fk_col_id": "p_uid"},
			{"pk_col_id": "u_id", "fk_col_id": "editor_uid"}
		],
		"decoy_fk_col_ids": ["ghost_uid"],
		"expected_relation": "1:M",
		"options": [
			{"id": "opt1", "text": "1:1", "f_reason": "RELATION_CONFUSION_1TO1_1TOM"},
			{"id": "opt2", "text": "1:M", "f_reason": null},
			{"id": "opt3", "text": "M:M", "f_reason": "RELATION_CONFUSION_1TOM_MTOM"}
		],
		"answer_id": "opt2",
		"timing_policy": {"mode": "LEARNING", "limit_sec": 120}
	},
	{
		"id": "DA7-B2-R1",
		"schema_version": SCHEMA_VERSION,
		"level": LEVEL,
		"topic": "DB_RELATIONSHIPS",
		"case_kind": "RELATIONSHIP",
		"interaction_type": "RELATIONSHIP_CHOICE",
		"interaction_variant": "PATCH_CABLE",
		"prompt": "Patch cable: connect PK in Users to FK in Posts.",
		"left_table": {
			"title": "Users",
			"columns": [
				{"col_id": "u_id", "title": "ID (PK)"},
				{"col_id": "u_name", "title": "Name"}
			],
			"rows_preview": [
				{"row_id": "u1", "cells": {"u_id": "1", "u_name": "Alice"}},
				{"row_id": "u2", "cells": {"u_id": "2", "u_name": "Bob"}}
			]
		},
		"right_table": {
			"title": "Posts",
			"columns": [
				{"col_id": "p_id", "title": "ID"},
				{"col_id": "p_uid", "title": "UserID (FK)"},
				{"col_id": "p_txt", "title": "Text"}
			],
			"rows_preview": [
				{"row_id": "p1", "cells": {"p_id": "10", "p_uid": "1", "p_txt": "Hello"}},
				{"row_id": "p2", "cells": {"p_id": "11", "p_uid": "1", "p_txt": "Update"}},
				{"row_id": "p3", "cells": {"p_id": "12", "p_uid": "2", "p_txt": "Hi"}}
			]
		},
		"pk_target": {"table": "left", "col_id": "u_id"},
		"fk_target": {"table": "right", "col_id": "p_uid"},
		"expected_relation": "1:M",
		"options": [
			{"id": "opt1", "text": "1:1", "f_reason": "RELATION_CONFUSION_1TO1_1TOM"},
			{"id": "opt2", "text": "1:M", "f_reason": null},
			{"id": "opt3", "text": "M:M", "f_reason": "RELATION_CONFUSION_1TOM_MTOM"}
		],
		"answer_id": "opt2",
		"timing_policy": {"mode": "LEARNING", "limit_sec": 120}
	},
	{
		"id": "DA7-B2-R2",
		"schema_version": SCHEMA_VERSION,
		"level": LEVEL,
		"topic": "DB_RELATIONSHIPS",
		"case_kind": "RELATIONSHIP",
		"interaction_type": "RELATIONSHIP_CHOICE",
		"interaction_variant": "PATCH_CABLE",
		"prompt": "Patch cable: connect PK in Employees to FK in PassportData.",
		"left_table": {
			"title": "Employees",
			"columns": [
				{"col_id": "e_id", "title": "ID (PK)"},
				{"col_id": "e_name", "title": "Name"}
			],
			"rows_preview": [
				{"row_id": "e1", "cells": {"e_id": "101", "e_name": "Ivan"}},
				{"row_id": "e2", "cells": {"e_id": "102", "e_name": "Zhanna"}}
			]
		},
		"right_table": {
			"title": "PassportData",
			"columns": [
				{"col_id": "pd_id", "title": "PassportID"},
				{"col_id": "pd_eid", "title": "EmployeeID (FK)"},
				{"col_id": "pd_num", "title": "Number"}
			],
			"rows_preview": [
				{"row_id": "p1", "cells": {"pd_id": "55", "pd_eid": "101", "pd_num": "A-001"}},
				{"row_id": "p2", "cells": {"pd_id": "56", "pd_eid": "102", "pd_num": "B-002"}}
			]
		},
		"pk_target": {"table": "left", "col_id": "e_id"},
		"fk_target": {"table": "right", "col_id": "pd_eid"},
		"expected_relation": "1:1",
		"options": [
			{"id": "opt1", "text": "1:1", "f_reason": null},
			{"id": "opt2", "text": "1:M", "f_reason": "RELATION_CONFUSION_1TO1_1TOM"},
			{"id": "opt3", "text": "M:M", "f_reason": "RELATION_CONFUSION_1TOM_MTOM"}
		],
		"answer_id": "opt1",
		"timing_policy": {"mode": "LEARNING", "limit_sec": 120}
	}
]

static func validate_case_b(case_data: Dictionary) -> bool:
	if str(case_data.get("schema_version", "")) != SCHEMA_VERSION:
		return false
	var interaction_type := str(case_data.get("interaction_type", ""))
	if interaction_type == "MULTI_SELECT_ROWS":
		if str(case_data.get("interaction_variant", "")) != "REDACTION":
			return false
		if not case_data.has_all(["answer_row_ids", "boundary_row_ids", "opposite_row_ids", "unrelated_row_ids", "decoy_row_ids", "predicate", "table"]):
			return false
		var table: Dictionary = case_data.get("table", {}) as Dictionary
		var rows: Array = table.get("rows", []) as Array
		var allowed: Dictionary = {}
		for row_v in rows:
			if typeof(row_v) != TYPE_DICTIONARY:
				continue
			allowed[str((row_v as Dictionary).get("row_id", ""))] = true
		var answer: Array = case_data.get("answer_row_ids", []) as Array
		var boundary: Array = case_data.get("boundary_row_ids", []) as Array
		var opposite: Array = case_data.get("opposite_row_ids", []) as Array
		var unrelated: Array = case_data.get("unrelated_row_ids", []) as Array
		var decoy: Array = case_data.get("decoy_row_ids", []) as Array
		if not _all_exist_in(answer, allowed):
			return false
		if not _all_exist_in(boundary, allowed):
			return false
		if not _all_exist_in(opposite, allowed):
			return false
		if not _all_exist_in(unrelated, allowed):
			return false
		if not _all_exist_in(decoy, allowed):
			return false
		if not _are_disjoint([answer, opposite, unrelated, decoy]):
			return false
		if _has_intersection(boundary, opposite) or _has_intersection(boundary, unrelated) or _has_intersection(boundary, decoy):
			return false
		var predicate: Dictionary = case_data.get("predicate", {}) as Dictionary
		if bool(predicate.get("strict_expected", false)) and _has_intersection(boundary, answer):
			return false
		return true
	if interaction_type == "RELATIONSHIP_CHOICE":
		var interaction_variant := str(case_data.get("interaction_variant", ""))
		if interaction_variant != "PATCH_CABLE" and interaction_variant != "PATCH_CABLE_MULTI":
			return false
		if not case_data.has_all(["left_table", "right_table", "pk_target"]):
			return false
		if case_data.has("options") and not case_data.has("answer_id"):
			return false
		var left_cols := _collect_column_ids(case_data.get("left_table", {}) as Dictionary)
		var right_cols := _collect_column_ids(case_data.get("right_table", {}) as Dictionary)
		if left_cols.is_empty() or right_cols.is_empty():
			return false
		var pk_target: Dictionary = case_data.get("pk_target", {}) as Dictionary
		var pk_target_id := str(pk_target.get("col_id", ""))
		if pk_target_id.is_empty() or not left_cols.has(pk_target_id):
			return false
		var required_connections: Array = case_data.get("required_connections", []) as Array
		var has_required := false
		var required_fk_ids: Array = []
		var seen_pairs: Dictionary = {}
		for pair_v in required_connections:
			if typeof(pair_v) != TYPE_DICTIONARY:
				return false
			var pair: Dictionary = pair_v as Dictionary
			var pk_col_id := str(pair.get("pk_col_id", ""))
			var fk_col_id := str(pair.get("fk_col_id", ""))
			if pk_col_id.is_empty() or fk_col_id.is_empty():
				return false
			if not left_cols.has(pk_col_id) or not right_cols.has(fk_col_id):
				return false
			var pair_key := _pair_key(pk_col_id, fk_col_id)
			if seen_pairs.has(pair_key):
				return false
			seen_pairs[pair_key] = true
			required_fk_ids.append(fk_col_id)
			has_required = true
		if not has_required:
			var fk_target: Dictionary = case_data.get("fk_target", {}) as Dictionary
			var fk_target_id := str(fk_target.get("col_id", ""))
			if fk_target_id.is_empty() or not right_cols.has(fk_target_id):
				return false
		var decoy_fk_col_ids: Array = case_data.get("decoy_fk_col_ids", []) as Array
		for decoy_v in decoy_fk_col_ids:
			var decoy_id := str(decoy_v)
			if decoy_id.is_empty() or not right_cols.has(decoy_id):
				return false
			if required_fk_ids.has(decoy_id):
				return false
		return true
	return false

static func _collect_column_ids(table_data: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	var columns: Array = table_data.get("columns", []) as Array
	for column_v in columns:
		if typeof(column_v) != TYPE_DICTIONARY:
			continue
		var column: Dictionary = column_v as Dictionary
		var col_id := str(column.get("col_id", ""))
		if not col_id.is_empty():
			out[col_id] = true
	return out

static func _pair_key(pk_col_id: String, fk_col_id: String) -> String:
	return "%s::%s" % [pk_col_id, fk_col_id]

static func _all_exist_in(ids: Array, allowed: Dictionary) -> bool:
	for id_v in ids:
		if not allowed.has(str(id_v)):
			return false
	return true

static func _are_disjoint(grouped_ids: Array) -> bool:
	var seen: Dictionary = {}
	for group_v in grouped_ids:
		if typeof(group_v) != TYPE_ARRAY:
			continue
		for id_v in group_v:
			var key := str(id_v)
			if seen.has(key):
				return false
			seen[key] = true
	return true

static func _has_intersection(a1: Array, a2: Array) -> bool:
	var lookup: Dictionary = {}
	for v in a2:
		lookup[str(v)] = true
	for v in a1:
		if lookup.has(str(v)):
			return true
	return false
