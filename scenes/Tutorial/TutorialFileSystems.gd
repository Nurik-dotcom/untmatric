extends "res://scenes/Tutorial/TutorialBase.gd"
# Файловые системы — FAT, NTFS, дерево каталогов
# Готовит к: DataArchive A

class_name TutorialFileSystems

func _initialize_tutorial() -> void:
	tutorial_id = "file_systems"
	tutorial_title = "Файловые системы"
	linked_quest_scene = "res://scenes/case_07/da7_data_archive_a.tscn"

	tutorial_steps = [
		{
			"text": "Файловая система (ФС) — способ организации и хранения файлов на носителе.\n\nБез ФС диск — просто набор байтов. ФС даёт:\n• Имена файлов и папок\n• Иерархию (дерево каталогов)\n• Метаданные (дата, размер, права)\n• Защиту от частичной потери данных\n\nПопулярные ФС:\nFAT32 — флешки, старые системы\nNTFS — Windows\nextFS — Linux\nAPFS — macOS",
			"render_func": "render_fs_overview",
		},
		{
			"text": "FAT (File Allocation Table):\n\nФС делит диск на кластеры — минимальные единицы хранения.\nFAT — таблица которая показывает, какой кластер следует за каким.\n\nФайл из 3 кластеров:\nКластер 5 → кластер 12 → кластер 8 → END\n\nПлюсы FAT32: простота, поддержка везде\nМинусы FAT32:\n• Макс. размер файла: 4 ГБ\n• Макс. размер тома: 2 ТБ\n• Нет журналирования (потери при сбое)",
			"render_func": "render_fat_concept",
		},
		{
			"text": "NTFS (New Technology File System):\n\nИспользует MFT (Master File Table) — таблицу всех файлов.\nКаждый файл → запись в MFT с атрибутами.\n\nПреимущества NTFS:\n• Файлы > 4 ГБ (до 16 ЭБ теоретически)\n• Журналирование — восстановление после сбоя\n• Шифрование EFS\n• Разрешения (ACL) для файлов\n• Сжатие файлов\n\nMinимальная ед.: кластер (обычно 4 КБ)",
			"render_func": "render_ntfs_concept",
		},
		{
			"text": "Дерево каталогов:\n\nФайловая система организована иерархически.\n\nWindows:\nC:\\Users\\Alex\\Documents\\report.docx\n\nLinux/macOS:\n/home/alex/documents/report.pdf\n\nКорневой каталог:\n• Windows: C:\\ D:\\\n• Linux/macOS: /\n\nПуть — строка из разделителей и имён каталогов от корня до файла.",
			"render_func": "render_dir_tree",
		},
		{
			"text": "Абсолютный и относительный пути:\n\nАбсолютный — от корня:\n/home/alex/docs/file.txt\nC:\\Users\\Alex\\docs\\file.txt\n\nОтносительный — от текущей папки:\n./docs/file.txt (текущая папка/docs/)\n../other/file.txt (на уровень выше, затем other/)\n\nСпециальные символы:\n.  = текущая директория\n.. = родительская директория\n~ (Linux) = домашняя директория пользователя",
			"render_func": "render_paths_demo",
		},
		{
			"text": "Метаданные файла:\n\nКаждый файл имеет атрибуты:\n• Имя и расширение\n• Размер (байты)\n• Дата создания / изменения / доступа\n• Права доступа (чтение, запись, выполнение)\n• Владелец\n• Тип (файл / директория / символическая ссылка)\n\nВ ЕНТ: задачи на вычисление размера файла, пути, количества файлов в дереве.",
			"render_func": "render_metadata_table",
		},
		{
			"text": "Задача ЕНТ — расчёт размера:\n\n«Папка содержит 5 файлов по 100 КБ и 3 подпапки по 2 файла по 50 КБ. Итоговый размер?»\n\n5 файлов × 100 КБ = 500 КБ\n3 подпапки × 2 файла × 50 КБ = 300 КБ\nИтого: 500 + 300 = 800 КБ\n\nПомни: 1 КБ = 1024 байта, 1 МБ = 1024 КБ.",
			"render_func": "render_size_task",
		},
		{
			"text": "В квесте «Архив данных» (уровень A):\n\n• Тебе дают дерево файлов с метаданными\n• Нужно найти файл по пути\n• Или вычислить итоговый размер директории\n• Или определить порядок сортировки файлов\n\nСтратегия: читай дерево сверху вниз, следи за текущей директорией.",
			"render_func": "render_archive_preview",
		},
	]


