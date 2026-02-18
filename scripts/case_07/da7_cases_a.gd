extends Node

const SCHEMA_VERSION := "DA7.A.v3"
const LEVEL := "A"

const CASES_A: Array = [
	{
		"id": "DA7-A-01",
		"schema_version": SCHEMA_VERSION,
		"level": LEVEL,
		"topic": "DB_BASICS",
		"interaction_type": "SINGLE_CHOICE",
		"case_title": "ACCESS_LOG_07",
		"briefing": "Archive mirror restored. Access traces were partially obfuscated. Verify only real high-access records.",
		"objective": "Identify IDs where Access >= 3.",
		"prompt": "Which records satisfy Access >= 3?",
		"table": {
			"columns": [
				{"col_id": "id", "title": "ID"},
				{"col_id": "name", "title": "Name"},
				{"col_id": "acc", "title": "Access"}
			],
			"rows": [
				{"row_id": "r1", "cells": {"id": "101", "name": "Alpha", "acc": "2"}},
				{"row_id": "r2", "cells": {"id": "102", "name": "Beta", "acc": "3"}},
				{"row_id": "r3", "cells": {"id": "103", "name": "Gamma", "acc": "4"}}
			]
		},
		"options": [
			{"id": "opt_1", "text": "File report: high-access list contains ID 101", "f_reason": "MISSED_COLUMN"},
			{"id": "opt_2", "text": "Submit evidence packet: IDs 102 and 103", "f_reason": null},
			{"id": "opt_3", "text": "Escalate all rows as high-access", "f_reason": "MISSED_ROW"},
			{"id": "opt_4", "text": "Seize only ID 103 as confirmed", "f_reason": "MISSED_ROW"}
		],
		"answer_id": "opt_2",
		"reveal": {
			"on_correct": "Rows r2 and r3 satisfy Access >= 3. Row r1 is below threshold.",
			"on_wrong_by_reason": {
				"MISSED_COLUMN": "You misread Access values. Use the Access column as the filter key.",
				"MISSED_ROW": "At least one qualifying row was dropped or over-included."
			}
		},
		"highlight": {
			"mode": "ROWS",
			"target_row_ids": ["r2", "r3"]
		},
		"timing_policy": {"mode": "LEARNING", "limit_sec": 120}
	},
	{
		"id": "DA7-A-02",
		"schema_version": SCHEMA_VERSION,
		"level": LEVEL,
		"topic": "DB_BASICS",
		"interaction_type": "SINGLE_CHOICE",
		"case_title": "SYSTEM_STATUS_12",
		"briefing": "Ops channel reports instability spikes. Extract only explicit ERROR records from incident timeline.",
		"objective": "Identify timestamps where Status == ERROR.",
		"prompt": "Which timestamps are marked ERROR?",
		"table": {
			"columns": [
				{"col_id": "time", "title": "Time"},
				{"col_id": "status", "title": "Status"}
			],
			"rows": [
				{"row_id": "r1", "cells": {"time": "09:00", "status": "OK"}},
				{"row_id": "r2", "cells": {"time": "09:05", "status": "ERROR"}},
				{"row_id": "r3", "cells": {"time": "09:10", "status": "WARN"}},
				{"row_id": "r4", "cells": {"time": "09:15", "status": "ERROR"}}
			]
		},
		"options": [
			{"id": "opt_1", "text": "Mark 09:00 and 09:10 as critical failures", "f_reason": "MISSED_COLUMN"},
			{"id": "opt_2", "text": "Open incident ticket for 09:05 and 09:15", "f_reason": null},
			{"id": "opt_3", "text": "Escalate only 09:05", "f_reason": "MISSED_ROW"},
			{"id": "opt_4", "text": "Flag every line as ERROR", "f_reason": "COUNT_HEADER_AS_RECORD"}
		],
		"answer_id": "opt_2",
		"reveal": {
			"on_correct": "Only rows with explicit ERROR status are r2 and r4.",
			"on_wrong_by_reason": {
				"MISSED_COLUMN": "Status must drive the filter; time values alone are not conditions.",
				"MISSED_ROW": "One ERROR row was skipped.",
				"COUNT_HEADER_AS_RECORD": "Do not treat labels or unrelated statuses as incident rows."
			}
		},
		"highlight": {
			"mode": "ROWS",
			"target_row_ids": ["r2", "r4"]
		},
		"timing_policy": {"mode": "LEARNING", "limit_sec": 120}
	},
	{
		"id": "DA7-A-03",
		"schema_version": SCHEMA_VERSION,
		"level": LEVEL,
		"topic": "DB_BASICS",
		"interaction_type": "SINGLE_CHOICE",
		"case_title": "RELATION_MAP_03",
		"briefing": "Entity map recovered from backup node. Confirm user-to-post dependency before linking archives.",
		"objective": "Determine relation type: one user can write many posts.",
		"prompt": "What relation fits Users.id -> Posts.user_id?",
		"table": {
			"columns": [
				{"col_id": "table", "title": "Table"},
				{"col_id": "key", "title": "Key"}
			],
			"rows": [
				{"row_id": "r1", "cells": {"table": "Users", "key": "id (PK)"}},
				{"row_id": "r2", "cells": {"table": "Posts", "key": "user_id (FK)"}}
			]
		},
		"options": [
			{"id": "opt_1", "text": "Approve relation as one-to-one", "f_reason": "CONFUSED_PK_FIELD"},
			{"id": "opt_2", "text": "Approve relation as one-to-many", "f_reason": null},
			{"id": "opt_3", "text": "Approve relation as many-to-many", "f_reason": "CONFUSED_ROW_COLUMN"},
			{"id": "opt_4", "text": "Reject relation linkage", "f_reason": "CONFUSED_PK_FIELD"}
		],
		"answer_id": "opt_2",
		"reveal": {
			"on_correct": "Users.id (PK) referenced by Posts.user_id (FK) forms a 1:M relation.",
			"on_wrong_by_reason": {
				"CONFUSED_PK_FIELD": "PK to FK here allows multiple posts per one user.",
				"CONFUSED_ROW_COLUMN": "Relation type follows key semantics, not table order in the grid."
			}
		},
		"highlight": {
			"mode": "COLUMNS",
			"target_col_ids": ["key"]
		},
		"timing_policy": {"mode": "LEARNING", "limit_sec": 120}
	},
	{
		"id": "DA7-A-04",
		"schema_version": SCHEMA_VERSION,
		"level": LEVEL,
		"topic": "DB_BASICS",
		"interaction_type": "SINGLE_CHOICE",
		"case_title": "ORDERS_AUDIT_22",
		"briefing": "Payment logs contain mixed-value orders. Isolate only low-amount transactions for manual review.",
		"objective": "Identify orders where Amount < 100.",
		"prompt": "Which orders satisfy Amount < 100?",
		"table": {
			"columns": [
				{"col_id": "ord", "title": "Order"},
				{"col_id": "sum", "title": "Amount"}
			],
			"rows": [
				{"row_id": "r1", "cells": {"ord": "A-10", "sum": "150"}},
				{"row_id": "r2", "cells": {"ord": "A-11", "sum": "80"}},
				{"row_id": "r3", "cells": {"ord": "A-12", "sum": "99"}},
				{"row_id": "r4", "cells": {"ord": "A-13", "sum": "100"}}
			]
		},
		"options": [
			{"id": "opt_1", "text": "Freeze orders A-11 and A-12 for review", "f_reason": null},
			{"id": "opt_2", "text": "Freeze A-11, A-12, and A-13", "f_reason": "MISSED_COLUMN"},
			{"id": "opt_3", "text": "Freeze only A-10", "f_reason": "MISSED_ROW"},
			{"id": "opt_4", "text": "Freeze only A-13", "f_reason": "MISSED_COLUMN"}
		],
		"answer_id": "opt_1",
		"reveal": {
			"on_correct": "A-11 (80) and A-12 (99) are strictly below 100.",
			"on_wrong_by_reason": {
				"MISSED_COLUMN": "Use strict '< 100'. Value 100 is excluded.",
				"MISSED_ROW": "You selected non-qualifying rows and missed valid low amounts."
			}
		},
		"highlight": {
			"mode": "ROWS",
			"target_row_ids": ["r2", "r3"]
		},
		"timing_policy": {"mode": "LEARNING", "limit_sec": 120}
	},
	{
		"id": "DA7-A-05",
		"schema_version": SCHEMA_VERSION,
		"level": LEVEL,
		"topic": "DB_BASICS",
		"interaction_type": "SINGLE_CHOICE",
		"case_title": "STATUS_FILTER_31",
		"briefing": "Query template is damaged. Restore the operator that excludes CLOSED states.",
		"objective": "Pick operator for condition: status not equal to CLOSED.",
		"prompt": "Which expression correctly means 'status not equal CLOSED'?",
		"table": {
			"columns": [
				{"col_id": "field", "title": "Field"},
				{"col_id": "value", "title": "Value"}
			],
			"rows": [
				{"row_id": "r1", "cells": {"field": "status", "value": "CLOSED"}},
				{"row_id": "r2", "cells": {"field": "status", "value": "OPEN"}},
				{"row_id": "r3", "cells": {"field": "status", "value": "PENDING"}}
			]
		},
		"options": [
			{"id": "opt_1", "text": "Deploy filter: status == CLOSED", "f_reason": "MISSED_COLUMN"},
			{"id": "opt_2", "text": "Deploy filter: status != CLOSED", "f_reason": null},
			{"id": "opt_3", "text": "Deploy filter: status > CLOSED", "f_reason": "CONFUSED_ROW_COLUMN"},
			{"id": "opt_4", "text": "Deploy filter: status <= CLOSED", "f_reason": "CONFUSED_ROW_COLUMN"}
		],
		"answer_id": "opt_2",
		"reveal": {
			"on_correct": "Operator '!=' excludes CLOSED and leaves OPEN/PENDING.",
			"on_wrong_by_reason": {
				"MISSED_COLUMN": "Equality checks CLOSED itself, not the exclusion set.",
				"CONFUSED_ROW_COLUMN": "String comparison operators here do not represent logical exclusion."
			}
		},
		"highlight": {
			"mode": "CELL",
			"target_cell": {"row_id": "r1", "col_id": "value"}
		},
		"timing_policy": {"mode": "LEARNING", "limit_sec": 120}
	},
	{
		"id": "DA7-A-06",
		"schema_version": SCHEMA_VERSION,
		"level": LEVEL,
		"topic": "DB_BASICS",
		"interaction_type": "SINGLE_CHOICE",
		"case_title": "CLIENT_CITY_19",
		"briefing": "Regional export list corrupted. Recover only client IDs linked to Almaty records.",
		"objective": "Select customers where City == Almaty.",
		"prompt": "Which customers are from Almaty?",
		"table": {
			"columns": [
				{"col_id": "cid", "title": "CID"},
				{"col_id": "city", "title": "City"}
			],
			"rows": [
				{"row_id": "r1", "cells": {"cid": "C1", "city": "Almaty"}},
				{"row_id": "r2", "cells": {"cid": "C2", "city": "Astana"}},
				{"row_id": "r3", "cells": {"cid": "C3", "city": "Almaty"}}
			]
		},
		"options": [
			{"id": "opt_1", "text": "Issue warrant for C2 only", "f_reason": "MISSED_COLUMN"},
			{"id": "opt_2", "text": "Issue warrant for C1 and C3", "f_reason": null},
			{"id": "opt_3", "text": "Issue warrant for all customers", "f_reason": "COUNT_HEADER_AS_RECORD"},
			{"id": "opt_4", "text": "Close case: no matching customers", "f_reason": "MISSED_ROW"}
		],
		"answer_id": "opt_2",
		"reveal": {
			"on_correct": "C1 and C3 are tagged with City = Almaty.",
			"on_wrong_by_reason": {
				"MISSED_COLUMN": "Filter must match City, not CID ordering.",
				"COUNT_HEADER_AS_RECORD": "Do not escalate non-matching rows.",
				"MISSED_ROW": "Valid Almaty rows were skipped."
			}
		},
		"highlight": {
			"mode": "ROWS",
			"target_row_ids": ["r1", "r3"]
		},
		"timing_policy": {"mode": "LEARNING", "limit_sec": 120}
	}
]
