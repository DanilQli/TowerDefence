## Система управления улучшениями башни
extends Node
class_name TowerUpgradeSystem
signal upgrades
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
		emit_signal("upgrades")

## Проверка возможности улучшения башни
func can_upgrade() -> bool:
	# Проверяем, не достигнут ли максимальный уровень
	if tower.current_lvl >= tower.max_lvl:
		tower.ui_system.set_max_level_ui()
		return false
	var upd_cost = GameConstants.PriseUnblockCard[GameConstants.DATA_TOWER[tower.id].type].upgrade_for_session[tower.current_lvl]
	if DataManager.data["Turrets"][tower.turret_id].mastery_lvl >= 6:
		upd_cost = MathUtils.round_to_dec(upd_cost * tower.mastery_cost_upgrade, 1)
	return GameSession.current_money_in_game_session >= upd_cost

## Выполнение улучшения башни
func perform_upgrade() -> bool:
	var upgrade_cost = GameConstants.PriseUnblockCard[GameConstants.DATA_TOWER[tower.id].type].upgrade_for_session[tower.current_lvl]
	if DataManager.data["Turrets"][tower.turret_id].mastery_lvl >= 6:
		upgrade_cost = MathUtils.round_to_dec(upgrade_cost * tower.mastery_cost_upgrade, 1)
	if GameSession.current_money_in_game_session - upgrade_cost > 0:
		GameSession.spend_money(upgrade_cost)
		tower.current_lvl += 1
		tower.emit_signal("money_in_game_session_changed")
		
		# Если достигнут максимальный уровень, обновляем UI
		if tower.current_lvl >= tower.max_lvl:
			tower.ui_system.set_max_level_ui()
		else:
			# принудительно обновляем кнопку после апгрейда
			tower.ui_system._check_upgrade_possibility()
			
		return true
	return false

## Применение эффектов улучшения
func apply_upgrade_effects() -> void:
	_upgrade_combat_tower()
	
## Улучшение боевой башни
func _upgrade_combat_tower() -> void:
	var tower_data = DataManager.tower_data[tower.type]
	var data = GameConstants.DATA_TOWER[tower.id]
	for i in range(len(data.text)):
		if data["parametr_" + str(i + 1)] is Dictionary:
			tower[data.data[i]] = data["parametr_" + str(i + 1)][int(tower_data["level"])][tower.current_lvl]
		else:
			tower[data.data[i]] = data["parametr_" + str(i + 1)][tower.current_lvl]
	tower.get_node("Range/CollisionShape2D").get_shape().radius = 0.5 * tower.range

## Обновление UI после улучшения
func update_ui() -> void:
	tower.ui_system.update_menu()
	tower.ui_system.update_menu_upgrade()
