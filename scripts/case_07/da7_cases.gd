extends Node

const CasesA = preload("res://scripts/case_07/da7_cases_a.gd")
const CasesB = preload("res://scripts/case_07/da7_cases_b.gd")

static func get_cases(level: String) -> Array:
	match level.to_upper():
		"A":
			return CasesA.CASES_A.duplicate(true)
		"B":
			return CasesB.CASES_B.duplicate(true)
	return []
