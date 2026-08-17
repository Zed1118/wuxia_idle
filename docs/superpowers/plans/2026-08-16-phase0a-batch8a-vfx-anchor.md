# Phase 0A Batch 8A: VFX 位置锚定

**日期**: 2026-08-16  
**基线**: `[READY] 3aa7e8a3`  
**协调分支**: `codex/phase0a-batch8-audit-plan`  
**审计文档**: `docs/audit/phase0a-batch8-vfx-anchor-audit-2026-08-16.md`

## 目标

将四类 CustomPaint VFX（掌风、Q 涡旋、R 墨爆、死亡墨散）从固定屏幕中心改为绑定 actor/world 坐标，并复查伤害数字的位置绑定。

## 冻结范围 (5 项)

| # | 切片 | 说明 |
|---|------|------|
| S1 | 掌风位置绑定 | 出手者→目标的 world 连线映射到屏幕 |
| S2 | Q 涡旋位置绑定 | 绑定玩家脚底 world 坐标 |
| S3 | R 墨爆位置绑定 | 绑定玩家脚底 world 坐标 |
| S4 | 死亡墨散位置绑定 | 事件快照敌人位置，避免尸体丢失 |
| S5 | 伤害数字复查 | 确认已正确绑定，加固多目标同时受击场景 |

## 禁止项

- 不新增或修改 Phase0a 专属 SfxId
- 不接入音频（独立为后续批次）
- 不实现重试入口（独立为后续批次）
- 不实现键盘导航（先测试证伪，独立为后续批次）
- 不新增命中墨花/受击闪光/屏幕震动
- 不修改旧 3v3 战斗
- 不修改 `numbers.yaml`
- 不在 Dart 中硬编码中文文案或数值

## 技术方案

### 核心原则: 事件位置快照

VFX entry 必须携带事件发生时的 `ArenaVector` 位置快照，渲染时使用 `Phase0aStage.worldToScreen()` 映射。不得在渲染时通过 id 反查当前 state（敌人可能已死亡消失）。

### 数据流

```
Phase0aEvent → Phase0aVfxController.consume()
  → Phase0aVfxEntry(携带位置快照: ArenaVector)
  → Phase0aBattleScreen._FeedbackLayer
  → Phase0aStage.worldToScreen(快照) → Offset
  → Positioned + CustomPaint
```

### Phase0aVfxEntry 扩展

新增字段:
```dart
final ArenaVector? anchor;  // VFX 的世界坐标锚点
final ArenaVector? source;  // 掌风: 出手者位置
final ArenaVector? vfxTarget;  // 掌风: 目标位置
```

### 各切片具体改动

**S1 掌风**: `palmTrail` entry 携带 `source`/`vfxTarget` 快照 → `_FeedbackLayer` 计算连线中点 + 角度 → `Positioned` 定位 `CustomPaint`

**S2 Q 涡旋**: `gatherVortex` entry 携带 `anchor`(玩家位置) → `_FeedbackLayer` 映射到屏幕 → `Positioned` 定位

**S3 R 墨爆**: `clearBurst` entry 携带 `anchor`(玩家位置) → 同上

**S4 死亡墨散**: `defeatInk` entry 携带 `anchor`(事件发生时的敌人位置) → 同上

**S5 伤害数字**: 复查 `_damagePopup` 的 `vfxPopupGap` 偏移逻辑，确认多目标同时受击时不重叠

## 验收标准

- 掌风出现在出手者与目标之间连线位置
- Q 涡旋出现在玩家脚底位置，随玩家移动
- R 墨爆以玩家为中心扩散
- 死亡墨散出现在被击败敌人位置（即使敌人已从 state 移除）
- 伤害数字在多个敌人同时受击（R 清场）时仍可读
- 1280×720 / 1440×900 双视口均不裁切
- `flutter analyze --no-pub` 0 issue
- 相关测试全绿
- macOS debug build 成功
- `git diff --check` 通过

## 恢复点

