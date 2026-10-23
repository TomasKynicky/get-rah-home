extends Node2D

const TileManagerScript = preload("res://scripts/tile_manager.gd")
const WORLD_WIDTH: float = 720.0
const CAMERA_PLAYER_OFFSET: float = 170.0
const FALL_RESET_Y: float = 1100.0

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var tile_manager: TileManagerScript = $TileManager
@onready var frame_left: Control = $ResponsiveLayout/PanelRoot/LeftPanel
@onready var frame_right: Control = $ResponsiveLayout/PanelRoot/RightPanel
@onready var frame_top: Control = $ResponsiveLayout/PanelRoot/TopPanel
@onready var frame_bottom: Control = $ResponsiveLayout/PanelRoot/BottomPanel

func _ready() -> void:
	player.global_position = Vector2(WORLD_WIDTH * 0.5, -35.0)
	tile_manager.configure(player)
	get_viewport().size_changed.connect(_update_responsive_layout)
	_update_responsive_layout()

func _process(_delta: float) -> void:
	if player.global_position.y > FALL_RESET_Y:
		player.global_position = Vector2(WORLD_WIDTH * 0.5, -35.0)
		player.velocity = Vector2.ZERO

	player.global_position.x = clampf(player.global_position.x, 18.0, WORLD_WIDTH - 18.0)
	if player.global_position.x <= 18.0 or player.global_position.x >= WORLD_WIDTH - 18.0:
		player.velocity.x = 0.0

	camera.global_position = Vector2(WORLD_WIDTH * 0.5, player.global_position.y - CAMERA_PLAYER_OFFSET)

func _update_responsive_layout() -> void:
	var viewport_size := get_viewport_rect().size
	var square_size := minf(viewport_size.x, viewport_size.y)
	if square_size <= 0.0:
		return

	var horizontal_margin := (viewport_size.x - square_size) * 0.5
	var vertical_margin := (viewport_size.y - square_size) * 0.5
	var square_top := vertical_margin
	var square_bottom := vertical_margin + square_size

	frame_left.position = Vector2(0.0, square_top)
	frame_left.size = Vector2(horizontal_margin, square_size)
	frame_right.position = Vector2(horizontal_margin + square_size, square_top)
	frame_right.size = Vector2(horizontal_margin, square_size)
	frame_top.position = Vector2.ZERO
	frame_top.size = Vector2(viewport_size.x, vertical_margin)
	frame_bottom.position = Vector2(0.0, square_bottom)
	frame_bottom.size = Vector2(viewport_size.x, vertical_margin)

	var camera_zoom := square_size / WORLD_WIDTH
	camera.zoom = Vector2(camera_zoom, camera_zoom)
