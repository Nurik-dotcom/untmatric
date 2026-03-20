extends "res://scenes/Tutorial/TutorialBase.gd"
# TutorialMatrix.gd — Матричные шифры
# Готовит к: MatrixDecryptor (уровень C)

class_name TutorialMatrix

func _initialize_tutorial() -> void:
	tutorial_id = "matrix"
	tutorial_title = "Матричные шифры"
	linked_quest_scene = "res://scenes/MatrixDecryptor.tscn"

	tutorial_steps = [
		{
			"text": "Матрица — таблица чисел, расположенных в строках и столбцах.\n\nЗапись: M[строка][столбец]\n\nПример матрицы 3×3:\n  [1] [2] [3]\n  [4] [5] [6]\n  [7] [8] [9]\n\nВ квесте матрица — это зашифрованный блок данных. Ты должен найти скрытые значения зная только суммы строк и столбцов.",
			"render_func": "render_matrix_intro",
			"values": [1, 2, 3, 4, 5, 6, 7, 8, 9],
		},
		{
			"text": "У каждой строки и каждого столбца матрицы есть своя сумма.\n\n[1] [2] [3]  → сумма = 6\n[4] [5] [6]  → сумма = 15\n[7] [8] [9]  → сумма = 24\n ↓   ↓   ↓\n12  15  18  ← суммы столбцов\n\nСуммы строк и столбцов — это «зацепки» для решения.",
			"render_func": "render_matrix_with_sums",
			"values":   [1, 2, 3, 4, 5, 6, 7, 8, 9],
			"row_sums": [6, 15, 24],
			"col_sums": [12, 15, 18],
		},
		{
			"text": "Алгоритм решения — как в судоку:\n\n1. Найди строку или столбец с ОДНИМ неизвестным\n2. Вычисли: неизвестное = сумма − (остальные числа)\n3. Заполни найденное значение\n4. Повтори шаги 1–3\n\nГлавное правило: начинай с самого «заполненного» ряда.",
			"render_func": "",
		},
		{
			"text": "Разберём пример пошагово.\n\nМатрица 2×2 с одним неизвестным:\n  [3] [?]  → сумма строки = 8\n  [5] [2]  → сумма строки = 7\n   ↓   ↓\n   8   ?\n\nШаг 1: В первой строке одно неизвестное\nШаг 2: ? = 8 − 3 = 5\nПроверка: сумма столбца 2 = 5 + 2 = 7 ✓",
			"render_func": "render_matrix_solve_demo",
		},
		{
			"text": "Практика — найди неизвестные числа.",
			"render_func": "render_matrix_puzzle",
			"values":   [1, 2, 3, 4, -1, 6, -1, 8, 9],
			"row_sums": [6, -1, -1],
			"col_sums": [-1, 15, 18],
			"hint": "Начни с первой строки — там одно неизвестное (позиция 4).\n4+?+6=15 → ?=5",
		},
		{
			"text": "В квесте «Матрица-Дешифратор» (уровень C) каждое число в матрице — это зашифрованный символ.\n\nЧтобы раскрыть код:\n• Реши матрицу → найди все скрытые числа\n• Переведи числа в символы (через ASCII)\n• Прочитай скрытое сообщение\n\nЭто самый сложный уровень квеста. Готовься!",
			"render_func": "render_matrix_quest_preview",
		},
	]


# ─── CELL HELPERS ─────────────────────────────────────────────────────────────

const CELL_SIZE := Vector2(50, 44)
const CELL_SEP  := 4

