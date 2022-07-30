global.__twitch_scopes = {
	analytics: {
		read: {
			extensions: "analytics:read:extensions",
			games: "analytics:read:games",
		},
	},
	bits: {
		read: "bits:read",
	},
	channel: {
		edit: {
			commercial: "channel:edit:commercial",	
		},
		manage: {
			broadcast: "channel:manage:broadcast",
			extensions: "channel:manage:extensions",
			polls: "channel:manage:polls",
			predictions: "channel:manage_predictions",
			raids: "channel:manage:raids",
			redemptions: "channel:manage:redemptions",
			schedule: "channel:manage:schedule",
			videos: "channel:manage:videos",
		},
		read: {
			editors: "channel:read:editors",
			goals: "channel:read:goals",
			hype_train: "channel:read:hype_train",
			polls: "channel:read:polls",
			predictions: "channel:read:predictions",
			redemptions: "channel:read:redemptions",
			stream_key: "channel:read:stream_key",
			subscriptions: "channel:read:subscriptions",
		},
		moderate: "channel:moderate",
	},
	chat: {
		edit: "chat:edit",
		read: "chat:read",	
	},
	clips: {
		edit:"clips:edit"
	},
	moderation: {
		read: {
			all: "moderation:read",
			blocked_terms: "moderation:read:blocked_terms",
			automod_settings: "moderation:read:automod_settings",
			chat_settings: "moderation:read:chat_settings",
		},
		manage: {
			banned_users:"moderation:manage:banned_users",
			blocked_terms: "moderation:manage:blocked_terms",
			automod: "moderation:manage:automod",
			chat_settings: "moderation:manage:chat_settings",
		}
	},
	user: {
		edit: {
			all: "user:edit",
		},
		manage: {
			blocked_users: "user:manage:blocked_users",	
		},
		read: {
			blocked_users: "user:read:blocked_users",
			broadcast: "user_read_broadcast",
			email: "user:read:email",
			subscriptions: "user:read:subscriptions",
		}
	},
	whispers: {
		read: "whispers:read",
		edit: "whispers:edit",
	}
}

function twitch_scope() {
	return global.__twitch_scopes;
}

