# P1 #1 Mac 端接手 handoff（2026-05-12）

会话边界文档：上游 Pen + DeepSeek 端已交付，下游 Mac 端接手未动。
当前会话 Opus 用量风险高，本文档目标是让**新会话开局即上下文齐备**。

---

## 0. 一句话摘要

DeepSeek 端 P1 #1 narrative schema 对齐已完成（commit 32ae3f3 已 push 到
`origin/feat/phase3-seclusion`）。Mac 端需做 **最小修复 scope**：让
NarrativeLoader 能找到 DeepSeek 拆好的 36 个文件，stages.yaml 现 6 关引用
对应 6 个 _opening + 6 个 _victory，跑通主线剧情。defeat hook 与 9 关扩容
**不在本次 scope**，留 Phase 4 W1。

---

## 1. 当前分支状态

- 分支：`feat/phase3-seclusion`，HEAD = `32ae3f3`
- 已 push 到 origin，Mac 本地已 pull 同步
- 最近 5 commits：
  ```
  32ae3f3 docs(narrative): stages 拆分 _opening/_victory + paragraphs[] schema 对齐  ← DeepSeek 端，含 36 + IDS_REGISTRY 改动
  b7e95f8 docs: 留档 P1 #1 DeepSeek 派单 + T52 闭关视觉验收 spec
  3431ac4 docs: PROGRESS 清外部审查（#21 归档 + 新挂账 #26/#27/#28）
  a7960d7 fix: 闭关导航链多余 pop 误弹 result 屏（清外部审查 P2 #3）
  b23a1d6 fix: 统一磨剑石/心血结晶 defId 为 item_* 体系（清外部审查 P1 #2）
  ```

## 2. 上游 DeepSeek 端已交付（已 review 通过）

- `data/narratives/stages/` 下 36 个新文件：
  - 15 个 `stage_NN_NN_opening.yaml`（每关都有）
  - 15 个 `stage_NN_NN_victory.yaml`（每关都有）
  - 6 个 `stage_NN_NN_defeat.yaml`（仅 01_04 / 01_05 / 02_04 / 02_05 / 03_04 / 03_05 章末关）
- 旧 15 个 `stage_NN_NN.yaml` 已删
- schema 全部统一 `{id, title, paragraphs[]}`
- title 后缀：`· 启 / · 终 / · 败` 三档
- `IDS_REGISTRY.md` 同步 36 条新 id，总数 143 → 259 = 238 旧实际 - 15 删 + 36 新
- 抽样验证：`stage_01_01_opening.yaml` 与 `stage_01_04_defeat.yaml` schema 均正确

## 3. 现状 mismatch（Mac 端要填的坑）

### 3.1 NarrativeLoader 路径（`lib/data/narrative_loader.dart:68`）

```dart
'data/narratives/$narrativeId.yaml'  // 扁平路径
```

只会找根目录扁平 yaml，**不进 stages/ 子目录**。DeepSeek 文案在 `stages/` 子目录里，
loader 找不到永远走 placeholder。

### 3.2 stages.yaml 现 6 关 narrative id 与 DeepSeek 命名不对齐

`data/stages.yaml` 当前 6 关：

| stage id | chapterIndex | requiredRealm | narrativeOpeningId（现） | narrativeVictoryId（现） |
|---|---|---|---|---|
| mainline_test_01 | 1 | xueTu | mainline_test_01_opening | mainline_test_01_victory |
| mainline_test_02 | 1 | xueTu | mainline_test_02_opening | mainline_test_02_victory |
| mainline_test_03 | 2 | sanLiu | mainline_test_03_opening | mainline_test_03_victory |
| mainline_test_04 | 2 | sanLiu | mainline_test_04_opening | mainline_test_04_victory |
| mainline_test_05 | 3 | erLiu | mainline_test_05_opening | mainline_test_05_victory |
| mainline_test_06 | 3 | erLiu | mainline_test_06_opening | mainline_test_06_victory |

DeepSeek 给的是 `stage_NN_NN_opening` / `_victory` 体系（共 15 关）。

**最小修复映射建议**（从 DeepSeek 15 关里挑 6 关复用，章节 + 境界匹配）：

