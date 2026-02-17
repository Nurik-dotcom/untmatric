extends Control

const LEVEL_PATH := "res://data/city_map/level_6_1.json"
const LOG_PREFIX := "case_6_1"
const DEFAULT_ACCENT := Color(0.40, 0.72, 1.0, 1.0)
const ARROW_ANGLE_RAD := 0.52
const ARROW_LEN := 16.0

@onready var content_split: BoxContainer = $SafeArea/MainVBox/ContentSplit
@onready var graph_container: Control = $SafeArea/MainVBox/ContentSplit/GraphPanel/GraphMargin/GraphContainer
@onready var edges_layer: Control = $SafeArea/MainVBox/ContentSplit/GraphPanel/GraphMargin/GraphContainer/EdgesLayer
@onready var nodes_layer: Control = $SafeArea/MainVBox/ContentSplit/GraphPanel/GraphMargin/GraphContainer/NodesLayer
@onready var btn_back: Button = $SafeArea/MainVBox/Header/BtnBack
@onready var btn_reset: Button = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/ButtonsRow/BtnReset
@onready var btn_submit: Button = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/ButtonsRow/BtnSubmit
@onready var sum_input: LineEdit = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/SumInput
@onready var path_display: Label = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/PathDisplay
@onready var sum_live_label: Label = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/SumLiveLabel
@onready var status_label: Label = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/StatusLabel
@onready var label_state: Label = $SafeArea/MainVBox/Header/LabelState
@onready var label_timer: Label = $SafeArea/MainVBox/Header/LabelTimer
@onready var footer_label: Label = $SafeArea/MainVBox/Footer/FooterLabel
@onready var briefing_title: Label = $SafeArea/MainVBox/BriefingCard/BriefingMargin/BriefingVBox/BriefingTitle
@onready var briefing_text: Label = $SafeArea/MainVBox/BriefingCard/BriefingMargin/BriefingVBox/BriefingText

var level_data: Dictionary = {}
var node_defs: Dictionary = {}
var adjacency: Dictionary = {}
var edge_visuals: Dictionary = {}
var node_buttons: Dictionary = {}
var config_hash: String = ""
var input_regex := RegEx.new()

var min_sum: int = 0
var accent_color: Color = DEFAULT_ACCENT
var node_radius_px: float = 25.0

var current_node: String = ""
var path: Array[String] = []
var path_sum: int = 0
var stability: float = 100.0
var t_elapsed_seconds: int = 0
var is_game_over: bool = false
var first_attempt_edge: String = ""
var level_started_ms: int = 0
var first_action_ms: int = -1

var n_calc: int = 0
var n_opt: int = 0
var n_parse: int = 0
var n_reset: int = 0

func _ready() -> void:
	btn_back.pressed.connect(_on_back_pressed)
	btn_reset.pressed.connect(_on_reset_pressed)
	btn_submit.pressed.connect(_on_submit_pressed)
	sum_input.text_changed.connect(_on_sum_input_changed)
	graph_container.resized.connect(_on_graph_resized)

	_load_level_data(LEVEL_PATH)
	_apply_content_layout_mode()
	_setup_timer()
	call_deferred("_post_ready")

func _post_ready() -> void:
	_set_briefing()
	_rebuild_graph_ui()
	_reset_round_state(true)
	_update_timer_display()
	_recalculate_stability()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		if not is_node_ready():
			return
		_apply_content_layout_mode()
		_rebuild_graph_ui()
		_update_visuals()
	elif what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		if has_node("ResearchTimer"):
			get_node("ResearchTimer").paused = true
	elif what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		if has_node("ResearchTimer"):
			get_node("ResearchTimer").paused = false

func _apply_content_layout_mode() -> void:
	content_split.vertical = get_viewport_rect().size.x < get_viewport_rect().size.y

func _setup_timer() -> void:
	var timer := Timer.new()
	timer.name = "ResearchTimer"
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_on_timer_tick)
	add_child(timer)

func _on_timer_tick() -> void:
	if is_game_over:
		return
	t_elapsed_seconds += 1
	_update_timer_display()
	if t_elapsed_seconds > int(level_data.get("time_limit_sec", 120)):
		_recalculate_stability()

