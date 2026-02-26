extends Control
# TutorialBase.gd - Базовый класс для всех интерактивных обучений
# Предоставляет общую систему шагов, подсказок и прогресса

class_name TutorialBase

signal tutorial_completed(tutorial_id: String)
signal step_changed(step_index: int, total_steps: int)

enum STATE { IDLE, SHOWING_STEP, WAITING_INPUT, TRANSITION }

# UI элементы (создаются динамически)
var safe_area: MarginContainer
var title_label: Label
var step_counter: Label
var content_area: VBoxContainer
var tooltip_label: Label
var visual_area: VBoxContainer
var button_area: HBoxContainer
var prev_btn: Button
var next_btn: Button
var skip_btn: Button
var home_btn: Button

# Данные обучения
var tutorial_id: String = "tutorial_base"
var tutorial_title: String = "Обучение"
var tutorial_steps: Array[Dictionary] = []
var current_step_index: int = 0
var state: STATE = STATE.IDLE

# Настройки
var can_skip: bool = true
var auto_next: bool = false
var auto_next_delay: float = 2.0

func _ready() -> void:
	_build_ui()
	_connect_signals()
	_initialize_tutorial()
	show_step(0)

func _build_ui() -> void:
	"""Создать UI иерархию динамически"""
	# SafeArea
	safe_area = MarginContainer.new()
	safe_area.add_theme_constant_override("margin_left", 20)
	safe_area.add_theme_constant_override("margin_right", 20)
	safe_area.add_theme_constant_override("margin_top", 20)
	safe_area.add_theme_constant_override("margin_bottom", 20)
	safe_area.anchor_left = 0.0
	safe_area.anchor_top = 0.0
	safe_area.anchor_right = 1.0
	safe_area.anchor_bottom = 1.0
	add_child(safe_area)
	
	# MainLayout with enhanced visual design
	var main_panel = PanelContainer.new()
	main_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Add main layout background
	var main_bg = StyleBoxFlat.new()
	main_bg.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	main_bg.border_color = Color(0.0, 0.6, 0.6, 0.4)
	main_bg.border_width_left = 1
	main_bg.border_width_right = 1
	main_bg.border_width_top = 1
	main_bg.border_width_bottom = 1
	main_bg.corner_radius_top_left = 12
	main_bg.corner_radius_top_right = 12
	main_bg.corner_radius_bottom_left = 12
	main_bg.corner_radius_bottom_right = 12
	main_panel.add_theme_stylebox_override("panel", main_bg)
	safe_area.add_child(main_panel)
	
	var main_layout = VBoxContainer.new()
	main_layout.add_theme_constant_override("separation", 20)
	main_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_panel.add_child(main_layout)
	
	# Title
	title_label = Label.new()
	title_label.text = tutorial_title
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.add_theme_color_override("font_color", Color(0.0, 1.0, 1.0, 1.0))  # Cyan
	title_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	main_layout.add_child(title_label)
	
	# Separator line
	var separator = Control.new()
	separator.custom_minimum_size = Vector2(0, 2)
	var sep_box = PanelContainer.new()
	var sep_style = StyleBoxFlat.new()
	sep_style.bg_color = Color(0.2, 0.8, 0.8, 0.5)
	sep_box.add_theme_stylebox_override("panel", sep_style)
	sep_box.custom_minimum_size = Vector2(0, 2)
	main_layout.add_child(sep_box)
	
	# Step Counter
	step_counter = Label.new()
	step_counter.text = "Шаг 0 из 0"
	step_counter.add_theme_font_size_override("font_size", 14)
	step_counter.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1.0))  # Gray
	step_counter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	main_layout.add_child(step_counter)
	
	# Content Area with enhanced styling
	var content_panel = PanelContainer.new()
	content_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Add background panel styling
	var content_bg = StyleBoxFlat.new()
	content_bg.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	content_bg.border_color = Color(0.0, 0.8, 0.8, 0.4)
	content_bg.border_width_left = 2
	content_bg.border_width_right = 2
	content_bg.border_width_top = 2
	content_bg.border_width_bottom = 2
	content_bg.corner_radius_top_left = 8
	content_bg.corner_radius_top_right = 8
	content_bg.corner_radius_bottom_left = 8
	content_bg.corner_radius_bottom_right = 8
	content_panel.add_theme_stylebox_override("panel", content_bg)
	
	content_area = VBoxContainer.new()
	content_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_area.add_theme_constant_override("separation", 15)
	content_area.add_theme_constant_override("margin_left", 16)
	content_area.add_theme_constant_override("margin_right", 16)
	content_area.add_theme_constant_override("margin_top", 12)
	content_area.add_theme_constant_override("margin_bottom", 12)
	content_panel.add_child(content_area)
	
	main_layout.add_child(content_panel)
	
	# Tooltip Label
	tooltip_label = Label.new()
	tooltip_label.text = "Загрузка..."
	tooltip_label.add_theme_font_size_override("font_size", 16)
	tooltip_label.add_theme_color_override("font_color", Color.WHITE)
	tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	content_area.add_child(tooltip_label)
	
	# Visual Area
	visual_area = VBoxContainer.new()
	visual_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_area.add_child(visual_area)
	
	# Button Area
	button_area = HBoxContainer.new()
	button_area.add_theme_constant_override("separation", 10)
	button_area.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	main_layout.add_child(button_area)
	
	# Buttons with enhanced styling
	prev_btn = Button.new()
	prev_btn.text = "← Назад"
	prev_btn.add_theme_font_size_override("font_size", 14)
	prev_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Button styling - cyan theme
	var prev_normal = StyleBoxFlat.new()
	prev_normal.bg_color = Color(0.0, 0.5, 0.5, 0.8)
	prev_normal.border_color = Color(0.0, 1.0, 1.0, 1.0)
	prev_normal.border_width_left = 2
	prev_normal.border_width_right = 2
	prev_normal.border_width_top = 2
	prev_normal.border_width_bottom = 2
	prev_normal.corner_radius_top_left = 6
	prev_normal.corner_radius_top_right = 6
	prev_normal.corner_radius_bottom_left = 6
	prev_normal.corner_radius_bottom_right = 6
	prev_btn.add_theme_stylebox_override("normal", prev_normal)
	var prev_hover = StyleBoxFlat.new()
	prev_hover.bg_color = Color(0.0, 0.7, 0.7, 0.9)
	prev_hover.border_color = Color(0.0, 1.0, 1.0, 1.0)
	prev_hover.border_width_left = 2
	prev_hover.border_width_right = 2
	prev_hover.border_width_top = 2
	prev_hover.border_width_bottom = 2
	prev_hover.corner_radius_top_left = 6
	prev_hover.corner_radius_top_right = 6
	prev_hover.corner_radius_bottom_left = 6
	prev_hover.corner_radius_bottom_right = 6
	prev_btn.add_theme_stylebox_override("hover", prev_hover)
	prev_btn.add_theme_color_override("font_color", Color.WHITE)
	button_area.add_child(prev_btn)
	
	next_btn = Button.new()
	next_btn.text = "Далее →"
	next_btn.add_theme_font_size_override("font_size", 14)
	next_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Button styling - yellow theme
	var next_normal = StyleBoxFlat.new()
	next_normal.bg_color = Color(0.8, 0.6, 0.0, 0.8)
	next_normal.border_color = Color(1.0, 1.0, 0.0, 1.0)
	next_normal.border_width_left = 2
	next_normal.border_width_right = 2
	next_normal.border_width_top = 2
	next_normal.border_width_bottom = 2
	next_normal.corner_radius_top_left = 6
	next_normal.corner_radius_top_right = 6
	next_normal.corner_radius_bottom_left = 6
	next_normal.corner_radius_bottom_right = 6
	next_btn.add_theme_stylebox_override("normal", next_normal)
	var next_hover = StyleBoxFlat.new()
	next_hover.bg_color = Color(1.0, 0.8, 0.0, 0.9)
	next_hover.border_color = Color(1.0, 1.0, 0.0, 1.0)
	next_hover.border_width_left = 2
	next_hover.border_width_right = 2
	next_hover.border_width_top = 2
	next_hover.border_width_bottom = 2
	next_hover.corner_radius_top_left = 6
	next_hover.corner_radius_top_right = 6
	next_hover.corner_radius_bottom_left = 6
	next_hover.corner_radius_bottom_right = 6
	next_btn.add_theme_stylebox_override("hover", next_hover)
	next_btn.add_theme_color_override("font_color", Color.BLACK)
	button_area.add_child(next_btn)
	
	skip_btn = Button.new()
	skip_btn.text = "Пропустить"
	skip_btn.add_theme_font_size_override("font_size", 14)
	skip_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Skip button styling - gray theme
	var skip_normal = StyleBoxFlat.new()
	skip_normal.bg_color = Color(0.3, 0.3, 0.3, 0.8)
	skip_normal.border_color = Color(0.5, 0.5, 0.5, 1.0)
	skip_normal.border_width_left = 2
	skip_normal.border_width_right = 2
	skip_normal.border_width_top = 2
	skip_normal.border_width_bottom = 2
	skip_normal.corner_radius_top_left = 6
	skip_normal.corner_radius_top_right = 6
	skip_normal.corner_radius_bottom_left = 6
	skip_normal.corner_radius_bottom_right = 6
	skip_btn.add_theme_stylebox_override("normal", skip_normal)
	var skip_hover = StyleBoxFlat.new()
	skip_hover.bg_color = Color(0.4, 0.4, 0.4, 0.9)
	skip_hover.border_color = Color(0.6, 0.6, 0.6, 1.0)
	skip_hover.border_width_left = 2
	skip_hover.border_width_right = 2
	skip_hover.border_width_top = 2
	skip_hover.border_width_bottom = 2
	skip_hover.corner_radius_top_left = 6
	skip_hover.corner_radius_top_right = 6
	skip_hover.corner_radius_bottom_left = 6
	skip_hover.corner_radius_bottom_right = 6
	skip_btn.add_theme_stylebox_override("hover", skip_hover)
	skip_btn.add_theme_color_override("font_color", Color.WHITE)
	button_area.add_child(skip_btn)
	
	home_btn = Button.new()
	home_btn.text = "На главную"
	home_btn.add_theme_font_size_override("font_size", 14)
	home_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Home button styling - red theme
	var home_normal = StyleBoxFlat.new()
	home_normal.bg_color = Color(0.6, 0.0, 0.0, 0.8)
	home_normal.border_color = Color(1.0, 0.0, 0.0, 1.0)
	home_normal.border_width_left = 2
	home_normal.border_width_right = 2
	home_normal.border_width_top = 2
	home_normal.border_width_bottom = 2
	home_normal.corner_radius_top_left = 6
	home_normal.corner_radius_top_right = 6
	home_normal.corner_radius_bottom_left = 6
	home_normal.corner_radius_bottom_right = 6
	home_btn.add_theme_stylebox_override("normal", home_normal)
	var home_hover = StyleBoxFlat.new()
	home_hover.bg_color = Color(0.8, 0.0, 0.0, 0.9)
	home_hover.border_color = Color(1.0, 0.0, 0.0, 1.0)
	home_hover.border_width_left = 2
	home_hover.border_width_right = 2
	home_hover.border_width_top = 2
	home_hover.border_width_bottom = 2
	home_hover.corner_radius_top_left = 6
	home_hover.corner_radius_top_right = 6
	home_hover.corner_radius_bottom_left = 6
	home_hover.corner_radius_bottom_right = 6
	home_btn.add_theme_stylebox_override("hover", home_hover)
	home_btn.add_theme_color_override("font_color", Color.WHITE)
	button_area.add_child(home_btn)
	
	# Set minimum button sizes for better appearance
	prev_btn.custom_minimum_size = Vector2(0, 44)
	next_btn.custom_minimum_size = Vector2(0, 44)
	skip_btn.custom_minimum_size = Vector2(0, 44)
	home_btn.custom_minimum_size = Vector2(0, 44)

