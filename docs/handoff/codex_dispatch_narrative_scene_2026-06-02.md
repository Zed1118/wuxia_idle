# Codex 视觉验收派单 · 剧情阅读屏背景图(narrative_scene)+ pngquant 近无损

**项目**：挂机武侠（`/Users/a10506/Desktop/Projects/挂机武侠`）· Mac 本地 Codex · 非 Pen
**验收对象**：① 30 张专属水墨背景 **pngquant 有损压缩后真机 banding**(本轮新风险,主闸门) ② 背景题材对位 + scrim 深浅 ③ 正文墨底浮层在背景上的可读性
**任务**：截图 + closeout。**不改代码、不改 yaml、不 push、不装包。**

## ⚠️ 关键:当前工作树含未提交改动,直跑勿动 git

主工作树 HEAD `ef43ce3`,但 **`assets/scenes/narrative_stage_*.png` 已就地 pngquant 压缩(50.4MB→15.8MB,未提交)** + **调试路由加了 `VISUAL_STAGE` 参数(未提交)**——**这两项正是本次验收对象**。

**绝对不要 `git checkout` / `git reset` / `git stash` / `git clean`**,否则会擦掉待验的压缩图与路由参数。也**不要 `flutter build` / build_runner**(`.g.dart` 已在主工作树就位,analyze 0 + 1667 测全绿已确认)。

## 启动方式(每个 stage 单独 build · dart-define 是编译期)

路由走 `VISUAL_ROUTE=narrative_scene`,叠加 `VISUAL_STAGE=<stageId>` 抽样不同关卡(未传默认 stage_01_05)。路由已改为**加载该关真实开场正文**,压在对应背景图上,故正文长度/排版与线上一致。

```bash
cd /Users/a10506/Desktop/Projects/挂机武侠
pkill -f wuxia_idle || true          # 每次启动前关旧 app

# 6 张精选(覆盖全调色谱 + 最差 banding 案例 + Ch4暖→Ch5冷转折)
flutter run -d macos --dart-define=VISUAL_ROUTE=narrative_scene --dart-define=VISUAL_STAGE=stage_01_05  # 风雨渡口·雨夜暗调
flutter run -d macos --dart-define=VISUAL_ROUTE=narrative_scene --dart-define=VISUAL_STAGE=stage_02_03  # 铸剑炉·暖炉熔光调
flutter run -d macos --dart-define=VISUAL_ROUTE=narrative_scene --dart-define=VISUAL_STAGE=stage_03_01  # 武林会·繁笔+天空渐变
flutter run -d macos --dart-define=VISUAL_ROUTE=narrative_scene --dart-define=VISUAL_STAGE=stage_04_03  # 沙海迷踪·大片素天渐变(banding 最差案例)
flutter run -d macos --dart-define=VISUAL_ROUTE=narrative_scene --dart-define=VISUAL_STAGE=stage_04_05  # 阳关一决·克制绛红暮色
flutter run -d macos --dart-define=VISUAL_ROUTE=narrative_scene --dart-define=VISUAL_STAGE=stage_05_02  # 嵩山道观·冷调雾色渐变
```

- 就绪信号:日志 `flutter: VISUAL_ROUTE_READY: narrative_scene`(首启 seed ~10-20s)。
- 出现 `VISUAL_ROUTE_ERROR` → FAIL 记现象 + 截当前屏。
- 截完一个在 run 终端按 `q` 退,再跑下一个。窗口尽量最大化,closeout 注明实际尺寸。

## 截图清单(存 `docs/handoff/codex_visual_narrative_scene_2026-06-02/`,PNG 不入库)

| 文件名 | VISUAL_STAGE | 题材 |
|---|---|---|
| `01_stage_01_05.png` | stage_01_05 | 风雨渡口(雨夜暗调) |
| `02_stage_02_03.png` | stage_02_03 | 铸剑炉/兵器铺(暖炉熔光,关名「春水堂」但题材为铸剑炉,系授权选片) |
| `03_stage_03_01.png` | stage_03_01 | 武林会(繁笔+天空渐变) |
| `04_stage_04_03.png` | stage_04_03 | 沙海迷踪(大片素天,banding 最易现) |
| `05_stage_04_05.png` | stage_04_05 | 阳关一决(克制绛红暮色) |
| `06_stage_05_02.png` | stage_05_02 | 嵩山道观(冷调雾色) |

## 验收门(逐条 PASS / WARN / FAIL)

**① pngquant banding(主闸门,逐张看天空/雾色/沙面等大片平滑渐变区)**：
1. **无色阶断层**:天空、雾、沙、水等渐变过渡平滑连续,无明显「一圈一圈」色带(banding)/色块化。
2. **墨色层次保留**:水墨浓淡、晕染层次未因有损压缩变脏/糊/丢细节。
3. **辨识无损**:与「无损应有的观感」相比,辨识度上看不出质损(近无损达标)。

> 这是本轮**唯一不可逆**风险点。任一张出现可见 banding/质损 → 该张记 FAIL/WARN + 框出区域,Mac 端会回退该张到 oxipng 无损版或提高压缩质量再验。

**② 题材对位 + scrim**：
4. **题材吻合**:背景与该关场景吻合(见上表),无张冠李戴(如沙漠关却显山门)。
5. **scrim 深浅**:背景上压了一层暗遮罩(scrim 50%),压暗适度——背景仍可辨,又不抢正文。

**③ 正文浮层可读性**：
6. **浮层可读**:正文区墨底浮层(半透明)压在背景上,文字清晰易读,不被背景纹理干扰;深色背景与浅色背景上都成立(01 暗 / 04 素天浅 对比看)。
7. **观感统一**:背景 + scrim + 浮层 + 题字整体水墨克制,低饱和,无高饱和/卡通/油画跳脱。

**全局**：
8. **布局不破**:无 overflow / RenderFlex;日志 0 Unhandled Exception。

任一 FAIL 记现象 + 截图。**重点主观判断**:pngquant 后**有没有肉眼可见的 banding**(尤其 04 沙海、06 嵩山雾色这两张大渐变),以及浅背景(04)上正文浮层是否仍清晰。

## closeout

写 `docs/handoff/codex_visual_narrative_scene_2026-06-02.md`(≤30 行)：
- 8 验收门逐条 PASS/WARN/FAIL 表 + 6 截图路径 + 实际窗口尺寸
- **逐张点名是否有 banding**(6 张各一句)
- scrim 深浅 / 浮层可读性主观建议
- 是否遇构建/权限/导航/存档异常 + 日志异常
- 一句话总判(达标可 commit / 部分张需回退 / 不达标)

## 边界

- 不改代码 / 不改 yaml / 不 push / 不装新包 / **不动 git(尤其勿 checkout/reset/stash/clean,会擦掉待验改动)**。
- 如必须 build_runner,只能在临时 worktree 内做并在 closeout 说明(正常路径用不到)。
