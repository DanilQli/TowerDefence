## GameEndController
extends Node

var main_scene
var stars_earned := 0
var end

func initialize(scene):
	main_scene = scene

func end_game_company():
	TasksManager.count_end_game_company += 1
	tasks()
	get_tree().paused = true

	end = load("res://Scenes/SupportScenes/end_game_company.tscn").instantiate()
	var money_dop = 0

	var panel_root = "Panel/MarginContainer/VBoxContainer"
	var score = GameSession.current_game_score
	var health = GameSession.base_health

	if health >= 9:
		stars_earned = 3
		end.get_node(panel_root + "/Label").text = tr("KEY_WIN")
		if not DataManager.level_option[GameSession.current_level - 1]:
			money_dop = int(int(score / 10) / 3.0)
			end.get_node(panel_root + "/HBoxStar/Label2").text = str(money_dop)
	elif health > 7:
		stars_earned = 2
		end.get_node(panel_root + "/Label").text = tr("KEY_WIN")
		end.get_node(panel_root + "/HBoxContainer2/NinePatchRect3").queue_free()
		if not DataManager.level_option[GameSession.current_level - 1]:
			money_dop = int(int(score / 10) / 3.1)
			end.get_node(panel_root + "/HBoxStar/Label2").text = str(money_dop)
	elif health > 5:
		stars_earned = 1
		end.get_node(panel_root + "/Label").text = tr("KEY_WIN")
		end.get_node(panel_root + "/HBoxContainer2/NinePatchRect2").queue_free()
		end.get_node(panel_root + "/HBoxContainer2/NinePatchRect3").queue_free()
		if not DataManager.level_option[GameSession.current_level - 1]:
			money_dop = int(int(score / 10) / 3.2)
			end.get_node(panel_root + "/HBoxStar/Label2").text = str(money_dop)
	else:
		stars_earned = 0
		end.get_node(panel_root + "/HBoxContainer2/NinePatchRect1").queue_free()
		end.get_node(panel_root + "/HBoxContainer2/NinePatchRect2").queue_free()
		end.get_node(panel_root + "/HBoxContainer2/NinePatchRect3").queue_free()
		if DataManager.level_option[GameSession.current_level - 1]:
			money_dop = int(int(score / 10) / 4.0)
			end.get_node(panel_root + "/HBoxStar/Label2").text = str(money_dop)

	end.get_node(panel_root + "/HBoxScore/Label2").text = str(score)
	end.get_node(panel_root + "/HBoxCoin/Label2").text = str(int(score / 10))
	end.get_node(panel_root + "/HBoxScoreBest/Label2").text = str(ResourceManager.best_score)

	end.get_node(panel_root + "/HBoxContainer/TextureButton_1").pressed.connect(restart)
	end.get_node(panel_root + "/HBoxContainer/TextureButton_2").pressed.connect(exit_menu)

	main_scene.get_node("UI").add_child(end)

	if score > ResourceManager.best_score:
		ResourceManager.best_score = score
		DataManager.data["settings_game"]["best_score"] = score

		var total_money = int(score / 10) + money_dop
		DataManager.add_data_money(total_money)
		DataManager.data["Resources"]["money"] = DataManager.data_money

		if not DataManager.level_option[GameSession.current_level - 1]:
			DataManager.level_option[GameSession.current_level - 1] = true
			DataManager.data["level_option"]["level"] = DataManager.level_option

		DataManager.write_file()

	GameSession.current_game_score = 0

func end_game():
	tasks()
	get_tree().paused = true
	end = load("res://Scenes/SupportScenes/EndGame.tscn").instantiate()

	var score = GameSession.current_game_score
	if score > ResourceManager.best_score:
		ResourceManager.best_score = score
		DataManager.data["SettingsGame"]["best_score"] = score
		DataManager.add_data_money(int(score / 10))
		DataManager.data["Resources"]["money"] = DataManager.data_money
		DataManager.write_file()
	stars_earned = randi_range(0, 3)
	end.get_node("Panel/MarginContainer/VBoxContainer/HBoxScore/Label2").text = str(score)
	end.get_node("Panel/MarginContainer/VBoxContainer/HBoxCoin/Label2").text = str(int(score / 10))
	end.get_node("Panel/MarginContainer/VBoxContainer/HBoxScoreBest/Label2").text = str(ResourceManager.best_score)

	end.get_node("Panel/MarginContainer/VBoxContainer/HBoxContainer/TextureButton_1").pressed.connect(restart)
	end.get_node("Panel/MarginContainer/VBoxContainer/HBoxContainer/TextureButton_2").pressed.connect(exit_menu)

	main_scene.get_node("UI").add_child(end)

	GameSession.current_game_score = 0

func tasks():
	TasksManager.win_several_times.pop_at(0)
	if GameSession.base_health == 1:
		TasksManager.win_one_hp_count += 1
		TasksManager.win_several_times.append(1)
	elif GameSession.base_health == 0:
		TasksManager.win_several_times.append(0)
	else:
		TasksManager.win_matches += 1
		TasksManager.win_several_times.append(1)
	TasksManager.count_end_game += 1
	DataManager.write_mastery()
	TasksManager.check_tasks_in_game_session()
	
func restart():
	GameSession.current_wave = 0
	GameSession.current_money_in_game_session = GameConstants.MONEY_BEGIN[GameSession.current_level]
	UiManager.list_open_menu_turrets = []
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/UI/GameScene.tscn")

func exit_menu():
	open_chest_pressed()

func open_chest_pressed():
	end.queue_free()
	# Генерируем карточки на основе звёзд
	var card_counts = GameConstants.POST_BATTLE_REWARDS.get(stars_earned)
	var box_card = GameConstants.get_random_card_pairs(card_counts)
	var i = 0
	while i < box_card.size():
		if box_card[i][1] == 0:
			box_card.remove_at(i)
		else:
			i += 1
	# ID предмета "Боевой сундук"
	var chest_item_id = GameConstants.BATTLE_CHEST_ITEM_ID
	
	# Добавляем карты в инвентарь игрока
	DataManager.TYPE_ITEMS[chest_item_id][0].call(box_card)
	DataManager.write_file()
	var choose_buy = load("res://Scenes/SupportScenes/buy_box_open.tscn").instantiate()
	choose_buy.setup(box_card, DataManager.TYPE_ITEMS[chest_item_id][2], DataManager.TYPE_ITEMS[chest_item_id][4], true)
	get_tree().current_scene.get_node("UI").add_child(choose_buy)
