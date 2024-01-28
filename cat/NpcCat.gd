extends PlayerBase

var decision_time: float = 0.0
var move_factor := 1.0
var rotate_delta := 0.0

var base_speed := 4
var receiving_pets := false

@export var true_cat := false

@onready var hearts: CPUParticles3D = $Hearts

func _ready():
	hearts.emitting = false
	buffered_sync = get_node("../../../BufferedSync")
	state_key = get_path()

func _input(event):
	pass

func _unhandled_input(event):
	pass

func _process(delta):
	super._process(delta)
	if not multiplayer.is_server():
		return
	
	decision_time -= delta
	if decision_time < 0.0:
		decision_time = randf_range(1.0, 5.0)
		speed = base_speed * randf_range(0.3, 1.3)
		
		if randi() % 3 == 0:
			speed = 0.0
		else:
			speed = base_speed * randf_range(0.3, 1.3)
			
		if randi() % 2 == 0:
			rotate_delta = 0.0
		else:
			rotate_delta = randf_range(-2, 2)
	
	if receiving_pets:
		z_movement = 0.0
		return
	
	z_movement = 1.0
	y_rotation += rotate_delta * delta

@rpc("call_local")
func set_hearts(active: bool):
	hearts.emitting = active

func receive_pets(duration: float):
	receiving_pets = true
	set_hearts.rpc(true)
	await get_tree().create_timer(duration).timeout
	set_hearts.rpc(false)
	receiving_pets = false

func _physics_process(delta):
	super._physics_process(delta)
