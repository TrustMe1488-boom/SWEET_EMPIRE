class_name SaveStore
extends RefCounted
# Binary Variants preserve Transform3D and 64-bit RNG state. Object decoding is disabled.
const VERSION: int = 1
const MAX_BYTES: int = 16 * 1024 * 1024
var directory: String = "user://progress"
var last_error: String = ""
var validate_payload: Callable
func _read(path: String) -> Dictionary:
 var file := FileAccess.open(path, FileAccess.READ)
 if file == null or file.get_length() > MAX_BYTES or file.get_length() < 44: return {}
 if file.get_buffer(8).get_string_from_ascii() != "SWEET001": return {}
 var length: int = file.get_32()
 if length != file.get_length() - 44: return {}
 var expected := file.get_buffer(32)
 var bytes := file.get_buffer(length)
 var hash := HashingContext.new()
 hash.start(HashingContext.HASH_SHA256); hash.update(bytes)
 if hash.finish() != expected: return {}
 var value = bytes_to_var(bytes)
 if not value is Dictionary: return {}
 if validate_payload.is_valid() and not validate_payload.call(value): return {}
 return value
func load_data() -> Dictionary:
 var value := _read(directory.path_join("save.dat"))
 if not value.is_empty(): return value
 return _read(directory.path_join("save.previous"))
func write_data(data: Dictionary) -> bool:
 last_error = ""
 if data.is_empty(): last_error = "Empty save"; return false
 if DirAccess.make_dir_recursive_absolute(directory) != OK: last_error = "Cannot create save directory"; return false
 var bytes := var_to_bytes(data)
 if bytes.size() > MAX_BYTES - 1024: last_error = "Save too large"; return false
 var hash := HashingContext.new(); hash.start(HashingContext.HASH_SHA256); hash.update(bytes)
 var path := directory.path_join("save.dat")
 var temp := directory.path_join("save.pending")
 var backup := directory.path_join("save.previous")
 var file := FileAccess.open(temp, FileAccess.WRITE)
 if file == null: last_error = "Cannot open pending save"; return false
 file.store_buffer("SWEET001".to_ascii_buffer())
 file.store_32(bytes.size())
 file.store_buffer(hash.finish())
 file.store_buffer(bytes)
 file.flush()
 var error := file.get_error()
 file.close()
 if error != OK or _read(temp) != data: last_error = "Pending save verification failed"; return false
 # Preserve the last valid state, never replace a valid backup with a corrupt primary.
 if not _read(path).is_empty():
  if DirAccess.copy_absolute(path, backup) != OK: last_error = "Cannot preserve previous save"; return false
  if _read(backup) != _read(path): last_error = "Previous save verification failed"; return false
 elif FileAccess.file_exists(path):
  var corrupt := directory.path_join("save.corrupt.%d" % Time.get_ticks_usec())
  if DirAccess.copy_absolute(path, corrupt) != OK: last_error = "Cannot preserve corrupt save"; return false
 # rename_absolute replaces a file on Windows through Godot's replace operation.
 if DirAccess.rename_absolute(temp, path) != OK: last_error = "Cannot promote pending save"; return false
 return true
