extends RigidBody3D

var is_on_floor = false
var ride_spring_strength = 800.0
var ride_spring_damper = 100.0
var m_goal_vel = Vector3.ZERO
var speed_factor = Vector3(1, 0, 1)

func _ready():
	pass # Replace with function body.


func _integrate_forces(state: PhysicsDirectBodyState3D):
	var delta = state.step
#	($ShapeCast3d as ShapeCast3D).force_shapecast_update()

	is_on_floor = $ShapeCast3d.is_colliding()
	var is_on_slope = false
	var floor_normal = Vector3.UP
	if is_on_floor:
		var collision_safe_fraction = $ShapeCast3d.get_closest_collision_safe_fraction()
		if collision_safe_fraction == 1.0:
			collision_safe_fraction = 0.0
		var velocity = linear_velocity
		var ray_dir = Vector3.DOWN

		var other_velocity = Vector3.ZERO

		var ray_dir_velocity = ray_dir.dot(velocity)
		var other_dir_velcoity = ray_dir.dot(other_velocity)

		var rel_velocity = ray_dir_velocity - other_dir_velcoity

		var ride_height = .5
		var ride_hit_distance = (1 * collision_safe_fraction) - ride_height
		var x = ride_hit_distance
		var spring_force = (x * ride_spring_strength) - (rel_velocity * ride_spring_damper)
		
		var collision_normal = $ShapeCast3d.get_collision_normal(0)
		floor_normal = collision_normal
		var collision_angle = collision_normal.angle_to(Vector3.UP)
		
		constant_force = Vector3.ZERO
		
#		if collision_angle >= .5:
#			is_on_slope = true
		constant_force += (Vector3.DOWN * 9.8 * mass).slide(collision_normal)
#			constant_force += (Vector3.DOWN * 9.8 * mass).slide(collision_normal)

		constant_force += (Vector3.DOWN * spring_force)
	else:
		constant_force = Vector3.DOWN * 9.8 * mass
	var input_vector = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
#	constant_force += Vector3.BACK * input_vector.y * 10
#	constant_force += Vector3.RIGHT * input_vector.x * 10


# desired direction
	var m_unit_goal = Vector3(input_vector.x, 0, input_vector.y)
	var acceleration = 8.0 if is_on_floor else 0.2
	var max_speed = 3.0
	var max_acceleration_force = 10.0

	# current direction
	var unit_vel = m_goal_vel.normalized()
	# difference between desired direction and current direction
	var vel_dot = m_unit_goal.dot(unit_vel)

#	var accel = acceleration * ((settings.acceleration_factor_from_dot as Curve).interpolate(vel_dot) + 1 / 2)
	var accel = acceleration
	var goal_vel = m_unit_goal * max_speed * speed_factor

	m_goal_vel = m_goal_vel.move_toward(goal_vel, accel * delta)

	var needed_accel = (m_goal_vel - (state.linear_velocity * Vector3(1, 0, 1))) / delta
	var max_accell = max_acceleration_force * Vector3(1, 0, 1)

	needed_accel = needed_accel.normalized() * min(needed_accel.length(), max_accell.length())
	needed_accel.y = 0.0
	constant_force += (needed_accel * mass).slide(floor_normal)
