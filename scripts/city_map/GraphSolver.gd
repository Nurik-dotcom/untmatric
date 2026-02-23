extends RefCounted
class_name GraphSolver

const INF := 1_000_000_000


func build_weight_adjacency(edges: Array, directed_default: bool = true) -> Dictionary:
	var adjacency: Dictionary = {}
	for edge_var in edges:
		if typeof(edge_var) != TYPE_DICTIONARY:
			continue
		var edge: Dictionary = edge_var
		var from_id := str(edge.get("from", ""))
		var to_id := str(edge.get("to", ""))
		if from_id.is_empty() or to_id.is_empty():
			continue

		var weight := int(edge.get("w", 0))
		if not adjacency.has(from_id):
			adjacency[from_id] = {}
		var out_neighbors: Dictionary = adjacency[from_id]
		out_neighbors[to_id] = weight
		adjacency[from_id] = out_neighbors

		var two_way := bool(edge.get("two_way", false))
		if two_way or not directed_default:
			if not adjacency.has(to_id):
				adjacency[to_id] = {}
			var back_neighbors: Dictionary = adjacency[to_id]
			back_neighbors[from_id] = weight
			adjacency[to_id] = back_neighbors

	return adjacency


func build_edge_adjacency(edges: Array, directed_default: bool = true) -> Dictionary:
	var adjacency: Dictionary = {}
	for edge_var in edges:
		if typeof(edge_var) != TYPE_DICTIONARY:
			continue
		var edge: Dictionary = edge_var
		var from_id := str(edge.get("from", ""))
		var to_id := str(edge.get("to", ""))
		if from_id.is_empty() or to_id.is_empty():
			continue

		if not adjacency.has(from_id):
			adjacency[from_id] = {}
		var out_neighbors: Dictionary = adjacency[from_id]
		out_neighbors[to_id] = edge.duplicate(true)
		adjacency[from_id] = out_neighbors

		var two_way := bool(edge.get("two_way", false))
		if two_way or not directed_default:
			if not adjacency.has(to_id):
				adjacency[to_id] = {}
			var reverse_edge := edge.duplicate(true)
			reverse_edge["from"] = to_id
			reverse_edge["to"] = from_id
			var back_neighbors: Dictionary = adjacency[to_id]
			back_neighbors[from_id] = reverse_edge
			adjacency[to_id] = back_neighbors

	return adjacency


func compute_min_sum_basic(node_ids: Array, adjacency: Dictionary, start_node: String, end_node: String) -> int:
	if start_node.is_empty() or end_node.is_empty():
		return 0

	var dist: Dictionary = {}
	var unvisited: Array[String] = []
	for node_var in node_ids:
		var node_id := str(node_var)
		dist[node_id] = INF
		unvisited.append(node_id)

	if not dist.has(start_node):
		dist[start_node] = 0
		unvisited.append(start_node)
	if not dist.has(end_node):
		dist[end_node] = INF
		unvisited.append(end_node)

	dist[start_node] = 0

	while not unvisited.is_empty():
		var best_index := -1
		var best_cost := INF
		for i in range(unvisited.size()):
			var node_id := str(unvisited[i])
			var candidate := int(dist.get(node_id, INF))
			if candidate < best_cost:
				best_cost = candidate
				best_index = i

		if best_index < 0:
			break

		var current := str(unvisited[best_index])
		unvisited.remove_at(best_index)
		if current == end_node:
			break

		var neighbors: Dictionary = adjacency.get(current, {})
		for next_id_var in neighbors.keys():
			var next_id := str(next_id_var)
			var alt := best_cost + int(neighbors[next_id_var])
			if alt < int(dist.get(next_id, INF)):
				dist[next_id] = alt
				if not unvisited.has(next_id):
					unvisited.append(next_id)

	var result := int(dist.get(end_node, INF))
	return 0 if result >= INF else result


