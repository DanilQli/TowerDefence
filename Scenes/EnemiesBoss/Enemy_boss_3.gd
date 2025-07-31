extends Enemy_boss
class_name Enemy_boss_3
const SPEED_MODIFER: float = 1.2

func _ready() -> void:
	ResourceManager.speed_modifer = SPEED_MODIFER
	super._ready()

func on_destroy() -> void:
	ResourceManager.speed_modifer = 1
	super.on_destroy()
