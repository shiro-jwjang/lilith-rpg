extends RefCounted

var _records_by_id: Dictionary = {}
var _registration_errors: Array = []


func register(records: Array) -> Array:
	_registration_errors.clear()
	for record in records:
		var record_id = record.get_id()
		if record_id == null or str(record_id).is_empty():
			_registration_errors.append("Missing record ID")
			continue
		if _records_by_id.has(record_id):
			_registration_errors.append("Duplicate record ID: %s" % record_id)
			continue
		_records_by_id[record_id] = record
	return _registration_errors.duplicate()


func get_by_id(record_id):
	return _records_by_id.get(record_id, null)


func validate_all() -> Array:
	var errors: Array = _registration_errors.duplicate()
	for record_id in _records_by_id:
		var record = _records_by_id[record_id]
		for error_text in record.validate():
			errors.append("%s: %s" % [str(record_id), str(error_text)])
	return errors
