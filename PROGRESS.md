# 挂机武侠 · 开发进度
> Mac 端 Claude Code 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。
> **当前阶段：1.0 长线打磨期（质量优先 · 不设上线时间压力）** — Demo ✅(2026-05) → 1.0 内容周期 ✅(P1-P5+) → 打磨中。阶段一变只改本行；工作原则见 CLAUDE.md §7。
## 当前阶段
- **2026-09-15 当前候选**：`codex/p2-player-flow-20260910` 代码 `5c1105cfa`，已由 `e743b6026` 纯 fast-forward；main 仍 `342d19275`。正式 M0–M9 仍 **1/10（仅 M1）**。
- **原生候选复验（本次实测）**：并发完整 `flutter test --no-pub` 942 文件 / 6756 PASS、0 失败/跳过/遗漏，终止 done.success=true，退出 0，墙钟 1041.843s；format 0 changed、analyze 0 issue。原生退出 5/5；exact Profile 独立工程新档正常进入主菜单与真实第一关，设置面板就绪，原生窗口关闭后进程退出 0（162.326s）；未触碰真实存档。证据 `/Users/a10506/Documents/Codex/2026-09-15/p2-onboarding-chain/batch1/summary.md`。
- **新档连续链（2026-09-15 本次实测）**：候选 `codex/p2-onboarding-chain-20260915` 代码 `c4aa90f7e`；合法刚猛 / mountain_wanderer / balanced_seed，创建 seed=20260820、战斗 seed=20260906。01 胜 243 拍/余 HP 2234/25 杀，02 胜 202 拍/余 HP 2126/15 杀，03 败 118 拍/HP 0/4 杀；均 maxHp=4000、装备攻击=174，可见敌人峰值 10/10/12。真实经验 0→5→10、装备战斗次数 0→1→2、tutorialStep 0→1→2、journal prepared/loadoutVersion 1→2→3 已断言；04/05 未进入。
- **操作容错（同一入场副本）**：A/B/C/D=风筝/粗放/每3拍决策/仅J站桩；01 结果 胜/败/败/败、拍数 243/48/110/48；02 结果 胜/败/败/败、拍数 171/52/83/48。八次入场与连续链进度/属性逐字段相同，副本独立且同 seed；每次重置随机流，故 A 重开数据与原连续流分开。仅本配置诊断，不代表全部开局或真人验收。
- **续跑补充诊断（2026-09-16）**：灵巧 / escort_apprentice 第二开局在同固定种子下 01/02 胜 224/83 拍、黑风岭败 189 拍，04/05 未进入。原刚猛配置 E（风筝每 3 拍，复跑旧 C）两关败 110/83 拍；F（风筝不按空格）01 胜 236 拍、02 败 89 拍，空格事件均 0。E/F 同旧 A 入场、封存副本哈希不变；原 A–D 八局结果与逐拍曲线未变；仅固定配置自动诊断，真人验收仍缺。
- **本批验证与续跑（2026-09-16）**：修正本批 2c 文案变更漏更新的列表断言，列表/情报测试共用 `UiStrings.stageCatalogEnemySummary`，不是既有回归。列表 16/16、情报目录 81/81，首次批末全量 946/946 文件、6769 PASS / 0 FAIL、done.success=true、退出 0、461.084s。补充诊断后定向 7/7，最终全量 948/948 文件、6771 PASS / 0 FAIL、0 跳过/遗漏，done.success=true、退出 0，08:07:37–08:16:10 CST、512.891s；format 0 changed、analyze 0 issue。证据 `/Users/a10506/Documents/Codex/2026-09-15/p2-onboarding-chain/batch2/summary.md`。
- **CI 已恢复**：修复 Linux 坏档异常分类、主线加载等待/失败清理、护送重试退场等待。exact-SHA CI `34747336113` success，921 文件 / 6574 PASS，0 失败/跳过，analyze、format、macOS build 全绿，覆盖率 86.39% ≥ 81.25%。本地全量 6574 PASS 属于前候选 `76144e458`；最终纯测试修正另跑主线 24 文件 / 204 PASS，不混写 SHA。
- **原生副本续验**：用户“按推荐执行”后，唯一包名/完整路径识别成功，0.49 副本真实进主页、领取归来卡并正常退出；七个原档/备份保持事故保全后哈希。全字段核对发现战备刷新覆盖收益账本，另有主页启动链未写解锁基线；均已测试复现，正在同一候选修复，尚不能记迁移 PASS。历史误启事故：slot 1 已证明事故前后逻辑无差异，slot 2/3 仍缺事故前精确备份，保持现状不回滚。
- **前三阻塞与下一步**：①第一章新档连续推进与操作容错证据不足；②密集战斗帧耗仍超标，M4 未关闭；③同冻结版真人/Windows证据与剩余塔/legacy退役未齐，M8/M9依赖未满足。用户4个原有文件保留；未合并/推送 main，正式 M0–M9 仍 1/10。
  - 本配置实测：01_01/01_02 风筝可通；合法刚猛 / mountain_wanderer / balanced_seed，创建 seed=20260820、战斗 seed=20260906。
  - 01_03 黑风岭固定种子连续链胜率 0/1，118 拍败；04/05 未进入。
  - 粗放/慢反应（每 3 拍决策）/站桩三变体在 01_01、01_02 全败；自动诊断不代签真人验收。
