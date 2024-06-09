extends Node2D

@export var PlayerScene: PackedScene

var players = {}
var player_info = {"name": ""}

const PORT = 7000
const ADDRESS = "127.0.0.1"

# Called when the node enters the scene tree for the first time.
func _ready():
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.connected_to_server.connect(connected_to_server)

func _on_name_text_changed(new_text):
	player_info["name"] = new_text
	
func _on_host_pressed():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, 20)
	if error:
		return error
	multiplayer.multiplayer_peer = peer
	$Menu/Name.visible = false
	players[multiplayer.get_unique_id()] = player_info

func _on_join_pressed():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ADDRESS, PORT)
	if error:
		print(error)
		return error
	multiplayer.multiplayer_peer = peer
	$Menu/Name.visible = false

func peer_connected(id):
	print("Player joined: ", id)
	register.rpc_id(id, player_info)
	
@rpc("any_peer", "reliable")
func register(new_player_info):
	players[multiplayer.get_remote_sender_id()] = new_player_info
	
# Only the client joining the server runs this
func connected_to_server():
	print("Connected to server")
	players[multiplayer.get_unique_id()] = player_info

func _on_start_pressed():
	print(players)
	start.rpc(players)
	
@rpc("authority", "call_local")
func start(nplayers):
	players = nplayers
	$Menu.visible = false
	for i in nplayers:
		var cPlayer = PlayerScene.instantiate()
		cPlayer.set_multiplayer_authority(i)
		cPlayer.global_position = $SpawnPoint.global_position
		add_child(cPlayer)
		
