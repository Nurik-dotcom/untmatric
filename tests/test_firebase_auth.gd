extends Node

class_name TestFirebaseAuth

const FIREBASE_AUTH_SCRIPT := preload("res://scripts/FirebaseAuth.gd")

var test_results: Dictionary = {
    "passed": 0,
    "failed": 0,
    "skipped": 0
}

var _auth
var _signal_emitted := false
var _signal_success: bool = false
var _signal_result: Variant = null

func _ready() -> void:
    _auth = FIREBASE_AUTH_SCRIPT.new()
    add_child(_auth)
    if not _auth.auth_finished.is_connected(_on_auth_finished_captured):
        _auth.auth_finished.connect(_on_auth_finished_captured)

    run_all_tests()

    if _auth.auth_finished.is_connected(_on_auth_finished_captured):
        _auth.auth_finished.disconnect(_on_auth_finished_captured)
    if is_instance_valid(_auth):
        _auth.queue_free()
    print_results()

func run_all_tests() -> void:
    test_success_response_emits_true_with_dictionary()
    test_success_response_populates_global_metrics_identity_fields()
    test_error_response_emits_firebase_error_message()
    test_invalid_json_body_uses_fallback_error_message()
    test_empty_json_body_uses_fallback_error_message()
    test_malformed_error_payload_uses_fallback_error_message()

func test_success_response_emits_true_with_dictionary() -> void:
    _reset_global_metrics_state()
    _reset_signal_capture()

    _invoke_request_completed(200, '{"localId":"uid_001","email":"agent007@enu.kz"}')

    assert_true(_signal_emitted, "auth_finished signal emitted on success")
    assert_true(_signal_success, "auth_finished success flag is true")
    assert_true(typeof(_signal_result) == TYPE_DICTIONARY, "auth_finished result is Dictionary")
    var result_dict: Dictionary = _signal_result if typeof(_signal_result) == TYPE_DICTIONARY else {}
    assert_equal(str(result_dict.get("localId", "")), "uid_001", "Signal payload contains localId")

func test_success_response_populates_global_metrics_identity_fields() -> void:
    _reset_global_metrics_state()
    _reset_signal_capture()

    _invoke_request_completed(200, '{"localId":"uid_777","email":"captain@unit.test"}')

    assert_equal(GlobalMetrics.user_id, "uid_777", "GlobalMetrics.user_id updated from successful auth")
    assert_equal(GlobalMetrics.user_nickname, "captain", "GlobalMetrics.user_nickname derived from email")
    assert_equal(GlobalMetrics.user_email, "captain@unit.test", "GlobalMetrics.user_email set from response")

func test_error_response_emits_firebase_error_message() -> void:
    _reset_global_metrics_state()
    _reset_signal_capture()

    _invoke_request_completed(400, '{"error":{"message":"INVALID_PASSWORD"}}')

    assert_true(_signal_emitted, "auth_finished signal emitted on failed auth")
    assert_false(_signal_success, "auth_finished success flag is false on error")
    assert_equal(str(_signal_result), "INVALID_PASSWORD", "Firebase error message is propagated")

func test_invalid_json_body_uses_fallback_error_message() -> void:
    _reset_signal_capture()

    _invoke_request_completed(500, '{invalid-json')

    assert_true(_signal_emitted, "auth_finished signal emitted for invalid JSON body")
    assert_false(_signal_success, "invalid JSON body returns failed auth")
    assert_equal(str(_signal_result), "AUTH_REQUEST_FAILED_500", "Invalid JSON body uses fallback message")

func test_empty_json_body_uses_fallback_error_message() -> void:
    _reset_signal_capture()

    _invoke_request_completed(401, "")

    assert_true(_signal_emitted, "auth_finished signal emitted for empty body")
    assert_false(_signal_success, "empty body returns failed auth")
    assert_equal(str(_signal_result), "AUTH_REQUEST_FAILED_401", "Empty JSON body uses fallback message")

func test_malformed_error_payload_uses_fallback_error_message() -> void:
    _reset_signal_capture()

    _invoke_request_completed(403, '{"error":{"code":403}}')

    assert_true(_signal_emitted, "auth_finished signal emitted for malformed error payload")
    assert_false(_signal_success, "malformed error payload returns failed auth")
    assert_equal(str(_signal_result), "AUTH_REQUEST_FAILED_403", "Malformed error payload uses fallback message")

func _invoke_request_completed(response_code: int, body_text: String) -> void:
    var http_node := Node.new()
    add_child(http_node)
    var body: PackedByteArray = body_text.to_utf8_buffer()
    _auth._on_request_completed(0, response_code, [], body, http_node, false)

func _reset_signal_capture() -> void:
    _signal_emitted = false
    _signal_success = false
    _signal_result = null

func _reset_global_metrics_state() -> void:
    GlobalMetrics.user_id = ""
    GlobalMetrics.user_nickname = ""
    GlobalMetrics.user_email = ""

func _on_auth_finished_captured(success: bool, result: Variant) -> void:
    _signal_emitted = true
    _signal_success = success
    _signal_result = result

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

func assert_false(condition: bool, message: String) -> void:
    if not condition:
        test_results["passed"] += 1
    else:
        test_results["failed"] += 1
        print("FAILED: %s" % message)

func print_results() -> void:
    print("[FIREBASE AUTH TESTS] passed=%d failed=%d" % [int(test_results.get("passed", 0)), int(test_results.get("failed", 0))])

func get_test_results() -> Dictionary:
    return test_results.duplicate(true)