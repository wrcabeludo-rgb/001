class_name Player
extends CharacterBody2D
## Stage 0 placeholder hero: a grey box that runs and jumps.
## Real movement (coyote time, wall jump, dash...) comes in stage 1.

const SIZE := Vector2(48, 96)
const LAYER_WORLD := 1
const LAYER_PLAYERS := 2

@export var run_speed := 420.0
@export var jump_velocity := -900.0
@export var gravity := 2600.0
@export var max_fall_speed := 1400.0
## Releasing jump early multiplies upward speed by this, for a shorter hop.
@export var jump_cut := 0.5

var slot := 0
var input: PlayerInput
var color := Color.GRAY


func setup(p_slot: int, p_input: PlayerInput, p_color: Color) -> void:
	slot = p_slot
	input = p_input
	color = p_color


func _ready() -> void:
	# Players stand on the world but pass through each other.
	collision_layer = LAYER_PLAYERS
	collision_mask = LAYER_WORLD

	var shape := RectangleShape2D.new()
	shape.size = SIZE
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)

	var body := ColorRect.new()
	body.size = SIZE
	body.position = -SIZE / 2
	body.color = color
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(body)

	var tag := Label.new()
	tag.text = "P%d" % (slot + 1)
	tag.add_theme_font_size_override("font_size", 24)
	tag.position = Vector2(-16, -SIZE.y / 2 - 36)
	add_child(tag)


func _physics_process(delta: float) -> void:
	if input == null:
		return

	velocity.x = input.get_move().x * run_speed

	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)
	if is_on_floor() and input.just_pressed("jump"):
		velocity.y = jump_velocity
	if input.just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut

	move_and_slide()
