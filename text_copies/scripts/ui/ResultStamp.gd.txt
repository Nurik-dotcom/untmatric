extends Control

@onready var stamp_panel: PanelContainer = $CenterContainer/StampPanel
@onready var stamp_label: Label = $CenterContainer/StampPanel/Margin/StampLabel

var _active_tween: Tween

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func show_result(is_correct: bool) -> void:
	if _active_tween != null and _active_tween.is_running():
		_active_tween.kill()

	visible = true
	modulate = Color(1, 1, 1, 1)
	stamp_panel.modulate = Color(1, 1, 1, 0)
	stamp_panel.scale = Vector2(0.8, 0.8)

	if is_correct:
		stamp_label.text = "ПОДТВЕРЖДЕНО"
		stamp_label.add_theme_color_override("font_color", Color(0.75, 1.0, 0.72))
	else:
		stamp_label.text = "ОТКЛОНЕНО"
		stamp_label.add_theme_color_override("font_color", Color(1.0, 0.65, 0.62))

	_active_tween = create_tween()
	_active_tween.set_parallel(true)
	_active_tween.tween_property(stamp_panel, "modulate:a", 1.0, 0.12)
	_active_tween.tween_property(stamp_panel, "scale", Vector2(1.0, 1.0), 0.16)
	_active_tween.set_parallel(false)
	_active_tween.tween_interval(0.28)
	_active_tween.tween_property(stamp_panel, "modulate:a", 0.0, 0.72)
	_active_tween.finished.connect(func() -> void:
		visible = false
	)

