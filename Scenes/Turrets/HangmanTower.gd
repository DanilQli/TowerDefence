extends TowerBase
class_name HangmanTower

var damage: float = 0.0
var health_level: float = 0
var critical_damage_all
var flag_dib: bool = false

func fire() -> void:
	if not block_damage:
		is_ready = false
		get_node("AnimationPlayer").play("Fire")
		_apply_damage()
		await get_tree().create_timer(rof).timeout
		is_ready = true
	
func _apply_damage() -> void:
	if enemy:
		if enemy.hp < enemy.base_hp / 100.0 * health_level and (enemy is Enemy or self.ability[1]):
			critical_damage_all = enemy.hp
			enemy.on_hit(critical_damage_all, 5, GameConstants.TowerType.GUN)
			flag_dib = true
		else:
			critical_damage_all = critical_damage()
			if flag_dib and self.ability[0]:
				critical_damage_all *= GameConstants.TURRET_9_ABILITY_0
			else:
				enemy.on_hit(critical_damage_all, 0, GameConstants.TowerType.GUN)
			flag_dib = false
		inflicted += critical_damage_all
		emit_signal("damage_inflicted_changed", inflicted)

func critical_damage():
	if randi_range(0, 100) <= GameConstants.CHANCE_CRITICAL_DAMAGE:
		return damage + (DataManager.critical_damage * damage) / 100
	else:
		return damage
		
func _initialize() -> void:
	super._initialize()
	get_node("Range/CollisionShape2D").shape.radius = 0.5 * range
