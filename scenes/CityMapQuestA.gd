extends Control

const PACK_PATH := "res://data/city_map/pack_6_1_A.json"
const LOG_PREFIX := "case_6_1"
const DEFAULT_ACCENT := Color(0.40, 0.72, 1.0, 1.0)
const ARROW_ANGLE_RAD := 0.52
const ARROW_LEN := 16.0

@onready var content_split: SplitContainer = $SafeArea/MainVBox/ContentSplit
@onready var graph_container: Control = $SafeArea/MainVBox/ContentSplit/GraphPanel/GraphMargin/GraphContainer
@onready var edges_layer: Control = $SafeArea/MainVBox/ContentSplit/GraphPanel/GraphMargin/GraphContainer/EdgesLayer
@onready var nodes_layer: Control = $SafeArea/MainVBox/ContentSplit/GraphPanel/GraphMargin/GraphContainer/NodesLayer
@onready var btn_back: Button = $SafeArea/MainVBox/Header/BtnBack
@onready var label_progress: Label = $SafeArea/MainVBox/Header/LabelProgress
@onready var btn_reset: Button = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/ButtonsRow/BtnReset
@onready var btn_submit: Button = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/ButtonsRow/BtnSubmit
@onready var btn_next: Button = $SafeArea/MainVBox/ContentSplit/InfoPanel/InfoMargin/InfoVBox/ButtonsRow/BtnNext
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
var pack_data: Dictionary = {}
var pack_levels: Array = []
var node_defs: Dictionary = {}
var adjacency: Dictionary = {}
var edge_visuals: Dictionary = {}
var node_buttons: Dictionary = {}
var config_hash: String = ""
var input_regex := RegEx.new()
var pack_id: String = "CITY_MAP_A_PACK_01"
var level_index: int = 0
var level_total: int = 0
var run_id: String = ""
var run_started_unix: int = 0
var attempt_in_sublevel: int = 0
var attempt_in_run: int = 0
var levels_completed: int = 0
var levels_perfect: int = 0
var run_total_time_seconds: int = 0
var run_total_calc_errors: int = 0
var run_total_opt_errors: int = 0
var run_total_parse_errors: int = 0
var run_total_resets: int = 0

var min_sum: int = 0
var accent_color: Color = DEFAULT_ACCENT
var node_radius_px: float = 25.0

var current_node: String = ""
var path: Array[String] = []
var path_sum: int = 0
var stability: float = 100.0
var t_elapsed_seconds: int = 0
var is_game_over: bool = false
var stage_completed: bool = false
var input_locked: bool = false
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
	btn_next.pressed.connect(_on_next_pressed)
	sum_input.text_changed.connect(_on_sum_input_changed)
	graph_container.resized.connect(_on_graph_resized)

	_load_pack(PACK_PATH)
	_apply_content_layout_mode()
	_setup_timer()
	call_deferred("_start_pack_run")

func _start_pack_run() -> void:
	run_started_unix = int(Time.get_unix_time_from_system())
	run_id = "CITYMAP_%s_%d" % ["A", run_started_unix]
	level_index = 0
	attempt_in_run = 0
	levels_completed = 0
	levels_perfect = 0
	run_total_time_seconds = 0
	run_total_calc_errors = 0
	run_total_opt_errors = 0
	run_total_parse_errors = 0
	run_total_resets = 0
	_load_sublevel(level_index)

