/// @description 

if (instance_number(obj_http) > 1) {
	instance_destroy();		// THERE CAN ONLY BE ONE	
}

requests = ds_map_create();