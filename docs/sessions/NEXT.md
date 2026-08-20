# 新会话开局清单

> 更新时间：2026-08-20 · Codex 接管 Kimi/Qoder 两日工作后的审计终态
> 主线：`main` = `5d48794c` = `origin/main`
> 在途：`feat/phase1-vs-slice2-mainline-wiring-0820` tip `80d2ae61`（WIP，禁止合并）

## 当前结论

- 战斗终态不变：Phase 0A 单角色 ARPG 按路线 C 替换旧 3v3，不做双轨长期共存。
- 08-18～19 已合主线成果总体方向正确：Phase 0C 工程验收、路线 C 拍板、共享 RPG 层迁移、0A headless 内核、Phase 1 纵切规格与 Ch1 内容映射均可保留。
- 死链基线仍为 65（B 23 + D 42 的已接受残余），不是待机械清零任务。
- 最后一段主线接线只完成了可运行骨架，尚未完成真实结算闭环；已冻结在 WIP 分支并写恢复计划，不能按“Phase 1 纵切成立”收账。

## WIP 审计要点

恢复计划：`docs/superpowers/plans/2026-08-20-phase1-vs-slice2-takeover.md`

1. 0A 胜利后 `applyVictoryResolution` 仍读取旧 `battleProvider`，本场 0A 末态没有驱动奖励、统计与成长结算。
2. 灰度门当前放行全部主线关，超出已拍板的 Ch1 五关范围，也未约束周目。
3. live 固定步长仍写在 Dart，未与 headless 共用 YAML 真相源。
4. Ch1 五关缺 live/headless 的胜负 + 末态 HP 一致性测试，缺真实 Isar 奖励/进度/退出零污染 e2e。
5. 真实 roster 把所有敌人 `isElite` 置为 false，Ch1 Boss 视觉语义尚未钉住。
6. 已合的 `Phase0aStageContentMapper` 暂时依赖待退役的 `StageBattleSetup.buildEnemyTeam`；旧引擎拆除前必须把角色快照装配职责抽成新引擎可长期持有的中立层。

## 下一步任务（按依赖顺序）

### P0 · 完成 Phase 1 纵切切片 2

1. 红测“0A 本场真实末态必须驱动结算”，定义引擎无关结算输入；旧 3v3 与 0A 分别适配，禁止新入口伪读旧 provider。
2. 让主线宿主回传胜负、双方末态 HP、技能使用与统计，接通奖励、成长、进度保存。
3. 灰度门收窄到 `stage_01_01..05` 且一周目；补 Ch2、塔、空敌队、二周目反例。
4. 把 fixed delta 移入 `phase0a_arena` 强类型配置；复核开场真气、Boss/elite 视觉和周目参数语义。
5. 补真实 Isar e2e：胜利有奖励/进度，战败、放弃、系统返回均零污染。
6. 参数化跑 Ch1 五关 live/headless 同 seed，断言胜负与末态 HP 一致。
7. 跑 1280×720、1440×900 视觉 smoke 与帧时间验证，再做 targeted、analyze、全量并打 `[READY]`。

### P1 · Phase 1 成立后的迁移前置

1. 抽离 `StageBattleSetup` 中仍被 0A 需要的角色/敌人快照装配职责，解除新引擎对旧 3v3 application 层的反向依赖。
2. 用 headless 胜率画像校准 Ch1，再扩到 122 关；不以“全胜”冒充难度成立。
3. 依内容迁移 ADR 依次接远征、断魂庄托管与扫荡 headless 直结，分别保留原有奖励/续传语义。

### 依赖锁死 · 不提前开工

1. Phase 0A 六人主观 Gate：与 BACKLOG 一#19/#4/#5/#6 合并试玩局，需用户排期。
2. Windows 实机 Gate：正式生产替换前必须人工完成。
3. 路线 C 原子切换与旧 3v3/65 路由拆除：只在 Phase 1、六人 Gate、Windows Gate、headless 消费面迁移全部过线后执行，同次 merge 保持零空窗。
4. Phase 0B `MANUAL_RIG_PENDING`：人工美术工作，非当前工程会话任务。

## 验证快照

- WIP 接管后：`flutter analyze` 0 issue；全量 `flutter test --no-pub --reporter=compact` = 5197 pass / 0 fail。
- 两条截图遗留红已定位并修复：裸 `Random` 构造、Phase 0A 表现层中文诊断串。
- `python3 tools/doc_link_scan.py`：1312 个 md、8341 引用、dead 65（基线守恒）。
- 以上测试绿只表示代码门禁通过，不推翻“真实结算链未闭环”的 WIP 判定。
