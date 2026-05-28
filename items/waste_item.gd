extends Area2D

const _Sprites := preload("res://scripts/sprites.gd")

signal picked_up(waste_item: Node)

@export var waste_type := "plastic"
@export var display_name := "Plastico"
@export var display_color := Color("#5ec4ff")


func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	body_entered.connect(_on_body_entered)

	var sprite := Sprite2D.new()
	sprite.texture = _Sprites.waste_gem()
	sprite.modulate = display_color
	add_child(sprite)


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		picked_up.emit(self)