func render_fs_overview(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 5)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var fs_list := [
		["FAT32",  "Флешки, SD-карты",        "Max файл: 4 ГБ",      Color(0.80,0.60,0.20,1.0)],
		["NTFS",   "Windows (C:)",             "Журнал, права, EFS",  Color(0.35,0.70,1.00,1.0)],
		["ext4",   "Linux (/)",                "Журнал, inode",       Color(0.20,0.85,0.55,1.0)],
		["APFS",   "macOS, iPhone",            "Снимки, шифрование",  Color(0.80,0.50,1.00,1.0)],
		["exFAT",  "Флешки > 4 ГБ (новые)",   "Без лимита файла",    Color(0.55,0.55,0.70,1.0)],
	]
	container.add_child(_make_row_bg(["ФС", "Где", "Особенность"], true))
	for fs in fs_list:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		container.add_child(row)
		for j in range(3):
			var cell := _make_cell(str(fs[j]), 13, fs[3] if j==0 else Color(0.80,0.80,0.90,1.0),
				fs[3]*Color(1,1,1,0.09), fs[3]*Color(1,1,1,0.35))
			row.add_child(cell)


func render_fat_concept(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	# Визуализация FAT-цепочки
	var chain_row := HBoxContainer.new()
	chain_row.add_theme_constant_override("separation", 4)
	chain_row.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_child(chain_row)

	var clusters := [
		["Кластер 5", Color(0.35,0.70,1.00,1.0)],
		["→",         Color(0.55,0.55,0.70,1.0)],
		["Кластер 12",Color(0.35,0.70,1.00,1.0)],
		["→",         Color(0.55,0.55,0.70,1.0)],
		["Кластер 8", Color(0.35,0.70,1.00,1.0)],
		["→ END",     Color(0.20,0.85,0.55,1.0)],
	]
	for c in clusters:
		var lbl := Label.new()
		lbl.text = c[0]
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", c[1])
		if c[0] != "→" and c[0] != "→ END":
			var p := PanelContainer.new()
			p.add_theme_stylebox_override("panel", _flat_style(c[1]*Color(1,1,1,0.12), c[1], 1, 6))
			p.add_child(lbl)
			chain_row.add_child(p)
		else:
			chain_row.add_child(lbl)

	container.add_child(_make_limits_row())


func _make_limits_row() -> VBoxContainer:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	var limits := [
		["FAT32 ограничения:", Color(0.90,0.55,0.20,1.0)],
		["Макс. размер файла: 4 ГБ (2³² - 1 байт)", Color(0.80,0.80,0.90,1.0)],
		["Макс. размер тома: 2 ТБ", Color(0.80,0.80,0.90,1.0)],
		["Нет журналирования — риск потери данных", Color(0.80,0.80,0.90,1.0)],
	]
	for l in limits:
		var lbl := Label.new()
		lbl.text = l[0]
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", l[1])
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		vb.add_child(lbl)
	return vb


func render_ntfs_concept(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 5)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var features := [
		["Журналирование",   "Восстановление после сбоя",  Color(0.20,0.85,0.55,1.0)],
		["Размер файла",     "До 16 ЭксаБайт",             Color(0.35,0.70,1.00,1.0)],
		["Права доступа ACL","Чтение/Запись/Выполнение",   Color(0.80,0.60,0.20,1.0)],
		["Шифрование EFS",   "Встроенное шифрование",      Color(0.80,0.50,1.00,1.0)],
		["Сжатие",           "Прозрачное для приложений",  Color(0.55,0.55,0.70,1.0)],
		["Альтернативные потоки","Метаданные в файле",     Color(0.55,0.55,0.70,1.0)],
	]
	container.add_child(_make_row_bg(["Функция", "Описание"], true))
	for f in features:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		container.add_child(row)
		for j in range(2):
			row.add_child(_make_cell(str(f[j]), 13, f[2] if j==0 else Color(0.80,0.80,0.90,1.0),
				f[2]*Color(1,1,1,0.08), f[2]*Color(1,1,1,0.30)))


func render_dir_tree(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 3)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var tree_lines := [
		["/ (корень)",                          0, Color(0.90,0.82,0.25,1.0)],
		["├── home/",                           1, Color(0.35,0.70,1.00,1.0)],
		["│   ├── alex/",                       2, Color(0.35,0.70,1.00,1.0)],
		["│   │   ├── docs/",                   3, Color(0.35,0.70,1.00,1.0)],
		["│   │   │   ├── report.pdf",          4, Color(0.20,0.85,0.55,1.0)],
		["│   │   │   └── notes.txt",           4, Color(0.20,0.85,0.55,1.0)],
		["│   │   └── photos/",                 3, Color(0.35,0.70,1.00,1.0)],
		["├── etc/",                            1, Color(0.80,0.60,0.20,1.0)],
		["└── var/",                            1, Color(0.80,0.60,0.20,1.0)],
	]
	for line_d in tree_lines:
		var lbl := Label.new()
		lbl.text = line_d[0]
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", line_d[2])
		container.add_child(lbl)


func render_paths_demo(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 6)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var examples := [
		["/home/alex/docs/file.txt",  "Абсолютный (Linux)",  Color(0.35,0.70,1.00,1.0)],
		["C:\\Users\\Alex\\file.txt", "Абсолютный (Windows)",Color(0.80,0.60,0.20,1.0)],
		["./docs/file.txt",           "Относительный (здесь)",Color(0.20,0.85,0.55,1.0)],
		["../other/file.txt",         "Относительный (выше)", Color(0.80,0.50,1.00,1.0)],
		["~/documents/",              "Домашняя папка (Linux)",Color(0.55,0.55,0.70,1.0)],
	]
	for ex in examples:
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", _flat_style(ex[2]*Color(1,1,1,0.09), ex[2], 1, 6))
		container.add_child(panel)
		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 3)
		panel.add_child(vb)
		var path_lbl := Label.new()
		path_lbl.text = ex[0]
		path_lbl.add_theme_font_size_override("font_size", 14)
		path_lbl.add_theme_color_override("font_color", ex[2])
		path_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		vb.add_child(path_lbl)
		var type_lbl := Label.new()
		type_lbl.text = ex[1]
		type_lbl.add_theme_font_size_override("font_size", 11)
		type_lbl.add_theme_color_override("font_color", Color(0.55,0.55,0.70,1.0))
		vb.add_child(type_lbl)


