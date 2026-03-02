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
	add_child(http)
	http.request_completed.connect(func(r, c, h, b): _on_request_completed(r, c, h, b, http))
	
	var body = JSON.stringify({"email": email, "password": password, "returnSecureToken": true})
	http.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)

func _on_request_completed(result, response_code, headers, body, http_node):
	var response = JSON.parse_string(body.get_string_from_utf8())
	if response_code == 200:
		# Сохраняем UID пользователя, чтобы знать, чью статистику писать
		GlobalMetrics.user_id = response.localId 
		auth_finished.emit(true, response)
	else:
		auth_finished.emit(false, response.error.message)
	http_node.queue_free()