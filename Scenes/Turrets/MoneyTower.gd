extends TowerBase
class_name MoneyTower

var income: float
var income_end: float

var mastery_damage: float = 1.0
var mastery_speed: float = 1.0
var mastery_chanse_crit: float = 1.0
var mastery_cost_upgrade: float = 1.0
var mastery_damage_boss: float = 1.0

func update():
	if ability[1]:
		income_end = income + (income * len(ResourceManager.list_turret[5]) / 100.0)
	else:
		income_end = income

func _ready():
	type_attack = GameConstants.TowerType.MONEY
	super._ready()
	get_node("AnimationPlayer").play("Fire")

func _on_timer_timeout():
	if not block_damage:
		var profit = income_end * GameSession.speed_game
		DataManager.mastery_moneytower_session[id] += profit
		GameSession.add_money(profit)
		
func fire() -> void:
	super.fire()
	if not block_damage:
		is_ready = false
		_apply_damage()
		await get_tree().create_timer(multiplier_rof_all * rof * mastery_speed).timeout
		is_ready = true
		_on_timer_timeout()
		
func _initialize() -> void:
	super._initialize()
	if self.ability[1]:
		self.get_node("Panel").visible = true
		for i in range(len(ResourceManager.list_turret[self.id])):
			ResourceManager.list_turret[self.id][i].get_node("Panel/Label").text = str(len(ResourceManager.list_turret[self.id]))
			ResourceManager.list_turret[self.id][i].update()
	for i in range(len(ResourceManager.list_turret[self.id])):
		ResourceManager.list_turret[self.id][i].update()
