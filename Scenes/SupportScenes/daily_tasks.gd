extends Control

var list_card_you
var date = Time.get_datetime_string_from_system()
var rng = RandomNumberGenerator.new()
var curent_stage = 100
var stage_preview = 100
var choose_buy
var index_buy

# Called when the node enters the scene tree for the first time.
func _ready():
	get_node("Panel/MarginContainer/VBoxContainer/HBoxButton/Daily").pressed.connect(visible_tasks.bind("1"))
	get_node("Panel/MarginContainer/VBoxContainer/HBoxButton/Weekly").pressed.connect(visible_tasks.bind("2"))
	get_node("Panel/MarginContainer/VBoxContainer/HBoxButton/Career").pressed.connect(visible_tasks.bind("3"))
	get_node("Panel/MarginContainer/VBoxContainer/ControlAll/Control3/VBoxContainer/HBoxContainer/Back").pressed.connect(func_stage_preview.bind(-1))
	get_node("Panel/MarginContainer/VBoxContainer/ControlAll/Control3/VBoxContainer/HBoxContainer/Forward").pressed.connect(func_stage_preview.bind(1))
	get_node("Panel/MarginContainer/VBoxContainer/ControlAll/Control1/VBoxContainer/HBoxContainer/Button").pressed.connect(info_tasks)
	get_node("Panel/MarginContainer/VBoxContainer/ControlAll/Control2/VBoxContainer/HBoxContainer/Button").pressed.connect(info_tasks)
	get_node("Panel/Close").pressed.connect(close_menu)
	check_daily_tasks()
	check_weekly_tasks()
	check_career_tasks()

func close_menu():
	get_parent().get_node("MarginContainer2").visible = true
	get_parent().get_node("Reward").visible = true
	queue_free()
	
func visible_tasks(index):
	for child in get_node("Panel/MarginContainer/VBoxContainer/ControlAll").get_children():
		child.visible = false
	get_node("Panel/MarginContainer/VBoxContainer/ControlAll/Control" + index).visible = true

func check_daily_tasks():
	var days = int(Time.get_unix_time_from_system() / 86400)  # 86400 секунд в дне
	var LIST_RANDOM_TASKS = [[0, 1], [2, 4], [5, 7], [8, 11]]
	if days > TasksManager.daily_task_update_day + 1:
		TasksManager.daily_task_update_day = days
		TasksManager.check_tasks_in_game_session()
		var id_tasks
		for i in range(len(LIST_RANDOM_TASKS)):
			rng.randomize()
			id_tasks = rng.randi_range(LIST_RANDOM_TASKS[i][0], LIST_RANDOM_TASKS[i][1])
			TasksManager.list_tasks_you[i][0] = id_tasks
			rng.randomize()
			TasksManager.list_tasks_you[i][1] = rng.randi_range(GameConstants.TASKS_INFO[id_tasks][1], GameConstants.TASKS_INFO[id_tasks][2])
			TasksManager.list_tasks_you[i][2] = 0
			TasksManager.list_tasks_you[i][3] = int( (int(TasksManager.list_tasks_you[i][1]) / float(GameConstants.TASKS_INFO[id_tasks][1])) * randi_range(int(GameConstants.TASKS_INFO[id_tasks][4] * 0.9), int(GameConstants.TASKS_INFO[id_tasks][4] * 1.1)))
			TasksManager.list_tasks_you[i][4] = 0
	else:
		for i in range(len(LIST_RANDOM_TASKS)):
			TasksManager.list_tasks_you[i][2] += TasksManager.get(TasksManager.task.find_key(int(TasksManager.list_tasks_you[i][0])))
	TasksManager.update_daily_task()
	var node
	for i in range(4):
		if TasksManager.list_tasks_you[i][4] == 0:
			node = load("res://Scenes/SupportScenes/tasks_panel_daily.tscn").instantiate()
			node.setup(i, 0)
			get_node("Panel/MarginContainer/VBoxContainer/ControlAll/Control1/VBoxContainer/ScrollContainer/VBoxContainer").add_child(node)
	get_node("Panel/MarginContainer/VBoxContainer/ControlAll/Control1/VBoxContainer/HBoxContainer/Time").text = str(23 - int(date.substr(11, 2))) + "h " + str(60 - int(date.substr(14, 2))) + "m"

