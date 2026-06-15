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
