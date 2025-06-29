extends TowerBase
class_name AreaTower

var damage: float = 0.0

func fire() -> void:
	is_ready = false
	get_node("AnimationPlayer").play("Fire")
	_apply_damage()
	await get_tree().create_timer(rof).timeout
	is_ready = true

func _apply_damage() -> void:
	for e in enemy_array:
		if is_instance_valid(e):
			e.on_hit(damage, type, 0, GameConstants.TowerType.AREA, current_lvl)

func _initialize() -> void:
	get_node("Range/CollisionShape2D").shape.radius = 0.5 * range
