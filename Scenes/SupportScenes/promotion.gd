extends Control

func _ready() -> void:
	_connect_signals()
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
