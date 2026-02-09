extends Control

# SSoT Data
var level_data: Dictionary = {}
var adjacency: Dictionary = {} # source -> {target: weight}
var min_sum: int = 0
var optimal_path_example: Array = []

# State
var current_node: String = ""
var path: Array = []
var trust: float = 100.0
var time_elapsed: float = 0.0
var is_game_over: bool = false
var first_attempt_edge: Variant = null # String or null

# Counters
var n_calc: int = 0
var n_opt: int = 0
var n_parse: int = 0
var n_reset: int = 0

# UI References
@onready var edges_layer = $MainLayout/GraphContainer/EdgesLayer
@onready var nodes_layer = $MainLayout/GraphContainer/NodesLayer
@onready var path_display = $MainLayout/Footer/PathDisplay
@onready var sum_input = $MainLayout/Footer/InputRow/SumInput
@onready var status_label = $MainLayout/Footer/StatusLabel
@onready var trust_label = $MainLayout/Header/TrustLabel
@onready var timer_label = $MainLayout/Header/TimerLabel
@onready var btn_back = $MainLayout/Header/BtnBack
@onready var btn_reset = $MainLayout/Footer/InputRow/BtnReset
@onready var btn_submit = $MainLayout/Footer/InputRow/BtnSubmit

# Helpers
var node_buttons: Dictionary = {} # id -> Button
var edge_lines: Dictionary = {} # "from->to" -> Line2D

func _ready():
	btn_back.pressed.connect(_on_back_pressed)
	btn_reset.pressed.connect(_on_reset_pressed)
	btn_submit.pressed.connect(_on_submit_pressed)

	_load_level_data("res://data/city_map/level_6_1.json")
	_calculate_optimal_path()
	_build_graph_ui()
	_reset_game_state()

func _process(delta):
	if is_game_over:
		return

	time_elapsed += delta
	_update_timer_display()

	# Check overtime penalty dynamically
	if time_elapsed > level_data.time_limit_sec:
		_update_trust()