- **恢复点与证据**：`docs/superpowers/plans/2026-09-05-mainline-ci-wait-investigation.md`；CI/测试/原生包及事故现场 `/Users/a10506/Documents/Codex/2026-09-13/p2-ci-recovery/`，本次续验在 `resume-native/`。原生意外后已停线保全，现仅在明确授权的副本范围恢复。
### 历史集成记录（以下为当时状态）
- **2026-09-07 存档清查前置集成**：B 配置严格校验与 C 断魂庄种子/架势写回已在候选 `5b20a154f` 合并，存档版本 `0.47.0`；完整 analyze 0 issue、定向 14 文件 142/142、全量 895 文件 6200/6200、format 1663 文件 0 改动、macOS release 构建通过。原始证据：`/Users/a10506/Documents/Codex/2026-09-07/isar-prerequisites-integration/`。玩家架势尚未生产启用；不代签真人/Windows，不变更正式里程碑。`0.48.0` 后续集成见下一条。
- **2026-09-07 Isar 缺字段归位前置集成**：D 单 `ecc75dba9` 在合并候选 `547db1c43` 集成，版本 `0.48.0`、归位文件存在；该 exact SHA 重新通过 build_runner、analyze 0 issue、定向 13 文件 115/115、全量 899 文件 6285/6285（无遗漏）、format 1771 文件 0 改动、macOS release。随后仅更新记录并纳入本地 main。62 个静态数值归位逻辑原样保留，该次集成时待决字段的考古与菜单尚未开展；本轮独立分诊见下一条。主仓用户文件保留，不 push、不代签 CI/Windows/真人或正式里程碑。完整证据：`docs/audit/isar_missing_fields_2026-09-07.md` 文末与 `/Users/a10506/Documents/Codex/2026-09-07/isar-d-integration/`。
- **2026-09-07 Isar 待决字段分诊候选**：独立分支 `codex/isar-deferred-triage-20260907`，代码 `5f60279e6`；两张登记表实测 61 项，A 60 / B 1 / C 0。唯一 B 为 `Sect.memberCount`，15 个可疑初始化器均有菜单（14 A + 1 B）；用户已批准 1A，实装见下一条。两表仅改理由，不删条目、不改归位/迁移，版本保持 `0.48.0`。build_runner、analyze 0 issue、覆盖守卫 4/4、全量 899 文件 6285/6285、format 1771 文件 0 改动、macOS release 均通过；未合 main、未 push。完整双 SHA 清单、菜单及真实日志见 `docs/audit/isar_deferred_field_triage_2026-09-07.md`。
- **2026-09-08 Isar 分诊与门派人数修复 main 集成（已批准 1A）**：main 快进至 `df3be1365`（修复代码 `5e0fb071a`），版本 `0.49.0`；启动时核实当前 founder 与成员关联后重建负计数，冲突留存诊断并重开重试，招收拒绝异常负数。其他 14 项默认、62 项静态归位与旧迁移不变。本次 main 重新通过 build_runner、analyze 0 issue、定向 19 文件 195/195、全量 900 文件 6307/6307（无失败、跳过或漏跑）；源码哈希与已验证候选一致，用户文件原样保留。用户已授权普通 push，远端 SHA/CI 实测见 `/Users/a10506/Documents/Codex/2026-09-08/isar-049-main-integration/delivery.json`；未部署或迁移玩家存档，不代签真人/Windows。完整边界与两轮验证见 `docs/audit/isar_sect_member_count_repair_2026-09-07.md`。
### 历史二阶段结果仪表盘（2026-09-06 当时状态）
- **正式里程碑**：M0–M9 固定分母 10，仅 M1 关闭，仍 `1/10`；不把代码修复、压力夹具或 CI 启动代签真人/Windows。
- **已完成**：此前边界、鼠标两秒持续普攻、Boss 接敌、首胜 Next 修复保留；本批 Bot 射程内站定瞄准，真实音频池防并发准备/异步释放竞态并复用素材，四类战斗宿主接入减少闪光设置。数值、奖励、解锁、schema、依赖均未改变。
- **已验证**：统一代码 `57f95bc7f`；合法冷档五武器×三战术 15 局均进入终局，原暗器 300 秒停滞变为 30.8 秒/40 杀 victory。真实 Boss 命中开关对照在 1280×720/1440×900 通过，伤害/位置一致；音频目录 35/35。首轮定向 106/106、analyze 0 issue；完整首轮 6091 PASS / 1 旧夹具 FAIL，修正后相关 20/20。完整全量及精确集成 CI 以同版本 `delivery.json` 和远端记录为准，失败与复跑均保留。
- **平台与视听**：macOS 带声十分钟 48,651 帧，RSS 285→320 MiB、峰值 328 MiB、原生音频告警 0，内存门通过；两个常规视口都有原生画面与运行时 settings 证据。Windows `34014731726` 同代码 unsigned build + 原生启动 PASS（16.07 秒）。
- **已知风险**：密集场景帧耗仍未达标（1280 带声短测 p99 62.979ms，静音 36.061ms；1440 带声 91.681ms），不关闭 M4。真人五武器手感、Boss 学习性、全模式 UI、物理 Windows 键鼠/音频/GPU、72h 仍未齐。
- **工程水位与依赖**：主线 typed `105/105`，塔 `0/49`、五处 legacy 接缝；塔错误目标反例仍先补约束后迁层。M0 timeline/Qi 接线及心魔逐身份、M4 两个专属音效、M8 长离线与 M9 冻结保持开放，不扩塔层。
- **下步顺序**：先定位密集帧耗，再补同冻结版本的自然人体验证据；原生音频悬挂和减少闪光不再重复立项。
- **版本、成本与数据**：13:20 CST 开始，以墙钟计、90 分钟检查点；候选在独立分支，最终集成记录见审计。生产原档三文件哈希一致，试玩退出后冷备份存档/设置，准备更新程序并保留当前进度；无待重新拍板的产品决策。
- **详细证据**：`docs/audit/phase2_blocker_fixes_2026-09-06.md`；原始日志、原生包、备份及最终交付记录位于 `/Users/a10506/Documents/Codex/2026-09-06/wuxia-blocker-fixes/`。前轮完整阻塞矩阵见 `docs/audit/phase2_blocker_verification_2026-09-06.md`，历史证据不回填当前正式 PASS。

