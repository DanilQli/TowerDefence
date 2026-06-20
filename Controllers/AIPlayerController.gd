# Controllers/AIPlayerController.gd
extends Node
class_name AIPlayerController

signal action_decided(action: Dictionary)

var container: Node
var is_active := false
var last_action_time := 0.0
var min_action_interval := 0.5

# === ДОБАВИТЬ ЭТИ СТРОКИ ===
var max_damage_val := 0.0
var max_damage_tower_id := -1
# ============================

func setup(player_container: Node):
	container = player_container
	is_active = true
	print("[AI Player] Контроллер активирован")

func _process(delta):
	if not is_active or not is_instance_valid(container):
		return
	
	var current_time = Time.get_ticks_msec() / 1000.0
	var should_think = (current_time - last_action_time) >= min_action_interval
	
	if should_think:
		var wave_active = _is_wave_active()
		var has_money = _get_current_money() >= 100
		
		if wave_active or has_money:
			_request_ai_decision()

func _is_wave_active() -> bool:
	if not container.wave_controller:
		return false
	
	var map_node = container.map_node
	if not is_instance_valid(map_node):
		return false
	
	var path_node = map_node.find_child("Path", true, false)
	if not path_node:
		return false
	
	var enemy_count = 0
	for path in path_node.get_children():
		enemy_count += path.get_child_count()
	
	return enemy_count > 0

func _request_ai_decision():
	last_action_time = Time.get_ticks_msec() / 1000.0
	
	var state = _collect_game_state()
	var action = await AIManager.predict(state)
	
	if action.has("error"):
		print("[AI Player] Ошибка AI: ", action.error)
		return
	
	if not is_instance_valid(container):
		return
	
	_execute_action(action)
	emit_signal("action_decided", action)

func _collect_game_state() -> Dictionary:
	var map_node = container.map_node
	
	# === ПОЛУЧАЕМ КОЛОДУ ===
	var deck = []
	if container.has_node("Controllers/UIController"):
		var ui_controller = container.get_node("Controllers/UIController")
		if ui_controller.has_property("list_activity_turret"):
			deck = ui_controller.list_activity_turret.duplicate()
	
	if deck.size() == 0:
		for i in range(DataManager.tower_data.size()):
			var tid = "Turret_" + str(i + 1) + "T1"
			if DataManager.tower_data.has(tid):
				if DataManager.tower_data[tid].get("activity", false):
					deck.append(i)
	
	if deck.size() == 0:
		deck = [0, 1, 2, 3]
	
	# === КРИТИЧЕСКИ ВАЖНО: Читаем деньги AI из meta! ===
	var money = _get_current_money()
	
	# ← ОТЛАДКА: Проверяем что читаем правильные деньги
	print("[AI Controller] 💰 Собираю state | Деньги AI: ", money)
	
	return {
		"grid": _get_grid_matrix(),
		"towers": _get_all_towers(),
		"enemies": _get_all_enemies(),
		"path": container.local_road_coords,
		"deck": deck,
		"money": money,  # ← НЕ GameSession! ТОЛЬКО meta!
		"wave": GameSession.current_wave,
		"base_hp": _get_ai_base_hp(),
		"wave_active": _is_wave_active(),
		"total_dps": 0.0,
		"total_enemy_hp": 0.0
	}

func _get_current_money() -> float:
	if not container:
		print("[AI Controller] ⚠️ container = NULL!")
		return 500.0
	
	if not container.has_meta("ai_money"):
		print("[AI Controller] ⚠️ Нет meta 'ai_money', инициализирую 500.0")
		container.set_meta("ai_money", 500.0)
		return 500.0
	
	var money = container.get_meta("ai_money")
	print("[AI Controller] ✅ Читаю ai_money = ", money)
	return money
	
func _get_ai_base_hp() -> int:
	if container.has_meta("ai_hp"):
		return container.get_meta("ai_hp")
	else:
		container.set_meta("ai_hp", 100)
		return 100

