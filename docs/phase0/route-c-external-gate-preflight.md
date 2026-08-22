# Route C 外部 Gate 预检

> 状态：`HUMAN_PENDING / WINDOWS_PENDING`。预检只防串包、缺样本和旧 probe 冒签，
> 不代替真人操作或 Windows 最低档物理机采样。

## 对象纠偏

历史 `phase0a-playtest-protocol.md` 的“旧战斗→新灰盒” AB 对照，以及
`tools/phase0minus_probe` 的 Windows 性能矩阵，均属早期隔离 probe 证据。它们可供
历史追溯，但不能签 Route C 生产根应用删除 Gate。

新证据必须同时绑定：

- 待删候选 commit；
- 根应用 `wuxia_idle` 的 Profile binary SHA-256；
- 生产 Phase 0A 可玩路由 `phase0a_battle_playable`；
- 六人全部同包，Windows 六次全部同 binary。

## 六人原始样本

每人一个 `human-session.json`，schema 为 `route-c-human-session-v1`，只用
`P01`–`P06` 匿名编号。除既有爽感、可读性、再战意愿外，必须原始记录：

- Boss 蓄力预警是否被看到；
- 可打断反馈是否被理解；
- 破招后硬直是否被看到；
- vulnerability window 是否被理解；
- 键鼠是否由测试者本人完成；
- 是否无溢出、卡死、实现者代打或外部污染。

## Windows 物理机样本

保留 `phase0a-windows-physical-gate.md` 的最低档硬件、本地 Console、60Hz、100% 缩放与
两视口各三次要求，但采样对象改为根应用 Profile binary。每次结果目录必须有
`manifest.json`，schema 为 `route-c-windows-production-run-v1`，且组合性能 Gate 已由
生产版采样器判为 `PASS`。旧 `phase0minus_probe.exe` 结果会被预检直接拒绝。

## 执行

```bash
dart run tool/route_c_gate_preflight.dart \
  --candidate <candidate-ref> \
  --human-dir <six-human-results> \
  --windows-dir <windows-matrix-results> \
  --output <preflight-report.json>
```

退出码：`0=PASS`、`2=PENDING`、`1=INVALID`。只有三项 Gate 都通过后，才能将候选
删除提交原子整合到主线并重跑全量验证。
