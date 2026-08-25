# P2-M6-U06 江湖恩怨统一地点详情实施计划

## 目标

在江湖地图与现有 `ReputationPanelScreen` 之间接入统一地点详情，只读展示第一章生产解锁门、六门派定义、已持久化声望、七阶区间及现有声望变化来源。CTA 仍进入原声望面板，保留声望写入、clamp、阶位映射、encounter/Boss 触发、NPC 关系战斗效果与原面板全部现有语义。

## 基线、分支与白名单

- 基线：`5966e2348987a87bf1e61b237bc209f17ee85716`
- 分支：`codex/phase2-m6-u06-reputation-location-detail-20260825`
- 工作树：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-m6-u06-reputation-location-detail`
- 精确 15 文件白名单以 `task_registry.yaml` 本任务 `owned_files` 为准。

## 验收 checklist（CLAUDE.md §8.2）

1. **生产接线**：地图先进详情；详情只读 `mainlineProgressProvider`、`GameRepository.factionDefs`、`numbersConfigProvider`、`reputationServiceProvider` 与 `reputationsForCurrentPlayerProvider`；CTA 续接原 `ReputationPanelScreen`。
2. **真实红测**：先写 provider、详情屏和地图路由测试，在新生产合同缺失时留存可复查编译失败。
3. **targeted 与整合验证**：聚焦新测试；地图/主菜单/声望/江湖服务相邻域；`1280×720` 和 `1440×900`；scoped/root analyze 0；最终候选仅跑一次全量。
4. **数据与异常**：门派 ID/名称/立场、七阶连续覆盖、触发区间、持久行 player/faction/value 必须自洽；未记录门派保持只读空态；未解锁、缺服务、未知/重复门派或异常 provider fail closed 且无 CTA。
5. **红线影响**：不改 schema/saveVersion、YAML、声望数值、概率、奖励、经济、战斗倍率、关系算法或生产解锁门；UI 文案只进 `UiStrings`。
6. **独立复审**：在冻结代码候选上核对真实生产数据、稀疏记录语义、地图→详情→原面板路由、异常关闭和白名单，P0/P1/P2 归零后才进 READY。
7. **残留风险**：不从关系表猜测当前 NPC 仇敌数量，因为入口没有冻结的 source character 身份；如无真人截图/Profile/Windows 证据则如实保留，不外推 U06/U14/M6 或二阶段完成。

## 任务切片

1. 登记任务与白名单，在 fresh worktree 完成依赖/生成准备。
2. 写新合同/路由真实红测并单独 commit。
3. 新增只读 domain DTO、生产 provider 和详情屏，将地图江湖恩怨路由改为先进详情。
4. 完成聚焦、声望相邻域、双视口与两层 analyze，冻结代码候选。
5. 独立语义复审；修复所有有效问题并重验。
6. 最终全量一次；代码完成后再同步 audit/registry/CLAUDE/GDD/PROGRESS，验证 YAML/truth-source/diff/白名单/clean 并产出 `[READY]`。

## 边界

- 不修改现有声望写入、clamp、七阶、Boss/encounter delta、NPC 关系战斗倍率或 faction 配置。
- 不把缺失声望行写成数据库中的零值，不自动补行，不猜测当前角色或 NPC 仇敌数量。
- 不新建第二套声望/关系系统，不修改 schema/saveVersion、YAML、`TUNING/candidate`、main 或 origin/main。
- 只关闭江湖恩怨统一地点详情首缺口，不晋升 U06、U14、M6 或二阶段整体状态。

## 当前恢复点

- 状态：代码候选 `a3585712` 已冻结，独立语义复审 P0/P1/P2=0，最终全量已通过；权威文档、audit 与 registry 已同步，待 READY 前终检和标记。
- 最后完成：首轮复审发现“门派数不是六个仍展示”的 P2，以独立红测 `0/1` 复现并修复；最终独立聚焦 `19/19`、生产相邻链 `42/42`、两组 analyze 0；最终全量仅运行一次并以 `5505/5505 PASS` 结束。
- 下一步：验证 registry YAML、truth-source、精确白名单、`git diff --check`、primary main 干净且未变；提交证据并创建 `[READY][CODEX][P2-M6-U06-REPUTATION-LOCATION-DETAIL]` 空标记 commit。
- 已跑验证：初始真实红测 `0/3`，复审红测 `0/1`；聚焦 `19/19`，相邻域 `268/268`，其中双视口 `2/2`；scoped/root analyze 均 0；独立复审 P0/P1/P2=0；最终全量 `5505/5505`。
- 阻塞项：无；任何当前 NPC 仇敌角色归属或新关系面板需求必须保持不做。
