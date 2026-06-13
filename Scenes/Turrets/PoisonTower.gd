# PoisonTower.gd
extends TowerBase
class_name PoisonTower

var damage: float
var duration: float
var tick: float

var num: bool = false

func fire() -> void:
	super.fire()
	if not block_damage and is_ready:
		is_ready = false
		
		var max_targets = 1
		if self.ability[1] and randf_range(0, 100) < GameConstants.TURRET_7_ABILITY_1:
			max_targets = 2
		
		var targets_hit = 0
		for e in enemy_array:
			if is_instance_valid(e):
				# Применяем яд
				if e is Enemy_boss:
					e.apply_poison({
						"damage": (damage * multiplier_damage_all * mastery_damage * mastery_damage_boss),
						"duration": duration,
						"tick": tick
					})
				else:
					e.apply_poison({
						"damage": (damage * multiplier_damage_all * mastery_damage),
						"duration": duration,
						"tick": tick
					})
				
				targets_hit += 1
				if targets_hit >= max_targets:
					break