function Twitch() constructor {
	client_id  ="";
	client_secret = "";
	scopes = "";
	scope_lut = {};
	redirect_uri = "http://localhost:3000";
	instance = instance_create_depth(0,0,0,obj_twitch);
	instance.struct = self;
	ready = false;
	port = 3000;
	token = {
		access:"",
		refresh:"",
		expires_at:0,
	}
	user_data = {
		broadcaster_type:"",
		created_at: "",
		description: "",
		display_name:"",
		email: "",
		id:0,
		login:"",
		profile_image_url:"",
		type: "",
		view_count: 0,
	};
	polls = [];
	goals = [];
	save_token_fn = undefined;
	load_token_fn = undefined;
	function init(_client_id,_client_secret,_scopes,_port=3000) {
		client_id =_client_id;
		client_secret =_client_secret;
		scopes = url_encode(array_join(_scopes," "));
		for (var i=0;i<array_length(_scopes);i++) {
			scope_lut[$ _scopes[i]] = true;
		}
		port = _port;
		redirect_uri = "http://localhost:"+string(port) + "/";
		
	}
	function authorize(cb=function(){}) {
		var auth_url = "https://id.twitch.tv/oauth2/authorize?";
		/*
		var querystring = "response_type=code"+
						  "&client_id="+string(client_id) + 
						  "&redirect_uri="+string(redirect_uri) +
						  "&scope=" + scopes;
		*/
		var querystring = qs_encode({
			response_type: "code",
			client_id: client_id,
			redirect_uri: redirect_uri,
			scope: scopes,
		});
		url_open(auth_url + querystring);
		instance.setup_http_server(port,cb);
	}
	function api_headers(){
		return struct_to_map({
			"Authorization": "Bearer " + token.access,
			"Client-ID": client_id,
		});
	}
	function exchange_code(code,cb) {
		var body = qs_encode({
			client_id: client_id,
			client_secret: client_secret,
			code: code,
			grant_type: "authorization_code",
			redirect_uri: redirect_uri,
		});
		
		var map = ds_map_create();
		map[? "Content-Type"] = "application/x-www-form-urlencoded";
		var options = {
			headers: map,
			keep_header_map: false,
			callback: cb,
		}
		http("https://id.twitch.tv/oauth2/token","POST",body,options,function(status,result,options) {
			result = json_parse(result);
			token.access = result.access_token;
			token.refresh = result.refresh_token;
			// token is expired after this time
			token.expires_at = date_inc_second(date_current_datetime(),real(result.expires_in));
			// yup, we're passing this along further
			get_user_data(options.callback);
		});
	}
	function get_user_data(cb=function(){}){
		var options = {
			headers: api_headers(),
			callback:cb,
		}
		http("https://api.twitch.tv/helix/users","GET","",options,function(status,result,options){
			result = json_parse(result);
			if (result[$ "data"] != undefined) {
				result = result.data[0];
				user_data.broadcaster_type = result.broadcaster_type;
				user_data.created_at = result.created_at;
				user_data.description = result.description;
				user_data.display_name = result.display_name;
				user_data.email = result[$ "email"] == undefined ? "" : result.email;
				// feather ignore once GM1008
				user_data.id = result.id;
				user_data.login = result.login;
				user_data.profile_image_url = result.profile_image_url;
				user_data.type = result.type;
				user_data.view_count = result.view_count;
				options.callback(user_data);
			}
		});
	}
	function update_user(new_data={},cb=function(){}) {
		var query = qs_encode(new_data);
		var options = {
			headers: api_headers(),
			keep_header_map: false,
			callback: cb,
		};
		http("https://api.twitch.tv/helix/users" + "?" + query,"PUT","",options,function(status,result,options){
			if (status == 200) {
				
				options.callback();	
			}
		});
	}
	function get_user_followers(user_id=user_data.id,cb=function(){}) {
		// Gets all users that *follow* a channel
		// Has pagination. Needs handling. 
		
		var query = qs_encode({
			to_id: user_id
		})
		var options = {
			headers: api_headers(),
			keep_header_map: false,
			callback: cb,
		}
		http("https://api.twitch.tv/helix/users/follows" + "?" + query,"GET","",options,function(status,result,options){
			result = json_parse(result);
			if (status == 200) { 
				options.callback(result);
			}
		});
	}
	function get_user_follow(user_id=user_data.id,cb=function(){}) {
		// Gets all channels that a single user follows
		// Has pagination. Needs handling. 
		
		var query = qs_encode({
			from_id: user_id
		})
		var options = {
			headers: api_headers(),
			keep_header_map: false,
			callback: cb,
		}
		http("https://api.twitch.tv/helix/users/follows" + "?" + query,"GET","",options,function(status,result,options){
			result = json_parse(result);
			if (status == 200) { 
				options.callback(result);
			}
		});
	}
	function get_user_blocklist(cb) {
		var query = qs_encode({
			broadcaster_id: user_data.id,
		});
		var options = {
			headers: api_headers(),
			keep_header_map: false,
			callback: cb,
		}
		http("https://api.twitch.tv/helix/users/blocks" + "?" + query,"GET","",function(status,result,options){
			result = json_parse(result);
			if (status == 200) {
				options.callback(result);
			}
		});
	}
	function block_user(user_id,reason="",source_context="",cb=function(){}) {
		
		var query = {
			target_user_id: user_id
		}
		if (array_pos(["spam","harassment","other"],reason) == -1) {
			query.reason = reason;
		}
		if (array_pos(["whisper","chat",],source_context) == -1) {
			query.source_context = source_context;
		}
		// feather ignore once GM1043
		query = qs_encode(query);
		var options = {
			headers: api_headers(),
			keep_header_map: false,
			callback: cb,
		};
		// feather ignore once GM1009
		http("https://api.twitch.tv/helix/users/blocks" + "?" + query,"PUT","",options,function(status,result,options){
			// returns 204 on success - there is no result
			if (status == 204) {
				options.callback();	
			}
		});
	}
	function block_user(user_id,reason="",source_context="",cb=function(){}) {
		var query = qs_encode({
			target_user_id: user_id
		});
		var options = {
			headers: api_headers(),
			keep_header_map: false,
			callback: cb,
		};
		http("https://api.twitch.tv/helix/users/blocks" + "?" + query,"DELETE","",options,function(status,result,options){
			// returns 204 on success - there is no result
			if (status == 204) {
				options.callback();	
			}
		});
	}
	function get_user_extensions(cb=function(){}) {
		var options = {
			headers: api_headers(),
			keep_header_map: false,
			callback: cb,
		}
		http("https://api.twitch.tv/helix/users/extensions/list","GET","",options,function(status,result,options){
			result = json_parse(result);
			if (status == 200) {
				options.callback(result.data);
			}
		});
	}
	function refresh_access_token(cb) {
		var body = qs_encode({
			client_id: client_id,
			client_secret: client_secret,
			refresh_token: token.refresh,
			grant_type: "refresh-token",
		});
		var options = {
			headers: struct_to_map({
				"Content-Type": "application/x-www-form-urlencoded"
			}),
			keep_header_map: false,
			callback: cb,
		}
		http("https://id.twitch.tv/oauth2/token","POST",body,options,function(status,result,options) {
			show_message(json_parse(result));
		});	
	}
	
	function set_save_token_function(fn){
		save_token_fn= fn;
	}
	function set_load_token_function(fn) {
		load_token_fn = fn;
	}
	function save_token() {
		if (save_token_fn != undefined) {
			save_token_fn(token);	
			return;
		}
		// otherwise, default save
		var str = json_stringify({refresh_token:token.refresh});
		var buff = buffer_create(string_length(str),buffer_fixed,1);
		buffer_write(buff,buffer_text,str);
		buffer_save(buff,"twitch-token.json");
		buffer_delete(buff);
		
	}
	function load_token() {
		if (load_token_fn != undefined) {
			var loaded_token = load_token_fn();
			///
			return;
		}
		if (file_exists("twitch-token.json")) {
			var buff = buffer_load("twitch-token.json");
			var str = buffer_read(buff,buffer_text);
			var json = json_parse(str);
			token.refresh = json.refresh_token;
		} else {
			// file doesn't exist, maybe throw or something
			throw {
				error: "file-not-found",
				description: "File 'twitch-token.json' not found"
			}
		}
	}
	function create_poll(title, choices, duration, options={bits_voting_enabled: false, bits_per_vote: 0, channel_points_voting_enabled: false, channel_points_per_vote: 0},cb=function(){}){
		var body = {
			title: title,
			choices: choices,
			duration: duration,
		}
		if (options.bits_voting_enabled == true) {
			body.bits_voting_enabled = true;
			body.bits_per_vote = options.bits_per_vote;
		}
		if (options.channel_points_voting_enabled == true) {
			body.channel_points_voting_enabled = true;
			body.channel_points_per_vote = options.channel_points_per_vote;
		}
		var http_options = {
			headers: api_headers(),
			keep_header_map: false,	
			callback:cb,
		}
		http("https://api.twitch.tv/helix/polls","POST",json_stringify(body),http_options,function(status,result,options){
			if (status == "200") {
				result = json_parse(result);
				result = result.data[0];
				// sends poll data back out - could replace with constructor?
				var poll = new TwitchPoll(result,self);
				options.callback(result);	
			}
			
		});
	}
	
	function get_polls(cb=function(){},after=0,num=0) {
		var query = qs_encode({
			broadcaster_id: user_data.id,
			after: after,
			first: num,
		});
		var options = {
			headers: api_headers(),
			keep_header_map: false,
			callback: cb,
		}
		
		http("https://api.twitch.tv/helix/polls" + "?" + query,"GET","",options,function(status,result,options){
			result = json_parse(result);
			if (status == 200) {
				var found_polls = [];
				for (var i=0;i<array_length(result.data);i++) {
					var ind = -1;
					for (var j=0;j<array_length(polls);j++) {
						if (result.data[i].id == polls[j].id) {
							ind = j;
							break;
						}
					}
					if (ind == -1) {
						array_push(polls,new TwitchPoll(result.data[i],self));
					} else {
						polls[i].update_choices(result.data[i].choices);
					}
				}
				options.callback(polls);
			}
		});
		
	function get_goals(cb) {
		var query = qs_encode({
			broadcaster_id: user_data.id,
		});
		var options = {
			headers: api_headers(),
			keep_header_map:false,
			callback: cb,
		};
		http("https://api.twitch.tv/helix/goals"+"?"+query,"GET","",options,function(status,result,options){
			result = json_parse(result);
			if (status == 200) {
				var found_goals = [];
				for (var i=0;i<array_length(result.data);i++) {
					var ind = -1;
					for (var j=0;j<array_length(goals);j++) {
						if (result.data[i].id == goals[j].id) {
							ind = j;
							break;
						}
					}
					if (ind == -1) {
						// feather ignore once GM1058
						array_push(goals,new TwitchGoal(result.data[i],self));
					} else {
						goals[ind].type = result.data[i].type;
						goals[ind].description = result.data[i].description;
						goals[ind].current_amount = result.data[i].current_amount;
						goals[ind].target_amount = result.data[i].target_amount;
					}
				}
			}
		});
	}
	
}

/// @param data Struct
/// @param parent Struct.Twitch
function TwitchPoll(data,parent) constructor {
	// feather ignore once GM1008
	id = data.id;	
	title = data.title;
	choices = [];
	for (var i=0;i<array_length(data.choices);i++) {
		array_push(choices,{
			id: data.choices[i].id,
			title: data.choices[i].title,
			votes: data.choices[i].votes,
			channel_points_votes: data.choices[i].channel_points_votes,
			bits_votes: data.choices[i].bits_votes,
		});	
	}
	bits_voting_enabled = data.bits_voting_enabled;
	bits_per_vote = data.bits_per_vote;
	channel_points_voting_enabled = data.channel_points_voting_enabled;
	channel_points_per_vote = data.channel_points_per_vote;
	status = data.status;
	duration = data.duration;
	started_at = data.started_at;
	client = parent;
	
	function update_choices(updated) {
		for (var i=0;i<array_length(updated);i++) {
			for (var j=0;j<array_length(choices);j++) {
					if (updated[i].id == choices[j].id) {
					choices[j].title = updated[i].title;
					choices[j].votes = updated[i].votes;
					choices[j].channel_points_votes = updated[i].channel_points_votes;
					choices[j].bits_votes = updated[i].bits_votes;
					break;
				}
			}
		}
	}
	
	function end_poll(cb) {
		var body = {
			broadcaster_id: client.user_data.id,
			id:id,
			status: "TERMINATED",
		};
		var options = {
			headers: client.api_headers(),
			keep_header_map: false,
		};
		http("https://api.twitch.tv/helix/polls","PATCH",body,function(status,result,options){
			result = json_parse(result);
			if (status == 200) {
				result = result.data[0];
				status = result.status;
				update_choices(result.choices);
			}
		});
	}
	
	function archive_poll(cb) {
		var body = {
			broadcaster_id: client.user_data.id,
			id:id,
			status: "ARCHIVED",
		};
		var options = {
			headers: client.api_headers(),
			keep_header_map: false,
		};
		http("https://api.twitch.tv/helix/polls","PATCH",body,function(status,result,options){
			result = json_parse(result);
			if (status == 200) {
				result = result.data[0];
				status = result.status;
				update_choices(result.choices);
			}
		});
	}
	
	function update_poll(cb){
		var query = qs_encode({
			broadcaster_id: client.user_data.id,
			id:id,
		});
		var options = {
			headers: client.api_headers(),
			keep_header_map: false,
		};
		http("https://api.twitch.tv/helix/polls"+"?"+query,"GET",function(status,result,options){
			result = json_parse(result);
			if (status == 200) {
				result = result.data[0];
				status = result.status;
				update_choices(result.choices);
			}
		});
	}
}

/// @param data Struct
/// @param parent Struct.Twitch
function TwitchGoal(data,parent) constructor {
	// feather ignore once GM1008
	id = data.id;
	type = data.type;
	description = data.description;
	current_amount = data.current_amount;
	target_amount = data.target_amount;
	created_at = data.created_at;
	client = parent;
}


