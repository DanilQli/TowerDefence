extends ColorRect

var level: int
@onready var turretMaxIcon = $Panel/MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/TextureRect/TextureRect
@onready var turretMaxName = $Panel/MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/Label
@onready var turretMaxLvl = $Panel/MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/Lvl
@onready var turretMaxLox = $Panel/MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/CardOf/Lock
@onready var CardOf = $Panel/MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/CardOf/CardOf
@onready var CardOfCardOf = $Panel/MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/CardOf
@onready var CardOfText = $Panel/MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/CardOf/CardOf/Label
@onready var CardOfDesc = $Panel/MarginContainer/ScrollContainer/VBoxContainer/RichTextLabel
@onready var PanelParametr = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Parametr/ScrollContainer/HBoxContainer
@onready var openLvlBut = $Panel/MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/Button
@onready var abilityText = [$Panel/MarginContainer/ScrollContainer/VBoxContainer/Control1/RichTextLabel, $Panel/MarginContainer/ScrollContainer/VBoxContainer/Control2/RichTextLabel]
@onready var abilityTextLock = [$Panel/MarginContainer/ScrollContainer/VBoxContainer/Control1/Lock/VBoxContainer/Label, $Panel/MarginContainer/ScrollContainer/VBoxContainer/Control2/Lock/VBoxContainer/Label]
@onready var abilityLockAll = [$Panel/MarginContainer/ScrollContainer/VBoxContainer/Control1/Lock, $Panel/MarginContainer/ScrollContainer/VBoxContainer/Control2/Lock]
@onready var abilityBut = [$Panel/MarginContainer/ScrollContainer/VBoxContainer/Control1/Lock/VBoxContainer/HBoxContainer2/Button, $Panel/MarginContainer/ScrollContainer/VBoxContainer/Control2/Lock/VBoxContainer/HBoxContainer2/Button]
@onready var close = $Panel/Close
var prise: int

func setup(data: Dictionary, number: int) -> void:
	turretMaxIcon.texture = load("res://Assets/Props/towerDefense_tile_turret_" + str(number + 1) + ".png")
	turretMaxName.text = tr("KEY_NAME_TURRET_" + str(number + 1))
	level = int(data["level"])
	CardOfDesc.text = tr("KEY_TURRET" + str(number + 1) + "_DESC")
	if not data["have"]:
		turretMaxLvl.text = tr("KEY_NOT_FOUND")
		prise = GameConstants.PriseUnblockCard[GameConstants.DATA_TOWER[number].type].open_card
		openLvlBut.text = tr("KEY_UNBLOCK_FOR") + str(prise)
	else:
		turretMaxLvl.text = tr("KEY_LVL") + str(level + 1)
		if level < GameConstants.NUMBER_LVL_TURRET_CARD:
			prise = GameConstants.PriseUnblockCard[GameConstants.DATA_TOWER[number].type].prise_up_money[level + 1]
			CardOf.max_value = TowerCards.get_cards_needed(number)
		else:
			prise = 1000
			CardOfCardOf.queue_free()
			openLvlBut.queue_free()
		openLvlBut.text = tr("KEY_UP") + str(prise)
		turretMaxLox.queue_free()
		CardOf.value = int(data["cards"])
		CardOfText.text = str(int(data["cards"])) + "/" + str(int(CardOf.max_value))
	close.pressed.connect(_close)
	_create_card_of_parametr(data, number)
	if level < GameConstants.NUMBER_LVL_TURRET_CARD and prise <= DataManager.data_money and (CardOf.max_value <= CardOf.value or not data["have"]):
		if not data["have"]:
			openLvlBut.pressed.connect(buy.bind(prise, number))
		else:
			if level >= GameConstants.NUMBER_LVL_TURRET_CARD:
				openLvlBut.queue_free()
			else:
				openLvlBut.pressed.connect(upgrade_card.bind(number))
		var style = openLvlBut.get_theme_stylebox("normal").duplicate()
		style.set("bg_color", Color(0.4, 0.7, 0.0))
		openLvlBut.add_theme_stylebox_override("normal", style)
	for i in range(len(GameConstants.LEVEL_OPEN_ABILITY)):
		abilityText[i].text = tr("KEY_TURRET" + str(number + 1) + "_UP" + str(i) + "_DESC")
		abilityBut[i].text = tr("KEY_UNBLOCK_FOR") + str(GameConstants.PriseUnblockCard[GameConstants.DATA_TOWER[number].type].abilit_prise[i])
		abilityTextLock[i].text = tr("KEY_AVAILABLE_ON1") + " " + str(GameConstants.LEVEL_OPEN_ABILITY[i]) + " " + tr("KEY_AVAILABLE_ON2")
		if not data["ability"][i] and level + 1 >= GameConstants.LEVEL_OPEN_ABILITY[i] and GameConstants.PriseUnblockCard[GameConstants.DATA_TOWER[number].type].abilit_prise[i] <= DataManager.data_money:
			var style = abilityBut[i].get_theme_stylebox("normal").duplicate()
			style.set("bg_color", Color(0.4, 0.7, 0.0))
			abilityBut[i].add_theme_stylebox_override("normal", style)
			abilityBut[i].pressed.connect(open_ability.bind(i, number))
		elif data["ability"][i]:
			abilityLockAll[i].queue_free()