func _load_level_data(path_to_file: String) -> void:
	var file := FileAccess.open(path_to_file, FileAccess.READ)
	if file == null:
		push_error("Failed to open level data: %s" % path_to_file)
		return

	var raw_json := file.get_as_text()
	config_hash = raw_json.sha256_text()
	var parsed: Variant = JSON.parse_string(raw_json)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid level JSON in %s" % path_to_file)
		return

	level_data = parsed
	node_defs.clear()
	adjacency.clear()

	for node_var in level_data.get("nodes", []):
		var node: Dictionary = node_var
		node_defs[str(node.get("id", ""))] = node

	for edge_var in level_data.get("edges", []):
		var edge: Dictionary = edge_var
		var from_id := str(edge.get("from", ""))
		var to_id := str(edge.get("to", ""))
		if from_id.is_empty() or to_id.is_empty():
			continue
		if not adjacency.has(from_id):
			adjacency[from_id] = {}
		adjacency[from_id][to_id] = int(edge.get("w", 0))

	input_regex = RegEx.new()
	var regex_pattern := "^[0-9]+$"
	if level_data.has("rules") and level_data.rules.has("input_regex"):
		regex_pattern = str(level_data.rules.input_regex)
	input_regex.compile(regex_pattern)

	min_sum = int(level_data.get("min_sum", -1))
	if min_sum < 0:
		min_sum = _calculate_min_sum()

	if level_data.has("ui"):
		if level_data.ui.has("accent_color"):
			accent_color = Color(level_data.ui.accent_color)
		if level_data.ui.has("node_radius_px"):
			var raw_radius := float(level_data.ui.node_radius_px)
			node_radius_px = raw_radius * 0.5 if raw_radius > 32.0 else raw_radius
			node_radius_px = maxf(16.0, node_radius_px)

func _set_briefing() -> void:
	briefing_title.text = "ROUTE AUDIT"
	briefing_text.text = "Reach node E using directed roads. Enter the final path sum and submit. Only the minimum route passes."
	footer_label.text = "Directed graph: only outgoing roads from your current node are clickable."

func _calculate_min_sum() -> int:
	var start_node := str(level_data.get("start_node", ""))
	var end_node := str(level_data.get("end_node", ""))
	if start_node.is_empty() or end_node.is_empty():
		return 0

	var dist: Dictionary = {}
	var unvisited: Array[String] = []
	for node_id in node_defs.keys():
		dist[node_id] = 1_000_000_000
		unvisited.append(node_id)
	dist[start_node] = 0

	while not unvisited.is_empty():
		var current := ""
		var best := 1_000_000_000
		for node_id in unvisited:
			var value := int(dist.get(node_id, 1_000_000_000))
			if value < best:
				best = value
				current = node_id

		if current.is_empty() or current == end_node:
			break
		unvisited.erase(current)

		var neighbors: Dictionary = adjacency.get(current, {})
		for next_id in neighbors.keys():
			var alt := best + int(neighbors[next_id])
			if alt < int(dist.get(next_id, 1_000_000_000)):
				dist[next_id] = alt

	var result := int(dist.get(end_node, 1_000_000_000))
	return 0 if result >= 1_000_000_000 else result

func _on_graph_resized() -> void:
	if graph_container.size.x <= 0.0 or graph_container.size.y <= 0.0:
		return
	_rebuild_graph_ui()
	_update_visuals()

