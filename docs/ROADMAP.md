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
- [x] expanded: タブ下に作業アニメ＋進捗バー（WorkStrip）と常時ログ3行（MiniLog）。作業モードをカード化
- [x] window: 展開時ミニ窓に追従／オフライン結果はクリックで閉じる・モーダル中もドラッグ可
- [x] UiTheme 適用・トーストをクリック透過・run.bat を毎回 import 化（古いキャッシュ起因の空タブ対策）
- [x] **UI 崩れの一次調整**（expanded 600x640、タブ領域確保、長いヘッダ/ログ/compact吹き出しを省略表示）
- [ ] 実機 GUI で UI 崩れが解消したか目視確認
- 詳細・再開メモは docs/SESSION_NOTES.md

### B1.6 — オーナー作業カード拡張（設計合意・未着手）
- [ ] 役割別に作業カードを追加（維持メーター=修繕/洗濯、能動バフ=もてなし、生産/採取=料理/釣り 等）
- [ ] 修繕＝故障メーター（汚れと同型）をスケール連動でアンロック
- [ ] 能動バフ系の新メカ（時限バフ）。skill_manager.apply_effect_for の分岐拡張＋state フィールド追加
- 方針正本: docs/SESSION_NOTES.md ＋ メモリ owner-work-cards-direction（Melvor 化に注意・意味づけ最優先）

### B2 以降（未着手）
- [ ] 営業モード（business_modes.json）＝エリア選択放置
- [ ] ドロップ/陳列/宿帳（collectibles.json）
- [ ] 特殊設備拡張（温泉/サウナ/酒場/詰所…）と実績アンロック
- [ ] レア客（インフルエンサー/有名人/おしのび）と家族（複数人泊）
- [ ] マイナスイベント＋security 抑制
- [ ] サービス階層③PB供給 / ④ハイテク化 / 支店・立地

---
検証ログ:
- A/B1: global_script_class_cache 再生成後、`--headless --path . --quit` パースエラー無し。smoke 全 assert 通過。
- リーク監査（2026-06）: 2400 フレームで objects 2036 / nodes 235 / orphans 0 で横ばい＝リーク無し。
  手順・baseline は AI_DEV_GUIDE.md「リーク監査」を正本とする。
- 常駐 perf: low_processor_mode / sleep 16000us / max_fps 30 を project.godot に適用（SETUP.md 参照）。
