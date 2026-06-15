class_name GameState
extends RefCounted
# game_state.gd — 状態の単一の真実（v0.3）。
# 純粋データのみを保持し、ロジックは持たない。
# 永続化は to_dict()/from_dict() 経由で save_manager が行う。

# 汚れメーターの上限（規模で増える）
const DIRTY_CAP_BASE: int = 30
const DIRTY_CAP_PER_CAPACITY: int = 10
# 調理済み在庫の互換上限（規模で増える）
const FOOD_CAP_BASE: int = 15
const FOOD_CAP_PER_CAPACITY: int = 5
const MEAL_STORAGE_BASE: int = 12
const MEAL_STORAGE_PER_CAPACITY: int = 4
const MEAL_STORAGE_PER_UPGRADE: int = 8
const VEGETABLE_CAP_BASE: int = 10
const VEGETABLE_CAP_PER_FOOD_STORAGE: int = 8
const VEGETABLE_CAP_PER_FIELD: int = 6
const VEGETABLE_CAP_PER_STORAGE: int = 10
const GENERIC_INGREDIENT_CAP_BASE: int = 8
const GENERIC_INGREDIENT_CAP_PER_FOOD_STORAGE: int = 6
const MEAL_RANKS: Array[String] = ["basic", "standard", "good", "luxury", "specialty", "vip"]
const MEAL_RANK_LABELS := {
	"basic": "簡単な食事",
	"standard": "家庭料理",
	"good": "宿の定食",
	"luxury": "季節料理",
	"specialty": "名物料理",
	"vip": "特別会席",
}

var gold: int = 50
var reputation: int = 0
var level: int = 1

var rooms: int = 2
var comfort: int = 1
var food: int = 1
var cleanliness: int = 1
var security: int = 0

var guest_count: int = 0
var guest_capacity: int = 2

var dirtiness: float = 0.0                # 0 .. dirty_cap()
var food_stock: float = 0.0               # 旧互換: meal_stocks 合計と同期する
var vegetable_stock: float = 0.0          # Lv2: 収穫で得る未調理食材
var generic_ingredient_stock: float = 0.0 # Lv2: 詰み防止用の食材パック
var meal_stocks: Dictionary = {           # meal rank:String -> cooked stock:float
	"basic": 0.0,
	"standard": 0.0,
	"good": 0.0,
	"luxury": 0.0,
	"specialty": 0.0,
	"vip": 0.0,
}
var service_rank: int = 1                 # サービス階層（1=素泊まり, 2=食事つき, ...）

var total_guests: int = 0
var total_gold_earned: int = 0
var guest_type_counts: Dictionary = {}

var unlocked_upgrades: Array[String] = []
var upgrade_levels: Dictionary = {}        # id:String -> level:int
var tool_levels: Dictionary = {}           # tool_id:String -> level:int

var skills: Dictionary = {}                # skill_id -> {"level":int, "xp":float}
var action_counts: Dictionary = {}         # skill_id -> manual action count:int
var staff: Array = []                       # [{role_id, name, level:int, xp:float, assigned:bool}]
var placement_slots: int = 0               # 配置可能なスタッフ数（スタッフ詰め所で増える）
var active_work: String = ""               # 手動で訓練中のスキルid（""=なし）
var tutorial_slot_unlocked: bool = false

var badges: Array[String] = []
var titles: Array[String] = []

var event_log: Array = []                  # 直近 MAX_LOG 件（新しいものが末尾）
const MAX_LOG: int = 50

var last_saved_at: int = 0

# --- 派生 ---
func dirty_cap() -> int:
	return DIRTY_CAP_BASE + guest_capacity * DIRTY_CAP_PER_CAPACITY

func food_cap() -> int:
	return FOOD_CAP_BASE + guest_capacity * FOOD_CAP_PER_CAPACITY

func meal_storage_capacity() -> int:
	return MEAL_STORAGE_BASE + guest_capacity * MEAL_STORAGE_PER_CAPACITY \
		+ upgrade_level("meal_storage") * MEAL_STORAGE_PER_UPGRADE

func vegetable_cap() -> int:
	return VEGETABLE_CAP_BASE \
		+ upgrade_level("food_storage") * VEGETABLE_CAP_PER_FOOD_STORAGE \
		+ upgrade_level("field") * VEGETABLE_CAP_PER_FIELD \
		+ upgrade_level("vegetable_storage") * VEGETABLE_CAP_PER_STORAGE

func generic_ingredient_cap() -> int:
	return GENERIC_INGREDIENT_CAP_BASE \
		+ upgrade_level("food_storage") * GENERIC_INGREDIENT_CAP_PER_FOOD_STORAGE

func add_vegetable_stock(amount: float) -> float:
	var before: float = vegetable_stock
	vegetable_stock = clampf(vegetable_stock + amount, 0.0, float(vegetable_cap()))
	return vegetable_stock - before

