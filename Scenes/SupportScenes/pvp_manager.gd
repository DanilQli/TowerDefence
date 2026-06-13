# Scenes\SupportScenes\pvp_manager.gd
extends Node

signal match_found(room_id: String, player_index: int, opponent_id: String)
signal search_failed()
signal game_state_updated(state: Dictionary)
signal game_started(wave_data: Array)
signal game_finished(winner_id: String)

# АДРЕС СЕРВЕРА (МЕНЯТЬ ТУТ)
# Для тестов на одном ПК: "ws://127.0.0.1:8765"
# Для игры по сети: "ws://ВАШ_NGROK_АДРЕС"
const SOCKET_URL = "ws://127.0.0.1:8765"

var socket: WebSocketPeer
var connected := false
var player_id := "" # Назначается сервером неявно, нам важен только индекс

func _ready():
	socket = WebSocketPeer.new()

func _process(_delta):
	socket.poll()
	var state = socket.get_ready_state()
	
	if state == WebSocketPeer.STATE_OPEN:
		if not connected:
			connected = true
			print("🟢 Подключено к серверу PvP")
		
		while socket.get_available_packet_count():
			var packet = socket.get_packet()
			var packet_text = packet.get_string_from_utf8()
			var data = JSON.parse_string(packet_text)
			if data:
				_handle_server_message(data)
				
	elif state == WebSocketPeer.STATE_CLOSED:
		if connected:
			connected = false
			print("🔴 Отключено от сервера. Код: ", socket.get_close_code())
			emit_signal("search_failed")

func start_search():
	print("🔍 Подключение к сокету...")
	var err = socket.connect_to_url(SOCKET_URL)
	if err != OK:
		print("❌ Ошибка подключения: ", err)
		emit_signal("search_failed")
		return
	
	# Ждем соединения, чтобы отправить запрос на поиск
	# (в реальном проекте лучше через сигнал, но тут сделаем через таймер для простоты)
	await get_tree().create_timer(0.5).timeout
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_send({"type": "find_match"})
	else:
		# Если не успели подключиться, пробуем еще раз чуть позже в _process
		# Но лучше просто отправить запрос сразу как state станет OPEN (сделано через флаг connected)
		call_deferred("_send_delayed_search")

func _send_delayed_search():
	# Костыль для надежности, если соединение идет долго
	var attempts = 0
	while socket.get_ready_state() != WebSocketPeer.STATE_OPEN and attempts < 10:
		await get_tree().create_timer(0.5).timeout
		attempts += 1
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_send({"type": "find_match"})

func set_ready():
	_send({
		"type": "ready",
		"room_id": PvPSession.room_id
	})

func send_game_state(hp: int, money: float, wave_index: int, towers: Array, enemies: Array):
	if not connected: return
	_send({
		"type": "update_state",
		"room_id": PvPSession.room_id,
		"hp": hp,
		"money": money,
		"wave": wave_index,
		"towers": towers,
		"enemies": enemies,
		"effects": effects 
	})

# --- Обработка входящих сообщений ---
func _handle_server_message(data: Dictionary):
	var type = data.get("type")
	
	match type:
		"match_found":
			print("✅ Матч найден!")
			# Обновляем сессию
			PvPSession.player_id = "me" # Для локальной логики
			PvPSession.room_id = data.room_id
			PvPSession.player_index = int(data.player_index)
			PvPSession.opponent_id = data.opponent_id
			emit_signal("match_found", data.room_id, data.player_index, data.opponent_id)
			
		"game_start":
			print("🚀 Старт игры!")
			emit_signal("game_started", data.waves)
			
		"opponent_state":
			print("Enemy progress: ", data.get("enemies", [])[0]["progress"] if data.get("enemies") else "None") 
			emit_signal("game_state_updated", data)
			
		"game_finished":
			print("🏆 Игра окончена. Победитель: ", data.winner_id)
			emit_signal("game_finished", data.winner_id)

func _send(data: Dictionary):
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		socket.send_text(JSON.stringify(data))
