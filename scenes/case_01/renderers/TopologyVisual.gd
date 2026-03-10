extends Control

var _topology_type: String = "star"

func set_topology(topology_type: String) -> void:
	_topology_type = topology_type.to_lower()
	queue_redraw()

func _draw() -> void:
	var s: Vector2 = size
	var cx: float = s.x * 0.5
	var cy: float = s.y * 0.5
	var r: float = minf(s.x, s.y) * 0.33
	var node_count: int = 6
	var node_radius: float = 10.0
	var node_color: Color = Color(0.72, 0.82, 0.95)
	var line_color: Color = Color(0.55, 0.6, 0.7, 0.8)

	match _topology_type:
		"star":
			draw_circle(Vector2(cx, cy), node_radius * 1.3, Color(0.95, 0.75, 0.3))
			for i in range(node_count):
				var angle: float = TAU * float(i) / float(node_count) - PI * 0.5
				var pos: Vector2 = Vector2(cx + cos(angle) * r, cy + sin(angle) * r)
				draw_line(Vector2(cx, cy), pos, line_color, 2.0)
				draw_circle(pos, node_radius, node_color)
		"bus":
			var y_bus: float = cy
			draw_line(Vector2(40, y_bus), Vector2(s.x - 40, y_bus), line_color, 3.0)
			for i in range(node_count):
				var x: float = lerpf(60.0, s.x - 60.0, float(i) / float(max(1, node_count - 1)))
				draw_line(Vector2(x, y_bus), Vector2(x, y_bus - 40.0), line_color, 2.0)
				draw_circle(Vector2(x, y_bus - 40.0), node_radius, node_color)
		"ring":
			for i in range(node_count):
				var a1: float = TAU * float(i) / float(node_count) - PI * 0.5
				var a2: float = TAU * float((i + 1) % node_count) / float(node_count) - PI * 0.5
				var p1: Vector2 = Vector2(cx + cos(a1) * r, cy + sin(a1) * r)
				var p2: Vector2 = Vector2(cx + cos(a2) * r, cy + sin(a2) * r)
				draw_line(p1, p2, line_color, 2.0)
				draw_circle(p1, node_radius, node_color)
		"mesh":
			var positions: Array[Vector2] = []
			for i in range(node_count):
				var angle: float = TAU * float(i) / float(node_count) - PI * 0.5
				positions.append(Vector2(cx + cos(angle) * r, cy + sin(angle) * r))
			for i in range(node_count):
				for j in range(i + 1, node_count):
					draw_line(positions[i], positions[j], Color(line_color.r, line_color.g, line_color.b, 0.35), 1.0)
			for pos in positions:
				draw_circle(pos, node_radius, node_color)
		_:
			draw_string(get_theme_default_font(), Vector2(20, 32), _topology_type)
