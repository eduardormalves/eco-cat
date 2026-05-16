extends Area2D

signal discard_requested(recycle_bin: Node)

@export var bin_type := "plastic"
@export var display_name := "plastico"


func _ready() -> void:
	collision_layer = 8
	collision_mask = 2
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		discard_requested.emit(self)
