extends Control

func _ready() -> void:
	_connect_signals()
	check_promotion_level()
	get_node("VBoxContainer/Panel/VBoxContainer/HBoxContainerLevel/TextureButton/VBoxContainer/VBoxContainer/HBoxContainer/HBoxContainer2/Label1").text = str(DataManager.promotion_stars)
	get_node("VBoxContainer/Panel/VBoxContainer/HBoxContainerLevel/TextureButton/VBoxContainer/VBoxContainer/HBoxContainer/HBoxContainer2/Label3").text = str(GameConstants.NEED_PROMOTION_STAR_LEVEL[DataManager.promotion_level])
	get_node("VBoxContainer/Panel/VBoxContainer/HBoxContainerLevel/TextureButton/VBoxContainer/VBoxContainer/HBoxContainer/HBoxContainer/Label2").text = str(DataManager.promotion_level + 1)
	get_node("VBoxContainer/Panel/VBoxContainer/HBoxContainerLevel/TextureButton/VBoxContainer/VBoxContainer/TextureProgressBar").value = DataManager.promotion_stars
	get_node("VBoxContainer/Panel/VBoxContainer/HBoxContainerLevel/TextureButton/VBoxContainer/VBoxContainer/TextureProgressBar").max_value = GameConstants.NEED_PROMOTION_STAR_LEVEL[DataManager.promotion_level]
	var ob
	var all = 0
	for i in range(GameConstants.NUMBER_PROMOTION):
		ob = load("res://Scenes/SupportScenes/panel_promotion.tscn").instantiate()
		ob.setup(i)
		get_node("VBoxContainer/Panel/VBoxContainer/HBoxContainerAll/VBoxContainer/ScrollContainer/HFlowContainer").add_child(ob)
		all += int(DataManager.promotion_progress_level[i])
	get_node("VBoxContainer/Panel/VBoxContainer/HBoxContainerAll/VBoxContainer/HBoxContainer/Label2").text = str(all)
	get_node("VBoxContainer/Panel/VBoxContainer/HBoxContainerAll/VBoxContainer/HBoxContainer/Label4").text = str(GameConstants.NUMBER_PROMOTION * GameConstants.NUMBER_MINI_PROMOTION)

func _connect_signals() -> void:
	get_node("VBoxContainer/Panel/Close").pressed.connect(close)
	
func close() -> void:
	get_parent().get_node("MarginContainer2").visible = true
	queue_free()

func check_promotion_level():
	while DataManager.promotion_level < len(GameConstants.NEED_PROMOTION_STAR_LEVEL) and DataManager.promotion_stars >= GameConstants.NEED_PROMOTION_STAR_LEVEL[DataManager.promotion_level]:
		DataManager.promotion_stars -= GameConstants.NEED_PROMOTION_STAR_LEVEL[DataManager.promotion_level]
		DataManager.promotion_level += 1
		DataManager.write_file()
