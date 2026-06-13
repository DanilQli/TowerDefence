extends Enemy_boss
class_name Enemy_boss_11

var list_children = []

func _ready() -> void:
	super._ready()
	
	# Если это зрительская копия, детей спавнить не нужно
	# (они придут отдельными объектами с сервера)
	if is_spectator_enemy:
		return

	await get_tree().create_timer(0.45).timeout
	
	# Проверка: если босс умер за время таймера, не спавним
	if not is_instance_valid(self): return

	for i in range(1, 4):
		var enemy = load("res://Scenes/EnemiesBoss/Enemy_boss_11_1.tscn").instantiate()
		enemy.get_node("Sprite2D").texture = load("res://Assets/Props/enemy_11_" + str(i) + ".png")
		enemy.names = self.names
		enemy.id = self.id
		enemy.hp = self.hp / 2
		enemy.current_speed = self.current_speed
		enemy.speed = self.current_speed
		enemy.duration_speed_mod = 0
		
		# --- ИСПРАВЛЕНИЕ ПОДКЛЮЧЕНИЯ СИГНАЛА ---
		# Пытаемся найти PlayerContainer (для PvP)
		var container = find_parent("Player1Container")
		if not container:
			container = find_parent("Player2Container")
		
		if container and container.has_method("on_base_damage"):
			enemy.base_damage.connect(container.on_base_damage)
		elif get_tree().current_scene.has_method("on_base_damage"):
			# Фолбэк для одиночной игры
			enemy.base_damage.connect(get_tree().current_scene.on_base_damage)
		# ----------------------------------------

		enemy.parent = self
		enemy.ind = i - 1
		
		# Ищем карту через родителя, а не глобально
		var map_node = find_parent("Map")
		if map_node:
			var path_node = map_node.get_node("Path")
			var num_paths = path_node.get_child_count()
			var path_index = randi_range(0, num_paths - 1)
			path_node.get_child(path_index).add_child(enemy, true)
			list_children.append(enemy)
		
		await get_tree().create_timer(0.15).timeout
		if not is_instance_valid(self): break # Если босс умер в процессе спавна

func fire() -> void:
	if is_spectator_enemy: return
	
	is_ready = false
	for i in range(len(list_children)):
		# Проверка на валидность, так как дети могут быть уже убиты
		if is_instance_valid(list_children[i]) and list_children[i] is Enemy_boss_11_1:
			list_children[i].hp += float((list_children[i].hp / 100.0) * 3)
			list_children[i].health_bar.value = list_children[i].hp
			list_children[i].get_node("AnimationPlayer2").play("sprite")
	
	await get_tree().create_timer(3).timeout
	if is_instance_valid(self):
		is_ready = true