func _connect_signals() -> void:
	prev_btn.pressed.connect(_on_prev_pressed)
	next_btn.pressed.connect(_on_next_pressed)
	skip_btn.pressed.connect(_on_skip_pressed)
	home_btn.pressed.connect(_on_home_pressed)

func _initialize_tutorial() -> void:
	"""Переопределить в потомках для заполнения tutorial_steps"""
	pass

# ============= УПРАВЛЕНИЕ ШАГАМИ =============

func show_step(index: int) -> void:
	if index < 0 or index >= tutorial_steps.size():
		return
	
	current_step_index = index
	state = STATE.SHOWING_STEP
	
	var step = tutorial_steps[index]
	
	# Обновить UI
	step_counter.text = "%d / %d" % [index + 1, tutorial_steps.size()]
	tooltip_label.text = step.get("text", "")
	
	# Очистить визуальную область
	for child in visual_area.get_children():
		child.queue_free()
	
	# Вызвать специфичный рендер шага
	if step.has("render_func"):
		var func_name = step["render_func"]
		if has_method(func_name):
			call(func_name, visual_area, step)
	
	# Обновить кнопки
	prev_btn.disabled = index == 0
	next_btn.disabled = index == tutorial_steps.size() - 1
	
	step_changed.emit(index, tutorial_steps.size())
	
	# Авто-переход если нужен
	if auto_next and index < tutorial_steps.size() - 1:
		await get_tree().create_timer(auto_next_delay).timeout
		show_next_step()

