# Codex 视觉验收 closeout · 战斗场景长尾 9 biome

日期：2026-06-02  
项目：挂机武侠（Mac 本地）  
HEAD：`1166443`  
窗口尺寸：逻辑 `1440x811`，截图 `2880x1622` Retina PNG  
截图目录：`docs/handoff/codex_visual_battle_scene_2026-06-02/`

## 执行记录

- 已执行 `git pull --ff-only`：Already up to date，HEAD 确认为 `1166443`。
- 逐 biome 执行 `flutter run -d macos --dart-define=VISUAL_ROUTE=battle_scene --dart-define=VISUAL_SCENE=<biome>`。
- 首次人工等 READY 截 `inn` 时已进入金「胜」overlay，已重跑并改用 expect 监听 `VISUAL_ROUTE_READY: battle_scene` 后立即截图，最终 9 张均为战斗进行中态。
- 未见 `VISUAL_ROUTE_ERROR`。每轮日志均出现 macOS `Failed to foreground app; open returned 1`，但后续通过 `osascript` 前置窗口成功，截图不受影响。
- 未改代码、未改 YAML、未 push、未装包。

## 逐 biome 验收

验收门：①渐变无 banding；②细节未脏糊；③scrim 适度；④UI 可读；⑤题材对位；⑥低饱和克制；⑦与高频图统一。

| biome | 截图 | ① | ② | ③ | ④ | ⑤ | ⑥ | ⑦ | 结论 | 备注 |
|---|---|---|---|---|---|---|---|---|---|---|
| inn | `01_inn.png` | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | 荒山野店题材明确，左右角色和血条清晰。 |
| escortroad | `02_escortroad.png` | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | 雾山/官道层次平滑，队列人物不干扰 UI。 |
| teahouse | `03_teahouse.png` | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | 水畔茶馆题材清楚，右侧浅水面未冲淡角色文字。 |
| smithy | `04_smithy.png` | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | 铁匠铺/砧台/棚架可辨，未见炉火暖光过艳。 |
| alley | `05_alley.png` | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | 暗场右墙很黑，但头像、姓名、血条和按钮仍可读，未过暗到难辨。 |
| temple | `06_temple.png` | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | 山寺庭院题材准确，远山/树影无明显色阶。 |
| desert | `07_desert.png` | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | 素天和远山渐变平滑，低饱和沙色未跳脱。 |
| bambooforest | `08_bambooforest.png` | PASS | PASS | PASS | PASS | PASS | PASS | PASS | PASS | 竹海整体偏灰青，不是高饱和绿色；UI 清晰。 |
| cliffwaterfall | `09_cliffwaterfall.png` | PASS | PASS | PASS | PASS | PASS | PASS | WARN | WARN | 无 banding，UI 清晰；但瀑布近景笔触比 citywall/frontier 等高频图更厚、更数字厚涂，风格统一性边缘。 |

## 结论

- 硬性 FAIL：无。
- 可销账战斗场景出版美术 pass：可以，建议带 `cliffwaterfall` 风格 WARN 记录销账。
- 待返工项：无必须返工项。可选优化：`cliffwaterfall` 若美术口径要求严格统一水墨，可换更留白、更纸本水墨的远景飞瀑变体。
