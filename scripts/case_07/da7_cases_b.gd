extends Node

const SCHEMA_VERSION = "DA7.B.v1"
const LEVEL = "B"

# --- F_REASON Constants (Ladder Priority) ---
const F_REASON_FILTER = [
	"EMPTY_SUBMIT",        # 1. No rows selected
	"OVERSELECT_ALL",      # 2. Selected > 80% of rows (and wrong)
	"SIGN_REVERSAL",       # 3. Selected only opposite rows
	"SIGN_MIXED",          # 4. Mixed opposite + others (no correct)
	"INCLUDED_BOUNDARY",   # 5. Strict mode but boundary selected
	"EXCLUDED_BOUNDARY",   # 6. Non-strict mode but boundary missed
	"FALSE_POSITIVE",      # 7. Selected extra (unrelated) rows
	"OMISSION",            # 8. Missed some correct rows
	"CORRECT"              # 9. Perfect match
]

const F_REASON_RELATION = [
	"RELATION_CONFUSION_1TO1_1TOM",
	"RELATION_CONFUSION_1TOM_MTOM",
	"FK_DIRECTION_SWAP",
	"GUESS_FAST_CLICK",
	"CORRECT"
]

const CASES_B: Array = [
	# --- 1. FILTER_ROWS (Strict >) ---
	{
		"id": "DA7-B-01",
		"schema_version": "DA7.B.v1",
		"level": "B",
		"topic": "DB_FILTERING",
		"case_kind": "FILTER_ROWS",
		"interaction_type": "MULTI_SELECT_ROWS",
		"prompt": "Терминал: Найдите всех агентов с уровнем допуска (Access) СТРОГО выше 3.",
		"predicate": {
			"field_col_id": "c_access",
			"operator": ">",
			"value": "3",
			"value_type": "INT",
			"strict_expected": true
		},
		"table": {
			"columns": [
				{"col_id": "c_name", "title": "Name"},
				{"col_id": "c_access", "title": "Access"}
			],
			"rows": [
				{"row_id": "r1", "cells": {"c_name": "Alpha", "c_access": "2"}},
				{"row_id": "r2", "cells": {"c_name": "Beta", "c_access": "5"}},
				{"row_id": "r3", "cells": {"c_name": "Gamma", "c_access": "3"}},
				{"row_id": "r4", "cells": {"c_name": "Delta", "c_access": "4"}}
			]
		},
		"answer_row_ids": ["r2", "r4"],
		"boundary_row_ids": ["r3"],
		"opposite_row_ids": ["r1"],
		"unrelated_row_ids": [],
		"anti_cheat": {"shuffle_rows": true, "shuffle_options": false},
		"timing_policy": {"mode": "LEARNING", "limit_sec": 120}
	},
	# --- 2. FILTER_ROWS (Non-Strict >=) ---
	{
		"id": "DA7-B-02",
		"schema_version": "DA7.B.v1",
		"level": "B",
		"topic": "DB_FILTERING",
		"case_kind": "FILTER_ROWS",
		"interaction_type": "MULTI_SELECT_ROWS",
		"prompt": "Система: Выберите записи с рейтингом 'B' или выше (A, S...)",
		# Logic: 'B' or higher implies lexicographical check if chars, or explicit list.
		# Let's use numeric Rank for clarity: Rank >= 2 (where 1=C, 2=B, 3=A)
		# Or better: "Select events with Severity >= 2"
		"prompt": "Система: Отфильтруйте инциденты с уровнем угрозы (Sev) 2 и выше.",
		"predicate": {
			"field_col_id": "c_sev",
			"operator": ">=",
			"value": "2",
			"value_type": "INT",
			"strict_expected": false
		},
		"table": {
			"columns": [
				{"col_id": "c_id", "title": "ID"},
				{"col_id": "c_sev", "title": "Sev"}
			],
			"rows": [
				{"row_id": "r1", "cells": {"c_id": "101", "c_sev": "1"}},
				{"row_id": "r2", "cells": {"c_id": "102", "c_sev": "2"}},
				{"row_id": "r3", "cells": {"c_id": "103", "c_sev": "3"}},
				{"row_id": "r4", "cells": {"c_id": "104", "c_sev": "1"}}
			]
		},
		"answer_row_ids": ["r2", "r3"],
		"boundary_row_ids": ["r2"], # Wait, boundary is usually the value itself. If included in answer, it's checked via logic.
		# Logic check:
		# If operator is >=, boundary (==2) IS correct. So r2 is in answer_row_ids.
		# boundary_row_ids is just identifying WHICH rows are boundary for specific error checks (EXCLUDED_BOUNDARY).
		# In >= case: boundary rows ARE in answer.
		# In > case: boundary rows are NOT in answer.
		# So r2 is both answer and boundary.
		"boundary_row_ids": ["r2"],
		"opposite_row_ids": ["r1", "r4"],
		"unrelated_row_ids": [],
		"anti_cheat": {"shuffle_rows": true, "shuffle_options": false},
		"timing_policy": {"mode": "LEARNING", "limit_sec": 120}
	},
	# --- 3. FILTER_ROWS (String equality ==) ---
	{
		"id": "DA7-B-03",
		"schema_version": "DA7.B.v1",
		"level": "B",
		"topic": "DB_FILTERING",
		"case_kind": "FILTER_ROWS",
		"interaction_type": "MULTI_SELECT_ROWS",
		"prompt": "Поиск: Выберите все записи со статусом 'ERROR'.",
		"predicate": {
			"field_col_id": "c_stat",
			"operator": "==",
			"value": "ERROR",
			"value_type": "TEXT",
			"strict_expected": true
		},
		"table": {
			"columns": [
				{"col_id": "c_ts", "title": "Time"},
				{"col_id": "c_stat", "title": "Status"}
			],
			"rows": [
				{"row_id": "r1", "cells": {"c_ts": "09:00", "c_stat": "OK"}},
				{"row_id": "r2", "cells": {"c_ts": "09:05", "c_stat": "ERROR"}},
				{"row_id": "r3", "cells": {"c_ts": "09:10", "c_stat": "WARN"}},
				{"row_id": "r4", "cells": {"c_ts": "09:15", "c_stat": "ERROR"}}
			]
		},
		"answer_row_ids": ["r2", "r4"],
		"boundary_row_ids": [], # Equality has no boundary in >/< sense, unless fuzzy.
		"opposite_row_ids": ["r1", "r3"], # Everything else is opposite/unrelated.
		"unrelated_row_ids": [],
		"anti_cheat": {"shuffle_rows": true, "shuffle_options": false},
		"timing_policy": {"mode": "LEARNING", "limit_sec": 120}
	},
	# --- 4. FILTER_ROWS (Mixed garbage) ---
	{
		"id": "DA7-B-04",
		"schema_version": "DA7.B.v1",
		"level": "B",
		"topic": "DB_FILTERING",
		"case_kind": "FILTER_ROWS",
		"interaction_type": "MULTI_SELECT_ROWS",
		"prompt": "Фильтр: Найти транзакции суммой менее 100.",
		"predicate": {
			"field_col_id": "c_sum",
			"operator": "<",
			"value": "100",
			"value_type": "INT",
			"strict_expected": true
		},
		"table": {
			"columns": [
				{"col_id": "c_id", "title": "TX_ID"},
				{"col_id": "c_sum", "title": "Amount"}
			],
			"rows": [
				{"row_id": "r1", "cells": {"c_id": "1", "c_sum": "50"}},
				{"row_id": "r2", "cells": {"c_id": "2", "c_sum": "100"}},
				{"row_id": "r3", "cells": {"c_id": "3", "c_sum": "150"}},
				{"row_id": "r4", "cells": {"c_id": "4", "c_sum": "99"}}
			]
		},
		"answer_row_ids": ["r1", "r4"],
		"boundary_row_ids": ["r2"],
		"opposite_row_ids": ["r3"],
		"unrelated_row_ids": [],
		"anti_cheat": {"shuffle_rows": true, "shuffle_options": false},
		"timing_policy": {"mode": "LEARNING", "limit_sec": 120}
	},
	# --- 5. RELATIONSHIP (1:M) ---
	{
		"id": "DA7-B-05",
		"schema_version": "DA7.B.v1",
		"level": "B",
		"topic": "DB_RELATIONSHIPS",
		"case_kind": "RELATION_TYPE",
		"interaction_type": "RELATIONSHIP_CHOICE",
		"prompt": "Схема: Определите тип связи между таблицами 'Users' и 'Posts'.",
		"schema_visual": {
			"left_table": {
				"title": "Users",
				"columns": [{"col_id":"u_id","title":"ID"}, {"col_id":"u_name","title":"Name"}],
				"rows_preview": [
					{"row_id":"u1", "cells":{"u_id":"1","u_name":"Alice"}},
					{"row_id":"u2", "cells":{"u_id":"2","u_name":"Bob"}}
				]
			},
			"right_table": {
				"title": "Posts",
				"columns": [{"col_id":"p_id","title":"ID"}, {"col_id":"p_uid","title":"User_ID"}, {"col_id":"p_txt","title":"Text"}],
				"rows_preview": [
					{"row_id":"p1", "cells":{"p_id":"10","p_uid":"1","p_txt":"Hello"}},
					{"row_id":"p2", "cells":{"p_id":"11","p_uid":"1","p_txt":"Update"}},
					{"row_id":"p3", "cells":{"p_id":"12","p_uid":"2","p_txt":"Hi"}}
				]
			},
			"link": {
				"hint_label": "Users.ID -> Posts.User_ID"
			}
		},
		"expected_relation": "1:M",
		"options": [
			{"id": "opt1", "text": "1:1 (One-to-One)", "f_reason": "RELATION_CONFUSION_1TO1_1TOM"},
			{"id": "opt2", "text": "1:M (One-to-Many)", "f_reason": null},
			{"id": "opt3", "text": "M:M (Many-to-Many)", "f_reason": "RELATION_CONFUSION_1TOM_MTOM"}
		],
		"answer_id": "opt2",
		"timing_policy": {"mode": "LEARNING", "limit_sec": 120},
		"anti_cheat": {"shuffle_rows": false, "shuffle_options": true}
	},
	# --- 6. RELATIONSHIP (1:1) ---
	{
		"id": "DA7-B-06",
		"schema_version": "DA7.B.v1",
		"level": "B",
		"topic": "DB_RELATIONSHIPS",
		"case_kind": "RELATION_TYPE",
		"interaction_type": "RELATIONSHIP_CHOICE",
		"prompt": "Схема: Как связаны 'Employee' и 'Passport_Details' (при условии уникальности паспорта)?",
		"schema_visual": {
			"left_table": {
				"title": "Employee",
				"columns": [{"col_id":"e_id","title":"ID"}, {"col_id":"e_name","title":"Name"}],
				"rows_preview": [
					{"row_id":"e1", "cells":{"e_id":"101","e_name":"John"}},
					{"row_id":"e2", "cells":{"e_id":"102","e_name":"Jane"}}
				]
			},
			"right_table": {
				"title": "Passport_Details",
				"columns": [{"col_id":"pd_id","title":"Pass_ID"}, {"col_id":"pd_eid","title":"Emp_ID"}, {"col_id":"pd_num","title":"Number"}],
				"rows_preview": [
					{"row_id":"p1", "cells":{"pd_id":"55","pd_eid":"101","pd_num":"A-001"}},
					{"row_id":"p2", "cells":{"pd_id":"56","pd_eid":"102","pd_num":"B-002"}}
				]
			},
			"link": {
				"hint_label": "Employee.ID -> Passport.Emp_ID (Unique)"
			}
		},
		"expected_relation": "1:1",
		"options": [
			{"id": "opt1", "text": "1:1 (One-to-One)", "f_reason": null},
			{"id": "opt2", "text": "1:M (One-to-Many)", "f_reason": "RELATION_CONFUSION_1TO1_1TOM"},
			{"id": "opt3", "text": "M:M (Many-to-Many)", "f_reason": "RELATION_CONFUSION_1TOM_MTOM"}
		],
		"answer_id": "opt1",
		"timing_policy": {"mode": "LEARNING", "limit_sec": 120},
		"anti_cheat": {"shuffle_rows": false, "shuffle_options": true}
	}
]

