# 大招/破招题字水墨墨团升级 · 设计(定稿)

**日期**:2026-06-10
**触发**:Codex B3 复验 FAIL — 题字衬底为规则圆角矩形框(`UltimateCaptionContent` 的 `0x99000000` border 容器),非水墨墨团。经查 B3 与已 PASS 的大招题字共用同一 widget,FAIL 是判据与实现错配,但暴露真问题:题字水墨感不足。用户拍板升级。
**范围**:单 widget(`UltimateCaptionContent`)视觉改造 + 一张墨团素材 + widget 测。大招题字 + 破招题字一并升级(共用 widget,一改两得)。

## 目标

题字从「半透明黑圆角矩形框 + accent 描边 + 文字投影」升级为「水墨墨团衬底(accent 色晕)+ 浅宣纸字 + 深墨描边」,贴合水墨基调(CLAUDE.md §9)。

## 素材(已就绪)

- `assets/ui/mj/caption_ink_blob.png`(从 MJ 泼墨圆团 _1_3 抠图):RGBA,RGB=深墨(26,26,26),**alpha = 墨浓淡**(亮度→alpha:纸白阈值 232 全透、墨浓不透、飞白边半透,高斯 0.8 羽化,bbox 裁切,1344×896)。`assets/ui/mj/` 整目录已 pubspec 注册,无需改 pubspec。
- 一张通用敌我两方:染色靠代码,不出两张。

## 渲染改造(`lib/features/battle/presentation/ultimate_caption_overlay.dart` · `UltimateCaptionContent`)

替换现 `Container`(decoration `0x99000000` + border + 文字 shadow)为 `Stack`(`alignment: center`)两层,外包 `Align(Alignment(0,-0.45))`(中部偏上,不变)+ `SizedBox` 约束墨团尺寸:

1. **墨团衬底层**:`ColorFiltered(colorFilter: ColorFilter.mode(accent, BlendMode.srcIn), child: Image.asset(墨团, fit: BoxFit.contain, errorBuilder: ...))`
   - `srcIn`:用 accent 替换墨团 RGB,保留 alpha 浓淡 → accent 色晕,浓淡靠 alpha 自然呈现。
   - `errorBuilder`:缺图兜底回原半透明圆角矩形容器(守 widget 测 + release 不破布局 · memory `feedback_image_asset_error_builder`)。
2. **文字层**:「破!」/招式名,真描边 = 两层 `Text` 叠(`Stack`)
   - 底层:深墨 outline(`TextStyle.foreground = Paint()..style=PaintingStyle.stroke..strokeWidth≈5..color=深墨 0xCC0A0A0A`)
   - 顶层:浅宣纸字实心填充(`color: WuxiaUi.paper` 0xFFE9DCC0)
   - 保留 fontSize 56 / FontWeight.bold / letterSpacing 6。

## 配色(沿用 token,字色不分敌我)

- 墨团 accent 色晕分敌我:破招/玩家方 = `WuxiaColors.resultHighlight`(暖金 0xFFE8C547);敌方 = `WuxiaColors.gangMeng`(绛红 0xFFC23A2A)。
- 字统一浅宣纸色 `WuxiaUi.paper` + 深墨描边(`0xCC0A0A0A`)。敌我靠墨团色区分,字色不变 → 字与同色墨团对比最强。

## 影响面

- `UltimateCaptionContent` 被 `UltimateCaptionOverlay`(`battle_screen` 大招/人剑合一题字)+ `_InterruptCaptionPreview`(破招验收路由)复用 → 大招 + 破招题字同步升级,无额外 callsite 改动。`isUltimateCaptionSkill` 纯函数不动。`UltimateCaptionOverlay` State 淡入淡出动画不动。

## 测试(`test/features/battle/.../ultimate_caption_*` 现有测族续)

- ① 暖金(isEnemy=false)+ 绛红(isEnemy=true)各渲染不崩;② 墨团 asset 缺失走 errorBuilder 不抛(`tester.takeException()` null);③ 「破!」文字可见(find.text)。
- 现有 `p0_charge_break_test` / `isUltimateCaptionSkill` 测不受影响(行为不变,仅视觉)。

## 验收

- `tools/visual_capture/visual_capture.sh battle_interrupt_caption`(前台 GUI session,bg headless 截图不稳)重出图;墨团 accent 色晕 + 浅宣纸字描边清晰、暖金/绛红两态区分;大招题字横向对照一致。

## 红线

- 不硬编码:墨团路径走文件内 const,文案沿用 `UiStrings.interruptCaption`;字色/墨团色走 token。
- 纯表现层,不动数值 / 不碰 §5.4。`flutter analyze` 0(含 info)+ 全量测过后合 main。

## 风险与 fallback

- srcIn 染色已在 PIL 预览验证两态清晰(preview2),层次靠 alpha 保留,无 modulate 丢层次风险。
- 描边 strokeWidth 5 @ 56 字号 PIL 预览 OK,Flutter 渲染后 `visual_capture` 截图微调。
- 抠图白边已羽化收边,深底自检无白晕(preview 已验)。

## 体例

照现有 `UltimateCaptionContent` 结构最小改动替换容器层,不重构 overlay 动画。
