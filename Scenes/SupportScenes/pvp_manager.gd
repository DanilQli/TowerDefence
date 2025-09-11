# pvp_manager.gd — исправленная версия для PythonAnywhere Free
extends Node

signal match_found(room_id: String, player_index: int, opponent_id: String)
signal search_failed()
signal game_state_updated(state: Dictionary)
signal game_started(wave_data: Array)

const SERVER_URL = "https://lobste.pythonanywhere.com"

const METHOD_GET = 0
const METHOD_POST = 3

var http: HTTPRequest
var searching := false
var room_id := ""
var player_id := ""
var player_index := 0
var opponent_id := ""
var last_sync := 0.0
var last_path := ""
var search_start_time := 0.0
var max_search_time := 10.0
var retry_timer := 1.5

func _ready():
	http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_request_completed)
	
	player_id = str(randi()) + "_" + str(Time.get_ticks_msec())

func start_search():
	if searching: return
	
	searching = true
	search_start_time = Time.get_ticks_msec() / 1000.0
	print("🔍 Данил ищет соперника...")
	
	_send_find_match_request()

func _send_find_match_request():
	var path = "/find_match?player_id=" + player_id
	_send_request(path, "", METHOD_GET)

func _send_request(path: String, body: String, method: int):
	last_path = path
	var headers = PackedStringArray(["Content-Type: application/json"])
	
	var error
	if method == METHOD_GET:
		error = http.request(SERVER_URL + path, headers, method)
	else:
		error = http.request(SERVER_URL + path, headers, method, body)
	
	if error != OK:
		push_error("HTTP Request failed: " + str(error))

func _on_request_completed(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		print("❌ Ошибка запроса: ", result, response_code)
		_schedule_retry()
		return

	var json_str = body.get_string_from_utf8()
	print("📡 Ответ сервера: ", json_str)

	if json_str.begins_with("<!doctype"):
		print("⚠️ Сервер вернул HTML, а не JSON.")
		_schedule_retry()
		return

	var json = JSON.parse_string(json_str)
	if not json:
		push_error("Invalid JSON")
		_schedule_retry()
		return

	if "/find_match" in last_path:
		if json.has("room_id") and json.has("player_index"):
			room_id = str(json.room_id)
			player_index = int(json.player_index)
			opponent_id = str(json.opponent_id)
			searching = false
			print("✅ Данил найден! Комната: %s, Индекс: %d, Ты: %s, Соперник: %s" % [room_id, player_index, player_id, opponent_id])
			emit_signal("match_found", room_id, player_index, opponent_id)
		else:
			_check_search_timeout()
			if searching:
				_schedule_retry()

	elif "/get_room_state" in last_path:
		emit_signal("game_state_updated", json)
		if json.has("started") and json.started:
			emit_signal("game_started", json.wave_data)

	elif "/set_ready" in last_path:
		if json.has("started") and json.started:
			emit_signal("game_started", json.wave_data)

func _schedule_retry():
	if not searching: return
	await get_tree().create_timer(retry_timer).timeout
	_send_find_match_request()

func _check_search_timeout():
	if not searching: return
	var elapsed = (Time.get_ticks_msec() / 1000.0) - search_start_time
	if elapsed >= max_search_time:
		print("⏰ Данил устал ждать. Поиск остановлен.")
		searching = false
		emit_signal("search_failed")

func start_sync():
	if room_id == "": return
	set_process(true)

func stop_sync():
	set_process(false)

func _process(delta):
	if room_id != "" and Time.get_ticks_msec() - last_sync > 1000:
		last_sync = Time.get_ticks_msec()
		_send_request("/get_room_state?room_id=" + room_id, "", METHOD_GET)

func send_game_state(hp: int, money: float, wave_index: int, towers: Array):
	if room_id == "": return
	var body = JSON.stringify({
		"room_id": room_id, "player_id": player_id, "hp": hp,
		"money": money, "wave": wave_index, "towers": towers
	})
	_send_request("/update_game_state", body, METHOD_POST)

func set_ready():
	if room_id == "": return
	_send_request("/set_ready?room_id=" + room_id + "&player_id=" + player_id, "", METHOD_GET)
