extends Node2D

signal base_money()

var type
var type_attack
var type_explosion
var enemy_array = []
var built = false
var enemy
var is_ready = true
var category
var inflicted = 0
var intensivity
var duration
var range
var rof
var damage
var strategy
var radius
var current_lvl
var max_lvl


func _ready():
	if built:
		self.get_node("Range/CollisionShape2D").get_shape().radius = 0.5 * self.range
		self.get_node("MenuButton").pressed.connect(_on_menu_button_pressed)
		self.get_node("Menu/V/HButton/Close").pressed.connect(hide_menu)
		self.get_node("Menu/V/HButton/Up").pressed.connect(upgrade)
		self.get_node("Menu/V/HButton/Up").disabled = true
		update_menu()
		update_menu_upgrade()
			
func _physics_process(delta):
	if enemy_array.size() != 0 and built:
		select_enemy()
		if self.type_attack != 1 and not get_node("AnimationPlayer").is_playing():
			turn()
		if is_ready:
			fire()
	else: 
		enemy = null
		
func turn():
#	var enemy_position = i.get_parent().get_curve().get_baked_length() - i.progress()
	get_node("Turret").look_at(enemy.position)

func select_enemy():
	var enemy_progress_array = []
	for i in enemy_array:
		enemy_progress_array.append(i.progress)
	var max_offset
	if strategy == 0:
		max_offset = enemy_progress_array.max()
	elif strategy == 1:
		max_offset = enemy_progress_array.min()
	else:
		max_offset = enemy_progress_array[randi() % enemy_progress_array.size()]
	var enemy_index = enemy_progress_array.find(max_offset) 
	enemy = enemy_array[enemy_index]

func fire():
	is_ready = false
	if self.type_attack in [0, 2]:
		fire_missile1()
	elif self.type_attack == 1:
		fire_missile2()
	if self.type_attack == 0:
		self.inflicted += self.damage
	if self.type_attack == 1:
		for i in enemy_array:
			i.on_hit(self.damage, self.type, self.type_explosion, self.type_attack, self.current_lvl)
	else:
		enemy.on_hit(self.damage, self.type, self.type_explosion, self.type_attack, self.current_lvl)
	await get_tree().create_timer(self.rof).timeout
	is_ready = true


func fire_missile1():
	get_node("AnimationPlayer").play("Fire")

func fire_missile2():
	var new_impact = preload("res://Scenes/SupportScenes/ProjecttileImpact_2.tscn").instantiate()
	new_impact.scale.x = self.range / 50
	new_impact.scale.y = self.range / 50
	new_impact.speed_scale = 60.0 / self.duration
	self.add_child(new_impact)

func _on_range_body_entered(body):
	enemy_array.append(body.get_parent())
	
func _on_Range_body_exited(body): 
	enemy_array.erase(body.get_parent())
	
##
## Меню башни
##
func _on_menu_button_pressed():
	for i in self.get_parent().get_children():
		i.get_node("MenuButton").hide()
	if GameData.current_money >= GameData.tower_data[self.type]["upgrade for"][self.current_lvl]:
		self.get_node("Menu/V/HButton/Up").disabled = false
	if self.type_attack == 0:
		self.get_node("Menu/V/HInflicted/HValue/Value").text = str(self.inflicted)

	GameData.list_open_menu_turrets.append(self.get_node("Menu"))
	"""Справо снизу"""
	if get_parent().get_parent().get_parent().get_node("UI/HUD").size[0] - self.position[0] < 400 and get_parent().get_parent().get_parent().get_node("UI/HUD").size[1] - self.position[1] < 300:
		"""Справо снизу"""
		get_node("Menu").position[0] = -300
		get_node("Menu").position[1] = -330
	elif get_parent().get_parent().get_parent().get_node("UI/HUD").size[0] - self.position[0] < 400 and self.position[1] < 150:
		"""Справо сверху"""
		get_node("Menu").position[0] = -300
		get_node("Menu").position[1] = 50
	elif get_parent().get_parent().get_parent().get_node("UI/HUD").size[0] - self.position[0] < 400:
		"""Снизу"""
		get_node("Menu").position[0] = -300
	elif get_parent().get_parent().get_parent().get_node("UI/HUD").size[1] - self.position[1] < 300:
		"""Справо"""
		get_node("Menu").position[1] = -330
	elif self.position[1] < 150:
		"""Сверху"""
		get_node("Menu").position[1] = 50
	else:
		"""По умолчанию"""
		get_node("Menu").position[0] = 50
		get_node("Menu").position[1] = -200
	self.get_node("Menu").show()
	
func hide_menu():
	for i in self.get_parent().get_children():
		i.get_node("MenuButton").show()
	while len(GameData.list_open_menu_turrets) > 0:
		GameData.list_open_menu_turrets[0].hide()
		GameData.list_open_menu_turrets.pop_at(0)

