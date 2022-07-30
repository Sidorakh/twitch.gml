/// @description 

if (keyboard_check_pressed(vk_space)) {
	// feather ignore once GM1009
	twitch.authorize(function(user){
		state = "user";
	});	
}