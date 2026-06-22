extends Node2D

const PLAYER_SCENE := preload("res://player/Player.tscn")
const WASTE_ITEM_SCENE := preload("res://items/WasteItem.tscn")
const RECYCLE_BIN_SCENE := preload("res://items/RecycleBin.tscn")
const TREE_TEXTURE := preload("res://textures/environment/tree.png")
const BUILDING_FLOOR := preload("res://textures/tilesets/building_floor.png")
const _Sprites := preload("res://scripts/sprites.gd")
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
	Vector2(68, 130),    # esquerda do prédio 1
	Vector2(290, 55),    # acima do prédio 1
	Vector2(1160, 50),   # acima do prédio 2
	Vector2(1450, 200),  # direita do prédio 2
	Vector2(1370, 760),  # direita do prédio 3
	Vector2(90, 740),    # esquerda do prédio 4
	Vector2(290, 895),   # abaixo do prédio 4
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
		recycle_bin.display_color = bin["color"]
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
	# Tiled grass ground
	draw_texture_rect(_Sprites.grass_tile(), Rect2(Vector2.ZERO, WORLD_SIZE), true)

	# Horizontal road (tiled dirt)
	draw_texture_rect(_Sprites.dirt_tile(), Rect2(Vector2(0, 400), Vector2(WORLD_SIZE.x, 150)), true)
	# Vertical road (tiled dirt)
	draw_texture_rect(_Sprites.dirt_tile(), Rect2(Vector2(690, 0), Vector2(170, WORLD_SIZE.y)), true)

	# Road borders
	draw_rect(Rect2(Vector2(0, 396), Vector2(WORLD_SIZE.x, 5)), Color("#907020"))
	draw_rect(Rect2(Vector2(0, 549), Vector2(WORLD_SIZE.x, 5)), Color("#907020"))
	draw_rect(Rect2(Vector2(686, 0), Vector2(5, WORLD_SIZE.y)), Color("#907020"))
	draw_rect(Rect2(Vector2(859, 0), Vector2(5, WORLD_SIZE.y)), Color("#907020"))

	# Road center dashes
	var dash := 36.0
	var gap := 18.0
	var cx := 0.0
	while cx < WORLD_SIZE.x:
		if not (cx > 670.0 and cx < 880.0):
			draw_rect(Rect2(cx, 471.0, dash, 5.0), Color("#d4b03a", 0.65))
		cx += dash + gap
	var cy := 0.0
	while cy < WORLD_SIZE.y:
		if not (cy > 380.0 and cy < 570.0):
			draw_rect(Rect2(771.0, cy, 5.0, dash), Color("#d4b03a", 0.65))
		cy += dash + gap

	# Buildings
	_draw_building(building_rects[0], Color("#e8c88a"), Color("#c8a860"))
	_draw_building(building_rects[1], Color("#c4dcf0"), Color("#9abce0"))
	_draw_building(building_rects[2], Color("#f0d068"), Color("#d0b048"))
	_draw_building(building_rects[3], Color("#b4d890"), Color("#8ab868"))


func _draw_building(rect: Rect2, wall: Color, roof: Color) -> void:
	# Wood floor tiled, tinted with the building's wall color
	draw_texture_rect(BUILDING_FLOOR, rect, true, wall)
	# Roof strip
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 14)), roof)
	# Left highlight strip
	draw_rect(Rect2(rect.position + Vector2(0, 14), Vector2(6, rect.size.y - 14)), wall.lightened(0.18))
	# Outline (pixel-crisp: 4 filled rects instead of unfilled rect with width)
	draw_rect(Rect2(rect.position,                               Vector2(rect.size.x, 3)),     Color("#6a5030"))
	draw_rect(Rect2(rect.position + Vector2(0, rect.size.y - 3),Vector2(rect.size.x, 3)),     Color("#6a5030"))
	draw_rect(Rect2(rect.position,                               Vector2(3, rect.size.y)),     Color("#6a5030"))
	draw_rect(Rect2(rect.position + Vector2(rect.size.x - 3, 0),Vector2(3, rect.size.y)),     Color("#6a5030"))

	# Two windows (pixel-crisp: draw_rect instead of draw_line for cross-bars)
	for wi in range(2):
		var wx := int(rect.position.x + rect.size.x * (0.18 + wi * 0.46))
		var wy := int(rect.position.y + 22.0)
		draw_rect(Rect2(wx, wy, 30, 24), Color("#80c4e0"))
		draw_rect(Rect2(wx,      wy,      30, 2),  Color("#6a5030"))
		draw_rect(Rect2(wx,      wy + 22, 30, 2),  Color("#6a5030"))
		draw_rect(Rect2(wx,      wy,       2, 24), Color("#6a5030"))
		draw_rect(Rect2(wx + 28, wy,       2, 24), Color("#6a5030"))
		draw_rect(Rect2(wx + 14, wy,       2, 24), Color("#6a5030"))
		draw_rect(Rect2(wx,      wy + 11, 30,  2), Color("#6a5030"))

	# Door (pixel-crisp outline)
	var dx := int(rect.position.x + rect.size.x * 0.44)
	var dy := int(rect.position.y + rect.size.y - 52.0)
	draw_rect(Rect2(dx, dy, 26, 52), Color("#8a5a28"))
	draw_rect(Rect2(dx,      dy,      26, 2),  Color("#6a5030"))
	draw_rect(Rect2(dx,      dy + 50, 26, 2),  Color("#6a5030"))
	draw_rect(Rect2(dx,      dy,       2, 52), Color("#6a5030"))
	draw_rect(Rect2(dx + 24, dy,       2, 52), Color("#6a5030"))
	draw_rect(Rect2(dx + 18, dy + 28,  4,  4), Color("#c8a030"))


func _draw_trees() -> void:
	for tree_pos in tree_positions:
		draw_texture_rect_region(
			TREE_TEXTURE,
			Rect2(tree_pos + Vector2(-64, -80), Vector2(128, 96)),
			Rect2(0, 0, 64, 48)
		)
