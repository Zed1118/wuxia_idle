# P2 M2 暗黑式战斗纵切计划

## 目标

在当前 `23eaeb019455258939218ea9381c096af6523a79` 基线上，将第一章真人战斗的输入闭环改为暗黑式桌面操作：左键点地移动、左键点怪追击并连续普攻、右键释放主技能、数字键释放已装备技能、空格闪避。以 `stage_01_02` 真人愿意继续战斗作为唯一权威 Gate。

## 分支

- `codex/p2-m2-diablo-combat-prototype-20260830`
- worktree: `/Users/a10506/.codex/worktrees/p2-m2-diablo-combat-20260830`

## 非目标

- 不照搬《暗黑破坏神》的角色、技能、美术、声音、名称、界面素材或数值。
- 不重做装备掉落、关卡内容、敌人模板、伤势规则或长期构筑。
- 不改存档 schema/saveVersion，不改伤害、移速、冷却、射程；本轮仅按真人反馈调整聚怪落点圈并为 pull behavior 增加显式控制拍数。
- 不启动 M3/M4，不把自动化绿测冒充真人手感验收。

## 验收标准

固定分母 7 项：

1. 左键点地后角色沿任意方向平滑移动，并在目的地附近停止，不来回振荡。
2. 左键点敌人后，射程外自动追击；进入现有普攻射程后停止移动并攻击。
3. 按住左键可持续追击/普攻；目标死亡或输入失效后不残留移动、攻击状态。
4. 右键按鼠标方向释放已装备的首个数字技能；无数字技能时 fail closed，不误放其他动作。
5. 空格闪避、数字键技能和 WASD 辅助移动继续可用；WASD 当前输入优先且不与鼠标目的地叠加。
6. `stage_01_02` 真实生产入口、1600x900 左右桌面窗口真人试玩，移动/追击/攻击无拉扯、无失控、无系统提示音；由用户决定是否过 Gate。
7. 聚怪改为定点释放：按 `Q` 或点击聚怪技能印进入选点，下一次左键点击舞台后以该世界坐标筛选并聚拢敌人，玩家不被带向落点；右键可取消选点。生产落点圈收至 60，受影响敌人独立停止行动 5 拍（0.5 秒），不得借用踉跄破防语义；由用户在 `stage_01_02` 判断聚拢完整性和生存压力是否改善。

## 生产接线与红线检查

- 入口：`Phase0aBattleScreen` 的真实舞台指针层。
- 消费：`Phase0aPlayerCommand` → `Phase0aPlayerInputAdapter` → 既有 `Phase0aMoveIntent` / `Phase0aAttackIntent` / `Phase0aSkillIntent` → 同一 reducer。
- 不新增结算真相源；自动、headless 仍消费同一 reducer，在线=离线规则不变。
- 不触及数值硬红线、三系锁死、反主流清单、schema/saveVersion。
- UI 文案如需新增只进入 `UiStrings`；本纵切预计不新增中文文案。

## 任务切片

1. 扩展玩家命令以承载归一化的任意方向移动，保留四向键兼容。
2. 在表现层维护鼠标目的地与锁定目标，逐 fixed tick 生成同一玩家命令。
3. 生产 Host 显式传入现有普攻射程，禁止表现层复制数值。
4. 增加目标选择反馈与右键首技能入口。
5. 补 domain/application/widget 回归，做破坏证红。
6. 将聚怪 geometry 从 caster anchor 接到 target-point anchor，并让涡旋与拉拢结算共用同一落点。
7. targeted → analyze → 风险相匹配回归 → 桌面真人试玩。

## 当前恢复点

- 状态：用户已确认定点聚怪会拉动敌人，但反馈部分敌人在尚未聚稳时立即恢复行动。根因是生产落点停在距中心 120 的环上，且 reducer 没有任何聚怪持续控制。现已实现独立控制运行态并收紧落点圈，自动化收口完成，等待用户真人复验。
- 最后完成：`skill_phase0a_gather` 的 pull behavior 现显式声明 `destinationRadius: 60` 与 `controlTicks: 5`；生产 binding 将控制拍数传入同核 reducer。存活目标聚拢后停止移动、普攻和技能 5 拍，AI 适配器与 reducer 双闸一致；该状态不设置 `staggerTicksRemaining`，不会附加踉跄减防/破绽。环内目标虽不被外推，也同样停留 5 拍。未改存档 schema、伤害、冷却、真气、作用半径或玩家移动。
- 下一步：从本 worktree 构建并重启 macOS 候选；用户在 `stage_01_02` 将远近多名敌人聚到鼠标落点，重点观察是否能完整收拢、是否在漩涡结束前散开，以及 0.5 秒后恢复是否自然。通过后再由用户决定是否授权合并与推送。M3/M4 不启动。
- 已跑验证：相关 11 文件 145/145；`flutter analyze --no-pub` 0 issue；整仓格式 1648 文件、0 改动；带锁全量 `flutter test --no-pub --reporter compact` 最终 5724/5724、`[E]` 0。真实 RED：未实现时新增 schema/生产映射/reducer 用例编译失败；删掉 reducer 控制写入后控制用例 1 FAIL（预期 5、实际 0）；生产落点恢复 120 后映射用例 1 FAIL（预期 60、实际 120）。首次全量另发现 2 条数值默认值源码契约失败，移除默认参数并显式传值后复绿。
- 阻塞项：自动化不能判断 60 落点圈与 0.5 秒控制的真人体感是否恰当。最终 Gate 仍须用户在 `stage_01_02` 真实生产入口签字；当前仅为候选，不代表 G2 PASS。

## §8.2 交付清单

- 生产接线：真实 `Phase0aBattleScreen` 入口；命令经 `Phase0aPlayerCommand`、`Phase0aPlayerInputAdapter`、既有 intents 和 reducer 消费，不停在 fixture/VisualRoute。
- 定向验证：聚怪控制相关 11 文件 145/145，双向破坏证红有效；5724/5724 全量、analyze 0；`flutter build macos --debug --no-pub` 成功生成 `wuxia_idle.app`。
- 红线影响：新增的是战斗配置 `pull.controlTicks`，不是存档 schema；聚怪落点圈 120→60、控制 5 拍，作用半径仍 1100。未改伤害、移速、冷却、真气消耗、checkpoint 归因、max_targets、在线/离线 reducer、三系锁死或反主流清单；未新增 Dart 中文文案和高频 debug 日志。
- 桌面语义：空格闪避、数字键技能、WASD 保留；WASD 当前输入覆盖鼠标目的地；鼠标左/右键走真实 pointer 入口。`Q`/聚怪技能印进入定点态，左键释放、右键取消。常规桌面视口的落点准确性与生存压力由本轮真人试玩收口。
- 残留风险：60 落点圈与 0.5 秒控制仍是待真人判断的手感参数；真人未签字前不得晋升 G2。本轮 macOS Debug 构建成功，未产生新 warning。
