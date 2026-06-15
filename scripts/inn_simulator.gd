class_name InnSimulator
extends RefCounted
# inn_simulator.gd — 1秒 tick ごとの計算（v0.3）。UI 非依存。
# 客の自動到着で汚れが増え、手動作業/スタッフ自動で汚れを下げる。
# 汚れが高いと集客・評判が鈍る。各種マネージャを束ねて毎秒評価し signal 通知する。

signal guest_arrived(type_def: Dictionary, line: String, price: int)
signal event_fired(event_def: Dictionary)
signal badge_unlocked(def: Dictionary)
signal title_unlocked(def: Dictionary)
signal slot_unlocked(slots: int)
signal skill_leveled(skill_id: String, level: int)
signal work_performed(skill_id: String, effect: int)

# --- バランス定数（docs/GAME_BALANCE.md と一致）---
const TICK_SECONDS: float = 1.0
const BASE_PRICE: float = 5.0
const DEPART_PROB: float = 0.15
const REP_GAIN_BASE: float = 0.02
const EVENT_PROB_PER_SEC: float = 0.20
const OFFLINE_CAP_SECONDS: int = 28800
const DIRTY_PER_GUEST: float = 2.0
const REP_THRESH_FRAC: float = 0.60
const RATE_THRESH_FRAC: float = 0.80
const TUTORIAL_GUESTS: int = 5
const FOOD_PER_GUEST: float = 1.0     # 食事1食あたりの在庫消費（②以降）
const MEAL_PRICE_MULT: float = 1.5    # 食事を提供できた客の単価倍率
const DOWNRANKED_MEAL_PRICE_MULT: float = 1.2

var state: GameState
var upgrades: UpgradeCatalog
var guests: GuestManager
var events: EventManager
var badges: BadgeManager
var titles: TitleManager
var skills: SkillManager
var staff: StaffManager
var tools: ToolCatalog

var price_mult: float = 1.0          # dev 調整用

var _rep_accumulator: float = 0.0
var _work_timer: float = 0.0
var _last_work_id: String = ""

func _init(p_state: GameState, p_upgrades: UpgradeCatalog, p_guests: GuestManager,
		p_events: EventManager, p_badges: BadgeManager, p_titles: TitleManager,
		p_skills: SkillManager, p_staff: StaffManager, p_tools: ToolCatalog) -> void:
	state = p_state
	upgrades = p_upgrades
	guests = p_guests
	events = p_events
	badges = p_badges
	titles = p_titles
	skills = p_skills
	staff = p_staff
	tools = p_tools

# --- 汚れ係数 ---
func _dirt_rate_factor() -> float:
	var cap: float = float(state.dirty_cap())
	var thr: float = cap * RATE_THRESH_FRAC
	if state.dirtiness <= thr:
		return 1.0
	var t: float = clampf((state.dirtiness - thr) / maxf(1.0, cap - thr), 0.0, 1.0)
	return lerpf(1.0, 0.2, t)

func _dirt_rep_factor() -> float:
	if state.dirtiness > float(state.dirty_cap()) * REP_THRESH_FRAC:
		return 0.5
	return 1.0

func guest_rate() -> float:
	var base: float = state.rooms * 0.4 + state.reputation * 0.05
	return base * _dirt_rate_factor()

func _compute_price(type_def: Dictionary) -> int:
	var p: float = (BASE_PRICE + state.comfort * 2 + state.food * 2 + state.cleanliness)
	p *= float(type_def.get("base_price_multiplier", 1.0))
	p *= price_mult
	return int(round(p))

# 1秒分の進行。
func tick() -> void:
	_do_active_work()
	staff.tick(state, TICK_SECONDS)
	_try_arrival()
	_accumulate_reputation()
	_try_departure()
	_try_event()
	_check_tutorial()
	_check_awards()

func _do_active_work() -> void:
	var id: String = state.active_work
	# 作業を切り替えたら進捗タイマーをリセット（バー表示と同期させる）
	if id != _last_work_id:
		_last_work_id = id
		_work_timer = 0.0
	if id == "" or not skills.has_skill(id):
		return
	if not skills.is_work_available(state, id):
		state.active_work = ""
		_last_work_id = ""
		_work_timer = 0.0
		return
	_work_timer += TICK_SECONDS
	var cd: float = skills.get_effective_cooldown(id, state)
	while _work_timer >= cd:
		_work_timer -= cd
		if not skills.is_work_available(state, id):
			state.active_work = ""
			_last_work_id = ""
			_work_timer = 0.0
			return
		var res: Dictionary = skills.perform(state, id)
		work_performed.emit(id, int(res.get("effect", 0)))
		if bool(res.get("leveled", false)):
			skill_leveled.emit(id, state.skill_level(id))

# UI 同期用: 現在の作業クールダウン進捗（0.0〜1.0）。作業なしは 0。
func work_progress() -> float:
	var id: String = state.active_work
	if id == "" or not skills.has_skill(id):
		return 0.0
	var cd: float = maxf(0.1, skills.get_effective_cooldown(id, state))
	return clampf(_work_timer / cd, 0.0, 1.0)

