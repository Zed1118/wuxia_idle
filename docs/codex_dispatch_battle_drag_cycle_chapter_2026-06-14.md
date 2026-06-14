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

A 章层周目控件:
1. PASS `drag_cycle_01_chapter_control_placement.png` - 周目控件位于章头 journey map 下方,关卡 tile 内未再出现周目控件。
2. PASS `drag_cycle_02_cycle1_label.png` - 「第1周目」条目可见,右侧标注「(自动)」。
3. PASS `drag_cycle_03_cycle2_label.png` - 「挑战第2周目」条目可见,右侧标注「(手动)」,语义区分清楚。
4. PASS `drag_cycle_04_selected_state.png` - 点击「挑战第2周目」后仅就地高亮并显示勾选,没有跳转战斗。
5. PASS `drag_cycle_05_per_tile_autoplay_toggle.png` - 每个已通关 tile 内仍保留「自/手」印章式自动/手动 toggle。
6. PASS `drag_cycle_06_720p_layout.png` - 1280x720 下 journey map、章层周目控件和前三个关卡 tile 没有溢出或明显叠压。
B 纯自动流:
7. PASS `drag_cycle_07_auto_flow_no_nextstep.png` - 进真战斗后底部为技能指令台,未见「下一步」单步按钮;战斗自动推进,右下仅有「快进」。
C 拖招交互:
8. FAIL `drag_cycle_08_guide_line.png` - 多次长按底部 ready/可见技能按钮并拖动,未捕捉到从按钮锚点跟手的流派色引导线。
9. FAIL `drag_cycle_09_enemy_hover_highlight.png` - 拖至存活敌人头像位置时未观察到绛红 hover 光晕;截图中出现的是战斗自动动作/受击帧,不是拖拽命中态。
10. FAIL `drag_cycle_10_single_target_hit.png` - 未能确认 single 技由拖拽指定到目标;可见伤害均来自自动战斗日志/结算,非拖拽下发证据。
11. FAIL `drag_cycle_11_charging_glow.png` - 拖招下发后我方头像流派色蓄势光晕未观察到。
12. FAIL `drag_cycle_12_rush_to_actor.png` - 未观察到拖招下发后的「立即触发/快进到出手」体感;战斗按自动节奏推进并很快胜利。
13. FAIL `drag_cycle_13_aoe_tap.png` - 点触大招/群体技未能形成可确认的 aoe 直发证据,截图已进入胜利演出。
14. FAIL `drag_cycle_14_drag_to_empty_noop.png` - 空白拖放未能确认 no-op,截图停在胜利弹窗,无法证明未下发/不消耗。
质量点主观评价:章层周目控件位置与 720p 密度良好,周目选中态清楚,关卡内「自/手」印章与章层控件不会混淆。战斗纯自动流符合预期,但拖招交互在 macOS 验收包内无法被稳定触发或捕捉:自动战斗结算很快,多次从第1关/第3关/Boss关进入后,长按并拖动底部技能按钮均未出现按钮锚点引导线、敌头像 hover、我方蓄势或拖后快进反馈;因此拖招相关质量点无法给出正向手感评价。

---

## R1 FAIL 根因诊断 + R2 重派(2026-06-14 续 · Claude)

### C 7/7 FAIL 根因 = 验收路径拖招层没开 + 战斗太快(非拖招代码 bug)

R1 在 `stage_list_cycle` 进的真战斗里拖不出任何反馈,根因有二,**均非拖招实现 bug**(12 个 widget 单测已在真 BattleScreen + 真长按拖手势上锁死 hitTest / 拖命中下发 targetId / aoe 点触 / 门控全契约):

1. **主因:验收战斗跑在默认「挂机自动」模式,拖招干预层根本没挂。** `gameplaySettings.autoPlayDefault=true` → `resolveAutoPlayMode(override:null, global:true)` → `AutoPlayMode.auto` → `allowPlayerIntervention=false` → battle_screen **不挂拖招 GestureDetector**。Codex 长按的按钮上压根没有手势 → 无引导线/无 hover/无蓄势。要进 interactive 必须先把那关的「自/手」印章 toggle 翻到「允许拖招」(手),R1 派单漏了这个前置。
2. **次因:Ch1 前期关卡战斗 1-2 tick 就打完**,长按(~500ms 触发)+拖+松手来不及。

### 修复:新增专用路由 `battle_drag_live`(本次新增)

直接 boot 真战斗 + **强制开干预(allowPlayerIntervention:true)** + **高血低攻耐久敌人**(战斗持续够长,玩家从容拖招)+ autoStart。无需翻 toggle、不会被秒。主控带 single 强力技(拖)+ aoe 大招(点)。

> ⚠️ **真玩为权威**:native 长按拖手势靠 Codex 鼠标合成本就不稳(memory `feedback_cli_no_gui_screenshots`)。本路由首要给**用户真玩**判手感;Codex 尽力截,拖不出来不算代码 FAIL(wiring 由 12 widget 单测 + buildVisualTarget 守卫测已证)。

### R2 验收步骤(重编验收包后)

hub 里点 **`battle_drag_live`**。开屏即真战斗(顶部提示条「长按拖技能到敌人头像指定目标 · 点大招群体直发」),敌人高血久撑。

操作:长按底部主控技能按钮 → 不松手拖 → 拖到存活敌头像 → 松手。逐项同上 C 段 8-14(引导线/hover/single 拖指定/蓄势光晕/立即触发变快/aoe 点触/拖空白 no-op),截图前缀改 `drag_live_`。

拖不出来时:文字说明「鼠标合成长按拖未触发」即可,**别记代码 FAIL**,转交真玩。

### R2 逐项结论(Codex best-effort 回填)

8. 9. 10. 11. 12. 13. 14.
真玩手感(用户回填):
