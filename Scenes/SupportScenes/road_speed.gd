extends Sprite2D

var speed: float = 0.20
var radius: int = 40

func _ready() -> void:
	add_to_group("speed")
	self.z_index = 0
