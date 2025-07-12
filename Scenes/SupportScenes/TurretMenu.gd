extends Control

var strategy := 0
var st := 0
var list_strategy := [tr("KEY_FIRST"), tr("KEY_LAST"), tr("KEY_RANDOM")]
@onready var list_nodes = [get_node("V/0"), get_node("V/1"), get_node("V/2"), get_node("V/3"), get_node("V/4"), get_node("V/5"), 
					get_node("V/6")]
var list_node = []

func _ready() -> void:
	self.z_index = 1
	
func setup(id):
	get_node("V/HStrateg/Strateg").text = list_strategy[st]
	get_node("V/HStrateg/Strateg").disabled = GameConstants.DATA_TOWER[id].strateg
	for i in range(len(list_nodes)):
		if not i + 1 in GameConstants.DATA_TOWER[id].queue_free:
			list_node.append(list_nodes[i])
		else:
			list_nodes[i].queue_free()
			size[1] -= 30
			
	for i in range(len(GameConstants.DATA_TOWER[id].text)):
		list_node[i].get_node("HValue/NameValue").text = GameConstants.DATA_TOWER[id].name_label[i]
		list_node[i].get_node("HText/VBoxContainer/TextureRect").texture = load(GameConstants.DATA_TOWER[id].img[i])
		list_node[i].get_node("HText/Name").text = GameConstants.DATA_TOWER[id].text[i]
		
func strateg():
	if strategy == 2:
		st = 0
	else:
		st = strategy + 1

	get_node("V/HStrateg/Strateg").text = list_strategy[st]
	strategy = st
	
