extends TowerBase
class_name CrossnowTower

var damage: float = 0.0
var phase: bool = false
var duration_1: float = 0.0
var duration_2: float = 0.0
var up_attack_speed: float = 0.0
var critical_damage_all

func fire() -> void:
	if not block_damage:
		is_ready = false
		get_node("AnimationPlayer").play("Fire")
		_apply_damage()
		await get_tree().create_timer(rof).timeout
		is_ready = true
	
func _apply_damage() -> void:
	if enemy:
		critical_damage_all = critical_damage()
		inflicted += critical_damage_all
		enemy.on_hit(critical_damage_all, type, 0, GameConstants.TowerType.GUN, current_lvl)
		emit_signal("damage_inflicted_changed", inflicted)

func critical_damage():
	if randi_range(0, 100) <= GameConstants.CHANCE_CRITICAL_DAMAGE:
		return damage + (DataManager.critical_damage * damage) / 100
	else:
		return damage
		
func _initialize() -> void:
	super._initialize()
	get_node("Range/CollisionShape2D").shape.radius = 0.5 * range
