# SESSION_NOTES.md — 作業ハンドオフ / 再開メモ

コンテキストをクリアしても再開できるよう、直近セッションの実装・既知の問題・実装予定をまとめる。
最新セクションを先頭に置く。正本の設計は SPEC/ROADMAP/GAME_BALANCE、起動は SETUP.md。

---

## 2026-06-15 締め — 次回 /clear 後の再開メモ

### 今回の正本
- 本作の拡張方針は **支店ではなく、一軒の宿を Lv1〜Lv8 へ巨大化**。
- `data/service_tiers.json` は旧称サービス階層だが、現状は **宿Lv定義** として使う。
- Lv2 は料理解放。料理は個別レシピではなく `meal_stocks` のランク別在庫
  (`basic` / `standard` / `good` / `luxury` / `specialty` / `vip`)。
- Lv3 は自力調達開始。`harvesting` → `vegetable_stock` → `cooking` → `meal_stocks` の最小ループが動く。
- `food_stock` は削除禁止。旧セーブ互換のため、合計料理在庫として `meal_stocks` と同期する。
- 外部購入は万能な自動補完にしない。`generic_ingredient_stock` は basic/standard/good までの補助素材で、
  現時点の入手は dev ボタン「素材+20」のみ。
- 倉庫の役割は分離済みの方向性:
  食材保管庫=未調理食材 cap、料理保管庫=調理後料理 cap、冷蔵庫=ロック定義中心で本効果は後続。
- 料理人は `tier_req:3` に加えて `action.cooking >= 20` で解放。農夫はまだ未実装。

### 実装済み
- 左サイドバー UI、道具ページ分離、もてなしカード、料理ランク別在庫、収穫スキル、野菜/汎用素材在庫。
- `GameState` は `meal_stocks` / `vegetable_stock` / `generic_ingredient_stock` を save/load する。
- `SkillManager` は清掃、もてなし、仕込み、収穫を処理する。
- Lv3以降の仕込みは野菜または汎用素材を消費する。材料が無い場合は仕込みカードを開始できない。

### 未実装 / 後続
- Lv4以降（取引宿、名物宿、温泉宿、リゾート宿、大規模ホテル）は定義中心で、本格システムは未実装。
- 農夫/自動収穫、汎用素材の正式入手経路、果実/魚介/肉/卵/醸造、luxury 以上の料理運用は未実装。
- 冷蔵庫はロック定義だけ。保存効果や鮮度システムは未実装。
- 支店/立地は保留。再開する場合は一宿Lv8巨大化後に再設計する。
- GUI 目視確認と UI 崩れ最終確認は未完了。headless は通っている。

### 次回最初にやること
1. `docs/SPEC.md` / `docs/ROADMAP.md` / この最新セクションを読む。
2. GUI で compact/expanded/仕事/道具/設備ページを目視確認する。
3. Lv2→Lv3 のプレイテンポを調整する。特に `action.cooking >= 20`、野菜 cap、料理生成量。
4. 次の実装候補は「農夫の解放条件と自動収穫」または「汎用素材の正式入手経路」。

---

## 2026-06-15 追記 — Lv3 自力調達ループ（収穫→野菜→料理）

### 実装済み
- `data/skills.json`: `harvesting`（収穫）を追加。Lv3解放、`target=stock` / `affects=vegetable_stock`。
- `GameState`: `vegetable_stock` と `generic_ingredient_stock` を追加し、save/load に対応。
  `vegetable_cap()` は食材保管庫Lv・畑Lv・野菜倉庫Lvから算出、`generic_ingredient_cap()` は食材保管庫Lvから算出。
- `SkillManager`: stock 分岐を拡張し、収穫で野菜在庫が増える。野菜在庫が満タンなら収穫カードは停止。
- Lv3以降の `cooking` は `vegetable_stock` または `generic_ingredient_stock` を消費して `meal_stocks` を作る。
  材料が一部足りない場合は生成量ぶんだけ作り、材料が無い場合は仕込みカードを開始できない。