func _get_grid_matrix() -> Array:
	var grid = []
	for x in range(12):
		var row = []
		for y in range(14):
			row.append(0)
		grid.append(row)
	
	var tilemap = container.map_node.get_node_or_null("TowerExlusion")
	var road_cells = []
	var blocked_cells = []
	
	if tilemap:
		for x in range(12):
			for y in range(14):
				var cell = Vector2i(x, y)
				var source_id = tilemap.get_cell_source_id(cell)
				if source_id != -1:
					grid[x][y] = 2
					blocked_cells.append(Vector2i(x, y))
	
	for coord in container.local_road_coords:
		var x = int(coord.x / 64.0)
		var y = int(coord.y / 64.0)
		if x >= 0 and x < 12 and y >= 0 and y < 14:
			grid[x][y] = 1
			road_cells.append(Vector2i(x, y))
	
	print("[AI Grid] Дорога: ", road_cells.size(), " клеток | Занято: ", blocked_cells.size())
	print("[AI Grid] Клетка (6,3) = ", grid[6][3], " (0=свободно, 1=дорога, 2=занято)")
	
	return grid

func _get_all_towers() -> Array:
	var towers = []
	var turret_layer = container.map_node.find_child("Turret", true, false)
	
	if not turret_layer:
		return towers
	
	max_damage_val = 0.0
	max_damage_tower_id = -1
	
	for turret in turret_layer.get_children():
		if is_instance_valid(turret):
			var damage = turret.damage if "damage" in turret else 0.0
			var rof = turret.rof if "rof" in turret else 1.0
			var range_val = turret.range if "range" in turret else 0.0
			var dps = damage / rof if rof > 0 else 0.0
			
			var grid_x = int(turret.position.x / 64.0)
			var grid_y = int(turret.position.y / 64.0)
			
			var t_data = {
				"grid_x": grid_x,
				"grid_y": grid_y,
				"type_id": turret.id,
				"lvl": turret.current_lvl,
				"dps": dps,
				"range": range_val,
				"role": 0.0
			}
			
			if turret.inflicted > max_damage_val:
				max_damage_val = turret.inflicted
				max_damage_tower_id = turret.id
			
			towers.append(t_data)
	
	return towers

func _get_all_enemies() -> Array:
	var enemies_data = []
	if not is_instance_valid(container.map_node):
		return enemies_data
	
	var path_node = container.map_node.find_child("Path", true, false)
	if not path_node:
		return enemies_data
	
	for path in path_node.get_children():
		for enemy in path.get_children():
			if is_instance_valid(enemy):
				if not enemy.has_meta("network_id"):
					enemy.set_meta("network_id", str(enemy.get_instance_id()) + "_" + str(randi()))
				
				var max_h = enemy.base_hp if "base_hp" in enemy else enemy.hp
				enemies_data.append({
					"position": enemy.global_position,
					"hp": enemy.hp,
					"max_hp": max_h
				})
	
	return enemies_data

