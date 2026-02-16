extends Control

# SSoT Data
var level_data: Dictionary = {}
var adjacency: Dictionary = {} # source -> {target: weight}
var min_sum: int = 0
var input_regex: RegEx
var config_hash: String = ""

# State
var current_node: String = ""
var path: Array = []
var trust: float = 100.0
var t_elapsed_seconds: int = 0
var is_game_over: bool = false
var first_attempt_edge: Variant = null # String or null
var level_started_ms: int = 0
var first_action_ms: int = -1

# B-Level Metrics
var backtrack_count: int = 0
var cycle_repeats: int = 0
var cycle_entered: bool = false
var n_transit: int = 0

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
	sum_input.text_changed.connect(_on_sum_input_changed)
	sum_input.placeholder_text = "Enter integer sum"

	_load_level_data("res://data/city_map/level_6_2.json")
	_calculate_optimal_path_with_transit()
	_build_graph_ui()
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
	t_elapsed_seconds += 1
	_update_timer_display()
	# Check overtime penalty dynamically
	if t_elapsed_seconds > level_data.time_limit_sec:
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

	# Build adjacency list handling two_way edges
	for edge in level_data.edges:
		_add_adjacency(edge.from, edge.to, edge.w)
		if edge.get("two_way", false):
			_add_adjacency(edge.to, edge.from, edge.w)

func _add_adjacency(from_id: String, to_id: String, w: int):
	if not adjacency.has(from_id):
		adjacency[from_id] = {}
	adjacency[from_id][to_id] = w

func _calculate_optimal_path_with_transit():
	# For Complexity B: must pass through C
	# min_sum = dist(Start->C) + dist(C->End)
	var start_node = level_data.start_node
	var end_node = level_data.end_node
	var transit_nodes = level_data.constraints.must_visit

	if transit_nodes.is_empty():
		min_sum = _dijkstra(start_node, end_node)
		return

	# Assuming single transit node for 6.2 as per spec
	var transit = transit_nodes[0]

	var leg1 = _dijkstra(start_node, transit)
	var leg2 = _dijkstra(transit, end_node)

	if leg1 == -1 or leg2 == -1:
		push_error("Path with transit invalid")
		min_sum = 999999
	else:
		min_sum = leg1 + leg2

func _dijkstra(start: String, end: String) -> int:
	var dist = {}
	var nodes = level_data.nodes

	for n in nodes:
		dist[n.id] = 999999

	dist[start] = 0
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

		if u == null:
			break
		if u == end:
			return dist[end]

		unvisited.erase(u)

		if adjacency.has(u):
			for v in adjacency[u]:
				var alt = dist[u] + adjacency[u][v]
				if alt < dist.get(v, 999999):
					dist[v] = alt

	return -1 # Unreachable

func _build_graph_ui():
	# Clear existing
	for child in nodes_layer.get_children():
		child.queue_free()
	for child in edges_layer.get_children():
		child.queue_free()
	node_buttons.clear()
	edge_lines.clear()

	# Draw Edges first
	for edge in level_data.edges:
		var from_node = _get_node_data(edge.from)
		var to_node = _get_node_data(edge.to)

		if from_node and to_node:
			var start_pos = Vector2(from_node.pos.x, from_node.pos.y)
			var end_pos = Vector2(to_node.pos.x, to_node.pos.y)

			var line = Line2D.new()
			line.points = [start_pos, end_pos]
			line.width = 4.0
			var gradient = Gradient.new()
			gradient.set_color(0, Color(0.3, 0.3, 0.3, 0.5))
			gradient.set_color(1, Color(0.6, 0.6, 1.0, 1.0))
			line.gradient = gradient

			edges_layer.add_child(line)

			# Arrow Head(s)
			var dir = (end_pos - start_pos).normalized()
			_draw_arrow(end_pos, dir, edges_layer)

			if edge.get("two_way", false):
				# Add reverse arrow at start
				_draw_arrow(start_pos, -dir, edges_layer)

			# Weight Label
			var mid_pos = (start_pos + end_pos) / 2
			var lbl = Label.new()
			lbl.text = str(edge.w)
			lbl.position = mid_pos + Vector2(5, -10)
			lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
			edges_layer.add_child(lbl)

			edge_lines[edge.id] = line

	# Draw Nodes
	for node_def in level_data.nodes:
		var btn = Button.new()
		btn.text = node_def.label
		btn.position = Vector2(node_def.pos.x, node_def.pos.y) - Vector2(25, 25)
		btn.size = Vector2(50, 50)
		btn.pressed.connect(_on_node_pressed.bind(node_def.id))
		nodes_layer.add_child(btn)
		node_buttons[node_def.id] = btn

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
	for n in level_data.nodes:
		if n.id == id:
			return n
	return {}

