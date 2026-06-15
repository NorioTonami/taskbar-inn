# ROADMAP.md — Taskbar Inn v0.3 着手順 / 進捗台帳

正本は `docs/SPEC.md`（v0.3）。数値は `docs/GAME_BALANCE.md`。
各フェーズ末で headless 起動を通すこと。
検証: `"C:\Users\Tonami\Desktop\gamedev\engines\godot\4.6.3\godot.exe" --headless --path . --quit`

v0.2（方針 style）は撤去。実装は **マイルストーンA → B** の2段。

---

## マイルストーンA — 素泊まり階層の縦1本 ＋ dev インフラ

### A0 — 撤去とデータ刷新
- [x] inn_styles.json / inn_style_manager.gd を撤去、参照を除去
- [x] upgrades.json をカテゴリ化（基礎・内装／厩舎削除）
- [x] guest_types.json を素泊まり向けに簡素化（style/stable 依存除去）
- [x] events.json / badges.json / titles.json を新フィールドへ更新
- [x] skills.json / staff_roles.json / tools.json / dev_config.json を新規作成

### A1 — 状態と基盤
- [x] game_state.gd 刷新（dirtiness/skills/staff/tool_levels/placement_slots/active_work 等＋to/from_dict）
- [x] cond_eval.gd 拡張（staff_count / skill.<id> / tool.<id> 解決）
- [x] data_loader.gd（流用）

### A2 — マネージャ
- [x] upgrade_catalog.gd 刷新（category/unlock、style/stable 派生を除去）
- [x] guest_manager.gd 刷新（style/stable バイアス除去）
- [x] skill_manager.gd 新規（手動作業 tick・効果・XP・Lv）
- [x] staff_manager.gd 新規（雇用ゲート・自動 tick・XP・Lv）
- [x] tool_catalog.gd 新規（2系統・世代購入・bonus 参照）

### A3 — シミュレータ
- [x] inn_simulator.gd 刷新（到着で汚れ加算/ペナルティ、手動作業、スタッフ自動、評判、退室、イベント、チュートリアル、表彰）
- [x] apply_offline 刷新（汚れ収支＋控えめ収入）

### A4 — UI（少しマシ）
- [x] compact_view.gd（汚れ表示・作業表示・吹き出し・危険サイン色）
- [x] expanded_view.gd（ヘッダ＋タブ：設備/仕事/ログ/実績、style UI 撤去）
- [x] work_panel.gd 新規（作業モード選択・清掃スキル・道具・スタッフ雇用/一覧）
- [x] upgrade_panel.gd（カテゴリ見出し・unlock 表示）

### A5 — 保存・dev
- [x] save_manager.gd（reset 追加）/ オフライン＋片付けトースト
- [x] dev_overlay.gd 新規（F9・time scale・gold/評判/汚れ/枠・5人強制・リセット）
- [x] main.gd 刷新（配線・time_scale ループ・dev・新ハンドラ）

### A6 — 検証
- [x] `--headless --path . --quit` パースエラー無し
- [x] smoke: 放置→チュートリアル枠解放、手動清掃→汚れ減＋スキルLv、道具で手動効率↑、
      雇用枠制限、スタッフ自動清掃、room_plusで dirty_cap↑、オフラインで汚れcap到達、save/load roundtrip
- [ ] 実機（GUI）でウィンドウ常駐・タブ操作・トーストの目視確認（次セッション）
- [ ] バランス調整：オフライン収入が高め（occupancy 0.4 と p上限の見直し候補）

検証ログ（A）: global_script_class_cache 再生成後、パースエラー無し。smoke test 全 assert 通過。

---

## マイルストーンB — 厚み（後続）

### B1 — サービス階層②（食事つき）★完了
- [x] service_tiers.json（rank/unlock）＋ service_tier_manager.gd（ランクアップ判定）
- [x] skills.json に cooking（target:stock→food_stock）＋ tier_req、skill_manager 汎用化
- [x] staff_roles.json に cook＋tier_req、staff_manager を skill 共通適用に
- [x] tools.json に料理道具2系統、game_state に food_stock/service_rank/food_cap()
- [x] simulator：食事提供で単価UP（在庫消費）＋オフライン食材収支
- [x] UI：ランクアップ section・cooking 作業/道具/料理人・compact/expanded に食材表示
- [x] dev：ランクUP/食材満/食材0 ボタン
- [x] headless OK＋smoke（ランクゲート/cooking在庫/食事単価/cook雇用ゲート/オフライン/roundtrip）

### B1.5 — UI 常駐強化（2026-06-15・実装済み / headless パス）
- [x] expanded: 作業状況カード（WorkStatusPanel）とホーム最新ログへ整理。作業モードをカード化
- [x] window: 展開時ミニ窓に追従／オフライン結果はクリックで閉じる・モーダル中もドラッグ可
- [x] UiTheme 適用・トーストをクリック透過・run.bat を毎回 import 化（古いキャッシュ起因の空タブ対策）
- [x] **UI 崩れの一次調整**（expanded 600x640、タブ領域確保、長いヘッダ/ログ/compact吹き出しを省略表示）
- [x] expanded: 左サイドバー + 右ページ構成へ変更（ホーム/設備/仕事/道具/ログ/実績）
- [x] ホーム: 定量ダッシュボード・通知エリア・宿アップデートを集約。設備一覧は設備ページへ分離
- [x] window: expanded を 1080x680 に拡張、横スクロールを抑制
- [x] 作業状況UIを WorkStatusPanel に統合し、下部の重複作業表示を削除
- [x] expanded を 1180x760 に拡張し、ホームを資源バー/状況グリッド/宿アップデート/最新ログへ整理
- [x] 宿アップデート欄の解放条件を複数行ラベル化して表示切れを修正
- [ ] 実機 GUI で UI 崩れが解消したか目視確認
- 詳細・再開メモは docs/SESSION_NOTES.md