- `generic_ingredient_stock` は basic/standard/good までの補助素材。完全自動補充は入れず、初期実装では dev ボタン
  「素材+20」で補充できるだけにした。
- UI: 仕事タブに Lv3 で収穫カードが出る。ホームに野菜在庫/汎用素材を表示。compact は情報過多を避け、
  引き続き料理在庫合計のみ表示。
- `data/service_tiers.json`: Lv3の解放スキルを `harvesting` に更新。Lv4仮条件も `skill.harvesting` /
  `action.harvesting` に変更。

### 未実装 / 後続扱い
- 農夫/自動収穫スタッフは未実装。後続で `harvesting Lv3 + action.harvesting >= 30 + field Lv2` などに紐づける。
- 果実、釣り、肉、卵、醸造、luxury 以上の素材要求は未実装。
- 汎用素材の本入手経路（仮購入、イベント、商談、仕入れなど）は未実装。現時点では dev 補助のみ。
- オフライン中の野菜自動増加は未実装。自動化スタッフ追加までは手動収穫を前提にする。

---

## 2026-06-15 追記 — 料理ランク別在庫への段階移行

### 実装済み
- `food_stock` は削除せず、旧セーブ互換用の合計料理在庫フィールドとして残した。
  新しい正の状態は `meal_stocks`（`basic` / `standard` / `good` / `luxury` / `specialty` / `vip`）。
- 実運用ランクは `basic`（簡単な食事）/ `standard`（家庭料理）/ `good`（宿の定食）まで。
  `luxury` 以上はデータ上の予約枠で、UI は詳細運用しない。
- `GameState` に `meal_storage_capacity()`、`add_meal_stock()`、`consume_meal_for()` などの互換レイヤーを追加。
  古いセーブに `meal_stocks` が無い場合、既存 `food_stock` を `basic` 在庫へ移して同期する。
- `cooking` 作業は `food_stock` ではなく `meal_stocks` を増やす。
  仮ルールは厨房Lv1=`basic`、Lv2=`standard`、Lv3+=`good`。料理Lvが足りない場合は一段下げる。
- 客定義に `required_meal_rank` を追加。一般人/旅人は `basic`、旅商人は `standard`。
- 客到着時は要求ランク以上のうち一番低い料理を消費し、なければ下位ランクの一番高い料理を提供する。
  下位提供時は食事単価ボーナスを控えめにし、評判蓄積を少し削る。料理が完全に無い場合は食事ボーナスなし。
- オフライン進行は、料理人の自動仕込みを現在作れる最高ランクへ加算し、客数ぶんを合計料理在庫から簡易消費する。
- compact は料理合計だけ、home/work/expanded は basic/standard/good の簡易内訳を表示する。

### 未実装 / 後続扱い
- 個別料理名、レシピ、料理方針、`luxury` 以上の本格運用は未実装。
- 食材保管庫と大型倉庫の cap 接続、野菜/果実/魚介/特産品の素材供給は未実装。
- `food_stock` はしばらく互換フィールドとして残す。後続でセーブ移行が安定してから参照削減を検討する。

---

## 2026-06-15 追記 — 宿Lv1〜Lv8 / 一宿巨大化への仕様更新

### 設計決定
- 支店拡張ではなく、**一軒の宿をLv8まで巨大化させる**方針を本線に変更。
- 既存実装は `service_tiers.json` / `service_rank` / `ServiceTierManager` でランクアップ UI と判定を持っているため、
  新規 `inn_levels.json` は作らず、`service_tiers.json` を実質的な **宿Lv定義** として拡張した。
- `docs/SPEC.md` に宿Lv1〜Lv8の表を追加し、支店/立地拡張は本作では保留と明記。
- `docs/ROADMAP.md` に B1.8「宿Lv/料理/倉庫再設計」を追加し、3段階
  （宿Lv定義とドキュメント → 料理ランク別在庫と倉庫 → 収穫スキル・野菜在庫・汎用素材）に分けた。

