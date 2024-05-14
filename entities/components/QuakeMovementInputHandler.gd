extends MovementInputHandler
class_name QuakeMovementInputHandler


# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	var nextVelocity: Vector3 = Vector3.ZERO
	nextVelocity.x = character.velocity.x
	nextVelocity.z = character.velocity.z
	nextVelocity = friction(   nextVelocity, delta ) 
	nextVelocity = accelerate( nextVelocity, ACCELERATION, speed, delta )
	
	super._physics_process(delta)


func accelerate( input_velocity: Vector3, accel: float, max_speed: float, delta: float) -> Vector3:
	var wish_direction      : Vector3 = Vector3(  cos(look_input_handler.look_vector.x), 0, sin( look_input_handler.look_vector.x ) )
	var current_speed : float   = input_velocity.dot( wish_direction ) 
	
	var add_speed: float = clamp( max_speed - current_speed, 0, accel * delta )
	
	return input_velocity + wish_direction * add_speed


func friction( input_velocity: Vector3, delta: float ) -> Vector3:
	var speed: float = input_velocity.length()
	var scaled_velocity: Vector3
	
	if speed != 0:
		var drop = speed * FRICTION * delta
		scaled_velocity = input_velocity * max( speed - drop, 0 ) / speed
	
	if speed < 0.1:
		return scaled_velocity * 0
	return scaled_velocity
