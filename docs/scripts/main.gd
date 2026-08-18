extends Node2D

const PLAYER_SCENE := preload("res://player/Player.tscn")
const WASTE_ITEM_SCENE := preload("res://items/WasteItem.tscn")
const RECYCLE_BIN_SCENE := preload("res://items/RecycleBin.tscn")
const MACHINE_SCRIPT := preload("res://items/machine.gd")
const TREE_TEXTURE := preload("res://textures/environment/tree.png")
const BUILDING_FLOOR := preload("res://textures/tilesets/building_floor.png")
const _Sprites := preload("res://scripts/sprites.gd")

const WORLD_SIZE := Vector2(1600, 1000)
# Quanto a grama passa das bordas do mapa (cobre qualquer proporcao de tela).
const GROUND_MARGIN := 4000.0
const COLLISION_LAYER_WORLD := 1
const BASE_DISCARD_COINS := 10
const CORRECT_DISCARD_SUSTAINABILITY := 4
const WRONG_DISCARD_SUSTAINABILITY_LOSS := 2
const BASE_SPEED := 190.0

const MAX_BAG := 6
const MAX_SHOE := 6
const MAX_AUTO := 4
const AUTO_UNLOCK_PHASE := 2  # automacao/startup passa a ser vendida na Fase 3

# Cada CIDADE tem as 6 fases (bairros). Zerar as 6 = fundar a startup daquela
# cidade -> abre o minimapa para escolher outra cidade e recomecar do zero.
const CITY_NAMES := ["Recicleia", "Verdemar", "Ecovale", "Sustentopolis", "Bosque Real", "Nova Folha"]

# Renda passiva das cidades ja concluidas (economia unica compartilhada).
const PASSIVE_BASE := 0.4            # moedas/seg por cidade concluida
const PASSIVE_PER_LEVEL := 0.25      # moedas/seg por nivel de automacao deixado

# Sede da Startup e lixeiras ficam sempre no centro.
const HQ_RECT := Rect2(690, 292, 220, 118)
const BIN_POSITIONS := [
	Vector2(560, 470), Vector2(640, 470), Vector2(720, 470),
	Vector2(800, 470), Vector2(880, 470), Vector2(960, 470),
]
const SACOLA_POS := Vector2(800, 660)
const PLAYER_START := Vector2(800, 840)
const PLAZA_KEEPOUT := Rect2(520, 280, 560, 440)

# --- Estado de jogo ------------------------------------------------------- #
var player: CharacterBody2D
var _inventory: Array = []
var coins := 0
var sustainability := 0
var phase_index := 0
var _combo := 0

# Economia / startup (economia unica compartilhada)
var _bag := 1
var _shoe := 0
var _collector := 0
var _conveyor := 0
var _sorter := 0
var _startup_announced := false

# Cidades e renda passiva
var _city_index := 0        # cidade atual (0..5)
var _cities: Array = []     # estado final de cada cidade (para renda passiva)
var _passive_accum := 0.0
var _passive_save_cd := 0.0
var _between_cities := false
var _minimap_open := false

var _total_items := 0
var _correct_discards := 0
var _phase_complete := false
var _shop_open := false
var _paused := false
var _guide_open := false

# --- Sacola / esteira ----------------------------------------------------- #
var _sacola: Array = []
var _belt_items: Array = []
var _belt_timer := 0.0
var _bin_pos_by_type: Dictionary = {}

# --- Layout da fase ------------------------------------------------------- #
var _phase_name := ""
var _theme := {}
var _building_defs: Array = []
var _tree_positions: Array = []
var _waste_positions: Array = []
var _bin_data: Array = []
var _collector_node: Node = null

var _phases: Array = []

const TIPS := [
	"Vidro pode ser reciclado infinitas vezes sem perder qualidade.",
	"Reciclar aluminio economiza ate 95% da energia de produzir do zero.",
	"Papel engordurado ou molhado vira rejeito: nao e reciclavel.",
	"Separar o lixo certo e o primeiro passo da economia circular.",
	"Pilhas e eletronicos (e-lixo) exigem descarte especial.",
	"Reciclar plastico ajuda a reduzir a poluicao dos oceanos.",
]

# --- HUD ------------------------------------------------------------------ #
var _hud_layer: CanvasLayer
var _phase_label: Label
var _coins_label: Label
var _passive_label: Label
var _progress_label: Label
var _bag_label: Label
var _combo_label: Label
var _sustain_bar: ProgressBar
var feedback_label: Label
var _sacola_label: Label
var _fade_rect: ColorRect
var _banner_root: Control
var _banner_panel: PanelContainer
var _banner_title: Label
var _banner_sub: Label
var _banner_tip: Label
var _confetti: CPUParticles2D

# --- Loja / Pausa / Guia -------------------------------------------------- #
var _shop_layer: CanvasLayer
var _shop_coins_label: Label
var _shop_rows: Dictionary = {}
var _pause_layer: CanvasLayer
var _guide_layer: CanvasLayer
var _mute_button: Button
const MAP_VIEW_SCRIPT := preload("res://ui/map_view.gd")
const TOUCH_CONTROLS_SCRIPT := preload("res://ui/touch_controls.gd")
var _minimap_layer: CanvasLayer
var _minimap_coins_label: Label
var _map_view                      # instancia de ui/map_view.gd (dinamico)
var _minimap_footer: Label
var _minimap_close_button: Button

# --- Controles de toque (so existem quando o jogo abre num aparelho de toque) - #
var _touch_layer: CanvasLayer
var _touch_controls                # instancia de ui/touch_controls.gd (dinamico)
var _hint_label: Label


func _ready() -> void:
	_ensure_input_actions()
	_phases = _build_phases()
	_apply_saved_state()
	_create_hud()
	_create_touch_controls()
	_create_shop()
	_create_pause_menu()
	_create_guide()
	_create_minimap()
	_create_sacola_area()
	_setup_phase()
	Audio.start_music()
	_fade_in()


func _process(delta: float) -> void:
	_accrue_passive(delta)
	if _touch_controls != null and is_instance_valid(player):
		player.touch_direction = _touch_controls.direction
	if _phase_complete or _shop_open or _paused or _guide_open or _minimap_open:
		return
	_process_belt(delta)


# --------------------------------------------------------------------------- #
# Renda passiva (cidades ja concluidas rendem na carteira compartilhada)
# --------------------------------------------------------------------------- #

func _passive_rate() -> float:
	var rate := 0.0
	for c in _cities:
		if c["completed"]:
			rate += PASSIVE_BASE + PASSIVE_PER_LEVEL * float(int(c["collector"]) + int(c["conveyor"]) + int(c["sorter"]))
	return rate


func _accrue_passive(delta: float) -> void:
	var rate := _passive_rate()
	if rate <= 0.0:
		return
	_passive_accum += rate * delta
	if _passive_accum >= 1.0:
		var add := int(_passive_accum)
		_passive_accum -= float(add)
		coins += add
		_update_hud()
	_passive_save_cd -= delta
	if _passive_save_cd <= 0.0:
		_passive_save_cd = 2.5
		_save()


# --------------------------------------------------------------------------- #
# Fases (temas)
# --------------------------------------------------------------------------- #

