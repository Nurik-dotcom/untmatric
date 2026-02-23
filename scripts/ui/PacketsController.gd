extends Control

@export var packet_color: Color = Color(0.88, 0.92, 0.98, 1.0)
@export var attacker_color: Color = Color(0.95, 0.3, 0.35, 1.0)
@export var packet_count: int = 18
@export_range(0.2, 2.0, 0.01) var speed: float = 1.0
@export_range(0.0, 1.0, 0.01) var scatter: float = 0.2
@export_range(0.0, 1.0, 0.01) var steal_rate: float = 0.0

var _phase: float = 0.0
var _verdict_code: String = "IDLE"

func _process(delta: float) -> void:
	_phase = fmod(_phase + delta * speed, 1.0)
	queue_redraw()

func configure_from_verdict(verdict_code: String, visual_sim: Dictionary) -> void:
	_verdict_code = verdict_code
	var config: Dictionary = visual_sim.get(verdict_code, {}) as Dictionary
	if config.is_empty():
		config = visual_sim.get("FAIL", {}) as Dictionary
	speed = float(config.get("speed", 1.0))
	scatter = float(config.get("scatter", 0.2))
	steal_rate = float(config.get("steal_rate", 0.0))
	queue_redraw()

func reset_to_idle() -> void:
	_verdict_code = "IDLE"
	speed = 1.0
	scatter = 0.2
	steal_rate = 0.0
	_phase = 0.0
	queue_redraw()

func _draw() -> void:
	var size: Vector2 = get_size()
	var center_y: float = size.y * 0.5
	var source: Vector2 = Vector2(20.0, center_y)
	var target: Vector2 = Vector2(size.x - 20.0, center_y)
	var attacker: Vector2 = Vector2(size.x * 0.55, size.y * 0.18)

	draw_line(source, target, Color(0.7, 0.75, 0.82, 0.85), 2.0, true)
	draw_circle(source, 7.0, Color(0.72, 0.78, 0.9, 1.0))
	draw_circle(target, 7.0, Color(0.72, 0.78, 0.9, 1.0))
	draw_circle(attacker, 6.0, attacker_color)

	if packet_count <= 0:
		return

	for i in range(packet_count):
		var t: float = fmod(_phase + (float(i) / float(packet_count)), 1.0)
		var x: float = lerpf(source.x, target.x, t)
		var wobble: float = sin((t * TAU * 6.0) + float(i)) * 18.0 * scatter
		var y: float = center_y + wobble
		var packet_pos: Vector2 = Vector2(x, y)
		draw_circle(packet_pos, 2.6, packet_color)

		var steal_threshold: float = steal_rate * 100.0
		var gate: float = fmod(float(i) * 19.0 + floor(t * 100.0), 100.0)
		if gate < steal_threshold:
			draw_line(packet_pos, attacker, attacker_color, 1.2, true)
