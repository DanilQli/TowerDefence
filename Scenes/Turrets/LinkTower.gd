# LinkTower.gd — полная, переработанная версия
extends TowerBase
class_name LinkTower

enum LinkDirection { HORIZONTAL, VERTICAL }

var linked_towers: Array[TowerBase]
var link_line_scene = preload("res://Scenes/SupportScenes/LinkLine.tscn")
var link_lines: Array[Line2D]

var damage_buff := 0.10
var damage: float
var _update_pending := false

func _initialize():
	super._initialize()
	type_attack = -1
	
	if ability[1]:
		damage_buff = 0.15
	
	get_tree().node_added.connect(_on_node_changed)
	get_tree().node_removed.connect(_on_node_changed)
	
	_schedule_update()

func _schedule_update():
	# Если обновление уже запланировано, ничего не делаем
	if _update_pending:
		return
	
	_update_pending = true
	# Вызываем обновление в конце кадра, чтобы все узлы успели добавиться/удалиться
	call_deferred("_perform_update")

func _perform_update():
	_update_links()
	# Сбрасываем флаг, чтобы следующее обновление могло быть запланировано
	_update_pending = false

func _update_links():
	_clear_old_links()
	
	var neighbors = _find_neighbors()
	for neighbor in neighbors:
		linked_towers.append(neighbor)
		_apply_buffs(neighbor)
		_create_link_line(neighbor)
		
	var network = _get_full_network()
	if not network.is_empty():
		network[0]._check_chain_synergy()
	
func _clear_old_links():
	for line in link_lines:
		if is_instance_valid(line): line.queue_free()
	link_lines.clear()
	
	for tower in linked_towers:
		if is_instance_valid(tower): _remove_buffs(tower)
	linked_towers.clear()

func _find_neighbors():
	var turret_layer = get_parent()
	if not is_instance_valid(turret_layer): return []
	
	var neighbors = []
	var cell_size = 64
	
	for tower in turret_layer.get_children():
		if tower == self or not tower is TowerBase or tower is LinkTower: continue
		
		var pos_diff = tower.global_position - global_position
		var is_horizontal = abs(pos_diff.y) < 10 and abs(pos_diff.x) < cell_size + 10
		var is_vertical = abs(pos_diff.x) < 10 and abs(pos_diff.y) < cell_size + 10
		
		if is_horizontal or is_vertical:
			neighbors.append(tower)
				
	return neighbors

func _apply_buffs(tower: TowerBase):
	tower.multiplier_damage_link = damage_buff
	tower.is_protected_by_link = true
	tower.tower_crit.connect(_on_linked_tower_crit)

func _remove_buffs(tower: TowerBase):
	if is_instance_valid(tower):
		tower.multiplier_damage_link = 0
		tower.is_protected_by_link = false
		if tower.tower_crit.is_connected(_on_linked_tower_crit):
			tower.tower_crit.disconnect(_on_linked_tower_crit)

# --- Проверка синергии цепочки (Способность 7 уровня) ---
func _check_chain_synergy():
	# 1. Проверяем, достигнут ли уровень способности
	if not ability[0]:
		# Сначала сбросим все старые бонусы, если они были
		_reset_all_synergy_buffs()
		return

	# 2. Находим всю связанную сеть LinkTower'ов
	var network_links = _get_full_network()
	
	# 3. Считаем, сколько раз каждый тип башни связан в сети
	var connection_counts: Dictionary = {}
	for link_tower in network_links:
		for linked_tower in link_tower.linked_towers:
			# Убеждаемся, что это не LinkTower
			if not linked_tower is LinkTower:
				connection_counts[linked_tower.type] = connection_counts.get(linked_tower.type, 0) + 1

	# 4. Сначала сбрасываем все старые бонусы, чтобы избежать дублирования
	_reset_all_synergy_buffs()

	# 5. Применяем новые бонусы, если условие выполнено
	for tower_type in connection_counts:
		if connection_counts[tower_type] >= 6:
			# Применяем бафф ко всем башням этого типа во всей сети
			for link_tower in network_links:
				for linked_tower in link_tower.linked_towers:
					if is_instance_valid(linked_tower) and linked_tower.type == tower_type:
						if not linked_tower.has_meta("synergy_buff"):
							linked_tower.multiplier_rof_link = 2.0 # Увеличиваем скорость атаки в 2 раза
							linked_tower.set_meta("synergy_buff", true) # Ставим метку, чтобы не бафнуть дважды

func _get_full_network():
	var network = [self]
	var queue = [self]
	var visited = {self: true}
	
	while not queue.is_empty():
		var current_link = queue.pop_front()
		
		# Ищем другие LinkTower через общие связанные башни
		for linked_tower in current_link.linked_towers:
			if not linked_tower is LinkTower:
				# Проверяем, связана ли эта башня с другими LinkTower
				var other_links = _find_links_connected_to(linked_tower)
				for other_link in other_links:
					if not visited.has(other_link):
						visited[other_link] = true
						network.append(other_link)
						queue.append(other_link)
	return network

func _find_links_connected_to(tower: TowerBase):
	var links = []
	var turret_layer = get_parent()
	if not is_instance_valid(turret_layer): return links
	
	for node in turret_layer.get_children():
		if node is LinkTower and node.linked_towers.has(tower):
			links.append(node)
	return links

func _reset_all_synergy_buffs():
	var all_towers = get_parent().get_children()
	for tower in all_towers:
		if tower is TowerBase and tower.has_meta("synergy_buff"):
			tower.multiplier_rof_link = 1.0
			tower.remove_meta("synergy_buff")
			
func _get_full_chain():
	var chain = [self]
	var queue = linked_towers.duplicate()
	var visited = {self: true}
	
	while not queue.is_empty():
		var current = queue.pop_front()
		if visited.has(current): continue
		
		visited[current] = true
		chain.append(current)
		
		if current is LinkTower:
			for neighbor in current.linked_towers:
				if not visited.has(neighbor):
					queue.append(neighbor)
	return chain
	
func _create_link_line(target: Node2D):
	var line = link_line_scene.instantiate()
	add_child(line)
	link_lines.append(line)
	# Начальная точка - центр самой LinkTower
	line.add_point(Vector2.ZERO)
	# Конечная точка - позиция соседа в локальных координатах
	line.add_point(to_local(target.global_position))

func _physics_process(delta):
	super._physics_process(delta) # Вызываем родительский метод
	
	# Обновляем позиции линий в каждом кадре
	for i in range(linked_towers.size()):
		if is_instance_valid(linked_towers[i]) and i < link_lines.size():
			var target_pos_local = to_local(linked_towers[i].global_position)
			link_lines[i].set_point_position(1, target_pos_local)
		else:
			# Если соседняя башня была удалена, обновляем все связи
			_update_links()
			return # Выходим, чтобы избежать ошибок в этом кадре

func _on_node_changed(node):
	if node is TowerBase:
		_schedule_update()

func _on_linked_tower_crit(tower: TowerBase):
	for linked in linked_towers:
		if linked != tower and is_instance_valid(linked):
			linked.force_next_attack_crit = true
