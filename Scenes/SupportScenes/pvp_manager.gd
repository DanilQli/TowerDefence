# PvPMatchmaker.gd — Godot 4.4, с логами и таймаутом поиска 10 сек
extends Node

signal match_found(room_id: String, player_index: int)
signal search_failed()
signal opponent_left()

const SERVER_URL = "https://lobste.pythonanywhere.com"

# HTTP методы для Godot 4.4
const METHOD_GET = 0
const METHOD_POST = 3
const METHOD_PUT = 5
const METHOD_DELETE = 4

var http: HTTPRequest
var searching := false
var room_id := ""
var player_index := 0
var last_ping := 0.0
var last_path := ""
var search_start_time := 0.0
var max_search_time := 10.0  # поиск до 10 секунд

func _ready():
	http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_request_completed)

func start_search():
	if searching:
		return
	
	searching = true
	search_start_time = Time.get_ticks_msec() / 1000.0  # секунды
	
	print("🔍 Начинаем поиск соперника...")
	_create_or_join_room()

func _create_or_join_room():
	var body = JSON.stringify({})
	_send_request("/find_match", body, METHOD_POST)

func _send_request(path: String, body: String, method: int):
	last_path = path
	var headers = PackedStringArray()
	var error = http.request(SERVER_URL + path, headers, method, body)
	if error != OK:
		push_error("HTTP Request failed: " + str(error))

func _on_request_completed(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		print("❌ Ошибка запроса: ", result, response_code)
		_check_search_timeout()
		return

	var json_str = body.get_string_from_utf8()
	print("📡 Ответ сервера: ", json_str)  # ← ЗДЕСЬ ВЫВОД ОТВЕТА СЕРВЕРА

	var json = JSON.parse_string(json_str)
	if not json:
		push_error("Invalid JSON")
		_check_search_timeout()
		return

	if "/find_match" in last_path:
		if json.has("room_id") and json.has("player_index"):
			room_id = str(json.room_id)
			player_index = int(json.player_index)
			searching = false
			print("✅ Соперник найден! Room ID: %s, Player Index: %d" % [room_id, player_index])
			emit_signal("match_found", room_id, player_index)
		else:
			_check_search_timeout()
			if searching:
				await get_tree().create_timer(1.5).timeout  # ждём 1.5 сек перед повтором
				_create_or_join_room()

func _check_search_timeout():
	if not searching:
		return
	
	var elapsed = (Time.get_ticks_msec() / 1000.0) - search_start_time
	if elapsed >= max_search_time:
		print("⏰ Поиск превысил 10 секунд. Останавливаем.")
		searching = false
		emit_signal("search_failed")

func _process(delta):
	if room_id != "" and Time.get_ticks_msec() - last_ping > 3000:
		last_ping = Time.get_ticks_msec()
		_send_heartbeat()

func _send_heartbeat():
	var body = JSON.stringify({"room_id": room_id})
	_send_request("/heartbeat", body, METHOD_POST)
