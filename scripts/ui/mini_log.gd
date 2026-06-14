class_name MiniLog
extends PanelContainer
# mini_log.gd — タブ下に常駐する直近ログ（数行）。ログタブとは別の常時表示。
# 新しいものほど下＆明るく表示する。state を読むだけ。

const LINES: int = 3

var _rows: Array[Label] = []

func _ready() -> void:
	var m := MarginContainer.new()
	for k in ["margin_left", "margin_right"]:
		m.add_theme_constant_override(k, 6)
	for k in ["margin_top", "margin_bottom"]:
		m.add_theme_constant_override(k, 4)
	add_child(m)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	m.add_child(box)
	for i in LINES:
		var l := Label.new()
		l.add_theme_font_size_override("font_size", 10)
		l.clip_text = true
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		box.add_child(l)
		_rows.append(l)

func populate(state: GameState) -> void:
	if _rows.is_empty():
		return
	var log: Array = state.event_log
	for i in LINES:
		var l: Label = _rows[i]
		var idx: int = log.size() - LINES + i   # 上=古い → 下=新しい
		if idx >= 0 and idx < log.size():
			l.text = "• %s" % str(log[idx])
			var age: int = LINES - 1 - i          # 0=最新
			l.modulate = Color(1, 1, 1, 1.0 - age * 0.30)
		else:
			l.text = ""