func _build_phases() -> Array:
	var brown := {"wall": Color("#d9b98a"), "roof": Color("#8a6a3a")}
	var red := {"wall": Color("#c85a4a"), "roof": Color("#7a2f28")}
	var cream := {"wall": Color("#e8d0a0"), "roof": Color("#b08a4a")}
	var gray := {"wall": Color("#cfc4b4"), "roof": Color("#8a7a68")}
	var pastel_a := {"wall": Color("#d8c4e8"), "roof": Color("#9a7ac0")}
	var pastel_b := {"wall": Color("#c4dcf0"), "roof": Color("#7aa8d8")}
	var mansion := {"wall": Color("#efe6c8"), "roof": Color("#c0982e")}
	var tower := {"wall": Color("#b8c6d4"), "roof": Color("#5f7080")}

	return [
		{
			"name": "Campo", "theme": {"grass": Color(1, 1, 1), "decor": "field"},
			"buildings": [
				_bld(120, 90, 150, 110, brown), _bld(1330, 90, 150, 110, brown),
				_bld(140, 800, 150, 110, brown), _bld(1310, 800, 170, 110, brown),
			],
			"trees": [
				Vector2(320, 150), Vector2(560, 100), Vector2(1080, 110), Vector2(1280, 160),
				Vector2(120, 560), Vector2(1490, 560), Vector2(360, 940), Vector2(1180, 940),
			],
			"waste_count": 14,
		},
		{
			"name": "Fazenda", "theme": {"grass": Color(1.02, 0.98, 0.82), "decor": "farm"},
			"buildings": [
				_bld(90, 70, 260, 150, red), _bld(1260, 70, 160, 150, cream),
				_bld(150, 800, 190, 120, brown), _bld(1210, 800, 220, 120, red),
			],
			"trees": [Vector2(470, 120), Vector2(1120, 130), Vector2(110, 560), Vector2(1500, 560), Vector2(1420, 940)],
			"waste_count": 18,
		},
		{
			"name": "Vila Simples", "theme": {"grass": Color(0.86, 0.86, 0.8), "decor": "dust"},
			"buildings": [
				_bld(90, 90, 150, 110, gray), _bld(300, 90, 150, 110, gray),
				_bld(1150, 90, 150, 110, gray), _bld(1360, 90, 150, 110, gray),
				_bld(130, 810, 150, 100, gray), _bld(1360, 810, 150, 100, gray),
			],
			"trees": [Vector2(560, 130), Vector2(1080, 130), Vector2(110, 560), Vector2(1500, 560)],
			"waste_count": 22,
		},
		{
			"name": "Classe Media", "theme": {"grass": Color(0.94, 0.98, 0.9), "decor": "plaza"},
			"buildings": [
				_bld(90, 80, 180, 120, pastel_a), _bld(330, 80, 180, 120, pastel_b),
				_bld(1090, 80, 180, 120, pastel_a), _bld(1330, 80, 170, 120, pastel_b),
				_bld(140, 800, 180, 110, pastel_b), _bld(1300, 800, 180, 110, pastel_a),
			],
			"trees": [Vector2(600, 130), Vector2(1010, 130), Vector2(120, 560), Vector2(1500, 560)],
			"waste_count": 26,
		},
		{
			"name": "Classe Alta", "theme": {"grass": Color(0.9, 1.02, 0.86), "decor": "garden"},
			"buildings": [
				_bld(90, 70, 260, 150, mansion), _bld(1250, 70, 260, 150, mansion),
				_bld(150, 800, 240, 120, mansion), _bld(1220, 800, 250, 120, mansion),
			],
			"trees": [Vector2(520, 120), Vector2(1090, 120), Vector2(120, 560), Vector2(1500, 560)],
			"waste_count": 30,
		},
		{
			"name": "Alta Sociedade", "theme": {"grass": Color(0.82, 0.86, 0.9), "decor": "city"},
			"buildings": [
				_bld(100, 40, 130, 230, tower), _bld(300, 60, 130, 210, tower),
				_bld(1180, 60, 130, 210, tower), _bld(1380, 40, 130, 230, tower),
				_bld(130, 780, 140, 150, tower), _bld(1330, 780, 140, 150, tower),
			],
			"trees": [Vector2(560, 140), Vector2(1080, 140)],
			"waste_count": 34,
		},
	]


func _bld(x: float, y: float, w: float, h: float, palette: Dictionary) -> Dictionary:
	return {"rect": Rect2(x, y, w, h), "wall": palette["wall"], "roof": palette["roof"]}


func _waste_kinds() -> Array:
	# Cores no padrao CONAMA da coleta seletiva.
	return [
		{"type": "plastic", "name": "plastico", "color": Color("#e0483a"), "value": 10},
		{"type": "paper", "name": "papel", "color": Color("#2b6fd6"), "value": 10},
		{"type": "glass", "name": "vidro", "color": Color("#3faf4e"), "value": 10},
		{"type": "metal", "name": "metal", "color": Color("#f2c531"), "value": 10},
		{"type": "organic", "name": "organico", "color": Color("#6b4a2b"), "value": 10},
		{"type": "reject", "name": "rejeito", "color": Color("#6f6f6f"), "value": 8},
	]


func _make_bins() -> Array:
	var kinds := _waste_kinds()
	var bins: Array = []
	for i in BIN_POSITIONS.size():
		var kind: Dictionary = kinds[i % kinds.size()]
		bins.append({
			"position": BIN_POSITIONS[i], "type": kind["type"],
			"name": kind["name"], "color": kind["color"],
		})
	return bins


func _scatter_waste(count: int) -> Array:
	var kinds := _waste_kinds()
	var result: Array = []
	var attempts := 0
	while result.size() < count and attempts < count * 80:
		attempts += 1
		var p := Vector2(randf_range(110, 1490), randf_range(110, 920))
		if PLAZA_KEEPOUT.has_point(p):
			continue
		var bad := false
		for b in _building_defs:
			var rect: Rect2 = b["rect"]
			if rect.grow(30).has_point(p):
				bad = true
				break
		if bad:
			continue
		for t in _tree_positions:
			if p.distance_to(t) < 48:
				bad = true
				break
		if bad:
			continue
		for e in result:
			var ep: Vector2 = e["position"]
			if ep.distance_to(p) < 70:
				bad = true
				break
		if bad:
			continue

		var kind: Dictionary = kinds[result.size() % kinds.size()]
		var item := {"position": p, "type": kind["type"], "name": kind["name"], "color": kind["color"], "value": kind["value"]}
		# E-lixo raro: descarte no rejeito, vale mais.
		if phase_index >= 1 and randf() < 0.12:
			item["type"] = "reject"
			item["name"] = "e-lixo"
			item["color"] = Color("#9b59b6")
			item["value"] = 30
		result.append(item)
	return result


# --------------------------------------------------------------------------- #
# Ciclo de vida da fase
# --------------------------------------------------------------------------- #

func _apply_saved_state() -> void:
	var data := SaveSystem.load_state()
	if not (SaveSystem.should_load_save and SaveSystem.has_save()):
		data = SaveSystem.default_state()

	coins = data["coins"]
	_cities = data["cities"]
	_city_index = clampi(data["current_city"], 0, CITY_NAMES.size() - 1)
	# Se a cidade atual ja foi concluida, pula para a proxima disponivel.
	if _cities[_city_index]["completed"]:
		_city_index = _first_available_city()
	phase_index = clampi(data["phase"], 0, _phases.size() - 1)
	_bag = clampi(data["bag"], 1, MAX_BAG)
	_shoe = clampi(data["shoe"], 0, MAX_SHOE)
	_collector = clampi(data["collector"], 0, MAX_AUTO)
	_conveyor = clampi(data["conveyor"], 0, MAX_AUTO)
	_sorter = clampi(data["sorter"], 0, MAX_AUTO)
	_startup_announced = _collector > 0 and _conveyor > 0 and _sorter > 0
	sustainability = 0
	_save()


func _first_available_city() -> int:
	for i in _cities.size():
		if not _cities[i]["completed"]:
			return i
	return 0  # todas concluidas


func _save() -> void:
	SaveSystem.save_state({
		"coins": coins,
		"current_city": _city_index,
		"phase": phase_index,
		"bag": _bag, "shoe": _shoe,
		"collector": _collector, "conveyor": _conveyor, "sorter": _sorter,
		"cities": _cities,
	})


func _setup_phase() -> void:
	var phase: Dictionary = _phases[phase_index]
	_phase_name = phase["name"]
	_theme = phase["theme"]
	_building_defs = phase["buildings"]
	_tree_positions = phase["trees"]
	_bin_data = _make_bins()
	_waste_positions = _scatter_waste(phase["waste_count"])

	_bin_pos_by_type = {}
	for bin in _bin_data:
		_bin_pos_by_type[bin["type"]] = bin["position"]

	_total_items = _waste_positions.size()
	_correct_discards = 0
	_combo = 0
	sustainability = 0
	_phase_complete = false
	_inventory = []
	_sacola = []
	_belt_items = []

	_create_world_collisions()
	_spawn_recycle_bins()
	_spawn_waste_items()
	_spawn_player()
	_spawn_collector()

	feedback_label.text = "Colete o lixo e separe na lixeira certa (cores CONAMA). Tecla G: guia."
	_update_hud()
	_update_sacola_label()
	queue_redraw()


