extends "res://Scenes/UI/Turrets.gd"


func _on_range_area_entered(body):
	print(enemy_array)
	enemy_array.append(body.get_parent())


func _on_range_body_exited(body):
	enemy_array.erase(body.get_parent())
