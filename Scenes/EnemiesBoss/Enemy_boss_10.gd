extends Enemy_boss
class_name Enemy_boss_10

func on_destroy(tower_id=-1):
	for i in range(3):
		var road_speed = load("res://Scenes/SupportScenes/road_speed.tscn").instantiate()
		var pos = GameManager.LIST_COORDS_ROAD[randi_range(0, len(GameManager.LIST_COORDS_ROAD) - 1)]
		road_speed.position = pos
		get_tree().current_scene.get_node("Map").add_child(road_speed)
	super.on_destroy(tower_id)
