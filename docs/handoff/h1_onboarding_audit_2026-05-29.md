# H1 上手 30min 体验 audit(2026-05-29 · 综合版 v2)

> **v2 supersede Batch-1 草稿**:4 并行子 agent Phase 0 grep(首屏链路 / 第一次战斗 / 解锁+引导合规 / 首次掉落+成长反馈)+ Pen Codex 真机视觉验收交叉印证。审计三部曲收尾(H2 中期 ✅ + H3 后期 ✅ + 本 H1 上手)。
> v1 草稿头号 G1(`mainMenuTitle='调试主菜单'`)已在 H1-Q1 `a497044` 修(→'挂机武侠'),本 v2 不再列。
> 关键发现已 Phase 0 复核证实(装备穿戴入口缺失 = grep 实证非漏看)。**不实装** · 修复批待用户拍。

## TL;DR

**上手骨架健康,但 2 条核心循环级 🔴 拖累第一印象**:① 主菜单 step 0 暴露 7 个未解锁系统按钮(违 §5.7);② 掉落装备无玩家穿戴入口(核心循环断裂)。第一次战斗体验本身 🟢 优秀。§10.2 引导方式(零教程弹窗 + banner 气泡 + 百科分档)教科书级合规。**Codex 真机**:无乱码/英文漏翻/布局溢出/卡死,视觉层干净 → 🔴 都是 UX/逻辑缺口非渲染 bug。

## 🔴 硬伤(建议优先修)

1. **主菜单 step 0 暴露未解锁系统按钮(违 §5.7)** — 心魔/轻功/群战/PVP/江湖/门派/排行榜 7 个 Phase-5/§12 系统在全新存档(step 0)全亮可点,无 tutorialStep 门槛;锁只在各屏内部(点进去才撞 locked 态),违 §5.7「未解锁系统菜单按钮直接灰掉/隐藏」。PVP 尤甚(点进是 Phase-5 空壳 + snackbar)。新手面对 13+ 亮按钮长列表劝退风险最高。**修法**:沿心法(step<3)/闭关(step<5)既有 `disabled` 体例加门槛。锚 `main_menu.dart:152-192`。A+C 双维度独立确认。
2. **掉落装备无玩家穿戴入口(核心循环断裂)** — 掉落装备 `ownerCharacterId=null` 入背包(`drop_service.dart:26`),但 `equippedWeaponId=` 赋值只在 recruitment/ascension/seed/debug,**无任何玩家 UI**:character_panel 装备槽只读占位、equipment_detail ActionBar 只有强化+开锋无「装备」、无 equip service 方法。Phase 0 grep 实证。掉装备是上手核心爽点却穿不上 = 装备系统半残。锚 `equipment_detail_screen.dart:137` / `character_panel_screen.dart:597`。
3. **首次掉落零仪式感(违 §10)** — StageVictoryDialog 掉落纯文字清单(`· text`),神物与磨剑石视觉完全一样,无 tier 色/图标/稀有度/动画(GDD §10「装备首次掉落仪式感」是上手重点)。锚 `stage_victory_dialog.dart:60-87` / `drop_service.dart:25-40`。(v1 G6 标 🟢 可选 · v2 据 §10 升 🔴)
4. **`'我的门派'` 硬编码中文(违 §5.6 · 玩家可见)** — `onboarding_service.dart:100` 全新玩家门派名硬编码,应迁 UiStrings/yaml。

## 🟡 可优化 polish

- **凝练领悟无领悟点 = SnackBar 非常驻空态**(D + Codex 双确认):transient SnackBar 易错过,常驻空态引导更好。锚 `technique_panel_screen.dart` + `strings.dart:291`。
- **卷首过场底部按钮浅紫**(Codex 真机):偏离 §9 水墨基调(青/墨/宣纸黄/绛红)。
- **闭关结果装备显示 raw defId 非中文名**(真 bug · 玩家可见):`retreat_result_screen.dart:108` 漏走 `getEquipment().name`(victory dialog 已正确)。
- **step 1-5 全程无 banner 引导**(v1 G2):banner 仅 step 6/7/8(收徒/奇遇/开锋),Ch1 通关前(上手 30min 主区间)无任何上下文气泡。是否补 step 1-5 banner 待定。
- **home_feed 空 feed 无明显 CTA**(v1 G3):占位文案 + 「直入江湖」按钮,但无显著引导玩家点击下一步。
- **叙事 opening → 战斗 衔接是否直觉**(v1 G4):NarrativeReader onPop 默认进战斗,无显式「开始战斗」prompt(Codex 本轮未专测此流,留 Pen 续验)。
- **「直入江湖」落点是主菜单非战斗**(A):命名与落点轻微预期落差。
- **首战无「战斗自动进行」气泡**(B):新手首面自动战斗+大招按钮信息密度偏高。
- **结算 summary 用「tick」开发术语**(B):已有「回合」(`strings.dart:19`)却不统一。
- **首关 victory 文案与战斗零呼应**(B):灰兔系绑腿纯过场,缺战斗-叙事衔接。
- **强化首次无引导**(D):50 磨剑石给了但无气泡引导去试。

## 🟢 健康(维持)

- **第一次战斗体验优秀**(B):首关学徒敌 vs 玩家一/二/三流(2-4 阶碾压几乎不可输)· 100% 掉落正反馈 · 双层结算 · 战败零惩罚免费重试 · 开场/胜利叙事古风质感高无 typo。
- **§10.2 引导方式合规**(C):全仓零教程弹窗 · banner 非阻塞气泡 · 百科 3 tab 机制按 step 分档 + lore 永久可查。
- **tutorialStep 模型正确**(C):0 起绑真实玩法事件递增(通关/突破/奇遇/+10 强化)· 心法(step3)/闭关(step5)灰显教科书级。
- **升阶仪式接线正确**(D):AdvancementSummary 小层 vs 大境界(military_tech badge)视觉分层 · 前 30min 大概率只见小层(内容节奏非 bug)。
- **闭关产出 + 凝练闭环完整**(D):retreat_result 5 维带图标 + insightHint 气泡 + 心法面板凝练双向打通。
- **全新启动链路顺**(A):splash 水墨 + 并行 init 防黑屏 → home_feed 空态引导 → 主菜单,onboarding seed 兜底不空队 crash。

## 建议修复批次(等用户拍)

- **批 1 修 🔴 接线(无数值 · 低风险)**:#1 主菜单门控(沿既有 disabled 体例)+ #4 `'我的门派'` 迁 UiStrings(~5min)。**ROI 最高 · 直接解第一印象劝退**。
- **批 2 装备穿戴入口(#2 · 功能实装)**:character_panel 装备槽可点 → 选背包装备上身 或 equipment_detail 加「装备」按钮 · 走 canEquip §5.3 三系锁校验。中等工程。**核心循环必补**。
- **批 3 仪式感 + 🟡 polish 一波**:#3 drop dialog 加 tier 色/图标 + 闭关 defId→中文名 + 过场按钮调色 + 凝练空态常驻化 + tick→回合术语统一 + step 1-5 banner。

> Pen Codex 视觉验收交叉印证产物:`docs/handoff/pen_visual_root_cause_a/`(7 截图 + NOTES · Pen 本地)。
