extends GameObject

onready var body = $RigidBody2D
onready var collision_shape = $RigidBody2D/CollisionPolygon2D
onready var sprite = $RigidBody2D/Sprite
onready var area = $RigidBody2D/Area2D
onready var sound = $AudioStreamPlayer
onready var character = Character

var velocity := Vector2(0, 0)
var controllable = false
var collected = false
var destroy_timer = 0.0
var color: = Color(1, 1, 1)
var hit_switches: = false

var gravity: = 0.0
var gravity_scale: = 0.0
var sleeping: = true
var camera_track: = false

var run_physics := true

func _set_properties():
	savable_properties = ["velocity", "controllable", "color", "hit_switches", "camera_track"]
	editable_properties = ["velocity", "controllable", "color", "hit_switches"]
	
func _set_property_values():
	set_property("velocity", velocity, 1)
	set_property("controllable", controllable, 1)
	set_property("color", color, 1)
	set_property("hit_switches", hit_switches, 1)
	set_property("camera_track", camera_track, 1)

func _ready():
	sprite.self_modulate = color
	if mode != 1 and run_physics:
		gravity = Singleton.CurrentLevelData.level_data.areas[Singleton.CurrentLevelData.area].settings.gravity
		run_physics = true
		gravity_scale = 1.0
		
		if hit_switches:
			body.collision_layer = 536870961
			
		if camera_track:
			character.camera.focus_on = RigidBody2D
	
func _process(delta):
	pass
			
func _physics_process(delta):
	gravity = Singleton.CurrentLevelData.level_data.areas[Singleton.CurrentLevelData.area].settings.gravity
	gravity_scale = 1.0
	if mode != 1 and run_physics:
		if controllable:
			var direction2 = Input.get_axis("editor_left", "editor_right")
			body.angular_velocity += direction2 * 0.5
			body.linear_velocity.x += direction2 * 0.5

func _on_Area2D_body_entered(body):
	pass


func _on_Area2D_body_exited(body):
	pass
