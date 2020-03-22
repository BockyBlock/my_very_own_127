extends KinematicBody2D

class_name Character

signal died
signal state_changed

onready var states_node = $States
onready var animated_sprite = $sprite

# Cutout
export var cutout_death : StreamTexture
export var cutout_circle : StreamTexture

# Basic Physics
export var initial_position = Vector2(0, 0)
export var velocity = Vector2(0, 0)
var last_velocity = Vector2(0, 0)

export var gravity_scale = 1
export var facing_direction = 1
export var move_direction = 0
export var last_move_direction = 0

export var move_speed = 216.0
export var acceleration = 7.5
export var deceleration = 15.0
export var aerial_acceleration = 7.5
export var friction = 10.5
export var aerial_friction = 1.15

# Sounds
onready var fall_sound_player = $fall_sounds

# Extra
export var is_wj_chained = false
export var real_friction = 0
export var current_jump = 0
export var jump_animation = 0
export var direction_on_stick = 1
export var rotating = true

export var disable_movement = false
export var disable_turning = false
export var disable_animation = false

# States
var state = null
var last_state = null
export var controllable = true
export var dead = false

# Collision vars
var collision_down
var collision_up
var collision_left
var collision_right
var collided_last_frame = false

#onready var global_vars_node = get_node("../GlobalVars")
#onready var level_settings_node = get_node("../LevelSettings")
onready var collision_shape = get_node("collision")
onready var dive_collision_shape = get_node("dive_collision")
onready var sprite = get_node("sprite")

var level_size = Vector2(80, 30)

func load_in(level_data : LevelData, level_area : LevelArea):
	level_size = level_area.settings.size

func is_grounded():
	return test_move(self.transform, Vector2(0, 0.1)) and collided_last_frame

func is_ceiling():
	return test_move(self.transform, Vector2(0, -0.1)) and collided_last_frame

func is_walled():
	return (is_walled_left() or is_walled_right()) and collided_last_frame

func is_walled_left():
	return test_move(self.transform, Vector2(-0.1, 0)) and collided_last_frame

func is_walled_right():
	return test_move(self.transform, Vector2(0.1, 0)) and collided_last_frame

func hide():
	visible = false
	velocity = Vector2(0, 0)
	position = initial_position

func show():
	visible = true

func set_state(state, delta: float):
	last_state = self.state
	self.state = null
	if last_state != null:
		last_state._stop(delta)
	if state != null:
		self.state = state
		state._start(delta)
	emit_signal("state_changed", state, last_state)

func get_state_node(name: String):
	if states_node.has_node(name):
		return states_node.get_node(name)

func set_state_by_name(name: String, delta: float):
	if get_state_node(name) != null:
		set_state(get_state_node(name), delta)

func _ready():
	real_friction = friction
	
func is_action_pressed(input):
	if controllable:
		return Input.is_action_pressed(input)
	else:
		return false
		
func is_action_just_pressed(input):
	if controllable:
		return Input.is_action_just_pressed(input)
	else:
		return false

