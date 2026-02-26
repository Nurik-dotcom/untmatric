extends "res://scenes/Tutorial/TutorialBase.gd"
# TutorialHexadecimal.gd - Обучение шестнадцатеричной системе

class_name TutorialHexadecimal

func _initialize_tutorial() -> void:
	tutorial_id = "tutorial_hexadecimal"
	tutorial_title = "Обучение: Шестнадцатеричная (HEX) система"
	
	tutorial_steps = [
		# Шаг 1: Введение
		{
			"text": "🔣 ШЕСТНАДЦАТЕРИЧНАЯ (HEX) СИСТЕМА - язык компьютеров\n\nHEX = 16-иричная система счисления\n\nЦифры: 0-9, A, B, C, D, E, F\n(где A=10, B=11, C=12, D=13, E=14, F=15)\n\n✓ Используется везде в компьютерных системах",
			"render_func": ""
		},
		
		# Шаг 2: Цифры HEX
		{
			"text": "🔢 ЦИФРЫ В HEX СИСТЕМЕ:\n\n0  1  2  3  4  5  6  7\n8  9  A  B  C  D  E  F\n       (10)(11)(12)(13)(14)(15)\n\n✓ После 9 идёт A (не 10!)\n✓ F - это максимум в HEX",
			"render_func": "render_hex_digits"
		},
		
		# Шаг 3: Позиционная система
		{
			"text": "📍 ПОЗИЦИИ В HEX - степени числа 16:\n\nПозиция 0 (справа) = 16⁰ = 1\nПозиция 1        = 16¹ = 16\nПозиция 2        = 16² = 256\nПозиция 3        = 16³ = 4096\n\n✓ Каждая позиция в 16 раз больше предыдущей",
			"render_func": "render_hex_positions"
		},
		
		# Шаг 4: Пример 1 - FF (максимум)
		{
			"text": "📊 ПРИМЕР 1: FF в HEX\n\nF × 16 + F × 1\n= 15 × 16 + 15 × 1\n= 240 + 15\n= 255 (десятичное число)\n\n✓ FF - это максимум для 8-битного числа\n✓ В игре часто встречается в цветах (#FFFFFF = белый)",
			"render_func": "render_hex_conversion",
			"hex_value": "FF",
			"decimal_value": 255
		},
		
		# Шаг 5: Пример 2 - 10 в HEX
		{
			"text": "📊 ПРИМЕР 2: 10 в HEX\n\n1 × 16 + 0 × 1\n= 16 (десятичное число)\n\n✓ НЕ путайте 10 в HEX с 10 в десятичной!\n✓ HEX 10 = DEC 16\n✓ В нашей игре 10 часто = базовое значение",
			"render_func": "render_hex_conversion",
			"hex_value": "10",
			"decimal_value": 16
		},
		
		# Шаг 6: Практика 1 - 20 в HEX
		{
			"text": "🎮 ПРАКТИКА 1: Что такое 20 в HEX?\n\nВычисляем:\n2 × 16 + 0 × 1 = ?\n\n🎯 Попробуй вычислить сам!",
			"render_func": "render_hex_conversion",
			"hex_value": "20",
			"decimal_value": 32
		},
		
		# Шаг 7: Практика 2 - A5 в HEX
		{
			"text": "🎮 ПРАКТИКА 2: Что такое A5 в HEX?\n\nВычисляем:\nA × 16 + 5 × 1 = ?\n(не забудь A = 10)\n\n🎯 Помни: HEX A = DEC 10",
			"render_func": "render_hex_conversion",
			"hex_value": "A5",
			"decimal_value": 165
		},
		
		# Шаг 8: Почему HEX?
		{
			"text": "❓ ПОЧЕМУ КОМПЬЮТЕРЫ ИСПОЛЬЗУЮТ HEX?\n\n✓ 1 HEX цифра = 4 бита (16 = 2⁴)\n✓ FF = 11111111 = 8 бит ↔ 2 hex цифры = удобно!\n✓ Компактнее чем двоичная (FF vs 11111111)\n✓ Используется в кодировании цветов\n✓ Удобна для криптографии и шифрования",
			"render_func": ""
		},
		
		# Шаг 9: Конвертация из двоичной
		{
			"text": "🔄 ПЕРЕВОД: Двоичная → HEX\n\nРазделите двоичное на группы по 4 бита:\n11110101\n ↓  ↓\n1111 0101\n  ↓   ↓\n  F   5  = F5 в HEX\n\n✓ F5 (HEX) = 245 (decimal)\n✓ Это часто встречается в криптографии",
			"render_func": "render_binary_to_hex",
			"binary": "11110101",
			"hex": "F5",
			"decimal": 245
		},
		
		# Шаг 10: В контексте игры
		{
			"text": "🕹️ ПРИМЕНЕНИЕ HEX В ИГРЕ:\n\n☑️ Хранение данных (00-FF = 0-255)\n☑️ Кодирование цветов (#RRGGBB)\n☑️ Шифроваие и дешифрование\n☑️ Операции с байтами\n☑️ Представление адресов и кодов",
			"render_func": ""
		},
		
		# Шаг 11: Заключение
		{
			"text": "✓ УСПЕШНО ЗАВЕРШИЛИ HEX ОБУЧЕНИЕ!\n\n📚 Теперь вы готовы к:\n• Логическим операциям (AND, OR, XOR)\n• Манипуляции битами и байтами\n• Криптографическим задачам\n• Сложным квестам!\n\n🎓 Отличная работа!",
			"render_func": ""
		}
	]

