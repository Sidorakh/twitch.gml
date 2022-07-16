function array_join(array,separator="") {
	var _str = "";
	for (var i=0;i<array_length(array);i++) {
		/// feather ignore once GM1061
		_str += string(array[i]);
		if (i+1<array_length(array)) _str += separator;
	}
	return _str;
}


function array_find(array,fn) {
	return array_indexof(array,fn) > -1
}

function array_indexof(array,fn) {
	for (var i=0;i<array_length(array);i++) {
		if (fn(array[i],i,array)) return i;
	}
	return -1;
}