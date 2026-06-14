# 战斗交互重做 + 周目按章 · 会话交接(2026-06-14)

> worktree `battle-drag-cycle-chapter`(branch `worktree-battle-drag-cycle-chapter`,基于 origin/main `db61dd16`)。
> spec:`docs/superpowers/specs/2026-06-14-battle-drag-cycle-chapter-design.md`(A 周目按章 / B 战斗自动流转 / C 拖招 / D 群体技,4 Phase + 3 开放点已拍板)。
> 真玩反馈 4 点 → 用户拍板:战斗=自动播放+随时拖招(废半手动单步)/ 周目按章·整章 Boss 解锁 / 群体技 targetType 我推导用户审。

## 本会话完成(可自主闭环部分)

- **Phase 1 群体技 targetType ✅**(commit `c426602b`):`TargetType{single,aoe}` + SkillDef.targetType(默认 single)+ 224 招回填(11 大招 aoe / 157 single,普攻+合击 single)+ 语义红线(普攻/合击必 single + aoe 集合非空)+ 6 红线测。
  - **aoe 11 招**(用户可调):万剑诀/落英缤纷/阴煞印/金刚怒目/万籁俱寂/玄冰诀/烈焰焚天/穿龙啸歌/混沌初开/无相劫/天罡破阵。
  - **偏离 spec D3**:spec 写"ult/power 必填",实改语义红线(fromYaml 默认 single 本就安全,语义红线守真约束)。
- **Phase 2 周目按章 · 数据层 ✅**:MainlineProgress 加 `clearedChapterCycleKeys`(`"chapterKey#cycle"`,chapterKey=主线`ch{N}`/副本 stageType.name)+ service 章级方法(chapterKeyForStage/highestClearedCycleForChapter/currentChallengeCycleForChapter)+ recordVictory 章末 Boss(isBossStage)补记 + saveVersion 0.21→**0.22.0** 迁移(旧 Boss 关 stage cycle key → chapter key)+ 5 测(派生/recordVictory/chapterKey/迁移)。

## 待续(都需视觉/真玩验收,且相互耦合 → 建议一起做)

- **Phase 2 UI**(周目控件上移到章层):`CycleSelectControl` 改 `stageId→chapterKey`(换 highestClearedCycleForChapter)+ 新 `selectedChallengeCycleProvider`(family by chapterKey)+ 4 选关屏挂载上移(主线章标题 / 副本整屏顶部 chapterKey=stageType.name)+ 关进入读 selectedCycle 传 targetCycle。**交互待拍**:章头选周目=设状态,关 tile 点击进入用该周目(需用户确认这个流)。**注:control 的"自动/手动"后缀在 Phase 3 后语义变,故与 Phase 3 一起做避免返工。**
- **Phase 3 战斗自动流转**(废半手动):删 manualStep/_NextStepButton/_ActorOrderBar/_TargetPickerDialog + 删录制回放链(~800 行:BattleNotifier.replay/_startReplayTimer/recordedOps/BattleReplay*/manual_clear_recorder)+ resolveAutoPlayMode 4态→2态(auto/interactive)+ BattleReplayRecord schema 可能删(再升 saveVersion)。**需真玩验收战斗"变快"手感。**
- **Phase 4 拖招交互**(依赖 D+B):技能栏 GestureDetector onPan + 引导线(复用 ProjectileTrail/CustomPaint)+ 敌人头像 GlobalKey hitTest + 单体拖拽/aoe 点触(读 targetType)+ 立即触发=快进到拖招者结算(确定性安全,不真插队)。**需真玩验收拖拽手感+引导线视觉。**

## 环境 / 续作须知

- fresh checkout/worktree 必跑 `flutter pub get && dart run build_runner build`(.g.dart gitignored)+ 从主仓拷 `libisar.dylib` 到 worktree 根(测试 dlopen 需要)。
- 验收一律 `-d macos`(Isar 无 web target)。analyze 用 --fatal-warnings(非 --fatal-errors)。
- 闸门状态:analyze 0 / 全量见 commit message(零回归)。