func check_weekly_tasks():
	var days = str(int(Time.get_unix_time_from_system() / 86400))  # 86400 секунд в дне
	var LIST_RANDOM_TASKS = [[0, 1], [2, 3], [4, 5], [6, 7], [8, 9], [9, 10], [10, 11]]
	if int(days) > int(TasksManager.daily_task_update_week) + 7:
		TasksManager.daily_task_update_week = days
		TasksManager.check_tasks_in_game_session()
		var id_tasks
		var list_number_do
		for i in range(len(LIST_RANDOM_TASKS)):
			rng.randomize()
			id_tasks = rng.randi_range(LIST_RANDOM_TASKS[i][0], LIST_RANDOM_TASKS[i][1])
			TasksManager.list_tasks_you[i + 4][0] = id_tasks
			rng.randomize()
			TasksManager.list_tasks_you[i + 4][1] = rng.randi_range(GameConstants.TASKS_INFO[id_tasks][1], GameConstants.TASKS_INFO[id_tasks][2])
			TasksManager.list_tasks_you[i + 4][2] = 0
			TasksManager.list_tasks_you[i + 4][3] = int( (int(TasksManager.list_tasks_you[i + 3][1]) / float(GameConstants.TASKS_INFO[id_tasks][1])) * randi_range(int(GameConstants.TASKS_INFO[id_tasks][4] * 0.9), int(GameConstants.TASKS_INFO[id_tasks][4] * 1.1)))
			TasksManager.list_tasks_you[i + 4][4] = 0
	else:
		for i in range(len(LIST_RANDOM_TASKS)):
			TasksManager.list_tasks_you[i + 4][2] += TasksManager.get(TasksManager.task.find_key(int(TasksManager.list_tasks_you[i + 4][0])))
	TasksManager.update_daily_task()
	var node
	for i in range(0, 7):
		if TasksManager.list_tasks_you[i + 4][4] == 0:
			node = load("res://Scenes/SupportScenes/tasks_panel_daily.tscn").instantiate()
			node.setup(i + 4, 1)
			get_node("Panel/MarginContainer/VBoxContainer/ControlAll/Control2/VBoxContainer/ScrollContainer/VBoxContainer").add_child(node)
	get_node("Panel/MarginContainer/VBoxContainer/ControlAll/Control2/VBoxContainer/HBoxContainer/Time").text = str(6 - ((int(days) - TasksManager.daily_task_update_week))) + "d " + str(24 - int(date.substr(11, 2))) + "h"

func check_career_tasks():
	var list_tasks_id
	var node
	var number_tasks = [0, 0]
	for i in range(0, len(TasksManager.daily_task_career_you)):
		if TasksManager.daily_task_career_you[i][3] == 0:
			curent_stage = TasksManager.daily_task_career_you[i][0]
			stage_preview = curent_stage
			break
	for i in range(len(TasksManager.daily_task_career)):
		TasksManager.daily_task_career_you[i][2] += TasksManager.get(TasksManager.task.find_key(int(TasksManager.daily_task_career[i][1])))
	
	TasksManager.update_task_count()
	
	for i in range(0, len(TasksManager.daily_task_career)):
		if TasksManager.daily_task_career[i][0] == curent_stage:
			if TasksManager.daily_task_career_you[i][3] == 0:
				number_tasks[1] += 1
				node = load("res://Scenes/SupportScenes/tasks_panel_daily.tscn").instantiate()
				node.setup(i, 2)
				get_node("Panel/MarginContainer/VBoxContainer/ControlAll/Control3/VBoxContainer/ScrollContainer/VBoxContainer").add_child(node)
			else:
				number_tasks[0] += 1
				number_tasks[1] += 1
	get_node("Panel/MarginContainer/VBoxContainer/ControlAll/Control3/VBoxContainer/HBoxContainer/Panel/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/NumberStage").text = str(int(curent_stage))
	get_node("Panel/MarginContainer/VBoxContainer/ControlAll/Control3/VBoxContainer/HBoxContainer/Panel/VBoxContainer/HBoxContainer2/TextureProgressBar/Label").text = str(number_tasks[0]) + "/" + str(number_tasks[1])
	get_node("Panel/MarginContainer/VBoxContainer/ControlAll/Control3/VBoxContainer/HBoxContainer/Panel/VBoxContainer/HBoxContainer2/TextureProgressBar").max_value = number_tasks[1]
	get_node("Panel/MarginContainer/VBoxContainer/ControlAll/Control3/VBoxContainer/HBoxContainer/Panel/VBoxContainer/HBoxContainer2/TextureProgressBar").value = number_tasks[0]
	for i in range(1, len(TasksManager.daily_task_career_you)):
		if TasksManager.daily_task_career_you[i][0] == curent_stage:
			get_node("Panel/MarginContainer/VBoxContainer/ControlAll/Control3/VBoxContainer/HBoxContainer/Panel/VBoxContainer/HBoxContainer/NinePatchRect").texture = load("res://Assets/Icons/box_" + str(TasksManager.daily_task_career[i][3]) + ".png")
			break
			
