extends Node

const SCHEMA_VERSION = "DA7.B.v1"
const LEVEL = "B"

# --- F_REASON Constants (Ladder Priority) ---
const F_REASON_FILTER = [
	"EMPTY_SELECTION",
	"PURE_OPPOSITE",
	"INCLUDED_BOUNDARY",
	"OVERSELECT_DECOY",
	"FALSE_POSITIVE",
	"OMISSION",
	"NONE"
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
		"prompt": "Терминал: выберите агентов с уровнем доступа строго больше 3.",
		"predicate": {
			"field_col_id": "c_access",
			"operator": ">",
			"value": "3",
			"value_type": "INT",
			"strict_expected": true
		},
		"table": {
			"columns": [
				{"col_id": "c_name", "title": "Имя"},
				{"col_id": "c_access", "title": "Доступ"}
			],
			"rows": [
				{"row_id": "r1", "cells": {"c_name": "Альфа", "c_access": "2"}},
				{"row_id": "r2", "cells": {"c_name": "Бета", "c_access": "5"}},
				{"row_id": "r3", "cells": {"c_name": "Гамма", "c_access": "3"}},
				{"row_id": "r4", "cells": {"c_name": "Дельта", "c_access": "4"}}
			]
		},
		"answer_row_ids": ["r2", "r4"],
		"boundary_row_ids": ["r3"],
		"opposite_row_ids": ["r1"],
		"decoy_row_ids": [],
		"unrelated_row_ids": [],
		"difficulty_tags": ["strict_inequality", "boundary_case"],
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
		"prompt": "Система: выберите инциденты с уровнем серьёзности >= 2.",
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
				{"col_id": "c_sev", "title": "Серьёзн."}
			],
			"rows": [
				{"row_id": "r1", "cells": {"c_id": "101", "c_sev": "1"}},
				{"row_id": "r2", "cells": {"c_id": "102", "c_sev": "2"}},
				{"row_id": "r3", "cells": {"c_id": "103", "c_sev": "3"}},
				{"row_id": "r4", "cells": {"c_id": "104", "c_sev": "1"}}
			]
		},
		"answer_row_ids": ["r2", "r3"],
		"boundary_row_ids": ["r2"],
		"opposite_row_ids": ["r1", "r4"],
		"decoy_row_ids": [],
		"unrelated_row_ids": [],
		"difficulty_tags": ["non_strict_inequality", "boundary_in_answer"],
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
		"prompt": "Поиск: выберите все строки со статусом ОШИБКА.",
		"predicate": {
			"field_col_id": "c_stat",
			"operator": "==",
			"value": "ОШИБКА",
			"value_type": "TEXT",
			"strict_expected": true
		},
		"table": {
			"columns": [
				{"col_id": "c_ts", "title": "Время"},
				{"col_id": "c_stat", "title": "Статус"}
			],
			"rows": [
				{"row_id": "r1", "cells": {"c_ts": "09:00", "c_stat": "НОРМА"}},
				{"row_id": "r2", "cells": {"c_ts": "09:05", "c_stat": "ОШИБКА"}},
				{"row_id": "r3", "cells": {"c_ts": "09:10", "c_stat": "ПРЕДУПРЕЖДЕНИЕ"}},
				{"row_id": "r4", "cells": {"c_ts": "09:15", "c_stat": "ОШИБКА"}}
			]
		},
		"answer_row_ids": ["r2", "r4"],
		"boundary_row_ids": [],
		"opposite_row_ids": ["r1", "r3"],
		"decoy_row_ids": [],
		"unrelated_row_ids": [],
		"difficulty_tags": ["equality_filter"],
		"anti_cheat": {"shuffle_rows": true, "shuffle_options": false},
		"timing_policy": {"mode": "LEARNING", "limit_sec": 120}
	},
	# --- 4. FILTER_ROWS (Strict <) ---
	{
		"id": "DA7-B-04",
		"schema_version": "DA7.B.v1",
		"level": "B",
		"topic": "DB_FILTERING",
		"case_kind": "FILTER_ROWS",
		"interaction_type": "MULTI_SELECT_ROWS",
		"prompt": "Фильтр: найдите транзакции с суммой < 100.",
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
				{"col_id": "c_sum", "title": "Сумма"}
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
		"decoy_row_ids": [],
		"unrelated_row_ids": [],
		"difficulty_tags": ["strict_inequality", "boundary_case"],
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
		"prompt": "Схема: определите связь между Пользователи и Посты.",
		"schema_visual": {
			"left_table": {
				"title": "Пользователи",
				"columns": [{"col_id":"u_id","title":"ID"}, {"col_id":"u_name","title":"Имя"}],
				"rows_preview": [
					{"row_id":"u1", "cells":{"u_id":"1","u_name":"Алиса"}},
					{"row_id":"u2", "cells":{"u_id":"2","u_name":"Боб"}}
				]
			},
			"right_table": {
				"title": "Посты",
				"columns": [{"col_id":"p_id","title":"ID"}, {"col_id":"p_uid","title":"ID_пользователя"}, {"col_id":"p_txt","title":"Текст"}],
				"rows_preview": [
					{"row_id":"p1", "cells":{"p_id":"10","p_uid":"1","p_txt":"Привет"}},
					{"row_id":"p2", "cells":{"p_id":"11","p_uid":"1","p_txt":"Обновление"}},
					{"row_id":"p3", "cells":{"p_id":"12","p_uid":"2","p_txt":"Здравствуй"}}
				]
			},
			"link": {
				"hint_label": "Пользователи.ID -> Посты.ID_пользователя"
			}
		},
		"expected_relation": "1:M",
		"options": [
			{"id": "opt1", "text": "1:1 (Один-к-одному)", "f_reason": "RELATION_CONFUSION_1TO1_1TOM"},
			{"id": "opt2", "text": "1:M (Один-ко-многим)", "f_reason": null},
			{"id": "opt3", "text": "M:M (Многие-ко-многим)", "f_reason": "RELATION_CONFUSION_1TOM_MTOM"}
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
		"prompt": "Схема: определите связь между Сотрудники и Паспортные_данные (уникальный паспорт).",
		"schema_visual": {
			"left_table": {
				"title": "Сотрудники",
				"columns": [{"col_id":"e_id","title":"ID"}, {"col_id":"e_name","title":"Имя"}],
				"rows_preview": [
					{"row_id":"e1", "cells":{"e_id":"101","e_name":"Иван"}},
					{"row_id":"e2", "cells":{"e_id":"102","e_name":"Жанна"}}
				]
			},
			"right_table": {
				"title": "Паспортные_данные",
				"columns": [{"col_id":"pd_id","title":"ID_паспорта"}, {"col_id":"pd_eid","title":"ID_сотрудника"}, {"col_id":"pd_num","title":"Номер"}],
				"rows_preview": [
					{"row_id":"p1", "cells":{"pd_id":"55","pd_eid":"101","pd_num":"A-001"}},
					{"row_id":"p2", "cells":{"pd_id":"56","pd_eid":"102","pd_num":"B-002"}}
				]
			},
			"link": {
				"hint_label": "Сотрудники.ID -> Паспорт.ID_сотрудника (Уникально)"
			}
		},
		"expected_relation": "1:1",
		"options": [
			{"id": "opt1", "text": "1:1 (Один-к-одному)", "f_reason": null},
			{"id": "opt2", "text": "1:M (Один-ко-многим)", "f_reason": "RELATION_CONFUSION_1TO1_1TOM"},
			{"id": "opt3", "text": "M:M (Многие-ко-многим)", "f_reason": "RELATION_CONFUSION_1TOM_MTOM"}
		],
		"answer_id": "opt1",
		"timing_policy": {"mode": "LEARNING", "limit_sec": 120},
		"anti_cheat": {"shuffle_rows": false, "shuffle_options": true}
	}
]

