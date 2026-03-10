extends Node

class_name TestCase01I18n

const EN_PATH := "res://data/i18n/en.json"
const RU_PATH := "res://data/i18n/ru.json"
const KK_PATH := "res://data/i18n/kk.json"

var test_results: Dictionary = {
	"passed": 0,
	"failed": 0,
	"skipped": 0
}

func _ready() -> void:
	run_all_tests()
	print_results()

func run_all_tests() -> void:
	test_resus_key_presence_and_parity()
	test_placeholder_parity_for_resus_keys()
	test_no_mojibake_in_resus_namespace()

func test_resus_key_presence_and_parity() -> void:
	var en: Dictionary = _load_dict(EN_PATH)
	var ru: Dictionary = _load_dict(RU_PATH)
	var kk: Dictionary = _load_dict(KK_PATH)

	var en_keys: Array[String] = _resus_keys(en)
	var ru_keys: Array[String] = _resus_keys(ru)
	var kk_keys: Array[String] = _resus_keys(kk)

	assert_equal(ru_keys.size(), en_keys.size(), "RU and EN have equal count of resus.* keys")
	assert_equal(kk_keys.size(), en_keys.size(), "KK and EN have equal count of resus.* keys")

	var ru_set: Dictionary = {}
	var kk_set: Dictionary = {}
	for k in ru_keys:
		ru_set[k] = true
	for k in kk_keys:
		kk_set[k] = true

	for key in en_keys:
		assert_true(ru_set.has(key), "RU contains key %s" % key)
		assert_true(kk_set.has(key), "KK contains key %s" % key)

func test_placeholder_parity_for_resus_keys() -> void:
	var en: Dictionary = _load_dict(EN_PATH)
	var ru: Dictionary = _load_dict(RU_PATH)
	var kk: Dictionary = _load_dict(KK_PATH)
	var placeholder_re := RegEx.new()
	placeholder_re.compile("\\{[A-Za-z0-9_]+\\}")

	for key in _resus_keys(en):
		var en_tokens: Array[String] = _extract_tokens(str(en.get(key, "")), placeholder_re)
		var ru_tokens: Array[String] = _extract_tokens(str(ru.get(key, "")), placeholder_re)
		var kk_tokens: Array[String] = _extract_tokens(str(kk.get(key, "")), placeholder_re)
		assert_equal(_token_signature(ru_tokens), _token_signature(en_tokens), "Placeholder parity RU/EN for %s" % key)
		assert_equal(_token_signature(kk_tokens), _token_signature(en_tokens), "Placeholder parity KK/EN for %s" % key)

func test_no_mojibake_in_resus_namespace() -> void:
	var bad_markers: Array[String] = [char(0x00D0), char(0x00D1), char(0xFF90)]
	for pair in [
		{"lang": "EN", "dict": _load_dict(EN_PATH)},
		{"lang": "RU", "dict": _load_dict(RU_PATH)},
		{"lang": "KK", "dict": _load_dict(KK_PATH)}
	]:
		var lang: String = str((pair as Dictionary).get("lang", "??"))
		var dict: Dictionary = (pair as Dictionary).get("dict", {}) as Dictionary
		for key in _resus_keys(dict):
			var value: String = str(dict.get(key, ""))
			var has_bad: bool = false
			for marker in bad_markers:
				if value.find(marker) != -1:
					has_bad = true
					break
			assert_true(not has_bad, "%s has no mojibake in %s" % [lang, key])

func _extract_tokens(text: String, regex: RegEx) -> Array[String]:
	var out: Array[String] = []
	for match in regex.search_all(text):
		out.append(match.get_string())
	out.sort()
	return out

func _token_signature(tokens: Array[String]) -> String:
	return "|".join(tokens)

func _load_dict(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return {}
	if typeof(json.data) != TYPE_DICTIONARY:
		return {}
	return json.data as Dictionary

func _resus_keys(dict: Dictionary) -> Array[String]:
	var keys: Array[String] = []
	for key_v in dict.keys():
		var key: String = str(key_v)
		if key.begins_with("resus."):
			keys.append(key)
	keys.sort()
	return keys

func assert_true(condition: bool, message: String) -> void:
	if condition:
		test_results["passed"] += 1
	else:
		test_results["failed"] += 1
		print("FAILED: %s" % message)

func assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		test_results["passed"] += 1
	else:
		test_results["failed"] += 1
		print("FAILED: %s (got=%s expected=%s)" % [message, str(actual), str(expected)])

func print_results() -> void:
	print("[CASE01 I18N TESTS] passed=%d failed=%d" % [int(test_results.get("passed", 0)), int(test_results.get("failed", 0))])

func get_test_results() -> Dictionary:
	return test_results.duplicate(true)
