extends "res://scenes/Tutorial/TutorialBase.gd"
# TutorialMatrix.gd - Обучение матричным головоломкам

class_name TutorialMatrix

func _initialize_tutorial() -> void:
	tutorial_id = "tutorial_matrix"
	tutorial_title = "Обучение: Матричные головоломки"
	
	tutorial_steps = [
		# Шаг 1: Введение
		{
			"text": "🧩 МАТРИЧНЫЕ ГОЛОВОЛОМКИ - сложная логическая задача\n\nЗабыл: Матрица - это таблица чисел в строках и столбцах\n\n🎯 Задача: Найти СКРЫТЫЕ числа, зная СУММУ каждой строки и столбца\n\n✓ Это был одна из самых сложных категорий квестов!"
		},
		
		# Шаг 2: Структура матрицы
		{
			"text": "📐 СТРУКТУРА МАТРИЦЫ 3×3:\n\n[a] [b] [c]   → Сумма строки 1 = a + b + c\n[d] [e] [f]   → Сумма строки 2 = d + e + f\n[g] [h] [i]   → Сумма строки 3 = g + h + i\n↓   ↓   ↓\nC1  C2  C3 (суммы столбцов)\n\n✓ Каждое число влияет на строку И столбец",
			"render_func": "render_matrix_structure"
		},
		
		# Шаг 3: Простой пример 2×2
		{
			"text": "📊 ПРОСТОЙ ПРИМЕР: Матрица 2×2\n\n[1] [2]  → Сумма = 3\n[3] [4]  → Сумма = 7\n↓   ↓\n4   6 (суммы столбцов)\n\n🎯 Убеди: 1+2=3 ✓ | 3+4=7 ✓ | 1+3=4 ✓ | 2+4=6 ✓",
			"render_func": "render_matrix_example",
			"matrix_data": {
				"rows": 2,
				"cols": 2,
				"values": [1, 2, 3, 4],
				"row_sums": [3, 7],
				"col_sums": [4, 6]
			}
		},
		
		# Шаг 4: Алгоритм решения
		{
			"text": "🔍 АЛГОРИТМ РЕШЕНИЯ:\n\n1️⃣ Найди строку/столбец с ОДНИМ неизвестным (?)\n2️⃣ Вычисли это число через сумму\n3️⃣ Заполни число и обнови суммы\n4️⃣ Повтори шаги 1-3 до разгадки\n5️⃣ ПРОВЕРЬ: все суммы должны совпадать!\n\n✓ Это как логическая головоломка Судоку!",
			"render_func": ""
		},
		
		# Шаг 5: Матрица 3×3 - Практика 1
		{
			"text": "🎮 ПРАКТИКА 1: Матрица 3×3 - Найти ОДНО число\n\nДана полная матрица, кроме ОДНОГО неизвестного (?)\n\nСуммы строк и столбцов даны\n\n🎯 Найди скрытое число используя логику!",
			"render_func": "render_matrix_puzzle",
			"matrix_data": {
				"rows": 3,
				"cols": 3,
				"values": [1, 2, 3, 4, 5, 6, 7, 8, -1],
				"row_sums": [6, 15, -1],
				"col_sums": [12, 15, 9],
				"unknown_index": 8,
				"solution": 24
			}
		},
		
		# Шаг 6: Матрица с несколькими неизвестными
		{
			"text": "🎮 ПРАКТИКА 2: ТРУДНАЯ - Матрица с 3 НЕИЗВЕСТНЫМИ\n\nТеперь нужно найти ТРИ скрытых числа\n\nЭта матрица НАМНОГО сложнее:\n- Нужно логически вывести всё\n- Порядок решения важен!\n- Это как настоящий квест!\n\n🎯 Способ: Начни с простейшей строки/столбца",
			"render_func": "render_matrix_puzzle",
			"matrix_data": {
				"rows": 3,
				"cols": 3,
				"values": [-1, 2, 3, 4, -1, 6, 7, 8, -1],
				"row_sums": [6, 15, -1],
				"col_sums": [12, 15, 9],
				"unknown_indices": [0, 4, 8],
				"solution": [1, 5, 12]
			}
		},
		
		# Шаг 7: Constraints - Ограничения
		{
			"text": "⚠️ ВАЖНЫЕ ОГРАНИЧЕНИЯ (Constraints):\n\n1️⃣ Все числа ЦЕЛЫЕ от 0 до 255\n2️⃣ Суммы строк ДОЛЖНЫ совпадать\n3️⃣ Суммы столбцов ДОЛЖНЫ совпадать\n4️⃣ Может быть несколько корректных решений!\n5️⃣ Нужно найти ВСЕ возможные варианты\n\n✓ Если находишь одно решение - выпей праздничный чай!",
			"render_func": ""
		},
		
		# Шаг 8: Стратегия решения
		{
			"text": "💡 ЛУЧШАЯ СТРАТЕГИЯ РЕШЕНИЯ:\n\n1️⃣ Ищи строки/столбцы с одним (?)\n2️⃣ Вычисли: СУММА - (известные числа)\n3️⃣ Заполни число\n4️⃣ Пересчитай суммы\n5️⃣ Повтори 1-4\n\n⚡ Почти как Судоку, но с суммами!\n\n🎓 Практика: Решение становится ОЧЕНЬ быстрым с опытом",
			"render_func": "render_solving_strategy"
		},
		
		# Шаг 9: Заключение
		{
			"text": "✓ УСПЕХ! ОВЛАДЕЛ МАТРИЧНЫМИ ГОЛОВОЛОМКАМИ!\n\n🏆 Теперь вы готовы:\n• Решать матрицы ЛЮБОГО размера\n• Применять логику на высочайшем уровне\n• Справляться с СЛОЖНЕЙШИМ уровнем C\n• Проходить последние квесты!\n\n🎊 ВЫПЕЙ ЧАЙ - ЗАСЛУЖИЛ!",
			"render_func": ""
		}
	]

