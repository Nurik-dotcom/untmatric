extends Control

const CLUES_DATA_PATH = "res://data/clues_levels.json"
const ITEM_SCENE = preload("res://scenes/ui/ClueItem.tscn")
const BUCKET_SCRIPT = preload("res://scripts/ui/ClueBucketZone.gd")

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

func _ready():
	_connect_signals()
	_load_level_data()

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
