extends Control

var number_card_choose_characters_choose_item = 90
var list_button = []
var list_button_activity = []
var ind

func _ready() -> void:
	ind = 0
	list_button_activity = []
	_connect_signals()
	_setup_turrets()

func _connect_signals() -> void:
	get_node("VBoxContainer/Panel/VBoxContainer/HBoxContainer/ButArmanent").pressed.connect(open_armanent)
	get_node("VBoxContainer/Panel/VBoxContainer/HBoxContainer/ButShop").pressed.connect(open_shop)
	get_node("VBoxContainer/Panel/VBoxContainer/HBoxContainer/Close").pressed.connect(close)

func _setup_turrets() -> void:
	for i in range(len(DataManager.tower_data)):
		var data = DataManager.tower_data["Turret_" + str(i + 1) + "T1"]
		var panel = _create_turret_panel(i, data)
		get_node("VBoxContainer/Panel/VBoxContainer/Shop/ScrollContainer/HBoxContainer").add_child(panel)
		panel.setup(data, i)
		if data["have"]:
			_setup_owned_turret(i, data, panel)
		else:
			_setup_buyable_turret(panel, data, i)

func _create_turret_panel(i: int, data: Dictionary) -> Node:
	var panel = load("res://Scenes/SupportScenes/turret_max.tscn").instantiate()
	return panel
	
func _create_owned_turret_ui(i: int) -> Node:
	var have = load('res://Scenes/SupportScenes/turret_choose.tscn').instantiate()
	have.get_node("VBoxContainer/TextureRect/TextureRect").texture = load("res://Assets/Props/towerDefense_tile_turret_" + str(i + 1) + ".png")
	have.get_node("VBoxContainer/Label").text = tr("KEY_NAME_TURRET_" + str(i + 1))
	return have

func _setup_active_turret(i: int) -> void:
	var activity = load('res://Scenes/SupportScenes/turret_mini.tscn').instantiate()
	activity.get_node("VBoxContainer/TextureRect/TextureRect").texture = load("res://Assets/Props/towerDefense_tile_turret_" + str(i + 1) + ".png")
	activity.get_node("VBoxContainer/Label").text = tr("KEY_NAME_TURRET_" + str(i + 1))
	get_node("VBoxContainer/Panel/VBoxContainer/Armanent/Vbox/Panel/HBoxContainer/Title" + str(ind + 1)).add_child(activity)
	list_button.append(activity)
	list_button_activity.append(i)
	ind += 1
	
func _setup_owned_turret(i: int, data: Dictionary, panel: Node) -> void:
	panel.get_node("VBoxContainer/Button").queue_free()
	var have = _create_owned_turret_ui(i)
	get_node("VBoxContainer/Panel/VBoxContainer/Armanent/Vbox/MarginContainer/ScrollContainer/GridContainer").add_child(have)
	
	if data["activity"]:
		_setup_active_turret(i)
	else:
		_setup_inactive_turret(have, i)  # Передаем i в функцию

func _setup_inactive_turret(have: Node, turret_index: int) -> void:  # Добавляем параметр turret_index
	var style = have.get_node("VBoxContainer/Button").get_theme_stylebox("normal").duplicate()
	style.set("bg_color", Color(0.0, 0.553, 0.251))
	have.get_node("VBoxContainer/Button").add_theme_stylebox_override("normal", style)
	have.get_node("VBoxContainer/Button").pressed.connect(choose_turret.bind(turret_index))  # Используем turret_index
	
func _setup_buyable_turret(panel: Node, data: Dictionary, i: int) -> void:
	panel.get_node("VBoxContainer/Button").text = tr("KEY_BUY_FOR") + " " + str(GameConstants.PriseUnblockCard[GameConstants.DATA_TOWER[i].type].open_card)
	if GameConstants.PriseUnblockCard[GameConstants.DATA_TOWER[i].type].open_card <= DataManager.data_money:
		var style = panel.get_node("VBoxContainer/Button").get_theme_stylebox("normal").duplicate()
		style.set("bg_color", Color(0.4, 0.7, 0.0))
		panel.get_node("VBoxContainer/Button").add_theme_stylebox_override("normal", style)
		panel.get_node("VBoxContainer/Button").pressed.connect(buy_turret.bind(GameConstants.PriseUnblockCard[GameConstants.DATA_TOWER[i].type].open_card, i + 1))

func buy_turret(prise: int, num_turret: int) -> void:
	DataManager.add_data_money(-prise)
	DataManager.add_critical_damage(GameConstants.ADD_CRITICAL_DAMAGE_BUY_CARD)
	get_parent().get_node("Panel/HBoxContainer/Label").text = str(DataManager.data_money)
	get_parent().get_node("Panel/HBoxContainer/Label2").text = str(DataManager.critical_damage)
	
	var turret_key = "Turret_" + str(num_turret) + "T1"
	DataManager.tower_data[turret_key]["have"] = true
	DataManager.write_file()
	close()

func choose_turret(id: int) -> void:
	if number_card_choose_characters_choose_item != id:
		number_card_choose_characters_choose_item = id
		_play_animations()
		_setup_button_connections(id)
	else:
		_stop_animations()
		_disconnect_buttons()

func _play_animations() -> void:
	for i in range(1, 5):
		get_node("VBoxContainer/Panel/VBoxContainer/Armanent/Vbox/Panel/HBoxContainer/Title" + str(i) + "/AnimationPlayer").play("rotate")

func _stop_animations() -> void:
	for i in range(1, 5):
		get_node("VBoxContainer/Panel/VBoxContainer/Armanent/Vbox/Panel/HBoxContainer/Title" + str(i) + "/AnimationPlayer").stop()

func _setup_button_connections(id: int) -> void:
	for i in range(len(list_button)):
		list_button[i].pressed.disconnect(choose_characters_choose_item.bind(1))
		list_button[i].pressed.connect(choose_characters_choose_item.bind(i))

func _disconnect_buttons() -> void:
	for i in range(len(list_button)):
		list_button[i].pressed.disconnect(choose_characters_choose_item.bind(i))

func choose_characters_choose_item(id: int) -> void:
	_stop_animations()
	
	var old_turret = "Turret_" + str(list_button_activity[id] + 1) + "T1"
	var new_turret = "Turret_" + str(number_card_choose_characters_choose_item + 1) + "T1"
	
	DataManager.tower_data[old_turret]["activity"] = false
	DataManager.tower_data[new_turret]["activity"] = true
	
	self.queue_free()
	UiManager.menu_object = load("res://Scenes/SupportScenes/shop.tscn").instantiate()
	get_parent().get_node(".").add_child(UiManager.menu_object)
	
	DataManager.write_file()

func open_armanent() -> void:
	get_node("VBoxContainer/Panel/VBoxContainer/Armanent").visible = true
	get_node("VBoxContainer/Panel/VBoxContainer/Shop").visible = false

func open_shop() -> void:
	get_node("VBoxContainer/Panel/VBoxContainer/Armanent").visible = false
	get_node("VBoxContainer/Panel/VBoxContainer/Shop").visible = true

func close() -> void:
	get_parent().get_node("MarginContainer2").visible = true
	get_parent().get_node("Reward").visible = true
	queue_free()
