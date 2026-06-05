class_name SurfaceFurniture
extends Furniture

func _init() -> void:
	surface_mount_enabled = true

func uses_surface_mount_rendering() -> bool:
	return true