func _reset_game_state():
	current_node = level_data.start_node
	path = [current_node]
	sum_input.text = ""
	status_label.text = ""
	backtrack_count = 0
	cycle_repeats = 0
	cycle_entered = false
	level_started_ms = Time.get_ticks_msec()
	first_action_ms = -1
	_update_visuals()
	_update_trust()

func _update_visuals():
	path_display.text = "Path: " + " -> ".join(path)

	for node_id in node_buttons:
		var btn = node_buttons[node_id]
		var is_neighbor = false

		if node_id == current_node:
			btn.disabled = true
			btn.modulate = Color(1, 1, 0)
			continue

		if adjacency.has(current_node) and adjacency[current_node].has(node_id):
			is_neighbor = true

		btn.disabled = not is_neighbor
		if is_neighbor:
			btn.modulate = Color(1, 1, 1)
		else:
			btn.modulate = Color(0.5, 0.5, 0.5)

func _on_node_pressed(node_id: String):
	if is_game_over: return

	if adjacency.has(current_node) and adjacency[current_node].has(node_id):
		if first_attempt_edge == null:
			first_attempt_edge = current_node + "->" + node_id
			first_action_ms = Time.get_ticks_msec() - level_started_ms

		# Metric: Backtrack
		if path.size() >= 2 and path[path.size()-2] == node_id:
			backtrack_count += 1

		# Metric: Cycle Repeats
		if path.has(node_id):
			cycle_repeats += 1
			cycle_entered = true

		path.append(node_id)
		current_node = node_id
		_update_visuals()

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

	if verdict == "OPTIMAL":
		status_label.text = "SUCCESS! Network Optimal."
		status_label.add_theme_color_override("font_color", Color.GREEN)
		is_game_over = true
		btn_submit.disabled = true
		btn_reset.disabled = true
		_update_trust()
	elif trust <= 10:
		status_label.text = "MISSION FAILED: Trust Depleted."
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
		"CALC_MISMATCH":
			return "Incorrect sum for the selected path."
		"NON_OPTIMAL":
			return "Path is valid, but not optimal."
		"ERR_MISSING_TRANSIT":
			return "Missing required transit node."
		"INCOMPLETE":
			return "Reach the destination before submit."
		"ERR_PATH_INVALID":
			return "Path is invalid."
	return "Error: " + verdict

func _judge_solution(input_text: String) -> String:
	# 1. Structural
	var real_sum = 0
	for i in range(path.size() - 1):
		if not adjacency.has(path[i]) or not adjacency[path[i]].has(path[i+1]):
			return "ERR_PATH_INVALID"
		real_sum += adjacency[path[i]][path[i+1]]

	# 2. Incomplete
	if level_data.rules.require_end_node_to_submit:
		if current_node != level_data.end_node:
			return "INCOMPLETE"

	# 3. Transit Check
	var has_transit = true
	for t_node in level_data.constraints.must_visit:
		if not path.has(t_node):
			has_transit = false
			break
	if not has_transit:
		n_transit += 1
		return "ERR_MISSING_TRANSIT"

	# 4. Parse
	if not input_regex.search(input_text):
		n_parse += 1
		return "PARSE_ERROR"

	# 5. Calc
	if int(input_text) != real_sum:
		n_calc += 1
		return "CALC_MISMATCH"

	# 6. Optimality
	if real_sum > min_sum:
		n_opt += 1
		return "NON_OPTIMAL"

	return "OPTIMAL"