func render_metadata_table(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 3)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var data := [
		["Имя", "report.pdf", "Идентификатор файла"],
		["Размер", "1 245 184 байт (≈1.2 МБ)", "Точный размер в байтах"],
		["Создан", "2024-03-15 10:23", "Дата и время создания"],
		["Изменён", "2024-03-20 14:45", "Последнее изменение"],
		["Тип", "Файл (не директория)", "Файл/папка/ссылка"],
		["Права", "rw-r--r--", "Чтение/запись/выполнение"],
	]
	container.add_child(_make_row_bg(["Атрибут", "Значение", "Смысл"], true))
	for row_d in data:
		container.add_child(_make_row_bg(row_d, false))


func render_size_task(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 6)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var steps_data := [
		["5 файлов × 100 КБ", "= 500 КБ", Color(0.35,0.70,1.00,1.0)],
		["3 × 2 файла × 50 КБ", "= 300 КБ", Color(0.20,0.85,0.55,1.0)],
		["Итого", "800 КБ", Color(0.90,0.82,0.25,1.0)],
	]
	for s in steps_data:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		container.add_child(row)
		var k := Label.new()
		k.text = s[0]
		k.add_theme_font_size_override("font_size", 14)
		k.add_theme_color_override("font_color", Color(0.78,0.78,0.88,1.0))
		k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		k.autowrap_mode = TextServer.AUTOWRAP_WORD
		row.add_child(k)
		var v := Label.new()
		v.text = s[1]
		v.add_theme_font_size_override("font_size", 16)
		v.add_theme_color_override("font_color", s[2])
		row.add_child(v)

	var tip := Label.new()
	tip.text = "1 КБ = 1024 байт  ·  1 МБ = 1024 КБ  ·  1 ГБ = 1024 МБ"
	tip.add_theme_font_size_override("font_size", 12)
	tip.add_theme_color_override("font_color", Color(0.55,0.55,0.70,1.0))
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(tip)


