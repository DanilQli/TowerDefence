extends Panel

func _ready() -> void:
	var hb
	get_node("VBoxContainer/TextureRect/Panel/HBoxContainer/VBoxContainer/ProgressBar").max_value = GameConstants.NUMBER_EXPERIENCE_GLORY[DataManager.glory_level]
	get_node("VBoxContainer/TextureRect/Panel/HBoxContainer/VBoxContainer/ProgressBar").value = DataManager.glory_progress
	var value = DataManager.glory_progress / (GameConstants.NUMBER_EXPERIENCE_GLORY[DataManager.glory_level] / 100.0)
	get_node("VBoxContainer/TextureRect/Panel/HBoxContainer/VBoxContainer/ProgressBar/Label").text = str(DataManager.glory_progress) + "/" + str(GameConstants.NUMBER_EXPERIENCE_GLORY[DataManager.glory_level])
	get_node("VBoxContainer/TextureRect/Panel/HBoxContainer/Romb/Label").text = str(DataManager.glory_level)
	var keys
	for i in range(len(GameConstants.NUMBER_EXPERIENCE_GLORY) - 1, -1, -1):
		keys = GameConstants.ID_GIFT_GLORY[i].keys()
		hb = preload("res://Scenes/SupportScenes/container_reward.tscn").instantiate()
		hb.get_node("Control/Romb/Label").text = str(i)
		hb.get_node("Panel2/Button/Panel/TextureRect").texture = DataManager.TYPE_ITEMS[keys[0]][2]
		hb.get_node("Panel1/Button/Panel/TextureRect").texture = DataManager.TYPE_ITEMS[keys[1]][2]
		if not keys[1] in [2, 3, 4, 5, 6, 7, 8, 9]:
			hb.get_node("Panel1/Button/Panel/Label").text = str(GameConstants.ID_GIFT_GLORY[i][keys[1]])
		if not keys[0] in [2, 3, 4, 5, 6, 7, 8, 9]:
			hb.get_node("Panel2/Button/Panel/Label").text = str(GameConstants.ID_GIFT_GLORY[i][keys[0]])
		if i > DataManager.glory_level + 1:
			hb.get_node("Control/ProgressBar").value = 0
		elif i > DataManager.glory_level and value > 50:
			hb.get_node("Control/ProgressBar").value = value - 50
		elif i == DataManager.glory_level:
			hb.get_node("Control/ProgressBar").value = value + 50
			if DataManager.glory_vip:
				hb.get_node("Panel1/Button/Panel/Lock").visible = false
				if not DataManager.glory_rewards_level_get[i][1]:
					hb.get_node("Panel1/Button").pressed.connect(open_rewards_glory.bind(keys, i, 1))
					hb.get_node("Panel1/Button/Panel/ColorRect").visible = true
			hb.get_node("Panel2/Button/Panel/Lock").visible = false
			if not DataManager.glory_rewards_level_get[i][0]:
				hb.get_node("Panel2/Button").pressed.connect(open_rewards_glory.bind(keys, i, 0))
				hb.get_node("Panel2/Button/Panel/ColorRect").visible = true
		else:
			hb.get_node("Control/ProgressBar").value = 100
			if DataManager.glory_vip:
				hb.get_node("Panel1/Button/Panel/Lock").visible = false
				if not DataManager.glory_rewards_level_get[i][1]:
					hb.get_node("Panel1/Button").pressed.connect(open_rewards_glory.bind(keys, i, 1))
					hb.get_node("Panel1/Button/Panel/ColorRect").visible = true
			hb.get_node("Panel2/Button/Panel/Lock").visible = false
			if not DataManager.glory_rewards_level_get[i][0]:
				hb.get_node("Panel2/Button").pressed.connect(open_rewards_glory.bind(keys, i, 0))
				hb.get_node("Panel2/Button/Panel/ColorRect").visible = true
		get_node("VBoxContainer/ScrollContainer/VBoxContainer").add_child(hb)

func open_rewards_glory(keysa, index, vip_index):
	var keys = keysa[vip_index]
	DataManager.glory_rewards_level_get[index][vip_index] = 1
	DataManager.data["PathOfGlory"]["rewards_level_get"] = DataManager.glory_rewards_level_get
	var box_card = false
	if keys in [2, 3, 4, 5, 6, 7, 8, 9]:
		box_card = true
		box_card = GameConstants.get_random_card_pairs(GameConstants.ID_GIFT_GLORY[index][keys])
		DataManager.TYPE_ITEMS[keys][0].call(box_card)
	else:
		DataManager.TYPE_ITEMS[keys][0].call(GameConstants.ID_GIFT_GLORY[index][keys])
	DataManager.write_file()
	if box_card:
		var choose_buy = load("res://Scenes/SupportScenes/buy_box_open.tscn").instantiate()
		choose_buy.setup(box_card, DataManager.TYPE_ITEMS[keys][2], DataManager.TYPE_ITEMS[keys][4])
		get_tree().current_scene.add_child(choose_buy)
	else:
		get_tree().reload_current_scene()
	pass
