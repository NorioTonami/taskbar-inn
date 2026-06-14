class_name EventLogPanel
extends VBoxContainer
# event_log_panel.gd — 直近のイベントログ（最大50件）を表示。
# state.event_log の末尾（新しい順）を上から並べる。

var _list: VBoxContainer
const SHOW_MAX: int = 30

func _ready() -> void:
	var title := Label.new()
	title.text = "ログ"
	title.add_theme_font_size_override("font_size", 16)
	add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 140)
	add_child(scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)

func populate(state: GameState) -> void:
	if _list == null:
		return
	for c in _list.get_children():
		c.queue_free()
	var log: Array = state.event_log
	var start: int = max(0, log.size() - SHOW_MAX)
	for i in range(log.size() - 1, start - 1, -1):
		var lbl := Label.new()
		lbl.text = "• %s" % str(log[i])
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_list.add_child(lbl)
