# P1 #1 Mac 端接手 closeout（2026-05-13）

> 上接 `docs/handoff/p1_1_mac_handoff_2026-05-12.md`（DeepSeek 端派单 + Mac 端 spec）。
> 本文档归档**接手过程的实际偏差与非显然发现**，给后续会话与 Pen 端验收用。

---

## 1. 一句话结论

P1 #1 narrative schema Mac 端接手完成，commit `bce5d33` 已推 main，**销账 #27**。
widget test 已直接验证「真实剧情『山门之外 · 启』可加载，不再走 placeholder」——main 上 narrative regression 闭环。

---

## 2. 实际 scope vs handoff scope 对比

| 项 | handoff 计划 | 实际 |
|---|---|---|
| T1 NarrativeLoader 子目录扫描 | 加 stages/ 一档 | 抽 `_scanPaths` 常量列表，顺序契约写入 doc |
| T2 stages.yaml 6 关 id 迁移 | 方案 B（stage_id 一并改名） | 采纳，6 关 + prevStageId 链 + narrative id 全链同步 |
| T2.5 全仓库引用清理（spec 漏列） | spec 仅提 `grep mainline_test_0` | 实际命中 8 文件 67 处，sed 批量重命名 |
| T3 pubspec asset 路径 | 需核对 | pubspec.yaml 已声明 `data/narratives/stages/`，**无须改** |
| T4 防回归 test 4 case | spec 说新建 | 文件**已存在**（7 case），改为扩展 +2 case |
| T5 清 Mac 本地存档 | 需做 | Mac 本地**无开发态存档目录**（从没跑过 desktop），自动跳过 |
| T6 测试基线 | spec 写 493 → 497 | 实际 493 → 495（spec 多算 2 case） |
| T7 commit + 销账 | 单 commit | done，commit `bce5d33` |

---

## 3. 接手过程中的非显然发现

### 3.1 PROGRESS.md 基线数字落后 36 条

PROGRESS.md 一直写「457/457」（Week 3 中段数字），handoff 说「493/493」。
实际跑 `flutter test` 得 **493**——handoff 准确，PROGRESS 数字过时。
原因：Codex 夜班 commit `b3f3613` + 外部审查清账 P1 #2 / P2 #3 都增加了 test，PROGRESS 没同步更新计数。

**规约**：Week 收尾时 PROGRESS 的测试基线数字要主动校准，不要假设。

### 3.2 widget test 中 rootBundle 能读到 pubspec 声明的真实 asset（关键）

T6 全量 test 跑出 1 fail：`stage_list_screen_test`「点 available 关卡 → 走 placeholder」case。

**根因**：runStageFlow 调 `NarrativeLoader.load(stage.narrativeOpeningId!)`，loader 改造后第二档扫 `data/narratives/stages/` 子目录。pubspec.yaml 已声明该路径为 asset，**widget test 环境的 rootBundle（`TestDefaultBinaryMessengerBinding`）实际能读到真实 asset 文件**，所以加载到 DeepSeek 写的「山门之外 · 启」真实文案，不再走 placeholder。

修复：把 test 期望改成验证真实文案加载（而非 placeholder 兜底）。**这反而比原测试更有价值——直接在 widget 层验证 #27 真正闭环**。placeholder 兜底路径在 narrative_loader_test 单测里已被覆盖。

**经验**：
- widget test 不接 Isar，但**接 pubspec 声明的真实 yaml asset**——这意味着任何依赖 `data/*.yaml` 内容的 widget 行为，在 widget test 里都是真实加载。
- 之前 T36 实现时这个 case 能通过是「巧合」——loader 只扫扁平根，根目录确实没文件 → 走 placeholder。schema 拆分到子目录后，巧合消失。

### 3.3 sed 残留 false positive

批量替换后 grep 检查发现两处「mainline_test」未被替换：
1. `mainline_progress_service_test.dart:28` 的 `createTemp('wuxia_mainline_test_')` —— 临时目录 prefix，与 stage id 无关，**正确保留**
2. `data/stages.yaml:26` 的迁移注释 —— 我自己加的变更记录，**正确保留**

**规约**：sed 批量替换后必须 grep 残留 + 人工辨别 false positive，不能依赖「grep clean」作为完成标志。

### 3.4 Mac 不跑 desktop，存档清盘只 Pen 端做

handoff §T5 要求清 `~/Library/Application Support/com.example.wuxia_idle/`，但 Mac 本地从没跑过 desktop（PROGRESS 挂账 #9/#11 已记录「Mac 无 Xcode 跑不了 desktop」），目录不存在。
**Pen Windows 端**才需要在拉新 main 后清开发态存档（脚本已写进 `bce5d33` commit message）。

---

## 4. 测试基线 deltas

| 阶段 | analyze | test |
|---|---|---|
| 开工前（main，merge d37d09d） | 0 issues | 493/493 |
| T1 改 NarrativeLoader | 0 issues | (未跑) |
| T2 改 stages.yaml | 0 issues | (未跑) |
| T2.5 sed 全仓库重命名 | (未跑) | (未跑) |
| T6 第一次全量 | 0 issues | 494/495（1 fail）|
| T6 修 stage_list_screen_test | 0 issues | 495/495 ✓ |

---

## 5. 给 Pen 端的物理验收建议（下次跑 Windows 时）

1. **拉新 main**：
   ```powershell
   cd F:\Projects\wuxia_idle
   git pull origin main
   ```
2. **清开发态存档**（否则旧 MainlineProgress.clearedStageIds 指向 `mainline_test_*` 旧 id，所有关卡显示为「未通关」；不会 fail-fast 但视觉混乱）：
   ```powershell
   rmdir /s /q "%APPDATA%\com.example.wuxia_idle"
   ```
   或直接进 `%APPDATA%` 删 `wuxia_idle` 目录。
3. **`flutter build windows --release` + 跑游戏**
4. **物理验收**（新增项，仅本次需补）：
   - 主菜单 → 主线 → Ch1 → stage_01_01：opening 显示「山门已经看不见了。路两侧是半人高的野蒿，露水还没干。」（**非 `[剧情待补]`**）
   - 战斗胜利后 victory 显示「蒿草深处窜出一只灰兔……」
   - 抽样跑 stage_02_01 / stage_03_01，确认章首关 opening 都是 DeepSeek 真实文案
5. 若发现任何剧情段落仍显示 `[剧情待补]`：截图 + stage_id 反馈给 Mac 端

---

## 6. 关联

- **handoff**：`docs/handoff/p1_1_mac_handoff_2026-05-12.md`（DeepSeek 派单 + Mac 接手 spec）
- **commit**：`bce5d33`（main）
- **挂账状态**：销 #27 / 新增 #29（defeat hook + 9 关扩容留 Phase 4 W1）
- **基线**：495/495 测试，analyze 0 issues，10 文件 +178/-113

---

## 7. 下一步候选（待人类决策）

Phase 3 Week 4 起手：C 奇遇 / D 师徒 / E 武学领悟。需先决 CLAUDE.md §12 待人类决策项（机缘值累积 / 师承遗物细则 / 祖师爷 buff）。详草案见 `phase3_tasks.md` 末尾。

新会话开局直接读 PROGRESS.md「当前阶段」段即可。
