extends TeleportObject


onready var area = $Area2D
onready var collision_shape = $Area2D/CollisionShape2D
onready var camera_stopper = $CameraStopper
onready var camera_stop_shape = $CameraStopper/CollisionShape2D
onready var sprite = $Sprite

var parts := 1
export var stops_camera := true
export var vertical := false

var teleport_enabled := true
var helper : AreaTransitionHelper

signal exit

func _set_properties() -> void:
	savable_properties = ["area_id", "destination_tag", "teleportation_mode", "parts", "stops_camera", "vertical"]
	editable_properties = ["area_id", "destination_tag", "teleportation_mode", "parts", "stops_camera", "vertical"]
	
func _set_property_values() -> void:

	set_property("area_id", area_id)
	set_property("destination_tag", destination_tag)
	set_property("teleportation_mode", teleportation_mode, true, "Teleport Mode")
	set_bool_alias("teleportation_mode", "Remote", "Local")
	set_property("parts", parts)
	set_property("stops_camera", stops_camera)
	set_property("vertical", vertical)
	
	
func _init():
	teleportation_mode = false
	object_type = "area_transition"
	

	
func _input(event):
	if event is InputEventMouseButton and event.is_pressed() and hovered:
		if event.button_index == 5: # Mouse wheel down
			parts -= 1
			if parts < 1:
				parts = 1
			set_property("parts", parts, true)
		elif event.button_index == 4: # Mouse wheel up
			parts += 1
			set_property("parts", parts, true)
	
func _ready() -> void:
	.ready() #calls parent class "TeleportObject"
	var append_tag
	if destination_tag != "default_teleporter" || destination_tag != null:
		append_tag = destination_tag.to_lower()
	Singleton.CurrentLevelData.level_data.vars.teleporters.append([append_tag, self])
	
	if mode != 1:
		var _connect = area.connect("body_entered", self, "body_entered")
		var _connect2 = area.connect("body_exited", self, "body_exited")
		sprite.visible = false
		camera_stopper.monitorable = stops_camera
	else:
		var _connect2 = connect("property_changed", self, "update_property")
		camera_stopper.visible = stops_camera
		
	update_property("vertical", vertical)
	camera_stopper.set_size(camera_stop_shape.shape.extents)
	
func connect_local_members():
	area.connect("body_entered", self, "prep_local_tp")

func connect_remote_members():
	area.connect("body_entered", self, "prep_remote_tp")
	
func prep_local_tp(character):
	if enabled and character.name.begins_with("Character") and !character.dead:
		if teleport_enabled:
			var pair = find_local_pair()
			if pair.object_type == "area_transition":
				pair.connect("exit", pair, "_exit_with_helper", [], CONNECT_ONESHOT)
				var helper = AreaTransitionHelper.new(character.velocity, character.state, character.facing_direction, to_local(character.global_position), vertical)
				pair.helper = helper
				pair.teleport_enabled = false
				character.camera.auto_move = false
				print("teleporting")
			character.gravity_scale = 0
			character.velocity = Vector2.ZERO
			character.toggle_movement(false)

			_start_local_transition(character, true)
		else:
			#_start_local_transition(character, false)
			pass
			
func prep_remote_tp(character : Character):
	if enabled and character.name.begins_with("Character") and !character.dead and character.controllable and teleport_enabled:
		print("start")
		Singleton.CurrentLevelData.level_data.vars.transition_character_data.append(AreaTransitionHelper.new(character.velocity, character.state.name, character.facing_direction, to_local(character.global_position), vertical))
		character.gravity_scale = 0
		character.velocity = Vector2.ZERO
		character.toggle_movement(false)
		change_areas(character, true)
	
	
#helper handles carrying over players movement, camera position, state, etc
func _exit_with_helper(character, entering : bool):
	if !is_instance_valid(helper):
		print("something has gone wrong in area transition script")
		return
	print("exiting with helper")
	character.velocity = helper.velocity
	character.set_state(helper.state, fps_util.PHYSICS_DELTA)
	character.facing_direction = helper.facing_direction
	print(character.position)
	print(helper.find_exit_offset(vertical, parts * 32))
	character.position = global_position + helper.find_exit_offset(vertical, parts * 32)
	if stops_camera:
		print(character.camera.global_position)
		character.camera.global_position = helper.find_camera_position(vertical, character.global_position, character.camera.base_size)
		character.camera.last_position = character.camera.global_position
		print(character.camera.global_position)
		character.camera.timer.start(1)
		
func exit_local_teleport():
	pass
	
func update_property(key, value):
	match(key):
		"parts":
			update_parts()
		"vertical":
			if vertical:
				sprite.rect_size.x = 32
				sprite.rect_position.x = -16
				collision_shape.shape.extents.x = 16
				camera_stop_shape.shape.extents.x = 52
			else:
				sprite.rect_size.y = 32
				sprite.rect_position.y = -16
				collision_shape.shape.extents.y = 16
				camera_stop_shape.shape.extents.y = 52
			update_parts()
		"rotation_degrees":
			rotation_degrees = 0
		"stops_camera":
			camera_stopper.visible = value
			
func update_parts():
	if vertical:
		sprite.rect_size.y = parts * 32
		sprite.rect_position.y = (-16 * parts)
		collision_shape.shape.extents.y = 16 * parts
		camera_stop_shape.shape.extents.y = collision_shape.shape.extents.y + 26
	else:
		sprite.rect_size.x = parts * 32
		sprite.rect_position.x = (-16 * parts)
		collision_shape.shape.extents.x = 16 * parts
		camera_stop_shape.shape.extents.x = collision_shape.shape.extents.x + 26
	

func body_entered(body):
#	if enabled and body.name.begins_with("Character") and !body.dead and body.controllable and teleport_enabled:
#		body.toggle_movement(false)
#		body.gravity_scale = 0
#		change_areas(body, true)
#		# change this to work with multiplayer
#		Singleton.CurrentLevelData.level_data.vars.transition_character_data.append(AreaTransitionHelper.new(body.velocity, body.state.name, body.facing_direction, to_local(body.global_position).x, vertical))
	pass
		
func body_exited(body):
	if enabled and body.name.begins_with("Character") and !body.dead:
		teleport_enabled = true
		
		
func exit_remote_teleport(): 
	teleport_enabled = false
		
func start_exit_anim(character):
	# to prevent teleport loop
	print("exiting")
	
	
	if teleportation_mode:
		# this means we came from another area transition
		print(Singleton.CurrentLevelData.level_data.vars.transition_character_data.back())
		if Singleton.CurrentLevelData.level_data.vars.transition_character_data.size() >= 6:
			var helper = Singleton.CurrentLevelData.level_data.vars.transition_character_data.back()
			Singleton.CurrentLevelData.level_data.vars.transition_data = []
			_exit_with_helper(character, false)
		else:
			print("no helper")
	else:
		_start_local_transition(character, false)
	teleport_enabled = false;
	character.toggle_movement(true)
	character.gravity_scale = 1
	print("emitting")
	print(is_connected("exit", self, "_exit_with_helper"))
	emit_signal("exit", character, false)
	
	reset_sprite(character)
	
func reset_sprite(character : Character): #This is here in case Mario came from a door to a pipe
	character.z_index = -1
	character.sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
	character.sprite.scale = Vector2(1.0, 1.0)
	character.sprite.position = Vector2.ZERO
