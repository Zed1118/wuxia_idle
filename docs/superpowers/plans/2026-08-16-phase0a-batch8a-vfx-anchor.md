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
final ArenaVector? target;  // 掌风: 目标位置
```

### 各切片具体改动

**S1 掌风**: `palmTrail` entry 携带 `source`/`target` 快照 → `_FeedbackLayer` 计算连线中点 + 角度 → `Positioned` 定位 `CustomPaint`

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

## 完成记录

- **RP0**: `b6e135be` — 审计文档 + 计划落地
- **RP1**: `d709894a` — S1-S5 全部完成
  - 8 屏幕红测 + 18 VFX 映射测试全部通过
  - `flutter analyze` 零问题
  - 移除 `_FeedbackLayer._actor()` 死代码

## 工具分工

- **主协调 (DeepSeek)**: 全部实现 + 红测 + 验证
- **Qoder**: 交叉审查每个切片 diff
- **Kimi**: 不参与本批（改动量小，适合单工具完成）