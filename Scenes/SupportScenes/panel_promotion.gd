extends Button

func setup(id):
	id = int(id)
	self.pressed.connect(details.bind(id))
	get_node("VBoxContainer/Label").text = tr("KEY_PROMOTION_NAME_" + str(id + 1))
	get_node("VBoxContainer/HBoxContainer/NinePatchRect").texture = load("res://Assets/Icons/medal_" + str(id + 1) + ".png")
	if int(DataManager.promotion_progress_level[id]) == 0:
		get_node("HBoxContainer2").queue_free()
	else:
		get_node("ColorRect").queue_free()
		get_node("HBoxContainer2/Label1").text = str(int(DataManager.promotion_progress_level[id]))
	get_node("HBoxContainer2/Label3").text = str(GameConstants.NUMBER_MINI_PROMOTION)
	get_node("VBoxContainer/TextureProgressBar").value = int(DataManager.promotion_progress[id])
	get_node("VBoxContainer/TextureProgressBar").max_value = int(GameConstants.NUMBER_LEVEL_PROMOTION[id][DataManager.promotion_progress_level[id]])

func details(id):
	UiManager.menu_object.visible = false
	var obj = load("res://Scenes/SupportScenes/details_promotion.tscn").instantiate()
	obj.setup(id)
	get_tree().current_scene.add_child(obj)
