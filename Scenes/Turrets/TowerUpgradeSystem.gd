## Система управления улучшениями башни
extends Node
class_name TowerUpgradeSystem

## Ссылка на башню, которой принадлежит система улучшений
var tower: TowerBase

## Инициализация системы улучшений
func setup(tower_base: TowerBase) -> void:
	tower = tower_base
	_connect_signals()

## Подключение сигналов для улучшения
func _connect_signals() -> void:
	tower.get_node("Menu/V/HButton/Up").pressed.connect(upgrade)
	tower.get_node("Menu/V/HButton/Up").disabled = true

## Основной метод улучшения башни
func upgrade() -> void:
	if not can_upgrade():
		return
		
	if perform_upgrade():
		apply_upgrade_effects()
		update_ui()

## Проверка возможности улучшения башни
func can_upgrade() -> bool:
	# Проверяем, не достигнут ли максимальный уровень
	if tower.current_lvl >= tower.max_lvl:
		tower.ui_system.set_max_level_ui()
		return false
		
	return GameSession.current_money_in_game_session >= DataManager.tower_data[tower.type]["upgrade_for"][tower.current_lvl]

## Выполнение улучшения башни
func perform_upgrade() -> bool:
	var upgrade_cost = DataManager.tower_data[tower.type]["upgrade_for"][tower.current_lvl]
	
	if GameSession.current_money_in_game_session - upgrade_cost > 0:
		GameSession.spend_money(upgrade_cost)
		tower.current_lvl += 1
		tower.emit_signal("money_in_game_session_changed")
		
		# Если достигнут максимальный уровень, обновляем UI
		if tower.current_lvl >= tower.max_lvl:
			tower.ui_system.set_max_level_ui()
			
		return true
	
	tower.get_node("Menu/V/HButton/Up").disabled = true
	return false

## Применение эффектов улучшения
func apply_upgrade_effects() -> void:
	if tower.type_attack != GameConstants.TowerType.MONEY:
		_upgrade_combat_tower()
	else:
		_upgrade_money_tower()

## Улучшение боевой башни
func _upgrade_combat_tower() -> void:
	var tower_data = DataManager.tower_data[tower.type]
	
	match tower.type_attack:
		GameConstants.TowerType.NORMAL, GameConstants.TowerType.AREA:
			tower.damage = tower_data["damage"][tower.current_lvl]
		GameConstants.TowerType.SLOW:
			tower.intensivity = tower_data["intensivity"][tower.current_lvl]
			tower.duration = tower_data["duration"][tower.current_lvl]
		GameConstants.TowerType.MOVEMENT:
			tower.duration = tower_data["distance"][tower.current_lvl]
		GameConstants.TowerType.POISON:
			tower.damage = tower_data["damage"][tower.current_lvl]
			tower.duration = tower_data["duration"][tower.current_lvl]
			tower.tick = tower_data["tick"][tower.current_lvl]
	tower.rof = tower_data["rof"][tower.current_lvl]
	tower.range = tower_data["range"][tower.current_lvl]
	tower.get_node("Range/CollisionShape2D").get_shape().radius = 0.5 * tower.range

## Улучшение денежной башни
func _upgrade_money_tower() -> void:
	var tower_data = DataManager.tower_data[tower.type]
	tower.speed = tower_data["speed"][tower.current_lvl]
	tower.income = tower_data["income"][tower.current_lvl]

## Обновление UI после улучшения
func update_ui() -> void:
	tower.ui_system.update_menu()
	
	tower.ui_system.update_menu_upgrade()