func render_hex_digits(area: Control, step: Dictionary) -> void:
	"""Рендер таблицы HEX цифр"""
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 10)
	area.add_child(container)
	
	var title = Label.new()
	title.text = "HEX цифры и их значения"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color.WHITE)
	container.add_child(title)
	
	var grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	container.add_child(grid)
	
	var hex_digits = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]
	
	for i in range(16):
		var cell = VBoxContainer.new()
		cell.add_theme_constant_override("separation", 5)
		
		var hex_label = Label.new()
		hex_label.text = hex_digits[i]
		hex_label.add_theme_font_size_override("font_size", 20)
		hex_label.add_theme_color_override("font_color", Color.YELLOW)
		hex_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(hex_label)
		
		var dec_label = Label.new()
		dec_label.text = "(%d)" % i
		dec_label.add_theme_font_size_override("font_size", 12)
		dec_label.add_theme_color_override("font_color", Color.CYAN)
		dec_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(dec_label)
		
		grid.add_child(cell)

func render_hex_positions(area: Control, step: Dictionary) -> void:
	"""Рендер позиций в HEX"""
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 10)
	area.add_child(container)
	
	var title = Label.new()
	title.text = "Позиции и их значения"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color.WHITE)
	container.add_child(title)
	
	var values = [
		{"name": "Position 0", "power": "16^0", "value": 1},
		{"name": "Position 1", "power": "16^1", "value": 16},
		{"name": "Position 2", "power": "16^2", "value": 256},
		{"name": "Position 3", "power": "16^3", "value": 4096}
	]
	
	for v in values:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 20)
		container.add_child(row)
		
		var name_label = Label.new()
		name_label.text = v["name"]
		name_label.custom_minimum_size = Vector2(100, 0)
		row.add_child(name_label)
		
		var power_label = Label.new()
		power_label.text = v["power"]
		power_label.add_theme_color_override("font_color", Color.CYAN)
		power_label.custom_minimum_size = Vector2(80, 0)
		row.add_child(power_label)
		
		var eq_label = Label.new()
		eq_label.text = "="
		eq_label.custom_minimum_size = Vector2(20, 0)
		row.add_child(eq_label)
		
		var val_label = Label.new()
		val_label.text = str(v["value"])
		val_label.add_theme_font_size_override("font_size", 16)
		val_label.add_theme_color_override("font_color", Color.YELLOW)
		row.add_child(val_label)

