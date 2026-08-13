extends Control
## Tela inicial do EcoCat.
## O fundo e um "diorama" cozy desenhado por codigo, reaproveitando os mesmos
## sprites do jogo (gato, lixeiras, gemas de residuo, grama, arvores), para
## remeter diretamente ao EcoCat.
##
## - Sem save: mostra apenas "Iniciar Jogo".
## - Com save: mostra "Continuar" e "Reiniciar".

const MAIN_SCENE := "res://scenes/Main.tscn"

const _Sprites := preload("res://scripts/sprites.gd")
const TREE_TEXTURE := preload("res://textures/environment/tree.png")

const WORLD := Vector2(1600, 1000)
const GROUND_Y := 560.0

const TITLE_COLOR := Color("#33502f")
const SUBTITLE_COLOR := Color("#4a5d3f")

# Posicoes (sobre a grama) dos elementos do cenario.
var _houses := [
	{"x": 120.0, "w": 150.0, "h": 118.0, "wall": Color("#bfe0a0"), "roof": Color("#7fae5a")},
	{"x": 330.0, "w": 132.0, "h": 100.0, "wall": Color("#f0dc94"), "roof": Color("#d8a94e")},
	{"x": 1150.0, "w": 158.0, "h": 128.0, "wall": Color("#bcd8f0"), "roof": Color("#7aa8d8")},
	{"x": 1370.0, "w": 130.0, "h": 100.0, "wall": Color("#e9c7b0"), "roof": Color("#c78f6a")},
]

var _trees := [
	{"base": Vector2(70, 700), "size": Vector2(180, 210)},
	{"base": Vector2(470, 706), "size": Vector2(150, 178)},
	{"base": Vector2(1300, 704), "size": Vector2(150, 178)},
	{"base": Vector2(1540, 700), "size": Vector2(180, 210)},
]

var _bins := [
	{"x": 1040.0, "tint": Color("#5ec4ff")},  # plastico
	{"x": 1148.0, "tint": Color("#8ad879")},  # vidro
	{"x": 1256.0, "tint": Color("#f2d16b")},  # papel
]

var _gems := [
	{"pos": Vector2(560, 700), "tint": Color("#5ec4ff"), "phase": 0.0},
	{"pos": Vector2(980, 690), "tint": Color("#f2d16b"), "phase": 1.4},
	{"pos": Vector2(1210, 700), "tint": Color("#8ad879"), "phase": 2.6},
	{"pos": Vector2(690, 660), "tint": Color("#c8c8c8"), "phase": 3.7},
]

var _time := 0.0

# Dimensoes reais do controle (preenchem a janela) e escala de posicao em X.
var _w := WORLD.x
var _h := WORLD.y
var _sx := 1.0


func _ready() -> void:
	_build_ui()
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


# --------------------------------------------------------------------------- #
# Cenario (fundo)
# --------------------------------------------------------------------------- #

func _draw() -> void:
	_w = maxf(size.x, WORLD.x)
	_h = maxf(size.y, WORLD.y)
	_sx = _w / WORLD.x
	_draw_sky()
	_draw_sun()
	_draw_clouds()
	_draw_back_hill()
	_draw_ground()
	_draw_path()
	for house in _houses:
		_draw_house(house)
	for tree in _trees:
		_draw_tree(tree)
	for bin in _bins:
		_draw_bin(bin)
	_draw_cat()
	for gem in _gems:
		_draw_gem(gem)


func _draw_sky() -> void:
	var sky_top := Color("#bfe6f2")
	var sky_horizon := Color("#f3f4d2")
	var bands := 60
	var band_h := GROUND_Y / float(bands)
	for i in bands:
		var t := i / float(bands - 1)
		draw_rect(Rect2(0, i * band_h, _w, band_h + 1.0), sky_top.lerp(sky_horizon, t))


func _draw_sun() -> void:
	var sun_pos := Vector2(_w * 0.84, 150)
	var pulse := 0.5 + 0.5 * sin(_time * 1.4)
	draw_circle(sun_pos, 116 + pulse * 12.0, Color(1.0, 0.95, 0.72, 0.14))
	draw_circle(sun_pos, 90, Color(1.0, 0.96, 0.78, 0.30))
	draw_circle(sun_pos, 68, Color("#fff2bf"))


func _draw_clouds() -> void:
	_draw_cloud(Vector2(300 * _sx, 130), 1.0, 10.0)
	_draw_cloud(Vector2(820 * _sx, 90), 0.8, 6.0)
	_draw_cloud(Vector2(1180 * _sx, 200), 1.15, 14.0)


