extends Node

var main_scene: Node2D
var wave_data_all: Array
var wave_data: Array
var enemies_in_wave: int
var gift_controller
var game_end_controller
var rng = RandomNumberGenerator.new()

func initialize(scene: Node2D):
	main_scene = scene
	wave_data_all = DataManager.data_wave["level_" + str(GameSession.current_level)]
	gift_controller = main_scene.gift_controller
	game_end_controller = main_scene.game_end_controller

func start_next_wave():
	wave_data = retrieve_wave_data()
	await get_tree().create_timer(0.2).timeout
	spawn_enemies(wave_data)

func retrieve_wave_data() -> Array:
	wave_data = wave_data_all[GameSession.current_wave]

	if GameSession.current_wave in DataManager.list_wave_gift and not main_scene.gift_controller.have_open_present:
		main_scene.gift_controller.launch_gift_box()
	
	GameSession.current_wave += 1
	enemies_in_wave = wave_data.size()
	return wave_data

func spawn_enemies(wave: Array, enemy_progress=false):
	main_scene.get_node("UI/HUD/InfoBar/H3/WaveValue").text = str(GameSession.current_wave)
	var type
	var delay
	var enemy
	for unit in wave:
		type = unit[0]
		delay = unit[1]
		enemy = load("res://Scenes/Enemies/%s.tscn" % type).instantiate()
		enemy.names = type
		enemy.id = int(type.split("_")[1]) - 1
		enemy.hp = GameConstants.DATA_ENEMY[enemy.id].hp
		enemy.current_speed = GameConstants.DATA_ENEMY[enemy.id].speed
		enemy.speed = GameConstants.DATA_ENEMY[enemy.id].speed
		enemy.duration_speed_mod = 0
		enemy.base_damage.connect(main_scene.on_base_damage)
		if enemy_progress:
			enemy.progress = enemy_progress
		
		var num_paths = main_scene.map_node.get_node("Path").get_child_count()
		var path_index = rng.randi_range(0, num_paths - 1)
		main_scene.map_node.get_node("Path").get_child(path_index).add_child(enemy, true)

		await get_tree().create_timer(delay).timeout
		
	if not enemy_progress:
		# Спавн боссов
		await get_tree().create_timer(1).timeout
		type = 8
		enemy = load("res://Scenes/EnemiesBoss/Enemy_boss_" + str(type) + ".tscn").instantiate()
		enemy.names = type
		enemy.id = type - 1
		enemy.hp = GameConstants.DATA_ENEMY_BOSS[type - 1].hp
		enemy.current_speed = GameConstants.DATA_ENEMY_BOSS[type - 1].speed
		enemy.speed = GameConstants.DATA_ENEMY_BOSS[type - 1].speed
		enemy.duration_speed_mod = 0
		enemy.base_damage.connect(main_scene.on_base_damage)
		enemy.stone.connect(main_scene.on_stone)
		enemy.signal_spawn_enemies.connect(main_scene.on_signal_spawn_enemies)
		var num_paths = main_scene.map_node.get_node("Path").get_child_count()
		var path_index = randi_range(0, num_paths - 1)
		main_scene.map_node.get_node("Path").get_child(path_index).add_child(enemy, true)
		
		if GameSession.current_wave < wave_data_all.size():
			await get_tree().create_timer(5).timeout
			start_next_wave()
