extends RefCounted
class_name GraphRenderer

const DEFAULT_DIM_START := Color(0.18, 0.22, 0.30, 0.28)
const DEFAULT_DIM_END := Color(0.30, 0.38, 0.52, 0.48)


func minimum_hit_radius(node_radius_px: float, min_hit_target_px: float = 48.0) -> float:
	return maxf(node_radius_px, maxf(0.0, min_hit_target_px) * 0.5)


func build_deterministic_jitter(node_defs: Dictionary, seed_source: String, max_abs_px: float = 6.0) -> Dictionary:
	var offsets: Dictionary = {}
	var amplitude := maxf(0.0, max_abs_px)

	for node_id_var in node_defs.keys():
		var node_id := str(node_id_var)
		var x_key := "%s|%s|x" % [seed_source, node_id]
		var y_key := "%s|%s|y" % [seed_source, node_id]
		offsets[node_id] = Vector2(_hash_to_unit(x_key), _hash_to_unit(y_key)) * amplitude

	return offsets


func compute_node_positions(
		node_defs: Dictionary,
		canvas_size: Vector2,
		node_radius_px: float,
		jitter_offsets: Dictionary = {},
		padding_px: float = 8.0
	) -> Dictionary:
	var positions: Dictionary = {}
	if canvas_size.x <= 0.0 or canvas_size.y <= 0.0:
		return positions

	var effective_padding := maxf(node_radius_px + 4.0, padding_px)
	var usable := canvas_size - Vector2(effective_padding * 2.0, effective_padding * 2.0)
	usable.x = maxf(1.0, usable.x)
	usable.y = maxf(1.0, usable.y)

	var normalized := _all_nodes_normalized(node_defs)
	if normalized:
		for node_id_var in node_defs.keys():
			var node_id := str(node_id_var)
			var node: Dictionary = node_defs[node_id_var]
			var pos: Dictionary = node.get("pos", {})
			var x := float(pos.get("x", 0.0))
			var y := float(pos.get("y", 0.0))
			var p := Vector2(
				effective_padding + x * usable.x,
				effective_padding + y * usable.y
			)
			if jitter_offsets.has(node_id):
				p += jitter_offsets[node_id]
			positions[node_id] = p
		return positions

	var raw_points: Dictionary = {}
	var min_point := Vector2(1e20, 1e20)
	var max_point := Vector2(-1e20, -1e20)
	for node_id_var in node_defs.keys():
		var node_id := str(node_id_var)
		var node: Dictionary = node_defs[node_id_var]
		var pos: Dictionary = node.get("pos", {})
		var p := Vector2(float(pos.get("x", 0.0)), float(pos.get("y", 0.0)))
		raw_points[node_id] = p
		min_point = Vector2(minf(min_point.x, p.x), minf(min_point.y, p.y))
		max_point = Vector2(maxf(max_point.x, p.x), maxf(max_point.y, p.y))

	var box_size := max_point - min_point
	box_size.x = maxf(1.0, box_size.x)
	box_size.y = maxf(1.0, box_size.y)

	var scale := minf(usable.x / box_size.x, usable.y / box_size.y)
	var fitted := box_size * scale
	var origin := Vector2(
		effective_padding + (usable.x - fitted.x) * 0.5,
		effective_padding + (usable.y - fitted.y) * 0.5
	)

	for node_id_var in raw_points.keys():
		var node_id := str(node_id_var)
		var raw_point: Vector2 = Vector2(raw_points[node_id_var])
		var fitted_pos: Vector2 = origin + (raw_point - min_point) * scale
		if jitter_offsets.has(node_id):
			fitted_pos += Vector2(jitter_offsets[node_id])
		positions[node_id] = fitted_pos

	return positions


func build_edge_points(start_pos: Vector2, end_pos: Vector2, bend: float, bake_interval: float = 10.0) -> PackedVector2Array:
	if start_pos.distance_to(end_pos) <= 0.001:
		return PackedVector2Array([start_pos, end_pos])

	var clamped_bend := clampf(bend, -1.0, 1.0)
	if absf(clamped_bend) <= 0.0001:
		return PackedVector2Array([start_pos, end_pos])

	var chord := end_pos - start_pos
	var normal := Vector2(-chord.y, chord.x).normalized()
	var midpoint := (start_pos + end_pos) * 0.5
	var arc_offset := normal * chord.length() * 0.35 * clamped_bend
	var control := midpoint + arc_offset

	var curve := Curve2D.new()
	curve.bake_interval = maxf(4.0, bake_interval)
	curve.add_point(start_pos, Vector2.ZERO, (control - start_pos) * 0.66)
	curve.add_point(end_pos, (control - end_pos) * 0.66, Vector2.ZERO)

	var points := curve.get_baked_points()
	if points.size() < 2:
		return PackedVector2Array([start_pos, end_pos])
	return points