func show_next_step() -> void:
	if current_step_index < tutorial_steps.size() - 1:
		show_step(current_step_index + 1)
	else:
		_complete_tutorial()

func show_prev_step() -> void:
	if current_step_index > 0:
		show_step(current_step_index - 1)

# ============= УТИЛИТЫ ДЛЯ РЕНДЕРА =============

func render_binary_input(area: Control, step: Dictionary) -> void:
	"""Рендер для ввода двоичного числа"""
	var container = VBoxContainer.new()
	area.add_child(container)
	
	var text_label = Label.new()
	text_label.text = step.get("description", "")
	text_label.add_theme_font_size_override("font_size", 18)
	container.add_child(text_label)
	
	# Поле для ввода
	var input = LineEdit.new()
	input.placeholder_text = "Введите двоичное число: 0 или 1"
	input.custom_minimum_size = Vector2(200, 40)
	container.add_child(input)
	
	step["input_field"] = input

func render_hex_input(area: Control, step: Dictionary) -> void:
	"""Рендер для ввода HEX числа"""
	var container = VBoxContainer.new()
	area.add_child(container)
	
	var text_label = Label.new()
	text_label.text = step.get("description", "")
	text_label.add_theme_font_size_override("font_size", 18)
	container.add_child(text_label)
	
	# Поле для ввода
	var input = LineEdit.new()
	input.placeholder_text = "Введите HEX: 0-9, A-F"
	input.custom_minimum_size = Vector2(200, 40)
	container.add_child(input)
	
	step["input_field"] = input

