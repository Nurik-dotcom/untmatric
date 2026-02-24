extends Control

const CLUES_DATA_PATH = "res://data/clues_levels.json"
const ITEM_SCENE = preload("res://scenes/ui/ClueItem.tscn")
const BUCKET_SCRIPT = preload("res://scripts/ui/ClueBucketZone.gd")
const PHONE_LANDSCAPE_MAX_HEIGHT := 740.0
const PHONE_PORTRAIT_MAX_WIDTH := 520.0

@onready var safe_area: MarginContainer = $SafeArea
@onready var main_vbox: VBoxContainer = $SafeArea/MainVBox
@onready var work_area: HBoxContainer = $SafeArea/MainVBox/WorkArea
@onready var pool_card: PanelContainer = $SafeArea/MainVBox/WorkArea/PoolCard
@onready var buckets_card: PanelContainer = $SafeArea/MainVBox/WorkArea/BucketsCard
@onready var bottom_bar: HBoxContainer = $SafeArea/MainVBox/BottomBar
@onready var title_label = $SafeArea/MainVBox/Header/TitleLabel
@onready var stage_label = $SafeArea/MainVBox/Header/StageLabel
@onready var stability_bar = $SafeArea/MainVBox/Header/StabilityBar
@onready var briefing_label = $SafeArea/MainVBox/BriefingCard/BriefingLabel
@onready var pool_grid = $SafeArea/MainVBox/WorkArea/PoolCard/VBox/ItemsFlow
@onready var bucket_input = $SafeArea/MainVBox/WorkArea/BucketsCard/BucketsVBox/BucketInput
@onready var bucket_output = $SafeArea/MainVBox/WorkArea/BucketsCard/BucketsVBox/BucketOutput
@onready var bucket_memory = $SafeArea/MainVBox/WorkArea/BucketsCard/BucketsVBox/BucketMemory
@onready var status_label = $SafeArea/MainVBox/BottomBar/StatusLabel
@onready var btn_reset = $SafeArea/MainVBox/BottomBar/BtnReset
@onready var btn_confirm = $SafeArea/MainVBox/BottomBar/BtnConfirm
@onready var btn_back = $SafeArea/MainVBox/Header/BtnBack
@onready var result_popup = $ResultPopup
@onready var dimmer = $Dimmer

@onready var res_label_verdict = $ResultPopup/VBox/VerdictLabel
@onready var res_label_score = $ResultPopup/VBox/ScoreLabel
@onready var res_label_stability = $ResultPopup/VBox/StabilityLabel
@onready var res_btn_retry = $ResultPopup/VBox/HBox/BtnRetry
@onready var res_btn_back = $ResultPopup/VBox/HBox/BtnBack

var level_data: Dictionary = {}
var current_level_idx: int = 0
var drag_count: int = 0
var start_time: int = 0
var _work_mobile_layout: VBoxContainer = null

func _ready():
	_connect_signals()
	_load_level_data()
	_on_viewport_size_changed()
	if not get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.connect(_on_viewport_size_changed)

func _exit_tree() -> void:
	if get_tree() != null and get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.disconnect(_on_viewport_size_changed)

func _connect_signals():
	btn_back.pressed.connect(_on_back_pressed)
	btn_reset.pressed.connect(_on_reset_pressed)
	btn_confirm.pressed.connect(_on_confirm_pressed)
	res_btn_retry.pressed.connect(_on_retry_pressed)
	res_btn_back.pressed.connect(_on_back_pressed)

func _load_level_data():
	var file = FileAccess.open(CLUES_DATA_PATH, FileAccess.READ)
	if not file:
		_show_error("Не удалось загрузить данные уровня")
		return

	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	if error != OK:
		_show_error("Ошибка разбора JSON: " + json.get_error_message())
		return

	var data = json.data
	if typeof(data) != TYPE_ARRAY or data.is_empty():
		_show_error("Некорректный формат JSON")
		return

	# Assume first level for A
	level_data = data[0]
	if not _validate_level(level_data):
		_show_error("Проверка данных уровня не пройдена")
		return

	_setup_ui()

func _validate_level(data: Dictionary) -> bool:
	if not data.has_all(["id", "format", "buckets", "items", "scoring_rules"]):
		return false
	if data.format != "MATCHING": return false
	if data.buckets.size() != 3: return false
	if data.items.size() != 8: return false
	return true

