# 二阶段 M6 U05 “武学与行囊”一级 Hub 纵切审计

## 结论

`P2-M6-U05-MARTIAL-INVENTORY-HUB` 为 `READY`。主菜单原先平铺的装备仓库、
心法面板与藏经阁已收拢为一个“武学与行囊”入口；Hub 复用四个既有生产 Screen，
分别承载招式配置、主修心法、装备与物品。本结论只关闭 U05 四个一级入口中的第二项，
不代表 U05、M6 或整个二阶段完成。

## 身份与范围

- base：`e618f6b2b970609cf0a99189125b2ec2ffc0796f`
- registration：`46da70a5c6ca1bd75b3bdf84816d47073220ce4c`
- code candidate：`3d73dc617b15c3250eb1c63fe8c1aea13dbd417c`
- reviewed candidate：`515f803b71a6bf0217ba943c6e78db265a22595c`
- branch：`codex/phase2-m6-u05-martial-inventory-hub-20260825`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-m6-u05-martial-inventory-hub`
- 生产修改仅涉及主菜单、统一 Hub 与共享 UI 文案；无 schema/saveVersion、YAML、
  数值、概率、奖励、解锁、叙事或业务写入修改。

## 生产行为

- 主菜单只保留一个“武学与行囊”入口，不再平铺装备仓库、心法面板、藏经阁。
- 招式配置进入既有 `CangJingGeScreen`，主修心法进入既有
  `TechniquePanelScreen`；两者使用 active roster 第一位角色。
- 装备进入 `InventoryScreen(initialTab: 0)`，物品进入
  `InventoryScreen(initialTab: 1)`。
- 招式与主修继续消费既有 tutorial step 3 门控；step 0/2 锁定，step 3/5/8
  向上兼容开放。active roster 加载中或为空时两项 fail closed，装备/物品仍可用。
- Hub 在 1280×720 与 1440×900 两个目标视口无布局异常。

## 红绿与验证证据

红测先只引入预期合同，编译明确失败于缺少 Hub 文件、类型与 `UiStrings` 字段；不是
断言自造失败。生产实现后新增纵切 11 项，覆盖入口唯一性、四路导航、库存 Tab、教程门、
active roster 身份与 fail-closed、双视口布局。

- 新增纵切：11/11 PASS。
- 新增纵切与既有主菜单联合：65/65 PASS。
- 主菜单、藏经阁、心法、库存、视觉路由与 truth source 联合：181/181 PASS。
- 根应用 `flutter analyze --no-pub lib test tool`：0 issue。
- 最终全量 `flutter test --no-pub --no-test-assets --reporter compact`：
  5336/5336 PASS，退出码 0。
- `git diff --check`：PASS。

复审前曾启动一次全量，但在首轮审查指出测试保护缺口后主动 SIGINT，中断时的计数与
清理噪声不计入通过或失败；上面的 5336 是补强测试后从头运行的唯一最终全量证据。

## 独立语义审查

首轮独立审查对生产实现给出 P0/P1=0、P2=1；P2 是 step 2、step 5/8 与 active roster
loading fail-closed 缺少显式回归，并非生产缺陷。补入 commit `515f803b` 后复审结论为
P0/P1/P2=0、READY。审查确认四条路由均落到既有生产 Screen/API，没有硬编码角色 ID、
业务规则、schema 或调优越界。

路由测试在未初始化 Isar 的测试壳中会打印既有 `ErrorFallback` 日志，因此不等同于子页面
真实数据渲染 E2E；本切片证明的是 MainMenu → Hub → Screen/Tab/角色参数接线。子页面真实
渲染与行为继续由纳入 181 项联合验证的既有 screen 测试保护，该日志不构成当前 P2。

## 未关闭边界

- U05 的“宗门”“江湖纪事”一级入口与资源总览角落工具化。
- U01 听剑生产接线及 headless/扫荡等全模式一致性。
- U05、M2、M6、M3/M4、其他里程碑与整个二阶段。
- 任何 `TUNE-*` 候选冻结、奖励/解锁/生态调优。
