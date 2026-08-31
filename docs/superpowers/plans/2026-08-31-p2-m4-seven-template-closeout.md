# M4 七模板工程收口计划

## 结果合同

- 单一目标：在现有四类生产模板基础上，将生存、守阵、追击补成真实生产消费，固定工程分母由 `4/7` 推进到 `7/7`。
- 基线：`main@96be15e572413929549f3723af4d565f8d8fc666`；分支 `codex/p2-m4-seven-template-closeout-20260831`；独立 worktree `/Users/a10506/.codex/worktrees/p2-m4-seven-template-closeout-20260831`。
- 生产范围：真实 migrated encounter、`Phase0aMainlineBattleHost`、既有 production flow assembler/reducer、目标事件、胜负失败与 HUD；不得停在 catalog fixture、VisualRoute 或纯领域对象。
- 非目标：不启动 M3/M7，不改存档 schema/saveVersion，不新增第二 reducer/session/headless 内核，不把真人可读性/手感挂账记为 PASS，不自行 merge/push。
- 固定分母：破路、据点、伏击、斩将继续保持 `4/4`；生存、守阵、追击各自只有在真实生产关、成功/失败语义、UI/观察、破坏证红与风险匹配回归均成立时才各记 `1/1`。
- 成本边界：无可靠 token/用量读数，以真实墙钟观察；约 90 分钟没有模板 Gate 变化时停止扩张并重评。只保留本 Gate 一个主 WIP。

## 验收标准

1. 生存：至少一场真实 production stage 使用 `survive_duration`；按真实 fixed delta 累计，时间到即胜且不要求清残兵，同拍玩家死亡优先判负；HUD 显示 typed 剩余时间。
2. 守阵：至少一场真实 production stage 使用 `defend_entity`；必须存在可被实际敌方压力破坏的独立耐久目标，长期守住才胜、目标失守即败；不得用恒真计时器或玩家本人冒充阵眼。
3. 追击：至少一场真实 production stage 使用 `pursue_target`；玩家真实接近指定移动目标后完成，未及时追上不直接硬失败；目标、事件与 HUD 必须绑定同一 canonical ID。
4. 三类目标均从现有 typed catalog 进入真实生产消费者；在线与 headless 继续共用同一 reducer/flow，不复制战斗规则。
5. 每类至少一向移除生产接线的破坏证红；另做一向退化值/恒真条件的破坏证红，精确反向还原。
6. targeted、相邻 objective/catalog/mainline/host/widget 回归、`flutter analyze --no-pub lib test`、整仓 format、macOS Debug build、持锁全量、receipt 与独立 Gate 全绿。
7. UI 在 1280×720 与 1440×900 做结构/布局 smoke；实际清晰度、压力、收尾感和桌面手感继续挂账。
8. 若现有 combat schema 无法表达守阵独立耐久或追击移动目标，必须以生产消费者证据判定 BLOCKED；不得为了凑 `7/7` 写恒真投影或在 Dart 散写产品数值。

## 任务切片

1. 核对三类 typed primitive、生产 factory、objective flow、HUD 与可用关卡/运行时绑定，先定位最小真实缺口。
2. 先写三类真实生产测试并记录 RED；拒绝只断言 YAML 字符串或对象存在。
3. 串行关闭生存真实关，再关闭追击，再处理守阵；每个子门完成后先做 targeted/邻接回归并形成可恢复提交。
4. 完成双向破坏证红，精确还原后再跑最终回归。
5. 最终 tip 生成 receipt，执行项目 Gate，冻结 clean `[READY]`；若守阵必须扩 schema 而越界，则如实 `[BLOCKED]`。

## 当前恢复点

- 状态：WIP，生产模板从 `4/7` 推进到诚实的 `6/7`；生存与追击 targeted Gate 已绿，待破坏证红和最终 Gate。
- 已完成：
  - `stage_02_02` 改为 `survive_duration`，`required_ticks: 900` 明确为 90 秒 TUNING 候选；真实 production host/headless 在第 900 拍带残敌胜利。
  - `stage_07_04` 接入 `ch7_encounter_04_grey_cloak_pursuit`；目标保留灰衣 Boss 身份，同一 entry/runtime actor ID 驱动逃逸 AI、接近投影、观察层、HUD 与终局；默认 headless bot 可完成且无硬超时。
  - 1280×720 与 1440×900 的生存/追击 HUD 结构 smoke 已覆盖；真人可读性继续挂账。
- 已跑验证：新数据/运行时/HUD 真红已记录；targeted + adjacent 共 43 项通过；`flutter analyze lib test` 零问题。无范围参数的整仓 `flutter analyze` 会进入历史独立子包 `tools/phase0minus_probe`，因其自身 package 依赖未解析报约 1900 项，非本 diff 引入。
- 下一步：提交可恢复点；对生存生产目标和追击投影/移动做双向破坏证红并精确还原，然后 format、macOS build、持锁全量与 Gate。
- 阻塞项：`CombatDefendEntityRef` 只有 `entityId + requiredTicks`，没有位置或 durability；`Phase0aArenaState` 只有单玩家与敌方 actor，生产流没有独立可受击目标 owner。按本单“不改 schema/saveVersion”红线，无法实现“敌压可毁、失守即败”的守阵语义；恒真 `EntityDefended` 计时器或把玩家冒充阵眼均被验收标准禁止。
