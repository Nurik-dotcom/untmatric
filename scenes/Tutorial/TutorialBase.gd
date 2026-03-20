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
var linked_quest_scene: String = ""

# Настройки
var can_skip: bool = true
var auto_next: bool = false
var auto_next_delay: float = 2.0

# Landscape/responsive
const LANDSCAPE_HEIGHT_MAX := 520.0
const STEP_DOT_SIZE := Vector2(10, 10)

# Новые ноды layout
var outer_panel: PanelContainer
var step_dots_row: HBoxContainer
var scroll_container: ScrollContainer
var landscape_split: HBoxContainer

var _dot_nodes: Array[Panel] = []
var _is_landscape: bool = false

func _ready() -> void:
	_build_ui()
	_connect_signals()
	_initialize_tutorial()
	show_step(0)

func _build_ui() -> void:
	# --- Фон ---
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.07, 0.08, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# --- Основная панель с нуар-бордером ---
	outer_panel = PanelContainer.new()
	outer_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	panel_style.border_color = Color(0.0, 0.55, 0.55, 0.25)
	panel_style.set_border_width_all(1)
	outer_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(outer_panel)

	# --- SafeArea ---
	safe_area = MarginContainer.new()
	safe_area.add_theme_constant_override("margin_left", 16)
	safe_area.add_theme_constant_override("margin_right", 16)
	safe_area.add_theme_constant_override("margin_top", 12)
	safe_area.add_theme_constant_override("margin_bottom", 12)
	outer_panel.add_child(safe_area)
	
	# --- Корневой VBox ---
	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 8)
	root_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	safe_area.add_child(root_vbox)

	# --- Заголовок + шаг ---
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 8)
	root_vbox.add_child(header_row)

	title_label = Label.new()
	title_label.text = tutorial_title
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color(0.0, 0.9, 0.9, 1.0))
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.clip_text = true
	header_row.add_child(title_label)

	step_counter = Label.new()
	step_counter.text = "0/0"
	step_counter.add_theme_font_size_override("font_size", 13)
	step_counter.add_theme_color_override("font_color", Color(0.45, 0.45, 0.55, 1.0))
	step_counter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header_row.add_child(step_counter)

	# --- Прогресс-точки ---
	step_dots_row = HBoxContainer.new()
	step_dots_row.add_theme_constant_override("separation", 6)
	root_vbox.add_child(step_dots_row)

	# --- Разделитель ---
	var sep_panel := Panel.new()
	sep_panel.custom_minimum_size = Vector2(0, 1)
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = Color(0.18, 0.18, 0.28, 1.0)
	sep_panel.add_theme_stylebox_override("panel", sep_style)
	root_vbox.add_child(sep_panel)

	# --- Основной контентный контейнер ---
	landscape_split = HBoxContainer.new()
	landscape_split.add_theme_constant_override("separation", 12)
	landscape_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(landscape_split)

	# Левая панель: текст/tooltip (показывается только в ландшафте)
	var left_pane := VBoxContainer.new()
	left_pane.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_pane.size_flags_vertical = Control.SIZE_EXPAND_FILL
	landscape_split.add_child(left_pane)

	var tooltip_panel := PanelContainer.new()
	tooltip_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var tp_style := StyleBoxFlat.new()
	tp_style.bg_color = Color(0.08, 0.09, 0.13, 1.0)
	tp_style.border_color = Color(0.15, 0.15, 0.25, 1.0)
	tp_style.set_border_width_all(1)
	tp_style.corner_radius_top_left = 8
	tp_style.corner_radius_top_right = 8
	tp_style.corner_radius_bottom_left = 8
	tp_style.corner_radius_bottom_right = 8
	tp_style.content_margin_left = 14
	tp_style.content_margin_right = 14
	tp_style.content_margin_top = 12
	tp_style.content_margin_bottom = 12
	tooltip_panel.add_theme_stylebox_override("panel", tp_style)
	left_pane.add_child(tooltip_panel)

	var tooltip_scroll := ScrollContainer.new()
	tooltip_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tooltip_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tooltip_panel.add_child(tooltip_scroll)

	tooltip_label = Label.new()
	tooltip_label.text = ""
	tooltip_label.add_theme_font_size_override("font_size", 15)
	tooltip_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9, 1.0))
	tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	tooltip_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tooltip_scroll.add_child(tooltip_label)

	# Правая панель: визуальный контент
	var right_pane := PanelContainer.new()
	right_pane.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_pane.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var rp_style := StyleBoxFlat.new()
	rp_style.bg_color = Color(0.06, 0.07, 0.10, 1.0)
	rp_style.border_color = Color(0.12, 0.12, 0.22, 1.0)
	rp_style.set_border_width_all(1)
	rp_style.corner_radius_top_left = 8
	rp_style.corner_radius_top_right = 8
	rp_style.corner_radius_bottom_left = 8
	rp_style.corner_radius_bottom_right = 8
	rp_style.content_margin_left   = 16
	rp_style.content_margin_right  = 16
	rp_style.content_margin_top    = 14
	rp_style.content_margin_bottom = 14
	right_pane.add_theme_stylebox_override("panel", rp_style)
	landscape_split.add_child(right_pane)

	scroll_container = ScrollContainer.new()
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_pane.add_child(scroll_container)

	content_area = VBoxContainer.new()
	content_area.add_theme_constant_override("separation", 12)
	content_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(content_area)

	visual_area = content_area  # visual_area указывает на content_area

	# --- Нижняя панель кнопок ---
	var btn_sep := Panel.new()
	btn_sep.custom_minimum_size = Vector2(0, 1)
	var bs_style := StyleBoxFlat.new()
	bs_style.bg_color = Color(0.18, 0.18, 0.28, 1.0)
	btn_sep.add_theme_stylebox_override("panel", bs_style)
	root_vbox.add_child(btn_sep)

	button_area = HBoxContainer.new()
	button_area.add_theme_constant_override("separation", 8)
	root_vbox.add_child(button_area)

	home_btn = _make_button("← Выход", Color(0.45, 0.12, 0.12), Color(0.75, 0.18, 0.18))
	button_area.add_child(home_btn)

	skip_btn = _make_button("Пропустить", Color(0.18, 0.18, 0.28), Color(0.35, 0.35, 0.50))
	button_area.add_child(skip_btn)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_area.add_child(spacer)

	prev_btn = _make_button("← Назад", Color(0.08, 0.28, 0.35), Color(0.12, 0.55, 0.65))
	button_area.add_child(prev_btn)

	next_btn = _make_button("Далее →", Color(0.55, 0.40, 0.05), Color(0.9, 0.75, 0.1))
	next_btn.add_theme_color_override("font_color", Color(0.08, 0.06, 0.0))
	button_area.add_child(next_btn)

	for btn in [prev_btn, next_btn, skip_btn, home_btn]:
		btn.custom_minimum_size = Vector2(0, 44)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	get_tree().root.size_changed.connect(_on_viewport_size_changed)
	call_deferred("_on_viewport_size_changed")

