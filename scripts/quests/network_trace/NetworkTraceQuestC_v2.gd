extends Control

const TrialV2 = preload("res://scripts/TrialV2.gd")
const MOBILE_INPUT_FIX = preload("res://scripts/MobileInputFix.gd")
const QUEST_ID: String = "NETWORK_TRACE_C"
const STAGE_ID: String = "C"

func _tr(key: String, default_text: String, params: Dictionary = {}) -> String:
	return I18n.tr_key(key, params.merged({"default": default_text}))

# 笏笏笏 LEVELS 笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏

const LEVELS: Array[Dictionary] = [
	{
		"id": "NTC_01", "ip": "192.168.1.45", "cidr": 24,
		"mask": "255.255.255.0", "network": "192.168.1.0", "host_bits": 8, "hosts": 254,
		"briefing_key": "nt.v2.c.C01.briefing",
		"briefing_default": "Intercepted packet. IP: 192.168.1.45/24.\nDetermine network parameters.",
		"hint_mask_key": "nt.v2.c.C01.hint_mask",
		"hint_mask_default": "For /24: first 24 bits are ones: 11111111.11111111.11111111.00000000",
		"hint_network": "192.168.1.45 AND 255.255.255.0\nLast octet: 45 AND 0 = 0",
		"hint_hosts": "host_bits = 32 - 24 = 8. Formula: 2^8 - 2 = 254"
	},
	{
		"id": "NTC_02", "ip": "10.0.5.130", "cidr": 25,
		"mask": "255.255.255.128", "network": "10.0.5.128", "host_bits": 7, "hosts": 126,
		"briefing_key": "nt.v2.c.C02.briefing",
		"briefing_default": "Node 10.0.5.130/25. What is its subnet?",
		"hint_mask_key": "nt.v2.c.C02.hint_mask",
		"hint_mask_default": "For /25: 25 ones. Last mask octet: 10000000 = 128",
		"hint_network": "10.0.5.130 AND 255.255.255.128\nLast octet: 130 AND 128 = 128",
		"hint_hosts": "host_bits = 32 - 25 = 7. Formula: 2^7 - 2 = 126"
	},
	{
		"id": "NTC_03", "ip": "172.16.4.200", "cidr": 26,
		"mask": "255.255.255.192", "network": "172.16.4.192", "host_bits": 6, "hosts": 62,
		"briefing_key": "nt.v2.c.C03.briefing",
		"briefing_default": "Traffic from 172.16.4.200/26. Decode network range.",
		"hint_mask_key": "nt.v2.c.C03.hint_mask",
		"hint_mask_default": "For /26: last mask octet is 11000000 = 192",
		"hint_network": "172.16.4.200 AND 255.255.255.192\nLast octet: 200 AND 192 = 192",
		"hint_hosts": "host_bits = 32 - 26 = 6. Formula: 2^6 - 2 = 62"
	},
	{
		"id": "NTC_04", "ip": "10.10.10.50", "cidr": 27,
		"mask": "255.255.255.224", "network": "10.10.10.32", "host_bits": 5, "hosts": 30,
		"briefing_key": "nt.v2.c.C04.briefing",
		"briefing_default": "Signal from 10.10.10.50/27. Determine subnet membership.",
		"hint_mask_key": "nt.v2.c.C04.hint_mask",
		"hint_mask_default": "For /27: last mask octet is 11100000 = 224",
		"hint_network": "10.10.10.50 AND 255.255.255.224\nLast octet: 50 AND 224 = 32",
		"hint_hosts": "host_bits = 32 - 27 = 5. Formula: 2^5 - 2 = 30"
	},
	{
		"id": "NTC_05", "ip": "192.168.10.100", "cidr": 28,
		"mask": "255.255.255.240", "network": "192.168.10.96", "host_bits": 4, "hosts": 14,
		"briefing_key": "nt.v2.c.C05.briefing",
		"briefing_default": "Node 192.168.10.100/28 in a small subnet. Calculate parameters.",
		"hint_mask_key": "nt.v2.c.C05.hint_mask",
		"hint_mask_default": "For /28: last mask octet is 11110000 = 240",
		"hint_network": "192.168.10.100 AND 255.255.255.240\nLast octet: 100 AND 240 = 96",
		"hint_hosts": "host_bits = 32 - 28 = 4. Formula: 2^4 - 2 = 14"
	},
	{
		"id": "NTC_06", "ip": "10.1.1.13", "cidr": 29,
		"mask": "255.255.255.248", "network": "10.1.1.8", "host_bits": 3, "hosts": 6,
		"briefing_key": "nt.v2.c.C06.briefing",
		"briefing_default": "Mini subnet 10.1.1.13/29. Find the network range.",
		"hint_mask_key": "nt.v2.c.C06.hint_mask",
		"hint_mask_default": "For /29: last mask octet is 11111000 = 248",
		"hint_network": "10.1.1.13 AND 255.255.255.248\nLast octet: 13 AND 248 = 8",
		"hint_hosts": "host_bits = 32 - 29 = 3. Formula: 2^3 - 2 = 6"
	},
	{
		"id": "NTC_07", "ip": "172.20.30.77", "cidr": 25,
		"mask": "255.255.255.128", "network": "172.20.30.0", "host_bits": 7, "hosts": 126,
		"briefing_key": "nt.v2.c.C07.briefing",
		"briefing_default": "Packet 172.20.30.77/25. Find the subnet identifier.",
		"hint_mask_key": "nt.v2.c.C07.hint_mask",
		"hint_mask_default": "Mask /25: 255.255.255.128",
		"hint_network": "172.20.30.77 AND 255.255.255.128\nLast octet: 77 AND 128 = 0",
		"hint_hosts": "host_bits = 32 - 25 = 7. Formula: 2^7 - 2 = 126"
	},
	{
		"id": "NTC_08", "ip": "192.168.5.210", "cidr": 26,
		"mask": "255.255.255.192", "network": "192.168.5.192", "host_bits": 6, "hosts": 62,
		"briefing_key": "nt.v2.c.C08.briefing",
		"briefing_default": "Address 192.168.5.210/26. Determine subnet block.",
		"hint_mask_key": "nt.v2.c.C08.hint_mask",
		"hint_mask_default": "Mask /26: 255.255.255.192",
		"hint_network": "192.168.5.210 AND 255.255.255.192\nLast octet: 210 AND 192 = 192",
		"hint_hosts": "host_bits = 32 - 26 = 6. Formula: 2^6 - 2 = 62"
	},
	{
		"id": "NTC_09", "ip": "10.5.5.250", "cidr": 28,
		"mask": "255.255.255.240", "network": "10.5.5.240", "host_bits": 4, "hosts": 14,
		"briefing_key": "nt.v2.c.C09.briefing",
		"briefing_default": "Address 10.5.5.250/28. Calculate network and host count.",
		"hint_mask_key": "nt.v2.c.C09.hint_mask",
		"hint_mask_default": "Mask /28: 255.255.255.240",
		"hint_network": "10.5.5.250 AND 255.255.255.240\nLast octet: 250 AND 240 = 240",
		"hint_hosts": "host_bits = 32 - 28 = 4. Formula: 2^4 - 2 = 14"
	},
	{
		"id": "NTC_10", "ip": "172.31.255.100", "cidr": 27,
		"mask": "255.255.255.224", "network": "172.31.255.96", "host_bits": 5, "hosts": 30,
		"briefing_key": "nt.v2.c.C10.briefing",
		"briefing_default": "Final target: 172.31.255.100/27.\nPerform full subnet analysis.",
		"hint_mask_key": "nt.v2.c.C10.hint_mask",
		"hint_mask_default": "Mask /27: 255.255.255.224",
		"hint_network": "172.31.255.100 AND 255.255.255.224\nLast octet: 100 AND 224 = 96",
		"hint_hosts": "host_bits = 32 - 27 = 5. Formula: 2^5 - 2 = 30"
	},
]

