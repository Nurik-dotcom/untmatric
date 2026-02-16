extends RefCounted
class_name NetworkTraceErrors

const SHORT_MESSAGES: Dictionary = {
	"": "",
	"A_WRONG_EVIDENCE": "Collect enough evidence before deployment.",
	"A_L1_BROADCAST": "Hub floods every port. Segment stays noisy.",
	"A_L2_SEGMENT_LIMIT": "Switch cannot route between subnets.",
	"A_L1_PHYSICAL": "Repeater only amplifies signal.",
	"A_PASSIVE": "Patch panel is passive wiring.",
	"B_MATH_X8": "Bytes were not converted to bits.",
	"B_MATH_1024": "Binary multiplier 1024 was missed.",
	"B_MATH_DIV": "Transfer rate must divide by time.",
	"B_UNIT_TRAP": "Requested unit is bit/s, not kbit/s.",
	"B_PIPELINE_INCOMPLETE": "Build and run pipeline before final answer.",
	"B_PIPELINE_BAD_DROP": "Module does not match this slot type.",
	"B_PIPELINE_MISMATCH": "Answer selected with incorrect pipeline.",
	"B_SPAM_TRACE": "Trace command spam detected.",
	"B_GARBAGE": "Result does not match the transfer model.",
	"C_MASK_VAL": "Mask value is not a network address.",
	"C_L24_FALLBACK": "Automatic /24 fallback is wrong here.",
	"C_BOUNDARY_SHIFT": "Subnet boundary was shifted.",
	"C_BROADCAST": "Broadcast address was selected.",
	"TIMEOUT": "Time limit reached.",
	"UNKNOWN": "Wrong option for this context."
}

const DETAIL_MESSAGES: Dictionary = {
	"A_WRONG_EVIDENCE": [
		"Evidence gating prevents blind guessing.",
		"Select the required log clues first."
	],
	"A_L1_BROADCAST": [
		"Hub sends frame copies to all ports.",
		"Use switch for L2 segmentation or router for subnet routing."
	],
	"A_L2_SEGMENT_LIMIT": [
		"Switch forwards by MAC inside one broadcast domain.",
		"Inter-subnet traffic needs router or L3 switch."
	],
	"A_L1_PHYSICAL": [
		"Repeater restores signal power only.",
		"It does not inspect addresses or enforce policy."
	],
	"A_PASSIVE": [
		"Patch panel is a cable termination point.",
		"It cannot filter or route traffic."
	],
	"B_MATH_X8": [
		"Rate formula is bits/time.",
		"Convert bytes to bits by multiplying by 8 first."
	],
	"B_MATH_1024": [
		"Binary storage units use 1024.",
		"Use KiB and MiB factors when task expects binary conversion."
	],
	"B_MATH_DIV": [
		"Throughput is total bits divided by transfer seconds.",
		"Missing division overstates the result."
	],
	"B_UNIT_TRAP": [
		"Answer must match requested unit exactly.",
		"If asked in bit/s, avoid kbit/s shorthand."
	],
	"B_PIPELINE_INCOMPLETE": [
		"The answer panel unlocks only after RUN CALC.",
		"Select base, byte-bit step, and time division first."
	],
	"B_PIPELINE_BAD_DROP": [
		"Each slot accepts only one module category.",
		"Match module slot_type with connector label."
	],
	"B_PIPELINE_MISMATCH": [
		"Final answer can be guessed even with wrong assembly.",
		"Review pipeline stages to avoid unit and formula drift."
	],
	"B_SPAM_TRACE": [
		"Repeated rapid clicks reduce reliability.",
		"Wait for cooldown before running trace again."
	],
	"B_GARBAGE": [
		"Chosen number does not follow conversion pipeline.",
		"Re-check each operation before selecting final answer."
	],
	"C_MASK_VAL": [
		"Mask itself is not the network id.",
		"Compute network as IP AND mask."
	],
	"C_L24_FALLBACK": [
		"Only /24 masks end with .0 boundaries by default.",
		"For other masks use actual block size."
	],
	"C_BOUNDARY_SHIFT": [
		"Find block size from last non-255 octet.",
		"Network id is the nearest lower block boundary."
	],
	"C_BROADCAST": [
		"Broadcast is the upper boundary of subnet.",
		"Network id is the lower boundary."
	],
	"TIMEOUT": [
		"Timed mode reached its limit.",
		"Use quick unit conversion and boundary checks."
	],
	"UNKNOWN": [
		"Option did not satisfy prompt constraints.",
		"Review context and pick one deterministic match."
	]
}

const TITLES: Dictionary = {
	"A_WRONG_EVIDENCE": "EVIDENCE REQUIRED",
	"A_L1_BROADCAST": "BROADCAST STORM",
	"A_L2_SEGMENT_LIMIT": "L2 LIMITATION",
	"A_L1_PHYSICAL": "PHYSICAL LAYER ONLY",
	"A_PASSIVE": "PASSIVE COMPONENT",
	"B_MATH_X8": "BITS CONVERSION ERROR",
	"B_MATH_1024": "BINARY UNIT ERROR",
	"B_MATH_DIV": "RATE FORMULA ERROR",
	"B_UNIT_TRAP": "UNIT MISMATCH",
	"B_PIPELINE_INCOMPLETE": "PIPELINE INCOMPLETE",
	"B_PIPELINE_BAD_DROP": "BAD DROP TARGET",
	"B_PIPELINE_MISMATCH": "PIPELINE MISMATCH",
	"B_SPAM_TRACE": "TRACE SPAM",
	"B_GARBAGE": "INVALID RESULT",
	"C_MASK_VAL": "MASK CONFUSION",
	"C_L24_FALLBACK": "DEFAULT SUBNET TRAP",
	"C_BOUNDARY_SHIFT": "BOUNDARY SHIFT",
	"C_BROADCAST": "BROADCAST SELECTED",
	"TIMEOUT": "TIMEOUT",
	"UNKNOWN": "WRONG DECISION"
}

static func short_message(code: String) -> String:
	var normalized: String = code.strip_edges()
	if SHORT_MESSAGES.has(normalized):
		return str(SHORT_MESSAGES[normalized])
	return str(SHORT_MESSAGES["UNKNOWN"])

static func get_error_title(code: String) -> String:
	var normalized: String = code.strip_edges()
	if TITLES.has(normalized):
		return str(TITLES[normalized])
	return str(TITLES["UNKNOWN"])

static func get_error_tip(code: String) -> String:
	return short_message(code)

static func detail_messages(code: String) -> Array[String]:
	var normalized: String = code.strip_edges()
	var source: Array = []
	if DETAIL_MESSAGES.has(normalized):
		source = DETAIL_MESSAGES[normalized]
	else:
		source = DETAIL_MESSAGES["UNKNOWN"]
	var details: Array[String] = []
	for line_var in source:
		details.append(str(line_var))
	return details
