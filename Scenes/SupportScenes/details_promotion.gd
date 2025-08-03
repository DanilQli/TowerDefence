extends Control


func setup(id) -> void:
	get_node("VBoxContainer/Panel/Close").pressed.connect(close)
	get_node("VBoxContainer/Panel/VBoxContainer/HBoxContainer/Label2").text = str(int(DataManager.promotion_progress_level[id]))
	get_node("VBoxContainer/Panel/VBoxContainer/HBoxContainer/Label4").text = str(GameConstants.NUMBER_MINI_PROMOTION)
	get_node("VBoxContainer/Panel/VBoxContainer/TextureProgressBar").max_value = GameConstants.NUMBER_MINI_PROMOTION
	get_node("VBoxContainer/Panel/VBoxContainer/TextureProgressBar").value = int(DataManager.promotion_progress_level[id])
	var k = 0
	for i in get_node("VBoxContainer/Panel/VBoxContainer/HBoxContainer2").get_children():
		i.get_node("VBoxContainer/VBoxContainer/Label").text = tr("KEY_PROMOTION_DESC_" + str(id + 1)) + str(GameConstants.NUMBER_LEVEL_PROMOTION[id][DataManager.promotion_progress_level[id]])
		i.get_node("VBoxContainer/VBoxContainer/HBoxContainer/NinePatchRect").texture = load("res://Assets/Icons/medal_" + str(id + 1) + ".png")
		i.get_node("VBoxContainer/VBoxContainer2/HBoxContainer/Label").text = str(GameConstants.NUMBER_EXPERIENCE_PROMOTION[id][k])
		if k < DataManager.promotion_progress_level[id]:
			i.get_node("ColorRect").queue_free()
			i.get_node("VBoxContainer/VBoxContainer2/HBoxContainer2/Label2").queue_free()
			i.get_node("VBoxContainer/VBoxContainer2/HBoxContainer2/Label3").queue_free()
			i.get_node("VBoxContainer/VBoxContainer2/HBoxContainer2/Label4").queue_free()
			i.get_node("VBoxContainer/VBoxContainer2/HBoxContainer2/Label1").text = tr("KEY_COMPLETED") +  " " + str(DataManager.promotion_progress_level_data_end[id][k])
		elif k == DataManager.promotion_progress_level[id]:
			i.get_node("VBoxContainer/VBoxContainer2/HBoxContainer2/Label2").text = str(int(DataManager.promotion_progress[id]))
			i.get_node("VBoxContainer/VBoxContainer2/HBoxContainer2/Label4").text = str(int(GameConstants.NUMBER_LEVEL_PROMOTION[id][DataManager.promotion_progress_level[id]]))
		else:
			i.get_node("VBoxContainer/VBoxContainer2/HBoxContainer2/Label1").text = ""
			i.get_node("VBoxContainer/VBoxContainer2/HBoxContainer2/Label2").text = ""
			i.get_node("VBoxContainer/VBoxContainer2/HBoxContainer2/Label3").text = ""
			i.get_node("VBoxContainer/VBoxContainer2/HBoxContainer2/Label4").text = ""
		k += 1
	
func close():
	UiManager.menu_object.visible = true
	self.queue_free()
