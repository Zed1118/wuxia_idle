# 挂机武侠 · 开发进度
> Mac 端 Claude Code 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。
> **当前阶段：1.0 长线打磨期（质量优先 · 不设上线时间压力）** — Demo ✅(2026-05) → 1.0 内容周期 ✅(P1-P5+) → 打磨中。阶段一变只改本行；工作原则见 CLAUDE.md §7。
## 当前阶段
### 二阶段结果仪表盘（2026-08-26 夜批收账后）
- **正式里程碑**：未加权 M0–M9 记录为 `1/10`，候选链已入 main。权重未获批准，不报告成熟度百分比。
- **当前权威 Gate**：`P2-CANDIDATE-STABILIZATION` `1/1 READY` 已发 main；当前无权威 WIP，下一门须人类先选 schema 授权或调整 automation 固定分母。
- **main 基线**：`6a0c2945`，领先 `origin/main` 697 commit，**未 push**（本批 push 未授权）。合并前后全量各一次均 5611/5611、analyze 0、format 0 changed。
- **本批合入（9 分支，零冲突）**：候选稳定化基线 + B 仅测试引用分档 + 入口徽章截断修复 + 战斗核心四条调优候选与决策登记 + 结算参与者身份修复 + 双视口视觉验收记录 + 夜批交接 + 攻击令牌接线。
- **决策出队**：`TUNE-POSTURE-01`/`TUNE-WEAPON-TIMELINE-01`/`TUNE-ATTACK-TOKEN-01` 拍 B、`TUNE-WEAPON-QI-01` 拍 C，registry `tuning 21 → 17`。仅 TOKEN 已接生产（`black_wind_ridge.yaml` 2/2/1/1，经 enforcing gate 真消费）。
- **已连接能力**：G2 生产目录/运行时绑定 `8/8`；九霄塔首通后 typed automation 子门 `1/1`；U14 权威门仍 `0/1 BLOCKED`，不得以子门替代。
- **测试成本**：热缓存并发全量墙钟约 5 分钟（本批两次实测 5:10 / 5:02），冷隔离约 14 分钟；reporter 的 `mm:ss` 是分秒不是小时。
- **前三阻塞**：POSTURE/TIMELINE/QI 三条冻结值的 parked 合同在 lib 内零消费者，接线等于替换生产战斗子系统，须人类重新授权范围；轻功 durable session/occupancy 未授权；守城 durable formation snapshot/occupancy 未授权。
- **待人类决策**：① 三条战斗子系统接线的范围与 v1.50 门槛（YAML+红线+模拟+双平台 Profile+真人试玩）② light-foot / mass-battle schema+saveVersion+共享占用扩展 ③ M0–M9 权重 ④ 是否 push main。
- **已知偏差**：候选目录守卫 `_enforceStage0103CandidateBounds` 限令牌总和 ∈[2,4]，而冻结值总和 6；该守卫仅作用于候选源、不适用生产，两边口径待统一。视觉验收 46 行鼠标判定已改 N/A（截图不含光标），返回 12 / 键盘 22 / semantics 20 三列 FAIL 未证伪，另立 triage。
- **worktree**：160+ 个，多数分支已入 main，清理债未授权未动。
- **详细证据**：计划、分支/worktree 分类审计与验证记录位于 `docs/superpowers/plans/`、`docs/audit/`；历史 READY 全文由 git 保留，不堆叠顶栏。

## 已知偏差 / 挂账事项
- **任务储备总账 → 根目录 `BACKLOG.md`**(2026-07-19 建账):待拍板/已解锁可派/依赖锁死/方向级四段,每批收账随 PROGRESS 同步更新;原开放挂账(Riverpod TickerMode 断言)已迁其 §三。
> 已销账条目(#1-#45)详见末尾归档。**P1 阶段全销账 ✅** + **Demo §8.4 14/14 全达标 ✅** + **1.0 ~95% release ready ✅**(A+B+C 全 PASS · 剩 D-G 留 M15-16)。
## 关键约束(每次开局必读)
- 数值硬红线(配置基础表值·schema 拦截):装备基础攻击 ≤2000 / 玩家血 ≤20000 / 内力 ≤15000 / Boss 血 60000+(GDD §5.4)
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
