extends GameObject

export(Array, Texture) var textures
const rainbow_animation_speed := 2500
onready var particles = $Particles2D
# onready var sprite = $Sprite

export var color := Color(1, 1, 1)
export var rainbow := false
export var rate := 14.0
export var radius := 24.0
export var lifetime := 1.0

func _set_properties():
	savable_properties = ["color", "rainbow", "rate", "radius", "lifetime"]
	editable_properties = ["color", "rainbow", "rate", "radius", "lifetime"]
	
func _set_property_values():
	set_property("color", color, 1)
	set_property("rainbow", rainbow, true)
	set_property("rate", rate, true)
	set_property("radius", radius, true)
	set_property("lifetime", lifetime, true)

func _ready():
	particles.texture = textures[palette]
	particles.lifetime = lifetime
	particles.amount = rate
	particles.modulate = color
	particles.process_material.emission_sphere_radius = radius
	# breakpoint

func _process(delta):
	if particles.lifetime != lifetime:
		particles.lifetime = lifetime
	if particles.amount != rate:
		particles.amount = rate
	particles.modulate = color
	particles.process_material.emission_sphere_radius = radius
	if rainbow:
		color.h = float(OS.get_ticks_msec() % rainbow_animation_speed) / rainbow_animation_speed
