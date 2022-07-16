/// @description 

if (!variable_instance_exists(self,"struct")) {
	// kills the warning
	struct = {};
}

server = undefined;
twitch_client_socket = undefined;
twitch_auth_callback = undefined;

function setup_http_server(port,cb){
    server = network_create_server_raw(network_socket_tcp,port,32);
	twitch_auth_callback = cb;
}

