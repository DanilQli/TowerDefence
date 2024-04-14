extends Node

func read(file_name):
	var file = FileAccess.open("res://Files/" + file_name + ".dat", FileAccess.READ)
	var dict = []
	while !file.eof_reached():
		dict.append(file.get_csv_line())
	file.close()
	return dict
	
func write(file_name, dict):
	var file = FileAccess.open("res://Files/" + file_name + ".dat", FileAccess.WRITE)
	for i in dict:
		file.store_csv_line(i)
	file.close()
