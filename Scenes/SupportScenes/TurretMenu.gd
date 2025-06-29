extends Control

var strategy := 0
var st := 0
var list_strategy := [tr("KEY_FIRST"), tr("KEY_LAST"), tr("KEY_RANDOM")]

func setup(type_attack):
	self.z_index = 1
	match type_attack:
		GameConstants.TowerType.NORMAL, GameConstants.TowerType.AREA:
			get_node("V/HStrateg/Strateg").pressed.connect(strateg)
			get_node("V/HDamage/HText/Name").text = tr("KEY_DAMAGE")
			get_node("V/HReload/HText/Name").text = tr("KEY_RELOAD")
			get_node("V/HRange/HText/Name").text = tr("KEY_RANGE")
			get_node("V/HInflicted/HText/Name").text = tr("KEY_INFLICTED")
			self.size[1] = self.size[1] - 30
			get_node("V/HTick").queue_free()
			get_node("V/HStrateg/Strateg").text = list_strategy[st]
			get_node("V/HDamage/HText/TextureRect").texture = load("res://.godot/imported/damage.png-872b5ccd784ae534d29ff2b790dfc3b4.ctex")
			get_node("V/HReload/HText/TextureRect").texture = load("res://.godot/imported/reload.png-640ae2fae7d793eb56d026ec5a460b96.ctex")
			get_node("V/HRange/HText/TextureRect").texture = load("res://.godot/imported/range.png-d3745379c73ab4ee989b44544ccbbc0e.ctex")
			get_node("V/HInflicted/HText/TextureRect").texture = load("res://.godot/imported/inflicted.png-1c2e6895b23b900526e6ad6b6c10ab68.ctex")
		GameConstants.TowerType.SLOW:
			get_node("V/HStrateg/Strateg").disabled = true
			get_node("V/HDamage/HText/Name").text = tr("KEY_INTENSIVITY")
			get_node("V/HReload/HText/Name").text = tr("KEY_DURATION")
			get_node("V/HRange/HText/Name").text = tr("KEY_RELOAD")
			get_node("V/HInflicted/HText/Name").text = tr("KEY_RANGE")
			self.size[1] = self.size[1] - 30
			get_node("V/HTick").queue_free()
			get_node("V/HDamage/HText/TextureRect").texture = load("res://.godot/imported/intensivity.png-1ce49c6ac50637b96205d06fd83040cd.ctex")
			get_node("V/HReload/HText/TextureRect").texture = load("res://.godot/imported/duration.png-74d70b7c6b29a77461a04fd5357fe67f.ctex")
			get_node("V/HRange/HText/TextureRect").texture = load("res://.godot/imported/reload.png-640ae2fae7d793eb56d026ec5a460b96.ctex")
			get_node("V/HInflicted/HText/TextureRect").texture = load("res://.godot/imported/range.png-d3745379c73ab4ee989b44544ccbbc0e.ctex")
		GameConstants.TowerType.MONEY:
			get_node("V/HStrateg/Strateg").disabled = true
			get_node("V/HDamage/HText/Name").text = tr("KEY_SPEED")
			get_node("V/HReload/HText/Name").text = tr("KEY_INCOME")
			self.size[1] = self.size[1] - 90
			get_node("V/HRange").queue_free()
			get_node("V/HInflicted").queue_free()
			get_node("V/HTick").queue_free()
			get_node("V/HDamage/HText/TextureRect").texture = load("res://.godot/imported/intensivity.png-1ce49c6ac50637b96205d06fd83040cd.ctex")
			get_node("V/HReload/HText/TextureRect").texture = load("res://.godot/imported/duration.png-74d70b7c6b29a77461a04fd5357fe67f.ctex")
		GameConstants.TowerType.MOVEMENT:
			get_node("V/HStrateg/Strateg").disabled = true
			get_node("V/HDamage/HText/Name").text = tr("KEY_DISTANCE")
			get_node("V/HReload/HText/Name").text = tr("KEY_RELOAD")
			get_node("V/HRange/HText/Name").text = tr("KEY_RANGE")
			get_node("V/HInflicted/HText/Name").text = tr("KEY_INFLICTED")
			self.size[1] = self.size[1] - 30
			get_node("V/HTick").queue_free()
			get_node("V/HStrateg/Strateg").text = list_strategy[st]
			get_node("V/HDamage/HText/TextureRect").texture = load("res://.godot/imported/distance.png-a3097e1cb8e56e338aba8f1c30601538.ctex")
			get_node("V/HReload/HText/TextureRect").texture = load("res://.godot/imported/reload.png-640ae2fae7d793eb56d026ec5a460b96.ctex")
			get_node("V/HRange/HText/TextureRect").texture = load("res://.godot/imported/range.png-d3745379c73ab4ee989b44544ccbbc0e.ctex")
			get_node("V/HInflicted/HText/TextureRect").texture = load("res://.godot/imported/inflicted.png-1c2e6895b23b900526e6ad6b6c10ab68.ctex")
		GameConstants.TowerType.POISON:
			get_node("V/HDamage/HText/Name").text = tr("KEY_DAMAGE")
			get_node("V/HReload/HText/Name").text = tr("KEY_RELOAD")
			get_node("V/HRange/HText/Name").text = tr("KEY_RANGE")
			get_node("V/HInflicted/HText/Name").text = tr("KEY_DURATION")
			get_node("V/HTick/HText/Name").text = tr("KEY_TICK")
			get_node("V/HInflicted/HValue/Up").visible = true
			get_node("V/HStrateg/Strateg").text = list_strategy[st]
			get_node("V/HDamage/HText/TextureRect").texture = load("res://.godot/imported/damage.png-872b5ccd784ae534d29ff2b790dfc3b4.ctex")
			get_node("V/HReload/HText/TextureRect").texture = load("res://.godot/imported/reload.png-640ae2fae7d793eb56d026ec5a460b96.ctex")
			get_node("V/HRange/HText/TextureRect").texture = load("res://.godot/imported/range.png-d3745379c73ab4ee989b44544ccbbc0e.ctex")
			get_node("V/HInflicted/HText/TextureRect").texture = load("res://.godot/imported/duration.png-74d70b7c6b29a77461a04fd5357fe67f.ctex")
			get_node("V/HTick/HText/TextureRect").texture = load("res://Assets/Icons/tick.png")

func strateg():
	if strategy == 2:
		st = 0
	else:
		st = strategy + 1

	get_node("V/HStrateg/Strateg").text = list_strategy[st]
	strategy = st
	
