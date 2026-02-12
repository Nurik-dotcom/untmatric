extends Control

# --- Constants & Config ---
const I_STAGE_A_DEFAULT = 7
const POOL_NORMAL = [64, 80, 100, 128, 256, 512, 1024]
const POOL_ANCHOR = [75, 110, 125, 300, 750, 1000]

const STORAGE_LABELS = {
	"bit": "бит",
	"byte": "байт",
	"kb": "Кбайт"
}

# --- State ---
enum Phase { CALC, SELECT, DONE }
var current_phase = Phase.CALC

var i_stage_a: int = 7
var K_val: int = 0
var I_true: int = 0
var I_user: int = 0
var pool_type: String = "NORMAL"

var storage_options: Array = [] # List of Dictionaries {capacity_bits, display_size, display_unit, type}
var selected_option_idx: int = -1

var calc_correct: bool = false
var used_converter: bool = false
var is_timed: bool = false
var forced_sampling: bool = false
var start_time: int = 0
var first_action_time: int = 0
var trial_count: int = 0

# --- Nodes ---
@onready var task_info = $RootPanel/VBox/TaskCard/Margin/VBoxTask/TaskInfo
@onready var task_goal = $RootPanel/VBox/TaskCard/Margin/VBoxTask/TaskGoal
@onready var calc_label = $RootPanel/VBox/CalcCard/Margin/VBoxCalc/CalcLabel
@onready var check_calc_btn = $RootPanel/VBox/CalcCard/Margin/VBoxCalc/CheckCalcBtn
@onready var storage_bay = $RootPanel/VBox/StorageBay
@onready var storage_grid = $RootPanel/VBox/StorageBay/Margin/Grid
@onready var status_label = $RootPanel/VBox/BottomPanel/Margin/VBoxBot/StatusLabel
@onready var submit_btn = $RootPanel/VBox/BottomPanel/Margin/VBoxBot/ActionRow/SubmitBtn
@onready var convert_btn = $RootPanel/VBox/BottomPanel/Margin/VBoxBot/ActionRow/ConvertBtn
@onready var timer_label = $RootPanel/VBox/HeaderBar/TimerLabel
@onready var stability_label = $RootPanel/VBox/HeaderBar/StabilityLabel

func _ready():
	randomize()
	_load_dependency_from_stage_A()
	_start_new_trial()

func _process(_delta):
	if is_timed and current_phase != Phase.DONE:
		var elapsed = (Time.get_ticks_msec() - start_time) / 1000.0
		var remaining = max(0, 35.0 - elapsed)
		timer_label.text = "%02d:%02d" % [int(remaining) / 60, int(remaining) % 60]
		if remaining <= 0:
			# Timeout handling could go here (force fail or auto-submit)
			pass
	elif not is_timed:
		timer_label.text = "--:--"

	stability_label.text = "STABILITY: %d%%" % int(GlobalMetrics.stability)

# --- Logic: Setup ---

func _load_dependency_from_stage_A():
	# In a real scenario, we'd fetch this from GlobalMetrics history or a shared state.
	# For now, we mock or use default.
	# TODO: Implement actual lookup if Stage A data is available.
	i_stage_a = I_STAGE_A_DEFAULT
	# Check for forced sampling trigger from previous session
	# if GlobalMetrics.has_flag("forced_sampling_pending"): forced_sampling = true

func _start_new_trial():
	current_phase = Phase.CALC
	trial_count += 1
	start_time = Time.get_ticks_msec()
	first_action_time = 0
	selected_option_idx = -1
	I_user = 0
	calc_correct = false
	used_converter = false

	# Determine if timed
	# Simple logic: if forced_sampling was set, or randomly occasional?
	# Spec says: "If in Stage A time_to_first_action > 10s... next trial becomes timed".
	# Here we simulate forced_sampling for demonstration if needed.
	is_timed = forced_sampling

	# Generate Data
	_generate_input_values()
	_generate_storage_options()

	# UI Update
	_update_ui_texts()
	_rebuild_storage_grid()
	_update_controls_state()

func _generate_input_values():
	# Check anchor condition (every 7-10 trials)
	var is_anchor = (trial_count % randi_range(7, 10) == 0)

	if is_anchor:
		pool_type = "ANCHOR"
		_setup_anchor_scenario()
	else:
		pool_type = "NORMAL"
		# Pick K from pools
		var pool = POOL_NORMAL if (randf() > 0.3) else POOL_ANCHOR
		K_val = pool[randi() % pool.size()]
		# Add some noise to K for variety? Spec says specific pools.
		# Let's stick to the pool or simple multipliers.
		# To ensure I_true is in 256..16384 range:
		# i=7, K=100 -> 700. K=1000 -> 7000. Fits.

		I_true = K_val * i_stage_a

