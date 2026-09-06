extends StaticBody2D
class_name Block

@onready var ray_cast_2d: RayCast2D = $RayCast2D

var onMove = false

const TILE_SIZE = 16

func _ready() -> void:
	ray_cast_2d.target_position = Vector2.DOWN * TILE_SIZE

#func _on_player_pushed_block(direction: Vector2) -> void:
func pushed(direction: Vector2):
	if onMove: return
	ray_cast_2d.target_position = direction * TILE_SIZE
	ray_cast_2d.force_raycast_update()
	if ray_cast_2d.is_colliding():
		return
		
	var targetPosition = global_position + direction * TILE_SIZE
	_move_to(targetPosition)
	
func _move_to(targetPosition):
	onMove = true
	var tween = create_tween()
	tween.tween_property(self, "global_position", targetPosition, 0.3)
	await tween.finished
	onMove = false
