# 二阶段 M6 U05 “宗门”一级 Hub 纵切审计

## 结论

`P2-M6-U05-SECT-HUB` 为 `READY`。主菜单原先平铺的角色面板、闭关修炼、桃花岛、
门派事务与江湖远行已收拢为一个“宗门”入口；Hub 复用七条既有生产路由，承载角色
档案、门人调度、闭关修炼、伤势疗养、江湖远行、桃花生产与门派事务。本结论只关闭
U05 四个一级入口中的第三项，不代表 U05、M6 或整个二阶段完成。

## 身份与范围

- base：`7e1708f005444f31a0e7cf0f90568b808e00eedc`
- registration：`63dd703d`
- code/reviewed candidate：`6e1ce4a725f655a948a89aa12828323bb3757946`
- branch：`codex/phase2-m6-u05-sect-hub-20260825`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-m6-u05-sect-hub`
- 生产修改只涉及主菜单、宗门 Hub 与共享 UI 文案；无 schema/saveVersion、YAML、
  数值、概率、奖励、解锁阈值、叙事或业务写入修改。

## 生产行为

- 主菜单只保留一个“宗门”入口，不再平铺五个旧入口；断魂庄仍按原远行标志独立显示。
- 角色档案与伤势疗养进入 active roster 第一位角色的 `CharacterPanelScreen`；后者真实
  挂载 `InjuryStatusPanel(showRecoveryAction: true)`。
- 门人调度进入既有 `TeamLineupScreen`；闭关把同一角色 ID 与境界交给既有
  `SeclusionMapListScreen`。
- 远征、桃花生产、门派事务分别进入既有 `ExpeditionOverviewScreen`、
  `TaohuaIslandScreen`、`SectScreen`。
- active roster 加载中、为空或首位角色悬空时，依赖角色的入口 fail closed，不回退
  硬编码角色 ID。
- 闭关 tutorial step 5、远征 `jianghuJourneyUnlocked`、桃花第二章、门派第一章门控由
  主菜单原值透传并在 Hub 内执行；阈值未变。
- 一级闭关状态 chip 随旧入口移除，但主菜单常驻 `MainMenuRetreatBanner` 继续展示活跃
  闭关状态并提供返回进行中页面的入口。

## 红绿与验证证据

真实红测先声明统一入口、七路导航、身份 fail-closed 与门控合同，编译只失败于缺少
`sect_hub_screen.dart`、`SectHubScreen` 和新 `UiStrings`，不是自造断言失败。实现后：

- 新增宗门纵切：12/12 PASS。
- 新增纵切与既有主菜单联合：63/63 PASS。
- 主菜单及角色档案、阵容调度、闭关地图、远征、桃花生产、门派事务生产屏联合：
  191/191 PASS。
- 变更五个 Dart 文件 scoped analyze：0 issue。
- 根应用 `flutter analyze --no-pub lib test tool`：0 issue。
- 最终全量 `flutter test --no-pub --no-test-assets --reporter compact`：
  5345/5345 PASS，退出码 0。
- `git diff --check`：PASS。

相邻生产屏首轮误带 `--no-test-assets`，既有 shader 与 AssetManifest 因测试参数缺失而
报错；该轮既不计通过，也不冒充产品回归。随后在原生资产条件下完整重跑同一集合，
得到上述 191/191 PASS。

## 独立语义审查

独立复核结论为 P0/P1/P2=0、READY。复核确认七条路由落到既有生产 Screen，身份与
四类门控均由生产来源透传；疗伤连接真实恢复动作，旧闭关状态仍由常驻 banner 承载。
`routeObserverForTest` 只在测试显式注入时旁路导航，生产默认 `null` 并走正常
`Navigator.push`，未形成生产风险。

路由单测通过受控 observer 检查 Screen 类型与参数，不冒充子页面真实数据渲染 E2E；
子页面渲染与核心行为由 191 项相邻生产屏测试独立保护。

## 未关闭边界

- U05 的“江湖纪事”一级入口与资源总览角落工具化；U05 仍开放。
- U08 后续门人调度最终形态；本纵切只复用既有阵容生产屏，不改调度业务。
- U01 听剑生产接线及 headless/扫荡等全模式一致性。
- M2/M6、M3/M4、M5 其余模式、M7/M8/M9 与整个二阶段。
- 任何 `TUNE-*` 候选冻结、奖励/解锁/生态调优。
