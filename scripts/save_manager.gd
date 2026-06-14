class_name SaveManager
extends RefCounted
# save_manager.gd — user://savegame.json への保存/復元とオフライン進行。
# load 時に last_saved_at との差分を simulator.apply_offline へ渡して概算反映する。

const SAVE_PATH: String = "user://savegame.json"

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

# dev: セーブを削除（呼び出し側でシーン再読込して初期状態に戻す）
func reset() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

func save(state: GameState) -> void:
	state.last_saved_at = int(Time.get_unix_time_from_system())
	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("SaveManager: cannot open save file for write")
		return
	f.store_string(JSON.stringify(state.to_dict(), "\t"))
	f.close()

# セーブを読み込み state に反映。経過時間からオフライン結果を集計適用。
# 戻り値: {"loaded": bool, "offline": Dictionary}
func load(state: GameState, sim: InnSimulator) -> Dictionary:
	if not has_save():
		return {"loaded": false, "offline": {}}
	var text: String = FileAccess.get_file_as_string(SAVE_PATH)
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		push_error("SaveManager: invalid save file")
		return {"loaded": false, "offline": {}}
	state.from_dict(parsed)
	var offline: Dictionary = {}
	if state.last_saved_at > 0:
		var now: int = int(Time.get_unix_time_from_system())
		offline = sim.apply_offline(now - state.last_saved_at)
	return {"loaded": true, "offline": offline}
