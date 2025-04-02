extends GameObject

onready var kinematic_body = $KinematicBody2D
onready var collision_shape = $KinematicBody2D/CollisionShape2D
onready var area = $KinematicBody2D/Area2D
onready var area_collision = $KinematicBody2D/Area2D/CollisionShape2D
onready var sound = $AudioStreamPlayer2D
onready var particle = $Particles2D
onready var image = $KinematicBody2D/Orb

var velocity := Vector2(0, 0)
var nozzle_type = "HoverNozzle"
var collected = false
var destroy_timer = 0.0

var gravity: = 0.0
var gravity_scale: = 1.0

var run_physics := true

func _set_properties():
	savable_properties = ["velocity", "nozzle_type"]
	editable_properties = ["velocity", "nozzle_type"]
	
func _set_property_values():
	set_property("velocity", velocity, 1)
		
func collect(body):
	if enabled and !collected and body.name.begins_with("Character") and !body.dead:
		sound.play()
		image.hide()
		run_physics = false
		collected = true
		particle.show()
		particle.set_emitting(true)
		

func _ready():
	particle.hide()
	var _connect = area.connect("body_entered", self, "collect")
	gravity = Singleton.CurrentLevelData.level_data.areas[Singleton.CurrentLevelData.area].settings.gravity
	
func _process(delta):
	pass
			
func _physics_process(delta):
	pass
