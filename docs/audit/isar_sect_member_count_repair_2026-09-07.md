# 门派旧档负人数缓存修复（已批准 1A，2026-09-07）

## 交付与授权

用户在 [分诊报告](isar_deferred_field_triage_2026-09-07.md) 后明确回复「按推荐执行」。本轮实装菜单 1A：核验当前 founder 身份及成员关联后重建异常负计数；其余 14 个可疑初始化器按推荐维持现状。

- 基线：分诊候选 `26f2fb75b2cacce831e8b680656d36ff3a0896b6`；主仓保持 `ba29fc33d2f21a5f1bf0fe7eb9346e01f19a8645`。
- 独立分支：`codex/isar-sect-member-count-049-20260907`；复用已有隔离 worktree `/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠`，分诊分支的原提交保持可追踪。
- 代码提交：`5e0fb071a23780ba31752a1d6a9bc550b704273f`，提交说明「修复门派旧档负人数缓存并保留异常诊断」。本报告与进度摘要在代码验证后补交。
- saveVersion 从 `0.48.0` 升为 `0.49.0`，新增段 19。已升级到 0.48 的旧库也必须进入此次修复；未修改生产 collection/embedded schema、数值 YAML 或依赖版本。
- 已实现不等于已应用到玩家存档：本轮只在隔离测试库验证和构建，未打开/迁移实际玩家存档、未替换正在使用的应用，未合 main、未 push。

## 实际行为与生产入口

入口为 [lib/data/isar_setup.dart:277](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/data/isar_setup.dart:277)。旧版本在同一写事务内执行已批准修复和版本更新；相同版本重开只重试此项负计数修复，不重跑旧业务迁移。高版本存档在进入修复前仍拒绝打开。

修复在 [lib/data/sect_member_count_repair.dart:39](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/data/sect_member_count_repair.dart:39)：

| 核对项 | 实装规则 |
|---|---|
| 候选行 | 只处理 `memberCount < 0`，包括真实缺字段的 minLong 和先前招收形成的 minLong+k |
| 非负值 | 所有非负缓存原样保留，不做全仓人数重算 |
| 门派身份 | 仅默认 `Sect.id == 1`；其他门派的负计数保留并列 `unsupportedSectIdentity` |
| founder 身份 | `Character[sect.founderId]` 存在、`isFounder == true`，且 `SaveData.founderCharacterId == Sect.founderId` |
| founder 关联 | 可正常未入派（旗标 false、sectId/rank 都 null）；若关联另一门派则拒绝推断 |
| 成员关系 | 目标门派成员须 `isInSect == true`、`sectId` 匹配且 `sectRank != null`；已知外派成员不计入 |
| 不明归属 | 有入派/阶位信息却没有 sectId、或 sectId 指向不存在门派，保留异常计数并记录角色 ID |
| 计数方式 | 统计一致关联中的角色，只排除当前 exact founder ID；死亡、退隐、非 active、旧祖师或 disciple 角色身份均不额外过滤 |
| 冲突处理 | 任一相关身份/关系检查不通过，该行不写入；不删除门派、角色，不改旗标/外键/阶位 |

本轮复核真实生产写路后确认：`LineageMember` 只存在于 Sect 的旧注释，当前没有该类或 Isar 集合，未据此创建虚构映射。初代 onboarding 写角色 1、founder 标记及 SaveData 指针；继任时 AscendService 同事务设置新标记、SaveData 指针和已有 Sect 指针。旧祖师仍可保留 `isFounder=true`，继任者可保留 `lineageRole=disciple`，因此必须用 exact 指针排除当前 founder。

身份依据：[lib/features/onboarding/application/onboarding_service.dart:97](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/features/onboarding/application/onboarding_service.dart:97)、[lib/features/onboarding/application/onboarding_service.dart:146](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/features/onboarding/application/onboarding_service.dart:146)、[lib/features/ascension/application/ascend_service.dart:287](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/features/ascension/application/ascend_service.dart:287) 与同文件 297/312 行。三个生产 Sect lazy-init 当前均使用默认 id/founderId=1，未读当前掌门指针；若延迟到传位后才建派而形成不一致，本轮保守留存诊断，没有顺手改创建/传位语义。

## 未解决行的诊断与招收保护

[lib/data/isar_setup.dart:87](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/data/isar_setup.dart:87) 的 `IsarSetup.sectMemberCountRepairIssues` 提供当前打开槽的不可变问题列表：每项含 sectId、相关 characterId（有则填）及 reason。只在整个写事务成功后发布；有异常时每次打开打印一条聚合诊断。关闭、失败清理及测试 reset 会清除，切槽不会沿用另一槽诊断。下次打开会重新检查；外部明确修正关系后可重试，而非因版本已升就永远跳过。

