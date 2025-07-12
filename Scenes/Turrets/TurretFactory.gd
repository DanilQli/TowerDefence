extends Node
class_name TurretFactory

static func create_turret(tower_id: String, position: Vector2) -> TowerBase:
	var path = "res://Scenes/Turrets/%s.tscn" % tower_id
	var scene = load(path)
	if not scene:
		push_error("❌ Can't load turret: " + path)
		return null

	var turret: TowerBase = scene.instantiate()
	var tower_data = DataManager.tower_data.get(tower_id, {})
	var parts = tower_id.left(tower_id.length() - 2).split("_")
	var number_str = parts[parts.size() - 1]
	turret.type = tower_id
	turret.id = int(number_str) - 1
	var data = GameConstants.DATA_TOWER[turret.id]
	turret.position = position
	turret.built = true
	turret.type_attack = data.type_attack
	turret.type_explosion = data.type_explosion
	turret.current_lvl = 0
	turret.max_lvl = GameConstants.NUMBER_LVL_TURRET - 1
	ResourceManager.list_turret[turret.id].append(turret)
	# базовые значения
	turret.ability = tower_data["ability"]
	for i in range(len(data.text)):
		if data["parametr_" + str(i + 1)] is Dictionary:
			turret[data.data[i]] = data["parametr_" + str(i + 1)][int(tower_data["level"])][0]
		else:
			turret[data.data[i]] = data["parametr_" + str(i + 1)][0]
	if turret.id == 5:
		if turret.ability[1]:
			turret.get_node("Panel").visible = true
			for i in range(len(ResourceManager.list_turret[turret.id])):
				ResourceManager.list_turret[turret.id][i].get_node("Panel/Label").text = str(len(ResourceManager.list_turret[turret.id]))
				ResourceManager.list_turret[turret.id][i].update()
		for i in range(len(ResourceManager.list_turret[turret.id])):
			ResourceManager.list_turret[turret.id][i].update()

	return turret
