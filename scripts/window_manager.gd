class_name WindowManager
extends RefCounted
# window_manager.gd — compact/expanded のウィンドウ設定とリサイズ。
# compact: borderless + always_on_top + 小サイズ。初回は右下寄せ、以降は前回位置を保持。
# expanded: compact の位置に追従して開く。画面中央より上なら下向き、下なら上向きに展開する。
# headless でも例外を出さないよう防御的に扱う。

const COMPACT_SIZE := Vector2i(420, 64)
const EXPANDED_SIZE := Vector2i(1180, 760)
const DIALOG_SIZE := Vector2i(440, 250)
const SCREEN_MARGIN := 12

var _win: Window
var _compact_pos: Vector2i = Vector2i(-1, -1)  # 記憶した compact 位置（未設定は -1）
var _target_size: Vector2i = COMPACT_SIZE

func _init(win: Window) -> void:
	_win = win

func apply_compact() -> void:
	if _win == null:
		return
	_win.borderless = true
	_win.always_on_top = true
	_apply_fixed_size(COMPACT_SIZE)
	if _compact_pos.x < 0:
		_place_bottom_right(COMPACT_SIZE)
	else:
		# expanded から戻るときはドラッグ前の compact 位置へ復帰
		_win.position = _clamp_to_usable(_compact_pos, COMPACT_SIZE)

# オフライン結果などの小ダイアログ用。compact の位置（または右下）に追従する。
func apply_dialog() -> void:
	if _win == null:
		return
	_win.borderless = true
	_win.always_on_top = true
	_apply_fixed_size(DIALOG_SIZE)
	if _compact_pos.x < 0:
		_place_bottom_right(DIALOG_SIZE)
	else:
		_win.position = _clamp_to_usable(_compact_pos, DIALOG_SIZE)

func apply_expanded() -> void:
	if _win == null:
		return
	# 現在の compact 位置（ドラッグ移動後を尊重）を記憶してから展開する
	var anchor := Rect2i(_win.position, _win.size)
	_compact_pos = _win.position
	_win.always_on_top = true
	_apply_fixed_size(EXPANDED_SIZE)
	_place_following(anchor, EXPANDED_SIZE)

func _apply_fixed_size(sz: Vector2i) -> void:
	_target_size = sz
	_win.unresizable = true
	_win.min_size = sz
	_win.size = sz

func enforce_fixed_size() -> void:
	if _win == null:
		return
	if _win.size != _target_size:
		_win.size = _target_size
	if _win.min_size != _target_size:
		_win.min_size = _target_size
	_win.unresizable = true

# compact の矩形に追従して expanded を配置する。
# compact が画面中央より上 → 上辺を合わせて下向きに展開。
# compact が画面中央より下 → 下辺を合わせて上向きに展開。
func _place_following(anchor: Rect2i, sz: Vector2i) -> void:
	var screen: int = _win.current_screen
	var usable: Rect2i = DisplayServer.screen_get_usable_rect(screen)
	if usable.size.x <= 0 or usable.size.y <= 0:
		return  # headless 等で画面情報が取れない場合は移動しない
	var screen_center_y: int = usable.position.y + usable.size.y / 2
	var anchor_center_y: int = anchor.position.y + anchor.size.y / 2
	var x: int = anchor.position.x
	var y: int
	if anchor_center_y < screen_center_y:
		y = anchor.position.y                       # 下向きに展開
	else:
		y = anchor.position.y + anchor.size.y - sz.y  # 上向きに展開
	_win.position = _clamp_to_usable(Vector2i(x, y), sz)

func _place_bottom_right(sz: Vector2i) -> void:
	var screen: int = _win.current_screen
	var usable: Rect2i = DisplayServer.screen_get_usable_rect(screen)
	if usable.size.x <= 0 or usable.size.y <= 0:
		return  # headless 等で画面情報が取れない場合は移動しない
	var x: int = usable.position.x + usable.size.x - sz.x - SCREEN_MARGIN
	var y: int = usable.position.y + usable.size.y - sz.y - SCREEN_MARGIN
	_win.position = Vector2i(x, y)

func _clamp_to_usable(pos: Vector2i, sz: Vector2i) -> Vector2i:
	var screen: int = _win.current_screen
	var usable: Rect2i = DisplayServer.screen_get_usable_rect(screen)
	if usable.size.x <= 0 or usable.size.y <= 0:
		return pos
	var min_x: int = usable.position.x + SCREEN_MARGIN
	var min_y: int = usable.position.y + SCREEN_MARGIN
	var max_x: int = max(min_x, usable.position.x + usable.size.x - sz.x - SCREEN_MARGIN)
	var max_y: int = max(min_y, usable.position.y + usable.size.y - sz.y - SCREEN_MARGIN)
	var x: int = clampi(pos.x, min_x, max_x)
	var y: int = clampi(pos.y, min_y, max_y)
	return Vector2i(x, y)
