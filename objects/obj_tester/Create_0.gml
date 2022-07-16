/// @description 

twitch = new Twitch();

//show_message(url_parse("http://localhost:3000/?code=gulfwdmys5lsm6qyz4xiz9q32l10&scope=channel%3Amanage%3Apolls+channel%3Aread%3Apolls&state=c3ab8aa609ea11e793ae92361f002671"));

// user:read:email channel:read:subscriptions channel:manage:polls bits:read
var scopes = [
	twitch_scope().user.read.email,
	twitch_scope().channel.read.subscriptions,
	twitch_scope().channel.manage.polls,
	twitch_scope().channel.manage.predictions,
	twitch_scope().bits.read,
];

var buff = buffer_load("./keys.json");
var keys = json_parse(buffer_read(buff,buffer_text));
var client_id = keys.client_id;
var client_secret = keys.client_secret;

twitch.init(client_id,client_secret,scopes,3000);


state = "start";