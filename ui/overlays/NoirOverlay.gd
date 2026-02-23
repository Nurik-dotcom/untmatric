extends CanvasLayer

@export_range(0.0, 1.0, 0.01) var intensity: float = 0.18
@export var fx_quality: int = 1
@export var tint_color: Color = Color(0.93, 0.93, 0.93, 1.0)

@onready var crt_overlay: ColorRect = $CRT_Overlay

var _shader_material: ShaderMaterial
var _danger_tween: Tween
var _base_glitch_strength: float = 0.0

func _ready() -> void:
	add_to_group("noir_overlay")
	_shader_material = crt_overlay.material as ShaderMaterial
	if _shader_material == null:
		return
	_shader_material.set_shader_parameter("tint_color", tint_color)
	_shader_material.set_shader_parameter("intensity", intensity)
	_shader_material.set_shader_parameter("fx_quality", fx_quality)
	_shader_material.set_shader_parameter("jitter_strength", 0.0)
	_shader_material.set_shader_parameter("glitch_strength", 0.0)
	_shader_material.set_shader_parameter("pulse", 0.0)
	_base_glitch_strength = 0.0

func glitch_burst(strength: float = 0.7, duration: float = 0.2) -> void:
	if _shader_material == null:
		return
	var burst_strength: float = clampf(strength, 0.0, 2.0)
	var burst_duration: float = maxf(0.05, duration)
	_shader_material.set_shader_parameter("glitch_strength", burst_strength)
	var tween := create_tween()
	tween.tween_method(
		func(value: float) -> void:
			_shader_material.set_shader_parameter("glitch_strength", value),
		burst_strength,
		_base_glitch_strength,
		burst_duration
	)

func set_danger_level(stability_percent: float) -> void:
	if _shader_material == null:
		return

	var clamped_stability: float = clampf(stability_percent, 0.0, 100.0)
	var danger: float = 1.0 - (clamped_stability / 100.0)
	var target_jitter: float = danger * 0.4
	var target_glitch: float = danger * 0.5
	var target_pulse: float = danger * 2.0
	_base_glitch_strength = target_glitch

	if _danger_tween != null and _danger_tween.is_valid():
		_danger_tween.kill()
	_danger_tween = create_tween()
	_danger_tween.set_parallel(true)
	_danger_tween.tween_method(
		func(value: float) -> void:
			_shader_material.set_shader_parameter("jitter_strength", value),
		_shader_float("jitter_strength", 0.0),
		target_jitter,
		1.0
	)
	_danger_tween.tween_method(
		func(value: float) -> void:
			_shader_material.set_shader_parameter("glitch_strength", value),
		_shader_float("glitch_strength", 0.0),
		target_glitch,
		1.0
	)
	_danger_tween.tween_method(
		func(value: float) -> void:
			_shader_material.set_shader_parameter("pulse", value),
		_shader_float("pulse", 0.0),
		target_pulse,
		1.0
	)

func _shader_float(param_name: String, fallback: float) -> float:
	if _shader_material == null:
		return fallback
	var value: Variant = _shader_material.get_shader_parameter(param_name)
	if typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT:
		return float(value)
	return fallback