func render_matrix_structure(area: Control, step: Dictionary) -> void:
	"""Рендер структуры матрицы"""
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 20)
	area.add_child(container)
	
	# Матрица
	var matrix_box = VBoxContainer.new()
	matrix_box.add_theme_constant_override("separation", 5)
	container.add_child(matrix_box)
	
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	matrix_box.add_child(grid)
	
	for i in range(9):
		var cell = Label.new()
		cell.text = ["[a]", "[b]", "[c]", "[d]", "[e]", "[f]", "[g]", "[h]", "[i]"][i]
		cell.custom_minimum_size = Vector2(50, 40)
		cell.add_theme_font_size_override("font_size", 14)
		cell.add_theme_color_override("font_color", Color.YELLOW)
		cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grid.add_child(cell)
	
	# Ограничения
	var constraints = Label.new()
	constraints.text = "Суммы: Каждой строки и столбца должны совпадать"
	constraints.add_theme_font_size_override("font_size", 12)
	constraints.add_theme_color_override("font_color", Color.CYAN)
	constraints.autowrap_mode = TextServer.AUTOWRAP_WORD
	container.add_child(constraints)

func render_matrix_example(area: Control, step: Dictionary) -> void:
	"""Рендер простого примера матрицы"""
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 15)
	area.add_child(container)
	
	var data = step.get("matrix_data", {})
	var rows = data.get("rows", 2)
	var cols = data.get("cols", 2)
	var values = data.get("values", [])
	var row_sums = data.get("row_sums", [])
	var col_sums = data.get("col_sums", [])
	
	# Заголовок
	var title = Label.new()
	title.text = "Матрица " + str(rows) + "×" + str(cols) + " (простой пример)"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color.WHITE)
	container.add_child(title)
	
	# Матрица с суммами
	var main_box = HBoxContainer.new()
	main_box.add_theme_constant_override("separation", 20)
	container.add_child(main_box)
	
	# Сама матрица
	var matrix_box = VBoxContainer.new()
	matrix_box.add_theme_constant_override("separation", 5)
	main_box.add_child(matrix_box)
	
	for r in range(rows):
		var row_box = HBoxContainer.new()
		row_box.add_theme_constant_override("separation", 5)
		matrix_box.add_child(row_box)
		
		for c in range(cols):
			var idx = r * cols + c
			var cell = Label.new()
			cell.text = str(values[idx])
			cell.custom_minimum_size = Vector2(50, 40)
			cell.add_theme_font_size_override("font_size", 16)
			cell.add_theme_color_override("font_color", Color.YELLOW)
			cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			row_box.add_child(cell)
		
		# Сумма строки
		if r < row_sums.size():
			var sum_label = Label.new()
			sum_label.text = "= " + str(row_sums[r])
			sum_label.custom_minimum_size = Vector2(60, 40)
			sum_label.add_theme_font_size_override("font_size", 14)
			sum_label.add_theme_color_override("font_color", Color.CYAN)
			row_box.add_child(sum_label)
	
	# Суммы столбцов
	var col_sums_box = HBoxContainer.new()
	col_sums_box.add_theme_constant_override("separation", 5)
	matrix_box.add_child(col_sums_box)
	
	for c in range(cols):
		var sum_label = Label.new()
		sum_label.text = str(col_sums[c])
		sum_label.custom_minimum_size = Vector2(50, 40)
		sum_label.add_theme_font_size_override("font_size", 14)
		sum_label.add_theme_color_override("font_color", Color.CYAN)
		sum_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col_sums_box.add_child(sum_label)

