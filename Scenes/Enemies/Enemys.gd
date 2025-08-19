extends PathFollow2D
class_name Enemy

signal base_damage(damage)
signal money_in_game_session_changed()
var damage = 1

var speed
var current_speed
var hp
var base_hp
var id
var names
var new_impact
var duration_speed_mod
var poison_data = null
var poison_tick_timer = 0.0
var speed_modifer = 1.0
# Так как урон от препятствия проверяется в _physics_process, то урон должен наносится лишь 3 раза в секунду
var hole_move = 19

@onready var health_bar = self.get_node("HealthBar")
@onready var impact_area = self.get_node("Impact")
@onready var poison_effect = $PoisonEffect
var projectile_impact_1 = preload("res://Scenes/SupportScenes/ProjecttileImpact_1.tscn")
var projectile_impact_3 = preload("res://Scenes/SupportScenes/ProjecttileImpact_3.tscn")
var projectile_impact_4 = preload("res://Scenes/SupportScenes/ProjecttileImpact_4.tscn")

func _ready():
	self.z_index = 1
	self.hp += self.hp * GameSession.current_wave * (DataManager.strengthening_enemies + (DataManager.strengthening_enemies_dop * GameSession.current_wave))
	self.base_hp = self.hp
	self.health_bar.max_value = base_hp
	self.health_bar.value = hp
	self.health_bar.top_level = true
	ResourceManager.list_active_enemy.append(self)
	
func _physics_process(delta):
	if self.progress_ratio == 1.0:
		emit_signal("base_damage", self.damage) 
		queue_free()
	move(delta)
	process_poison(delta)

func apply_poison(data: Dictionary) -> void:
	poison_data = {
		"damage": data.damage,
		"duration": data.duration,
		"tick": data.tick,
		"timer": 0.0
	}
	poison_tick_timer = 0.0
	# Запускаем анимацию
	poison_effect.visible = true
	poison_effect.get_node("AnimationPlayer").play("Poison")

func process_poison(delta: float) -> void:
	if poison_data == null:
		return
		
	poison_data.duration -= delta
	poison_tick_timer -= delta
	
	# Наносим урон по тику
	if poison_tick_timer <= 0:
		poison_tick_timer = poison_data.tick
		self.hp -= poison_data.damage
		self.health_bar.visible = true
		self.health_bar.value = hp
		
		if self.hp <= 0:
			GameSession.add_game_score(int(float(GameConstants.DATA_ENEMY[id].money_death) / 2 * (GameSession.current_wave / 3.0)))
			GameSession.add_money(int(GameConstants.DATA_ENEMY[id].money_death) + int(float(GameConstants.DATA_ENEMY[id].money_death) * GameSession.current_wave * DataManager.strengthening_money))
			on_destroy()
			return
	
	# Проверяем окончание действия яда
	if poison_data.duration <= 0:
		poison_data = null
		# Останавливаем анимацию
		poison_effect.visible = false
		poison_effect.get_node("AnimationPlayer").stop()
	
func move(delta):
	var is_in_hole = false
	for hole in get_tree().get_nodes_in_group("holes"):
		if position.distance_to(hole.position) <= hole.radius:
			is_in_hole = hole
			break
	if is_in_hole:
		self.speed = self.current_speed * GameConstants.OBSTACLE_SLOW
		if hole_move % 20 == 0:
			on_hit(is_in_hole.damage / 3, -1, GameConstants.TowerType.GUN, false)
		hole_move += 1
	else:
		if self.duration_speed_mod <= 1:
			self.speed = self.current_speed
		hole_move = 19
	for speed in get_tree().get_nodes_in_group("speed"):
		if position.distance_to(speed.position) <= speed.radius and self.speed_modifer < 1.6:
			self.speed_modifer += speed.speed
			speed.queue_free()
			break
	
	self.progress += self.speed * ResourceManager.speed_modifer * self.speed_modifer * delta
	if self.duration_speed_mod > 0:
		self.duration_speed_mod -= 1
		if self.duration_speed_mod < 1:
			self.speed = self.current_speed
	self.health_bar.set_position(self.position - Vector2(30, 30))

func on_hit(damage, type_explosion, type_attack, towers, parametrs=false):
	if type_attack in [0, 1]:
		if type_explosion >= 0:
			impact(type_explosion, type_attack)
	if type_attack in [0, 1]:
		self.hp -= damage
		self.health_bar.visible = true
		self.health_bar.value = hp
		if self.hp <= 0:
			GameSession.add_game_score(int(float(GameConstants.DATA_ENEMY[id].money_death) / 2 * (GameSession.current_wave / 3.0)))
			GameSession.add_money(int(GameConstants.DATA_ENEMY[id].money_death) + int(float(GameConstants.DATA_ENEMY[id].money_death) * GameSession.current_wave * DataManager.strengthening_money))
			on_destroy()
	elif type_attack == GameConstants.TowerType.SLOW:
		self.speed *= (100 - damage) / 100.0
		if self.speed < 50:
			self.speed = 50
		self.duration_speed_mod = parametrs
	elif type_attack == 3:
		self.progress_ratio -= damage
		if self.progress_ratio < 0:
			self.progress_ratio = 0

func impact(type_explosion, type_attack):
	if type_explosion == 5:
		new_impact = projectile_impact_4.instantiate()
		new_impact.position = Vector2(impact_area.global_position.x, impact_area.global_position.y - 10)
		new_impact.z_index = 5
		get_tree().current_scene.add_child(new_impact)
	else:
		randomize()
		var x_pos = randi() % 31
		randomize()
		var y_pos = randi() % 31
		var impact_location = Vector2(x_pos, y_pos)
		if type_attack == 0 and type_explosion == 1:
			new_impact = projectile_impact_3.instantiate()
		else:
			new_impact = projectile_impact_1.instantiate()
		new_impact.position = impact_location
		impact_area.add_child(new_impact)

func on_destroy():
	if len(ResourceManager.list_turret[5]) > 0 and ResourceManager.list_turret[5][0].ability[0]:
		GameSession.add_money(len(ResourceManager.list_turret[5]))
	ResourceManager.list_active_enemy.erase(self)
	self.queue_free()
