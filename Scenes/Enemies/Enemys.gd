extends PathFollow2D

signal base_damage(damage)
signal base_money()
var damage = 1

var speed
var current_speed
var hp
var names
var new_impact
var duration_speed_mod

@onready var health_bar = self.get_node("HealthBar")
@onready var impact_area = self.get_node("Impact")
var projectile_impact_1 = preload("res://Scenes/SupportScenes/ProjecttileImpact_1.tscn")
var projectile_impact_3 = preload("res://Scenes/SupportScenes/ProjecttileImpact_3.tscn")

func _ready():
	self.hp += self.hp * GameData.current_wave * (GameData.strengthening_enemies + (GameData.strengthening_enemies_dop * GameData.current_wave))
	self.health_bar.max_value = hp
	self.health_bar.value = hp
	self.health_bar.top_level = true
	
func _physics_process(delta):
	if self.progress_ratio == 1.0:
		emit_signal("base_damage", self.damage) 
		queue_free()
	move(delta)
	
func move(delta):
	self.progress += self.speed * delta
	if self.duration_speed_mod > 0:
		self.duration_speed_mod -= 1
		if self.duration_speed_mod == 1:
			self.speed = self.current_speed
	self.health_bar.set_position(self.position - Vector2(30, 30))

func on_hit(damage, type_turret, type_explosion, type_attack, level):
	if type_attack in [0, 2]:
		impact(type_explosion, type_attack)
	if type_attack == 0:
		self.hp -= damage
		self.health_bar.visible = true
		self.health_bar.value = hp
		if self.hp <= 0:
			GameData.current_money += int(GameData.enemy_data[self.names]["money death"]) + int(float(GameData.enemy_data[self.names]["money death"]) * GameData.current_wave * GameData.strengthening_money)
			get_parent().get_parent().get_parent().base_money()
			on_destroy()
	elif type_attack == 1:
		self.speed -= (self.speed * float(GameData.tower_data[type_turret]["intensivity"][level]))
		if self.speed < 50:
			self.speed = 50
		self.duration_speed_mod = int(GameData.tower_data[type_turret]["duration"][level])
	else:
		self.progress -= float(GameData.tower_data[type_turret]["distance"][level])

func impact(type_explosion, type_attack):
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
	get_node("CharacterBody2D").queue_free()
	await get_tree().create_timer(0.2).timeout
	self.queue_free()
