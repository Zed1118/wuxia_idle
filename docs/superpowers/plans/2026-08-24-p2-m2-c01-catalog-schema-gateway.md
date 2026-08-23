# P2-M2-C01：Catalog schema / gateway 补全

## 目标

在 G0 READY `44e42497` 与既有 S01/L01/O02 合同上，补齐 M2 黑风岭内容包所需、但当前 public catalog 尚不能表达的纯数据边界：显式多目标组合、spawn 入口/位置/行为引用，以及 archetype role 的攻击集合、攻击标签、姿态、掉落、音效和外观引用。

本切片只交付 caller-provided typed schema、纯 loader/validator、纯 objective mapper gateway、fixture 与测试；不读取或创建 production `data/combat/**`，不接 `GameRepository`、production host、UI、save、奖励或调优默认。

## 分支与文件边界

- 分支：`codex/phase2-m2-c01-catalog-schema-gateway-20260824`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-m2-c01-schema`
- 基线：G0 READY `44e42497b9e4968e6baa64ed10ad940034664220`
- 允许：`lib/data/defs/combat_*`、`lib/data/combat_encounter_catalog_loader.dart`、`lib/data/validation/combat_encounter_catalog_validator.dart`、`lib/data/validation/combat_objective_primitive_mapper.dart`、对应 `test/data/**`、`test/fixtures/phase2/combat/**` 与本计划。
- 禁止：task/decision registry、`GDD.md`、`CLAUDE.md`、`PROGRESS.md`、production YAML、host routing、UI、save、奖励与调优值。

## 证据与安全语义

- 二阶段方案 §14 明确八原语用于“组合”，并明确：破路为清敌后到出口（all）；据点可全毁锚点或斩首（any）；斩将须头目与必要随从（all）。因此只冻结扁平 `all | any`；不猜嵌套优先级、失败组合、阶段切换或残敌处置。
- 每个 objective clause 有 caller 显式稳定 ID；组合规则、clause 列表和 primitive 参数均无默认。至少一个 clause，clause ID 唯一。
- spawn 的 `entranceId / positionId / behaviorId` 与 role 的 `attackSetId / attackTagIds / postureProfileId / dropGroupId / sfxGroupId / visualVariantIds` 都是必填 caller 引用。
- caller 必须提供 `CombatCatalogReferenceIndex`；typed manifest 与带 source-path 的 loader preflight 都拒绝未知引用。索引自身只接受唯一、非空、无空白 ID，不携带内容或数值。
- 视觉变体只要求非空唯一引用，不在 schema 强制“两种”；方案已声明约 48 变体是内容目标、非阻塞核心系统硬红线。
- objective mapper 只把 clause 逐一映射为新 O01 primitive，并原样保留显式 `all/any` 与 clause ID；不实现 encounter flow、终局或奖励语义。

## 验收 checklist（CLAUDE §8.2）

- [x] typed def 防御性复制、集合不可变、空/重复/未知引用 fail closed。
- [x] YAML exact-key validator 覆盖新增必填字段、enum、列表、重复与叶子路径。
- [x] loader 保留 source + leaf diagnostics，并由显式 reference index 关闭悬空引用。
- [x] fixture 至少有一个 `all` 多目标和一个 `any` 多目标；八原语仍全部覆盖。
- [x] objective composition mapper 保留 rule/clause ID、每次生成独立 objective owner、显式正 tick 与溢出保护不退化。
- [x] 生产接线证据：本切片按授权只交付公共 gateway，明确不切 production host；M2 内容/host 后续任务消费该合同。
- [x] targeted tests 给出命令与通过数；scoped analyze 0 issue；format 与 `git diff --check` 通过。
- [x] 红线：0 production 数值、0 Dart 中文玩家文案、0 三系/伤害/在线离线/反主流触点。
- [x] 残留风险：未实现 nested objective、失败组合、阶段/残敌 flow；这些不是本切片可推断语义。
- [x] 常规实现 commit 后树干净；tip 为 `[READY][CODEX][P2-M2-C01]` 空提交。

## 任务切片

1. 完整读取操作/设计/G0/M2 证据，盘点 S01/L01/O02 当前缺口。
2. 先补 typed、validator、loader、mapper 的失败测试与组合 fixture，确认当前合同红测。
3. 最小扩展 defs、loader、validator 与 mapper，不触及 production route。
4. 运行 targeted、scoped analyze、format、diff 与路径边界审计；复核失败诊断。
5. 更新恢复点，提交实现并追加 READY 空提交。

## 当前恢复点

- 状态：Batch10 终审 P1 返修实现、验证与普通 fix commit 完成，待主控独立验收；按主控要求不追加 Batch10 READY。返修分支 `codex/phase2-m2-c01-objective-reference-fix-20260824`，基线 `3ba090c6a076a67a06f9b11601b2d6341bcf3add`。
- P1 事实：旧 `CombatCatalogReferenceIndex` 没有 objective 权威 namespace，`CombatCatalogManifestDef` 与 loader preflight 都未校验 7 个含 ID primitive，因此“关闭每个 cross-reference”的原声明不成立。
- 红证据：fresh worktree 先出现 Flutter native-assets `Bad state: No element`；执行 `flutter pub get --offline` 后，`combat_catalog_schema_gateway_test.dart` 按预期在编译期因 `objectiveTargetIds` 构造参数/getter 不存在而失败，证明测试先于实现。
- 最后完成：增加 caller-required `objectiveTargetIds / objectiveAnchorIds / objectiveEntityIds / objectiveCheckpointIds / objectiveMarkerIds`；typed manifest 穷尽遍历每个 clause 的 7 个含 ID primitive；loader 在 typed 构建前逐 leaf 校验，list 路径带索引。`defeatTargets / pursueTarget / defeatCommander` 共用 target namespace，未与 spawn entry 派生绑定。
- 下一步：交主控独立验收；本分支不打 Batch10 READY。
- 已跑验证：C01 8 份 targeted test 逐文件执行，共 140/140 通过；因本基线未集成 R03 controller 文件，另在已冻结 R03 worktree 逐文件复跑 objective domain/controller/mapper 3 份共 29/29。`flutter analyze --no-pub` 覆盖本分支 16 个相关 Dart 文件，0 issue；`dart format --output=none --set-exit-if-changed` 7 个变更 Dart 文件 0 changed；`git diff --check` 通过。
- 生产接线：本切片依授权不接 `GameRepository`、production IO/YAML 或 host routing；交付的是后续 M2 内容与 host 任务的公共 gateway，不冒充 production 已上线。
- 红线影响：未改生产 data、奖励、伤势、save、UI、数值公式或调优值；所有数值和引用均由 caller 显式提供，无 Dart 中文玩家文案。
- 残留风险：future host 必须从权威内容源组装新增的五个 namespace；nested objective、失败组合、阶段切换与残敌 flow 未冻结且未实现。无当前切片阻塞。
