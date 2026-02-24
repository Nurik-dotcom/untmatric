extends RefCounted
class_name NetworkTraceErrors

const A_WRONG_EVIDENCE := "A_WRONG_EVIDENCE"
const A_L1_BROADCAST := "A_L1_BROADCAST"
const A_L2_SEGMENT_LIMIT := "A_L2_SEGMENT_LIMIT"
const A_L1_PHYSICAL := "A_L1_PHYSICAL"
const A_PASSIVE := "A_PASSIVE"
const A_L3_OVERKILL := "A_L3_OVERKILL"
const A_L2_BRIDGE_LIMIT := "A_L2_BRIDGE_LIMIT"

const B_MATH_X8 := "B_MATH_X8"
const B_MATH_1024 := "B_MATH_1024"
const B_MATH_DIV := "B_MATH_DIV"
const B_UNIT_TRAP := "B_UNIT_TRAP"
const B_PIPELINE_INCOMPLETE := "B_PIPELINE_INCOMPLETE"
const B_PIPELINE_BAD_DROP := "B_PIPELINE_BAD_DROP"
const B_PIPELINE_MISMATCH := "B_PIPELINE_MISMATCH"
const B_SPAM_TRACE := "B_SPAM_TRACE"
const B_GARBAGE := "B_GARBAGE"

const C_NOT_APPLIED := "C_NOT_APPLIED"
const C_MASK_VAL := "C_MASK_VAL"
const C_L24_FALLBACK := "C_L24_FALLBACK"
const C_BOUNDARY_SHIFT := "C_BOUNDARY_SHIFT"
const C_BROADCAST := "C_BROADCAST"
const C_MASK_INVALID := "C_MASK_INVALID"
const C_BAD_STEP := "C_BAD_STEP"
const C_BAD_DROP := "C_BAD_DROP"
const C_IP_VAL := "C_IP_VAL"

const TIMEOUT := "TIMEOUT"
const UNKNOWN := "UNKNOWN"

const TITLES: Dictionary = {
	A_WRONG_EVIDENCE: "Insufficient Evidence",
	A_L1_BROADCAST: "Layer 1 Broadcast Fault",
	A_L2_SEGMENT_LIMIT: "Layer 2 Limitation",
	A_L1_PHYSICAL: "Physical Link Fault",
	A_PASSIVE: "Passive Component",
	A_L3_OVERKILL: "Overengineered Layer 3",
	A_L2_BRIDGE_LIMIT: "Bridge Limitation",
	B_MATH_X8: "Byte-to-Bit Error",
	B_MATH_1024: "1024 Conversion Error",
	B_MATH_DIV: "Missing Time Division",
	B_UNIT_TRAP: "Unit Mismatch",
	B_PIPELINE_INCOMPLETE: "Pipeline Incomplete",
	B_PIPELINE_BAD_DROP: "Module in Wrong Slot",
	B_PIPELINE_MISMATCH: "Pipeline Mismatch",
	B_SPAM_TRACE: "Command Spam",
	B_GARBAGE: "Irrelevant Value",
	C_NOT_APPLIED: "AND Not Applied",
	C_MASK_VAL: "Mask Value Confusion",
	C_L24_FALLBACK: "Reflex /24 Guess",
	C_BOUNDARY_SHIFT: "Boundary Shift",
	C_BROADCAST: "Broadcast Address",
	C_MASK_INVALID: "Invalid Mask Pattern",
	C_BAD_STEP: "Wrong Segment Step",
	C_BAD_DROP: "Mask Not Placed",
	C_IP_VAL: "IP Value Instead of Network ID",
	TIMEOUT: "Timeout",
	UNKNOWN: "Unknown Error"
}

