# P2-M2-R09：目标感知的动态遭遇流

## 目标与边界

在 Batch12 的动态 `Phase0aEncounterFlow` 与 R06 objective tracker 之间交付一条显式、可原子提交的 objective 接缝。调用方只能从单拍不可变 frame 的真实事实投影有序 objective events；flow 不猜 target、commander、checkpoint、role、ID 或时间语义。

- 分支：`codex/phase2-m2-r09-objective-aware-encounter-flow-20260824`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-m2-r09-objective-aware-encounter-flow`
- 基线：`81d47f16880b2b9d7a860379cf308cca3f6110e2`
- 允许：tracker、新 encounter objective event source、encounter flow、两份 targeted test 与本计划。
- 禁止：assembler、task/decision registry、audit、production host/data/main、reward/save/UI/failure policy/tuning 与其他 worktree。

## 冻结合同

- tracker 的 prepared transition 精确保留 tracker owner/base/next；prepare 只在局部快照上归约，commit 用 owner + base identity/equality 做 CAS，foreign/stale/double commit 全部 fail closed。
- objective runtime 只能成对配置 tracker + source。两者都为 null 时保持现有动态遭遇胜负、事件、state、records 与 RNG 调用语义。
- 配置 objective 后，玩家死亡优先且不提交 objective；objective completion 是唯一 victory 真相源，不再由场空、director exhausted 或旧 `surviveTicks` 自动判胜。
- source、lazy iterable、controller 归约或 records/return snapshot 投影任一失败时，flow 不提交 session/director/outcome/records/objective progress。objective commit 是所有可抛投影成功后的最后一次可抛操作，随后只做不抛的引用赋值。
- 现有 resolver/RNG 无 rewind API。本任务不新增随机消费，也不声称 resolver 抛错前已消费的 RNG 可回滚。

## 验收 checklist（CLAUDE §8.2）

- [x] tracker 覆盖原子批 prepare/commit、all/any、foreign/stale/double commit、duplicate 与 terminal no-op。
- [x] frame 只暴露 before/after arena、before/after spawn、director/spawn/combat events 与 delta 真实事实，容器防御性不可变。
- [x] flow 覆盖成对配置、显式 target/commander、kill 后 checkpoint、场空未完成 ongoing、活敌下 objective victory、玩家死亡优先、duplicate、terminal no-op 和 null 旧语义。
- [x] source immediate/lazy 失败与可达投影失败动态证明四类 flow 状态和 objective progress 不提交。
- [x] `ObjectiveController`/八 primitive 现为 `final`/sealed，无可注入 throw 实现；不扩大 domain 或新增测试缝。controller throw 的回滚以局部归约后才返回 transition 的结构保证，不伪造不可达测试。
- [x] targeted + 受影响回归、scoped analyze、format check、`git diff --check` 与 owned-files 白名单审计全绿。
- [x] 生产接线证据：本切片交付 runtime flow 显式 opt-in 接缝，但按授权不修 assembler/host，不冒充生产 route 已切换。
- [x] 红线：0 production 数值/YAML、0 玩家文案、0 reward/save/UI/failure policy/tuning，不触三系/在线离线/反主流边界。
- [x] 实现/证据小提交后追加精确 `[READY][CODEX][P2-M2-R09]` 空提交，工作树干净。

## 任务切片

1. 读取项目红线、已否登记、R03/R04/R06、flow/session/director/events 与动态遭遇测试。
2. 红：先增 tracker prepared CAS 和 objective-aware flow 合同测试，确认因 API/文件缺失失败。
3. 绿：实现 tracker transition、不可变 frame/source 与 flow 原子集成。
4. 验收：逐文件 targeted、受影响回归、scoped analyze、format/diff/path 审计。
5. 更新恢复点，小提交实现与证据，自审后追加 READY。

## 当前恢复点

- 状态：实现、验证、证据与 READY 冻结完成，待主控独立评审。
- 最后完成：tracker 新增 owner-bound prepared transition/CAS；flow 新增不可变 frame + 显式 source，objective 成对配置后以 completion 作唯一 victory 真相源，并把 objective commit 推迟到所有可抛投影之后。实现提交：`b20bdd74`、`bb6a3792`。
- 下一步：主控核对真实 diff、原子性、验证证据与 P0/P1/P2 后决定整合。
- 已跑验证：11 份 targeted/受影响回归逐文件执行，tracker 15 + objective flow 13 + dynamic flow 12 + compatibility 4 + consumers 2 + production assembler 23 + observer 1 + encounter mapping 15 + session seams 15 + controller 8 + objective primitives 9 = 117/117 通过；scoped `flutter analyze --no-pub` 5 项 0 issue；Dart format 5 文件 0 changed；`git diff --check` 通过。
- 阻塞项：无。
- 自审：P0=0、P1=0、P2=0。确认无 objective 身份/角色/时间推断，无部分 objective 提交，无 null 路径胜负漂移，无越界生产接线。
- 残留风险：本任务只配置 flow 明确消费的 objective source，不切换 assembler/host；objective 事件语义正确性由后续 caller source 负责；resolver 失败前已消费的 RNG 不可回卷；controller throw 回滚为结构保证，现有 sealed/final API 下无诚实的直接注入测试。
