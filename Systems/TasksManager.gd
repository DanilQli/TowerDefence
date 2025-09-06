extends Node

var count_end_game: int #1
var count_spend_money: int #2
var count_end_game_company: int #3
var win_several_times: Array #4
var support_damage: int #5
var support_win_unique_count: int #6
var win_one_hp_count: int #7

var daily_task_update_day: int
var daily_task_update_week: int
var list_tasks_you: Array
# id этапа,id задачи,Нужно,id сундука(или награда в монетах),внутри сундука
var daily_task_career: Array = [[1, 1, 12, 5], [1, 2, 13, 4, [5, 3, 1]], [2, 3, 12, 6], [2, 4, 13, 4, [5, 3, 1]]]
# id этапа,id задачи,Прогресс,Пройдено,Сундук получен
var daily_task_career_you: Array = []
# счётчики заданий
var deal_damage
var destroy_enemies
var get_common_turret_cards
var get_rare_turret_cards
var get_epic_turret_cards
var upgrade_turrets
var get_coins
var get_diamonds
var get_common_hero_cards
var get_rare_hero_cards
var get_epic_hero_cards
var win_matches
enum task {
	deal_damage = 0,
	destroy_enemies = 1,   
	get_common_turret_cards = 2,  
	get_rare_turret_cards = 3,
	get_epic_turret_cards = 4,
	upgrade_turrets = 5,
	get_coins = 6,   
	get_diamonds = 7,  
	get_common_hero_cards = 8,
	get_rare_hero_cards = 9,
	get_epic_hero_cards = 10,
	win_matches = 11
}

func check_tasks_in_game_session():
	check_promotion_in_game_session()
	DataManager.data["Tasks"]["count_end_game"] = count_end_game
	DataManager.data["Tasks"]["count_end_game_company"] = count_end_game_company
	DataManager.data["Tasks"]["win_several_times"] = win_several_times
	DataManager.data["Tasks"]["win_one_hp_count"] = win_one_hp_count
	DataManager.data["Tasks"]["support_damage"] = support_damage
	DataManager.data["Tasks"]["support_win_unique_count"] = support_win_unique_count
	
	DataManager.data["Tasks"]["daily_task_update_day"] = daily_task_update_day
	DataManager.data["Tasks"]["daily_task_update_week"] = daily_task_update_week
	DataManager.data["Tasks"]["list_tasks_you"] = list_tasks_you
	DataManager.data["Tasks"]["daily_task_career_you"] = daily_task_career_you
	check_tasks_in_game_session_count()

func check_tasks_in_game_session_count():
	DataManager.data["Tasks"]["deal_damage"] = deal_damage
	DataManager.data["Tasks"]["destroy_enemies"] = destroy_enemies 
	DataManager.data["Tasks"]["get_common_turret_cards"] = get_common_turret_cards
	DataManager.data["Tasks"]["get_rare_turret_cards"] = get_rare_turret_cards
	DataManager.data["Tasks"]["get_epic_turret_cards"] = get_epic_turret_cards
	DataManager.data["Tasks"]["upgrade_turrets"] = upgrade_turrets
	DataManager.data["Tasks"]["get_coins"] = get_coins
	DataManager.data["Tasks"]["get_diamonds"] = get_diamonds
	DataManager.data["Tasks"]["get_common_hero_cards"] = get_common_hero_cards
	DataManager.data["Tasks"]["get_rare_hero_cards"] = get_rare_hero_cards
	DataManager.data["Tasks"]["get_epic_hero_cards"] = get_epic_hero_cards
	DataManager.data["Tasks"]["win_matches"] = win_matches
	
	DataManager.write_file()

func check_promotion_in_game_session():
	DataManager.promotion_progress[0] = count_end_game
	DataManager.promotion_progress[2] = count_end_game_company
	var count = 0
	var max_count = 0
	for i in range(len(win_several_times)):
		if win_several_times[i] == 1:
			count += 1
			if count > max_count:
				max_count = count
		else:
			count = 0
	DataManager.promotion_progress[3] = max_count
	DataManager.promotion_progress[4] = support_damage
	DataManager.promotion_progress[5] = support_win_unique_count
	DataManager.promotion_progress[6] = win_one_hp_count
	
func check_tasks_not_in_game_session():
	DataManager.data["Tasks"]["count_spend_money"] = count_spend_money
	check_promotion_not_in_game_session()

func update_daily_task():
	DataManager.data["Tasks"]["list_tasks_you"] = list_tasks_you

func update_task_count():
	deal_damage = 0
	destroy_enemies = 0
	get_common_turret_cards = 0 
	get_rare_turret_cards = 0
	get_epic_turret_cards = 0
	upgrade_turrets = 0
	get_coins = 0
	get_diamonds = 0
	get_common_hero_cards = 0
	get_rare_hero_cards = 0
	get_epic_hero_cards = 0
	win_matches = 0
	check_tasks_in_game_session_count()
	
func check_promotion_not_in_game_session():
	DataManager.promotion_progress[1] = count_spend_money
