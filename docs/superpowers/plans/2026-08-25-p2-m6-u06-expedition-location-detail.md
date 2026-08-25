# P2-M6-U06 百草岭远征统一地点详情实施计划

## 目标

在江湖地图与现有 `ExpeditionOverviewScreen` 之间接入统一地点详情，只读展示百草岭生产历史/当前进度、基础推荐境界、普通/险关敌方生态、三种方针的核心产出、真实可派遣候选人或进行中参与者、当前仅支持的门人差遣方式与会话占用。CTA 仍进入原远征总览，保留选人、方针、周目、离线推进、召回、结算与返程全部现有语义。

## 基线、分支与白名单

- 基线：`c6c9e7a9eef846a2125c4d33cccf33499352c4b2`
- 分支：`codex/phase2-m6-u06-expedition-location-detail-20260825`
- 工作树：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-m6-u06-expedition-location-detail`
- 精确 15 文件白名单以 `task_registry.yaml` 本任务 `owned_files` 为准。

## 验收 checklist（CLAUDE.md §8.2）

1. **生产接线**：地图先进详情；详情只读 `expeditionConfigProvider`、`expeditionMaxDepthProvider`、`expeditionCandidatesProvider`、`activeExpeditionProvider`、Isar 真实角色与 `GameRepository` 道具定义；CTA 续接原 `ExpeditionOverviewScreen`。
2. **真实红测**：先写 provider、详情屏和地图路由测试，在新生产合同缺失时留存可复查失败证据。
3. **targeted 与整合验证**：聚焦新测试；地图/主菜单/远征相邻域；`1280×720` 和 `1440×900`；scoped/root analyze 0；最终候选仅跑一次全量。
4. **红线影响**：不改 schema/saveVersion、YAML、数值、奖励、概率、在线=离线、三系锁死、反主流边界或生产解锁门；UI 文案只进 `UiStrings`。
5. **UI/桌面语义**：两个常规视口无 overflow；进入 CTA 沿用 `WuxiaInkButton` 的键盘/focus/mouse/semantics 能力；loading/error fail closed 且错误态无 CTA。
6. **独立复审**：在冻结代码候选上核对真实生产数据、idle/active 路由、异常关闭、无政策外推和白名单，P0/P1/P2 归零后才进 READY。
7. **残留风险**：如未取得真人视觉实拍、性能或 Windows 证据则如实记录；不用 widget 绿测外推 U06/U14/M6 或二阶段完成。

## 任务切片

1. 登记任务与白名单，在 fresh worktree 完成依赖/生成准备。
2. 写新合同/路由真实红测并单独 commit。
3. 新增纯展示 domain DTO、生产 provider 和详情屏，将地图百草岭路由改为先进详情。
4. 完成聚焦、远征相邻域、双视口与两层 analyze，冻结代码候选。
5. 独立语义复审；修复所有有效问题并重验。
6. 最终全量一次；代码完成后再同步 audit/registry/CLAUDE/GDD/PROGRESS，验证 YAML/truth-source/diff/白名单/clean 并产出 `[READY]`。

## 边界

- 不把远征的“差遣”扩展为玩家亲战、前台 bot、多人或新自动化；只如实显示现有单门人派遣。
- 不改候选人政策、方针权重、周目门槛、节点时长、离线结算、召回、战败、奖励或解锁语义。
- 不新建第二套远征状态/结算系统，不修改 schema/saveVersion、YAML、`TUNING/candidate`、main 或 origin/main。
- 只关闭百草岭统一地点详情首缺口，不晋升 U06、U14、M5、M6 或二阶段整体状态。

## 当前恢复点

- 状态：代码候选 `bf6dcfc3` 已冻结，独立语义复审 P0/P1/P2=0，最终全量已通过；权威文档、audit 与 registry 已同步，待 READY 前终检和标记。
- 最后完成：独立复审重跑聚焦 `19/19`、远征生产域 `59/59` 与 scoped analyze 0；最终全量仅运行一次并以 `5490/5490 PASS` 结束；registry YAML、精确白名单 `15/15`、truth-source guard `9/9` 与 `git diff --check` 均通过。
- 下一步：提交证据文档，复核 base..HEAD 精确白名单、primary main 干净且未变，创建 `[READY][CODEX][P2-M6-U06-EXPEDITION-LOCATION-DETAIL]` 空标记 commit 并确认 worktree clean。
- 已跑验证：真实红测 `0/3`；聚焦 provider/详情屏/地图 `19/19 PASS`，其中双视口 `2/2`；地图、远征和宗门入口相邻域 `211/211 PASS`；scoped/root analyze 均 0 issue；独立远征生产域 `59/59`；最终全量 `5490/5490`。转绿中仅修正测试把生产“三流”误写成“二流”的预期，未改 YAML/数值。
- 阻塞项：无；任何渐进解锁或新参与方式需求必须保持不做。
