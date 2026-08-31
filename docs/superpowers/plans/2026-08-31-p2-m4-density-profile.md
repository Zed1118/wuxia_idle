# M4-F 24-active 群战性能 fixture 计划

## 结果合同

- 单一目标：新增可由现有 `BattleFrameProfileProbe` 驱动的 24-active 调试/性能路由，使用真实 `Phase0aBattleScreen`、controller、bot、production flow assembler 与 reducer，为 P09 后续双视口 Profile 矩阵提供稳定入口。
- 基线：`0d565fa0856ff54f1bd62655f151e320c38852d0`，承接 M4-E 音效聚合 clean Gate 候选。
- 分母：M4-F 工程 fixture `0/1`；只有路由可解析、首波精确 24 active、重建仍保持 24、生产屏可挂载且机器 Gate 通过后记 `1/1`。M4 父 Gate 仍不关闭。
- 当前阻塞：既有 `phase0a_battle_profile` 只有 2/3 敌人，`phase0a_black_ridge_profile` 只有 12 active，缺 P09 的 24-active 采样入口。
- 成本上限：一个独立 worktree、一个小提交、一次独立 Gate；不跑三轮双视口正式 Profile 矩阵，不占用真人目检。

## 范围

- 基于既有 debug YAML 的 typed 配置在内存中生成一波 24 名普通敌人；不新增生产数值、不改 `numbers.yaml`、schema、存档、关卡或结算语义。
- 仅为动态生成的调试敌人补通用既有资产视觉，不改变原 fixture 的玩家、五名既有敌人的显示名或资产。
- 新增 `phase0a_m4_density_profile` 路由，复用现有 `_Phase0aProfilePreview` 的 bot 循环与预热重建池。
- 新增 fixture 与 route 守卫；所有测试 diff 保持零删除。

## 验证

1. RED：测试先要求 density fixture 初始与 fresh/restart 均为 24 active，并要求新 route 可解析、host 接线存在。
2. GREEN：fixture/route 目标测试、相邻 debug/profile/战斗屏测试通过。
3. 破坏证红：把 density 数量退化为 23；移除新 route 的 host 分支；两向分别必须红，精确反向还原。
4. `flutter analyze --no-pub lib test`、全仓 format、持锁全量、收据与独立 Gate。

## 挂账

- 1280×720、1440×900 各 60 秒、3 次有效 Profile run 及正式 p99/RSS 判定。
- 24 active 下玩家、关键威胁、伤害数字、屏外提示和音频的真人可读/可控/听感验收。
- Windows 发布构建矩阵。fixture 工程完成不等于上述性能或真人 Gate PASS。

## 执行结果

- 有效 RED：`loadM4Density` 与 `VisualRoute.phase0aM4DensityProfile` 均不存在，两个目标文件编译失败。
- density fixture 初始、`fresh()` 与两项预热重建均精确保持 24 active；动态 actor id 唯一且每名都有可加载的既有敌人资产。
- 1280×720 widget 守卫把 24 名敌人全部挂入真实 `Phase0aBattleScreen`，显式卸载后无异常；相邻 debug/profile/战斗屏联合测试 72/72。
- macOS profile 构建成功。真实应用 2 秒零预热烟测输出 `VISUAL_ROUTE_READY: phase0a_m4_density_profile`、102 帧、1280×720 与完整 GC 遥测；因零预热包含启动抖动，`frame_streak_gate_passes=false`，只证明路由/采集链可用，不作为性能 PASS。
- 双向破坏证红：active 数量强制退化 24→23，目标用例失败 1；host 强制退回普通 fixture，route 接线用例失败 1。两项均精确反向还原。
