extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	get_node("VBoxContainer/Panel/VBoxContainer/HBoxContainer/ButArmanent").pressed.connect(open_armanent)
	get_node("VBoxContainer/Panel/VBoxContainer/HBoxContainer/ButShop").pressed.connect(open_shop)
	get_node("VBoxContainer/Panel/VBoxContainer/HBoxContainer/Close").pressed.connect(close)
	for i in range(len(GameData.tower_data)):
		var panel = load("res://Scenes/SupportScenes/turret_max.tscn").instantiate()
		var data = GameData.tower_data["Turret_" + str(i + 1) + "T1"]
		panel.get_node("VBoxContainer/TextureRect/TextureRect").texture = load("res://Assets/Props/towerDefense_tile_turret_" + str(i + 1) + ".png")
		panel.get_node("VBoxContainer/Label").text = tr("KEY_NAME_TURRET_" + str(i + 1))
		if data["type attack"] in [0, 3]:
			panel.get_node("VBoxContainer/HBoxContainer1/Label1").text = tr("KEY_DAMAGE")
			panel.get_node("VBoxContainer/HBoxContainer2/Label1").text = tr("KEY_RELOAD")
			panel.get_node("VBoxContainer/HBoxContainer3/Label1").text = tr("KEY_RANGE")
			panel.get_node("VBoxContainer/HBoxContainer1/Label2").text = str(data["damage"][0])
			panel.get_node("VBoxContainer/HBoxContainer2/Label2").text = str(data["rof"][0])
			panel.get_node("VBoxContainer/HBoxContainer3/Label2").text = str(data["range"][0])
			panel.get_node("VBoxContainer/HBoxContainer4").queue_free()
		elif data["type attack"] == 1:
			panel.get_node("VBoxContainer/HBoxContainer1/Label1").text = tr("KEY_INTENSIVITY")
			panel.get_node("VBoxContainer/HBoxContainer2/Label1").text = tr("KEY_DURATION")
			panel.get_node("VBoxContainer/HBoxContainer3/Label1").text = tr("KEY_RELOAD")
			panel.get_node("VBoxContainer/HBoxContainer4/Label1").text = tr("KEY_RANGE")
			panel.get_node("VBoxContainer/HBoxContainer1/Label2").text = str(data["intensivity"][0])
			panel.get_node("VBoxContainer/HBoxContainer2/Label2").text = str(data["duration"][0])
			panel.get_node("VBoxContainer/HBoxContainer3/Label2").text = str(data["rof"][0])
			panel.get_node("VBoxContainer/HBoxContainer4/Label2").text = str(data["range"][0])
		elif data["type attack"] == 2:
			panel.get_node("VBoxContainer/HBoxContainer1/Label1").text = tr("KEY_DISTANCE")
			panel.get_node("VBoxContainer/HBoxContainer2/Label1").text = tr("KEY_RELOAD")
			panel.get_node("VBoxContainer/HBoxContainer3/Label1").text = tr("KEY_RANGE")
			panel.get_node("VBoxContainer/HBoxContainer1/Label2").text = str(data["distance"][0])
			panel.get_node("VBoxContainer/HBoxContainer2/Label2").text = str(data["rof"][0])
			panel.get_node("VBoxContainer/HBoxContainer3/Label2").text = str(data["range"][0])
			panel.get_node("VBoxContainer/HBoxContainer4").queue_free()
		get_node("VBoxContainer/Panel/VBoxContainer/Shop/ScrollContainer/HBoxContainer").add_child(panel)
		
		if data["have"]:
			panel.get_node("VBoxContainer/Button").queue_free()
			var have = load('res://Scenes/SupportScenes/turret_choose.tscn').instantiate()
			have.get_node("VBoxContainer/TextureRect/TextureRect").texture = load("res://Assets/Props/towerDefense_tile_turret_" + str(i + 1) + ".png")
			have.get_node("VBoxContainer/Label").text = tr("KEY_NAME_TURRET_" + str(i + 1))
			get_node("VBoxContainer/Panel/VBoxContainer/Armanent/Vbox/Hb/GridContainer").add_child(have)
			if data["activity"]:
				var activity = load('res://Scenes/SupportScenes/turret_mini.tscn').instantiate()
				activity.get_node("VBoxContainer/TextureRect/TextureRect").texture = load("res://Assets/Props/towerDefense_tile_turret_" + str(i + 1) + ".png")
				activity.get_node("VBoxContainer/Label").text = tr("KEY_NAME_TURRET_" + str(i + 1))
				get_node("VBoxContainer/Panel/VBoxContainer/Armanent/Vbox/Panel/HBoxContainer").add_child(activity)
		else:
			panel.get_node("VBoxContainer/Button").text = tr("KEY_BUY_FOR") + " " + str(data["prise"])
func open_armanent():
	get_node("VBoxContainer/Panel/VBoxContainer/Armanent").visible = true
	get_node("VBoxContainer/Panel/VBoxContainer/Shop").visible = false
	
func open_shop():
	get_node("VBoxContainer/Panel/VBoxContainer/Armanent").visible = false
	get_node("VBoxContainer/Panel/VBoxContainer/Shop").visible = true
	
func close():
	get_parent().get_node("MarginContainer2").visible = true
	get_node(".").queue_free()
