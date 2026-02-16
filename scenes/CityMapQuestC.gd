extends Control

# SSoT Data
var level_data: Dictionary = {}
var adjacency: Dictionary = {} # source -> {target: edge_data}
var min_sum: int = 0
var input_regex: RegEx
var config_hash: String = ""

# State
var current_node: String = ""
var path: Array = []
var trust: float = 100.0
var real_time_sec: int = 0
var sim_time_sec: int = 0
var is_game_over: bool = false
var first_attempt_edge: Variant = null # String or null

# C-Level Metrics
var planning_time_ms: int = 0
var start_time_ms: int = 0
var dynamic_weight_awareness: bool = true # Assume true until proven false
var violations: Dictionary = {
	"xor": 0,
	"blacklist_attempts": 0,
	"closed_edge_attempts": 0,
	"must_visit_missing_submits": 0
}
var ambush_triggered: bool = false

# Counters
var n_calc: int = 0
var n_opt: int = 0
var n_parse: int = 0
var n_reset: int = 0
var n_logic: int = 0

# UI References
@onready var edges_layer = $MainLayout/HBox/GraphPanel/GraphContainer/EdgesLayer
@onready var nodes_layer = $MainLayout/HBox/GraphPanel/GraphContainer/NodesLayer
@onready var path_display = $MainLayout/Footer/PathDisplay
@onready var sum_input = $MainLayout/Footer/InputRow/SumInput
@onready var status_label = $MainLayout/Footer/StatusLabel
@onready var trust_label = $MainLayout/Header/TrustLabel
@onready var real_time_label = $MainLayout/Header/RealTimeLabel
@onready var sim_time_label = $MainLayout/Header/SimTimeLabel
@onready var schedule_list = $MainLayout/HBox/SchedulePanel/Scroll/ScheduleList
@onready var btn_back = $MainLayout/Header/BtnBack
@onready var btn_reset = $MainLayout/Footer/InputRow/BtnReset
@onready var btn_submit = $MainLayout/Footer/InputRow/BtnSubmit

# Helpers
var node_buttons: Dictionary = {} # id -> Button
var edge_lines: Dictionary = {} # "from->to" -> Line2D
var edge_labels: Dictionary = {} # "from->to" -> Label

func _ready():
	start_time_ms = Time.get_ticks_msec()
	btn_back.pressed.connect(_on_back_pressed)
	btn_reset.pressed.connect(_on_reset_pressed)
	btn_submit.pressed.connect(_on_submit_pressed)
	sum_input.text_changed.connect(_on_sum_input_changed)
	sum_input.placeholder_text = "Enter integer sum"

	_load_level_data("res://data/city_map/level_6_3.json")
	_calculate_optimal_path_dynamic()
	_build_graph_ui()
	_build_schedule_ui()
	_setup_deterministic_timer()
	_reset_game_state()

func _setup_deterministic_timer():
	var timer = Timer.new()
	timer.name = "ResearchTimer"
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_on_timer_tick)
	add_child(timer)

func _on_timer_tick():
	if is_game_over: return
	real_time_sec += 1
	_update_real_time_display()
	# Check overtime penalty dynamically
	if real_time_sec > level_data.time_limit_sec:
		_update_trust()

func _notification(what):
	if has_node("ResearchTimer"):
		if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			get_node("ResearchTimer").paused = true
		elif what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
			get_node("ResearchTimer").paused = false

