extends Control

@export var packet_color: Color = Color(0.88, 0.92, 0.98, 1.0)
@export var attacker_color: Color = Color(0.95, 0.3, 0.35, 1.0)
@export var packet_count: int = 18
@export_range(0.2, 2.0, 0.01) var speed: float = 1.0
@export_range(0.0, 1.0, 0.01) var scatter: float = 0.2
@export_range(0.0, 1.0, 0.01) var steal_rate: float = 0.0
@export_range(0.0, 1.0, 0.01) var attacker_alpha: float = 0.9

var _phase: float = 0.0
var _verdict_code: String = "IDLE"

func _process(delta: float) -> void:
	_phase = fmod(_phase + delta * speed, 1.0)
	queue_redraw()

func configure_from_verdict(verdict_code: String, visual_sim: Dictionary, risk: Dictionary = {}) -> void:
	_verdict_code = verdict_code
	var config: Dictionary = visual_sim.get(verdict_code, {}) as Dictionary
	if config.is_empty():
		config = visual_sim.get("FAIL", {}) as Dictionary
	speed = float(config.get("speed", 1.0))
	scatter = float(config.get("scatter", 0.2))
	packet_count = int(config.get("packet_count", 18))
	steal_rate = float(config.get("steal_rate", 0.0))
	attacker_alpha = clampf(float(config.get("attacker_alpha", 0.9)), 0.0, 1.0)
	packet_color = _parse_color(config.get("packet_tint", packet_color))
	attacker_color = _parse_color(config.get("attacker_tint", attacker_color))
	_apply_risk_modulation(risk)
	queue_redraw()

func reset_to_idle() -> void:
	_verdict_code = "IDLE"
	speed = 1.0
	scatter = 0.2
	steal_rate = 0.0
	packet_count = 18
	attacker_alpha = 0.9
	packet_color = Color(0.88, 0.92, 0.98, 1.0)
	attacker_color = Color(0.95, 0.3, 0.35, 1.0)
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
	draw_circle(attacker, 6.0, Color(attacker_color.r, attacker_color.g, attacker_color.b, attacker_alpha))

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
			draw_line(packet_pos, attacker, Color(attacker_color.r, attacker_color.g, attacker_color.b, attacker_alpha), 1.2, true)

func _parse_color(raw_value: Variant) -> Color:
	match typeof(raw_value):
		TYPE_COLOR:
			return raw_value as Color
		TYPE_STRING:
			var raw_text: String = str(raw_value).strip_edges()
			if raw_text.is_empty():
				return Color.WHITE
			return Color(raw_text)
		_:
			return Color.WHITE

func _apply_risk_modulation(risk: Dictionary) -> void:
	if risk.is_empty():
		return
	var eavesdrop: String = str(risk.get("eavesdrop", "MID"))
	var filtering: String = str(risk.get("filtering", "OFF"))
	var media: String = str(risk.get("media", "UNKNOWN"))

	if eavesdrop == "HIGH":
		steal_rate = clampf(steal_rate + 0.12, 0.0, 1.0)
		attacker_alpha = clampf(attacker_alpha + 0.08, 0.0, 1.0)
	elif eavesdrop == "LOW":
		steal_rate = clampf(steal_rate - 0.05, 0.0, 1.0)

	if filtering == "ON":
		steal_rate = clampf(steal_rate - 0.06, 0.0, 1.0)
	if media == "FIBER":
		scatter = clampf(scatter - 0.05, 0.0, 1.0)
