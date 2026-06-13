extends TowerBase
class_name AreaTower

var damage: float = 0.0
var target: int = 1
var ability_0: int = 0
var dam
var chance_dop: float = 0

func fire() -> void:
	super.fire()
	if not block_damage:
		is_ready = false
		get_node("AnimationPlayer").play("Fire")
		_apply_damage()
		await get_tree().create_timer(multiplier_rof_all * rof * mastery_speed).timeout
		is_ready = true

func _apply_damage() -> void:
	var alredy = 0
	chance_dop = (len(ResourceManager.list_turret[1]) * 5.0) / 100.0
	for e in enemy_array:
		if is_instance_valid(e):
			dam = critical_damage()
			inflicted += dam
			func_add_deal_damage(dam)
			e.on_hit(dam, 0, GameConstants.TowerType.AREA, self)
			alredy += 1
			emit_signal("damage_inflicted_changed", inflicted)
		if alredy >= target:
			break

func critical_damage():
	var damage_all = (damage * multiplier_damage_all * mastery_damage) + ability_0 * GameConstants.TURRET_1_ABILITY_1
	if force_next_attack_crit or randi_range(0, 100) <= (GameConstants.CHANCE_CRITICAL_DAMAGE + chance_dop) * mastery_chanse_crit:
		emit_signal("tower_crit", self)
		force_next_attack_crit = false
		if enemy is Enemy_boss:
			return (damage_all * mastery_damage_boss) + (DataManager.critical_damage * (damage_all * mastery_damage_boss)) / 100
		return damage_all + (DataManager.critical_damage * damage_all) / 100
	else:
		if enemy is Enemy_boss:
			return damage_all * mastery_damage_boss
		return damage_all
		
func _initialize() -> void:
	super._initialize()
	get_node("Range/CollisionShape2D").shape.radius = 0.5 * range
