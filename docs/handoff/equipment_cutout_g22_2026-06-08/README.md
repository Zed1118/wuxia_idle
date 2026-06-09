# 装备 G2.2 抠白底 · 收口(2026-06-08)

## 状态:机械活全完成,只剩晚上 ③ 视觉验收 + 合并
- **代码+资产已在分支** `worktree-equip-cutout-transparent`(worktree 同名目录,已 build),commit `5734650`,**基于已含 §5.6 的 origin/main,可干净 ff**。
- **闸门双绿**:analyze 0 / 全量 1763 测过(1 skip)。item_slot 测已改断言新行为(无 multiply)。
- **不合 main**:按"视觉 PASS 才合 main"约定,等晚上 ③ 三屏 Codex/用户确认再 ff 合 + push。

## 已做
- widget `equipment_art_image.dart`:删 `color`/`colorBlendMode` multiply 染底 + 无用 `tintOpacity`。**alpha 通道天然路由**:透明浮面板 / scene 不透明渲成装裱画,无 runtime flag。
- 替 **130 张 cut assets**(pngquant 70-92 + oxipng,assets/equipment 51MB→26MB),**30 张 scene 原图不动**。
- 分类:scene(frame)30 = corner-spread>18(21)+ ring-keep>0.06(9,逐张验证);cut 130。frag 判据弃(多部件产品误报)。规律:detail 版常是氛围场景即便 icon 干净。
- v3 抠图器(cut_v3.py):投影感知 + 软斜坡 alpha + 补环心洞 + 红朱印去除 + 角落题字印删。

## 晚上动作(2 步)
1. **③ 三屏视觉验收**:item_slot 缩略图 / character_panel 角色槽 / equipment_detail hero。
   - web 路径不通(项目未配 web + Isar 无 web 后端)→ Codex @ Pen 或用户跑 `flutter run -d windows`(VISUAL_ROUTE=hub)。
   - 实质已由 Python 合成真面板底色验过,属低风险最终确认。
2. **PASS 后**:`git merge --ff-only worktree-equip-cutout-transparent`(从主仓)+ 更 PROGRESS + push。FAIL 则按反馈调 cut 集/分类(改 cut_v3.py 重出对应图)。

## 产物(主仓 docs/handoff/)
cut_out/(130 定稿透明)· sheet_1-3.png · det_/icon_ 复核图(job tmp)· manifest.json(定稿)· cut_v3.py / manifest.py。
