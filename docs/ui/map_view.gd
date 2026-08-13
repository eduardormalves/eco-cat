extends Control
## Mapa desenhado das cidades do EcoCat (usado no minimapa).
## Desenha uma paisagem com rotas conectando as cidades, um pino por cidade
## (colorido conforme o status) e uma animacao do gato viajando pela rota.

signal city_selected(index)

const _Sprites := preload("res://scripts/sprites.gd")

const MAP_SIZE := Vector2(980, 540)
const LAYOUT := [
	Vector2(150, 400), Vector2(330, 250), Vector2(510, 390),
	Vector2(680, 240), Vector2(830, 380), Vector2(890, 180),
]

# Cada entrada: {name:String, color:Color, status:String, rate:float}
var cities: Array = []
var travel_enabled := false
var _hover := -1

var _appear := 1.0
var _anim_t := 0.0

var _traveling := false
var _travel_path: PackedVector2Array = PackedVector2Array()
var _travel_t := 0.0
var _travel_done: Callable


func _ready() -> void:
	custom_minimum_size = MAP_SIZE
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)


func _process(delta: float) -> void:
	_anim_t += delta
	if _traveling:
		queue_redraw()


func set_data(new_cities: Array, can_travel: bool) -> void:
	cities = new_cities
	travel_enabled = can_travel
	# Animacao de entrada dos pinos.
	_appear = 0.0
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_appear, 0.0, 1.0, 0.45)
	queue_redraw()


func _set_appear(v: float) -> void:
	_appear = v
	queue_redraw()


func _set_travel_t(v: float) -> void:
	_travel_t = v


func travel(from_index: int, to_index: int, on_done: Callable) -> void:
	_travel_path = PackedVector2Array()
	if to_index >= from_index:
		for i in range(from_index, to_index + 1):
			_travel_path.append(_pin_pos(i))
	else:
		for i in range(from_index, to_index - 1, -1):
			_travel_path.append(_pin_pos(i))
	if _travel_path.size() < 2:
		on_done.call()
		return

	_travel_done = on_done
	_travel_t = 0.0
	_traveling = true
	var duration := maxf(0.9, 0.7 * float(_travel_path.size() - 1))
	var tween := create_tween()
	tween.tween_method(_set_travel_t, 0.0, 1.0, duration)
	tween.tween_callback(_finish_travel)


func _finish_travel() -> void:
	_traveling = false
	var cb := _travel_done
	_travel_done = Callable()
	if cb.is_valid():
		cb.call()


func _pin_pos(i: int) -> Vector2:
	return LAYOUT[i % LAYOUT.size()]


func _path_point(t: float) -> Vector2:
	if _travel_path.size() == 0:
		return Vector2.ZERO
	if _travel_path.size() == 1:
		return _travel_path[0]
	var lens: Array = []
	var total := 0.0
	for i in range(_travel_path.size() - 1):
		var l := _travel_path[i].distance_to(_travel_path[i + 1])
		lens.append(l)
		total += l
	var target := clampf(t, 0.0, 1.0) * total
	var acc := 0.0
	for i in range(lens.size()):
		if acc + lens[i] >= target:
			var lt: float = (target - acc) / maxf(0.001, lens[i])
			return _travel_path[i].lerp(_travel_path[i + 1], lt)
		acc += lens[i]
	return _travel_path[_travel_path.size() - 1]


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, MAP_SIZE)
	draw_rect(r, Color("#a9d4e0"))
	_fill_round(r.grow(-16), Color("#cfe6ac"), 22.0)
	for spot in [Vector2(90, 120), Vector2(430, 120), Vector2(620, 430), Vector2(240, 470), Vector2(760, 110)]:
		draw_circle(spot, 26, Color("#a8cf7e"))
	draw_circle(Vector2(200, 200), 30, Color("#8fc3d8"))
	draw_circle(Vector2(720, 470), 26, Color("#8fc3d8"))

	for i in range(cities.size() - 1):
		_draw_route(_pin_pos(i), _pin_pos(i + 1))

	for i in cities.size():
		_draw_city(i)

	if _traveling:
		_draw_travel_cat()


