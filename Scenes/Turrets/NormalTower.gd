extends TowerBase
class_name NormalTower

var damage: float = 0.0

func fire() -> void:
	is_ready = false
	get_node("AnimationPlayer").play("Fire")
	_apply_damage()
	await get_tree().create_timer(rof).timeout
	is_ready = true

func _apply_damage() -> void:
	if enemy:
		inflicted += damage
		enemy.on_hit(damage, type, 0, GameConstants.TowerType.NORMAL, current_lvl)
		emit_signal("damage_inflicted_changed", inflicted)

func _initialize() -> void:
	get_node("Range/CollisionShape2D").shape.radius = 0.5 * range
