# Isar 待决字段暴露面分诊与决策菜单（2026-09-07）

## 结论与本单范围

两张登记表实测共 **61 项：A 60 / B 1 / C 0**。唯一 B 档是 `Sect.memberCount`；本轮需要拍板的只有菜单 **1**。其余 14 个可疑初始化器仍逐项提供菜单，全部推荐 A「维持现状」，不要求逐项回复。

| 登记范围 | 条目 | A 同期引入 | B 后加字段 | C 无法判定 |
|---|---:|---:|---:|---:|
| deferredNumericFields | 56 | 55 | 1 | 0 |
| deferredNonNumericFields | 5 | 5 | 0 | 0 |
| 合计 | 61 | 60 | 1 | 0 |
| 其中：无初始化器的 late int | 46 | 46 | 0 | 0 |
| 其中：15 个可疑初始化器 | 15 | 14 | 1 | 0 |

与任务描述中的 155 相差 **94 项**：D 单全仓报告中的 140 个 late 字段由 46 个 late int 与 94 个非数值 late 字段组成；后者是 String 34、DateTime 31、enum 26、bool 2、Attributes 1，它们没有进入这两张 Map。两表实际是 46 + 15 = 61。本单按用户指定的登记表成员分诊，不新增条目，也不把表外 94 项声称已分诊或已安全。D 单原始清查口径见 [D 单报告](isar_missing_fields_2026-09-07.md)“清查汇总”。

“初始化器对旧档语义可能不合适”并不单独证明有历史缺字段暴露。复核后 15 项中有 14 项从所属类的首个持久版本起就存在；本报告没有沿用 D 单的待决理由作为事实。

## 前置条件、基线与修改边界

