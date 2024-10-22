# Enemy.gd
extends CharacterBody2D

@export var speed = 150.0  # Adjust speed as needed
@export var detect_range = 500.0  # How far the enemy can see the player

# Reference to the player node
var player: Node2D = null

func _ready():
	# Wait a brief moment to ensure the player is in the scene
	await get_tree().create_timer(0.1).timeout
	# Get reference to the player (assuming it has a group name "player")
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	if player == null:
		return
		
	# Calculate direction to player
	var direction = (player.global_position - global_position).normalized()
	
	# Set velocity towards player
	velocity = direction * speed
	
	# Move and slide using Godot's built-in physics
	move_and_slide()
	
	# Optional: Rotate enemy to face player
	rotation = direction.angle()

# Optional: Add this method if you want to handle damage
func take_damage(amount: float):
	# Implement damage logic here
	pass

func _on_hitbox_area_entered(area):
	# Implement collision logic here
	pass
