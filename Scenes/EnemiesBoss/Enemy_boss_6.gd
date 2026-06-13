# Scenes/EnemiesBoss/Enemy_boss_6.gd
extends Enemy_boss
class_name Enemy_boss_6

var rng = RandomNumberGenerator.new()

func fire() -> void:
	if is_ready:
		is_ready = false
		
		# Собираем валидные списки башен
		var list_valid_indices = []
		for i in range(len(ResourceManager.list_turret)):
			# Проверяем, есть ли в этой категории башни
			if not ResourceManager.list_turret[i].is_empty():
				# Дополнительно чистим список от мусора (уже удаленных башен)
				var valid_turrets = []
				for t in ResourceManager.list_turret[i]:
					if is_instance_valid(t):
						valid_turrets.append(t)
				ResourceManager.list_turret[i] = valid_turrets
				
				if not ResourceManager.list_turret[i].is_empty():
					list_valid_indices.append(i)
		
		if not list_valid_indices.is_empty():
			# Выбираем случайный тип башни
			var type_index = list_valid_indices[rng.randi_range(0, len(list_valid_indices) - 1)]
			var towers_list = ResourceManager.list_turret[type_index]
			
			if not towers_list.is_empty():
				# Выбираем случайную башню
				var target_index = rng.randi_range(0, len(towers_list) - 1)
				var target_turret = towers_list[target_index]
				
				if is_instance_valid(target_turret):
					# Сначала берем позицию
					var pos = target_turret.global_position
					
					# Создаем эффект
					var new_impact = projectile_impact_1.instantiate()
					new_impact.global_position = pos
					new_impact.z_index = 5
					new_impact.scale = Vector2i(1, 1)
					get_tree().root.get_node(".").add_child(new_impact)
					
					# Удаляем башню
					target_turret.queue_free()
					towers_list.remove_at(target_index)
