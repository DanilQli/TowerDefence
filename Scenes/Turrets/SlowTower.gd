extends TowerBase
class_name SlowTower

var intensivity: float
var duration: float

func _ready() -> void:
	super._ready()
	
func fire() -> void:
	if not block_damage and is_ready:
		is_ready = false
		fire_missile()
		for e in enemy_array:
			if is_instance_valid(e):
				e.on_hit(intensivity, 0, GameConstants.TowerType.SLOW, self, duration * 60)
		if ability[0]:
			for e in enemy_array:
				if is_instance_valid(e):
					if ability[1] and e is Enemy_boss:
						e.on_hit(e.hp / GameConstants.TURRET_4_ABILITY_1, 0, GameConstants.TowerType.AREA, self)
					else:
						e.on_hit(e.hp / GameConstants.TURRET_4_ABILITY_0, 0, GameConstants.TowerType.AREA, self)
		await get_tree().create_timer((multiplier_rof_enemy * rof)).timeout
		is_ready = true

func _initialize() -> void:
	get_node("Range/CollisionShape2D").shape.radius = 0.5 * range

func fire_missile() -> void:
	var fx = preload("res://Scenes/SupportScenes/ProjecttileImpact_2.tscn").instantiate()
	fx.scale = Vector2(range / 50, range / 50)
	add_child(fx)
