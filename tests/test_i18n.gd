extends Node

class_name TestI18n

var test_results: Dictionary = {
	"passed": 0,
	"failed": 0,
	"skipped": 0
}

var _signal_count: int = 0
var _initial_language: String = "ru"

func _ready() -> void:
	_initial_language = I18n.get_language()
	run_all_tests()
	I18n.set_language(_initial_language)
	print_results()

func run_all_tests() -> void:
	test_tr_key_ru()
	test_fallback_kk_to_ru()
	test_fallback_en_to_ru()
	test_resolve_field_key_and_legacy()
	test_language_changed_emits_once()
	test_case08_briefing_not_ru_for_kk_en()
	test_en_contains_required_case08_keys()
	test_decryptor_required_keys_in_en_kk()
	test_decryptor_not_ru_for_kk_en()
	test_menu_back_keys_present()
	test_decryptor_namespace_has_no_mojibake()
	test_city_map_required_keys_in_ru_kk_en()
	test_city_map_not_ru_for_kk_en_samples()
	test_city_map_no_question_marks_in_ru_kk()
	test_city_map_placeholder_parity()
	test_city_map_namespace_has_no_mojibake()
	test_radio_required_keys_in_ru_kk_en()
	test_radio_not_ru_for_kk_en_samples()
	test_radio_placeholder_parity()
	test_radio_namespace_has_no_mojibake()

func test_tr_key_ru() -> void:
	I18n.set_language("ru")
	var value: String = I18n.tr_key("ui.main_menu.quests", {"default": "fallback"})
	assert_equal(value, "КВЕСТЫ", "tr_key() returns RU translation")

func test_fallback_kk_to_ru() -> void:
	I18n.set_language("kk")
	var value: String = I18n.tr_key("test.i18n.ru_only", {"default": "fallback"})
	assert_equal(value, "Только RU", "kk fallback uses ru key when kk key is missing")

func test_fallback_en_to_ru() -> void:
	I18n.set_language("en")
	var value: String = I18n.tr_key("test.i18n.ru_only", {"default": "fallback"})
	assert_equal(value, "Только RU", "en fallback uses ru key when en key is missing")

func test_resolve_field_key_and_legacy() -> void:
	I18n.set_language("ru")
	var entry_with_key: Dictionary = {
		"title_key": "ui.main_menu.quests",
		"title": "LEGACY"
	}
	var entry_legacy_only: Dictionary = {
		"title": "LEGACY"
	}
	var from_key: String = I18n.resolve_field(entry_with_key, "title")
	var from_legacy: String = I18n.resolve_field(entry_legacy_only, "title")
	assert_equal(from_key, "КВЕСТЫ", "resolve_field() prioritizes *_key")
	assert_equal(from_legacy, "LEGACY", "resolve_field() falls back to legacy field")

func test_language_changed_emits_once() -> void:
	_signal_count = 0
	var start_lang: String = I18n.get_language()
	var target_lang: String = "kk" if start_lang != "kk" else "ru"

	if I18n.language_changed.is_connected(_on_language_changed_test):
		I18n.language_changed.disconnect(_on_language_changed_test)
	I18n.language_changed.connect(_on_language_changed_test)

	I18n.set_language(start_lang)
	I18n.set_language(target_lang)
	I18n.set_language(target_lang)

	assert_equal(_signal_count, 1, "language_changed emits once per actual language change")

	if I18n.language_changed.is_connected(_on_language_changed_test):
		I18n.language_changed.disconnect(_on_language_changed_test)
	I18n.set_language(start_lang)

func test_case08_briefing_not_ru_for_kk_en() -> void:
	var sample_key: String = "case08.fr8a.FR8-A-L01.briefing"
	I18n.set_language("ru")
	var ru_value: String = I18n.tr_key(sample_key, {"default": "__missing_ru__"})
	I18n.set_language("kk")
	var kk_value: String = I18n.tr_key(sample_key, {"default": "__missing_kk__"})
	I18n.set_language("en")
	var en_value: String = I18n.tr_key(sample_key, {"default": "__missing_en__"})

	assert_true(ru_value != "__missing_ru__", "RU has sample FR8 briefing key")
	assert_true(kk_value != "__missing_kk__", "KK has sample FR8 briefing key")
	assert_true(en_value != "__missing_en__", "EN has sample FR8 briefing key")
	assert_true(kk_value != ru_value, "KK sample briefing differs from RU")
	assert_true(en_value != ru_value, "EN sample briefing differs from RU")

