extends Node

const API_KEY = "AIzaSyBm0_J8Bkcohx4F1Ad_ISwmWMd2t0U8PMw"
const SIGN_UP_URL = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=" + API_KEY
const SIGN_IN_URL = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=" + API_KEY

signal auth_finished(success, result)

func register(email, password):
	_send_request(SIGN_UP_URL, email, password)

func login(email, password):
	_send_request(SIGN_IN_URL, email, password)

func _send_request(url, email, password):
	var http = HTTPRequest.new()
	http.accept_gzip = false
	add_child(http)
	http.request_completed.connect(func(r, c, h, b): _on_request_completed(r, c, h, b, http))
	
	var body = JSON.stringify({"email": email, "password": password, "returnSecureToken": true})
	http.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)

func _on_request_completed(result, response_code, headers, body, http_node):
	# 1. Проверяем, убил ли браузер наш запрос (0 = ответа от сервера не было вообще)
	if response_code == 0:
		auth_finished.emit(false, "Network/Browser Block. Result code: " + str(result))
		http_node.queue_free()
		return

	# 2. Если ответ есть, пытаемся его прочитать
	var response_text = body.get_string_from_utf8()
	var response = JSON.parse_string(response_text)
	
	if response_code == 200 and response != null:
		GlobalMetrics.user_id = response.localId 
		GlobalMetrics.current_session_id = ""
		
		if response.has("email"):
			GlobalMetrics.user_nickname = response.email.split("@")[0]
			GlobalMetrics.user_email = response.email
		
		if response.has("idToken"):
			GlobalMetrics.auth_token = response.idToken

		if GlobalMetrics.has_method("record_login_session"):
			GlobalMetrics.record_login_session()
			
		auth_finished.emit(true, response)
	else:
		# Читаем чистый ответ сервера
		var response_texst = body.get_string_from_utf8()
		
		# ПРИНУДИТЕЛЬНО выводим его в твой красный ErrorLabel
		auth_finished.emit(false, "ОШИБКА 400: " + response_texst)
		
	http_node.queue_free()
