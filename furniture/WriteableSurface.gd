extends Node3D

var label_text:
	set(val):
		$Label3D.text = val
	get:
		return $Label3D.text

func _ready():
	label_text = "Example Text that could be written by player 2"

func _process(delta):
	pass
