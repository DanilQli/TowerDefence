extends Enemy_boss
class_name Enemy_boss_13

@onready var range_area: Area2D = $Range

func _ready() -> void:
	super._ready()
	range_area.connect("area_entered", Callable(self, "_on_range_area_entered"))
	
func _on_range_area_entered(area: Node) -> void:
	var parent = area.get_parent()
	if parent and parent.has_method("select_enemy"):
		if parent.current_lvl > 0:
			var new_impact = projectile_impact_1.instantiate()
			new_impact.position = parent.global_position
			new_impact.z_index = 5
			new_impact.scale = Vector2i(1, 1)
			get_tree().root.get_node(".").add_child(new_impact)
			parent.current_lvl -= 1
			parent.upgrade_system.apply_upgrade_effects()
			parent.upgrade_system.update_ui()
