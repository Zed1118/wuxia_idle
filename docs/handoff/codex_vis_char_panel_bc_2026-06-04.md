# Codex 视觉验收派单 · P0-3 ②③ 主修 hero + 心魔成长瓶颈面板

**项目:** 挂机武侠(Mac 本地)· **commit:** f9425b8 · **日期:** 2026-06-04
**验收包(零编译):** `build/macos/Build/Products/Debug/wuxia_idle.app`(debug · VISUAL_ROUTE=hub)
**用法:** `open "build/macos/Build/Products/Debug/wuxia_idle.app"` → 显「验收总入口」hub → 点路由进屏截图 → 左上返回 → 下一个。

## 背景

P0-3 角色卡收口最后一块:② 主修心法 tile hero 化(宣纸底 + 主修名加大);③ 心魔成长瓶颈面板(武圣常驻显「心魔 X/7」进度条 + 突破 CTA,数据 = 已通关心魔关数 / 7)。纯 Flutter,无新出图。

## 路由与验收门

### A. `character_panel`(② 主修 hero + 档案头回归)
祖师(id=1,非武圣 fixture)角色页。截图:`a1_profile.png`(全屏)+ `a2_main_technique.png`(主修 tile 局部)。
门:
1. **主修 tile 宣纸底**:主修心法区有暖宣纸纹理底(非冷黑方块),与 Phase B 心法面板卷轴感一致。
2. **主修名加大**:主修心法真名(如「听雨剑」)以校色大字(~20px)显示,醒目于辅修。
3. 阶名 + 段位 + 进度条 + 进度数值齐全,不溢出。
4. 辅修 tile 维持原样(未改)。
5. 档案头(立绘 + 姓名/境界/流派/4 属性)回归无破。

### B. `character_panel_growth`(③ 心魔成长瓶颈面板)
祖师 bump 武圣·熟练 + exp 满 + 心魔 2/7(被 stage_inner_demon_03 拦)。截图:`b1_growth_blocked.png`(全屏)+ `b2_inner_demon_panel.png`(面板局部)。
门:
1. **「心魔试炼」面板显示**:武圣祖师角色页出现该面板(进度条 + 右上「2 / 7」计数)。
2. **被拦强调态**:锁图标 + 「突破被拦」相关文案 + 「心魔关〔关名〕未通,经验留账」+ 右下醒目「突破」按钮(ElevatedButton)。
3. **进度条** 2/7 ≈ 29% 填充,绛红/高亮色。
4. **1280×720 无 RenderFlex overflow**(整页滚动到底无黄黑条)。
5. 切到弟子 Tab(非武圣)→ 心魔面板**消失**(shrink),不残留。

## 验收基建注意

- 验收路由用真 seed(seedCharacterPanelGrowth / seedMasterDisciple),非假数据;立绘走真 portraitPath。
- 此包 = commit f9425b8 快照;代码再改需重跑 `tool/build_acceptance.sh`。

## closeout

验收后写 `docs/handoff/codex_vis_char_panel_bc_2026-06-04_closeout.md`:每门 PASS/WARN/FAIL + 截图路径 + 一句话。WARN/FAIL 附复现与建议。
