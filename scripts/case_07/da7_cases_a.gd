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
		"briefing": "Зеркало архива восстановлено. Следы доступа частично обфусцированы. Проверьте только реальные записи с высоким уровнем доступа.",
		"objective": "Определите ID, где Доступ >= 3.",
		"prompt": "Какие записи удовлетворяют Доступ >= 3?",
		"table": {
			"columns": [
				{"col_id": "id", "title": "ID"},
				{"col_id": "name", "title": "Имя"},
				{"col_id": "acc", "title": "Доступ"}
			],
			"rows": [
				{"row_id": "r1", "cells": {"id": "101", "name": "Альфа", "acc": "2"}},
				{"row_id": "r2", "cells": {"id": "102", "name": "Бета", "acc": "3"}},
				{"row_id": "r3", "cells": {"id": "103", "name": "Гамма", "acc": "4"}}
			]
		},
		"options": [
			{"id": "opt_1", "text": "Оформить отчёт: список высокого доступа содержит ID 101", "f_reason": "MISSED_COLUMN"},
			{"id": "opt_2", "text": "Отправить пакет доказательств: ID 102 и 103", "f_reason": null},
			{"id": "opt_3", "text": "Эскалировать все строки как высокий доступ", "f_reason": "MISSED_ROW"},
			{"id": "opt_4", "text": "Подтвердить только ID 103", "f_reason": "MISSED_ROW"}
		],
		"answer_id": "opt_2",
		"reveal": {
			"on_correct": "Строки r2 и r3 удовлетворяют Доступ >= 3. Строка r1 ниже порога.",
			"on_wrong_by_reason": {
				"MISSED_COLUMN": "Значения Доступ прочитаны неверно. Используйте столбец Доступ как ключ фильтра.",
				"MISSED_ROW": "Хотя бы одна подходящая строка пропущена или лишняя строка включена."
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
		"briefing": "Оперативный канал сообщает о всплесках нестабильности. Извлеките только явные записи с ОШИБКОЙ из хронологии инцидента.",
		"objective": "Определите отметки времени, где Статус == ОШИБКА.",
		"prompt": "Какие отметки времени помечены как ОШИБКА?",
		"table": {
			"columns": [
				{"col_id": "time", "title": "Время"},
				{"col_id": "status", "title": "Статус"}
			],
			"rows": [
				{"row_id": "r1", "cells": {"time": "09:00", "status": "НОРМА"}},
				{"row_id": "r2", "cells": {"time": "09:05", "status": "ОШИБКА"}},
				{"row_id": "r3", "cells": {"time": "09:10", "status": "ПРЕДУПРЕЖДЕНИЕ"}},
				{"row_id": "r4", "cells": {"time": "09:15", "status": "ОШИБКА"}}
			]
		},
		"options": [
			{"id": "opt_1", "text": "Отметить 09:00 и 09:10 как критические сбои", "f_reason": "MISSED_COLUMN"},
			{"id": "opt_2", "text": "Открыть тикет инцидента для 09:05 и 09:15", "f_reason": null},
			{"id": "opt_3", "text": "Эскалировать только 09:05", "f_reason": "MISSED_ROW"},
			{"id": "opt_4", "text": "Пометить каждую строку как ОШИБКА", "f_reason": "COUNT_HEADER_AS_RECORD"}
		],
		"answer_id": "opt_2",
		"reveal": {
			"on_correct": "Только строки с явным статусом ОШИБКА — r2 и r4.",
			"on_wrong_by_reason": {
				"MISSED_COLUMN": "Фильтр должен строиться по Статус; одних значений времени недостаточно.",
				"MISSED_ROW": "Одна строка с ОШИБКОЙ была пропущена.",
				"COUNT_HEADER_AS_RECORD": "Не считайте заголовки или нерелевантные статусы строками инцидента."
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
		"briefing": "Карта сущностей восстановлена с резервного узла. Подтвердите зависимость пользователь-пост перед связыванием архивов.",
		"objective": "Определите тип связи: один пользователь может написать много постов.",
		"prompt": "Какая связь соответствует Пользователи.id -> Посты.user_id?",
		"table": {
			"columns": [
				{"col_id": "table", "title": "Таблица"},
				{"col_id": "key", "title": "Ключ"}
			],
			"rows": [
				{"row_id": "r1", "cells": {"table": "Пользователи", "key": "id (PK)"}},
				{"row_id": "r2", "cells": {"table": "Посты", "key": "user_id (FK)"}}
			]
		},
		"options": [
			{"id": "opt_1", "text": "Подтвердить связь один-к-одному", "f_reason": "CONFUSED_PK_FIELD"},
			{"id": "opt_2", "text": "Подтвердить связь один-ко-многим", "f_reason": null},
			{"id": "opt_3", "text": "Подтвердить связь многие-ко-многим", "f_reason": "CONFUSED_ROW_COLUMN"},
			{"id": "opt_4", "text": "Отклонить связь", "f_reason": "CONFUSED_PK_FIELD"}
		],
		"answer_id": "opt_2",
		"reveal": {
			"on_correct": "Пользователи.id (PK), на который ссылается Посты.user_id (FK), образует связь 1:M.",
			"on_wrong_by_reason": {
				"CONFUSED_PK_FIELD": "Связь PK->FK здесь допускает несколько постов на одного пользователя.",
				"CONFUSED_ROW_COLUMN": "Тип связи определяется семантикой ключей, а не порядком таблиц в сетке."
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
		"briefing": "Платёжные логи содержат заказы с разными суммами. Выделите только транзакции с малой суммой для ручной проверки.",
		"objective": "Определите заказы, где Сумма < 100.",
		"prompt": "Какие заказы удовлетворяют Сумма < 100?",
		"table": {
			"columns": [
				{"col_id": "ord", "title": "Заказ"},
				{"col_id": "sum", "title": "Сумма"}
			],
			"rows": [
				{"row_id": "r1", "cells": {"ord": "A-10", "sum": "150"}},
				{"row_id": "r2", "cells": {"ord": "A-11", "sum": "80"}},
				{"row_id": "r3", "cells": {"ord": "A-12", "sum": "99"}},
				{"row_id": "r4", "cells": {"ord": "A-13", "sum": "100"}}
			]
		},
		"options": [
			{"id": "opt_1", "text": "Заморозить для проверки заказы A-11 и A-12", "f_reason": null},
			{"id": "opt_2", "text": "Заморозить A-11, A-12 и A-13", "f_reason": "MISSED_COLUMN"},
			{"id": "opt_3", "text": "Заморозить только A-10", "f_reason": "MISSED_ROW"},
			{"id": "opt_4", "text": "Заморозить только A-13", "f_reason": "MISSED_COLUMN"}
		],
		"answer_id": "opt_1",
		"reveal": {
			"on_correct": "A-11 (80) и A-12 (99) строго меньше 100.",
			"on_wrong_by_reason": {
				"MISSED_COLUMN": "Используйте строгое '< 100'. Значение 100 исключается.",
				"MISSED_ROW": "Вы выбрали неподходящие строки и пропустили корректные малые суммы."
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
		"briefing": "Шаблон запроса повреждён. Восстановите оператор, исключающий состояние ЗАКРЫТ.",
		"objective": "Выберите оператор для условия: статус не равно ЗАКРЫТ.",
		"prompt": "Какое выражение корректно означает 'статус не равно ЗАКРЫТ'?",
		"table": {
			"columns": [
				{"col_id": "field", "title": "Поле"},
				{"col_id": "value", "title": "Значение"}
			],
			"rows": [
				{"row_id": "r1", "cells": {"field": "статус", "value": "ЗАКРЫТ"}},
				{"row_id": "r2", "cells": {"field": "статус", "value": "ОТКРЫТ"}},
				{"row_id": "r3", "cells": {"field": "статус", "value": "ОЖИДАНИЕ"}}
			]
		},
		"options": [
			{"id": "opt_1", "text": "Применить фильтр: статус == ЗАКРЫТ", "f_reason": "MISSED_COLUMN"},
			{"id": "opt_2", "text": "Применить фильтр: статус != ЗАКРЫТ", "f_reason": null},
			{"id": "opt_3", "text": "Применить фильтр: статус > ЗАКРЫТ", "f_reason": "CONFUSED_ROW_COLUMN"},
			{"id": "opt_4", "text": "Применить фильтр: статус <= ЗАКРЫТ", "f_reason": "CONFUSED_ROW_COLUMN"}
		],
		"answer_id": "opt_2",
		"reveal": {
			"on_correct": "Оператор '!=' исключает ЗАКРЫТ и оставляет ОТКРЫТ/ОЖИДАНИЕ.",
			"on_wrong_by_reason": {
				"MISSED_COLUMN": "Проверка равенства выбирает сам ЗАКРЫТ, а не множество исключения.",
				"CONFUSED_ROW_COLUMN": "Операторы сравнения строк здесь не выражают логическое исключение."
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
		"briefing": "Региональный экспортный список повреждён. Восстановите только ID клиентов, связанных с записями Алматы.",
		"objective": "Выберите клиентов, где Город == Алматы.",
		"prompt": "Какие клиенты из Алматы?",
		"table": {
			"columns": [
				{"col_id": "cid", "title": "CID"},
				{"col_id": "city", "title": "Город"}
			],
			"rows": [
				{"row_id": "r1", "cells": {"cid": "C1", "city": "Алматы"}},
				{"row_id": "r2", "cells": {"cid": "C2", "city": "Астана"}},
				{"row_id": "r3", "cells": {"cid": "C3", "city": "Алматы"}}
			]
		},
		"options": [
			{"id": "opt_1", "text": "Выдать ордер только для C2", "f_reason": "MISSED_COLUMN"},
			{"id": "opt_2", "text": "Выдать ордер для C1 и C3", "f_reason": null},
			{"id": "opt_3", "text": "Выдать ордер для всех клиентов", "f_reason": "COUNT_HEADER_AS_RECORD"},
			{"id": "opt_4", "text": "Закрыть дело: подходящих клиентов нет", "f_reason": "MISSED_ROW"}
		],
		"answer_id": "opt_2",
		"reveal": {
			"on_correct": "C1 и C3 помечены как Город = Алматы.",
			"on_wrong_by_reason": {
				"MISSED_COLUMN": "Фильтр должен совпадать по Город, а не по порядку CID.",
				"COUNT_HEADER_AS_RECORD": "Не эскалируйте неподходящие строки.",
				"MISSED_ROW": "Корректные строки Алматы были пропущены."
			}
		},
		"highlight": {
			"mode": "ROWS",
			"target_row_ids": ["r1", "r3"]
		},
		"timing_policy": {"mode": "LEARNING", "limit_sec": 120}
	}
]
