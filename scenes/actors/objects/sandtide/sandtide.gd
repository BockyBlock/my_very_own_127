extends GameObject

var width := 600.0
var height := 300.0
var size := Vector2(600.0, 300.0)
var color := Color(1, 1, 0)
var render_in_front := false
var tag = "default"

var last_size : Vector2
var last_color : Color
var last_texture : bool
var last_front : bool

var moving : bool = false
var horizontal : bool = false
var match_level : float = 0.0
var move_speed : float = 1.0
var tap_mode : bool = true
var textured : bool = true

var save_pos : Vector2

onready var area_collision = $Area2D/CollisionShape2D
onready var body_collision = $KinematicBody2D/CollisionShape2D
onready var sprite = $ColorRect
onready var waves = $Stone
onready var color_sprite = $Stone/Stone_colorable

func _set_properties():
	savable_properties = ["width", "height", "color", "render_in_front", "tag", "tap_mode", "textured"]
	editable_properties = ["width", "height", "color", "render_in_front", "tag", "tap_mode", "textured"]

func _set_property_values():
	set_property("width", width, true)
	set_property("height", height, true)
	set_property("color", color, true)
	set_property("render_in_front", render_in_front, true)
	set_property("tag", tag, true)
	set_property("tap_mode", tap_mode, true)
	set_bool_alias("tap_mode", "Move", "Scale")
	set_property("textured", textured, true)

func _ready():
	var id = Singleton.CurrentLevelData.level_data.vars.current_liquid_id
	if Singleton.CurrentLevelData.level_data.vars.liquid_positions.size() > Singleton.CurrentLevelData.area and Singleton.CurrentLevelData.level_data.vars.liquid_positions[Singleton.CurrentLevelData.area].size() > id:
		var set_position = Singleton.CurrentLevelData.level_data.vars.liquid_positions[Singleton.CurrentLevelData.area][id]
		if set_position != Vector2():
			global_position = set_position
			save_pos = set_position
	Singleton.CurrentLevelData.level_data.vars.current_liquid_id += 1

	area_collision.shape = area_collision.shape.duplicate()
	change_size()
	last_size = Vector2(width, height)

	area_collision.disabled = !enabled
	body_collision.disabled = !enabled
	
	Singleton.CurrentLevelData.level_data.vars.liquids.append([tag.to_lower(), self])

func change_size():
	preview_position = Vector2(-width / 2, height / 2)
	sprite.rect_size = Vector2(width, height)
	waves.rect_size = sprite.rect_size
	color_sprite.rect_size = sprite.rect_size
	area_collision.position = Vector2(width / 2, height / 2)
	area_collision.reset_physics_interpolation()
	area_collision.shape.extents = area_collision.position
	body_collision.position = area_collision.position
	body_collision.reset_physics_interpolation()
	body_collision.shape = area_collision.shape
	
	waves.visible = textured
	sprite.visible = !textured
	
	var rounded_color = Color(stepify(color.r, 0.05), stepify(color.g, 0.05), stepify(color.b, 0.05))
	if (rounded_color == Color(0.5, 0, 0) or rounded_color == Color(1, 1, 0)) and textured:
		color_sprite.visible = false
		sprite.color = Color(0.8470588235294118, 0.625, 0.2196078431372549)
		sprite.modulate = Color(1, 1, 1)
		waves.self_modulate = Color(1, 1, 1)
	else:
		color_sprite.visible = true
		color_sprite.modulate = color
		sprite.color = Color(1,1,1)
		sprite.modulate = color
		var desat_color = color
		desat_color.s /= 2
		waves.self_modulate = desat_color
	
	z_index = -1 if !render_in_front else 25
	#sprite.color = color
	
	last_size = Vector2(width, height)
	last_color = color
	last_texture = textured
	last_front = render_in_front

func _physics_process(_delta):
	if !moving: return
	
	if !horizontal:
		var end_pos := global_position.y + height
		var speed_modifier : float = transform.basis_xform(Vector2(0.0, 1.0)).y
		global_position.y = move_toward(global_position.y, match_level, move_speed * 2)
		
		if !tap_mode:
			height += speed_modifier * ((end_pos - global_position.y) - height)
			change_size() # Letting it happen in _process causes issues
	else:
		var end_pos := global_position.x + height
		var speed_modifier : float = transform.basis_xform(Vector2(0.0, 1.0)).x
		global_position.x = move_toward(global_position.x, match_level, move_speed * 2)
		
		if !tap_mode:
			height += speed_modifier * ((end_pos - global_position.x) - height)
			change_size() # Letting it happen in _process causes issues

func _process(_delta):
	if "\n" in tag:
		tag = tag.replace("\n", "")
	if (Vector2(width, height) != last_size ||
			color != last_color ||
			textured != last_texture ||
			render_in_front != last_front):
		change_size()
