extends NPCBase


const rainbow_animation_speed := 1500

onready var visibility_notifier = $"%VisibilityNotifier2D"

onready var body_color1 = $KinematicBody2D/AnimationHandler/Body/Color

var shell_color := Color.green
var rainbow: bool


func _set_properties():
	savable_properties = ["curve", "custom_path", "move_type", "walk_speed", "physics_enabled", "idle_expression", "idle_action", "speaking_expression", "speaking_action", "path_reference", "tag_link", "required_shines", "shell_color", "rainbow"]
	editable_properties = ["idle_expression", "idle_action", "speaking_expression", "speaking_action", "tag_link", "custom_path", "walk_speed", "move_type", "physics_enabled", "required_shines", "path_reference", "shell_color", "rainbow"]


func _set_property_values():
	._set_property_values()
	
	set_property("shell_color", shell_color, true)
	set_property("rainbow", rainbow, true)


func _process(delta):
	if not visibility_notifier.is_on_screen() and not is_preview: return
	
	if rainbow:
		shell_color.h = float(OS.get_ticks_msec() % rainbow_animation_speed) / rainbow_animation_speed
	
	body_color1.modulate = shell_color
	
	if curve != path.curve:
		path.curve = curve
