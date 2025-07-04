extends ColorRect

var level: int
@onready var turretMaxIcon = $Panel/MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/TextureRect/TextureRect
@onready var turretMaxName = $Panel/MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/Label
@onready var turretMaxLvl = $Panel/MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/Lvl
@onready var turretMaxLox = $Panel/MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/CardOf/Lock
@onready var CardOf = $Panel/MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/CardOf/CardOf
@onready var CardOfText = $Panel/MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/CardOf/CardOf/Label
@onready var CardOfDesc = $Panel/MarginContainer/ScrollContainer/VBoxContainer/RichTextLabel
@onready var PanelParametr = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Parametr/ScrollContainer/HBoxContainer
@onready var openLvlBut = $Panel/MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/Button
@onready var abilityText = [$Panel/MarginContainer/ScrollContainer/VBoxContainer/Control1/RichTextLabel, $Panel/MarginContainer/ScrollContainer/VBoxContainer/Control2/RichTextLabel]
@onready var abilityTextLock = [$Panel/MarginContainer/ScrollContainer/VBoxContainer/Control1/Lock/VBoxContainer/Label, $Panel/MarginContainer/ScrollContainer/VBoxContainer/Control2/Lock/VBoxContainer/Label]
@onready var abilityLock = [$Panel/MarginContainer/ScrollContainer/VBoxContainer/Control1/Lock/VBoxContainer/HBoxContainer/NinePatchRect, $Panel/MarginContainer/ScrollContainer/VBoxContainer/Control2/Lock/VBoxContainer/HBoxContainer/NinePatchRect]
@onready var abilityBut = [$Panel/MarginContainer/ScrollContainer/VBoxContainer/Control1/Lock/VBoxContainer/HBoxContainer2/Button, $Panel/MarginContainer/ScrollContainer/VBoxContainer/Control2/Lock/VBoxContainer/HBoxContainer2/Button]
@onready var abilityColor = [$Panel/MarginContainer/ScrollContainer/VBoxContainer/Control1/Lock/ColorRect, $Panel/MarginContainer/ScrollContainer/VBoxContainer/Control2/Lock/ColorRect]

@onready var close = $Panel/Close


func setup(data: Dictionary, number: int) -> void:
	turretMaxIcon.texture = load("res://Assets/Props/towerDefense_tile_turret_" + str(number + 1) + ".png")
	turretMaxName.text = tr("KEY_NAME_TURRET_" + str(number + 1))
	level = int(data["level"])
	CardOfDesc.text = tr("KEY_TURRET" + str(number + 1) + "_DESC")
	var prise: int
	if not data["have"]:
		turretMaxLvl.text = tr("KEY_NOT_FOUND")
		prise = GameConstants.PriseUnblockCard[GameConstants.DATA_TOWER[number].type].open_card
		openLvlBut.text = tr("KEY_UNBLOCK_FOR") + str(prise)
	else:
		turretMaxLvl.text = tr("KEY_LVL") + str(level + 1)
		prise = GameConstants.PriseUnblockCard[GameConstants.DATA_TOWER[number].type].prise_up_money[level]
		openLvlBut.text = tr("KEY_UP") + str(prise)
		turretMaxLox.queue_free()
		CardOf.max_value = TowerCards.get_cards_needed(number)
		CardOf.value = int(data["cards"])
		CardOfText.text = str(int(CardOf.value)) + "/" + str(int(CardOf.max_value))
	close.pressed.connect(_close)
	_create_card_of_parametr(data, int(data["type_attack"]))
	if prise <= DataManager.data_money:
		if not data["have"]:
			openLvlBut.pressed.connect(get_parent().buy_turret.bind(prise, number))
		else:
			openLvlBut.pressed.connect(upgrade_card)
		var style = openLvlBut.get_theme_stylebox("normal").duplicate()
		style.set("bg_color", Color(0.4, 0.7, 0.0))
		openLvlBut.add_theme_stylebox_override("normal", style)
	for i in range(len(GameConstants.LEVEL_OPEN_ABILITY)):
		abilityText[i].text = tr("KEY_TURRET" + str(number + 1) + "_UP" + str(i) + "_DESC")
		if not data["ability"][i] and level + 1 < GameConstants.LEVEL_OPEN_ABILITY[i]:
			abilityTextLock[i].text = tr("KEY_AVAILABLE_ON1") + " " + str(GameConstants.LEVEL_OPEN_ABILITY[i]) + " " + tr("KEY_AVAILABLE_ON2")
			abilityBut[i].text = tr("KEY_UNBLOCK_FOR") + str(GameConstants.PriseUnblockCard[GameConstants.DATA_TOWER[number].type].abilit_prise[i])
		elif not data["ability"][i] and level + 1 >= GameConstants.LEVEL_OPEN_ABILITY[i] and GameConstants.PriseUnblockCard[GameConstants.DATA_TOWER[number].type].abilit_prise[i] >= DataManager.data_money:
			var style = abilityBut.get_theme_stylebox("normal").duplicate()
			style.set("bg_color", Color(0.4, 0.7, 0.0))
			abilityBut[i].add_theme_stylebox_override("normal", style)
			openLvlBut.pressed.connect(open_ability.bind(i))
		else:
			abilityColor[i].queue_free()
			abilityBut[i].queue_free()
			abilityLock[i].queue_free()
			abilityTextLock[i].queue_free()

func open_ability(ind):
	pass
	
func upgrade_card():
	pass
	
func _create_card_of_parametr(data, type):
	var obj
	var text
	for i in range(len(GameConstants.DATA_TOWER[type].text)):
		obj = load("res://Scenes/SupportScenes/card_of_parametr.tscn").instantiate()
		PanelParametr.add_child(obj)
		obj.get_node("VBoxContainer/HBoxContainer/NinePatchRect").texture = load(GameConstants.DATA_TOWER[type].img[i])
		obj.get_node("VBoxContainer/Label").text = GameConstants.DATA_TOWER[type].text[i]
		if GameConstants.DATA_TOWER[type].text[i] != "KEY_RELOAD":
			text = "+"
		else:
			text = ""
		if GameConstants.DATA_TOWER[type]["parametr_" + str(i + 1)][level + 1] is Array:
			obj.get_node("VBoxContainer/HBoxContainer2/Label").text = str(GameConstants.DATA_TOWER[type]["parametr_" + str(i + 1)][level + 1][0])
			if level + 1 == GameConstants.NUMBER_LVL_TURRET_CARD:
				text = ""
			else:
				text += str(GameConstants.DATA_TOWER[type]["parametr_" + str(i + 1)][level + 2][0] - GameConstants.DATA_TOWER[type]["parametr_" + str(i + 1)][level + 1][0])
		else:
			obj.get_node("VBoxContainer/HBoxContainer2/Label").text = str(GameConstants.DATA_TOWER[type]["parametr_" + str(i + 1)][level])
			if level + 1 == GameConstants.NUMBER_LVL_TURRET_CARD:
				text = ""
			else:
				text += str(GameConstants.DATA_TOWER[type]["parametr_" + str(i + 1)][level + 1] - GameConstants.DATA_TOWER[type]["parametr_" + str(i + 1)][level])
		obj.get_node("VBoxContainer/HBoxContainer2/Label2").text = text

func _close():
	self.queue_free()
