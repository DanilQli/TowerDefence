extends Enemy_boss
class_name Enemy_boss_9

var phase: bool = false
var duration_1: float = 3.0
var duration_2: float = 3.0
@onready var sprite2d = get_node("Sprite2D")

func _ready() -> void:
	super._ready()
	phase_f()
	
func on_hit(damage, type_explosion, type_attack, tower, parametrs=false) -> void:
	if phase:
		super.on_hit(0, type_explosion, type_attack, tower, parametrs)
	else:
		super.on_hit(damage, type_explosion, type_attack, tower, parametrs)

func phase_f():
	phase = false
	sprite2d.modulate = Color(1, 1, 1, 1)
	await get_tree().create_timer(duration_1).timeout
	phase = true
	sprite2d.modulate = Color(1, 1, 1, 0.392)
	await get_tree().create_timer(duration_2).timeout
	phase_f()