func _clear_phase_nodes() -> void:
	if _collector_node != null and is_instance_valid(_collector_node):
		_collector_node.free()
	_collector_node = null
	for node_name in ["WorldCollisions", "RecycleBins", "WasteItems"]:
		var node := get_node_or_null(node_name)
		if node != null:
			node.free()
	if is_instance_valid(player):
		player.free()
		player = null


# --------------------------------------------------------------------------- #
# Spawns
# --------------------------------------------------------------------------- #

func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	player.position = PLAYER_START
	player.set("speed", BASE_SPEED * _speed_multiplier())
	add_child(player)


func _speed_multiplier() -> float:
	return 1.0 + 0.1 * float(_shoe)


func _spawn_waste_items() -> void:
	var waste_root := Node2D.new()
	waste_root.name = "WasteItems"
	add_child(waste_root)

	for waste_data in _waste_positions:
		var waste_item := WASTE_ITEM_SCENE.instantiate()
		waste_item.position = waste_data["position"]
		waste_item.waste_type = waste_data["type"]
		waste_item.display_name = waste_data["name"]
		waste_item.display_color = waste_data["color"]
		waste_item.value = waste_data["value"]
		waste_item.picked_up.connect(_on_waste_item_picked_up)
		waste_root.add_child(waste_item)


func _spawn_recycle_bins() -> void:
	var bin_root := Node2D.new()
	bin_root.name = "RecycleBins"
	add_child(bin_root)

	for bin in _bin_data:
		var recycle_bin := RECYCLE_BIN_SCENE.instantiate()
		recycle_bin.position = bin["position"]
		recycle_bin.bin_type = bin["type"]
		recycle_bin.display_name = bin["name"]
		recycle_bin.display_color = bin["color"]
		recycle_bin.discard_requested.connect(_on_discard_requested)
		bin_root.add_child(recycle_bin)


func _spawn_collector() -> void:
	_collector_node = null
	if phase_index < AUTO_UNLOCK_PHASE or _collector <= 0:
		return
	var bot = MACHINE_SCRIPT.new()
	add_child(bot)
	bot.setup(_collector, SACOLA_POS, Color("#8fb8d8"))
	bot.deposited.connect(_on_collector_deposited)
	_collector_node = bot


func _create_world_collisions() -> void:
	var collision_root := Node2D.new()
	collision_root.name = "WorldCollisions"
	add_child(collision_root)

	_add_rect_collision(collision_root, HQ_RECT, "StartupHQ")

	for b in _building_defs:
		_add_rect_collision(collision_root, b["rect"], "BuildingCollision")

	for tree_position in _tree_positions:
		var tp: Vector2 = tree_position
		_add_circle_collision(collision_root, tp + Vector2(0, 16), 16.0, "TreeCollision")

	for bin in _bin_data:
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


func _create_sacola_area() -> void:
	var area := Area2D.new()
	area.name = "SacolaArea"
	area.position = SACOLA_POS
	area.collision_layer = 0
	area.collision_mask = 2
	add_child(area)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 54.0
	shape.shape = circle
	area.add_child(shape)
	area.body_entered.connect(_on_sacola_body_entered)


# --------------------------------------------------------------------------- #
# Coleta e descarte
# --------------------------------------------------------------------------- #

func _on_waste_item_picked_up(waste_item: Node) -> void:
	if _phase_complete:
		return
	if _inventory.size() >= _bag:
		feedback_label.text = "Bolsa cheia (%d/%d). Leve ate as lixeiras do centro." % [_inventory.size(), _bag]
		return

	_inventory.append({
		"type": waste_item.get("waste_type"), "name": waste_item.get("display_name"),
		"color": waste_item.get("display_color"), "value": int(waste_item.get("value")),
	})
	feedback_label.text = "Coletado: %s. Bolsa: %d/%d." % [waste_item.get("display_name"), _inventory.size(), _bag]
	Audio.play("pickup")
	_spawn_sparkle(waste_item.position, waste_item.get("display_color"))
	waste_item.queue_free()
	_update_hud()


func _on_sacola_body_entered(body: Node2D) -> void:
	if _phase_complete or _shop_open or _paused or _guide_open:
		return
	if body.name != "Player":
		return
	var moved := 0
	while _inventory.size() < _bag and not _sacola.is_empty():
		_inventory.append(_sacola.pop_front())
		moved += 1
	if moved > 0:
		Audio.play("pickup")
		feedback_label.text = "Peguei %d item(ns) da sacola da coletora. Agora separe!" % moved
		_update_hud()
		_update_sacola_label()


func _on_discard_requested(recycle_bin: Node) -> void:
	if _phase_complete:
		return
	var bin_type: String = recycle_bin.get("bin_type")
	var bin_name: String = recycle_bin.get("display_name")
	var bin_pos: Vector2 = recycle_bin.position

	if _inventory.is_empty():
		feedback_label.text = "Colete um residuo antes de usar a lixeira de %s." % bin_name
		return

	var discarded := 0
	var earned := 0
	var kept: Array = []
	for item in _inventory:
		if item["type"] == bin_type:
			_combo += 1
			var mult := clampf(1.0 + 0.15 * float(_combo - 1), 1.0, 2.5)
			var award := int(round(float(item["value"]) * mult))
			coins += award
			earned += award
			sustainability = mini(100, sustainability + CORRECT_DISCARD_SUSTAINABILITY)
			_correct_discards += 1
			discarded += 1
		else:
			kept.append(item)
	_inventory = kept

	if discarded > 0:
		_spawn_popup(bin_pos + Vector2(0, -40), "+%d" % earned, Color("#2c451f"))
		_spawn_sparkle(bin_pos, recycle_bin.get("display_color"))
		recycle_bin.call("react")
		_punch_label(_coins_label)
		Audio.play("correct")
		var combo_txt := ""
		if _combo >= 2:
			combo_txt = "  Combo x%d!" % _combo
			_punch_label(_combo_label)
		feedback_label.text = "Correto! %d na lixeira de %s. +%d moedas%s" % [discarded, bin_name, earned, combo_txt]
	else:
		_combo = 0
		sustainability = maxi(0, sustainability - WRONG_DISCARD_SUSTAINABILITY_LOSS)
		Audio.play("wrong")
		feedback_label.text = "Nada da sua bolsa vai na lixeira de %s. Combo perdido." % bin_name

	_update_hud()
	_save()
	_check_phase_complete()


func _on_collector_deposited(item: Dictionary) -> void:
	if _phase_complete:
		return
	_sacola.append(item)
	_spawn_sparkle(SACOLA_POS, item["color"])
	_update_sacola_label()
	queue_redraw()


# Esteira + separadora: processam a sacola automaticamente (rende so o valor
# base, sem combo — separar na mao continua valendo mais).
func _process_belt(delta: float) -> void:
	var line_active := _conveyor > 0 and _sorter > 0 and phase_index >= AUTO_UNLOCK_PHASE

	if line_active and not _sacola.is_empty() and _belt_items.size() < 2 + _conveyor:
		_belt_timer -= delta
		if _belt_timer <= 0.0:
			var item: Dictionary = _sacola.pop_front()
			var to: Vector2 = _bin_pos_by_type.get(item["type"], BIN_POSITIONS[0])
			_belt_items.append({"item": item, "from": SACOLA_POS, "to": to, "t": 0.0})
			_belt_timer = maxf(0.4, 1.6 - 0.2 * float(_conveyor) - 0.2 * float(_sorter))
			_update_sacola_label()

	if _belt_items.is_empty():
		return

	var speed := 0.5 + 0.15 * float(_conveyor)
	var done: Array = []
	for entry in _belt_items:
		entry["t"] += speed * delta
		if entry["t"] >= 1.0:
			done.append(entry)
	for entry in done:
		_belt_items.erase(entry)
		_credit_auto(entry["item"], entry["to"])

	queue_redraw()


func _credit_auto(item: Dictionary, at: Vector2) -> void:
	if _phase_complete:
		return
	var award: int = item["value"]
	coins += award
	sustainability = mini(100, sustainability + CORRECT_DISCARD_SUSTAINABILITY)
	_correct_discards += 1
	_spawn_popup(at + Vector2(0, -40), "+%d" % award, Color("#3a5a8a"))
	_spawn_sparkle(at, item["color"])
	Audio.play("coin")
	_update_hud()
	_save()
	_check_phase_complete()


