extends State

class_name WallJumpState

export var walljump_power = Vector2(350, 320)

var press_buffer = 0.0
var wall_jump_timer = 0.0
var direction_on_wj = 1
var position_on_wj = Vector2(0, 0)
var limit_y = false
var character_in_range = false

func _ready():
	priority = 1
	disable_turning = true

func _start_check(delta):
	return character.state == character.get_state_node("WallSlideState") and !(limit_y and character.position.y < position_on_wj.y and character_in_range) and press_buffer > 0

func _start(delta):
	var sound_player = character.get_node("Sounds")
	press_buffer = 0
	position_on_wj = character.position
	character.facing_direction = -character.direction_on_stick
	character.velocity.x = walljump_power.x * character.facing_direction
	character.velocity.y = -walljump_power.y
	character.position.x += 2 * character.facing_direction
	character.position.y -= 2
	direction_on_wj = character.facing_direction
	wall_jump_timer = 0.45
	sound_player.play_jump_sound()
	character.jump_animation = 0
	limit_y = true
	character.is_wj_chained = true

func _update(delta):
	var sprite = character.animated_sprite
	if (direction_on_wj == 1):
		sprite.animation = "jumpRight"
	else:
		sprite.animation = "jumpLeft"
	pass

func _stop_check(delta):
	return wall_jump_timer <= 0 or character.is_walled() or character.is_grounded()
	
func _general_update(delta):
	if character.position.x > position_on_wj.x - 3 and character.position.x < position_on_wj.x + 3:
		character_in_range = true
	else:
		character_in_range = false
	if character.is_grounded():
		limit_y = false
		character.is_wj_chained = false
	if character.jump_just_pressed and !character.is_grounded():
		press_buffer = 0.075
	if press_buffer > 0:
		press_buffer -= delta
		if press_buffer <= 0:
			press_buffer = 0
	if wall_jump_timer > 0:
		wall_jump_timer -= delta
		if wall_jump_timer <= 0:
			wall_jump_timer = 0
