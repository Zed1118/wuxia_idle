# Codex 视觉验收派单 · 战斗场景长尾 9 biome 专属背景(battle_scene)

**项目**：挂机武侠（`/Users/a10506/Desktop/Projects/挂机武侠`）· Mac 本地 Codex · 非 Pen
**HEAD**：`f08055b`（已全部 push,工作树仅 build 产物 + 截图未跟踪,可正常 `git pull`）
**验收对象**：9 张长尾 biome 专属战斗背景图(inn/escortRoad/teaHouse/smithy/alley/temple/desert/bambooForest/cliffWaterfall),叠 scrim 40% + 3v3 战斗 UI 后的观感
**任务**：截图 + closeout。**不改代码、不改 yaml、不 push、不装包。**

## 启动方式(每个 biome 单独 build · dart-define 是编译期)

路由 `VISUAL_ROUTE=battle_scene` + `VISUAL_SCENE=<biome>` 抽样(取 `assets/scenes/battle_<biome>.png`,缺图走 errorBuilder 兜底,未传默认 citywall)。scenarioB 左队稳胜,自动推进到金「胜」仪式。

```bash
cd /Users/a10506/Desktop/Projects/挂机武侠
pkill -f wuxia_idle || true          # 每次启动前关旧 app
for s in inn escortroad teahouse smithy alley temple desert bambooforest cliffwaterfall; do
  flutter run -d macos --dart-define=VISUAL_ROUTE=battle_scene --dart-define=VISUAL_SCENE=$s
  # 截图后在 run 终端按 q 退,再下一个
done
```

- 就绪信号:日志 `flutter: VISUAL_ROUTE_READY: battle_scene`(首启 seed ~10-20s)。
- 出现 `VISUAL_ROUTE_ERROR` → FAIL 记现象 + 截当前屏。
- 窗口尽量最大化,closeout 注明实际尺寸。

## ⚠️ 截图时机(关键 · 沿 B2 backlog)

背景验收要截**战斗进行中**(背景 + scrim + 3v3 角色/血条/技能 UI 同屏),**金「胜」仪式 overlay 出现前**。scenarioB 结算较快:
- READY 后**立刻截**(战斗自动播放时背景全屏可见)。
- 若已弹金「胜」全屏 overlay 盖住背景 → **按 q 退,重跑该 biome 再快速截战斗中态**。
- 金「胜」仪式本身非本轮验收对象(B2 已验),只需背景层。

## 截图清单(存 `docs/handoff/codex_visual_battle_scene_2026-06-02/`,PNG 不入库)

| 文件名 | VISUAL_SCENE | 题材 | 重点 |
|---|---|---|---|
| `01_inn.png` | inn | 荒山野店院前 | — |
| `02_escortroad.png` | escortroad | 官道镖路雾山 | — |
| `03_teahouse.png` | teahouse | 江南水畔茶馆 | — |
| `04_smithy.png` | smithy | 铁匠铺炉前 | 炉火暖光是否跳脱克制 |
| `05_alley.png` | alley | 雨夜窄巷 | **暗场叠 scrim 是否过暗到 UI 难辨** |
| `06_temple.png` | temple | 山寺/道观庭院 | — |
| `07_desert.png` | desert | 大漠戈壁(素天渐变) | banding 最易现 |
| `08_bambooforest.png` | bambooforest | 竹海 | **是否偏绿跳脱水墨克制** |
| `09_cliffwaterfall.png` | cliffwaterfall | 险崖飞瀑(雾色渐变) | banding |

## 验收门(逐条 PASS / WARN / FAIL)

**① banding(逐张看渐变区:desert 素天 / cliff 雾 / temple 远山 / escortroad 雾山)**：
1. 渐变过渡平滑,无可见色阶断层/色块化(纹理重的 alley/bamboo/inn banding 风险低,主看大片平滑区)。
2. 墨色层次保留,未因 pngquant 有损变脏/糊/丢细节。

**② scrim 40% + 战斗 UI 叠加(中部留空设计验证 · 主闸门)**：
3. **scrim 适度**:背景压暗后仍可辨题材,又不抢战斗 UI。
4. **UI 可读**:3v3 角色立绘/血条/技能/伤害浮字在中下区清晰,不被背景纹理干扰(**alley 暗场重点看 UI 是否够亮**)。
5. **题材对位**:背景与 biome 吻合(见表),无张冠李戴。

**③ 水墨克制 + 风格统一**：
6. **低饱和克制**:无高饱和/卡通/油画跳脱(**bamboo 重点看是否偏绿,smithy 炉火暖光是否过艳**)。
7. **与现有 7 高频图统一**:观感与 battle_citywall/frontier/mountainforest 等一致(可对比一张高频图)。

## closeout 模板(写 `docs/handoff/codex_visual_battle_scene_2026-06-02.md`)

每 biome 一行 PASS/WARN/FAIL + 逐张 banding 备注 + 截图尺寸 + 构建/导航/异常日志。**任一 biome 不过(过暗/偏绿/banding/张冠李戴)→ 记 FAIL + 框区域**,Mac 端会重选变体或调压缩再验。

回报给 Mac 端:① 9 biome 逐门结论 ② 是否可销账战斗场景出版美术 pass ③ 待返工的 biome + 现象。