### データ/コード更新
- `data/service_tiers.json`: Lv1〜Lv8を追加。Lv2条件は
  `total_guests >= 10` / `reputation >= 20` / `skill.cleaning >= 2` / `upgrade.room_plus >= 2`。
  Lv3条件は cooking Lv、料理作業回数、厨房Lv、食材保管庫Lvを含めた仮条件。
- `data/upgrades.json`: 食材保管庫、料理保管庫、畑、野菜倉庫、商談机、宿帳台、置き土産棚、
  温泉浴場、庭園、酒場、用心棒詰所、大型厨房、大型倉庫、管理事務所を定義追加。
  未実装設備は `effects:{}` にして副作用なし。
- `data/staff_roles.json`: 料理人は Lv2 では解放せず、暫定で `tier_req:3` に変更。
- `scripts/cond_eval.gd`: `upgrade.<id>` と `action.<id>` 条件を解決できるようにした。
- `scripts/game_state.gd` / `skill_manager.gd`: 手動作業回数 `action_counts` を保存・復元し、作業実行時に加算する。

### 未実装 / 後続扱い
- 料理ランク別在庫、食材/料理/野菜/大型倉庫の cap 接続、倉庫 UI は未実装。
- 収穫スキル、野菜在庫、農夫、商談/市場調査、名物料理、温泉採掘、醸造、警備、采配、設備管理は未実装。
  今回は `service_tiers.json` 上の定義またはアップグレード定義のみ。
- Lv4以降の unlock 数値は仮。`docs/GAME_BALANCE.md` で後続調整する。
- Dev の「ランクUP」ボタンで未実装Lvへ進めることはできるが、対応スキル/メーター/UIはまだ接続されていない。

---

## 2026-06-15 追記 — UI再編 / 仕事・道具分離 / スタッフ設計メモ

### 実装済み（headless パス済み）
- `scripts/ui/expanded_view.gd`: 上タブを廃止し、**左サイドバー + 右ページ**へ変更。
  メニューは `ホーム / 設備 / 仕事 / 道具 / ログ / 実績`。
- `scripts/window_manager.gd`: expanded サイズを **1080x680** に変更。
- `scripts/ui/home_panel.gd`: ホームは宿の定量ダッシュボード、通知、宿アップデートに整理。
  設備投資一覧はホームから外した。
- `scripts/ui/upgrade_panel.gd`: 設備ページとして独立表示。
- `scripts/ui/tool_panel.gd`: 道具ページを新規追加。プレイヤー用/スタッフ用ツール投資を仕事タブから分離。
- `scripts/ui/work_panel.gd`: 仕事タブは作業カードとスタッフ雇用/一覧に集中。
  「手を止める」は「休憩」へ変更。
- `data/skills.json` / `skill_manager.gd`: `hospitality`（もてなし）を追加。
  現状は `target=stat, affects=reputation` の暫定効果で評判を上げる。
- `skill_manager.gd` / `inn_simulator.gd`: 清掃は汚れ 0、仕込みは在庫満タンのとき作業を止め、
  自動で休憩へ戻る。
- `data/service_tiers.json`: 当時は開発中の高速リセット前提で、食事つき宿の仮条件を
  `total_guests >= 5` に軽量化していた。現在は上の「宿Lv1〜Lv8」セクションの条件が最新。

### UI 方針
- expanded は「ホームで現在地を見る」「設備/道具/仕事は個別ページで操作する」構成。
- ホームはトップページ的な情報集約に寄せる。設備や道具の購入操作は専用ページへ逃がす。
- 仕事ページの横スクロールは当面出さない。幅は今後 GUI 目視で微調整。