func _draw_cloud(center: Vector2, s: float, speed: float) -> void:
	var drift := fmod(_time * speed, _w + 400.0) - 200.0
	var c := Vector2(center.x + drift, center.y)
	var white := Color(1, 1, 1, 0.9)
	draw_circle(c + Vector2(-46, 6) * s, 30 * s, white)
	draw_circle(c + Vector2(0, -8) * s, 40 * s, white)
	draw_circle(c + Vector2(44, 6) * s, 32 * s, white)
	draw_circle(c + Vector2(6, 14) * s, 36 * s, white)


func _draw_back_hill() -> void:
	var pts := PackedVector2Array()
	var x := 0.0
	while x <= _w:
		pts.append(Vector2(x, 512.0 + sin(x * 0.0075 + 1.2) * 24.0))
		x += 40.0
	pts.append(Vector2(_w, GROUND_Y + 8.0))
	pts.append(Vector2(0, GROUND_Y + 8.0))
	draw_colored_polygon(pts, Color("#b7dd8b"))


func _draw_ground() -> void:
	draw_texture_rect(_Sprites.grass_tile(), Rect2(0, GROUND_Y, _w, _h - GROUND_Y), true)
	# Linha de horizonte suave.
	draw_rect(Rect2(0, GROUND_Y - 3.0, _w, 3.0), Color("#8fbf62"))
	draw_rect(Rect2(0, GROUND_Y, _w, 3.0), Color("#5f8c38"))


func _draw_path() -> void:
	# Caminho de terra em perspectiva, guiando o olhar para o horizonte.
	var cx := _w * 0.5
	var top := GROUND_Y + 6.0
	var pts := PackedVector2Array([
		Vector2(cx - 100, _h), Vector2(cx + 100, _h),
		Vector2(cx + 38, top), Vector2(cx - 38, top),
	])
	draw_colored_polygon(pts, Color("#c9a05c"))
	# Bordas.
	draw_line(Vector2(cx - 100, _h), Vector2(cx - 38, top), Color("#a67f42"), 4.0)
	draw_line(Vector2(cx + 100, _h), Vector2(cx + 38, top), Color("#a67f42"), 4.0)
	# Tracejado central.
	var steps := 7
	for i in steps:
		var t := i / float(steps)
		var w: float = lerp(70.0, 6.0, t)
		var y: float = lerp(_h - 20.0, top + 10.0, t)
		var dash_h: float = lerp(26.0, 6.0, t)
		draw_rect(Rect2(cx - w * 0.06, y, max(6.0, w * 0.12), dash_h), Color("#e6c877", 0.7))


func _draw_house(house: Dictionary) -> void:
	var w: float = house["w"]
	var h: float = house["h"]
	var base_y := GROUND_Y + 44.0
	var x: float = house["x"] * _sx
	var top := base_y - h
	var wall: Color = house["wall"]
	var roof: Color = house["roof"]

	# Parede.
	draw_rect(Rect2(x, top, w, h), wall)
	# Telhado (triangulo).
	draw_colored_polygon(PackedVector2Array([
		Vector2(x - 8, top), Vector2(x + w + 8, top), Vector2(x + w * 0.5, top - 44),
	]), roof)
	# Porta.
	var dw := w * 0.22
	draw_rect(Rect2(x + w * 0.5 - dw * 0.5, base_y - h * 0.45, dw, h * 0.45), Color("#8a5a30"))
	# Janelas.
	var win := Color("#eaf6ff")
	draw_rect(Rect2(x + w * 0.16, top + h * 0.28, w * 0.2, h * 0.22), win)
	draw_rect(Rect2(x + w * 0.64, top + h * 0.28, w * 0.2, h * 0.22), win)
	# Contorno inferior.
	draw_rect(Rect2(x, base_y - 3, w, 3), Color("#6a5030"))


func _draw_tree(tree: Dictionary) -> void:
	var base: Vector2 = tree["base"]
	base.x *= _sx
	var size: Vector2 = tree["size"]
	draw_texture_rect_region(
		TREE_TEXTURE,
		Rect2(base - Vector2(size.x * 0.5, size.y), size),
		Rect2(0, 0, 64, 48)
	)


func _draw_bin(bin: Dictionary) -> void:
	var tex := _Sprites.recycle_bin()
	var size := Vector2(86, 108)
	var base_y := _h - 94.0
	var x: float = bin["x"] * _sx
	var rect := Rect2(Vector2(x, base_y - size.y), size)
	# Sombra.
	draw_circle(Vector2(x + size.x * 0.5, base_y), 34, Color(0, 0, 0, 0.10))
	draw_texture_rect(tex, rect, false, bin["tint"])