# 笏笏笏 UI NODES 笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏

var btn_back: Button
var title_label: Label
var progress_label: Label
var stability_bar: ProgressBar
var content_scroll: ScrollContainer
var content_vbox: VBoxContainer
var status_label: Label
var btn_hint: Button

var step1_panel: PanelContainer
var step2_panel: PanelContainer
var step3_panel: PanelContainer
var and_vis_label: Label
var edit_mask: LineEdit
var edit_network: LineEdit
var edit_hosts: LineEdit
var btn_check1: Button
var btn_check2: Button
var btn_check3: Button

# 笏笏笏 STATE 笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏

var current_idx: int = 0
var step: int = 1  # 1, 2, 3
var hint_used: bool = false
var hint_step: int = 0
var trial_seq: int = 0
var level_started_ms: int = 0
var _quest_done: bool = false
var _wrong_counts: Array[int] = [0, 0, 0]

# 笏笏笏 HELPERS 笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏

func _make_panel() -> PanelContainer:
	return PanelContainer.new()

func _make_semantic_panel(semantic: String) -> PanelContainer:
	var p := PanelContainer.new()
	var s := StyleBoxFlat.new()
	match semantic:
		"correct":
			s.bg_color = Color(0.06, 0.09, 0.06, 0.96)
			s.border_color = Color(0.2, 0.5, 0.25, 0.7)
		"wrong":
			s.bg_color = Color(0.09, 0.06, 0.06, 0.96)
			s.border_color = Color(0.5, 0.2, 0.2, 0.7)
		"hint", "info":
			s.bg_color = Color(0.06, 0.06, 0.09, 0.96)
			s.border_color = Color(0.3, 0.3, 0.5, 0.7)
		_:
			return p
	s.set_border_width_all(1)
	s.corner_radius_top_left = 8; s.corner_radius_top_right = 8
	s.corner_radius_bottom_left = 8; s.corner_radius_bottom_right = 8
	s.content_margin_left = 14; s.content_margin_right = 14
	s.content_margin_top = 10; s.content_margin_bottom = 10
	p.add_theme_stylebox_override("panel", s)
	return p

