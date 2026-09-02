# 挂机武侠 · 开发进度
> Mac 端 Claude Code 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。
> **当前阶段：1.0 长线打磨期（质量优先 · 不设上线时间压力）** — Demo ✅(2026-05) → 1.0 内容周期 ✅(P1-P5+) → 打磨中。阶段一变只改本行；工作原则见 CLAUDE.md §7。
## 当前阶段
### 二阶段结果仪表盘（2026-09-02 P0 质量候选收口）
- **正式里程碑**：未加权 M0–M9 固定分母为 10，当前仅 M1 关闭，结果 `1/10`；权重未获批准，不报告成熟度百分比。
- **精确工程集成基线**：`main == origin/main == 1c0eaa3ae8c2b77730cd4ab0844e54fd15939991` 且 clean；M3 集成 `f3076cef045145cc17cc2d4098f5fba0161998e1`、CI run `33530794272` 成功，M7 第二章集成 `1c0eaa3ae8c2b77730cd4ab0844e54fd15939991`、CI run `33533824877` 成功。
- **工程门**：M3 五类单段普攻生产画像 `5/5` 已集成；M7 第二章 `5/5`、全主线 typed catalog `14/105` 已集成，塔仍为 `0/49`；本轮独立候选已关闭台账、M3 真实生产遭遇矩阵、第二章有效画像/动态终局共 `3/3` P0 质量子门，但尚未合入 main；M5 六模式七合同 `42/42`、M6 顶层生产入口/身份/结算合同 `1/1` 已集成。
- **真人挂账**：M2 G2、M3 五类武器手感/辨识度、M4 视觉/音频/Windows、M5 六模式实际操作、M6 导航与交互及 M7 第二章实战均未获本轮独立真人签字，统一保持未关闭，不以自动化或历史截图补猜。
- **当前权威顺序**：先评审并集成本轮 `3/3` P0 质量候选，再继续 M7 按章迁移；M8 发布质量与 M9 RC 不提前启动。任何下游 READY 均不反推上游正式通过。
- **M0 开放决策**：decision registry 仍有 20 条 `tuning`、1 条 `deferred_pending_matrix`、1 条 `partially_reopened`；涉及生产战斗数值或规则时仍按授权边界处理。
- **前三阻塞**：① 本轮 `3/3` P0 质量候选尚待独立评审与集成；② M2–M7 真人/Windows 挂账仍未关闭；③ M7 主线 `91`、塔 `49` 个迁移缺口仍未关闭。
- **治理约束**：正式进度只按已连接生产路径、风险匹配验证、main 精确集成和 clean 状态计；工程候选、测试数量、文档与 READY 不计正式里程碑。
- **详细证据**：P0 质量收口见 `docs/superpowers/plans/2026-09-02-p2-p0-quality-hardening.md` 与 `docs/audit/phase2_p0_quality_hardening_2026-09-02.md`；M3/M7 原始计划、精确 SHA CI run `33530794272` / `33533824877` 仍只证明既有 main 集成。

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
