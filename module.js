var Module = {
  print: function(text) { console.log('stdout: ' + text) },
  printErr: function(text) { console.log('stderr: ' + text) },
  noInitialRun: true,

  normalize: function normalize(text) {
    var pointer = allocate(intArrayFromString(text), ALLOC_NORMAL);
    var parsed  = Module.raw_normalize(pointer);
    Module._free(pointer);
    
    if (parsed.error.message == "") {
      parsed.error = null
    }

    return parsed;
  },

  parse: function parse(text) {
    var pointer = allocate(intArrayFromString(text), ALLOC_NORMAL);
    var parsed  = Module.raw_parse(pointer);
    Module._free(pointer);
    
    parsed.parse_tree = JSON.parse(parsed['parse_tree']);

    if (parsed.error.message == "") {
      parsed.error = null
    }

    return parsed;
  },

  parse_plpgsql: function parse_plpgsql(text) {
    var pointer = allocate(intArrayFromString(text), ALLOC_NORMAL);
    var parsed  = Module.raw_parse_plpgsql(pointer);
    Module._free(pointer);
    
    parsed.plpgsql_funcs = JSON.parse(parsed['plpgsql_funcs']);

    if (parsed.error.message == "") {
      parsed.error = null
    }

    return parsed;
  },

  fingerprint: function fingerprint(text) {
    var pointer = allocate(intArrayFromString(text), ALLOC_NORMAL);
    var parsed  = Module.raw_fingerprint(pointer);
    Module._free(pointer);
    
    if (parsed.error.message == "") {
      parsed.error = null
    } else {
      parsed.hexdigest = null
    }

    return parsed;
  },
};
