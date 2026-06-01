# Codex 视觉验收派单 · 战斗屏出版美术 B2(大招题字 + Boss 头像金边)

**项目**：挂机武侠（`/Users/a10506/Desktop/Projects/挂机武侠`）· Mac 本地 Codex · 非 Pen
**验收对象**：① 大招题字 overlay（玩家暖金 / 敌方绛红）② Boss 头像金色加粗边框 ③ B1 回归（scrim + 胜负仪式）
**任务**：截图 + closeout。**不改代码、不改 yaml、不 push、不装包。**

## 启动方式（主工作树直跑，勿 checkout / 勿 worktree）

主工作树 HEAD `9a497da` **已含 B2**，`lib/` 干净（仅 docs/macos 未跟踪残留，不影响）。
B2 的 `VISUAL_ROUTE` 走编译期 `dart-define`，**一个 build 只对应一个 route**，故 3 路由各启动一次：

```bash
cd /Users/a10506/Desktop/Projects/挂机武侠
pkill -f wuxia_idle || true          # 每次启动前关旧 app

# 路由 1（静态题字，READY 即可截）
flutter run -d macos --dart-define=VISUAL_ROUTE=battle_ultimate_caption
# 路由 2（自动播放战斗，Boss 在右队首位）
flutter run -d macos --dart-define=VISUAL_ROUTE=battle_boss_frame
# 路由 3（B1 回归，自动播放到胜负仪式）
flutter run -d macos --dart-define=VISUAL_ROUTE=battle_scene
```

- 就绪信号：日志出现 `flutter: VISUAL_ROUTE_READY: <route_id>`（首启 seed ~10-20s）。
- 出现 `VISUAL_ROUTE_ERROR` → 直接 FAIL 记现象 + 截当前屏。
- 截完一个 route 在 run 终端按 `q` 退出，再跑下一个。**不要 checkout、不要 `flutter build`、不要 build_runner**（`.g.dart` 已在主工作树就位）。

## 截图清单（存 `docs/handoff/codex_visual_battle_b2_2026-06-01/`，PNG 不入库）

| 文件名 | 路由 | 时机 |
|---|---|---|
| `01_ultimate_caption.png` | battle_ultimate_caption | READY 后立即截（题字两态静态，无需等待/点击） |
| `02_boss_frame.png` | battle_boss_frame | READY 后立即截（Boss 满血在场，金边最清晰） |
| `03_battle_scene_regression.png` | battle_scene | 战斗进行中截（背景 + scrim + 战斗 UI 同屏，验 B1 未被 B2 破坏） |

窗口尽量最大化；1280×720 与全屏任一即可，closeout 注明实际尺寸。

## 验收门（逐条 PASS / WARN / FAIL）

**路由 1 · 大招题字**（`01_ultimate_caption.png`）：
1. **题字呈现**：上方「天问归一」、下方「血煞噬魂」两段招式名以水墨/题字风显示，字大醒目。
2. **暖/冷区分**：上方玩家题字偏**暖金**、下方敌方题字偏**绛红**，两态色彩对比清晰可辨。
3. **水墨克制**：题字低饱和墨调，醒目但不刺眼；无高饱和/卡通/油画感。

**路由 2 · Boss 金边**（`02_boss_frame.png`）：
4. **金边到位**：右队**首位**敌人头像有金色加粗边框（约 6px），其余角色头像无此边框。
5. **辨识度**：Boss 金边与普通角色头像区分明显，一眼能认出哪个是 Boss。
6. **不冲突**：金边与角色流派色 / 血条 / 内力条不打架、不喧宾夺主；战斗 UI 正常可读。

**路由 3 · B1 回归**（`03_battle_scene_regression.png`）：
7. **背景 + scrim**：底层水墨城墙背景铺满 + scrim 压暗，战斗 UI（顶栏/日志/头像/血条/大招按钮）清晰可读，B2 改动**未破坏** B1 观感。

**全局**：
8. **布局不破**：无 overflow / RenderFlex；日志 0 Unhandled Exception（尤其无 `_pickSkill` / `Bad state`）。

任一 FAIL 记现象 + 截图。**重点主观判断**：题字暖/冷区分是否够明显、Boss 金边辨识度是否足够（如偏弱可建议加粗到 8px 或调更亮的金）。

## closeout

写 `docs/handoff/codex_visual_battle_b2_2026-06-01.md`（≤30 行）：
- 8 验收门逐条 PASS/WARN/FAIL 表 + 3 截图路径 + 实际窗口尺寸
- 题字暖冷 / Boss 金边主观精修建议
- 是否遇构建/权限/导航/存档异常 + 日志异常
- 一句话总判（达标 / 基本达标 / 不达标）

## 边界

- 不改代码 / 不改 yaml / 不 push / 不装新包。
- 如必须 build_runner，只能在临时 worktree 内做并在 closeout 说明（正常路径用不到）。
