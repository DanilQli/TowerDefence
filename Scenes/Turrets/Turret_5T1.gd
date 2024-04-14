extends "res://Scenes/UI/Turrets.gd"


func _oe_body_entered(body):
	enemy_array.append(body.get_parent())


func _on_range_body_exited(body):
	enemy_array.erase(body.get_parent())
	
