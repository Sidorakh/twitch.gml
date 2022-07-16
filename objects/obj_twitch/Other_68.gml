/// @description 

if (is_undefined(server)) return;
if (async_load[? "type"] == network_type_connect) {
	if (async_load[? "id"] == server) {
		twitch_client_socket = async_load[? "socket"];
	}
}
if (async_load[? "type"] == network_type_data) {
	if (async_load[? "id"] == twitch_client_socket) {
		var data = buffer_read(async_load[? "buffer"],buffer_text);
		data = string_delete(data,string_pos("\n",data),string_length(data));
		show_debug_message(data);
		data = string_replace(data,"GET /?","");
		data = string_replace(data," HTTP/1.1","");
		var url = url_parse(data);
		
		if (url.query[$ "error"] != undefined)  {
			show_message("oh boy. error: " + string(url.query.error));
			var response= "";
			response += "HTTP/1.1 401 Unauthorized\n";
			response += "Content-Type: text/plain";
			response += "\n\nAuthorisation failed. Error: " + string(url.query.error);
		
			var buff = buffer_create(string_length(response),buffer_fixed,1);
			buffer_write(buff,buffer_text,response);
			network_send_raw(twitch_client_socket,buff,buffer_tell(buff));
			buffer_delete(buff);
			return;
		}
		var code = url.query.code;
		
		var response = "";
		response += "HTTP/1.1 200 OK\n";
		response += "Content-Type: text/plain";
		response += "\n\nAuthorisation complete. You may now close this tab";
		
		var buff = buffer_create(string_length(response),buffer_fixed,1);
		buffer_write(buff,buffer_text,response);
		network_send_raw(twitch_client_socket,buff,buffer_tell(buff));
		buffer_delete(buff);
		/// feather ignore once GM1041
		network_destroy(server);
		show_debug_message(string(code) + " - " + "exchanging code");
		struct.exchange_code(code,twitch_auth_callback);
	}
}

