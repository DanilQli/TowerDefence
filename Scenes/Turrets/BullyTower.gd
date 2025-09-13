extends TowerBase
class_name BillyTower

var damage: float = 0.0
var damage_new: float = damage
var critical_damage_all: float = 0.0
var bonus_damage: int = 0
var bonus_speed_attack: int = 0
var rang = RandomNumberGenerator.new()
var rage: int = 0
var rof_new: float = rof
var dop_mn: float = 0.0

func _initialize() -> void:
	super._initialize()
	get_node("Range/CollisionShape2D").shape.radius = 0.5 * range
	rof_new = rof
	
func fire() -> void:
	super.fire()
	if not block_damage:
		is_ready = false
		get_node("AnimationPlayer").play("Fire")
		_apply_damage()
		await get_tree().create_timer(rof_new).timeout
		is_ready = true
	
func _apply_damage() -> void:
	if enemy:
		if self.ability[1]:
			dop_mn = len(ResourceManager.list_active_enemy)
			if dop_mn > GameConstants.TURRET_10_ABILITY_1[1]:
				dop_mn = 1 + GameConstants.TURRET_10_ABILITY_1[0] * GameConstants.TURRET_10_ABILITY_1[1] / 100.0
		if rage in [0, 1] and self.ability[0] and enemy is Enemy_boss and rang.randi_range(0, 100) <= GameConstants.TURRET_10_ABILITY_0[0]:
			critical_damage_all = critical_damage() * GameConstants.TURRET_10_ABILITY_0[1] / 100.0
			rage_attack()
		elif (rage == 0 and len(ResourceManager.list_active_enemy) > 5 and rang.randi_range(0, 100) <= 15) or (rage == 0 and enemy is Enemy_boss):
			rage = 1
			rage_interval()
			critical_damage_all = critical_damage()
			rage_attack()
		elif rage in [0, 1]:
			critical_damage_all = critical_damage()
			rage_attack()

func rage_attack():
	inflicted += critical_damage_all
	func_add_deal_damage(critical_damage_all)
	enemy.on_hit(critical_damage_all, 0, GameConstants.TowerType.GUN, self)
	emit_signal("damage_inflicted_changed", inflicted)
	
func rage_interval():
	rof_new = rof / (1 + bonus_speed_attack / 100.0)* multiplier_rof_all
	damage_new = (damage * multiplier_damage_all) * (1 + bonus_damage / 100.0)
	self.get_node("Turret").modulate = Color(0.7, 0.7, 0.7)
	await get_tree().create_timer(10).timeout
	self.get_node("Turret").modulate = Color(0.1, 0.1, 0.1)
	rage = 2
	rof_new = 3 * multiplier_rof_all
	await get_tree().create_timer(3).timeout
	self.get_node("Turret").modulate = Color(1, 1, 1)
	rof_new = multiplier_rof_all * rof
	damage_new = (damage * multiplier_damage_all)
	rage = 0
	
func critical_damage():
	if force_next_attack_crit or randi_range(0, 100) <= GameConstants.CHANCE_CRITICAL_DAMAGE:
		emit_signal("tower_crit", self)
		force_next_attack_crit = false
		if self.ability[1]:
			return (damage_new + (DataManager.critical_damage * damage_new) / 100) * dop_mn
		else:
			return damage_new + (DataManager.critical_damage * damage_new) / 100
	else:
		if self.ability[1]:
			return damage_new * dop_mn
		else:
			return damage_new
