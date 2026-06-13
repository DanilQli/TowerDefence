# Controllers/UIController.gd
extends Node

var main_scene
var list_activity_turret: Array = []
var is_player := true

# Скрипт для драга (внутренний класс или прелоад)
# Мы создадим его динамически, чтобы не плодить файлы, если не хочется.
# Но лучше вынести в отдельный файл, если он сложный.
# В данном случае, я использую подход с заменой скрипта.

func initialize(scene, flag=true):
	main_scene = scene
	is_player = flag
	
	# Подключаем управление игрой только если это игрок
	if is_player and main_scene.has_node("UI/HUD/GameControl/PausePlay"):
		var pause_button = main_scene.get_node("UI/HUD/GameControl/PausePlay")
		var speed_button = main_scene.get_node("UI/HUD/GameControl/SpeedUp")
		
		# Отключаем старые соединения если были
		if pause_button.pressed.is_connected(_on_pause_play_pressed):
			pause_button.pressed.disconnect(_on_pause_play_pressed)
		if speed_button.pressed.is_connected(_on_speed_up_pressed):
			speed_button.pressed.disconnect(_on_speed_up_pressed)

		pause_button.pressed.connect(_on_pause_play_pressed)
		speed_button.pressed.connect(_on_speed_up_pressed)

	# Сигнал денег
	if not GameSession.money_in_game_session_changed.is_connected(_on_money_changed):
		GameSession.money_in_game_session_changed.connect(_on_money_changed)

	GameSession.current_money_in_game_session = 500 # Дефолт для старта

	# Собираем доступные башни
	list_activity_turret.clear()
	for i in range(len(GameConstants.DATA_TOWER)):
		var turret_id = "Turret_" + str(i + 1) + "T1"
		# Проверяем, есть ли башня в DataManager и активна ли она (выбрана в инвентаре)
		if DataManager.tower_data.has(turret_id) and DataManager.tower_data[turret_id]["activity"]:
			list_activity_turret.append(i + 1)
	
	# Настройка кнопок постройки
	if is_player: 
		for i in range(list_activity_turret.size()):
			var index = i + 1 # Индекс кнопки UI (1, 2, 3, 4)
			var tower_index = list_activity_turret[i] # ID башни (реальный)
			var turret_name = "Turret_" + str(tower_index)

			var icon_path = "UI/HUD/BuldBar/Tower_" + str(index) + "/Icon"
			var button_path = "UI/HUD/BuldBar/Tower_" + str(index)

			if main_scene.has_node(icon_path):
				main_scene.get_node(icon_path).texture = load("res://Assets/Props/towerDefense_tile_turret_" + str(tower_index) + ".png")

			if main_scene.has_node(button_path):
				var button = main_scene.get_node(button_path)
				
				# --- ВНЕДРЕНИЕ DRAG & DROP ---
				# Мы заменяем скрипт кнопки на DraggableButton
				# Но чтобы не терять ссылки, лучше просто привязать сигналы button_down/up,
				# Либо, если мы хотим использовать _get_drag_data (нативный драг),
				# нужно чтобы кнопка имела скрипт с этим методом.
				
				# Вариант с подменой скрипта:
				var draggable_script = load("res://Scenes/SupportScenes/DraggableButton.gd")
				if draggable_script:
					button.set_script(draggable_script)
					# Передаем данные в кнопку
					button.turret_type = turret_name
					button.turret_index = tower_index
					button.main_scene = main_scene
					# ВАЖНО: Разрешаем обработку событий мыши
					button.mouse_filter = Control.MOUSE_FILTER_STOP 
				else:
					print("❌ Ошибка: DraggableButton.gd не найден!")
				# -----------------------------

	_on_money_changed()

# Эти методы больше не нужны, если используется DraggableButton.gd,
# но оставим их на всякий случай или для ПК логики (если там не драг)
func start_drag_build(type, index):
	main_scene.build_controller.initiate_build_mode(type, index)
	main_scene.build_controller.update_tower_preview()

func finish_drag_build():
	if main_scene.build_controller.build_mode:
		main_scene.build_controller.verify_and_build()
		main_scene.build_controller.cancel_build_mode()
		
func _on_pause_play_pressed():
	if not is_player: return
	if main_scene.build_controller.build_mode:
		main_scene.build_controller.cancel_build_mode()

	if GameSession.current_wave == 0:
		main_scene.wave_controller.start_next_wave()
	else:
		var paused = main_scene.get_tree().paused
		main_scene.get_tree().paused = not paused
		GameSession.speed_game = GameConstants.SPEED_NORMAL_GAME_SESSION if paused else 0.0

func _on_speed_up_pressed():
	if not is_player: return
	if GameSession.current_wave == 0:
		main_scene.wave_controller.start_next_wave()
		return

	if GameSession.speed_game == GameConstants.SPEED_UP_GAME_SESSION:
		GameSession.speed_game = GameConstants.SPEED_NORMAL_GAME_SESSION
	else:
		GameSession.speed_game = GameConstants.SPEED_UP_GAME_SESSION

	Engine.set_time_scale(GameSession.speed_game)

func _on_money_changed():
	if main_scene.has_node("UI/HUD/InfoBar/H/Money"):
		main_scene.get_node("UI/HUD/InfoBar/H/Money").text = str(int(GameSession.current_money_in_game_session))

	if is_player:
		for i in range(list_activity_turret.size()):
			var index = i + 1
			var tower_idx = list_activity_turret[i]
			
			var cost = GameConstants.DATA_TOWER[tower_idx - 1].cost_in_session
			# Учет мастерства
			if DataManager.data["Turrets"].has(DataManager.keys[tower_idx - 1]):
				if DataManager.data["Turrets"][DataManager.keys[tower_idx - 1]].mastery_lvl >= 2:
					cost = MathUtils.round_to_dec(cost * (1 - GameConstants.CARDS_MASTERY_MODIFICATOR_LVL[2][0]), 1)
			
			var cost_label_path = "UI/HUD/BuldBar/Tower_" + str(index) + "/Color/Cost"
			var color_rect_path = "UI/HUD/BuldBar/Tower_" + str(index) + "/Color"

			if main_scene.has_node(cost_label_path):
				main_scene.get_node(cost_label_path).text = str(cost)

			if main_scene.has_node(color_rect_path):
				var color_rect = main_scene.get_node(color_rect_path)
				if GameSession.current_money_in_game_session < cost:
					color_rect.color = Color("ff0000") # Красный
				else:
					color_rect.color = Color("008000") # Зеленый

func title_show(id_ui: String, id: String):
	# Логика показа меню характеристик (оставляем как было, просто проверка)
	var node_mouse_entered = load("res://Scenes/SupportScenes/TurretMenu.tscn").instantiate()
	main_scene.add_child(node_mouse_entered)
	var tower_path = "UI/HUD/BuldBar/Tower_" + id_ui
	
	if main_scene.has_node(tower_path):
		var tower_pos = main_scene.get_node(tower_path).global_position
		node_mouse_entered.global_position = tower_pos + Vector2(90, 0) # Смещение вправо
		node_mouse_entered.setup(int(id) - 1)
		UiManager.list_open_menu_turrets.append(node_mouse_entered)

func title_hide():
	for menu in UiManager.list_open_menu_turrets:
		if is_instance_valid(menu):
			menu.queue_free()
	UiManager.list_open_menu_turrets.clear()
