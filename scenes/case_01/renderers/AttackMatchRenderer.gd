extends PanelContainer

signal all_rounds_complete

var _level_data: Dictionary = {}
var _controller: Node = null
var _rounds: Array = []
var _answers: Array = []
var _round_index: int = 0
var _selected_attack: String = ""
var _selected_defense: String = ""
var _awaiting_next: bool = false

@onready var progress_label: Label = $VBox/ProgressLabel
@onready var scenario_label: RichTextLabel = $VBox/ScenarioLabel
@onready var attack_title: Label = $VBox/AttackTitle
@onready var attack_grid: GridContainer = $VBox/AttackGrid
@onready var defense_title: Label = $VBox/DefenseTitle
@onready var defense_grid: GridContainer = $VBox/DefenseGrid
@onready var btn_confirm: Button = $VBox/BtnConfirm
@onready var explain_label: RichTextLabel = $VBox/ExplainLabel

func _ready() -> void:
	btn_confirm.pressed.connect(_on_confirm_pressed)

func setup(level_data: Dictionary, controller: Node) -> void:
	_level_data = level_data.duplicate(true)
	_controller = controller
	_rounds = _level_data.get("rounds", []) as Array
	_round_index = 0
	_answers.clear()
	_awaiting_next = false
	explain_label.text = ""
	_render_round()

func apply_i18n() -> void:
	_render_round()

func reset() -> void:
	_round_index = 0
	_answers.clear()
	_awaiting_next = false
	explain_label.text = ""
	_render_round()

func get_answers() -> Variant:
	return _answers.duplicate(true)

func show_result(result: Dictionary) -> void:
	explain_label.text = "[b]%s[/b] %d/%d" % [str(result.get("verdict_code", "")), int(result.get("correct_count", 0)), int(result.get("total", 0))]

func _render_round() -> void:
	for child in attack_grid.get_children():
		child.queue_free()
	for child in defense_grid.get_children():
		child.queue_free()

	if _rounds.is_empty():
		progress_label.text = "0/0"
		scenario_label.text = ""
		btn_confirm.disabled = true
		return

	var idx: int = clampi(_round_index, 0, _rounds.size() - 1)
	var round_data: Dictionary = _rounds[idx] as Dictionary
	progress_label.text = "%d/%d" % [idx + 1, _rounds.size()]
	scenario_label.text = _resolve_text(round_data, "scenario")
	attack_title.text = _resolve_text(round_data, "question1")
	defense_title.text = _resolve_text(round_data, "question2")
	_selected_attack = ""
	_selected_defense = ""
	_awaiting_next = false
	btn_confirm.text = I18n.tr_key("resus.btn.confirm", {"default": "CONFIRM"})
	btn_confirm.disabled = true
	explain_label.text = ""

	for option_v in round_data.get("attack_options", []) as Array:
		if typeof(option_v) != TYPE_DICTIONARY:
			continue
		var option_data: Dictionary = option_v as Dictionary
		var option_id: String = str(option_data.get("id", ""))
		var button: Button = Button.new()
		button.text = _resolve_option(option_data)
		button.custom_minimum_size = Vector2(0, 48)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_attack_selected.bind(option_id, button))
		attack_grid.add_child(button)

	for option_v in round_data.get("defense_options", []) as Array:
		if typeof(option_v) != TYPE_DICTIONARY:
			continue
		var option_data: Dictionary = option_v as Dictionary
		var option_id: String = str(option_data.get("id", ""))
		var button: Button = Button.new()
		button.text = _resolve_option(option_data)
		button.custom_minimum_size = Vector2(0, 48)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_defense_selected.bind(option_id, button))
		defense_grid.add_child(button)

func _on_attack_selected(option_id: String, pressed_button: Button) -> void:
	if _awaiting_next:
		return
	var previous_attack: String = _selected_attack
	_selected_attack = option_id
	for child in attack_grid.get_children():
		if child is Button:
			(child as Button).modulate = Color(1, 1, 1, 1)
	pressed_button.modulate = Color(1.08, 1.08, 1.08, 1.0)
	_notify_controller("attack_selected", {
		"round": _round_index,
		"option_id": option_id,
		"previous": previous_attack
	})
	_update_confirm_state()

func _on_defense_selected(option_id: String, pressed_button: Button) -> void:
	if _awaiting_next:
		return
	var previous_defense: String = _selected_defense
	_selected_defense = option_id
	for child in defense_grid.get_children():
		if child is Button:
			(child as Button).modulate = Color(1, 1, 1, 1)
	pressed_button.modulate = Color(1.08, 1.08, 1.08, 1.0)
	_notify_controller("defense_selected", {
		"round": _round_index,
		"option_id": option_id,
		"previous": previous_defense
	})
	_update_confirm_state()

