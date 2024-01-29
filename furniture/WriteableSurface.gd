extends Node3D

@export var label_text: String:
	set(val):
		$Label3D.text = val
		if multiplayer != null:
			if multiplayer.is_server():
				sync_label_text.rpc(val)
		
	get:
		return $Label3D.text

@onready var light: Node3D = $Light
@onready var writer_spot: Node3D = $WriterSpot

func _ready():
	light.visible = false
	var max_angle_degrees = 30
	var random_radians = randf() * deg_to_rad(max_angle_degrees)
	if randi() % 2 == 0:
		random_radians = random_radians * -1
	$Label3D.rotate_object_local(Vector3(0, 0, 1), random_radians)

func _process(delta):
	pass

@rpc
func sync_label_text(text):
	label_text = text

func set_illuminate(active: bool):
	light.visible = active
