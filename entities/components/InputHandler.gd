extends WM_Component
class_name InputHandler


var character : CharacterBody3D

signal handled_input(event:InputEvent)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !(parent is InputSynchronizer) and !(parent is InputHandler):
		super.set_enabled( false )
		return
	if !enabled: return
	set_enabled(enabled)
	character = parent.character


func set_enabled( enabled_status : bool ) -> void:
	super.set_enabled( enabled_status )
	if !parent: return
	if enabled_status:
		parent.handled_input.connect( handle_input, 1 )
	else:
		parent.handled_input.disconnect( handle_input )


func handle_input( event : InputEvent ) -> void:
	emit_signal( "handled_input", event)