| 恢复点 | 触发条件 | 内容 |
|--------|---------|------|
| RP0 | 计划落地后 | 审计文档 + 计划文档 + 空提交 (`b6e135be`) |
| RP1 | S5 完成后 | 全部 VFX 位置绑定 + 红测通过 (`d709894a`) |
| GATE | 坐标契约测试 + 视觉 Gate | 10 项新增测试 + 文档修复 + build 验证 (`e4ed139e`) |
| GATE-2 | 接管后补强 | 精确屏幕坐标/方向/死亡流程 + 恢复容量测试 (`38826c4b`) |
| GATE-3 | 交叉审查后 | 容量测试确实撞限并精确断言 48/160 (`b503ebf3`) |

## 完成记录

- **RP0**: `b6e135be` — 审计文档 + 计划落地
- **RP1**: `d709894a` — S1-S5 全部完成
  - 8 屏幕红测 + 18 VFX 映射测试全部通过
  - `flutter analyze` 零问题
  - 移除 `_FeedbackLayer._actor()` 死代码
- **GATE**: `e4ed139e` — 坐标契约测试 + 视觉 Gate
  - 新增 6 项 VFX 控制器坐标快照测试 + 4 项屏幕坐标测试
  - 但误删了 3 项容量上限测试(见下个修复提交)
  - 屏幕测试断言过弱(见下个修复提交)
  - 54 测试全过 (21 event_mapping + 33 其他 Phase0A)
  - `flutter analyze lib/ test/` 零问题
  - `git diff --check` 通过
  - macOS debug build 成功 (`build/macos/Build/Products/Debug/wuxia_idle.app`)
- **GATE-2**: `38826c4b` — 修复前述 GATE 证据缺口
  - 恢复 3 项容量契约测试；屏幕断言改为精确比较 `worldToScreen`
  - 新增掌风屏幕方向断言，以及敌人从 state 移除后的死亡墨迹/致死飘字真实流程测试
  - 临时将掌风/Q/R/死亡墨迹恢复为旧版屏幕中心渲染，坐标组 **5/5 全红**；还原锚定实现后 **5/5 全绿**
- **GATE-3**: `b503ebf3` — 收紧容量契约
  - popup 场景从“≤48”改为精确等于 48
  - 混合场景理论产量提升至 218，确认总 entry 精确截断为 160
  - `phase0a_event_mapping_test.dart` **24/24 全绿**

## Qoder 交叉审查

审查范围: `d709894a..38826c4b`

- [x] 坐标快照架构正确性 (`anchor/source/vfxTarget`)
- [x] `worldToScreen`、掌风方向、死亡快照、致死飘字无阻塞问题
- [x] 指出的两项容量测试弱断言已在 `b503ebf3` 修复
- [x] 所报 `dispose()` 监听器问题经 `git blame` 和源码复核为误报：当前实现为 `removeListener`
- [x] `gatherPull` 渲染、掌风并发覆盖和 debug fallback 诊断为本批冻结范围外残余项，不混入 Batch 8A

## 最终验证证据

- 相关根应用回归：**351/351 全绿**
- 根 `flutter analyze --no-pub`：**No issues found**（fresh worktree 先为独立 probe 离线重建 `.dart_tool`，未改源码/依赖）
- probe 隔离契约：`--no-test-assets` **5/5 全绿**
- macOS debug build：成功
- 静态原生窗口：`1280x720`、`1440x900` 均成功，manifest 标记 `dirty: true` 以如实记录当时待提交测试修正
- 真机交互帧：`J` 掌风连线、`Q` 玩家锚定涡旋与 4.8 秒冷却、`R` 玩家锚定墨爆/敌人死亡墨迹/3830 飘字与 7.8 秒冷却均通过
- 视觉证据目录：`build/visual_acceptance/phase0a_batch8a_vfx_anchor/`（build 产物，按仓库规则忽略）
- 两档 capture log：均含 `VISUAL_ROUTE_READY`，无异常/overflow，fidelity incomplete 为空
- `git diff --check`：通过

## 工具分工

- **主协调 (DeepSeek)**: 全部实现 + 红测 + 坐标契约测试 + 视觉 Gate
- **Qoder**: 交叉审查 diff (待执行)
- **Kimi**: 不参与本批
