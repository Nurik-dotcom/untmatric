extends "res://scenes/Tutorial/TutorialBase.gd"
# TutorialBinary.gd - Обучение двоичной системе

class_name TutorialBinary

func _initialize_tutorial() -> void:
	tutorial_id = "tutorial_binary"
	tutorial_title = "Обучение: Двоичная система"
	
	tutorial_steps = [
		# Шаг 1: Введение
		{
			"text": "🔢 ДВОИЧНАЯ СИСТЕМА - основа всех компьютеров\n\nВсе компьютеры работают с двоичными числами (0 и 1)\n\n0 = ⊘ ВЫКЛЮЧЕНО (нет сигнала)\n1 = ⊙ ВКЛЮЧЕНО (есть сигнал)",
			"render_func": ""
		},
		
		# Шаг 2: Позиции и веса
		{
			"text": "📍 ПОЗИЦИИ И ВЕСА битов\n\nКаждая позиция имеет вес - степень двойки:\n\n128 = 2⁷ | 64 = 2⁶ | 32 = 2⁵ | 16 = 2⁴\n  8 = 2³ |  4 = 2² |  2 = 2¹ |  1 = 2⁰\n\n✓ Правая позиция (1) - самая младшая\n✓ Левая позиция (128) - самая старшая"
		},
		
		# Шаг 3: Визуальная демонстрация
		{
			"text": "📊 ПРИМЕР: 8-битное число = 10101010\n\nЭто число содержит 1 на чётных позициях\n\n1 в позиции 128? ✓ ДА\n0 в позиции 64?  ✓ ДА\n1 в позиции 32?  ✓ ДА\n0 в позиции 16?  ✓ ДА",
			"render_func": "render_bit_grid",
			"title": "📊 Число: 10101010",
			"bits": [1, 0, 1, 0, 1, 0, 1, 0]
		},
		
		# Шаг 4: Расчет
		{
			"text": "🧮 ВЫЧИСЛЕНИЕ итогового значения\n\n1×128 + 0×64 + 1×32 + 0×16 + 1×8 + 0×4 + 1×2 + 0×1\n\n= 128 + 32 + 8 + 2 = 170 (десятичное число)\n\n✓ В игре: часто используется для шифрования кодов",
			"render_func": "render_bit_grid",
			"title": "🧮 Результат: 10101010 = 170",
			"bits": [1, 0, 1, 0, 1, 0, 1, 0]
		},
		
		# Шаг 5: Практика 1
		{
			"text": "🎮 ПРАКТИКА 1: Максимальное число\n\nЧто произойдёт если ВСЕ биты = 1?\n\n11111111 = ?\n\n🎯 Подсказка: суммируй все веса (128+64+32+16+8+4+2+1)",
			"render_func": "render_bit_grid",
			"title": "🎮 Практика: 11111111 = ?",
			"bits": [1, 1, 1, 1, 1, 1, 1, 1],
			"correct_answer": 255
		},
		
		# Шаг 6: Объяснение
		{
			"text": "✓ ОТВЕТ: 11111111 = 255\n\nЭто максимальное значение 8-битного числа\n\nДля больших чисел нужно больше бит:\n• 16 бит: 0-65535\n• 32 бита: 0-4,294,967,295\n• 64 бита: огромное количество!\n\n🎓 В игре это используется в криптографии и шифровании",
			"title": "8-битный диапазон",
			"value1_label": "Минимум (00000000):",
			"value1": 0,
			"value2_label": "Максимум (11111111):",
			"value2": 255
		},
		
		# Шаг 7: Практика 2
		{
			"text": "🎮 ПРАКТИКА 2: ASCII код буквы 'A'\n\nДвоичное число: 01000001\n\nТолько позиции 64 и 1 содержат 1\n\n64 + 1 = ? 🤔\n\n🎯 Это известный код в криптографии!",
			"render_func": "render_bit_grid",
			"title": "🎮 Практика: 01000001 = ? (буква 'A')",
			"bits": [0, 1, 0, 0, 0, 0, 0, 1],
			"correct_answer": 65
		},
		
		# Шаг 8: В контексте игры
		{
			"text": "🕹️ ПРИМЕНЕНИЕ В ИГРЕ:\n\n• ☑️ Хранение информации (флаги, статусы)\n• ☑️ Создание кодов (ASCII, шифры)\n• ☑️ Битовые операции (AND, OR, XOR)\n• ☑️ Манипуляция данными\n• ☑️ Шифрование и дешифрование",
			"render_func": ""
		},
		
		# Шаг 9: Заключение
		{
			"text": "✓ УСПЕШНО ЗАВЕРШИЛИ ОБУЧЕНИЕ ДВОИЧНОЙ СИСТЕМЕ!\n\n📚 В следующих уроках:\n• Шестнадцатеричная система (HEX)\n• Логические операции (AND, OR, XOR)\n• Практические задачи из квестов\n\n🎓 Готовы к следующему вызову?",
			"render_func": ""
		}
	]