func func_stage_preview(direction):
	"""Отобразить следующий этап
	:direction: напрвление"""
	stage_preview += direction
	if stage_preview < 1:
		stage_preview = TasksManager.daily_task_career[len(TasksManager.daily_task_career) - 1][0]
	elif stage_preview > TasksManager.daily_task_career[len(TasksManager.daily_task_career) - 1][0]:
		stage_preview = 1
	get_node("Panel/MarginContainer/VBoxContainer/ControlAll/Control3/VBoxContainer/HBoxContainer/Panel/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/NumberStage").text = str(int(stage_preview))
	get_node("Panel/MarginContainer/VBoxContainer/ControlAll/Control3/VBoxContainer/HBoxContainer/Panel/VBoxContainer/HBoxContainer2/TextureProgressBar/Label").text = ""
	get_node("Panel/MarginContainer/VBoxContainer/ControlAll/Control3/VBoxContainer/HBoxContainer/Panel/VBoxContainer/HBoxContainer2/TextureProgressBar").max_value = 1
	get_node("Panel/MarginContainer/VBoxContainer/ControlAll/Control3/VBoxContainer/HBoxContainer/Panel/VBoxContainer/HBoxContainer2/TextureProgressBar").value = 0
	for i in range(0, len(TasksManager.daily_task_career_you)):
		if TasksManager.daily_task_career_you[i][0] == stage_preview and TasksManager.daily_task_career_you[i][1] == GameConstants.NUMBER_TASKS_IN_CAREER:
			get_node("Panel/MarginContainer/VBoxContainer/ControlAll/Control3/VBoxContainer/HBoxContainer/Panel/VBoxContainer/HBoxContainer/NinePatchRect").texture = load("res://Assets/Icons/box_" + str(TasksManager.daily_task_career[i][3]) + ".png")
			if int(TasksManager.daily_task_career_you[i][4]) == 1:
				get_node("Panel/MarginContainer/VBoxContainer/ControlAll/Control3/VBoxContainer/HBoxContainer/Panel/VBoxContainer/HBoxContainer/NinePatchRect/Button").pressed.connect(box_open.bind(i))
			elif int(TasksManager.daily_task_career_you[i][3]) == 1:
				get_node("Panel/MarginContainer/VBoxContainer/ControlAll/Control3/VBoxContainer/HBoxContainer/Panel/VBoxContainer/HBoxContainer/NinePatchRect/Button2").visible = true
			break
	for child in get_node("Panel/MarginContainer/VBoxContainer/ControlAll/Control3/VBoxContainer/ScrollContainer/VBoxContainer").get_children():
		child.queue_free()
	if stage_preview == curent_stage:
		check_career_tasks()

func info_tasks():
	var info = load("res://Scenes/SupportScenes/info_buy_card.tscn").instantiate()
	info.get_node("Panel/VBoxContainer/HBoxContainer/Panel/RichTextLabel").text = tr("KEY_TASKS_INFO")
	add_child(info)
	info.get_node("Panel/Close").pressed.connect(close.bind(info))
	info.get_node("Panel/VBoxContainer/CardOf/Button").pressed.connect(close.bind(info))

func box_open(ind):
	var box_card = GameConstants.get_random_card_pairs(TasksManager.daily_task_career[ind][4])
	DataManager.TYPE_ITEMS[3][0].call(box_card)
	DataManager.write_file()
	if box_card:
		var choose_buy = load("res://Scenes/SupportScenes/buy_box_open.tscn").instantiate()
		choose_buy.setup(box_card, DataManager.TYPE_ITEMS[3][2], DataManager.TYPE_ITEMS[3][4])
		get_tree().current_scene.add_child(choose_buy)

func close(obj):
	obj.queue_free()
