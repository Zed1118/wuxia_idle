# Codex 派单 · T5 闭关地图化(视觉增强 · 分支闭环)

**项目:挂机武侠** (`/Users/a10506/Desktop/Projects/挂机武侠`)
**baseline commit:** `324ee18`(已在 main · 工作树仅 1 个无关 `M test/tools/output/stress_*.md` 测输出,别动)
**分工:** Codex 在分支上做视觉实时截图闭环 → 改完交回 Claude 过闸(analyze+全量测试+硬编码/红线扫)再合 main。**别直接 push main。**

---

## 一句话任务
把闭关(seclusion)4 屏从「卡片+底图已有」再往「**5 个山水地点图册**」的地点感推一档:产出差异一眼可辨、地点氛围连贯。**这是增强不是重做——下面"现状"已实装的别推倒重来。**

## 现状(已实装,勿重做)
- `seclusion_map_list_screen.dart`:已是 **GridView 卡片**(1-2 列自适应)+ `_MapImage` 引 `assets/maps/{id}.png`(5 张一一对应)+ `_MapStatusPill`(locked/available/active)+ 顶部活跃 session banner。
- `active_retreat_screen.dart`:已有 `_MapBackdrop`(整幅地图大图底 + 0.42 overlay)+ 宣纸进度面板 + 收功按钮。
- `retreat_result_screen.dart`:已有 `_ResultHero`(ceremony 素材/地图 fallback)+ 5 维奖励行 + 升层 banner。
- `seclusion_setup_screen.dart`:时长选择(1h/4h/12h)+ 产出预估行。
- 5 张地图素材就绪:`shanLin`(山林·平衡) `guJianZhong`(古剑冢·兵器掉率+50%) `cangJingGe`(藏经阁·心法领悟+50%) `xuanYaPuBu`(悬崖瀑布·内力+50%) `duanYaJueBi`(断崖绝壁·顶级综合)。

## 改进方向(候选 · 用户看屏指哪改哪,不必全做)
1. **产出差异可视化**:bonus 现在是纯文字("兵器掉率+50%")→ 配水墨符号/小图标(剑/卷/气/山)让 5 地点产出倾向不读字也能分。
2. **地点图册氛围**:地图列表整体更像「山水图册/卷宗」而非普通网格——统一装帧(宣纸/卷轴框)、地点名做题字/朱印感。
3. **4 屏地点语言连贯**:list→setup→active→result 共用同一套地点视觉锚点(同地点同色调/同题字位)。
4. **状态层级**:locked/available/active/已完成 用统一视觉语言,locked 调暗但仍可见山水。

## 怎么看屏(直达,免找路径)
4 个闭关屏各有 debug 直达 VISUAL_ROUTE(已就位):
- `seclusion_map_list` · `seclusion_setup` · `seclusion_active` · `seclusion_result`
- 单屏实时迭代:`flutter run -d macos --dart-define=VISUAL_ROUTE=seclusion_map_list`
- 批量截图:`tools/visual_capture/visual_capture.sh seclusion_map_list seclusion_setup seclusion_active seclusion_result`(产图到 docs/handoff/)
- 全路由总入口:`./tool/build_acceptance.sh` 出 hub 包,`open` 后点按钮切屏。

## 红线测试(必须保持绿 · 改 UI 易撞)
- `test/features/seclusion/presentation/seclusion_map_list_screen_test.dart:53-61` 期望 5 地图名集合 `{山林,古剑冢,藏经阁,悬崖瀑布,断崖绝壁}`——改名必改测(但地图名应走 UiStrings 不内联)。
- 同文件 `:66-75` locked 卡片无导航——改 tap 逻辑要复查。
- `retreat_result_screen_test.dart:102` 期望 `WuxiaUi.ceremonyRetreatResult` 素材路径——换素材要同步。
- 改完本地先跑:`flutter test test/features/seclusion/`(必全绿)+ `flutter analyze`(0)。

## 5 条硬规矩(开工前默念)
1. **在分支改,别 push main**:`git switch -c codex/t5-seclusion-map`(从 `324ee18`),改完留分支等 Claude 过闸。
2. **不硬编码**:文案走 `UiStrings`(闭关已有 35+ key,前缀 `seclusion*`/`activeRetreat*`)、数值走 `numbers.yaml`,别内联中文/数字。
3. **水墨克制**:不上 Material 饱和色 / 不加金光网游味 / 不碰带伪文字的 MJ 素材。金色仅高阶装帧/收益/胜利,绛红仅危险/破坏性确认。
4. **只动 presentation 层**:`lib/features/seclusion/presentation/` + 复用 `lib/shared/widgets/wuxia_ui/` kit。**不碰** `application/`/`domain/` 逻辑、`*.yaml`/schema/GDD/numbers.yaml。
5. 视觉满意 → 交回 Claude(给分支名 + 截图 + 改了哪几屏)。

## closeout 格式(交回时填)
```
# T5 闭关地图化 closeout
分支: codex/t5-seclusion-map  改后 commit: <sha>
改了哪几屏: list/setup/active/result 勾选 + 一句话各自改动
截图: docs/handoff/<...>(4 屏 · 双分辨率 1280x720 + 1920x1080)
本地闸门: flutter test test/features/seclusion/ <PASS/FAIL> · flutter analyze <0/n>
踩坑: <若有>
待 Claude 过闸: 全量测试 + 硬编码/红线扫 + 行为 diff → ff 合 main
```

## 验收(T5 达标线)
- 截图 `seclusion_map.png` 不读说明能看出「这是 5 个闭关地点」。
- 5 地点产出差异不读长文也能大致理解。
- 离线结算/收功入口不丢失,4 屏流程不破。
