// because http_request uses.. maps.. why
function struct_to_map(struct = {}) {
	var map = ds_map_create();
	var names = variable_struct_get_names(struct);
	for (var i=0;i<array_length(names);i++) {
		map[? names[i]] = struct[$ names[i]];	
	}
	return map;
}