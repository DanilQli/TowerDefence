# Scenes/SupportScenes/TurretMenu.gd
extends Control

var strategy := 0
var st := 0
var list_strategy := [tr("KEY_FIRST"), tr("KEY_LAST"), tr("KEY_RANDOM")]
@onready var list_nodes = [get_node("V/0"), get_node("V/1"), get_node("V/2"), get_node("V/3"), get_node("V/4"), get_node("V/5"), 
					get_node("V/6")]
var list_node = []

func _ready() -> void:
	self.z_index = 2
	
func setup(id):
	var btn = get_node("V/HStrateg/Strateg")
	
	# Очищаем старые подключения, если они есть (на всякий случай)
	if btn.pressed.is_connected(strateg):
		btn.pressed.disconnect(strateg)
		
	btn.text = list_strategy[st]
	
	if GameConstants.DATA_TOWER[id].strateg:
		# Безопасное подключение
		if not btn.pressed.is_connected(strateg):
			btn.pressed.connect(strateg)
		btn.disabled = false
	else:
		btn.disabled = true
		
	list_node.clear() # Очищаем список перед заполнением
	
	# Восстанавливаем узлы, если они были удалены (для переиспользования меню)
	# В текущей реализации меню создается заново, но логика фильтрации:
	for i in range(len(list_nodes)):
		if is_instance_valid(list_nodes[i]):
			if not i + 1 in GameConstants.DATA_TOWER[id].queue_free:
				list_nodes[i].visible = true
				list_node.append(list_nodes[i])
			else:
				list_nodes[i].visible = false
				# Не удаляем queue_free, просто скрываем, чтобы не ломать ссылки
				
	# Корректируем размер окна
	var hidden_count = 7 - list_node.size()
	custom_minimum_size.y = 200 + (hidden_count * 30)
	size.y = custom_minimum_size.y

	for i in range(len(GameConstants.DATA_TOWER[id].text)):
		if i < list_node.size():
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
