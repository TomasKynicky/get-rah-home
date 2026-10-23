extends Node2D

const TILE_FOLDER: String = "res://tiles"
const TILE_WIDTH: float = 720.0
const TILE_HEIGHT: float = 720.0

@export_range(1, 12, 1) var tiles_ahead: int = 5
@export_range(0, 6, 1) var tiles_behind: int = 2

var _player: CharacterBody2D
var _random := RandomNumberGenerator.new()
var _tile_scenes: Array[PackedScene] = []
var _active_tiles: Array[Node2D] = []
var _next_chunk_bottom_y: float = 0.0
var _next_tile_index: int = 0
var _last_tile_path: String = ""

func configure(player: CharacterBody2D) -> void:
	_player = player
	_random.randomize()
	_scan_tile_folder()
	if _tile_scenes.is_empty():
		push_error("TileManager: no valid tile scenes found in res://tiles/.")
		set_process(false)
		return

	_next_chunk_bottom_y = 0.0
	_fill_tiles_above_player()

func _process(_delta: float) -> void:
	if _player == null or _tile_scenes.is_empty():
		return
	_fill_tiles_above_player()
	_recycle_tiles_below_player()

func _scan_tile_folder() -> void:
	_tile_scenes.clear()
	var files := DirAccess.get_files_at(TILE_FOLDER)
	files.sort()
	for filename in files:
		if not filename.to_lower().ends_with(".tscn"):
			continue
		var scene_path := TILE_FOLDER.path_join(filename)
		var packed_scene := ResourceLoader.load(scene_path) as PackedScene
		if packed_scene == null:
			push_warning("TileManager: skipping invalid tile scene: " + scene_path)
			continue

		var preview_node := packed_scene.instantiate()
		if not preview_node is Node2D:
			preview_node.free()
			push_warning("TileManager: tile root must be Node2D: " + scene_path)
			continue
		var preview := preview_node as Node2D
		var valid_height := is_equal_approx(float(preview.get("tile_height")), TILE_HEIGHT)
		var valid_width := is_equal_approx(float(preview.get("tile_width")), TILE_WIDTH)
		var platform_data: Variant = preview.get("platform_rects")
		var has_platform_data: bool = platform_data is PackedVector4Array and platform_data.size() > 0
		preview.free()
		if not valid_width or not valid_height or not has_platform_data:
			push_warning("TileManager: tile must be 720 x 720 and contain platform_rects: " + scene_path)
			continue
		_tile_scenes.append(packed_scene)

func _fill_tiles_above_player() -> void:
	var upper_limit := _player.global_position.y - TILE_HEIGHT * tiles_ahead
	while _next_chunk_bottom_y > upper_limit:
		_spawn_tile_above()

func _spawn_tile_above() -> void:
	var packed_scene := _choose_tile_scene()
	var tile := packed_scene.instantiate() as Node2D
	if tile == null:
		return
	var tile_height := float(tile.get("tile_height"))
	tile.position = Vector2(0.0, _next_chunk_bottom_y - tile_height)
	tile.name = "Tile_%06d" % _next_tile_index
	_next_tile_index += 1
	add_child(tile)
	_active_tiles.append(tile)
	_next_chunk_bottom_y = tile.position.y
	_last_tile_path = packed_scene.resource_path

func _choose_tile_scene() -> PackedScene:
	if _tile_scenes.size() == 1:
		return _tile_scenes[0]
	var choices: Array[PackedScene] = []
	for scene in _tile_scenes:
		if scene.resource_path != _last_tile_path:
			choices.append(scene)
	if choices.is_empty():
		choices = _tile_scenes
	return choices[_random.randi_range(0, choices.size() - 1)]

func _recycle_tiles_below_player() -> void:
	while _active_tiles.size() > 1:
		var lowest_tile := _active_tiles[0]
		var lowest_tile_bottom_y := lowest_tile.position.y + float(lowest_tile.get("tile_height"))
		if lowest_tile_bottom_y <= _player.global_position.y + TILE_HEIGHT * tiles_behind:
			break
		_active_tiles.pop_front()
		lowest_tile.queue_free()
