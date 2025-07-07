extends TowerBase
class_name SlowTower

var damage: float
var intensivity: float
var duration: float

func _ready() -> void:
	super._ready()
	duration *= 60
	
func fire() -> void:
	is_ready = false
	fire_missile()
	for e in enemy_array:
		if is_instance_valid(e):
			e.on_hit(intensivity, type, 0, GameConstants.TowerType.SLOW, current_lvl, duration)

	await get_tree().create_timer(rof).timeout
	is_ready = true

func _initialize() -> void:
	get_node("Range/CollisionShape2D").shape.radius = 0.5 * range

func fire_missile() -> void:
	var fx = preload("res://Scenes/SupportScenes/ProjecttileImpact_2.tscn").instantiate()
	fx.scale = Vector2(range / 50, range / 50)
	add_child(fx)

func _apply_damage() -> void:
	pass  # нет применения напрямую, всё внутри fire