func _check_phase_complete() -> void:
	if _correct_discards >= _total_items:
		_on_phase_complete()


# --------------------------------------------------------------------------- #
# Popups e faiscas
# --------------------------------------------------------------------------- #

func _spawn_popup(world_pos: Vector2, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.position = world_pos
	label.z_index = 50
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.9))
	label.add_theme_constant_override("outline_size", 6)
	add_child(label)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", world_pos.y - 60.0, 0.9)
	tween.tween_property(label, "modulate:a", 0.0, 0.9)
	tween.finished.connect(label.queue_free)


func _spawn_sparkle(world_pos: Vector2, color: Color) -> void:
	var p := CPUParticles2D.new()
	p.position = world_pos
	p.amount = 16
	p.lifetime = 0.6
	p.one_shot = true
	p.explosiveness = 0.9
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.gravity = Vector2(0, 180)
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 160.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.color = color
	add_child(p)
	p.emitting = true
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)


func _punch_label(label: Label) -> void:
	if label == null:
		return
	label.pivot_offset = label.size * 0.5
	label.scale = Vector2.ONE
	var tween := create_tween()
	tween.tween_property(label, "scale", Vector2(1.18, 1.18), 0.08).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(label, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_QUAD)


# --------------------------------------------------------------------------- #
# HUD
# --------------------------------------------------------------------------- #

func _create_hud() -> void:
	_hud_layer = CanvasLayer.new()
	_hud_layer.name = "Hud"
	add_child(_hud_layer)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	panel.position = Vector2(20, 18)
	panel.custom_minimum_size = Vector2(450, 0)
	_hud_layer.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	panel.add_child(column)

	_phase_label = _hud_label(23, Color("#2c451f"))
	column.add_child(_phase_label)
	_coins_label = _hud_label(20, Color("#3c513a"))
	column.add_child(_coins_label)
	_passive_label = _hud_label(18, Color("#3a6a8a"))
	column.add_child(_passive_label)

	_sustain_bar = ProgressBar.new()
	_sustain_bar.min_value = 0
	_sustain_bar.max_value = 100
	_sustain_bar.show_percentage = false
	_sustain_bar.custom_minimum_size = Vector2(0, 20)
	_sustain_bar.add_theme_stylebox_override("background", _bar_style(Color("#d5e6c4")))
	_sustain_bar.add_theme_stylebox_override("fill", _bar_style(Color("#5fae4b")))
	column.add_child(_sustain_bar)

	_progress_label = _hud_label(20, Color("#3c513a"))
	column.add_child(_progress_label)
	_bag_label = _hud_label(20, Color("#3c513a"))
	column.add_child(_bag_label)
	_combo_label = _hud_label(20, Color("#c8781f"))
	column.add_child(_combo_label)

	feedback_label = _hud_label(18, Color("#4a5d3f"))
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_label.custom_minimum_size = Vector2(418, 0)
	column.add_child(feedback_label)

	var shop_button := Button.new()
	shop_button.text = "Startup / Loja (L)"
	shop_button.custom_minimum_size = Vector2(0, 44)
	shop_button.add_theme_font_size_override("font_size", 22)
	shop_button.add_theme_color_override("font_color", Color("#2c451f"))
	shop_button.add_theme_stylebox_override("normal", _button_style(Color("#9fd57e")))
	shop_button.add_theme_stylebox_override("hover", _button_style(Color("#b6e695")))
	shop_button.add_theme_stylebox_override("pressed", _button_style(Color("#8ac368")))
	shop_button.pressed.connect(_toggle_shop)
	column.add_child(shop_button)

	_hint_label = _hud_label(16, Color("#20301f"))
	_hint_label.text = "WASD: mover  •  L: Startup  •  G: Guia  •  M: Mapa  •  ESC: Pausa"
	_hint_label.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.7))
	_hint_label.add_theme_constant_override("shadow_offset_x", 1)
	_hint_label.add_theme_constant_override("shadow_offset_y", 1)
	# Ancorado no rodape: em tela de celular o viewport e bem mais alto que 1000.
	_hint_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_hint_label.offset_left = 24
	_hint_label.offset_right = 924
	_hint_label.offset_top = -44
	_hint_label.offset_bottom = -16
	_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_layer.add_child(_hint_label)

	_sacola_label = Label.new()
	_sacola_label.add_theme_font_size_override("font_size", 18)
	_sacola_label.add_theme_color_override("font_color", Color("#2c451f"))
	_sacola_label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.9))
	_sacola_label.add_theme_constant_override("outline_size", 5)
	_sacola_label.z_index = 20
	add_child(_sacola_label)

	_create_transition_and_banner()


func _create_touch_controls() -> void:
	if not TOUCH_CONTROLS_SCRIPT.is_available():
		return

	_touch_layer = CanvasLayer.new()
	_touch_layer.name = "TouchControls"
	_touch_layer.layer = 2   # acima do HUD, abaixo da loja/pausa/guia/mapa
	add_child(_touch_layer)

	_touch_controls = Control.new()
	_touch_controls.set_script(TOUCH_CONTROLS_SCRIPT)
	_touch_layer.add_child(_touch_controls)
	_touch_controls.connect("guide_pressed", _toggle_guide)
	_touch_controls.connect("map_pressed", _toggle_minimap)
	_touch_controls.connect("pause_pressed", _touch_pause)

	# Sem teclado a dica de teclas so atrapalha (e fica embaixo do manche).
	if _hint_label != null:
		_hint_label.visible = false


func _touch_pause() -> void:
	if not _paused and not _shop_open and not _guide_open and not _minimap_open and not _phase_complete:
		_open_pause()


func _update_sacola_label() -> void:
	if _sacola_label == null:
		return
	_sacola_label.visible = not _sacola.is_empty()
	_sacola_label.text = "Sacola: %d" % _sacola.size()
	_sacola_label.position = SACOLA_POS + Vector2(-34, 20)


func _hud_label(size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.97, 0.99, 0.92, 0.9)
	style.set_corner_radius_all(16)
	style.border_color = Color("#7fa85c")
	style.set_border_width_all(3)
	style.set_content_margin_all(16)
	style.shadow_color = Color(0, 0, 0, 0.15)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 4)
	return style


func _bar_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(8)
	return style


func _button_style(bg_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(12)
	style.set_content_margin_all(10)
	style.border_color = Color("#5f8c3c")
	style.set_border_width_all(2)
	return style


func _create_transition_and_banner() -> void:
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0.06, 0.09, 0.06, 1.0)
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.visible = false
	_hud_layer.add_child(_fade_rect)

	var grad := Gradient.new()
	grad.set_color(0, Color("#5ec4ff"))
	grad.set_color(1, Color("#f2d16b"))
	grad.add_point(0.35, Color("#8ad879"))
	grad.add_point(0.7, Color("#f0a8a8"))

	_confetti = CPUParticles2D.new()
	_confetti.position = Vector2(WORLD_SIZE.x * 0.5, 30)
	_confetti.amount = 90
	_confetti.lifetime = 2.6
	_confetti.one_shot = true
	_confetti.explosiveness = 0.5
	_confetti.emitting = false
	_confetti.direction = Vector2(0, 1)
	_confetti.spread = 70.0
	_confetti.gravity = Vector2(0, 260)
	_confetti.initial_velocity_min = 120.0
	_confetti.initial_velocity_max = 340.0
	_confetti.scale_amount_min = 3.0
	_confetti.scale_amount_max = 7.0
	_confetti.angular_velocity_min = -220.0
	_confetti.angular_velocity_max = 220.0
	_confetti.color_ramp = grad
	_hud_layer.add_child(_confetti)

	_banner_root = CenterContainer.new()
	_banner_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_banner_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_root.visible = false
	_hud_layer.add_child(_banner_root)

	_banner_panel = PanelContainer.new()
	_banner_panel.add_theme_stylebox_override("panel", _banner_style())
	_banner_root.add_child(_banner_panel)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 10)
	_banner_panel.add_child(vb)

	_banner_title = Label.new()
	_banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_title.add_theme_font_size_override("font_size", 60)
	_banner_title.add_theme_color_override("font_color", Color("#2c451f"))
	vb.add_child(_banner_title)

	_banner_sub = Label.new()
	_banner_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_sub.add_theme_font_size_override("font_size", 26)
	_banner_sub.add_theme_color_override("font_color", Color("#4a5d3f"))
	vb.add_child(_banner_sub)

	_banner_tip = Label.new()
	_banner_tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_banner_tip.custom_minimum_size = Vector2(620, 0)
	_banner_tip.add_theme_font_size_override("font_size", 20)
	_banner_tip.add_theme_color_override("font_color", Color("#6f8a5a"))
	vb.add_child(_banner_tip)


