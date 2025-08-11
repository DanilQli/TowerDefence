extends Enemy_boss
class_name Enemy_boss_6

var rng = RandomNumberGenerator.new()

func fire() -> void:
	if is_ready:
		is_ready = false
		var list_ind = []
		for i in range(len(ResourceManager.list_turret) - 1):
			if len(ResourceManager.list_turret[i]) > 0:
				list_ind.append(i)
		var indexx = rng.randi_range(0, len(list_ind) - 1)
		if len(list_ind) > 0:
			var ind = list_ind[indexx]
			var index = rng.randi_range(0, len(ResourceManager.list_turret[ind]) - 1)
			var new_impact = projectile_impact_1.instantiate()
			new_impact.position = ResourceManager.list_turret[ind][index].global_position
			new_impact.z_index = 5
			new_impact.scale = Vector2i(1, 1)
			get_tree().root.get_node(".").add_child(new_impact)
			ResourceManager.list_turret[ind][index].queue_free()
			ResourceManager.list_turret[ind].pop_at(index)
