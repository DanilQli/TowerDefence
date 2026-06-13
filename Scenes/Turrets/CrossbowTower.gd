extends TowerBase
class_name CrossnowTower

var damage: float = 0.0
var phase: bool = false
var duration_1: float = 0.0
var duration_2: float = 0.0
var up_attack_speed: float = 0.0
var critical_damage_all
var base_rof: float
var phase_num: int = 0
var phase_damage: float = 0.0

var phase_time: float = 0.0
var current_phase_duration: float

@onready var polygon = $Turret/Polygon2D

func _ready():
	super._ready()
	base_rof = rof
	_start_phase_1()

func _process(delta):
	if len(ability) > 0:
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
	if ability[0] and randi_range(0, 100) <= GameConstants.TURRET_3_ABILITY_0:
		_start_phase_1()
	phase_num += 1
	if phase_num == 3:
		phase_num = 0
		phase_damage = (damage * multiplier_damage_all * mastery_damage) * GameConstants.TURRET_3_ABILITY_1
	else:
		phase_damage = (damage * multiplier_damage_all * mastery_damage)
	phase = true
	rof = base_rof / (up_attack_speed / 100)
	current_phase_duration = duration_2
	polygon.visible = true

func fire() -> void:
	super.fire()
	if not block_damage and is_ready:
		is_ready = false
		get_node("AnimationPlayer").play("Fire")
		_apply_damage()
		await get_tree().create_timer((multiplier_rof_all * rof * mastery_speed)).timeout
		is_ready = true
	
func _apply_damage() -> void:
	if enemy:
		critical_damage_all = critical_damage()
		func_add_deal_damage(critical_damage_all)
		inflicted += critical_damage_all
		enemy.on_hit(critical_damage_all, 0, GameConstants.TowerType.GUN, self)
		emit_signal("damage_inflicted_changed", inflicted)

func critical_damage():
	if force_next_attack_crit or randi_range(0, 100) <= GameConstants.CHANCE_CRITICAL_DAMAGE * mastery_chanse_crit:
		emit_signal("tower_crit", self)
		force_next_attack_crit = false
		if enemy is Enemy_boss:
			return (phase_damage * mastery_damage_boss) + (DataManager.critical_damage * (phase_damage * mastery_damage_boss)) / 100
		return phase_damage + (DataManager.critical_damage * phase_damage) / 100
	else:
		if enemy is Enemy_boss:
			return phase_damage * mastery_damage_boss
		return phase_damage
		
func _initialize() -> void:
	super._initialize()
	get_node("Range/CollisionShape2D").shape.radius = 0.5 * range
