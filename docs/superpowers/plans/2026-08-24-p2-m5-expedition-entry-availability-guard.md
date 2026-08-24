# P2-M5 远征入口存活资格守卫计划

## 目标与边界

- 任务：`P2-M5-EXPEDITION-ENTRY-AVAILABILITY-GUARD`。
- source base：`8296db0c033b64faa1eb09b24f2f22269f281363`。
- 分支：`codex/phase2-m5-expedition-entry-availability-guard-20260824`。
- 生产目标：在 `ExpeditionService.dispatch` 的权威 `writeTxn`
  内，对 canonical `Character.isAlive` 进行入口复检；已故、有主心法且
  空闲的角色必须 fail closed。
- 原子性：拒绝时不建 `ExpeditionRun`，不推进
  `SaveData.expeditionRunSerial`。
- 保持不变：正常派遣、founder、occupied/no-main、single-active、
  奖励、数值、schema 与 UI 行为。
- 不扩展为新的 availability 架构，不处理 run 进行中死亡，不修改
  registry / `CLAUDE.md` / `GDD.md` / `PROGRESS.md`，不碰 main/origin main。

## Owned files

1. `lib/features/expedition/application/expedition_service.dart`
2. `test/features/expedition/expedition_dispatch_test.dart`
3. `docs/superpowers/plans/2026-08-24-p2-m5-expedition-entry-availability-guard.md`

## 交付验收

- [x] 生产入口在同一 `writeTxn` 内重读 canonical `Character`，并在任何
  run/serial 写入前拒绝 `isAlive == false`。
- [x] TDD 红灯先证明现状会错误建 run；实现后同一测试转绿。
- [x] 死亡 + 有主心法 + 空闲回归同时断言抛错、run count=0、
  serial 不变，防止仅断言 throw 的 fake-green。
- [x] 死亡矩阵覆盖：dead-only serial=0、alive 落库后独立事务改 dead 并只
  传 ID、预置 serial=41 后失败仍为 41、alive control 成功且 serial 精确
  +1。
- [x] 既有 dispatch 整文件回归保持正常派遣、founder、occupied/no-main、
  single-active 行为。
- [x] 运行 focused dispatch、完整 `test/features/expedition`、scoped
  analyze、format 与 `git diff --check`。
- [ ] 同一 Pi 模型对 `base..final` 实际 diff 进行只读终审，triage 后
  P0/P1 清零。
- [ ] 所有实质修改已提交，最后只追加一个 `[READY]` 提交，worktree
  clean。

## Pi 实现前只读设计审查

- Pi CLI：`0.84.1`。
- model：exact `deepseek/deepseek-v4-flash`。
- thinking：`high`。
- 权限：仅 `read,grep,find,ls`；`--no-session --no-skills`；无
  `bash/edit/write`，零写入。
- 完整命令：

```text
pi --no-session --no-skills --model deepseek/deepseek-v4-flash --thinking high --tools read,grep,find,ls --print '你是本任务的实现前只读设计审查员。严格禁止修改文件，禁止使用 bash/edit/write，只能读取。项目根目录就是当前目录。请实际读取 CLAUDE.md、GDD.md、/Users/a10506/Desktop/二阶段优化方案.md 中与角色存活/活动占用/远征相关部分，并完整读取 lib/features/expedition/application/expedition_service.dart、test/features/expedition/expedition_dispatch_test.dart、lib/core/domain/character.dart、lib/features/activity/application/character_occupancy_service.dart、lib/features/expedition/application/expedition_providers.dart。任务 P2-M5-EXPEDITION-ENTRY-AVAILABILITY-GUARD：唯一代码/测试 owned files 是 expedition_service.dart 与 expedition_dispatch_test.dart；另可新建 source plan docs/superpowers/plans/2026-08-24-p2-m5-expedition-entry-availability-guard.md。目标是在 ExpeditionService.dispatch 创建任何 run 之前，于其权威 write transaction 内，对 canonical Character 与 occupancy 重新检查死亡状态；死亡但有主心法且空闲的角色必须 fail closed，不能创建 ExpeditionRun，不能推进 expeditionRunSerial；保持正常派遣、founder、occupied/no-main、single-active、奖励/数值/schema/UI 行为不变。请审查最小实现位置、校验顺序、TDD 测试应如何证明 transactional rollback 和避免 fake-green，并识别 P0/P1/P2 风险。不要建议超出 owned files 的架构扩展。输出格式：DESIGN PASS 或 DESIGN REVISE；MODEL EVIDENCE（明确写 deepseek/deepseek-v4-flash、thinking high、read-only）；建议实现；测试矩阵；findings（P0/P1/P2，没有则写 0）。'
```

