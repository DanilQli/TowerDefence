# TurretFactory.gd
# Создание и конфигурация башен по данным

extends Node
class_name TurretFactory

## Создает и настраивает башню по идентификатору и позиции
static func create_turret(tower_id: String, position: Vector2) -> TowerBase:
	var scene_path = "res://Scenes/Turrets/" + tower_id + ".tscn"
	var tower_scene = load(scene_path)
	if not tower_scene:
		push_error("❌ Не удалось загрузить башню: " + scene_path)
		return null
	
	var tower: TowerBase = tower_scene.instantiate()
	var data: Dictionary = DataManager.tower_data.get(tower_id, {})

	if data.is_empty():
		push_error("❌ Нет данных о башне: " + tower_id)
		return null
	
	# Базовые параметры
	tower.type = tower_id
	tower.position = position
	tower.built = true
	tower.type_attack = data["type_attack"]
	tower.type_explosion = data["type_explosion"]
	tower.current_lvl = 0
	tower.max_lvl = data.get("damage", []).size() - 1  # может быть другой стат

	# Настройки по типу атаки
	match tower.type_attack:
		GameConstants.TowerType.NORMAL, GameConstants.TowerType.AREA:
			tower.damage = data["damage"][0]
		GameConstants.TowerType.SLOW:
			tower.intensivity = data["intensivity"][0]
			tower.duration = data["duration"][0]
		GameConstants.TowerType.MOVEMENT:
			tower.duration = data["distance"][0]
		GameConstants.TowerType.MONEY:
			tower.income = data["income"][0]
			tower.speed = data["speed"][0]
			# У денежной башни не нужно дальше настраивать
			return tower

	# Настройка боевых параметров
	tower.rof = data["rof"][0]
	tower.range = data["range"][0]
	tower.strategy = 0  # может быть вытащено из `data` позже

	return tower
