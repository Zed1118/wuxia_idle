# 挂机武侠 · 开发进度
> Mac 端 Claude Code 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。
> **当前阶段：1.0 长线打磨期（质量优先 · 不设上线时间压力）** — Demo ✅(2026-05) → 1.0 内容周期 ✅(P1-P5+) → 打磨中。阶段一变只改本行；工作原则见 CLAUDE.md §7。
## 当前阶段
### 二阶段结果仪表盘（2026-09-05 关卡预览修复已集成，精确 SHA 远端通过）
- **正式里程碑**：未加权 M0–M9 固定分母为 10，当前仅 M1 关闭，结果 `1/10`；权重未获批准，不报告成熟度百分比。
- **主线入口测试加固（2026-09-05 后续授权集成）**：候选 `e5a60292` 改为墙钟限时等待并补失败卸载；真实延迟反例证明旧等待会误报，但未证明首次 CI 的宿主缺失/十分钟超时根因。持锁全量 `6033/6033`、analyze 0 issue、format 1645/0 changed、测试契约 Gate PASS；生产源码与冻结 `13504129` 一致。精确 merge CI 与同包 M2 受托实机证据另见本任务收工记录；不代签真人/听感/Windows、不晋升正式门。过程与证据位置见 `docs/superpowers/plans/2026-09-05-mainline-ci-wait-investigation.md`。
- **精确代码集成证据**：Ch13 修复原候选 `21ad6e60` 的生产代码/数据/测试，在受检候选 `cb824b534e7b4ed9e59ef21379eae8ca5846df9a` 中保持完全一致，经 no-ff merge `261f2daf17e4357aaf12a04b86775dc64aa1164a` 进入 `origin/main`；merge exact-SHA CI `33935197099` 已核验 `completed/success`（测试、覆盖率门槛、macOS 构建通过）。PROGRESS 作为本批授权治理尾同步，不伪称被施工 Gate 覆盖。M0-R 真实候选 `eea54b970df647a77340bbbc4ea43fc1538a8678`；原主线与塔集成基线 `2d254abd` 的 CI `33901066970` 已成功。
- **工程门**：M3 五类单段普攻生产画像 `5/5`、P0 三项质量子门 `3/3` 已集成。主线 typed catalog 覆盖 `105/105`；Ch13 身份/技能、数值保真、知客僧后置入场三类修复已进入 main，不把目录满额外推为整个主线真人验收完成。塔基础门已集成，目标限制、三入口行为验证及完整 parity 尚待补强；塔仍为 `0/49`，三个可达塔兼容入口与两个主线 null fallback 共五处 legacy 接缝。
- **实测与验收边界**：M2–M6 已增加分版本的受托 AI 桌面记录，并据此修复六项客观问题；完整 G2/五武器/Boss 应对、高密度与长时、导航叙事全链、实际听感及 Windows 证据仍未齐，里程碑继续开放。已有实机记录不回填为其他 SHA 的 PASS，不冒充自然人或 Windows 签字。
- **当前任务状态（真人反馈修复）**：本批生产版本 `793d95c10` 已接通边界约束、首关出口指引、鼠标长按两秒持续普攻/单击取消、九位确证 Boss 主动接敌及敌方出手反馈；最终持锁全量 **6066/6066**、analyze 0 issue、format 1657/0 changed，macOS Profile 构建通过。独立修复包已打开，第二卷第一章5关与原手动/1280×720/静音设置均已核对；原用户档保持隔离。集成与新 SHA CI 另见交付证据，旧 CI 不覆盖本批。恢复计划：`docs/superpowers/plans/2026-09-05-p2-human-first-stage-fixes.md`。
- **M0 开放决策**：22 项集中处置已按用户批准的 M0-R 全部分类并集成；M0 仍缺适用生产接线、测量、实测及真人/Windows 证据，心魔逐身份签字仍开放，不以批准记录冒充正式关闭。
- **M2 优先续验**：旧受托操作和bot对照失败仍保留；后续用户亲自提供山门之外胜利截图，新冷副本/原生存档页确认第二卷已通第一章5关，故不再将合法新档首关记为不可胜。新包真人输入/手感与逐关证据仍需复验；09_04、10_04/05为守位且近身可攻击，追击是否符合战术设计另行确认，07_04为正常追逃目标。冻结生产数值不变。旧 `6d8ffa14` Windows run33964735494 已 success、未签名包哈希和CRC通过；Windows实机仍未执行。
- **前三阻塞（执行顺序）**：① M2 黑风岭完整输入→终局→结算证据、合法首通五关连续链与真人 G2 未闭合；② M3–M6 五武器、密度/长时/听感、六模式与导航的同包验收和 Windows 签字仍缺；③ M0 生产验证/心魔逐身份签字及 M7 塔基础补强、49 层和 5 处 legacy 接缝开放。先推进 M2，再按依赖处理后续门，不以扩塔替代体验验收。
- **治理约束**：`M7-DEPENDENCY-SEMANTICS-01` 明确 M3/M4 工程基础已集成后可继续逐批内容工程，但 M2–M6 真人/Windows 依赖仍阻断 M7 正式关闭及 M8/M9；正式进度只按已连接生产路径、风险匹配验证、main 精确集成和 clean 状态计，工程候选、测试数量、文档与 READY 不计正式里程碑。
- **详细证据**：桌面集成见 `docs/audit/phase2_desktop_fixes_integration_2026-09-05.md` 与对应恢复计划；分版本实机见 `docs/audit/phase2_battle_visibility_repair_2026-09-05.md` 及首轮报告。Ch13 见 `docs/audit/phase2_m7_ch13_contract_fix_2026-09-05.md`；塔基础门见 `docs/audit/phase2_m7_tower_foundation_2026-09-05.md`，五处 legacy 接缝基线见 `docs/audit/phase2_m7_next_batch_and_tower_foundation_audit_2026-09-04.md`。

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
