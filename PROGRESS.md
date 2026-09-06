# 挂机武侠 · 开发进度
> Mac 端 Claude Code 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。
> **当前阶段：1.0 长线打磨期（质量优先 · 不设上线时间压力）** — Demo ✅(2026-05) → 1.0 内容周期 ✅(P1-P5+) → 打磨中。阶段一变只改本行；工作原则见 CLAUDE.md §7。
## 当前阶段
### 二阶段结果仪表盘（2026-09-06 全阻塞验证）
- **正式里程碑**：M0–M9 固定分母 10，仅 M1 关闭，仍 `1/10`；本批修复和测试不代签真人/Windows，不增加正式完成数。
- **已完成**：此前边界/出口提示/鼠标两秒持续普攻及 Boss 接敌修复保留；本批修复首胜刷新进度时丢失页面 context 导致 Next 回到列表的问题。生产 StageList 入口已连接，数值、战斗规则、奖励、解锁和 schema 均未改变。
- **已验证**：代码 `4ed04ae42` 上新增真实建档→键盘战斗→首胜→第二关回归 RED→GREEN；相邻 13 项、持锁全量 **6067/6067**、analyze 0 issue；代码精确 SHA CI `34005471171` 测试/覆盖率/macOS 构建通过。合法学徒冷副本五关连续真实 victory、章末退出后重开 Isar 五关 cleared/五条 journal closed 均通过。
- **平台与视听**：同代码 Windows `34004669034` unsigned 构建和原生 exe 启动成功（观察 17.06 秒）；macOS 正常菜单冷副本启动、轻功败局返回可用。30 MP3 完整解码，但原生双视口 24-active 帧门失败；带声十分钟 RSS 约 283→2477 MiB、帧 p99 106ms，帧/RSS 双门失败；静音十分钟 RSS 门通过但帧门仍红。CI 启动不等于实体 Windows 键鼠/声音/GPU 验收。
- **已知风险**：暗器 Bot 近身移动/瞄准停滞（原策略 300 秒未完，受控停步瞄准 30.8 秒胜）、减少闪光开关无效、密集场景性能及音频并发异常。五类武器均已通过正常库存合法实装，但真实手感、Boss 学习性、六模式全部 UI 循环和跨页面人工验收仍未齐；旧版本实机不回填新版本 PASS。
- **工程水位与依赖**：主线 typed `105/105`，塔 `0/49`、五处 legacy 接缝。塔 typed 候选可接受错误目标早胜的反例已复现，尚未用于当前 legacy 生产塔；先补目标约束/三入口行为/完整 parity，再迁层。M0 timeline/Qi 生产接线和心魔逐身份决策、M4 两个专属音效、M8 72h/长离线及 M9 冻结仍开放。
- **下批建议（执行顺序）**：① 同一 M2 主 WIP 修复自动战斗近身停滞，五武器/边缘/战术定向反例再验；② 音频真实后端并发与内存/性能闭环，再做双视口 3 轮及长时/平台实测；③ 减少闪光生产消费并证明领域状态一致。暂不扩塔层。
- **版本、预算与数据**：09:24:10 CST 开始，首轮 90 分钟墙钟上限，47 分钟检查点已报告；原生产三个 Isar 哈希一致，用户 humanfix 试玩档不写，新包及所有探针使用独立容器或临时冷副本。最终集成状态与成本见报告收口记录。
- **详细证据**：`docs/audit/phase2_blocker_verification_2026-09-06.md`；恢复计划 `docs/superpowers/plans/2026-09-06-p2-blocker-verification.md`。历史分版本证据保留于 `docs/audit/phase2_delegated_desktop_acceptance_2026-09-05.md`、真人反馈修复计划及 Git 历史；本次没有待重投票的产品决策。

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
