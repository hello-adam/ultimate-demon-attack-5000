extends CharacterBody3D
class_name PlayerBase

var speed = 22.0
var jump_velocity = 10.0

var mouse_sensitivity = 0.15

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var gravity_vector = ProjectSettings.get_setting("physics/3d/default_gravity_vector")

var pid: int = -1
var nametag: String = ""

var buffered_sync: BufferedSync

var interacting: bool = false
var interact_requested: bool = false
var x_movement: float = 0.0
var z_movement: float = 0.0
var y_rotation: float = 0.0

var last_x_input: float = 0.0
var last_z_input: float = 0.0

var state_key: String

func _ready():
	buffered_sync = get_node("../../../BufferedSync")
	state_key = "%d" % pid
	if multiplayer.get_unique_id() == pid:
		$Camera3D.make_current()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

@rpc("any_peer")
func do_interact():
	if multiplayer.get_remote_sender_id() != pid:
		return
	interact_requested = true
	
@rpc("any_peer")
func set_x_movement(amount: float):
	if multiplayer.get_remote_sender_id() != pid:
		return
	x_movement = clampf(amount, -1.0, 1.0)
	
@rpc("any_peer")
func set_z_movement(amount: float):
	if multiplayer.get_remote_sender_id() != pid:
		return
	z_movement = clampf(amount, -1.0, 1.0)

@rpc("any_peer")
func add_y_rotation(amount: float):
	if multiplayer.get_remote_sender_id() != pid:
		return
	y_rotation += amount

@rpc("call_local")
func set_interacting(active: bool):
	interacting = active

func _input(event):
	if multiplayer.get_unique_id() != pid:
		return
	# don't do physics if interacting
	if interacting:
		return
	if event is InputEventMouseMotion:
		add_y_rotation.rpc_id(1, -1 * deg_to_rad(event.relative.x * mouse_sensitivity))

func _unhandled_input(event):
	if multiplayer.get_unique_id() != pid:
		return
	
	if event.is_action_pressed("ui_accept"):
		do_interact.rpc_id(1)

func _process(delta):
	if multiplayer.get_unique_id() != pid:
		return
	var x_input = Input.get_axis("ui_left", "ui_right")
	if x_input != last_x_input:
		set_x_movement.rpc_id(1, x_input)
		last_x_input = x_input
	
	var z_input = Input.get_axis("ui_up", "ui_down")
	if z_input != last_z_input:
		set_z_movement.rpc_id(1, z_input)
		last_z_input = z_input

func _apply_sync_state():
	var s = buffered_sync.get_state(state_key)
	if not s.valid:
		if buffered_sync.got_initial_state:
			push_warning("no valid sync state")
		return
	if s.start_state != null and s.end_state != null:
		position = s.start_state["p"].lerp(s.end_state["p"], s.progress)
		rotation = s.start_state["r"].lerp(s.end_state["r"], s.progress)

func _physics_process(delta):
	if not multiplayer.is_server():
		_apply_sync_state()
		return
	
	# don't do physics if interacting
	if interacting:
		return
	
	# Add the gravity.
	if not is_on_floor():
		velocity += gravity_vector * gravity * delta
	
	rotation.y = y_rotation
	
	var movement := Vector3(0, 0, 0)
	if x_movement:
		movement += Vector3(x_movement, 0, 0)
	if z_movement:
		movement += Vector3(0, 0, z_movement)
	
	if movement.length_squared() > 0:
		movement = movement.rotated(Vector3(0, 1, 0), rotation.y)
		movement = movement.normalized() * speed
		
	velocity.z = movement.z
	velocity.x = movement.x

	move_and_slide()
	
	buffered_sync.amend_server_state(state_key, {
		"p": position,
		"r": rotation
	})
