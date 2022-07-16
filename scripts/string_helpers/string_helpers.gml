global.URL_ENCODE_INPUT_BUFFER = buffer_create(1024,buffer_grow,1);
global.URL_ENCODE_OUTPUT_BUFFER = buffer_create(1024,buffer_grow,1);
global.URL_ENCODE_ALLOWED_LUT = array_create(256,false);
global.URL_ENCODE_HEX_LUT = array_create(256,0);

for (var c = ord("A"); c <= ord("Z"); c++) global.URL_ENCODE_ALLOWED_LUT[c] = true;
for (var c = ord("a"); c <= ord("z"); c++) global.URL_ENCODE_ALLOWED_LUT[c] = true;
for (var c = ord("0"); c <= ord("9"); c++) global.URL_ENCODE_ALLOWED_LUT[c] = true;
global.URL_ENCODE_ALLOWED_LUT[ord("-")] = true;
global.URL_ENCODE_ALLOWED_LUT[ord("_")] = true;
global.URL_ENCODE_ALLOWED_LUT[ord(".")] = true;
global.URL_ENCODE_ALLOWED_LUT[ord("!")] = true;
global.URL_ENCODE_ALLOWED_LUT[ord("~")] = true;
global.URL_ENCODE_ALLOWED_LUT[ord("*")] = true;
global.URL_ENCODE_ALLOWED_LUT[ord("'")] = true;
global.URL_ENCODE_ALLOWED_LUT[ord("(")] = true;
global.URL_ENCODE_ALLOWED_LUT[ord(")")] = true;

for (var c=0;c<256;c++) {
	var _hv;
	var _hd = c >> 4;
	if (_hd >= 10) {
		_hv = ord("A") + _hd-10;
	} else {
		_hv = ord("0") + _hd;
	}
	_hd = c & $F;
	if (_hd >= 10) {
		_hv |= (ord("A")+ (_hd-10))<<8;
	} else {
		_hv |= (ord("0")+ _hd)<<8;
	}
	global.URL_ENCODE_HEX_LUT[c] = _hv;
}

function url_encode(str){
	buffer_seek(global.URL_ENCODE_INPUT_BUFFER,buffer_seek_start,0);
	buffer_write(global.URL_ENCODE_INPUT_BUFFER,buffer_text,str);
	buffer_seek(global.URL_ENCODE_INPUT_BUFFER,buffer_seek_start,0);
	buffer_seek(global.URL_ENCODE_OUTPUT_BUFFER,buffer_seek_start,0);
	repeat (string_length(str)) {
		var _byte = buffer_read(global.URL_ENCODE_INPUT_BUFFER,buffer_u8);
		if (global.URL_ENCODE_ALLOWED_LUT[_byte]) {
			buffer_write(global.URL_ENCODE_OUTPUT_BUFFER,buffer_u8,_byte);	
		} else {
			buffer_write(global.URL_ENCODE_OUTPUT_BUFFER,buffer_u8,ord("%"));	
			buffer_write(global.URL_ENCODE_OUTPUT_BUFFER,buffer_u16,global.URL_ENCODE_HEX_LUT[_byte]);
		}
	}
	buffer_write(global.URL_ENCODE_OUTPUT_BUFFER,buffer_u8,0);
	buffer_seek(global.URL_ENCODE_OUTPUT_BUFFER,buffer_seek_start,0);
	var enc = buffer_read(global.URL_ENCODE_OUTPUT_BUFFER,buffer_string);
	return enc;
}

function url_decode(str) {
	var out = str;
	str = string_replace_all(str,"+"," ");
	var count = string_count("%",str);
	var last = 0;
	repeat (count) {
		var percent = string_pos_ext("%",str,last);
		last = percent;
		var hex = string_upper(string_copy(str,percent+1,2));
		var char = chr(hex_to_dec(hex));
		str = string_replace(str,"%" + hex,char);
		last -= 2;
	}
	return str;
}

function url_parse(url) {
	var query_start = string_pos("?",url);
	var href = string_copy(url,1,query_start-1);
	var fragment_start = string_pos("#",url);
	var querystring = string_copy(url,query_start+1,(fragment_start > 0 ? (fragment_start-1) : string_length(url)) - query_start);
	var fragment = "";
	if (fragment_start > 0) {
		fragment = string_copy(url,fragment_start+1,string_length(url));
	}
	var query_params = string_split(querystring,"&");
	var query = {};
	for (var i=0;i<array_length(query_params);i++) {
	    var param = string_split(query_params[i],"=");
	    query[$ param[0]] = url_decode(param[1]);
	}
	return {
		href: href,
		query: query,
		fragment: fragment,
	}
}

// Encodes struct into queyrstring format
// {a: 5, b:"hello, world"}
// a=5&b=hello%2C+world
/// @description qs_encode
/// @param query Struct
function qs_encode(query={}) {
	var qs = "";
	var params = variable_struct_get_names(query);
	for (var i=0;i<array_length(params);i++) {
		qs += params[i] + "=" + string(query[$ params[i]]);
		if (i+1 < array_length(params)) {
			qs += "&";	
		}
	}
	return qs;
}

function string_split(str,sep) {
	var results = [];
	repeat (string_count(sep,str)) {
		var pos = string_pos(sep,str);
		var left = string_copy(str,1,pos-1);
		var right = string_copy(str,pos+1,string_length(str)-(pos));
		array_push(results,left);
		str = right;
	}
	array_push(results,str);
	
	return results;
}

function hex_to_dec(str) {
	var hex = 0;
	var hex_digits = "0123456789ABCDEF";
	repeat (string_length(str)) {
		var char = string_char_at(str,1);
		str = string_delete(str,1,1);
		hex = hex << 4 | (string_pos(char,hex_digits)-1);
	}
	return hex;
	
}