func _apply_semantic_style(panel: PanelContainer, semantic: String) -> void:
	var s := StyleBoxFlat.new()
	match semantic:
		"correct":
			s.bg_color = Color(0.06, 0.09, 0.06, 0.96)
			s.border_color = Color(0.2, 0.5, 0.25, 0.7)
		"wrong":
			s.bg_color = Color(0.09, 0.06, 0.06, 0.96)
			s.border_color = Color(0.5, 0.2, 0.2, 0.7)
		"hint", "info":
			s.bg_color = Color(0.06, 0.06, 0.09, 0.96)
			s.border_color = Color(0.3, 0.3, 0.5, 0.7)
	s.set_border_width_all(1)
	s.corner_radius_top_left = 8; s.corner_radius_top_right = 8
	s.corner_radius_bottom_left = 8; s.corner_radius_bottom_right = 8
	s.content_margin_left = 14; s.content_margin_right = 14
	s.content_margin_top = 10; s.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", s)

func _make_button(text_val: String) -> Button:
	var btn := Button.new()
	btn.text = text_val
	btn.focus_mode = Control.FOCUS_NONE
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return btn

func _make_label(text_val: String, size: int = 0) -> Label:
	var l := Label.new()
	l.text = text_val
	if size > 0:
		l.add_theme_font_size_override("font_size", size)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

func _make_sep() -> Panel:
	var sep := Panel.new()
	sep.custom_minimum_size.y = 1
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.2, 0.2, 0.22)
	sep.add_theme_stylebox_override("panel", s)
	return sep

func _make_edit(
	placeholder: String,
	prompt_title: String,
	keyboard_type: int = LineEdit.KEYBOARD_TYPE_DEFAULT
) -> LineEdit:
	var e: LineEdit = MOBILE_INPUT_FIX.new()
	e.placeholder_text = placeholder
	e.set("prompt_title", prompt_title)
	e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	e.custom_minimum_size.y = 48
	e.focus_mode = Control.FOCUS_CLICK
	e.virtual_keyboard_type = keyboard_type
	return e