func _draw_cat() -> void:
	var tex := _Sprites.cat()
	var size := Vector2(176, 176)
	var bob := sin(_time * 2.0) * 6.0
	var base := Vector2(720 * _sx, (_h - 88.0) + bob)
	# Sombra.
	draw_circle(Vector2(base.x, _h - 84.0), 60, Color(0, 0, 0, 0.12))
	draw_texture_rect(tex, Rect2(base - Vector2(size.x * 0.5, size.y), size), false)


func _draw_gem(gem: Dictionary) -> void:
	var tex := _Sprites.waste_gem()
	var size := Vector2(46, 46)
	var pos: Vector2 = gem["pos"]
	pos.x *= _sx
	var bob := sin(_time * 2.2 + gem["phase"]) * 10.0
	var center := Vector2(pos.x, pos.y + bob)
	# Brilho.
	draw_circle(center, 30, Color(gem["tint"].r, gem["tint"].g, gem["tint"].b, 0.20))
	draw_texture_rect(tex, Rect2(center - size * 0.5, size), false, gem["tint"])


# --------------------------------------------------------------------------- #
# Interface (titulo, botoes)
# --------------------------------------------------------------------------- #

func _build_ui() -> void:
	# Faixa superior que centraliza o cartao do menu.
	var top_band := Control.new()
	top_band.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_band.offset_left = 0
	top_band.offset_right = 0
	top_band.offset_top = 48
	top_band.offset_bottom = 500
	top_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_band)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_band.add_child(center)

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _card_style())
	center.add_child(card)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 14)
	card.add_child(column)

	var title := Label.new()
	title.text = "EcoCat"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", TITLE_COLOR)
	title.add_theme_font_size_override("font_size", 92)
	column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Colete, separe e deixe a cidade mais sustentavel"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", SUBTITLE_COLOR)
	subtitle.add_theme_font_size_override("font_size", 22)
	column.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	column.add_child(spacer)

	if SaveSystem.has_save():
		var continue_button := _make_button("Continuar")
		continue_button.pressed.connect(_on_continue_pressed)
		column.add_child(continue_button)

		var restart_button := _make_button("Reiniciar")
		restart_button.pressed.connect(_on_restart_pressed)
		column.add_child(restart_button)

		continue_button.grab_focus()
	else:
		var start_button := _make_button("Iniciar Jogo")
		start_button.pressed.connect(_on_start_pressed)
		column.add_child(start_button)

		start_button.grab_focus()

	# Dica no rodape.
	var hint := Label.new()
	hint.text = "Mover: WASD ou setas   •   ESC volta para este menu"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color("#33502f"))
	hint.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.6))
	hint.add_theme_font_size_override("font_size", 18)
	hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_bottom = -22
	hint.offset_top = -52
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)


func _card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.97, 0.99, 0.92, 0.92)
	style.set_corner_radius_all(26)
	style.border_color = Color("#7fa85c")
	style.set_border_width_all(4)
	style.set_content_margin_all(40)
	style.content_margin_left = 56
	style.content_margin_right = 56
	style.shadow_color = Color(0, 0, 0, 0.18)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 8)
	return style


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(340, 66)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 28)
	button.add_theme_color_override("font_color", Color("#2c451f"))
	button.add_theme_color_override("font_hover_color", Color("#1c3014"))
	button.add_theme_color_override("font_pressed_color", Color("#1c3014"))
	button.add_theme_color_override("font_focus_color", Color("#1c3014"))
	button.add_theme_stylebox_override("normal", _button_style(Color("#9fd57e")))
	button.add_theme_stylebox_override("hover", _button_style(Color("#b6e695")))
	button.add_theme_stylebox_override("pressed", _button_style(Color("#8ac368")))
	button.add_theme_stylebox_override("focus", _button_style(Color("#b6e695")))
	return button


func _button_style(bg_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(16)
	style.set_content_margin_all(12)
	style.border_color = Color("#5f8c3c")
	style.set_border_width_all(3)
	style.shadow_color = Color(0, 0, 0, 0.12)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	return style


# --------------------------------------------------------------------------- #
# Acoes
# --------------------------------------------------------------------------- #

func _on_start_pressed() -> void:
	_start_new_game()


func _on_continue_pressed() -> void:
	SaveSystem.should_load_save = true
	get_tree().change_scene_to_file(MAIN_SCENE)


func _on_restart_pressed() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Reiniciar jogo"
	dialog.dialog_text = "Tem certeza? Isso vai apagar seu progresso salvo."
	dialog.ok_button_text = "Reiniciar"
	dialog.cancel_button_text = "Cancelar"
	dialog.confirmed.connect(_start_new_game)
	add_child(dialog)
	dialog.popup_centered()


func _start_new_game() -> void:
	SaveSystem.clear_save()
	SaveSystem.should_load_save = false
	get_tree().change_scene_to_file(MAIN_SCENE)