func _execute_action(action: Dictionary):
	var action_type = int(action.action_type)
	var tower_slot = int(action.tower_idx)  # ← СЛОТ в колоде (0-3)!
	var grid_x = int(action.grid_x)
	var grid_y = int(action.grid_y)
	
	# === ПОЛУЧАЕМ АКТИВНУЮ КОЛОДУ ===
	var active_turrets = container.ui_controller.list_activity_turret
	
	match action_type:
		0:  # Idle
			print("[AI Player] Действие: Idle | 💰 ", _get_current_money())
		
		1:  # Build
			# ← ПРОВЕРЯЕМ ЧТО СЛОТ СУЩЕСТВУЕТ
			if tower_slot >= active_turrets.size():
				print("[AI Player] ❌ Неверный слот колоды: ", tower_slot, 
					  " (доступно слотов: ", active_turrets.size(), ")")
				return
			var tower_id = active_turrets[tower_slot]
			var cost = GameConstants.DATA_TOWER[tower_id].cost_in_session
			
			# Мастерство (скидка)
			if DataManager.data["Turrets"].has(DataManager.keys[tower_id]):
				if DataManager.data["Turrets"][DataManager.keys[tower_id]].mastery_lvl >= 2:
					cost = MathUtils.round_to_dec(cost * (1 - GameConstants.CARDS_MASTERY_MODIFICATOR_LVL[2][0]), 1)
			
			print("[AI Player] Действие: Build tower=", tower_id, 
				  " (slot ", tower_slot, ") pos=(", grid_x, ",", grid_y, 
				  ") | 💰 ", _get_current_money(), " | Cost: ", cost)
			
			if _get_current_money() < cost:
				print("[AI Player] ❌ НЕДОСТАТОЧНО ДЕНЕГ! Ожидается: ", cost, 
					  " Есть: ", _get_current_money())
				return
			
			if not _is_cell_free(grid_x, grid_y):
				print("[AI Player] ❌ Клетка занята! (", grid_x, ",", grid_y, ")")
				return
			
			_build_tower(tower_id, grid_x, grid_y)
		
		2:  # Upgrade
			var turret = _get_tower_at(grid_x, grid_y)
			if not turret:
				print("[AI Player] ❌ Башня не найдена на (", grid_x, ",", grid_y, ")")
				return
			
			var current_lvl = turret.current_lvl
			var max_lvl = turret.max_lvl
			var upgrade_cost = 0.0
			
			if current_lvl < max_lvl:
				upgrade_cost = GameConstants.PriseUnblockCard[GameConstants.DATA_TOWER[turret.id].type].upgrade_for_session[current_lvl]
				
				# Мастерство (скидка на апгрейд)
				if DataManager.data["Turrets"].has(turret.turret_id):
					if DataManager.data["Turrets"][turret.turret_id].mastery_lvl >= 6:
						upgrade_cost = MathUtils.round_to_dec(upgrade_cost * turret.mastery_cost_upgrade, 1)
			
			print("[AI Player] Действие: Upgrade pos=(", grid_x, ",", grid_y, 
				  ") | 💰 ", _get_current_money(), 
				  " | Level: ", current_lvl, "/", max_lvl,
				  " | Cost: ", upgrade_cost)
			
			if current_lvl >= max_lvl:
				print("[AI Player] ❌ МАКСИМАЛЬНЫЙ УРОВЕНЬ! Нельзя улучшить")
				return
			
			if _get_current_money() < upgrade_cost:
				print("[AI Player] ❌ НЕДОСТАТОЧНО ДЕНЕГ! Ожидается: ", upgrade_cost, 
					  " Есть: ", _get_current_money())
				return
			
			_upgrade_tower(grid_x, grid_y)

# ← ВСПОМОГАТЕЛЬНАЯ ФУНКЦИЯ
func _get_tower_at(grid_x: int, grid_y: int) -> Node:
	var turret_layer = container.map_node.find_child("Turret", true, false)
	if not turret_layer:
		return null
	
	var target_pos = Vector2(grid_x * 64 + 32, grid_y * 64 + 32)
	for turret in turret_layer.get_children():
		if turret.position.distance_to(target_pos) < 32:
			return turret
	return null

func _is_cell_free(grid_x: int, grid_y: int) -> bool:
	if grid_x < 0 or grid_x >= 12 or grid_y < 0 or grid_y >= 14:
		return false
	
	var tilemap = container.map_node.get_node_or_null("TowerExlusion")
	if tilemap and tilemap.get_cell_source_id(Vector2i(grid_x, grid_y)) != -1:
		return false
	
	for coord in container.local_road_coords:
		if int(coord.x / 64.0) == grid_x and int(coord.y / 64.0) == grid_y:
			return false
	
	var turret_layer = container.map_node.find_child("Turret", true, false)
	if turret_layer:
		var target_pos = Vector2(grid_x * 64 + 32, grid_y * 64 + 32)
		for turret in turret_layer.get_children():
			if turret.position.distance_to(target_pos) < 32:
				return false
	
	return true