func upgrade():
	if self.current_lvl < self.max_lvl:
		if GameData.current_money >= GameData.tower_data[self.type]["upgrade for"][self.current_lvl]:
			GameData.current_money -= GameData.tower_data[self.type]["upgrade for"][self.current_lvl]
			get_parent().get_parent().get_parent().base_money()
			emit_signal("base_money") 
			self.current_lvl += 1
			if self.type_attack == 0:
				self.damage = GameData.tower_data[self.type]["damage"][self.current_lvl]
			elif self.type_attack == 1:
				self.intensivity = GameData.tower_data[self.type]["intensivity"][self.current_lvl]
				self.duration = GameData.tower_data[self.type]["duration"][self.current_lvl]
			else:
				self.duration = GameData.tower_data[self.type]["distance"][self.current_lvl]
			self.rof = GameData.tower_data[self.type]["rof"][self.current_lvl]
			self.range = GameData.tower_data[self.type]["range"][self.current_lvl]
			update_menu()
			if self.current_lvl + 1 < self.max_lvl:
				update_menu_upgrade()
		else:
			self.get_node("Menu/V/HButton/Up").disabled = true
	else:
		self.get_node("Menu/V/HButton/Up").disabled = true
		self.get_node("Menu/V/HButton/Up/TextureRect").visible = false
		self.get_node("Menu/V/HButton/Up/LabelValue").visible = false
		self.get_node("Menu/V/HButton/Up/LabelBut").text = tr("KEY_LVL_MAX")
		
func update_menu():
	if self.type_attack == 0:
		self.get_node("Menu/V/HDamage/HValue/Value").text = str(GameData.tower_data[self.type]["damage"][self.current_lvl])
		self.get_node("Menu/V/HReload/HValue/Value").text = str(GameData.tower_data[self.type]["rof"][self.current_lvl])
		self.get_node("Menu/V/HRange/HValue/Value").text = str(GameData.tower_data[self.type]["range"][self.current_lvl])
	elif self.type_attack == 1:
		self.get_node("Menu/V/HDamage/HValue/Value").text = str(GameData.tower_data[self.type]["intensivity"][self.current_lvl] * 100)
		self.get_node("Menu/V/HReload/HValue/Value").text = str(GameData.tower_data[self.type]["duration"][self.current_lvl])
		self.get_node("Menu/V/HRange/HValue/Value").text = str(GameData.tower_data[self.type]["rof"][self.current_lvl])
		self.get_node("Menu/V/HInflicted/HValue/Value").text = str(GameData.tower_data[self.type]["range"][self.current_lvl])
	else:
		self.get_node("Menu/V/HDamage/HValue/Value").text = str(GameData.tower_data[self.type]["distance"][self.current_lvl])
		self.get_node("Menu/V/HReload/HValue/Value").text = str(GameData.tower_data[self.type]["rof"][self.current_lvl])
		self.get_node("Menu/V/HRange/HValue/Value").text = str(GameData.tower_data[self.type]["range"][self.current_lvl])

	self.get_node("Menu/V/NameAndLvl/Lvl").text = tr("KEY_LVL") + " " + str(self.current_lvl + 1) + "/" + str(self.max_lvl + 1)
	
func update_menu_upgrade():
	if self.type_attack == 0:
		self.get_node("Menu/V/HDamage/HValue/Up").text = "+" + str(GameData.tower_data[self.type]["damage"][self.current_lvl + 1] - GameData.tower_data[self.type]["damage"][self.current_lvl])
		self.get_node("Menu/V/HReload/HValue/Up").text = str(GameData.tower_data[self.type]["rof"][self.current_lvl + 1] - GameData.tower_data[self.type]["rof"][self.current_lvl])
		self.get_node("Menu/V/HRange/HValue/Up").text = "+" + str(GameData.tower_data[self.type]["range"][self.current_lvl + 1] - GameData.tower_data[self.type]["range"][self.current_lvl])
	elif self.type_attack == 1:
		self.get_node("Menu/V/HDamage/HValue/Up").text = "+" + str(GameData.tower_data[self.type]["intensivity"][self.current_lvl + 1] - GameData.tower_data[self.type]["intensivity"][self.current_lvl])
		self.get_node("Menu/V/HReload/HValue/Up").text = str(GameData.tower_data[self.type]["duration"][self.current_lvl + 1] - GameData.tower_data[self.type]["duration"][self.current_lvl])
		self.get_node("Menu/V/HRange/HValue/Up").text = "+" + str(GameData.tower_data[self.type]["rof"][self.current_lvl + 1] - GameData.tower_data[self.type]["rof"][self.current_lvl + 1])
#		self.get_node("Menu/V/HInflicted/HValue/Up").text = str(GameData.tower_data[self.type]["range"][self.current_lvl] - GameData.tower_data[self.type]["range"][self.current_lvl])
	else:
		self.get_node("Menu/V/HDamage/HValue/Up").text = "+" + str(GameData.tower_data[self.type]["distance"][self.current_lvl + 1] - GameData.tower_data[self.type]["distance"][self.current_lvl])
		self.get_node("Menu/V/HReload/HValue/Up").text = str(GameData.tower_data[self.type]["rof"][self.current_lvl + 1] - GameData.tower_data[self.type]["rof"][self.current_lvl])
		self.get_node("Menu/V/HRange/HValue/Up").text = "+" + str(GameData.tower_data[self.type]["range"][self.current_lvl + 1] - GameData.tower_data[self.type]["range"][self.current_lvl])
	self.get_node("Menu/V/HButton/Up/LabelValue").text = str(GameData.tower_data[self.type]["upgrade for"][self.current_lvl])