func test_en_contains_required_case08_keys() -> void:
	var required_keys: Array[String] = [
		"case08.fr8a.title",
		"case08.fr8a.status.hint",
		"case08.fr8a.render.error",
		"case08.fr8a.preview.render_off",
		"case08.fr8b.title",
		"case08.fr8b.status.hint",
		"case08.fr8c.title",
		"case08.fr8c.status.hint",
		"case08.scoring.default_check_done",
		"case08.scoring.c.try_again"
	]

	I18n.set_language("en")
	for key in required_keys:
		var sentinel: String = "__missing_%s__" % key
		var value: String = I18n.tr_key(key, {"default": sentinel})
		assert_true(value != sentinel, "EN has required key %s" % key)

func test_decryptor_required_keys_in_en_kk() -> void:
	var required_keys: Array[String] = [
		"decryptor.ab.ui.btn_check",
		"decryptor.ab.ui.safe_title",
		"decryptor.ab.hint.none",
		"decryptor.ab.toast.success",
		"decryptor.ab.log.system_ready",
		"decryptor.ab.rank.analyst",
		"decryptor.c.ui.status_title",
		"decryptor.c.hint.match_targets",
		"decryptor.c.status.progress",
		"decryptor.c.toast.stage_complete",
		"decryptor.c.log.stage_start",
		"decryptor.c.mode.stages_rc"
	]

	for lang in ["en", "kk"]:
		I18n.set_language(lang)
		for key in required_keys:
			var sentinel: String = "__missing_%s_%s__" % [lang, key]
			var value: String = I18n.tr_key(key, {"default": sentinel})
			assert_true(value != sentinel, "%s has decryptor key %s" % [lang.to_upper(), key])

func test_decryptor_not_ru_for_kk_en() -> void:
	var sample_keys: Array[String] = [
		"decryptor.ab.hint.none",
		"decryptor.ab.toast.success",
		"decryptor.c.hint.match_targets",
		"decryptor.c.toast.stage_complete"
	]

	I18n.set_language("ru")
	var ru_values: Dictionary = {}
	for key in sample_keys:
		ru_values[key] = I18n.tr_key(key, {"default": "__missing_ru__"})

	for lang in ["kk", "en"]:
		I18n.set_language(lang)
		for key in sample_keys:
			var value: String = I18n.tr_key(key, {"default": "__missing_%s__" % lang})
			assert_true(value != str(ru_values.get(key, "")), "%s decryptor text differs from RU for %s" % [lang.to_upper(), key])

func test_menu_back_keys_present() -> void:
	var required_keys: Array[String] = [
		"ui.quest_select.back_to_menu",
		"ui.learn_select.back_to_menu"
	]

	for lang in ["ru", "kk", "en"]:
		I18n.set_language(lang)
		for key in required_keys:
			var sentinel: String = "__missing_%s_%s__" % [lang, key]
			var value: String = I18n.tr_key(key, {"default": sentinel})
			assert_true(value != sentinel, "%s has menu back key %s" % [lang.to_upper(), key])

func test_decryptor_namespace_has_no_mojibake() -> void:
	var dictionaries := {
		"ru": _load_dictionary("res://data/i18n/ru.json"),
		"kk": _load_dictionary("res://data/i18n/kk.json"),
		"en": _load_dictionary("res://data/i18n/en.json")
	}
	var bad_pattern := RegEx.new()
	bad_pattern.compile("[ЃЌЋЏђѓќћџ�]")

	for lang in dictionaries.keys():
		var dict: Dictionary = dictionaries.get(lang, {})
		for key_var in dict.keys():
			var key: String = str(key_var)
			if not key.begins_with("decryptor.ab.") and not key.begins_with("decryptor.c."):
				continue
			var value: String = str(dict.get(key, ""))
			var has_bad: bool = bad_pattern.search(value) != null
			assert_true(not has_bad, "%s decryptor key has no mojibake marker: %s" % [str(lang).to_upper(), key])

func test_city_map_required_keys_in_ru_kk_en() -> void:
	var required_keys: Array[String] = [
		"city_map.common.header.case",
		"city_map.common.header.progress",
		"city_map.common.btn.reset",
		"city_map.common.btn.submit",
		"city_map.common.input.path",
		"city_map.common.result.err_calc",
		"city_map.common.status.stability",
		"city_map.common.warning.none",
		"city_map.a.briefing.title",
		"city_map.b.briefing.title",
		"city_map.b.constraints.must_visit",
		"city_map.c.briefing.title",
		"city_map.c.schedule.title",
		"city_map.c.constraints.xor",
		"city_map.c.status.wait",
		"city_map.c.result.err_logic_violation"
	]

	for lang in ["ru", "kk", "en"]:
		I18n.set_language(lang)
		for key in required_keys:
			var sentinel: String = "__missing_%s_%s__" % [lang, key]
			var value: String = I18n.tr_key(key, {"default": sentinel})
			assert_true(value != sentinel, "%s has city_map key %s" % [lang.to_upper(), key])
			assert_true(not value.strip_edges().is_empty(), "%s city_map key is not empty: %s" % [lang.to_upper(), key])

