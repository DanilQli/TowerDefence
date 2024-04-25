extends Node

func read(name):
	var txt = []
	var file = FileAccess.open("res://Files/" + name + ".dat", FileAccess.READ)
	var lines = file.get_as_text()
	lines = lines.split("\r")
	for i in lines:
		txt.append(i.split(","))
	file.close()
	while len(txt[len(txt) - 1]) == 1:
		txt.remove_at(len(txt) - 1)
	return txt
	
func write(name, data):
	var file = FileAccess.open("res://Files/" + name + ".dat", FileAccess.WRITE)
	for i in data:
		var txt = i[0]
		for j in range(1, len(i)):
			txt += "," + i[j]
		file.store_string(txt + "\r")
	file.close()
