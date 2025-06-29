extends TowerBase
class_name MoneyTower

var income: float
var speed: float

func _ready():
	type_attack = GameConstants.TowerType.MONEY
	get_node("Timer").wait_time = speed
	get_node("Timer").timeout.connect(_on_timer_timeout)
	get_node("Timer").start()
	super._ready()
	get_node("AnimationPlayer").play("Fire")

func fire(): pass
func _apply_damage(): pass

func _on_timer_timeout():
	var profit = income * (GameSession.speed_game if GameSession.speed_game != 0.0 else 1.0)
	ResourceManager.add_money(int(profit))
	emit_signal("money_in_game_session_changed")
