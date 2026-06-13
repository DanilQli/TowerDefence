# Systems/NetworkManager.gd
# Systems/NetworkManager.gd
extends Node

signal match_found(room_id: String, player_index: int, opponent_id: String)
signal search_failed()
signal game_state_updated(state: Dictionary)
signal game_started(wave_data: Array)
signal game_finished(winner_id: String)

# const SOCKET_URL = "ws://127.0.0.1:8765"
const SOCKET_URL = "wss://virulently-authigenic-manuel.ngrok-free.dev"

var socket: WebSocketPeer
var connected := false
var is_searching := false # Флаг, что мы хотим найти игру

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	socket = WebSocketPeer.new()

func _process(_delta):
	socket.poll()
	var state = socket.get_ready_state()
	
	if state == WebSocketPeer.STATE_OPEN:
		if not connected:
			connected = true
			print("🟢 [Network] Соединение установлено!")
			
			# Если мы нажали "Искать игру" до подключения, отправляем запрос сейчас
			if is_searching:
				print("📤 [Network] Отправляю запрос на поиск матча...")
				_send({"type": "find_match"})
				is_searching = false # Сбрасываем флаг, чтобы не отправить дважды
		
		while socket.get_available_packet_count():
			var packet = socket.get_packet()
			var packet_text = packet.get_string_from_utf8()
			var data = JSON.parse_string(packet_text)
			if data:
				_handle_server_message(data)
				
	elif state == WebSocketPeer.STATE_CLOSED:
		if connected:
			connected = false
			var code = socket.get_close_code()
			var reason = socket.get_close_reason()
			print("🔴 [Network] Отключено. Код: %s, Причина: %s" % [code, reason])
			emit_signal("search_failed")

func connect_to_server():
	if socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		print("🔄 [Network] Подключаюсь к ", SOCKET_URL)
		# ВАЖНО: Добавляем заголовок для обхода защиты Ngrok
		socket.set_handshake_headers(["ngrok-skip-browser-warning: true"])
		var err = socket.connect_to_url(SOCKET_URL)
		if err != OK:
			print("❌ [Network] Ошибка вызова connect_to_url: ", err)
			emit_signal("search_failed")

func start_search():
	print("🔍 [Network] Начат поиск игры...")
	is_searching = true
	
	# Если уже подключены - отправляем сразу
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		print("📤 [Network] Сокет уже открыт, отправляю find_match")
		_send({"type": "find_match"})
		is_searching = false
	else:
		# Если нет - подключаемся, запрос уйдет в _process
		connect_to_server()

func set_ready():
	print("✅ [Network] Игрок готов к бою")
	_send({
		"type": "ready",
		"room_id": PvPSession.room_id
	})

func send_game_state(hp: int, money: float, wave_index: int, towers: Array, enemies: Array, effects: Array = []):
	# Логируем только если есть эффекты, чтобы не спамить в консоль
	print({
		"type": "update_state",
		"room_id": PvPSession.room_id,
		"hp": hp,
		"money": money,
		"wave": wave_index,
		"towers": towers,
		"enemies": enemies,
		"effects": effects 
	})
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

func _handle_server_message(data: Dictionary):
	var type = data.get("type")
	
	if type == "opponent_state" and data.has("effects") and data["effects"].size() > 0:
		print("📥 [Network] Пришли эффекты от соперника: ", data["effects"])
	
	match type:
		"match_found":
			print("⚔️ [Network] Матч найден! Комната: ", data.room_id)
			PvPSession.room_id = data.room_id
			PvPSession.player_index = int(data.player_index)
			PvPSession.opponent_id = data.opponent_id
			PvPSession.player_id = data.get("my_id") 
			emit_signal("match_found", data.room_id, data.player_index, data.opponent_id)
			
		"game_start":
			print("🚀 [Network] Старт игры!")
			emit_signal("game_started", data.waves)
			
		"opponent_state":
			emit_signal("game_state_updated", data)
			
		"game_finished":
			print("🏆 [Network] Игра окончена. Победитель: ", data.winner_id)
			emit_signal("game_finished", data.winner_id)

func _send(data: Dictionary):
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		socket.send_text(JSON.stringify(data))
	else:
		print("⚠️ [Network] Попытка отправить данные в закрытый сокет")
