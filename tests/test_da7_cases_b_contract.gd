extends Node

class_name TestDA7CasesBContract

const CasesModuleB := preload("res://scripts/case_07/da7_cases_b.gd")

var test_results: Dictionary = {
	"passed": 0,
	"failed": 0,
	"skipped": 0
}

func _ready() -> void:
	run_all_tests()
	print_results()

func run_all_tests() -> void:
	test_legacy_relationship_case_is_valid()
	test_multi_cable_relationship_case_is_valid()
	test_invalid_required_fk_is_rejected()
	test_invalid_required_pk_is_rejected()
	test_decoy_overlap_is_rejected()
	test_duplicate_required_pair_is_rejected()

func test_legacy_relationship_case_is_valid() -> void:
	var case_data := _find_case("DA7-B2-R1")
	assert_true(not case_data.is_empty(), "Legacy DA7-B2-R1 case exists")
	assert_true(CasesModuleB.validate_case_b(case_data), "Legacy relationship case remains valid")

func test_multi_cable_relationship_case_is_valid() -> void:
	var case_data := _find_case("DA7-B2-R3")
	assert_true(not case_data.is_empty(), "Multi-cable DA7-B2-R3 case exists")
	assert_true(CasesModuleB.validate_case_b(case_data), "Multi-cable relationship case is valid")

func test_invalid_required_fk_is_rejected() -> void:
	var case_data := _find_case("DA7-B2-R3")
	case_data["required_connections"] = [
		{"pk_col_id": "u_id", "fk_col_id": "missing_fk"}
	]
	assert_true(not CasesModuleB.validate_case_b(case_data), "Unknown FK in required_connections is rejected")

func test_invalid_required_pk_is_rejected() -> void:
	var case_data := _find_case("DA7-B2-R3")
	case_data["required_connections"] = [
		{"pk_col_id": "missing_pk", "fk_col_id": "p_uid"}
	]
	assert_true(not CasesModuleB.validate_case_b(case_data), "Unknown PK in required_connections is rejected")

func test_decoy_overlap_is_rejected() -> void:
	var case_data := _find_case("DA7-B2-R3")
	case_data["decoy_fk_col_ids"] = ["p_uid"]
	assert_true(not CasesModuleB.validate_case_b(case_data), "Decoy FK cannot overlap required FK")

func test_duplicate_required_pair_is_rejected() -> void:
	var case_data := _find_case("DA7-B2-R3")
	case_data["required_connections"] = [
		{"pk_col_id": "u_id", "fk_col_id": "p_uid"},
		{"pk_col_id": "u_id", "fk_col_id": "p_uid"}
	]
	assert_true(not CasesModuleB.validate_case_b(case_data), "Duplicate required pair is rejected")

func _find_case(case_id: String) -> Dictionary:
	for case_v in CasesModuleB.CASES_B:
		if typeof(case_v) != TYPE_DICTIONARY:
			continue
		var case_data: Dictionary = (case_v as Dictionary).duplicate(true)
		if str(case_data.get("id", "")) == case_id:
			return case_data
	return {}

func assert_true(condition: bool, message: String) -> void:
	if condition:
		test_results["passed"] += 1
	else:
		test_results["failed"] += 1
		print("FAILED: %s" % message)

func print_results() -> void:
	print("[DA7 B CONTRACT TESTS] passed=%d failed=%d" % [int(test_results.get("passed", 0)), int(test_results.get("failed", 0))])

func get_test_results() -> Dictionary:
	return test_results.duplicate(true)