func _update_confirm_state() -> void:
	if _awaiting_next:
		btn_confirm.disabled = false
		return
	btn_confirm.disabled = _selected_attack == "" or _selected_defense == ""

func _on_confirm_pressed() -> void:
	if _rounds.is_empty():
		return

	if _awaiting_next:
		_awaiting_next = false
		if _round_index < _rounds.size() - 1:
			_round_index += 1
			_render_round()
		else:
			all_rounds_complete.emit()
		return

	if _selected_attack == "" or _selected_defense == "":
		return

	var idx: int = clampi(_round_index, 0, _rounds.size() - 1)
	if _answers.size() <= idx:
		_answers.resize(idx + 1)
	_answers[idx] = {"attack": _selected_attack, "defense": _selected_defense}

	var round_data: Dictionary = _rounds[idx] as Dictionary
	_notify_controller("scan_started", {"round": idx})
	var attack_ok: bool = _is_option_correct(round_data.get("attack_options", []) as Array, _selected_attack)
	var defense_ok: bool = _is_option_correct(round_data.get("defense_options", []) as Array, _selected_defense)
	var round_ok: bool = attack_ok and defense_ok
	var error_type: String = "SUCCESS"
	if not defense_ok:
		error_type = "WRONG_DEFENSE"
	elif not attack_ok:
		error_type = "THREAT_MISMATCH"
	_highlight_grid(attack_grid, round_data.get("attack_options", []) as Array, _selected_attack, attack_ok)
	_highlight_grid(defense_grid, round_data.get("defense_options", []) as Array, _selected_defense, defense_ok)
	explain_label.text = _resolve_text(round_data, "explain")
	_notify_controller("round_checked", {
		"round": idx,
		"attack": _selected_attack,
		"defense": _selected_defense,
		"attack_ok": attack_ok,
		"defense_ok": defense_ok,
		"round_ok": round_ok,
		"error_type": error_type
	})

	_set_grids_disabled(true)
	_awaiting_next = true
	btn_confirm.disabled = false
	btn_confirm.text = I18n.tr_key("resus.btn.next_round", {"default": "NEXT ->"}) if _round_index < _rounds.size() - 1 else I18n.tr_key("resus.btn.finish_quiz", {"default": "FINISH"})

func _highlight_grid(grid: GridContainer, options: Array, selected_id: String, selected_is_correct: bool) -> void:
	var idx: int = 0
	for child in grid.get_children():
		if not (child is Button):
			continue
		var button: Button = child as Button
		button.modulate = Color(1, 1, 1, 1)
		button.disabled = true
		if idx < options.size() and typeof(options[idx]) == TYPE_DICTIONARY:
			var option_data: Dictionary = options[idx] as Dictionary
			var option_id: String = str(option_data.get("id", ""))
			var option_ok: bool = bool(option_data.get("is_correct", false))
			if option_id == selected_id:
				button.modulate = Color(0.7, 1.0, 0.7, 1.0) if selected_is_correct else Color(1.0, 0.7, 0.7, 1.0)
			elif option_ok and not selected_is_correct:
				button.modulate = Color(0.8, 1.0, 0.8, 0.65)
		idx += 1

func _set_grids_disabled(disabled: bool) -> void:
	for child in attack_grid.get_children():
		if child is Button:
			(child as Button).disabled = disabled
	for child in defense_grid.get_children():
		if child is Button:
			(child as Button).disabled = disabled

func _is_option_correct(options: Array, option_id: String) -> bool:
	for option_v in options:
		if typeof(option_v) != TYPE_DICTIONARY:
			continue
		var option_data: Dictionary = option_v as Dictionary
		if str(option_data.get("id", "")).strip_edges() == option_id:
			return bool(option_data.get("is_correct", false))
	return false

func _resolve_text(round_data: Dictionary, field: String) -> String:
	var key: String = str(round_data.get("%s_key" % field, ""))
	var fallback: String = str(round_data.get(field, ""))
	if key != "":
		return I18n.tr_key(key, {"default": fallback})
	return fallback

func _resolve_option(option_data: Dictionary) -> String:
	var key: String = str(option_data.get("label_key", ""))
	var fallback: String = str(option_data.get("label", option_data.get("id", "")))
	if key != "":
		return I18n.tr_key(key, {"default": fallback})
	return fallback

func _notify_controller(event_name: String, payload: Dictionary = {}) -> void:
	if _controller != null and _controller.has_method("on_renderer_event"):
		_controller.call("on_renderer_event", event_name, payload)
