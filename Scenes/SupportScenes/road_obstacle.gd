extends Sprite2D

var damage
var radius: int = 40

func _ready() -> void:
	add_to_group("holes")
	self.z_index = 0
	await get_tree().create_timer(GameConstants.ROAD_OBSTACLE).timeout
	GameManager.list_coords_road_use_index.erase(position)
	self.queue_free()
