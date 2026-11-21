# Controllers/WaveController.gd
extends Node

var main_scene
var wave_data_all: Array
var wave_data: Array
var enemies_in_wave: int
var gift_controller
var game_end_controller
var current_wave_index: int = -1
var local_wave: int = 0
var active_spawn_sequences: int = 0
var rng = RandomNumberGenerator.new()
var _scene_cache: Dictionary = {}

func _load_enemy_scene(path: String) -> PackedScene:
	if _scene_cache.has(path):
		return _scene_cache[path] as PackedScene
	var sc: PackedScene = load(path) as PackedScene
	if sc != null:
		_scene_cache[path] = sc
	return sc

func _is_primary_player_controller() -> bool:
	if is_instance_valid(main_scene) and ("is_player" in main_scene):
		return AudioManager.to_bool(main_scene.is_player, true)
	return true

func initialize(scene: Node, waves_data = null):
	main_scene = scene
	local_wave = 0
	current_wave_index = -1
	active_spawn_sequences = 0
	if waves_data:
		wave_data_all = waves_data
	else:
		var key = "level_" + str(GameSession.current_level)
		if DataManager.data_wave.has(key):
			wave_data_all = DataManager.data_wave[key]
		else:
			wave_data_all = []
			
	gift_controller = main_scene.gift_controller
	game_end_controller = main_scene.game_end_controller

func retrieve_wave_data() -> Array:
	if local_wave >= wave_data_all.size():
		return []
	wave_data = wave_data_all[local_wave]
	if _is_primary_player_controller() and GameSession.game_mode in [GameConstants.GameMode.SANDBOX, GameConstants.GameMode.CAMPAIGN]:
		if local_wave > 0 and local_wave % 10 == 0:
			if is_instance_valid(main_scene.gift_controller) and not main_scene.gift_controller.have_open_present:
				main_scene.gift_controller.launch_gift_box(local_wave)
	local_wave += 1
	if _is_primary_player_controller():
		GameSession.current_wave = local_wave
	enemies_in_wave = wave_data.size()
	return wave_data

func spawn_enemies(wave: Array, enemy_progress = null):
	if not is_instance_valid(self) or not is_inside_tree() or not is_instance_valid(main_scene):
		return
	var has_custom_progress: bool = (typeof(enemy_progress) in [TYPE_FLOAT, TYPE_INT] and float(enemy_progress) >= 0.0)
	var spawn_wave_num: int = maxi(1, local_wave)
	if not has_custom_progress and _is_primary_player_controller():
		AudioManager.play_combat_sfx("wave_start", main_scene)

	active_spawn_sequences += 1
	if main_scene.has_node("UI/HUD/InfoBar/H3/WaveValue"):
		main_scene.get_node("UI/HUD/InfoBar/H3/WaveValue").text = str(spawn_wave_num)
	else:
		var wv = main_scene.find_child("WaveValue", true, false) as Label
		if wv:
			wv.text = str(spawn_wave_num)
	
	for unit in wave:
		while is_instance_valid(self) and is_inside_tree() and get_tree().paused:
			await get_tree().create_timer(0.1, false).timeout
		if not is_instance_valid(self) or not is_inside_tree() or not is_instance_valid(main_scene):
			active_spawn_sequences = maxi(0, active_spawn_sequences - 1)
			return

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

		var enemy_scene: PackedScene = _load_enemy_scene(enemy_scene_path)
		if enemy_scene == null:
			push_error("❌ [WaveController] Не удалось загрузить врага: " + enemy_scene_path)
			await get_tree().create_timer(delay, false).timeout
			if not is_instance_valid(self) or not is_inside_tree():
				return
			continue
		
		var enemy = enemy_scene.instantiate()
		if enemy == null:
			push_error("❌ [WaveController] Ошибка создания экземпляра: " + enemy_scene_path)
			await get_tree().create_timer(delay, false).timeout
			if not is_instance_valid(self) or not is_inside_tree():
				return
			continue
		
		enemy.names = unit_type
		enemy.id = enemy_id
		enemy.duration_speed_mod = 0
		enemy.set_meta("spawn_wave", spawn_wave_num)
		
		if is_boss:
			if GameConstants.DATA_ENEMY_BOSS.has(enemy.id):
				enemy.hp = GameConstants.DATA_ENEMY_BOSS[enemy.id].hp
				enemy.speed = GameConstants.DATA_ENEMY_BOSS[enemy.id].speed
			else:
				enemy.hp = 1000
				enemy.speed = 100
			enemy.current_speed = enemy.speed
			if enemy.has_signal("stone"): 
				enemy.stone.connect(main_scene.on_stone)
			if enemy.has_signal("signal_spawn_enemies"): 
				enemy.signal_spawn_enemies.connect(main_scene.on_signal_spawn_enemies)
		else:
			if GameConstants.DATA_ENEMY.has(enemy.id):
				enemy.hp = GameConstants.DATA_ENEMY[enemy.id].hp
				enemy.speed = GameConstants.DATA_ENEMY[enemy.id].speed
			else:
				enemy.hp = 100
				enemy.speed = 100
			enemy.current_speed = enemy.speed
		
		if "is_spectator_enemy" in enemy:
			var is_pvp_ai = GameSession.game_mode == GameConstants.GameMode.PVP_AI
			if is_pvp_ai:
				enemy.is_spectator_enemy = false
			elif "is_player" in main_scene:
				enemy.is_spectator_enemy = not main_scene.is_player
			else:
				enemy.is_spectator_enemy = false

		if not is_instance_valid(main_scene.map_node):
			enemy.queue_free()
			active_spawn_sequences = maxi(0, active_spawn_sequences - 1)
			return

		var path_node = main_scene.map_node.get_node_or_null("Path")
		
		if path_node and path_node.get_child_count() > 0:
			var path_index = rng.randi_range(0, path_node.get_child_count() - 1)
			var path_child = path_node.get_child(path_index)
			
			if path_child is Path2D:
				path_child.add_child(enemy, true)
				enemy.progress = float(enemy_progress) if has_custom_progress else 0.0
			else:
				enemy.queue_free()
		else:
			enemy.queue_free()

		await get_tree().create_timer(delay, false).timeout
		if not is_instance_valid(self) or not is_inside_tree() or not is_instance_valid(main_scene):
			active_spawn_sequences = maxi(0, active_spawn_sequences - 1)
			return

	active_spawn_sequences = maxi(0, active_spawn_sequences - 1)
	if not has_custom_progress and _is_primary_player_controller():
		AudioManager.play_combat_sfx("wave_complete", main_scene)
	if not has_custom_progress and local_wave < wave_data_all.size():
		await get_tree().create_timer(5.0, false).timeout
		while is_instance_valid(self) and is_inside_tree() and get_tree().paused:
			await get_tree().create_timer(0.1, false).timeout
		if is_instance_valid(self) and is_inside_tree() and is_instance_valid(main_scene):
			start_next_wave()
		
func set_wave_data(waves: Array):
	wave_data_all = waves

func start_next_wave():
	current_wave_index = local_wave
	wave_data = retrieve_wave_data()
	if wave_data.size() > 0:
		spawn_enemies(wave_data)
