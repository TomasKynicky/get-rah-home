extends CharacterBody2D

@export var walk_speed: float = 270.0
@export var sprint_multiplier: float = 1.65
@export var acceleration: float = 1900.0
@export var gravity: float = 1450.0
@export var jump_velocity: float = -650.0
@export var double_jump_velocity: float = -600.0
@export var wall_jump_velocity: Vector2 = Vector2(390.0, -460.0)
@export var max_charge_time: float = 1.25
@export_range(0.0, 10.0, 0.1) var power_jump_cooldown: float = 1.5
@export var power_jump_min_velocity: float = -700.0
@export var power_jump_max_velocity: float = -1050.0
@export var wall_slide_speed: float = 155.0

@onready var visual_root: Node2D = $VisualRoot
@onready var aura: Polygon2D = $VisualRoot/Aura
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var _air_jumps_used: int = 0
var _charging: bool = false
var _charge_time: float = 0.0
var _power_jump_timer: float = 0.0
var power_jump_cooldown_remaining: float = 0.0
var _facing: int = 1
var _space_was_down: bool = false
var _s_was_down: bool = false
var current_mode: String = "idle"

var charge_ratio: float:
	get:
		return clampf(_charge_time / max_charge_time, 0.0, 1.0)

var is_charging: bool:
	get:
		return _charging

var is_power_jump_on_cooldown: bool:
	get:
		return power_jump_cooldown_remaining > 0.0

func _ready() -> void:
	_build_animations()
	aura.visible = false
	animation_player.play("idle")

func _physics_process(delta: float) -> void:
	if is_on_floor():
		_air_jumps_used = 0

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	_power_jump_timer = maxf(0.0, _power_jump_timer - delta)
	power_jump_cooldown_remaining = maxf(0.0, power_jump_cooldown_remaining - delta)
	var charge_key_down := Input.is_physical_key_pressed(KEY_S)
	var charge_key_pressed := charge_key_down and not _s_was_down
	_s_was_down = charge_key_down
	if charge_key_pressed and is_on_floor() and not _charging and power_jump_cooldown_remaining <= 0.0:
		_charging = true
		_charge_time = 0.0
	if _charging:
		if charge_key_down:
			_charge_time = minf(_charge_time + delta, max_charge_time)
			velocity.x = 0.0
		else:
			_release_power_jump()

	var space_down := Input.is_physical_key_pressed(KEY_SPACE)
	var direction := 0.0 if _charging else float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A))
	var sprinting := Input.is_physical_key_pressed(KEY_SHIFT)
	var target_speed := direction * walk_speed * (sprint_multiplier if sprinting else 1.0)
	velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)

	if space_down and not _space_was_down and not _charging and _power_jump_timer <= 0.0:
		if is_on_floor():
			velocity.y = jump_velocity
			_air_jumps_used = 1
		elif is_on_wall():
			var wall_normal := get_wall_normal()
			velocity.x = wall_normal.x * wall_jump_velocity.x
			velocity.y = wall_jump_velocity.y
			_facing = 1 if wall_normal.x > 0.0 else -1
			_air_jumps_used = 1
		elif _air_jumps_used < 2:
			velocity.y = double_jump_velocity
			_air_jumps_used += 1

	if is_on_wall() and not is_on_floor() and velocity.y > 0.0:
		velocity.y = minf(velocity.y, wall_slide_speed)

	if absf(direction) > 0.01:
		_facing = 1 if direction > 0.0 else -1
	_space_was_down = space_down
	visual_root.scale.x = float(_facing)

	move_and_slide()
	_update_animation_state()

func _release_power_jump() -> void:
	var ratio := charge_ratio
	velocity.y = lerpf(power_jump_min_velocity, power_jump_max_velocity, ratio)
	_charging = false
	_charge_time = 0.0
	_power_jump_timer = 0.24
	power_jump_cooldown_remaining = maxf(0.0, power_jump_cooldown)
	_air_jumps_used = 1

func _update_animation_state() -> void:
	var next_mode := "idle"
	if _charging:
		next_mode = "charge"
	elif _power_jump_timer > 0.0:
		next_mode = "power_jump"
	elif is_on_wall() and not is_on_floor() and velocity.y > 0.0:
		next_mode = "wall_slide"
	elif not is_on_floor():
		next_mode = "jump" if velocity.y < 25.0 else "fall"
	elif absf(velocity.x) > 25.0:
		next_mode = "run"

	aura.visible = _charging or _power_jump_timer > 0.0
	if next_mode != current_mode:
		current_mode = next_mode
		animation_player.play(current_mode)

