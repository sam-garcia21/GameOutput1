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

func _physics_process(_delta: float) -> void:
	if onMove:
		return
		
	if has_forced_movement():
		return
	
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
		if ray_cast_2d.is_colliding(): return
		
		# Computes the next target position of the player.
		var targetPosition = global_position + direction * TILE_SIZE
		
		_move_to(targetPosition)

func _move_to(targetPosition):
	onMove = true
	
	var tween = create_tween()
	tween.tween_property(self, "global_position", targetPosition, 0.3)
	await tween.finished
	
	onMove = false

func _set_animation():
	if not ray_cast_2d.is_colliding():
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
			idle_animation()
	else:
		idle_animation()

# conditions for idle animation
# TODO: need idle for left and right i think not just side
func idle_animation():
	if lastDirection.x:
		animated_sprite_2d.play("idle_side")
	elif lastDirection.y < 0:
		animated_sprite_2d.play("idle_up")
	elif lastDirection.y > 0:
		animated_sprite_2d.play("idle_down")
			
func has_forced_movement():
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
				
				# Checks if the player collision is colliding. If yes, returns.
				if ray_cast_2d.is_colliding(): return false
				
				# Computes the next target position of the player.
				var targetPosition = global_position + currentDirection * TILE_SIZE
				
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
				
				# Checks if the player collision is colliding. If yes, returns.
				if ray_cast_2d.is_colliding(): return false
				
				# Computes the next target position of the player.
				var targetPosition = global_position + arrow_direction * TILE_SIZE
				
				_move_to(targetPosition)
				return true