func _setup_ui():
	title_label.text = "ДЕЛО №1: УЛИКИ В МУСОРЕ"
	stage_label.text = "ЭТАП A"
	briefing_label.text = level_data.get("briefing", "")
	stability_bar.value = GlobalMetrics.stability

	# Setup Buckets
	if bucket_input.has_method("setup"):
		bucket_input.setup("INPUT", "ВВОД")
	if bucket_output.has_method("setup"):
		bucket_output.setup("OUTPUT", "ВЫВОД")
	if bucket_memory.has_method("setup"):
		bucket_memory.setup("MEMORY", "ПАМЯТЬ")

	# Setup Pool (PoolCard has the script)
	var pool_card = $SafeArea/MainVBox/WorkArea/PoolCard
	if pool_card.has_method("setup"):
		pool_card.setup("POOL", "СВАЛКА")

	_spawn_items()
	start_time = Time.get_ticks_msec()
	drag_count = 0

	result_popup.hide()
	dimmer.hide()
	btn_confirm.disabled = false
	status_label.text = "Рассортируйте улики..."

func _spawn_items():
	# Clear existing items
	for child in pool_grid.get_children():
		child.queue_free()
	for bucket in [bucket_input, bucket_output, bucket_memory]:
		var flow = bucket.get_node_or_null("VBox/ItemsFlow")
		if flow:
			for child in flow.get_children():
				child.queue_free()

	# Spawn new items
	var items = level_data.items.duplicate()
	items.shuffle()

	for item_info in items:
		var item = ITEM_SCENE.instantiate()
		pool_grid.add_child(item)
		item.setup(item_info)

func _on_reset_pressed():
	_spawn_items()
	status_label.text = "Сброс выполнен"
	status_label.add_theme_color_override("font_color", Color("ffb000")) # Theme color
	AudioManager.play("relay")
	drag_count = 0

func _on_confirm_pressed():
	var snapshot = {}
	var assigned_count = 0

	# Check buckets
	for bucket in [bucket_input, bucket_output, bucket_memory]:
		var flow = bucket.get_node_or_null("VBox/ItemsFlow")
		if flow:
			for child in flow.get_children():
				if child.has_method("setup"): # Is ClueItem
					snapshot[child.item_id] = bucket.bucket_id
					assigned_count += 1

	# Check pool
	for child in pool_grid.get_children():
		if child.has_method("setup"):
			snapshot[child.item_id] = "POOL"

	if assigned_count < 8:
		status_label.text = "Не все улики распределены!"
		status_label.add_theme_color_override("font_color", Color(1, 1, 0)) # Yellow
		AudioManager.play("error")
		# Proceed despite warning as per spec

	var result = _calculate_scoring(snapshot)
	_show_result(result, snapshot)

func _calculate_scoring(snapshot: Dictionary) -> Dictionary:
	var correct_count = 0
	for item in level_data.items:
		var iid = item.item_id
		var correct = item.correct_bucket_id
		var actual = snapshot.get(iid, "POOL")
		if actual == correct:
			correct_count += 1

	var points = 0
	var stability_delta = -30
	var verdict = "FAIL"
	var is_fit = false
	var is_correct = false

	if correct_count == 8:
		points = 2
		stability_delta = 0
		verdict = "PERFECT"
		is_fit = true
		is_correct = true
	elif correct_count >= 6:
		points = 1
		stability_delta = -10
		verdict = "PARTIAL"
		is_fit = true
		is_correct = false
	else:
		points = 0
		stability_delta = -30
		verdict = "FAIL"
		is_fit = false
		is_correct = false

	return {
		"points": points,
		"max_points": 2,
		"is_fit": is_fit,
		"is_correct": is_correct,
		"stability_delta": stability_delta,
		"correct_count": correct_count,
		"total_items": 8,
		"verdict_code": verdict
	}

func _show_result(result: Dictionary, snapshot: Dictionary):
	var elapsed_ms = Time.get_ticks_msec() - start_time
	var payload = {
		"quest_id": "CASE_01_CLUES",
		"level_id": level_data.id,
		"stage": "A",
		"format": "MATCHING",
		"match_key": "CL_A_%s_%d" % [level_data.id, GlobalMetrics.session_history.size()],
		"snapshot": snapshot,
		"correct_count": result.correct_count,
		"total_items": result.total_items,
		"points": result.points,
		"max_points": result.max_points,
		"is_fit": result.is_fit,
		"is_correct": result.is_correct,
		"stability_delta": result.stability_delta,
		"verdict_code": result.verdict_code,
		"drag_count": drag_count,
		"elapsed_ms": elapsed_ms
	}
	GlobalMetrics.register_trial(payload)

	dimmer.show()
	result_popup.show()
	res_label_verdict.text = result.verdict_code
	res_label_score.text = "Верно: %d/%d\nБаллы: %d/%d" % [result.correct_count, result.total_items, result.points, result.max_points]
	res_label_stability.text = "Стабильность: %d" % result.stability_delta

	if result.is_correct:
		AudioManager.play("click")
		res_label_verdict.modulate = Color(0, 1, 0)
	elif result.is_fit:
		AudioManager.play("click")
		res_label_verdict.modulate = Color(1, 1, 0)
	else:
		AudioManager.play("error")
		res_label_verdict.modulate = Color(1, 0, 0)

	# Block interaction
	btn_confirm.disabled = true

