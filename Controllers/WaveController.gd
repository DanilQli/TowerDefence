# Controllers/WaveController.gd
extends Node

var main_scene
var wave_data_all: Array
var wave_data: Array
var enemies_in_wave: int
var gift_controller
var game_end_controller
var current_wave_index: int = -1
var rng = RandomNumberGenerator.new()

func initialize(scene: Node, waves_data = null):
	main_scene = scene
	if waves_data: wave_data_all = waves_data
	else: 
		var key = "level_" + str(GameSession.current_level)
		if DataManager.data_wave.has(key):
			wave_data_all = DataManager.data_wave[key]
		else:
			wave_data_all = [] 
			
	gift_controller = main_scene.gift_controller
	game_end_controller = main_scene.game_end_controller

func retrieve_wave_data() -> Array:
	if GameSession.current_wave >= wave_data_all.size(): return []
	wave_data = wave_data_all[GameSession.current_wave]
	if GameSession.game_mode != GameConstants.GameMode.CAMPAIGN:
		if GameSession.current_wave in DataManager.list_wave_gift and not main_scene.gift_controller.have_open_present:
			main_scene.gift_controller.launch_gift_box()
	GameSession.current_wave += 1
	enemies_in_wave = wave_data.size()
	return wave_data

func spawn_enemies(wave: Array, enemy_progress=false):
	if main_scene.has_node("UI/HUD/InfoBar/H3/WaveValue"):
		main_scene.get_node("UI/HUD/InfoBar/H3/WaveValue").text = str(GameSession.current_wave)
	
	for unit in wave:
		var unit_type = str(unit[0])
		var delay = float(unit[1])
		
		var enemy_scene_path = ""
		var enemy_id = 0
		var is_boss = false
		
		if unit_type.begins_with("BOSS_"):
			is_boss = true
			enemy_id = int(unit_type.split("_")[1])
			enemy_scene_path = "res://Scenes/EnemiesBoss/Enemy_boss_" + str(enemy_id) + ".tscn"
		elif unit_type.begins_with("Enemy_"):
			is_boss = false
			var parts = unit_type.split("_")
			if parts.size() > 1: 
				enemy_id = int(parts[1]) - 1
			enemy_scene_path = "res://Scenes/Enemies/" + unit_type + ".tscn"
		else:
			is_boss = false
			enemy_scene_path = "res://Scenes/Enemies/" + unit_type + ".tscn"
			enemy_id = int(unit_type.split("_")[1]) - 1

		var enemy_scene = load(enemy_scene_path)
		if enemy_scene == null:
			push_error("❌ [WaveController] Не удалось загрузить врага: " + enemy_scene_path)
			await get_tree().create_timer(delay).timeout
			continue
		
		var enemy = enemy_scene.instantiate()
		if enemy == null:
			push_error("❌ [WaveController] Ошибка создания экземпляра: " + enemy_scene_path)
			await get_tree().create_timer(delay).timeout
			continue
		
		enemy.names = unit_type
		enemy.id = enemy_id
		enemy.duration_speed_mod = 0
		
		if is_boss:
			if GameConstants.DATA_ENEMY_BOSS.has(enemy.id):
				enemy.hp = GameConstants.DATA_ENEMY_BOSS[enemy.id].hp
				enemy.speed = GameConstants.DATA_ENEMY_BOSS[enemy.id].speed
			else:
				enemy.hp = 1000
				enemy.speed = 100
			enemy.current_speed = enemy.speed
			if enemy.has_signal("stone"): enemy.stone.connect(main_scene.on_stone)
			if enemy.has_signal("signal_spawn_enemies"): enemy.signal_spawn_enemies.connect(main_scene.on_signal_spawn_enemies)
		else:
			if GameConstants.DATA_ENEMY.has(enemy.id):
				enemy.hp = GameConstants.DATA_ENEMY[enemy.id].hp
				enemy.speed = GameConstants.DATA_ENEMY[enemy.id].speed
			else:
				enemy.hp = 100
				enemy.speed = 100
			enemy.current_speed = enemy.speed

		if main_scene.has_method("on_base_damage") and not enemy.base_damage.is_connected(main_scene.on_base_damage):
			enemy.base_damage.connect(main_scene.on_base_damage)
		
		# --- ЛОГИКА ОПРЕДЕЛЕНИЯ ЗРИТЕЛЯ ---
		# В одиночной игре (GameScene) нет флага is_player, поэтому enemy.is_spectator_enemy всегда false
		# В PvP (player_container) флаг есть.
		if "is_spectator_enemy" in enemy: 
			if "is_player" in main_scene:
				enemy.is_spectator_enemy = (not main_scene.is_player)
			else:
				enemy.is_spectator_enemy = false
		# ----------------------------------

		if not is_instance_valid(main_scene.map_node):
			enemy.queue_free()
			return

		var path_node = main_scene.map_node.get_node_or_null("Path")
		
		if path_node and path_node.get_child_count() > 0:
			var path_index = rng.randi_range(0, path_node.get_child_count() - 1)
			var path_child = path_node.get_child(path_index)
			
			if path_child is Path2D:
				path_child.add_child(enemy, true)
				if enemy_progress:
					enemy.progress = enemy_progress
				else:
					enemy.progress = 0
			else:
				enemy.queue_free()
		else:
			enemy.queue_free()

		await get_tree().create_timer(delay).timeout

	if not enemy_progress and GameSession.current_wave < wave_data_all.size():
		await get_tree().create_timer(5).timeout
		start_next_wave()

func set_wave_data(waves: Array): wave_data_all = waves

func force_start_wave(index: int):
	if current_wave_index >= index: return
	current_wave_index = index
	GameSession.current_wave = index
	if index < wave_data_all.size(): spawn_enemies(wave_data_all[index])

func start_next_wave():
	current_wave_index = GameSession.current_wave
	wave_data = retrieve_wave_data()
	if wave_data.size() > 0: spawn_enemies(wave_data)

func get_current_wave_index() -> int: return current_wave_index