# 笏笏笏 BUILD UI 笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.06)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var safe := MarginContainer.new()
	safe.set_anchors_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", 14)
	safe.add_theme_constant_override("margin_right", 14)
	safe.add_theme_constant_override("margin_top", 44)
	safe.add_theme_constant_override("margin_bottom", 10)
	add_child(safe)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 8)
	safe.add_child(root_vbox)

	# 笏笏 Header 笏笏
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 52
	header.add_theme_constant_override("separation", 8)
	root_vbox.add_child(header)

	btn_back = _make_button("")
	btn_back.custom_minimum_size = Vector2(80, 44)
	btn_back.size_flags_horizontal = 0
	header.add_child(btn_back)

	title_label = _make_label("", 20)
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(title_label)

	progress_label = _make_label("", 15)
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	progress_label.size_flags_horizontal = 0
	progress_label.custom_minimum_size.x = 90
	header.add_child(progress_label)

	stability_bar = ProgressBar.new()
	stability_bar.custom_minimum_size = Vector2(100, 22)
	stability_bar.size_flags_horizontal = 0
	stability_bar.max_value = 100
	stability_bar.value = float(GlobalMetrics.stability)
	root_vbox.add_child(stability_bar)

	root_vbox.add_child(_make_sep())

	# 笏笏 Scroll content 笏笏
	content_scroll = ScrollContainer.new()
	content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(content_scroll)

	content_vbox = VBoxContainer.new()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 12)
	content_scroll.add_child(content_vbox)

	# 笏笏 Status + Hint 笏笏
	var bottom := HBoxContainer.new()
	bottom.custom_minimum_size.y = 48
	bottom.add_theme_constant_override("separation", 8)
	root_vbox.add_child(bottom)

	status_label = _make_label("")
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bottom.add_child(status_label)

	btn_hint = _make_button("")
	btn_hint.size_flags_horizontal = 0
	btn_hint.custom_minimum_size = Vector2(120, 44)
	bottom.add_child(btn_hint)

# 笏笏笏 LOAD LEVEL 笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏

func _load_level(idx: int) -> void:
	current_idx = idx
	step = 1
	hint_used = false
	hint_step = 0
	_wrong_counts = [0, 0, 0]
	level_started_ms = Time.get_ticks_msec()
	btn_hint.disabled = false

	var lv: Dictionary = LEVELS[current_idx]
	progress_label.text = "%d / %d" % [current_idx + 1, LEVELS.size()]
	status_label.text = ""

	for child in content_vbox.get_children():
		child.queue_free()
	step1_panel = null; step2_panel = null; step3_panel = null

	# Briefing
	var brief_panel := _make_panel()
	brief_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(brief_panel)
	var brief_margin := MarginContainer.new()
	brief_margin.add_theme_constant_override("margin_left", 14)
	brief_margin.add_theme_constant_override("margin_right", 14)
	brief_margin.add_theme_constant_override("margin_top", 10)
	brief_margin.add_theme_constant_override("margin_bottom", 10)
	brief_panel.add_child(brief_margin)
	var brief_vbox := VBoxContainer.new()
	brief_vbox.add_theme_constant_override("separation", 6)
	brief_margin.add_child(brief_vbox)
	var brief_title := _make_label(
		_tr("nt.v2.c.case_title", "CASE {n} — NETWORK ANALYSIS", {"n": current_idx + 1}),
		16
	)
	brief_title.add_theme_color_override("font_color", Color(0.92, 0.2, 0.24))
	brief_vbox.add_child(brief_title)
	var briefing_text: String = _tr(
		str(lv.get("briefing_key", "")),
		str(lv.get("briefing_default", ""))
	)
	brief_vbox.add_child(_make_label(briefing_text, 14))

	# IP / CIDR info
	var info_hbox := HBoxContainer.new()
	info_hbox.add_theme_constant_override("separation", 16)
	brief_vbox.add_child(info_hbox)
	var ip_lbl := _make_label("IP: " + str(lv.get("ip", "")), 15)
	ip_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	ip_lbl.size_flags_horizontal = 0
	info_hbox.add_child(ip_lbl)
	var cidr_lbl := _make_label("/" + str(lv.get("cidr", "")), 15)
	cidr_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	cidr_lbl.size_flags_horizontal = 0
	info_hbox.add_child(cidr_lbl)

	_build_step1()

