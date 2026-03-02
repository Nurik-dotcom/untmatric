extends Control

# Ссылки на узлы
@onready var email_input: LineEdit = $CenterContainer/VBoxContainer/EmailInput
@onready var password_input: LineEdit = $CenterContainer/VBoxContainer/PasswordInput
@onready var error_label: Label = $CenterContainer/VBoxContainer/ErrorLabel
@onready var login_button: Button = $CenterContainer/VBoxContainer/ActionButtons/LoginButton
@onready var register_button: Button = $CenterContainer/VBoxContainer/ActionButtons/RegisterButton
@onready var background_shader: ColorRect = $BackgroundShader

func _ready() -> void:
	# Применяем шейдер к фону программно
	var shader_material = ShaderMaterial.new()
	shader_material.shader = load("res://ui/shaders/monitor_crt.gdshader")
	background_shader.material = shader_material
	
	# Подключаем сигналы от нашего синглтона
	FirebaseAuth.auth_finished.connect(_on_auth_finished)
	
	# Подключаем сигналы кнопок
	login_button.pressed.connect(_on_login_button_pressed)
	register_button.pressed.connect(_on_register_button_pressed)
	
	# Звуки при нажатии (используем твой AudioManager)
	if AudioManager and AudioManager.has_method("play"):
		login_button.pressed.connect(func(): AudioManager.play("click"))
		register_button.pressed.connect(func(): AudioManager.play("click"))
	else:
		print("AudioManager or play method not found!")

func _on_login_button_pressed() -> void:
	var email = email_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	
	if email.is_empty() or password.is_empty():
		_display_error("INPUT_REQUIRED")
		return
		
	set_process_input(false) # Блокируем ввод на время запроса
	if FirebaseAuth:
		FirebaseAuth.login(email, password)
	else:
		_display_error("AUTH_SERVICE_UNAVAILABLE")
		set_process_input(true)

func _on_register_button_pressed() -> void:
	var email = email_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	
	if email.is_empty() or password.is_empty():
		_display_error("INPUT_REQUIRED")
		return
		
	set_process_input(false) # Блокируем ввод на время запроса
	if FirebaseAuth:
		FirebaseAuth.register(email, password)
	else:
		_display_error("AUTH_SERVICE_UNAVAILABLE")
		set_process_input(true)

func _on_auth_finished(success: bool, result) -> void:
	set_process_input(true)
	
	if success:
		# Сохраняем UID в GlobalMetrics
		if GlobalMetrics:
			GlobalMetrics.user_id = result.localId
			
			# Извлекаем никнейм из email (часть до @)
			var email = result.email if result.has("email") else email_input.text.strip_edges()
			var at_pos = email.find("@")
			if at_pos > 0:
				GlobalMetrics.user_nickname = email.substr(0, at_pos)
			else:
				GlobalMetrics.user_nickname = email
		
		# Переходим в главное меню
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	else:
		_display_error(str(result))

func _display_error(msg: String) -> void:
	error_label.text = "ERROR: " + msg
	# Используем твой звук ошибки
	if AudioManager and AudioManager.has_method("play"):
		AudioManager.play("error")