| stage.yaml id | 复用 narrative | 章节适配 |
|---|---|---|
| mainline_test_01 | stage_01_01_opening / stage_01_01_victory | 章 1 起手 |
| mainline_test_02 | stage_01_02_opening / stage_01_02_victory | 章 1 |
| mainline_test_03 | stage_02_01_opening / stage_02_01_victory | 章 2 起手 |
| mainline_test_04 | stage_02_02_opening / stage_02_02_victory | 章 2 |
| mainline_test_05 | stage_03_01_opening / stage_03_01_victory | 章 3 起手 |
| mainline_test_06 | stage_03_02_opening / stage_03_02_victory | 章 3 |

（也可以把 stage.yaml 的 id 改名为 `stage_NN_NN` 让 stage_id 与 narrative_id 命名统一，
但 stage_id 改动会让 MainlineProgress 旧数据失效，需要清存档。开发态可接受。）

### 3.3 stage_id 改名 vs 不改名的取舍

- **A. 只改 narrative id 引用**（stage_id 保 mainline_test_*）：
  - 优点：MainlineProgress 旧数据不失效
  - 缺点：stage_id 与 narrative_id 命名分叉，未来扩容时混乱
- **B. stage_id 也改 stage_NN_NN**（如 mainline_test_01 → stage_01_01）：
  - 优点：命名统一，与 DeepSeek 体系对齐
  - 缺点：开发态需清存档（rm wuxia_save_slot1.isar）

**推荐 B**（统一命名，Phase 4 扩容时只需续 stage_01_03..stage_03_05，不必再迁一次）。
Demo 阶段开发态清存档可接受。

## 4. 本次接手任务清单（最小修复 scope）

### T1. NarrativeLoader 子目录扫描

`lib/data/narrative_loader.dart` 改造：

```dart
// 优先扁平路径，缺失 → 尝试 stages/ 子目录，再缺失 → placeholder
static Future<NarrativeContent> load(String narrativeId, {...}) async {
  for (final path in [
    'data/narratives/$narrativeId.yaml',
    'data/narratives/stages/$narrativeId.yaml',
  ]) {
    try {
      final raw = await (loader ?? rootBundle.loadString)(path);
      return NarrativeContent.fromYaml(parseYamlMap(raw));
    } catch (_) { /* try next */ }
  }
  return NarrativeContent.placeholder(narrativeId);
}
```

不动 `chapters/` `techniques/` `codex/` 子目录扫描（代码侧暂未引用，Phase 4 再加）。

### T2. stages.yaml 改 6 关 narrative id（采纳方案 B）

逐关：

- `id: mainline_test_01` → `id: stage_01_01`，narrativeOpeningId: `stage_01_01_opening`，narrativeVictoryId: `stage_01_01_victory`
- mainline_test_02 → stage_01_02
- mainline_test_03 → stage_02_01
- mainline_test_04 → stage_02_02
- mainline_test_05 → stage_03_01
- mainline_test_06 → stage_03_02
- `prevStageId` 链对应同步：stage_01_02.prevStageId = stage_01_01 / stage_02_02.prevStageId = stage_02_01 / stage_03_02.prevStageId = stage_03_01；stage_02_01 / stage_03_01 为章首关，prevStageId = null

注意：stages.yaml 的 6 关都用 enemyTeam fixture（学徒/三流/二流梯度），数值不动，**只改 id 字段**。

### T3. main.dart pubspec.yaml asset 扫描

确认 `pubspec.yaml` 的 assets 区块覆盖 `data/narratives/stages/`（一般声明 `data/narratives/` 目录就够 Flutter rootBundle 递归读取，但要验）。

### T4. 防回归 test

`test/data/narrative_loader_test.dart`（如不存在则新建）：

- case 1: 扁平路径 `data/narratives/foo.yaml` 存在 → 加载成功
- case 2: 子目录路径 `data/narratives/stages/stage_01_01_opening.yaml` 存在 → 加载成功
- case 3: 两层都缺失 → placeholder 兜底，`isPlaceholder == true`
- case 4: paragraphs[] 解析正确（非 placeholder 的 `paragraphs.length >= 1`）

用 mock loader 注入 `Future<String> Function(String)`，不接 rootBundle 也不接 Isar。

### T5. 清开发态 Isar 存档（Mac 本地 + 文档提示 Pen 同步）

```bash
rm -rf ~/Library/Application\ Support/com.example.wuxia_idle/wuxia_save_slot1.isar*
```

Pen 端 Windows 跑：

```powershell
rmdir /s /q "$env:APPDATA\wuxia_idle"
```

