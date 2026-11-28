extends Node

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var tower: Node = (load("res://Scenes/Turrets/Turret_16T1.tscn") as PackedScene).instantiate()
	add_child(tower)
	tower.is_opponent = true
	tower.built = false
	tower.type_attack = GameConstants.TowerType.GUN
	tower.range = float(GameConstants.DATA_TOWER[15].parametr_3[0])
	tower.rof = float(GameConstants.DATA_TOWER[15].parametr_2[0])
	tower.damage = float(GameConstants.DATA_TOWER[15].parametr_1[0][0])
	tower.burn_damage = float(GameConstants.DATA_TOWER[15].parametr_4[0][0])
	tower.multiplier_damage_all = 1.0
	tower.mastery_damage = 1.0
	tower.ability = [false, false]
	tower._initialize()
	tower.built = true

	var enemy: Node = (load("res://Scenes/Enemies/Enemy_1.tscn") as PackedScene).instantiate()
	add_child(enemy)
	enemy.set_physics_process(false)
	enemy.position = Vector2(50.0, 0.0)
	enemy.hp = 1000.0
	enemy.base_hp = 1000.0
	enemy.health_bar.max_value = 1000.0
	enemy.health_bar.value = 1000.0

	# Let Godot's actual physics Area2D acquire the enemy and run the normal tower/burn loops.
	var hp_before: float = enemy.hp
	for _frame in range(22):
		await get_tree().physics_frame
		enemy.process_flame_burn(1.0 / 60.0)
	var hp_after_direct: float = enemy.hp
	var direct_loss: float = hp_before - hp_after_direct
	assert(tower.enemy_array.has(enemy), "tower range Area2D did not acquire real enemy")
	assert(direct_loss >= tower.damage * 4.0, "Flamethrower did not sustain the 0.10s direct-damage cadence")
	assert(enemy.flame_burn_damage > 0.0, "Flamethrower did not apply burn to real enemy")
	tower.built = false
	tower._stop_flame_stream()
	for _frame in range(31):
		await get_tree().physics_frame
		enemy.process_flame_burn(1.0 / 60.0)
	var hp_after_burn: float = enemy.hp
	var burn_loss: float = hp_after_direct - hp_after_burn
	assert(burn_loss >= enemy.flame_burn_damage, "Real enemy burn tick did not lower HP")
	print("FLAME_REAL_COMBAT_PASS range=", tower.range, " 0.10s-direct-loss=", direct_loss, " isolated-burn-loss=", burn_loss, " total=", hp_before - hp_after_burn)
	get_tree().quit(0)