func compute_min_sum_with_constraints(
		adjacency: Dictionary,
		start_node: String,
		end_node: String,
		must_visit_nodes: Array,
		max_visits_per_node: int = 2
	) -> int:
	if start_node.is_empty() or end_node.is_empty():
		return 0

	var frontier: Array[Dictionary] = [{
		"node": start_node,
		"cost": 0,
		"path": [start_node]
	}]
	var best := INF

	while not frontier.is_empty():
		var best_index := _lowest_cost_index(frontier)
		var state: Dictionary = frontier.pop_at(best_index)

		var node_id := str(state.get("node", ""))
		var cost := int(state.get("cost", INF))
		var path_local: Array = state.get("path", [])
		if cost >= best:
			continue

		if node_id == end_node and path_has_all(path_local, must_visit_nodes):
			best = min(best, cost)
			continue

		var neighbors: Dictionary = adjacency.get(node_id, {})
		for next_id_var in neighbors.keys():
			var next_id := str(next_id_var)
			if _count_visits(path_local, next_id) >= max_visits_per_node:
				continue
			frontier.append({
				"node": next_id,
				"cost": cost + int(neighbors[next_id_var]),
				"path": path_local + [next_id]
			})

	return 0 if best >= INF else best


func compute_min_sum_dynamic(
		edge_adjacency: Dictionary,
		start_node: String,
		end_node: String,
		must_visit_nodes: Array,
		xor_groups: Array,
		blacklist_nodes: Array,
		start_sim_time_sec: int = 0,
		max_visits_per_node: int = 2
	) -> int:
	if start_node.is_empty() or end_node.is_empty():
		return 0

	var frontier: Array[Dictionary] = [{
		"node": start_node,
		"sim": start_sim_time_sec,
		"cost": 0,
		"path": [start_node]
	}]
	var best := INF

	while not frontier.is_empty():
		var best_index := _lowest_cost_index(frontier)
		var state: Dictionary = frontier.pop_at(best_index)

		var node_id := str(state.get("node", ""))
		var sim := int(state.get("sim", 0))
		var cost := int(state.get("cost", INF))
		var path_local: Array = state.get("path", [])
		if cost >= best:
			continue

		if node_id == end_node \
				and path_has_all(path_local, must_visit_nodes) \
				and not path_violates_xor(path_local, xor_groups) \
				and not path_has_any(path_local, blacklist_nodes):
			best = min(best, cost)
			continue

		var neighbors: Dictionary = edge_adjacency.get(node_id, {})
		for next_id_var in neighbors.keys():
			var next_id := str(next_id_var)
			var edge: Dictionary = neighbors[next_id_var]
			var runtime := edge_runtime_state(edge, sim)
			if str(runtime.get("state", "open")) == "closed":
				continue

			if _count_visits(path_local, next_id) >= max_visits_per_node:
				continue

			var next_path := path_local + [next_id]
			if path_violates_xor(next_path, xor_groups):
				continue
			if path_has_any(next_path, blacklist_nodes):
				continue

			var weight := int(runtime.get("weight", edge.get("w", 0)))
			frontier.append({
				"node": next_id,
				"sim": sim + weight,
				"cost": cost + weight,
				"path": next_path
			})

	return 0 if best >= INF else best


func edge_runtime_state(edge: Dictionary, time_sec: int) -> Dictionary:
	var base_weight := int(edge.get("w", 0))
	var active_weight := base_weight
	var active_state := str(edge.get("state", "open"))
	var next_change_sec := -1

	var schedule: Array = edge.get("schedule", [])
	if not schedule.is_empty():
		active_state = "open"
		for slot_var in schedule:
			if typeof(slot_var) != TYPE_DICTIONARY:
				continue
			var slot: Dictionary = slot_var
			var t_from := int(slot.get("t_from", 0))
			var t_to := int(slot.get("t_to", 0))
			if time_sec >= t_from and time_sec < t_to:
				active_state = str(slot.get("state", "open"))
				active_weight = int(slot.get("w", base_weight))
				next_change_sec = max(0, t_to - time_sec)
				break
			if time_sec < t_from:
				var until_change := t_from - time_sec
				if next_change_sec < 0 or until_change < next_change_sec:
					next_change_sec = until_change

	return {
		"weight": active_weight,
		"base_weight": base_weight,
		"state": active_state,
		"danger": active_state != "closed" and active_weight > base_weight,
		"next_change_sec": next_change_sec
	}


