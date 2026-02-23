extends RefCounted
class_name NetworkTraceErrors

const A_WRONG_EVIDENCE := "A_WRONG_EVIDENCE"
const A_L1_BROADCAST := "A_L1_BROADCAST"
const A_L2_SEGMENT_LIMIT := "A_L2_SEGMENT_LIMIT"
const A_L1_PHYSICAL := "A_L1_PHYSICAL"
const A_PASSIVE := "A_PASSIVE"
const A_L3_OVERKILL := "A_L3_OVERKILL"
const A_L2_BRIDGE_LIMIT := "A_L2_BRIDGE_LIMIT"

const B_MATH_X8 := "B_MATH_X8"
const B_MATH_1024 := "B_MATH_1024"
const B_MATH_DIV := "B_MATH_DIV"
const B_UNIT_TRAP := "B_UNIT_TRAP"
const B_PIPELINE_INCOMPLETE := "B_PIPELINE_INCOMPLETE"
const B_PIPELINE_BAD_DROP := "B_PIPELINE_BAD_DROP"
const B_PIPELINE_MISMATCH := "B_PIPELINE_MISMATCH"
const B_SPAM_TRACE := "B_SPAM_TRACE"
const B_GARBAGE := "B_GARBAGE"

const C_NOT_APPLIED := "C_NOT_APPLIED"
const C_MASK_VAL := "C_MASK_VAL"
const C_L24_FALLBACK := "C_L24_FALLBACK"
const C_BOUNDARY_SHIFT := "C_BOUNDARY_SHIFT"
const C_BROADCAST := "C_BROADCAST"
const C_MASK_INVALID := "C_MASK_INVALID"
const C_BAD_STEP := "C_BAD_STEP"
const C_BAD_DROP := "C_BAD_DROP"
const C_IP_VAL := "C_IP_VAL"

const TIMEOUT := "TIMEOUT"
const UNKNOWN := "UNKNOWN"

const TITLES: Dictionary = {
	A_WRONG_EVIDENCE: "НЕДОСТАТОЧНО УЛИК",
	A_L1_BROADCAST: "L1 ШТОРМ",
	A_L2_SEGMENT_LIMIT: "ОГРАНИЧЕНИЕ L2",
	A_L1_PHYSICAL: "ТОЛЬКО ФИЗИКА",
	A_PASSIVE: "ПАССИВНЫЙ ЭЛЕМЕНТ",
	A_L3_OVERKILL: "ИЗБЫТОЧНОЕ РЕШЕНИЕ",
	A_L2_BRIDGE_LIMIT: "ОГРАНИЧЕНИЕ BRIDGE",
	B_MATH_X8: "ОШИБКА ПЕРЕВОДА В БИТЫ",
	B_MATH_1024: "ОШИБКА БАЗЫ",
	B_MATH_DIV: "ОШИБКА ФОРМУЛЫ",
	B_UNIT_TRAP: "ЛОВУШКА ЕДИНИЦ",
	B_PIPELINE_INCOMPLETE: "ЯДРО НЕ СОБРАНО",
	B_PIPELINE_BAD_DROP: "НЕВЕРНЫЙ СЛОТ",
	B_PIPELINE_MISMATCH: "PIPELINE MISMATCH",
	B_SPAM_TRACE: "ЧАСТЫЕ ЗАПУСКИ",
	B_GARBAGE: "НЕКОРРЕКТНЫЙ РЕЗУЛЬТАТ",
	C_NOT_APPLIED: "AND НЕ ПРИМЕНЕН",
	C_MASK_VAL: "ЭТО ЗНАЧЕНИЕ МАСКИ",
	C_L24_FALLBACK: "ЛОВУШКА /24",
	C_BOUNDARY_SHIFT: "СДВИГ ГРАНИЦ",
	C_BROADCAST: "BROADCAST",
	C_MASK_INVALID: "НЕКОРРЕКТНАЯ МАСКА",
	C_BAD_STEP: "НЕВЕРНЫЙ ШАГ",
	C_BAD_DROP: "МАСКА НЕ УСТАНОВЛЕНА",
	C_IP_VAL: "ЭТО ЗНАЧЕНИЕ IP",
	TIMEOUT: "ТАЙМ-АУТ",
	UNKNOWN: "НЕВЕРНОЕ РЕШЕНИЕ"
}

