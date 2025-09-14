extends Control

@onready var tile = get_node("Panel/VBoxContainer/VBoxContainer")
var index_buy

func setup(list_card, img, img_open, flag=false):
	get_node("Panel/VBoxContainer/HBoxContainer/TextureRect").texture = img
	get_node("Panel/VBoxContainer/CardOf/Button/Label").text = tr("KEY_OPEN")
	index_buy = 0
	get_node("Panel/VBoxContainer/CardOf/Button").pressed.connect(buy_box_action_show_card_one.bind(list_card, img_open, flag))

func buy_box_action_show_card_one(list_card, img_open, flag):
	if len(list_card) <= index_buy:
		if flag:
			get_tree().paused = false
			get_tree().change_scene_to_file("res://Scenes/UI/Menu.tscn")
		else:
			get_tree().reload_current_scene()
			self.queue_free()
	else:
		get_node("Panel/VBoxContainer/HBoxContainer/TextureRect").texture = img_open
		tile.get_node("HBoxContainer").visible = true
		tile.get_node("HBoxContainer2").visible = true
		tile.get_node("HBoxContainer/Turret/VBoxContainer/TextureRect/TextureRect").texture = load("res://Assets/Props/towerDefense_tile_turret_" + str(list_card[index_buy][0]) + ".png")
		tile.get_node("HBoxContainer/Turret/VBoxContainer/Label").text = tr("KEY_NAME_TURRET_" + str(list_card[index_buy][0]))
		tile.get_node("HBoxContainer2/Label2").text = str(list_card[index_buy][1])
		get_node("Panel/VBoxContainer/CardOf/Button/Label").text = tr("KEY_CONTINUE")
		index_buy += 1
