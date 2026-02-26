extends "res://scenes/Tutorial/TutorialBase.gd"
# TutorialLogicGates.gd - Обучение логическим воротам

class_name TutorialLogicGates

func _initialize_tutorial() -> void:
	tutorial_id = "tutorial_logic_gates"
	tutorial_title = "Обучение: Логические ворота"
	
	tutorial_steps = [
		# Шаг 1: Введение
		{
			"text": "🎯 ЛОГИЧЕСКИЕ ВОРОТА\n\nЭто основа криптографии и детективной работы!\n\nОни принимают 2 входа (0 или 1) и выдают 1 результат",
			"render_func": ""
		},
		
		# Шаг 2: AND ворота - реальный пример
		{
			"text": "🔓 AND (И) - ОБА УСЛОВИЯ\n\n✓ Вывод = 1 ТОЛЬКО когда ОБА входа = 1\n✗ В остальных случаях вывод = 0\n\n📋 Пример из дела:\n'Машина заведется если есть КЛЮЧ И нажата СТАРТ'",
			"render_func": "render_gate_with_example",
			"gate": "AND",
			"example_a": "КЛЮЧ",
			"example_b": "СТАРТ",
			"truth_table": [
				{"a": 0, "b": 0, "result": 0, "desc": "Нет ключа, нет старта"},
				{"a": 0, "b": 1, "result": 0, "desc": "Есть старт, но нет ключа"},
				{"a": 1, "b": 0, "result": 0, "desc": "Есть ключ, но нет старта"},
				{"a": 1, "b": 1, "result": 1, "desc": "✓ Оба условия!"}
			]
		},
		
		# Шаг 3: OR ворота - реальный пример
		{
			"text": "🌧️ OR (ИЛИ) - ОДНО ИЗ УСЛОВИЙ\n\n✓ Вывод = 1 если ЛЮБОЙ вход = 1\n✗ Вывод = 0 только если оба входа = 0\n\n📋 Пример из дела:\n'Вы промокнете если идет ДОЖДЬ или СНЕГ'",
			"render_func": "render_gate_with_example",
			"gate": "OR",
			"example_a": "ДОЖДЬ",
			"example_b": "СНЕГ",
			"truth_table": [
				{"a": 0, "b": 0, "result": 0, "desc": "Сухо, ясно"},
				{"a": 0, "b": 1, "result": 1, "desc": "✓ Идет снег"},
				{"a": 1, "b": 0, "result": 1, "desc": "✓ Идет дождь"},
				{"a": 1, "b": 1, "result": 1, "desc": "✓ Обе напасти!"}
			]
		},
		
		# Шаг 4: NOT ворота - реальный пример
		{
			"text": "🔄 NOT (НЕ) - ИНВЕРСИЯ\n\n✓ Вывод = ПРОТИВОПОЛОЖНОСТЬ входа\n  1 → 0\n  0 → 1\n\n📋 Пример из дела:\n'Детектор лжи инвертирует сигнал'",
			"render_func": "render_gate_with_example",
			"gate": "NOT",
			"example_a": "СИГНАЛ",
			"example_b": "",
			"truth_table": [
				{"a": 0, "result": 1, "desc": "На входе 0 → На выходе 1"},
				{"a": 1, "result": 0, "desc": "На входе 1 → На выходе 0"}
			]
		},
		
		# Шаг 5: XOR ворота - реальный пример
		{
			"text": "⚡ XOR (Исключающее ИЛИ)\n\n✓ Вывод = 1 если входы РАЗНЫЕ\n✗ Вывод = 0 если входы ОДИНАКОВЫЕ\n\n📋 Пример из дела:\n'Сигнализация молчит если датчики совпадают'",
			"render_func": "render_gate_with_example",
			"gate": "XOR",
			"example_a": "ДАТЧИК_1",
			"example_b": "ДАТЧИК_2",
			"truth_table": [
				{"a": 0, "b": 0, "result": 0, "desc": "Оба 0 - молчит"},
				{"a": 0, "b": 1, "result": 1, "desc": "✓ Разные - сигнал!"},
				{"a": 1, "b": 0, "result": 1, "desc": "✓ Разные - сигнал!"},
				{"a": 1, "b": 1, "result": 0, "desc": "Оба 1 - молчит"}
			]
		},
		
		# Шаг 6: NAND ворота
		{
			"text": "🔐 NAND (И-НЕ) - Противоположность AND\n\n✓ Вывод = 0 ТОЛЬКО если оба входа = 1\n✗ В остальных случаях вывод = 1",
			"render_func": "render_gate_truth_table",
			"gate": "NAND",
			"truth_table": [
				{"a": 0, "b": 0, "result": 1},
				{"a": 0, "b": 1, "result": 1},
				{"a": 1, "b": 0, "result": 1},
				{"a": 1, "b": 1, "result": 0}
			]
		},
		
		# Шаг 7: NOR ворота
		{
			"text": "🚫 NOR (ИЛИ-НЕ) - Противоположность OR\n\n✓ Вывод = 1 ТОЛЬКО если оба входа = 0\n✗ В остальных случаях вывод = 0\n\n📋 Пример из дела:\n'Замок заклинит если нажать хотя бы 1 рычаг'",
			"render_func": "render_gate_truth_table",
			"gate": "NOR",
			"truth_table": [
				{"a": 0, "b": 0, "result": 1},
				{"a": 0, "b": 1, "result": 0},
				{"a": 1, "b": 0, "result": 0},
				{"a": 1, "b": 1, "result": 0}
			]
		},
		
		# Шаг 8: Практика - AND
		{
			"text": "🎮 ПРАКТИКА: AND ворота\n\nВы анализируете дело:\n'Машина может завестись?'\n\nУсловия:\n• КЛЮЧ вставлен? → 1 (ДА)\n• СТАРТ нажат? → 0 (НЕТ)\n\nЧему равен результат?",
			"render_func": "render_gate_quiz",
			"gate": "AND",
			"a": 1,
			"b": 0,
			"correct_answer": 0,
			"explanation": "Нужны ОБА условия. Ключ есть, но старт не нажат → результат 0"
		},
		
		# Шаг 9: Практика - OR
		{
			"text": "🎮 ПРАКТИКА: OR ворота\n\n'Будет ли ущерб?'\n\nУсловия:\n• Идет ДОЖДЬ? → 0 (НЕТ)\n• Идет СНЕГ? → 1 (ДА)\n\nЧему равен результат?",
			"render_func": "render_gate_quiz",
			"gate": "OR",
			"a": 0,
			"b": 1,
			"correct_answer": 1,
			"explanation": "Достаточно ОДНОГО условия. Снег идет → результат 1"
		},
		
		# Шаг 10: Практика - XOR
		{
			"text": "🎮 ПРАКТИКА: XOR ворота\n\n'Сигнализация сработает?'\n\nУсловия:\n• ДАТЧИК_1 = 1 (АКТИВЕН)\n• ДАТЧИК_2 = 1 (АКТИВЕН)\n\nЧему равен результат?",
			"render_func": "render_gate_quiz",
			"gate": "XOR",
			"a": 1,
			"b": 1,
			"correct_answer": 0,
			"explanation": "XOR требует РАЗНЫЕ входы. Оба датчика активны → результат 0"
		},
		
		# Шаг 11: Заключение
		{
			"text": "🎓 ОТЛИЧНО!\n\nВы освоили все логические ворота!\n\n✓ AND, OR, NOT, XOR\n✓ NAND, NOR\n\nТеперь вы готовы к квесту 'Детектор лжи'!\n\nНажимайте 'Далее →' для перехода к заданиям.",
			"render_func": ""
		}
	]