func _on_retry_pressed():
	result_popup.hide()
	dimmer.hide()
	btn_confirm.disabled = false
	_on_reset_pressed()

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _show_error(msg):
	status_label.text = msg
	status_label.add_theme_color_override("font_color", Color(1, 0, 0))

func _on_viewport_size_changed() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var is_landscape: bool = viewport_size.x >= viewport_size.y
	var phone_landscape: bool = is_landscape and viewport_size.y <= PHONE_LANDSCAPE_MAX_HEIGHT
	var phone_portrait: bool = (not is_landscape) and viewport_size.x <= PHONE_PORTRAIT_MAX_WIDTH
	var compact: bool = phone_landscape or phone_portrait

	_apply_safe_area_padding(compact)
	main_vbox.add_theme_constant_override("separation", 10 if compact else 16)
	work_area.add_theme_constant_override("separation", 12 if compact else 20)
	bottom_bar.add_theme_constant_override("separation", 10 if compact else 20)
	_set_work_mobile_mode(compact)

	pool_grid.columns = 1 if phone_portrait else 2
	btn_reset.custom_minimum_size = Vector2(96.0 if compact else 120.0, 52.0 if compact else 60.0)
	btn_confirm.custom_minimum_size = Vector2(120.0 if compact else 160.0, 52.0 if compact else 60.0)
	status_label.add_theme_font_size_override("font_size", 16 if compact else 18)

	var popup_width: float = clampf(viewport_size.x - (24.0 if compact else 120.0), 280.0, 420.0)
	var popup_height: float = clampf(viewport_size.y - (24.0 if compact else 120.0), 220.0, 340.0)
	result_popup.offset_left = -popup_width * 0.5
	result_popup.offset_top = -popup_height * 0.5
	result_popup.offset_right = popup_width * 0.5
	result_popup.offset_bottom = popup_height * 0.5

func _set_work_mobile_mode(use_mobile: bool) -> void:
	var mobile_layout: VBoxContainer = _ensure_work_mobile_layout()
	if use_mobile:
		if work_area.visible:
			if pool_card.get_parent() != mobile_layout:
				pool_card.reparent(mobile_layout)
			if buckets_card.get_parent() != mobile_layout:
				buckets_card.reparent(mobile_layout)
			pool_card.size_flags_stretch_ratio = 1.0
		work_area.visible = false
		mobile_layout.visible = true
	else:
		if not work_area.visible:
			if pool_card.get_parent() != work_area:
				pool_card.reparent(work_area)
			if buckets_card.get_parent() != work_area:
				buckets_card.reparent(work_area)
			pool_card.size_flags_stretch_ratio = 0.6
		mobile_layout.visible = false
		work_area.visible = true

func _ensure_work_mobile_layout() -> VBoxContainer:
	if _work_mobile_layout != null and is_instance_valid(_work_mobile_layout):
		return _work_mobile_layout
	_work_mobile_layout = VBoxContainer.new()
	_work_mobile_layout.name = "WorkMobileLayout"
	_work_mobile_layout.visible = false
	_work_mobile_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_work_mobile_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_work_mobile_layout.add_theme_constant_override("separation", 12)
	main_vbox.add_child(_work_mobile_layout)
	main_vbox.move_child(_work_mobile_layout, main_vbox.get_children().find(work_area) + 1)
	return _work_mobile_layout

func _apply_safe_area_padding(compact: bool) -> void:
	var left: float = 8.0 if compact else 16.0
	var top: float = 8.0 if compact else 12.0
	var right: float = 8.0 if compact else 16.0
	var bottom: float = 8.0 if compact else 12.0

	var safe_rect: Rect2i = DisplayServer.get_display_safe_area()
	if safe_rect.size.x > 0 and safe_rect.size.y > 0:
		var viewport_size: Vector2 = get_viewport_rect().size
		left = maxf(left, float(safe_rect.position.x))
		top = maxf(top, float(safe_rect.position.y))
		right = maxf(right, viewport_size.x - float(safe_rect.position.x + safe_rect.size.x))
		bottom = maxf(bottom, viewport_size.y - float(safe_rect.position.y + safe_rect.size.y))

	safe_area.add_theme_constant_override("margin_left", int(round(left)))
	safe_area.add_theme_constant_override("margin_top", int(round(top)))
	safe_area.add_theme_constant_override("margin_right", int(round(right)))
	safe_area.add_theme_constant_override("margin_bottom", int(round(bottom)))