func _banner_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.97, 0.99, 0.92, 0.95)
	style.set_corner_radius_all(26)
	style.border_color = Color("#7fa85c")
	style.set_border_width_all(5)
	style.content_margin_left = 60
	style.content_margin_right = 60
	style.content_margin_top = 40
	style.content_margin_bottom = 40
	style.shadow_color = Color(0, 0, 0, 0.22)
	style.shadow_size = 22
	style.shadow_offset = Vector2(0, 10)
	return style


func _update_hud() -> void:
	if _phase_label == null:
		return
	_phase_label.text = "%s — Fase %d/%d: %s" % [CITY_NAMES[_city_index], phase_index + 1, _phases.size(), _phase_name]
	_coins_label.text = "Moedas: %d" % coins
	var rate := _passive_rate()
	if rate > 0.0:
		_passive_label.text = "Renda passiva: +%.1f/s" % rate
	else:
		_passive_label.text = ""
	_sustain_bar.value = sustainability
	_progress_label.text = "Reciclados: %d / %d" % [_correct_discards, _total_items]

	var carried := ""
	if not _inventory.is_empty():
		var names := PackedStringArray()
		for item in _inventory:
			names.append(String(item["name"]))
		carried = "  (" + ", ".join(names) + ")"
	_bag_label.text = "Bolsa: %d/%d%s" % [_inventory.size(), _bag, carried]

	if _combo >= 2:
		_combo_label.text = "Combo x%d" % _combo
	else:
		_combo_label.text = ""


# --------------------------------------------------------------------------- #
# Loja / Startup
# --------------------------------------------------------------------------- #

func _create_shop() -> void:
	_shop_layer = CanvasLayer.new()
	_shop_layer.name = "Shop"
	_shop_layer.layer = 5
	_shop_layer.visible = false
	add_child(_shop_layer)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shop_layer.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shop_layer.add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _banner_style())
	center.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)

	var title := Label.new()
	title.text = "Startup Sustentavel EcoCat"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color("#2c451f"))
	column.add_child(title)

	_shop_coins_label = Label.new()
	_shop_coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shop_coins_label.add_theme_font_size_override("font_size", 24)
	_shop_coins_label.add_theme_color_override("font_color", Color("#3c513a"))
	column.add_child(_shop_coins_label)

	_shop_rows["bag"] = _make_shop_row(column, _buy_bag)
	_shop_rows["shoe"] = _make_shop_row(column, _buy_shoe)
	_shop_rows["collector"] = _make_shop_row(column, func() -> void: _buy_auto("collector"))
	_shop_rows["conveyor"] = _make_shop_row(column, func() -> void: _buy_auto("conveyor"))
	_shop_rows["sorter"] = _make_shop_row(column, func() -> void: _buy_auto("sorter"))

	var close_button := Button.new()
	close_button.text = "Fechar (L / ESC)"
	close_button.custom_minimum_size = Vector2(0, 46)
	close_button.add_theme_font_size_override("font_size", 22)
	close_button.add_theme_color_override("font_color", Color("#2c451f"))
	close_button.add_theme_stylebox_override("normal", _button_style(Color("#e0c58a")))
	close_button.add_theme_stylebox_override("hover", _button_style(Color("#eed6a0")))
	close_button.add_theme_stylebox_override("pressed", _button_style(Color("#d0b478")))
	close_button.pressed.connect(_close_shop)
	column.add_child(close_button)


func _make_shop_row(parent: Node, on_buy: Callable) -> Dictionary:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	parent.add_child(row)

	var info := VBoxContainer.new()
	info.custom_minimum_size = Vector2(560, 0)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)

	var name_label := Label.new()
	name_label.add_theme_font_size_override("font_size", 25)
	name_label.add_theme_color_override("font_color", Color("#2c451f"))
	info.add_child(name_label)

	var desc_label := Label.new()
	desc_label.add_theme_font_size_override("font_size", 17)
	desc_label.add_theme_color_override("font_color", Color("#4a5d3f"))
	info.add_child(desc_label)

	var buy_button := Button.new()
	buy_button.custom_minimum_size = Vector2(220, 54)
	buy_button.add_theme_font_size_override("font_size", 22)
	buy_button.add_theme_color_override("font_color", Color("#2c451f"))
	buy_button.add_theme_stylebox_override("normal", _button_style(Color("#9fd57e")))
	buy_button.add_theme_stylebox_override("hover", _button_style(Color("#b6e695")))
	buy_button.add_theme_stylebox_override("pressed", _button_style(Color("#8ac368")))
	buy_button.add_theme_stylebox_override("disabled", _button_style(Color("#c8ccc0")))
	buy_button.pressed.connect(on_buy)
	row.add_child(buy_button)

	return {"name": name_label, "desc": desc_label, "button": buy_button}


func _toggle_shop() -> void:
	if _shop_open:
		_close_shop()
	elif not _paused and not _guide_open and not _minimap_open and not _phase_complete:
		_open_shop()


func _open_shop() -> void:
	_shop_open = true
	_shop_layer.visible = true
	_set_gameplay_active(false)
	_refresh_shop()


func _close_shop() -> void:
	_shop_open = false
	_shop_layer.visible = false
	if not _phase_complete:
		_set_gameplay_active(true)


func _set_gameplay_active(value: bool) -> void:
	if is_instance_valid(player):
		player.set_physics_process(value)
		if not value:
			player.touch_direction = Vector2.ZERO
	if _touch_layer != null:
		_touch_layer.visible = value
		_touch_controls.release()
	if _collector_node != null and is_instance_valid(_collector_node):
		_collector_node.set("active", value)


func _refresh_shop() -> void:
	_shop_coins_label.text = "Moedas: %d" % coins

	var bag_row: Dictionary = _shop_rows["bag"]
	bag_row["name"].text = "Bolsa do Eco  (nivel %d/%d)" % [_bag, MAX_BAG]
	if _bag >= MAX_BAG:
		bag_row["desc"].text = "Carrega ate %d residuos por vez. Maximo!" % _bag
		_set_buy(bag_row["button"], "Maximo", false)
	else:
		var price := _bag_price()
		bag_row["desc"].text = "Carrega %d por vez -> melhora para %d." % [_bag, _bag + 1]
		_set_buy(bag_row["button"], "Comprar (%d)" % price, coins >= price)

	var shoe_row: Dictionary = _shop_rows["shoe"]
	shoe_row["name"].text = "Calcado  (%.1fx)" % _speed_multiplier()
	if _shoe >= MAX_SHOE:
		shoe_row["desc"].text = "Velocidade maxima (%.1fx)!" % _speed_multiplier()
		_set_buy(shoe_row["button"], "Maximo", false)
	else:
		var price := _shoe_price()
		shoe_row["desc"].text = "Deixa o Eco %.1fx mais rapido." % (1.0 + 0.1 * float(_shoe + 1))
		_set_buy(shoe_row["button"], "Comprar (%d)" % price, coins >= price)

	_refresh_auto_row("collector", _shop_rows["collector"], _collector,
		"Coletora", "Recolhe o lixo do chao ate a sacola da sede.")
	_refresh_auto_row("conveyor", _shop_rows["conveyor"], _conveyor,
		"Esteira", "Leva o lixo da sacola ate as lixeiras (precisa da separadora).")
	_refresh_auto_row("sorter", _shop_rows["sorter"], _sorter,
		"Separadora", "Separa o lixo na lixeira certa (precisa da esteira).")


