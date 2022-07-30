/// @description 


if (state == "start") {
	draw_text(4,4,"Press SPACE to login with Twitch");
}
// feather disable GM1009
if (state == "user") {
	var str = array_join([
		"Logged in",
		"Display name: " + twitch.user_data.display_name,
		"Created at: " + twitch.user_data.created_at,
		"Email: " + twitch.user_data.email,
		"ID: " + string(twitch.user_data.id),
	],"\n");
	draw_text(4,4,str);
}
// feather enable GM1009