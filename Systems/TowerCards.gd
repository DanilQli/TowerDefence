# TowerCards.gd
extends Node

# Добавление карт башни
func add_cards(tower_id: int, amount: int):
	DataManager.tower_data[DataManager.tower_data.keys()[tower_id]]["cards"] += amount

# Проверка возможности повышения уровня
func check_level_up(tower_id: int) -> bool:
	var tower = DataManager.tower_data[DataManager.tower_data.keys()[tower_id]]
	if tower["level"] >= GameConstants.NUMBER_LVL_TURRET_CARD:
		return false
		
	var cards_needed = get_cards_needed(tower_id)
	if tower["cards"] >= cards_needed:
		return true
	return false

# Получение необходимого количества карт для следующего уровня
static func get_cards_needed(tower_id: int) -> int:
	var tower = DataManager.tower_data[DataManager.tower_data.keys()[tower_id]]
	var level_index = tower["level"] + 1
	var rarity = GameConstants.DATA_TOWER[tower_id].type
	return GameConstants.PriseUnblockCard[rarity].prise_up_card[int(level_index)]

# Повышение уровня башни
func level_up(tower_id: int):
	var cards_needed = get_cards_needed(tower_id)
	DataManager.tower_data[DataManager.tower_data.keys()[tower_id]]["cards"] -= cards_needed
	DataManager.tower_data[DataManager.tower_data.keys()[tower_id]]["level"] += 1
	DataManager.data_money -= GameConstants.CARDS_MONEY_LEVEL[GameConstants.DATA_TOWER[tower_id].type][DataManager.tower_data[DataManager.tower_data.keys()[tower_id]]["level"]]
	DataManager.write_file()
	