func render_gate_with_example(area: Control, step: Dictionary) -> void:
	"""Рендер таблицы с примерами из реальных дел"""
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 15)
	area.add_child(container)
	
	# Примеры
	var gate = step.get("gate", "AND")
	var example_a = step.get("example_a", "A")
	var example_b = step.get("example_b", "B")
	
	# Панель примера
	var example_panel = PanelContainer.new()
	var example_style = StyleBox.new()
	example_panel.add_theme_stylebox_override("panel", example_style)
	container.add_child(example_panel)
	
	var example_box = VBoxContainer.new()
	example_box.add_theme_constant_override("separation", 8)
	example_panel.add_child(example_box)
	
	var ex_title = Label.new()
	ex_title.text = "📋 Пример из дела:"
	ex_title.add_theme_font_size_override("font_size", 16)
	ex_title.add_theme_color_override("font_color", Color.YELLOW)
	example_box.add_child(ex_title)
	
	var ex_a = Label.new()
	ex_a.text = "• " + example_a + " = [0 или 1]"
	ex_a.add_theme_font_size_override("font_size", 14)
	example_box.add_child(ex_a)
	
	if example_b != "":
		var ex_b = Label.new()
		ex_b.text = "• " + example_b + " = [0 или 1]"
		ex_b.add_theme_font_size_override("font_size", 14)
		example_box.add_child(ex_b)
	
	# Таблица истинности
	var table_title = Label.new()
	table_title.text = "📊 Таблица истинности:"
	table_title.add_theme_font_size_override("font_size", 16)
	table_title.add_theme_color_override("font_color", Color.CYAN)
	container.add_child(table_title)
	
	var table = VBoxContainer.new()
	table.add_theme_constant_override("separation", 2)
	container.add_child(table)
	
	var truth_table = step.get("truth_table", [])
	
	# Заголовок
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 15)
	table.add_child(header)
	
	if truth_table.size() > 0 and not truth_table[0].has("b"):
		var a_h = Label.new()
		a_h.text = example_a
		a_h.custom_minimum_size = Vector2(80, 30)
		a_h.add_theme_font_size_override("font_size", 13)
		a_h.add_theme_color_override("font_color", Color.CYAN)
		a_h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		header.add_child(a_h)
	else:
		for col in [example_a, example_b, "РЕЗУЛЬТАТ"]:
			var col_h = Label.new()
			col_h.text = col
			col_h.custom_minimum_size = Vector2(80, 30)
			col_h.add_theme_font_size_override("font_size", 13)
			col_h.add_theme_color_override("font_color", Color.CYAN)
			col_h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			header.add_child(col_h)
	
	# Строки
	for row in truth_table:
		var row_container = HBoxContainer.new()
		row_container.add_theme_constant_override("separation", 15)
		table.add_child(row_container)
		
		if not row.has("b"):
			# Унарная операция (NOT)
			var a_cell = Label.new()
			a_cell.text = str(row.get("a", "?"))
			a_cell.custom_minimum_size = Vector2(80, 30)
			a_cell.add_theme_font_size_override("font_size", 14)
			a_cell.add_theme_color_override("font_color", Color.YELLOW)
			a_cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			row_container.add_child(a_cell)
			
			var res_cell = Label.new()
			res_cell.text = str(row.get("result", "?"))
			res_cell.custom_minimum_size = Vector2(80, 30)
			res_cell.add_theme_font_size_override("font_size", 14)
			res_cell.add_theme_color_override("font_color", Color.CYAN)
			res_cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			row_container.add_child(res_cell)
		else:
			# Бинарная операция
			var a_cell = Label.new()
			a_cell.text = str(row.get("a", "?"))
			a_cell.custom_minimum_size = Vector2(80, 30)
			a_cell.add_theme_font_size_override("font_size", 14)
			a_cell.add_theme_color_override("font_color", Color.YELLOW)
			a_cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			row_container.add_child(a_cell)
			
			var b_cell = Label.new()
			b_cell.text = str(row.get("b", "?"))
			b_cell.custom_minimum_size = Vector2(80, 30)
			b_cell.add_theme_font_size_override("font_size", 14)
			b_cell.add_theme_color_override("font_color", Color.YELLOW)
			b_cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			row_container.add_child(b_cell)
			
			var res_cell = Label.new()
			res_cell.text = str(row.get("result", "?"))
			res_cell.custom_minimum_size = Vector2(80, 30)
			res_cell.add_theme_font_size_override("font_size", 14)
			res_cell.add_theme_color_override("font_color", Color.CYAN)
			res_cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			row_container.add_child(res_cell)
		
		# Описание
		if row.has("desc"):
			var desc_label = Label.new()
			desc_label.text = row.get("desc", "")
			desc_label.add_theme_font_size_override("font_size", 12)
			desc_label.add_theme_color_override("font_color", Color.GRAY)
			desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
			table.add_child(desc_label)

