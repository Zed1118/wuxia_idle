# M3 五类单段普攻合同实施计划

## 结果合同

- 单一目标：让五类武器身份从真实装备 YAML 进入玩家战斗快照与生产普攻装配，同时保持基础普攻为单段、可持续按住、无攻击位移。
- 实时基线：`9b05f44a97d3a7d31a645e62d0be9615fdb122dd`；M3 为 `0/5` 武器画像、`0/15` 清杂/精英/Boss 场景。
- 固定分母：剑、重兵、软兵、双持、暗器共 5 类；每类后续分别通过清杂、精英、Boss 三场，共 15 格。
- 本单可关闭的结构门：37 件生产武器全部有显式类别；类别贯通 `EquipmentDef -> CombatantSnapshot -> Phase0aPlayerInputAdapter`；无武器保持现有掌风基线；生产装配继续不注入三段链和攻击位移。
- 正式画像边界：用户已按推荐 M3 合同授权自主选择非持久化生产画像；五类范围、角度、节奏、姿态压力和表现差异进入独立 combat catalog，不改既有技能伤害公式或 `numbers.yaml`。
- 正式里程碑边界：候选绿色不等于 M3 通过；生产值选定、真实生产消费、集成 Gate 和真人目检仍分别闭环。

## 授权与禁止项

- 已授权：扩展非持久化 `EquipmentDef` 和 `data/equipment.yaml` 武器类别；扩展非持久化战斗快照/运行时装配字段；自主选择并接入五类单段生产画像。
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
  - `data/combat/player_attack_profiles.yaml`
  - `lib/data/defs/weapon_attack_profile_def.dart`
  - `lib/data/weapon_attack_profile_loader.dart`
  - `lib/features/battle/presentation/phase0a/phase0a_vfx_controller.dart`
  - `lib/features/battle/presentation/phase0a/phase0a_battle_screen.dart`
  - 对应 targeted tests、M3 候选测试/说明与 task registry

## 实施与验收顺序

1. 先写会红的 YAML schema、全量分类、快照来源与生产 mapper 合同测试。
2. 新增唯一核心枚举 `WeaponArchetype`；`EquipmentDef.fromYaml` 对 weapon 缺类别、非 weapon 带类别均 fail closed。
3. 为 37 件生产武器写显式类别；运行时不按名称、ID、流派或装备数值推断。
4. 玩家快照从实际装备 def 派生类别；无武器为 `null`，多武器或 def/slot 不一致 fail closed；复制与心魔镜像保持字段。
5. 生产 mapper 依据已装备类别读取正式画像；无装备保持原掌风基线，`basicAttackChain == null` 与攻击位移 `0` 保持不变。
6. 用真实仓库、生产 mapper、snapshot factory、damage adapter 与 reducer 完成五类 × 三流派 × 清杂/精英/Boss 的 45 格矩阵。
7. 对生产画像消费与单目标/零位移红线做双向精确破坏证红并还原。
8. 执行 targeted、`flutter analyze`、整仓 `dart format .`、锁保护全量测试和 exact-tip Gate；真人目检继续挂账。

## 恢复点

- 恢复时先核对本分支、worktree clean、`9b05f44a` 祖先关系和任务登记的唯一权威 WIP。
- 连续约 90 分钟没有关闭上述结构门时停止扩展候选，优先收口最小生产接线与失败证据。
- 工程 Gate 关闭后仍不得把自动矩阵、截图或测试当作真人桌面手感；正式 M3 人验保持挂账。

## 当前收口（2026-09-01）

- 结构门完成：5 类枚举、37/37 生产武器显式分类、实际装备快照与生产 mapper 接线均完成。
- 候选门完成：`5 x 3` 受控模拟为 `15/15`，四向破坏证红均精确 `1` 个失败并还原。
- 验证完成：联合定向 `125/125`、应用分析 `0 issue`、整仓格式 `0 changed`、修正后全量 `5868/5868`。
- 正式画像正在收口：五类因子已写入独立 production catalog，真实 mapper、事件与表现层已经消费；45 格生产矩阵首轮通过。
- 待完成：提交后破坏证红、整仓格式、最终全量、exact-tip Gate、合并 push；真人桌面手感继续挂账。
