# PoisonTower.gd
extends TowerBase
class_name PoisonTower

var damage: float
var duration: float
var tick: float

var num: bool = false

var mastery_damage: float = 1.0
var mastery_speed: float = 1.0
var mastery_chanse_crit: float = 1.0
var mastery_cost_upgrade: float = 1.0
var mastery_damage_boss: float = 1.0

func fire() -> void:
	super.fire()
	if not block_damage:
		is_ready = false
		for e in enemy_array:
			if enemy is Enemy_boss:
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
			func_add_deal_damage((damage * multiplier_damage_all * mastery_damage) * (duration / 1.0 / tick))
			if self.ability[0]:
				e.on_hit(GameConstants.TURRET_7_ABILITY_0, 0, GameConstants.TowerType.SLOW, self, duration)
			if self.ability[1]:
				if num:
					break
				if randf_range(0, 100) < GameConstants.TURRET_7_ABILITY_1:
					num = true
			else:
				break
		get_node("AnimationPlayer").play("Fire")
		await get_tree().create_timer((multiplier_rof_all * rof * mastery_speed)).timeout
		is_ready = true
