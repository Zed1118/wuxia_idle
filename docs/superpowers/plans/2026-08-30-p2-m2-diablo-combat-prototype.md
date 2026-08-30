# P2 M2 暗黑式战斗纵切计划

## 目标

在当前 `23eaeb019455258939218ea9381c096af6523a79` 基线上，将第一章真人战斗的输入闭环改为暗黑式桌面操作：左键点地移动、左键点怪追击并连续普攻、右键释放主技能、数字键释放已装备技能、空格闪避。以 `stage_01_02` 真人愿意继续战斗作为唯一权威 Gate。

## 分支

- `codex/p2-m2-diablo-combat-prototype-20260830`
- worktree: `/Users/a10506/.codex/worktrees/p2-m2-diablo-combat-20260830`

## 非目标

- 不照搬《暗黑破坏神》的角色、技能、美术、声音、名称、界面素材或数值。
- 不重做装备掉落、关卡内容、敌人模板、伤势规则或长期构筑。
- 不改 schema/saveVersion，不改伤害、移速、冷却、射程等现有 YAML 数值。
- 不启动 M3/M4，不把自动化绿测冒充真人手感验收。

## 验收标准

固定分母 6 项：

1. 左键点地后角色沿任意方向平滑移动，并在目的地附近停止，不来回振荡。
2. 左键点敌人后，射程外自动追击；进入现有普攻射程后停止移动并攻击。
3. 按住左键可持续追击/普攻；目标死亡或输入失效后不残留移动、攻击状态。
4. 右键按鼠标方向释放已装备的首个数字技能；无数字技能时 fail closed，不误放其他动作。
5. 空格闪避、数字键技能和 WASD 辅助移动继续可用；WASD 当前输入优先且不与鼠标目的地叠加。
6. `stage_01_02` 真实生产入口、1600x900 左右桌面窗口真人试玩，移动/追击/攻击无拉扯、无失控、无系统提示音；由用户决定是否过 Gate。

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
6. targeted → analyze → 风险相匹配回归 → 桌面真人试玩。

## 当前恢复点

- 状态：候选已冻结前收口；生产输入纵切、风险匹配验证和 macOS 构建均完成，等待用户真人手感 Gate。
- 最后完成：左键点地、点怪追击/连续普攻、目标偏好、右键首数字技能、WASD 优先及目标反馈均已接入真实 `Phase0aBattleScreen`；主线/塔/断魂庄 Host 显式传入既有普攻射程。Debug 候选已从本 worktree 构建并启动。
- 下一步：用户在 `stage_01_02` 真人试玩；若手感通过，再由用户决定是否授权合并与推送。M3/M4 不启动。
- 已跑验证：核心整屏 34/34；输入/右键技能/主线 Host/控制相邻域 40/40；`flutter analyze --no-pub` 0 issue；整仓格式 1648 文件、0 改动；全量 `flutter test --no-pub --reporter compact` 5715/5715；`flutter build macos --debug --no-pub` 成功。破坏证红：切断任意方向后 3/4（1 FAIL），切断目标偏好后目标由 `wave1_archer` 错成 `wave1_blade`（1 FAIL）；均已精确还原并复绿。
- 阻塞项：自动化不能回答“是否愿意继续战斗”。最终 Gate 仍须用户在 `stage_01_02` 真实生产入口签字；当前仅为候选，不代表 G2 PASS。

## §8.2 交付清单

- 生产接线：真实 `Phase0aBattleScreen` 入口；命令经 `Phase0aPlayerCommand`、`Phase0aPlayerInputAdapter`、既有 intents 和 reducer 消费，不停在 fixture/VisualRoute。
- 定向验证：34/34 核心整屏、40/40 相邻域、两项破坏证红、5715/5715 全量、analyze 0、macOS Debug build 成功。
- 红线影响：不改 YAML 数值、schema/saveVersion、checkpoint 归因、在线/离线 reducer、三系锁死或反主流清单；未新增 Dart 中文文案和高频 debug 日志。
- 桌面语义：空格闪避、数字键技能、WASD 保留；WASD 当前输入覆盖鼠标目的地；鼠标左/右键走真实 pointer 入口。常规桌面视口的最终运动感和目标可点性由本轮真人试玩收口。
- 残留风险：第三方 `audioplayers_darwin` 有 Swift actor warning，Xcode Flutter Assemble 有既有脚本提示；均未阻止构建。右键在无已装备数字技能时 fail closed。真人手感未签字前不得晋升 G2。