### B1.6 — オーナー作業カード拡張（進行中）
- [x] もてなしカードを追加（暫定: 評判 +1、XPあり）
- [x] 清掃/調理は対象が満たされたら自動で休憩へ戻る（汚れ0・在庫満タン）
- [x] 「手を止める」を「休憩」へ変更
- [ ] 役割別に作業カードを追加（維持メーター=修繕/洗濯、能動バフ=もてなし、生産/採取=料理/釣り 等）
- [ ] 修繕＝故障メーター（汚れと同型）をスケール連動でアンロック
- [ ] 能動バフ系の新メカ（時限バフ）。skill_manager.apply_effect_for の分岐拡張＋state フィールド追加
- 方針正本: docs/SESSION_NOTES.md ＋ メモリ owner-work-cards-direction（Melvor 化に注意・意味づけ最優先）

### B1.7 — スタッフ管理の再設計メモ（設計未確定）
- [ ] 現行の「職種固定」スタッフモデルを維持するか、個体ごとのランダム能力＋後配置方式へ移行するか検討
- [ ] 配置換え頻度が高すぎる違和感を避けるため、宿レベル/宿数/配置枠/部門増加に合わせた管理規模を設計
- [ ] 雇用スタッフ数の上限・増加ペースを、宿の規模拡大とゲームバランスに紐づける

### B1.8 — 宿Lv/料理/倉庫再設計（進行中）
- [x] 1. 宿Lv定義とドキュメント
  - [x] 支店拡張を保留し、一軒の宿を巨大化させる方針を SPEC に反映
  - [x] `service_tiers.json` を宿Lv1〜Lv8の定義として拡張
  - [x] unlock 条件に `skill.<id>` / `upgrade.<id>` / `action.<id>` を組み合わせる方針を反映
  - [x] Lv2 は料理人を解放せず、手動料理＋厨房/保管庫の段階に変更
- [x] 2. 料理ランク別在庫と倉庫（basic/standard/good まで）
  - [x] `food_stock` 互換を維持しつつ、`meal_stocks` を保存・復元する状態構造を追加
  - [x] 料理保管庫から `meal_storage_capacity()` を算出し、compact/home/work に簡易表示
  - [x] 食事提供時にランク別料理を消費し、単価/評判へ反映
  - [ ] 食材保管庫/大型倉庫の cap と UI 表示を接続
- [x] 3. 収穫スキル・野菜在庫・食材パック（Lv2の最小ループ）
  - [x] 収穫スキルと収穫作業カードを `skills.json` / skill_manager に実装し、Lv2で解放
  - [x] 野菜在庫と食材保管庫/畑/野菜倉庫由来 cap を game_state / save に追加
  - [x] 食材パックを basic/standard/good の補助素材として追加（入手は dev 仮ボタン）
  - [x] Lv2以降の cooking が vegetable/generic ingredient を参照して調理済みを作る
  - [x] 果実・魚介・特産品などを素材カテゴリとして扱う方針を GAME_BALANCE に落とす
  - [ ] 農夫（自動収穫）は後続で `harvesting Lv3 + harvest_actions >= 30 + field Lv2` などに紐づける

### B1.9 — 設備効果の体感化 / 厨房ページ（実装済み / headless パス）
- [x] 清掃用具・厨房・畑のLvで、対応する手動作業クールダウンを短縮
- [x] `SkillManager.get_effective_cooldown()` を追加し、シミュレーションと作業UIが同じ所要時間を参照
- [x] 作業状況カード/仕事詳細に `所要 x.x秒` と設備短縮の理由を表示
- [x] 左サイドバー順を `ホーム / 仕事 / 厨房 / 設備 / スタッフ / 道具 / ログ / 実績` に更新
- [x] `KitchenPanel` を追加。調理済み内訳、野菜/食材パック、調理可否、客の要求ランク、調理ルールを表示
- [ ] GUI で厨房ページと作業カードの表示崩れを目視確認

### B2 以降（未着手）
- [ ] 街巡り（素材/食材パック/特産品/置き土産の入手導線候補）
- [ ] 展示MVP（置き土産/忘れ物/陳列/宿帳、パッシブ集客・売上・評判効果）
- [ ] 営業モード（business_modes.json）＝エリア選択放置
- [ ] 特殊設備拡張（温泉/サウナ/酒場/詰所…）と実績アンロック
- [ ] レア客（インフルエンサー/有名人/おしのび）と家族（複数人泊）
- [ ] マイナスイベント＋security 抑制
- [ ] 宿Lv4以降（取引宿 / 名物宿 / 温泉宿 / リゾート宿 / 大規模ホテル）の本実装
- [ ] 支店・立地は保留。再開する場合は一宿巨大化Lv8後に再設計する

---
検証ログ:
- A/B1: global_script_class_cache 再生成後、`--headless --path . --quit` パースエラー無し。smoke 全 assert 通過。
- リーク監査（2026-06）: 2400 フレームで objects 2036 / nodes 235 / orphans 0 で横ばい＝リーク無し。
  手順・baseline は AI_DEV_GUIDE.md「リーク監査」を正本とする。
- 常駐 perf: low_processor_mode / sleep 16000us / max_fps 30 を project.godot に適用（SETUP.md 参照）。
