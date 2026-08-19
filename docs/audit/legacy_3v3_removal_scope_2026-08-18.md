# 旧 3v3 拆除范围审计(N1)

> 日期:2026-08-18(夜批)
> 状态:`AUDIT_ONLY / DECISION_DEFERRED`
> 基线:`bb0f664d` 之上的 `audit/legacy-3v3-removal-scope-0818` 分支
> 上位:v2 方案 §7.4 存量三路线 / §15.2 剩余拍板项(⚠ 2026-08-19 注:v2 方案系 08-16~18 派单会话上下文产物,未归档入库;用户 2026-08-19 确认不识此档,按拍板处置为引用显式标注未归档;本报告的定量清点即为可核验事实底座)/ BACKLOG 四#1「旧 3v3 → Phase 0A
> 单角色 ARPG 替换收口」
> 性质:只读清点,零代码改动;所有数字为 grep/find 实测口径,复现命令见附录 A。

## 1. 为什么做这份清点

战斗终态已拍板(2026-08-18 B3 终裁):Phase 0A 单角色 ARPG **替换**旧 3v3,
不做两模式并存。但「替换」的拆除范围此前从未定量。§7.4 ADR(最迟 Phase 1
正式场景立项前必须拍)需要三路线的事实底座,本审计只提供事实,不做路线裁决。

## 2. 代码面清点(`lib/features/battle/`,不含 phase0a)

| 层 | 旧 3v3 文件数 | 对照:phase0a |
|---|---:|---:|
| domain(含 strategy/ 4 文件) | 18 | 7 |
| application | 8 | 7 |
| presentation(含 widgets/ 10 文件) | 45 | 9 |
| **合计 dart 文件** | **71** | **23** |
| **代码行(不含 .g.dart)** | **~21,900** | **~4,600** |

口径:`find lib/features/battle -name '*.dart' -not -path '*phase0a*'`。
mass_battle(群战)与 battle_record(战绩册)是独立 feature,不计入「旧 3v3」。

## 3. 消费方分类(battle 外的 78 个引用文件)

### 3.1 live 战斗入口(6 处 push `BattleScreen`)

| 入口 | 文件 |
|---|---|
| 主线 | `mainline/presentation/stage_entry_flow.dart:580` |
| 爬塔 | `tower/presentation/tower_entry_flow.dart:850` |
| 断魂庄 | `boss_gauntlet/presentation/gauntlet_entry_flow.dart:213` |
| 扫荡 | `sweep/presentation/sweep_screen.dart:138` |
| debug | `debug/presentation/battle_test_menu.dart:1480` |
| 视觉路由 | `debug/presentation/visual_route_host.dart:1682` |

### 3.2 headless 结算链(不经 BattleScreen 的引擎消费)

`expedition_battle_runner`/`expedition_combat`(远征)、`gauntlet_service`/
`gauntlet_controller`(断魂庄托管)、`mainline_progress_service`、`drop_service`、
`sweep_unit`/`sweep_settlement`。**挂机主循环(离线时长→资源)不经战斗引擎**;
`combat_progression_settlement_service` 仅被 stage/tower entry flow 的 live 结算消费。

### 3.3 共享 RPG 层(非 3v3 独占,拆除须重新安置)

| 模块 | 外部 import 数 | 性质 |
|---|---:|---|
| `enum_localizations.dart` | 57 | 全库枚举中文本地化集中层 |
| `battle_providers.dart` | 22 | Riverpod 战斗接线 |
| `derived_stats.dart` | 12 | 角色派生属性(ARPG 同样消费) |
| `battle_state.dart` | 12 | 战斗态(含 `audio_assets.dart` sfx 映射依赖) |
| `stage_battle_setup.dart` | 9 | 关卡→战斗装配 |
| `cycle_*`(realm_gate/trait_intel/selected_cycle) | 10+ | 周目语义,挂进度而非 3v3 |

### 3.4 路由层

`VisualRoute` enum 共 **137** 条验收路由:旧战斗相关 **65** 条(`battle_*` +
`mainline_first_clear_battle*`),phase0a 仅 **4** 条(playable + J/Q/R 静态反馈)。
旧战斗路由承载了大量已归档目检证据(docs/screenshots 等),拆路由 = 证据链处置问题。

## 4. 测试面