func _update_trust():
	var t_overtime = max(0, t_elapsed_seconds - level_data.time_limit_sec)
	var overtime_div = level_data.trust.get("overtime_div", 2)
	var penalty_overtime = floor(t_overtime / float(overtime_div))

	var penalties = (n_calc * level_data.trust.penalty_calc) + \
					(n_opt * level_data.trust.penalty_opt) + \
					(n_parse * level_data.trust.penalty_parse) + \
					(n_reset * level_data.trust.penalty_reset) + \
					(n_transit * level_data.trust.get("penalty_transit", 25)) + \
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
	_log_attempt("", "FAIL_TRUST")

func _update_timer_display():
	var minutes = int(t_elapsed_seconds / 60)
	var seconds = int(t_elapsed_seconds) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]
	if t_elapsed_seconds > level_data.time_limit_sec:
		timer_label.add_theme_color_override("font_color", Color.RED)
	else:
		timer_label.add_theme_color_override("font_color", Color.WHITE)

func _log_attempt(input_sum_raw: String, verdict: String):
	var user_input_int = -1
	var input_valid = false
	var norm_input = input_sum_raw.strip_edges()
	if input_regex.search(norm_input):
		user_input_int = int(norm_input)
		input_valid = true

	var real_path_sum = 0
	var is_structurally_valid = true
	for i in range(path.size() - 1):
		if adjacency.has(path[i]) and adjacency[path[i]].has(path[i+1]):
			real_path_sum += adjacency[path[i]][path[i+1]]
		else:
			is_structurally_valid = false

	var has_transit = true
	for t_node in level_data.constraints.must_visit:
		if not path.has(t_node):
			has_transit = false
			break

	var attempt_no = GlobalMetrics.session_history.size() + 1
	var t_overtime = max(0, t_elapsed_seconds - level_data.time_limit_sec)

	var log_data = {
		"schema_version": "trial.v2",
		"quest_id": "CITY_MAP",
		"stage": "B",
		"task_id": str(level_data.get("level_id", "CITY_B")),
		"interaction_type": "PATH_SUM",
		"match_key": "CITY_MAP|B|%s|v%s" % [str(level_data.get("level_id", "CITY_B")), config_hash.substr(0, 8)],
		"variant_hash": config_hash,
		"contract_version": level_data.get("contract_version", "city_map.v1.0.0"),
		"level_id": level_data.level_id,
		"config_hash": config_hash,
		"attempt_no": attempt_no,

		"calc_ok": (user_input_int == real_path_sum) if input_valid else false,
		"optimal_ok": (is_structurally_valid and current_node == level_data.end_node and real_path_sum == min_sum and has_transit),
		"transit_ok": has_transit,
		"path_valid": is_structurally_valid,
		"reached_end": (current_node == level_data.end_node),

		"first_attempt_edge": first_attempt_edge,
		"t_elapsed_seconds": t_elapsed_seconds,
		"t_overtime_seconds": t_overtime,
		"trust_final": int(trust),
		"path": path,

		"entered_sum_raw": norm_input,
		"entered_sum_int": user_input_int if input_valid else null,
		"real_sum": real_path_sum,
		"min_sum": min_sum,

		"N_calc": n_calc,
		"N_opt": n_opt,
		"N_parse": n_parse,
		"N_reset": n_reset,
		"N_transit": n_transit,

		"backtrack_count": backtrack_count,
		"cycle_repeats": cycle_repeats,
		"cycle_entered": cycle_entered,

		"verdict_code": verdict,
		"is_correct": verdict == "OPTIMAL",
		"is_fit": verdict == "OPTIMAL",
		"stability_delta": 0,
		"elapsed_ms": t_elapsed_seconds * 1000,
		"duration": float(t_elapsed_seconds),
		"time_to_first_action_ms": first_action_ms if first_action_ms >= 0 else t_elapsed_seconds * 1000,
		"error_type": verdict if verdict != "OPTIMAL" else "NONE"
	}

	GlobalMetrics.register_trial(log_data)
	_save_json_log(log_data)

func _save_json_log(data: Dictionary):
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("research_logs"):
		dir.make_dir("research_logs")

	var filename = "user://research_logs/case_6_2_%d.json" % Time.get_unix_time_from_system()
	var file = FileAccess.open(filename, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
