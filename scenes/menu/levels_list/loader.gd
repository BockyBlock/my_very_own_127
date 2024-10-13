extends Node


signal loading_finished

onready var list_handler: LevelListHandler = $"%ListHandler"
onready var drag_cursor: Area2D = $"%DragCursor"
onready var http_thumbnails: HTTPThumbnails = $"%HTTPThumbnails"

onready var folder_card_scene: PackedScene = preload("res://scenes/menu/levels_list/cards/folder/folder_card.tscn")
onready var level_card_scene: PackedScene = preload("res://scenes/menu/levels_list/cards/level/level_card.tscn")
onready var level_load_thread := Thread.new()


func start_level_loading(working_folder: String):
	if level_load_thread.is_active():
		level_load_thread.wait_to_finish()
	
#	load_directory(working_folder)
	var err = level_load_thread.start(self, "load_directory", working_folder)
	if err != OK:
		push_error("Error starting level loading thread.")


# Thread must be disposed (or "joined"), for portability.
func _exit_tree():
	if level_load_thread.is_active():
		level_load_thread.wait_to_finish()


func transition_to_directory(working_folder: String):
	list_handler.parent_screen.transition("LevelView")
	yield(list_handler.parent_screen, "screen_change")
	load_directory(working_folder)


var first_card: BaseCard
func load_directory(working_folder: String):
	http_thumbnails.clear_queue()
	list_handler.clear_grid()
	list_handler.working_folder = working_folder
	
	print("Loading directory " + working_folder + "...")
	
	if working_folder != level_list_util.BASE_FOLDER:
		var parent_folder: String = level_list_util.get_parent_from_path(working_folder)
		# folder id is useless on back buttons :p
		add_folder_card("", parent_folder, false, false, true)
	
	var sort: Dictionary = sort_file_util.load_sort_file(working_folder)
	for folder in sort.get(sort_file_util.FOLDERS, []):
		add_folder_card(folder, working_folder, true)
	for level in sort.get(sort_file_util.LEVELS, []):
		add_level_card(level, working_folder, true)
	
	print("Done loading levels in directory.")
	emit_signal("loading_finished")
	
	list_handler.emit_signal("directory_changed", working_folder)
	list_handler.call_deferred("change_focus", first_card)
	first_card = null


func add_folder_card(
	folder_id: String, 
	parent_folder: String,
	can_sort: bool,
	move_to_front: bool = false,
	is_back: bool = false
):
	var level_grid: GridContainer = list_handler.level_grid
	var card_node: FolderCard = folder_card_scene.instance()
	card_node.pass_nodes(
		list_handler,
		drag_cursor
	)
	card_node.setup(
		folder_id,
		parent_folder,
		can_sort,
		move_to_front,
		is_back
	)
	
	level_grid.call_deferred("add_child", card_node)
	if not is_instance_valid(first_card):
		first_card = card_node


func add_level_card(
	level_id: String, 
	working_folder: String,
	can_sort: bool,
	move_to_front: bool = false,
	level_code: String = ""
):
	var level_grid: GridContainer = list_handler.level_grid
	var card_node: LevelCard = level_card_scene.instance()
	card_node.pass_nodes(
		list_handler,
		drag_cursor,
		http_thumbnails
	)
	card_node.setup(
		level_id,
		working_folder,
		can_sort,
		move_to_front,
		level_code
	)
	
	level_grid.call_deferred("add_child", card_node)
	if not is_instance_valid(first_card):
		first_card = card_node
