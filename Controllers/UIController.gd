# Controllers/UIController.gd
extends Node

var main_scene
var list_activity_turret: Array = []
var is_player := true
var _selected_speed: float = 1.0

func initialize(scene, flag=true):
	main_scene = scene
	is_player = flag
	if is_equal_approx(GameSession.speed_game, GameConstants.SPEED_UP_GAME_SESSION):
		_selected_speed = GameConstants.SPEED_UP_GAME_SESSION
	else:
		_selected_speed = GameConstants.SPEED_NORMAL_GAME_SESSION
	if is_player:
		GameSession.speed_game = _selected_speed
		Engine.set_time_scale(_selected_speed)

	# Подключаем управление игрой только если это игрок
	if is_player and main_scene.has_node("UI/HUD/GameControl/PausePlay"):
		var pause_button = main_scene.get_node("UI/HUD/GameControl/PausePlay")
		var speed_button = main_scene.get_node("UI/HUD/GameControl/SpeedUp")

		if pause_button.pressed.is_connected(_on_pause_play_pressed):
			pause_button.pressed.disconnect(_on_pause_play_pressed)
		if speed_button.pressed.is_connected(_on_speed_up_pressed):
			speed_button.pressed.disconnect(_on_speed_up_pressed)

		pause_button.pressed.connect(_on_pause_play_pressed)
		speed_button.pressed.connect(_on_speed_up_pressed)

	# Сигнал денег и стартовый баланс — только для контейнера игрока
	if is_player:
		if not GameSession.money_in_game_session_changed.is_connected(_on_money_changed):
			GameSession.money_in_game_session_changed.connect(_on_money_changed)
		GameSession.current_money_in_game_session = 500
	elif GameSession.money_in_game_session_changed.is_connected(_on_money_changed):
		GameSession.money_in_game_session_changed.disconnect(_on_money_changed)

	# Собираем доступные башни
	list_activity_turret.clear()
	for i in range(len(GameConstants.DATA_TOWER)):
		var turret_id = "Turret_" + str(i + 1) + "T1"
		if DataManager.tower_data.has(turret_id) and DataManager.tower_data[turret_id]["activity"]:
			list_activity_turret.append(i)

	# Настройка кнопок постройки
	if is_player:
		for i in range(list_activity_turret.size()):
			var index = i + 1
			var tower_index = list_activity_turret[i] + 1
			var turret_name = "Turret_" + str(tower_index)

			var icon_path = "UI/HUD/BuldBar/Tower_" + str(index) + "/Icon"
			var button_path = "UI/HUD/BuldBar/Tower_" + str(index)

			if main_scene.has_node(icon_path):
				main_scene.get_node(icon_path).texture = preload("res://Systems/SkinPreview.gd").texture(tower_index)

			if main_scene.has_node(button_path):
				var button = main_scene.get_node(button_path)
				var draggable_script = load("res://Scenes/SupportScenes/DraggableButton.gd")
				if draggable_script:
					button.set_script(draggable_script)
					button.turret_type = turret_name
					button.turret_index = tower_index
					button.main_scene = main_scene
					button.mouse_filter = Control.MOUSE_FILTER_STOP
				else:
					print("❌ Ошибка: DraggableButton.gd не найден!")

	if is_player:
		_update_speed_up_visuals()
		_on_money_changed()

func _exit_tree() -> void:
	if GameSession and GameSession.money_in_game_session_changed.is_connected(_on_money_changed):
		GameSession.money_in_game_session_changed.disconnect(_on_money_changed)

func start_drag_build(type, index):
	if main_scene.build_controller.initiate_build_mode(type, index):
		main_scene.build_controller.update_tower_preview()

func _on_pause_play_pressed():
	if not is_player: return
	AudioManager.play_sfx("pause_toggle")
	if main_scene.build_controller.build_mode:
		main_scene.build_controller.cancel_build_mode()

	if GameSession.current_wave == 0:
		GameSession.speed_game = _selected_speed
		Engine.set_time_scale(_selected_speed)
		main_scene.wave_controller.start_next_wave()
	else:
		var was_paused: bool = main_scene.get_tree().paused
		if not was_paused and GameSession.speed_game > 0.0:
			_selected_speed = GameSession.speed_game
		main_scene.get_tree().paused = not was_paused
		if was_paused:
			GameSession.speed_game = _selected_speed
			Engine.set_time_scale(_selected_speed)
		else:
			GameSession.speed_game = 0.0
	_update_speed_up_visuals()