func test_city_map_not_ru_for_kk_en_samples() -> void:
	var sample_keys: Array[String] = [
		"city_map.a.briefing.title",
		"city_map.b.status.success",
		"city_map.c.status.wait",
		"city_map.c.warning.blacklist"
	]

	I18n.set_language("ru")
	var ru_values: Dictionary = {}
	for key in sample_keys:
		ru_values[key] = I18n.tr_key(key, {"default": "__missing_ru__"})

	for lang in ["kk", "en"]:
		I18n.set_language(lang)
		for key in sample_keys:
			var value: String = I18n.tr_key(key, {"default": "__missing_%s__" % lang})
			assert_true(value != str(ru_values.get(key, "")), "%s city_map text differs from RU for %s" % [lang.to_upper(), key])

func test_city_map_no_question_marks_in_ru_kk() -> void:
	var dictionaries := {
		"ru": _load_dictionary("res://data/i18n/ru.json"),
		"kk": _load_dictionary("res://data/i18n/kk.json")
	}
	var bad_pattern := RegEx.new()
	bad_pattern.compile("\\?{2,}")

	for lang in dictionaries.keys():
		var dict: Dictionary = dictionaries.get(lang, {})
		for key_var in dict.keys():
			var key: String = str(key_var)
			if not key.begins_with("city_map."):
				continue
			var value: String = str(dict.get(key, ""))
			var has_bad: bool = bad_pattern.search(value) != null
			assert_true(not has_bad, "%s city_map key has no ?? pattern: %s" % [str(lang).to_upper(), key])

func test_city_map_placeholder_parity() -> void:
	var en_dict: Dictionary = _load_dictionary("res://data/i18n/en.json")
	var ru_dict: Dictionary = _load_dictionary("res://data/i18n/ru.json")
	var kk_dict: Dictionary = _load_dictionary("res://data/i18n/kk.json")
	var keys: Array[String] = [
		"city_map.common.header.progress",
		"city_map.common.input.path",
		"city_map.common.input.sum",
		"city_map.common.status.time",
		"city_map.common.result.unhandled",
		"city_map.common.warning.list",
		"city_map.b.constraints.must_visit",
		"city_map.b.constraints.backtrack",
		"city_map.b.warning.missing_must",
		"city_map.c.constraints.must_visit",
		"city_map.c.constraints.xor",
		"city_map.c.constraints.blacklist",
		"city_map.c.schedule.active_slot",
		"city_map.c.schedule.row",
		"city_map.c.schedule.row_ttc",
		"city_map.c.schedule.time_to_change",
		"city_map.c.schedule.danger_weight",
		"city_map.c.warning.missing_must"
	]

	for key in keys:
		var en_placeholders: Array[String] = _extract_placeholders(str(en_dict.get(key, "")))
		var ru_placeholders: Array[String] = _extract_placeholders(str(ru_dict.get(key, "")))
		var kk_placeholders: Array[String] = _extract_placeholders(str(kk_dict.get(key, "")))
		assert_equal(ru_placeholders, en_placeholders, "RU placeholder parity for %s" % key)
		assert_equal(kk_placeholders, en_placeholders, "KK placeholder parity for %s" % key)

func test_city_map_namespace_has_no_mojibake() -> void:
	var dictionaries := {
		"ru": _load_dictionary("res://data/i18n/ru.json"),
		"kk": _load_dictionary("res://data/i18n/kk.json"),
		"en": _load_dictionary("res://data/i18n/en.json")
	}
	var bad_pattern := RegEx.new()
	bad_pattern.compile("(?:Р.|С.){3,}|вЂ")

	for lang in dictionaries.keys():
		var dict: Dictionary = dictionaries.get(lang, {})
		for key_var in dict.keys():
			var key: String = str(key_var)
			if not key.begins_with("city_map."):
				continue
			var value: String = str(dict.get(key, ""))
			var has_bad: bool = bad_pattern.search(value) != null
			assert_true(not has_bad, "%s city_map key has no mojibake marker: %s" % [str(lang).to_upper(), key])

func test_radio_required_keys_in_ru_kk_en() -> void:
	var required_keys: Array[String] = _collect_radio_keys_from_scripts()
	assert_true(not required_keys.is_empty(), "Collected radio.* keys from RadioQuest scripts")

	for lang in ["ru", "kk", "en"]:
		I18n.set_language(lang)
		for key in required_keys:
			var sentinel: String = "__missing_%s_%s__" % [lang, key]
			var value: String = I18n.tr_key(key, {"default": sentinel})
			assert_true(value != sentinel, "%s has radio key %s" % [lang.to_upper(), key])
			assert_true(not value.strip_edges().is_empty(), "%s radio key is not empty: %s" % [lang.to_upper(), key])

