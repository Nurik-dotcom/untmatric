extends CanvasLayer

@export_range(0.0, 1.0, 0.01) var intensity: float = 0.18
@export var fx_quality: int = 1
@export var tint_color: Color = Color(0.93, 0.93, 0.93, 1.0)
@export_enum("CRT", "PENCIL", "ENHANCED") var overlay_mode: String = "ENHANCED"

@onready var crt_overlay: ColorRect = get_node_or_null("CRT_Overlay") as ColorRect

var _shader_material: ShaderMaterial
var _danger_tween: Tween
var _base_glitch_strength: float = 0.0

const CRT_SHADER: Shader = preload("res://ui/shaders/crt_overlay.gdshader")
const PENCIL_SHADER: Shader = preload("res://ui/shaders/noir_pencil_overlay.gdshader")
const ENHANCED_SHADER: Shader = preload("res://ui/shaders/noir_enhanced.gdshader")

func _ready() -> void:
	add_to_group("noir_overlay")
	crt_overlay = get_node_or_null("CRT_Overlay") as ColorRect
	if crt_overlay == null:
		crt_overlay = ColorRect.new()
		crt_overlay.name = "CRT_Overlay"
		crt_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		crt_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		crt_overlay.color = Color(1, 1, 1, 0)
		add_child(crt_overlay)
	_ensure_material_for_mode()
	_apply_base_profile()
	_base_glitch_strength = 0.0

func set_overlay_mode(mode: String) -> void:
	var normalized: String = mode.strip_edges().to_upper()
	if normalized not in ["CRT", "PENCIL", "ENHANCED"]:
		normalized = "ENHANCED"
	if overlay_mode == normalized and _shader_material != null:
		return
	overlay_mode = normalized
	_ensure_material_for_mode()
	_apply_base_profile()

func glitch_burst(strength: float = 0.7, duration: float = 0.2) -> void:
	if _shader_material == null:
		return
	var burst_strength: float = clampf(strength, 0.0, 2.0)
	var burst_duration: float = maxf(0.05, duration)
	var glitch_param: String = "glitch_strength" if _has_uniform("glitch_strength") else "pulse"
	_set_shader_param(glitch_param, burst_strength)
	var tween := create_tween()
	tween.tween_method(
		func(value: float) -> void:
			_set_shader_param(glitch_param, value),
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
	var target_pulse: float = danger * 2.0 if _has_uniform("glitch_strength") else danger * 0.9
	_base_glitch_strength = target_glitch if _has_uniform("glitch_strength") else target_pulse

	if _danger_tween != null and _danger_tween.is_valid():
		_danger_tween.kill()
	_danger_tween = create_tween()
	_danger_tween.set_parallel(true)
	_danger_tween.tween_method(
		func(value: float) -> void:
			_set_shader_param("jitter_strength", value),
		_shader_float("jitter_strength", 0.0),
		target_jitter,
		1.0
	)
	if _has_uniform("glitch_strength"):
		_danger_tween.tween_method(
			func(value: float) -> void:
				_set_shader_param("glitch_strength", value),
			_shader_float("glitch_strength", 0.0),
			target_glitch,
			1.0
		)
	_danger_tween.tween_method(
		func(value: float) -> void:
			_set_shader_param("pulse", value),
		_shader_float("pulse", 0.0),
		target_pulse,
		1.0
	)

func _ensure_material_for_mode() -> void:
	var target_shader: Shader
	match overlay_mode:
		"PENCIL":
			target_shader = PENCIL_SHADER
		"ENHANCED":
			target_shader = ENHANCED_SHADER
		_:
			target_shader = CRT_SHADER
	
	if crt_overlay == null:
		return
	var current_material: ShaderMaterial = crt_overlay.material as ShaderMaterial
	if current_material == null:
		current_material = ShaderMaterial.new()
	if current_material.shader != target_shader:
		current_material = current_material.duplicate() as ShaderMaterial
		current_material.shader = target_shader
	crt_overlay.material = current_material
	_shader_material = current_material

func _apply_base_profile() -> void:
	if _shader_material == null:
		return

	_set_shader_param("intensity", intensity)
	_set_shader_param("fx_quality", fx_quality)
	_set_shader_param("jitter_strength", 0.0)
	_set_shader_param("pulse", 0.0)
	_set_shader_param("glitch_strength", 0.0)
	_set_shader_param("tint_color", tint_color)
	
	match overlay_mode:
		"PENCIL":
			_set_shader_param("grain_strength", 0.30)
			_set_shader_param("hatch_strength", 0.24)
			_set_shader_param("vignette_strength", 0.40)
		"ENHANCED":
			_set_shader_param("vignette_strength", 0.40)
			_set_shader_param("scanline_strength", 0.35)
			_set_shader_param("noise_strength", 0.05)
		_:
			pass

func _set_shader_param(param_name: String, value: Variant) -> void:
	if _shader_material == null:
		return
	if not _has_uniform(param_name):
		return
	_shader_material.set_shader_parameter(param_name, value)

func _has_uniform(param_name: String) -> bool:
	if _shader_material == null:
		return false
	var shader: Shader = _shader_material.shader
	if shader == null:
		return false
	var uniforms: Array = shader.get_shader_uniform_list()
	for item_var in uniforms:
		if typeof(item_var) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = item_var
		if str(item.get("name", "")) == param_name:
			return true
	return false

func _shader_float(param_name: String, fallback: float) -> float:
	if _shader_material == null or not _has_uniform(param_name):
		return fallback
	var value: Variant = _shader_material.get_shader_parameter(param_name)
	if typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT:
		return float(value)
	return fallback