func path_has_all(path_local: Array, required_nodes: Array) -> bool:
	for node_var in required_nodes:
		if not path_local.has(str(node_var)):
			return false
	return true


func path_has_any(path_local: Array, blocked_nodes: Array) -> bool:
	for node_var in blocked_nodes:
		if path_local.has(str(node_var)):
			return true
	return false


func path_violates_xor(path_local: Array, xor_groups: Array) -> bool:
	for group_var in xor_groups:
		if typeof(group_var) != TYPE_DICTIONARY:
			continue
		var group: Dictionary = group_var
		if str(group.get("type", "AT_MOST_ONE")) != "AT_MOST_ONE":
			continue
		var hits := 0
		for node_var in group.get("nodes", []):
			if path_local.has(str(node_var)):
				hits += 1
		if hits > 1:
			return true
	return false


func compute_weighted_path_sum(path_local: Array, adjacency: Dictionary) -> int:
	var total := 0
	for i in range(path_local.size() - 1):
		var from_id := str(path_local[i])
		var to_id := str(path_local[i + 1])
		if not adjacency.has(from_id):
			return -1
		var neighbors: Dictionary = adjacency[from_id]
		if not neighbors.has(to_id):
			return -1
		total += int(neighbors[to_id])
	return total


func compute_step_weight_sum(path_local: Array, step_weights: Array) -> int:
	if path_local.size() <= 1:
		return 0
	if step_weights.size() < path_local.size() - 1:
		return -1
	var total := 0
	for i in range(path_local.size() - 1):
		total += int(step_weights[i])
	return total


func simulate_dynamic_path(path_local: Array, edge_adjacency: Dictionary, start_sim_time_sec: int = 0) -> Dictionary:
	var sim := start_sim_time_sec
	var total := 0
	var closed_attempts := 0
	var danger_steps := 0
	var weights: Array[int] = []

	for i in range(path_local.size() - 1):
		var from_id := str(path_local[i])
		var to_id := str(path_local[i + 1])
		if not edge_adjacency.has(from_id):
			return {
				"sum": -1,
				"sim_end": sim,
				"closed_attempts": closed_attempts,
				"danger_steps": danger_steps,
				"weights": weights
			}
		var neighbors: Dictionary = edge_adjacency[from_id]
		if not neighbors.has(to_id):
			return {
				"sum": -1,
				"sim_end": sim,
				"closed_attempts": closed_attempts,
				"danger_steps": danger_steps,
				"weights": weights
			}

		var edge: Dictionary = neighbors[to_id]
		var runtime := edge_runtime_state(edge, sim)
		var state := str(runtime.get("state", "open"))
		if state == "closed":
			closed_attempts += 1
			return {
				"sum": -1,
				"sim_end": sim,
				"closed_attempts": closed_attempts,
				"danger_steps": danger_steps,
				"weights": weights
			}

		if bool(runtime.get("danger", false)):
			danger_steps += 1

		var weight := int(runtime.get("weight", edge.get("w", 0)))
		weights.append(weight)
		total += weight
		sim += weight

	return {
		"sum": total,
		"sim_end": sim,
		"closed_attempts": closed_attempts,
		"danger_steps": danger_steps,
		"weights": weights
	}


func _lowest_cost_index(frontier: Array) -> int:
	var best_index := 0
	for i in range(1, frontier.size()):
		if int(frontier[i].get("cost", INF)) < int(frontier[best_index].get("cost", INF)):
			best_index = i
	return best_index


func _count_visits(path_local: Array, node_id: String) -> int:
	var count := 0
	for step in path_local:
		if str(step) == node_id:
			count += 1
	return count
