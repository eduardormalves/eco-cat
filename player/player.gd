extends CharacterBody2D

const _Sprites := preload("res://scripts/sprites.gd")

@export var speed := 190.0
@export var movement_bounds := Rect2(Vector2(40, 40), Vector2(1520, 920))

var _sprite: Sprite2D


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1

	_sprite = Sprite2D.new()
	_sprite.texture = _Sprites.cat()
	_sprite.offset = Vector2(0, -8)
	add_child(_sprite)


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()

	position = position.clamp(movement_bounds.position, movement_bounds.position + movement_bounds.size)

	if direction != Vector2.ZERO and direction.x != 0:
		_sprite.flip_h = direction.x < 0