func _try_arrival() -> void:
	if state.guest_count >= state.guest_capacity:
		return
	var p: float = clampf(guest_rate(), 0.0, 1.0)
	if randf() > p:
		return
	var type_def: Dictionary = guests.pick(state)
	if type_def.is_empty():
		return
	var id: String = str(type_def.get("id", ""))
	state.add_guest_count(id, 1)
	state.total_guests += 1
	state.guest_count = min(state.guest_count + 1, state.guest_capacity)
	var price: int = _compute_price(type_def)
	# 食事つき階層：必要ランクに近い調理済みを1食消費して単価アップ
	if state.service_rank >= 2:
		var meal: Dictionary = state.consume_meal_for(
			str(type_def.get("required_meal_rank", "basic")), FOOD_PER_GUEST)
		if bool(meal.get("served", false)):
			if int(meal.get("rank_index", 0)) >= int(meal.get("required_index", 0)):
				price = int(round(price * MEAL_PRICE_MULT))
			else:
				price = int(round(price * DOWNRANKED_MEAL_PRICE_MULT))
				_rep_accumulator = maxf(-0.5, _rep_accumulator - 0.15)
		else:
			_rep_accumulator = maxf(-0.5, _rep_accumulator - 0.25)
	state.gold += price
	state.total_gold_earned += price
	state.dirtiness = minf(float(state.dirty_cap()), state.dirtiness + DIRTY_PER_GUEST)
	guest_arrived.emit(type_def, guests.random_line(id), price)

func _accumulate_reputation() -> void:
	var rep: float = (state.cleanliness + state.food) * REP_GAIN_BASE
	rep *= _dirt_rep_factor()
	_rep_accumulator += rep
	if _rep_accumulator >= 1.0:
		var gain: int = int(_rep_accumulator)
		state.reputation += gain
		_rep_accumulator -= gain

func _try_departure() -> void:
	if state.guest_count > 0 and randf() < DEPART_PROB:
		state.guest_count -= 1

func _try_event() -> void:
	if randf() < EVENT_PROB_PER_SEC:
		var e: Dictionary = events.fire_one(state)
		if not e.is_empty():
			event_fired.emit(e)

func _check_tutorial() -> void:
	if not state.tutorial_slot_unlocked and state.total_guests >= TUTORIAL_GUESTS:
		state.tutorial_slot_unlocked = true
		state.add_log("スタッフ詰め所が設備に追加されました。建てるとスタッフを雇えます")
		slot_unlocked.emit(state.placement_slots)

func _check_awards() -> void:
	for b in badges.check(state):
		badge_unlocked.emit(b)
	for t in titles.check(state):
		title_unlocked.emit(t)

# --- オフライン進行（集計式）---
# 経過秒を最大 OFFLINE_CAP_SECONDS でクランプ。留守中の収入と汚れ収支を概算。
func apply_offline(elapsed_seconds: int) -> Dictionary:
	var sec: int = clampi(elapsed_seconds, 0, OFFLINE_CAP_SECONDS)
	if sec <= 0:
		return {"guests": 0, "gold": 0, "reputation": 0, "events": 0, "seconds": 0}

	var p: float = clampf(guest_rate(), 0.0, 1.0)
	var arrivals: int = int(sec * p * 0.4)

	var avg_type: Dictionary = guests.get_type("traveler")
	if avg_type.is_empty():
		avg_type = {"base_price_multiplier": 1.0}
	var avg_price: int = _compute_price(avg_type)
	var gold_gain: int = arrivals * avg_price

	var rep_per_sec: float = (state.cleanliness + state.food) * REP_GAIN_BASE
	var rep_gain: int = int(rep_per_sec * sec * 0.5)
	var ev_count: int = int(sec * EVENT_PROB_PER_SEC * 0.1)

	# 汚れ収支：留守中の客で増え、配置中スタッフで減る
	var dirt_added: float = arrivals * DIRTY_PER_GUEST
	var dirt_cleaned: float = staff.auto_per_sec_for(state, "cleaning") * sec
	state.dirtiness = clampf(state.dirtiness + dirt_added - dirt_cleaned, 0.0, float(state.dirty_cap()))

	# 調理済みの収支（②以降）：料理人が素材を消費して作り、客が合計在庫から食べる
	if state.service_rank >= 2:
		var cooked: float = staff.auto_per_sec_for(state, "cooking") * sec
		state.cook_meals(cooked)
		_consume_offline_meals(arrivals * FOOD_PER_GUEST)

	state.gold += gold_gain
	state.total_gold_earned += gold_gain
	state.reputation += rep_gain
	state.total_guests += arrivals
	state.add_guest_count("traveler", arrivals)

	return {
		"guests": arrivals,
		"gold": gold_gain,
		"reputation": rep_gain,
		"events": ev_count,
		"seconds": sec,
		"dirtiness": int(state.dirtiness),
		"dirty_cap": state.dirty_cap(),
	}

func _consume_offline_meals(amount: float) -> void:
	var remaining: float = amount
	for rank in GameState.MEAL_RANKS:
		if remaining <= 0.0:
			return
		var cur: float = state.meal_stock(rank)
		var used: float = minf(cur, remaining)
		state.meal_stocks[rank] = cur - used
		remaining -= used
	state.sync_food_stock_from_meals()
