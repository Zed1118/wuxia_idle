# M4 剩余三套生态生产纵切计划

## 结果合同

- 单一目标：为西凉、邪道/毒门、寺院三套生态各接入一场真实主线生产关，形成固定 `3/3` 子 Gate。
- 基线：`aafd86ca1cc07956cffeea4dda2197942203fe0a`，承接已独立收口的门派与官军生态候选。
- 生产锚点：`stage_04_01` 阳关初渡、`stage_02_01` 镖局护送、`stage_13_02` 半山寺。
- 不扩张项：不启动 M3，不改 schema/存档/数值表，不新增 AI 原语，不改关卡目标产品语义，不 merge/push。
- 人工边界：敌人外观辨识、战斗可读性、手感和桌面实际试玩全部挂账，不以自动测试代替目检。

## 验收门

1. 三个 stage 都由 `stage_assignments.yaml` 路由到各自精确 encounter。
2. 每套生态恰有四个 canonical role、25 个逻辑敌人、10 个 active cap、`2/1/1/1` token budget。
3. 每个 role 有显示名、攻击集合/标签、姿态、掉落组、音效组和两种已有美术变体引用。
4. typed runtime bundle、真实 production host、AI 行为和 25 敌目标闭环全部通过。
5. 破坏证红：移除任一 stage assignment 必须 fail closed；退化任一角色行为必须由精确测试抓住。
6. targeted、邻接 `test/data/phase2`、analyze、全仓 format、macOS Debug build、持锁全量与独立 Gate 全绿。
7. 最终分支 worktree clean，主 checkout 保持 clean 且未改。

## 实现顺序

1. 先添加一个三生态矩阵式生产测试并记录 RED。
2. 添加三个 archetype source 与三个 encounter source。
3. 补 manifest reference index、stage assignments 和 runtime bindings。
4. 运行定向测试并做双向破坏证红、精确还原。
5. 只在最终状态跑一次完整验证与独立 Gate。

## 后置挂账

- 三套生态在真实桌面战斗中的轮廓、武器与身份辨识。
- 10 个 active 敌人的遮挡、入口预警、令牌错峰与屏外提示可读性。
- 三个生产入口的实际导航、战斗与终局。

## 实测证据

- TDD RED：首次完成依赖生成后，三条生产 stage 断言均因 assignment 为 `null` 失败（`0/3`）。
- 破坏证红 A：移除 `stage_13_02` assignment 后 catalog fail closed，精确反向补丁还原后 `3/3`。
- 破坏证红 B：将 `ai_ch2p_blood_blade` 的移动从 `direct_advance` 退化为 `guarded_position` 后，仅 `stage_02_01` 失败（`2/3`），精确反向补丁还原后 `3/3`。
- 定向/邻接：新增生产测试 `3/3`；`test/data/phase2` 加 catalog repository/loader/schema/validator/migration/factory/preflight 共 `175/175`。
- 生产预检：`manifest=149; eligible=149; skipped=0; runs=447; wins=91; defeats=356; timeouts=0; maxDamage=4419`。
- 静态/格式：`flutter analyze --no-pub lib test` 为 `0 issues`；`dart format .` 检查 `1651` 文件、`0 changed`；`git diff --check` 通过。
- 构建：`flutter build macos --debug --no-pub` 成功生成 `wuxia_idle.app`，仅有既存第三方 `audioplayers` Swift warning。
- 全量：持锁执行 `flutter test --no-pub`，`5734/5734`，末行 `All tests passed!`，退出码 `0`。进程退出钩子误写 `/usr/bin/unlink`，随后仅对本次创建的精确锁文件使用 `/bin/unlink` 清理并确认不存在。
- 独立 Gate：待候选提交后记录。
- 首次独立 Gate：静态、格式及前置项通过，但全量在既有 `game_event_feed_providers_test.dart` 的首个 Isar 查询处因默认 30 秒超时而失败；展开日志复跑在同一位置再次失败。该文件单跑 `3/3`，墙钟 `2.94s`，确认是整仓并发冷启动资源饥饿而非本批生产数据回归。
- Gate 稳定性修复：仅为该测试库增加 2 分钟时间预算；不改断言、不 skip、不改生产实现，并保持 test diff 纯新增、零删除。修复后的全量与独立 Gate 待记录。