- 主线基线：`ba29fc33d2f21a5f1bf0fe7eb9346e01f19a8645`；D 单代码 `ecc75dba9bba04e8f18b6dbe603d0679e99b6cae` 已经由 `547db1c430db01d4624fd6c0377638664ef72c1c` 集成。
- 开工核实 `lib/data/isar_missing_field_defaults.dart` 存在，`lib/data/isar_setup.dart` 的 `_currentSaveVersion` 为 `'0.48.0'`；主仓和独立 worktree 的 `git log --oneline -3` 均成功，没有主仓 `.git` 访问障碍。
- 独立分支：`codex/isar-deferred-triage-20260907`；worktree：`/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠`。
- 登记理由的已验证代码提交：`5f60279e6a36da53bd39d0e44e7fd18f722e0846`，提交说明「分诊 Isar 待决字段暴露面并登记考古结论」。之后仅补本报告与 `PROGRESS.md`。
- 两表 61 个键、顺序和成员均保留，只更新理由。将两表理由字符串归一化后，整个源文件与基线逐字一致；其他修复清单、归位函数与执行逻辑均不变。没有改测试或断言、迁移段、saveVersion、data/*.yaml、AGENTS.md、CLAUDE.md。
- 本单仅交付分诊和语义菜单，**未实装菜单中的任何默认值/缓存修复，未合 main、未 push**。

## 考古方法与可信范围

1. 从两张实际 Map 提取 61 个键，用 D 单 AST 清单定位当前实体文件、类型、初始化器与持久字段名；没有按 D 单理由文本分类。
2. 对每个字段及所属 `@collection` / `@embedded` 类运行 `git log --follow -S... -- <当前文件>`，同时读取 `--follow --name-status` 的文件历史；沿 rename 回到当时的实际路径。字段名命中必须落实到该类的真实字段声明，排除注释、调用、工厂参数和同文件其他类。
3. 独立复核 27 个当前源文件的 117 个历史版本及相关父提交，以 Dart analyzer AST 检查实体注解、直接字段声明、初始化器与 `@Name` / `@ignore`。每个 A 项均有类、字段同次加入，父提交缺类，以及后续可见版本没有“类存在而字段缺失”的证据。
4. 类引入父提交还查了全仓 Dart 声明和持久名称，排除已存类的简单改名/搬迁；所有引入提交均是本次基线的祖先。主 agent 的 AST 结果与两个只读子任务的逐字段考古 SHA 完全一致。
5. `git rev-parse --is-shallow-repository` 为 false；27 条路径的普通 `--follow` 与 `--follow --full-history` 提交集合一致。仓库根提交为 `ceadd90dbd1d5a3b64cd740b8f8cc0972ca30ee8`。

仓库其他功能确有 squash 记录，不能声称全仓从未 squash。本次目标类的引入与后续历史可核对，没有因 squash 或整片重构无法判定的项，故 C = 0。`lib/data/models/` 向 core/features 的搬迁已逐路径跟随，例如 core 模型的 `f1682f54ef2ab9d252df38a10399e93e1220968c`；features 的其他搬迁各按本文件历史追踪。`BiomeMinutes` 按类创建时间而非文件创建时间判定；`Character.rarity` 后补初始化器不等于后加持久字段。

这里的 A 只说明：在本仓可见持久 schema 历史中，没有早于该字段的同类旧行/对象。它不保证没有业务坏值、外部不可见版本、手工损坏或整个 embedded 对象缺失，也不替表外 94 项作结论。任何上述条件出现新证据，需要重新分诊。

可复核的只读命令形式：

```sh
git log --follow --format='%H %s' -S'字段名' -- lib/当前路径.dart
git log --follow --format='%H %s' -S'class 类名' -- lib/当前路径.dart
git log --follow --name-status -- lib/当前路径.dart
git show <下表引入SHA>:<下表历史路径>
git grep -n 'class 类名' <引入提交父SHA> -- '*.dart'
```

以下每条 A 项均保留两条完整 SHA；最后一栏行号属于对应引入提交的历史文件，不能拿当前文件行号替代。

## A 档完整清单（60 项）

| 字段 | 类型 | 类引入 SHA | 字段引入 SHA | 历史文件；类行 / 字段行 |
|---|---|---|---|---|
| `ActivityMemberSnapshot.characterId` | `int` | `9e55c268695333242e93e90f98eb70dbc459efcd` | `9e55c268695333242e93e90f98eb70dbc459efcd` | `lib/features/activity/domain/activity_member_snapshot.dart`；9 / 10 |
| `Attributes.agility` | `int` | `1aeb94c593814ecaa873c8f36700a78b7a1aa945` | `1aeb94c593814ecaa873c8f36700a78b7a1aa945` | `lib/data/models/attributes.dart`；8 / 11 |
| `Attributes.constitution` | `int` | `1aeb94c593814ecaa873c8f36700a78b7a1aa945` | `1aeb94c593814ecaa873c8f36700a78b7a1aa945` | `lib/data/models/attributes.dart`；8 / 9 |
| `Attributes.enlightenment` | `int` | `1aeb94c593814ecaa873c8f36700a78b7a1aa945` | `1aeb94c593814ecaa873c8f36700a78b7a1aa945` | `lib/data/models/attributes.dart`；8 / 10 |
| `Attributes.fortune` | `int` | `1aeb94c593814ecaa873c8f36700a78b7a1aa945` | `1aeb94c593814ecaa873c8f36700a78b7a1aa945` | `lib/data/models/attributes.dart`；8 / 12 |
| `BossGauntletRun.saveDataId` | `late int` | `7a06a2abaab9749629ed471685dc76b503cc5531` | `7a06a2abaab9749629ed471685dc76b503cc5531` | `lib/features/boss_gauntlet/domain/boss_gauntlet_run.dart`；15 / 18 |
| `BossGauntletRun.seed` | `late int` | `7a06a2abaab9749629ed471685dc76b503cc5531` | `7a06a2abaab9749629ed471685dc76b503cc5531` | `lib/features/boss_gauntlet/domain/boss_gauntlet_run.dart`；15 / 21 |
| `BossMemory.defeatCount` | `late int` | `bdee80d577e6563be4d01e64bfc89ee46ccd57e8` | `bdee80d577e6563be4d01e64bfc89ee46ccd57e8` | `lib/features/battle_record/domain/boss_memory.dart`；9 / 45 |
| `BossMemory.groupIndex` | `late int` | `bdee80d577e6563be4d01e64bfc89ee46ccd57e8` | `bdee80d577e6563be4d01e64bfc89ee46ccd57e8` | `lib/features/battle_record/domain/boss_memory.dart`；9 / 22 |
| `BossMemory.saveDataId` | `late int` | `bdee80d577e6563be4d01e64bfc89ee46ccd57e8` | `bdee80d577e6563be4d01e64bfc89ee46ccd57e8` | `lib/features/battle_record/domain/boss_memory.dart`；9 / 11 |
| `Character.internalForceMax` | `int` | `549991ec8b2146e5cfac898c04078314cda82181` | `549991ec8b2146e5cfac898c04078314cda82181` | `lib/data/models/character.dart`；12 / 24 |
| `DurableActivityCombatRun.cycleIndex` | `late int` | `fedad8812b81f10b44d2fca02b71bcfc0975c0fb` | `fedad8812b81f10b44d2fca02b71bcfc0975c0fb` | `lib/features/activity/domain/durable_activity_combat_run.dart`；23 / 35 |
| `DurableActivityCombatRun.saveDataId` | `late int` | `fedad8812b81f10b44d2fca02b71bcfc0975c0fb` | `fedad8812b81f10b44d2fca02b71bcfc0975c0fb` | `lib/features/activity/domain/durable_activity_combat_run.dart`；23 / 27 |
| `DurableActivityCombatRun.seed` | `late int` | `fedad8812b81f10b44d2fca02b71bcfc0975c0fb` | `fedad8812b81f10b44d2fca02b71bcfc0975c0fb` | `lib/features/activity/domain/durable_activity_combat_run.dart`；23 / 36 |
| `EncounterProgress.saveDataId` | `late int` | `1027431d6eff64f0e3d5f8c026bd3a669c284440` | `1027431d6eff64f0e3d5f8c026bd3a669c284440` | `lib/data/models/encounter_progress.dart`；21 / 25 |
| `EquipmentCatalogEntry.obtainedCount` | `late int` | `a150a93018a0c7418117b26c67f6bbe39806e691` | `a150a93018a0c7418117b26c67f6bbe39806e691` | `lib/features/weapon_codex/domain/equipment_catalog_entry.dart`；10 / 25 |
| `EquipmentCatalogEntry.saveDataId` | `late int` | `a150a93018a0c7418117b26c67f6bbe39806e691` | `a150a93018a0c7418117b26c67f6bbe39806e691` | `lib/features/weapon_codex/domain/equipment_catalog_entry.dart`；10 / 12 |
| `ExpeditionMilestoneRecord.nodeIndex` | `late int` | `80d95a1415c73f168786836a7de28eb474f32e08` | `80d95a1415c73f168786836a7de28eb474f32e08` | `lib/features/expedition/domain/expedition_milestone_record.dart`；11 / 26 |
| `ExpeditionMilestoneRecord.nodeSeed` | `late int` | `80d95a1415c73f168786836a7de28eb474f32e08` | `80d95a1415c73f168786836a7de28eb474f32e08` | `lib/features/expedition/domain/expedition_milestone_record.dart`；11 / 27 |
| `ExpeditionMilestoneRecord.saveDataId` | `late int` | `80d95a1415c73f168786836a7de28eb474f32e08` | `80d95a1415c73f168786836a7de28eb474f32e08` | `lib/features/expedition/domain/expedition_milestone_record.dart`；11 / 20 |
| `ExpeditionMilestoneRecord.sourceParticipantId` | `late int` | `80d95a1415c73f168786836a7de28eb474f32e08` | `80d95a1415c73f168786836a7de28eb474f32e08` | `lib/features/expedition/domain/expedition_milestone_record.dart`；11 / 31 |
| `ExpeditionMilestoneRecord.sourceRunId` | `late int` | `80d95a1415c73f168786836a7de28eb474f32e08` | `80d95a1415c73f168786836a7de28eb474f32e08` | `lib/features/expedition/domain/expedition_milestone_record.dart`；11 / 30 |
| `ExpeditionRun.saveDataId` | `late int` | `2726b63fb63f6f15217c9de0bf65042daf13eea8` | `2726b63fb63f6f15217c9de0bf65042daf13eea8` | `lib/features/expedition/domain/expedition_run.dart`；13 / 17 |
| `ExpeditionRun.seed` | `late int` | `2726b63fb63f6f15217c9de0bf65042daf13eea8` | `2726b63fb63f6f15217c9de0bf65042daf13eea8` | `lib/features/expedition/domain/expedition_run.dart`；13 / 23 |
| `ForgingSlot.slotIndex` | `int` | `1aeb94c593814ecaa873c8f36700a78b7a1aa945` | `1aeb94c593814ecaa873c8f36700a78b7a1aa945` | `lib/data/models/forging_slot.dart`；10 / 11 |
| `MainlineProgress.saveDataId` | `late int` | `0f97327ca586fad3c651a4569a830bff7be9f0d8` | `0f97327ca586fad3c651a4569a830bff7be9f0d8` | `lib/data/models/mainline_progress.dart`；17 / 22 |
| `MainlineSettlementJournal.loadoutVersion` | `late int` | `6d9902600fbb076b3e344fb9710a9209c9fe1a55` | `6d9902600fbb076b3e344fb9710a9209c9fe1a55` | `lib/features/mainline/domain/mainline_settlement_journal.dart`；106 / 120 |
| `MainlineSettlementJournal.participantId` | `late int` | `6d9902600fbb076b3e344fb9710a9209c9fe1a55` | `6d9902600fbb076b3e344fb9710a9209c9fe1a55` | `lib/features/mainline/domain/mainline_settlement_journal.dart`；106 / 119 |
| `MainlineSettlementJournal.saveDataId` | `late int` | `6d9902600fbb076b3e344fb9710a9209c9fe1a55` | `6d9902600fbb076b3e344fb9710a9209c9fe1a55` | `lib/features/mainline/domain/mainline_settlement_journal.dart`；106 / 113 |
| `NpcRelation.level` | `late int` | `7c88ed2c00eb88ef7ef43606cb602b1c3b65abec` | `7c88ed2c00eb88ef7ef43606cb602b1c3b65abec` | `lib/features/jianghu/domain/npc_relation.dart`；13 / 18 |
| `NpcRelation.sourceCharacterId` | `late int` | `7c88ed2c00eb88ef7ef43606cb602b1c3b65abec` | `7c88ed2c00eb88ef7ef43606cb602b1c3b65abec` | `lib/features/jianghu/domain/npc_relation.dart`；13 / 15 |
| `NpcRelation.targetCharacterId` | `late int` | `7c88ed2c00eb88ef7ef43606cb602b1c3b65abec` | `7c88ed2c00eb88ef7ef43606cb602b1c3b65abec` | `lib/features/jianghu/domain/npc_relation.dart`；13 / 16 |
| `ProgressiveUnlockReceipt.saveDataId` | `late int` | `05727c830763dee29e5b41dd54b8025ab1354660` | `05727c830763dee29e5b41dd54b8025ab1354660` | `lib/features/progressive_unlock/domain/progressive_unlock_receipt.dart`；8 / 17 |
| `PvpRecord.eloDelta` | `late int` | `a90282ee0b81edb46db35e18cb30b79f199b8248` | `a90282ee0b81edb46db35e18cb30b79f199b8248` | `lib/features/pvp/domain/pvp_record.dart`；20 / 46 |
| `PvpRecord.leftSnapshotId` | `late int` | `a90282ee0b81edb46db35e18cb30b79f199b8248` | `a90282ee0b81edb46db35e18cb30b79f199b8248` | `lib/features/pvp/domain/pvp_record.dart`；20 / 34 |
| `PvpRecord.opponentSnapshotId` | `late int` | `a90282ee0b81edb46db35e18cb30b79f199b8248` | `a90282ee0b81edb46db35e18cb30b79f199b8248` | `lib/features/pvp/domain/pvp_record.dart`；20 / 31 |
| `PvpRecord.playerEloAfter` | `late int` | `a90282ee0b81edb46db35e18cb30b79f199b8248` | `a90282ee0b81edb46db35e18cb30b79f199b8248` | `lib/features/pvp/domain/pvp_record.dart`；20 / 43 |
| `PvpRecord.playerEloBefore` | `late int` | `a90282ee0b81edb46db35e18cb30b79f199b8248` | `a90282ee0b81edb46db35e18cb30b79f199b8248` | `lib/features/pvp/domain/pvp_record.dart`；20 / 40 |
| `PvpRecord.playerId` | `late int` | `a90282ee0b81edb46db35e18cb30b79f199b8248` | `a90282ee0b81edb46db35e18cb30b79f199b8248` | `lib/features/pvp/domain/pvp_record.dart`；20 / 28 |
| `PvpSnapshot.snapshotElo` | `late int` | `a90282ee0b81edb46db35e18cb30b79f199b8248` | `a90282ee0b81edb46db35e18cb30b79f199b8248` | `lib/features/pvp/domain/pvp_snapshot.dart`；16 / 23 |
| `Reputation.playerId` | `late int` | `7c88ed2c00eb88ef7ef43606cb602b1c3b65abec` | `7c88ed2c00eb88ef7ef43606cb602b1c3b65abec` | `lib/features/jianghu/domain/reputation.dart`；14 / 19 |
| `Reputation.value` | `late int` | `7c88ed2c00eb88ef7ef43606cb602b1c3b65abec` | `7c88ed2c00eb88ef7ef43606cb602b1c3b65abec` | `lib/features/jianghu/domain/reputation.dart`；14 / 22 |
| `RetreatSession.saveDataId` | `late int` | `091c51f370e89b2dda7b50b5fddec2ecc5295c9c` | `091c51f370e89b2dda7b50b5fddec2ecc5295c9c` | `lib/data/models/retreat_session.dart`；18 / 22 |
| `RewardClaimReceipt.saveDataId` | `late int` | `d2c5185fa307c065fdf67a981e51637fee5de1cd` | `d2c5185fa307c065fdf67a981e51637fee5de1cd` | `lib/features/reward/domain/reward_claim_receipt.dart`；13 / 23 |
| `SaveData.slotId` | `int` | `549991ec8b2146e5cfac898c04078314cda82181` | `549991ec8b2146e5cfac898c04078314cda82181` | `lib/data/models/save_data.dart`；12 / 18 |
| `Sect.founderId` | `late int` | `0dff1f667f7ce80e5396e9b8140b7f55fc5632d2` | `0dff1f667f7ce80e5396e9b8140b7f55fc5632d2` | `lib/features/sect/domain/sect.dart`；22 / 28 |
| `Sect.sectLevel` | `late int` | `0dff1f667f7ce80e5396e9b8140b7f55fc5632d2` | `0dff1f667f7ce80e5396e9b8140b7f55fc5632d2` | `lib/features/sect/domain/sect.dart`；22 / 31 |
| `Sect.sectReputation` | `late int` | `0dff1f667f7ce80e5396e9b8140b7f55fc5632d2` | `0dff1f667f7ce80e5396e9b8140b7f55fc5632d2` | `lib/features/sect/domain/sect.dart`；22 / 34 |
| `Sect.totalWins` | `late int` | `0dff1f667f7ce80e5396e9b8140b7f55fc5632d2` | `0dff1f667f7ce80e5396e9b8140b7f55fc5632d2` | `lib/features/sect/domain/sect.dart`；22 / 37 |
| `SectEvent.sectId` | `late int` | `0dff1f667f7ce80e5396e9b8140b7f55fc5632d2` | `0dff1f667f7ce80e5396e9b8140b7f55fc5632d2` | `lib/features/sect/domain/sect_event.dart`；12 / 17 |
| `Technique.cultivationProgressToNext` | `int` | `549991ec8b2146e5cfac898c04078314cda82181` | `549991ec8b2146e5cfac898c04078314cda82181` | `lib/data/models/technique.dart`；13 / 32 |
| `Technique.ownerCharacterId` | `late int` | `549991ec8b2146e5cfac898c04078314cda82181` | `549991ec8b2146e5cfac898c04078314cda82181` | `lib/data/models/technique.dart`；13 / 20 |
| `TowerPersonalRecord.participantId` | `late int` | `a04567dbb541f8db1a23417aab91a5bb31f273cf` | `a04567dbb541f8db1a23417aab91a5bb31f273cf` | `lib/features/tower/domain/tower_personal_record.dart`；10 / 22 |
| `TowerPersonalRecord.saveDataId` | `late int` | `a04567dbb541f8db1a23417aab91a5bb31f273cf` | `a04567dbb541f8db1a23417aab91a5bb31f273cf` | `lib/features/tower/domain/tower_personal_record.dart`；10 / 19 |
| `TowerProgress.saveDataId` | `late int` | `71a78d4889b5632a049e34fdca0e8192db52f2eb` | `71a78d4889b5632a049e34fdca0e8192db52f2eb` | `lib/data/models/tower_progress.dart`；18 / 23 |
| `Character.isAlive` | `bool` | `549991ec8b2146e5cfac898c04078314cda82181` | `549991ec8b2146e5cfac898c04078314cda82181` | `lib/data/models/character.dart`；12 / 58 |
| `Lore.isPreset` | `bool` | `1aeb94c593814ecaa873c8f36700a78b7a1aa945` | `1aeb94c593814ecaa873c8f36700a78b7a1aa945` | `lib/data/models/lore.dart`；9 / 11 |
| `Lore.addedAt` | `DateTime` | `1aeb94c593814ecaa873c8f36700a78b7a1aa945` | `1aeb94c593814ecaa873c8f36700a78b7a1aa945` | `lib/data/models/lore.dart`；9 / 12 |
| `Character.rarity` | `RarityTier` | `549991ec8b2146e5cfac898c04078314cda82181` | `549991ec8b2146e5cfac898c04078314cda82181` | `lib/data/models/character.dart`；12 / 31 |
| `BiomeMinutes.biome` | `EncounterBiome` | `e08c8e7068f15a715223c1046135b02c2def8634` | `e08c8e7068f15a715223c1046135b02c2def8634` | `lib/data/models/encounter_progress.dart`；73 / 75 |

## B 档清单（1 项）及 C 档清单（0 项）

`Sect.memberCount`：类于 `0dff1f667f7ce80e5396e9b8140b7f55fc5632d2` 引入；字段于 `5378c2a3f10eaf92fd4af2dcee254eff002e6474` 后加。两个提交的 `lib/features/sect/domain/sect.dart` 真实源代码表明旧类已有持久行结构但无该字段，后一个提交新增 `int memberCount = 0;`。其父提交亦可直接验证字段不存在。完整影响与选项在菜单 1。

**C 档：无。** 没有用猜测把历史不明项填进 A；逐字段证据和历史检查 JSON 保留在文末证据目录。

## 决策菜单（15 个初始化器字段，包含唯一 B 项）

可直接回复 **1A**，表示选择菜单 1 的推荐语义，之后另单实装。本单不会因菜单交付而自动改迁移。2–15 均为 A 档，默认推荐维持现状；其中 B/C 选项是未来独立证实损坏时的条件恢复方案，不是本轮必选事项。

下列消费路径与行号均以本单代码提交为准；`minLong` 为 `-9223372036854775808`。A 项的“假想缺失”用于说明语义风险，不代表查出了历史暴露。缺字段读取值来自 D 单已合入的真实旧 schema 契约，本轮全量测试再次执行了这些测试。

### 1 · Sect.memberCount（B 档，需决策）

字段：`Sect.memberCount`（`int`；初始化器 `0`）。类引入 `0dff1f667f7ce80e5396e9b8140b7f55fc5632d2`；字段引入 `5378c2a3f10eaf92fd4af2dcee254eff002e6474`。

现状：旧行读 `-9223372036854775808`；流向 [lib/features/sect/application/sect_member_service.dart:46](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/features/sect/application/sect_member_service.dart:46) 容量比较、`:51` 招收后 `+1`、`:111` 仅正数时退派减一，以及 [lib/features/sect/presentation/sect_screen.dart:740](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/features/sect/presentation/sect_screen.dart:740) 人数显示。

实际影响：静默错误。minLong 小于正常人数上限，招收容量限制失效；第一次招收后持久化成 minLong+1，不再匹配精确哨兵，退派也不减。`currentSectProvider` 只在整行不存在时初始化（[lib/features/sect/application/sect_providers.dart:168](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/features/sect/application/sect_providers.dart:168)）；`ensureDefaultSectInTxn` 直接返回已有行（[lib/features/sect/application/sect_recruit_transaction_service.dart:26](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/features/sect/application/sect_recruit_transaction_service.dart:26)）。没有消费前必覆写保证。

- A) 按现存且一致的 Character 入派关联重建异常负计数缓存：`isInSect=true && sectId==该 Sect.id`，排除已确认 founder；不按 `isAlive` 过滤。有关联矛盾时停止该行自动修复并列出异常。
- B) 仅把精确 minLong 归 0，且先确认无既有非 founder 成员。实现便宜，但漏掉已变成 minLong+k 的污染缓存；有成员时会低估人数。
- C) 先阻止异常门派招收，保留门派和角色；由用户逐项核对身份/关联冲突后回填。

我的推荐：**A**。memberCount 是现存关系的缓存；重建必须先核验关联，并覆盖 minLong 经 +1 后形成的污染。

适用边界：`listMembers` 只按 sectId 查询（[sect_member_service.dart:121](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/features/sect/application/sect_member_service.dart:121)），不足以自动证明 isInSect 一致。模型 `founderId` 注释仍称 `LineageMember.id`（[lib/features/sect/domain/sect.dart:27](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/features/sect/domain/sect.dart:27)），而当前 dismiss 与 `Character.id` 比较（[sect_member_service.dart:107](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/features/sect/application/sect_member_service.dart:107)），不能在 founder 引用不明时直接计数。死亡不等于退派，不能过滤死亡角色。任何旗标/外键/身份矛盾都停止该行修复并列异常。

Character 的 isInSect/sectId/sectRank 与 memberCount 同在 `5378c2a3f10eaf92fd4af2dcee254eff002e6474` 新增，真正未经后续招收的旧库可能可证重建为 0，但不能推断所有已经升级的旧库仍为 0。针对 memberCount 负计数的后续修复需要本菜单明确授权，不推广到其他允许负值的字段。

### 2 · ActivityMemberSnapshot.characterId（A 档）

字段：`int`，初始化器 `0`。类引入与字段引入均为 `9e55c268695333242e93e90f98eb70dbc459efcd`。

现状：假想缺失读 minLong；流向 [lib/features/activity/application/durable_activity_automation_service.dart:340](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/features/activity/application/durable_activity_automation_service.dart:340) 按 ID 取参与角色，`:559` 不存在/不适格即抛 StateError。

实际影响：可见历史无缺字段暴露；若另有损坏快照，恢复准入会被拒绝。读取旧身份先于 `:346` 新建验证快照，不能声称恢复会先重写身份。

- A) 维持现状，不新增迁移。
- B) 未来确证损坏且有唯一可信参与记录时，用该记录的 exact Character ID 恢复；匹配不唯一时停止。
- C) 无法确定参与者时封存/取消该会话，另行处理奖励与占用，不以 0 或当前掌门替身。

我的推荐：**A**。字段与 embedded 类同期，0 是构造占位，不是待拍的历史默认。

### 3 · SaveData.slotId（A 档）

字段：`int`，初始化器 `1`。类引入与字段引入均为 `549991ec8b2146e5cfac898c04078314cda82181`。

现状：假想缺失读 minLong；流向 [lib/data/isar_setup.dart:647](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/data/isar_setup.dart:647) 的 saveDataId、`:865` 恢复槽号校验；[lib/features/save_management/application/save_management_service.dart:69](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/features/save_management/application/save_management_service.dart:69) 备份文件名和 `:103` 恢复路径。

实际影响：可见历史无缺字段暴露。异常值会让恢复校验失败或下游归属/文件名异常；新档在 isar_setup.dart:291 写当前槽号，已有存档不会因此必覆写。

- A) 维持现状，不新增迁移。
- B) 未来确证缺失时，由可信打开上下文和实际选择槽号恢复，校验槽内归属记录，不只相信可重命名的备份文件名。
- C) 槽身份不能验证时阻止继续写档，保留原文件供恢复，不统一写 1。

我的推荐：**A**。初版 SaveData 已有 slotId，槽 2/3 身份不能由构造默认决定。

### 4 · ForgingSlot.slotIndex（A 档）

字段：`int`，初始化器 `1`。类引入与字段引入均为 `1aeb94c593814ecaa873c8f36700a78b7a1aa945`。

现状：假想缺失读 minLong；流向 [lib/features/inventory/presentation/equipment_detail_screen.dart:936](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/features/inventory/presentation/equipment_detail_screen.dart:936) 第三槽绝技识别。主要开锋在 [lib/features/equipment/application/forging_service.dart:91](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/features/equipment/application/forging_service.dart:91) 按外部槽号访问列表，不替旧 embedded 编号纠错。

实际影响：可见历史无缺字段暴露；损坏的第三槽编号会让绝技展示漏识别。不能把主要开锋按索引写入当作编号必覆写。

- A) 维持现状，不新增迁移。
- B) 未来确证缺失且三槽顺序完整、无重排证据时，按列表位置 +1 恢复编号，保留已开锋内容。
- C) 形状异常时保留装备并暂停该槽操作供核对，不把所有槽都归 1。

我的推荐：**A**。初版 ForgingSlot 与编号同期；三槽构造证据在 [lib/core/domain/equipment.dart:98](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/core/domain/equipment.dart:98)，位置修复仅适用于顺序不变量仍成立的行。

### 5 · Character.internalForceMax（A 档）

字段：`int`，初始化器 `500`。类引入与字段引入均为 `549991ec8b2146e5cfac898c04078314cda82181`。

现状：假想缺失读 minLong；流向 [lib/shared/battle_shared/derived_stats.dart:288](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/shared/battle_shared/derived_stats.dart:288) 上限派生/clamp、[lib/features/seclusion/application/seclusion_service.dart:509](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/features/seclusion/application/seclusion_service.dart:509) 永久内力 clamp。

实际影响：可见历史无缺字段暴露。异常上限会让派生上限归零，闭关可能将永久内力压到异常上限。[lib/features/cultivation/application/character_advancement_service.dart:95](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/features/cultivation/application/character_advancement_service.dart:95) 只有真实升层才覆写；未达经验阈值、零经验、被锁或终局均无必覆写保证。

- A) 维持现状，不新增迁移。
- B) 未来确证缺失且境界合法时，按 realmTier+realmLayer 查 RealmDef.internalForceMax 恢复基础上限；保留永久内力，另定是否截断。
- C) 缺可信境界/历史时保留角色并暂停成长/战斗，从可信备份恢复，不固定写 500。

我的推荐：**A**。字段与 Character 同期，B 是当前规则的可选恢复语义，不是证明某个历史档的原值。

当前生产创建 [master_builder.dart:58](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/features/onboarding/application/master_builder.dart:58)、[recruitment_service.dart:104](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/features/recruitment/application/recruitment_service.dart:104)、[sect_recruit_transaction_service.dart:76](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/features/sect/application/sect_recruit_transaction_service.dart:76) 及升级 [character_advancement_service.dart:95](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/features/cultivation/application/character_advancement_service.dart:95) 都写 RealmDef；遗物和祖师增益在 [derived_stats.dart:274](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/shared/battle_shared/derived_stats.dart:274) 后另叠。该链支持 B 的当前规则依据，不证明任意历史快照都能无条件还原。

### 6 · Technique.cultivationProgressToNext（A 档）

字段：`int`，初始化器 `100`。类引入与字段引入均为 `549991ec8b2146e5cfac898c04078314cda82181`。

现状：假想缺失读 minLong；流向 [lib/features/cultivation/application/cultivation_service.dart:93](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/features/cultivation/application/cultivation_service.dart:93) 阈值比较、`:94` 减阈值、`:106` 跨层后刷新；[lib/features/technique_panel/presentation/technique_panel_screen.dart:746](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/features/technique_panel/presentation/technique_panel_screen.dart:746) 进度比例。

实际影响：可见历史无缺字段暴露。异常阈值先被比较和减法消费，后才写新阈值，会发生错误升层/进度整数运算；不能把跨层后刷新当作消费前必覆写。

- A) 维持现状，不新增迁移。
- B) 未来确证缺失时按 cultivationLayer 的 NumbersConfig.cultivationProgressToNext 重建；jiJing 按封顶语义采用升入时上一层 wuXia 的阈值。
- C) 从可信备份一起恢复层级/进度/阈值，不统一写 100 或删除修炼事实。

我的推荐：**A**。阈值在 Technique 初版即存在。jiJing 保留上一层阈值的逻辑在 [cultivation_service.dart:99](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/features/cultivation/application/cultivation_service.dart:99) 和 `:112`，不能简单查 jiJing map。

### 7 · Attributes.constitution（A 档）

字段：`int`，初始化器 `5`。类引入与字段引入均为 `1aeb94c593814ecaa873c8f36700a78b7a1aa945`。

现状：假想缺失读 minLong；流向 [lib/shared/battle_shared/derived_stats.dart:117](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/shared/battle_shared/derived_stats.dart:117) HP 计算和 [lib/core/domain/attribute_effect_policy.dart:117](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/core/domain/attribute_effect_policy.dart:117) 重伤减时。

实际影响：可见历史无缺字段暴露。异常根骨直接进入 HP 与整数减法/倍率链，产生不符合角色语义的生命/伤势结果。升级不改四属性（[character_advancement_service.dart:36](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/features/cultivation/application/character_advancement_service.dart:36)），奇遇只增加 applied（[encounter_service.dart:403](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/features/encounter/application/encounter_service.dart:403)），没有消费前归位保证。

- A) 维持现状，不新增迁移。
- B) 未来确证缺失时，仅在可信创建快照和该角色逐项奇遇增量完整时重建根骨。
- C) 用户逐角色接受新根骨值（例如 5）作为补偿性重置，同时审查出生总点数和资质；不称恢复原值。

我的推荐：**A**。根骨与 Attributes 同期，5 只是构造占位。

角色只存 attributeBonusFromAdventure 总增量；EncounterProgress 的四项增量不是任意角色独立历史账，不能无条件按总量拆回根骨。

### 8 · Attributes.enlightenment（A 档）

字段：`int`，初始化器 `5`。类引入与字段引入均为 `1aeb94c593814ecaa873c8f36700a78b7a1aa945`。

现状：假想缺失读 minLong；流向 [lib/core/domain/attribute_effect_policy.dart:126](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/core/domain/attribute_effect_policy.dart:126) 悟性成长倍率、`:154` 领悟概率；[lib/shared/battle_shared/player_combatant_snapshot_builder.dart:252](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/shared/battle_shared/player_combatant_snapshot_builder.dart:252) 将悟性传入战斗成长。

实际影响：可见历史无缺字段暴露。异常值进入整数减法、增长倍率与概率计算，可能得到错误加成/概率；奇遇 [encounter_service.dart:405](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/features/encounter/application/encounter_service.dart:405) 只有增量写入，没有先整体重建。

- A) 维持现状，不新增迁移。
- B) 未来确证缺失且可信创建快照与该角色逐项奇遇增量完整时重建悟性。
- C) 用户逐角色接受新悟性值（例如 5）及资质/成长影响，按补偿性重置处理。

我的推荐：**A**。悟性在 Attributes 初版存在。rarity 档位和总点数不能唯一反解四维分配。

### 9 · Attributes.agility（A 档）

字段：`int`，初始化器 `5`。类引入与字段引入均为 `1aeb94c593814ecaa873c8f36700a78b7a1aa945`。

现状：假想缺失读 minLong；流向 [lib/shared/battle_shared/derived_stats.dart:153](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/shared/battle_shared/derived_stats.dart:153) 速度、`:199` 闪避；[lib/features/character_panel/presentation/lineage_character_detail_screen.dart:297](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/features/character_panel/presentation/lineage_character_detail_screen.dart:297) 属性展示。

实际影响：可见历史无缺字段暴露。异常值进入速度/闪避算式，造成错误战斗属性；奇遇 [encounter_service.dart:407](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/features/encounter/application/encounter_service.dart:407) 只增量，不恢复历史分配。

- A) 维持现状，不新增迁移。
- B) 未来确证缺失，且可信创建快照与逐项后天增量可核对时重建身法。
- C) 用户逐角色指定新身法（例如 5）并接受战斗表现变化，按补偿性重置记录。

我的推荐：**A**。身法与所属 embedded 类同次引入，不需要为占位 5 拍默认。

### 10 · Attributes.fortune（A 档）

字段：`int`，初始化器 `5`。类引入与字段引入均为 `1aeb94c593814ecaa873c8f36700a78b7a1aa945`。

现状：假想缺失读 minLong；流向 [lib/core/domain/attribute_effect_policy.dart:157](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/core/domain/attribute_effect_policy.dart:157) 当前概率策略、[lib/features/encounter/application/encounter_service.dart:248](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/features/encounter/application/encounter_service.dart:248) 兼容概率公式与 `:559` 机缘门槛；[lib/features/encounter/presentation/encounter_hook.dart:103](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/features/encounter/presentation/encounter_hook.dart:103) 传入选择界面。

实际影响：可见历史无缺字段暴露。异常机缘使概率和特殊选项门槛出错。奇遇 [encounter_service.dart:409](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/features/encounter/application/encounter_service.dart:409) 只增量，不能保证先重建。

- A) 维持现状，不新增迁移。
- B) 未来确证缺失，有可信创建快照和该角色逐项加点账时重建机缘。
- C) 用户逐角色指定新机缘（例如 5）并接受奇遇/选项变化，按补偿性重置记录。

我的推荐：**A**。机缘与 Attributes 同期，无历史缺字段暴露。不能用当前总点数、章节或统一配置机缘替代实际出生值。

### 11 · Character.isAlive（A 档）

字段：`bool`，初始化器 `true`。类引入与字段引入均为 `549991ec8b2146e5cfac898c04078314cda82181`。

现状：假想缺失读 `false`，与合法持久布尔值重合；流向 [lib/features/activity/application/durable_activity_automation_service.dart:562](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/features/activity/application/durable_activity_automation_service.dart:562) 活动恢复准入和 [lib/features/lineup/application/lineup_service.dart:89](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/features/lineup/application/lineup_service.dart:89) 死亡角色入阵拒绝。

实际影响：可见历史无缺字段暴露。假想缺失会被当死亡拒绝准入，但 false 没有缺失标签，批量改 true 会覆盖存档的生死事实。

- A) 维持现状，保留已存布尔值。
- B) 仅对未来能由历史 schema/备份证明缺失，且有可信存活记录的 exact 角色改 true。
- C) 无证据时保留该角色和旧档，由用户逐角色确认生死再恢复，不全体复活。

我的推荐：**A**。初版 Character 已含 isAlive；初始化器 true 与回读 false 不同，不等于有历史暴露。恢复必须依赖字段外证据。

### 12 · Lore.isPreset（A 档）

字段：`bool`，初始化器 `true`。类引入与字段引入均为 `1aeb94c593814ecaa873c8f36700a78b7a1aa945`。

现状：假想缺失读 `false`，与真实续写典故重合；流向 [lib/features/inventory/presentation/equipment_detail_screen.dart:1118](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/features/inventory/presentation/equipment_detail_screen.dart:1118) 的续写筛选。[lib/features/event/application/game_event_service.dart:154](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/features/event/application/game_event_service.dart:154) 就会为获得装备的真实续写写 false。

实际影响：可见历史无缺字段暴露。假想缺失可能让预设典故出现在续写区，但批量改 true 会隐藏真正的玩家经历。

- A) 维持现状，保留已存分类。
- B) 未来确证缺失后，仅按明确触发事件/预设来源逐条归类；无法归类的正文保留。
- C) 无法判来源的条目标未知来源，保留正文，不伪造预设或玩家经历。

我的推荐：**A**。Lore 初版即有此字段。触发描述可能为空或旧格式，不能只凭正文与 YAML 相同断言是预设条目。

### 13 · Lore.addedAt（A 档）

字段：`DateTime`，初始化器 `DateTime(2000)`。类引入与字段引入均为 `1aeb94c593814ecaa873c8f36700a78b7a1aa945`。

现状：假想缺失读 UTC `1970-01-01T00:00:00.000Z`，可与合法时间重合；流向 [lib/features/inventory/presentation/equipment_detail_screen.dart:1119](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/features/inventory/presentation/equipment_detail_screen.dart:1119) 时间排序。新事件在 [lib/features/event/application/game_event_service.dart:155](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/features/event/application/game_event_service.dart:155) 写 now。

实际影响：可见历史无缺字段暴露。假想缺失会排到早期，但 epoch 比较本身不会崩溃。每次新事件只追加新 Lore，不会补旧典故历史日期。

- A) 维持现状，保留已有时间。
- B) 未来确证缺失，且能定位 exact 事件记录时按该事件时间回填。
- C) 无事件时间时保留“未知时间”语义并稳定排序，不用迁移当天或 2000 年冒充历史日期。

我的推荐：**A**。Lore 与 addedAt 同期，2000 年是构造占位，不是历史事实。单看 epoch 不能区分缺失；展示未知时间属于另行决定的 UI/数据语义。

### 14 · Character.rarity（A 档）

字段：`RarityTier`，`@Enumerated(EnumType.name)`，当前初始化器 `RarityTier.biaoZhun`。类引入与字段引入均为 `549991ec8b2146e5cfac898c04078314cda82181`。

现状：假想缺失读首项 `RarityTier.yongCai`，与合法庸才重合；流向 [lib/features/character_panel/presentation/lineage_character_detail_screen.dart:306](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/features/character_panel/presentation/lineage_character_detail_screen.dart:306) 资质徽章。出生总点数公式在 [lib/core/domain/character.dart:290](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/core/domain/character.dart:290)；[lib/data/isar_setup.dart:553](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/data/isar_setup.dart:553) 仅在 `<0.39` 迁移门内按出生点数重算。

实际影响：可见历史无缺字段暴露。假想缺失会显示庸才，但这也是合法档位。0.39 修正受版本门限制，奇遇也明确不再重算资质，不能保证所有读取前刷新。

- A) 维持现状，保留出生资质。
- B) 未来确证缺失，且四项属性和该角色后天总加点完整一致时，用 `attributes.total-attributeBonusFromAdventure` 按资质表重建。
- C) 缺出生证据时保留未知/人工恢复，不用当前属性总和或默认 biaoZhun 覆盖。

我的推荐：**A**。初版真实持久声明为 `late RarityTier rarity;`；`30f2cf9b1a45c3c19a5a66717e2446320f14f6c1` 只是补构造默认，不是新增属性。B 公式有正常账本依据，也不能先把所有 yongCai 当缺失。

### 15 · BiomeMinutes.biome（A 档）

字段：`EncounterBiome`，`@enumerated` ordinal，初始化器 `EncounterBiome.mountainForest`。类引入与字段引入均为 `e08c8e7068f15a715223c1046135b02c2def8634`。

现状：假想缺失读首项 `EncounterBiome.mountainPath`，与合法山路重合；流向 [lib/features/encounter/domain/encounter_progress.dart:121](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/features/encounter/domain/encounter_progress.dart:121) 按地图读分钟和 `:129` 同 key 累加；[lib/features/encounter/application/encounter_service.dart:568](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/features/encounter/application/encounter_service.dart:568) 地点停留门槛。

实际影响：可见历史无缺字段暴露。假想缺失会把分钟归到山路，影响地点门槛。addMinutes 只同 key 累加或新建条目，不会找回旧条目的原地图。

- A) 维持现状，保留现有枚举键。
- B) 未来确证缺失且有可信按地图活动账时，将分钟归还原地图并合并同键计数。
- C) 地点无法找回时保留未知地点时间，或经用户同意舍弃该缓存，不把所有山路改 mountainForest。

我的推荐：**A**。BiomeMinutes 类与 biome 同时引入；较早文件里存在的 EncounterProgress 不是这个 embedded 类。山路是有效地图，首项不能充当缺失检测器。


## 验证的真实输出

下面所有验证均在代码提交 `5f60279e6a36da53bd39d0e44e7fd18f722e0846` 的独立 worktree 执行。`--machine` 仅为可核验计数，`--no-pub` 复用已按 lockfile 安装的依赖，未指定测试子集；完整测试文件清单与 D 单收官 899 文件 / 6285 项对照。全量测试使用既有共享锁 `/Users/a10506/.claude/locks/wuxia_full_test.lock`，没有删除或抢占锁。未设置 `DEVELOPER_DIR`。

### 1. `dart run build_runner build --delete-conflicting-outputs`

退出码 `0`；开始 `2026-09-07T20:30:10.837100+08:00`，结束 `2026-09-07T20:30:34.666568+08:00`。

```text
  0s isar_community_generator on 141 inputs: 1 no-op; lib/core/domain/attributes.dart
  1s isar_community_generator on 141 inputs: 37 output, 104 no-op
  0s source_gen:combining_builder on 1606 inputs; lib/core/application/character_providers.dart
  0s source_gen:combining_builder on 1606 inputs: 72 output, 1534 no-op
  Built with build_runner/aot in 19s; wrote 144 outputs.
```

完整真实输出：[build-runner.log](/Users/a10506/Documents/Codex/2026-09-07/isar-deferred-triage/build-runner.log)。

### 2. `flutter analyze`

退出码 `0`；开始 `2026-09-07T20:30:34.666846+08:00`，结束 `2026-09-07T20:31:00.754929+08:00`。

```text
Analyzing 挂机武侠...
No issues found! (ran in 21.9s)
```

完整真实输出：[analyze.log](/Users/a10506/Documents/Codex/2026-09-07/isar-deferred-triage/analyze.log)。

### 3. `flutter test --no-pub --machine`

退出码 `0`；开始 `2026-09-07T20:31:11.598366+08:00`，结束 `2026-09-07T20:42:04.031359+08:00`。

```text
{"success":true,"type":"done","time":650588}
```

原始 machine 事件统计：**6285 PASS / 0 FAIL / 0 SKIP，实际加载 899/899 个测试文件，漏跑 0、额外 0**。与 D 单收官的 6285 项完全一致；不是从 testStart 数推算（已排除隐藏加载事件）。

完整真实输出：[full-test.log](/Users/a10506/Documents/Codex/2026-09-07/isar-deferred-triage/full-test.log)。

### 4. `dart format .`

退出码 `0`；开始 `2026-09-07T20:42:04.147574+08:00`，结束 `2026-09-07T20:42:11.225259+08:00`。

```text
Formatted 1771 files (0 changed) in 5.49 seconds.
```

完整真实输出：[format.log](/Users/a10506/Documents/Codex/2026-09-07/isar-deferred-triage/format.log)。

### 5. `flutter build macos`

退出码 `0`；开始 `2026-09-07T20:42:11.226771+08:00`，结束 `2026-09-07T20:43:45.093432+08:00`。

```text
                   ^
/Users/a10506/.pub-cache/hosted/pub.flutter-io.cn/audioplayers_darwin-6.4.0/darwin/audioplayers_darwin/Sources/audioplayers_darwin/WrappedMediaPlayer.swift:211:16: warning: call to main actor-isolated instance method 'reset()' in a synchronous nonisolated context
          self.reset()
               ^
  private func reset() {
               ^
warning: Run script build phase 'Run Script' will be run during every build because it does not specify any outputs. To address this issue, either add output dependencies to the script phase, or configure it to run in every build by unchecking "Based on dependency analysis" in the script phase. (in target 'Flutter Assemble' from project 'Runner')
✓ Built build/macos/Build/Products/Release/wuxia_idle.app (177.3MB)
```

原生编译有 audioplayers_darwin 的 Swift 并发警告及 Run Script 提示；退出码为 0，完整警告保留在日志中。本轮未改依赖或编译配置。

完整真实输出：[macos-build.log](/Users/a10506/Documents/Codex/2026-09-07/isar-deferred-triage/macos-build.log)。

另做登记覆盖守卫：`flutter test --no-pub --machine test/data/isar_missing_field_coverage_test.dart`，4 PASS / 0 FAIL / 0 SKIP。没有理由文本导致的断言失败，也没有更改断言迁就字符串。完整记录：[coverage-guard.log](/Users/a10506/Documents/Codex/2026-09-07/isar-deferred-triage/coverage-guard.log)。

## 证据与交付边界

- [逐字段独立 AST 核对](/Users/a10506/Documents/Codex/2026-09-07/isar-deferred-triage/independent-history-check.json)：61 项完整引入 SHA、路径、行号、父提交与版本连续性。
- [46 个 late 字段原始考古](/Users/a10506/Documents/Codex/2026-09-07/isar-deferred-triage/late-history.json) / [15 个初始化器字段原始考古](/Users/a10506/Documents/Codex/2026-09-07/isar-deferred-triage/defaults-history.json)：逐字段 `--follow`、pickaxe、真实声明、父提交与命中排歧义。
- [实际登记清单](/Users/a10506/Documents/Codex/2026-09-07/isar-deferred-triage/registered-fields.json) / [理由变更边界证明](/Users/a10506/Documents/Codex/2026-09-07/isar-deferred-triage/reason-edit-proof.json) / [历史完整性检查](/Users/a10506/Documents/Codex/2026-09-07/isar-deferred-triage/history-completeness.json)。
- [五项验证命令、时间、退出码及全量文件清单](/Users/a10506/Documents/Codex/2026-09-07/isar-deferred-triage/validation-results.json)。
- [主仓开工基线与用户文件哈希](/Users/a10506/Documents/Codex/2026-09-07/isar-deferred-triage/before.json)；交付核对另存同目录 `delivery.json`。

本单分诊完成不表示 B 项已修复。当前 `Sect.memberCount` 的旧档风险仍待用户选菜单后另单处理。A 项继续留在登记表中供覆盖守卫追踪。独立候选没有合 main、没有 push；本轮本地验证不代签远端 CI、Windows 或真人验收。
