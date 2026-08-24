# P2 M5 Batch1 心魔修炼度惩罚收口审计

日期：2026-08-24  
任务：`P2-M5-BATCH1-INNER-DEMON-CULTIVATION-CLOSEOUT`  
基线：`a0f3ee5b96a2d125f0df0cb9f44a84910c0d0655`（P2 M2 Batch20 READY）

## 结论

G0 `INNER-DEMON-CULTIVATION-01` 已从设计决议迁移到生产：心魔失败不再扣主修修炼度，仅施加有上限的内息紊乱。退役 `failure_penalty` 的配置、typed 类型/字段、服务参数与 cultivation 写回已删除；任何同名 YAML 键（包括 null/空值）均 fail-closed。普通 Boss 的内力、修炼度/层数和伤势结算与摘要未改。

## 源任务与受控外审

- R01：Pi `0.84.1`，精确模型 `deepseek/deepseek-v4-flash`，thinking `high`，只读工具；source READY `83755eb597bf4f8315f86e2ad9eeac9f0b4ec254`，owned scope 最终 P0/P1/P2=`0/0/0`，11 files `106/106`，10-item analyze 0。
- R02：Qoder CLI `1.1.28`，精确模型 `Qwen3.8-Max`，reasoning `high`，只读工具；source READY `50ae2d5c96b4646a1d70177c8e88c70a47f54bb5`，最终 P0/P1/P2=`0/0/0`，5 files `40/40`，5-item analyze 0。
- 主控逐补丁验证 source tip 与集成生产/测试 blob；R02 计划证据在集成层按真实上下文重写，不拿 whole-patch ID 伪装相同，但 code/test scoped patch identity 相同。

## 集成行为核验

- 生产链：`CombatResolutionService.resolveSnapshot` → `InnerDemonService.applyFailurePenalty` → `InnerBreathDisorder.apply`；结果保留 progress before/after 恒等证据，不再写回 cultivation。
- 不产生惩罚性境界、永久内力、装备属性、物理伤势或主修进度回退；通用装备 `battleCount` 仍正常递增。
- 心魔摘要只显示角色名与“内息紊乱”，不显示未变化的内力区间或修炼度回退；普通 Boss 旧摘要分支保持。
- 独立审查发现真实 P1：角色带既有伤势进入心魔后，旧投影会把既有伤势误报为本次“负伤”。`93258f68` 将心魔 entry 固定为 `injuryApplied=false` 并增加预存伤势到 banner 的回归；`cb4c9179` 同步订正 API 注释。普通 Boss 伤势投影不变。
- 未参与实现的 Codex agent 在两轮修复复核后给出集成代码 P0/P1/P2=`0/0/0`。
- 零 Isar collection/schema、saveVersion 或旧档迁移；不触七心魔 AI、调参、画像、生产 host、durable persistence、G2 或真人试玩 Gate。

## 验证

- 联合定向：13 files，`127/127`。
- 变更范围：15 Dart items，analyze 0。
- 根应用：`flutter analyze --no-pub lib test tool`，0 issue。
- 无参数 `flutter analyze --no-pub`：exit 1，1943 issues，均来自隔离 nested package `tools/phase0minus_probe` 未安装自己的 `flame`/package 依赖；该目录按现有 CI/PROGRESS 契约不属于根应用 analyze 边界，未在本批越界修改。
- 完整 `flutter test --no-pub`：`5156/5156`，0 fail，exit 0（约 6 分 14 秒）。
- Registry：105 tasks/105 unique、49 decisions/49 unique；0 duplicate、0 dangling prerequisite、0 dangling decision reference。
- Repository：变更 15 Dart files `dart format --output=none --set-exit-if-changed` 为 0 changed，`git diff --check` 通过；两个 source worktree 均 clean 且位于登记 READY tip；main/origin main 均未变化。

## UI 与残留风险

- `defeat_loss_banner_residue_test.dart` 在 1280×720、1440×900 两个常规桌面 surface 均无异常/溢出，事实文本与负断言通过。
- 当前基线没有可达的 `defeat_inner_demon_residue` VISUAL_ROUTE，因此没有真机截图目检；这是已记录的视觉残留，不冒充完成。
- 内息紊乱数值与恢复规则沿用既有冻结配置；本批没有授权或实施调参。

## 仓库边界

- 集成分支：`codex/phase2-m5-batch1-inner-demon-cultivation-closeout-20260824`。
- 验证提交：`f78b6b033d4b72054f2ff99a36418cda8545ecff`（代码、测试、设计真相源与验收证据冻结点）。
- `main` 与 `origin/main` 在本批启动和收口检查中均应保持 `e292d3a069fbc0e129dd74fafc1ebb3746f53557`。
- READY 只在完整测试、独立复核、registry/audit 真相源与工作树检查全部闭合后生成。
