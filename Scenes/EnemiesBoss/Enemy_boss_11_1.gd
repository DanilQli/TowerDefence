extends Enemy_boss
class_name Enemy_boss_11_1

var parent
var ind

func on_destroy(tower_id=-1):
	if parent:
		parent.list_children[ind] = 0
	super.on_destroy(tower_id)
