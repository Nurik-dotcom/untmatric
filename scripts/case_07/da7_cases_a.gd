extends Node

const SCHEMA_VERSION := "DA7.A.v1"
const LEVEL := "A"

const CASES_A: Array = [
	{
		"id": "DA7-A-01",
		"schema_version": SCHEMA_VERSION,
		"level": LEVEL,
		"topic": "DB_BASICS",
		"prompt": "Select IDs where Access >= 3.",
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
			{"id": "opt_1", "text": "101"},
			{"id": "opt_2", "text": "102, 103"},
			{"id": "opt_3", "text": "101, 102, 103"},
			{"id": "opt_4", "text": "103 only"}
		],
		"answer_id": "opt_2"
	},
	{
		"id": "DA7-A-02",
		"schema_version": SCHEMA_VERSION,
		"level": LEVEL,
		"topic": "DB_BASICS",
		"prompt": "Select rows where Status == ERROR.",
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
			{"id": "opt_1", "text": "09:00, 09:10"},
			{"id": "opt_2", "text": "09:05, 09:15"},
			{"id": "opt_3", "text": "09:05 only"},
			{"id": "opt_4", "text": "All rows"}
		],
		"answer_id": "opt_2"
	},
	{
		"id": "DA7-A-03",
		"schema_version": SCHEMA_VERSION,
		"level": LEVEL,
		"topic": "DB_BASICS",
		"prompt": "Which relation matches: One user can write many posts?",
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
			{"id": "opt_1", "text": "1:1"},
			{"id": "opt_2", "text": "1:M"},
			{"id": "opt_3", "text": "M:M"},
			{"id": "opt_4", "text": "No relation"}
		],
		"answer_id": "opt_2"
	},
	{
		"id": "DA7-A-04",
		"schema_version": SCHEMA_VERSION,
		"level": LEVEL,
		"topic": "DB_BASICS",
		"prompt": "Select orders where Amount < 100.",
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
			{"id": "opt_1", "text": "A-11, A-12"},
			{"id": "opt_2", "text": "A-11, A-12, A-13"},
			{"id": "opt_3", "text": "A-10 only"},
			{"id": "opt_4", "text": "A-13 only"}
		],
		"answer_id": "opt_1"
	},
	{
		"id": "DA7-A-05",
		"schema_version": SCHEMA_VERSION,
		"level": LEVEL,
		"topic": "DB_BASICS",
		"prompt": "Which operator is correct for 'not equal to CLOSED'?",
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
			{"id": "opt_1", "text": "status == CLOSED"},
			{"id": "opt_2", "text": "status != CLOSED"},
			{"id": "opt_3", "text": "status > CLOSED"},
			{"id": "opt_4", "text": "status <= CLOSED"}
		],
		"answer_id": "opt_2"
	},
	{
		"id": "DA7-A-06",
		"schema_version": SCHEMA_VERSION,
		"level": LEVEL,
		"topic": "DB_BASICS",
		"prompt": "Select customers with City == Almaty.",
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
			{"id": "opt_1", "text": "C2 only"},
			{"id": "opt_2", "text": "C1, C3"},
			{"id": "opt_3", "text": "All rows"},
			{"id": "opt_4", "text": "No rows"}
		],
		"answer_id": "opt_2"
	}
]

