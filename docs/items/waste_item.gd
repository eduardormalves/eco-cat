extends Area2D

const _Sprites := preload("res://scripts/sprites.gd")

signal picked_up(waste_item: Node)

@export var waste_type := "plastic"
@export var display_name := "Plastico"
@export var display_color := Color("#5ec4ff")
@export var value := 10

# Marcado por uma maquina que ja escolheu este residuo como alvo,
# para duas maquinas nao correrem para o mesmo item.
var claimed := false

var _sprite: Sprite2D
var _phase := 0.0
var _t := 0.0


func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	add_to_group("waste_items")
	body_entered.connect(_on_body_entered)

	_sprite = Sprite2D.new()
	_sprite.texture = _Sprites.waste_gem()
	_sprite.modulate = display_color
	add_child(_sprite)

	_phase = position.x * 0.02 + position.y * 0.02


func _process(delta: float) -> void:
	_t += delta
	if _sprite != null:
		_sprite.position.y = sin(_t * 3.0 + _phase) * 3.5
		var s := 1.0 + sin(_t * 3.0 + _phase) * 0.06
		_sprite.scale = Vector2(s, s)


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		picked_up.emit(self)
