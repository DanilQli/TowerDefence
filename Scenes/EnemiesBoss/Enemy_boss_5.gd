extends Enemy_boss
class_name Enemy_boss_5

const rof: int = 2
@onready var anim = $AnimationPlayer2

func fire() -> void:
	is_ready = false
	if hp < base_hp:
		if hp + int(base_hp / 20) < base_hp:
			hp += int(base_hp / 20)
		else:
			hp = base_hp
		health_bar.value = hp
		anim.play("sprite")
	await get_tree().create_timer(rof).timeout
	is_ready = true