func render_matrix_puzzle(area: Control, step: Dictionary) -> void:
	"""Рендер матричной головоломки для практики"""
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 15)
	area.add_child(container)
	
	var data = step.get("matrix_data", {})
	var rows = data.get("rows", 3)
	var cols = data.get("cols", 3)
	var values = data.get("values", [])
	var row_sums = data.get("row_sums", [])
	var col_sums = data.get("col_sums", [])
	
	# Заголовок
	var title = Label.new()
	title.text = "Найти неизвестные значения (?)"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color.WHITE)
	container.add_child(title)
	
	# Матрица
	var main_box = HBoxContainer.new()
	main_box.add_theme_constant_override("separation", 20)
	container.add_child(main_box)
	
	var matrix_box = VBoxContainer.new()
	matrix_box.add_theme_constant_override("separation", 5)
	main_box.add_child(matrix_box)
	
	for r in range(rows):
		var row_box = HBoxContainer.new()
		row_box.add_theme_constant_override("separation", 5)
		matrix_box.add_child(row_box)
		
		for c in range(cols):
			var idx = r * cols + c
			var cell = Label.new()
			
			if values[idx] == -1:
				cell.text = "?"
				cell.add_theme_color_override("font_color", Color.RED)
			else:
				cell.text = str(values[idx])
				cell.add_theme_color_override("font_color", Color.YELLOW)
			
			cell.custom_minimum_size = Vector2(50, 40)
			cell.add_theme_font_size_override("font_size", 16)
			cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			row_box.add_child(cell)
		
		# Сумма строки
		if r < row_sums.size():
			var sum_label = Label.new()
			if row_sums[r] == -1:
				sum_label.text = "= ?"
				sum_label.add_theme_color_override("font_color", Color.RED)
			else:
				sum_label.text = "= " + str(row_sums[r])
				sum_label.add_theme_color_override("font_color", Color.CYAN)
			sum_label.custom_minimum_size = Vector2(60, 40)
			sum_label.add_theme_font_size_override("font_size", 14)
			row_box.add_child(sum_label)
	
	# Суммы столбцов
	var col_sums_box = HBoxContainer.new()
	col_sums_box.add_theme_constant_override("separation", 5)
	matrix_box.add_child(col_sums_box)
	
	for c in range(cols):
		var sum_label = Label.new()
		if col_sums[c] == -1:
			sum_label.text = "?"
			sum_label.add_theme_color_override("font_color", Color.RED)
		else:
			sum_label.text = str(col_sums[c])
			sum_label.add_theme_color_override("font_color", Color.CYAN)
		sum_label.custom_minimum_size = Vector2(50, 40)
		sum_label.add_theme_font_size_override("font_size", 14)
		sum_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col_sums_box.add_child(sum_label)
	
	# Подсказка
	var hint = Label.new()
	hint.text = "Совет: Используйте логику! Если в строке только одно неизвестное, вы можете его вычислить."
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color.GRAY)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	container.add_child(hint)

func render_solving_strategy(area: Control, step: Dictionary) -> void:
	"""Рендер стратегии решения"""
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 15)
	area.add_child(container)
	
	var strategies = [
		"1. ПОИСК: Найти строку/столбец с одним неизвестным",
		"2. ВЫЧИСЛЕНИЕ: Решить это неизвестное",
		"3. ОБНОВЛЕНИЕ: Обновить оставшиеся суммы",
		"4. ПОВТОРЕНИЕ: Вернуться к шагу 1",
		"5. ПРОВЕРКА: Все ли ограничения выполнены?"
	]
	
	for strategy in strategies:
		var label = Label.new()
		label.text = strategy
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", Color.CYAN)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		container.add_child(label)
	
	# Пример
	var example_title = Label.new()
	example_title.text = "\nПример:"
	example_title.add_theme_font_size_override("font_size", 12)
	example_title.add_theme_color_override("font_color", Color.WHITE)
	container.add_child(example_title)
	
	var example = Label.new()
	example.text = "Если первая строка: [5] [?] [?] = 12\nВторая: [3] [4] [5] = 12\nТретья: [4] [?] [3] = ?\n\nВторая строка уже полная. Используйте её сумму 12 для проверки!"
	example.add_theme_font_size_override("font_size", 12)
	example.add_theme_color_override("font_color", Color.GRAY)
	example.autowrap_mode = TextServer.AUTOWRAP_WORD
	container.add_child(example)
