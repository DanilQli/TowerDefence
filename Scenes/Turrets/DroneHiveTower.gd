# DroneHiveTower.gd — исправленная версия с атакой и дронами
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

func _initialize():
	super._initialize()
	if ability[1]:
		drone_damage_bonus = 2
	await get_tree().create_timer(3).timeout
	_on_spawn_timer_timeout()

func _on_spawn_timer_timeout():
	# Дроны ищут цели по всей карте, а не только в радиусе башни
	var all_enemies = get_tree().get_nodes_in_group("enemies")
	if all_enemies.is_empty():
		return

	# Спавним дронов со стратегиями
	_spawn_drone_with_strategy(GameConstants.TowerDroneStrategy.SCOUT)
	_spawn_drone_with_strategy(GameConstants.TowerDroneStrategy.INTERCEPTOR)
		
	if ability[0] and randf() < 0.5:
		_spawn_drone_with_strategy(GameConstants.TowerDroneStrategy.RANDOM)
	accumulated_tokens = 0
	token_label_p.visible = false
	await get_tree().create_timer(multiplier_rof_all * spawn_interval).timeout
	_on_spawn_timer_timeout()

func _spawn_drone_with_strategy(strategy: GameConstants.TowerDroneStrategy):
	var drone = drone_scene.instantiate()
	get_tree().current_scene.add_child(drone)
	drone.global_position = global_position
	
	var final_damage = drone_base_damage * (1.0 + (accumulated_tokens * drone_damage_bonus / 100.0))
	
	# Дрон сам найдёт свою первую цель
	drone.launch(self, strategy, final_damage, drone_speed, drone_lifetime, attack_interval)
	drone.find_new_target() # Запускаем поиск сразу после запуска
	
func report_drone_return(tokens_earned: int):
	accumulated_tokens += tokens_earned

	if accumulated_tokens > 0:
		token_label_p.visible = true
		token_label.text = str(accumulated_tokens)
	else:
		token_label_p.visible = false

# --- Атака самой башни (как в GunTower) ---
func fire():
	super.fire()
	if not block_damage and is_ready and is_instance_valid(enemy):
		is_ready = false
		get_node("AnimationPlayer").play("Fire")
		_apply_damage()
		await get_tree().create_timer(multiplier_rof_all * rof).timeout
		is_ready = true
	
func _apply_damage():
	if is_instance_valid(enemy):
		var crit_dmg = critical_damage()
		func_add_deal_damage(crit_dmg)
		inflicted += crit_dmg
		enemy.on_hit(crit_dmg, 0, GameConstants.TowerType.GUN, self)
		emit_signal("damage_inflicted_changed", inflicted)

func critical_damage():
	if force_next_attack_crit or randi_range(0, 100) <= GameConstants.CHANCE_CRITICAL_DAMAGE:
		emit_signal("tower_crit", self)
		force_next_attack_crit = false
		return (damage * multiplier_damage_all) + (DataManager.critical_damage * (damage * multiplier_damage_all)) / 100
	else:
		return (damage * multiplier_damage_all)
