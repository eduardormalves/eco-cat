extends Area2D

const _Sprites := preload("res://scripts/sprites.gd")

signal discard_requested(recycle_bin: Node)

@export var bin_type := "plastic"
@export var display_name := "plastico"
@export var display_color := Color.WHITE

var _sprite: Sprite2D


func _ready() -> void:
	collision_layer = 8
	collision_mask = 2
	body_entered.connect(_on_body_entered)

	_sprite = Sprite2D.new()
	_sprite.texture = _Sprites.recycle_bin()
	_sprite.centered = false
	_sprite.modulate = display_color
	add_child(_sprite)


func react() -> void:
	# Saltinho + brilho quando recebe o lixo certo.
	if _sprite == null:
		return
	var tween := create_tween()
	tween.tween_property(_sprite, "position:y", -8.0, 0.08).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(_sprite, "position:y", 0.0, 0.16).set_trans(Tween.TRANS_BOUNCE)
	var flash := create_tween()
	flash.tween_property(_sprite, "modulate", display_color.lightened(0.4), 0.08)
	flash.tween_property(_sprite, "modulate", display_color, 0.18)


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		discard_requested.emit(self)