func render_archive_preview(area: Control, _step: Dictionary) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _flat_style(Color(0.07,0.10,0.06,1.0), Color(0.25,0.60,0.20,0.6), 1, 10))
	area.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 7)
	panel.add_child(vb)
	var t := Label.new()
	t.text = "🗄️ АРХИВ ДАННЫХ — Уровень A"
	t.add_theme_font_size_override("font_size", 16)
	t.add_theme_color_override("font_color", Color(0.25,0.80,0.35,1.0))
	vb.add_child(t)
	for hint in ["📂 Дерево файлов с именами и размерами","🔍 Найди файл по пути","📊 Вычисли размер директории","📋 Определи порядок сортировки"]:
		var lbl := Label.new()
		lbl.text = hint
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.75,0.75,0.85,1.0))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		vb.add_child(lbl)


# HELPERS ─────────────────────────────────────────────────────
func _flat_style(bg: Color, border: Color, bw: int = 1, radius: int = 6) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg; s.border_color = border
	s.set_border_width_all(bw)
	s.corner_radius_top_left = radius; s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius; s.corner_radius_bottom_right = radius
	s.content_margin_left = 10; s.content_margin_right = 10
	s.content_margin_top = 6; s.content_margin_bottom = 6
	return s

func _make_cell(text: String, fsize: int, fcol: Color, bg: Color, border: Color) -> PanelContainer:
	var cell := PanelContainer.new()
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cs := StyleBoxFlat.new()
	cs.bg_color = bg; cs.border_color = border
	cs.set_border_width_all(1)
	cs.corner_radius_top_left = 3; cs.corner_radius_top_right = 3
	cs.corner_radius_bottom_left = 3; cs.corner_radius_bottom_right = 3
	cs.content_margin_left = 6; cs.content_margin_right = 6
	cs.content_margin_top = 5; cs.content_margin_bottom = 5
	cell.add_theme_stylebox_override("panel", cs)
	var lbl := Label.new()
	lbl.text = text; lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", fsize)
	lbl.add_theme_color_override("font_color", fcol)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	cell.add_child(lbl)
	return cell

func _make_row_bg(values: Array, is_header: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	for val in values:
		row.add_child(_make_cell(str(val), 12,
			Color(0.5,0.7,1.0,1.0) if is_header else Color(0.8,0.8,0.9,1.0),
			Color(0.10,0.12,0.20,1.0) if is_header else Color(0.07,0.08,0.12,1.0),
			Color(0.22,0.35,0.55,0.7) if is_header else Color(0.15,0.15,0.22,0.5)))
	return row

func _calculate_stars() -> int:
	return 3 if current_step_index >= tutorial_steps.size() - 1 else 2
