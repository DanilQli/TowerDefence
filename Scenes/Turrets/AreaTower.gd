extends TowerBase
class_name AreaTower

var damage: float = 0.0
var num_enemy: int = 1
var ability_0: int = 0
var dam

func fire() -> void:
	is_ready = false
	get_node("AnimationPlayer").play("Fire")
	_apply_damage()
	await get_tree().create_timer(rof).timeout
	is_ready = true

func _apply_damage() -> void:
	num_enemy = (current_lvl + 1) / 2
	var alredy = 0
	for e in enemy_array:
		if is_instance_valid(e):
			dam = critical_damage()
			inflicted += dam
			e.on_hit(dam, type, 0, GameConstants.TowerType.AREA, current_lvl)
			alredy += 1
			emit_signal("damage_inflicted_changed", inflicted)
		if alredy >= num_enemy:
			break

func critical_damage():
	var damage_all = damage + ability_0 * GameConstants.TURRET_1_ABILITY_1
	if randi_range(0, 100) <= GameConstants.CHANCE_CRITICAL_DAMAGE:
		return damage_all + (DataManager.critical_damage * damage_all) / 100
	else:
		return damage_all
		
func _initialize() -> void:
	super._initialize()
	get_node("Range/CollisionShape2D").shape.radius = 0.5 * range

"""Пушка атакует [color='blue']первые несколько целей[/color] в зависимости от ранга: одна цель на первом, две на третьем, три на пятом...пять на девятом",
Смерть боса пометит [color='blue']случайную ракету[/color]. Урон за каждую метку увеличивается на [color='blue']3%[/color],
Увеличивает шанс критического урона по боссам на [color='blue']5%[/color] от всех ракет,"""
