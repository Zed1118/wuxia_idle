# Codex 视觉验收 closeout：敌人立绘 + 装备 detail

日期：2026-06-04  
环境：macOS Flutter debug，窗口 1280x720（导航时短暂拉高过窗口，验收截图按 1280x720）  
截图目录：`docs/handoff/codex_visual_art_2026-06-04/`

## 结论先行

整体结论：FAIL。

- 战斗屏主验失败：三条战斗路由均出现头像首字兜底，没有渲染敌人立绘；同时 1280x720 下稳定出现 `RenderFlex overflowed by 47 pixels` 黄黑条。
- 装备详情页基础渲染可用：未见破图，`BoxFit.contain` 完整显示；但 detail 资产整体风格断层明显，很多是白底产品图/近照片/高饱和游戏图，不符合“水墨场景氛围”。
- 敌人资产独立抽查基本可用：top37 新图多为水墨胸像，`shidi_b` 女性正确，未见纯山水无人物、明显 anime/油画跳风格；但 app 战斗屏未接上这些图。

## 截图清单

- `01_battle_citywall.png`
- `02_battle_mountainforest.png`
- `03_battle_boss_frame.png`
- `04_inv_list.png`
- `05_detail_xunchang.png`
- `06_detail_liqi.png`
- `07_detail_shenwu_asset_direct.png`：神物资产直检，不是 app 详情页截图
- `asset_sheet_enemies_top37.png`
- `asset_sheet_equipment_detail_45.png`

## 路由验收

| 路由 / 场景 | 结果 | 一句话 |
|---|---|---|
| `battle_scene` citywall | FAIL | 六个圆形头像全部显示“刚/灵/阴”等首字兜底，未渲染敌人立绘；底部有 overflow 黄黑条。 |
| `battle_scene` + `VISUAL_SCENE=mountainforest` | FAIL | 背景正常切到山林，但头像仍是首字兜底，且同样 overflow 47px。 |
| `battle_boss_frame` | FAIL | Boss 位仍显示首字/灰暗圆形，金边头像无法有效验收；同样 overflow 47px。 |
| 背包列表 | WARN | 缩略图可渲染，列表无 overflow；但未能通过 debug 菜单进入 P2 seed，只基于当前本地背包验收。 |
| `weapon_xunchang_tie_jian` 详情 | PASS | app 内 detail 图 contain 完整，低阶水墨感可接受。 |
| `weapon_liqi_long_quan` 详情 | WARN | app 内 contain 完整、本体清楚，但白底单体产品图感强，缺少水墨场景氛围。 |
| 神物详情 | WARN | 当前背包没有神物条目，未能 app 内进入；改用 `armor_shenwu_tian_can_bao_jia_detail.png` 直检，见下方资产问题。 |

## 战斗屏 FAIL 项

- `CharacterAvatar` / 战斗单位头像：三条路由均未显示 `assets/enemies/*.png`，而是首字 fallback。
- `battle_screen.dart:790` 附近布局：三条路由日志均报 `RenderFlex overflowed by 47 pixels on the bottom`。
- Boss 金边：因头像未渲染且胜利遮罩变暗，Boss 6px 金边无法确认通过。
- 死亡灰化：可见整体半透/灰化差异，但因头像是 fallback 字，不算立绘灰化验收通过。

## 敌人资产抽查

结果：PASS with minor WARN。

- top37 新敌人图整体是水墨胸像，脸部多清晰居中。
- `shidi_b.png` 为女性，性别正确。
- 未见纯山水无人物、带马全身、明显 anime/油画跳风格。
- 轻微 WARN：少数图有明显题字/印章或脸部不够贴近圆形裁切中心，例如 `bazhu_youfu.png`、`xiliang_bazhu.png`、`yidu_jianke.png`、`lightfoot_changfeng_a.png`；若圆形头像接通后建议复看裁切。

## 装备 detail 资产抽查

结果：WARN/FAIL 混合，主要问题是风格断层，不是破图。

代表性需要重出/复核：

- `armor_shenwu_tian_can_bao_jia_detail.png`：神物感强但高饱和金色游戏图标感，和水墨克制基调断层。
- `weapon_shenwu_kong_que_ling_detail.png`：高饱和蓝金 fantasy/产品渲染感明显。
- `accessory_special_xin_mo_zhu_detail.png`：近 3D 水晶球/产品图观感，非水墨场景。
- `accessory_xunchang_tong_ling_detail.png`：近照片金属铃产品图，和同阶水墨图不统一。
- `armor_xunchang_mian_jia_detail.png`、`armor_haojiahuo_chou_shan_detail.png`：白底服装产品图感强。
- `accessory_haojiahuo_she_dan_wan_detail.png`、`accessory_liqi_jin_chuang_gao_detail.png`：器物清楚但接近商品摄影/渲染，且后者罐身文字明显。
- `weapon_zhongqi_ri_yue_lun_detail.png`：本体辨识弱，更像墨圈符号。

未见问题：

- 详情页 `contain` 显示完整，没有细长兵器被裁切。
- app 内装备详情页未见破图占位或 RenderFlex overflow。

## 未完成 / 限制

- 未能从正常 UI 进入 debug 菜单点 P2；当前背包样本来自已有本地存档。
- 神物未能在 app 详情屏实机打开，只做了资产直检与 contact sheet 抽查。
- 未改代码、未改资产。