func _load_level_data(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Failed to load level data: " + path)
		return

	var content = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(content)
	if error == OK:
		level_data = json.data
	else:
		push_error("JSON Parse Error: " + json.get_error_message())

	# Build adjacency list for logic
	for edge in level_data.edges:
		if not adjacency.has(edge.from):
			adjacency[edge.from] = {}
		adjacency[edge.from][edge.to] = edge.w

func _calculate_optimal_path():
	# Simple Dijkstra
	var start_node = level_data.start_node
	var end_node = level_data.end_node

	var dist = {}
	var prev = {}
	var nodes = level_data.nodes

	for n in nodes:
		dist[n.id] = 999999
		prev[n.id] = null

	dist[start_node] = 0
	var unvisited = []
	for n in nodes:
		unvisited.append(n.id)

	while unvisited.size() > 0:
		var u = null
		var min_dist = 999999
		for node_id in unvisited:
			if dist[node_id] < min_dist:
				min_dist = dist[node_id]
				u = node_id

		if u == null or u == end_node:
			break

		unvisited.erase(u)

		if adjacency.has(u):
			for v in adjacency[u]:
				var alt = dist[u] + adjacency[u][v]
				if alt < dist[v]:
					dist[v] = alt
					prev[v] = u

	min_sum = dist[end_node]
	# Reconstruct path? Not strictly needed for logic, just min_sum is needed for Judge.
	# But good for debugging.

func _build_graph_ui():
	# Clear existing
	for child in nodes_layer.get_children():
		child.queue_free()
	for child in edges_layer.get_children():
		child.queue_free()
	node_buttons.clear()
	edge_lines.clear()

	# Draw Edges first (behind nodes)
	for edge in level_data.edges:
		var from_node = _get_node_data(edge.from)
		var to_node = _get_node_data(edge.to)

		if from_node and to_node:
			var start_pos = Vector2(from_node.pos.x, from_node.pos.y)
			var end_pos = Vector2(to_node.pos.x, to_node.pos.y)

			var line = Line2D.new()
			line.points = [start_pos, end_pos]
			line.width = 4.0
			# Gradient: Dim to Bright
			var gradient = Gradient.new()
			gradient.set_color(0, Color(0.3, 0.3, 0.3, 0.5)) # Start dim
			gradient.set_color(1, Color(0.6, 0.6, 1.0, 1.0)) # End bright
			line.gradient = gradient

			edges_layer.add_child(line)

			# Weight Label
			var mid_pos = (start_pos + end_pos) / 2
			var lbl = Label.new()
			lbl.text = str(edge.w)
			lbl.position = mid_pos + Vector2(5, -10) # Offset slightly
			lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
			edges_layer.add_child(lbl)

			edge_lines[edge.from + "->" + edge.to] = line

	# Draw Nodes
	for node_def in level_data.nodes:
		var btn = Button.new()
		btn.text = node_def.label
		btn.position = Vector2(node_def.pos.x, node_def.pos.y) - Vector2(25, 25) # Centered
		btn.size = Vector2(50, 50)
		btn.pressed.connect(_on_node_pressed.bind(node_def.id))
		# Style?
		nodes_layer.add_child(btn)
		node_buttons[node_def.id] = btn

func _get_node_data(id: String) -> Dictionary:
	for n in level_data.nodes:
		if n.id == id:
			return n
	return {}

func _reset_game_state():
	current_node = level_data.start_node
	path = [current_node]
	sum_input.text = ""
	status_label.text = ""
	_update_visuals()
	_update_trust()

func _update_visuals():
	path_display.text = "Path: " + " -> ".join(path)

	# Enable/Disable buttons based on adjacency
	for node_id in node_buttons:
		var btn = node_buttons[node_id]
		var is_neighbor = false

		# If it's the current node, disable it (already there)
		if node_id == current_node:
			btn.disabled = true
			btn.modulate = Color(1, 1, 0) # Highlight current
			continue

		# Check if direct edge exists from current_node to node_id
		if adjacency.has(current_node) and adjacency[current_node].has(node_id):
			is_neighbor = true

		# Special case: allow clicking backward? No, directed graph.
		# Only allow forward movement.
		# But wait, can we go back? No, "Next node available only if direct edge exists".
		# So once we leave A, we can't click A unless there is an edge back to A.

		btn.disabled = not is_neighbor
		if is_neighbor:
			btn.modulate = Color(1, 1, 1) # Normal
		else:
			btn.modulate = Color(0.5, 0.5, 0.5) # Dimmed

	# Also highlight edges in the path?
	# Reset all lines
	for key in edge_lines:
		edge_lines[key].default_color = Color(1, 1, 1, 1) # Reset to gradient default

	# Highlight path edges? (Optional, visually nice)

func _on_node_pressed(node_id: String):
	if is_game_over: return

	# Verify edge exists (Double check)
	if adjacency.has(current_node) and adjacency[current_node].has(node_id):

		# Capture first attempt edge
		if path.size() == 1 and first_attempt_edge == null and n_reset == 0:
			first_attempt_edge = current_node + "->" + node_id

		path.append(node_id)
		current_node = node_id
		_update_visuals()
	else:
		pass # Should be disabled anyway

func _on_reset_pressed():
	if is_game_over: return

	n_reset += 1
	_reset_game_state()
	# Reset does NOT clear time_elapsed, but updates trust
	_update_trust()

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _on_submit_pressed():
	if is_game_over: return

	var input_text = sum_input.text.strip_edges()
	var verdict = _judge_solution(input_text)

	_log_attempt(input_text, verdict)

	if verdict == "OPTIMAL":
		status_label.text = "SUCCESS! Path optimal."
		status_label.add_theme_color_override("font_color", Color.GREEN)
		is_game_over = true
		btn_submit.disabled = true
		btn_reset.disabled = true
		_update_trust() # Final update
		# Victory?
	elif verdict == "FAIL_TRUST":
		status_label.text = "MISSION FAILED: Trust Depleted."
		status_label.add_theme_color_override("font_color", Color.RED)
		is_game_over = true
		btn_submit.disabled = true
		btn_reset.disabled = true
	else:
		# Feedback
		status_label.text = "Error: " + verdict
		status_label.add_theme_color_override("font_color", Color.ORANGE)
		_update_trust()

func _judge_solution(input_text: String) -> String:
	# 1. INCOMPLETE
	if level_data.rules.require_end_node_to_submit:
		if current_node != level_data.end_node:
			return "INCOMPLETE"

	# 2. INVALID_PATH (Should be prevented by UI, but check anyway)
	var real_sum = 0
	for i in range(path.size() - 1):
		var u = path[i]
		var v = path[i+1]
		if not adjacency.has(u) or not adjacency[u].has(v):
			return "INVALID_PATH"
		real_sum += adjacency[u][v]

	# 3. PARSE_ERROR
	var regex = RegEx.new()
	regex.compile(level_data.rules.input_regex)
	if not regex.search(input_text):
		n_parse += 1
		return "PARSE_ERROR"

	# 4. CALC_MISMATCH
	var input_val = int(input_text)
	if input_val != real_sum:
		n_calc += 1
		return "CALC_MISMATCH"

	# 5. NON_OPTIMAL
	if real_sum > min_sum:
		n_opt += 1
		return "NON_OPTIMAL"

	# 6. OPTIMAL
	return "OPTIMAL"

func _update_trust():
	var t_overtime = max(0, time_elapsed - level_data.time_limit_sec)
	var penalty_overtime = floor(t_overtime / 2.0)

	var penalties = (n_calc * level_data.trust.penalty_calc) + \
					(n_opt * level_data.trust.penalty_opt) + \
					(n_parse * level_data.trust.penalty_parse) + \
					(n_reset * level_data.trust.penalty_reset) + \
					penalty_overtime

	trust = clamp(level_data.trust.initial - penalties, 0, 100)
	trust_label.text = "Trust: %d%%" % int(trust)

	if trust <= 10:
		if not is_game_over:
			_game_over_trust()

func _game_over_trust():
	is_game_over = true
	status_label.text = "MISSION FAILED: Trust Critical."
	status_label.add_theme_color_override("font_color", Color.RED)
	btn_submit.disabled = true
	btn_reset.disabled = true
	# Log final fail
	_log_attempt("", "FAIL_TRUST")

func _update_timer_display():
	var minutes = int(time_elapsed / 60)
	var seconds = int(time_elapsed) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]
	if time_elapsed > level_data.time_limit_sec:
		timer_label.add_theme_color_override("font_color", Color.RED)
	else:
		timer_label.add_theme_color_override("font_color", Color.WHITE)