func _build_step1() -> void:
	var lv: Dictionary = LEVELS[current_idx]
	step1_panel = _make_panel()
	step1_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(step1_panel)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 14)
	m.add_theme_constant_override("margin_right", 14)
	m.add_theme_constant_override("margin_top", 10)
	m.add_theme_constant_override("margin_bottom", 10)
	step1_panel.add_child(m)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	m.add_child(vb)

	var lbl_step := _make_label(_tr("nt.v2.c.step1_title", "STEP 1 — SUBNET MASK"), 14)
	lbl_step.add_theme_color_override("font_color", Color(0.92, 0.2, 0.24))
	vb.add_child(lbl_step)
	vb.add_child(_make_label(
		_tr("nt.v2.c.step1_prompt", "Write subnet mask for /{cidr} in X.X.X.X format:", {"cidr": lv.get("cidr", 0)}),
		13
	))

	edit_mask = _make_edit(
		_tr("nt.v2.c.step1_placeholder", "e.g.: 255.255.255.0"),
		"Введите маску подсети:"
	)
	vb.add_child(edit_mask)

	btn_check1 = _make_button(_tr("nt.v2.c.btn_check1", "CHECK MASK"))
	btn_check1.custom_minimum_size.y = 48
	vb.add_child(btn_check1)
	btn_check1.pressed.connect(_on_check1_pressed)

func _build_step2() -> void:
	var lv: Dictionary = LEVELS[current_idx]
	step2_panel = _make_panel()
	step2_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(step2_panel)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 14)
	m.add_theme_constant_override("margin_right", 14)
	m.add_theme_constant_override("margin_top", 10)
	m.add_theme_constant_override("margin_bottom", 10)
	step2_panel.add_child(m)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	m.add_child(vb)

	var lbl_step := _make_label(_tr("nt.v2.c.step2_title", "STEP 2 — NETWORK ID"), 14)
	lbl_step.add_theme_color_override("font_color", Color(0.92, 0.2, 0.24))
	vb.add_child(lbl_step)
	vb.add_child(_make_label(
		_tr("nt.v2.c.step2_desc", "AND operation: IP AND Mask = Network ID."),
		13
	))

	# Binary AND visualization for last octet
	var ip_parts := str(lv.get("ip", "")).split(".")
	var mask_parts := str(lv.get("mask", "")).split(".")
	if ip_parts.size() == 4 and mask_parts.size() == 4:
		var ip_last := int(ip_parts[3])
		var mask_last := int(mask_parts[3])
		var net_last := ip_last & mask_last
		and_vis_label = _make_label(
			_tr(
				"nt.v2.c.step2_and_view",
				"[Last octet AND\n  IP:   {ip_bin}  ({ip_dec})\nMASK: {mask_bin}  ({mask_dec})\n  AND:  {and_bin}  ({and_dec})]",
				{
					"ip_bin": _byte_to_bin(ip_last),
					"ip_dec": ip_last,
					"mask_bin": _byte_to_bin(mask_last),
					"mask_dec": mask_last,
					"and_bin": _byte_to_bin(net_last),
					"and_dec": net_last
				}
			),
			13
		)
		and_vis_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
		vb.add_child(and_vis_label)

	vb.add_child(_make_label(_tr("nt.v2.c.step2_prompt", "Write network ID in X.X.X.X format:"), 13))
	edit_network = _make_edit(
		_tr("nt.v2.c.step2_placeholder", "e.g.: 192.168.1.0"),
		"Введите идентификатор сети:"
	)
	vb.add_child(edit_network)

	btn_check2 = _make_button(_tr("nt.v2.c.btn_check2", "CHECK NETWORK"))
	btn_check2.custom_minimum_size.y = 48
	vb.add_child(btn_check2)
	btn_check2.pressed.connect(_on_check2_pressed)