func _setup_anchor_scenario():
	# Implement 3 anchor types from Spec Section 11
	var type = randi() % 3
	match type:
		0: # 512 bit vs 512 byte
			I_true = 512
			K_val = I_true / i_stage_a # Integer div might be rough, so adjust K to display approximate if needed?
			# Actually K must be integer. If 512 % 7 != 0, this anchor is tricky with i=7.
			# Let's adjust I_true to be multiple of i_stage_a close to 512?
			# Or just force K and calc I_true.
			# Spec says: "I_bits_true = 512".
			# If i=7, K = 73.14... Not possible.
			# So we might need to fuzz K or I_true slightly, OR assume i is power of 2 from Stage A?
			# If i comes from Stage A, it might be 5, 6, 7, 8.
			# Let's pick a K such that K*i is CLOSE to target, or exactly target.
			K_val = 73 # 73*7 = 511. Close enough for "approx"? No, math must be exact.
			I_true = K_val * i_stage_a # 511
			# This breaks the "512" anchor logic slightly.
			# FIX: For Anchor trials, we might fake K display to user? No, must be honest.
			# If i=7, we can't hit 512.
			# Let's stick to valid Math: K * i.
			pass
		1: # 1024 bit
			K_val = 146 # 146 * 7 = 1022
			I_true = K_val * i_stage_a
		2: # 8192 bit (1 KB)
			K_val = 1170 # 1170 * 7 = 8190
			I_true = K_val * i_stage_a

	# Override for clean numbers if i is convenient (e.g. 8)
	if i_stage_a == 8:
		if type == 0: I_true = 512; K_val = 64
		if type == 1: I_true = 1024; K_val = 128
		if type == 2: I_true = 8192; K_val = 1024

func _generate_storage_options():
	storage_options.clear()

	# We need 4 options: Best-fit, Underfit, Unit-trap, Overkill

	# 1. Best Fit: Smallest capacity >= I_true
	# We'll generate a "clean" capacity close to I_true.
	# Standard sizes: 128, 256, 512, 1024 (1K), 2048 (2K), 4096 (4K), 8192 (1KB/8Kb)
	# Logic: Find power of 2 (or standard bank) that fits.
	var best_fit_bits = _find_next_power_of_2(I_true)
	if best_fit_bits < I_true: best_fit_bits *= 2 # just in case

	# Add Best Fit
	storage_options.append(_create_option(best_fit_bits, "best_fit"))

	# 2. Underfit: Slightly less
	var underfit_bits = best_fit_bits / 2
	if underfit_bits >= I_true: underfit_bits = I_true - 1 # force under
	storage_options.append(_create_option(underfit_bits, "underfit"))

	# 3. Overkill: 4x or next order
	var overkill_bits = best_fit_bits * 4
	storage_options.append(_create_option(overkill_bits, "overkill"))

	# 4. Unit Trap:
	# e.g. if I_true is ~1000 bits. Best fit 1024 bits.
	# Trap: "128 bytes" (=1024 bits) but maybe presented confusingly?
	# Or "1024 bytes" (=8192 bits) which looks like 1024 bits number-wise.
	var trap_bits = 0
	var trap_type = "unit_trap"

	# Trap logic: Value numerically similar to I_true but in different unit.
	# If I_true ~ 1000. Trap -> 1000 Bytes (=8000 bits).
	# If I_true ~ 8000. Trap -> 1000 Bits (Underfit physically, but number looks match if confused with bytes).

	# Let's try: Trap Value = I_true (approx) but label says Bytes. -> Huge Overkill.
	trap_bits = I_true * 8
	storage_options.append(_create_option(trap_bits, "unit_trap", true)) # true = force byte display if possible

	storage_options.shuffle()

