extends Node2D

const PLAYER_SCENE := preload("res://player/Player.tscn")
const WASTE_ITEM_SCENE := preload("res://items/WasteItem.tscn")
const RECYCLE_BIN_SCENE := preload("res://items/RecycleBin.tscn")
const WORLD_SIZE := Vector2(1600, 1000)
const COLLISION_LAYER_WORLD := 1
const CORRECT_DISCARD_COINS := 10
const CORRECT_DISCARD_SUSTAINABILITY := 5
const WRONG_DISCARD_SUSTAINABILITY_LOSS := 2

var player: CharacterBody2D
var current_waste_type := ""
var current_waste_name := "nenhum"
var coins := 0
var sustainability := 0
var stats_label: Label
var feedback_label: Label

var building_rects: Array[Rect2] = [
	Rect2(Vector2(80, 90), Vector2(420, 210)),
	Rect2(Vector2(980, 90), Vector2(430, 220)),
	Rect2(Vector2(980, 690), Vector2(360, 170)),
	Rect2(Vector2(140, 660), Vector2(340, 180)),
]

var tree_positions: Array[Vector2] = [
	Vector2(180, 160),
	Vector2(310, 220),
	Vector2(1240, 180),
	Vector2(1380, 280),
	Vector2(260, 760),
	Vector2(1180, 780),
	Vector2(1420, 840),
]

var waste_positions: Array[Dictionary] = [
	{"position": Vector2(420, 360), "type": "plastic", "name": "plastico", "color": Color("#5ec4ff")},
	{"position": Vector2(930, 330), "type": "paper", "name": "papel", "color": Color("#f2d16b")},
	{"position": Vector2(510, 610), "type": "glass", "name": "vidro", "color": Color("#8ad879")},
	{"position": Vector2(1060, 610), "type": "metal", "name": "metal", "color": Color("#c8c8c8")},
	{"position": Vector2(820, 760), "type": "organic", "name": "organico", "color": Color("#b8875f")},
]

var bin_data: Array[Dictionary] = [
	{"position": Vector2(250, 450), "type": "plastic", "name": "plastico", "color": Color("#5ec4ff")},
	{"position": Vector2(330, 450), "type": "paper", "name": "papel", "color": Color("#f2d16b")},
	{"position": Vector2(410, 450), "type": "glass", "name": "vidro", "color": Color("#8ad879")},
	{"position": Vector2(490, 450), "type": "metal", "name": "metal", "color": Color("#c8c8c8")},
	{"position": Vector2(570, 450), "type": "organic", "name": "organico", "color": Color("#b8875f")},
]


func _ready() -> void:
	_ensure_input_actions()
	_create_world_collisions()
	_spawn_recycle_bins()
	_spawn_waste_items()
	_spawn_player()
	_create_hud()
	_update_hud()
	queue_redraw()


func _draw() -> void:
	_draw_map()
	_draw_trees()
	_draw_recycle_bins()


func _ensure_input_actions() -> void:
	var actions := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
	}

	for action_name in actions:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)

		for keycode in actions[action_name]:
			var event := InputEventKey.new()
			event.physical_keycode = keycode
			InputMap.action_add_event(action_name, event)


func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	player.position = Vector2(760, 520)
	add_child(player)


func _spawn_waste_items() -> void:
	var waste_root := Node2D.new()
	waste_root.name = "WasteItems"
	add_child(waste_root)

	for waste_data in waste_positions:
		var waste_item := WASTE_ITEM_SCENE.instantiate()
		waste_item.position = waste_data["position"]
		waste_item.waste_type = waste_data["type"]
		waste_item.display_name = waste_data["name"]
		waste_item.display_color = waste_data["color"]
		waste_item.picked_up.connect(_on_waste_item_picked_up)
		waste_root.add_child(waste_item)


func _spawn_recycle_bins() -> void:
	var bin_root := Node2D.new()
	bin_root.name = "RecycleBins"
	add_child(bin_root)

	for bin in bin_data:
		var recycle_bin := RECYCLE_BIN_SCENE.instantiate()
		recycle_bin.position = bin["position"]
		recycle_bin.bin_type = bin["type"]
		recycle_bin.display_name = bin["name"]
		recycle_bin.discard_requested.connect(_on_discard_requested)
		bin_root.add_child(recycle_bin)


func _create_world_collisions() -> void:
	var collision_root := Node2D.new()
	collision_root.name = "WorldCollisions"
	add_child(collision_root)

	for rect in building_rects:
		_add_rect_collision(collision_root, rect, "BuildingCollision")

	for tree_position in tree_positions:
		_add_circle_collision(collision_root, tree_position + Vector2(0, 16), 16.0, "TreeCollision")

	for bin in bin_data:
		var bin_position: Vector2 = bin["position"]
		_add_rect_collision(collision_root, Rect2(bin_position, Vector2(38, 48)), "RecycleBinCollision")


func _add_rect_collision(parent: Node, rect: Rect2, body_name: String) -> void:
	var body := StaticBody2D.new()
	body.name = body_name
	body.collision_layer = COLLISION_LAYER_WORLD
	body.collision_mask = 0
	body.position = rect.position + rect.size * 0.5
	parent.add_child(body)

	var shape := CollisionShape2D.new()
	var rectangle_shape := RectangleShape2D.new()
	rectangle_shape.size = rect.size
	shape.shape = rectangle_shape
	body.add_child(shape)


