extends SceneTree

func _init():
	print("Starting Case 7 Verification...")

	var CasesModule = load("res://scripts/case_07/da7_cases_a.gd")
	if not CasesModule:
		printerr("FAIL: Could not load da7_cases_a.gd")
		quit(1)
		return

	print("Loaded Cases Module. Version: ", CasesModule.SCHEMA_VERSION)

	var cases = CasesModule.CASES_A
	if cases.size() < 8:
		printerr("FAIL: Expected at least 8 cases, found ", cases.size())
		quit(1)
		return

	print("Found ", cases.size(), " cases.")

	var errors = 0
	for i in range(cases.size()):
		var c = cases[i]
		if not CasesModule.validate_case(c):
			printerr("FAIL: Case invalid: ", c.get("id", "UNKNOWN"))
			errors += 1
		else:
			print("Case OK: ", c.id)

	if errors > 0:
		printerr("FAIL: ", errors, " cases failed validation.")
		quit(1)
	else:
		print("ALL CASES VALID.")
		print("VERIFICATION SUCCESS")
		quit(0)
