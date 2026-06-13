# Scenes/UI/player_container.gd
extends Control

@onready var map_node = load("res://Scenes/Maps/map_battle_0.tscn").instantiate()

var build_controller
var wave_controller
var gift_controller
var ui_controller
var game_end_controller
var health_controller

var is_player := false
var pvp_manager: Node
var spectator_enemies = {} 
var spectator_towers_map = {} 
var spectator_effects = {} 

var local_road_coords = []

# Статистика
var tower_damage_history = {} 
var enemy_kill_history = {}   

# Для MVP
var max_damage_tower_id = -1
var max_damage_val = 0

func _ready():
	map_node.name = "Map"
	add_child(map_node)
	move_child(map_node, 0)
	_initialize_controllers()
	call_deferred("_init_local_road_coords")
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		await get_tree().process_frame
		
		# Получаем размеры контейнера (куда надо вписать карту)
		var cont_w = self.size.x
		var cont_h = self.size.y
		
		# Реальный размер карты (примерно 800x900, но лучше взять точно)
		# Если map_node не имеет size, берем константы
		var map_w = 800.0 
		var map_h = 900.0 
		
		# Считаем скейл, чтобы заполнить ВЕСЬ контейнер
		var scale_x = cont_w / map_w
		var scale_y = cont_h / map_h
		
		# Выбираем МАКСИМАЛЬНЫЙ скейл, чтобы покрыть всё (Cover/Zoom)
		# Или минимальный, чтобы вписать (Fit/Letterbox)
		# Ты хочешь "растягивалась вверх и вниз", значит Cover.
		var final_scale = max(scale_x, scale_y)
		
		map_node.scale = Vector2(final_scale, final_scale)
		
		# Центрируем карту
		var new_w = map_w * final_scale
		var new_h = map_h * final_scale
		map_node.position.x = (cont_w - new_w) / 2.0
		map_node.position.y = (cont_h - new_h) / 2.0

func _init_local_road_coords():
	if is_instance_valid(map_node) and map_node.has_node("TowerExlusion"):
		local_road_coords = GameManager.get_matching_tile_coords(map_node.get_node("TowerExlusion"))

func set_as_player(manager: Node):
	is_player = true
	pvp_manager = manager
	GameSession.current_money_in_game_session = 500.0
	GameSession.base_health = 100
	GameSession.current_wave = 0 
	GameSession.game_mode = GameConstants.GameMode.PVP 
	if has_node("UI/HUD/BuldBar"): get_node("UI/HUD/BuldBar").visible = true
	if has_node("UI/HUD/GameControl"): get_node("UI/HUD/GameControl").visible = true
	if ui_controller: ui_controller.initialize(self, true)

func set_as_spectator():
	is_player = false
	if build_controller: build_controller.build_mode = false
	if has_node("UI/HUD/BuldBar"): get_node("UI/HUD/BuldBar").visible = false
	if has_node("UI/HUD/GameControl"): get_node("UI/HUD/GameControl").visible = false
	if ui_controller: ui_controller.initialize(self, false)

func start_game(wave_data: Array):
	if wave_controller:
		wave_controller.set_wave_data(wave_data)
		if is_player: wave_controller.start_next_wave()

func _initialize_controllers():
	var controllers_container = Node.new()
	controllers_container.name = "Controllers"
	add_child(controllers_container)
	build_controller = _create_controller("res://Controllers/BuildController.gd", controllers_container)
	wave_controller = _create_controller("res://Controllers/WaveController.gd", controllers_container)
	gift_controller = _create_controller("res://Controllers/GiftController.gd", controllers_container)
	ui_controller = _create_controller("res://Controllers/UIController.gd", controllers_container)
	game_end_controller = _create_controller("res://Controllers/GameEndController.gd", controllers_container)
	health_controller = _create_controller("res://Controllers/HealthController.gd", controllers_container)
	build_controller.initialize(self)
	wave_controller.initialize(self)
	gift_controller.initialize(self)
	ui_controller.initialize(self, false) 
	game_end_controller.initialize(self)
	health_controller.initialize(self)
	GameManager.get_road_coords(self)

func _create_controller(script_path: String, parent_node: Node) -> Node:
	var script = load(script_path)
	var controller = Node.new()
	controller.set_script(script)
	parent_node.add_child(controller)
	return controller

func on_base_damage(damage: int):
	if is_player:
		GameSession.base_health -= damage
		if GameSession.base_health < 0: GameSession.base_health = 0
		if has_node("UI/HUD/InfoBar/H2/HP"): get_node("UI/HUD/InfoBar/H2/HP").text = str(GameSession.base_health)
		if GameSession.base_health <= 0 and pvp_manager:
			pvp_manager._send({"type": "game_over", "room_id": PvPSession.room_id, "loser_id": PvPSession.player_id})