static func validate_case_b(c: Dictionary) -> bool:
	if c.schema_version != SCHEMA_VERSION:
		push_error("Case %s bad schema" % c.id)
		return false

	if c.interaction_type == "MULTI_SELECT_ROWS":
		# Validation for disjoint sets
		# A, B, O, U must be disjoint.
		# Note: In strict >=, boundary IS in answer.
		# So disjoint check applies to: (A \ B), (B \ A), (A ∩ B), O, U?
		# Spec says: "Sets must be disjoint" but also "answer contains boundary if non-strict".
		# This implies the logical sets defined in JSON should be disjoint in ID listing if we interpret them as:
		# "Strictly Correct", "Strictly Boundary", "Strictly Opposite", "Unrelated"
		# BUT the fields are named `answer_row_ids` etc.
		# Let's check overlap carefully.

		# For strict logic, A and B should be disjoint.
		# For non-strict logic, A contains B.

		# Let's perform basic existence check first.
		if not c.has("answer_row_ids") or not c.has("boundary_row_ids"):
			push_error("Case %s missing sets" % c.id)
			return false

		# Check options/predicate existence
		if not c.has("predicate"):
			push_error("Case %s missing predicate" % c.id)
			return false

	elif c.interaction_type == "RELATIONSHIP_CHOICE":
		if not c.has("schema_visual"):
			push_error("Case %s missing schema_visual" % c.id)
			return false
		if not c.has("options"):
			push_error("Case %s missing options" % c.id)
			return false

	return true
