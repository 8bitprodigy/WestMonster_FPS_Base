extends InputHandler
class_name MouseCaptureInputHandler


var captured : bool = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	parent.add_user_signal( "mouse_captured", [ { "name" : "captured", "type" : TYPE_BOOL} ])
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	set_enabled(enabled)


func handle_input( event : InputEvent ) -> void:
	if !enabled: return
	if event is InputEventKey and Input.is_action_just_pressed("scoreboard"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		captured = false
	if event is InputEventMouseButton:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		captured = true
	
	super.handle_input(event)