func on_signal_spawn_enemies(wave: Array, enemy_progress: float):
	if is_player and wave_controller:
		wave_controller.spawn_enemies(wave, enemy_progress)
	
func on_stone(number_block: int, duration: int):
	if not is_player: return
	var available_turrets = []
	var turret_layer = map_node.find_child("Turret", true, false)
	if not turret_layer: return
	for turret in turret_layer.get_children():
		if is_instance_valid(turret) and not turret.get_node("NinePatchRect").visible:
			available_turrets.append(turret)
	if available_turrets.is_empty(): return
	while number_block > 0 and not available_turrets.is_empty():
		var idx = randi() % available_turrets.size()
		available_turrets[idx].stone_effect_start(duration)
		available_turrets.remove_at(idx)
		number_block -= 1

# MVP
func record_tower_damage(tower_type: String, amount: float):
	if not tower_damage_history.has(tower_type):
		tower_damage_history[tower_type] = 0.0
	tower_damage_history[tower_type] += amount

func record_enemy_kill(enemy_name: String):
	if not enemy_kill_history.has(enemy_name):
		enemy_kill_history[enemy_name] = 0
	enemy_kill_history[enemy_name] += 1

func _process(delta):
	if is_player:
		if build_controller and build_controller.build_mode:
			build_controller.update_tower_preview()
		
		if pvp_manager and Time.get_ticks_msec() % 200 < delta * 1000:
			var effects = get_local_effects()
			if effects.size() > 0:
				print("📦 [PLAYER] Отправляю эффекты: ", effects) # ЛОГ ОТПРАВКИ
			
			pvp_manager.send_game_state(
				GameSession.base_health,
				GameSession.current_money_in_game_session,
				GameSession.current_wave,
				get_local_towers(),
				get_local_enemies(),
				effects
			)

func get_local_towers() -> Array:
	var towers = []
	if not is_instance_valid(map_node): return towers
	var turret_layer = map_node.find_child("Turret", true, false)
	if not turret_layer: return towers
	
	max_damage_val = 0
	max_damage_tower_id = -1
	
	for turret in turret_layer.get_children():
		if is_instance_valid(turret):
			var t_data = {
				"type": turret.type, 
				"pos": [snapped(turret.position.x, 0.1), snapped(turret.position.y, 0.1)], 
				"lvl": turret.current_lvl,
				"ability_count": 0,
				"color": "",
				"debuff_icon": "" 
			}
			
			if "ability_0" in turret: t_data["ability_count"] = int(turret.ability_0)
			elif "accumulated_tokens" in turret: t_data["ability_count"] = int(turret.accumulated_tokens)
			if turret.has_node("Turret"): t_data["color"] = turret.get_node("Turret").modulate.to_html()
			
			if turret.has_node("NinePatchRect") and turret.get_node("NinePatchRect").visible:
				var tex = turret.get_node("NinePatchRect").texture
				if tex: t_data["debuff_icon"] = tex.resource_path
			
			if turret.inflicted > max_damage_val:
				max_damage_val = turret.inflicted
				max_damage_tower_id = turret.id
				
			towers.append(t_data)
	return towers

func get_local_enemies() -> Array:
	var enemies_data = []
	if not is_instance_valid(map_node): return enemies_data
	var path_node = map_node.find_child("Path", true, false)
	if not path_node: return enemies_data
	for path in path_node.get_children():
		for enemy in path.get_children():
			if is_instance_valid(enemy) and enemy.has_method("get_progress_ratio"):
				if not enemy.has_meta("network_id"):
					enemy.set_meta("network_id", str(enemy.get_instance_id()) + "_" + str(randi()))
				var max_h = enemy.base_hp if "base_hp" in enemy else enemy.hp
				var variant = 0
				if "ind" in enemy: variant = enemy.ind
				enemies_data.append({
					"net_id": enemy.get_meta("network_id"),
					"name": str(enemy.names),
					"hp": enemy.hp,
					"max_hp": max_h, 
					"progress": snapped(enemy.progress_ratio, 0.001),
					"variant": variant
				})
	return enemies_data

func get_local_effects() -> Array:
	var effects = []
	if not is_instance_valid(map_node): return effects
	
	# Ищем эффекты СКОРОСТИ
	# Важно: Используем get_tree().get_nodes_in_group("speed") и фильтруем по родителю
	# Это надежнее, чем find_children, если иерархия сложная
	var all_speeds = get_tree().get_nodes_in_group("speed")
	
	for child in all_speeds:
		if is_instance_valid(child):
			# Проверяем, принадлежит ли этот эффект НАШЕЙ карте (PlayerContainer)
			# Используем is_ancestor_of
			if map_node.is_ancestor_of(child) or child.get_parent() == map_node:
				var rel_pos = map_node.to_local(child.global_position)
				effects.append({
					"id": str(child.get_instance_id()),
					"type": "speed",
					"pos": [snapped(rel_pos.x, 1), snapped(rel_pos.y, 1)]
				})
	return effects