func render_bit_grid(area: Control, step: Dictionary) -> void:
	"""Улучшенный рендер бит-сетки с расчетами"""
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 15)
	area.add_child(container)
	
	var title = Label.new()
	title.text = step.get("title", "")
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color.WHITE)
	container.add_child(title)
	
	# Сетка битов
	var grid = GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	container.add_child(grid)
	
	var bits = step.get("bits", [1,0,1,0,1,0,1,0])
	var weights = [128, 64, 32, 16, 8, 4, 2, 1]
	var total = 0
	
	for i in range(8):
		var cell = VBoxContainer.new()
		cell.add_theme_constant_override("separation", 2)
		
		# Значение бита
		var bit_label = Label.new()
		bit_label.text = str(bits[i])
		bit_label.add_theme_font_size_override("font_size", 20)
		bit_label.add_theme_color_override("font_color", Color.YELLOW if bits[i] == 1 else Color.GRAY)
		bit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(bit_label)
		
		# Вес
		var weight_label = Label.new()
		weight_label.text = "2^%d" % (7 - i)
		weight_label.add_theme_font_size_override("font_size", 11)
		weight_label.add_theme_color_override("font_color", Color.GRAY)
		weight_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(weight_label)
		
		# Значение позиции
		var value_label = Label.new()
		value_label.text = str(weights[i])
		value_label.add_theme_font_size_override("font_size", 12)
		value_label.add_theme_color_override("font_color", Color.CYAN if bits[i] == 1 else Color.GRAY)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(value_label)
		
		grid.add_child(cell)
		
		if bits[i] == 1:
			total += weights[i]
	
	# Расчет
	var calc_label = Label.new()
	var calc_text = ""
	for i in range(8):
		if bits[i] == 1:
			if calc_text != "":
				calc_text += " + "
			calc_text += str(weights[i])
	
	calc_label.text = calc_text + " = %d" % total
	calc_label.add_theme_font_size_override("font_size", 16)
	calc_label.add_theme_color_override("font_color", Color.YELLOW)
	calc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(calc_label)

func render_comparison(area: Control, step: Dictionary) -> void:
	"""Рендер для сравнения"""
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 20)
	area.add_child(container)
	
	var title = Label.new()
	title.text = step.get("title", "")
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color.WHITE)
	container.add_child(title)
	
	# Минимум
	var min_box = HBoxContainer.new()
	min_box.add_theme_constant_override("separation", 15)
	container.add_child(min_box)
	
	var min_label = Label.new()
	min_label.text = step.get("value1_label", "")
	min_label.custom_minimum_size = Vector2(180, 0)
	min_box.add_child(min_label)
	
	var min_val = Label.new()
	min_val.text = str(step.get("value1", ""))
	min_val.add_theme_font_size_override("font_size", 20)
	min_val.add_theme_color_override("font_color", Color.CYAN)
	min_box.add_child(min_val)
	
	# Максимум
	var max_box = HBoxContainer.new()
	max_box.add_theme_constant_override("separation", 15)
	container.add_child(max_box)
	
	var max_label = Label.new()
	max_label.text = step.get("value2_label", "")
	max_label.custom_minimum_size = Vector2(180, 0)
	max_box.add_child(max_label)
	
	var max_val = Label.new()
	max_val.text = str(step.get("value2", ""))
	max_val.add_theme_font_size_override("font_size", 20)
	max_val.add_theme_color_override("font_color", Color.YELLOW)
	max_box.add_child(max_val)