| 口径 | 数量 |
|---|---:|
| 引用旧战斗模块的测试文件(全 test/) | 215 |
| └ 触及引擎核心/表现层 | 180 |
| └ 仅共享层(enum/derived/cycle 等) | 35 |
| `test/features/battle/` 非 phase0a | 124 文件 |
| phase0a 测试 | 18 文件 |
| 相关测试代码行(含共享层) | ~63,000 |

引擎核心判定正则见附录 A;「共享层」测试随共享层安置去留,不随 3v3 拆除。

## 5. 内容数据与引擎的关系

`stages.yaml`(122 关)/`towers.yaml`(49 层)/`boss_gauntlets.yaml`/`skills.yaml`/
`techniques.yaml`/`equipment.yaml` 是**内容定义**,旧引擎只是消费者;
phase0a 生产层已证明新引擎可复用正式数值(正式伤害公式适配 Batch 已合)。
故「122 关/塔 49 去留」与「旧引擎去留」是**两个独立决策**,前者属 §7.4 内容
迁移 ADR,后者属本审计范围。`encounters.yaml` 是奇遇系统,与战斗引擎无关。

## 6. §7.4 三路线事实表(只列事实,不裁决)

| 路线 | 现状成本 | 拆除/迁移前提 | 已知风险 |
|---|---|---|---|
| A 保留兼容(双轨) | 维持 21.9k 行旧引擎 + 180 测试文件的持续维护 | 无 | v2 §15 已列「双轨失控」为高风险;每批内容都要双引擎适配 |
| B 分批改造 | 逐内容把 3v3 入口迁到 ARPG 引擎 | **ARPG 引擎需先有 headless 结算能力**(当前 0A 只有可玩 flow,扫荡/远征/断魂庄托管无结算内核可换) | 过渡期新旧混跑,回归面最大 |
| C 重做替换(用户 08-18 拍的终态方向) | 按本报告清单拆除 | ① 6 人 Gate + Windows 实机过线(已后置)② Phase 1 纵切成立 ③ 共享层重新安置 + headless 内核替代先于表现层拆除 | 拆除期旧内容暂不可玩,需拍「过渡期主线战斗空窗」处置 |

## 7. 拆除顺序约束(供 ADR 参考,非拍板)

若走 C:共享层(enum_localizations/derived_stats/cycle_*)与 headless 结算内核的
替代必须先于表现层拆除,否则远征/扫荡/断魂庄托管先断;表现层拆除以路由批为
单位(65 条),证据归档随批处置;domain 引擎最后删(测试面 180 文件同批清理)。

## 8. 移交(留早晨拍板)

1. §7.4 ADR 路线选择(A/B/C 及过渡期处置)——🔴 用户拍板项;
2. headless 结算内核替代方案(B/C 路线硬前提);
3. 65 条旧战斗路由与目检证据归档的处置口径;
4. 共享层重新安置的落点(留在 battle/domain 还是迁 shared)。

## 附录 A · 复现口径

```bash
# 代码面
find lib/features/battle -name '*.dart' -not -path '*phase0a*' | grep -c .
find lib/features/battle -name '*.dart' -not -path '*phase0a*' -not -name '*.g.dart' | xargs wc -l
# 外部引用(补相对路径口径)
grep -rlE "import '.*battle/(domain|application|presentation)/[^']*'" lib --include='*.dart' \
  | grep -v 'lib/features/battle/' | grep -vE 'battle_record|mass_battle'
# 引擎核心测试面
grep -rlE "battle/(domain/(battle_state|battle_ai|damage_calculator|battle_log|battle_diagnosis|battle_skill_utils|qi_cycle|auto_play_mode|top_damage_contributor|strategy/)|application/(battle_resolution|stage_battle_setup|combat_progression_settlement|post_combat_invalidation)|presentation/)" \
  test --include='*_test.dart' | grep -v phase0a | grep -vE 'mass_battle|battle_record'
# 路由
grep -E "^  [a-zA-Z0-9]+\(" lib/features/debug/application/visual_route.dart | grep -c .
```

局限:静态 grep 口径,未含字符串拼接的动态路由(如 `battle_audit_stage_01_01`
动态 id 按 3 条母路由计);mass_battle/battle_record 是否随终态调整属内容决策,
不在本审计范围。
