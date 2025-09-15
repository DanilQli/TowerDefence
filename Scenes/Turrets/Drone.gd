# Drone.gd — улучшенная версия с умным поиском целей
extends Node2D

var strategy: GameConstants.TowerDroneStrategy

var target: Node2D
var damage: float
var speed: float
var tokens_earned := 0
var is_returning := false
var home_tower: Node2D

var lifetime_left: float
var attack_cooldown: float

var off_num: int = 60

var offset := Vector2(-off_num, -off_num)

func launch(home: Node2D, drone_strategy: GameConstants.TowerDroneStrategy, drone_damage: float, drone_speed: float, lifetime: float, attack_interval: float):
	home_tower = home
	strategy = drone_strategy
	damage = drone_damage
	speed = drone_speed
	lifetime_left = lifetime
	attack_cooldown = attack_interval
	find_new_target()
	_on_attack_timer_timeout()
	await get_tree().create_timer(lifetime_left).timeout
	_return_to_base()

func _physics_process(delta):
	if is_returning:
		global_position = global_position.move_toward(home_tower.global_position, speed * delta)
		if global_position.distance_to(home_tower.global_position) < 10:
			home_tower.report_drone_return(tokens_earned)
			queue_free()
	elif is_instance_valid(target):
		var target_pos = calculate_target_position(target.global_position)
		global_position = global_position.move_toward(target_pos, speed * delta)
		var angle = get_node("Turret").global_position.direction_to(target.global_position).angle()
		get_node("Turret").rotation = angle
	else:
		find_new_target()
		if not is_instance_valid(target):
			_return_to_base()

func find_new_target():
	var all_enemies = get_tree().get_nodes_in_group("enemies")
	if all_enemies.is_empty():
		target = null
		return
	
	match strategy:
		GameConstants.TowerDroneStrategy.SCOUT:
			target = _find_first_enemy_global(all_enemies)
		GameConstants.TowerDroneStrategy.INTERCEPTOR:
			target = _find_last_enemy_global(all_enemies)
		GameConstants.TowerDroneStrategy.RANDOM:
			target = all_enemies.pick_random()

func _on_attack_timer_timeout():
	if home_tower:
		if is_instance_valid(target) and global_position.distance_to(target.global_position) < 100:
			if target.has_method("on_hit"):
				get_node("AnimationPlayer").play("Fire")
				target.on_hit(damage, 0, GameConstants.TowerType.GUN, home_tower)
				home_tower.func_add_deal_damage(damage)
				if target.hp <= 0:
					tokens_earned += 1
					target = null
		await get_tree().create_timer(home_tower.multiplier_rof_all * attack_cooldown).timeout
		_on_attack_timer_timeout()
	else:
		queue_free()

func _return_to_base():
	if is_returning: return
	is_returning = true
	target = null
	
# --- Функции поиска (скопированы из DroneHiveTower) ---
func _find_first_enemy_global(enemies: Array) -> Node2D:
	if enemies.is_empty(): return null
	var best_target: Node2D = null
	var max_progress: float = -1.0
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.progress > max_progress:
			max_progress = enemy.progress
			best_target = enemy
	return best_target

func _find_last_enemy_global(enemies: Array) -> Node2D:
	if enemies.is_empty(): return null
	var best_target: Node2D = null
	var min_progress: float = INF
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.progress < min_progress:
			min_progress = enemy.progress
			best_target = enemy
	return best_target

func calculate_target_position(enemy_pos: Vector2) -> Vector2:
	var desired_pos = enemy_pos + offset
	# Обработка краёв экрана
	var screen_size = get_viewport_rect().size
	if desired_pos.x < off_num: # Левый край
		desired_pos.x = enemy_pos.x + abs(offset.x)
	if desired_pos.y < off_num: # Верхний край
		desired_pos.y = enemy_pos.y + abs(offset.y)
	if desired_pos.x > screen_size.x - off_num: # Правый край
		desired_pos.x = enemy_pos.x - abs(offset.x)
	if desired_pos.y > screen_size.y - off_num: # Нижний край
		desired_pos.y = enemy_pos.y - abs(offset.y)
	
	return desired_pos