static func validate_case_b(c: Dictionary) -> bool:
	var case_id: String = str(c.get("id", "UNKNOWN"))
	if str(c.get("schema_version", "")) != SCHEMA_VERSION:
		push_error("Case %s bad schema" % case_id)
		return false

	if str(c.get("interaction_type", "")) == "MULTI_SELECT_ROWS":
		# Validation for disjoint sets (basic existence checks).
		if not c.has("answer_row_ids") or not c.has("boundary_row_ids") or not c.has("opposite_row_ids") or not c.has("unrelated_row_ids") or not c.has("decoy_row_ids"):
			push_error("Case %s missing sets" % case_id)
			return false
		if not c.has("predicate"):
			push_error("Case %s missing predicate" % case_id)
			return false
		if not c.has("table"):
			push_error("Case %s missing table" % case_id)
			return false
		var table: Dictionary = c.get("table", {}) as Dictionary
		var rows: Array = table.get("rows", []) as Array
		var all_row_ids: Dictionary = {}
		for row_v in rows:
			if typeof(row_v) != TYPE_DICTIONARY:
				continue
			var row_id: String = str((row_v as Dictionary).get("row_id", ""))
			if row_id == "":
				continue
			all_row_ids[row_id] = true
		var answer_ids: Array = c.get("answer_row_ids", []) as Array
		var boundary_ids: Array = c.get("boundary_row_ids", []) as Array
		var opposite_ids: Array = c.get("opposite_row_ids", []) as Array
		var unrelated_ids: Array = c.get("unrelated_row_ids", []) as Array
		var decoy_ids: Array = c.get("decoy_row_ids", []) as Array
		if not _all_exist_in(answer_ids, all_row_ids) or not _all_exist_in(boundary_ids, all_row_ids) or not _all_exist_in(opposite_ids, all_row_ids) or not _all_exist_in(unrelated_ids, all_row_ids) or not _all_exist_in(decoy_ids, all_row_ids):
			push_error("Case %s has unknown row ids in sets" % case_id)
			return false
		if not _are_disjoint([answer_ids, boundary_ids, opposite_ids, unrelated_ids, decoy_ids]):
			push_error("Case %s has intersecting sets (A/B/O/U/D)" % case_id)
			return false

	elif str(c.get("interaction_type", "")) == "RELATIONSHIP_CHOICE":
		if not c.has("schema_visual"):
			push_error("Case %s missing schema_visual" % case_id)
			return false
		if not c.has("options"):
			push_error("Case %s missing options" % case_id)
			return false

	return true

static func _all_exist_in(ids: Array, allowed: Dictionary) -> bool:
	for id_v in ids:
		var row_id: String = str(id_v)
		if not allowed.has(row_id):
			return false
	return true

static func _are_disjoint(grouped_ids: Array) -> bool:
	var seen: Dictionary = {}
	for group_v in grouped_ids:
		if typeof(group_v) != TYPE_ARRAY:
			continue
		var group: Array = group_v
		for id_v in group:
			var key: String = str(id_v)
			if seen.has(key):
				return false
			seen[key] = true
	return true
