extends Node
#class_name Game


const _Player : PackedScene = preload("res://entities/characters/player.tscn")

enum{
	INTERNET,
	LOCAL
}

const PORT : int = 9999 #27015
var enet_peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()
var spawn_path : NodePath = ""

func _ready():
	'''var upnp = UPNP.new()
	var discover_result = upnp.discover()
	
	if discover_result == UPNP.UPNP_RESULT_SUCCESS:
		if upnp.get_gateway() and upnp.get_gateway().is_valid_gateway():
			
			var map_result_udp = upnp.add_port_mapping(PORT,PORT,"godot_udp","UDP",0)
			var map_result_tcp = upnp.add_port_mapping(PORT,PORT,"godot_tcp","TCP",0)
			
			if not map_result_udp == UPNP.UPNP_RESULT_SUCCESS:
				upnp.add_port_mapping(PORT,PORT,"","UDP")
			if not map_result_tcp == UPNP.UPNP_RESULT_SUCCESS:
				upnp.add_port_mapping(PORT,PORT,"","TCP")
	
	var external_ip = upnp.query_external_address()
	
	upnp.delete_port_mapping(PORT,"UDP")
	upnp.delete_port_mapping(PORT,"TCP")'''
	pass


func host(network_option:int):
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	add_player(multiplayer.get_unique_id())
	
	if network_option == 0:
		upnp_setup()
	pass # Replace with function body.

func join(network_option:int,address_entry:String):
	
	if network_option == INTERNET:
		enet_peer.create_client(address_entry, PORT)
	if network_option == LOCAL:
		enet_peer.create_client("localhost", PORT)
	
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(
		func(peer_id):
			await get_tree().create_timer(1).timeout
			rpc("add_player",peer_id)
	)
	#multiplayer.peer_disconnected.connect(remove_player)
	add_player(multiplayer.get_unique_id())

@rpc
func add_player(peer_id):
	var player = _Player.instantiate()
	player.name = str(peer_id)
	get_node(spawn_path).add_child(player)
	player.global_position = Vector3.ZERO
	player.velocity = Vector3.ZERO

func remove_player(peer_id):
	prints("Peer Disconnected: ", peer_id)
	var player = get_node(spawn_path).get_node_or_null(str(peer_id))
	prints("Player: ", player)
	if player:
		prints("Freeing Player.")
		player.queue_free()

func upnp_setup():
	var upnp = UPNP.new()
	
	var discover_result = upnp.discover()
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, "UPNP Discover Failed! Error %s" % discover_result)
	
	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), "UPNP Invalid Gateway!")
	
	var map_result = upnp.add_port_mapping(PORT,PORT,"Godot_FPS","UDP",0)
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, "UPNP Port Mapping Failed! Error %s" % map_result)
	
	prints("Success! Join Addres: %s" % upnp.query_external_address())