func _log_attempt(input_sum: String, verdict: String):
	# Calculate real sum for logging
	var real_sum = 0
	for i in range(path.size() - 1):
		var u = path[i]
		var v = path[i+1]
		if adjacency.has(u) and adjacency[u].has(v):
			real_sum += adjacency[u][v]

	var log_data = {
		"level_id": level_data.level_id,
		"attempt_no": GlobalMetrics.session_history.size() + 1, # Approx
		"calc_ok": (verdict != "CALC_MISMATCH"),
		"optimal_ok": (verdict == "OPTIMAL"),
		"first_attempt_edge": first_attempt_edge,
		"t_elapsed_seconds": int(time_elapsed),
		"path": path,
		"real_sum": real_sum,
		"entered_sum": input_sum,
		"min_sum": min_sum,
		"N_calc": n_calc,
		"N_opt": n_opt,
		"N_parse": n_parse,
		"N_reset": n_reset,
		"trust_final": int(trust),
		"verdict_code": verdict,
		"config_hash": "TODO_HASH" # Optional for now
	}

	# 1. Append to GlobalMetrics
	# Note: GlobalMetrics.register_trial expects specific keys for its internal logic?
	# The memory says: "Quest completion data must be sent to GlobalMetrics.register_trial(data)"
	# And: "The logging contract... requires... is_correct, is_fit..."
	# I should adapt keys to make GlobalMetrics happy while keeping my specific fields.
	log_data["is_correct"] = (verdict == "OPTIMAL")
	log_data["is_fit"] = (verdict == "OPTIMAL")

	GlobalMetrics.register_trial(log_data)

	# 2. Save to file
	_save_json_log(log_data)

func _save_json_log(data: Dictionary):
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("research_logs"):
		dir.make_dir("research_logs")

	var filename = "user://research_logs/case_6_1_%d.json" % Time.get_unix_time_from_system()
	var file = FileAccess.open(filename, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