func render_hex_conversion(area: Control, step: Dictionary) -> void:
	"""Рендер конвертации HEX в десятичную"""
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 15)
	area.add_child(container)
	
	var hex = step.get("hex_value", "FF")
	var decimal = step.get("decimal_value", 255)
	
	# HEX значение
	var hex_box = HBoxContainer.new()
	hex_box.add_theme_constant_override("separation", 10)
	container.add_child(hex_box)
	
	var hex_label = Label.new()
	hex_label.text = "HEX:"
	hex_label.custom_minimum_size = Vector2(80, 0)
	hex_box.add_child(hex_label)
	
	var hex_val = Label.new()
	hex_val.text = hex
	hex_val.add_theme_font_size_override("font_size", 24)
	hex_val.add_theme_color_override("font_color", Color.YELLOW)
	hex_box.add_child(hex_val)
	
	# Стрелка
	var arrow = Label.new()
	arrow.text = "→ Конвертация →"
	arrow.add_theme_font_size_override("font_size", 14)
	arrow.add_theme_color_override("font_color", Color.CYAN)
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(arrow)
	
	# Десятичное значение
	var dec_box = HBoxContainer.new()
	dec_box.add_theme_constant_override("separation", 10)
	container.add_child(dec_box)
	
	var dec_label = Label.new()
	dec_label.text = "Decimal:"
	dec_label.custom_minimum_size = Vector2(80, 0)
	dec_box.add_child(dec_label)
	
	var dec_val = Label.new()
	dec_val.text = str(decimal)
	dec_val.add_theme_font_size_override("font_size", 24)
	dec_val.add_theme_color_override("font_color", Color.CYAN)
	dec_box.add_child(dec_val)

func render_binary_to_hex(area: Control, step: Dictionary) -> void:
	"""Рендер конвертации двоичной в HEX"""
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 15)
	area.add_child(container)
	
	var binary = step.get("binary", "11110101")
	var hex = step.get("hex", "F5")
	var decimal = step.get("decimal", 245)
	
	# Двоичное число
	var bin_box = VBoxContainer.new()
	bin_box.add_theme_constant_override("separation", 5)
	container.add_child(bin_box)
	
	var bin_label = Label.new()
	bin_label.text = "Двоичное:"
	bin_box.add_child(bin_label)
	
	var bin_val = Label.new()
	bin_val.text = binary
	bin_val.add_theme_font_size_override("font_size", 20)
	bin_val.add_theme_color_override("font_color", Color.YELLOW)
	bin_box.add_child(bin_val)
	
	# Группы по 4
	var group_label = Label.new()
	group_label.text = "= " + binary.substr(0, 4) + " " + binary.substr(4, 4)
	group_label.add_theme_font_size_override("font_size", 16)
	group_label.add_theme_color_override("font_color", Color.CYAN)
	container.add_child(group_label)
	
	# HEX результат
	var hex_box = VBoxContainer.new()
	hex_box.add_theme_constant_override("separation", 5)
	container.add_child(hex_box)
	
	var hex_label = Label.new()
	hex_label.text = "HEX:"
	hex_box.add_child(hex_label)
	
	var hex_val = Label.new()
	hex_val.text = hex
	hex_val.add_theme_font_size_override("font_size", 24)
	hex_val.add_theme_color_override("font_color", Color.YELLOW)
	hex_box.add_child(hex_val)
	
	# Десятичное
	var dec_box = VBoxContainer.new()
	dec_box.add_theme_constant_override("separation", 5)
	container.add_child(dec_box)
	
	var dec_label = Label.new()
	dec_label.text = "Decimal:"
	dec_box.add_child(dec_label)
	
	var dec_val = Label.new()
	dec_val.text = str(decimal)
	dec_val.add_theme_font_size_override("font_size", 20)
	dec_val.add_theme_color_override("font_color", Color.CYAN)
	dec_box.add_child(dec_val)
