extends TowerBase
class_name MovementTower

var distance: float
var dist_end

func _ready() -> void:
	super._ready()
	distance = distance / 100.0
	
func fire() -> void:
	if not block_damage:
		is_ready = false
		get_node("AnimationPlayer").play("Fire")
		_apply_damage()
		await get_tree().create_timer((multiplier_rof_all * rof * mastery_speed)).timeout
		is_ready = true

func _apply_damage() -> void:
	if enemy:
		if self.ability[0] and randi_range(0, 100) < GameConstants.TURRET_5_ABILITY_1:
			dist_end = enemy.progress_ratio
		if self.ability[1] and enemy.base_hp / 10 >= enemy.hp:
			enemy.on_hit(enemy.hp, 0, GameConstants.TowerType.GUN, self)
		else:
			dist_end = distance
			enemy.on_hit(distance, 0, GameConstants.TowerType.MOVING, self)