func _make_button(text: String, bg_col: Color, border_col: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", Color.WHITE)
	var normal := StyleBoxFlat.new()
	normal.bg_color = bg_col
	normal.border_color = border_col
	normal.set_border_width_all(1)
	normal.corner_radius_top_left = 6
	normal.corner_radius_top_right = 6
	normal.corner_radius_bottom_left = 6
	normal.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = border_col * Color(1, 1, 1, 0.85)
	btn.add_theme_stylebox_override("hover", hover)
	return btn

func _on_viewport_size_changed() -> void:
	var vp := get_viewport_rect().size
	_is_landscape = vp.x > vp.y and vp.y <= LANDSCAPE_HEIGHT_MAX
	var left_pane  := landscape_split.get_child(0) as Control
	var right_pane := landscape_split.get_child(1) as Control

	if _is_landscape:
		left_pane.visible = true
		left_pane.size_flags_horizontal  = Control.SIZE_EXPAND_FILL
		right_pane.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		left_pane.size_flags_stretch_ratio  = 1.0
		right_pane.size_flags_stretch_ratio = 1.4
		safe_area.add_theme_constant_override("margin_top",    6)
		safe_area.add_theme_constant_override("margin_bottom", 6)
		title_label.add_theme_font_size_override("font_size", 16)
		tooltip_label.add_theme_font_size_override("font_size", 13)
		for btn in [prev_btn, next_btn, skip_btn, home_btn]:
			btn.custom_minimum_size.y = 36.0
			btn.add_theme_font_size_override("font_size", 13)
		step_dots_row.visible = false
	else:
		# Критично: убрать SIZE_EXPAND_FILL чтобы hidden-нода не резервировала место
		left_pane.visible = false
		left_pane.size_flags_horizontal  = Control.SIZE_SHRINK_BEGIN
		right_pane.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		right_pane.size_flags_stretch_ratio = 1.0
		safe_area.add_theme_constant_override("margin_top",    12)
		safe_area.add_theme_constant_override("margin_bottom", 12)
		title_label.add_theme_font_size_override("font_size", 22)
		tooltip_label.add_theme_font_size_override("font_size", 15)
		for btn in [prev_btn, next_btn, skip_btn, home_btn]:
			btn.custom_minimum_size.y = 44.0
			btn.add_theme_font_size_override("font_size", 14)
		step_dots_row.visible = true

	_rebuild_dots()

func _rebuild_dots() -> void:
	for child in step_dots_row.get_children():
		child.queue_free()
	_dot_nodes.clear()
	var total := tutorial_steps.size()
	if total == 0:
		return
	for i in range(total):
		var dot := Panel.new()
		dot.custom_minimum_size = STEP_DOT_SIZE
		var style := StyleBoxFlat.new()
		style.corner_radius_top_left = 5
		style.corner_radius_top_right = 5
		style.corner_radius_bottom_left = 5
		style.corner_radius_bottom_right = 5
		if i == current_step_index:
			style.bg_color = Color(0.0, 0.85, 0.85, 1.0)
			dot.custom_minimum_size = Vector2(22, 10)
		elif i < current_step_index:
			style.bg_color = Color(0.2, 0.6, 0.5, 0.8)
		else:
			style.bg_color = Color(0.2, 0.2, 0.32, 1.0)
		dot.add_theme_stylebox_override("panel", style)
		step_dots_row.add_child(dot)
		_dot_nodes.append(dot)

func _make_text_block(text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.13, 1.0)
	style.border_color = Color(0.15, 0.15, 0.25, 1.0)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9, 1.0))
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(lbl)
	return panel

