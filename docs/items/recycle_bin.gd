extends Area2D
## Lixeira da coleta seletiva. Nao descarta sozinha ao encostar: o jogador
## escolhe o item na mao e aperta o botao de descarte perto dela (main.gd).
## Assim um erro e uma decisao, e nao um esbarrao na lixeira vizinha.

const _Sprites := preload("res://scripts/sprites.gd")

@export var bin_type := "plastic"
@export var display_name := "plastico"
@export var display_color := Color.WHITE

var _sprite: Sprite2D
var _name_label: Label
var _prompt: Label
var _focused := false
var _t := 0.0


func _ready() -> void:
	collision_layer = 8
	collision_mask = 2
	add_to_group("recycle_bins")

	_sprite = Sprite2D.new()
	_sprite.texture = _Sprites.recycle_bin()
	_sprite.centered = false
	_sprite.modulate = display_color
	add_child(_sprite)

	# Nome embaixo da lixeira: ajuda quem ainda nao decorou as cores (e daltonicos).
	_name_label = _make_label(display_name.to_upper(), 13)
	_name_label.position = Vector2(-21, 44)
	_name_label.z_index = 0  # fica por baixo do gato quando ele para em frente
	add_child(_name_label)

	_prompt = _make_label("", 15)
	_prompt.position = Vector2(-96, -30)  # 230 de largura, centrado no x=19 da lixeira
	_prompt.add_theme_color_override("font_color", Color("#7a3b00"))
	_prompt.visible = false
	add_child(_prompt)


func _process(delta: float) -> void:
	if not _focused:
		return
	_t += delta
	_prompt.position.y = -30.0 + sin(_t * 6.0) * 2.5


func _make_label(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(80 if size < 15 else 230, 0)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("#20301f"))
	label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.92))
	label.add_theme_constant_override("outline_size", 5)
	label.z_index = 30
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


## Destaca a lixeira mais proxima do gato e mostra como descartar nela
## (o nome vai junto: o gato cobre o rotulo de baixo quando para ali).
func set_focus(value: bool, action_text: String) -> void:
	_focused = value
	_t = 0.0
	if _prompt != null:
		_prompt.text = "%s no %s" % [action_text, display_name.to_upper()] if value else ""
		_prompt.visible = value
	if _sprite != null:
		_sprite.modulate = display_color.lightened(0.22) if value else display_color


func react() -> void:
	# Saltinho + brilho quando recebe o lixo certo.
	if _sprite == null:
		return
	var tween := create_tween()
	tween.tween_property(_sprite, "position:y", -8.0, 0.08).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(_sprite, "position:y", 0.0, 0.16).set_trans(Tween.TRANS_BOUNCE)
	var flash := create_tween()
	flash.tween_property(_sprite, "modulate", display_color.lightened(0.4), 0.08)
	flash.tween_property(_sprite, "modulate", _rest_color(), 0.18)


func reject() -> void:
	# Tremida + vermelho quando recebe o lixo errado (contaminacao).
	if _sprite == null:
		return
	var shake := create_tween()
	for dx in [-6.0, 6.0, -4.0, 4.0, 0.0]:
		shake.tween_property(_sprite, "position:x", dx, 0.05)
	var flash := create_tween()
	flash.tween_property(_sprite, "modulate", Color("#ff4a3a"), 0.06)
	flash.tween_property(_sprite, "modulate", _rest_color(), 0.35)


func _rest_color() -> Color:
	return display_color.lightened(0.22) if _focused else display_color
