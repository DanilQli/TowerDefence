extends Control

func _ready():
	$Panel/VBoxContainer/BtnCampaign.pressed.connect(_on_mode_selected.bind(1))
	$Panel/VBoxContainer/BtnSandbox.pressed.connect(_on_mode_selected.bind(2))
	$Panel/VBoxContainer/BtnPvP.pressed.connect(_on_mode_selected.bind(3))
	$Panel/BtnClose.pressed.connect(queue_free)

func _on_mode_selected(index):
	# Сохраняем выбранный режим в глобальную переменную (добавь в GameSession!)
	GameSession.selected_mode = index
	
	# Обновляем текст кнопки в меню и закрываемся
	var main_menu = find_parent("MenuMobile")
	if main_menu:
		main_menu.update_mode_button(index)
	
	queue_free()
