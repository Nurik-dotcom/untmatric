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
	A_WRONG_EVIDENCE: "Недостаточно доказательств",
	A_L1_BROADCAST: "Ошибка широковещательной передачи уровня 1",
	A_L2_SEGMENT_LIMIT: "Ограничение уровня 2",
	A_L1_PHYSICAL: "Ошибка физического канала",
	A_PASSIVE: "Пассивный компонент",
	A_L3_OVERKILL: "Перепроектированный уровень 3",
	A_L2_BRIDGE_LIMIT: "Ограничение моста",
	B_MATH_X8: "Ошибка преобразования байта в бит",
	B_MATH_1024: "1024 Ошибка преобразования",
	B_MATH_DIV: "Отсутствует разделение времени",
	B_UNIT_TRAP: "Несоответствие единиц измерения",
	B_PIPELINE_INCOMPLETE: "Трубопровод не завершен",
	B_PIPELINE_BAD_DROP: "Модуль в неправильном слоте",
	B_PIPELINE_MISMATCH: "Несоответствие трубопровода",
	B_SPAM_TRACE: "Командный спам",
	B_GARBAGE: "Нерелевантная ценность",
	C_NOT_APPLIED: "И не применяется",
	C_MASK_VAL: "Путаница со значением маски",
	C_L24_FALLBACK: "Рефлекс /24 Угадайка",
	C_BOUNDARY_SHIFT: "Сдвиг границ",
	C_BROADCAST: "Широковещательный адрес",
	C_MASK_INVALID: "Неверный шаблон маски",
	C_BAD_STEP: "Неправильный шаг сегмента",
	C_BAD_DROP: "Маска не установлена",
	C_IP_VAL: "Значение IP вместо идентификатора сети",
	TIMEOUT: "Тайм-аут",
	UNKNOWN: "Неизвестная ошибка"
}

const SHORT_MESSAGES: Dictionary = {
	"": "",
	A_WRONG_EVIDENCE: "Прежде чем запускать трассировку, соберите как минимум две улики.",
	A_L1_BROADCAST: "Хаб перенасыщает трафик и не может изолировать коллизии.",
	A_L2_SEGMENT_LIMIT: "Устройства уровня 2 не маршрутизируются между подсетями.",
	A_L1_PHYSICAL: "Это исправляет только сигнал, а не логику пересылки пакетов.",
	A_PASSIVE: "Пассивное оборудование не может принимать решения о пересылке.",
	A_L3_OVERKILL: "Маршрутизатор работает, но набор подсказок указывает на более простое решение.",
	A_L2_BRIDGE_LIMIT: "Мост по-прежнему работает внутри одного широковещательного домена.",
	B_MATH_X8: "Байты необходимо преобразовать в биты с помощью x8.",
	B_MATH_1024: "В этой задаче используйте 1024 для преобразования КБ/МБ.",
	B_MATH_DIV: "Пропускная способность требует деления по времени.",
	B_UNIT_TRAP: "Выходная единица не соответствует запрошенной единице.",
	B_PIPELINE_INCOMPLETE: "Заполните все четыре слота конвейера, затем запустите расчет.",
	B_PIPELINE_BAD_DROP: "Этот тип модуля не может быть установлен в этот слот.",
	B_PIPELINE_MISMATCH: "Выбранный ответ не соответствует поведению собранного конвейера.",
	B_SPAM_TRACE: "Обнаружены повторные спам-клики.",
	B_GARBAGE: "Выбранное значение не связано с расчетной пропускной способностью.",
	C_NOT_APPLIED: "Выполните «ПРИМЕНИТЬ И» перед выбором идентификатора сети.",
	C_MASK_VAL: "Значение маски не является идентификатором сети.",
	C_L24_FALLBACK: "Предположение по умолчанию /24 не соответствует текущему CIDR.",
	C_BOUNDARY_SHIFT: "Выбирайте границу сегмента, а не ближайшее число.",
	C_BROADCAST: "Широковещательный адрес не является идентификатором сети.",
	C_MASK_INVALID: "Маска должна быть непрерывной: 111...000...",
	C_BAD_STEP: "Шаг сегмента неверен для этого CIDR.",
	C_BAD_DROP: "Сначала поместите маску в целевую область маски.",
	C_IP_VAL: "Это значение IP хоста, а не идентификатор сети.",
	TIMEOUT: "Срок истек.",
	UNKNOWN: "Проверьте этапы преобразования и целевую единицу измерения."
}

const DETAIL_MESSAGES: Dictionary = {
	A_L1_BROADCAST: [
		"Широковещательные штормы и всплески столкновений указывают на неправильное использование хаба.",
		"Для изоляции трафика требуется коммутация или маршрутизация."
	],
	A_L2_SEGMENT_LIMIT: [
		"Коммутация и пересылка кадров внутри одного домена L2.",
		"Для подключения между подсетями требуется маршрутизатор."
	],
	B_MATH_X8: [
		"Формула: биты = байты х 8.",
		"Пропуск x8 возвращает скорость передачи данных, а не скорость передачи данных."
	],
	B_MATH_1024: [
		"В этом задании используйте двоичное преобразование КБ/МБ.",
		"KB = 1024 байт, MB = 1024 x 1024 байт."
	],
	B_UNIT_TRAP: [
		"Перед подтверждением проверьте блок подсказки.",
		"Если целевая единица — кбит/с, переведите бит/с в кбит/с делением на 1000."
	],
	C_MASK_VAL: [
		"Идентификатор сети = IP_last И mask_last.",
		"Маска сама по себе является лишь фильтром, а не окончательным ответом."
	],
	C_BOUNDARY_SHIFT: [
		"Шаг = 256 - mask_last.",
		"Граница сети равна этажу, кратному шагу."
	],
	UNKNOWN: [
		"Перепроверьте каждый этап преобразования.",
		"Убедитесь, что выбранная опция соответствует вычисленному результату."
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
