# 任务储备总账(唯一正向储备)

> 反向储备(拍死不做·防重提)见 `docs/spec/rejected_task_registry.md`,规划新任务前两份都读。
> **准入三态**:待拍板 / 已解锁未做 / 依赖锁死——「本次没空做」不准进(CLAUDE §7 打磨期原则)。
> **维护**:每批收账随 PROGRESS 同步更新;销账即删行(git 留历史);总行数 ≤80。
> 2026-07-19 建账:散落储备(PROGRESS 挂账段 / playability_phase2_backlog / 两份 audit followup)已归纳至此,旧文件原地归档留指针。

## 一 · 待拍板(拍一个解锁一个)

| # | 项 | 域/性质 | 拍板点 |
|---|---|---|---|
| 3 | P2③ Boss 协同窗口 | 设计讨论 | 「敌方协同」新概念,先定范围再动(master spec §四) |
| 4 | 丹房强度 2B | 数值复核 | 已定「不动」,待真人试玩数据复核(2026-07-19 1A 批决议) |
| 5 | 残页集齐数量(真解1/残页5 默认) | 数值微调 | 实玩后可调(P1a §16#4 默认值) |
| 6 | 高熟练度难度微调候选 | 数值微调 | 波B 全表 sweep 读数在案,待真玩拍板 |
| 7 | CLAUDE §12.2 #5 归档行闭关单倍率表述 | no-touch 文档订正 | 1A 经验倍率拆分批后 stale,待版本订正窗口 |
| 8 | 生产 DefaultRng 无种子统一走 rngProvider(#57 遗留) | 生产接线 | 2026-07-22 拍板留议(非阻塞·stage_entry_flow.dart:826/:1040 两处直 new,全生产约 10 位点:tower×2/gauntlet_reward/recruitment/disciple_join/milestone_equipment/onboarding×2 等·2026-07-24 外审 triage 补记)。**2026-07-25 实证代价升级(不再是纯洁癖项)**::826 的裸 rng 一路传到稀有彩头 roll(`battle_resolution` → `drop_service.rollRareBonus`),彩头命中(cycle=1 时 5%+1.5%)即在固定掉落外追加 1 件装备,打翻 `sweep_settlement_test` 的 `equipmentDrops==1` 精确断言 → **CI 约 5-6.5% 跑次无故变红**(PR #55/#64/#72 三次「随机 fail」真身·PR #72 同 commit 重跑绿实证);因是生产 inline `new` 而非 provider,**测试 override 不到**。修法二选一:根因修(改读 rngProvider)/测试侧修(override numbersConfig 关 rare_bonus_drop 或断言改 ≥1)。详 memory `feedback_wuxia_sweep_rare_bonus_flaky_drop_count` |
| 11 | 既有场景素材的书法题字/印章是否触伪文字红线 | 设计拍板 | 2026-07-25 Ch16 美术批合成验证时发现:`assets/scenes/battle_frontier.png` 右上带书法题字+红印章,`battle_desert.png` 有小红印记(早期 MJ 素材遗留);CLAUDE §8.2/视觉验收规范禁「带伪文字 MJ 素材」。拍板点=是否判定为违红线 → 违则开清查小批(全 assets/scenes 扫一轮 + 重出或去字) |

## 二 · 已解锁可派

| # | 项 | 域 | 预估 | 依据 |
|---|---|---|---|---|
| 1 | battle-ui-v2 阶段 5(Windows 100%/125%/150% 缩放) | battle 表现层(原分支/worktree 已清,需新开载体) | 随批 | plan `2026-07-19-battle-ui-v2-85-fidelity-implementation.md` 既定末段;阶段5证据须留 repo 内非 gitignored 目录(外审 07-24 教训) |
| 2 | Ch17「沙海纵深」实装批(灵巧主题·末 Boss 单窗口 0.20 机制教学·feng_juan 收编+夜雨残页) | 主线内容 | xhigh 专会话 | spec `2026-07-24-zongshi-arc-ch16-18-design.md` §8 前瞻登记,章级细化随批终拍(Ch16 已于 2026-07-24 交付销账) |
| 3 | 中文散写 CI 自动门禁实装 | 工程门禁 | ~40-60min | 原 §一#10,**2026-07-25 用户拍定口径 A**:豁免①注释②诊断异常串(throw/assert/Error/Exception 参数)③debug 域(`lib/features/debug/`)④三集中 sink(`strings.dart`/`enum_localizations.dart`/`battle_log.dart`),门禁只管 presentation/domain 里玩家可见的 UI 文案散写。**实装面实测(2026-07-25·非 10min 小活)**:口径 A 剔完仍剩 312 行行级误报,因诊断串多为**多行拼接的续行**(续行内无 throw 关键字)→ 行级正则做不出,须语句级/AST 扫描(analyzer 或「向前扫到上一个 `;`/`{`」启发式),比现有 `art_tone_audit.dart` 行级体例升一档。**批内待补拍**:`damage_calculator.dart` 的战报格式化片段(`'(凝甲,原…)'`/`'(弱点/抗性)'`)性质同 `battle_log.dart`,是否算第 4 合法 sink |

## 三 · 依赖锁死(附再开条件)

| # | 项 | 依赖/再开条件 |
|---|---|---|
| 1 | Riverpod `pausedActiveSubscriptionCount` debug 断言(低severity·框架bug·release 无感) | isar_community 支持 analyzer≥12 → 升 riverpod 3.3.2+ 真机验;详 memory `reference_riverpod_tickermode_pause_assert` |
| 2 | isar fork 供应链 / analyzer 三角(analyzer 钉 9.0.0 止血中) | 同上游条件,解锁后做一轮依赖维护批 |

## 四 · 方向级候选(大活·需专注会话+xhigh)

- **爬塔二流段 spec**——塔内容扩展另一轴
