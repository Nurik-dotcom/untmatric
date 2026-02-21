extends Node

const SCHEMA_VERSION := "DA7.C.v2"
const LEVEL := "C"

const CASES_C: Array = [
	{
		"id": "DA7-C-01",
		"schema_version": SCHEMA_VERSION,
		"level": LEVEL,
		"topic": "DB_SQL",
		"case_kind": "SQL_SELECT",
		"interaction_type": "ASSEMBLE_BLOCKS",
		"prompt": "Соберите запрос, который выбирает имена пользователей, где id = 5.",
		"available_blocks": [
			{"id": "b1", "text": "SELECT", "role": "KW_MAIN"},
			{"id": "b2", "text": "name", "role": "IDENT_FIELD"},
			{"id": "b3", "text": "FROM", "role": "KW_FROM"},
			{"id": "b4", "text": "Users", "role": "IDENT_TABLE"},
			{"id": "b5", "text": "WHERE", "role": "KW_WHERE"},
			{"id": "b6", "text": "id=5", "role": "COND_WHERE"},
			{"id": "b7", "text": "DELETE", "role": "KW_DISTRACTOR"},
			{"id": "b8", "text": "TABLE", "role": "KW_DISTRACTOR"}
		],
		"correct_sequence_ids": ["b1", "b2", "b3", "b4", "b5", "b6"],
		"rules": {
			"required_roles": ["KW_MAIN", "KW_FROM", "IDENT_TABLE"],
			"min_tokens": 6,
			"allow_repeat_roles": [],
			"forbidden_block_ids": ["b7", "b8"],
			"forbidden_roles": ["KW_DISTRACTOR"],
			"skeleton_roles": ["KW_MAIN", "KW_FROM", "IDENT_TABLE"],
			"order_rules": [
				{"before": "KW_FROM", "after": "KW_MAIN"},
				{"before": "IDENT_TABLE", "after": "KW_FROM"},
				{"before": "KW_WHERE", "after": "IDENT_TABLE"},
				{"before": "COND_WHERE", "after": "KW_WHERE"}
			]
		},
		"timing_policy": {"mode": "EXAM", "limit_sec": 120, "on_timeout": "TIMEOUT"},
		"anti_cheat": {"shuffle_blocks": true}
	},
	{
		"id": "DA7-C-02",
		"schema_version": SCHEMA_VERSION,
		"level": LEVEL,
		"topic": "DB_SQL",
		"case_kind": "SQL_UPDATE",
		"interaction_type": "ASSEMBLE_BLOCKS",
		"prompt": "Соберите UPDATE-запрос: установите role='admin' для пользователя с id = 5.",
		"available_blocks": [
			{"id": "b1", "text": "UPDATE", "role": "KW_MAIN"},
			{"id": "b2", "text": "Users", "role": "IDENT_TABLE"},
			{"id": "b3", "text": "SET", "role": "KW_SET"},
			{"id": "b4", "text": "role='admin'", "role": "ASSIGN"},
			{"id": "b5", "text": "WHERE", "role": "KW_WHERE"},
			{"id": "b6", "text": "id=5", "role": "COND_WHERE"},
			{"id": "b7", "text": "FROM", "role": "KW_DISTRACTOR"},
			{"id": "b8", "text": "DROP", "role": "KW_DISTRACTOR"}
		],
		"correct_sequence_ids": ["b1", "b2", "b3", "b4", "b5", "b6"],
		"rules": {
			"required_roles": ["KW_MAIN", "IDENT_TABLE", "KW_SET", "ASSIGN"],
			"min_tokens": 6,
			"allow_repeat_roles": [],
			"forbidden_block_ids": ["b7", "b8"],
			"forbidden_roles": ["KW_DISTRACTOR"],
			"skeleton_roles": ["KW_MAIN", "IDENT_TABLE", "KW_SET"],
			"order_rules": [
				{"before": "IDENT_TABLE", "after": "KW_MAIN"},
				{"before": "KW_SET", "after": "IDENT_TABLE"},
				{"before": "ASSIGN", "after": "KW_SET"},
				{"before": "KW_WHERE", "after": "ASSIGN"},
				{"before": "COND_WHERE", "after": "KW_WHERE"}
			]
		},
		"timing_policy": {"mode": "EXAM", "limit_sec": 120, "on_timeout": "TIMEOUT"},
		"anti_cheat": {"shuffle_blocks": true}
	},
	{
		"id": "DA7-C-03",
		"schema_version": SCHEMA_VERSION,
		"level": LEVEL,
		"topic": "DB_SQL",
		"case_kind": "SQL_DELETE",
		"interaction_type": "ASSEMBLE_BLOCKS",
		"prompt": "Удалите DEBUG-логи из таблицы Logs.",
		"available_blocks": [
			{"id": "b1", "text": "DELETE", "role": "KW_MAIN"},
			{"id": "b2", "text": "FROM", "role": "KW_FROM"},
			{"id": "b3", "text": "Logs", "role": "IDENT_TABLE"},
			{"id": "b4", "text": "WHERE", "role": "KW_WHERE"},
			{"id": "b5", "text": "level='DEBUG'", "role": "COND_WHERE"},
			{"id": "b6", "text": "TABLE", "role": "DDL_TARGET"},
			{"id": "b7", "text": "CREATE", "role": "KW_DISTRACTOR"}
		],
		"correct_sequence_ids": ["b1", "b2", "b3", "b4", "b5"],
		"rules": {
			"required_roles": ["KW_MAIN", "KW_FROM", "IDENT_TABLE"],
			"min_tokens": 5,
			"allow_repeat_roles": [],
			"forbidden_block_ids": ["b6", "b7"],
			"forbidden_roles": ["DDL_TARGET", "KW_DISTRACTOR"],
			"skeleton_roles": ["KW_MAIN", "KW_FROM", "IDENT_TABLE"],
			"order_rules": [
				{"before": "KW_FROM", "after": "KW_MAIN"},
				{"before": "IDENT_TABLE", "after": "KW_FROM"},
				{"before": "KW_WHERE", "after": "IDENT_TABLE"},
				{"before": "COND_WHERE", "after": "KW_WHERE"}
			]
		},
		"timing_policy": {"mode": "EXAM", "limit_sec": 120, "on_timeout": "TIMEOUT"},
		"anti_cheat": {"shuffle_blocks": true}
	},
	{
		"id": "DA7-C-04",
		"schema_version": SCHEMA_VERSION,
		"level": LEVEL,
		"topic": "DB_SQL",
		"case_kind": "SQL_INSERT",
		"interaction_type": "ASSEMBLE_BLOCKS",
		"prompt": "Добавьте пользователя (7, 'Neo') в таблицу Users.",
		"available_blocks": [
			{"id": "b1", "text": "INSERT", "role": "KW_MAIN"},
			{"id": "b2", "text": "INTO", "role": "KW_INTO"},
			{"id": "b3", "text": "Users", "role": "IDENT_TABLE"},
			{"id": "b4", "text": "(id,name)", "role": "FIELD_LIST"},
			{"id": "b5", "text": "VALUES", "role": "KW_VALUES"},
			{"id": "b6", "text": "(7,'Neo')", "role": "VALUE_LIST"},
			{"id": "b7", "text": "WHERE", "role": "KW_DISTRACTOR"}
		],
		"correct_sequence_ids": ["b1", "b2", "b3", "b4", "b5", "b6"],
		"rules": {
			"required_roles": ["KW_MAIN", "KW_INTO", "IDENT_TABLE", "KW_VALUES"],
			"min_tokens": 6,
			"allow_repeat_roles": [],
			"forbidden_block_ids": ["b7"],
			"forbidden_roles": ["KW_DISTRACTOR"],
			"skeleton_roles": ["KW_MAIN", "KW_INTO", "IDENT_TABLE"],
			"order_rules": [
				{"before": "KW_INTO", "after": "KW_MAIN"},
				{"before": "IDENT_TABLE", "after": "KW_INTO"},
				{"before": "FIELD_LIST", "after": "IDENT_TABLE"},
				{"before": "KW_VALUES", "after": "FIELD_LIST"},
				{"before": "VALUE_LIST", "after": "KW_VALUES"}
			]
		},
		"timing_policy": {"mode": "EXAM", "limit_sec": 120, "on_timeout": "TIMEOUT"},
		"anti_cheat": {"shuffle_blocks": true}
	},
	{
		"id": "DA7-C-05",
		"schema_version": SCHEMA_VERSION,
		"level": LEVEL,
		"topic": "DB_SQL",
		"case_kind": "DDL_CREATE_TABLE",
		"interaction_type": "ASSEMBLE_BLOCKS",
		"prompt": "Создайте таблицу Archive с одним столбцом id типа INT.",
		"available_blocks": [
			{"id": "b1", "text": "CREATE", "role": "KW_MAIN"},
			{"id": "b2", "text": "TABLE", "role": "DDL_TARGET"},
			{"id": "b3", "text": "Archive", "role": "IDENT_TABLE"},
			{"id": "b4", "text": "(id INT)", "role": "DDL_DEF"},
			{"id": "b5", "text": "WHERE", "role": "KW_DISTRACTOR"},
			{"id": "b6", "text": "DELETE", "role": "KW_DISTRACTOR"}
		],
		"correct_sequence_ids": ["b1", "b2", "b3", "b4"],
		"rules": {
			"required_roles": ["KW_MAIN", "DDL_TARGET", "IDENT_TABLE", "DDL_DEF"],
			"min_tokens": 4,
			"allow_repeat_roles": [],
			"forbidden_block_ids": ["b5", "b6"],
			"forbidden_roles": ["KW_DISTRACTOR"],
			"skeleton_roles": ["KW_MAIN", "DDL_TARGET", "IDENT_TABLE"],
			"order_rules": [
				{"before": "DDL_TARGET", "after": "KW_MAIN"},
				{"before": "IDENT_TABLE", "after": "DDL_TARGET"},
				{"before": "DDL_DEF", "after": "IDENT_TABLE"}
			]
		},
		"timing_policy": {"mode": "EXAM", "limit_sec": 120, "on_timeout": "TIMEOUT"},
		"anti_cheat": {"shuffle_blocks": true}
	},
	{
		"id": "DA7-C-06",
		"schema_version": SCHEMA_VERSION,
		"level": LEVEL,
		"topic": "DB_SQL",
		"case_kind": "DDL_CREATE_DB",
		"interaction_type": "ASSEMBLE_BLOCKS",
		"prompt": "Создайте базу данных ArchiveDB.",
		"available_blocks": [
			{"id": "b1", "text": "CREATE", "role": "KW_MAIN"},
			{"id": "b2", "text": "DATABASE", "role": "DDL_TARGET"},
			{"id": "b3", "text": "ArchiveDB", "role": "IDENT_DB"},
			{"id": "b4", "text": "TABLE", "role": "KW_DISTRACTOR"},
			{"id": "b5", "text": "FROM", "role": "KW_DISTRACTOR"}
		],
		"correct_sequence_ids": ["b1", "b2", "b3"],
		"rules": {
			"required_roles": ["KW_MAIN", "DDL_TARGET", "IDENT_DB"],
			"min_tokens": 3,
			"allow_repeat_roles": [],
			"forbidden_block_ids": ["b4", "b5"],
			"forbidden_roles": ["KW_DISTRACTOR"],
			"skeleton_roles": ["KW_MAIN", "DDL_TARGET", "IDENT_DB"],
			"order_rules": [
				{"before": "DDL_TARGET", "after": "KW_MAIN"},
				{"before": "IDENT_DB", "after": "DDL_TARGET"}
			]
		},
		"timing_policy": {"mode": "EXAM", "limit_sec": 120, "on_timeout": "TIMEOUT"},
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
	var rules: Dictionary = case_data.get("rules", {}) as Dictionary
	var correct_ids: Array = case_data.get("correct_sequence_ids", []) as Array
	if blocks.is_empty() or rules.is_empty() or correct_ids.is_empty():
		push_error("Case %s missing blocks/rules/correct ids" % case_id)
		return false

	var block_by_id: Dictionary = {}
	for block_v in blocks:
		if typeof(block_v) != TYPE_DICTIONARY:
			push_error("Case %s has non-dictionary block" % case_id)
			return false
		var block_data: Dictionary = block_v as Dictionary
		var block_id: String = str(block_data.get("id", ""))
		var block_text: String = str(block_data.get("text", ""))
		var block_role: String = str(block_data.get("role", ""))
		if block_id == "" or block_text == "" or block_role == "" or block_by_id.has(block_id):
			push_error("Case %s has invalid block contract" % case_id)
			return false
		block_by_id[block_id] = block_data

	var required_roles: Array = rules.get("required_roles", []) as Array
	var allow_repeat_roles: Array = rules.get("allow_repeat_roles", []) as Array
	var forbidden_block_ids: Array = rules.get("forbidden_block_ids", []) as Array
	var forbidden_roles: Array = rules.get("forbidden_roles", []) as Array
	var skeleton_roles: Array = rules.get("skeleton_roles", []) as Array
	var order_rules: Array = rules.get("order_rules", []) as Array
	var min_tokens: int = int(rules.get("min_tokens", 0))
	if min_tokens <= 0:
		push_error("Case %s has invalid min_tokens" % case_id)
		return false
	if required_roles.is_empty() or skeleton_roles.is_empty():
		push_error("Case %s rules missing required/skeleton roles" % case_id)
		return false
	if typeof(allow_repeat_roles) != TYPE_ARRAY or typeof(forbidden_block_ids) != TYPE_ARRAY or typeof(forbidden_roles) != TYPE_ARRAY:
		push_error("Case %s rules arrays are malformed" % case_id)
		return false
	for block_id_v in forbidden_block_ids:
		if not block_by_id.has(str(block_id_v)):
			push_error("Case %s forbidden block id %s is unknown" % [case_id, str(block_id_v)])
			return false
	for order_rule_v in order_rules:
		if typeof(order_rule_v) != TYPE_DICTIONARY:
			push_error("Case %s has malformed order rule" % case_id)
			return false
		var order_rule: Dictionary = order_rule_v as Dictionary
		if str(order_rule.get("before", "")) == "" or str(order_rule.get("after", "")) == "":
			push_error("Case %s has incomplete order rule" % case_id)
			return false

	for id_v in correct_ids:
		if not block_by_id.has(str(id_v)):
			push_error("Case %s correct_sequence_ids contains unknown block id %s" % [case_id, str(id_v)])
			return false
	if correct_ids.size() < min_tokens:
		push_error("Case %s correct sequence shorter than min_tokens" % case_id)
		return false

	return true
