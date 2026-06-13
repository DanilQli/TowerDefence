# Scenes/EnemiesBoss/Enemy_boss_8.gd
extends Enemy_boss
class_name Enemy_boss_8

@onready var range_area: Area2D = $Range
@onready var plants_texture = preload("res://Assets/Icons/wild_plants.png")
var list_tower_enemy_8: Array = []

func _ready() -> void:
	super._ready()
	range_area.connect("area_entered", Callable(self, "_on_range_area_entered"))
	
func _on_range_area_entered(area: Node) -> void:
	var parent = area.get_parent()
	if parent and parent.has_method("select_enemy"):
		if parent.has_node("NinePatchRect"):
			parent.get_node('NinePatchRect').visible = true
			parent.get_node('NinePatchRect').texture = plants_texture
			parent.multiplier_rof_enemy = 0.2
			list_tower_enemy_8.append(parent)

func on_destroy(tower_id=-1):
	for tower in list_tower_enemy_8:
		if is_instance_valid(tower):
			if tower.has_node('NinePatchRect'):
				tower.get_node('NinePatchRect').visible = false
			tower.multiplier_rof_enemy = 0.0
	
	list_tower_enemy_8.clear()
	
	super.on_destroy(tower_id)
