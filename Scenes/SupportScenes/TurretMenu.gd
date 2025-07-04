extends Control

var strategy := 0
var st := 0
var list_strategy := [tr("KEY_FIRST"), tr("KEY_LAST"), tr("KEY_RANDOM")]

func setup(type_attack):
	self.z_index = 1
	self.size[1] = self.size[1] - 30 * (GameConstants.NUMBER_MAX_EFFECT_CARD - len(GameConstants.DATA_TOWER[type_attack].text))
	get_node("V/HStrateg/Strateg").text = list_strategy[st]
	get_node("V/HStrateg/Strateg").disabled = GameConstants.DATA_TOWER[type_attack].strateg
	for i in range(len(GameConstants.DATA_TOWER[type_attack].text)):
		get_node("V/" + str(i) + "/HText/TextureRect").texture = load(GameConstants.DATA_TOWER[type_attack].img[i])
		get_node("V/" + str(i) + "/HText/Name").text = GameConstants.DATA_TOWER[type_attack].text[i]
	for i in GameConstants.DATA_TOWER[type_attack].queue_free:
		get_node("V/" + str(i)).queue_free()
		
func strateg():
	if strategy == 2:
		st = 0
	else:
		st = strategy + 1

	get_node("V/HStrateg/Strateg").text = list_strategy[st]
	strategy = st
	
