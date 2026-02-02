extends Control

# UI References
@onready var lbl_level = $MainLayout/TopBar/LevelLabel
@onready var lbl_rank = $MainLayout/TopBar/RankLabel
@onready var progress_stability = $MainLayout/TopBar/StabilityBar
@onready var lbl_target = $MainLayout/ContentContainer/LeftPanel/ScreenPanel/VBox/TargetValue
@onready var lbl_preview = $MainLayout/ContentContainer/LeftPanel/ScreenPanel/VBox/PreviewValue
@onready var lbl_system = $MainLayout/ContentContainer/LeftPanel/ScreenPanel/VBox/SystemLabel
@onready var container_switches = $MainLayout/ContentContainer/RightPanel/SwitchesContainer
@onready var container_labels = $MainLayout/ContentContainer/RightPanel/BitLabelsContainer
@onready var btn_check = $MainLayout/ContentContainer/RightPanel/ControlButtons/CheckButton
@onready var log_text = $MainLayout/FeedbackPanel/LogText

# Modal References
@onready var modal_selection = $ModeSelectionModal

# Game State
var current_target: int = 0
var current_input: int = 0
var is_level_active: bool = false

const SWIPE_MIN: float = 60.0
const SWIPE_MAX_Y: float = 40.0
var _swipe_start_pos: Vector2 = Vector2.ZERO
var _swipe_tracking: bool = false

# System Colors
const COLOR_NORMAL = Color("33ff33") # Green
const COLOR_WARN = Color("ffcc00")   # Amber
const COLOR_ERROR = Color("ff3333")  # Red

func _ready():
	# Connect global signals
	GlobalMetrics.stability_changed.connect(_on_stability_changed)
	GlobalMetrics.shield_triggered.connect(_on_shield_triggered)

	# Initialize switches
	for i in range(8):
		var switch = CheckButton.new()
		switch.name = "Switch_%d" % i
		switch.text = ""
		switch.toggled.connect(_on_switch_toggled.bind(i))
		container_switches.add_child(switch)

		var lbl = Label.new()
		lbl.name = "Label_%d" % i
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.text = "0"
		# Ensure labels have min width to match switches somewhat or use size flags
		lbl.custom_minimum_size = Vector2(40, 0)
		container_labels.add_child(lbl)

	# Start Game Immediately (Modal is now in QuestSelect)
	start_level(GlobalMetrics.current_level_index)

func _unhandled_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			if _is_in_switches(event.position):
				_swipe_start_pos = event.position
				_swipe_tracking = true
		else:
			if _swipe_tracking:
				var delta = event.position - _swipe_start_pos
				if abs(delta.x) >= SWIPE_MIN and abs(delta.y) <= SWIPE_MAX_Y:
					_apply_shift_left()
				_swipe_tracking = false
	elif event is InputEventMouseButton:
		# Desktop swipe simulation with mouse drag
		if event.pressed:
			if _is_in_switches(event.position):
				_swipe_start_pos = event.position
				_swipe_tracking = true
		else:
			if _swipe_tracking:
				var delta_mouse = event.position - _swipe_start_pos
				if abs(delta_mouse.x) >= SWIPE_MIN and abs(delta_mouse.y) <= SWIPE_MAX_Y:
					_apply_shift_left()
				_swipe_tracking = false

func start_level(level_idx):
	GlobalMetrics.start_level(level_idx)
	is_level_active = true

	# Target from GlobalMetrics (A or B)
	current_target = GlobalMetrics.current_target_value
	current_input = 0

	# Update UI for Mode
	var mode = GlobalMetrics.current_mode
	update_visuals_for_mode(mode)

	# Reset Switches
	for child in container_switches.get_children():
		child.set_pressed_no_signal(false)

	# Display Target or Example
	if level_idx >= 15:
		lbl_target.text = _format_example(mode)
	else:
		lbl_target.text = _format_value(current_target, mode)

	lbl_system.text = "SYSTEM: %s" % mode
	lbl_level.text = "LEVEL %02d" % (level_idx + 1)
	var rank = GlobalMetrics.get_rank_info()
	lbl_rank.text = rank.name
	lbl_rank.add_theme_color_override("font_color", rank.color)
	btn_check.text = "CHECK"

	log_message("System initialized. Target locked.", COLOR_NORMAL)
	_on_stability_changed(100.0, 0)

	# Reset preview
	update_preview_display()
