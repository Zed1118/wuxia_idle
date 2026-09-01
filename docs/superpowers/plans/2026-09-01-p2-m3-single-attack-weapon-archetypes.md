# M3 五类单段普攻合同实施计划

## 结果合同

- 单一目标：让五类武器身份从真实装备 YAML 进入玩家战斗快照与生产普攻装配，同时保持基础普攻为单段、可持续按住、无攻击位移。
- 实时基线：`9b05f44a97d3a7d31a645e62d0be9615fdb122dd`；M3 为 `0/5` 武器画像、`0/15` 清杂/精英/Boss 场景。
- 固定分母：剑、重兵、软兵、双持、暗器共 5 类；每类后续分别通过清杂、精英、Boss 三场，共 15 格。
- 本单可关闭的结构门：37 件生产武器全部有显式类别；类别贯通 `EquipmentDef -> CombatantSnapshot -> Phase0aPlayerInputAdapter`；无武器保持现有掌风基线；生产装配继续不注入三段链和攻击位移。
- 候选边界：可以生成五类单段画像候选及 15 格模拟证据，但未获用户选择前不把候选范围、角度、节奏或表现值写入生产配置。
- 正式里程碑边界：候选绿色不等于 M3 通过；生产值选定、真实生产消费、集成 Gate 和真人目检仍分别闭环。

## 授权与禁止项

- 已授权：扩展非持久化 `EquipmentDef` 和 `data/equipment.yaml` 武器类别；扩展非持久化战斗快照/运行时装配字段；建立五类单段画像候选。
- 不改：Isar、`schemaVersion`、`saveVersion`、装备基础属性、玩家属性、技能、奖励、经济、解锁和战斗结算数值。
- 不恢复：三段普攻链、进步斩、攻击位移、shield/parry 或 `Z` 防御入口。
- 不把 parked `WeaponType`、fixture、模拟或历史 READY 当作生产画像完成。

## 工作区与所有权

- 分支：`codex/p2-m3-single-attack-weapon-archetypes-20260901`
- worktree：`/Users/a10506/.codex/worktrees/p2-m3-single-attack-weapon-archetypes-20260901`
- 主要 owned files：
  - `lib/core/domain/enums.dart`
  - `lib/data/defs/equipment_def.dart`
  - `data/equipment.yaml`
  - `lib/shared/battle_shared/combatant_snapshot.dart`
  - `lib/shared/battle_shared/player_combatant_snapshot_builder.dart`
  - `lib/features/battle/application/phase0a/phase0a_player_input_adapter.dart`
  - `lib/features/battle/application/phase0a/phase0a_stage_content_mapper.dart`
  - 对应 targeted tests、M3 候选测试/说明与 task registry

## 实施与验收顺序

1. 先写会红的 YAML schema、全量分类、快照来源与生产 mapper 合同测试。
2. 新增唯一核心枚举 `WeaponArchetype`；`EquipmentDef.fromYaml` 对 weapon 缺类别、非 weapon 带类别均 fail closed。
3. 为 37 件生产武器写显式类别；运行时不按名称、ID、流派或装备数值推断。
4. 玩家快照从实际装备 def 派生类别；无武器为 `null`，多武器或 def/slot 不一致 fail closed；复制与心魔镜像保持字段。
5. 生产 mapper 把类别送进 `Phase0aPlayerInputAdapter`，但攻击范围、角度、冷却、倍率及 `basicAttackChain == null` 保持现状。
6. 建立五类单段画像候选与 `5 x 3` 模拟矩阵，只输出候选差异、红线和待选择项。
7. 对 schema 守卫、快照来源、生产 mapper 和候选红线分别做精确破坏证红并还原。
8. 执行 targeted、`flutter analyze`、整仓 `dart format .`、锁保护全量测试和 exact-tip Gate；真人目检继续挂账。

## 恢复点

- 恢复时先核对本分支、worktree clean、`9b05f44a` 祖先关系和任务登记的唯一权威 WIP。
- 连续约 90 分钟没有关闭上述结构门时停止扩展候选，优先收口最小生产接线与失败证据。
- 未获正式数值选择时，允许以“结构 READY + 候选待决”收口，但不得宣称 M3 `1/1` 或 `5/5`。