旧 MainlineProgress 行 stage_id 是 `mainline_test_*`，stage_id 改名后这些行
对不上新 stage_id，UI 会显示「未通关」。开发态可接受。

### T6. flutter analyze + flutter test 全绿

基线 493/493。预期：
- T4 新增 4 条 narrative loader test → 497/497
- 现有 stage_battle_setup_test 引用 `mainline_test_01` 需要改 stage id 为 `stage_01_01`（grep 一下，看有几处）

### T7. PROGRESS.md 更新

- 销账 #27（narrative schema 已 全套对齐）
- 当前阶段段记录 P1 #1 Mac 端接手完成
- T52 视觉验收清单加一条「主线 stage_01_01 → stage_03_02 进战斗剧情正常加载（非 placeholder）」

### T8. 升档建议

任务跨 5+ 文件 + schema 改动 + 数据迁移 + 防回归 test，按 CLAUDE.md
「复杂任务开工前一次性提示用户升 xhigh」。新会话开局执行这条建议。

---

## 5. 不要做的事（scope 边界）

- ❌ 不动 narrativeDefeatId 字段（stage_entry_flow.dart:24 已注 Phase 4 再加）
- ❌ 不扩容 stages.yaml 到 15 关（Phase 4 W1 + 主线引导 UI 一起做）
- ❌ 不动 chapters / techniques narrative loader（代码侧暂未引用）
- ❌ 不动 IDS_REGISTRY.md（DeepSeek 领地，已同步过）
- ❌ 不重写 stage 6 关的 enemyTeam fixture（数值不动）
- ❌ 不动 stages.yaml schema（StageDef 字段不加不减）

---

## 6. 关联挂账

- **#27 narrative schema 接口未对齐**：本次接手完成后销账
- **#26 闭关入口硬编码 character/realm**：与本次 scope 无关，Phase 4 fixture 一并处理
- **#25 Phase2SeedService.seedP1 缺主修**：本次 scope 不动；T52 验收 + P1 #1 验收都需要先跑 P3 种子才能进战斗
- **#23 widget test 不接真 Isar**：本次 T4 narrative loader test 用 mock loader 注入，绕开

---

## 7. 完成后的下一波动作

1. commit + push（分支保留 `feat/phase3-seclusion`）
2. T52 视觉验收（Pen 物理机，按 `docs/handoff/t52_visual_check_spec_2026-05-12.md`）：
   - **新加一条验收**：进 mainline_test_01（改名后 stage_01_01）战斗，opening 剧情显示「山门已经看不见了……」（非 placeholder）；victory 后剧情显示「蒿草深处窜出一只灰兔……」
3. T52 通过后 merge `feat/phase3-seclusion` → main → tag `v0.3.0-w3`
4. 起 Phase 4 W1 spec（含 9 关扩容 + defeat hook + 主线引导 UI）

---

## 8. 文件位置速查表

| 用途 | 路径 |
|---|---|
| Loader 改造目标 | `lib/data/narrative_loader.dart` |
| stages.yaml | `data/stages.yaml` |
| StageDef | `lib/data/defs/stage_def.dart` |
| Mainline progress 服务 | `lib/services/mainline_progress_service.dart` |
| 主线战斗流程入口 | `lib/ui/mainline/stage_entry_flow.dart` |
| Narrative reader UI | `lib/ui/narrative/narrative_reader_screen.dart` |
| 旧 stage 引用搜 | `grep -rn "mainline_test_0" lib/ test/ data/` |
| DeepSeek 36 文件 | `data/narratives/stages/` |
| pubspec assets | `pubspec.yaml` |
| Test 基础设施 | `test/data/` 下已有同 mock loader 模式 |

---

## 9. 验收命令清单（接手 Claude 开工前/收尾跑）

```bash
# 开局基线
cd ~/Desktop/挂机武侠
git log --oneline -3       # 顶部应 32ae3f3
git status                  # working tree clean
flutter analyze             # 期望 0 issues
flutter test                # 期望 493 pass

# T4 改完跑
flutter test test/data/narrative_loader_test.dart  # 新增 4 test
flutter test                                       # 期望 497 pass

# 完成收尾
git add -A
git commit -m "fix(narrative): NarrativeLoader 加 stages/ 子目录扫描 + stages.yaml 6 关 id 迁移对齐 DeepSeek（清挂账 #27）"
git push origin feat/phase3-seclusion
```
