# Codex 派单 · T9 最终截图包(干净双分辨率 · Steam 商品页候选)

**项目:挂机武侠** (`/Users/a10506/Desktop/Projects/挂机武侠`)
**前置已就绪(Claude 2026-06-09 修):** 截图工具已修好——干净窗口(无桌面/dock) + 真双分辨率(1280x720 + 1920x1080 真渲染)。先 `git pull` 拿最新 main。
**分工:** Codex 跑脚本出图 + 视觉策展(挑商品页候选 + 查问题) → 交回 closeout。这是验收/策展任务,**几乎不写代码**(若发现 overflow/debug 残留才回报,由 Claude 修)。

---

## 一句话任务
出一套干净的 Steam 商品页候选截图(覆盖 8-11 屏 × 双分辨率),逐张查无 debug 字段/无缺图/无 overflow,挑出风格一致的 5 张核心图。

## 开局动作
```
cd /Users/a10506/Desktop/Projects/挂机武侠
git pull --rebase --autostash          # 拿最新截图工具(c580fb3)
# 一次性截全部候选屏 × 双分辨率(约 20 分钟,每屏自动起 app→截干净窗口→退)
tools/visual_capture/visual_capture.sh \
  main_menu battle_scene battle_victory_first_clear \
  character_panel inventory equipment_detail_screen \
  technique_panel_tier_all technique_panel_hero \
  stage_list tower_floor_list seclusion_map_list
```
产图到 `docs/handoff/visual_capture_<sha>_<ts>/`,每屏 2 个文件(`<route>_1280x720.png` + `<route>_1920x1080.png`),manifest.txt 记每张状态。

## 截图工具说明(已修,正常应全 READY 干净窗口)
- 干净窗口:用 `window_id.swift`(CGWindowList 取窗口 id)+ `screencapture -o -l<id>`,无桌面杂物。
- 双分辨率:`VISUAL_WINDOW_W/H` env 强制窗口尺寸 + min==max 锁死。1280x720 出 2560x1440px、1920x1080 出 3840x2160px(均 Retina 2x)。
- 若某屏 manifest 显示「全屏兜底」而非「干净窗口」→ 该屏窗口 id 没取到(偶发),重跑该单屏:`tools/visual_capture/visual_capture.sh <route>`。
- 单屏实时看:`flutter run -d macos --dart-define=VISUAL_ROUTE=<route>`(配 `VISUAL_WINDOW_W=1280 VISUAL_WINDOW_H=720` 看 720p)。

## 逐张验收标准(T9)
对每张图(尤其 720p 最低分辨率)检查:
1. **无 debug 字段**:页面右上/角落无 VISUAL_ROUTE 水印、无 skillUsage/debug 计数、无开发占位。
2. **无缺图**:装备/敌人/地图/封面图都加载出来,无 errorBuilder 兜底灰块。
3. **无 overflow**:1280x720 下无 RenderFlex 溢出黄黑条、无文字截断、无控件出界。
4. **风格一致**:水墨克制基调统一(青/墨/宣纸黄/绛红点缀),无 Material 饱和色突兀、无网游金光。

## 交回(closeout 写到 docs/handoff/codex_t9_result_2026-06-09.md)
```
# T9 截图包 closeout
出图目录: docs/handoff/visual_capture_<sha>_<ts>/  (PNG 本地 · gitignored)
逐屏验收表: | route | 720p | 1080p | debug? | 缺图? | overflow? | 风格 | 备注 |
核心 5 张候选(商品页): <route × 分辨率 + 一句话为什么选它>
问题清单(需 Claude 修): <overflow/debug 残留/缺图 的具体屏 + 描述,无则写"无">
```
注:截图 PNG 被 .gitignore 忽略(不入库),留本地;只把 closeout + manifest 交回。商品页图由用户从本地目录取。

## 验收达标线
- 5 张核心图风格一致,能直接作 Steam 商品页候选。
- 全部候选图无 debug 字段、无缺图、无 overflow(有则列进问题清单)。
- 双分辨率都覆盖,720p 重点验 overflow。
