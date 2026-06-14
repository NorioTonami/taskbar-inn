class_name UiTheme
extends RefCounted
# ui_theme.gd — コードで宿らしい暖色の Theme を組み立てる（v0.3）。
# main が root Control に割り当て、compact/expanded/トースト全体へカスケードさせる。
# 派手にせず、暗い木目調＋琥珀のアクセントで「常駐ユーティリティ」の落ち着きを狙う。

const BG_PANEL := Color(0.15, 0.12, 0.10, 0.97)   # 木目の暗茶
const BG_INSET := Color(0.11, 0.09, 0.08, 0.98)   # ログ等の沈んだ面
const BTN_NORMAL := Color(0.28, 0.23, 0.18)
const BTN_HOVER := Color(0.38, 0.31, 0.23)
const BTN_PRESSED := Color(0.22, 0.18, 0.14)
const BTN_DISABLED := Color(0.20, 0.18, 0.16, 0.6)
const ACCENT := Color(0.86, 0.66, 0.36)           # 琥珀
const BORDER := Color(0.42, 0.33, 0.24)
const TEXT := Color(0.94, 0.90, 0.83)
const TEXT_DIM := Color(0.70, 0.64, 0.56)

static func build() -> Theme:
	var t := Theme.new()

	# --- パネル類 ---
	t.set_stylebox("panel", "PanelContainer", _panel(BG_PANEL, 8, 1))
	t.set_stylebox("panel", "Panel", _panel(BG_PANEL, 8, 1))

	# --- ボタン ---
	t.set_stylebox("normal", "Button", _panel(BTN_NORMAL, 6, 1))
	t.set_stylebox("hover", "Button", _panel(BTN_HOVER, 6, 1))
	t.set_stylebox("pressed", "Button", _panel(BTN_PRESSED, 6, 1))
	t.set_stylebox("disabled", "Button", _panel(BTN_DISABLED, 6, 0))
	t.set_stylebox("focus", "Button", _empty())
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color(1, 1, 1))
	t.set_color("font_pressed_color", "Button", ACCENT)
	t.set_color("font_disabled_color", "Button", TEXT_DIM)

	# --- ラベル ---
	t.set_color("font_color", "Label", TEXT)

	# --- タブ ---
	t.set_stylebox("panel", "TabContainer", _panel(BG_PANEL, 8, 1))
	t.set_stylebox("tab_selected", "TabContainer", _tab(BTN_HOVER, ACCENT))
	t.set_stylebox("tab_unselected", "TabContainer", _tab(BTN_PRESSED, BORDER))
	t.set_stylebox("tab_hovered", "TabContainer", _tab(BTN_NORMAL, BORDER))
	t.set_color("font_selected_color", "TabContainer", ACCENT)
	t.set_color("font_unselected_color", "TabContainer", TEXT_DIM)
	t.set_color("font_hovered_color", "TabContainer", TEXT)

	# --- スクロール余白 ---
	t.set_constant("h_separation", "HBoxContainer", 8)

	return t

static func _panel(bg: Color, radius: int, border: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.set_border_width_all(border)
	s.border_color = BORDER
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 5
	s.content_margin_bottom = 5
	return s

static func _tab(bg: Color, top: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.corner_radius_top_left = 6
	s.corner_radius_top_right = 6
	s.border_width_top = 2
	s.border_color = top
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 5
	s.content_margin_bottom = 5
	return s

static func _empty() -> StyleBoxEmpty:
	return StyleBoxEmpty.new()