func render_comparison(area: Control, step: Dictionary) -> void:
	"""Рендер для сравнения двух значений"""
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 20)
	area.add_child(container)
	
	var title = Label.new()
	title.text = step.get("title", "Сравните:")
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color.WHITE)
	container.add_child(title)
	
	# Верхнее значение
	var val1_box = HBoxContainer.new()
	val1_box.add_theme_constant_override("separation", 10)
	container.add_child(val1_box)
	
	var label1 = Label.new()
	label1.text = step.get("value1_label", "Значение 1:")
	label1.custom_minimum_size = Vector2(150, 0)
	val1_box.add_child(label1)
	
	var val1_display = Label.new()
	val1_display.text = str(step.get("value1", ""))
	val1_display.add_theme_font_size_override("font_size", 24)
	val1_display.add_theme_color_override("font_color", Color.YELLOW)
	val1_box.add_child(val1_display)
	
	# Нижнее значение
	var val2_box = HBoxContainer.new()
	val2_box.add_theme_constant_override("separation", 10)
	container.add_child(val2_box)
	
	var label2 = Label.new()
	label2.text = step.get("value2_label", "Значение 2:")
	label2.custom_minimum_size = Vector2(150, 0)
	val2_box.add_child(label2)
	
	var val2_display = Label.new()
	val2_display.text = str(step.get("value2", ""))
	val2_display.add_theme_font_size_override("font_size", 24)
	val2_display.add_theme_color_override("font_color", Color.CYAN)
	val2_box.add_child(val2_display)

