extends Node3D

func _ready():
	pass # Replace with function body.

func _process(delta):
	rotation.y += delta * 0.5

@rpc("reliable","call_local")
func collect():
	queue_free()