func _load_level_data(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Failed to load level data: " + path)
		return

	var content = file.get_as_text()
	config_hash = content.sha256_text()

	var json = JSON.new()
	var error = json.parse(content)
	if error == OK:
		level_data = json.data
	else:
		push_error("JSON Parse Error: " + json.get_error_message())

	# Compile Regex
	input_regex = RegEx.new()
	if level_data.has("rules") and level_data.rules.has("input_regex"):
		input_regex.compile(level_data.rules.input_regex)
	else:
		input_regex.compile("^[0-9]+$")

	# Build adjacency list
	# For complexity C, we store the full edge object to access schedules
	for edge in level_data.edges:
		if not adjacency.has(edge.from):
			adjacency[edge.from] = {}
		adjacency[edge.from][edge.to] = edge

func _get_current_edge_weight(edge_data: Dictionary, time: int) -> Dictionary:
	# Returns {w: int, state: "open"|"closed"}
	var result = { "w": edge_data.w, "state": "open" }

	if edge_data.has("schedule"):
		for period in edge_data.schedule:
			if time >= period.t_from and time < period.t_to:
				result.w = period.w
				result.state = period.get("state", "open")
				break

	return result

func _calculate_optimal_path_dynamic():
	# A* / Dijkstra with State = (node, time)
	# Target: reach end_node satisfying constraints with min accumulated weight

	var start_node = level_data.start_node
	var end_node = level_data.end_node

	# Priority Queue: [cost, time, current_node, visited_mask_must, visited_mask_blacklist, visited_xor]
	# Simplified: We implement a basic Dijkstra on (Node, Time) state space
	# Note: This can get complex. We'll implement a reasonable approximation
	# assuming time only moves forward and weights are non-negative.

	# Since full state search is heavy, and we need reference for 'OPTIMAL',
	# we will try to find the best path that satisfies ALL constraints.

	# State: node_id -> min_weight_at_arrival
	# But weight depends on arrival time.
	# Let's limit search depth or time? No, level is small (12 nodes).
	# Use a list of active paths: {node, current_sim_time, path_history}

	var queue = [] # Array of paths
	queue.append({
		"node": start_node,
		"sim_time": 0,
		"path": [start_node],
		"cost": 0,
		"visited": {start_node: true}
	})

	var best_solution = 999999
	var visited_states = {} # "node_id:sim_time" -> cost

	var iterations = 0
	while queue.size() > 0 and iterations < 5000:
		iterations += 1
		# Pop lowest cost (simple linear scan for simplicity in GDScript prototype)
		var best_idx = 0
		for i in range(1, queue.size()):
			if queue[i].cost < queue[best_idx].cost:
				best_idx = i
		var current = queue.pop_at(best_idx)

		# Pruning
		if current.cost >= best_solution:
			continue

		var u = current.node

		# Check Completion
		if u == end_node:
			# Verify Constraints
			if _check_constraints_strict(current.path):
				if current.cost < best_solution:
					best_solution = current.cost
			continue

		# Expand
		if adjacency.has(u):
			for v in adjacency[u]:
				var edge = adjacency[u][v]
				var w_info = _get_current_edge_weight(edge, current.sim_time)

				if w_info.state == "closed":
					continue

				# Check Blacklist immediately for pruning (optional, strict)
				if level_data.constraints.has("blacklist_nodes") and v in level_data.constraints.blacklist_nodes:
					continue # Don't go to blacklist in optimal search

				var new_cost = current.cost + w_info.w
				var new_time = current.sim_time + w_info.w

				# Check XOR violation (simple check)
				if _is_xor_violation(current.path + [v]):
					continue

				# Visited State Check (Pruning cyclic or worse paths)
				# Only prune if we arrived at same node at same time with worse cost
				var state_key = "%s:%d" % [v, new_time]
				if visited_states.has(state_key) and visited_states[state_key] <= new_cost:
					continue
				visited_states[state_key] = new_cost

				var new_path_obj = {
					"node": v,
					"sim_time": new_time,
					"path": current.path + [v],
					"cost": new_cost,
					"visited": current.visited.duplicate()
				}
				new_path_obj.visited[v] = true
				queue.append(new_path_obj)

	min_sum = best_solution if best_solution < 999999 else 0

func _check_constraints_strict(p_path: Array) -> bool:
	# Must Visit
	if level_data.constraints.has("must_visit"):
		for m in level_data.constraints.must_visit:
			if not p_path.has(m):
				return false

	# Blacklist
	if level_data.constraints.has("blacklist_nodes"):
		for b in level_data.constraints.blacklist_nodes:
			if p_path.has(b):
				return false

	# XOR
	if _is_xor_violation(p_path):
		return false

	return true

func _is_xor_violation(p_path: Array) -> bool:
	if level_data.constraints.has("xor_groups"):
		for group in level_data.constraints.xor_groups:
			if group.type == "AT_MOST_ONE":
				var count = 0
				for n in group.nodes:
					if p_path.has(n):
						count += 1
				if count > 1:
					return true
	return false

func _build_graph_ui():
	# Nodes & Edges
	for child in nodes_layer.get_children(): child.queue_free()
	for child in edges_layer.get_children(): child.queue_free()
	node_buttons.clear()
	edge_lines.clear()
	edge_labels.clear()

	for edge in level_data.edges:
		var from_node = _get_node_data(edge.from)
		var to_node = _get_node_data(edge.to)

		if from_node and to_node:
			var start_pos = Vector2(from_node.pos.x, from_node.pos.y)
			var end_pos = Vector2(to_node.pos.x, to_node.pos.y)

			var line = Line2D.new()
			line.points = [start_pos, end_pos]
			line.width = 4.0
			line.default_color = Color(0.4, 0.4, 0.4)
			edges_layer.add_child(line)
			edge_lines[edge.id] = line

			# Arrow
			var dir = (end_pos - start_pos).normalized()
			_draw_arrow(end_pos, dir, edges_layer)

			# Label
			var mid = (start_pos + end_pos) / 2
			var lbl = Label.new()
			lbl.text = str(edge.w)
			lbl.position = mid + Vector2(0, -15)
			lbl.add_theme_color_override("font_color", Color.WHITE)
			edges_layer.add_child(lbl)
			edge_labels[edge.id] = lbl

	for node_def in level_data.nodes:
		var btn = Button.new()
		btn.text = node_def.label
		btn.position = Vector2(node_def.pos.x, node_def.pos.y) - Vector2(25, 25)
		btn.size = Vector2(50, 50)
		btn.pressed.connect(_on_node_pressed.bind(node_def.id))
		nodes_layer.add_child(btn)
		node_buttons[node_def.id] = btn

func _build_schedule_ui():
	for child in schedule_list.get_children(): child.queue_free()

	# Find edges with schedules
	for edge in level_data.edges:
		if edge.has("schedule"):
			var row = HBoxContainer.new()
			var lbl = Label.new()
			var edge_name = "%s->%s" % [edge.from, edge.to]
			lbl.text = "%s: " % edge_name
			lbl.add_theme_color_override("font_color", Color.YELLOW)
			row.add_child(lbl)

			for sch in edge.schedule:
				var info = Label.new()
				var w_text = "CLOSED" if sch.get("state") == "closed" else str(sch.w)
				info.text = "[%d-%ds: %s] " % [sch.t_from, sch.t_to, w_text]
				info.add_theme_font_size_override("font_size", 12)
				row.add_child(info)

			schedule_list.add_child(row)

func _draw_arrow(pos: Vector2, dir: Vector2, parent: Node):
	var arrow_size = 15.0
	var arrow_pos = pos - (dir * 30.0)
	var polygon = Polygon2D.new()
	var p1 = arrow_pos + (dir * arrow_size)
	var p2 = arrow_pos + (dir.rotated(2.5) * arrow_size)
	var p3 = arrow_pos + (dir.rotated(-2.5) * arrow_size)
	polygon.polygon = [p1, p2, p3]
	polygon.color = Color(0.6, 0.6, 1.0, 1.0)
	parent.add_child(polygon)

func _get_node_data(id: String) -> Dictionary:
	for n in level_data.nodes: if n.id == id: return n
	return {}

func _reset_game_state():
	current_node = level_data.start_node
	path = [current_node]
	sim_time_sec = 0
	sum_input.text = ""
	status_label.text = ""
	ambush_triggered = false
	first_attempt_edge = null
	planning_time_ms = 0
	start_time_ms = Time.get_ticks_msec()
	_update_visuals()
	_update_sim_time_display()
	_update_trust()

func _update_visuals():
	path_display.text = "Path: " + " -> ".join(path)

	# Update edge visuals based on sim_time
	for edge in level_data.edges:
		var info = _get_current_edge_weight(edge, sim_time_sec)
		var line = edge_lines.get(edge.id)
		var lbl = edge_labels.get(edge.id)

		if line:
			if info.state == "closed":
				line.default_color = Color.RED
				line.width = 2.0
				# Dashed effect simulation?
			else:
				# Highlight active vs changed
				if info.w != edge.w: # Changed from base
					line.default_color = Color.ORANGE
				else:
					line.default_color = Color.GRAY

		if lbl:
			lbl.text = "CLOSED" if info.state == "closed" else str(info.w)
			lbl.modulate = Color.RED if info.state == "closed" else (Color.YELLOW if info.w != edge.w else Color.WHITE)

	# Nodes availability
	for node_id in node_buttons:
		var btn = node_buttons[node_id]
		var is_neighbor = false

		if node_id == current_node:
			btn.disabled = true
			btn.modulate = Color.YELLOW
			continue

		# Check adjacency
		if adjacency.has(current_node) and adjacency[current_node].has(node_id):
			is_neighbor = true

		btn.disabled = not is_neighbor
		btn.modulate = Color.WHITE if is_neighbor else Color(0.3, 0.3, 0.3)

func _on_node_pressed(node_id: String):
	if is_game_over: return

	if first_attempt_edge == null:
		first_attempt_edge = current_node + "->" + node_id
		planning_time_ms = Time.get_ticks_msec() - start_time_ms

	if adjacency.has(current_node) and adjacency[current_node].has(node_id):
		var edge = adjacency[current_node][node_id]
		var info = _get_current_edge_weight(edge, sim_time_sec)

		if info.state == "closed":
			violations.closed_edge_attempts += 1
			status_label.text = "EDGE CLOSED!"
			status_label.add_theme_color_override("font_color", Color.RED)
			# Soft block or penalty?
			# Specification says: "attempt = logical violation" but doesn't explicitly say Trust penalty immediately unless judge?
			# Actually "Violation XOR ... Trust -= penalty".
			# Let's verify constraints here?
			return

		# Move
		sim_time_sec += info.w
		current_node = node_id
		path.append(node_id)

		# Check Immediate Blacklist Ambush
		if level_data.constraints.has("blacklist_nodes") and current_node in level_data.constraints.blacklist_nodes:
			if not ambush_triggered: # Apply once?
				ambush_triggered = true
				violations.blacklist_attempts += 1
				var mult = level_data.trust.get("ambush_multiplier", 0.5)
				trust = floor(trust * mult)
				status_label.text = "AMBUSH! Trust Critical."
				status_label.add_theme_color_override("font_color", Color.RED)
				_update_trust() # Check fail threshold

		_update_visuals()
		_update_sim_time_display()

func _on_reset_pressed():
	if is_game_over: return
	n_reset += 1
	_reset_game_state()
	_update_trust()

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _on_submit_pressed():
	if is_game_over: return

	var input_text = sum_input.text.strip_edges()
	var verdict = _judge_solution(input_text)

	_log_attempt(input_text, verdict)

	if verdict == "OK_OPTIMAL":
		status_label.text = "SUCCESS! Plan Executed."
		status_label.add_theme_color_override("font_color", Color.GREEN)
		is_game_over = true
		btn_submit.disabled = true
		btn_reset.disabled = true
		_update_trust()
	elif trust <= level_data.trust.fail_threshold:
		status_label.text = "MISSION FAILED."
		status_label.add_theme_color_override("font_color", Color.RED)
		is_game_over = true
		btn_submit.disabled = true
		btn_reset.disabled = true
	else:
		status_label.text = _format_verdict_message(verdict)
		status_label.add_theme_color_override("font_color", Color.ORANGE)
		_update_trust()

func _on_sum_input_changed(new_text: String) -> void:
	var filtered := ""
	for ch in new_text:
		if ch >= "0" and ch <= "9":
			filtered += ch
	if filtered != new_text:
		sum_input.text = filtered
		sum_input.caret_column = filtered.length()

func _format_verdict_message(verdict: String) -> String:
	match verdict:
		"PARSE_ERROR":
			return "Enter a whole number."
		"ERR_CALC":
			return "Incorrect sum for the selected path."
		"ERR_NOT_OPT":
			return "Path is valid, but not optimal."
		"ERR_MISSING_REQUIRED":
			return "Missing required node(s)."
		"ERR_LOGIC_VIOLATION":
			return "Logical constraints are violated."
		"INCOMPLETE":
			return "Reach the destination before submit."
	return "Error: " + verdict

func _judge_solution(input_text: String) -> String:
	# 1. Structural (Calculated during move, but verify)
	# 2. Completion
	if level_data.rules.require_end_node_to_submit:
		if current_node != level_data.end_node:
			return "INCOMPLETE"

	# 3. Must Visit
	if level_data.constraints.has("must_visit"):
		for m in level_data.constraints.must_visit:
			if not path.has(m):
				violations.must_visit_missing_submits += 1
				return "ERR_MISSING_REQUIRED"

	# 4. XOR Checks
	if _is_xor_violation(path):
		n_logic += 1
		violations.xor += 1
		return "ERR_LOGIC_VIOLATION"

	# 5. Ambush Check (if fatal?)
	# Ambush handled in runtime, trust already penalized.

	# 6. Parse
	if not input_regex.search(input_text):
		n_parse += 1
		return "PARSE_ERROR"

	# 7. Calc
	if int(input_text) != sim_time_sec:
		n_calc += 1
		return "ERR_CALC"

	# 8. Optimality
	if sim_time_sec > min_sum:
		n_opt += 1
		return "ERR_NOT_OPT"

	return "OK_OPTIMAL"

func _update_trust():
	var t_overtime = max(0, real_time_sec - level_data.time_limit_sec)
	var overtime_div = level_data.trust.get("overtime_div", 2)
	var penalty_overtime = floor(t_overtime / float(overtime_div))

	var penalties = (n_calc * level_data.trust.penalty_calc) + \
					(n_opt * level_data.trust.penalty_opt) + \
					(n_parse * level_data.trust.penalty_parse) + \
					(n_reset * level_data.trust.penalty_reset) + \
					(n_logic * level_data.trust.get("penalty_logic_violation", 30)) + \
					penalty_overtime

	# Initial trust minus linear penalties
	var calculated_trust = level_data.trust.initial - penalties

	# Apply ambush multipliers (handled in runtime by directly modifying 'trust' variable?)
	# Issue: reset re-calculates trust. We need to persist ambush effect or re-apply it?
	# Better: 'trust' variable accumulates permanent damage.
	# BUT: formula based approach is cleaner.
	# Solution: `trust` instance variable holds current state. Penalties subtract from it.
	# But `_update_trust` resets it based on counts.
	# Correct approach for this strict logic:
	# Trust = Base - Penalties. Ambush is a permanent multiplier on the RESULT.

	var effective_trust = calculated_trust
	if ambush_triggered:
		effective_trust = floor(effective_trust * level_data.trust.get("ambush_multiplier", 0.5))

	trust = clamp(effective_trust, 0, 100)
	trust_label.text = "Trust: %d%%" % int(trust)

	if trust <= level_data.trust.fail_threshold:
		if not is_game_over:
			is_game_over = true
			status_label.text = "MISSION FAILED: Trust Critical."
			status_label.add_theme_color_override("font_color", Color.RED)
			btn_submit.disabled = true
			btn_reset.disabled = true
			_log_attempt("", "FAIL_TRUST")

func _update_real_time_display():
	var minutes = int(real_time_sec / 60)
	var seconds = int(real_time_sec) % 60
	real_time_label.text = "REAL: %02d:%02d" % [minutes, seconds]
	if real_time_sec > level_data.time_limit_sec:
		real_time_label.add_theme_color_override("font_color", Color.RED)
	else:
		real_time_label.add_theme_color_override("font_color", Color.WHITE)

func _update_sim_time_display():
	sim_time_label.text = "SIM: %ds" % sim_time_sec

func _log_attempt(input_sum_raw: String, verdict: String):
	# Logging Logic
	var user_input_int = -1
	var input_valid = false
	var norm_input = input_sum_raw.strip_edges()
	if input_regex.search(norm_input):
		user_input_int = int(norm_input)
		input_valid = true

	var attempt_no = GlobalMetrics.session_history.size() + 1
	var t_overtime = max(0, real_time_sec - level_data.time_limit_sec)

	var log_data = {
		"schema_version": "trial.v2",
		"quest_id": "CITY_MAP",
		"stage": "C",
		"task_id": str(level_data.get("level_id", "CITY_C")),
		"interaction_type": "PATH_SUM",
		"match_key": "CITY_MAP|C|%s|v%s" % [str(level_data.get("level_id", "CITY_C")), config_hash.substr(0, 8)],
		"variant_hash": config_hash,
		"contract_version": level_data.get("contract_version", "city_map.v1.0.0"),
		"level_id": level_data.level_id,
		"config_hash": config_hash,
		"attempt_no": attempt_no,

		"planning_time_ms": planning_time_ms,
		"real_time_sec": real_time_sec,
		"sim_time_sec": sim_time_sec,

		"path": path,
		"entered_sum_raw": norm_input,
		"entered_sum_int": user_input_int if input_valid else null,
		"real_sum": sim_time_sec,
		"min_sum": min_sum,

		"verdict_code": verdict,
		"trust_final": int(trust),
		"violations": violations,
		"ambush_triggered": ambush_triggered,

		"N_calc": n_calc,
		"N_opt": n_opt,
		"N_parse": n_parse,
		"N_reset": n_reset,
		"N_logic": n_logic
	}

	log_data["is_correct"] = verdict == "OK_OPTIMAL"
	log_data["is_fit"] = verdict == "OK_OPTIMAL"
	log_data["stability_delta"] = 0
	log_data["elapsed_ms"] = real_time_sec * 1000
	log_data["duration"] = float(real_time_sec)
	log_data["time_to_first_action_ms"] = planning_time_ms if planning_time_ms > 0 else real_time_sec * 1000
	log_data["error_type"] = verdict if verdict != "OK_OPTIMAL" else "NONE"
	GlobalMetrics.register_trial(log_data)
	_save_json_log(log_data)

func _save_json_log(data: Dictionary):
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("research_logs"):
		dir.make_dir("research_logs")

	var filename = "user://research_logs/case_6_3_%d.json" % Time.get_unix_time_from_system()
	var file = FileAccess.open(filename, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
