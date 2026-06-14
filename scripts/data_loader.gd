class_name DataLoader
extends RefCounted
# data_loader.gd — data/*.json を安全に読む共有ヘルパー。
# 失敗時は push_error して空のフォールバックを返し、起動は止めない。

static func load_json(path: String, fallback: Variant) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("DataLoader: file not found: %s" % path)
		return fallback
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("DataLoader: empty file: %s" % path)
		return fallback
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null:
		push_error("DataLoader: JSON parse failed: %s" % path)
		return fallback
	return parsed

static func load_array(path: String) -> Array:
	return load_json(path, []) as Array

static func load_dict(path: String) -> Dictionary:
	return load_json(path, {}) as Dictionary
