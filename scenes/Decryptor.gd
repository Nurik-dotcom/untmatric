extends Control

# UI References
@onready var lbl_level = $MainLayout/TopBar/LevelLabel
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

func start_level(level_idx):
	GlobalMetrics.start_level(level_idx)
	is_level_active = true

	# Generate Target
	if GlobalMetrics.current_operator != GlobalMetrics.Operator.NONE:
		# Protocol B (Arithmetic)
		current_target = GlobalMetrics.arithmetic_target
	else:
		# Protocol A (Simple)
		current_target = randi_range(1, 255)

	current_input = 0

	# Update UI for Mode
	var mode = GlobalMetrics.current_mode
	update_visuals_for_mode(mode)

	# Reset Switches
	for child in container_switches.get_children():
		child.set_pressed_no_signal(false)

	# Display Target
	var display_text = ""
	if GlobalMetrics.current_operator != GlobalMetrics.Operator.NONE:
		# Display Arithmetic Equation
		var op_char = ""
		if GlobalMetrics.current_operator == GlobalMetrics.Operator.ADD: op_char = "+"
		elif GlobalMetrics.current_operator == GlobalMetrics.Operator.SUB: op_char = "-"
		elif GlobalMetrics.current_operator == GlobalMetrics.Operator.SHIFT: op_char = "<<"

		display_text = "%X %s %X" % [GlobalMetrics.operand_a, op_char, GlobalMetrics.operand_b]
	else:
		# Standard Display
		if mode == "DEC":
			display_text = "%d" % current_target
		elif mode == "OCT":
			display_text = "%o" % current_target
		elif mode == "HEX":
			display_text = "%X" % current_target

	lbl_target.text = display_text
	lbl_system.text = "СИСТЕМА: %s" % mode
	lbl_level.text = "УРОВЕНЬ %02d" % (level_idx + 1)
	btn_check.text = "ПРОВЕРИТЬ"
	btn_check.disabled = false

	log_message("Система инициализирована. Цель захвачена.", COLOR_NORMAL)
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
	# Only visible for Complexity A (Levels 0-14)
	if GlobalMetrics.current_level_index >= 15:
		lbl_preview.visible = false
		return

	lbl_preview.visible = true
	var mode = GlobalMetrics.current_mode
	var preview_text = ""

	if mode == "DEC":
		preview_text = "ТЕКУЩЕЕ: %d" % current_input
	elif mode == "OCT":
		preview_text = "ТЕКУЩЕЕ: %o" % current_input
	elif mode == "HEX":
		preview_text = "ТЕКУЩЕЕ: %X" % current_input

	lbl_preview.text = preview_text

func _on_switch_toggled(pressed: bool, bit_index: int):
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
		log_message("ДОСТУП РАЗРЕШЕН.", COLOR_NORMAL)
		if result.get("is_overflow", false):
			log_message("ВНИМАНИЕ: Обнаружено переполнение регистра!", COLOR_WARN)

		is_level_active = false

		# Wait and go next
		await get_tree().create_timer(1.0).timeout
		if GlobalMetrics.current_level_index < GlobalMetrics.MAX_LEVELS - 1:
			start_level(GlobalMetrics.current_level_index + 1)
		else:
			log_message("МИССИЯ ВЫПОЛНЕНА.", COLOR_NORMAL)
	else:
		if result.has("error"):
			if result.error == "SHIELD_FREQ":
				log_message(result.message, COLOR_WARN)
			elif result.error == "SHIELD_ACTIVE":
				log_message(result.message, COLOR_ERROR)
			else:
				log_message(result.message, COLOR_ERROR)

				# Borrow Warning Logic
				if result.get("borrow_warning", false):
					log_message("ВНИМАНИЕ: Ошибка в каскадном заёме разрядов", COLOR_WARN)

				if result.has("hints"):
					var h = result.hints
					# Hint Ladder Logic: Zone hint only if stability <= 50%
					var show_zone = GlobalMetrics.stability <= 50.0
					var msg = ""
					if show_zone:
						msg = "ПОДСКАЗКА: %s | ЗОНА: %s" % [_translate_hint(h.diagnosis), _translate_hint(h.zone)]
					else:
						msg = "ПОДСКАЗКА: %s (ЗОНА СКРЫТА > 50%%)" % [_translate_hint(h.diagnosis)]

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
		log_message("КРИТИЧЕСКИЙ СБОЙ. АКТИВАЦИЯ БЕЗОПАСНОГО РЕЖИМА...", COLOR_ERROR)
		_show_safe_mode()
		is_level_active = false # Pause regular checks?
		btn_check.disabled = true # Lock check button in safe mode? Assuming yes, or needs specific safe mode interaction.
		# For now, locking until restart or manual intervention logic (not fully defined, just showing diag).

func _show_safe_mode():
	# Identify wrong bits
	var xor_val = current_input ^ current_target
	var wrong_bits = []
	for i in range(8):
		if (xor_val & (1 << i)) != 0:
			wrong_bits.append(i)

	if wrong_bits.size() > 0:
		var random_bit_idx = wrong_bits.pick_random()
		# UI index is 7 - bit_index
		var ui_idx = 7 - random_bit_idx

		# Highlight ONLY this bit
		var switches = container_switches.get_children()
		switches[ui_idx].modulate = Color(1, 0, 0) # Red highlight

		log_message("БЕЗОПАСНЫЙ РЕЖИМ: Обнаружено %d ошибок." % wrong_bits.size(), COLOR_ERROR)
		log_message("КРИТИЧЕСКАЯ ТОЧКА: Бит #%d (значение %d)" % [random_bit_idx, 1 << random_bit_idx], COLOR_ERROR)
	else:
		log_message("БЕЗОПАСНЫЙ РЕЖИМ: Ошибок не обнаружено??", COLOR_WARN)

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

# --- Navigation ---
func _on_menu_button_pressed():
	# Go back to Quest Select
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")