func _add_circle_collision(parent: Node, center: Vector2, radius: float, body_name: String) -> void:
	var body := StaticBody2D.new()
	body.name = body_name
	body.collision_layer = COLLISION_LAYER_WORLD
	body.collision_mask = 0
	body.position = center
	parent.add_child(body)

	var shape := CollisionShape2D.new()
	var circle_shape := CircleShape2D.new()
	circle_shape.radius = radius
	shape.shape = circle_shape
	body.add_child(shape)


func _create_hud() -> void:
	var canvas_layer := CanvasLayer.new()
	add_child(canvas_layer)

	var label := Label.new()
	label.text = "EcoCat - prototipo local | Mover: WASD ou setas | Objetivo: coletar e separar residuos"
	label.position = Vector2(24, 20)
	label.add_theme_color_override("font_color", Color("#203021"))
	label.add_theme_font_size_override("font_size", 22)
	canvas_layer.add_child(label)

	stats_label = Label.new()
	stats_label.position = Vector2(24, 52)
	stats_label.add_theme_color_override("font_color", Color("#3c513a"))
	stats_label.add_theme_font_size_override("font_size", 18)
	canvas_layer.add_child(stats_label)

	feedback_label = Label.new()
	feedback_label.text = "Encoste em um residuo colorido para coletar."
	feedback_label.position = Vector2(24, 82)
	feedback_label.add_theme_color_override("font_color", Color("#5d6f4f"))
	feedback_label.add_theme_font_size_override("font_size", 16)
	canvas_layer.add_child(feedback_label)


func _update_hud() -> void:
	if stats_label == null:
		return

	stats_label.text = "Moedas: %d    Item atual: %s    Sustentabilidade: %d%%" % [
		coins,
		current_waste_name,
		sustainability,
	]


func _on_waste_item_picked_up(waste_item: Node) -> void:
	if current_waste_type != "":
		feedback_label.text = "Inventario cheio: descarte o item atual antes de coletar outro."
		return

	current_waste_type = waste_item.get("waste_type")
	current_waste_name = waste_item.get("display_name")
	feedback_label.text = "Coletado: %s. Agora leve ate a lixeira correta." % current_waste_name
	waste_item.queue_free()
	_update_hud()


func _on_discard_requested(recycle_bin: Node) -> void:
	if current_waste_type == "":
		feedback_label.text = "Colete um residuo antes de usar a lixeira de %s." % recycle_bin.get("display_name")
		return

	var bin_type: String = recycle_bin.get("bin_type")
	var bin_name: String = recycle_bin.get("display_name")

	if current_waste_type == bin_type:
		coins += CORRECT_DISCARD_COINS
		sustainability = mini(100, sustainability + CORRECT_DISCARD_SUSTAINABILITY)
		feedback_label.text = "Correto! %s foi descartado na lixeira de %s. +%d moedas" % [
			current_waste_name,
			bin_name,
			CORRECT_DISCARD_COINS,
		]
		current_waste_type = ""
		current_waste_name = "nenhum"
	else:
		sustainability = maxi(0, sustainability - WRONG_DISCARD_SUSTAINABILITY_LOSS)
		feedback_label.text = "Ops: %s nao vai na lixeira de %s. Tente outra lixeira." % [
			current_waste_name,
			bin_name,
		]

	_update_hud()


func _draw_map() -> void:
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("#a8d977"))
	draw_rect(Rect2(Vector2(0, 400), Vector2(WORLD_SIZE.x, 150)), Color("#8b8b7a"))
	draw_rect(Rect2(Vector2(690, 0), Vector2(170, WORLD_SIZE.y)), Color("#8b8b7a"))
	draw_rect(Rect2(Vector2(0, 380), Vector2(WORLD_SIZE.x, 20)), Color("#d8c89a"))
	draw_rect(Rect2(Vector2(0, 550), Vector2(WORLD_SIZE.x, 20)), Color("#d8c89a"))
	draw_rect(Rect2(Vector2(670, 0), Vector2(20, WORLD_SIZE.y)), Color("#d8c89a"))
	draw_rect(Rect2(Vector2(860, 0), Vector2(20, WORLD_SIZE.y)), Color("#d8c89a"))
	draw_rect(building_rects[0], Color("#e7cf9c"))
	draw_rect(building_rects[1], Color("#cfe5f4"))
	draw_rect(building_rects[2], Color("#f1d58f"))
	draw_rect(building_rects[3], Color("#b9d8a8"))

	for rect in building_rects:
		draw_rect(rect, Color("#8a7b5f"), false, 4.0)


func _draw_trees() -> void:
	for tree_position in tree_positions:
		draw_rect(Rect2(tree_position + Vector2(-6, 12), Vector2(12, 24)), Color("#8a613f"))
		draw_circle(tree_position, 28, Color("#4e9c58"))
		draw_circle(tree_position + Vector2(-14, 10), 20, Color("#65b96a"))
		draw_circle(tree_position + Vector2(16, 8), 20, Color("#73c477"))


func _draw_recycle_bins() -> void:
	for bin in bin_data:
		var position: Vector2 = bin["position"]
		var color: Color = bin["color"]
		draw_rect(Rect2(position, Vector2(38, 48)), Color("#31413a"))
		draw_rect(Rect2(position + Vector2(4, 8), Vector2(30, 34)), color)
		draw_rect(Rect2(position + Vector2(-2, 0), Vector2(42, 8)), Color("#26342e"))
