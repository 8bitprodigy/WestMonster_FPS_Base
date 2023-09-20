extends Node3D

@onready var connect_menu = $CanvasLayer/ConnectMenu
@onready var address_entry = $CanvasLayer/ConnectMenu/MarginContainer/VBoxContainer/AddressEntry
@onready var network_option = $CanvasLayer/ConnectMenu/MarginContainer/VBoxContainer/NetworkOption
@onready var hud = $CanvasLayer/HUD
@onready var health_bar = $CanvasLayer/HUD/HealthBar

const _Player = preload("res://entities/characters/player.tscn")

const PORT = 27015
var enet_peer = ENetMultiplayerPeer.new()

func _ready():
	Game.spawn_path = $entities.get_path()

func _unhandled_input(_event):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()


func _on_host_button_pressed():
	connect_menu.hide()
	hud.show()
	Game.host(network_option.selected)


func _on_join_button_pressed():
	connect_menu.hide()
	hud.show()
	Game.join(network_option.selected,address_entry.text)

func add_player(peer_id):
	var player = _Player.instantiate()
	player.name = str(peer_id)
	get_node("entities").add_child(player)
	player.global_position = Vector3.ZERO
	player.velocity = Vector3.ZERO

func remove_player(peer_id):
	prints("Peer Disconnected: ", peer_id)
	var player = get_node("entities").get_node_or_null(str(peer_id))
	prints("Player: ", player)
	if player:
		prints("Freeing Player.")
		player.queue_free()

func update_health_bar(health_value):
	health_bar.value = health_value

func _on_multiplayer_spawner_spawned(node):
	if node.is_multiplayer_authority():
		node.health_changed.connect(update_health_bar)
	pass # Replace with function body.

func upnp_setup():
	var upnp = UPNP.new()
	
	var discover_result = upnp.discover()
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, "UPNP Discover Failed! Error %s" % discover_result)
	
	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), "UPNP Invalid Gateway!")
	
	var map_result = upnp.add_port_mapping(PORT,PORT,"Godot_FPS","UDP",0)
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, "UPNP Port Mapping Failed! Error %s" % map_result)
	
	prints("Success! Join Addres: %s" % upnp.query_external_address())
