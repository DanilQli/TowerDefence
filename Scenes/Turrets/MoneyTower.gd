extends TowerBase
class_name MoneyTower

var income: float
var income_end: float

func update():
	if ability[1]:
		income_end = income + (income * len(ResourceManager.list_turret[5]) / 100.0)
	else:
		income_end = income

func _ready():
	type_attack = GameConstants.TowerType.MONEY
	get_node("Timer").wait_time = rof
	get_node("Timer").timeout.connect(_on_timer_timeout)
	get_node("Timer").start()
	super._ready()
	get_node("AnimationPlayer").play("Fire")

func _on_timer_timeout():
	if not block_damage:
		var profit = income_end * GameSession.speed_game
		GameSession.add_money(profit)

func _initialize() -> void:
	super._initialize()
	if self.ability[1]:
		self.get_node("Panel").visible = true
		for i in range(len(ResourceManager.list_turret[self.id])):
			ResourceManager.list_turret[self.id][i].get_node("Panel/Label").text = str(len(ResourceManager.list_turret[self.id]))
			ResourceManager.list_turret[self.id][i].update()
	for i in range(len(ResourceManager.list_turret[self.id])):
		ResourceManager.list_turret[self.id][i].update()