func test_radio_not_ru_for_kk_en_samples() -> void:
	var sample_keys: Array[String] = [
		"radio.a.ui.title",
		"radio.a.status.plan",
		"radio.a.details.rule",
		"radio.b.ui.storage_title",
		"radio.b.status.converter_hint",
		"radio.b.preview.class_best",
		"radio.c.ui.title",
		"radio.c.status.plan",
		"radio.c.details.formula"
	]

	I18n.set_language("ru")
	var ru_values: Dictionary = {}
	for key in sample_keys:
		ru_values[key] = I18n.tr_key(key, {"default": "__missing_ru__"})

	for lang in ["kk", "en"]:
		I18n.set_language(lang)
		for key in sample_keys:
			var value: String = I18n.tr_key(key, {"default": "__missing_%s__" % lang})
			assert_true(value != str(ru_values.get(key, "")), "%s radio text differs from RU for %s" % [lang.to_upper(), key])

func test_radio_placeholder_parity() -> void:
	var en_dict: Dictionary = _load_dictionary("res://data/i18n/en.json")
	var ru_dict: Dictionary = _load_dictionary("res://data/i18n/ru.json")
	var kk_dict: Dictionary = _load_dictionary("res://data/i18n/kk.json")
	var keys: Array[String] = _collect_radio_keys_from_scripts()

	for key in keys:
		var en_placeholders: Array[String] = _extract_placeholders(str(en_dict.get(key, "")))
		var ru_placeholders: Array[String] = _extract_placeholders(str(ru_dict.get(key, "")))
		var kk_placeholders: Array[String] = _extract_placeholders(str(kk_dict.get(key, "")))
		assert_equal(ru_placeholders, en_placeholders, "RU radio placeholder parity for %s" % key)
		assert_equal(kk_placeholders, en_placeholders, "KK radio placeholder parity for %s" % key)

func test_radio_namespace_has_no_mojibake() -> void:
	var dictionaries := {
		"ru": _load_dictionary("res://data/i18n/ru.json"),
		"kk": _load_dictionary("res://data/i18n/kk.json"),
		"en": _load_dictionary("res://data/i18n/en.json")
	}
	var bad_pattern := RegEx.new()
	bad_pattern.compile("[ﾐσ糊巾肖柘酉慯嶝滂ｿｽ]")

	for lang in dictionaries.keys():
		var dict: Dictionary = dictionaries.get(lang, {})
		for key_var in dict.keys():
			var key: String = str(key_var)
			if not key.begins_with("radio."):
				continue
			var value: String = str(dict.get(key, ""))
			var has_bad: bool = bad_pattern.search(value) != null
			assert_true(not has_bad, "%s radio key has no mojibake marker: %s" % [str(lang).to_upper(), key])

func _extract_placeholders(value: String) -> Array[String]:
	var pattern := RegEx.new()
	pattern.compile("\\{[A-Za-z0-9_]+\\}")
	var matches: Array[RegExMatch] = pattern.search_all(value)
	var unique: Dictionary = {}
	for match in matches:
		unique[match.get_string()] = true
	var result: Array[String] = []
	for key_var in unique.keys():
		result.append(str(key_var))
	result.sort()
	return result

func _load_dictionary(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed as Dictionary

func _collect_radio_keys_from_scripts() -> Array[String]:
	var paths: Array[String] = [
		"res://scenes/RadioQuestA.gd",
		"res://scenes/RadioQuestB.gd",
		"res://scenes/RadioQuestC.gd"
	]
	var pattern := RegEx.new()
	pattern.compile("\"(radio\\.[^\"]+)\"")
	var unique: Dictionary = {}

	for path in paths:
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		if file == null:
			continue
		var text: String = file.get_as_text()
		var matches: Array[RegExMatch] = pattern.search_all(text)
		for match in matches:
			unique[match.get_string(1)] = true

	var keys: Array[String] = []
	for key_var in unique.keys():
		keys.append(str(key_var))
	keys.sort()
	return keys

func _on_language_changed_test(_code: String) -> void:
	_signal_count += 1

func assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		test_results["passed"] += 1
	else:
		test_results["failed"] += 1
		print("FAILED: %s (got=%s expected=%s)" % [message, str(actual), str(expected)])

func assert_true(condition: bool, message: String) -> void:
	if condition:
		test_results["passed"] += 1
	else:
		test_results["failed"] += 1
		print("FAILED: %s" % message)

func print_results() -> void:
	print("[I18N TESTS] passed=%d failed=%d" % [int(test_results.get("passed", 0)), int(test_results.get("failed", 0))])

func get_test_results() -> Dictionary:
	return test_results.duplicate(true)