func update_visuals_for_mode(mode):
	var weights = []
	if mode == "DEC":
		weights = [128, 64, 32, 16, 8, 4, 2, 1]
	elif mode == "OCT":
		# 2-1 | 4-2-1 | 4-2-1
		weights = [2, 1, 4, 2, 1, 4, 2, 1]
	elif mode == "HEX":
		# 8-4-2-1 | 8-4-2-1
		weights = [8, 4, 2, 1, 8, 4, 2, 1]

	var labels = container_labels.get_children()
	for i in range(8):
		labels[i].text = str(weights[i])

func update_preview_display():
	lbl_preview.visible = true
	var mode = GlobalMetrics.current_mode
	lbl_preview.text = "INPUT: %s" % _format_value(current_input, mode)
func _on_switch_toggled(pressed: bool, bit_index: int):
	AudioManager.play("click")
	# Bit index 0 in UI is usually MSB (leftmost), but mathematically bit 0 is LSB.
	# Let's assume UI is MSB -> LSB (Switch 0 is 128, Switch 7 is 1).
	var power = 7 - bit_index
	if pressed:
		current_input |= (1 << power)
	else:
		current_input &= ~(1 << power)

	update_preview_display()

func _on_check_button_pressed():
	if not is_level_active: return

	var result = GlobalMetrics.check_solution(current_target, current_input)

	if result.success:
		AudioManager.play("relay")
		log_message("ДОСТУП РАЗРЕШЕН.", COLOR_NORMAL)
		is_level_active = false

		# Wait and go next
		await get_tree().create_timer(1.0).timeout
		if GlobalMetrics.current_level_index < GlobalMetrics.MAX_LEVELS - 1:
			start_level(GlobalMetrics.current_level_index + 1)
		else:
			log_message("МИССИЯ ВЫПОЛНЕНА.", COLOR_NORMAL)
	else:
		AudioManager.play("error")
		if result.has("error"):
			if result.error == "SHIELD_FREQ":
				log_message(result.message, COLOR_WARN)
			elif result.error == "SHIELD_ACTIVE":
				log_message(result.message, COLOR_ERROR)
			else:
				log_message(result.message, COLOR_ERROR)
				if result.has("hints"):
					var h = result.hints
					var msg = "ПОДСКАЗКА: %s | ЗОНА: %s" % [_translate_hint(h.diagnosis), _translate_hint(h.zone)]
					log_message(msg, COLOR_WARN)

func _translate_hint(code: String) -> String:
	match code:
		"VALUE_LOW": return "ЗНАЧЕНИЕ МАЛО"
		"VALUE_HIGH": return "ЗНАЧЕНИЕ ВЕЛИКО"
		"BIT_ERROR": return "ОШИБКА БИТА"
		"BOTH_NIBBLES": return "ОБА НИББЛА"
		"LOWER_NIBBLE": return "МЛАДШИЙ НИББЛ (4-0)"
		"UPPER_NIBBLE": return "СТАРШИЙ НИББЛ (7-4)"
		"NONE": return "НЕТ"
	return code

func _on_stability_changed(new_val, change):
	progress_stability.value = new_val
	if new_val <= 0:
		is_level_active = false
		btn_check.disabled = true
		start_safe_mode_analysis()
func _on_shield_triggered(name, duration):
	log_message("ЩИТ БЕЗОПАСНОСТИ: %s. ЖДИТЕ %s с." % [name, duration], COLOR_WARN)
	# Could disable button here
	btn_check.disabled = true
	await get_tree().create_timer(duration).timeout
	btn_check.disabled = false
	log_message("ЩИТ ОТКЛЮЧЕН.", COLOR_NORMAL)