const SHORT_MESSAGES: Dictionary = {
	"": "",
	A_WRONG_EVIDENCE: "Collect at least two clues before running trace.",
	A_L1_BROADCAST: "Hub floods traffic and cannot isolate collisions.",
	A_L2_SEGMENT_LIMIT: "Layer 2 devices do not route between subnets.",
	A_L1_PHYSICAL: "This fixes signal only, not packet forwarding logic.",
	A_PASSIVE: "Passive hardware cannot make forwarding decisions.",
	A_L3_OVERKILL: "Router works, but the clue set points to a simpler fix.",
	A_L2_BRIDGE_LIMIT: "Bridge still works inside one broadcast domain.",
	B_MATH_X8: "Bytes must be converted to bits using x8.",
	B_MATH_1024: "Use 1024 for KB/MB conversion in this task.",
	B_MATH_DIV: "Throughput requires division by time.",
	B_UNIT_TRAP: "Output unit does not match the requested unit.",
	B_PIPELINE_INCOMPLETE: "Fill all four pipeline slots, then run calculation.",
	B_PIPELINE_BAD_DROP: "That module type cannot be placed in this slot.",
	B_PIPELINE_MISMATCH: "Chosen answer does not match assembled pipeline behavior.",
	B_SPAM_TRACE: "Repeated spam clicks detected.",
	B_GARBAGE: "Selected value is unrelated to calculated throughput.",
	C_NOT_APPLIED: "Run APPLY AND before selecting Network ID.",
	C_MASK_VAL: "Mask value is not the network ID.",
	C_L24_FALLBACK: "Default /24 guess does not match current CIDR.",
	C_BOUNDARY_SHIFT: "Choose the segment boundary, not the nearest number.",
	C_BROADCAST: "Broadcast address is not the network ID.",
	C_MASK_INVALID: "Mask must be contiguous: 111...000...",
	C_BAD_STEP: "Segment step is incorrect for this CIDR.",
	C_BAD_DROP: "Place the mask in the mask target area first.",
	C_IP_VAL: "That is host IP value, not Network ID.",
	TIMEOUT: "Time limit expired.",
	UNKNOWN: "Check conversion steps and unit target."
}

const DETAIL_MESSAGES: Dictionary = {
	A_L1_BROADCAST: [
		"Broadcast storms and collision spikes indicate hub misuse.",
		"Switching or routing is required to isolate traffic."
	],
	A_L2_SEGMENT_LIMIT: [
		"Switch and bridge forward frames inside one L2 domain.",
		"Inter-subnet connectivity requires a router."
	],
	B_MATH_X8: [
		"Formula: bits = bytes x 8.",
		"Skipping x8 returns byte rate, not bit rate."
	],
	B_MATH_1024: [
		"Use binary conversion for KB/MB in this challenge.",
		"KB = 1024 bytes, MB = 1024 x 1024 bytes."
	],
	B_UNIT_TRAP: [
		"Check prompt unit before confirming.",
		"If ask_unit is kbps, convert bps / 1000."
	],
	C_MASK_VAL: [
		"Network ID is IP_last AND mask_last.",
		"Mask itself is only a filter, not a final answer."
	],
	C_BOUNDARY_SHIFT: [
		"Step = 256 - mask_last.",
		"Network boundary is the floor multiple of step."
	],
	UNKNOWN: [
		"Re-check every conversion stage.",
		"Verify that selected option matches the computed result."
	]
}

static func short_message(code: String) -> String:
	var normalized: String = code.strip_edges()
	if SHORT_MESSAGES.has(normalized):
		return str(SHORT_MESSAGES[normalized])
	return str(SHORT_MESSAGES[UNKNOWN])

static func get_error_title(code: String) -> String:
	var normalized: String = code.strip_edges()
	if TITLES.has(normalized):
		return str(TITLES[normalized])
	return str(TITLES[UNKNOWN])

static func get_error_tip(code: String) -> String:
	return short_message(code)

static func detail_messages(code: String) -> Array[String]:
	var normalized: String = code.strip_edges()
	var source_variant: Variant = DETAIL_MESSAGES.get(normalized, DETAIL_MESSAGES.get(UNKNOWN, []))
	var source: Array = []
	if typeof(source_variant) == TYPE_ARRAY:
		source = source_variant
	var result: Array[String] = []
	for line_var in source:
		result.append(str(line_var))
	return result
