extends Panel

func _ready() -> void:
	var hb
	get_node("VBoxContainer/TextureRect/Panel/HBoxContainer/VBoxContainer/ProgressBar").max_value = GameConstants.NUMBER_EXPERIENCE_GLORY[DataManager.glory_level]
	get_node("VBoxContainer/TextureRect/Panel/HBoxContainer/VBoxContainer/ProgressBar").value = DataManager.glory_progress
	var value = DataManager.glory_progress / (GameConstants.NUMBER_EXPERIENCE_GLORY[DataManager.glory_level] / 100.0)
	get_node("VBoxContainer/TextureRect/Panel/HBoxContainer/VBoxContainer/ProgressBar/Label").text = str(DataManager.glory_progress) + "/" + str(GameConstants.NUMBER_EXPERIENCE_GLORY[DataManager.glory_level])
	get_node("VBoxContainer/TextureRect/Panel/HBoxContainer/Romb/Label").text = str(DataManager.glory_level)
	var keys
	for i in range(len(GameConstants.NUMBER_EXPERIENCE_GLORY) - 1, 0, -1):
		keys = GameConstants.ID_GIFT_GLORY[i].keys()
		hb = preload("res://Scenes/SupportScenes/container_reward.tscn").instantiate()
		hb.get_node("Control/Romb/Label").text = str(i)
		hb.get_node("Panel1/Button/Panel/TextureRect").texture = DataManager.TYPE_ITEMS[keys[0]][2]
		hb.get_node("Panel2/Button/Panel/TextureRect").texture = DataManager.TYPE_ITEMS[keys[1]][2]
		if i > DataManager.glory_level + 1:
			hb.get_node("Control/ProgressBar").value = 0
		elif i > DataManager.glory_level and value > 50:
			hb.get_node("Control/ProgressBar").value = value - 50
		elif i == DataManager.glory_level:
			hb.get_node("Control/ProgressBar").value = value + 50
			if DataManager.glory_vip:
				hb.get_node("Panel2/Button/Panel/Lock").visible = false
				if not DataManager.glory_rewards_level_get[i][0]:
					hb.get_node("Panel2/Button").pressed.connect(open_rewards_glory.bind(i, 1))
					hb.get_node("Panel2/Button/Panel/ColorRect").visible = true
			hb.get_node("Panel1/Button/Panel/Lock").visible = false
			if not DataManager.glory_rewards_level_get[i][1]:
				hb.get_node("Panel1/Button").pressed.connect(open_rewards_glory.bind(i, 0))
				hb.get_node("Panel1/Button/Panel/ColorRect").visible = true
		else:
			hb.get_node("Control/ProgressBar").value = 100
			if DataManager.glory_vip:
				hb.get_node("Panel2/Button/Panel/Lock").visible = false
				if not DataManager.glory_rewards_level_get[i][0]:
					hb.get_node("Panel2/Button").pressed.connect(open_rewards_glory.bind(i, 1))
					hb.get_node("Panel2/Button/Panel/ColorRect").visible = true
			hb.get_node("Panel1/Button/Panel/Lock").visible = false
			if not DataManager.glory_rewards_level_get[i][1]:
				hb.get_node("Panel2/Button").pressed.connect(open_rewards_glory.bind(i, 0))
				hb.get_node("Panel1/Button/Panel/ColorRect").visible = true
		get_node("VBoxContainer/ScrollContainer/VBoxContainer").add_child(hb)

func open_rewards_glory(index, vip_index):
	print(index, vip_index)
	pass
