extends Node

class_name TestRadioI18nRuntime

var test_results: Dictionary = {
	"passed": 0,
	"failed": 0,
	"skipped": 0
}

var _initial_language: String = "ru"

func _ready() -> void:
	_initial_language = I18n.get_language()
	await run_all_tests()
	I18n.set_language(_initial_language)
	await _wait_frames(2)
	print_results()

func run_all_tests() -> void:
	await _test_scene_language_switch(
		"RadioQuestA",
		"res://scenes/RadioQuestA.tscn",
		"SafeArea/RootVBox/Header/HeaderHBox/TitleLabel",
		"SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/ActionsRow/BtnAnalyze",
		"SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/StatusLabel"
	)
	await _test_scene_language_switch(
		"RadioQuestB",
		"res://scenes/RadioQuestB.tscn",
		"SafeArea/RootVBox/Header/HeaderHBox/TitleLabel",
		"SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/ActionsRow/BtnConverter",
		"SafeArea/RootVBox/BodyHSplit/RightPane/RightMargin/RightVBox/StatusLabel"
	)
	await _test_scene_language_switch(
		"RadioQuestC",
		"res://scenes/RadioQuestC.tscn",
		"SafeArea/RootVBox/TopBar/TopBarHBox/TitleLabel",
		"SafeArea/RootVBox/BodyHSplit/LeftCol/KnobCard/KnobMargin/KnobVBox/BtnAnalyze",
		"SafeArea/RootVBox/BodyHSplit/LeftCol/StatusCard/StatusMargin/StatusLabel"
	)

func _test_scene_language_switch(scene_name: String, scene_path: String, title_path: String, button_path: String, status_path: String) -> void:
	var packed: PackedScene = load(scene_path) as PackedScene
	assert_true(packed != null, "%s scene loads" % scene_name)
	if packed == null:
		return

	var scene: Node = packed.instantiate()
	add_child(scene)
	await _wait_frames(2)

	var title_label: Label = scene.get_node_or_null(title_path) as Label
	var action_button: Button = scene.get_node_or_null(button_path) as Button
	var status_label: Label = scene.get_node_or_null(status_path) as Label
	assert_true(title_label != null, "%s title label exists" % scene_name)
	assert_true(action_button != null, "%s action button exists" % scene_name)
	assert_true(status_label != null, "%s status label exists" % scene_name)

	if title_label == null or action_button == null or status_label == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	I18n.set_language("ru")
	await _wait_frames(2)
	var ru_title: String = title_label.text
	var ru_button: String = action_button.text
	var ru_status: String = status_label.text
	assert_true(not ru_title.strip_edges().is_empty(), "%s RU title is not empty" % scene_name)
	assert_true(not ru_button.strip_edges().is_empty(), "%s RU button is not empty" % scene_name)
	assert_true(not ru_status.strip_edges().is_empty(), "%s RU status is not empty" % scene_name)

	I18n.set_language("en")
	await _wait_frames(2)
	var en_title: String = title_label.text
	var en_button: String = action_button.text
	var en_status: String = status_label.text
	assert_true(not en_title.strip_edges().is_empty(), "%s EN title is not empty" % scene_name)
	assert_true(not en_button.strip_edges().is_empty(), "%s EN button is not empty" % scene_name)
	assert_true(not en_status.strip_edges().is_empty(), "%s EN status is not empty" % scene_name)
	assert_true(en_title != ru_title, "%s title updates on RU -> EN" % scene_name)
	assert_true(en_button != ru_button, "%s button updates on RU -> EN" % scene_name)
	assert_true(en_status != ru_status, "%s status updates on RU -> EN" % scene_name)

	I18n.set_language("kk")
	await _wait_frames(2)
	var kk_title: String = title_label.text
	var kk_button: String = action_button.text
	var kk_status: String = status_label.text
	assert_true(not kk_title.strip_edges().is_empty(), "%s KK title is not empty" % scene_name)
	assert_true(not kk_button.strip_edges().is_empty(), "%s KK button is not empty" % scene_name)
	assert_true(not kk_status.strip_edges().is_empty(), "%s KK status is not empty" % scene_name)
	assert_true(kk_title != ru_title, "%s title updates on RU -> KK" % scene_name)
	assert_true(kk_button != ru_button, "%s button updates on RU -> KK" % scene_name)
	assert_true(kk_status != ru_status, "%s status updates on RU -> KK" % scene_name)

	scene.queue_free()
	await _wait_frames(2)

func _wait_frames(count: int = 1) -> void:
	for _idx in range(count):
		await get_tree().process_frame

func assert_true(condition: bool, message: String) -> void:
	if condition:
		test_results["passed"] += 1
	else:
		test_results["failed"] += 1
		print("FAILED: %s" % message)

func print_results() -> void:
	print("[RADIO I18N RUNTIME TESTS] passed=%d failed=%d" % [int(test_results.get("passed", 0)), int(test_results.get("failed", 0))])

func get_test_results() -> Dictionary:
	return test_results.duplicate(true)