### スタッフ設計の未決論点
- 現行実装は「雇用する職種が担当ポストに直結する」簡易モデル。
- ユーザー案：よくある経営ゲームのように、雇用スタッフ個体ごとにランダムパラメーター/適性を持たせ、
  どのポストに配置するかを後で決める方式もあり得る。
- ただし、ころころ配置換えするゲーム感は宿経営として違和感がある。
  宿レベル、宿数、配置枠、サービス階層、部門増加に応じて、スタッフ数をどの規模まで増やすかが要点。
- この論点は ChatGPT 側で詳細を詰める予定。実装前に SPEC/ROADMAP へ再反映する。

### 未コミット
- 2026-06-15 の UI/仕事/道具変更と、この docs 更新はまだ push していない。

---

## 2026-06-15 セッション

### Codex引き継ぎ後の修正
- docs/SPEC.md / ROADMAP.md / SESSION_NOTES.md / GAME_BALANCE.md / AI_DEV_GUIDE.md を読み込み、現状は B1.5 まで実装済みと確認。
- 既知問題の「UI 崩れ」へ一次対応：
  - `scripts/window_manager.gd`: expanded サイズを 600x640 に拡大。
  - `scripts/ui/expanded_view.gd`: 余白/間隔を少し圧縮、タブ領域の最小高さを確保、ヘッダを省略表示。
  - `work_strip.gd` / `mini_log.gd` / `compact_view.gd`: 長いテキストを省略表示し、縦余白を軽量化。
- 検証：`--check-only`（expanded_view/work_strip/mini_log）と `--headless --path . --quit` はパス。
- 残り：実機 GUI で expanded/compact の見た目を目視確認し、まだ崩れる箇所があれば追加調整。

### このセッションで実装した変更（実装済み・headless パス済み）

**ウィンドウ／常駐まわり（`scripts/window_manager.gd`, `scripts/main.gd`）**
- compact→expanded 展開時、**ミニウィンドウの位置に追従**して開く。画面の上半分にあるなら下向き、
  下半分なら上向きに展開（`_place_following`）。閉じると展開前の compact 位置へ復帰（`_compact_pos` を記憶）。
- オフライン結果の小ダイアログ用に `apply_dialog()`（440x250、compact 位置に追従）。

**オフライン結果モーダル（`main.gd: _show_offline_panel`）**
- 自動で消えず**クリックで閉じる**モーダルに変更（暗幕＋中央パネル＋「✓ 確認して始める」）。
- モーダル表示中も**暗幕ドラッグでウィンドウ移動可**（`bg.gui_input → _drag_window`、ドラッグ処理を共通化）。

**トースト（`main.gd: _show_toast`）**
- パネル/ラベルを `MOUSE_FILTER_IGNORE` にして**クリック透過**。バッジ獲得トーストが
  compact の 📋（展開）ボタンに重なっても押せるよう修正。

**テーマ（`scripts/ui/ui_theme.gd` 新規 `UiTheme`）**
- 暖色の暗い木目＋琥珀アクセントの Theme を root Control に適用（compact/expanded/トーストへカスケード）。

**開発トグル（`main.gd`, `expanded_view.gd`）**
- expanded 下部ステータスバーに dev_mode 時のみ「🛠 DEV」トグルボタン。F9 も従来どおり有効。

**作業まわり — 仕事タブ＋常時表示（★今回の主目玉）**
- `scripts/ui/work_strip.gd` 新規 `WorkStrip`：タブ下に常駐する**作業アニメ＋進捗バー**。
  選択中スキルのクールダウンを UI 側 delta で 0→100% 表示し、実際の `perform()`（汚れ減少等）で
  0 リセット＋発光＋効果量表示（「🧹 -4」）。`is_visible_in_tree()` で非表示時は _process 停止。
- `scripts/ui/mini_log.gd` 新規 `MiniLog`：タブ下に**常時ログ3行**（最新が下・明るい）。ログタブは残置。
- `scripts/ui/work_panel.gd`：作業モードを **ButtonGroup のトグルカード**化（単一選択。別カードを
  押すと前の作業が自動オフ）。`_work_card()` ヘルパ、見出しは autowrap。