func _rebuild_graph_ui() -> void:
	for child in edges_layer.get_children():
		child.queue_free()
	for child in nodes_layer.get_children():
		child.queue_free()
	edge_visuals.clear()
	node_buttons.clear()

	if graph_container.size.x <= 0.0 or graph_container.size.y <= 0.0:
		return

	for edge_var in level_data.get("edges", []):
		var edge: Dictionary = edge_var
		var from_id := str(edge.get("from", ""))
		var to_id := str(edge.get("to", ""))
		if from_id.is_empty() or to_id.is_empty() or not node_defs.has(from_id) or not node_defs.has(to_id):
			continue

		var start_pos := _node_screen_pos(node_defs[from_id])
		var end_pos := _node_screen_pos(node_defs[to_id])

		var line := Line2D.new()
		line.width = 4.0
		line.points = PackedVector2Array([start_pos, end_pos])
		line.gradient = _build_gradient(Color(0.18, 0.22, 0.30, 0.28), Color(0.30, 0.38, 0.52, 0.48))
		edges_layer.add_child(line)

		var arrow := _create_arrow_polygon(start_pos, end_pos)
		edges_layer.add_child(arrow)

		var label := Label.new()
		label.text = str(edge.get("w", 0))
		label.add_theme_font_size_override("font_size", 15)
		label.position = _edge_label_pos(start_pos, end_pos)
		label.add_theme_color_override("font_color", Color(0.62, 0.74, 0.90))
		edges_layer.add_child(label)

		var key := _edge_key(from_id, to_id)
		edge_visuals[key] = {
			"line": line,
			"arrow": arrow,
			"label": label
		}

	for node_id in node_defs.keys():
		var node: Dictionary = node_defs[node_id]
		var btn := Button.new()
		btn.text = str(node.get("label", node_id))
		var diameter := node_radius_px * 2.0
		btn.size = Vector2(diameter, diameter)
		btn.position = _node_screen_pos(node) - Vector2(node_radius_px, node_radius_px)
		btn.pressed.connect(_on_node_pressed.bind(node_id))
		nodes_layer.add_child(btn)
		node_buttons[node_id] = btn

func _edge_label_pos(start_pos: Vector2, end_pos: Vector2) -> Vector2:
	var dir := (end_pos - start_pos).normalized()
	var normal := Vector2(-dir.y, dir.x)
	return ((start_pos + end_pos) * 0.5) + (normal * 12.0) - Vector2(10.0, 10.0)

func _create_arrow_polygon(start_pos: Vector2, end_pos: Vector2) -> Polygon2D:
	var dir := (end_pos - start_pos).normalized()
	var tip := end_pos - dir * (node_radius_px + 4.0)
	var base := tip - dir * ARROW_LEN
	var side_len := ARROW_LEN * 0.65

	var polygon := Polygon2D.new()
	polygon.polygon = PackedVector2Array([
		tip,
		base + dir.rotated(ARROW_ANGLE_RAD) * side_len,
		base + dir.rotated(-ARROW_ANGLE_RAD) * side_len
	])
	polygon.color = Color(0.45, 0.66, 0.96, 0.95)
	return polygon

func _build_gradient(start_color: Color, end_color: Color) -> Gradient:
	var gradient := Gradient.new()
	gradient.set_color(0, start_color)
	gradient.set_color(1, end_color)
	return gradient

func _node_screen_pos(node_data: Dictionary) -> Vector2:
	var pos: Dictionary = node_data.get("pos", {})
	var x := float(pos.get("x", 0.0))
	var y := float(pos.get("y", 0.0))

	if x >= 0.0 and x <= 1.0 and y >= 0.0 and y <= 1.0:
		var padding := node_radius_px + 4.0
		var usable := graph_container.size - Vector2(padding * 2.0, padding * 2.0)
		usable.x = maxf(1.0, usable.x)
		usable.y = maxf(1.0, usable.y)
		return Vector2(padding + x * usable.x, padding + y * usable.y)

	return Vector2(x, y)

func _reset_round_state(full_reset: bool) -> void:
	current_node = str(level_data.get("start_node", "A"))
	path = [current_node]
	path_sum = 0
	sum_input.clear()
	status_label.text = ""
	first_action_ms = -1
	first_attempt_edge = ""

	if full_reset:
		level_started_ms = Time.get_ticks_msec()

	_update_visuals()

func _update_visuals() -> void:
	path_display.text = "PATH: %s" % " -> ".join(path)
	sum_live_label.text = "SUM: %d" % path_sum

	for node_id in node_buttons.keys():
		var btn: Button = node_buttons[node_id]
		var is_current: bool = node_id == current_node
		var is_available: bool = adjacency.has(current_node) and adjacency[current_node].has(node_id)
		btn.disabled = is_current or not is_available or is_game_over
		if is_current:
			btn.modulate = Color(0.95, 0.86, 0.45)
		elif is_available:
			btn.modulate = Color(1, 1, 1)
		else:
			btn.modulate = Color(0.42, 0.46, 0.56)

	for key in edge_visuals.keys():
		_set_edge_style(key, "dim")

	if adjacency.has(current_node):
		for next_id in adjacency[current_node].keys():
			_set_edge_style(_edge_key(current_node, str(next_id)), "available")

	for i in range(path.size() - 1):
		_set_edge_style(_edge_key(path[i], path[i + 1]), "traversed")

