
return ::(path) {
  return ::? {
    @:buf = Filesystem.readBytes(path);
    return JSON.encode(:buf);
  } => {
    onError ::(value) {
      error(:'Could not get ' + path + ' as valid JSON!');    
    }
  }
}
