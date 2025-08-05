extends Control

var parrent_obj

func _ready() -> void:
	get_node("VBoxContainer/Panel/Close").pressed.connect(close)
	get_node("VBoxContainer/Panel/VBoxContainer/Control/HBoxContainer/NinePatchRect/Label").text = str(DataManager.promotion_level + 1) 
	get_node("VBoxContainer/Panel/VBoxContainer/Control/HBoxContainer/VBoxContainer/TextureProgressBar").max_value = GameConstants.NEED_PROMOTION_STAR_LEVEL[DataManager.promotion_level]
	get_node("VBoxContainer/Panel/VBoxContainer/Control/HBoxContainer/VBoxContainer/TextureProgressBar").value = DataManager.promotion_stars
	var level_element
	var panel_rewards
	var flag = false
	var list_keys = GameConstants.PROMOTION_LEVEL.keys()
	for key in list_keys:
		level_element = load("res://Scenes/SupportScenes/level_element.tscn").instantiate()
		level_element.get_node("VBoxContainer/Label").text = str(key)
		if DataManager.promotion_level + 1 >= key:
			level_element.get_node("VBoxContainer/HSeparator/NinePatchRect").queue_free()
			level_element.get_node("ColorRect").visible = false
			if DataManager.promotion_open_level < key:
				level_element.get_node("ColorRect2").visible = true
				if not flag:
					flag = true
					level_element.pressed.connect(open_promotion_level.bind(key, list_keys))
		for j in range(len(GameConstants.PROMOTION_LEVEL[key])):
			panel_rewards = load(DataManager.TYPE_ITEMS[GameConstants.PROMOTION_LEVEL[key][j][0]][3]).instantiate()
			panel_rewards.get_node("NinePatchRect").texture = DataManager.TYPE_ITEMS[GameConstants.PROMOTION_LEVEL[key][j][0]][2]
			panel_rewards.tooltip_text = tr(DataManager.TYPE_ITEMS[GameConstants.PROMOTION_LEVEL[key][j][0]][1])
			if GameConstants.PROMOTION_LEVEL[key][j][0] == 2:
				panel_rewards.get_node("Label").text = "1"
			else:
				panel_rewards.get_node("Label").text = str(GameConstants.PROMOTION_LEVEL[key][j][1])
			level_element.get_node("VBoxContainer/HBoxContainer2/VBoxContainer").add_child(panel_rewards)
		get_node("VBoxContainer/Panel/VBoxContainer/ScrollContainer/HBoxContainer").add_child(level_element)

func setup(obj):
	parrent_obj = obj
	parrent_obj.visible = false

func close():
	parrent_obj.visible = true
	self.queue_free()
	
func open_promotion_level(i, list_keys):
	var idx = list_keys.find(i)
	if idx != -1 and idx + 1 < list_keys.size():
		DataManager.promotion_open_level = list_keys[idx + 1] - 1
	else:
		DataManager.promotion_open_level += 1
	"""Получить награды"""
	var box_card = false
	var box_img = false
	for j in range(len(GameConstants.PROMOTION_LEVEL[i])):
		if GameConstants.PROMOTION_LEVEL[i][j][0] in [2, 3, 4, 5]:
			box_card = true
			box_card = GameConstants.get_random_card_pairs(GameConstants.PROMOTION_LEVEL[i][j][1])
			box_img = GameConstants.PROMOTION_LEVEL[i][j][0]
			DataManager.TYPE_ITEMS[GameConstants.PROMOTION_LEVEL[i][j][0]][0].call(box_card)
		else:
			DataManager.TYPE_ITEMS[GameConstants.PROMOTION_LEVEL[i][j][0]][0].call(GameConstants.PROMOTION_LEVEL[i][j][1])
	DataManager.write_file()
	if box_card:
		var choose_buy = load("res://Scenes/SupportScenes/buy_box_open.tscn").instantiate()
		choose_buy.setup(box_card, DataManager.TYPE_ITEMS[box_img][2], DataManager.TYPE_ITEMS[box_img][4])
		get_tree().current_scene.add_child(choose_buy)
	else:
		get_tree().reload_current_scene()
	
