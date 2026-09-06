extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var ray_cast_2d: RayCast2D = $RayCast2D

# Constants determining Tile Size and Speed of movement.
const TILE_SIZE = 16
const SPEED = 300.0

# Variables that check whether the player is moving or not.
var onMove = false
var currentDirection: Vector2
var lastDirection: Vector2

var teleporterJustUsed = false

func _ready() -> void:
	ray_cast_2d.target_position = Vector2.DOWN * TILE_SIZE

func _physics_process(_delta: float) -> void:
	if onMove:
		return
		
	if _has_forced_movement():
		return
	
	_use_teleporter()
	_normal_movement()
	_set_animation()
	
	lastDirection = currentDirection

# Directional keys for movement.
func _normal_movement():
	var direction: Vector2
	
	if Input.is_action_pressed("ui_up"):
		direction = Vector2.UP
	elif Input.is_action_pressed("ui_down"):
		direction = Vector2.DOWN
	elif Input.is_action_pressed("ui_left"):
		direction = Vector2.LEFT
	elif Input.is_action_pressed("ui_right"):
		direction = Vector2.RIGHT
	
	currentDirection = direction
	
	if direction:
		if direction:
			ray_cast_2d.target_position = direction * TILE_SIZE
			ray_cast_2d.force_raycast_update()
		
		# Checks if the player collision is colliding. If yes, returns.
		if ray_cast_2d.is_colliding():
			_is_pushing_block()
			if not _not_cliff_face():
				return
		
		# Computes the next target position of the player.
		var targetPosition = global_position + direction * TILE_SIZE
		
		_move_to(targetPosition)

func _move_to(targetPosition):
	onMove = true
	
	var tween = create_tween()
	tween.tween_property(self, "global_position", targetPosition, 0.3)
	await tween.finished
	onMove = false
	teleporterJustUsed = false

func _set_animation():
	if not ray_cast_2d.is_colliding() or _not_cliff_face():
		if currentDirection.x > 0:
			animated_sprite_2d.flip_h = false
			animated_sprite_2d.play("run_side")
		elif currentDirection.x < 0:
			animated_sprite_2d.flip_h = true
			animated_sprite_2d.play("run_side")
		elif currentDirection.y < 0:
			animated_sprite_2d.play("run_up")
		elif currentDirection.y > 0:
			animated_sprite_2d.play("run_down")
		else:
			_idle_animation()
	else:
		_idle_animation()

# set to idle animation
func _idle_animation():
	if lastDirection.x > 0:
		animated_sprite_2d.flip_h = false
		animated_sprite_2d.play("idle_side")
	elif lastDirection.x < 0:
		animated_sprite_2d.flip_h = true
		animated_sprite_2d.play("idle_side")
	elif lastDirection.y < 0:
		animated_sprite_2d.play("idle_up")
	elif lastDirection.y > 0:
		animated_sprite_2d.play("idle_down")
			
# checks if player is on tiles that force movement
func _has_forced_movement():
	var ice_tilemap = get_node("/root/Game/TileMap/Ice")
	var arrow_tilemap = get_node("/root/Game/TileMap/Arrows")
	
	if ice_tilemap:
		var cell = ice_tilemap.local_to_map(position)
		var data = ice_tilemap.get_cell_tile_data(cell)
		if data:
			var is_ice = data.get_custom_data("is_ice")
			if is_ice:
				if currentDirection:
					ray_cast_2d.target_position = currentDirection * TILE_SIZE
					ray_cast_2d.force_raycast_update()
				if ray_cast_2d.is_colliding(): return false
				
				var targetPosition = global_position + currentDirection * TILE_SIZE
				lastDirection = currentDirection
				_idle_animation()
				_move_to(targetPosition)
				return true

	if arrow_tilemap:
		var cell = arrow_tilemap.local_to_map(position)
		var data = arrow_tilemap.get_cell_tile_data(cell)
		if data:
			var is_arrow = data.get_custom_data("is_arrow")
			if is_arrow:
				var arrow_direction = data.get_custom_data("arrow_direction")
				if arrow_direction:
					ray_cast_2d.target_position = arrow_direction * TILE_SIZE
					ray_cast_2d.force_raycast_update()
				if ray_cast_2d.is_colliding(): return false
				
				var targetPosition = global_position + arrow_direction * TILE_SIZE
				lastDirection = arrow_direction
				_idle_animation()
				_move_to(targetPosition)
				
				return true

func _not_cliff_face():
	var cliff_tilemap = get_node("/root/Game/TileMap/OneWay")
	
	if cliff_tilemap:
		var cell = cliff_tilemap.local_to_map(position + currentDirection*TILE_SIZE)
		var data = cliff_tilemap.get_cell_tile_data(cell)
		if data:
			var is_cliff = data.get_custom_data("is_cliff")
			if is_cliff:
				var cliff_barrier = data.get_custom_data("cliff_barrier")
				if currentDirection == Vector2.UP or currentDirection == Vector2.DOWN:
					if currentDirection.y == cliff_barrier.y:
						return false
				elif currentDirection == Vector2.LEFT or currentDirection == Vector2.RIGHT:
					if currentDirection.x == cliff_barrier.x:
						return false
				return true
	return false

func _use_teleporter():
	var teleporter_tilemap = get_node("/root/Game/TileMap/TeleportDevice")
	var teleportTo: int
	var cellTo
	const posCorrecter := Vector2(-8,-8)
	
	if teleporter_tilemap:
		if !teleporterJustUsed:
			var cell = teleporter_tilemap.local_to_map(position)
			var data = teleporter_tilemap.get_cell_tile_data(cell)
			if data:
				var is_teleporter = data.get_custom_data("is_teleporter")
				if is_teleporter:
					if data.get_custom_data("id") == 1:
						teleportTo = 2
					elif data.get_custom_data("id") == 2:
						teleportTo = 1
					for outCell in teleporter_tilemap.get_used_cells():
						var outData = teleporter_tilemap.get_cell_tile_data(outCell)
						if outData.get_custom_data("id") == teleportTo:
							cellTo = outCell
							break
					position = teleporter_tilemap.map_to_local(cellTo) + posCorrecter
					teleporterJustUsed = true
				
func _is_pushing_block():
	if ray_cast_2d.get_collider() is Block or ray_cast_2d.get_collider() is NPC:
		ray_cast_2d.get_collider().pushed(currentDirection)
		return true
	