func _build_step3() -> void:
	var lv: Dictionary = LEVELS[current_idx]
	step3_panel = _make_panel()
	step3_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(step3_panel)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 14)
	m.add_theme_constant_override("margin_right", 14)
	m.add_theme_constant_override("margin_top", 10)
	m.add_theme_constant_override("margin_bottom", 10)
	step3_panel.add_child(m)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	m.add_child(vb)

	var lbl_step := _make_label(_tr("nt.v2.c.step3_title", "STEP 3 — HOST COUNT"), 14)
	lbl_step.add_theme_color_override("font_color", Color(0.92, 0.2, 0.24))
	vb.add_child(lbl_step)

	var cidr: int = lv.get("cidr", 24)
	var host_bits: int = 32 - cidr
	vb.add_child(_make_label(
		_tr(
			"nt.v2.c.step3_prompt",
			"Formula: 2^host_bits - 2\n/{cidr} -> host_bits = 32 - {cidr} = {hb}\nHow many hosts?",
			{"cidr": cidr, "hb": host_bits}
		),
		13
	))

	edit_hosts = _make_edit(
		_tr("nt.v2.c.step3_placeholder", "enter number"),
		"Введите количество хостов:",
		LineEdit.KEYBOARD_TYPE_NUMBER_DECIMAL
	)
	vb.add_child(edit_hosts)

	btn_check3 = _make_button(_tr("nt.v2.c.btn_check3", "CHECK HOSTS"))
	btn_check3.custom_minimum_size.y = 48
	vb.add_child(btn_check3)
	btn_check3.pressed.connect(_on_check3_pressed)

# 笏笏笏 CHECK HANDLERS 笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏

func _on_check1_pressed() -> void:
	var lv: Dictionary = LEVELS[current_idx]
	var answer: String = edit_mask.text.strip_edges()
	var correct: String = str(lv.get("mask", ""))
	if answer == correct:
		_apply_semantic_style(step1_panel, "correct")
		edit_mask.editable = false
		btn_check1.disabled = true
		_register_trial(1, true)
		status_label.text = _tr("nt.v2.c.mask_correct", "Mask is correct!")
		step = 2
		_build_step2()
		await get_tree().process_frame
		if is_instance_valid(edit_network):
			edit_network.grab_focus()
		content_scroll.scroll_vertical = content_scroll.get_v_scroll_bar().max_value
	else:
		_wrong_counts[0] += 1
		_apply_semantic_style(step1_panel, "wrong")
		_register_trial(1, false)
		status_label.text = _tr(
			"nt.v2.c.mask_wrong",
			"Wrong. Check the number of ones in the mask for /{cidr}.",
			{"cidr": lv.get("cidr", 0)}
		)
		GlobalMetrics.add_mistake("NTC mask wrong: %s expected %s" % [answer, correct])

func _on_check2_pressed() -> void:
	var lv: Dictionary = LEVELS[current_idx]
	var answer: String = edit_network.text.strip_edges()
	var correct: String = str(lv.get("network", ""))
	if answer == correct:
		_apply_semantic_style(step2_panel, "correct")
		edit_network.editable = false
		btn_check2.disabled = true
		_register_trial(2, true)
		status_label.text = _tr("nt.v2.c.net_correct", "Network identified correctly!")
		step = 3
		_build_step3()
		await get_tree().process_frame
		if is_instance_valid(edit_hosts):
			edit_hosts.grab_focus()
		content_scroll.scroll_vertical = content_scroll.get_v_scroll_bar().max_value
	else:
		_wrong_counts[1] += 1
		_apply_semantic_style(step2_panel, "wrong")
		_register_trial(2, false)
		status_label.text = _tr("nt.v2.c.net_wrong", "Wrong. Apply AND to each octet of IP and mask.")
		GlobalMetrics.add_mistake("NTC network wrong: %s expected %s" % [answer, correct])