func sync_opponent_state(state: Dictionary):
	if is_player: return

	var hp_label = get_node_or_null("UI/HUD/InfoBar/H2/HP")
	if hp_label: hp_label.text = str(int(state.get("hp", 100)))
	var money_label = get_node_or_null("UI/HUD/InfoBar/H/Money")
	if money_label: money_label.text = str(int(state.get("money", 500.0)))
	var wave_label = get_node_or_null("UI/HUD/InfoBar/H3/WaveValue")
	if wave_label: wave_label.text = str(int(state.get("wave", 0)) + 1)
	
	# --- БАШНИ ---
	if is_instance_valid(map_node):
		var turret_layer = map_node.find_child("Turret", true, false)
		if turret_layer:
			var current_tower_positions = []
			for tower_data in state.get("towers", []):
				var pos_vec = Vector2(tower_data.pos[0], tower_data.pos[1])
				current_tower_positions.append(pos_vec)
				if spectator_towers_map.has(pos_vec) and is_instance_valid(spectator_towers_map[pos_vec]):
					var t = spectator_towers_map[pos_vec]
					if t.type != tower_data.type:
						t.queue_free()
						_create_spectator_tower(tower_data, pos_vec, turret_layer)
					else:
						if t.current_lvl != tower_data.lvl: t.current_lvl = tower_data.lvl
						_update_tower_visuals(t, tower_data)
				else:
					_create_spectator_tower(tower_data, pos_vec, turret_layer)
			var pos_to_remove = []
			for pos in spectator_towers_map.keys():
				if not pos in current_tower_positions:
					var t = spectator_towers_map[pos]
					if is_instance_valid(t): t.queue_free()
					pos_to_remove.append(pos)
			for pos in pos_to_remove: spectator_towers_map.erase(pos)
	
	# --- ВРАГИ (ИСПРАВЛЕНО) ---
	if is_instance_valid(map_node):
		var path_node = map_node.find_child("Path", true, false)
		if not path_node: return
		var current_packet_ids = []
		
		for enemy_data in state.get("enemies", []):
			var net_id = str(enemy_data.get("net_id", "unknown"))
			current_packet_ids.append(net_id)
			
			if spectator_enemies.has(net_id) and is_instance_valid(spectator_enemies[net_id]):
				# ОБНОВЛЕНИЕ СУЩЕСТВУЮЩЕГО
				var enemy = spectator_enemies[net_id]
				if not enemy.is_inside_tree(): continue
				
				if "server_progress_ratio" in enemy:
					enemy.server_progress_ratio = float(enemy_data.progress)
				else:
					enemy.progress_ratio = float(enemy_data.progress)
					
				enemy.hp = float(enemy_data.hp)
				_update_enemy_visuals(enemy, enemy_data)
			else:
				# СОЗДАНИЕ НОВОГО
				var enemy_name = str(enemy_data.name)
				var enemy_scene_path = _get_enemy_scene_path(enemy_name)
				
				# --- ФИКС: УБРАЛИ FileAccess.file_exists, сразу грузим ---
				var enemy_scene = load(enemy_scene_path)
				
				if enemy_scene:
					var enemy = enemy_scene.instantiate()
					enemy.hp = float(enemy_data.hp)
					enemy.base_hp = float(enemy_data.get("max_hp", enemy.hp))
					enemy.is_spectator_enemy = true
					
					if "11" in enemy_name and enemy_data.has("variant"):
						var variant = int(enemy_data.variant) + 1
						if variant > 0 and variant <= 3:
							# Тут тоже используем load напрямую
							var tex_path = "res://Assets/Props/enemy_11_" + str(variant) + ".png"
							var tex = load(tex_path)
							if tex: enemy.get_node("Sprite2D").texture = tex
					
					_set_spectator_speed(enemy, enemy_name)
					
					if "server_progress_ratio" in enemy:
						enemy.server_progress_ratio = float(enemy_data.progress)
					
					if path_node.is_inside_tree():
						path_node.get_child(0).add_child(enemy)
						enemy.progress_ratio = float(enemy_data.progress)
						spectator_enemies[net_id] = enemy
						_update_enemy_visuals(enemy, enemy_data)
				else:
					# Логируем ошибку, если файла реально нет в APK
					print("❌ [SPECTATOR] Ошибка загрузки сцены врага: ", enemy_scene_path)
		
		var ids_to_remove = []
		for net_id in spectator_enemies.keys():
			if not net_id in current_packet_ids:
				var enemy = spectator_enemies[net_id]
				if is_instance_valid(enemy): enemy.queue_free()
				ids_to_remove.append(net_id)
		for id in ids_to_remove: spectator_enemies.erase(id)

	# --- ЭФФЕКТЫ ---
	if is_instance_valid(map_node) and state.has("effects"):
		var current_effect_ids = []
		for eff_data in state.get("effects", []):
			var eid = str(eff_data.id)
			current_effect_ids.append(eid)
			
			if not spectator_effects.has(eid):
				var obj = null
				if eff_data.type == "speed":
					obj = load("res://Scenes/SupportScenes/road_speed.tscn").instantiate()
				
				if obj:
					obj.position = Vector2(eff_data.pos[0], eff_data.pos[1])
					obj.z_index = 0 
					map_node.add_child(obj)
					spectator_effects[eid] = obj
		
		var eff_to_remove = []
		for eid in spectator_effects.keys():
			if not eid in current_effect_ids:
				var obj = spectator_effects[eid]
				if is_instance_valid(obj): obj.queue_free()
				eff_to_remove.append(eid)
		for eid in eff_to_remove: spectator_effects.erase(eid)
		