func render_bit_grid(area: Control, step: Dictionary) -> void:
	"""Рендер 8-битной сетки"""
	var container = VBoxContainer.new()
	area.add_child(container)
	
	var title = Label.new()
	title.text = step.get("title", "Двоичное число:")
	title.add_theme_font_size_override("font_size", 18)
	container.add_child(title)
	
	var grid = GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	container.add_child(grid)
	
	var bits = step.get("bits", [1,0,1,0,1,0,1,0])
	var weights = [128, 64, 32, 16, 8, 4, 2, 1]
	
	for i in range(8):
		var cell = VBoxContainer.new()
		cell.add_theme_constant_override("separation", 2)
		
		var bit_label = Label.new()
		bit_label.text = str(bits[i])
		bit_label.add_theme_font_size_override("font_size", 20)
		bit_label.add_theme_color_override("font_color", Color.YELLOW if bits[i] == 1 else Color.GRAY)
		bit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(bit_label)
		
		var weight_label = Label.new()
		weight_label.text = "2^%d" % (7 - i)
		weight_label.add_theme_font_size_override("font_size", 12)
		weight_label.add_theme_color_override("font_color", Color.GRAY)
		weight_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(weight_label)
		
		grid.add_child(cell)

func render_logic_gate_truth_table(area: Control, step: Dictionary) -> void:
	"""Рендер таблицы истинности для логических ворот"""
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 10)
	area.add_child(container)
	
	var title = Label.new()
	title.text = step.get("gate_name", "AND") + " ворота"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color.WHITE)
	container.add_child(title)
	
	var table = VBoxContainer.new()
	container.add_child(table)
	
	var rows = step.get("rows", [
		{"a": 0, "b": 0, "result": 0},
		{"a": 0, "b": 1, "result": 0},
		{"a": 1, "b": 0, "result": 0},
		{"a": 1, "b": 1, "result": 1}
	])
	
	# Заголовок
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	table.add_child(header)
	
	for title_text in ["A", "B", "Результат"]:
		var label = Label.new()
		label.text = title_text
		label.custom_minimum_size = Vector2(80, 0)
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", Color.CYAN)
		header.add_child(label)
	
	# Строки
	for row in rows:
		var row_container = HBoxContainer.new()
		row_container.add_theme_constant_override("separation", 20)
		table.add_child(row_container)
		
		for key in ["a", "b", "result"]:
			var label = Label.new()
			label.text = str(row.get(key, "?"))
			label.custom_minimum_size = Vector2(80, 0)
			label.add_theme_font_size_override("font_size", 14)
			row_container.add_child(label)

# ============= ОБРАБОТЧИКИ КНОПОК =============

func _on_prev_pressed() -> void:
	show_prev_step()

func _on_next_pressed() -> void:
	show_next_step()

func _on_skip_pressed() -> void:
	if can_skip:
		_complete_tutorial()

func _on_home_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/LearnSelect.tscn")

# ============= ЗАВЕРШЕНИЕ =============

func _complete_tutorial() -> void:
	state = STATE.IDLE
	tutorial_completed.emit(tutorial_id)
	
	# Анимация завершения
	var tween = create_tween()
	tween.tween_property(title_label, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(content_area, "modulate:a", 0.0, 0.3)
	
	await tween.finished
	
	# Сохранить прогресс
	var progress = {
		"tutorial_id": tutorial_id,
		"completed": true,
		"timestamp": Time.get_ticks_msec()
	}
	# TODO: Сохранить в GlobalMetrics или файл
	
	# Вернуться в меню
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/LearnSelect.tscn")
