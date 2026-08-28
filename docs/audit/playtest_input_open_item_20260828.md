# 挂账 · 真人试玩输入现象未定性(2026-08-28)

## 状态

`OPEN` — 待一次 10 秒真人验证。**不阻塞其他派单,阻塞 G2 八项试玩**。

## 现象(用户原话)

在链 tip `1ba913a6` 编译的 macOS app 里进第 8 章战斗:「无法移动,也无法放技能,只能普攻」。

## 已实测证伪的(codex D1 单,分支 `codex/p2-d1-input-blocker-diagnosis-20260828`)

- **移动链正常**:CGEvent 发 `W` → `KeyDownEvent` 到达 → `_heldMovementKeys` `[]`→`[W]` →
  每 0.1s tick 采样 → 产出 `Phase0aMoveIntent` → reducer 实际位移
  `(-320,0)→(-320,-147)`,连续 7 拍。`defenseConsumed=false`、`suppressedActorIds={}`。
- **技能未全空**:该存档 `numericSkillBindings.equipped.length=1`。
  槽 2 = `skill_gangmeng_jichu_skill`(重击)**实测可释放**,产出
  `Phase0aSkillStarted`/`SkillApplied`/`EnemyDefeated`,放完真气 37。
- **六槽真实状态**:1=普攻(按拍板规则排除,避免鼠标+数字键双入口重复结算)、
  2=重击(唯一 equipped)、3–6=`null` 未装备。封印区 UI 实际渲染
  `1/3/4/5/6 未装备`、`2 重击 可用`,不是整区缺失。

结论:**代码层没有可修的确定性 bug**,D1 单以 `[BLOCKED]` 交付,未合并。

## 未证实的主假设(协调者,2026-08-28)

用户当前选中输入法为**搜狗拼音**(`com.sogou.inputmethod.pinyin`,读自
`~/Library/Preferences/com.apple.HIToolbox.plist` 的 `AppleSelectedInputSources`)。

若试玩当时处于中文输入态,可一次性解释全部现象:
WASD 被 IME 吞作拼音、数字键 1–6 被 IME 当候选词选择键吞掉、鼠标左键不经 IME 故普攻正常
(普攻主键 `J` 与鼠标左键按住皆可,用户未说明用的哪种)。
codex 用 CGEvent 直接投递绕过 IME 层,故复现不了。

**这是假设不是结论**:只读到了「此刻」的输入法状态,无法证明试玩当时同态。

## 待验证动作

切 ABC 英文输入法 → 进战斗 → 按 `W` 与 `2`。

- 能动且技能能放 → 根因为 IME,非游戏缺陷,转「已知环境事项」并解除 G2 挂账
- 仍不行 → 本假设被证伪,改往焦点层排查(`phase0a_battle_screen.dart` 的
  `onFocusChange` → `_clearHeldInput` 链),重新派单

## 相关

- 诊断全文:D1 分支内 `docs/audit/playtest_input_blocker_diagnosis_20260828.md`(46 行)
- G2 八项 runbook:`docs/dispatch/G2_playtest_runbook_20260827.md`
- 存档已备份:`~/Desktop/wuxia_save_backup_20260828/`(slot1 sha256 前缀 `9a79f3e1`)
