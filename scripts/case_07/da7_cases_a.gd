extends Node

const SCHEMA_VERSION = "DA7.A.v1"
const LEVEL = "A"

# Fixed Enum for F_REASON_A
const F_REASON_A = [
	"COUNT_HEADER_AS_RECORD",
	"MISSED_COLUMN",
	"MISSED_ROW",
	"CONFUSE_ROWS_WITH_COLUMNS",
	"OFF_BY_ONE",
	"PRIMARY_KEY_NOT_UNIQUE",
	"PRIMARY_KEY_CAN_BE_NULL",
	"CHOOSE_FIRST_COLUMN_BIAS",
	"TYPE_CONFUSION_NUMBER_TEXT",
	"TYPE_CONFUSION_DATE_TEXT"
]

const TOPICS = ["DB_TABLE_STRUCTURE", "DB_PRIMARY_KEY", "DB_DATA_TYPES"]
const KINDS = ["DIMENSIONS", "COUNT_ROWS", "COUNT_COLUMNS", "FIND_PRIMARY_KEY", "FIND_DATA_TYPE"]

static var CASES_A: Array = [
	# Case 1: Dimensions (2x3)
	{
		"id": "DA7-A-01",
		"schema_version": "DA7.A.v1",
		"level": "A",
		"topic": "DB_TABLE_STRUCTURE",
		"case_kind": "DIMENSIONS",
		"interaction_type": "SINGLE_CHOICE",
		"prompt": "Терминал: Определите размерность таблицы (строк x столбцов) архива подозреваемых (без заголовка).",
		"table": {
			"columns": [
				{"col_id": "c_id", "title": "ID"},
				{"col_id": "c_name", "title": "Name"},
				{"col_id": "c_crime", "title": "Crime"}
			],
			"rows": [
				{"row_id": "r1", "cells": {"c_id": "101", "c_name": "Black", "c_crime": "Theft"}},
				{"row_id": "r2", "cells": {"c_id": "102", "c_name": "White", "c_crime": "Fraud"}}
			]
		},
		"expected": {"n_rows": 2, "n_cols": 3},
		"options": [
			{"id": "opt1", "text": "3 x 3", "f_reason": "COUNT_HEADER_AS_RECORD"},
			{"id": "opt2", "text": "2 x 3", "f_reason": null},
			{"id": "opt3", "text": "2 x 2", "f_reason": "MISSED_COLUMN"}
		],
		"answer_id": "opt2",
		"timing_policy": {"mode": "LEARNING", "limit_sec": 120},
		"anti_cheat": {"shuffle_options": true}
	},
	# Case 2: Dimensions (4x2)
	{
		"id": "DA7-A-02",
		"schema_version": "DA7.A.v1",
		"level": "A",
		"topic": "DB_TABLE_STRUCTURE",
		"case_kind": "DIMENSIONS",
		"interaction_type": "SINGLE_CHOICE",
		"prompt": "Система: Укажите размерность таблицы логов (строк x столбцов).",
		"table": {
			"columns": [
				{"col_id": "c_time", "title": "Timestamp"},
				{"col_id": "c_event", "title": "Event"}
			],
			"rows": [
				{"row_id": "r1", "cells": {"c_time": "12:00", "c_event": "Login"}},
				{"row_id": "r2", "cells": {"c_time": "12:05", "c_event": "Access"}},
				{"row_id": "r3", "cells": {"c_time": "12:10", "c_event": "Logout"}},
				{"row_id": "r4", "cells": {"c_time": "12:15", "c_event": "Error"}}
			]
		},
		"expected": {"n_rows": 4, "n_cols": 2},
		"options": [
			{"id": "opt1", "text": "4 x 2", "f_reason": null},
			{"id": "opt2", "text": "5 x 2", "f_reason": "COUNT_HEADER_AS_RECORD"},
			{"id": "opt3", "text": "2 x 4", "f_reason": "CONFUSE_ROWS_WITH_COLUMNS"}
		],
		"answer_id": "opt1",
		"timing_policy": {"mode": "LEARNING", "limit_sec": 120},
		"anti_cheat": {"shuffle_options": true}
	},
	# Case 3: Count Rows
	{
		"id": "DA7-A-03",
		"schema_version": "DA7.A.v1",
		"level": "A",
		"topic": "DB_TABLE_STRUCTURE",
		"case_kind": "COUNT_ROWS",
		"interaction_type": "SINGLE_CHOICE",
		"prompt": "Анализ: Сколько записей (строк данных) содержит таблица доступа?",
		"table": {
			"columns": [
				{"col_id": "c_user", "title": "User"},
				{"col_id": "c_lvl", "title": "Level"}
			],
			"rows": [
				{"row_id": "r1", "cells": {"c_user": "Admin", "c_lvl": "5"}},
				{"row_id": "r2", "cells": {"c_user": "Guest", "c_lvl": "1"}},
				{"row_id": "r3", "cells": {"c_user": "Bot", "c_lvl": "0"}}
			]
		},
		"expected": {"n_rows": 3, "n_cols": 2},
		"options": [
			{"id": "opt1", "text": "4", "f_reason": "COUNT_HEADER_AS_RECORD"},
			{"id": "opt2", "text": "3", "f_reason": null},
			{"id": "opt3", "text": "2", "f_reason": "OFF_BY_ONE"}
		],
		"answer_id": "opt2",
		"timing_policy": {"mode": "LEARNING", "limit_sec": 120},
		"anti_cheat": {"shuffle_options": true}
	},
	# Case 4: Count Columns
	{
		"id": "DA7-A-04",
		"schema_version": "DA7.A.v1",
		"level": "A",
		"topic": "DB_TABLE_STRUCTURE",
		"case_kind": "COUNT_COLUMNS",
		"interaction_type": "SINGLE_CHOICE",
		"prompt": "Структура: Сколько полей (атрибутов) определено для каждого объекта?",
		"table": {
			"columns": [
				{"col_id": "c1", "title": "ID"},
				{"col_id": "c2", "title": "Type"},
				{"col_id": "c3", "title": "Status"},
				{"col_id": "c4", "title": "Date"}
			],
			"rows": [
				{"row_id": "r1", "cells": {"c1": "1", "c2": "A", "c3": "OK", "c4": "2023"}}
			]
		},
		"expected": {"n_rows": 1, "n_cols": 4},
		"options": [
			{"id": "opt1", "text": "4", "f_reason": null},
			{"id": "opt2", "text": "3", "f_reason": "MISSED_COLUMN"},
			{"id": "opt3", "text": "5", "f_reason": "OFF_BY_ONE"} # Generic off-by-one or imagining hidden ID
		],
		"answer_id": "opt1",
		"timing_policy": {"mode": "LEARNING", "limit_sec": 120},
		"anti_cheat": {"shuffle_options": true}
	},
	# Case 5: Find Primary Key (Valid)
	{
		"id": "DA7-A-05",
		"schema_version": "DA7.A.v1",
		"level": "A",
		"topic": "DB_PRIMARY_KEY",
		"case_kind": "FIND_PRIMARY_KEY",
		"interaction_type": "SINGLE_CHOICE",
		"prompt": "Идентификация: Какое поле может служить Первичным Ключом (PK) в этой выборке?",
		"table": {
			"columns": [
				{"col_id": "badge", "title": "Badge_Num"},
				{"col_id": "dept", "title": "Department"},
				{"col_id": "rank", "title": "Rank"}
			],
			"rows": [
				{"row_id": "r1", "cells": {"badge": "TX-01", "dept": "Patrol", "rank": "Sgt"}},
				{"row_id": "r2", "cells": {"badge": "TX-02", "dept": "Patrol", "rank": "Ofc"}},
				{"row_id": "r3", "cells": {"badge": "TX-05", "dept": "Cyber", "rank": "Sgt"}}
			]
		},
		"expected": {"n_rows": 3, "n_cols": 3},
		"options": [
			{"id": "opt1", "text": "Badge_Num", "f_reason": null},
			{"id": "opt2", "text": "Department", "f_reason": "PRIMARY_KEY_NOT_UNIQUE"},
			{"id": "opt3", "text": "Rank", "f_reason": "PRIMARY_KEY_NOT_UNIQUE"}
		],
		"answer_id": "opt1",
		"timing_policy": {"mode": "LEARNING", "limit_sec": 120},
		"anti_cheat": {"shuffle_options": true}
	},
	# Case 6: Find Primary Key (Trap - First col is not unique)
	{
		"id": "DA7-A-06",
		"schema_version": "DA7.A.v1",
		"level": "A",
		"topic": "DB_PRIMARY_KEY",
		"case_kind": "FIND_PRIMARY_KEY",
		"interaction_type": "SINGLE_CHOICE",
		"prompt": "Анализ ключей: Выберите единственный столбец, пригодный для PK (Primary Key).",
		"table": {
			"columns": [
				{"col_id": "loc", "title": "Location"},
				{"col_id": "uuid", "title": "Session_UUID"},
				{"col_id": "stat", "title": "Status"}
			],
			"rows": [
				{"row_id": "r1", "cells": {"loc": "Room_101", "uuid": "a1-b2", "stat": "Active"}},
				{"row_id": "r2", "cells": {"loc": "Room_101", "uuid": "c3-d4", "stat": "Idle"}},
				{"row_id": "r3", "cells": {"loc": "Room_102", "uuid": "e5-f6", "stat": "Active"}}
			]
		},
		"expected": {"n_rows": 3, "n_cols": 3},
		"options": [
			{"id": "opt1", "text": "Location", "f_reason": "CHOOSE_FIRST_COLUMN_BIAS"},
			{"id": "opt2", "text": "Session_UUID", "f_reason": null},
			{"id": "opt3", "text": "Status", "f_reason": "PRIMARY_KEY_NOT_UNIQUE"}
		],
		"answer_id": "opt2",
		"timing_policy": {"mode": "LEARNING", "limit_sec": 120},
		"anti_cheat": {"shuffle_options": true}
	},
	# Case 7: Data Type (Number vs Text)
	{
		"id": "DA7-A-07",
		"schema_version": "DA7.A.v1",
		"level": "A",
		"topic": "DB_DATA_TYPES",
		"case_kind": "FIND_DATA_TYPE",
		"interaction_type": "SINGLE_CHOICE",
		"prompt": "Типизация: Определите наиболее подходящий тип данных для столбца 'Access_Level'.",
		"table": {
			"columns": [
				{"col_id": "uid", "title": "User_ID"},
				{"col_id": "lvl", "title": "Access_Level"}
			],
			"rows": [
				{"row_id": "r1", "cells": {"uid": "u1", "lvl": "5"}},
				{"row_id": "r2", "cells": {"uid": "u2", "lvl": "3"}},
				{"row_id": "r3", "cells": {"uid": "u3", "lvl": "1"}}
			]
		},
		"expected": {"n_rows": 3, "n_cols": 2},
		"options": [
			{"id": "opt1", "text": "Integer (Число)", "f_reason": null},
			{"id": "opt2", "text": "String (Текст)", "f_reason": "TYPE_CONFUSION_NUMBER_TEXT"}, # Technically text is valid but less specific
			{"id": "opt3", "text": "Date (Дата)", "f_reason": "TYPE_CONFUSION_DATE_TEXT"}
		],
		"answer_id": "opt1",
		"timing_policy": {"mode": "LEARNING", "limit_sec": 120},
		"anti_cheat": {"shuffle_options": true}
	},
	# Case 8: Data Type (Date vs Text)
	{
		"id": "DA7-A-08",
		"schema_version": "DA7.A.v1",
		"level": "A",
		"topic": "DB_DATA_TYPES",
		"case_kind": "FIND_DATA_TYPE",
		"interaction_type": "SINGLE_CHOICE",
		"prompt": "Типизация: Какой тип данных хранит столбец 'Last_Login'?",
		"table": {
			"columns": [
				{"col_id": "u", "title": "User"},
				{"col_id": "ts", "title": "Last_Login"}
			],
			"rows": [
				{"row_id": "r1", "cells": {"u": "Neo", "ts": "2099-01-01"}},
				{"row_id": "r2", "cells": {"u": "Morpheus", "ts": "2099-01-02"}}
			]
		},
		"expected": {"n_rows": 2, "n_cols": 2},
		"options": [
			{"id": "opt1", "text": "Date/Time (Дата)", "f_reason": null},
			{"id": "opt2", "text": "Integer (Число)", "f_reason": "TYPE_CONFUSION_NUMBER_TEXT"},
			{"id": "opt3", "text": "Boolean (Логический)", "f_reason": "TYPE_CONFUSION_DATE_TEXT"}
		],
		"answer_id": "opt1",
		"timing_policy": {"mode": "LEARNING", "limit_sec": 120},
		"anti_cheat": {"shuffle_options": true}
	}
]

