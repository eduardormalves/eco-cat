extends Control
## Controles de toque para quando o jogo e aberto no celular/tablet.
##
## - Manche virtual (canto inferior esquerdo) para locomover o gato: da direcao
##   analogica, entao anda tambem na diagonal.
## - Botoes de atalho (canto inferior direito) para as telas que no PC ficam
##   no teclado (G/M/ESC), que num celular nao existem.
##
## Os tamanhos sao em unidades do viewport base (1600x1000): como o stretch e
## "viewport", tudo escala junto com a tela do aparelho.

signal guide_pressed
signal map_pressed
signal pause_pressed

const STICK_BOX := 640.0
const STICK_PAD := 56.0
const BASE_RADIUS := 260.0
const KNOB_RADIUS := 104.0
const DEAD_ZONE := 0.16

const _POINTER_NONE := -1
const _POINTER_MOUSE := -2

## Direcao normalizada (0..1) pedida pelo manche. Lida por scripts/main.gd.
var direction := Vector2.ZERO

var _stick: Control
var _center := Vector2.ZERO
var _knob := Vector2.ZERO
var _pointer := _POINTER_NONE


## Verdadeiro quando o jogo esta rodando num aparelho de toque (celular nativo,
## navegador em Android/iOS ou qualquer tela sensivel ao toque).
static func is_available() -> bool:
	# Permite forcar os controles no PC para testar: godot ... -- --touch-ui
	if OS.get_cmdline_user_args().has("--touch-ui"):
		return true
	return OS.has_feature("mobile") \
		or OS.has_feature("web_android") \
		or OS.has_feature("web_ios") \
		or DisplayServer.is_touchscreen_available()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# So o manche e os botoes capturam toque; o resto da tela segue livre.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_stick()
	_build_buttons()


## Solta o manche (chamado quando o jogo pausa ou abre uma tela por cima).
func release() -> void:
	_pointer = _POINTER_NONE
	_knob = _center
	direction = Vector2.ZERO
	if _stick != null:
		_stick.queue_redraw()


# --------------------------------------------------------------------------- #
# Manche
# --------------------------------------------------------------------------- #

func _build_stick() -> void:
	_stick = Control.new()
	_stick.name = "Stick"
	_stick.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_stick.offset_left = STICK_PAD
	_stick.offset_top = -(STICK_BOX + STICK_PAD)
	_stick.offset_right = STICK_PAD + STICK_BOX
	_stick.offset_bottom = -STICK_PAD
	_stick.mouse_filter = Control.MOUSE_FILTER_STOP
	_stick.draw.connect(_draw_stick)
	_stick.gui_input.connect(_on_stick_gui_input)
	_stick.resized.connect(_recenter)
	add_child(_stick)
	_recenter()


func _recenter() -> void:
	_center = _stick.size * 0.5
	_knob = _center
	_stick.queue_redraw()


func _draw_stick() -> void:
	var active := _pointer != _POINTER_NONE
	# Base.
	_stick.draw_circle(_center + Vector2(0, 8), BASE_RADIUS, Color(0, 0, 0, 0.14))
	_stick.draw_circle(_center, BASE_RADIUS, Color(0.97, 0.99, 0.92, 0.34 if active else 0.26))
	_stick.draw_arc(_center, BASE_RADIUS, 0.0, TAU, 72, Color("#5f8c3c", 0.85), 6.0, true)
	# Setas de referencia nas quatro direcoes.
	for dir in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		var tip: Vector2 = _center + dir * (BASE_RADIUS - 34.0)
		var side: Vector2 = Vector2(dir.y, dir.x) * 22.0
		_stick.draw_colored_polygon(
			PackedVector2Array([tip, tip - dir * 34.0 + side, tip - dir * 34.0 - side]),
			Color("#3f6a28", 0.5)
		)
	# Manopla.
	_stick.draw_circle(_knob + Vector2(0, 6), KNOB_RADIUS, Color(0, 0, 0, 0.18))
	_stick.draw_circle(_knob, KNOB_RADIUS, Color("#b6e695" if active else "#9fd57e"))
	_stick.draw_arc(_knob, KNOB_RADIUS, 0.0, TAU, 48, Color("#3f6a28", 0.9), 5.0, true)


func _on_stick_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if _pointer == _POINTER_NONE:
				_pointer = event.index
				_move_knob(event.position)
		elif _pointer == event.index:
			release()
		_stick.accept_event()
	elif event is InputEventScreenDrag:
		if _pointer == event.index:
			_move_knob(event.position)
			_stick.accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# Tambem responde ao mouse (util para testar no PC).
		if event.pressed:
			if _pointer == _POINTER_NONE:
				_pointer = _POINTER_MOUSE
				_move_knob(event.position)
		elif _pointer == _POINTER_MOUSE:
			release()
		_stick.accept_event()
	elif event is InputEventMouseMotion and _pointer == _POINTER_MOUSE:
		_move_knob(event.position)
		_stick.accept_event()


func _move_knob(local_pos: Vector2) -> void:
	var offset := (local_pos - _center).limit_length(BASE_RADIUS)
	_knob = _center + offset
	var raw := offset / BASE_RADIUS
	var strength := raw.length()
	if strength < DEAD_ZONE:
		direction = Vector2.ZERO
	else:
		# Reescala para a zona morta nao "roubar" velocidade do gato.
		direction = raw.normalized() * minf((strength - DEAD_ZONE) / (1.0 - DEAD_ZONE), 1.0)
	_stick.queue_redraw()


# --------------------------------------------------------------------------- #
# Atalhos (equivalentes as teclas G / M / ESC)
# --------------------------------------------------------------------------- #

func _build_buttons() -> void:
	var column := VBoxContainer.new()
	column.name = "Actions"
	column.alignment = BoxContainer.ALIGNMENT_END
	column.add_theme_constant_override("separation", 22)
	column.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	column.offset_left = -(400.0 + STICK_PAD)
	column.offset_top = -(3.0 * 140.0 + 2.0 * 22.0 + STICK_PAD)
	column.offset_right = -STICK_PAD
	column.offset_bottom = -STICK_PAD
	add_child(column)

	column.add_child(_action_button("Guia", func() -> void: guide_pressed.emit()))
	column.add_child(_action_button("Mapa", func() -> void: map_pressed.emit()))
	column.add_child(_action_button("Pausa", func() -> void: pause_pressed.emit()))


func _action_button(text: String, on_press: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(400, 140)
	button.add_theme_font_size_override("font_size", 48)
	button.add_theme_color_override("font_color", Color("#2c451f"))
	button.add_theme_color_override("font_hover_color", Color("#1c3014"))
	button.add_theme_color_override("font_pressed_color", Color("#1c3014"))
	button.add_theme_stylebox_override("normal", _style(Color("#9fd57e", 0.92)))
	button.add_theme_stylebox_override("hover", _style(Color("#b6e695", 0.95)))
	button.add_theme_stylebox_override("pressed", _style(Color("#8ac368", 0.95)))
	button.pressed.connect(on_press)
	return button


func _style(bg_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(28)
	style.set_content_margin_all(16)
	style.border_color = Color("#5f8c3c")
	style.set_border_width_all(5)
	return style