func _fill_round(rect: Rect2, color: Color, radius: float) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(int(radius))
	sb.border_color = Color("#8fb26a")
	sb.set_border_width_all(3)
	draw_style_box(sb, rect)


func _draw_route(a: Vector2, b: Vector2) -> void:
	draw_line(a, b, Color("#c8a46a"), 12.0)
	draw_line(a, b, Color("#e6cd94"), 6.0)
	var dir := (b - a).normalized()
	var dist := a.distance_to(b)
	var d := 10.0
	while d < dist - 10.0:
		draw_circle(a + dir * d, 2.0, Color("#a67f42"))
		d += 16.0


func _draw_city(i: int) -> void:
	var pos := _pin_pos(i)
	var c: Dictionary = cities[i]
	var status: String = c["status"]

	var ring := Color("#9aa0a0")
	match status:
		"done": ring = Color("#3f8f4a")
		"current": ring = Color("#d8a72e")
		"available": ring = Color("#2b8fd6") if travel_enabled else Color("#9aa0a0")

	var hovered := i == _hover and travel_enabled and status == "available"
	var base_r := 27.0 if hovered else 24.0
	# Pulso suave nas cidades disponiveis; "respiro" na atual.
	if status == "available" and travel_enabled:
		base_r += sin(_anim_t * 4.0 + float(i)) * 1.5
	elif status == "current":
		base_r += sin(_anim_t * 3.0) * 1.2
	var radius := base_r * _appear

	draw_circle(pos + Vector2(0, 5), radius, Color(0, 0, 0, 0.18))
	draw_circle(pos, radius, ring)
	draw_circle(pos, maxf(1.0, radius - 6.0), c["color"])
	draw_rect(Rect2(pos + Vector2(-8, -2), Vector2(16, 12)), Color(1, 1, 1, 0.9 * _appear))
	draw_colored_polygon(PackedVector2Array([
		pos + Vector2(-10, -2), pos + Vector2(10, -2), pos + Vector2(0, -12),
	]), Color(1, 1, 1, 0.95 * _appear))

	var font := ThemeDB.fallback_font
	var text_col := Color("#25401d", _appear)
	var sub_col := Color("#4a5d3f", _appear)
	draw_string(font, pos + Vector2(-70, 24.0 + 20.0), c["name"],
		HORIZONTAL_ALIGNMENT_CENTER, 140, 20, text_col)
	var sub := ""
	match status:
		"done": sub = "Zerada  +%.1f/s" % float(c["rate"])
		"current": sub = "Voce esta aqui"
		"available": sub = "Clique para vir" if travel_enabled else "Bloqueada"
	draw_string(font, pos + Vector2(-70, 24.0 + 40.0), sub,
		HORIZONTAL_ALIGNMENT_CENTER, 140, 15, sub_col)


func _draw_travel_cat() -> void:
	var pos := _path_point(_travel_t)
	var bob := absf(sin(_travel_t * 34.0)) * 5.0
	var size := Vector2(46, 46)
	# Poeirinha atras.
	draw_circle(pos + Vector2(0, 6), 14, Color(0, 0, 0, 0.15))
	draw_texture_rect(_Sprites.cat(), Rect2(pos - Vector2(size.x * 0.5, size.y - 6 + bob), size), false)


func _gui_input(event: InputEvent) -> void:
	if _traveling:
		return
	if event is InputEventMouseMotion:
		var prev := _hover
		_hover = _city_at(event.position)
		if _hover != prev:
			queue_redraw()
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var idx := _city_at(event.position)
		if idx >= 0 and travel_enabled and cities[idx]["status"] == "available":
			city_selected.emit(idx)


func _city_at(point: Vector2) -> int:
	for i in cities.size():
		if point.distance_to(_pin_pos(i)) <= 28.0:
			return i
	return -1
