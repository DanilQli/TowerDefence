extends ColorRect

var level: int
@onready var turretMaxIcon = $Panel/MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/TextureRect/TextureRect
@onready var turretMaxName = $Panel/MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/Label
@onready var turretMaxLvl = $Panel/MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/Lvl
@onready var turretMaxLox = $Panel/MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/CardOf/Lock
@onready var CardOf = $Panel/MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/CardOf/CardOf
@onready var CardOfText = $Panel/MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/CardOf/CardOf/Label
@onready var parametr0Value = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Parametr/ColorRect0/HBoxContainer/Value
@onready var parametr0Value2 = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Parametr/ColorRect0/HBoxContainer/Label2
@onready var parametr1Icon = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Parametr/ColorRect1/HBoxContainer/NinePatchRect
@onready var parametr1Name = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Parametr/ColorRect1/HBoxContainer/Name
@onready var parametr1Value = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Parametr/ColorRect1/HBoxContainer/Value
@onready var parametr1Value2 = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Parametr/ColorRect1/HBoxContainer/Label2
@onready var parametr2Icon = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Parametr/ColorRect2/HBoxContainer/NinePatchRect
@onready var parametr2Name = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Parametr/ColorRect2/HBoxContainer/Name
@onready var parametr2Value = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Parametr/ColorRect2/HBoxContainer/Value
@onready var parametr2Value2 = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Parametr/ColorRect2/HBoxContainer/Label2
@onready var parametr3 = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Parametr/ColorRect3
@onready var parametr3Icon = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Parametr/ColorRect3/HBoxContainer/NinePatchRect
@onready var parametr3Name = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Parametr/ColorRect3/HBoxContainer/Name
@onready var parametr3Value = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Parametr/ColorRect3/HBoxContainer/Value
@onready var parametr3Value2 = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Parametr/ColorRect3/HBoxContainer/Label2
@onready var parametr4 = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Parametr/ColorRect4
@onready var parametr4Icon = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Parametr/ColorRect4/HBoxContainer/NinePatchRect
@onready var parametr4Name = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Parametr/ColorRect4/HBoxContainer/Name
@onready var parametr4Value = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Parametr/ColorRect4/HBoxContainer/Value
@onready var parametr4Value2 = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Parametr/ColorRect4/HBoxContainer/Label2
@onready var parametr5 = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Parametr/ColorRect5
@onready var parametr5Icon = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Parametr/ColorRect5/HBoxContainer/NinePatchRect
@onready var parametr5Name = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Parametr/ColorRect5/HBoxContainer/Name
@onready var parametr5Value = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Parametr/ColorRect5/HBoxContainer/Value
@onready var parametr5Value2 = $Panel/MarginContainer/ScrollContainer/VBoxContainer/Parametr/ColorRect5/HBoxContainer/Label2
@onready var close = $Panel/Close

func setup(data: Dictionary, number: int) -> void:
	turretMaxIcon.texture = load("res://Assets/Props/towerDefense_tile_turret_" + str(number + 1) + ".png")
	turretMaxName.text = tr("KEY_NAME_TURRET_" + str(number + 1))
	level = int(data["level"]) - 1
	if not data["have"]:
		turretMaxLvl.text = tr("KEY_NOT_FOUND") 
	else:
		turretMaxLvl.text = tr("KEY_LVL") + str(level + 1)
	if data["have"]:
		turretMaxLox.queue_free()
		CardOf.max_value = TowerCards.get_cards_needed(number)
		CardOf.value = int(data["cards"])
		CardOfText.text = str(int(CardOf.value)) + "/" + str(int(CardOf.max_value))
	close.pressed.connect(_close)
	parametr0Value.text = str(level + 1) + " " + tr("KEY_LVL")
	parametr0Value2.text = str(level + 2) + " " + tr("KEY_LVL")
	match int(data["type_attack"]):
		0, 3:
			_setup_damage_turret(data)
		1:
			_setup_slow_turret(data)
		2:
			_setup_movement_turret(data)
		4:
			_setup_money_turret(data)
		5:
			_setup_poison_turret(data)

func _setup_damage_turret(data: Dictionary) -> void:
	parametr1Name.text = tr("KEY_DAMAGE")
	parametr2Name.text = tr("KEY_RELOAD")
	parametr3Name.text = tr("KEY_RANGE")
	parametr1Value.text = str(data["damage"][level])
	parametr2Value.text = str(data["rof"][level])
	parametr3Value.text = str(data["range"][level])
	parametr1Icon.texture = load("res://.godot/imported/damage.png-872b5ccd784ae534d29ff2b790dfc3b4.ctex")
	parametr2Icon.texture = load("res://.godot/imported/reload.png-640ae2fae7d793eb56d026ec5a460b96.ctex")
	parametr3Icon.texture = load("res://.godot/imported/range.png-d3745379c73ab4ee989b44544ccbbc0e.ctex")
	if int(data["level"]) - 1 < GameConstants.NUMBER_LVL_TURRET_CARD:
		parametr1Value2.text = str(data["damage"][level + 1])
		parametr2Value2.text = str(data["rof"][level + 1])
		parametr3Value2.text = str(data["range"][level + 1])
	parametr4.queue_free()
	parametr5.queue_free()