func render_gate_truth_table(area: Control, step: Dictionary) -> void:
	"""Рендер таблицы истинности"""
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 15)
	area.add_child(container)
	
	var gate_name = step.get("gate", "AND")
	var title = Label.new()
	title.text = gate_name + " - Таблица истинности"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color.WHITE)
	container.add_child(title)
	
	var table = VBoxContainer.new()
	table.add_theme_constant_override("separation", 2)
	container.add_child(table)
	
	var truth_table = step.get("truth_table", [])
	
	# Определить если это унарная операция (NOT)
	var is_unary = truth_table.size() > 0 and not truth_table[0].has("b")
	
	# Заголовок
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	table.add_child(header)
	
	if is_unary:
		var a_header = Label.new()
		a_header.text = "Input (A)"
		a_header.custom_minimum_size = Vector2(100, 30)
		a_header.add_theme_font_size_override("font_size", 14)
		a_header.add_theme_color_override("font_color", Color.CYAN)
		a_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		header.add_child(a_header)
		
		var result_header = Label.new()
		result_header.text = "Output"
		result_header.custom_minimum_size = Vector2(100, 30)
		result_header.add_theme_font_size_override("font_size", 14)
		result_header.add_theme_color_override("font_color", Color.CYAN)
		result_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		header.add_child(result_header)
	else:
		for col_name in ["A", "B", "Output"]:
			var col_header = Label.new()
			col_header.text = col_name
			col_header.custom_minimum_size = Vector2(100, 30)
			col_header.add_theme_font_size_override("font_size", 14)
			col_header.add_theme_color_override("font_color", Color.CYAN)
			col_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			header.add_child(col_header)
	
	# Строки таблицы
	for row in truth_table:
		var row_container = HBoxContainer.new()
		row_container.add_theme_constant_override("separation", 20)
		table.add_child(row_container)
		
		if is_unary:
			# A
			var a_cell = Label.new()
			a_cell.text = str(row.get("a", "?"))
			a_cell.custom_minimum_size = Vector2(100, 30)
			a_cell.add_theme_font_size_override("font_size", 16)
			a_cell.add_theme_color_override("font_color", Color.YELLOW)
			a_cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			row_container.add_child(a_cell)
			
			# Result
			var result_cell = Label.new()
			result_cell.text = str(row.get("result", "?"))
			result_cell.custom_minimum_size = Vector2(100, 30)
			result_cell.add_theme_font_size_override("font_size", 16)
			result_cell.add_theme_color_override("font_color", Color.YELLOW)
			result_cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			row_container.add_child(result_cell)
		else:
			# A
			var a_cell = Label.new()
			a_cell.text = str(row.get("a", "?"))
			a_cell.custom_minimum_size = Vector2(100, 30)
			a_cell.add_theme_font_size_override("font_size", 16)
			a_cell.add_theme_color_override("font_color", Color.YELLOW)
			a_cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			row_container.add_child(a_cell)
			
			# B
			var b_cell = Label.new()
			b_cell.text = str(row.get("b", "?"))
			b_cell.custom_minimum_size = Vector2(100, 30)
			b_cell.add_theme_font_size_override("font_size", 16)
			b_cell.add_theme_color_override("font_color", Color.YELLOW)
			b_cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			row_container.add_child(b_cell)
			
			# Result
			var result_cell = Label.new()
			result_cell.text = str(row.get("result", "?"))
			result_cell.custom_minimum_size = Vector2(100, 30)
			result_cell.add_theme_font_size_override("font_size", 16)
			result_cell.add_theme_color_override("font_color", Color.CYAN)
			result_cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			row_container.add_child(result_cell)

