extends Enemy_boss
class_name Enemy_boss_11

var list_children = []

func _ready() -> void:
	super._ready()
	await get_tree().create_timer(0.45).timeout
	for i in range(1, 4):
		var enemy = load("res://Scenes/EnemiesBoss/Enemy_boss_11_1.tscn").instantiate()
		enemy.get_node("Sprite2D").texture = load("res://Assets/Props/enemy_11_" + str(i) + ".png")
		enemy.names = self.names
		enemy.id = self.id
		enemy.hp = self.hp / 2
		enemy.current_speed = self.current_speed
		enemy.speed = self.current_speed
		enemy.duration_speed_mod = 0
		enemy.base_damage.connect(get_tree().current_scene.on_base_damage)
		enemy.parent = self
		enemy.ind = i - 1
		var num_paths = get_tree().current_scene.map_node.get_node("Path").get_child_count()
		var path_index = randi_range(0, num_paths - 1)
		get_tree().current_scene.map_node.get_node("Path").get_child(path_index).add_child(enemy, true)
		list_children.append(enemy)
		await get_tree().create_timer(0.15).timeout
		
func fire() -> void:
	is_ready = false
	for i in range(len(list_children)):
		if list_children[i] is Enemy_boss_11_1:
			list_children[i].hp += float((list_children[i].hp / 100.0) * 3)
			list_children[i].health_bar.value = list_children[i].hp
			list_children[i].get_node("AnimationPlayer2").play("sprite")
	await get_tree().create_timer(3).timeout
	is_ready = true