func _refresh_auto_row(kind: String, row: Dictionary, level: int, title: String, desc: String) -> void:
	row["name"].text = "%s  (nivel %d/%d)" % [title, level, MAX_AUTO]
	if phase_index < AUTO_UNLOCK_PHASE:
		row["desc"].text = "%s Disponivel ao fundar a Startup na Fase %d." % [desc, AUTO_UNLOCK_PHASE + 1]
		_set_buy(row["button"], "Bloqueada", false)
		return
	if level >= MAX_AUTO:
		row["desc"].text = "%s No maximo!" % desc
		_set_buy(row["button"], "Maximo", false)
		return
	var price := _auto_price(kind, level)
	row["desc"].text = desc
	if level == 0:
		_set_buy(row["button"], "Comprar (%d)" % price, coins >= price)
	else:
		_set_buy(row["button"], "Melhorar (%d)" % price, coins >= price)


func _set_buy(button: Button, text: String, enabled: bool) -> void:
	button.text = text
	button.disabled = not enabled


func _bag_price() -> int:
	return 40 * _bag


func _shoe_price() -> int:
	return 30 * (_shoe + 1)


func _auto_price(kind: String, level: int) -> int:
	var base := {"collector": 150, "conveyor": 180, "sorter": 220}
	var step := {"collector": 120, "conveyor": 130, "sorter": 150}
	if level == 0:
		return int(base[kind])
	return int(step[kind]) * level


func _buy_bag() -> void:
	if _bag >= MAX_BAG:
		return
	var price := _bag_price()
	if coins < price:
		return
	coins -= price
	_bag += 1
	Audio.play("buy")
	_after_purchase()


func _buy_shoe() -> void:
	if _shoe >= MAX_SHOE:
		return
	var price := _shoe_price()
	if coins < price:
		return
	coins -= price
	_shoe += 1
	if is_instance_valid(player):
		player.set("speed", BASE_SPEED * _speed_multiplier())
	Audio.play("buy")
	_after_purchase()


func _buy_auto(kind: String) -> void:
	if phase_index < AUTO_UNLOCK_PHASE:
		return
	var level := _auto_level(kind)
	if level >= MAX_AUTO:
		return
	var price := _auto_price(kind, level)
	if coins < price:
		return
	coins -= price
	_set_auto_level(kind, level + 1)
	Audio.play("buy")

	if kind == "collector":
		if _collector_node != null and is_instance_valid(_collector_node):
			_collector_node.set("level", _collector)
		else:
			_spawn_collector()
			# a loja esta aberta: mantem pausado
			if _collector_node != null and is_instance_valid(_collector_node):
				_collector_node.set("active", false)

	_check_startup_founded()
	_after_purchase()


func _auto_level(kind: String) -> int:
	match kind:
		"collector": return _collector
		"conveyor": return _conveyor
		_: return _sorter


func _set_auto_level(kind: String, value: int) -> void:
	match kind:
		"collector": _collector = value
		"conveyor": _conveyor = value
		"sorter": _sorter = value


func _check_startup_founded() -> void:
	if not _startup_announced and _collector > 0 and _conveyor > 0 and _sorter > 0:
		_startup_announced = true
		Audio.play("phase")
		feedback_label.text = "Startup EcoCat fundada! A linha coletora -> esteira -> separadora esta completa."


func _after_purchase() -> void:
	_save()
	_update_hud()
	_refresh_shop()


# --------------------------------------------------------------------------- #
# Pausa e Guia
# --------------------------------------------------------------------------- #

func _create_pause_menu() -> void:
	_pause_layer = CanvasLayer.new()
	_pause_layer.name = "Pause"
	_pause_layer.layer = 6
	_pause_layer.visible = false
	add_child(_pause_layer)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_layer.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_layer.add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _banner_style())
	center.add_child(panel)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)

	var title := Label.new()
	title.text = "Pausa"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color("#2c451f"))
	column.add_child(title)

	column.add_child(_menu_button("Continuar", _resume))
	column.add_child(_menu_button("Startup / Loja", _pause_to_shop))
	_mute_button = _menu_button("Som: Ligado", _toggle_mute)
	column.add_child(_mute_button)
	column.add_child(_menu_button("Menu Principal", _go_to_menu))


func _menu_button(text: String, on_press: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(340, 56)
	button.add_theme_font_size_override("font_size", 24)
	button.add_theme_color_override("font_color", Color("#2c451f"))
	button.add_theme_stylebox_override("normal", _button_style(Color("#9fd57e")))
	button.add_theme_stylebox_override("hover", _button_style(Color("#b6e695")))
	button.add_theme_stylebox_override("pressed", _button_style(Color("#8ac368")))
	button.pressed.connect(on_press)
	return button


func _open_pause() -> void:
	_paused = true
	_pause_layer.visible = true
	_set_gameplay_active(false)


func _resume() -> void:
	_paused = false
	_pause_layer.visible = false
	if not _phase_complete:
		_set_gameplay_active(true)


func _pause_to_shop() -> void:
	_resume()
	_open_shop()


func _toggle_mute() -> void:
	var muted := Audio.toggle_mute()
	_mute_button.text = "Som: Desligado" if muted else "Som: Ligado"


func _go_to_menu() -> void:
	_save()
	get_tree().change_scene_to_file("res://ui/MainMenu.tscn")


func _create_guide() -> void:
	_guide_layer = CanvasLayer.new()
	_guide_layer.name = "Guide"
	_guide_layer.layer = 6
	_guide_layer.visible = false
	add_child(_guide_layer)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_guide_layer.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_guide_layer.add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _banner_style())
	center.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)

	var title := Label.new()
	title.text = "Guia da Coleta Seletiva (CONAMA)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color("#2c451f"))
	column.add_child(title)

	var lines := [
		[Color("#2b6fd6"), "Papel (azul): jornais, caixas, cadernos"],
		[Color("#e0483a"), "Plastico (vermelho): garrafas, sacos, embalagens"],
		[Color("#3faf4e"), "Vidro (verde): garrafas, potes"],
		[Color("#f2c531"), "Metal (amarelo): latas, tampas"],
		[Color("#6b4a2b"), "Organico (marrom): restos de comida, cascas"],
		[Color("#6f6f6f"), "Rejeito (cinza): nao reciclavel, e-lixo, engordurados"],
	]
	for line in lines:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var swatch := ColorRect.new()
		swatch.color = line[0]
		swatch.custom_minimum_size = Vector2(30, 30)
		row.add_child(swatch)
		var label := Label.new()
		label.text = line[1]
		label.add_theme_font_size_override("font_size", 22)
		label.add_theme_color_override("font_color", Color("#33502f"))
		row.add_child(label)
		column.add_child(row)

	var hint := Label.new()
	hint.text = "Tecla G ou ESC para fechar"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color("#6f8a5a"))
	column.add_child(hint)

	# Botao de fechar: no celular nao ha tecla G nem ESC.
	var close_button := Button.new()
	close_button.text = "Fechar"
	close_button.custom_minimum_size = Vector2(0, 46)
	close_button.add_theme_font_size_override("font_size", 22)
	close_button.add_theme_color_override("font_color", Color("#2c451f"))
	close_button.add_theme_stylebox_override("normal", _button_style(Color("#e0c58a")))
	close_button.add_theme_stylebox_override("hover", _button_style(Color("#eed6a0")))
	close_button.add_theme_stylebox_override("pressed", _button_style(Color("#d0b478")))
	close_button.pressed.connect(_close_guide)
	column.add_child(close_button)


func _toggle_guide() -> void:
	if _guide_open:
		_close_guide()
	elif not _shop_open and not _paused and not _minimap_open and not _phase_complete:
		_guide_open = true
		_guide_layer.visible = true
		_set_gameplay_active(false)


func _close_guide() -> void:
	_guide_open = false
	_guide_layer.visible = false
	if not _phase_complete and not _paused and not _shop_open:
		_set_gameplay_active(true)


# --------------------------------------------------------------------------- #
# Minimapa das cidades
# --------------------------------------------------------------------------- #

