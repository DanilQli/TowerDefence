extends TowerBase
class_name AreaTower

var damage: float = 0.0
var target: int = 1
var ability_0: int = 0
var dam
var chance_dop: int = 0
		
func fire() -> void:
	if not block_damage:
		is_ready = false
		get_node("AnimationPlayer").play("Fire")
		_apply_damage()
		await get_tree().create_timer(rof).timeout
		is_ready = true

func _apply_damage() -> void:
	var alredy = 0
	chance_dop = int(GameConstants.CHANCE_CRITICAL_DAMAGE * (100.0 / len(ResourceManager.list_turret[1]) * 5))
	for e in enemy_array:
		if is_instance_valid(e):
			dam = critical_damage()
			inflicted += dam
			e.on_hit(dam, type, 0, GameConstants.TowerType.AREA, current_lvl)
			alredy += 1
			emit_signal("damage_inflicted_changed", inflicted)
		if alredy >= target:
			break

func critical_damage():
	var damage_all = damage + ability_0 * GameConstants.TURRET_1_ABILITY_1
	if randi_range(0, 100) <= GameConstants.CHANCE_CRITICAL_DAMAGE + chance_dop:
		return damage_all + (DataManager.critical_damage * damage_all) / 100
	else:
		return damage_all
		
func _initialize() -> void:
	super._initialize()
	get_node("Range/CollisionShape2D").shape.radius = 0.5 * range
