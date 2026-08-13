extends Node
## Autoload de save do EcoCat (user://).
## Economia UNICA compartilhada: uma carteira de moedas para todas as cidades.
## Cada cidade guarda seu proprio nivel de automacao (que gera renda passiva
## depois de concluida). Bolsa e calcado do gato persistem entre cidades.

const SAVE_PATH := "user://ecocat_save.json"
const SAVE_FILE := "ecocat_save.json"
const CITY_COUNT := 6

var should_load_save := false


func default_state() -> Dictionary:
	var cities: Array = []
	for i in CITY_COUNT:
		cities.append({"completed": false, "collector": 0, "conveyor": 0, "sorter": 0})
	return {
		"coins": 0,          # carteira unica compartilhada
		"current_city": 0,   # cidade atual (0..5)
		"phase": 0,          # fase/bairro dentro da cidade (0..5)
		# Progresso da cidade atual (reinicia do zero em cada cidade nova):
		"bag": 1,
		"shoe": 0,
		"collector": 0,
		"conveyor": 0,
		"sorter": 0,
		# Estado final de cada cidade concluida (gera renda passiva):
		"cities": cities,
	}


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_state(state: Dictionary) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("EcoCat: nao foi possivel gravar o save.")
		return
	file.store_string(JSON.stringify(state))
	file.close()


func load_state() -> Dictionary:
	var data := default_state()
	if not has_save():
		return data

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return data

	var raw := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		return data

	data["coins"] = int(parsed.get("coins", 0))
	data["current_city"] = int(parsed.get("current_city", 0))
	data["phase"] = int(parsed.get("phase", 0))
	data["bag"] = int(parsed.get("bag", 1))
	data["shoe"] = int(parsed.get("shoe", 0))
	data["collector"] = int(parsed.get("collector", 0))
	data["conveyor"] = int(parsed.get("conveyor", 0))
	data["sorter"] = int(parsed.get("sorter", 0))

	var cities: Variant = parsed.get("cities", null)
	if typeof(cities) == TYPE_ARRAY:
		for i in mini((cities as Array).size(), CITY_COUNT):
			var c: Variant = cities[i]
			if typeof(c) == TYPE_DICTIONARY:
				data["cities"][i] = {
					"completed": bool(c.get("completed", false)),
					"collector": int(c.get("collector", 0)),
					"conveyor": int(c.get("conveyor", 0)),
					"sorter": int(c.get("sorter", 0)),
				}

	return data


func clear_save() -> void:
	var dir := DirAccess.open("user://")
	if dir != null and dir.file_exists(SAVE_FILE):
		dir.remove(SAVE_FILE)
	should_load_save = false
