extends Node

class_name TestSceneSmoke

var test_results: Dictionary = {
	"passed": 0,
	"failed": 0,
	"skipped": 0
}

const CORE_SCENES: Array[String] = [
	"res://scenes/MainMenu.tscn",
	"res://scenes/QuestSelect.tscn",
	"res://scenes/LearnSelect.tscn"
]

const QUESTSELECT_TARGET_SCENES: Array[String] = [
	"res://scenes/Decryptor.tscn",
	"res://scenes/MatrixDecryptor.tscn",
	"res://scenes/LogicQuestA.tscn",
	"res://scenes/LogicQuestB.tscn",
	"res://scenes/LogicQuestC.tscn",
	"res://scenes/RadioQuestA.tscn",
	"res://scenes/RadioQuestB.tscn",
	"res://scenes/RadioQuestC.tscn",
	"res://scenes/SuspectQuestA.tscn",
	"res://scenes/RestoreQuestB.tscn",
	"res://scenes/DisarmQuestC.tscn",
	"res://scenes/CityMapQuestA.tscn",
	"res://scenes/CityMapQuestB.tscn",
	"res://scenes/CityMapQuestC.tscn",
	"res://scenes/case_07/da7_data_archive_a.tscn",
	"res://scenes/case_07/da7_data_archive_b.tscn",
	"res://scenes/case_07/da7_data_archive_c.tscn",
	"res://scenes/case_08/fr8_final_report_a.tscn",
	"res://scenes/case_08/fr8_final_report_b.tscn",
	"res://scenes/case_08/fr8_final_report_c.tscn",
	"res://scenes/NetworkTraceQuestA.tscn",
	"res://scenes/NetworkTraceQuestB.tscn",
	"res://scenes/NetworkTraceQuestC.tscn",
	"res://scenes/case_01/DigitalResusQuestA.tscn",
	"res://scenes/case_01/DigitalResusQuestB.tscn",
	"res://scenes/case_01/DigitalResusQuestC.tscn"
]

func _ready() -> void:
	print("\n[SCENE SMOKE TESTS]")
	test_core_scene_loading()
	test_quest_select_targets_open()
	print_results()

func test_core_scene_loading() -> void:
	print("\n[TEST] Core scene loading")
	for scene_path in CORE_SCENES:
		_assert_scene_openable(scene_path, "Core scene opens: %s" % scene_path)

func test_quest_select_targets_open() -> void:
	print("\n[TEST] QuestSelect transition targets")
	for scene_path in QUESTSELECT_TARGET_SCENES:
		_assert_scene_openable(scene_path, "QuestSelect target opens: %s" % scene_path)

func _assert_scene_openable(scene_path: String, message: String) -> void:
	var packed: PackedScene = load(scene_path) as PackedScene
	assert_true(packed != null, "%s (scene resource exists)" % message)
	if packed == null:
		return

	var instance: Node = packed.instantiate()
	assert_true(instance != null, "%s (instantiated)" % message)
	if instance == null:
		return

	instance.free()

func assert_true(condition: bool, message: String = "") -> void:
	if condition:
		test_results["passed"] += 1
		print("  [OK] %s" % message)
	else:
		test_results["failed"] += 1
		print("  [FAIL] %s" % message)

func print_results() -> void:
	var total: int = int(test_results.get("passed", 0)) + int(test_results.get("failed", 0))
	var pass_rate: float = (float(test_results["passed"]) / float(total) * 100.0) if total > 0 else 0.0

	print("\n[SCENE SMOKE SUMMARY]")
	print("Passed: %d" % int(test_results.get("passed", 0)))
	print("Failed: %d" % int(test_results.get("failed", 0)))
	print("Pass rate: %.1f%%" % pass_rate)

func get_test_results() -> Dictionary:
	return test_results.duplicate(true)
