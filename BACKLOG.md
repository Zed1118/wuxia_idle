# 任务储备总账(唯一正向储备)

> 反向储备(拍死不做·防重提)见 `docs/spec/rejected_task_registry.md`,规划新任务前两份都读。
> **准入三态**:待拍板 / 已解锁未做 / 依赖锁死——「本次没空做」不准进(CLAUDE §7 打磨期原则)。
> **维护**:每批收账随 PROGRESS 同步更新;销账即删行(git 留历史);总行数 ≤80。
> 2026-07-19 建账:散落储备(PROGRESS 挂账段 / playability_phase2_backlog / 两份 audit followup)已归纳至此,旧文件原地归档留指针。

## 一 · 待拍板(拍一个解锁一个)

| # | 项 | 域/性质 | 拍板点 |
|---|---|---|---|
| 19 | **资质视觉档位化**(2026-08-08 defer;2026-08-11 随 #15/#16 实装销账时**单独立行**) | 玩家可见 UI · 观感 | 现状:档案页资质 chip 六档共用一个灰底标签、档位差异只靠档名文字(`lineage_character_detail_screen.dart:303` 自注「视觉表现为临时版」)。可选表达:色阶/印章/边框/底纹。**用户 2026-08-11 已拍板并入试玩局再定**。**2026-08-18 拍板:与 #4/#5/#6 及 Phase 0A 六人主观 Gate 合并同一试玩局**——一次拿旧数值裁决+新战斗主观数据 |
| 4 | 丹房强度 2B | 数值复核 | 已定「不动」,待真人试玩数据复核(2026-07-19 1A 批决议) |
| 5 | 残页集齐数量(真解1/残页5 默认) | 数值微调 | 实玩后可调(P1a §16#4 默认值) |
| 6 | 高熟练度难度微调候选 | 数值微调 | 波B 全表 sweep 读数在案,待真玩拍板 |

## 二 · 已解锁可派

（空——2026-08-18 二#7 B3 拍死删行:战斗终态=Phase 0A 单角色 ARPG 替换旧 3v3,旧屏调参项失去意义,全文见 git 历史）

## 三 · 依赖锁死(附再开条件)

| # | 项 | 依赖/再开条件 |
|---|---|---|
| 1 | Riverpod `pausedActiveSubscriptionCount` debug 断言(低severity·框架bug·release 无感) | isar_community 支持 analyzer≥12 → 升 riverpod 3.3.2+ 真机验;详 memory `reference_riverpod_tickermode_pause_assert` |
| 2 | isar fork 供应链 / analyzer 三角(analyzer 钉 9.0.0 止血中) | 同上游条件,解锁后做一轮依赖维护批 |
| 3 | Flutter SDK 3.41.5→≥3.44 升级(解锁 audioplayers 6.8.x / 松 windows-2022 钉) | 2026-08-05 拍板暂缓(无需求驱动+isar fork 兼容风险与上行 #2 统一处理);再开条件=windows-2022 退役公告 / audioplayers 出本项目需要的修复 / #2 解锁开依赖维护批时**合并做**。要点存档(2026-08-01 实测):真闸门=audioplayers ≥6.8.0 要 Flutter ≥3.44(非 pubspec 约束);动作序列=升 SDK→pub upgrade→CMake 3.14→3.15 三处(`windows/CMakeLists.txt:2,11`+`windows/runner/CMakeLists.txt:1`)→CI 三处 flutter-version 钉(`ci.yml:36,78`/`windows-release.yml:35`)→`windows-release.yml:26` 放回 windows-latest→Windows release CI 实跑(唯一真证明);isar_community 对新 Dart 兼容须复核 |

## 四 · 方向级候选(大活·需专注会话+xhigh)

- **旧 3v3 → Phase 0A 单角色 ARPG 替换收口**(登记 2026-08-18,codex 派单域我只跟不派):**2026-08-19 §7.4 ADR 拍板路线 C 终态替换·前置排程**(终态拍板见 `docs/dispatch/packages/2026-08-16_phase0a_qoder_production_wiring_followup.md`;拆除范围事实底座 `docs/audit/legacy_3v3_removal_scope_2026-08-18.md`)。硬前提=0A 六人主观 Gate + Windows 实机过线(用户已拍暂挂)+ Phase 1 纵切成立 + 共享层安置/headless 结算内核替代先于表现层拆除。**4 子项已拍**(2026-08-19 同日调研拍板,全 α 推荐项):① headless 内核=**复用 0A reducer**(补玩家 bot adapter+快进循环,headless 与可玩共用同一模拟核;远征/断魂庄队伍续传语义需随之重设计,绑内容迁移 ADR)② 65 路由=**删路由·证据原地标注**(enum 条目随表现层拆除批删,截图留原位,归档文档加「路由已删·证据为历史快照」标注)③ 共享层=**拆分迁移**(enum_localizations/derived_stats/cycle_* 迁 lib/shared,战斗专属件留 battle 随引擎删)④ 空窗=**原子切换·零空窗**(0A 主线接线批与旧入口拆除批同次 merge)。调研事实详 `docs/audit/legacy_3v3_removal_scope_2026-08-18.md` §8 拍板回声。另:122 关/塔 49 去留属内容迁移 ADR(独立决策);旧屏删后「第八阶段真机观感目检」随之定谳;GDD v1.26/CLAUDE v1.43 已加漂移指针,口径改写随执行批。**解锁件已拍板**(2026-08-19 用户全按推荐):Phase 1 纵切=主线 Ch1/竞技场形态先行/双跑口径胜负+末态 HP;内容迁移=D1 机械映射+γ 后置校准/D2 全保留/D3 单主角续传/D4 headless 直结,定稿 `docs/spec/2026-08-19-phase1-vertical-slice-draft-spec.md`+`2026-08-19-content-migration-adr-decision-sheet.md`,Phase 1 纵切实装已解锁。
