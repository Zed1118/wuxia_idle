# 任务储备总账(唯一正向储备)

> 反向储备(拍死不做·防重提)见 `docs/spec/rejected_task_registry.md`,规划新任务前两份都读。
> **准入三态**:待拍板 / 已解锁未做 / 依赖锁死——「本次没空做」不准进(CLAUDE §7 打磨期原则)。
> **维护**:每批收账随 PROGRESS 同步更新;销账即删行(git 留历史);总行数 ≤80。
> 2026-07-19 建账:散落储备(PROGRESS 挂账段 / playability_phase2_backlog / 两份 audit followup)已归纳至此,旧文件原地归档留指针。
> 2026-08-22 最新收口事实：Phase 0A 已补齐 guardian ward/拦截/合击、surviveTicks、Boss 蓄力/破招/脆弱窗口表现及高周目 cycleVulnerability；塔 49 层 live 消费面与扫荡 headless 直结均已建立默认关闭的单祖师灰度纵切，neutral settlement 接回原塔/主线重打结算，超时、退出、活动占用与替补污染均有 Gate。预检 **149/149 eligible、0 skipped、447 runs/0 timeout/maxDamage 2044**，最终全量 **5383/0**。正式默认入口仍关闭；六人/Windows Gate 与远征/断魂庄单主角续传仍为路线 C 依赖。

## 一 · 待拍板(拍一个解锁一个)

| # | 项 | 域/性质 | 拍板点 |
|---|---|---|---|
| 19 | **资质视觉档位化**(2026-08-08 defer;2026-08-11 随 #15/#16 实装销账时**单独立行**) | 玩家可见 UI · 观感 | 现状:档案页资质 chip 六档共用一个灰底标签、档位差异只靠档名文字(`lineage_character_detail_screen.dart:303` 自注「视觉表现为临时版」)。可选表达:色阶/印章/边框/底纹。**用户 2026-08-11 已拍板并入试玩局再定**。**2026-08-18 拍板:与 #4/#5/#6 及 Phase 0A 六人主观 Gate 合并同一试玩局**——一次拿旧数值裁决+新战斗主观数据 |
| 4 | 丹房强度 2B | 数值复核 | 已定「不动」,待真人试玩数据复核(2026-07-19 1A 批决议) |
| 5 | 残页集齐数量(真解1/残页5 默认) | 数值微调 | 实玩后可调(P1a §16#4 默认值) |
| 6 | 高熟练度难度微调候选 | 数值微调 | 波B 全表 sweep 读数在案,待真玩拍板 |

## 二 · 已解锁可派

（空——Phase 0A 护法近身标签错列打磨已于 2026-08-22 销账；git 历史可溯）

## 三 · 依赖锁死(附再开条件)

| # | 项 | 依赖/再开条件 |
|---|---|---|
| 1 | Riverpod `pausedActiveSubscriptionCount` debug 断言(低severity·框架bug·release 无感) | isar_community 支持 analyzer≥12 → 升 riverpod 3.3.2+ 真机验;详 memory `reference_riverpod_tickermode_pause_assert` |
| 2 | isar fork 供应链 / analyzer 三角(analyzer 钉 9.0.0 止血中) | 同上游条件,解锁后做一轮依赖维护批 |
| 3 | Flutter SDK 3.41.5→≥3.44 升级(解锁 audioplayers 6.8.x / 松 windows-2022 钉) | 2026-08-05 拍板暂缓(无需求驱动+isar fork 兼容风险与上行 #2 统一处理);再开条件=windows-2022 退役公告 / audioplayers 出本项目需要的修复 / #2 解锁开依赖维护批时**合并做**。要点存档(2026-08-01 实测):真闸门=audioplayers ≥6.8.0 要 Flutter ≥3.44(非 pubspec 约束);动作序列=升 SDK→pub upgrade→CMake 3.14→3.15 三处(`windows/CMakeLists.txt:2,11`+`windows/runner/CMakeLists.txt:1`)→CI 三处 flutter-version 钉(`ci.yml:36,78`/`windows-release.yml:35`)→`windows-release.yml:26` 放回 windows-latest→Windows release CI 实跑(唯一真证明);isar_community 对新 Dart 兼容须复核 |

## 四 · 方向级候选(大活·需专注会话+xhigh)

- **旧 3v3 → Phase 0A 单角色 ARPG 替换收口**(登记 2026-08-18,codex 派单域我只跟不派):**2026-08-19 §7.4 ADR 拍板路线 C 终态替换·前置排程**(终态拍板见 `docs/dispatch/packages/2026-08-16_phase0a_qoder_production_wiring_followup.md`;拆除范围事实底座 `docs/audit/legacy_3v3_removal_scope_2026-08-18.md`)。硬前提=0A 六人主观 Gate + Windows 实机过线(用户已拍暂挂)+ Phase 1 纵切成立 + 共享层安置/headless 结算内核替代先于表现层拆除。**4 子项已拍**(2026-08-19 同日调研拍板,全 α 推荐项):① headless 内核=**复用 0A reducer**② 65 路由=**删路由·证据原地标注**③ 共享层=**拆分迁移**④ 空窗=**原子切换·零空窗**。内容迁移 D1–D5 已拍：122 关/塔 49 全保留、远征/断魂庄单主角续传、扫荡 headless 直结、曲线继承+bot 胜率验收。**当前能力底座**=Phase 1 Ch1 全链、neutral snapshot、正式控制、Boss/guardian/survive/cycle 语义及 Ch2–Ch21+塔 **149/149** 预检均成立，塔 live 与扫荡 headless 两个默认关闭消费面已收口；**当前真实入口**仍仅 Ch1 一周目灰度门且默认关闭。下一工程序=远征/断魂庄单主角续传；正式替换仍锁六人 Gate/Windows Gate，且必须与旧入口拆除同批原子切换。
