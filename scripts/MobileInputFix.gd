extends LineEdit

@export var prompt_title: String = "Введите текст:"

func _ready() -> void:
	if not focus_entered.is_connected(_on_focus_entered):
		focus_entered.connect(_on_focus_entered)

func _on_focus_entered() -> void:
	if not OS.has_feature("web"):
		return
	if not Engine.has_singleton("JavaScriptBridge"):
		return

	# Drop focus first to avoid Safari iOS auto-zoom on LineEdit focus.
	release_focus()

	var js_title := JSON.stringify(prompt_title)
	var js_default := JSON.stringify(text)
	var js_code := "prompt(%s, %s);" % [js_title, js_default]
	var user_input: Variant = JavaScriptBridge.eval(js_code)

	if user_input != null and str(user_input) != "null":
		text = str(user_input)
		text_changed.emit(text)