func buy(prise, number):
	DataManager.data_money_spend(prise)
	DataManager.add_critical_damage(GameConstants.ADD_CRITICAL_DAMAGE_BUY_CARD)
	get_tree().get_root().get_node("Menu/Panel/HBoxContainer/Label").text = str(DataManager.data_money)
	get_tree().get_root().get_node("Menu/Panel/HBoxContainer/Label2").text = str(DataManager.critical_damage)
	var turret_key = "Turret_" + str(number + 1) + "T1"
	DataManager.tower_data[turret_key]["have"] = true
	DataManager.write_file()
	_close()
	UiManager.menu_object.queue_free()
	UiManager.menu_object = load("res://Scenes/SupportScenes/shop.tscn").instantiate()
	get_tree().get_root().get_node("Menu").add_child(UiManager.menu_object)
	
func open_ability(ind, number):
	DataManager.data_money -= GameConstants.PriseUnblockCard[GameConstants.DATA_TOWER[number].type].abilit_prise[ind]
	DataManager.data["Resources"]["money"] = DataManager.data_money
	get_tree().get_root().get_node("Menu/Panel/HBoxContainer/Label").text = str(DataManager.data_money)
	
	var turret_key = "Turret_" + str(number + 1) + "T1"
	DataManager.tower_data[turret_key]["ability"][ind] = true
	
	DataManager.write_file()
	_close()
	UiManager.menu_object.queue_free()
	UiManager.menu_object = load("res://Scenes/SupportScenes/shop.tscn").instantiate()
	get_tree().get_root().get_node("Menu").add_child(UiManager.menu_object)
	
func upgrade_card(number):
	DataManager.data_money_spend(prise)
	DataManager.add_critical_damage(GameConstants.ADD_CRITICAL_DAMAGE_UP_CARD)
	get_tree().get_root().get_node("Menu/Panel/HBoxContainer/Label").text = str(DataManager.data_money)
	get_tree().get_root().get_node("Menu/Panel/HBoxContainer/Label2").text = str(DataManager.critical_damage)
	var turret_key = "Turret_" + str(number + 1) + "T1"
	DataManager.tower_data[turret_key]["cards"] = int(DataManager.tower_data[turret_key]["cards"]) - TowerCards.get_cards_needed(number)
	DataManager.tower_data[turret_key]["level"] = int(DataManager.tower_data[turret_key]["level"]) + 1
	DataManager.write_file()
	_close()
	UiManager.menu_object.queue_free()
	UiManager.menu_object = load("res://Scenes/SupportScenes/shop.tscn").instantiate()
	get_tree().get_root().get_node("Menu").add_child(UiManager.menu_object)
	
func _create_card_of_parametr(data, id):
	var obj
	var text = ""
	for i in range(len(GameConstants.DATA_TOWER[id].text)):
		obj = load("res://Scenes/SupportScenes/card_of_parametr.tscn").instantiate()
		PanelParametr.add_child(obj)
		obj.get_node("VBoxContainer/HBoxContainer/NinePatchRect").texture = load(GameConstants.DATA_TOWER[id].img[i])
		obj.get_node("VBoxContainer/Label").text = GameConstants.DATA_TOWER[id].text[i]
		if level < GameConstants.NUMBER_LVL_TURRET_CARD:
			if GameConstants.DATA_TOWER[id].text[i] != "KEY_RELOAD":
				text = "+"
			else:
				text = ""
			if GameConstants.DATA_TOWER[id]["parametr_" + str(i + 1)][level + 1] is Array:
				obj.get_node("VBoxContainer/HBoxContainer2/Label").text = str(GameConstants.DATA_TOWER[id]["parametr_" + str(i + 1)][level + 1][0])
				text += str(GameConstants.round_to_dec(GameConstants.DATA_TOWER[id]["parametr_" + str(i + 1)][level + 1][0] - GameConstants.DATA_TOWER[id]["parametr_" + str(i + 1)][level][0], 2))
			else:
				obj.get_node("VBoxContainer/HBoxContainer2/Label").text = str(GameConstants.DATA_TOWER[id]["parametr_" + str(i + 1)][level])
				text += str(GameConstants.round_to_dec(GameConstants.DATA_TOWER[id]["parametr_" + str(i + 1)][level + 1] - GameConstants.DATA_TOWER[id]["parametr_" + str(i + 1)][level], 2))
		else:
			if GameConstants.DATA_TOWER[id]["parametr_" + str(i + 1)][level] is Array:
				obj.get_node("VBoxContainer/HBoxContainer2/Label").text = str(GameConstants.DATA_TOWER[id]["parametr_" + str(i + 1)][level][0])
			else:
				obj.get_node("VBoxContainer/HBoxContainer2/Label").text = str(GameConstants.DATA_TOWER[id]["parametr_" + str(i + 1)][level])
		obj.get_node("VBoxContainer/HBoxContainer2/Label2").text = text

func _close():
	self.queue_free()
