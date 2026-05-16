extends CharacterBody2D

@export var speed := 190.0
@export var movement_bounds := Rect2(Vector2(40, 40), Vector2(1520, 920))

var last_direction := Vector2.DOWN


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()

	position = position.clamp(movement_bounds.position, movement_bounds.position + movement_bounds.size)

	if direction != Vector2.ZERO:
		last_direction = direction
		queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 15, Color("#f2a766"))
	draw_circle(Vector2(0, -17), 13, Color("#f7b97c"))
	draw_polygon([
		Vector2(-10, -27),
		Vector2(-3, -42),
		Vector2(4, -27),
	], [Color("#f7b97c")])
	draw_polygon([
		Vector2(5, -27),
		Vector2(13, -41),
		Vector2(15, -24),
	], [Color("#f7b97c")])
	draw_circle(Vector2(-5, -20), 2, Color("#26342e"))
	draw_circle(Vector2(6, -20), 2, Color("#26342e"))
	draw_rect(Rect2(Vector2(-15, -4), Vector2(30, 6)), Color("#3fa65a"))
	draw_rect(Rect2(Vector2(11, 0), Vector2(9, 18)), Color("#5d8b69"))
	draw_line(Vector2.ZERO, last_direction.normalized() * 22.0, Color("#2f5f45"), 2.0)
