extends Control

func setup(data: Dictionary) -> void:
	if GameConstants.CARDS_MASTERY_MAX_LVL == int(data["mastery_lvl"]):
		get_node("Panel/VBoxContainer/Shop/HBoxContainer/Label2").text = ""
		get_node("Panel/VBoxContainer/Shop/HBoxContainer/Label3").text = ""
		get_node("Panel/VBoxContainer/Shop/HBoxContainer/Label2").text = tr("MAX_LVL")
	else:
		get_node("Panel/VBoxContainer/Shop/HBoxContainer/Label2").text = str(int(data["mastery_xp"]))
		get_node("Panel/VBoxContainer/Shop/HBoxContainer/Label4").text = str(GameConstants.CARDS_MASTERY_NEED_XP_LVL[int(data["mastery_lvl"])])
		get_node("Panel/VBoxContainer/Shop/TextureProgressBar").value = int(data["mastery_xp"])
		get_node("Panel/VBoxContainer/Shop/TextureProgressBar").max_value = int(GameConstants.CARDS_MASTERY_NEED_XP_LVL[int(data["mastery_lvl"])])
	var panel
	for i in range(len(GameConstants.CARDS_MASTERY_NEED_XP_LVL)):
		if int(data["mastery_lvl"]) > i:
			panel = load("res://Scenes/SupportScenes/mastery_lvl_have.tscn").instantiate()
		else:
			panel = load("res://Scenes/SupportScenes/mastery_lvl.tscn").instantiate()
		panel.setup(i)
		get_node("Panel/VBoxContainer/Shop/ScrollContainer/HBoxContainer").add_child(panel)
	get_node("Panel/VBoxContainer/HBoxContainer/Close").pressed.connect(close)
	
func close():
	queue_free()