func _make_cell(text: String, kind: String) -> PanelContainer:
	var cell := PanelContainer.new()
	cell.custom_minimum_size = CELL_SIZE
	var cs := StyleBoxFlat.new()
	cs.corner_radius_top_left    = 6; cs.corner_radius_top_right   = 6
	cs.corner_radius_bottom_left = 6; cs.corner_radius_bottom_right = 6
	cs.content_margin_left = 4; cs.content_margin_right = 4
	cs.content_margin_top  = 4; cs.content_margin_bottom = 4
	cs.set_border_width_all(1)
	match kind:
		"normal":
			cs.bg_color     = Color(0.08, 0.10, 0.18, 1.0)
			cs.border_color = Color(0.25, 0.35, 0.60, 0.7)
		"unknown":
			cs.bg_color     = Color(0.18, 0.06, 0.06, 1.0)
			cs.border_color = Color(0.70, 0.20, 0.20, 0.9)
		"sum":
			cs.bg_color     = Color(0.06, 0.16, 0.24, 1.0)
			cs.border_color = Color(0.20, 0.55, 0.85, 0.7)
		"found":
			cs.bg_color     = Color(0.05, 0.20, 0.10, 1.0)
			cs.border_color = Color(0.20, 0.75, 0.42, 0.9)
	cell.add_theme_stylebox_override("panel", cs)

	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	match kind:
		"normal":  lbl.add_theme_color_override("font_color", Color(0.75, 0.80, 1.00, 1.0))
		"unknown": lbl.add_theme_color_override("font_color", Color(0.95, 0.40, 0.40, 1.0))
		"sum":     lbl.add_theme_color_override("font_color", Color(0.35, 0.72, 1.00, 1.0))
		"found":   lbl.add_theme_color_override("font_color", Color(0.25, 0.95, 0.55, 1.0))
	cell.add_child(lbl)
	return cell


func _build_matrix_widget(values: Array, rows: int, cols: int,
		row_sums: Array = [], col_sums: Array = []) -> VBoxContainer:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", CELL_SEP)
	wrapper.alignment = BoxContainer.ALIGNMENT_CENTER

	for r in range(rows):
		var row_hbox := HBoxContainer.new()
		row_hbox.add_theme_constant_override("separation", CELL_SEP)
		row_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		wrapper.add_child(row_hbox)

		for c in range(cols):
			var idx := r * cols + c
			var val: int = values[idx] if idx < values.size() else 0
			var kind: String = "unknown" if val == -1 else "normal"
			var text: String = "?" if val == -1 else str(val)
			row_hbox.add_child(_make_cell(text, kind))

		if r < row_sums.size():
			var sep := Label.new()
			sep.text = "="
			sep.add_theme_color_override("font_color", Color(0.45, 0.45, 0.60, 1.0))
			sep.add_theme_font_size_override("font_size", 16)
			sep.custom_minimum_size = Vector2(24, 0)
			sep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			sep.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
			row_hbox.add_child(sep)

			var rs_val: int = row_sums[r]
			var rs_kind: String = "unknown" if rs_val == -1 else "sum"
			row_hbox.add_child(_make_cell("?" if rs_val == -1 else str(rs_val), rs_kind))

	if col_sums.size() > 0:
		var cs_row := HBoxContainer.new()
		cs_row.add_theme_constant_override("separation", CELL_SEP)
		cs_row.alignment = BoxContainer.ALIGNMENT_CENTER
		wrapper.add_child(cs_row)
		for c in range(cols):
			var cs_val: int = col_sums[c] if c < col_sums.size() else -1
			cs_row.add_child(_make_cell("?" if cs_val == -1 else str(cs_val), "sum"))
		cs_row.add_child(_make_cell("", "normal"))
		cs_row.add_child(_make_cell("", "normal"))

	return wrapper


# ─── RENDER FUNCTIONS ─────────────────────────────────────────────────────────

func render_matrix_intro(area: Control, step: Dictionary) -> void:
	var values: Array = step.get("values", [1,2,3,4,5,6,7,8,9])
	var widget := _build_matrix_widget(values, 3, 3)
	widget.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	area.add_child(widget)


func render_matrix_with_sums(area: Control, step: Dictionary) -> void:
	var values:   Array = step.get("values",   [1,2,3,4,5,6,7,8,9])
	var row_sums: Array = step.get("row_sums", [6,15,24])
	var col_sums: Array = step.get("col_sums", [12,15,18])
	var widget := _build_matrix_widget(values, 3, 3, row_sums, col_sums)
	widget.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	area.add_child(widget)


