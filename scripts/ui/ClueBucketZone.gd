extends PanelContainer

var bucket_id: String = ""
@onready var items_flow = $VBox/ItemsFlow

func _ready():
	mouse_exited.connect(func(): modulate = Color(1,1,1))

func setup(p_bucket_id: String, p_label_text: String):
	bucket_id = p_bucket_id
	var title_lbl = $VBox/BucketTitle
	if title_lbl:
		title_lbl.text = p_label_text

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) == TYPE_DICTIONARY and data.get("kind") == "CLUE_ITEM":
		modulate = Color(1.2, 1.2, 1.2) # Highlight
		return true
	return false

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	modulate = Color(1.0, 1.0, 1.0) # Remove highlight

	var source_path = data.get("source_path")
	var source_node = get_node_or_null(source_path)

	if source_node and items_flow:
		source_node.reparent(items_flow)
		AudioManager.play("click")

		# Snap effect
		var tw = create_tween()
		source_node.scale = Vector2(1.05, 1.05)
		tw.tween_property(source_node, "scale", Vector2.ONE, 0.1)

func _notification(what):
	if what == NOTIFICATION_DRAG_END:
		if not is_drag_successful():
			modulate = Color(1.0, 1.0, 1.0)