func _exit_tree() -> void:
	if get_tree() and get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.disconnect(_on_viewport_size_changed)

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

	# Показать/скрыть левую текстовую панель
	var left_pane := landscape_split.get_child(0) as Control
	left_pane.visible = _is_landscape

	# Очистить визуальную область
	for child in visual_area.get_children():
		child.queue_free()

	# В портрете: добавить текстовый блок первым в content_area
	if not _is_landscape:
		var text_block := _make_text_block(step.get("text", ""))
		visual_area.add_child(text_block)

	# Вызвать специфичный рендер шага
	if step.has("render_func") and step["render_func"] != "":
		var func_name: String = step["render_func"]
		if has_method(func_name):
			call(func_name, visual_area, step)

	# Обновить кнопки
	prev_btn.disabled = index == 0
	next_btn.disabled = index == tutorial_steps.size() - 1

	step_changed.emit(index, tutorial_steps.size())
	_rebuild_dots()
	
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
	var gate_name: String = step.get("gate_name", "AND")
	var rows: Array = step.get("rows", [
		{"a": 0, "b": 0, "result": 0},
		{"a": 0, "b": 1, "result": 0},
		{"a": 1, "b": 0, "result": 0},
		{"a": 1, "b": 1, "result": 1},
	])

	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	area.add_child(container)

	# Заголовок вентиля
	var gate_panel := PanelContainer.new()
	var gp_style := StyleBoxFlat.new()
	gp_style.bg_color = Color(0.06, 0.15, 0.22, 1.0)
	gp_style.border_color = Color(0.1, 0.5, 0.75, 0.8)
	gp_style.set_border_width_all(1)
	gp_style.corner_radius_top_left = 8
	gp_style.corner_radius_top_right = 8
	gp_style.corner_radius_bottom_left = 8
	gp_style.corner_radius_bottom_right = 8
	gp_style.content_margin_left = 12
	gp_style.content_margin_right = 12
	gp_style.content_margin_top = 8
	gp_style.content_margin_bottom = 8
	gate_panel.add_theme_stylebox_override("panel", gp_style)
	container.add_child(gate_panel)

	var gate_lbl := Label.new()
	gate_lbl.text = gate_name + " вентиль"
	gate_lbl.add_theme_font_size_override("font_size", 18)
	gate_lbl.add_theme_color_override("font_color", Color(0.3, 0.75, 1.0, 1.0))
	gate_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gate_panel.add_child(gate_lbl)

	# Таблица истинности
	var table := VBoxContainer.new()
	table.add_theme_constant_override("separation", 3)
	container.add_child(table)

	table.add_child(_make_table_row(["A", "B", "Результат"], true))
	for row_data in rows:
		var values := [str(row_data.get("a", "?")), str(row_data.get("b", "?")), str(row_data.get("result", "?"))]
		table.add_child(_make_table_row(values, false, int(row_data.get("result", 0)) == 1))

