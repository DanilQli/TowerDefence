extends Button

@onready var turretMaxIcon = $VBoxContainer/TextureRect/TextureRect
@onready var turretMaxName = $VBoxContainer/Label
@onready var turretMaxLvl = $VBoxContainer/Lvl
@onready var turretMaxLox = $VBoxContainer/CardOf/Lock
@onready var CardOf = $VBoxContainer/CardOf/CardOf
@onready var CardOfText = $VBoxContainer/CardOf/CardOf/Label

func setup(data: Dictionary, number: int) -> void:
	turretMaxIcon.texture = load("res://Assets/Props/towerDefense_tile_turret_" + str(number + 1) + ".png")
	turretMaxName.text = tr("KEY_NAME_TURRET_" + str(number + 1))
	var level = int(data["level"])
	if not data["have"]:
		turretMaxLvl.text = tr("KEY_NOT_FOUND") 
	else:
		turretMaxLvl.text = tr("KEY_LVL") + str(level + 1)
	if data["have"]:
		turretMaxLox.queue_free()
		CardOf.max_value = TowerCards.get_cards_needed(number)
		CardOf.value = int(data["cards"])
		CardOfText.text = str(int(CardOf.value)) + "/" + str(int(CardOf.max_value))
	self.pressed.connect(turret_menu_open.bind(data, number))
	
func turret_menu_open(data, number):
	var menu = load("res://Scenes/SupportScenes/turret_menu_shop.tscn").instantiate()
	get_tree().current_scene.add_child(menu)
	menu.setup(data, number)
