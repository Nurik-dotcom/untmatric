extends "res://scenes/Tutorial/TutorialBase.gd"
# Частотный анализ в задачах дешифровки
# Готовит к: RadioQuest B

class_name TutorialFreqAnalysis

func _initialize_tutorial() -> void:
	tutorial_id = "encode_freq"
	tutorial_title = "Частотный анализ"
	linked_quest_scene = "res://scenes/RadioQuestB.tscn"

	tutorial_steps = [
		{
			"text": "Частотный анализ — метод дешифровки, где мы сравниваем частоты символов в шифртексте с частотами языка.\n\nЕсли шифр подстановочный и текст достаточно длинный, самые частые буквы обычно остаются самыми частыми.",
			"render_func": "render_intro",
		},
		{
			"text": "Частые буквы в русском языке: О, Е, А, И, Н, Т, С.\nЧастые в английском: E, T, A, O, I, N, S.\n\nЭто стартовые гипотезы, а не абсолютное правило.",
			"render_func": "render_lang_freq",
		},
		{
			"text": "Шаг 1: подсчёт частот.\n\nСчитаем, сколько раз встречается каждый символ.\nПотом переводим в проценты: count / total * 100.\n\nСортировка по убыванию сразу показывает кандидатов на замену.",
			"render_func": "render_counting",
		},
		{
			"text": "Шаг 2: предположение о замене.\n\nЕсли символ X встречается чаще всего, возможно это «О» или «Е» (для русского текста).\nДальше проверяем гипотезу по биграммам и словам.",
			"render_func": "render_substitution_guess",
		},
		{
			"text": "Проверка гипотезы:\n• Смотрим частые биграммы (СТ, НО, ТО, EN, TH и т.д.)\n• Проверяем, появляются ли осмысленные слова\n• Если нет — меняем соответствия\n\nЭто итеративный процесс.",
			"render_func": "render_validation",
		},
		{
			"text": "Типовые вопросы ЕНТ:\n1) Какая буква наиболее вероятно соответствует самому частому символу?\n2) Какой метод дешифровки здесь применим?\n3) Почему частотный анализ работает хуже на коротких строках?\n\nОтвет на (3): статистики недостаточно.",
			"render_func": "render_ent_tasks",
		},
		{
			"text": "В квесте «Радиоперехват» B:\n• Получаешь шифртекст\n• Строишь таблицу частот\n• Проверяешь 2–3 гипотезы замен\n• Выбираешь читаемую расшифровку\n\nРабочая стратегия: частоты + здравый смысл по словам.",
			"render_func": "render_preview",
		},
	]


func render_intro(area: Control, _step: Dictionary) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _flat_style(Color(0.08,0.10,0.20,1.0), Color(0.25,0.45,0.85,0.7), 1, 8))
	area.add_child(panel)

	var lbl := Label.new()
	lbl.text = "Идея: частоты букв в естественном языке не равномерны"
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", Color(0.55,0.75,1.0,1.0))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	panel.add_child(lbl)


func render_lang_freq(area: Control, _step: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(row)

	for block in [
		["Русский", "О Е А И Н Т С", Color(0.35,0.70,1.00,1.0)],
		["English", "E T A O I N S", Color(0.20,0.85,0.55,1.0)],
	]:
		var p := PanelContainer.new()
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p.add_theme_stylebox_override("panel", _flat_style(block[2]*Color(1,1,1,0.10), block[2], 1, 7))
		row.add_child(p)

		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 4)
		p.add_child(vb)

		var t := Label.new()
		t.text = block[0]
		t.add_theme_font_size_override("font_size", 14)
		t.add_theme_color_override("font_color", block[2])
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(t)

		var s := Label.new()
		s.text = block[1]
		s.add_theme_font_size_override("font_size", 16)
		s.add_theme_color_override("font_color", Color(0.82,0.82,0.92,1.0))
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(s)


