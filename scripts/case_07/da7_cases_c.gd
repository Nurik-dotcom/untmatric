extends Node

const SCHEMA_VERSION := "DA7.C.v1"
const LEVEL := "C"

const CASES_C: Array = [
	{
		"id": "DA7-C-01",
		"schema_version": SCHEMA_VERSION,
		"level": LEVEL,
		"topic": "DB_SQL",
		"case_kind": "SQL_SELECT",
		"interaction_type": "ASSEMBLE_BLOCKS",
		"prompt": "Build a query that selects user names where id = 5.",
		"available_blocks": [
			{"id": "b1", "text": "SELECT", "role": "KW_MAIN", "group": "KW", "is_distractor": false},
			{"id": "b2", "text": "name", "role": "FIELD", "group": "ID", "is_distractor": false},
			{"id": "b3", "text": "FROM", "role": "KW_FROM", "group": "KW", "is_distractor": false},
			{"id": "b4", "text": "Users", "role": "TABLE", "group": "ID", "is_distractor": false},
			{"id": "b5", "text": "WHERE", "role": "KW_WHERE", "group": "KW", "is_distractor": false},
			{"id": "b6", "text": "id=5", "role": "COND", "group": "COND", "is_distractor": false},
			{"id": "b7", "text": "DELETE", "role": "KW_DELETE", "group": "KW", "is_distractor": true},
			{"id": "b8", "text": "ORDER BY", "role": "KW_ORDER", "group": "KW", "is_distractor": true},
			{"id": "b9", "text": "DESC", "role": "ORDER_DIR", "group": "KW", "is_distractor": true}
		],
		"constraints": {
			"required_roles": ["KW_MAIN", "FIELD", "KW_FROM", "TABLE", "KW_WHERE", "COND"],
			"forbidden_roles": ["DDL_OBJ", "KW_DELETE"],
			"skeleton_order": ["KW_MAIN", "FIELD", "KW_FROM", "TABLE", "KW_WHERE", "COND"],
			"allow_repeat_roles": [],
			"min_tokens": 6,
			"max_tokens": 8
		},
		"correct_sequence_ids": ["b1", "b2", "b3", "b4", "b5", "b6"],
		"timing_policy": {"mode": "EXAM", "limit_sec": 120, "on_timeout": "FAIL_TASK"},
		"anti_cheat": {"shuffle_blocks": true}
	},
	{
		"id": "DA7-C-02",
		"schema_version": SCHEMA_VERSION,
		"level": LEVEL,
		"topic": "DB_SQL",
		"case_kind": "SQL_UPDATE",
		"interaction_type": "ASSEMBLE_BLOCKS",
		"prompt": "Build UPDATE query: set role='admin' for user id = 5.",
		"available_blocks": [
			{"id": "b1", "text": "UPDATE", "role": "KW_MAIN", "group": "KW", "is_distractor": false},
			{"id": "b2", "text": "Users", "role": "TABLE", "group": "ID", "is_distractor": false},
			{"id": "b3", "text": "SET", "role": "KW_SET", "group": "KW", "is_distractor": false},
			{"id": "b4", "text": "role='admin'", "role": "ASSIGN", "group": "COND", "is_distractor": false},
			{"id": "b5", "text": "WHERE", "role": "KW_WHERE", "group": "KW", "is_distractor": false},
			{"id": "b6", "text": "id=5", "role": "COND", "group": "COND", "is_distractor": false},
			{"id": "b7", "text": "FROM", "role": "KW_FROM", "group": "KW", "is_distractor": true},
			{"id": "b8", "text": "DROP", "role": "KW_DROP", "group": "KW", "is_distractor": true}
		],
		"constraints": {
			"required_roles": ["KW_MAIN", "TABLE", "KW_SET", "ASSIGN", "KW_WHERE", "COND"],
			"forbidden_roles": ["DDL_OBJ", "KW_DROP", "KW_FROM"],
			"skeleton_order": ["KW_MAIN", "TABLE", "KW_SET", "ASSIGN", "KW_WHERE", "COND"],
			"allow_repeat_roles": [],
			"min_tokens": 6,
			"max_tokens": 8
		},
		"correct_sequence_ids": ["b1", "b2", "b3", "b4", "b5", "b6"],
		"timing_policy": {"mode": "EXAM", "limit_sec": 120, "on_timeout": "FAIL_TASK"},
		"anti_cheat": {"shuffle_blocks": true}
	},
	{
		"id": "DA7-C-03",
		"schema_version": SCHEMA_VERSION,
		"level": LEVEL,
		"topic": "DB_SQL",
		"case_kind": "SQL_DELETE",
		"interaction_type": "ASSEMBLE_BLOCKS",
		"prompt": "Delete DEBUG logs from Logs table.",
		"available_blocks": [
			{"id": "b1", "text": "DELETE", "role": "KW_MAIN", "group": "KW", "is_distractor": false},
			{"id": "b2", "text": "FROM", "role": "KW_FROM", "group": "KW", "is_distractor": false},
			{"id": "b3", "text": "Logs", "role": "TABLE", "group": "ID", "is_distractor": false},
			{"id": "b4", "text": "WHERE", "role": "KW_WHERE", "group": "KW", "is_distractor": false},
			{"id": "b5", "text": "level='DEBUG'", "role": "COND", "group": "COND", "is_distractor": false},
			{"id": "b6", "text": "TABLE", "role": "DDL_OBJ", "group": "KW", "is_distractor": true},
			{"id": "b7", "text": "CREATE", "role": "KW_CREATE", "group": "KW", "is_distractor": true}
		],
		"constraints": {
			"required_roles": ["KW_MAIN", "KW_FROM", "TABLE", "KW_WHERE", "COND"],
			"forbidden_roles": ["DDL_OBJ", "KW_CREATE"],
			"skeleton_order": ["KW_MAIN", "KW_FROM", "TABLE", "KW_WHERE", "COND"],
			"allow_repeat_roles": [],
			"min_tokens": 5,
			"max_tokens": 7
		},
		"correct_sequence_ids": ["b1", "b2", "b3", "b4", "b5"],
		"timing_policy": {"mode": "EXAM", "limit_sec": 120, "on_timeout": "FAIL_TASK"},
		"anti_cheat": {"shuffle_blocks": true}
	},
	{
		"id": "DA7-C-04",
		"schema_version": SCHEMA_VERSION,
		"level": LEVEL,
		"topic": "DB_SQL",
		"case_kind": "SQL_INSERT",
		"interaction_type": "ASSEMBLE_BLOCKS",
		"prompt": "Insert user (7, 'Neo') into Users table.",
		"available_blocks": [
			{"id": "b1", "text": "INSERT", "role": "KW_MAIN", "group": "KW", "is_distractor": false},
			{"id": "b2", "text": "INTO", "role": "KW_INTO", "group": "KW", "is_distractor": false},
			{"id": "b3", "text": "Users", "role": "TABLE", "group": "ID", "is_distractor": false},
			{"id": "b4", "text": "(id,name)", "role": "FIELD_LIST", "group": "ID", "is_distractor": false},
			{"id": "b5", "text": "VALUES", "role": "KW_VALUES", "group": "KW", "is_distractor": false},
			{"id": "b6", "text": "(7,'Neo')", "role": "VALUE_LIST", "group": "COND", "is_distractor": false},
			{"id": "b7", "text": "WHERE", "role": "KW_WHERE", "group": "KW", "is_distractor": true}
		],
		"constraints": {
			"required_roles": ["KW_MAIN", "KW_INTO", "TABLE", "FIELD_LIST", "KW_VALUES", "VALUE_LIST"],
			"forbidden_roles": ["KW_WHERE", "DDL_OBJ"],
			"skeleton_order": ["KW_MAIN", "KW_INTO", "TABLE", "FIELD_LIST", "KW_VALUES", "VALUE_LIST"],
			"allow_repeat_roles": [],
			"min_tokens": 6,
			"max_tokens": 8
		},
		"correct_sequence_ids": ["b1", "b2", "b3", "b4", "b5", "b6"],
		"timing_policy": {"mode": "EXAM", "limit_sec": 120, "on_timeout": "FAIL_TASK"},
		"anti_cheat": {"shuffle_blocks": true}
	},
	{
		"id": "DA7-C-05",
		"schema_version": SCHEMA_VERSION,
		"level": LEVEL,
		"topic": "DB_SQL",
		"case_kind": "DDL_CREATE_TABLE",
		"interaction_type": "ASSEMBLE_BLOCKS",
		"prompt": "Create table Archive with a single INT id column.",
		"available_blocks": [
			{"id": "b1", "text": "CREATE", "role": "KW_MAIN", "group": "KW", "is_distractor": false},
			{"id": "b2", "text": "TABLE", "role": "DDL_OBJ", "group": "KW", "is_distractor": false},
			{"id": "b3", "text": "Archive", "role": "TABLE", "group": "ID", "is_distractor": false},
			{"id": "b4", "text": "(id INT)", "role": "DDL_DEF", "group": "COND", "is_distractor": false},
			{"id": "b5", "text": "WHERE", "role": "KW_WHERE", "group": "KW", "is_distractor": true},
			{"id": "b6", "text": "DELETE", "role": "KW_DELETE", "group": "KW", "is_distractor": true}
		],
		"constraints": {
			"required_roles": ["KW_MAIN", "DDL_OBJ", "TABLE", "DDL_DEF"],
			"forbidden_roles": ["KW_WHERE", "KW_DELETE"],
			"skeleton_order": ["KW_MAIN", "DDL_OBJ", "TABLE", "DDL_DEF"],
			"allow_repeat_roles": [],
			"min_tokens": 4,
			"max_tokens": 6
		},
		"correct_sequence_ids": ["b1", "b2", "b3", "b4"],
		"timing_policy": {"mode": "EXAM", "limit_sec": 120, "on_timeout": "FAIL_TASK"},
		"anti_cheat": {"shuffle_blocks": true}
	},
	{
		"id": "DA7-C-06",
		"schema_version": SCHEMA_VERSION,
		"level": LEVEL,
		"topic": "DB_SQL",
		"case_kind": "DDL_CREATE_DB",
		"interaction_type": "ASSEMBLE_BLOCKS",
		"prompt": "Create database ArchiveDB.",
		"available_blocks": [
			{"id": "b1", "text": "CREATE", "role": "KW_MAIN", "group": "KW", "is_distractor": false},
			{"id": "b2", "text": "DATABASE", "role": "DDL_OBJ", "group": "KW", "is_distractor": false},
			{"id": "b3", "text": "ArchiveDB", "role": "DB_NAME", "group": "ID", "is_distractor": false},
			{"id": "b4", "text": "TABLE", "role": "KW_TABLE", "group": "KW", "is_distractor": true},
			{"id": "b5", "text": "FROM", "role": "KW_FROM", "group": "KW", "is_distractor": true}
		],
		"constraints": {
			"required_roles": ["KW_MAIN", "DDL_OBJ", "DB_NAME"],
			"forbidden_roles": ["KW_TABLE", "KW_FROM"],
			"skeleton_order": ["KW_MAIN", "DDL_OBJ", "DB_NAME"],
			"allow_repeat_roles": [],
			"min_tokens": 3,
			"max_tokens": 5
		},
		"correct_sequence_ids": ["b1", "b2", "b3"],
		"timing_policy": {"mode": "EXAM", "limit_sec": 120, "on_timeout": "FAIL_TASK"},
		"anti_cheat": {"shuffle_blocks": true}
	}
]