static func validate_case(c: Dictionary) -> bool:
	# 1. Required Fields presence
	var req_fields = ["id", "schema_version", "level", "topic", "case_kind",
		"interaction_type", "prompt", "table", "options", "answer_id"]
	for f in req_fields:
		if not c.has(f):
			push_error("Case %s missing field: %s" % [c.get("id", "??"), f])
			return false

	# 2. Schema Check
	if c.schema_version != SCHEMA_VERSION:
		push_error("Case %s bad schema: %s" % [c.id, c.schema_version])
		return false

	if c.level != LEVEL:
		push_error("Case %s bad level: %s" % [c.id, c.level])
		return false

	# 3. Table Structure
	if not c.table.has("columns") or not c.table.has("rows"):
		push_error("Case %s bad table structure" % c.id)
		return false

	if c.table.columns.size() == 0:
		push_error("Case %s no columns" % c.id)
		return false

	var col_ids = []
	for col in c.table.columns:
		if not col.has("col_id") or not col.has("title"):
			push_error("Case %s bad column def" % c.id)
			return false
		col_ids.append(col.col_id)

	for row in c.table.rows:
		if not row.has("row_id") or not row.has("cells"):
			push_error("Case %s bad row def" % c.id)
			return false
		for cid in col_ids:
			if not row.cells.has(cid):
				push_error("Case %s row %s missing cell for %s" % [c.id, row.row_id, cid])
				return false

	# 4. Options
	if c.options.size() < 2:
		push_error("Case %s too few options" % c.id)
		return false

	var has_answer = false
	for opt in c.options:
		if opt.id == c.answer_id:
			has_answer = true
			if opt.f_reason != null:
				push_error("Case %s correct answer has f_reason != null" % c.id)
				return false
		else:
			if opt.f_reason == null:
				push_error("Case %s incorrect option %s has f_reason == null" % [c.id, opt.id])
				return false
			if not (opt.f_reason in F_REASON_A):
				push_error("Case %s unknown f_reason: %s" % [c.id, opt.f_reason])
				return false

	if not has_answer:
		push_error("Case %s answer_id not found in options" % c.id)
		return false

	# 5. Expected Dimensions
	if c.expected.n_rows != c.table.rows.size():
		push_error("Case %s dimension mismatch rows: exp %d vs real %d" % [c.id, c.expected.n_rows, c.table.rows.size()])
		return false

	if c.expected.n_cols != c.table.columns.size():
		push_error("Case %s dimension mismatch cols: exp %d vs real %d" % [c.id, c.expected.n_cols, c.table.columns.size()])
		return false

	return true
