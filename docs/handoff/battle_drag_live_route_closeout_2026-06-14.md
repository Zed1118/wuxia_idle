# 战斗交互重做 · 拖招验收闭环 + battle_drag_live route · closeout(2026-06-14 续3)

> ✅ **已合 main**(真玩长按拖确认可用 → ff-only 合 main)。worktree `battle-drag-cycle-chapter`,全 push origin。
> 承接 续2(Phase 4 拖招 + Phase 2 UI),本波 = 合 main 前闸门修复 + 拖招验收闭环。

## 本波完成

### 闸门修复(`f3e83642`)
- battle_screen 拖招快进死亡兜底(拖招者出手前被击杀 → 清 `_rushToActorId` 防卡死快进,纯表现层)。
- skill_def.dart targetType 注释 drift(改 enforcer 真实语义)+ visual_route label drift(章层口径)。

### 拖招验收闭环(`271eb61a` + `3ac0fa84`)
- **Codex R1 拖招 7/7 FAIL 定根因**(非代码 bug):验收战斗跑默认「挂机自动」模式 →
  `allowPlayerIntervention=false` → battle_screen 不挂拖招手势;且 `ScenarioLauncher`
  此前**未透传** `allowPlayerIntervention`(恒 false)。次因 Ch1 战斗太快。
- **修复**:① ScenarioLauncher 加 `allowPlayerIntervention` 透传 ② 新 `scenarioDragLive`
  (高血 16000 / 低攻 200 耐久敌久撑 + 主控 single 强力技 + aoe 大招)③ 新 route
  `battle_drag_live`(强制开干预 + autoStart)④ 守卫测 `buildVisualTarget(battleDragLive)
  → allowPlayerIntervention==true`(防透传缺口回归)。
- **Codex R2**:13 aoe 点触直发 PASS(进冷却 + 多目标伤害);8-12/14 长按拖鼠标合成无法触发
  (按派单不记代码 FAIL)。长按拖真机手感转交真玩。

## 验收矩阵(合 main 前)
- analyze 0 / 全量 **2160 测** / 1 skip / 零回归。
- A 章层周目控件 Codex 6/6 PASS · B 纯自动流 1/1 PASS · C-aoe 单测+Codex 双证 ·
  C-长按拖 wiring 12 widget 单测锁契约 · 红线+正确性 review 无 Blocker。
- ff-only 零冲突(main `db61dd16` 是 HEAD 祖先,领先 13 / 落后 0)。
- **唯一剩**:native 长按拖真机手感 = 真玩(本质只有人能验)。

## 合 main 收尾步骤(真玩 OK 后)
1. 真玩 OK → 更新 PROGRESS.md「续3」段 + 本 closeout 标 ✅,commit 到 branch。
2. 确认 ff 前提:`git fetch origin main && git rev-list --count origin/main..HEAD`(应 =0 behind)。
3. ff 合 main:在主 checkout `git checkout main && git merge --ff-only worktree-battle-drag-cycle-chapter`
   (或 worktree 侧 `git push origin worktree-battle-drag-cycle-chapter:main` 远端 ff)。
4. **主 checkout 必跑** `flutter pub get && dart run build_runner build`(.g.dart gitignored,
   含 `selected_cycle_provider.g.dart`)+ 确认 libisar.dylib。
5. 主 checkout 全量复测 → 2160 测 / analyze 0 / 零回归。
6. worktree 可删(本特性线已合)。

## 踩坑沿用
- 拖招手势 `onLongPress*`(非 onPan)规避底栏横滚竞争。
- native 长按拖无静态 route 可 CLI 验,只能真玩;Codex 鼠标合成做不了(memory `feedback_cli_no_gui_screenshots`)。
- 拖招默认 opt-in(挂机自动模式拖招层关闭),需关卡切「允许拖招」或走 battle_drag_live 路由才挂手势。
- macos/Runner.xcodeproj churn = CocoaPods build 元数据,每次 build 重生,不入库(`git checkout -- macos/`)。