func render_matrix_solve_demo(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 10)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var before_lbl := Label.new()
	before_lbl.text = "До решения:"
	before_lbl.add_theme_font_size_override("font_size", 13)
	before_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65, 1.0))
	container.add_child(before_lbl)

	var before := _build_matrix_widget([3, -1, 5, 2], 2, 2, [8, 7], [8, -1])
	before.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	container.add_child(before)

	var arrow := Label.new()
	arrow.text = "▼  ? = 8 − 3 = 5  ▼"
	arrow.add_theme_color_override("font_color", Color(0.25, 0.90, 0.55, 1.0))
	arrow.add_theme_font_size_override("font_size", 15)
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(arrow)

	var after_lbl := Label.new()
	after_lbl.text = "После решения:"
	after_lbl.add_theme_font_size_override("font_size", 13)
	after_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65, 1.0))
	container.add_child(after_lbl)

	var after := _build_matrix_widget([3, 5, 5, 2], 2, 2, [8, 7], [8, 7])
	after.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	container.add_child(after)


func render_matrix_puzzle(area: Control, step: Dictionary) -> void:
	var values:   Array  = step.get("values",   [])
	var row_sums: Array  = step.get("row_sums", [])
	var col_sums: Array  = step.get("col_sums", [])
	var hint: String     = step.get("hint",     "")

	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 10)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	var widget := _build_matrix_widget(values, 3, 3, row_sums, col_sums)
	widget.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	container.add_child(widget)

	if hint != "":
		var hint_panel := PanelContainer.new()
		var hp := StyleBoxFlat.new()
		hp.bg_color = Color(0.08, 0.14, 0.08, 1.0)
		hp.border_color = Color(0.25, 0.60, 0.30, 0.7)
		hp.set_border_width_all(1)
		hp.corner_radius_top_left    = 6; hp.corner_radius_top_right   = 6
		hp.corner_radius_bottom_left = 6; hp.corner_radius_bottom_right = 6
		hp.content_margin_left = 12; hp.content_margin_right = 12
		hp.content_margin_top  = 8;  hp.content_margin_bottom = 8
		hint_panel.add_theme_stylebox_override("panel", hp)
		container.add_child(hint_panel)

		var h_lbl := Label.new()
		h_lbl.text = "💡 " + hint
		h_lbl.add_theme_font_size_override("font_size", 13)
		h_lbl.add_theme_color_override("font_color", Color(0.65, 0.90, 0.65, 1.0))
		h_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		hint_panel.add_child(h_lbl)


func render_matrix_quest_preview(area: Control, _step: Dictionary) -> void:
	var panel := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.07, 0.10, 0.18, 1.0)
	ps.border_color = Color(0.25, 0.45, 0.80, 0.6)
	ps.set_border_width_all(1)
	ps.corner_radius_top_left    = 10; ps.corner_radius_top_right   = 10
	ps.corner_radius_bottom_left = 10; ps.corner_radius_bottom_right = 10
	ps.content_margin_left = 14; ps.content_margin_right = 14
	ps.content_margin_top  = 12; ps.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", ps)
	area.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.text = "🔢 МАТРИЦА-ДЕШИФРАТОР — Уровень C"
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Color(0.40, 0.70, 1.00, 1.0))
	vbox.add_child(title_lbl)

	for hint in [
		"🧩 Тебе дают матрицу со скрытыми числами",
		"🧮 Решаешь матрицу через суммы строк и столбцов",
		"🔡 Числа переводишь в символы ASCII",
		"✅ Читаешь скрытое сообщение агента",
	]:
		var lbl := Label.new()
		lbl.text = hint
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85, 1.0))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(lbl)


func _calculate_stars() -> int:
	return 3 if current_step_index >= tutorial_steps.size() - 1 else 2
