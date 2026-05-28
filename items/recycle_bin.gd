extends Area2D

const _Sprites := preload("res://scripts/sprites.gd")

signal discard_requested(recycle_bin: Node)

@export var bin_type := "plastic"
@export var display_name := "plastico"
@export var display_color := Color.WHITE


func _ready() -> void:
	collision_layer = 8
	collision_mask = 2
	body_entered.connect(_on_body_entered)

	var sprite := Sprite2D.new()
	sprite.texture = _Sprites.recycle_bin()
	sprite.centered = false
	sprite.modulate = display_color
	add_child(sprite)


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		discard_requested.emit(self)
