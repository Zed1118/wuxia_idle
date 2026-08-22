# 路线 C · Mac 集成 Gate 证据

- 日期：2026-08-22
- 分支：`codex/deepseek-route-c-delete-rehearsal`
- 工程基线：`01bf00feea1165ae90c4c9b0755519b2a806e1c9`
- 裁决：`MAC_PRODUCTION_ROOT_PROFILE_GATE_PASS`
- 边界：由 production root Profile runner 自动启动、采集并关闭应用，不代替用户点击；六人主观 Gate 不在本裁决内。

## 当前整合态

主线、塔、扫荡、远征、断魂庄五个生产消费面均永久走 Phase 0A 单角色 ARPG。生产代码不再保留旧 `BattleScreen`、`StageBattleSetup`、旧 battle provider 或 legacy gate 回退；历史多人会话走安全兑现与释放，不再启动旧 runner。

## 自动验收

1. 生产根应用矩阵：1280×720 与 1440×900 各 3 轮，共 **6/6 PASS**；每轮逻辑视口精确匹配，DPR=2。
2. 每轮 ≥8522 帧；最差 p99 6.011ms；severe frame 最大 1（门槛 ≤1），frame gate 全过。
3. 每轮采集 GC，最少 102 个事件；12 秒 warmup 后 RSS 采样全部通过。
4. 六份 run manifest、frame 记录、截图及统一 binary/fixture SHA 均齐全；`SHA256SUMS` 和 ZIP 完整性验证通过。
5. fixture SHA-256：`ad10b473acc77fc84002ff6a2f023d0b1212512f64a49a113094d8fc20ef3fa4`；应用自动关闭，无残留 response-handle warning。
6. 证据目录：`build/route_c_macos_matrix/20260822T125256Z`；压缩包为同名 `.zip`。该轮绑定工程基线 `01bf00fe`，真相源同步后的最终候选仍须复跑一次并以新 manifest 为准。

聚焦 Gate 覆盖：非 3v3 角色层、Boss 蓄力/护法/破绽表现、WASD/J/Q/R、Tab 焦点、1280×720 与 1440×900、主线/塔/断魂庄入口，以及断魂庄三连战、失败、整备、奖励链。

## 已有人工/动态目检

此前 Mac 动态目检已通过 Boss 蓄力预警、可打断反馈、破招/硬直、vulnerability window、两档分辨率、键鼠、暂停/再战、布局溢出与卡死；本轮 production root Profile 矩阵补齐提交绑定的性能、内存、视口和包完整性证据。详 `docs/phase0/2026-08-22-phase0a-gauntlet-visual-acceptance.md`。

## 尚未验收与删除闸门

- 六人主观 Gate 尚无原始证据。
- Windows 物理机 Gate 尚未执行。
- 因此旧 3v3 原子删除只能停留在独立候选，不允许 merge 至主线。
- 待两个外部 Gate 齐备后，按 `docs/audit/route_c_atomic_deletion_manifest_2026-08-22.md` 原子 merge，并在整合态重新执行 Mac/Windows 全量验证。