func _load_pack(pack_path: String) -> void:
	pack_data.clear()
	pack_levels.clear()
	level_total = 0

	var file := FileAccess.open(pack_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open pack data: %s" % pack_path)
		pack_levels = [{"id": "6_1_01", "path": "res://data/city_map/level_6_1.json"}]
		level_total = pack_levels.size()
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid pack JSON in %s" % pack_path)
		pack_levels = [{"id": "6_1_01", "path": "res://data/city_map/level_6_1.json"}]
		level_total = pack_levels.size()
		return

	pack_data = parsed
	pack_id = str(pack_data.get("pack_id", "CITY_MAP_A_PACK_01"))
	var raw_levels: Array = pack_data.get("levels", [])
	for level_var in raw_levels:
		if typeof(level_var) != TYPE_DICTIONARY:
			continue
		var level_entry: Dictionary = level_var
		if str(level_entry.get("path", "")).is_empty():
			continue
		pack_levels.append(level_entry)

	if pack_levels.is_empty():
		pack_levels = [{"id": "6_1_01", "path": "res://data/city_map/level_6_1.json"}]
	level_total = pack_levels.size()

func _load_sublevel(index: int) -> void:
	if index < 0 or index >= pack_levels.size():
		return

	level_index = index
	var level_entry := _current_level_entry()
	var level_path := str(level_entry.get("path", ""))
	if level_path.is_empty():
		push_error("Missing level path in pack entry at index %d" % index)
		return

	_load_level_data(level_path)
	attempt_in_sublevel = 0
	is_game_over = false
	stage_completed = false
	input_locked = false
	n_calc = 0
	n_opt = 0
	n_parse = 0
	n_reset = 0
	t_elapsed_seconds = 0

	_set_briefing()
	_rebuild_graph_ui()
	_reset_round_state(true)
	_lock_input(false)
	_update_timer_display()
	_recalculate_stability()
	if is_game_over:
		return
	btn_next.visible = false
	btn_next.disabled = true
	_set_progress_ui()

func _current_level_entry() -> Dictionary:
	if level_index < 0 or level_index >= pack_levels.size():
		return {}
	var level_var: Variant = pack_levels[level_index]
	if typeof(level_var) != TYPE_DICTIONARY:
		return {}
	return level_var

func _set_progress_ui() -> void:
	var shown_index := maxi(1, level_index + 1)
	var total := maxi(1, level_total)
	var level_entry := _current_level_entry()
	var sub_id := str(level_entry.get("id", ""))
	label_progress.text = "ЗАДАНИЕ: %d/%d%s" % [shown_index, total, ("" if sub_id.is_empty() else " • " + sub_id)]
	if level_index >= total - 1:
		btn_next.text = "ЗАВЕРШИТЬ"
	else:
		btn_next.text = "ДАЛЕЕ"

func _is_round_locked() -> bool:
	return is_game_over or stage_completed or input_locked

func _lock_input(locked: bool) -> void:
	input_locked = locked
	sum_input.editable = not locked and not is_game_over and not stage_completed
	btn_submit.disabled = locked or is_game_over or stage_completed
	btn_reset.disabled = locked or is_game_over or stage_completed
	_update_visuals()

func _on_next_pressed() -> void:
	if not stage_completed:
		return
	if level_index + 1 >= level_total:
		_finalize_pack_run()
		get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")
		return
	_load_sublevel(level_index + 1)

func _finalize_pack_run() -> void:
	var summary := {
		"schema_version": "city_map.run.v1",
		"quest_id": "CITY_MAP",
		"mode": "A",
		"run_id": run_id,
		"pack_id": pack_id,
		"levels_total": level_total,
		"levels_completed": levels_completed,
		"levels_perfect": levels_perfect,
		"total_time_seconds": run_total_time_seconds,
		"total_calc_errors": run_total_calc_errors,
		"total_opt_errors": run_total_opt_errors,
		"total_parse_errors": run_total_parse_errors,
		"total_reset_errors": run_total_resets,
		"finished_at_unix": int(Time.get_unix_time_from_system())
	}
	_save_json_log(summary, true)

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
	if is_game_over or stage_completed or level_data.is_empty():
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
	briefing_title.text = "АУДИТ МАРШРУТА"
	briefing_text.text = "Доберитесь до узла E по направленным дорогам. Введите итоговую сумму пути и отправьте. Проходит только минимальный маршрут."
	footer_label.text = "Ориентированный граф: нажимать можно только исходящие дороги из текущего узла."

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
	path_display.text = "ПУТЬ: %s" % " -> ".join(path)
	sum_live_label.text = "СУММА: %d" % path_sum

	for node_id in node_buttons.keys():
		var btn: Button = node_buttons[node_id]
		var is_current: bool = node_id == current_node
		var is_available: bool = adjacency.has(current_node) and adjacency[current_node].has(node_id)
		btn.disabled = is_current or not is_available or _is_round_locked()
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
	if _is_round_locked():
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
	if _is_round_locked():
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
	if _is_round_locked():
		return

	attempt_in_sublevel += 1
	attempt_in_run += 1
	var verdict := _judge_solution(sum_input.text.strip_edges())
	_log_attempt(verdict)

	if verdict.result_code == "OK":
		status_label.text = "Маршрут принят. Оптимальная сумма подтверждена."
		status_label.add_theme_color_override("font_color", Color(0.38, 1.0, 0.62))
		stage_completed = true
		levels_completed += 1
		run_total_time_seconds += t_elapsed_seconds
		run_total_calc_errors += n_calc
		run_total_opt_errors += n_opt
		run_total_parse_errors += n_parse
		run_total_resets += n_reset
		if attempt_in_sublevel == 1:
			levels_perfect += 1
		btn_next.visible = true
		btn_next.disabled = false
		_lock_input(true)
		_set_progress_ui()
		return

	status_label.text = _result_message(str(verdict.result_code))
	status_label.add_theme_color_override("font_color", Color(1.0, 0.62, 0.28))
	_recalculate_stability()

func _result_message(result_code: String) -> String:
	match result_code:
		"ERR_INCOMPLETE":
			return "Дойдите до узла E перед отправкой."
		"ERR_PARSE":
			return "Вводите только цифры."
		"ERR_CALC":
			return "Введённая сумма не совпадает с выбранным маршрутом."
		"ERR_NOT_OPT":
			return "Маршрут корректный, но не оптимальный."
		"ERR_PATH_INVALID":
			return "Маршрут недопустим для ориентированных рёбер."
		_:
			return "Необработанный результат: %s" % result_code

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
	label_state.text = "СТАБИЛЬНОСТЬ: %d%%" % int(stability)

	if stability <= 10.0 and not is_game_over:
		is_game_over = true
		stage_completed = false
		status_label.text = "МИССИЯ ПРОВАЛЕНА: КРИТИЧЕСКАЯ СТАБИЛЬНОСТЬ."
		status_label.add_theme_color_override("font_color", Color(1.0, 0.30, 0.30))
		btn_next.visible = false
		btn_next.disabled = true
		_lock_input(true)

func _update_timer_display() -> void:
	var time_limit := int(level_data.get("time_limit_sec", 120))
	var remaining: int = maxi(0, time_limit - t_elapsed_seconds)
	var mm: int = remaining / 60
	var ss: int = remaining % 60
	label_timer.text = "ВРЕМЯ: %02d:%02d" % [mm, ss]
	if t_elapsed_seconds > time_limit:
		label_timer.add_theme_color_override("font_color", Color(1.0, 0.36, 0.36))
	else:
		label_timer.add_theme_color_override("font_color", Color(1, 1, 1))

func _log_attempt(verdict: Dictionary) -> void:
	var sum_actual := int(verdict.get("sum_actual", -1))
	var sum_input_value: Variant = verdict.get("sum_input", null)
	var result_code := str(verdict.get("result_code", "ERR_UNKNOWN"))
	var level_entry := _current_level_entry()
	var sublevel_id := str(level_entry.get("id", "6_1_%02d" % (level_index + 1)))
	var sublevel_path := str(level_entry.get("path", ""))
	var next_available := result_code == "OK" and level_index + 1 < level_total

	var attempt_no := GlobalMetrics.session_history.size() + 1
	var log_data := {
		"schema_version": "city_map.v2.2.0",
		"quest_id": "CITY_MAP",
		"stage": "A",
		"task_id": str(level_data.get("level_id", "6_1")),
		"run_id": run_id,
		"pack_id": pack_id,
		"sublevel_index": level_index + 1,
		"sublevel_total": level_total,
		"sublevel_id": sublevel_id,
		"sublevel_path": sublevel_path,
		"attempt_in_sublevel": attempt_in_sublevel,
		"attempt_in_run": attempt_in_run,
		"next_available": next_available,
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

func _save_json_log(data: Dictionary, is_summary: bool = false) -> void:
	var dir := DirAccess.open("user://")
	if dir == null:
		return
	if not dir.dir_exists("research_logs"):
		dir.make_dir("research_logs")

	var stamp_msec: int = Time.get_ticks_msec()
	var attempt_tag := ""
	if data.has("attempt_in_run"):
		attempt_tag = "_a%s" % str(data.get("attempt_in_run"))

	var filename := "user://research_logs/%s_%s_%d%s.json" % [LOG_PREFIX, run_id, stamp_msec, attempt_tag]
	if is_summary:
		filename = "user://research_logs/%s_run_%s_%d.json" % [LOG_PREFIX, run_id, stamp_msec]
	var file := FileAccess.open(filename, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