func _set_edge_style(key: String, state: String) -> void:
	if not edge_visuals.has(key):
		return

	var visual: Dictionary = edge_visuals[key]
	var line: Line2D = visual["line"]
	var arrow: Polygon2D = visual["arrow"]
	var label: Label = visual["label"]

	var start_color := Color(0.18, 0.22, 0.30, 0.28)
	var end_color := Color(0.30, 0.38, 0.52, 0.48)

	if state == "available":
		start_color = Color(0.24, 0.40, 0.62, 0.48)
		end_color = accent_color
		end_color.a = 0.95
	elif state == "traversed":
		start_color = accent_color.lightened(0.10)
		start_color.a = 0.80
		end_color = Color(0.92, 0.97, 1.0, 1.0)

	line.gradient = _build_gradient(start_color, end_color)
	arrow.color = end_color
	label.add_theme_color_override("font_color", end_color.lightened(0.10))

func _edge_key(from_id: String, to_id: String) -> String:
	return "%s->%s" % [from_id, to_id]

func _on_node_pressed(node_id: String) -> void:
	if is_game_over:
		return
	if not adjacency.has(current_node) or not adjacency[current_node].has(node_id):
		return

	if first_attempt_edge.is_empty():
		first_attempt_edge = _edge_key(current_node, node_id)
		first_action_ms = Time.get_ticks_msec() - level_started_ms

	path_sum += int(adjacency[current_node][node_id])
	path.append(node_id)
	current_node = node_id
	_update_visuals()

func _on_reset_pressed() -> void:
	if is_game_over:
		return
	n_reset += 1
	_reset_round_state(false)
	_recalculate_stability()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _on_sum_input_changed(new_text: String) -> void:
	var digits := ""
	for ch in new_text:
		if ch >= "0" and ch <= "9":
			digits += ch
	if digits != new_text:
		sum_input.text = digits
		sum_input.caret_column = digits.length()

func _on_submit_pressed() -> void:
	if is_game_over:
		return

	var verdict := _judge_solution(sum_input.text.strip_edges())
	_log_attempt(verdict)

	if verdict.result_code == "OK":
		status_label.text = "Route accepted. Optimal sum confirmed."
		status_label.add_theme_color_override("font_color", Color(0.38, 1.0, 0.62))
		is_game_over = true
		btn_submit.disabled = true
		btn_reset.disabled = true
		_update_visuals()
		return

	status_label.text = _result_message(str(verdict.result_code))
	status_label.add_theme_color_override("font_color", Color(1.0, 0.62, 0.28))
	_recalculate_stability()

func _result_message(result_code: String) -> String:
	match result_code:
		"ERR_INCOMPLETE":
			return "Reach node E before submit."
		"ERR_PARSE":
			return "Enter digits only."
		"ERR_CALC":
			return "Input sum does not match the selected path."
		"ERR_NOT_OPT":
			return "Path is valid, but not optimal."
		"ERR_PATH_INVALID":
			return "Path is invalid for directed edges."
		_:
			return "Unhandled result: %s" % result_code

func _judge_solution(input_text: String) -> Dictionary:
	var sum_actual := _compute_path_sum()
	var sum_input_value: Variant = null
	var result_code := "OK"

	if sum_actual < 0:
		result_code = "ERR_PATH_INVALID"
	elif current_node != str(level_data.get("end_node", "E")):
		result_code = "ERR_INCOMPLETE"
	elif input_regex.search(input_text) == null:
		n_parse += 1
		result_code = "ERR_PARSE"
	else:
		sum_input_value = int(input_text)
		if int(sum_input_value) != sum_actual:
			n_calc += 1
			result_code = "ERR_CALC"
		elif sum_actual != min_sum:
			n_opt += 1
			result_code = "ERR_NOT_OPT"

	return {
		"result_code": result_code,
		"sum_actual": sum_actual,
		"sum_input": sum_input_value
	}

func _compute_path_sum() -> int:
	var total := 0
	for i in range(path.size() - 1):
		var from_id := path[i]
		var to_id := path[i + 1]
		if not adjacency.has(from_id) or not adjacency[from_id].has(to_id):
			return -1
		total += int(adjacency[from_id][to_id])
	return total