- `scripts/inn_simulator.gd`：`signal work_performed(skill_id, effect)` 追加、作業切替で `_work_timer`
  リセット（`_last_work_id`）、`work_progress()` 追加。`main.gd: _on_work_performed` → `expanded.on_work_performed`。

**起動の堅牢化（`run.bat`）**
- 旧 run.bat は**キャッシュファイルが無いときだけ** import していた。class_name を足すとキャッシュが
  古いまま起動して型解決失敗（expanded のタブ中身が空になる等）。→ **毎回 `--import`** してから起動するよう変更。
- 背景：「設備・仕事タブが空」の真因は**古い global_script_class_cache**。コード自体は正しく描画される
  ことを実機レンダリングのスクショで確認済み（新規・セーブあり・120tick 後すべて）。詳細は
  メモリ `godot-global-class-cache-regen` 参照。

### 既知の問題 / 次の最初の一手
- **UI が崩れている**（ユーザー報告。expanded に work_strip＋mini_log＋status bar を足して 520px 窓が
  窮屈になった可能性が高い）。**ユーザーが変更指示を追って出す予定**。再開時はまずスクショで現状確認 →
  どこがどう崩れているか切り分けてから直す。
- ROADMAP A6 の「実機 GUI 目視確認」「オフライン収入のバランス」は未了のまま。

### 次の実装テーマ：オーナー作業カードの拡張（ブレスト合意・未着手）
メモリ `owner-work-cards-direction` が正。要点：

- **役割別フレーム**で増やす（数だけ増やすと Melvor 化＝作業ゲーになるので意味づけ必須）：
  - A. 維持メーター系（放置で溜まる→減らす）＝最前線のやりくり：清掃(既存)/**修繕**/洗濯/害虫
  - B. 生産ストック系（溜める→客が消費）：仕込み(既存)/醸造/薪割り/水汲み
  - C. 能動バフ系（客に即作用・**新メカ＝一時バフが必要**）：**もてなし**/呼び込み/弾き語り/帳簿
  - D. 客タイプ特化：商談(商人)/道案内(冒険者)/道中弁当(旅人)
  - E. メタ/上級：庭園/風呂焚き/采配
- **合意した当面の方針**：
  - 追加カード候補＝🙇もてなし・🍳料理・🎣採取/釣り。
  - **修繕＝「設備修正カード」で故障状態を“汚れ”と同じ維持メーター**として扱う。
    最初は変数を持たず、**宿の規模拡大でアンロック**（スケール連動）。
  - 軸は「守り(維持メーター)＋攻め(もてなしの即得)」を先に立て、生産チェーン/採取は規模拡大のご褒美に。
  - 生産チェーン（水→清掃/料理/風呂 等）は別ゲーム性につながる種として温存。
- **実装上の注意**：
  - スキル効果モデルは `data/skills.json` の `target=meter(減)/stock(増)` × `affects=状態フィールド`、
    `base_effect + Lv×per + 道具bonus`、`cooldown_sec`、`tier_req`。対応する `staff_roles`/`tools` で自動化。
  - `skill_manager.gd: apply_effect_for` は現状 **dirtiness / meal_stocks / reputation** の最小分岐。
    新メーター/ストックを足すには game_state にフィールド追加＋分岐追加＋compact/expanded のメーター表示が要る。
  - **能動バフ系（もてなし等）は新システム**（時限バフが guest_rate/price/rep_gain を一時補正）が必要。

### 再開のしかた
1. `run.bat` をダブルクリック（毎回 import するので class_name 追加後もそのまま起動可）。
2. まず UI 崩れの現状をスクショ確認 → ユーザーの変更指示に沿って修正。
3. その後、上記「作業カード拡張」を役割フレームに沿って着手（まず維持メーター or もてなしの二軸から）。
