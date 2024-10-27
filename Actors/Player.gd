#movement.gd
# This script extends CharacterBody2D, which is a built-in Godot class for characters that can move and collide with the environment
extends CharacterBody2D

# Constant for the character's movement speed
const SPEED = 150.0

# @onready means this variable will be initialized when the node is ready
# It gets a reference to the AnimatedSprite2D node, which is a child of this node
@onready var animated_sprite = $AnimatedSprite2D

# Variable to keep track of the last direction the character was facing
var last_direction = Vector2.DOWN  # Default facing down

# This function is called every physics frame (typically 60 times per second)
func _physics_process(_delta: float) -> void:
	# Initialize a Vector2 to store the input direction
	var input_direction = Vector2.ZERO
	
	# Get the horizontal input (-1 for left, 1 for right, 0 for no input)
	input_direction.x = Input.get_axis("move_left", "move_right")
	# Get the vertical input (-1 for up, 1 for down, 0 for no input)
	input_direction.y = Input.get_axis("move_up", "move_down")
	
	# Check if there's any input
	if input_direction != Vector2.ZERO:
		# Normalize the input direction to ensure diagonal movement isn't faster
		last_direction = input_direction.normalized()
		# Set the velocity based on the input direction and speed
		velocity = last_direction * SPEED
		# Play the walking animation
		play_walk_animation(last_direction)
	else:
		# If there's no input, stop the character
		velocity = Vector2.ZERO
		# Play the idle animation
		play_idle_animation()

	# Apply the movement
	move_and_slide()

# Function to play the appropriate walking animation based on the movement direction
func play_walk_animation(direction: Vector2) -> void:
	# Check if the horizontal movement is greater than the vertical movement
	if abs(direction.x) > abs(direction.y):
		# Play left or right animation based on the horizontal direction
		animated_sprite.play("move_right" if direction.x > 0 else "move_left")
	else:
		# Play up or down animation based on the vertical direction
		animated_sprite.play("move_down" if direction.y > 0 else "move_up")

# Function to play the idle animation based on the last direction faced
func play_idle_animation() -> void:
	# Check if the last movement was more horizontal than vertical
	if abs(last_direction.x) > abs(last_direction.y):
		# Play the default idle animation (assuming it's the same for left and right)
		animated_sprite.play("default")
	else:
		# Play the default idle animation (assuming it's the same for up and down)
		animated_sprite.play("default")
