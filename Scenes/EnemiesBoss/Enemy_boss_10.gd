# Scenes/EnemiesBoss/Enemy_boss_10.gd
extends Enemy_boss
class_name Enemy_boss_10

func on_destroy(tower_id=-1):
	# Генерирует только Владелец (Игрок). Зритель получит через синхронизацию.
	if not is_spectator_enemy:
		# Пытаемся найти карту через родителя
		var map_node = find_parent("Map")
		
		# Если не нашли (например, тест), ищем в корне сцены
		if not map_node:
			map_node = get_tree().current_scene.find_child("Map", true, false)
			
		var possible_coords = []
		
		# Пытаемся получить координаты с карты
		if map_node and map_node.has_node("TowerExlusion"):
			possible_coords = GameManager.get_matching_tile_coords(map_node.get_node("TowerExlusion"))
		else:
			# Фолбэк на глобальные координаты (для тестов)
			possible_coords = GameManager.LIST_COORDS_ROAD
			
		if possible_coords.size() > 0:
			for i in range(3):
				var road_speed = load("res://Scenes/SupportScenes/road_speed.tscn").instantiate()
				var pos = possible_coords[randi_range(0, len(possible_coords) - 1)]
				
				road_speed.position = pos
				# Важно: добавляем в группу speed ДО добавления в сцену
				if not road_speed.is_in_group("speed"):
					road_speed.add_to_group("speed")
				
				if map_node:
					map_node.add_child(road_speed)
				else:
					get_tree().current_scene.add_child(road_speed)
	
	super.on_destroy(tower_id)
