extends Area2D

signal picked_up(waste_item: Node)

@export var waste_type := "plastic"
@export var display_name := "Plastico"
@export var display_color := Color("#5ec4ff")


func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 11, Color("#344034"))
	draw_circle(Vector2(0, -2), 8, display_color)
	draw_arc(Vector2.ZERO, 16, 0.0, TAU, 18, Color("#eef4df"), 2.0)


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		picked_up.emit(self)
