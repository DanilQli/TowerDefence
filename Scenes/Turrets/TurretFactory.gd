extends Node
class_name TurretFactory

static func create_turret(tower_id: String, position: Vector2) -> TowerBase:
	var path = "res://Scenes/Turrets/%s.tscn" % tower_id
	var scene = load(path)
	if not scene:
		push_error("❌ Can't load turret: " + path)
		return null

	var turret: TowerBase = scene.instantiate()
	var data = DataManager.tower_data.get(tower_id, {})
	if data.is_empty():
		push_error("❌ No data for turret: " + tower_id)
		return null

	turret.type = tower_id
	turret.position = position
	turret.built = true
	turret.type_attack = data["type_attack"]
	turret.type_explosion = data["type_explosion"]
	turret.current_lvl = 0
	turret.max_lvl = GameConstants.NUMBER_LVL_TURRET - 1

	# базовые значения
	turret.rof = data["rof"][0]
	turret.range = data["range"][0]

	if turret is NormalTower:
		turret.damage = data["damage"][0]
	elif turret is SlowTower:
		turret.intensivity = data["intensivity"][0]
		turret.duration = data["duration"][0]
	elif turret is MovementTower:
		turret.distance = data["distance"][0]
	elif turret is AreaTower:
		turret.damage = data["damage"][0]
	elif turret is MoneyTower:
		turret.income = data["income"][0]
		turret.speed = data["speed"][0]
	elif turret is PoisonTower:
		turret.damage = data["damage"][0]
		turret.duration = data["duration"][0]
		turret.tick = data["tick"][0]

	return turret