func _build_animations() -> void:
	var library := AnimationLibrary.new()
	_add_animation(library, "idle", 1.1, true, [
		["VisualRoot/Body:scale", 0.0, Vector2.ONE],
		["VisualRoot/Body:scale", 0.55, Vector2(1.035, 0.97)],
		["VisualRoot/Body:scale", 1.1, Vector2.ONE],
	])
	_add_animation(library, "run", 0.3, true, [
		["VisualRoot/Body:scale", 0.0, Vector2(0.9, 1.1)],
		["VisualRoot/Body:scale", 0.15, Vector2(1.1, 0.9)],
		["VisualRoot/Body:scale", 0.3, Vector2(0.9, 1.1)],
		["VisualRoot/Body:rotation", 0.0, deg_to_rad(-5.0)],
		["VisualRoot/Body:rotation", 0.15, deg_to_rad(5.0)],
		["VisualRoot/Body:rotation", 0.3, deg_to_rad(-5.0)],
	])
	_add_animation(library, "jump", 0.24, false, [
		["VisualRoot/Body:scale", 0.0, Vector2(1.12, 0.84)],
		["VisualRoot/Body:scale", 0.12, Vector2(0.88, 1.16)],
		["VisualRoot/Body:scale", 0.24, Vector2(0.96, 1.06)],
	])
	_add_animation(library, "fall", 0.42, true, [
		["VisualRoot/Body:scale", 0.0, Vector2(0.94, 1.07)],
		["VisualRoot/Body:scale", 0.21, Vector2(1.04, 0.96)],
		["VisualRoot/Body:scale", 0.42, Vector2(0.94, 1.07)],
	])
	_add_animation(library, "wall_slide", 0.32, true, [
		["VisualRoot/Body:rotation", 0.0, deg_to_rad(13.0)],
		["VisualRoot/Body:rotation", 0.16, deg_to_rad(8.0)],
		["VisualRoot/Body:rotation", 0.32, deg_to_rad(13.0)],
	])
	_add_animation(library, "charge", 0.4, true, [
		["VisualRoot/Body:scale", 0.0, Vector2(1.08, 0.84)],
		["VisualRoot/Body:scale", 0.2, Vector2(1.16, 0.76)],
		["VisualRoot/Body:scale", 0.4, Vector2(1.08, 0.84)],
		["VisualRoot/Aura:modulate", 0.0, Color(1.0, 1.0, 1.0, 0.12)],
		["VisualRoot/Aura:modulate", 0.2, Color(1.0, 1.0, 1.0, 0.72)],
		["VisualRoot/Aura:modulate", 0.4, Color(1.0, 1.0, 1.0, 0.12)],
	])
	_add_animation(library, "power_jump", 0.24, false, [
		["VisualRoot/Body:scale", 0.0, Vector2(1.3, 0.62)],
		["VisualRoot/Body:scale", 0.1, Vector2(0.78, 1.3)],
		["VisualRoot/Body:scale", 0.24, Vector2(0.94, 1.12)],
		["VisualRoot/Aura:modulate", 0.0, Color(1.0, 1.0, 1.0, 0.95)],
		["VisualRoot/Aura:modulate", 0.24, Color(1.0, 1.0, 1.0, 0.08)],
	])
	animation_player.add_animation_library("", library)

func _add_animation(library: AnimationLibrary, animation_name: String, duration: float, looping: bool, keys: Array) -> void:
	var animation := Animation.new()
	animation.length = duration
	animation.loop_mode = Animation.LOOP_LINEAR if looping else Animation.LOOP_NONE
	var tracks: Dictionary = {}
	for key_data in keys:
		var track_path := NodePath(key_data[0])
		var track_key := str(track_path)
		var track_index: int
		if tracks.has(track_key):
			track_index = tracks[track_key]
		else:
			track_index = animation.add_track(Animation.TYPE_VALUE)
			animation.track_set_path(track_index, track_path)
			tracks[track_key] = track_index
		animation.track_insert_key(track_index, float(key_data[1]), key_data[2])
	library.add_animation(animation_name, animation)
