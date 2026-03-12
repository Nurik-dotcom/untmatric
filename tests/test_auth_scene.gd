extends Node

class_name TestAuthScene

const AUTH_SCENE := preload("res://scenes/Auth.tscn")

var test_results: Dictionary = {
	"passed": 0,
	"failed": 0,
	"skipped": 0
}

var _auth_scene

func _ready() -> void:
	_auth_scene = AUTH_SCENE.instantiate()
	add_child(_auth_scene)
	run_all_tests()
	if is_instance_valid(_auth_scene):
		_auth_scene.queue_free()
	print_results()

func run_all_tests() -> void:
	test_login_empty_credentials_shows_input_required()
	test_register_empty_credentials_shows_input_required()
	test_auth_finished_error_shows_message_and_reenables_input()

func test_login_empty_credentials_shows_input_required() -> void:
	_auth_scene.email_input.text = ""
	_auth_scene.password_input.text = ""
	_auth_scene.error_label.text = ""

	_auth_scene._on_login_button_pressed()

	assert_equal(_auth_scene.error_label.text, "ERROR: INPUT_REQUIRED", "Login with empty credentials shows INPUT_REQUIRED")

func test_register_empty_credentials_shows_input_required() -> void:
	_auth_scene.email_input.text = ""
	_auth_scene.password_input.text = ""
	_auth_scene.error_label.text = ""

	_auth_scene._on_register_button_pressed()

	assert_equal(_auth_scene.error_label.text, "ERROR: INPUT_REQUIRED", "Register with empty credentials shows INPUT_REQUIRED")

func test_auth_finished_error_shows_message_and_reenables_input() -> void:
	_auth_scene.set_process_input(false)
	_auth_scene.error_label.text = ""

	_auth_scene._on_auth_finished(false, "INVALID_PASSWORD")

	assert_equal(_auth_scene.error_label.text, "ERROR: INVALID_PASSWORD", "Auth error text is displayed")
	assert_true(_auth_scene.is_processing_input(), "Input processing is enabled after auth callback")

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
	print("[AUTH SCENE TESTS] passed=%d failed=%d" % [int(test_results.get("passed", 0)), int(test_results.get("failed", 0))])

func get_test_results() -> Dictionary:
	return test_results.duplicate(true)