## 已知偏差 / 挂账事项
- **任务储备总账 → 根目录 `BACKLOG.md`**(2026-07-19 建账):待拍板/已解锁可派/依赖锁死/方向级四段,每批收账随 PROGRESS 同步更新;原开放挂账(Riverpod TickerMode 断言)已迁其 §三。
> 已销账条目(#1-#45)详见末尾归档。**P1 阶段全销账 ✅** + **Demo §8.4 14/14 全达标 ✅** + **1.0 ~95% release ready ✅**(A+B+C 全 PASS · 剩 D-G 留 M15-16)。
## 关键约束(每次开局必读)
- 数值硬红线(配置基础表值·schema 拦截):装备基础攻击 ≤2000 / 玩家血 ≤20000 / 内力 ≤15000 / Boss 血 ≤60000(GDD §5.4)
- 数值软红线(极值满 build 实战可见值·保可读):核心唯一线=不进百万膨胀(普攻真实峰值~13.5万 / 大招~21万,均六位可读)
- 不硬编码数值/文案(走 numbers.yaml / data/narratives, lore, events)
- Riverpod 状态管理;Isar 本地存储;data/ asset 根
- 不动 GDD.md / CLAUDE.md / numbers.yaml / data_schema.md / IDS_REGISTRY.md(数值/规则层 · 改前 ask)
- Mac 端写 lib/、data/(顶层)、test/、文案(v1.8 起 DeepSeek 退役)
## 远程仓库
- GitHub:https://github.com/Zed1118/wuxia_idle · 主分支 main
- 协作:Mac 单端代码+数值+文案;视觉验收 Mac 本地 Codex(Pen Windows AI 工具 2026-06-11 已下线)
## 归档
### 当前阶段旧条目(逆时序 · 从上方迁入;标「已压缩归档」的为摘要,全文见 git 历史)
> **2026-07-20..23 九批已压缩归档并入(Ch14/Ch15 spec 起草拍板七项+八项全兑现于 PR #64/#67 / Ch14 整章 PR #64 `8cf1d168` 4652/0+美术 #65 `79aeea4e` 终判 11/11 PASS·绝顶段第二章全链闭环 / 日批五 PR #55-#59 4647/0 / kimi 三单 #60-#62+Ch13 美术 #61 4651/0 / 清账 #63 Ch13 webp / 夜批六 PR #49-#54 4626/0+mount_deferred A2+B1 拍定 / Ch10「中州」`8be841d0`/Ch11「名门之虚」`758a2637`+11 立绘/Ch12「名下之实」一流三章收官 / kimi 红线区考核首单 `591fb81b` / Ch9 立绘接线 PR #44 `01dae889`+kimi 测试硬化 `7cdd9e23`+4A 死字段清理 `0bc59ed5`)**:git log + PR #44-#67 body 可溯,均合 main;当时已知风险均由后续批销账。
> **2026-08-04 批 A · A0 解爬塔层数硬编码已压缩归档(PR #114 merge `e36884f9`)**:范围 Phase 0 由 3 处修正为 11 处生产行为点(validator 启动崩 + isFirstClear 静默卡 30 两处比 plan 更硬);`GameRepository.towerMaxFloor` 唯一派生点+注入式 maxFloor;破坏证红 5 轮逐处对应;守卫缺口经非 30 fixture 常驻化;codegraph「未初始化」证伪(worktree 里查所致,索引在主 checkout,V8 OOM 加 NODE_OPTIONS 重建)。全量 4813/0。详 git log + PR #114 body。
> **2026-07-24..25 宗师段(Ch16-18)spec 拍板冻结 + Ch16「凉州词」两批已压缩归档(spec `f8d52ae4`·main 直落·BACKLOG §一#9 销账 / 整章实装 PR #71 `a5d6ddba` / 美术 11 图接线 PR #72 `27b6d96d`)**:git log + `docs/spec/2026-07-24-zongshi-arc-ch16-18-design.md`(92 行·段级六项+Ch16 章级六项拍板全文)+ 各 PR body 可溯,均已合 main;宗师段首章全链闭环(5 关 stage_16_01..05·敌招零新增复用失传神功心法 9 门·真解「铁马冰河」·cap 35→38 cross-tier·16_05 相位 unlockSkillIds 主线首用·叙事 13 篇·~30 站点 reconcile·11 图接线+known_missing 清零),当时已知风险(11 图缺图 / 17M 待转码)已由 PR #77 销账。**仍在账**:① idle_horizon **s1 45.6 天/下沿 45 贴线**(Ch17 扩缺口必破须重校);② 16_05 相位配法与 Ch16 立绘真机战斗屏均未目检;③ Ch17/Ch18 章级细化未起(spec §8 前瞻已定向:cap 38→40→42·Ch17 末 Boss vulnerability 0.20 教学·Ch18 章中+末 0.12 全机制·真解 Ch17 新写 / Ch18 收编 `yang_guan`)。