func _make_table_row(values: Array, is_header: bool, highlight: bool = false) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	for i in range(values.size()):
		var cell := PanelContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cs := StyleBoxFlat.new()
		if is_header:
			cs.bg_color = Color(0.08, 0.12, 0.2, 1.0)
			cs.border_color = Color(0.2, 0.35, 0.55, 0.8)
		elif highlight and i == values.size() - 1:
			cs.bg_color = Color(0.1, 0.22, 0.14, 1.0)
			cs.border_color = Color(0.25, 0.65, 0.4, 0.8)
		else:
			cs.bg_color = Color(0.07, 0.08, 0.12, 1.0)
			cs.border_color = Color(0.15, 0.15, 0.22, 0.6)
		cs.set_border_width_all(1)
		cs.corner_radius_top_left = 4
		cs.corner_radius_top_right = 4
		cs.corner_radius_bottom_left = 4
		cs.corner_radius_bottom_right = 4
		cs.content_margin_left = 8
		cs.content_margin_right = 8
		cs.content_margin_top = 7
		cs.content_margin_bottom = 7
		cell.add_theme_stylebox_override("panel", cs)
		row.add_child(cell)

		var lbl := Label.new()
		lbl.text = values[i]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 15 if not is_header else 13)
		var col: Color
		if is_header:
			col = Color(0.5, 0.7, 1.0, 1.0)
		elif highlight and i == values.size() - 1:
			col = Color(0.3, 1.0, 0.6, 1.0)
		else:
			col = Color(0.8, 0.8, 0.9, 1.0)
		lbl.add_theme_color_override("font_color", col)
		cell.add_child(lbl)
	return row

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
	var stars := _calculate_stars()
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.7, 0.2)
	_show_lesson_summary(stars)

func _show_lesson_summary(stars: int) -> void:
	var summary_scene := load("res://scenes/Tutorial/LessonSummary.tscn")
	if summary_scene == null:
		push_error("TutorialBase: не найдена LessonSummary.tscn")
		get_tree().change_scene_to_file("res://scenes/LearnSelect.tscn")
		return
	var summary: Control = summary_scene.instantiate()
	add_child(summary)
	summary.set_anchors_preset(Control.PRESET_FULL_RECT)
	summary.setup(tutorial_id, stars, linked_quest_scene)
	summary.retry_requested.connect(func():
		get_tree().change_scene_to_file(get_scene_file_path())
	)
	summary.home_requested.connect(func():
		get_tree().change_scene_to_file("res://scenes/LearnSelect.tscn")
	)
	summary.quest_requested.connect(func(path: String):
		get_tree().change_scene_to_file(path)
	)

func _calculate_stars() -> int:
	return 1
