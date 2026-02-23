extends Node

const SCHEMA_VERSION := "DA7.A.v4"
const LEVEL := "A"

const CASES_A: Array = [
	{
		"id": "DA7-A4-01",
		"schema_version": SCHEMA_VERSION,
		"level": LEVEL,
		"topic": "DB_KEYS",
		"interaction_type": "SINGLE_CHOICE",
		"interaction_variant": "CLICK_TARGET",
		"case_title": "ARCHIVE_INDEX_01",
		"briefing": "Find the primary key in the table before linking records.",
		"objective": "Click the column header that is the PK.",
		"prompt": "Which column is the primary key?",
		"table": {
			"columns": [
				{"col_id": "id", "title": "ID", "type_hint": "INT", "key_hint": "PK"},
				{"col_id": "name", "title": "Name", "type_hint": "TEXT", "key_hint": ""},
				{"col_id": "dept", "title": "Dept", "type_hint": "TEXT", "key_hint": ""}
			],
			"rows": [
				{"row_id": "r1", "cells": {"id": "101", "name": "Alpha", "dept": "Ops"}},
				{"row_id": "r2", "cells": {"id": "102", "name": "Beta", "dept": "Ops"}},
				{"row_id": "r3", "cells": {"id": "103", "name": "Gamma", "dept": "Sec"}}
			]
		},
		"targets": [
			{"id": "t_id", "kind": "COLUMN_HEADER", "col_id": "id", "row_id": "header", "is_correct": true, "f_reason": null},
			{"id": "t_name", "kind": "COLUMN_HEADER", "col_id": "name", "row_id": "header", "is_correct": false, "f_reason": "CONFUSED_PK_FIELD"},
			{"id": "t_dept", "kind": "COLUMN_HEADER", "col_id": "dept", "row_id": "header", "is_correct": false, "f_reason": "CONFUSED_PK_FIELD"},
			{"id": "t_row", "kind": "ROW", "col_id": "", "row_id": "r2", "is_correct": false, "f_reason": "CONFUSED_ROW_COLUMN"}
		],
		"reveal": {
			"on_correct": "PK uniquely identifies each record. Here it is ID.",
			"on_wrong_by_reason": {
				"CONFUSED_PK_FIELD": "PK must be unique for every row.",
				"CONFUSED_ROW_COLUMN": "A key is a column, not a row."
			}
		},
		"highlight": {"mode": "COLUMNS", "target_col_ids": ["id"]},
		"timing_policy": {"mode": "LEARNING", "limit_sec": 120},
		"anti_cheat": {"shuffle_rows": true}
	},
	{
		"id": "DA7-A4-02",
		"schema_version": SCHEMA_VERSION,
		"level": LEVEL,
		"topic": "DB_NORMALIZATION",
		"interaction_type": "SINGLE_CHOICE",
		"interaction_variant": "CLICK_TARGET",
		"case_title": "PHONEBOOK_LEAK_09",
		"briefing": "One phone cell contains multiple values.",
		"objective": "Click the non-atomic cell.",
		"prompt": "Which cell breaks 1NF atomicity?",
		"table": {
			"columns": [
				{"col_id": "cid", "title": "CID", "type_hint": "TEXT", "key_hint": "PK"},
				{"col_id": "phone", "title": "Phone", "type_hint": "TEXT", "key_hint": ""}
			],
			"rows": [
				{"row_id": "r1", "cells": {"cid": "C1", "phone": "+7-700-111-22-33"}},
				{"row_id": "r2", "cells": {"cid": "C2", "phone": "+7-701-555-44-33, +7-702-999-00-11"}},
				{"row_id": "r3", "cells": {"cid": "C3", "phone": "+7-705-000-11-22"}}
			]
		},
		"targets": [
			{"id": "t_r1", "kind": "CELL", "row_id": "r1", "col_id": "phone", "is_correct": false, "f_reason": "TYPE_CONFUSION_NUMBER_TEXT"},
			{"id": "t_r2", "kind": "CELL", "row_id": "r2", "col_id": "phone", "is_correct": true, "f_reason": null},
			{"id": "t_r3", "kind": "CELL", "row_id": "r3", "col_id": "phone", "is_correct": false, "f_reason": "TYPE_CONFUSION_NUMBER_TEXT"},
			{"id": "t_hdr", "kind": "COLUMN_HEADER", "row_id": "header", "col_id": "phone", "is_correct": false, "f_reason": "COUNT_HEADER_AS_RECORD"}
		],
		"reveal": {
			"on_correct": "Two values in one cell are non-atomic. Split into separate records.",
			"on_wrong_by_reason": {
				"TYPE_CONFUSION_NUMBER_TEXT": "Single phone value is atomic. Find the comma-separated one.",
				"COUNT_HEADER_AS_RECORD": "Header is not data."
			}
		},
		"highlight": {"mode": "CELL", "target_cell": {"row_id": "r2", "col_id": "phone"}},
		"timing_policy": {"mode": "LEARNING", "limit_sec": 120},
		"anti_cheat": {"shuffle_rows": true}
	},
	{
		"id": "DA7-A4-03",
		"schema_version": SCHEMA_VERSION,
		"level": LEVEL,
		"topic": "DB_DATA_TYPES",
		"interaction_type": "SINGLE_CHOICE",
		"interaction_variant": "CLICK_TARGET",
		"case_title": "AGE_FIELD_CORRUPTION",
		"briefing": "Age should be integer, but one value is text.",
		"objective": "Click the cell with type mismatch.",
		"prompt": "Where is the type violation for Age INT?",
		"table": {
			"columns": [
				{"col_id": "id", "title": "ID", "type_hint": "INT", "key_hint": "PK"},
				{"col_id": "age", "title": "Age", "type_hint": "INT", "key_hint": ""}
			],
			"rows": [
				{"row_id": "r1", "cells": {"id": "1", "age": "16"}},
				{"row_id": "r2", "cells": {"id": "2", "age": "sixteen"}},
				{"row_id": "r3", "cells": {"id": "3", "age": "18"}}
			]
		},
		"targets": [
			{"id": "t_r1", "kind": "CELL", "row_id": "r1", "col_id": "age", "is_correct": false, "f_reason": "TYPE_CONFUSION_NUMBER_TEXT"},
			{"id": "t_r2", "kind": "CELL", "row_id": "r2", "col_id": "age", "is_correct": true, "f_reason": null},
			{"id": "t_r3", "kind": "CELL", "row_id": "r3", "col_id": "age", "is_correct": false, "f_reason": "TYPE_CONFUSION_NUMBER_TEXT"},
			{"id": "t_hdr", "kind": "COLUMN_HEADER", "row_id": "header", "col_id": "age", "is_correct": false, "f_reason": "COUNT_HEADER_AS_RECORD"}
		],
		"reveal": {
			"on_correct": "INT field cannot contain words.",
			"on_wrong_by_reason": {
				"TYPE_CONFUSION_NUMBER_TEXT": "16 and 18 are valid integers.",
				"COUNT_HEADER_AS_RECORD": "Header is not a data cell."
			}
		},
		"highlight": {"mode": "CELL", "target_cell": {"row_id": "r2", "col_id": "age"}},
		"timing_policy": {"mode": "LEARNING", "limit_sec": 120},
		"anti_cheat": {"shuffle_rows": true}
	},
	{
		"id": "DA7-A4-04",
		"schema_version": SCHEMA_VERSION,
		"level": LEVEL,
		"topic": "DB_KEYS",
		"interaction_type": "SINGLE_CHOICE",
		"interaction_variant": "CLICK_TARGET",
		"case_title": "POSTS_FK_TRACE",
		"briefing": "Find the foreign key that links posts to users.",
		"objective": "Click the FK column header.",
		"prompt": "Which column is the FK?",
		"table": {
			"columns": [
				{"col_id": "p_id", "title": "PostID", "type_hint": "INT", "key_hint": "PK"},
				{"col_id": "u_id", "title": "UserID", "type_hint": "INT", "key_hint": "FK"},
				{"col_id": "txt", "title": "Text", "type_hint": "TEXT", "key_hint": ""}
			],
			"rows": [
				{"row_id": "r1", "cells": {"p_id": "10", "u_id": "1", "txt": "Hello"}},
				{"row_id": "r2", "cells": {"p_id": "11", "u_id": "1", "txt": "Update"}},
				{"row_id": "r3", "cells": {"p_id": "12", "u_id": "2", "txt": "Hi"}}
			]
		},
		"targets": [
			{"id": "t_pk", "kind": "COLUMN_HEADER", "row_id": "header", "col_id": "p_id", "is_correct": false, "f_reason": "FK_DIRECTION_SWAP"},
			{"id": "t_fk", "kind": "COLUMN_HEADER", "row_id": "header", "col_id": "u_id", "is_correct": true, "f_reason": null},
			{"id": "t_txt", "kind": "COLUMN_HEADER", "row_id": "header", "col_id": "txt", "is_correct": false, "f_reason": "CONFUSED_PK_FIELD"},
			{"id": "t_row", "kind": "ROW", "row_id": "r2", "col_id": "", "is_correct": false, "f_reason": "CONFUSED_ROW_COLUMN"}
		],
		"reveal": {
			"on_correct": "FK stores references to another table PK. Here: UserID.",
			"on_wrong_by_reason": {
				"FK_DIRECTION_SWAP": "PostID is local PK, not FK.",
				"CONFUSED_PK_FIELD": "Text cannot be FK.",
				"CONFUSED_ROW_COLUMN": "FK is a column, not a row."
			}
		},
		"highlight": {"mode": "COLUMNS", "target_col_ids": ["u_id"]},
		"timing_policy": {"mode": "LEARNING", "limit_sec": 120},
		"anti_cheat": {"shuffle_rows": true}
	},
	{
		"id": "DA7-A4-05",
		"schema_version": SCHEMA_VERSION,
		"level": LEVEL,
		"topic": "DB_FILTERING",
		"interaction_type": "SINGLE_CHOICE",
		"interaction_variant": "CLICK_TARGET",
		"case_title": "ACCESS_ANOMALY_ROW",
		"briefing": "Policy requires Access >= 3. Find violating record.",
		"objective": "Click the row that does NOT satisfy Access >= 3.",
		"prompt": "Which row violates Access >= 3?",
		"table": {
			"columns": [
				{"col_id": "id", "title": "ID", "type_hint": "INT", "key_hint": "PK"},
				{"col_id": "acc", "title": "Access", "type_hint": "INT", "key_hint": ""}
			],
			"rows": [
				{"row_id": "r1", "cells": {"id": "101", "acc": "4"}},
				{"row_id": "r2", "cells": {"id": "102", "acc": "3"}},
				{"row_id": "r3", "cells": {"id": "103", "acc": "2"}}
			]
		},
		"targets": [
			{"id": "t_r1", "kind": "ROW", "row_id": "r1", "col_id": "", "is_correct": false, "f_reason": "MISSED_ROW"},
			{"id": "t_r2", "kind": "ROW", "row_id": "r2", "col_id": "", "is_correct": false, "f_reason": "INCLUDED_BOUNDARY"},
			{"id": "t_r3", "kind": "ROW", "row_id": "r3", "col_id": "", "is_correct": true, "f_reason": null},
			{"id": "t_hdr", "kind": "COLUMN_HEADER", "row_id": "header", "col_id": "acc", "is_correct": false, "f_reason": "COUNT_HEADER_AS_RECORD"}
		],
		"reveal": {
			"on_correct": "Access=2 is below threshold.",
			"on_wrong_by_reason": {
				"MISSED_ROW": "Pick the violating row, not a valid one.",
				"INCLUDED_BOUNDARY": "Boundary value 3 is valid for >= 3.",
				"COUNT_HEADER_AS_RECORD": "Header is not data."
			}
		},
		"highlight": {"mode": "ROWS", "target_row_ids": ["r3"]},
		"timing_policy": {"mode": "LEARNING", "limit_sec": 120},
		"anti_cheat": {"shuffle_rows": true}
	},
	{
		"id": "DA7-A4-06",
		"schema_version": SCHEMA_VERSION,
		"level": LEVEL,
		"topic": "DB_FILTERING",
		"interaction_type": "SINGLE_CHOICE",
		"interaction_variant": "CLICK_TARGET",
		"case_title": "CITY_FILTER_COLUMN",
		"briefing": "Query by city must use the correct field.",
		"objective": "Click the column used for City == Almaty filter.",
		"prompt": "Which column should be used for City == Almaty?",
		"table": {
			"columns": [
				{"col_id": "cid", "title": "CID", "type_hint": "TEXT", "key_hint": "PK"},
				{"col_id": "city", "title": "City", "type_hint": "TEXT", "key_hint": ""}
			],
			"rows": [
				{"row_id": "r1", "cells": {"cid": "C1", "city": "Almaty"}},
				{"row_id": "r2", "cells": {"cid": "C2", "city": "Astana"}},
				{"row_id": "r3", "cells": {"cid": "C3", "city": "Almaty"}}
			]
		},
		"targets": [
			{"id": "t_city", "kind": "COLUMN_HEADER", "row_id": "header", "col_id": "city", "is_correct": true, "f_reason": null},
			{"id": "t_cid", "kind": "COLUMN_HEADER", "row_id": "header", "col_id": "cid", "is_correct": false, "f_reason": "MISSED_COLUMN"},
			{"id": "t_row", "kind": "ROW", "row_id": "r1", "col_id": "", "is_correct": false, "f_reason": "CONFUSED_ROW_COLUMN"}
		],
		"reveal": {
			"on_correct": "City filter must use City column.",
			"on_wrong_by_reason": {
				"MISSED_COLUMN": "CID is identifier, not city value.",
				"CONFUSED_ROW_COLUMN": "Filter condition is set on column, not row."
			}
		},
		"highlight": {"mode": "COLUMNS", "target_col_ids": ["city"]},
		"timing_policy": {"mode": "LEARNING", "limit_sec": 120},
		"anti_cheat": {"shuffle_rows": true}
	}
]

static func validate_case_a(case_data: Dictionary) -> bool:
	if str(case_data.get("schema_version", "")) != SCHEMA_VERSION:
		return false
	if str(case_data.get("interaction_variant", "")) != "CLICK_TARGET":
		return false
	var targets: Array = case_data.get("targets", []) as Array
	if targets.is_empty():
		return false
	var correct_count := 0
	for target_v in targets:
		if typeof(target_v) != TYPE_DICTIONARY:
			return false
		var target: Dictionary = target_v as Dictionary
		if bool(target.get("is_correct", false)):
			correct_count += 1
		elif target.get("f_reason", null) == null:
			return false
	return correct_count == 1
