class_name FurnitureDefinition
extends Resource

@export var sprite_w: int = 32
@export var sprite_h: int = 32
## 0 = horizontal strip (one row), 1 = vertical strip (one column), N = N-column grid
@export var columns: int = 1
@export var footprint_size: Vector2 = Vector2.ZERO
@export var hotspot_specs: Array[HotspotSpec] = []
