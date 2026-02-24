extends Node

const LANDSCAPE_HEIGHT_TRIGGER := 760.0
const LANDSCAPE_BASE_HEIGHT := 840.0
const MIN_SCALE := 0.84

func _ready() -> void:
	_apply_scale()
	if get_tree() != null and not get_tree().root.size_changed.is_connected(_on_root_resized):
		get_tree().root.size_changed.connect(_on_root_resized)

func _exit_tree() -> void:
	if get_tree() != null and get_tree().root.size_changed.is_connected(_on_root_resized):
		get_tree().root.size_changed.disconnect(_on_root_resized)

func _on_root_resized() -> void:
	_apply_scale()

func _apply_scale() -> void:
	if get_tree() == null or get_tree().root == null:
		return

	var root: Window = get_tree().root
	var size: Vector2 = root.size
	var is_landscape: bool = size.x >= size.y
	var target_scale: float = 1.0

	if is_landscape and size.y <= LANDSCAPE_HEIGHT_TRIGGER:
		target_scale = clampf(size.y / LANDSCAPE_BASE_HEIGHT, MIN_SCALE, 1.0)

	root.content_scale_factor = target_scale
