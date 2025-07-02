extends Node

var main_scene: Node2D
var list_activity_turret: Array = []

func initialize(scene: Node2D):
	main_scene = scene

	var pause_button = main_scene.get_node("UI/HUD/GameControl/PausePlay")
	var speed_button = main_scene.get_node("UI/HUD/GameControl/SpeedUp")

	pause_button.pressed.connect(_on_pause_play_pressed)
	speed_button.pressed.connect(_on_speed_up_pressed)

	GameSession.money_in_game_session_changed.connect(_on_money_changed)

	# Установка денег
	GameSession.current_money_in_game_session = GameConstants.MONEY_BEGIN[GameSession.current_level]

	# Получение доступных турелей
	for i in range(GameConstants.NUMBER_TURRET):
		var turret_id = "Turret_" + str(i + 1) + "T1"
		if DataManager.tower_data.has(turret_id) and DataManager.tower_data[turret_id]["activity"]:
			list_activity_turret.append(i + 1)

	# Подключаем кнопки постройки и наведения
	for i in range(list_activity_turret.size()):
		var index = i + 1
		var tower_index = list_activity_turret[i]
		var turret_name = "Turret_" + str(tower_index)

		var icon_path = "UI/HUD/BuldBar/Tower_" + str(index) + "/Icon"
		var button_path = "UI/HUD/BuldBar/Tower_" + str(index)

		main_scene.get_node(icon_path).texture = load("res://Assets/Props/towerDefense_tile_turret_" + str(tower_index) + ".png")

		var button = main_scene.get_node(button_path)
		button.pressed.connect(Callable(main_scene.build_controller, "initiate_build_mode").bind(turret_name))
		button.mouse_entered.connect(Callable(self, "title_show").bind(str(index), str(tower_index)))
		button.mouse_exited.connect(Callable(self, "title_hide"))
		main_scene.get_node(button_path).mouse_entered.connect(
			title_show.bind(str(index), str(tower_index))
		)
		main_scene.get_node(button_path).mouse_exited.connect(title_hide)

	# Обновим стоимостные элементы в UI
	_on_money_changed()

func _on_pause_play_pressed():
	if main_scene.build_controller.build_mode:
		main_scene.build_controller.cancel_build_mode()

	if GameSession.current_wave == 0:
		main_scene.wave_controller.start_next_wave()
	else:
		var paused = get_tree().paused
		get_tree().paused = not paused
		if paused:
			GameSession.speed_game = 1.0
		else:
			GameSession.speed_game = 0.0

func _on_speed_up_pressed():
	if GameSession.current_wave == 0:
		main_scene.wave_controller.start_next_wave()
		return

	if GameSession.speed_game == 4.0:
		GameSession.speed_game = 1.0
	else:
		GameSession.speed_game = 4.0

	Engine.set_time_scale(GameSession.speed_game)

func _on_money_changed():
	main_scene.get_node("UI/HUD/InfoBar/H/Money").text = str(GameSession.current_money_in_game_session)

	for i in range(list_activity_turret.size()):
		var index = i + 1
		var turret_id = "Turret_" + str(list_activity_turret[i]) + "T1"

		var cost_label = main_scene.get_node("UI/HUD/BuldBar/Tower_" + str(index) + "/Color/Cost")
		cost_label.text = str(DataManager.tower_data[turret_id]["cost"])

		var color_rect = main_scene.get_node("UI/HUD/BuldBar/Tower_" + str(index) + "/Color")
		if GameSession.current_money_in_game_session < DataManager.tower_data[turret_id]["cost"]:
			color_rect.color = Color("ff0000")
		else:
			color_rect.color = Color("008000")

func title_show(id_ui: String, id: String):
	var type_attack = int(DataManager.tower_data["Turret_" + id + "T1"]["type_attack"])
	var node_mouse_entered = load("res://Scenes/SupportScenes/TurretMenu.tscn").instantiate()
	var tower_position = main_scene.get_node("UI/HUD/BuldBar/Tower_" + id_ui).position
	node_mouse_entered.position = tower_position + Vector2(100, 50)
	for i in range(len(GameConstants.NameParameters[type_attack].text)):
		node_mouse_entered.get_node("V/" + str(i) + "/HValue/Value").text = str(DataManager.tower_data["Turret_" + id + "T1"][GameConstants.NameParameters[type_attack].data[i]][0])
		node_mouse_entered.get_node("V/" + str(i) + "/HValue/Up").queue_free()
	for i in GameConstants.NameParameters[type_attack].queue_free:
		node_mouse_entered.get_node("V/" + str(i)).queue_free()
	UiManager.list_open_menu_turrets.append(node_mouse_entered)
	main_scene.add_child(node_mouse_entered)
	node_mouse_entered.setup(type_attack)

func title_hide():
	for menu in UiManager.list_open_menu_turrets:
		if is_instance_valid(menu):
			menu.queue_free()
	UiManager.list_open_menu_turrets.clear()
