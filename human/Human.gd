extends PlayerBase

func _ready():
	super._ready()
	if multiplayer.get_unique_id() == pid:
		$InitPopup.popup_centered_ratio.call_deferred(0.5)

func _input(event):
	super._input(event)

func _unhandled_input(event):
	super._unhandled_input(event)

func _process(delta):
	super._process(delta)

func _physics_process(delta):
	super._physics_process(delta)
