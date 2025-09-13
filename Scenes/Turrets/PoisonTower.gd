# PoisonTower.gd
extends TowerBase
class_name PoisonTower

var damage: float
var duration: float
var tick: float

var num: bool = false

func fire() -> void:
	super.fire()
	if not block_damage:
		is_ready = false
		for e in enemy_array:
			e.apply_poison({
				"damage": (damage * multiplier_damage_all),
				"duration": duration,
				"tick": tick
			})
			func_add_deal_damage((damage * multiplier_damage_all) * (duration / 1.0 / tick))
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
		await get_tree().create_timer((multiplier_rof_all * rof)).timeout
		is_ready = true