- 运行结果：exit `0`。
- 原始结论：`DESIGN PASS`；P0=0，P1=0，P2=3。
- 采纳：存活复检放在事务内 canonical `Character` 重读后、
  `entryMaxTier`/占用/快照/serial 之前；新路径不更改既有存活 founder
  行为；
  新回归使用真 Isar + 真 `dispatch`，同时断言 run count 与 serial。
- P2 triage：重伤等其他资格、run 中途死亡、未来寿命写端 e2e 均超出
  本任务 owned scope，如实保留为后续边界，不扩张实现。

## 主控独立 Codex 只读审查补充

- 结论：raw bypass 在 `dispatch` 的 `writeTxn` 内 canonical
  `Character` 读取后闭合；死亡权威定义只是 `isAlive == false`。
- 采纳的更严格顺序：dead gate 紧跟 null 检查，早于
  founder/occupancy/snapshot/serial。Pi 建议的 founder 优先级不是现有测试或
  玩家文案合同；按主控终审要求采用更早的死亡权威闸。
- 四项必测：
  1. dead-only（非 founder、有主心法、无占用/active run）拒绝，
     run=0，serial 不变；
  2. 先落 alive，再于独立事务改 dead，调用仅传 ID，证明 canonical
     reload；
  3. 预置 serial=41，失败后仍为 41；
  4. alive control 成功且 serial 精确 +1。
- 测试夹具禁止同时命中 founder/occupied/no-main 旧 gate；不用
  injury/HP/downed 代替 `Character.isAlive`。

## 任务切片

1. 读取项目规约、二阶段方案、现有 service/test，完成 Pi 只读设计审查。
2. 先加死亡入口回归，运行 focused dispatch 获得有效红灯。
3. 仅在 `dispatch` 事务内增加最小存活复检，转绿后提交实现。
4. 运行 focused/full-feature/analyze/format/diff/path/status 验证。
5. 将 `base..final` 实际 diff 交给同一 Pi 只读终审，triage 后收口证据。
6. 复核白名单、分支与 clean 状态，追加唯一 `[READY]` 提交。

## 当前恢复点

- 状态：实现、TDD 与本地验证完成，待 Pi 实际 diff 终审。
- 最后完成：`dispatch` 在权威 `writeTxn` 内读取 canonical `Character`
  后，紧跟 null 检查拒绝 `isAlive == false`；新测由 11 pass / 3 fail 转为
  focused dispatch 14/14 PASS。
- 下一步：提交验证证据，将 `8296db0c...HEAD` 实际三文件 diff 交给
  同一 Pi 配置只读终审。
- 已跑验证：Pi 只读审查 exit 0；首轮 focused 在 native-assets 编译前
  崩溃，二轮因 fresh worktree 缺少 gitignored Isar `*.g.dart` 编译失败，
  两者均不计业务红灯；`flutter pub get --offline` 与
  `dart run build_runner build` 恢复本地派生态且零 tracked diff 后，focused
  获得上述有效 11/3 红灯；实现后 focused dispatch 14/14、完整
  `test/features/expedition` 108/108；`flutter analyze --no-pub` scoped 2 items
  0 issue；format 2 files / 0 changed；`git diff --check` 与 owned-path guard PASS；
  验证后 worktree clean。
- 阻塞：无。

## READY

最终唯一 READY 提交固定为：
`[READY][PI][P2-M5-EXPEDITION-ENTRY-AVAILABILITY-GUARD] 补齐远征入口存活守卫`。
