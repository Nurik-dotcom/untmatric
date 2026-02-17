extends CanvasLayer

@export_range(0.0, 1.0, 0.01) var intensity: float = 0.12
@export var fx_quality: int = 1
@export var tint_color: Color = Color(0.0, 1.0, 0.25, 1.0)

@onready var crt_overlay: ColorRect = $CRT_Overlay

var _shader_material: ShaderMaterial

func _ready() -> void:
	_shader_material = crt_overlay.material as ShaderMaterial
	if _shader_material == null:
		return
	_shader_material.set_shader_parameter("tint_color", tint_color)
	_shader_material.set_shader_parameter("intensity", intensity)
	_shader_material.set_shader_parameter("fx_quality", fx_quality)
	_shader_material.set_shader_parameter("glitch_strength", 0.0)

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
		0.0,
		burst_duration
	)