func render_gate_quiz(area: Control, step: Dictionary) -> void:
	"""Рендер для практики с воротами"""
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 20)
	area.add_child(container)
	
	var gate = step.get("gate", "AND")
	var a = step.get("a", 0)
	var b = step.get("b", 0)
	
	# Вопрос
	var question = Label.new()
	question.text = gate + " вход:"
	question.add_theme_font_size_override("font_size", 18)
	question.add_theme_color_override("font_color", Color.WHITE)
	container.add_child(question)
	
	# Входы
	var inputs = VBoxContainer.new()
	inputs.add_theme_constant_override("separation", 10)
	container.add_child(inputs)
	
	var a_box = HBoxContainer.new()
	a_box.add_theme_constant_override("separation", 10)
	inputs.add_child(a_box)
	
	var a_label = Label.new()
	a_label.text = "A ="
	a_label.custom_minimum_size = Vector2(50, 0)
	a_box.add_child(a_label)
	
	var a_val = Label.new()
	a_val.text = str(a)
	a_val.add_theme_font_size_override("font_size", 20)
	a_val.add_theme_color_override("font_color", Color.YELLOW)
	a_box.add_child(a_val)
	
	var b_box = HBoxContainer.new()
	b_box.add_theme_constant_override("separation", 10)
	inputs.add_child(b_box)
	
	var b_label = Label.new()
	b_label.text = "B ="
	b_label.custom_minimum_size = Vector2(50, 0)
	b_box.add_child(b_label)
	
	var b_val = Label.new()
	b_val.text = str(b)
	b_val.add_theme_font_size_override("font_size", 20)
	b_val.add_theme_color_override("font_color", Color.YELLOW)
	b_box.add_child(b_val)
	
	# Подсказка
	var hint = Label.new()
	hint.text = "Вспомните таблицу истинности для " + gate
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color.GRAY)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	container.add_child(hint)