func _create_minimap() -> void:
	_minimap_layer = CanvasLayer.new()
	_minimap_layer.name = "Minimap"
	_minimap_layer.layer = 7
	_minimap_layer.visible = false
	add_child(_minimap_layer)

	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.08, 0.06, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_minimap_layer.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_minimap_layer.add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _banner_style())
	center.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)

	var title := Label.new()
	title.text = "Mapa das Cidades"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color("#2c451f"))
	column.add_child(title)

	_minimap_coins_label = Label.new()
	_minimap_coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_minimap_coins_label.add_theme_font_size_override("font_size", 22)
	_minimap_coins_label.add_theme_color_override("font_color", Color("#3c513a"))
	column.add_child(_minimap_coins_label)

	_map_view = MAP_VIEW_SCRIPT.new()
	_map_view.city_selected.connect(_on_map_city_selected)
	column.add_child(_map_view)

	_minimap_footer = Label.new()
	_minimap_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_minimap_footer.add_theme_font_size_override("font_size", 18)
	_minimap_footer.add_theme_color_override("font_color", Color("#6f8a5a"))
	column.add_child(_minimap_footer)

	_minimap_close_button = Button.new()
	_minimap_close_button.custom_minimum_size = Vector2(0, 46)
	_minimap_close_button.add_theme_font_size_override("font_size", 22)
	_minimap_close_button.add_theme_color_override("font_color", Color("#2c451f"))
	_minimap_close_button.add_theme_stylebox_override("normal", _button_style(Color("#e0c58a")))
	_minimap_close_button.add_theme_stylebox_override("hover", _button_style(Color("#eed6a0")))
	_minimap_close_button.add_theme_stylebox_override("pressed", _button_style(Color("#d0b478")))
	_minimap_close_button.pressed.connect(_on_minimap_close)
	column.add_child(_minimap_close_button)


func _city_color(i: int) -> Color:
	var colors := [
		Color("#8ab86a"), Color("#d8b24a"), Color("#b9a58a"),
		Color("#b6a0d0"), Color("#d8c98a"), Color("#8fa0b4"),
	]
	return colors[i % colors.size()]


func _all_completed() -> bool:
	for c in _cities:
		if not c["completed"]:
			return false
	return true


func _open_minimap() -> void:
	_minimap_open = true
	_minimap_layer.visible = true
	_set_gameplay_active(false)
	_banner_root.visible = false
	_refresh_minimap()


func _toggle_minimap() -> void:
	if _minimap_open:
		if not _between_cities:
			_close_minimap()
	elif not _shop_open and not _paused and not _guide_open and not _phase_complete:
		_open_minimap()


func _close_minimap() -> void:
	if _between_cities:
		return
	_minimap_open = false
	_minimap_layer.visible = false
	if not _phase_complete and not _paused and not _shop_open and not _guide_open:
		_set_gameplay_active(true)


func _on_minimap_close() -> void:
	if _between_cities and _all_completed():
		# Zerou todas as cidades: limpa o save e volta ao menu (novo ciclo).
		SaveSystem.clear_save()
		get_tree().change_scene_to_file("res://ui/MainMenu.tscn")
	else:
		_close_minimap()


func _refresh_minimap() -> void:
	_minimap_coins_label.text = "Moedas: %d      Renda passiva total: +%.1f/s" % [coins, _passive_rate()]

	var data: Array = []
	for i in CITY_NAMES.size():
		var city: Dictionary = _cities[i]
		var status := "available"
		var rate := 0.0
		if city["completed"]:
			status = "done"
			rate = PASSIVE_BASE + PASSIVE_PER_LEVEL * float(int(city["collector"]) + int(city["conveyor"]) + int(city["sorter"]))
		elif i == _city_index and not _between_cities:
			status = "current"
		data.append({"name": CITY_NAMES[i], "color": _city_color(i), "status": status, "rate": rate})
	_map_view.set_data(data, _between_cities)

	if _between_cities:
		if _all_completed():
			_minimap_footer.text = "Todas as cidades foram limpas. Missao cumprida!"
			_minimap_close_button.text = "Menu Principal"
			_minimap_close_button.visible = true
		else:
			_minimap_footer.text = "Escolha a proxima cidade para comecar do zero."
			_minimap_close_button.visible = false
	else:
		_minimap_footer.text = "Termine a cidade atual para poder viajar."
		_minimap_close_button.text = "Continuar cidade atual"
		_minimap_close_button.visible = true


func _on_map_city_selected(index: int) -> void:
	# Anima o gato viajando pela rota; ao chegar, troca de cidade.
	Audio.play("buy")
	_minimap_footer.text = "Viajando para %s..." % CITY_NAMES[index]
	_map_view.travel(_city_index, index, _travel_to_city.bind(index))


# --------------------------------------------------------------------------- #
# Conclusao de fase + transicao
# --------------------------------------------------------------------------- #

func _on_phase_complete() -> void:
	_phase_complete = true
	_set_gameplay_active(false)
	if _shop_open:
		_close_shop()
	_confetti.restart()
	Audio.play("phase")

	if phase_index + 1 >= _phases.size():
		_complete_city()
		return

	_banner_title.text = "Fase Concluida!"
	_banner_sub.text = "%s reciclado. Proximo bairro de %s..." % [_phase_name, CITY_NAMES[_city_index]]
	_banner_tip.text = "Voce sabia? " + TIPS[randi() % TIPS.size()]
	_show_banner()
	get_tree().create_timer(3.0).timeout.connect(_advance_phase)


func _advance_phase() -> void:
	await _fade_to_black()
	_banner_root.visible = false
	_clear_phase_nodes()
	phase_index += 1
	_save()
	_setup_phase()
	_fade_in()


func _complete_city() -> void:
	# Zerou as 6 fases: a startup da cidade esta fundada. Guarda a automacao
	# construida aqui (vira renda passiva) e abre o minimapa.
	_between_cities = true
	_cities[_city_index]["completed"] = true
	_cities[_city_index]["collector"] = _collector
	_cities[_city_index]["conveyor"] = _conveyor
	_cities[_city_index]["sorter"] = _sorter
	_save()

	var founded := _collector > 0 and _conveyor > 0 and _sorter > 0
	_banner_title.text = "%s zerada!" % CITY_NAMES[_city_index]
	if founded:
		_banner_sub.text = "Startup fundada! Esta cidade vai gerar renda passiva."
	else:
		_banner_sub.text = "Cidade limpa! Monte a startup para render mais nas proximas."
	_banner_tip.text = "Voce sabia? " + TIPS[randi() % TIPS.size()]
	_show_banner()
	get_tree().create_timer(3.2).timeout.connect(_open_minimap)


func _show_banner() -> void:
	_banner_root.visible = true
	_banner_root.modulate.a = 0.0
	_banner_panel.pivot_offset = _banner_panel.size * 0.5
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_banner_root, "modulate:a", 1.0, 0.4)
	tween.tween_property(_banner_panel, "scale", Vector2.ONE, 0.4).from(Vector2(0.7, 0.7))


func _travel_to_city(index: int) -> void:
	if index < 0 or index >= CITY_NAMES.size():
		return
	if _cities[index]["completed"]:
		return
	_minimap_open = false
	_minimap_layer.visible = false
	_between_cities = false
	await _fade_to_black()
	_banner_root.visible = false
	_clear_phase_nodes()
	# Nova cidade: recomeca do zero (Fase 1, sem equipamento e sem startup).
	_city_index = index
	phase_index = 0
	_bag = 1
	_shoe = 0
	_collector = 0
	_conveyor = 0
	_sorter = 0
	_startup_announced = false
	_save()
	_setup_phase()
	_fade_in()


func _fade_to_black() -> void:
	_fade_rect.visible = true
	_fade_rect.color.a = 0.0
	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", 1.0, 0.5)
	await tween.finished


