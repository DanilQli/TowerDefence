extends TowerBase
class_name CrossnowTower

var damage: float = 0.0
var phase: bool = false
var duration_1: float = 0.0
var duration_2: float = 0.0
var up_attack_speed: float = 0.0
var critical_damage_all
var base_rof: float

var phase_time: float = 0.0
var current_phase_duration: float

@onready var polygon = $Turret/Polygon2D

func _ready():
	super._ready()
	base_rof = rof
	_start_phase_1()

func _process(delta):
	phase_time += delta
	if phase_time >= current_phase_duration:
		phase_time = 0
		if phase:
			_start_phase_1()
		else:
			_start_phase_2()

func _start_phase_1():
	phase = false
	rof = base_rof
	current_phase_duration = duration_1
	polygon.visible = false

func _start_phase_2():
	phase = true
	rof = base_rof / (up_attack_speed / 100)
	current_phase_duration = duration_2
	polygon.visible = true

func fire() -> void:
	if not block_damage and is_ready:
		is_ready = false
		get_node("AnimationPlayer").play("Fire")
		_apply_damage()
		await get_tree().create_timer(rof).timeout
		is_ready = true
	
func _apply_damage() -> void:
	if enemy:
		critical_damage_all = critical_damage()
		inflicted += critical_damage_all
		enemy.on_hit(critical_damage_all, type, 0, GameConstants.TowerType.GUN, current_lvl)
		emit_signal("damage_inflicted_changed", inflicted)

func critical_damage():
	if randi_range(0, 100) <= GameConstants.CHANCE_CRITICAL_DAMAGE:
		return damage + (DataManager.critical_damage * damage) / 100
	else:
		return damage
		
func _initialize() -> void:
	super._initialize()
	get_node("Range/CollisionShape2D").shape.radius = 0.5 * range
