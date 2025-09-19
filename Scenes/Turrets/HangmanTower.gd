extends TowerBase
class_name HangmanTower

var damage: float = 0.0
var health_level: float = 0
var critical_damage_all
var flag_dib: bool = false

var mastery_damage: float = 1.0
var mastery_speed: float = 1.0
var mastery_chanse_crit: float = 1.0
var mastery_cost_upgrade: float = 1.0
var mastery_damage_boss: float = 1.0

func fire() -> void:
	super.fire()
	if not block_damage:
		is_ready = false
		get_node("AnimationPlayer").play("Fire")
		_apply_damage()
		await get_tree().create_timer((multiplier_rof_all * rof * mastery_speed)).timeout
		is_ready = true
	
func _apply_damage() -> void:
	if enemy:
		if enemy.hp < enemy.base_hp / 100.0 * health_level and (enemy is Enemy or self.ability[1]):
			critical_damage_all = enemy.hp
			enemy.on_hit(critical_damage_all, 5, GameConstants.TowerType.GUN, self)
			flag_dib = true
		else:
			critical_damage_all = critical_damage()
			if flag_dib and self.ability[0]:
				critical_damage_all *= GameConstants.TURRET_9_ABILITY_0
				func_add_deal_damage(critical_damage_all)
			else:
				func_add_deal_damage(critical_damage_all)
				enemy.on_hit(critical_damage_all, 0, GameConstants.TowerType.GUN, self)
			flag_dib = false
		inflicted += critical_damage_all
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
		
func _initialize() -> void:
	super._initialize()
	get_node("Range/CollisionShape2D").shape.radius = 0.5 * range