func _fade_in() -> void:
	_fade_rect.visible = true
	_fade_rect.color.a = 1.0
	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", 0.0, 0.5)
	tween.tween_callback(func() -> void: _fade_rect.visible = false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _minimap_open:
			if not _between_cities:
				_close_minimap()
		elif _guide_open:
			_close_guide()
		elif _shop_open:
			_close_shop()
		elif _paused:
			_resume()
		elif not _phase_complete:
			_open_pause()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_L:
			_toggle_shop()
		elif event.keycode == KEY_G:
			_toggle_guide()
		elif event.keycode == KEY_M:
			_toggle_minimap()


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


# --------------------------------------------------------------------------- #
# Desenho do mapa (temas + sede da startup + esteira)
# --------------------------------------------------------------------------- #

func _draw() -> void:
	_draw_ground()
	_draw_decor()
	for b in _building_defs:
		_draw_building(b["rect"], b["wall"], b["roof"])
	_draw_trees()
	_draw_belt()
	_draw_startup_hq()
	_draw_sacola()


func _draw_ground() -> void:
	var tint: Color = _theme.get("grass", Color(1, 1, 1))
	# Grama estendida bem alem do mapa: com a tela cheia (aspect expand) a camera
	# enxerga fora da cidade em telas de proporcao extrema (celular em pe, monitor
	# ultrawide). Ali tem que haver campo, nunca o fundo do motor.
	draw_texture_rect(_Sprites.grass_tile(), Rect2(Vector2.ZERO, WORLD_SIZE).grow(GROUND_MARGIN), true, tint)


func _draw_decor() -> void:
	var decor: String = _theme.get("decor", "field")
	match decor:
		"farm":
			_draw_crop_field(Rect2(120, 320, 240, 130))
			_draw_crop_field(Rect2(1240, 320, 240, 130))
			_draw_crop_field(Rect2(120, 600, 240, 120))
			_draw_crop_field(Rect2(1240, 600, 240, 120))
		"dust":
			for spot in [Vector2(360, 320), Vector2(1200, 340), Vector2(300, 720), Vector2(1250, 700)]:
				draw_texture_rect(_Sprites.dirt_tile(), Rect2(spot, Vector2(150, 90)), true, Color(0.8, 0.78, 0.72))
		"plaza":
			_draw_pavement(Rect2(470, 380, 660, 320), Color("#cfd0cc"))
		"garden":
			_draw_pavement(Rect2(450, 370, 700, 340), Color("#dcdcd2"))
			draw_circle(Vector2(540, 560), 24, Color("#7fbfe0"))
			draw_circle(Vector2(1060, 560), 24, Color("#7fbfe0"))
		"city":
			_draw_pavement(Rect2(60, 60, WORLD_SIZE.x - 120, WORLD_SIZE.y - 120), Color("#b9bcc0"))


func _draw_crop_field(rect: Rect2) -> void:
	draw_rect(rect, Color("#a9773f"))
	var y := rect.position.y + 8
	while y < rect.end.y - 4:
		draw_rect(Rect2(rect.position.x + 6, y, rect.size.x - 12, 4), Color("#7c5a2e"))
		y += 16


func _draw_pavement(rect: Rect2, color: Color) -> void:
	draw_rect(rect, color)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 4)), color.darkened(0.15))
	draw_rect(Rect2(rect.position + Vector2(0, rect.size.y - 4), Vector2(rect.size.x, 4)), color.darkened(0.15))


func _draw_belt() -> void:
	# Esteira: so aparece quando a esteira foi comprada.
	if _conveyor > 0 and phase_index >= AUTO_UNLOCK_PHASE:
		draw_rect(Rect2(SACOLA_POS.x - 16, 470, 32, SACOLA_POS.y - 470), Color("#5a5a5a"))
		draw_rect(Rect2(SACOLA_POS.x - 16, 470, 32, SACOLA_POS.y - 470), Color("#3a3a3a"))
	for entry in _belt_items:
		var from: Vector2 = entry["from"]
		var to: Vector2 = entry["to"]
		var pos := from.lerp(to, clampf(entry["t"], 0.0, 1.0))
		var col: Color = entry["item"]["color"]
		draw_circle(pos, 9, Color(0, 0, 0, 0.25))
		draw_circle(pos, 7, col)


func _draw_startup_hq() -> void:
	var rect := HQ_RECT
	# Corpo da sede.
	draw_rect(rect, Color("#eae0c8"))
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 20)), Color("#3f7a48"))  # telhado verde
	draw_rect(Rect2(rect.position + Vector2(0, 20), Vector2(6, rect.size.y - 20)), Color("#f4ead2"))
	# Contorno.
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 3)), Color("#5a4326"))
	draw_rect(Rect2(rect.position + Vector2(0, rect.size.y - 3), Vector2(rect.size.x, 3)), Color("#5a4326"))
	draw_rect(Rect2(rect.position, Vector2(3, rect.size.y)), Color("#5a4326"))
	draw_rect(Rect2(rect.position + Vector2(rect.size.x - 3, 0), Vector2(3, rect.size.y)), Color("#5a4326"))
	# Porta e janelas.
	draw_rect(Rect2(rect.position + Vector2(rect.size.x * 0.44, rect.size.y - 44), Vector2(30, 44)), Color("#7a5230"))
	draw_rect(Rect2(rect.position + Vector2(24, 40), Vector2(34, 28)), Color("#8fd0e8"))
	draw_rect(Rect2(rect.position + Vector2(rect.size.x - 58, 40), Vector2(34, 28)), Color("#8fd0e8"))
	# Placa "ECO".
	var sign_pos := rect.position + Vector2(rect.size.x * 0.5 - 30, 26)
	draw_rect(Rect2(sign_pos, Vector2(60, 16)), Color("#2c451f"))
	draw_rect(Rect2(sign_pos + Vector2(2, 2), Vector2(56, 12)), Color("#a9d98a"))
	# Modulos comprados (chamines/antenas) indicam o nivel da startup.
	var modules := (1 if _collector > 0 else 0) + (1 if _conveyor > 0 else 0) + (1 if _sorter > 0 else 0)
	for i in modules:
		draw_rect(Rect2(rect.position + Vector2(20 + i * 26, -16), Vector2(14, 16)), Color("#7f8a92"))
		draw_circle(rect.position + Vector2(27 + i * 26, -18), 4, Color("#f2d16b"))
	# Separadora ao pe da esteira (se comprada).
	if _sorter > 0 and phase_index >= AUTO_UNLOCK_PHASE:
		draw_rect(Rect2(SACOLA_POS.x - 26, 486, 52, 34), Color("#2c2418"))
		draw_rect(Rect2(SACOLA_POS.x - 23, 489, 46, 28), Color("#c0a86a"))


func _draw_sacola() -> void:
	if _sacola.is_empty():
		return
	# Sacola (pilha de lixo recolhido pela coletora).
	var base := SACOLA_POS
	draw_circle(base + Vector2(0, 8), 26, Color(0, 0, 0, 0.12))
	draw_rect(Rect2(base.x - 20, base.y - 18, 40, 30), Color("#b98a4a"))
	draw_rect(Rect2(base.x - 20, base.y - 24, 40, 8), Color("#8a6a3a"))
	draw_rect(Rect2(base.x - 20, base.y - 18, 40, 3), Color("#7a5a2a"))


func _draw_building(rect: Rect2, wall: Color, roof: Color) -> void:
	draw_texture_rect(BUILDING_FLOOR, rect, true, wall)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 14)), roof)
	draw_rect(Rect2(rect.position + Vector2(0, 14), Vector2(6, rect.size.y - 14)), wall.lightened(0.18))
	draw_rect(Rect2(rect.position,                                Vector2(rect.size.x, 3)), Color("#6a5030"))
	draw_rect(Rect2(rect.position + Vector2(0, rect.size.y - 3), Vector2(rect.size.x, 3)), Color("#6a5030"))
	draw_rect(Rect2(rect.position,                                Vector2(3, rect.size.y)), Color("#6a5030"))
	draw_rect(Rect2(rect.position + Vector2(rect.size.x - 3, 0),  Vector2(3, rect.size.y)), Color("#6a5030"))

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

	var dx := int(rect.position.x + rect.size.x * 0.44)
	var dy := int(rect.position.y + rect.size.y - 52.0)
	draw_rect(Rect2(dx, dy, 26, 52), Color("#8a5a28"))
	draw_rect(Rect2(dx,      dy,      26, 2),  Color("#6a5030"))
	draw_rect(Rect2(dx,      dy + 50, 26, 2),  Color("#6a5030"))
	draw_rect(Rect2(dx,      dy,       2, 52), Color("#6a5030"))
	draw_rect(Rect2(dx + 24, dy,       2, 52), Color("#6a5030"))
	draw_rect(Rect2(dx + 18, dy + 28,  4,  4), Color("#c8a030"))


func _draw_trees() -> void:
	for tree_pos in _tree_positions:
		var tp: Vector2 = tree_pos
		draw_texture_rect_region(
			TREE_TEXTURE,
			Rect2(tp + Vector2(-64, -80), Vector2(128, 96)),
			Rect2(0, 0, 64, 48)
		)
