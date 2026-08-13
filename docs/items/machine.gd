extends Node2D
## Coletora automatica da Startup EcoCat (a partir da Fase 3).
## Recolhe o residuo mais proximo do chao e leva ate a SACOLA central
## (nao separa nem recicla — isso e feito pelo gato ou pela esteira+separadora).
## Niveis maiores = mais rapida e com menos espera.

signal deposited(item)

var level := 1
var home := Vector2.ZERO          # ponto da sacola onde larga o lixo
var body_color := Color("#8fb8d8")
var active := true

var _target: Node2D = null
var _carry: Dictionary = {}
var _cooldown := 0.0


func setup(p_level: int, p_home: Vector2, p_color: Color) -> void:
	level = p_level
	home = p_home
	position = p_home
	body_color = p_color
	queue_redraw()


func _ready() -> void:
	_cooldown = _cooldown_time()
	queue_redraw()


func _speed() -> float:
	return 110.0 + float(level) * 34.0


func _cooldown_time() -> float:
	return maxf(0.5, 2.4 - float(level) * 0.4)


func _physics_process(delta: float) -> void:
	if not active:
		return

	# Carregando um item: volta para a sacola e deposita.
	if not _carry.is_empty():
		if _step_to(home, delta):
			deposited.emit(_carry)
			_carry = {}
			_cooldown = _cooldown_time()
			queue_redraw()
		return

	# Indo pegar um alvo.
	if _target != null and is_instance_valid(_target):
		if _step_to((_target as Node2D).position, delta):
			if is_instance_valid(_target):
				_carry = {
					"type": _target.get("waste_type"),
					"name": _target.get("display_name"),
					"color": _target.get("display_color"),
					"value": int(_target.get("value")),
				}
				_target.queue_free()
			_target = null
			queue_redraw()
		return

	# Ocioso: volta para casa e espera.
	_step_to(home, delta)
	_cooldown -= delta
	if _cooldown <= 0.0:
		_acquire_target()


func _acquire_target() -> void:
	var best: Node2D = null
	var best_d := INF
	for raw in get_tree().get_nodes_in_group("waste_items"):
		var wnode := raw as Node2D
		if wnode == null or not is_instance_valid(wnode):
			continue
		if bool(wnode.get("claimed")):
			continue
		var d := position.distance_to(wnode.position)
		if d < best_d:
			best_d = d
			best = wnode
	if best != null:
		best.set("claimed", true)
		_target = best


func _step_to(dest: Vector2, delta: float) -> bool:
	var to := dest - position
	var step := _speed() * delta
	if to.length() <= step:
		position = dest
		return true
	position += to.normalized() * step
	return false


func _draw() -> void:
	var outline := Color("#2c2418")
	draw_rect(Rect2(-16, 6, 32, 10), outline)
	draw_rect(Rect2(-13, 8, 8, 6), Color("#4a4a4a"))
	draw_rect(Rect2(5, 8, 8, 6), Color("#4a4a4a"))
	draw_rect(Rect2(-15, -16, 30, 24), outline)
	draw_rect(Rect2(-13, -14, 26, 20), body_color)
	draw_rect(Rect2(-9, -10, 18, 7), Color("#eaf6ff"))
	draw_rect(Rect2(-2, -24, 4, 8), outline)
	draw_circle(Vector2(0, -25), 3, Color("#f2d16b"))
	if not _carry.is_empty():
		draw_circle(Vector2(0, -2), 5, _carry.get("color", Color("#8ad879")))
