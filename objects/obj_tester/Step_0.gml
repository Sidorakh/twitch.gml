/// @description 

if (keyboard_check_pressed(vk_space)) {
	twitch.authorize(function(user){
		state = "user";
	});	
}