extends TowerBase
class_name MovementTower

var distance: float

func fire() -> void:
	is_ready = false
	get_node("AnimationPlayer").play("Fire")
	_apply_damage()
	await get_tree().create_timer(rof).timeout
	is_ready = true

func _apply_damage() -> void:
	if enemy:
		enemy.on_hit(distance, type, 0, GameConstants.TowerType.MOVEMENT, current_lvl)
