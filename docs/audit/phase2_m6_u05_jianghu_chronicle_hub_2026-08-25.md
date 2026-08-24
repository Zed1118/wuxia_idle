# 二阶段 M6 U05 “江湖纪事”一级 Hub 纵切审计

## 结论

`P2-M6-U05-JIANGHU-CHRONICLE-HUB` 为 `READY`。主菜单原先平铺的档案入口已
收拢为一个“江湖纪事”：章节卷轴、人物、地点、敌手、装备典故和待处理江湖事六路
分别复用既有生产 Screen 或专用只读页面。本结论只关闭 U05 四个一级入口中的第四项；
四项均已有独立 READY，但资源总览角落工具化、U05/M6 其余边界与整个二阶段仍开放。

## 身份与范围

- base：`062ea6bb5160e1c528ffa3d347a4fdde4a7500da`
- registration：`749df844`
- code/reviewed candidate：`1a5691f50e79452377a04867e830e959a959bc20`
- branch：`codex/phase2-m6-u05-jianghu-chronicle-hub-20260825`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-m6-u05-jianghu-chronicle-hub`
- 无 schema/saveVersion、YAML、数值、概率、奖励、解锁阈值、经济或 narrative 内容修改。

## 生产行为

- 主菜单只保留一个“江湖纪事”入口，不再平铺人物、排行榜、藏卷阁、战绩册、兵器谱和
  江湖见闻录；旧生产页面没有被删除。
- 章节卷轴、人物、敌手、装备典故分别进入既有 `ChapterListScreen`、
  `LineagePanelScreen`、`BattleRecordScreen`、`BaikeScreen(initialTab: 1)`。
- 敌手与装备典故继续消费原 Boss 纪念/装备图鉴计数隐藏门控；纪事本身不继承旧社交门，
  因章节、地点和待处理事项在新存档也必须可查。
- 地点档案按生产主线章节准入解析，只输出 `cleared` 与当前 `available` 关卡；锁定关卡
  名称不会离开 resolver。本页是只读行迹，不冒充 U06 江湖地图或地点玩法面板。
- 待处理事项只读取当前存档既有 `MainlineSettlementJournal` active outbox，按持久顺序
  严格解析 typed ref，并校验 settlement identity；空、prepared、损坏、多 active 或未知
  编码均 fail closed。
- “继续处理”直接调用既有 `runStageFlow(targetCycle: 1,
  continueFirstClearRun: true)`，由现有 bootstrap 恢复 journal；未建立第二队列或复制
  奇遇/招降 claim 业务。

## 红绿与验证证据

完成 package metadata 与 codegen 后，真实红测仅因缺少三个新 Screen、新 `UiStrings` 和
`pendingForSave` 编译失败；首次 native-assets 崩溃与生成文件缺失不计作红测。实现后：

- 新服务/地点/待处理 UI 与主菜单 Hub 联合：23/23 PASS。
- 修正旧主菜单与百科导航预期后：主菜单 51/51、百科导航 3/3 PASS。
- 变更切片与导航合并：77/77 PASS。
- 主菜单、藏卷阁、战绩册、装备图鉴、百科及主线相邻回归：205/205 PASS。
- `flutter analyze --no-pub lib test tool`：0 issue。
- 根 analyze 首轮仅因独立 `tools/phase0minus_probe` 缺 package metadata 失败；对该已跟踪
  子包执行 `flutter pub get --offline` 后，同一根 `flutter analyze --no-pub`：0 issue。
- 最终 `flutter test --no-pub`：5360/5360 PASS，退出码 0。
- 12 个变更 Dart format：0 changed；`git diff --check` 与精确白名单：PASS。

相邻套件会打印既有 `IsarSetup 未初始化` fallback 日志，因为部分 Navigator 测试刻意只
pump 一帧、不 settle 子屏；命令最终 205/205，全量也 5360/5360，不将日志冒充失败或通过。

## 独立语义审查

独立复核结论为 P0/P1/P2=0、建议 READY。复核确认六路连接真实生产 Screen；地点过滤
不泄露锁定关卡；待处理事项只读现有 outbox，并由原恢复流继续；异常与缺失 stage 均
fail closed。`routeObserverForTest`、loader/resume seam 只在测试显式注入，生产默认走
Navigator、Isar 与 `runStageFlow`。service 的真实 Isar FIFO/损坏态与恢复链另有测试，
因此 Screen 类型测试不构成 fake-green。

## 未关闭边界

- 资源总览角落工具化、旧顶层工具最终归位；U05 仍不宣告整体关闭。
- 排行榜未来归位未在本切片拍板；本批只按冻结六类纪事入口收拢，不擅自新增第七类。
- U03 叙事扩展、U06 江湖地图/地点面板、M7 全敌人/装备内容生产。
- U01 听剑生产接线及 replay/manual/auto/headless/扫荡全模式一致性。
- M2/M6、M3/M4、M5 其余模式、M7/M8/M9 与整个二阶段。
- 任何 `TUNE-*` 候选冻结、奖励/解锁/生态调优、main 合并或 push。