func _setup_slow_turret(data: Dictionary) -> void:
	parametr1Name.text = tr("KEY_INTENSIVITY")
	parametr2Name.text = tr("KEY_DURATION")
	parametr3Name.text = tr("KEY_RELOAD")
	parametr4Name.text = tr("KEY_RANGE")
	parametr1Value.text = str(data["intensivity"][level])
	parametr2Value.text = str(data["duration"][level])
	parametr3Value.text = str(data["rof"][level])
	parametr4Value.text = str(data["range"][level])
	parametr1Icon.texture = load("res://.godot/imported/intensivity.png-1ce49c6ac50637b96205d06fd83040cd.ctex")
	parametr2Icon.texture = load("res://.godot/imported/duration.png-74d70b7c6b29a77461a04fd5357fe67f.ctex")
	parametr3Icon.texture = load("res://.godot/imported/reload.png-640ae2fae7d793eb56d026ec5a460b96.ctex")
	parametr4Icon.texture = load("res://.godot/imported/range.png-d3745379c73ab4ee989b44544ccbbc0e.ctex")
	if int(data["level"]) - 1 < GameConstants.NUMBER_LVL_TURRET_CARD:
		parametr1Value2.text = str(data["intensivity"][level + 1])
		parametr2Value2.text = str(data["duration"][level + 1])
		parametr3Value2.text = str(data["rof"][level + 1])
		parametr4Value2.text = str(data["range"][level + 1])
	parametr5.queue_free()

func _setup_movement_turret(data: Dictionary) -> void:
	parametr1Name.text = tr("KEY_DISTANCE")
	parametr2Name.text = tr("KEY_RELOAD")
	parametr3Name.text = tr("KEY_RANGE")
	parametr1Value.text = str(data["distance"][level])
	parametr2Value.text = str(data["rof"][level])
	parametr3Value.text = str(data["range"][level])
	parametr1Icon.texture = load("res://.godot/imported/distance.png-a3097e1cb8e56e338aba8f1c30601538.ctex")
	parametr2Icon.texture = load("res://.godot/imported/reload.png-640ae2fae7d793eb56d026ec5a460b96.ctex")
	parametr3Icon.texture = load("res://.godot/imported/range.png-d3745379c73ab4ee989b44544ccbbc0e.ctex")
	if int(data["level"]) - 1 < GameConstants.NUMBER_LVL_TURRET_CARD:
		parametr1Value2.text = str(data["distance"][level + 1])
		parametr2Value2.text = str(data["rof"][level + 1])
		parametr3Value2.text = str(data["range"][level + 1])
	parametr4.queue_free()
	parametr5.queue_free()

func _setup_money_turret(data: Dictionary) -> void:
	parametr1Name.text = tr("KEY_INCOME")
	parametr2Name.text = tr("KEY_SPEED")
	parametr1Value.text = str(data["speed"][level])
	parametr2Value.text = str(data["income"][level])
	parametr1Icon.texture = load("res://.godot/imported/intensivity.png-1ce49c6ac50637b96205d06fd83040cd.ctex")
	parametr2Icon.texture = load("res://.godot/imported/duration.png-74d70b7c6b29a77461a04fd5357fe67f.ctex")
	if int(data["level"]) - 1 < GameConstants.NUMBER_LVL_TURRET_CARD:
		parametr1Value2.text = str(data["speed"][level + 1])
		parametr2Value2.text = str(data["income"][level + 1])
	parametr3.queue_free()
	parametr4.queue_free()
	parametr5.queue_free()

func _setup_poison_turret(data: Dictionary) -> void:
	parametr1Name.text = tr("KEY_DAMAGE")
	parametr2Name.text = tr("KEY_RELOAD")
	parametr3Name.text = tr("KEY_RANGE")
	parametr4Name.text = tr("KEY_DURATION")
	parametr5Name.text = tr("KEY_TICK")
	parametr1Value.text = str(data["damage"][level])
	parametr2Value.text = str(data["rof"][level])
	parametr3Value.text = str(data["range"][level])
	parametr4Value.text = str(data["duration"][level])
	parametr5Value.text = str(data["tick"][level])
	parametr1Icon.texture = load("res://.godot/imported/damage.png-872b5ccd784ae534d29ff2b790dfc3b4.ctex")
	parametr2Icon.texture = load("res://.godot/imported/reload.png-640ae2fae7d793eb56d026ec5a460b96.ctex")
	parametr3Icon.texture = load("res://.godot/imported/range.png-d3745379c73ab4ee989b44544ccbbc0e.ctex")
	parametr4Icon.texture = load("res://.godot/imported/duration.png-74d70b7c6b29a77461a04fd5357fe67f.ctex")
	parametr5Icon.texture = load("res://Assets/Icons/tick.png")
	if int(data["level"]) - 1 < GameConstants.NUMBER_LVL_TURRET_CARD:
		parametr1Value2.text = str(data["damage"][level + 1])
		parametr2Value2.text = str(data["rof"][level + 1])
		parametr3Value2.text = str(data["range"][level + 1])
		parametr4Value2.text = str(data["duration"][level + 1])
		parametr5Value2.text = str(data["tick"][level + 1])

func _close():
	self.queue_free()