func _physics_process(delta: float):
	var gravity = 7.82 #global_vars_node.gravity
	# Gravity
	velocity += gravity * Vector2(0, gravity_scale)
	
	if test_move(transform, Vector2(velocity.x * delta, -1)) and !test_move(transform.translated(Vector2(0, -5)), Vector2(move_direction * 5, 0)) and is_grounded():
		var space_state = get_world_2d().direct_space_state
		var result = space_state.intersect_ray(position - Vector2(0, 5), position)
		velocity.y = -1
		if not result.empty():
			position.x += move_direction * 5
			position.y = result.position.y + 3
	
	if state != null:
		disable_movement = state.disable_movement
		disable_turning = state.disable_turning
		disable_animation = state.disable_animation
	else:
		disable_movement = false
		disable_turning = false
		disable_animation = false
	# Movement
	move_direction = 0
	if is_action_pressed("move_left") and disable_movement == false:
		move_direction = -1
	elif is_action_pressed("move_right") and disable_movement == false:
		move_direction = 1
	if move_direction != 0:
		if is_grounded():
			if ((velocity.x > 0 && move_direction == -1) || (velocity.x < 0 && move_direction == 1)):
				velocity.x += deceleration * move_direction
			elif ((velocity.x < move_speed && move_direction == 1) || (velocity.x > -move_speed && move_direction == -1)):
				velocity.x += acceleration * move_direction
			elif ((velocity.x > move_speed && move_direction == 1) || (velocity.x < -move_speed && move_direction == -1)):
				velocity.x -= 3.5 * move_direction
			facing_direction = move_direction

			if !disable_animation:
				if !test_move(transform, Vector2(velocity.x * delta, 0)):
					var animation_frame = sprite.frame
					if move_direction == 1:
						sprite.animation = "movingRight"
						if last_move_direction != move_direction:
							sprite.frame = animation_frame + 1
					else:
						sprite.animation = "movingLeft"
						if last_move_direction != move_direction:
							sprite.frame = animation_frame + 1
				else:
					if facing_direction == 1:
						sprite.animation = "idleRight"
					else:
						sprite.animation = "idleLeft"
				if (abs(velocity.x) > move_speed):
					sprite.speed_scale = abs(velocity.x) / move_speed
				else:
					sprite.speed_scale = 1
		else:
			if ((velocity.x < move_speed && move_direction == 1) || (velocity.x > -move_speed && move_direction == -1)):
				velocity.x += aerial_acceleration * move_direction
			elif ((velocity.x > move_speed && move_direction == 1) || (velocity.x < -move_speed && move_direction == -1)):
				velocity.x -= 0.25 * move_direction
			if !disable_turning:
				facing_direction = move_direction
	else:
		if (velocity.x > 0):
			if (velocity.x > 15):
				if (is_grounded()):
					velocity.x -= friction
				else:
					velocity.x -= aerial_friction
			else:
				velocity.x = 0
		elif (velocity.x < 0):
			if (velocity.x < -15):
				if (is_grounded()):
					velocity.x += friction
				else:
					velocity.x += aerial_friction
			else:
				velocity.x = 0

		if !disable_animation:
			if is_grounded():
				if facing_direction == 1:
					sprite.animation = "idleRight"
				else:
					sprite.animation = "idleLeft"
				sprite.speed_scale = 1

	for state_node in states_node.get_children():
		state_node.handle_update(delta)

	# Move by velocity
	velocity = move_and_slide(velocity)
	var slide_count = get_slide_count()
	collided_last_frame = true if slide_count else false

	# Boundaries
	if position.y > (level_size.y * 32) + 128:
		kill("fall")
	if position.x < 0:
		position.x = 0
		velocity.x = 0
		if is_grounded() and move_direction != 0 and !disable_animation:
			if facing_direction == 1:
				sprite.animation = "idleRight"
			else:
				sprite.animation = "idleLeft"
	if position.x > level_size.x * 32:
		position.x = level_size.x * 32
		velocity.x = 0
		if is_grounded() and move_direction != 0 and !disable_animation:
			if facing_direction == 1:
				sprite.animation = "idleRight"
			else:
				sprite.animation = "idleLeft"
	last_velocity = velocity
	last_move_direction = move_direction

func kill(cause):
	if !dead:
		dead = true
		emit_signal("dead")
		var cutout_in = cutout_circle
		var cutout_out = cutout_circle
		var transition_time = 0.75
		if cause == "fall":
			controllable = false
			cutout_in = cutout_death
			fall_sound_player.play()
			yield(get_tree().create_timer(.75), "timeout")
		elif cause == "reload":
			transition_time = 0.4
		scene_transitions.reload_scene(cutout_in, cutout_out, transition_time)

func exit():
	mode_switcher.get_node("ModeSwitcherButton").switch()