func _on_speed_up_pressed():
	if not is_player: return
	AudioManager.play_sfx("speed_toggle")
	if is_equal_approx(_selected_speed, GameConstants.SPEED_UP_GAME_SESSION):
		_selected_speed = GameConstants.SPEED_NORMAL_GAME_SESSION
	else:
		_selected_speed = GameConstants.SPEED_UP_GAME_SESSION

	if GameSession.current_wave == 0:
		GameSession.speed_game = _selected_speed
		Engine.set_time_scale(_selected_speed)
		main_scene.wave_controller.start_next_wave()
		_update_speed_up_visuals()
		return

	if not main_scene.get_tree().paused:
		GameSession.speed_game = _selected_speed
		Engine.set_time_scale(_selected_speed)
	_update_speed_up_visuals()

func _update_speed_up_visuals():
	if not is_instance_valid(main_scene):
		return
	var speed_btn = main_scene.get_node_or_null("UI/HUD/GameControl/SpeedUp")
	if not speed_btn:
		return
	var effective_speed: float = GameSession.speed_game if GameSession.speed_game > 0.0 else _selected_speed
	var is_fast: bool = is_equal_approx(effective_speed, GameConstants.SPEED_UP_GAME_SESSION)
	speed_btn.self_modulate = Color(1.0, 0.86, 0.32, 1.0) if is_fast else Color(0.88, 0.93, 1.0, 0.95)

	var frame = speed_btn.get_node_or_null("BtnFrame") as Panel
	if frame:
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0.24, 0.17, 0.05, 0.92) if is_fast else Color(0.08, 0.11, 0.18, 0.85)
		st.border_color = Color(1.0, 0.78, 0.22, 0.98) if is_fast else Color(0.30, 0.40, 0.58, 0.75)
		st.set_border_width_all(2 if is_fast else 1)
		st.set_corner_radius_all(12)
		frame.add_theme_stylebox_override("panel", st)

	var badge = speed_btn.get_node_or_null("SpeedBadge") as Label
	if badge:
		badge.text = "2×" if is_fast else "1×"
		badge.add_theme_color_override("font_color", Color(1.0, 0.86, 0.28, 1.0) if is_fast else Color(0.72, 0.82, 0.95, 0.9))

func _on_money_changed():
	if not is_instance_valid(main_scene):
		return
	if main_scene.has_node("UI/HUD/InfoBar/H/Money"):
		main_scene.get_node("UI/HUD/InfoBar/H/Money").text = str(int(GameSession.current_money_in_game_session))

	if is_player:
		for i in range(list_activity_turret.size()):
			var index = i + 1
			var tower_idx = list_activity_turret[i] + 1

			var cost = GameConstants.DATA_TOWER[tower_idx - 1].cost_in_session
			if DataManager.data["Turrets"].has(DataManager.keys[tower_idx - 1]):
				if DataManager.data["Turrets"][DataManager.keys[tower_idx - 1]].mastery_lvl >= 3:
					cost = MathUtils.round_to_dec(cost * (1 - GameConstants.CARDS_MASTERY_MODIFICATOR_LVL[2][0]), 1)

			var affordable: bool = GameSession.current_money_in_game_session >= cost
			var cost_label_path = "UI/HUD/BuldBar/Tower_" + str(index) + "/Color/Cost"
			var color_rect_path = "UI/HUD/BuldBar/Tower_" + str(index) + "/Color"
			var icon_path = "UI/HUD/BuldBar/Tower_" + str(index) + "/Icon"

			if main_scene.has_node(cost_label_path):
				var cost_lbl: Label = main_scene.get_node(cost_label_path)
				cost_lbl.text = str(cost)
				cost_lbl.add_theme_color_override(
					"font_color",
					Color(1.0, 0.90, 0.48, 1.0) if affordable else Color(1.0, 0.52, 0.52, 1.0)
				)

			if main_scene.has_node(icon_path):
				var icon_node: TextureRect = main_scene.get_node(icon_path)
				icon_node.modulate = Color(1.0, 1.0, 1.0, 1.0) if affordable else Color(0.62, 0.65, 0.72, 0.88)

			if main_scene.has_node(color_rect_path):
				var color_rect = main_scene.get_node(color_rect_path)
				color_rect.color = Color("008000") if affordable else Color("ff0000")
				var pill = color_rect.get_node_or_null("PillBg") as Panel
				if pill:
					var pill_style := StyleBoxFlat.new()
					pill_style.bg_color = Color(0.06, 0.13, 0.11, 0.94) if affordable else Color(0.18, 0.06, 0.08, 0.94)
					pill_style.border_color = Color(0.22, 0.82, 0.48, 0.92) if affordable else Color(0.90, 0.30, 0.32, 0.90)
					pill_style.set_border_width_all(2)
					pill_style.set_corner_radius_all(9)
					pill_style.shadow_color = Color(0, 0, 0, 0.42)
					pill_style.shadow_size = 4
					pill_style.shadow_offset = Vector2(0, 2)
					pill.add_theme_stylebox_override("panel", pill_style)

