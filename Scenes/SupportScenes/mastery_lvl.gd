extends Panel

func setup(number: int) -> void:
	get_node("VBoxContainer/Label").text = tr("KEY_LVL") + str(number + 1)
	get_node("VBoxContainer/Label2").text = str(GameConstants.CARDS_MASTERY_NEED_XP_LVL[number]) + " XP"
	get_node("VBoxContainer/Label3").text = tr("KEY_MASTERY_LVL_" + str(number + 1))