func edge_label_position(edge_points: PackedVector2Array, normal_offset: float = 12.0) -> Vector2:
	if edge_points.is_empty():
		return Vector2.ZERO
	if edge_points.size() == 1:
		return edge_points[0] - Vector2(10.0, 10.0)

	var mid: int = int(edge_points.size() / 2.0)
	var p := edge_points[mid]
	var a := edge_points[maxi(0, mid - 1)]
	var b := edge_points[mini(edge_points.size() - 1, mid + 1)]
	var tangent := (b - a).normalized()
	if tangent.length() <= 0.0001:
		tangent = Vector2.RIGHT
	var normal := Vector2(-tangent.y, tangent.x)
	return p + normal * normal_offset - Vector2(10.0, 10.0)


func compute_fit_transform(node_positions: Dictionary, viewport_size: Vector2, margin_px: float = 24.0) -> Dictionary:
	if node_positions.is_empty() or viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return {
			"scale": 1.0,
			"offset": Vector2.ZERO,
			"bounds": Rect2()
		}

	var min_point := Vector2(1e20, 1e20)
	var max_point := Vector2(-1e20, -1e20)
	for p_var in node_positions.values():
		var p := Vector2(p_var)
		min_point = Vector2(minf(min_point.x, p.x), minf(min_point.y, p.y))
		max_point = Vector2(maxf(max_point.x, p.x), maxf(max_point.y, p.y))

	var graph_size := max_point - min_point
	graph_size.x = maxf(1.0, graph_size.x)
	graph_size.y = maxf(1.0, graph_size.y)

	var target := viewport_size - Vector2(margin_px * 2.0, margin_px * 2.0)
	target.x = maxf(1.0, target.x)
	target.y = maxf(1.0, target.y)
	var scale := minf(target.x / graph_size.x, target.y / graph_size.y)
	var scaled_size := graph_size * scale

	var offset := Vector2(
		margin_px + (target.x - scaled_size.x) * 0.5 - min_point.x * scale,
		margin_px + (target.y - scaled_size.y) * 0.5 - min_point.y * scale
	)

	return {
		"scale": scale,
		"offset": offset,
		"bounds": Rect2(min_point, graph_size)
	}


func style_for_state(state: String, accent_color: Color, runtime: Dictionary = {}) -> Dictionary:
	var start_color := DEFAULT_DIM_START
	var end_color := DEFAULT_DIM_END
	var label_text := ""

	match state:
		"available":
			start_color = Color(0.24, 0.40, 0.62, 0.48)
			end_color = accent_color
			end_color.a = 0.95
		"traversed":
			start_color = accent_color.lightened(0.10)
			start_color.a = 0.80
			end_color = Color(0.92, 0.97, 1.0, 1.0)
		"danger":
			start_color = Color(0.62, 0.35, 0.12, 0.60)
			end_color = Color(1.0, 0.62, 0.18, 1.0)
			if runtime.has("weight"):
				label_text = "%d DANGER" % int(runtime.get("weight", 0))
		"closed":
			start_color = Color(0.58, 0.14, 0.14, 0.55)
			end_color = Color(1.0, 0.25, 0.25, 1.0)
			label_text = "CLOSED"
		"cycle":
			start_color = Color(0.72, 0.26, 0.22, 0.70)
			end_color = Color(1.0, 0.44, 0.30, 1.0)
			label_text = "LOOP"
		_:
			pass

	return {
		"start_color": start_color,
		"end_color": end_color,
		"label_text": label_text
	}


func _all_nodes_normalized(node_defs: Dictionary) -> bool:
	for node_var in node_defs.values():
		if typeof(node_var) != TYPE_DICTIONARY:
			return false
		var node: Dictionary = node_var
		var pos: Dictionary = node.get("pos", {})
		var x := float(pos.get("x", -1.0))
		var y := float(pos.get("y", -1.0))
		if x < 0.0 or x > 1.0 or y < 0.0 or y > 1.0:
			return false
	return true


func _hash_to_unit(source: String) -> float:
	var hash := 2166136261
	for i in range(source.length()):
		hash = hash ^ source.unicode_at(i)
		hash = int((hash * 16777619) & 0x7fffffff)
	return (float(hash) / float(0x7fffffff)) * 2.0 - 1.0
