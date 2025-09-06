extends Panel

func setup(i, type):
	if type < 2:
		get_node("HBoxContainer/VBoxContainer/RichTextLabel").text = tr("KEY_TASK_" + str(int(TasksManager.list_tasks_you[i][0]) + 1)) + str(int(TasksManager.list_tasks_you[i][1]))
		get_node("HBoxContainer/VBoxContainer/HBoxContainer/TextureProgressBar/Label").text = str(int(TasksManager.list_tasks_you[i][2])) + "/" + str(int(TasksManager.list_tasks_you[i][1]))
		get_node("HBoxContainer/VBoxContainer/HBoxContainer/TextureProgressBar").max_value = TasksManager.list_tasks_you[i][1]
		get_node("HBoxContainer/VBoxContainer/HBoxContainer/TextureProgressBar").value = TasksManager.list_tasks_you[i][2]
		get_node("HBoxContainer/VBoxContainer/HBoxContainer/Button").text = str(int(TasksManager.list_tasks_you[i][3]))
		get_node("HBoxContainer/VboxIcon/NinePatchRect").texture = GameConstants.TASKS_INFO[int(TasksManager.list_tasks_you[i][0])][0]
		if type == 1:
			get_node("HBoxContainer/VBoxContainer/HBoxContainer/Button").icon = load("res://Assets/Icons/token.png")
		else:
			get_node("HBoxContainer/VBoxContainer/HBoxContainer/Button").icon = load("res://Assets/Button/money.png")
		if int(TasksManager.list_tasks_you[i][2]) >= int(TasksManager.list_tasks_you[i][1]):
			get_node("HBoxContainer/VBoxContainer/HBoxContainer/Button").pressed.connect(write_done_tasks.bind(i, type))
	else:
		if len(TasksManager.daily_task_career[i]) == 4:
			get_node("HBoxContainer/VBoxContainer/HBoxContainer/Button").text = str(int(TasksManager.daily_task_career[i][3]))
			get_node("HBoxContainer/VBoxContainer/HBoxContainer/Button").icon = load("res://Assets/Button/money.png")
		if int(TasksManager.daily_task_career_you[i][2]) >= int(TasksManager.daily_task_career[i][2]):
			get_node("HBoxContainer/VBoxContainer/HBoxContainer/Button").pressed.connect(write_done_tasks.bind(i, type))
		get_node("HBoxContainer/VBoxContainer/RichTextLabel").text = tr("KEY_TASK_" + str(int(TasksManager.daily_task_career[i][1]) + 1)) + str(int(TasksManager.daily_task_career[i][2]))
		get_node("HBoxContainer/VBoxContainer/HBoxContainer/TextureProgressBar/Label").text = str(int(TasksManager.daily_task_career_you[i][2])) + "/" + str(int(TasksManager.daily_task_career[i][2]))
		get_node("HBoxContainer/VBoxContainer/HBoxContainer/TextureProgressBar").max_value = TasksManager.daily_task_career[i][2]
		get_node("HBoxContainer/VBoxContainer/HBoxContainer/TextureProgressBar").value = TasksManager.daily_task_career_you[i][2]
		get_node("HBoxContainer/VboxIcon/NinePatchRect").texture = GameConstants.TASKS_INFO[int(TasksManager.daily_task_career[i][1])][0]

func write_done_tasks(task, type):
	if type < 2:
		TasksManager.list_tasks_you[task][4] = 1
		DataManager.TYPE_ITEMS[int(TasksManager.list_tasks_you[task][0])][0].call(int(TasksManager.list_tasks_you[task][3]))
	else:
		TasksManager.daily_task_career_you[task][3] = 1
		DataManager.TYPE_ITEMS[int(TasksManager.daily_task_career[task][1])][0].call(int(TasksManager.daily_task_career[task][3]))
	DataManager.write_file()
	get_tree().get_root().get_node("Menu/Panel/HBoxContainer/Label").text = str(DataManager.data_money)
	UiManager.menu_object = load("res://Scenes/SupportScenes/daily_tasks.tscn").instantiate()
	get_node(".").add_child(UiManager.menu_object)
	self.queue_free()