func _on_check3_pressed() -> void:
	var lv: Dictionary = LEVELS[current_idx]
	var answer_str: String = edit_hosts.text.strip_edges()
	var correct: int = lv.get("hosts", 0)
	if answer_str.is_valid_int() and int(answer_str) == correct:
		_apply_semantic_style(step3_panel, "correct")
		edit_hosts.editable = false
		btn_check3.disabled = true
		_register_trial(3, true)
		status_label.text = _tr("nt.v2.c.hosts_correct", "Correct! Level complete.")
		btn_hint.disabled = true
		_level_complete()
	else:
		_wrong_counts[2] += 1
		_apply_semantic_style(step3_panel, "wrong")
		_register_trial(3, false)
		status_label.text = _tr(
			"nt.v2.c.hosts_wrong",
			"Wrong. Formula: 2^{hb} - 2",
			{"hb": 32 - lv.get("cidr", 24)}
		)
		GlobalMetrics.add_mistake("NTC hosts wrong: %s expected %d" % [answer_str, correct])

# 笏笏笏 HINT 笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏

func _on_hint_pressed() -> void:
	var lv: Dictionary = LEVELS[current_idx]
	hint_used = true
	GlobalMetrics.stability -= 5.0
	GlobalMetrics.stability_changed.emit(GlobalMetrics.stability, -5.0)

	var hint_text: String
	match step:
		1:
			hint_text = _tr(
				str(lv.get("hint_mask_key", "")),
				str(lv.get("hint_mask_default", ""))
			)
			hint_step = 1
		2:
			var ip_text: String = str(lv.get("ip", ""))
			var mask_text: String = str(lv.get("mask", ""))
			var ip_parts: PackedStringArray = ip_text.split(".")
			var mask_parts: PackedStringArray = mask_text.split(".")
			var ip_last: int = int(ip_parts[3]) if ip_parts.size() == 4 else 0
			var mask_last: int = int(mask_parts[3]) if mask_parts.size() == 4 else 0
			hint_text = _tr(
				"nt.v2.c.hint_network",
				"{ip} AND {mask}\nLast octet: {ip_last} AND {mask_last} = {net_last}",
				{
					"ip": ip_text,
					"mask": mask_text,
					"ip_last": ip_last,
					"mask_last": mask_last,
					"net_last": ip_last & mask_last
				}
			)
			hint_step = 2
		3:
			var cidr: int = int(lv.get("cidr", 24))
			var host_bits: int = 32 - cidr
			var hosts: int = int(lv.get("hosts", 0))
			hint_text = _tr(
				"nt.v2.c.hint_hosts",
				"host_bits = 32 - {cidr} = {hb}. Formula: 2^{hb} - 2 = {hosts}",
				{
					"cidr": cidr,
					"hb": host_bits,
					"hosts": hosts
				}
			)
			hint_step = 3
		_:
			hint_text = _tr("nt.v2.c.no_hint", "No hint available.")

	var hint_panel := _make_semantic_panel("hint")
	hint_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(hint_panel)
	var hint_vbox := VBoxContainer.new()
	hint_vbox.add_theme_constant_override("separation", 4)
	hint_panel.add_child(hint_vbox)
	var hl := _make_label(
		_tr("nt.v2.c.hint_title", "HINT (step {step})", {"step": step}),
		13
	)
	hl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.85))
	hint_vbox.add_child(hl)
	hint_vbox.add_child(_make_label(hint_text, 13))

	await get_tree().process_frame
	content_scroll.scroll_vertical = content_scroll.get_v_scroll_bar().max_value

# 笏笏笏 LEVEL COMPLETE 笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏

func _level_complete() -> void:
	await get_tree().create_timer(0.4).timeout

	if current_idx + 1 >= LEVELS.size():
		_show_complete()
	else:
		_load_level(current_idx + 1)

