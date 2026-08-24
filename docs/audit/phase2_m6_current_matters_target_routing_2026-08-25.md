# P2 M6 主菜单“当前要事”精确角色路由审计

## 结论

`P2-M6-CURRENT-MATTERS-TARGET-ROUTING` 已达到 `ready_reviewed`。闭关、伤势与突破
摘要不再把所有点击硬编码到角色 1；生产 provider 生成 typed 角色载荷，点击时再次核验
当前 active roster、角色实体以及闭关 session/境界，任何缺失、悬空、重复或 provider
异常均 fail closed。桃花岛、主线、摘要优先级、文案和最多五项保持不变。

本结论只关闭“当前要事”角色路由缺口，不关闭 U05/U06/U07、M6 或整个二阶段。

## 施工身份

- base：`23ab38cd7da8ae33923cc0b068c5905078b05f0d`
- branch：`codex/phase2-m6-current-matters-target-routing-20260825`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-m6-current-matters-target-routing`
- registration：`2de7a2e393bacbb224f62a98039c525301ef4cfe`
- code candidate：`8926d0c3da6e473991774ae508af5bb92392dc29`
- reviewed candidate：`08eac7961e669451f39668129f131188433374af`

## 真实缺口与修复

基线 `MainMenuStatusSummaryItem` 只有 kind/route/title/detail，展示层把闭关、伤势、突破
固定导航到 `characterId = 1`，闭关境界固定为 `RealmTier.xueTu`。继承换代或门人状态会
进入错误角色；角色页还可能把悬空 ID 静默回退到 roster 首人。

修复后：

1. item 新增可空 typed `targetCharacterId` 与 `targetRealmTier`。
2. 闭关只在 active roster 中存在唯一 session 关联角色时生成，并携带该角色真实境界。
3. 伤势继续聚合原人数/时长，但目标固定为 active roster 顺序首名伤者；突破继续选择原
   顺序首名达标者。
4. 点击角色路由重新读取 active roster 与角色实体；闭关额外重新读取 active session 并
   校验关联和境界。null、非正数、正数悬空、重复关联、lookup error、旧 session 均不 push。
5. island/mainline 路由不增加角色依赖，原优先级与 `take(5)` 不变。

## TDD 与复核闭环

- 初始红测 `8f21453e`：新增目标字段/构造参数不存在，聚焦 0/1。
- 首候选 `8926d0c3`：聚焦转绿，但独立复核发现正数悬空 ID 仍 push，报告 P1。
- 复核红测 `d68af49b`：真实复现悬空 999 产生第二条 route，10/11。
- 修复候选 `08eac796`：点击时重新解析当前生产身份；补真实
  `mainMenuStatusSummaryProvider → MainMenuStatusSummaryPanel → CharacterPanelScreen`
  端到端测试。
- 复审：P0=0、P1=0；唯一 P2 为计划文件 EOF 空行，已在本次同步删除。

## 验证

| Gate | 结果 |
| --- | --- |
| 聚焦 `main_menu_status_summary_test.dart` | 14/14 PASS |
| 1280×720、1440×900 | 2/2 PASS，零 overflow |
| main_menu + character_panel + seclusion | 387/387 PASS |
| scoped analyze | 0 issue |
| root application analyze `lib test tool` | 0 issue |
| 最终全量（真实 test assets） | 5430/5430 PASS |
| 独立语义复审 | P0=0，P1=0 |

最终同步后还执行 truth-source guard、base→tip `git diff --check`、精确 10 文件白名单、
格式与 clean 状态检查；这些门禁必须全部通过后才提交 READY tip。

## 范围与非声明

- 精确白名单为 2 个生产 Dart、1 个测试和 7 个计划/审计/权威文档，共 10 文件。
- 零 schema/saveVersion、YAML、调优、数值、奖励、经济、解锁与业务写入变更。
- 未修改 primary `main`，未合并，未 push，未冻结任何候选值。
- READY 不代表 U05/U06/U07、M6、M2–M9 或整个二阶段完成。

最终 marker：`[READY][CODEX][P2-M6-CURRENT-MATTERS-TARGET-ROUTING] 修正当前要事角色路由`。
