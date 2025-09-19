extends TowerBase
class_name SlowTower

var intensivity: float
var duration: float

var mastery_damage: float = 1.0
var mastery_speed: float = 1.0
var mastery_chanse_crit: float = 1.0
var mastery_cost_upgrade: float = 1.0
var mastery_damage_boss: float = 1.0

func _ready() -> void:
	super._ready()
	
func fire() -> void:
	if not block_damage and is_ready:
		is_ready = false
		fire_missile()
		for e in enemy_array:
			if is_instance_valid(e):
				DataManager.mastery_slowtower_session += 1
				e.on_hit(intensivity, 0, GameConstants.TowerType.SLOW, self, duration * 60)
		if ability[0]:
			for e in enemy_array:
				if is_instance_valid(e):
					if ability[1] and e is Enemy_boss:
						e.on_hit(e.hp / GameConstants.TURRET_4_ABILITY_1, 0, GameConstants.TowerType.AREA, self)
					else:
						e.on_hit(e.hp / GameConstants.TURRET_4_ABILITY_0, 0, GameConstants.TowerType.AREA, self)
		await get_tree().create_timer((multiplier_rof_all * rof * mastery_speed)).timeout
		is_ready = true

func _initialize() -> void:
	get_node("Range/CollisionShape2D").shape.radius = 0.5 * range

func fire_missile() -> void:
	var fx = preload("res://Scenes/SupportScenes/ProjecttileImpact_2.tscn").instantiate()
	fx.scale = Vector2(range / 50, range / 50)
	add_child(fx)