func _create_option(bits: int, type: String, force_unit_mismatch: bool = false) -> Dictionary:
	# Determine display
	var d_size = bits
	var d_unit = "bit"

	# Auto-convert for display unless forced mismatch
	# Logic: if bits >= 8192 (1KB), show KB. If >= 64, can show Bytes.
	# But we want specific pedagogical traps.

	if force_unit_mismatch:
		# If it's a trap, we want the NUMBER to look like the target input, but unit differs.
		# E.g. Target 1000 bits. Option is 1000 Bytes.
		# So bits input is actually 8000. Display 1000 Bytes.
		if bits % 8 == 0:
			d_size = bits / 8
			d_unit = "byte"
	else:
		# Normal formatting
		if bits >= 8192 and bits % 8192 == 0:
			d_size = bits / 8192
			d_unit = "kb"
		elif bits >= 8 and bits % 8 == 0:
			# Randomly choose bits or bytes for variety, favor bytes for larger
			if randf() > 0.5:
				d_size = bits / 8
				d_unit = "byte"

	return {
		"capacity_bits": bits,
		"display_size": d_size,
		"display_unit": d_unit,
		"type": type
	}

func _find_next_power_of_2(val: int) -> int:
	var p = 1
	while p < val:
		p *= 2
	return p

# --- UI Updates ---

func _update_ui_texts():
	task_info.text = "Глубина кодирования: i = %d бит\nДлина сообщения: K = %d символов" % [i_stage_a, K_val]
	calc_label.text = "I (в битах): %d" % I_user

	status_label.text = "СТАТУС: Сначала вычисли I и нажми «ПРОВЕРИТЬ РАСЧЁТ»."
	if current_phase == Phase.SELECT:
		status_label.text = "СТАТУС: Выбери подходящий носитель."
	elif current_phase == Phase.DONE:
		pass # Set by validation logic

func _update_controls_state():
	# Calc Phase
	var is_calc = (current_phase == Phase.CALC)
	check_calc_btn.disabled = not is_calc
	check_calc_btn.visible = is_calc

	# Storage Phase
	# Disable storage buttons if not in SELECT phase
	for i in range(storage_grid.get_child_count()):
		var btn = storage_grid.get_child(i)
		btn.disabled = (current_phase != Phase.SELECT)

	# Submit Btn
	submit_btn.disabled = (current_phase != Phase.SELECT or selected_option_idx == -1)
	if current_phase == Phase.DONE:
		submit_btn.text = "СЛЕДУЮЩИЙ СИГНАЛ"
		submit_btn.disabled = false
	else:
		submit_btn.text = "ЗАФИКСИРОВАТЬ"

func _rebuild_storage_grid():
	for c in storage_grid.get_children():
		c.queue_free()

	for i in range(storage_options.size()):
		var opt = storage_options[i]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(100, 100)
		btn.toggle_mode = true
		btn.text = "%d %s" % [opt.display_size, STORAGE_LABELS.get(opt.display_unit, opt.display_unit)]
		btn.set_meta("idx", i)
		btn.pressed.connect(_on_storage_option_pressed.bind(btn))
		btn.add_theme_font_size_override("font_size", 24)
		storage_grid.add_child(btn)

# --- Event Handlers ---

func _register_action():
	if first_action_time == 0:
		first_action_time = Time.get_ticks_msec()

func _on_storage_option_pressed(btn: Button):
	_register_action()
	# Exclusive selection
	for child in storage_grid.get_children():
		if child != btn:
			child.button_pressed = false

	if btn.button_pressed:
		selected_option_idx = btn.get_meta("idx")
	else:
		selected_option_idx = -1

	_update_controls_state()

func _on_back_pressed():
	# Go back to menu
	# SceneManager or standard change_scene
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

# Stepper controls
func _on_plus_pressed():
	_register_action()
	if current_phase == Phase.CALC:
		I_user += 8
		_update_ui_texts()
		_reset_storage_if_needed()

func _on_minus_pressed():
	_register_action()
	if current_phase == Phase.CALC:
		I_user = max(0, I_user - 8)
		_update_ui_texts()
		_reset_storage_if_needed()

func _on_div8_pressed():
	_register_action()
	if current_phase == Phase.CALC:
		I_user = int(I_user / 8)
		_update_ui_texts()
		_reset_storage_if_needed()

func _on_mul8_pressed():
	_register_action()
	if current_phase == Phase.CALC:
		I_user = I_user * 8
		_update_ui_texts()
		_reset_storage_if_needed()

func _on_reset_pressed():
	_register_action()
	if current_phase == Phase.CALC:
		I_user = 0
		_update_ui_texts()
		_reset_storage_if_needed()

func _reset_storage_if_needed():
	# If user changes number after checking, force re-check?
	# Spec says: "После смены I: сбрасываем выбранный носитель и снова требуем проверку"
	# So we revert to CALC phase.
	if current_phase == Phase.SELECT:
		current_phase = Phase.CALC
		selected_option_idx = -1
		for c in storage_grid.get_children():
			c.button_pressed = false
		_update_controls_state()

