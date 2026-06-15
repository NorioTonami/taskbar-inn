class_name DevOverlay
extends PanelContainer
# dev_overlay.gd — 開発用デバッグパネル（v0.3）。F9 で表示切替。
# 時間加速・gold/評判/汚れ/枠の操作・5人宿泊強制・セーブリセットを提供。
# dev_config.json の dev_mode=true のときのみ main から生成される。

signal time_scale_set(scale: int)
signal add_gold(n: int)
signal add_rep(n: int)
signal set_dirty(full: bool)
signal set_food(full: bool)
signal add_generic_ingredients(n: int)
signal force_guests(n: int)
signal add_slot()
signal rank_up()
signal reset_save()

func _ready() -> void:
	modulate = Color(1, 1, 1, 0.96)
	var m := MarginContainer.new()
	for k in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		m.add_theme_constant_override(k, 8)
	add_child(m)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	m.add_child(box)

	var title := Label.new()
	title.text = "🛠 DEV (F9)"
	title.add_theme_font_size_override("font_size", 12)
	box.add_child(title)

	var t := HBoxContainer.new()
	box.add_child(t)
	t.add_child(_btn("x1", func(): time_scale_set.emit(1)))
	t.add_child(_btn("x10", func(): time_scale_set.emit(10)))
	t.add_child(_btn("x60", func(): time_scale_set.emit(60)))

	var g := HBoxContainer.new()
	box.add_child(g)
	g.add_child(_btn("+1000G", func(): add_gold.emit(1000)))
	g.add_child(_btn("+10⭐", func(): add_rep.emit(10)))

	var d := HBoxContainer.new()
	box.add_child(d)
	d.add_child(_btn("汚す", func(): set_dirty.emit(true)))
	d.add_child(_btn("掃除", func(): set_dirty.emit(false)))
	d.add_child(_btn("食材満", func(): set_food.emit(true)))
	d.add_child(_btn("食材0", func(): set_food.emit(false)))
	d.add_child(_btn("素材+20", func(): add_generic_ingredients.emit(20)))

	var s := HBoxContainer.new()
	box.add_child(s)
	s.add_child(_btn("+5客", func(): force_guests.emit(5)))
	s.add_child(_btn("枠+1", func(): add_slot.emit()))
	s.add_child(_btn("ランクUP", func(): rank_up.emit()))

	box.add_child(_btn("セーブ消去して再起動", func(): reset_save.emit()))

func _btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 11)
	b.pressed.connect(cb)
	return b