static func validate_case_c(case_data: Dictionary) -> bool:
	var case_id: String = str(case_data.get("id", "UNKNOWN"))
	if str(case_data.get("schema_version", "")) != SCHEMA_VERSION:
		push_error("Case %s bad schema version" % case_id)
		return false
	if str(case_data.get("interaction_type", "")) != "ASSEMBLE_BLOCKS":
		push_error("Case %s bad interaction_type" % case_id)
		return false
	var blocks: Array = case_data.get("available_blocks", []) as Array
	var constraints: Dictionary = case_data.get("constraints", {}) as Dictionary
	var correct_ids: Array = case_data.get("correct_sequence_ids", []) as Array
	if blocks.is_empty() or constraints.is_empty() or correct_ids.is_empty():
		push_error("Case %s missing blocks/constraints/correct ids" % case_id)
		return false
	var block_ids: Dictionary = {}
	for block_v in blocks:
		if typeof(block_v) != TYPE_DICTIONARY:
			continue
		var block_data: Dictionary = block_v as Dictionary
		var block_id: String = str(block_data.get("id", ""))
		if block_id == "" or block_ids.has(block_id):
			push_error("Case %s has invalid block ids" % case_id)
			return false
		block_ids[block_id] = true
	for id_v in correct_ids:
		if not block_ids.has(str(id_v)):
			push_error("Case %s correct_sequence_ids contains unknown block id %s" % [case_id, str(id_v)])
			return false
	return true
