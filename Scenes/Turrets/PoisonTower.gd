# PoisonTower.gd
extends TowerBase
class_name PoisonTower

var damage: float
var duration: float
var tick: float

func fire() -> void:
	is_ready = false
	if enemy:
		enemy.apply_poison({
			"damage": damage,
			"duration": duration,
			"tick": tick
		})
	get_node("AnimationPlayer").play("Fire")
	await get_tree().create_timer(rof).timeout
	is_ready = true
