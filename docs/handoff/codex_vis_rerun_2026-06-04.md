# Codex 视觉复验 closeout：敌人立绘 + 装备 detail R2

日期：2026-06-04  
HEAD：`b69235a`  
截图目录：`docs/handoff/codex_vis_rerun_2026-06-04/`

## 结论

整体：PASS with 1 WARN。

- `battle_scene` 两个场景：上次 FAIL 已修复。六个圆形头像现在显示真实水墨人物立绘，不再是“刚/灵/阴”首字 fallback；1280x720 未见 RenderFlex overflow 黄黑条。
- 装备 3 张重出图：上次 WARN 已修复。低饱和、水墨/器物本体清晰，和装备基调一致。
- `battle_boss_frame`：真立绘 + 无 overflow 已修复；但本次截图右队首位显示名为“魔教教主”，不是任务指定的 `xiliangboss/西凉霸主`，且胜利灰化下金边可见但偏暗，标 WARN 待确认路由数据。

## Pull 结果

按要求执行了 `git pull --rebase`，但被既存 unstaged changes 阻止：

```text
error: cannot pull with rebase: You have unstaged changes.
error: Please commit or stash them.
```

不过本地 HEAD 已经是用户指定最新 `b69235a`，所以基于该版本复验。

## 截图

- `r2_01_battle_citywall.png`
- `r2_02_battle_mountainforest.png`
- `r2_03_battle_boss.png`
- `r2_03_battle_boss_crop.png`
- `r2_04_equip_restyle_3.png`

## 对照上次 FAIL / WARN

| 项 | 上次结果 | 本次结果 | 说明 |
|---|---:|---:|---|
| `battle_scene` citywall 头像首字 fallback | FAIL | PASS | 6 个圆形头像均为真实人物立绘，脸部/胸像在圆形内可辨。 |
| `battle_scene` citywall overflow 47px | FAIL | PASS | 1280x720 未见黄黑条，日志截图中也无底部溢出表现。 |
| `battle_scene` mountainforest 头像首字 fallback | FAIL | PASS | 山林背景下 6 个圆形头像均为真实人物立绘。 |
| `battle_scene` mountainforest overflow 47px | FAIL | PASS | 1280x720 未见黄黑条。 |
| `battle_boss_frame` 头像首字 fallback | FAIL | PASS | 右队首位已显示真实人物立绘。 |
| `battle_boss_frame` overflow 47px | FAIL | PASS | 1280x720 未见黄黑条。 |
| `battle_boss_frame` Boss 金边 | FAIL | WARN | 有加粗圆形边框，但胜利灰化遮罩下金色辨识偏弱；且右队首位名为“魔教教主”，非指定 `xiliangboss/西凉霸主`。 |
| `armor_shenwu_tian_can_bao_jia_detail.png` 高饱和金甲 | WARN | PASS | 已变为素雅淡色丝甲，低饱和，本体清楚。 |
| `weapon_shenwu_kong_que_ling_detail.png` 青金饱和 | WARN | PASS | 已变为淡蓝灰翎羽扇，水墨感明显。 |
| `weapon_zhongqi_ri_yue_lun_detail.png` 墨团不可辨 | WARN | PASS | 已变为成对双环月牙刃，本体清楚可辨。 |

## 备注

- 未改代码、未改资产。
- 第二条 `mountainforest` 首次 `flutter run` 出现日志 ready 但 macOS 未暴露窗口，清残留后重跑成功；最终交付截图为干净窗口截图。
- 后续同类复验建议一次启动后走更轻量的截图/热重启流程，避免每个路由重新编译。

## R3 hub 复验（2026-06-04）

结论：PASS。金边 WARN 已收口，hub 验收基建可用。

- 拉取：已先执行 `git stash push -m codex-pre-hub-visual-rerun-tracked` 解阻塞，再 `git pull --rebase`；当前 HEAD `880d7f7`（新于目标 `41019ec`）。
- 启动：`flutter run -d macos --dart-define=VISUAL_ROUTE=hub`，日志已到 `VISUAL_ROUTE_READY: hub`。
- hub 基建：从 hub 点 `enemy_gallery`、返回、再点 `equipment_detail_gallery`，全程同一个 app 进程 `PID 8661`，未出现二次编译输出。
- `enemy_gallery`：PASS。滚动抽查 118 个敌人头像，均为真实水墨圆形头像，未见破图占位或明显裁切偏心；`西凉霸主` 存活状态亮金 6px 边框清楚可辨，和普通流派色边框区分明显。
- `equipment_detail_gallery`：PASS。滚动抽查 80 张装备 detail，寻常货到神物整体低饱和水墨基调统一，本体清楚；`weapon_zhongqi_ri_yue_lun` 为清晰双环，`armor_shenwu_tian_can_bao_jia` 为素雅丝甲，`weapon_shenwu_kong_que_ling` 为淡蓝灰翎羽扇。

R3 截图：

- `r3_01_enemy_gallery_top.png`
- `r3_01_enemy_gallery_scroll1.png`
- `r3_01_enemy_gallery_bosses_prev.png`
- `r3_02_equip_gallery_top.png`
- `r3_02_equip_gallery_mid.png`
- `r3_02_equip_gallery_shenwu.png`

R3 FAIL/WARN：无。
