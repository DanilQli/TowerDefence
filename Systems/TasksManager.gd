extends Node

var count_end_game: int #1
var count_spend_money: int #2
var count_end_game_company: int #3
var win_several_times: Array #4
var support_damage: int #5
var support_win_unique_count: int #6
var win_one_hp_count: int #7

func check_tasks_in_game_session():
	check_promotion_in_game_session()
	DataManager.data["Tasks"]["count_end_game"] = count_end_game
	DataManager.data["Tasks"]["count_end_game_company"] = count_end_game_company
	DataManager.data["Tasks"]["win_several_times"] = win_several_times
	DataManager.data["Tasks"]["win_one_hp_count"] = win_one_hp_count
	DataManager.data["Tasks"]["support_damage"] = support_damage
	DataManager.data["Tasks"]["support_win_unique_count"] = support_win_unique_count
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
	
func check_promotion_not_in_game_session():
	DataManager.promotion_progress[1] = count_spend_money
