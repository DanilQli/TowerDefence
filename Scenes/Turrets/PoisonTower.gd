# PoisonTower.gd
extends TowerBase
class_name PoisonTower

var damage: float
var duration: float = 4.0
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
