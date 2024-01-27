extends CharacterBody3D

const SPEED = 22.0
const ROTATION_SPEED = 5.0
const JUMP_VELOCITY = 10.0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var gravity_vector = ProjectSettings.get_setting("physics/3d/default_gravity_vector")

var pid: int
var nametag: String = ""

var buffered_sync: BufferedSync

var jump_requested: bool = false
var x_movement: float = 0.0
var z_movement: float = 0.0

var last_x_input: float
var last_z_input: float

var state_key: String

func _ready():
	buffered_sync = get_node("../../../BufferedSync")
	state_key = "%d" % pid
	if multiplayer.get_unique_id() == pid:
		$Camera3D.make_current()
		$InitPopup.popup_centered_ratio.call_deferred(0.5)
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


@rpc("any_peer")
func do_a_jump():
	if multiplayer.get_remote_sender_id() != pid:
		return
	jump_requested = true
	
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


func _unhandled_input(event):
	if multiplayer.get_unique_id() != pid:
		return
	
	if event.is_action_pressed("ui_accept"):
		do_a_jump.rpc_id(1)

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
	if not s.valid and buffered_sync.got_initial_state:
		push_warning("no valid sync state")
		return
	
	position = s.start_state["p"].lerp(s.end_state["p"], s.progress)
	rotation = s.start_state["r"].lerp(s.end_state["r"], s.progress)

func _physics_process(delta):
	if not multiplayer.is_server():
		_apply_sync_state()
		return
		
	# Add the gravity.
	if not is_on_floor():
		velocity += gravity_vector * gravity * delta
		
	if jump_requested and is_on_floor():
		velocity.y = JUMP_VELOCITY
	jump_requested = false
	
	# for simplicity, x movement will just rotate
	if x_movement:
		rotate_y(ROTATION_SPEED * delta * x_movement * -1.0)
	
	if z_movement:
		var v := Vector3(0, 0, z_movement * SPEED).rotated(Vector3(0, 1, 0), rotation.y)
		velocity.z = v.z
		velocity.x = v.x
	else:
		var v := Vector3(0, 0, 0)
		velocity.z = v.z
		velocity.x = v.x

	move_and_slide()
	
	buffered_sync.amend_server_state(state_key, {
		"p": position,
		"r": rotation
	})