func _create_spectator_tower(tower_data, pos, parent):
	var turret = TurretFactory.create_turret(tower_data.type, pos)
	if turret:
		turret.built = true
		turret.current_lvl = tower_data.lvl
		turret.set_opponent_tower(true)
		parent.add_child(turret)
		spectator_towers_map[pos] = turret
		_update_tower_visuals(turret, tower_data)

func _update_enemy_visuals(enemy, data):
	if enemy.has_node("HealthBar"):
		var bar = enemy.get_node("HealthBar")
		bar.visible = true
		bar.top_level = true 
		bar.max_value = float(data.get("max_hp", enemy.base_hp))
		bar.value = float(enemy.hp)
		bar.global_position = enemy.global_position + Vector2(-30, -40)
		bar.rotation = 0

func _update_tower_visuals(turret, data):
	var count = int(data.get("ability_count", 0))
	if count > 0:
		if turret.has_node("Panel"):
			turret.get_node("Panel").visible = true
			if turret.get_node("Panel").has_node("Label"):
				turret.get_node("Panel/Label").text = str(count)
		if turret.has_node("TokenLabel"):
			turret.get_node("TokenLabel").visible = true
			if turret.get_node("TokenLabel").has_node("Label"):
				turret.get_node("TokenLabel/Label").text = str(count)
	else:
		if turret.has_node("Panel"): turret.get_node("Panel").visible = false
		if turret.has_node("TokenLabel"): turret.get_node("TokenLabel").visible = false
	
	if data.has("color") and data["color"] != "" and turret.has_node("Turret"):
		turret.get_node("Turret").modulate = Color(data["color"])
		
	var icon_path = data.get("debuff_icon", "")
	if icon_path != "":
		if turret.has_node("NinePatchRect"):
			turret.get_node("NinePatchRect").visible = true
			turret.get_node("NinePatchRect").texture = load(icon_path)
	else:
		if turret.has_node("NinePatchRect"):
			turret.get_node("NinePatchRect").visible = false

func _get_enemy_scene_path(enemy_name: String) -> String:
	if enemy_name.begins_with("Enemy_"):
		return "res://Scenes/Enemies/%s.tscn" % enemy_name
	var boss_id = 0
	if enemy_name.begins_with("BOSS_"): boss_id = int(enemy_name.split("_")[1])
	else: boss_id = int(float(enemy_name))
	return "res://Scenes/EnemiesBoss/Enemy_boss_%d.tscn" % boss_id

func _set_spectator_speed(enemy, enemy_name):
	var id = 0
	if enemy_name.begins_with("Enemy_"):
		var parts = enemy_name.split("_")
		if parts.size() > 1: id = int(parts[1]) - 1
		enemy.speed = GameConstants.DATA_ENEMY.get(id, {}).get("speed", 100)
	else:
		if enemy_name.begins_with("BOSS_"):
			id = int(enemy_name.split("_")[1])
		else:
			id = int(float(enemy_name))
			
		if GameConstants.DATA_ENEMY_BOSS.has(id):
			enemy.speed = GameConstants.DATA_ENEMY_BOSS[id].get("speed", 100)
		else:
			enemy.speed = 100
			
	enemy.current_speed = enemy.speed
	enemy.is_spectator_enemy = true 
