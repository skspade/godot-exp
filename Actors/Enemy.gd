# Enemy.gd
extends CharacterBody2D

# Movement and behavior settings
@export var speed = 150.0
@export var detect_range = 500.0
@export var movement_pattern: String = "chase" # chase, circle, zigzag
@export var attack_damage = 10.0
@export var attack_cooldown = 1.0
@export var max_health = 100.0

# Node references
@onready var animated_sprite = $AnimatedSprite2D

@onready var animation_player = $AnimationPlayer
@onready var sprite = $Sprite2D
@onready var attack_timer = $AttackTimer
@onready var audio_player = $AudioStreamPlayer2D
@onready var health_bar = $HealthBar

# Sound effects - assign in inspector
@export var hit_sound: AudioStream
@export var death_sound: AudioStream
@export var attack_sound: AudioStream

# State variables
var player: Node2D = null
var current_health: float
var can_attack: bool = true
var time_offset: float # For movement patterns
var original_position: Vector2

# Movement pattern variables
var circle_radius = 100.0
var zigzag_amplitude = 50.0
var zigzag_frequency = 2.0

var last_direction = Vector2.DOWN  # Default facing down

func _ready():
	# Initialize health and UI
	current_health = max_health
	health_bar.max_value = max_health
	health_bar.value = current_health
	
	# Initialize timers
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	
	# Store initial position for movement patterns
	original_position = global_position
	
	# Add random offset to make enemies move differently
	time_offset = randf() * PI * 2
	
	# Get player reference
	await get_tree().create_timer(0.1).timeout
	player = get_tree().get_first_node_in_group("player")
	
	# Start idle animation
	play_animation("idle")

func _physics_process(delta):
	if player == null:
		return
	
	var direction = get_movement_direction(delta)
	velocity = direction * speed
	move_and_slide()
	
	# Update facing direction
	update_facing_direction(direction)
	
	# Try to attack if in range
	check_attack()

func get_movement_direction(_delta) -> Vector2:
	var base_direction = (player.global_position - global_position).normalized()
	
	match movement_pattern:
		"chase":
			return base_direction
		
		"circle":
			var time = Time.get_ticks_msec() / 1000.0 + time_offset
			var circle_x = cos(time) * circle_radius
			var circle_y = sin(time) * circle_radius
			var circle_center = player.global_position
			var target = circle_center + Vector2(circle_x, circle_y)
			return (target - global_position).normalized()
		
		"zigzag":
			var time = Time.get_ticks_msec() / 1000.0 + time_offset
			var perpendicular = Vector2(-base_direction.y, base_direction.x)
			var zigzag = perpendicular * sin(time * zigzag_frequency) * zigzag_amplitude
			return (base_direction + zigzag).normalized()
		
		_:
			return base_direction

func update_facing_direction(direction: Vector2):
	# Update sprite facing direction
	if direction.x != 0:
		sprite.flip_h = direction.x < 0
	
	# Play movement animation
	if velocity.length() > 0:
		play_animation("walk")
	else:
		play_animation("idle")

func check_attack():
	if !can_attack:
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player < 50.0: # Attack range
		attack()

func attack():
	can_attack = false
	attack_timer.start()
	
	# Play attack animation and sound
	play_animation("attack")
	play_sound(attack_sound)
	
	# Emit signal for damage
	var attack_data = {
		"damage": attack_damage,
		"source": self
	}
	emit_signal("enemy_attacked", attack_data)

func take_damage(amount: float):
	current_health -= amount
	health_bar.value = current_health
	
	# Play hit animation and sound
	play_animation("hurt")
	play_sound(hit_sound)
	
	if current_health <= 0:
		die()
	else:
		# Flash red when hit
		sprite.modulate = Color(1, 0, 0, 1)
		await get_tree().create_timer(0.1).timeout
		sprite.modulate = Color(1, 1, 1, 1)

func die():
	# Play death animation and sound
	play_animation("death")
	play_sound(death_sound)
	
	# Disable collision and physics
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	
	# Wait for animation to finish
	await animation_player.animation_finished
	
	# Optional: Spawn particles, drop items, etc.
	queue_free()

func play_animation(anim_name: String):
	if animation_player.has_animation(anim_name) and animation_player.current_animation != anim_name:
		animation_player.play(anim_name)

func play_sound(sound: AudioStream):
	if sound != null:
		audio_player.stream = sound
		audio_player.play()

func _on_attack_timer_timeout():
	can_attack = true
	
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

# Signals
signal enemy_attacked(attack_data)
