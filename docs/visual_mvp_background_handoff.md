# Visual MVP Background Handoff

作成日: 2026-06-15  
ブランチ: `feature/visual-mvp-background`

## 完了したこと

- 参考画像 `docs/references/visual_concept_taskbar_inn_godot.png` を確認した。
- 参考画像は完成アセットとして直接使わず、Godot 実装へ分解するための構成案として扱う方針にした。
- Visual MVP 向けの設計書 `docs/visual_mvp_design.md` を作成した。
- 設計書では、背景画像とキャラクタースプライトを最優先にし、家具・小物・アイテム類は後回しにした。

## 設計書に整理した内容

- 目的とスコープ
- 必要アセット一覧
- 背景、キャラクター、最小演出、UI/吹き出し系のファイル名案
- Godot の Scene Tree 例
- `Sprite2D` / `AnimatedSprite2D` / `Node2D` / `Control` の使い分け
- 歩行、座る、寝る、吹き出し、ランプ揺らぎの MVP 実装方針
- 宿Lv1〜Lv8 の背景レベルアップ方針
- 生成AIで素材を作る場合の順番と注意点

## 重要な判断

- MVP 背景は `1枚絵ベース + 最小限のライトレイヤー` から始める。
- 将来拡張を考慮し、背景・キャラ・吹き出し・ライト・UI は Godot 上で別ノードとして扱う。
- キャラは小さめにし、歩行を最優先にする。
- 座る、寝るはフルアニメではなく、状態スプライト切り替えで表現する。
- 会話吹き出しは将来、イベントやヒントのフックとして使える前提にする。

## 次の一手

1. `assets/visual/backgrounds/inn_room/inn_room_lv01_base.png` のアートターゲットを作る。
2. 店員1人、客1人の最小スプライトセットを作る。
3. `scripts/ui/inn_visual_view.gd` 相当の仮表示ノードで、背景・座席・ベッド・入口座標を確認する。
4. ランプ光と吹き出しを仮実装し、生活感の最小演出を検証する。

## Visual MVP Step 1 実装メモ

2026-06-15 に `scripts/ui/inn_visual_view.gd` を追加し、Home 画面へ「宿屋ビジュアルプレビュー」として表示する導線を作った。

- 背景画像の想定パスは `assets/visual/backgrounds/inn_room/inn_room_lv01_base.png`。
- 背景画像がない場合は、16:9 の `Inn Room Lv01 Placeholder` を描画する。
- 仮マーカーは `Entrance / Hall 01 / Hall 02 / Seat 01 / Seat 02 / Bed 01`。
- 固定ルートは `entrance_to_seat_01` と `seat_01_to_bed_01`。
- マーカー座標は `scripts/ui/inn_visual_view.gd` の `MARKERS`、ルートは `ROUTES` を調整する。
- 将来のキャラ移動用に `get_marker_position(marker_name)` と `get_route(route_name)` を用意した。

この段階ではキャラクター表示、歩行アニメ、家具/小物の個別PNG化、背景生成は未実装。

## Visual MVP Step 1.5 実装メモ

2026-06-16 に、宿屋ビューを Home 内の小さなプレビューから Expanded 画面内の常設ステージへ変更した。

- `ExpandedView` は `左ナビ / 宿屋ステージ / 管理パネル` の3カラム試作レイアウトになった。
- `InnVisualView` はタブ切り替えで作り直されず、Expanded 画面内に残り続ける。
- Home/仕事/厨房/設備/スタッフ/道具/ログ/実績は、右側の管理パネル内で切り替える。
- DEVマーカーと固定ルートはステージ右上の `ルート` ボタンで ON/OFF できる。
- 次にキャラ往復移動を入れる場合は、`scripts/ui/inn_visual_view.gd` の `get_route()` と `start_preview_patrol()` を入口にする。

この段階でもキャラクター表示、歩行アニメ、下部ナビ化、管理UIの完成デザイン化は未実装。

## Visual MVP Step 1.6 実装メモ

2026-06-16 に、中央ステージ型レイアウトから `右ペイン宿屋背景 + 管理UIオーバーレイ` 構成へ試作を進めた。

- 左サイドバーと上部HUDは維持した。
- 右ペイン全体へ `InnVisualView` を敷き、宿屋背景を背景レイヤーとして扱う構成にした。
- `WorkStatusPanel` は上部の大きな横長表示から、右ペイン左上のコンパクトオーバーレイへ移動した。
- Home/仕事/厨房/設備/スタッフ/道具/ログ/実績の既存ページは、右ペイン上の `ManagementOverlay` 内で切り替える。
- 右上の `UI` ボタンで管理オーバーレイを表示/非表示にできる。
- `ルート` ボタンで DEV マーカー/固定ルートを表示/非表示にできる。

この試作は「宿屋ビューが背景として常設され、その上へ介入UIを重ねる」思想の確認用。キャラクター自動行動、半透明パネルの本格デザイン、ページごとの最適なオーバーレイ幅調整は次段階。