func _show_complete() -> void:
	if _quest_done:
		return
	_quest_done = true
	GlobalMetrics.finish_quest(QUEST_ID, 100, true)

	for child in content_vbox.get_children():
		child.queue_free()

	var done_panel := _make_semantic_panel("correct")
	done_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(done_panel)
	var done_vbox := VBoxContainer.new()
	done_vbox.add_theme_constant_override("separation", 12)
	done_panel.add_child(done_vbox)
	var done_title := _make_label(_tr("nt.v2.c.quest_done", "INVESTIGATION COMPLETE"), 20)
	done_title.add_theme_color_override("font_color", Color(0.7, 0.85, 0.7))
	done_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	done_vbox.add_child(done_title)
	done_vbox.add_child(_make_label(
		_tr(
			"nt.v2.c.quest_done_body",
			"All {n} levels complete.\nIP addressing analysis - key skill for a network detective.",
			{"n": LEVELS.size()}
		),
		15
	))

	btn_hint.disabled = true
	btn_back.text = _tr("nt.v2.c.btn_exit", "EXIT")

# 笏笏笏 METRICS 笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏

func _register_trial(step_num: int, is_correct: bool) -> void:
	var lv: Dictionary = LEVELS[current_idx]
	var interaction: String = ["MASK_INPUT", "NETWORK_INPUT", "HOSTS_INPUT"][step_num - 1]
	var payload: Dictionary = TrialV2.build(
		QUEST_ID, STAGE_ID, str(lv.get("id", "")), interaction
	)
	payload["is_correct"] = is_correct
	payload["is_fit"] = is_correct and not hint_used
	payload["stability_delta"] = 0.0 if is_correct else -8.0
	payload["elapsed_ms"] = Time.get_ticks_msec() - level_started_ms
	payload["duration"] = float(payload["elapsed_ms"]) / 1000.0
	payload["hint_used"] = hint_used
	payload["step"] = step_num
	payload["level_index"] = current_idx
	payload["cidr"] = lv.get("cidr", 0)
	payload["wrong_count"] = _wrong_counts[step_num - 1]
	payload["trial_seq"] = trial_seq
	trial_seq += 1
	GlobalMetrics.register_trial(payload)

# 笏笏笏 UTILS 笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏

func _byte_to_bin(val: int) -> String:
	var result: String = ""
	for i in range(7, -1, -1):
		result += "1" if (val >> i) & 1 else "0"
		if i == 4:
			result += " "
	return result

# 笏笏笏 LIFECYCLE 笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏笏

func _connect_signals() -> void:
	btn_back.pressed.connect(_on_back_pressed)
	btn_hint.pressed.connect(_on_hint_pressed)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/QuestSelect.tscn")

func _on_stability_changed(new_val: float, _delta: float) -> void:
	stability_bar.value = new_val

func _apply_i18n() -> void:
	title_label.text = _tr("nt.v2.c.title", "NETWORK TRACE | C")
	btn_hint.text = _tr("nt.v2.c.btn_hint", "HINT")
	_on_viewport_size_changed()

func _on_language_changed(_new_language: String) -> void:
	if _quest_done:
		_apply_i18n()
		btn_back.text = _tr("nt.v2.c.btn_exit", "EXIT")
		return
	_load_level(current_idx)
	_apply_i18n()

func _on_viewport_size_changed() -> void:
	var vp: Vector2 = get_viewport_rect().size
	var compact: bool = vp.y <= 420.0 or vp.x <= 500.0
	btn_back.custom_minimum_size = Vector2(48.0 if compact else 80.0, 44.0)
	if _quest_done:
		btn_back.text = _tr("nt.v2.c.btn_exit", "EXIT")
	else:
		btn_back.text = "<" if compact else _tr("nt.v2.c.btn_back", "BACK")

func _ready() -> void:
	_build_ui()
	_connect_signals()
	GlobalMetrics.start_quest(QUEST_ID)
	if not GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.connect(_on_stability_changed)
	if not I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.connect(_on_language_changed)
	if not get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.connect(_on_viewport_size_changed)
	_apply_i18n()
	call_deferred("_on_viewport_size_changed")
	_load_level(0)

func _exit_tree() -> void:
	if get_tree() and get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.disconnect(_on_viewport_size_changed)
	if GlobalMetrics.stability_changed.is_connected(_on_stability_changed):
		GlobalMetrics.stability_changed.disconnect(_on_stability_changed)
	if I18n.language_changed.is_connected(_on_language_changed):
		I18n.language_changed.disconnect(_on_language_changed)
