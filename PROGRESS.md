# 挂机武侠 · 开发进度
> Mac 端 Claude Code 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。
> **当前阶段：1.0 长线打磨期（质量优先 · 不设上线时间压力）** — Demo ✅(2026-05) → 1.0 内容周期 ✅(P1-P5+) → 打磨中。阶段一变只改本行；工作原则见 CLAUDE.md §7。
## 当前阶段
### 二阶段结果仪表盘（2026-08-26）
- **正式里程碑**：当前统一候选按未加权 M0–M9 记录为 `1/10`；main 仍 `0/10`。权重未获批准，不报告成熟度百分比。
- **当前权威 Gate**：`P2-CANDIDATE-STABILIZATION` 已 `1/1 READY`；当前无权威 WIP，下一门须由人类先选择 schema 授权或调整 automation 固定分母。
- **候选基线**：`codex/phase2-candidate-stabilization-20260826` 基于 `4226a9c2`；main 为 `e292d3a0`，本任务不合并、不推送 main。
- **已连接能力**：G2 生产目录/运行时绑定记录为 `8/8`；九霄塔首通后 typed automation 子门 `1/1`；U14 权威门仍 `0/1 BLOCKED`，不得以上述子门替代。
- **候选验证**：已提交 `2ff18b61` 在独立诊断 clone 默认并发 full suite 为 6,294/6,294 非 loading test events、0 skip、0 error、exit 0，墙钟 `14:06.91`；稳定 worktree 生成 128 个 ignored outputs 后，最终 scoped analyze 0 issue（墙钟 `22.10s`）；diff check 0，registry YAML 可解析。
- **测试成本订正**：历史 reporter `5:00` 表示约 5 分钟，不是 5 小时；当前冷隔离候选约 14 分钟，施工预算按约 5–15 分钟，不按小时。
- **恢复事实**：首次测试期间应用托管 b679 worktree 整体消失；同一 commit 在 disposable clone 越过原时间点并完整全绿，仓内未找到删除 repo root 的路径。最符合证据的推断是外部 worktree 生命周期竞态；候选已迁至稳定专用 worktree，main 与其他工作树未受影响。
- **分支分类**：187 个本地分支中 100 个 tip 已在候选祖先链，87 个历史分叉待逐项归类；其中 2026-08-25 新增治理分支 `503d1ad3` 正在本 Gate 语义吸收。不得把 87 直接等同于 87 项集成债。
- **worktree**：仍为 154 个；当前候选已迁至 `/Users/a10506/Desktop/Projects/挂机武侠-phase2-candidate-stabilization-20260826`，不再复用应用托管 b679 路径；未删除或复用他人 worktree。
- **孤立集成债**：治理分支 `503d1ad3` 已语义吸收；其余 86 个历史分叉尚未完成“已吸收 / 已替代 / 仍待评”分类，不直接计债。
- **main 发布债**：0 个已关闭权威产品 Gate 待发 main；候选稳定化是治理 Gate，不晋升产品里程碑，也不自动授权合 main。
- **预算**：主成本读数为墙钟；约 90 分钟无 Gate 变化即停线。本 Gate 的有效完整套件已结束，不重复执行。
- **前三阻塞**：轻功 durable session/occupancy/返程 owner 未授权；守城 durable formation snapshot/occupancy 未授权；M0–M9 权重未批准。
- **待人类决策**：授权 light-foot / mass-battle schema+saveVersion+共享占用扩展，或明确从固定 automation Gate 分母移除 dispatch；本任务不代替拍板。
- **详细证据**：候选稳定化计划、分支/worktree 分类审计和最终验证记录位于 `docs/superpowers/plans/`、`docs/audit/`；历史 READY 全文由 git 保留，不再堆叠在本页顶栏。

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