func log_message(msg: String, color: Color):
	var time_str = Time.get_time_string_from_system()
	log_text.push_color(color)
	log_text.add_text("[%s] %s\n" % [time_str, msg])
	log_text.pop()

func _is_in_switches(pos: Vector2) -> bool:
	return container_switches.get_global_rect().has_point(pos)

func _apply_shift_left():
	current_input = (current_input << 1) & 0xFF
	_sync_switches_to_input()
	update_preview_display()

func _sync_switches_to_input():
	var switches = container_switches.get_children()
	for i in range(switches.size()):
		var bit = 7 - i
		var pressed = ((current_input >> bit) & 1) == 1
		switches[i].set_pressed_no_signal(pressed)

func _format_value(val: int, mode: String) -> String:
	if mode == "DEC":
		return "%d" % val
	elif mode == "OCT":
		return "%o" % val
	elif mode == "HEX":
		return "%X" % val
	return "%d" % val

func _format_example(mode: String) -> String:
	var a = GlobalMetrics.current_reg_a
	var b = GlobalMetrics.current_reg_b
	var op = GlobalMetrics.current_operator
	var a_txt = _format_value(a, mode)
	var b_txt = _format_value(b, mode)
	if op == GlobalMetrics.Operator.ADD:
		return "%s + %s" % [a_txt, b_txt]
	elif op == GlobalMetrics.Operator.SUB:
		return "%s - %s" % [a_txt, b_txt]
	else:
		return "%s << %s" % [a_txt, b_txt]

func start_safe_mode_analysis():
	log_message("РЕЖИМ БЕЗОПАСНОСТИ: анализ переноса", COLOR_WARN)
	if GlobalMetrics.current_level_index < 15:
		log_message("Анализ доступен только для уровней арифметики.", COLOR_WARN)
		return

	var a = GlobalMetrics.current_reg_a
	var b = GlobalMetrics.current_reg_b
	var op = GlobalMetrics.current_operator

	if op == GlobalMetrics.Operator.ADD:
		var carry = 0
		for bit in range(8):
			var abit = (a >> bit) & 1
			var bbit = (b >> bit) & 1
			var sum = abit + bbit + carry
			var res = sum & 1
			var new_carry = (sum >> 1) & 1
			log_message("Разряд %d: %d+%d+%d = %d, перенос %d" % [bit + 1, abit, bbit, carry, res, new_carry], COLOR_WARN)
			var input_bit = (current_input >> bit) & 1
			if input_bit != res:
				log_message("Ошибка в %d-м разряде: %d+%d+%d=10, перенос -> %d" % [bit + 1, abit, bbit, carry, bit + 2], COLOR_ERROR)
				break
			carry = new_carry
	elif op == GlobalMetrics.Operator.SUB:
		var borrow = 0
		for bit in range(8):
			var abit = (a >> bit) & 1
			var bbit = (b >> bit) & 1
			var diff = abit - bbit - borrow
			var used_borrow = borrow
			if diff < 0:
				diff += 2
				borrow = 1
				if bit == 3:
					log_message("Заём из старшего полубайта", COLOR_WARN)
			else:
				borrow = 0
			log_message("Разряд %d: %d-%d-%d = %d" % [bit + 1, abit, bbit, used_borrow, diff], COLOR_WARN)
			var input_bit = (current_input >> bit) & 1
			if input_bit != diff:
				log_message("Ошибка в %d-м разряде: требуется заём" % [bit + 1], COLOR_ERROR)
				break
	else:
		var shift = GlobalMetrics.current_reg_b
		log_message("SHIFT << %d" % shift, COLOR_WARN)
		for bit in range(8 - shift):
			var src = (a >> bit) & 1
			log_message("%d -> %d : %d" % [bit + 1, bit + 1 + shift, src], COLOR_WARN)

# --- Navigation ---
func _on_menu_button_pressed():
	# Go back to Quest Select
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _on_complexity_a_pressed():
	pass