const SHORT_MESSAGES: Dictionary = {
	"": "",
	A_WRONG_EVIDENCE: "Соберите улики перед запуском трассировки.",
	A_L1_BROADCAST: "Hub раздаёт всем: сегмент тонет в широковещании.",
	A_L2_SEGMENT_LIMIT: "L2 не маршрутизирует между подсетями.",
	A_L1_PHYSICAL: "Это решение для физического уровня, а не адресации.",
	A_PASSIVE: "Пассивный элемент не принимает логических решений.",
	A_L3_OVERKILL: "Router здесь избыточен, проблема решается на L2.",
	A_L2_BRIDGE_LIMIT: "Bridge не закрывает условие кейса.",
	B_MATH_X8: "Забыт перевод байт в биты (×8).",
	B_MATH_1024: "Использована десятичная база вместо 1024.",
	B_MATH_DIV: "Скорость нужно делить на время.",
	B_UNIT_TRAP: "Перепутаны единицы вывода (bps/kbps/байт/с).",
	B_PIPELINE_INCOMPLETE: "Сначала соберите ядро и нажмите RUN CALC.",
	B_PIPELINE_BAD_DROP: "Модуль не подходит к этому слоту.",
	B_PIPELINE_MISMATCH: "Ответ совпал, но pipeline собран неверно.",
	B_SPAM_TRACE: "Слишком частые запуски. Дождитесь окончания цикла.",
	B_GARBAGE: "Результат не совпадает с расчётной моделью.",
	C_NOT_APPLIED: "Сначала APPLY AND, затем выбирайте ответ.",
	C_MASK_VAL: "Это маска, а не Network ID.",
	C_L24_FALLBACK: "Рефлекс /24 тут не работает.",
	C_BOUNDARY_SHIFT: "Выбран неверный диапазон шага сети.",
	C_BROADCAST: "255 - это broadcast, не адрес сети.",
	C_MASK_INVALID: "Маска должна быть непрерывной: 111..000..",
	C_BAD_STEP: "Шаг подсети рассчитан неверно.",
	C_BAD_DROP: "Установите карту маски в строку MASK.",
	C_IP_VAL: "Это значение IP, нужен Network ID.",
	TIMEOUT: "Время задачи вышло.",
	UNKNOWN: "Неверный вариант для текущего кейса."
}

const DETAIL_MESSAGES: Dictionary = {
	A_L1_BROADCAST: [
		"Hub дублирует кадры на все порты и усиливает шум.",
		"Для адресной доставки в сегменте нужен Switch."
	],
	A_L2_SEGMENT_LIMIT: [
		"Switch и Bridge работают внутри L2-домена.",
		"Для обмена между разными подсетями нужен Router."
	],
	B_MATH_X8: [
		"Формула пропускной способности оперирует битами.",
		"Сначала переведите байты в биты: ×8."
	],
	B_MATH_1024: [
		"Для KB/MB в задаче используется двоичная база.",
		"Применяйте 1024, а не 1000."
	],
	B_UNIT_TRAP: [
		"Проверьте требуемую единицу в prompt.",
		"Число может быть верным, но единица - нет."
	],
	C_MASK_VAL: [
		"Значение mask_last не равно Network ID.",
		"Сеть вычисляется через IP AND MASK."
	],
	C_BOUNDARY_SHIFT: [
		"Определите шаг: 256 - mask_last.",
		"Возьмите ближайшую нижнюю границу диапазона."
	],
	UNKNOWN: [
		"Сопоставьте действие с условиями задачи.",
		"Проверьте улики, формулу или битовый шаг."
	]
}

static func short_message(code: String) -> String:
	var normalized: String = code.strip_edges()
	if SHORT_MESSAGES.has(normalized):
		return str(SHORT_MESSAGES[normalized])
	return str(SHORT_MESSAGES[UNKNOWN])

static func get_error_title(code: String) -> String:
	var normalized: String = code.strip_edges()
	if TITLES.has(normalized):
		return str(TITLES[normalized])
	return str(TITLES[UNKNOWN])

static func get_error_tip(code: String) -> String:
	return short_message(code)

static func detail_messages(code: String) -> Array[String]:
	var normalized: String = code.strip_edges()
	var source_variant: Variant = DETAIL_MESSAGES.get(normalized, DETAIL_MESSAGES.get(UNKNOWN, []))
	var source: Array = []
	if typeof(source_variant) == TYPE_ARRAY:
		source = source_variant
	var result: Array[String] = []
	for line_var in source:
		result.append(str(line_var))
	return result
