# 路线 C · Mac 集成 Gate 证据

- 日期：2026-08-22
- 分支：`codex/phase0a-gauntlet-main-0822`
- 裁决：`MAC_ENGINEERING_GATE_PASS`
- 边界：不启动 GUI；复用此前 Mac 动态目检结论，并对当前整合态执行自动化回归与原生构建。

## 当前整合态

主线、塔、扫荡、远征、断魂庄五个生产消费面均永久走 Phase 0A 单角色 ARPG。生产代码不再保留旧 `BattleScreen`、`StageBattleSetup`、旧 battle provider 或 legacy gate 回退；历史多人会话走安全兑现与释放，不再启动旧 runner。

## 自动验收

1. 五消费面与路线守卫联合测试：589/589。
2. Boss 机制、双视口、键鼠与真实入口聚焦 Gate：57/57。
3. `phase0a_battle_screen_test.dart` 独立复跑：23/23。
4. 生产内容预检：149/149 eligible，447 runs，0 timeout，maxDamage 2044。
5. `flutter analyze --no-pub lib test`：0 issue。
6. `flutter build macos --debug --no-pub`：成功生成 `wuxia_idle.app`。
7. 全量测试：5361 项中 1 项失败；失败首次出现在 Phase 0A 表现测试并发批次，所属文件独立复跑全绿，判为全量并发时序抖动，不计作功能通过的替代证据。

聚焦 Gate 覆盖：非 3v3 角色层、Boss 蓄力/护法/破绽表现、WASD/J/Q/R、Tab 焦点、1280×720 与 1440×900、主线/塔/断魂庄入口，以及断魂庄三连战、失败、整备、奖励链。

## 已有人工/动态目检

此前同分支 Mac 动态目检已通过 Boss 蓄力预警、可打断反馈、破招/硬直、vulnerability window、两档分辨率、键鼠、暂停/再战、布局溢出与卡死；详 `docs/phase0/2026-08-22-phase0a-gauntlet-visual-acceptance.md`。

## 尚未验收与删除闸门

- 六人主观 Gate 尚无原始证据。
- Windows 物理机 Gate 尚未执行。
- 因此只允许保持五消费面 Phase 0A 永久切换；不允许执行旧 3v3 引擎、旧视觉路由及旧测试的全局原子删除。
- 待两个外部 Gate 齐备后，按 `docs/audit/route_c_atomic_deletion_manifest_2026-08-22.md` 单批删除并重新执行 Mac/Windows 全量验证。
