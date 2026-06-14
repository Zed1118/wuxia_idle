# Codex 视觉/交互验收派单:战斗交互重做(Phase 4 拖招 + Phase 2 UI 周目按章)

验收点:① 章层周目选择控件(从 per-stage 上移到章层) ② 纯自动战斗流(已废「下一步」单步) ③ **拖招交互**(长按拖技能→敌头像,引导线/命中高亮/蓄势光晕/立即触发变快)。
分支 `worktree-battle-drag-cycle-chapter`(未合 main,HEAD `6fd57fdf`)。验收包 = `tool/build_acceptance.sh` 产出(hub 总入口)。

> ⚠️ 与上一份 `codex_dispatch_cycle_evolution_2026-06-14.md` 的区别:周目控件**已从每个关卡 tile 内上移到章层**(主线挂章头 journey map 下方,一章一个控件,不再每关一个)。请按本 doc 的章层口径验,不要找 per-tile 控件。

## 验收包

先编(代码改动后重跑):

```
cd "/Users/a10506/Desktop/Projects/挂机武侠/.claude/worktrees/battle-drag-cycle-chapter"
./tool/build_acceptance.sh
```

编完:

```
open "/Users/a10506/Desktop/Projects/挂机武侠/.claude/worktrees/battle-drag-cycle-chapter/build/macos/Build/Products/Debug/wuxia_idle.app"
```

窗口拉 **1280×720**。开屏是「验收总入口」hub,点路由按钮进屏,左上返回切下一个。

---

## 路由:`stage_list_cycle`(主线选关·章层周目 + 拖招真关卡入口)

hub 里点 **`stage_list_cycle`**。seed = 整章 Ch1(stage_01_01 .. 01_05 含章末 Boss)cycle1 全通(`ch1#1`),所以**章头周目控件可见**、且每关 tile 都可点进真战斗(主线允许拖招)。

### A. 章层周目控件(静态截图)

1. **周目控件在章头、非每关 tile 内**:选关屏顶部 journey map(章进度图)**下方**出现一个周目选择控件(整章一个);**关卡 tile 内不再有**周目控件。截 `drag_cycle_01_chapter_control_placement.png`。
2. **「第1周目(自动/回放)」选项可见**:控件内含「第1周目」条目(回放已通最高周目)。截 `drag_cycle_02_cycle1_label.png`。
3. **「挑战第2周目(手动)」选项可见**:控件内含「挑战第2周目」条目(=最高+1 新挑战)。两项语义可区分。截 `drag_cycle_03_cycle2_label.png`。
4. **选周目=设选中态、不进战斗**:点「挑战第2周目」,控件**就地高亮/勾标**该项(选中态变化),**不跳战斗**(仍停在选关屏)。截 `drag_cycle_04_selected_state.png`。
5. **per-stage 自动/手动 toggle 仍在 tile 内**:每个已通关 tile 内仍各有「自动/手动」开关(绛红方印「自/手」glyph),与章层周目控件正交并存。截 `drag_cycle_05_per_tile_autoplay_toggle.png`。
6. **720p 布局不溢出**:章头周目控件 + journey map + 关卡列表在 1280×720 下不叠压/截断/字号过小。截 `drag_cycle_06_720p_layout.png`。

### B. 纯自动战斗流(进真战斗后静态截图)

在选关屏点任一**已通关关卡 tile**(如 stage_01_01),经剧情过场进入 3v3 战斗。

7. **战斗为纯自动流、无「下一步」按钮**:战斗自动播放(回合自动推进),底部**没有**「下一步」单步按钮(Phase 3 已废半手动单步)。底部应是技能指令台(强力/破招/共鸣/大招分组按钮 + 内力/冷却/待发印状态)。截 `drag_cycle_07_auto_flow_no_nextstep.png`。

### C. 拖招交互(真关卡 · 动态手势 · 重点验收)

> 拖招是 native GUI 手势,无静态 route,必须在上面进入的真战斗里实操。
> 操作:**长按**某个可用技能按钮(底部指令台,需该技能 ready 且未待发)→ 不松手**拖动**指针 → 拖到某个**存活敌人头像**上 → 松手。

