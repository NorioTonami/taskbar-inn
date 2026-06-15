extends Control
# inn_visual_view.gd — Visual MVP Step 1 の宿屋背景プレビュー。
# 背景1枚絵またはプレースホルダーを16:9で表示し、
# 疑似3D背景向けの仮マーカーと固定歩行ルートを検証する。
# キャラクター移動やアニメーションはまだ扱わない。

const BACKGROUND_PATH := "res://assets/visual/backgrounds/inn_room/inn_room_lv01_base.png"
const TARGET_ASPECT := 16.0 / 9.0
const DEBUG_VISUAL_MVP := true

const MARKERS := {
	"entrance": Vector2(0.09, 0.78),
	"hall_01": Vector2(0.28, 0.68),
	"hall_02": Vector2(0.52, 0.61),
	"seat_01": Vector2(0.72, 0.54),
	"seat_02": Vector2(0.82, 0.67),
	"bed_01": Vector2(0.63, 0.32),
}

const MARKER_LABELS := {
	"entrance": "Entrance",
	"hall_01": "Hall 01",
	"hall_02": "Hall 02",
	"seat_01": "Seat 01",
	"seat_02": "Seat 02",
	"bed_01": "Bed 01",
}

const ROUTES := {
	"entrance_to_seat_01": ["entrance", "hall_01", "hall_02", "seat_01"],
	"seat_01_to_bed_01": ["seat_01", "hall_02", "bed_01"],
}

var debug_markers_visible: bool = DEBUG_VISUAL_MVP:
	set(value):
		debug_markers_visible = value
		queue_redraw()

var _background: Texture2D

func _ready() -> void:
	name = "InnVisualView"
	custom_minimum_size = Vector2(640, 360)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_load_background()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func get_marker_position(marker_name: String) -> Vector2:
	var key := marker_name.to_lower()
	if not MARKERS.has(key):
		return Vector2.ZERO
	return _to_view_position(MARKERS[key])

func get_route(route_name: String) -> Array[Vector2]:
	var points: Array[Vector2] = []
	if not ROUTES.has(route_name):
		return points
	for marker_name in ROUTES[route_name]:
		points.append(get_marker_position(str(marker_name)))
	return points

func set_debug_markers_visible(is_visible: bool) -> void:
	debug_markers_visible = is_visible

func start_preview_patrol() -> void:
	# Step 2 でキャラ1体の往復移動をここから接続する想定。
	pass

func _load_background() -> void:
	if ResourceLoader.exists(BACKGROUND_PATH):
		var res := load(BACKGROUND_PATH)
		if res is Texture2D:
			_background = res

func _draw() -> void:
	var view := _view_rect()
	_draw_background(view)
	_draw_light_placeholder(view)
	if debug_markers_visible:
		_draw_routes(view)
		_draw_markers(view)

func _draw_background(view: Rect2) -> void:
	draw_rect(view, Color(0.11, 0.08, 0.06), true)
	if _background != null:
		draw_texture_rect(_background, _fit_texture_rect(view, _background.get_size()), false)
	else:
		_draw_placeholder(view)
	draw_rect(view, Color(0.72, 0.52, 0.30), false, 2.0)

func _draw_placeholder(view: Rect2) -> void:
	var floor_color := Color(0.23, 0.15, 0.10)
	var wall_color := Color(0.16, 0.11, 0.08)
	var path_color := Color(0.42, 0.28, 0.16, 0.38)
	draw_rect(view, wall_color, true)
	draw_rect(Rect2(view.position.x, view.position.y + view.size.y * 0.46,
			view.size.x, view.size.y * 0.54), floor_color, true)
	var path := PackedVector2Array([
		_to_view_position(MARKERS["entrance"]),
		_to_view_position(MARKERS["hall_01"]),
		_to_view_position(MARKERS["hall_02"]),
		_to_view_position(MARKERS["seat_01"]),
	])
	if path.size() >= 2:
		draw_polyline(path, path_color, 18.0, true)
	_draw_text(view.position + Vector2(18, 28), "Inn Room Lv01 Placeholder",
			16, Color(0.98, 0.82, 0.52))
	_draw_text(view.position + Vector2(18, 50), "16:9 preview / background frame / debug route overlay",
			11, Color(0.92, 0.78, 0.58, 0.82))

func _draw_light_placeholder(view: Rect2) -> void:
	var glow_pos := view.position + Vector2(view.size.x * 0.78, view.size.y * 0.22)
	draw_circle(glow_pos, min(view.size.x, view.size.y) * 0.12, Color(1.0, 0.58, 0.16, 0.10))
	draw_circle(glow_pos, min(view.size.x, view.size.y) * 0.035, Color(1.0, 0.72, 0.25, 0.42))

func _draw_routes(_view: Rect2) -> void:
	var route_a := PackedVector2Array(get_route("entrance_to_seat_01"))
	var route_b := PackedVector2Array(get_route("seat_01_to_bed_01"))
	if route_a.size() >= 2:
		draw_polyline(route_a, Color(0.18, 0.74, 1.0, 0.82), 3.0, true)
	if route_b.size() >= 2:
		draw_polyline(route_b, Color(1.0, 0.70, 0.22, 0.88), 3.0, true)

func _draw_markers(_view: Rect2) -> void:
	for marker_name in MARKERS.keys():
		var p := get_marker_position(str(marker_name))
		draw_circle(p, 5.0, Color(0.05, 0.05, 0.04, 0.95))
		draw_circle(p, 3.4, _marker_color(str(marker_name)))
		draw_line(p + Vector2(-8, 0), p + Vector2(8, 0), Color(1, 1, 1, 0.85), 1.0)
		draw_line(p + Vector2(0, -8), p + Vector2(0, 8), Color(1, 1, 1, 0.85), 1.0)
		_draw_text(p + Vector2(8, -8), str(MARKER_LABELS.get(marker_name, marker_name)),
				10, Color(1, 0.94, 0.78))

func _marker_color(marker_name: String) -> Color:
	if marker_name.begins_with("seat"):
		return Color(0.42, 0.94, 0.52)
	if marker_name.begins_with("bed"):
		return Color(0.78, 0.52, 1.0)
	if marker_name.begins_with("hall"):
		return Color(0.35, 0.78, 1.0)
	return Color(1.0, 0.52, 0.34)

func _to_view_position(normalized: Vector2) -> Vector2:
	var view := _view_rect()
	return view.position + Vector2(view.size.x * normalized.x, view.size.y * normalized.y)

func _view_rect() -> Rect2:
	var area := Rect2(Vector2.ZERO, size)
	if area.size.x <= 0.0 or area.size.y <= 0.0:
		return Rect2(Vector2.ZERO, custom_minimum_size)
	var width := area.size.x
	var height := width / TARGET_ASPECT
	if height > area.size.y:
		height = area.size.y
		width = height * TARGET_ASPECT
	var pos := Vector2((area.size.x - width) * 0.5, (area.size.y - height) * 0.5)
	return Rect2(pos, Vector2(width, height))

func _fit_texture_rect(bounds: Rect2, texture_size: Vector2) -> Rect2:
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return bounds
	var scale_factor: float = min(bounds.size.x / texture_size.x, bounds.size.y / texture_size.y)
	var fitted_size := texture_size * scale_factor
	return Rect2(bounds.position + (bounds.size - fitted_size) * 0.5, fitted_size)

func _draw_text(pos: Vector2, text: String, font_size: int, color: Color) -> void:
	var font := get_theme_default_font()
	if font == null:
		return
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)
