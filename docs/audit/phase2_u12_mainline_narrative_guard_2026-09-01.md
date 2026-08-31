# Phase 2 U12 主线叙事守卫审计

日期：2026-09-01  
基线：`4dc54697df9a26d26abceb58577a67368e9b63cb`  
任务：`P2-M6-U12-MAINLINE-NARRATIVE-GUARD`

## 当前结论

U02/U03 的生产实现仍在真实入口生效：主线三类自动阅读统一由 `StageType.mainline` 判据关闭，特殊模式保留；252 个旧 ID 由严格 manifest 投影到现有章节卷轴，物理资产完整性守卫覆盖三个 `NarrativeLoader` 搜索目录。

本轮发现一条弱守卫：既有 `105` 数量断言没有锁精确关卡拓扑。现已补为 `stage_01_01..stage_21_05` 精确集合，并逐关锁定 opening/victory ID 与 Boss defeat ID 自洽；没有改变生产代码、配置或内容资产。

## 当前证据

| 检查 | 结果 |
|---|---|
| 原 U02/U03 关键基线 | 43/43 PASS |
| 精确 21×5 拓扑守卫 | 3/3 PASS |
| 破坏主线去阻塞判据 | 2 FAIL，RED_CONFIRMED |
| manifest `targetId` 漂移 | 1 FAIL，RED_CONFIRMED |
| 增加 `stage_99_99_opening` 物理孤儿 | 1 FAIL，RED_CONFIRMED |
| 精确反向补丁恢复后三类核心守卫 | 17/17 PASS |

## 待完成

- U02/U03 原 12 文件保护网 + 新拓扑守卫。
- analyze、整仓 format、锁定全量、Gate。
- main 合并、push 与精确 SHA CI。

真人章节卷轴阅读、键鼠交互与视觉密度继续按用户要求挂账；本工程门不得据此宣称 M6 或 Phase 2 正式验收通过。