8. **引导线跟手**:长按技能按钮后开始拖,从按钮锚点到指针出现一条**流派色笔触引导线**,实时跟随指针移动。截拖动中 `drag_cycle_08_guide_line.png`。
9. **命中敌头像高亮**:拖到存活敌人头像上方时,该敌头像出现**绛红光晕高亮**(hovered 态),表示命中可下发。截 `drag_cycle_09_enemy_hover_highlight.png`。
10. **单体技拖到敌头像=指定该目标**:对一个**单体技**(targetType=single)拖到某敌头像松手,该技能对准你拖中的那个敌人结算(伤害落在该敌)。截松手后该敌受击 `drag_cycle_10_single_target_hit.png`。
11. **拖招者「蓄势」光晕**:下发拖招后,出招的我方角色头像出现**流派色蓄势光晕**(charging 态),直到其出手结算才消失。截 `drag_cycle_11_charging_glow.png`。
12. **立即触发=很快看到该角色出手**:下发拖招后战斗**明显加速**(快进)推进到拖招角色出手,然后恢复常速——主观上「拖完很快就看到我指定的角色放了这招」。截能体现的帧 `drag_cycle_12_rush_to_actor.png`,文字描述快进体感。
13. **群体技(aoe)点触直发**:对一个**大招/群体技**(targetType=aoe),**点一下**(不拖)按钮即触发,目标由 AI 选,不需拖到头像。截 `drag_cycle_13_aoe_tap.png`。
14. **拖到空白不下发**:长按技能按钮后拖到**非敌头像的空白区域**松手,该技能**不下发**(不消耗、引导线消失、无结算)。截/描述 `drag_cycle_14_drag_to_empty_noop.png`。

---

## 关注质量点(主观手感,回填观感即可)

- **引导线观感**:流派色笔触是否清晰、跟手是否顺、是否有明显延迟或断裂。
- **命中高亮辨识度**:绛红光晕是否足够明显能确认「拖到了这个敌人」;多个敌人靠近时切换高亮是否准。
- **蓄势光晕 vs 命中高亮**:我方拖招者的「蓄势」光晕(charging)与敌方「命中」光晕(hovered)颜色/位置是否易混。
- **立即触发加速强度**:快进到出手的速度是否合适(太快看不清出招过程?太慢没「立即」感?)。
- **single 拖 vs aoe 点触区分**:玩家能否直觉区分「这招要拖到敌人」vs「这招点一下就放」。

---

## 已知非 bug(别记 FAIL)

- **route label 文案旧口径**:hub 里 `stage_list_cycle` 按钮说明文字可能仍写「01_01..04 ... 每关显示」的旧 per-stage 口径——这是 label 文案 drift,以本 doc 章层口径为准,控件实际已上移章头。
- **single 技能「点一下」(不拖)也能放**:single 技点触走 AI 选目标(additive 友好),只有**拖**才指定具体 targetId。所以 single 既能点触也能拖,这是有意设计,非 bug。验收第 10 项请用**拖**来验指定目标。
- **某些技能按钮禁用(灰)**:技能未 ready / 内力不足 / 已待发 时按钮禁用、不挂拖招手势,属正常门控。
- **拖招不真插队**:立即触发是 UI 时序快进(advance 到该角色出手),不是把该角色插到队首——所以快进期间其他角色也会按既有顺序行动,只是整体变快,这是为保引擎/rng 确定性的有意设计。

---

## 验收流程说明

本 doc 仅覆盖视觉/交互验收(Codex 闭环)。Claude 闸门工作(flutter analyze / 全量测试 / 合 main)单独进行,不在本派单范围内。

结论回填本 doc「逐项结论」段(每项 PASS/FAIL + 截图名 + 一句观察)。手感类(质量点)单独写一段主观评价。

---

## 逐项结论

Codex 视觉/交互验收回填(待填,macOS app,窗口 1280×720):

A 章层周目控件:1. 2. 3. 4. 5. 6.
B 纯自动流:7.
C 拖招交互:8. 9. 10. 11. 12. 13. 14.
质量点主观评价:
