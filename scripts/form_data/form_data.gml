#macro NEWLINE (chr(13)+chr(10))
global.ADD_FILE_OPTIONS_DEFAULT = {
	file_is_buffer: false,
	keep_buffer: false,
	filename: "",
	mimetype: "",
}
global.ADD_FILE_OPTIONS_KEYS = variable_struct_get_names(global.ADD_FILE_OPTIONS_DEFAULT);
global.bound_char_set = [
	"-","_",
	"1","2","3","4","5","6","7","8","9","0",
	"a","b","c","d","e","f","g","h","i","j","k","l","m",
	"n","o","p","q","r","s","t","u","v","w","x","y","z",
	"A","B","C","D","E","F","G","H","I","J","K","L","M",
	"N","O","P","Q","R","S","T","U","V","W","X","Y","Z"
];
function form_get_bound_safe_char() {
	var _index = irandom(array_length(global.bound_char_set)-1);
	return global.bound_char_set[_index];
}
function FormData() constructor {
	boundary = "----" + sha1_string_utf8(date_datetime_string(date_current_datetime()));
	fields = [];
	function add_file(name,file,options={}) {
		var buffer;
		for (var i=0;i<array_length(global.ADD_FILE_OPTIONS_KEYS);i++) {
			var key = global.ADD_FILE_OPTIONS_KEYS[i];
			if (options[$ key] == undefined) {
				options[$ key] = global.ADD_FILE_OPTIONS_DEFAULT[$ key];
			}
		}
		var fname = file;
		if (options.file_is_buffer == true) {
			buffer = file;
			fname = "unknown";
			if (options.filename != undefined && options.filename != "") {
				fname = options.filename;
			}
		} else {
			buffer = buffer_load(file);
		}
		if (!is_string(options.filename)) {
			options.filename = filename_name(file);
		}
		if (!is_string(options.mimetype) && is_string(file) && options.file_is_buffer != true) {
			options.mimetype = get_mime_from_extension(filename_ext(options.filename));
		}
		
		array_push(fields,{
			type: "file",
			enctype: "binary",
			name: name,
			buffer: buffer,
			keep_buffer: ((options.file_is_buffer == true) && (options.keep_buffer == true)),
			mimetype: options.mimetype,
			filename: fname,
			
		});
		// now check the boundary.. yaaaaay
		var check_bound_byte = 1;
		for (var p=0;p<buffer_get_size(buffer);p++) {
			var byte = buffer_peek(buffer,p,buffer_u8);	
			var check_byte = ord(string_byte_at(boundary,check_bound_byte));
			if (byte == check_byte) {
				bc++;
				if (bc == string_length(boundary)) {
					boundary += form_get_bound_safe_char();
				}
			} else {
				bc = 1;
			}
		}
	}
	function add_data(field,value) {
		array_push(fields,{
			type:"text",
			name:field,
			data:value,
		})
	}
	function cleanup() {
		for (var i=0;i<array_length(fields);i++) {
			var field = fields[i];
			if (field.type == "file") {
				if (field.keep_buffer != true) {
					buffer_delete(field.buffer);
				}
			}
		}
	}
	
	function post_body() {
		var buffer = buffer_create(4,buffer_grow,1);
		for (var i=0;i<array_length(fields);i++) {
			var field = fields[i];
			var name = field.name;
			
			buffer_write(buffer,buffer_text,"--"+boundary+NEWLINE);
			
			// Text field
			if (field.type=="text") {
				var data = field.data;
				buffer_write(buffer,buffer_text,"Content-Disposition: form-data; name=\""+name+"\""+NEWLINE+NEWLINE);
				buffer_write(buffer,buffer_text,string(data)+NEWLINE);
				continue;
			}
			// File field!
			if (field.filename == undefined) {
				field.filename = name;	
			}
			if (field.mimetype == undefined) {
				// apparently this should be assumed, ask rfc2045 ¯\_(ツ)_/¯
				field.mimetype = "text/plain";	
			}
			buffer_write(buffer,buffer_text,"Content-Disposition: form-data;name=\""+name+"\"; filename=\"" + field.filename + "\"" + NEWLINE);
			buffer_write(buffer,buffer_text,"Content-Type: " + field.mimetype + NEWLINE + NEWLINE);
			
			buffer_copy(field.buffer,0,buffer_get_size(field.buffer),buffer,buffer_tell(buffer));
			buffer_seek(buffer,buffer_seek_relative,buffer_get_size(field.buffer));
			buffer_write(buffer,buffer_text,NEWLINE);
		}
		buffer_write(buffer,buffer_text,"--"+boundary+"--"+NEWLINE);
		return [buffer,boundary];
	}
}


function get_mime_from_extension(extension) {
	return "application/octet-stream";
}