func _recalculate_stability() -> void:
	var trust_cfg: Dictionary = level_data.get("trust", {})
	var overtime_div := int(trust_cfg.get("overtime_div", 2))
	overtime_div = maxi(1, overtime_div)
	var overtime: int = maxi(0, t_elapsed_seconds - int(level_data.get("time_limit_sec", 120)))
	var overtime_penalty := int(floor(float(overtime) / float(overtime_div)))

	var penalties := (
		n_calc * int(trust_cfg.get("penalty_calc", 25))
		+ n_opt * int(trust_cfg.get("penalty_opt", 25))
		+ n_parse * int(trust_cfg.get("penalty_parse", 5))
		+ n_reset * int(trust_cfg.get("penalty_reset", 5))
		+ overtime_penalty
	)

	stability = clampf(float(trust_cfg.get("initial", 100)) - float(penalties), 0.0, 100.0)
	label_state.text = "STABILITY: %d%%" % int(stability)

	if stability <= 10.0 and not is_game_over:
		is_game_over = true
		status_label.text = "MISSION FAILED: STABILITY CRITICAL."
		status_label.add_theme_color_override("font_color", Color(1.0, 0.30, 0.30))
		btn_submit.disabled = true
		btn_reset.disabled = true
		_update_visuals()

func _update_timer_display() -> void:
	var time_limit := int(level_data.get("time_limit_sec", 120))
	var remaining: int = maxi(0, time_limit - t_elapsed_seconds)
	var mm: int = remaining / 60
	var ss: int = remaining % 60
	label_timer.text = "TIME: %02d:%02d" % [mm, ss]
	if t_elapsed_seconds > time_limit:
		label_timer.add_theme_color_override("font_color", Color(1.0, 0.36, 0.36))
	else:
		label_timer.add_theme_color_override("font_color", Color(1, 1, 1))

func _log_attempt(verdict: Dictionary) -> void:
	var sum_actual := int(verdict.get("sum_actual", -1))
	var sum_input_value: Variant = verdict.get("sum_input", null)
	var result_code := str(verdict.get("result_code", "ERR_UNKNOWN"))

	var attempt_no := GlobalMetrics.session_history.size() + 1
	var log_data := {
		"schema_version": "city_map.v2.1.0",
		"quest_id": "CITY_MAP",
		"stage": "A",
		"task_id": str(level_data.get("level_id", "6_1")),
		"match_key": "CITY_MAP|A|%s|v%s" % [str(level_data.get("level_id", "6_1")), config_hash.substr(0, 8)],
		"variant_hash": config_hash,
		"contract_version": str(level_data.get("contract_version", "city_map.v2.1.0")),
		"attempt_no": attempt_no,
		"result_code": result_code,
		"calc_ok": sum_input_value != null and int(sum_input_value) == sum_actual,
		"optimal_ok": sum_actual == min_sum and result_code == "OK",
		"first_attempt_edge": null if first_attempt_edge.is_empty() else first_attempt_edge,
		"t_elapsed_seconds": t_elapsed_seconds,
		"path": path.duplicate(),
		"sum_actual": sum_actual,
		"sum_input": sum_input_value,
		"min_sum": min_sum,
		"stability_final": int(stability),
		"n_calc": n_calc,
		"n_opt": n_opt,
		"n_parse": n_parse,
		"n_reset": n_reset,
		"is_correct": result_code == "OK",
		"is_fit": result_code == "OK",
		"stability_delta": 0,
		"elapsed_ms": t_elapsed_seconds * 1000,
		"duration": float(t_elapsed_seconds),
		"time_to_first_action_ms": first_action_ms if first_action_ms >= 0 else t_elapsed_seconds * 1000,
		"error_type": "NONE" if result_code == "OK" else result_code
	}

	GlobalMetrics.register_trial(log_data)
	_save_json_log(log_data)

func _save_json_log(data: Dictionary) -> void:
	var dir := DirAccess.open("user://")
	if dir == null:
		return
	if not dir.dir_exists("research_logs"):
		dir.make_dir("research_logs")

	var filename := "user://research_logs/%s_%d.json" % [LOG_PREFIX, Time.get_unix_time_from_system()]
	var file := FileAccess.open(filename, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
