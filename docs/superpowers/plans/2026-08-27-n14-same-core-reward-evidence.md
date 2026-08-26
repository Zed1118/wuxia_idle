# N14 同核奖励证据结果合同与恢复点

## 结果合同

- 单一目标：把 N2 L56 的 7 组“无法判定”转成可复跑 PASS/FAIL；不修改产品规则。
- 固定验收门：`0/7 可判定 → 7/7 可判定`；仅 `7 PASS` 可 `[READY]`，任一 FAIL/不可判定/seed 不稳/需改 `lib/` 均 `[BLOCKED]`。
- 实时基线：分支 `codex/p2-same-core-evidence-20260827`，base `b3a1b1cf`，开工工作树 clean，main 未改。
- 关键阻塞：sweep 公共结果不暴露逐 tick trace；有界方案是记录其同一 mapper/assembler/public async kernel，并用真实 `Phase0aSweepHeadlessRunner` 终局反校验，不新增生产接口。
- 预期增量：本 N14 证据门 `0/7 → 7/7`；不晋升 M0–M9、Phase 2 或其他活动同核结论。
- 成本上限：墙钟约 90 分钟无门变化即停线；只写 `test/`、`docs/audit/` 与本恢复点。

## 范围与非目标

- 真实 `stage_01_01`、同一生产角色快照、固定 battle/reward seed；manual/bot/headless/sweep 逐 tick hash、事件、结算与三次重复掉落 profile。
- 奖励随机走 `rngProvider` override；战斗随机走既存 `mathRandomProvider` override；不新增 `dart:math Random` 签名 service。
- 禁改 `lib/`、`data/numbers.yaml`、`GDD.md`、`PROGRESS.md`、`lib/shared/strings.dart`、`pubspec.yaml` 与外部优化方案；禁 push/merge/main/revert。
- 不把 `stage_01_01` 或旧 `stage_01_03` 结果外推到塔、远征、断魂庄或全关卡。

## §8.2 验收 checklist

- [x] 生产接线证据：真实 controller/input adapter、sync/async headless kernel、生产 sweep runner 与 `applyVictoryResolution`/两条 sweep settlement 入口。
- [x] targeted：新证据测试同命令连续两次 `7/7 PASS` 且 hash 不变；真实键鼠屏、mainline、sweep 相邻域全绿。
- [x] 红线影响：0 产品/YAML/数值/schema/saveVersion 改动；不触及三系、在线=离线、反主流或文案硬编码。
- [x] 残留风险：只证明一个真实主线活动的四模式；sweep 逐 tick 由同一 production components 记录并以真实 runner 终局反校验，公共 API 本身仍只返回终局。
- [x] 集成态：只含允许的 test/audit/plan 文件；无 `skip:`；格式与 scoped analyze 通过。

## 当前恢复点

- 状态：`READY candidate`；证据门 `7/7 PASS`，无 BLOCKED 出口命中。
- 稳定摘要：battle `3898e0822cd4fc59` / 76 ticks；reward `3f5cec5f1b4acbbb`；三次重复装备多重计数为布衣 3、铜铃 2。
- 已跑：新测试三次均 `7/7`；键鼠屏 `27/27`；mainline 全目录 PASS；sweep `50/50`；新文件 analyze 0 issue。
- 下一步：提交 `[READY]` 中文动宾 tip 后运行外部 `gate.sh` 全量模式；若 Gate 红，保持本分支不合并并按实际失败转 `[BLOCKED]`。
