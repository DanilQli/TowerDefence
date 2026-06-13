extends TowerBase
class_name GunTower

var damage: float = 0.0
var damage_reduction: int = 0
var current_damage_up
var critical_damage_all

func fire() -> void:
	super.fire()
	if not block_damage:
		is_ready = false
		get_node("AnimationPlayer").play("Fire")
		_apply_damage()
		await get_tree().create_timer((multiplier_rof_all * rof * mastery_speed)).timeout
		is_ready = true
	
func _apply_damage() -> void:
	current_damage_up = DataManager.critical_damage
	if enemy and self.ability[1]:
		current_damage_up += randi_range(0, 40)
	if enemy:
		critical_damage_all = critical_damage()
		func_add_deal_damage(critical_damage_all)
		inflicted += critical_damage_all
		enemy.on_hit(critical_damage_all, 0, GameConstants.TowerType.GUN, self)
		emit_signal("damage_inflicted_changed", inflicted)
	if self.ability[0] and randi_range(0, 100) <= GameConstants.CHANCE_AGAIN_DAMAGE:
		critical_damage_all = critical_damage()
		func_add_deal_damage(critical_damage_all)
		inflicted += critical_damage_all
		enemy.on_hit(critical_damage_all, 0, GameConstants.TowerType.GUN, self)
		emit_signal("damage_inflicted_changed", inflicted)

func critical_damage():
	if force_next_attack_crit or randi_range(0, 100) <= GameConstants.CHANCE_CRITICAL_DAMAGE * mastery_chanse_crit:
		emit_signal("tower_crit", self)
		force_next_attack_crit = false
		if enemy is Enemy_boss:
			return (damage * multiplier_damage_all * mastery_damage * mastery_damage_boss) + (current_damage_up * (damage * multiplier_damage_all * mastery_damage * mastery_damage_boss)) / 100 + randi_range(0, damage_reduction)
		return (damage * multiplier_damage_all * mastery_damage) + (current_damage_up * (damage * multiplier_damage_all * mastery_damage)) / 100 + randi_range(0, damage_reduction)
	else:
		if enemy is Enemy_boss:
			return (damage * multiplier_damage_all * mastery_damage * mastery_damage_boss) + randi_range(0, damage_reduction)
		return (damage * multiplier_damage_all * mastery_damage) + randi_range(0, damage_reduction)
		
func _initialize() -> void:
	super._initialize()
	get_node("Range/CollisionShape2D").shape.radius = 0.5 * range