func _build_tower(tower_id: int, grid_x: int, grid_y: int):
	var tower_name = "Turret_" + str(tower_id + 1) + "T1"
	var cost = GameConstants.DATA_TOWER[tower_id].cost_in_session
	
	# Мастерство (скидка)
	if DataManager.data["Turrets"].has(DataManager.keys[tower_id]):
		if DataManager.data["Turrets"][DataManager.keys[tower_id]].mastery_lvl >= 2:
			cost = MathUtils.round_to_dec(cost * (1 - GameConstants.CARDS_MASTERY_MODIFICATOR_LVL[2][0]), 1)
	
	var current_money = _get_current_money()
	
	if current_money < cost:
		print("[AI Player] ❌ Мало денег: ", current_money, " < ", cost)
		return
	
	var tilemap = container.map_node.get_node_or_null("TowerExlusion")
	if tilemap:
		var cell = Vector2i(grid_x, grid_y)
		var source_id = tilemap.get_cell_source_id(cell)
		if source_id != -1:
			print("[AI Player] Клетка занята tilemap: (", grid_x, ",", grid_y, ")")
			return
	
	for coord in container.local_road_coords:
		var rx = int(coord.x / 64.0)
		var ry = int(coord.y / 64.0)
		if rx == grid_x and ry == grid_y:
			print("[AI Player] Это дорога: (", grid_x, ",", grid_y, ")")
			return
	
	var turret_layer = container.map_node.get_node_or_null("Turret")
	if turret_layer:
		var target_pos = Vector2(grid_x * 64 + 32, grid_y * 64 + 32)
		for turret in turret_layer.get_children():
			if turret.position.distance_to(target_pos) < 32:
				print("[AI Player] Башня уже стоит на: (", grid_x, ",", grid_y, ")")
				return
	
	var position = Vector2(grid_x * 64 + 32, grid_y * 64 + 32)
	var turret = TurretFactory.create_turret(tower_name, position)
	if not turret:
		print("[AI Player] Не удалось создать: ", tower_name)
		return
	
	if not turret_layer:
		print("[AI Player] Нет слоя Turret!")
		return
	
	turret_layer.add_child(turret)
	turret.position = position
	turret.built = true
	turret._ready()
	
	if tilemap:
		tilemap.set_cell(Vector2i(grid_x, grid_y), 0, Vector2i(0, 4))
	
	# === КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Обновляем деньги AI ===
	container.set_meta("ai_money", current_money - cost)
	
	print("[AI Player] ✅ Башня построена: ", tower_name, " на (", grid_x, ",", grid_y, ") | денег: ", current_money - cost)
	
func _upgrade_tower(grid_x: int, grid_y: int):
	var turret_layer = container.map_node.find_child("Turret", true, false)
	if not turret_layer:
		return
	
	var target_pos = Vector2(grid_x * 64 + 32, grid_y * 64 + 32)
	
	for turret in turret_layer.get_children():
		if turret.position.distance_to(target_pos) < 32:
			if turret.current_lvl >= turret.max_lvl:
				return
			
			var cost = GameConstants.PriseUnblockCard[GameConstants.DATA_TOWER[turret.id].type].upgrade_for_session[turret.current_lvl]
			
			# Мастерство (скидка)
			if DataManager.data["Turrets"].has(turret.turret_id):
				if DataManager.data["Turrets"][turret.turret_id].mastery_lvl >= 6:
					cost = MathUtils.round_to_dec(cost * turret.mastery_cost_upgrade, 1)
			
			var current_money = _get_current_money()
			
			if current_money < cost:
				return
			
			turret.current_lvl += 1
			turret.upgrade_system.apply_upgrade_effects()
			
			# === КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Обновляем деньги AI ===
			container.set_meta("ai_money", current_money - cost)
			
			print("[AI Player] Улучшена башня на (", grid_x, ",", grid_y, ") до уровня ", turret.current_lvl, " | денег: ", current_money - cost)
			return
			
func stop():
	is_active = false
	print("[AI Player] Контроллер остановлен")
