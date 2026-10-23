extends Node2D

@export var tile_width: float = 720.0
@export var tile_height: float = 720.0
# Each Vector4 stores a platform as (x, y, width, height) in tile-local coordinates.
@export var platform_rects: PackedVector4Array = PackedVector4Array()
@export var platform_color: Color = Color(0.08, 0.32, 0.43, 1.0)
@export var edge_color: Color = Color(0.36, 0.91, 1.0, 1.0)

func _ready() -> void:
	for index in range(platform_rects.size()):
		var data := platform_rects[index]
		var rect := Rect2(Vector2(data.x, data.y), Vector2(data.z, data.w))
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			push_warning("Ignoring a tile platform with a non-positive size.")
			continue

		var body := StaticBody2D.new()
		body.name = "Platform_%02d" % index
		body.collision_layer = 1
		body.collision_mask = 1
		body.position = rect.position + rect.size * 0.5
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		var collision := CollisionShape2D.new()
		collision.shape = shape
		body.add_child(collision)
		add_child(body)

		var visual := Polygon2D.new()
		visual.name = "PlatformVisual_%02d" % index
		visual.polygon = PackedVector2Array([
			Vector2(-rect.size.x * 0.5, -rect.size.y * 0.5),
			Vector2(rect.size.x * 0.5, -rect.size.y * 0.5),
			Vector2(rect.size.x * 0.5, rect.size.y * 0.5),
			Vector2(-rect.size.x * 0.5, rect.size.y * 0.5),
		])
		visual.position = body.position
		visual.color = platform_color if index % 2 == 0 else platform_color.lightened(0.08)
		visual.z_index = 1
		add_child(visual)

		var edge := Line2D.new()
		edge.name = "PlatformEdge_%02d" % index
		edge.points = PackedVector2Array([
			Vector2(rect.position.x, rect.position.y),
			Vector2(rect.end.x, rect.position.y),
		])
		edge.width = 4.0
		edge.default_color = edge_color
		edge.z_index = 2
		add_child(edge)
