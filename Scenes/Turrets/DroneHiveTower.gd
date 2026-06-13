# Scenes/Turrets/DroneHiveTower.gd
extends TowerBase
class_name DroneHiveTower

@onready var token_label_p = $TokenLabel
@onready var token_label = $TokenLabel/Label
var drone_scene = preload("res://Scenes/Turrets/Drone.tscn")

var accumulated_tokens := 0
var drone_damage_bonus := 1.0

# Параметры башни
var damage: float = 0.0

# Параметры дронов
var drone_base_damage := 100.0
var drone_speed := 300.0
var drone_lifetime := 15.0
var spawn_interval := 20.0
var attack_interval: = 1.00

var drone_timer: Timer

func _initialize():
	super._initialize()
	if ability[1]:
		drone_damage_bonus = 2
	
	# Создаем таймер для дронов
	drone_timer = Timer.new()
	drone_timer.one_shot = true
	drone_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(drone_timer)
	drone_timer.start(3.0) # Первый запуск через 3 сек

func _on_spawn_timer_timeout():
	if not is_instance_valid(self): return
	
	# Проверяем, есть ли враги на карте. 
	# Используем глобальный поиск, так как дроны летают по всей карте
	var all_enemies = get_tree().get_nodes_in_group("enemies")
	var valid_enemies = []
	
	# Фильтруем врагов, чтобы атаковать только врагов на СВОЕМ поле (если PvP)
	# Для этого ищем родительский контейнер
	var my_map = find_parent("Map")
	if my_map:
		for e in all_enemies:
			if is_instance_valid(e) and my_map.is_ancestor_of(e):
				valid_enemies.append(e)
	else:
		# Если не нашли карту (например, тест), берем всех
		valid_enemies = all_enemies

	if valid_enemies.is_empty():
		# Врагов нет, пробуем через 2 секунды
		drone_timer.start(2.0)
		return

	# Спавним дронов
	_spawn_drone_with_strategy(GameConstants.TowerDroneStrategy.SCOUT)
	_spawn_drone_with_strategy(GameConstants.TowerDroneStrategy.INTERCEPTOR)
		
	if ability[0] and randf() < 0.5:
		_spawn_drone_with_strategy(GameConstants.TowerDroneStrategy.RANDOM)
		
	accumulated_tokens = 0
	token_label_p.visible = false
	
	# Перезапускаем таймер с учетом скорострельности
	drone_timer.start(multiplier_rof_all * spawn_interval)

func _spawn_drone_with_strategy(strategy: GameConstants.TowerDroneStrategy):
	var drone = drone_scene.instantiate()
	# Добавляем дрона в текущую сцену (или в карту, чтобы он был виден)
	var parent_node = get_parent().get_parent() # Обычно это Map
	if parent_node:
		parent_node.add_child(drone)
	else:
		get_tree().current_scene.add_child(drone)
		
	drone.global_position = global_position
	
	# Расчет урона дрона
	var final_damage = (drone_base_damage + (damage * 0.5)) * (1.0 + (accumulated_tokens * drone_damage_bonus / 100.0))
	
	drone.launch(self, strategy, final_damage, drone_speed, drone_lifetime, attack_interval)
	
func report_drone_return(tokens_earned: int):
	accumulated_tokens += tokens_earned

	if accumulated_tokens > 0:
		token_label_p.visible = true
		token_label.text = str(accumulated_tokens)
	else:
		token_label_p.visible = false

# Стандартная стрельба самой башни
func fire():
	super.fire()
	if not block_damage and is_ready and is_instance_valid(enemy):
		is_ready = false
		get_node("AnimationPlayer").play("Fire")
		_apply_damage()
		await get_tree().create_timer(multiplier_rof_all * rof * mastery_speed).timeout
		is_ready = true
	
func _apply_damage():
	if is_instance_valid(enemy):
		var crit = critical_damage()
		func_add_deal_damage(crit)
		inflicted += crit
		enemy.on_hit(crit, 0, GameConstants.TowerType.GUN, self)
		emit_signal("damage_inflicted_changed", inflicted)

func critical_damage():
	if force_next_attack_crit or randi_range(0, 100) <= GameConstants.CHANCE_CRITICAL_DAMAGE * mastery_chanse_crit:
		emit_signal("tower_crit", self)
		force_next_attack_crit = false
		if enemy is Enemy_boss:
			return (damage * multiplier_damage_all * mastery_damage * mastery_damage_boss) + (DataManager.critical_damage * (damage * multiplier_damage_all * mastery_damage * mastery_damage_boss)) / 100
		return (damage * multiplier_damage_all * mastery_damage) + (DataManager.critical_damage * (damage * multiplier_damage_all * mastery_damage)) / 100
	else:
		if enemy is Enemy_boss:
			return damage * multiplier_damage_all * mastery_damage * mastery_damage_boss
		return damage * multiplier_damage_all * mastery_damage
