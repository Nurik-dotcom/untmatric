extends "res://scenes/Tutorial/TutorialBase.gd"
class_name TutorialComputerArch

func _initialize_tutorial() -> void:
	tutorial_id = "comp_arch"
	tutorial_title = "Архитектура компьютера"
	linked_quest_scene = "res://scenes/case_01/Case01Flow.tscn"

	tutorial_steps = [
		{
			"text": """
Компьютер состоит из четырех основных блоков:

1. ВВОД (Input) - устройства, через которые данные попадают в компьютер
2. ВЫВОД (Output) - устройства, через которые компьютер показывает результат
3. ПАМЯТЬ (Memory) - хранение данных и программ
4. ПРОЦЕССОР (CPU) - обработка и вычисления

Эту схему называют архитектурой фон Неймана.
""",
			"render_func": "render_arch_diagram",
		},
		{
			"text": """
УСТРОЙСТВА ВВОДА (Input):

- Клавиатура - ввод текста
- Мышь - ввод координат и кликов
- Микрофон - ввод звука
- Сканер - ввод изображений с бумаги
- Веб-камера - ввод видео
- Сенсорный экран - ввод касаний
- Джойстик - ввод для игр

Правило: если устройство ПЕРЕДАЕТ данные В компьютер - это ввод.
""",
			"render_func": "render_device_list",
			"category": "INPUT",
		},
		{
			"text": """
УСТРОЙСТВА ВЫВОДА (Output):

- Монитор - вывод изображения
- Принтер - вывод на бумагу
- Колонки/наушники - вывод звука
- Проектор - вывод на экран

Правило: если устройство ПОЛУЧАЕТ данные ОТ компьютера - это вывод.

Исключение: сенсорный экран - и ввод, и вывод одновременно.
""",
			"render_func": "render_device_list",
			"category": "OUTPUT",
		},
		{
			"text": """
ПАМЯТЬ (Memory):

ОЗУ (RAM) - оперативная, быстрая, стирается при выключении
ПЗУ (ROM) - постоянная, сохраняет данные без питания
HDD/SSD - жесткий диск, долговременное хранение
Флеш-накопитель - переносная память

Правило: если устройство ХРАНИТ данные - это память.

В ЕНТ часто спрашивают: "Какой тип памяти стирается при выключении?" -> ОЗУ
""",
			"render_func": "render_device_list",
			"category": "MEMORY",
		},
		{
			"text": """
Хитрые вопросы ЕНТ:

- Модем - ввод И вывод (принимает и отправляет данные)
- Сетевая карта - ввод И вывод
- Сенсорный экран - ввод И вывод
- Флешка - память (не ввод!)
- Процессор - НИ ОДНА из категорий I/O/Memory, это CPU

Если вопрос: "Что является ТОЛЬКО устройством ввода?"
-> клавиатура, мышь, сканер, микрофон.
""",
			"render_func": "render_tricky_quiz",
		},
		{
			"text": """
В квесте "Анализ подсказок" (Дело #1):

На месте взлома разбросаны устройства.
Ты нажимаешь на устройство -> выбираешь категорию:
INPUT / OUTPUT / MEMORY

Используй правила из этого урока:
- Передает данные В компьютер -> INPUT
- Получает данные ОТ компьютера -> OUTPUT
- Хранит данные -> MEMORY
""",
			"render_func": "",
		},
	]


func render_arch_diagram(area: Control, _step: Dictionary) -> void:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	area.add_child(root)

	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override("separation", 16)
	root.add_child(top)

	top.add_child(_make_info_panel("ВВОД\nInput", Color(0.08, 0.22, 0.14, 1.0), Color(0.18, 0.70, 0.42, 1.0)))
	var arrow_1 := Label.new()
	arrow_1.text = "->"
	arrow_1.add_theme_font_size_override("font_size", 22)
	top.add_child(arrow_1)
	top.add_child(_make_info_panel("CPU\nПроцессор", Color(0.24, 0.12, 0.10, 1.0), Color(0.80, 0.35, 0.28, 1.0)))
	var arrow_2 := Label.new()
	arrow_2.text = "->"
	arrow_2.add_theme_font_size_override("font_size", 22)
	top.add_child(arrow_2)
	top.add_child(_make_info_panel("ВЫВОД\nOutput", Color(0.10, 0.17, 0.28, 1.0), Color(0.35, 0.55, 0.88, 1.0)))

	var down := Label.new()
	down.text = "|"
	down.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	down.add_theme_font_size_override("font_size", 22)
	root.add_child(down)

	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(bottom)
	bottom.add_child(_make_info_panel("ПАМЯТЬ\nMemory", Color(0.24, 0.22, 0.10, 1.0), Color(0.90, 0.82, 0.25, 1.0)))


func render_device_list(area: Control, step: Dictionary) -> void:
	var category: String = str(step.get("category", ""))
	var items: Array[String] = []
	var bg := Color(0.08, 0.08, 0.10, 1.0)
	var border := Color(0.35, 0.35, 0.45, 1.0)

	match category:
		"INPUT":
			items = ["Клавиатура", "Мышь", "Микрофон", "Сканер", "Веб-камера", "Сенсорный экран", "Джойстик"]
			bg = Color(0.08, 0.22, 0.14, 1.0)
			border = Color(0.18, 0.70, 0.42, 1.0)
		"OUTPUT":
			items = ["Монитор", "Принтер", "Колонки", "Наушники", "Проектор"]
			bg = Color(0.10, 0.17, 0.28, 1.0)
			border = Color(0.35, 0.55, 0.88, 1.0)
		"MEMORY":
			items = ["RAM", "ROM", "HDD", "SSD", "Флеш-накопитель"]
			bg = Color(0.24, 0.22, 0.10, 1.0)
			border = Color(0.90, 0.82, 0.25, 1.0)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	area.add_child(grid)

	for item in items:
		grid.add_child(_make_info_panel(item, bg, border))


func render_tricky_quiz(area: Control, _step: Dictionary) -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	area.add_child(vbox)

	vbox.add_child(_make_info_panel("Модем -> INPUT + OUTPUT", Color(0.20, 0.12, 0.30, 1.0), Color(0.62, 0.35, 0.84, 1.0)))
	vbox.add_child(_make_info_panel("Сетевая карта -> INPUT + OUTPUT", Color(0.20, 0.12, 0.30, 1.0), Color(0.62, 0.35, 0.84, 1.0)))
	vbox.add_child(_make_info_panel("Флешка -> MEMORY", Color(0.24, 0.22, 0.10, 1.0), Color(0.90, 0.82, 0.25, 1.0)))
	vbox.add_child(_make_info_panel("Процессор -> CPU (не I/O/Memory)", Color(0.24, 0.12, 0.10, 1.0), Color(0.80, 0.35, 0.28, 1.0)))


func _make_info_panel(text: String, bg: Color, border: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.98, 1.0))
	panel.add_child(label)
	return panel
