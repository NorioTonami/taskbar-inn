class_name KitchenPanel
extends VBoxContainer
# kitchen_panel.gd — 厨房タブの読み取り専用ステータス表示。
# 調理済み在庫、食材、現在作れる料理ランク、客の要求料理ランクをまとめる。
# 操作は仕事タブに残し、このパネルは GameState と JSON 定義の見える化だけを行う。

var _guests: Array = []

func _ready() -> void:
	add_theme_constant_override("separation", 8)
	_guests = DataLoader.load_array("res://data/guest_types.json")

func populate(state: GameState) -> void:
	for c in get_children():
		c.queue_free()
	if state.service_rank < 2:
		_header("厨房")
		_body("宿Lv2で食事つき営業が始まると、厨房の詳細を確認できます。")
		return

	_header("厨房")
	_body("調理済みと食材の状態を確認します。調理や収穫の開始は仕事タブで行います。")
	_add_meal_stock_section(state)
	_add_ingredient_section(state)
	_add_cookable_section(state)
	_add_guest_requirements_section()
	_add_rule_section()

func _add_meal_stock_section(state: GameState) -> void:
	_section("調理済み")
	var cap: int = state.meal_storage_capacity()
	_row("容量", "%d / %d" % [int(state.total_meal_stock()), cap])
	for rank in ["basic", "standard", "good"]:
		_row(_rank_label(rank), "%d" % int(state.meal_stock(rank)))
	var faded := Label.new()
	faded.text = "上位料理: 季節料理以降は今後の宿Lvで扱います"
	faded.add_theme_font_size_override("font_size", 11)
	faded.modulate = Color(0.55, 0.50, 0.43)
	add_child(faded)

func _add_ingredient_section(state: GameState) -> void:
	_section("食材")
	_row("野菜", "%d / %d" % [int(state.vegetable_stock), state.vegetable_cap()])
	_row("食材パック", "%d / %d" % [
		int(state.generic_ingredient_stock), state.generic_ingredient_cap()])
	_body("食材パックは正式な仕入れルート実装前の補助・テスト用です。basic〜good までの不足補助に限ります。")

func _add_cookable_section(state: GameState) -> void:
	_section("現在作れるもの")
	var blockers: Array[String] = _blocking_reasons(state)
	if not blockers.is_empty():
		_row("調理不可", " / ".join(blockers))
	else:
		var rank: String = state.highest_cookable_meal_rank()
		_row("調理可能", _rank_label(rank))
	_row("根拠", "厨房Lv%d / 調理Lv%d" % [
		max(1, state.upgrade_level("kitchen")), max(1, state.skill_level("cooking"))])
	var missing: Array[String] = _missing_reasons(state)
	if missing.is_empty():
		_row("不足/注意", "なし")
	else:
		_row("不足/注意", " / ".join(missing))

func _add_guest_requirements_section() -> void:
	_section("客の食事要求")
	for g in _guests:
		var req: String = str(g.get("required_meal_rank", "basic"))
		_row("%s %s" % [str(g.get("icon", "")), str(g.get("name", ""))], _rank_label(req))

func _add_rule_section() -> void:
	_section("調理ルール")
	_body("調理は野菜を消費して調理済みを作ります。")
	_body("野菜が足りない場合、食材パックで basic〜good まで補助できます。")
	_body("食材パックは万能素材ではなく、上位料理には使えません。")

func _blocking_reasons(state: GameState) -> Array[String]:
	var out: Array[String] = []
	if state.total_meal_stock() >= float(state.meal_storage_capacity()):
		out.append("調理済み満杯")
	if state.vegetable_stock + state.generic_ingredient_stock <= 0.0:
		out.append("野菜不足")
	return out

func _missing_reasons(state: GameState) -> Array[String]:
	var out: Array[String] = []
	if state.vegetable_stock <= 0.0:
		out.append("野菜不足")
	if state.generic_ingredient_stock <= 0.0:
		out.append("食材パック補助なし")
	return out

func _rank_label(rank: String) -> String:
	return str(GameState.MEAL_RANK_LABELS.get(rank, rank))

func _header(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 16)
	add_child(l)

func _section(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 14)
	l.modulate = Color(1.0, 0.86, 0.58)
	add_child(l)

func _body(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 12)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(l)

func _row(label: String, value: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	add_child(row)
	var left := Label.new()
	left.custom_minimum_size = Vector2(160, 0)
	left.text = label
	left.add_theme_font_size_override("font_size", 12)
	row.add_child(left)
	var right := Label.new()
	right.text = value
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_font_size_override("font_size", 12)
	right.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(right)
