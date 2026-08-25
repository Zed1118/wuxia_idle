# P2-M6-E2E-MANUAL-DISPATCH-REPORT 结果合同

- 唯一目标：关闭百草岭“宗门/江湖地图 → 真实差遣入口 → eligible 实际参与者 → durable participant snapshot → 统一占用 → Phase 0A headless 自动/离线生产路径 → 共享战斗账本 → 返程实际参与者报告”生产子门。
- 固定验收门：本任务 0/1 → 1/1；顶层 M0–M9 基线与完成后口径均保持 1/10，M6 保持 WIP，不把本子门冒充 M6 或 Phase 2 完成。
- 实时基线：READY 串行链 tip `47b2d4a706ed38c13181c0250866fc3f775e0604`；registry 145 项（144 `ready_reviewed` + 1 `completed`），无 active WIP；primary main clean `e292d3a069fbc0e129dd74fafc1ebb3746f53557`。
- 当前关键阻塞：参与请求未进入真实远征链；真实 runner 终局未进入 `CombatResolutionService` 且缺 stale/loadout fail-closed；返程结果不携带实际参与者身份。
- 预期增量：只关闭上述 1 个 M6 生产子门；不推进顶层分母，不宣称 U01/U09/U10/U14 或 G2 关闭。
- 成本上限：以本任务墙钟耗时为主成本读数；90 分钟无验收门变化立即停线重评。只跑定向与相邻域，候选稳定后最多一次必要全量。
- 主 WIP：`P2-M6-E2E-MANUAL-DISPATCH-REPORT`；不接管、不删除、也不把未登记 worktree `/Users/a10506/Desktop/Projects/挂机武侠-phase2-m6-e2e-manual-dispatch-report` 当证据。
- 明确非目标：schema/saveVersion、YAML、TUNING/candidate、奖励/经济/解锁/叙事/战斗规则；旧 3v3、前台断魂庄 bot、代选奖励、统一完成报告；main 修改/合并/push；新增 reducer/session/headless/provider/settlement 真相源。

## 验收证据

1. RED：非法/悬空掌门、跨代、死亡、疗养、无主修、重复占用、provider 异常、悬空装备/心法、stale participant、错人 settlement 均被契约覆盖。
2. GREEN：真实 UI 只提交 typed participation request；落库 participant snapshot 与实际选择一致；生产 runner 只消费该 snapshot，终局只结算该参与者。
3. 共享结算：装备战斗次数、招式使用/修炼度等由既有 `CombatResolutionService` 处理；远征会话奖励、经验与伤势仍由原 owner 处理，禁止双结算。
4. 报告：现有返程行记显示实际参与者；身份悬空时 fail closed，不生成假报告。
5. 验证顺序：定向 RED/GREEN → 活动域 → 相邻主线/占用/结算域 → `flutter analyze --no-pub lib test` → diff/白名单/语义复核 → 稳定后一次必要全量 → 文档/registry 同步 → clean READY。