func add_generic_ingredient_stock(amount: float) -> float:
	var before: float = generic_ingredient_stock
	generic_ingredient_stock = clampf(generic_ingredient_stock + amount, 0.0,
		float(generic_ingredient_cap()))
	return generic_ingredient_stock - before

func ensure_meal_stocks() -> void:
	for rank in MEAL_RANKS:
		if not meal_stocks.has(rank):
			meal_stocks[rank] = 0.0

func meal_stock(rank: String) -> float:
	ensure_meal_stocks()
	return float(meal_stocks.get(rank, 0.0))

func set_meal_stock(rank: String, amount: float) -> void:
	ensure_meal_stocks()
	meal_stocks[rank] = maxf(0.0, amount)
	_trim_meals_to_capacity()
	sync_food_stock_from_meals()

func add_meal_stock(rank: String, amount: float) -> float:
	ensure_meal_stocks()
	var cap: float = float(meal_storage_capacity())
	var room: float = maxf(0.0, cap - total_meal_stock())
	var before: float = meal_stock(rank)
	var after: float = before + minf(amount, room)
	meal_stocks[rank] = after
	sync_food_stock_from_meals()
	return after - before

func total_meal_stock() -> float:
	ensure_meal_stocks()
	var total: float = 0.0
	for rank in MEAL_RANKS:
		total += float(meal_stocks.get(rank, 0.0))
	return total

func sync_food_stock_from_meals() -> void:
	food_stock = total_meal_stock()

func sync_meals_from_legacy_food() -> void:
	ensure_meal_stocks()
	if total_meal_stock() <= 0.0 and food_stock > 0.0:
		meal_stocks["basic"] = minf(food_stock, float(meal_storage_capacity()))
	_trim_meals_to_capacity()
	sync_food_stock_from_meals()

func _trim_meals_to_capacity() -> void:
	var overflow: float = maxf(0.0, total_meal_stock() - float(meal_storage_capacity()))
	if overflow <= 0.0:
		return
	for i in range(MEAL_RANKS.size() - 1, -1, -1):
		var rank: String = MEAL_RANKS[i]
		var cur: float = meal_stock(rank)
		var take: float = minf(cur, overflow)
		meal_stocks[rank] = cur - take
		overflow -= take
		if overflow <= 0.0:
			return

func highest_cookable_meal_rank() -> String:
	var kitchen_lv: int = max(1, upgrade_level("kitchen"))
	var cooking_lv: int = max(1, skill_level("cooking"))
	var kitchen_index: int = 0
	if kitchen_lv >= 3:
		kitchen_index = 2
	elif kitchen_lv >= 2:
		kitchen_index = 1
	var skill_index: int = 0
	if cooking_lv >= 3:
		skill_index = 2
	elif cooking_lv >= 2:
		skill_index = 1
	return MEAL_RANKS[min(kitchen_index, skill_index)]

func cook_meals(amount: float) -> float:
	var rank: String = highest_cookable_meal_rank()
	var room: float = maxf(0.0, float(meal_storage_capacity()) - total_meal_stock())
	amount = minf(amount, room)
	if amount <= 0.0:
		return 0.0
	if service_rank < 2:
		return add_meal_stock(rank, amount)

	var ingredient_need: float = amount
	var used_veg: float = minf(vegetable_stock, ingredient_need)
	vegetable_stock -= used_veg
	ingredient_need -= used_veg

	var used_generic: float = minf(generic_ingredient_stock, ingredient_need)
	generic_ingredient_stock -= used_generic
	ingredient_need -= used_generic

	var produced: float = used_veg + used_generic
	if produced <= 0.0:
		return 0.0
	if produced < amount:
		var idx: int = max(0, MEAL_RANKS.find(rank) - 1)
		rank = MEAL_RANKS[idx]
	return add_meal_stock(rank, produced)

func consume_meal_for(required_rank: String, amount: float = 1.0) -> Dictionary:
	ensure_meal_stocks()
	var req_idx: int = max(0, MEAL_RANKS.find(required_rank))
	for i in range(req_idx, MEAL_RANKS.size()):
		var rank: String = MEAL_RANKS[i]
		if meal_stock(rank) >= amount:
			meal_stocks[rank] = meal_stock(rank) - amount
			sync_food_stock_from_meals()
			return {"served": true, "rank": rank, "rank_index": i, "required_index": req_idx}
	for i in range(req_idx - 1, -1, -1):
		var rank: String = MEAL_RANKS[i]
		if meal_stock(rank) >= amount:
			meal_stocks[rank] = meal_stock(rank) - amount
			sync_food_stock_from_meals()
			return {"served": true, "rank": rank, "rank_index": i, "required_index": req_idx}
	return {"served": false, "rank": "", "rank_index": -1, "required_index": req_idx}

# --- ログ / 客 ---
func add_log(text: String) -> void:
	event_log.append(text)
	if event_log.size() > MAX_LOG:
		event_log = event_log.slice(event_log.size() - MAX_LOG, event_log.size())

func get_count(type_id: String) -> int:
	return int(guest_type_counts.get(type_id, 0))