func _on_check_calc_pressed():
	_register_action()
	calc_correct = (I_user == I_true)

	if calc_correct:
		current_phase = Phase.SELECT
		status_label.text = "Расчёт верен. Выбери носитель."
	else:
		status_label.text = "Ошибка в расчётах. I = K * i"
		# Spec: valid_for_diagnostics=true, but mastery=false.
		# We don't fail immediately, just let them retry or fail?
		# Spec implies: "Пока CALC не проверен... StorageBay.disabled = true".
		# Meaning they CANNOT proceed until calc is correct?
		# OR they can proceed but it's marked as fail?
		# "Если calc_correct=false... valid_for_mastery=false"
		# This implies they CAN finish the trial with wrong calc?
		# "Фаза CALC должна проверять... Если calc_correct=false... это не засчитываем"
		# Usually in such games, if I click "Check" and it's wrong, it tells me.
		# If I fix it, I can proceed.
		# If I proceed with WRONG calc... wait, the button is "Check Calc".
		# Let's unlock ONLY if correct.
		# If user is stuck, they use Converter.

	_update_controls_state()

func _on_convert_pressed():
	_register_action()
	used_converter = true
	# Show info
	# "Не вычисляет K*i, но переводит"
	# What does it convert? The current I_user? Or just gives a hint?
	# "Показывает (I) в битах... байтах... Кбайтах"
	# Assuming it converts the current I_user to help them understand units.
	var b = I_user
	var B = "нецелое"
	if b % 8 == 0: B = str(b / 8)
	var KB = "нецелое"
	if b % 8192 == 0: KB = str(b / 8192)

	status_label.text = "Конвертер: %d бит = %s байт = %s Кбайт" % [b, B, KB]

func _on_submit_pressed():
	_register_action()
	if current_phase == Phase.DONE:
		_start_new_trial()
		return

	# Validation Logic
	var selected = storage_options[selected_option_idx]
	var choice_cap = selected.capacity_bits

	var is_fit = (choice_cap >= I_true)

	# Find min fit for classification
	var min_fit_cap = 999999999999
	for opt in storage_options:
		if opt.capacity_bits >= I_true and opt.capacity_bits < min_fit_cap:
			min_fit_cap = opt.capacity_bits

	var is_best_fit = (is_fit and choice_cap == min_fit_cap)
	var is_overkill = (is_fit and not is_best_fit)
	var waste_ratio = float(choice_cap) / float(I_true)

	var error_type = "best_fit"
	if not is_fit:
		error_type = "underfit"
	elif is_overkill:
		if waste_ratio <= 4.0:
			error_type = "overkill_soft"
		else:
			error_type = "overkill_hard"

	# Unit confusion detection (simplified)
	if abs(choice_cap - I_true * 8) < 1: error_type = "unit_confusion_bits_bytes"

	# Log Metrics
	var payload = {
		"quest_id": "radio_intercept",
		"stage_id": "B",
		"match_key": "RI_B_K%d_i%d_pool%s" % [K_val, i_stage_a, pool_type],
		"pool_type": pool_type,
		"i_bits": i_stage_a,
		"K_symbols": K_val,
		"I_bits_true": I_true,
		"I_bits_user": I_user,
		"calc_correct": calc_correct,
		"choice_capacity_bits": choice_cap,
		"choice_display_size": selected.display_size,
		"choice_display_unit": selected.display_unit,
		"used_converter": used_converter,
		"is_fit": is_fit,
		"is_best_fit": is_best_fit,
		"is_overkill": is_overkill,
		"waste_ratio": waste_ratio,
		"error_type": error_type,
		"is_timed": is_timed,
		"forced_sampling": forced_sampling,
		"elapsed_ms": Time.get_ticks_msec() - start_time,
		"time_to_first_action_ms": first_action_time - start_time if first_action_time > 0 else 0,
		"valid_for_diagnostics": true,
		"valid_for_mastery": (not used_converter and calc_correct)
	}

	GlobalMetrics.register_trial(payload)

	# Update Status and Phase
	current_phase = Phase.DONE

	if is_best_fit:
		status_label.text = "СТАТУС: Идеально. Следов нет."
		status_label.add_theme_color_override("font_color", Color.GREEN)
	elif is_overkill:
		status_label.text = "СТАТУС: Помещается, но избыточно (риск)."
		status_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		status_label.text = "СТАТУС: Данные не помещаются."
		status_label.add_theme_color_override("font_color", Color.RED)

	_update_controls_state()
