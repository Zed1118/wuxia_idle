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

固定分母 7 项：

1. 左键点地后角色沿任意方向平滑移动，并在目的地附近停止，不来回振荡。
2. 左键点敌人后，射程外自动追击；进入现有普攻射程后停止移动并攻击。
3. 按住左键可持续追击/普攻；目标死亡或输入失效后不残留移动、攻击状态。
4. 右键按鼠标方向释放已装备的首个数字技能；无数字技能时 fail closed，不误放其他动作。
5. 空格闪避、数字键技能和 WASD 辅助移动继续可用；WASD 当前输入优先且不与鼠标目的地叠加。
6. `stage_01_02` 真实生产入口、1600x900 左右桌面窗口真人试玩，移动/追击/攻击无拉扯、无失控、无系统提示音；由用户决定是否过 Gate。
7. 聚怪改为定点释放：按 `Q` 或点击聚怪技能印进入选点，下一次左键点击舞台后以该世界坐标筛选并聚拢敌人，玩家不被带向落点；右键可取消选点。由用户在 `stage_01_02` 判断落点准确性和生存压力是否改善。

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

- 状态：用户已确认基础移动与普攻正常，并实测反馈远端点击无法聚怪；已确认原 520 半径小于当前镜头世界对角线约 1036，且冷却/真气不可用时键盘 `Q` 仍会产生假选点。两项均已修复并完成自动化收口，等待用户真人复验。
- 最后完成：聚怪作用半径由 520 调整为 1100，覆盖同一镜头两端但不扩成无条件全地图吸怪；`Q` 仅在聚怪槽为 ready 时进入选点，冷却或真气不足不再显示十字光标后静默失效。敌人仍按点击位筛选并围绕落点聚拢，玩家不移动，涡旋锚定同一点。旧的无落点调用保留 caster fallback，避免破坏自动/headless 路径。Debug 候选已从本 worktree 重新构建。
- 下一步：用户在 `stage_01_02` 真人试玩定点聚怪；若落点准确且不再把敌群拉到自己身边，再由用户决定是否授权合并与推送。M3/M4 不启动。
- 已跑验证：定点聚怪相关 12 文件 201/201；`flutter analyze --no-pub` 0 issue；整仓格式 1648 文件、0 改动；全量 `flutter test --no-pub --reporter compact` 5721/5721；`flutter build macos --debug --no-pub` 成功。新增真实红证：旧 520 半径下远端落点拉到 0 个敌人（1 FAIL），冷却中按 `Q` 仍显示 precise cursor（1 FAIL）；修复后均复绿。此前定点结算、涡旋锚点、任意方向与目标偏好破坏证红保持有效。
- 阻塞项：自动化不能判断定点操作是否顺手、是否真实改善围杀风险。最终 Gate 仍须用户在 `stage_01_02` 真实生产入口签字；当前仅为候选，不代表 G2 PASS。

## §8.2 交付清单

- 生产接线：真实 `Phase0aBattleScreen` 入口；命令经 `Phase0aPlayerCommand`、`Phase0aPlayerInputAdapter`、既有 intents 和 reducer 消费，不停在 fixture/VisualRoute。
- 定向验证：定点聚怪相关 12 文件 201/201、远端落点范围与不可用 `Q` 假选点两项新增红证、5721/5721 全量、analyze 0、macOS Debug build 成功。
- 红线影响：仅将聚怪作用半径 520 调整为 1100，并同步 production、legacy fallback 与 debug fixture；不改伤害、冷却、真气消耗、schema/saveVersion、checkpoint 归因、在线/离线 reducer、三系锁死或反主流清单；未新增 Dart 中文文案和高频 debug 日志。
- 桌面语义：空格闪避、数字键技能、WASD 保留；WASD 当前输入覆盖鼠标目的地；鼠标左/右键走真实 pointer 入口。`Q`/聚怪技能印进入定点态，左键释放、右键取消。常规桌面视口的落点准确性与生存压力由本轮真人试玩收口。
- 残留风险：第三方 `audioplayers_darwin` 有 Swift actor warning，Xcode Flutter Assemble 有既有脚本提示；均未阻止构建。右键在无已装备数字技能时 fail closed。真人手感未签字前不得晋升 G2。