func add_guest_count(type_id: String, n: int = 1) -> void:
	guest_type_counts[type_id] = get_count(type_id) + n

# --- アップグレード / 道具 ---
func upgrade_level(id: String) -> int:
	return int(upgrade_levels.get(id, 0))

func tool_level(id: String) -> int:
	return int(tool_levels.get(id, 0))

# --- スキル ---
func _ensure_skill(id: String) -> void:
	if not skills.has(id):
		skills[id] = {"level": 1, "xp": 0.0}

func skill_level(id: String) -> int:
	if not skills.has(id):
		return 0
	return int(skills[id].get("level", 1))

func skill_xp(id: String) -> float:
	if not skills.has(id):
		return 0.0
	return float(skills[id].get("xp", 0.0))

func action_count(id: String) -> int:
	return int(action_counts.get(id, 0))

func add_action_count(id: String, n: int = 1) -> void:
	action_counts[id] = action_count(id) + n

# --- スタッフ ---
func staff_count() -> int:
	return staff.size()

func assigned_staff_count() -> int:
	var n: int = 0
	for s in staff:
		if bool(s.get("assigned", false)):
			n += 1
	return n

# --- 永続化 ---
func to_dict() -> Dictionary:
	ensure_meal_stocks()
	return {
		"gold": gold,
		"reputation": reputation,
		"level": level,
		"rooms": rooms,
		"comfort": comfort,
		"food": food,
		"cleanliness": cleanliness,
		"security": security,
		"guest_count": guest_count,
		"guest_capacity": guest_capacity,
		"dirtiness": dirtiness,
		"food_stock": food_stock,
		"vegetable_stock": vegetable_stock,
		"generic_ingredient_stock": generic_ingredient_stock,
		"meal_stocks": meal_stocks,
		"service_rank": service_rank,
		"total_guests": total_guests,
		"total_gold_earned": total_gold_earned,
		"guest_type_counts": guest_type_counts,
		"unlocked_upgrades": unlocked_upgrades,
		"upgrade_levels": upgrade_levels,
		"tool_levels": tool_levels,
		"skills": skills,
		"action_counts": action_counts,
		"staff": staff,
		"placement_slots": placement_slots,
		"active_work": active_work,
		"tutorial_slot_unlocked": tutorial_slot_unlocked,
		"badges": badges,
		"titles": titles,
		"event_log": event_log,
		"last_saved_at": last_saved_at,
	}

func from_dict(d: Dictionary) -> void:
	gold = int(d.get("gold", gold))
	reputation = int(d.get("reputation", reputation))
	level = int(d.get("level", level))
	rooms = int(d.get("rooms", rooms))
	comfort = int(d.get("comfort", comfort))
	food = int(d.get("food", food))
	cleanliness = int(d.get("cleanliness", cleanliness))
	security = int(d.get("security", security))
	guest_count = int(d.get("guest_count", guest_count))
	guest_capacity = int(d.get("guest_capacity", guest_capacity))
	dirtiness = float(d.get("dirtiness", dirtiness))
	food_stock = float(d.get("food_stock", food_stock))
	vegetable_stock = float(d.get("vegetable_stock", vegetable_stock))
	generic_ingredient_stock = float(d.get("generic_ingredient_stock", generic_ingredient_stock))
	meal_stocks = (d.get("meal_stocks", {}) as Dictionary).duplicate(true)
	sync_meals_from_legacy_food()
	service_rank = int(d.get("service_rank", service_rank))
	total_guests = int(d.get("total_guests", total_guests))
	total_gold_earned = int(d.get("total_gold_earned", total_gold_earned))
	guest_type_counts = (d.get("guest_type_counts", {}) as Dictionary).duplicate(true)
	upgrade_levels = (d.get("upgrade_levels", {}) as Dictionary).duplicate(true)
	vegetable_stock = clampf(vegetable_stock, 0.0, float(vegetable_cap()))
	generic_ingredient_stock = clampf(generic_ingredient_stock, 0.0,
		float(generic_ingredient_cap()))
	tool_levels = (d.get("tool_levels", {}) as Dictionary).duplicate(true)
	skills = (d.get("skills", {}) as Dictionary).duplicate(true)
	action_counts = (d.get("action_counts", {}) as Dictionary).duplicate(true)
	staff = (d.get("staff", []) as Array).duplicate(true)
	placement_slots = int(d.get("placement_slots", placement_slots))
	active_work = str(d.get("active_work", active_work))
	tutorial_slot_unlocked = bool(d.get("tutorial_slot_unlocked", tutorial_slot_unlocked))
	last_saved_at = int(d.get("last_saved_at", 0))
	# 型付き配列へはコピーして格納する
	unlocked_upgrades.clear()
	for v in d.get("unlocked_upgrades", []):
		unlocked_upgrades.append(str(v))
	badges.clear()
	for v in d.get("badges", []):
		badges.append(str(v))
	titles.clear()
	for v in d.get("titles", []):
		titles.append(str(v))
	event_log = (d.get("event_log", []) as Array).duplicate()
