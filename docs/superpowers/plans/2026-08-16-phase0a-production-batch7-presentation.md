# Phase 0A 根应用生产化第七批：debug 正式表现层首切片

## 目标

在第六批生产装配器之上新增一个仅 debug 可达的纯 Flutter 单角色水墨 ARPG 战斗屏。它必须真实消费 `Phase0aWaveBattleFlow.state` 与 `Phase0aEvent`，把已经稳定的确定性模拟核变成可操作、可读、明显脱离 Demo 感的根应用画面；本批不切任何生产入口。

## 视觉方向

- 方向：克制水墨长卷 + 强烈关键帧反馈。常态依靠低彩场景、宣纸技能印、墨色层次和不对称留白建立气质；出手、命中、Q、R、换波和终局采用短促高对比反馈。
- 记忆点：角色在横向长卷中按脚底锚点真实移动，远近由 y 轴缩放、遮挡顺序、接地阴影和雾层共同表达；战斗不是把头像/几何图形摆在平面面板上。
- 复用根应用现有 `BattleSceneBackground`、水墨色板、字体、伤害飘字/血条视觉语言和正式角色/敌人资产；不得依赖或修改 `tools/phase0minus_probe`。
- 全体存活敌人持续显示名称与血条；任何命中必须有伤害数字。技能印大小统一，不因技能名长短变化。

## 冻结范围

### 新增

1. `lib/features/battle/presentation/phase0a/`：
   - debug 战斗屏与固定拍控制器；
   - world→screen 纵深变换、按脚底 y 排序的角色舞台；
   - 角色名/血条、真气条、伤害数字、攻击轨迹/命中墨花；
   - Q 聚怪涡旋、R 清场径向墨爆、波次横幅、胜负封签；
   - Q/R 等宽技能印及 ready/cooldown/qi/casting/down 五态；
   - 视觉 roster/config（actor id→名称、正式资产、精英语义），不污染 domain。
2. debug fixture：使用真实 `BattleCharacter`、真实 `NumbersConfig`、显式 seed，经 `Phase0aProductionFlowAssembler` 生成 flow。
3. `VisualRoute.phase0aBattlePlayable`：仅 visual/debug route 可达；键盘 WASD、普攻、Q、R 可操作，同时保留鼠标技能按钮与可见键位提示。
4. `UiStrings` 与集中 presentation tokens；Dart presentation/domain 不散写中文文案或结算数值。

### 不做

- 不替换 `stage_entry_flow`、主线/塔/心魔/轻功/群战/扫荡/远征/断魂庄入口。
- 不接奖励、掉落、成长、伤势、存档或 `BattleResolutionService`。
- 不删除、重构或改变旧 3v3 行为。
- 不改 Phase0a domain/application 规则与数值，不复制伤害、CD、真气、AI、波次或终局公式。
- 不改 probe，不迁 probe 固定数值/素材，不引入 Flame 或新运行时依赖。
- 首切片不生成新资产；正式素材缺口登记到后续资产批。

## 事件与画面映射

| 输入 | 唯一表现消费 |
|---|---|
| `state.player/enemies.position` | 脚底锚点位置、y 轴纵深缩放、按 y 排序、接地阴影 |
| `currentHealth/maxHealth` | 全体持续可见血条；不得由表现层自行扣血 |
| `qiCurrent/qiMax` | 玩家真气条与 qi 不足态 |
| `Phase0aAttackStarted` | 出手前摇/墨锋起笔；不伪造伤害 |
| `Phase0aHitLanded` | 命中墨花、白闪/震动、伤害数字；玩家远距命中显示掌风轨迹 |
| `Phase0aGatherStarted/Applied` | 聚怪涡旋→目标拉拢轨迹；只读 outcomes/status |
| `Phase0aClearStarted/Applied` | 清场题字/径向墨爆→逐目标伤害数字；只读 outcomes |
| `Phase0aEnemyDefeated` | 普通淡墨散、精英更重墨散；不得重复移除 |
| `Phase0aSkillAvailabilityChanged` + `state.skillSlots` | 等宽技能印五态、CD 秒数、真气门槛、亮暗与可交互态 |
| `Phase0aWaveStarted/Cleared` | 宣纸波次横幅与短转场 |
| `Phase0aBattleVictory/Defeat` | 全场唯一终局封签；终局后输入无效 |

表现层按 `seq` 单调消费事件并去重；不得按 widget rebuild 重播旧反馈。

## 交互与布局验收

- 1280×720 与 1440×900：角色、全体敌人、血条/名称、伤害数字、真气、Q/R 状态和波次均在安全区，无裁切/遮挡。
- 键盘：WASD 连续移动；普攻、Q、R 单次触发；焦点进入屏幕后无需点两次；按钮可 Tab 聚焦、Enter/Space 激活并有语义标签/禁用态。
- 技能可释放时高亮，cooldown/qi/casting/down 明显变暗且文本原因可读；Q/R 不能释放时不得仍播放成功特效。
- 所有敌人血条常显；所有非零伤害都有数字；暴击与 R 具有更高但克制的视觉层级。
- 画面不得出现 greybox 圆/矩形角色、纯白 X、平行白线占位或 Material 默认饱和色。

## 测试切片

1. 红测：world→screen 纵深、排序、状态映射、事件 seq 去重。
2. 红测：真实 flow 驱动血条/伤害/Q/R/波次/终局，表现层不得修改 state 或重算伤害。
3. 红测：技能五态亮暗、CD/真气文案、键鼠与桌面 semantics。
4. 红测：visual route 注册且不出现在生产路由。
5. 实装后跑 Phase0a 全套、presentation/debug targeted、audio 相关回归、analyze、diff-check。
6. 1280×720 / 1440×900 真机截图与短操作 smoke；由主窗口目检自然纵深、可读性和非 Demo 感。

## 切片与恢复点

1. [x] 从第六批 `[READY] 2e688b08` 创建独立 worktree并完成依赖预热。
2. [x] Phase0a 基线 150/150。
3. [x] Kimi 只读审计根资产、复用组件、debug 接线点与事件映射。
4. [x] 红测与最小实现。
5. [x] 双视口真机验收与修正。
6. [x] 全验证并冻结 `[READY]`。

当前恢复点(已交付):实现分支 `feat/phase0a-kimi-production-presentation` 于 tip `bc7cdddd` 干净收口,并以 `--no-ff` 合并入协调分支。验证证据:根应用相关 340 项全绿;表现层两文件 26 项全绿;`flutter analyze --no-pub` 0 issue;macOS build 成功;1280×720 与 1440×900 原生窗口抓图成功,主窗口目检通过——无裁切遮挡、自然纵深成立、正式角色/敌人资产可辨、全体名字血条/伤害数字/HUD/Q-R 可读,Q 涡旋与受击并存,R 墨爆/波次/CD/真气/终局禁用正常;probe isolation 用 `--no-test-assets` 5 项全绿(probe 工具链测试须带 `--no-test-assets` 运行)。边界复核:未改 GDD.md/CLAUDE.md/PROGRESS.md/pubspec.yaml/tools/phase0minus_probe;新增战斗屏仅由 lib/features/debug 接线。