func render_counting(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 3)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	container.add_child(_make_row_bg(["Символ", "Count", "%"], true))
	for r in [["X","18","18%"],["Q","14","14%"],["M","11","11%"],["Z","9","9%"],["...","...","..."]]:
		container.add_child(_make_row_bg(r, false))

	var tip := Label.new()
	tip.text = "Формула: p = count / total * 100"
	tip.add_theme_font_size_override("font_size", 13)
	tip.add_theme_color_override("font_color", Color(0.90,0.82,0.25,1.0))
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(tip)


func render_substitution_guess(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 3)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	container.add_child(_make_row_bg(["Символ шифра", "Гипотеза", "Причина"], true))
	for row_data in [
		["X", "О", "самая частая позиция"],
		["Q", "Е", "вторая по частоте"],
		["M", "А", "третья по частоте"],
	]:
		container.add_child(_make_row_bg(row_data, false))


func render_validation(area: Control, _step: Dictionary) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _flat_style(Color(0.07,0.10,0.06,1.0), Color(0.25,0.60,0.20,0.6), 1, 8))
	area.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	panel.add_child(vb)

	for line in [
		"1) Проверить частые биграммы",
		"2) Проверить, читаются ли короткие слова",
		"3) При необходимости переставить 2-3 соответствия",
		"4) Снова оценить читаемость текста",
	]:
		var lbl := Label.new()
		lbl.text = line
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.80,0.84,0.90,1.0))
		vb.add_child(lbl)


func render_ent_tasks(area: Control, _step: Dictionary) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 6)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(container)

	for t in [
		["Тип 1", "Определи вероятную букву по частоте", Color(0.35,0.70,1.00,1.0)],
		["Тип 2", "Выбери метод: частотный анализ", Color(0.20,0.85,0.55,1.0)],
		["Тип 3", "Объясни ограничение короткого текста", Color(0.80,0.60,0.20,1.0)],
	]:
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", _flat_style(t[2]*Color(1,1,1,0.09), t[2], 1, 7))
		container.add_child(p)

		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		p.add_child(hb)

		var a := Label.new()
		a.text = t[0]
		a.custom_minimum_size = Vector2(58, 0)
		a.add_theme_font_size_override("font_size", 14)
		a.add_theme_color_override("font_color", t[2])
		hb.add_child(a)

		var b := Label.new()
		b.text = t[1]
		b.add_theme_font_size_override("font_size", 13)
		b.add_theme_color_override("font_color", Color(0.82,0.82,0.92,1.0))
		b.autowrap_mode = TextServer.AUTOWRAP_WORD
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(b)


func render_preview(area: Control, _step: Dictionary) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _flat_style(Color(0.07,0.10,0.06,1.0), Color(0.25,0.60,0.20,0.6), 1, 10))
	area.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	panel.add_child(vb)

	var title := Label.new()
	title.text = "📻 РАДИОПЕРЕХВАТ — Уровень B"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.25,0.80,0.35,1.0))
	vb.add_child(title)

	for line in [
		"• Построй частотную таблицу",
		"• Сделай первичную подстановку",
		"• Проверь биграммы и короткие слова",
		"• Выбери наиболее читаемый вариант",
	]:
		var lbl := Label.new()
		lbl.text = line
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.75,0.75,0.85,1.0))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		vb.add_child(lbl)


# HELPERS ─────────────────────────────────────────────────────
func _flat_style(bg: Color, border: Color, bw: int = 1, radius: int = 6) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s

func _make_cell(text: String, fsize: int, fcol: Color, bg: Color, border: Color) -> PanelContainer:
	var cell := PanelContainer.new()
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cs := StyleBoxFlat.new()
	cs.bg_color = bg
	cs.border_color = border
	cs.set_border_width_all(1)
	cs.corner_radius_top_left = 3
	cs.corner_radius_top_right = 3
	cs.corner_radius_bottom_left = 3
	cs.corner_radius_bottom_right = 3
	cs.content_margin_left = 6
	cs.content_margin_right = 6
	cs.content_margin_top = 5
	cs.content_margin_bottom = 5
	cell.add_theme_stylebox_override("panel", cs)
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