招收在 [lib/features/sect/application/sect_member_service.dart:46](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/features/sect/application/sect_member_service.dart:46) 先拒绝负计数并返回 `RecruitResult.invalidMemberCount`，避免继续绕过 cap 或污染计数。[lib/features/sect/application/sect_recruit_transaction_service.dart:94](/Users/a10506/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠/lib/features/sect/application/sect_recruit_transaction_service.dart:94) 将其交给已有异常分支抛错；caller 写事务回滚已写内容和新候选，不将异常伪装成满员并兑换 fallback 奖励。pending affair 的 applyInTxn 成功后才记录 claim，代码审阅确认抛错不会消费待办；新增真实 Isar 事务用例验证前置写入和候选创建一起回滚。旧招收 flow 的失败清理路径仍保留。

没有新增 UI。留存冲突行的原数值仍可能被既有界面展示；它们不能继续通过招收入口使用负数计数。诊断用来定位待核对行，本轮没有猜填这些行。

## 修改边界

- D 单的 62 个静态归位项、归位逻辑及旧迁移段 1–18 原样保留；旧迁移主体已逐字比对一致。
- 两张登记表仍为数值 56 + 非数值 5 = 61 项，键及顺序不变；只将 `Sect.memberCount` 理由更新为“1A 已批准，由 0.49 条件修复，冲突留存”。历史分档仍为 A 60 / B 1 / C 0，修复不会改写字段引入历史。
- 其余 14 个可疑默认值及所有实体声明均未改；无身份推断写回，无 cap/奖励/境界数值改动。
- 新增 21 个缓存修复测试及 1 个既有招收事务文件中的回滚测试。9 个既有测试文件只更新 13 处“当前版本”断言为 0.49，输入旧版本和业务断言不变；未放宽理由文本或业务守卫。
- `build.yaml` 仅增加一个旧 schema fixture 的生成入口；生成的 `.g.dart` 不提交。未修改 AGENTS.md、CLAUDE.md、data/*.yaml。

边界证据：[scope-proof.json](/Users/a10506/Documents/Codex/2026-09-07/isar-sect-member-count-049/scope-proof.json)；源文件哈希：[implementation_hashes.json](/Users/a10506/Documents/Codex/2026-09-07/isar-sect-member-count-049/implementation_hashes.json)。

## 直接回归与失败记录

真实 RED（接线前）保留原始日志：

```text
缺字段旧库经 init 后：Expected <2>, Actual <-9223372036854775808>
负数招收事务：Expected throws StateError, Actual Future emitted null
```

分别见 [red-missing-property.log](/Users/a10506/Documents/Codex/2026-09-07/isar-sect-member-count-049/red-missing-property.log) / [red-recruit.log](/Users/a10506/Documents/Codex/2026-09-07/isar-sect-member-count-049/red-recruit.log)。缺字段 fixture 用真实 `@Name('Sect')` 旧 collection 省略 memberCount，SaveData 与 Character 使用真实 schema 以隔离本字段；先验证当前 schema 原始读取确为 minLong，再经生产 init 修复、关闭、重开。没有用手设 minLong 替代缺字段证明；另有已落库 minLong+k 的污染测试。

首轮修复相关测试为 25 PASS / 1 FAIL，失败是新增测试用 UTC DateTime 对象直接匹配 Isar 回读本地 DateTime；改为预期 `.toLocal()`，仍严格核对持久时间。没有因此修改生产逻辑或放宽业务断言。原日志：[green-repair.log](/Users/a10506/Documents/Codex/2026-09-07/isar-sect-member-count-049/green-repair.log)。

扩大回归 **19/19 文件，195 PASS / 0 FAIL / 0 SKIP**，核对无漏文件。覆盖新 21 项、招收事务、成员服务、传位、0.48 缺字段守卫、历史迁移门、存档恢复和跨槽，以及塔旧档通关。结果来自提交前同内容工作树；提交后完整套件再次覆盖这些文件。完整命令及文件清单：[targeted-summary.json](/Users/a10506/Documents/Codex/2026-09-07/isar-sect-member-count-049/targeted-summary.json)，原始输出：[targeted.log](/Users/a10506/Documents/Codex/2026-09-07/isar-sect-member-count-049/targeted.log)。

独立只读审查检查了 founder 真实写路、修复谓词、事务发布时机、同版本重试、forward-save 拒绝和 pending affair 异常回滚路径，未发现阻塞；主窗口另核对实际 diff 和生产消费方。审查结论不替代以下测试结果。

## 五项完整验证

均在代码提交 `5e0fb071a23780ba31752a1d6a9bc550b704273f` 执行；后续只补报告及进度文档。全量遵守既有共享锁 `/Users/a10506/.claude/locks/wuxia_full_test.lock`，不删除或抢占；macOS 构建未设置 `DEVELOPER_DIR`。

### 1. `dart run build_runner build --delete-conflicting-outputs`

退出码 0；开始 `2026-09-07T21:58:20.261776+08:00`，结束 `2026-09-07T21:58:35.040474+08:00`。

```text
  0s source_gen:combining_builder on 1609 inputs; lib/core/application/character_providers.dart
  0s source_gen:combining_builder on 1609 inputs: 1578 skipped, 31 same
  Built with build_runner/aot in 4s; wrote 62 outputs.
```

完整输出：[build-runner.log](/Users/a10506/Documents/Codex/2026-09-07/isar-sect-member-count-049/build-runner.log)。

### 2. `flutter analyze`

退出码 0；开始 `2026-09-07T21:58:35.040902+08:00`，结束 `2026-09-07T21:59:19.156546+08:00`。

```text
Analyzing 挂机武侠...
No issues found! (ran in 5.1s)
```

完整输出：[analyze.log](/Users/a10506/Documents/Codex/2026-09-07/isar-sect-member-count-049/analyze.log)。

### 3. `flutter test --no-pub --machine`

退出码 0；开始 `2026-09-07T21:59:19.192081+08:00`，结束 `2026-09-07T22:08:00.737100+08:00`。

```text
{"success":true,"type":"done","time":519950}
```

原始 machine 事件统计：**6307 PASS / 0 FAIL / 0 SKIP，900/900 文件，漏跑 0**。相对 D/E 单的 6285 项与 899 文件，准确增加 22 项、1 个测试文件。

完整输出：[full-test.log](/Users/a10506/Documents/Codex/2026-09-07/isar-sect-member-count-049/full-test.log)。

### 4. `dart format .`

退出码 0；开始 `2026-09-07T22:08:00.813869+08:00`，结束 `2026-09-07T22:08:08.150285+08:00`。

```text
Formatted 1775 files (0 changed) in 5.42 seconds.
```

完整输出：[format.log](/Users/a10506/Documents/Codex/2026-09-07/isar-sect-member-count-049/format.log)。

### 5. `flutter build macos`

退出码 0；开始 `2026-09-07T22:08:08.153137+08:00`，结束 `2026-09-07T22:09:02.348211+08:00`。

```text
Try `flutter pub outdated` for more information.
Building macOS application...
✓ Built build/macos/Build/Products/Release/wuxia_idle.app (177.3MB)
```

完整输出：[macos-build.log](/Users/a10506/Documents/Codex/2026-09-07/isar-sect-member-count-049/macos-build.log)。

## 最终边界

最终主仓 HEAD、既有用户文件 SHA256、候选 clean 状态、代码/文档分离和检查结果见 [delivery.json](/Users/a10506/Documents/Codex/2026-09-07/isar-sect-member-count-049/delivery.json)。原始完整验证记录：[validation-results.json](/Users/a10506/Documents/Codex/2026-09-07/isar-sect-member-count-049/validation-results.json)。

本轮交付独立工程候选，没有合 main、push、部署或迁移实际玩家存档；不代签远端 CI、Windows 或真人验收。无法证明身份/关联的负计数行按批准方案继续保留，需依据诊断核对后重开重试。

## 2026-09-08 main 集成验证（后续授权）

用户在核查合并与 push 条件后回复「按建议顺序执行」，授权快进合并、main 集成验证和普通 push，范围包含远端之后原有的 16 个提交。main 已从 `ba29fc33d2f21a5f1bf0fe7eb9346e01f19a8645` 快进至 `df3be136515b423300ad81f3ecafbd6ed300ef41`，没有生成合并提交；此后仅补本节及 PROGRESS 集成摘要，推送共 17 个提交。

本次全部在主仓 `/Users/a10506/Desktop/Projects/挂机武侠` 的 `df3be1365` 执行。生成前置及集成检查依次为：

| 命令 | 实测结果 |
|---|---|
| `dart run build_runner build --delete-conflicting-outputs` | exit 0；5s，146 outputs |
| `flutter analyze` | exit 0；No issues found，11.7s |
| `flutter test --no-pub --machine` 加相关文件清单 | exit 0；19/19 文件，195 PASS / 0 FAIL / 0 SKIP |
| `flutter test --no-pub --machine` | exit 0；900/900 文件，6307 PASS / 0 FAIL / 0 SKIP，漏跑 0 |

全量开始 `2026-09-08T09:33:03.398946+08:00`，结束 `2026-09-08T09:39:20.604755+08:00`；正常等待并使用既有共享锁，未删除或抢占。生成文件仍被忽略，未提交。源码与上一轮五项验证时的 18 个文件 SHA256 全部一致；本次按集成规则重跑 analyze、相关测试和全量，候选的 format/macOS release 证据仍见上文，没有伪称本轮重跑。

主仓原有 AGENTS.md、CLAUDE.md、.qoder/settings.json 及冻结归档文件的内容哈希均未变化；未提交、还原或删除它们。独立分支与 worktree 保留。此次仅集成与推送代码，没有打开/迁移玩家存档或更新运行中的应用。

本节提交前所有本地集成检查已通过，尚未以未来结果宣称 push 或远端 CI 成功；最终远端 SHA、推送结果及 CI 状态由 [delivery.json](/Users/a10506/Documents/Codex/2026-09-08/isar-049-main-integration/delivery.json) 实测记录。完整命令和各文件执行清单见 [integration-results.json](/Users/a10506/Documents/Codex/2026-09-08/isar-049-main-integration/integration-results.json)，原始输出见同目录 `merge.log`、`build-runner.log`、`analyze.log`、`targeted.log`、`full-test.log`。远端 CI、真人及 Windows 验收分别记录，不相互替代。
