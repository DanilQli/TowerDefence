extends Control
var st = 0
var list_strategy = [tr("KEY_FIRST"), tr("KEY_LAST"), tr("KEY_RANDOM")]

func _ready():
	if get_parent().type_attack == 0:
		self.get_node("V/HStrateg/Strateg").pressed.connect(strateg)
		self.get_node("V/HDamage/HText/Name").text = tr("KEY_DAMAGE")
		self.get_node("V/HReload/HText/Name").text = tr("KEY_RELOAD")
		self.get_node("V/HRange/HText/Name").text = tr("KEY_RANGE")
		self.get_node("V/HInflicted/HText/Name").text = tr("KEY_INFLICTED")
		self.get_node("V/HStrateg/Strateg").text = list_strategy[st]
		self.get_node("V/HDamage/HText/TextureRect").texture = load("res://.godot/imported/damage.png-872b5ccd784ae534d29ff2b790dfc3b4.ctex")
		self.get_node("V/HReload/HText/TextureRect").texture = load("res://.godot/imported/reload.png-640ae2fae7d793eb56d026ec5a460b96.ctex")
		self.get_node("V/HRange/HText/TextureRect").texture = load("res://.godot/imported/range.png-d3745379c73ab4ee989b44544ccbbc0e.ctex")
		self.get_node("V/HInflicted/HText/TextureRect").texture = load("res://.godot/imported/inflicted.png-1c2e6895b23b900526e6ad6b6c10ab68.ctex")
	elif get_parent().type_attack == 1:
		self.get_node("V/HStrateg/Strateg").disabled = true
		self.get_node("V/HDamage/HText/Name").text = tr("KEY_INTENSIVITY")
		self.get_node("V/HReload/HText/Name").text = tr("KEY_DURATION")
		self.get_node("V/HRange/HText/Name").text = tr("KEY_RELOAD")
		self.get_node("V/HInflicted/HText/Name").text = tr("KEY_RANGE")
		self.get_node("V/HDamage/HText/TextureRect").texture = load("res://.godot/imported/intensivity.png-1ce49c6ac50637b96205d06fd83040cd.ctex")
		self.get_node("V/HReload/HText/TextureRect").texture = load("res://.godot/imported/duration.png-74d70b7c6b29a77461a04fd5357fe67f.ctex")
		self.get_node("V/HRange/HText/TextureRect").texture = load("res://.godot/imported/reload.png-640ae2fae7d793eb56d026ec5a460b96.ctex")
		self.get_node("V/HInflicted/HText/TextureRect").texture = load("res://.godot/imported/range.png-d3745379c73ab4ee989b44544ccbbc0e.ctex")
	else:
		self.get_node("V/HStrateg/Strateg").disabled = true
		self.get_node("V/HDamage/HText/Name").text = tr("KEY_DISTANCE")
		self.get_node("V/HReload/HText/Name").text = tr("KEY_RELOAD")
		self.get_node("V/HRange/HText/Name").text = tr("KEY_RANGE")
		self.get_node("V/HInflicted/HText/Name").text = tr("KEY_INFLICTED")
		self.get_node("V/HStrateg/Strateg").text = list_strategy[st]
		self.get_node("V/HDamage/HText/TextureRect").texture = load("res://.godot/imported/distance.png-a3097e1cb8e56e338aba8f1c30601538.ctex")
		self.get_node("V/HReload/HText/TextureRect").texture = load("res://.godot/imported/reload.png-640ae2fae7d793eb56d026ec5a460b96.ctex")
		self.get_node("V/HRange/HText/TextureRect").texture = load("res://.godot/imported/range.png-d3745379c73ab4ee989b44544ccbbc0e.ctex")
		self.get_node("V/HInflicted/HText/TextureRect").texture = load("res://.godot/imported/inflicted.png-1c2e6895b23b900526e6ad6b6c10ab68.ctex")

func strateg():
	if get_parent().strategy == 2:
		st = 0
	else:
		st = get_parent().strategy + 1
	self.get_node("V/HStrateg/Strateg").text = list_strategy[st]
	get_parent().strategy = st
	
