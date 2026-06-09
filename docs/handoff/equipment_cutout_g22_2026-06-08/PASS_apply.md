# G2.2 Codex PASS 后收尾(草稿 · 等回执再执行)

## A. PROGRESS edit(更新 2026-06-08 续条目 ② 段,净 0 行)

### 标题 old → new
old: 装备 G2.2 抠白底 Phase 0 收口待晚上视觉)**
new: 装备 G2.2 抠白底全闭环)**

### ② 段尾 old → new
old: · **剩 ~20 氛围/泼墨底尾巴需人眼/Codex 定 cut-or-frame + widget 改+替 assets → 晚上视觉验收**。
new: · 分类定稿 **scene 30 / cut 130**(corner-spread + ring-keep 逐张验证,frag 误报弃 · detail 版常是氛围场景即便 icon 干净)· widget 删 multiply 染底(alpha 通道自动路由,无 runtime flag)+ 替 130 透明 assets(51→26MB,scene 30 原图不动)· item_slot 红线测改断言无 multiply · 闸门 analyze 0 / 全量 **1763 测过** · Codex Mac 三屏视觉 PASS · ff 合 main `5734650`。**G2.2 浅底块销账 ✅**。

## B. 命令序列(主仓执行)
```
cd /Users/a10506/Desktop/Projects/挂机武侠
git merge --ff-only worktree-equip-cutout-transparent      # 带 widget+130 assets,HEAD→5734650
# 应用上面 A 的 PROGRESS edit(两处)
git add PROGRESS.md
git commit -m "更新 PROGRESS:装备 G2.2 抠白底全闭环(scene30/cut130 · Codex 视觉 PASS)"
git push origin main
# 清理已合分支 + worktree(Codex 已验完)
git worktree remove --force .claude/worktrees/equip-cutout-transparent
git branch -d worktree-equip-cutout-transparent
```

## C. FAIL 路径(若回执有问题图)
1. 看 result.md 列的问题图 + 类型(矩形块/白边/碎片/残洞)。
2. 碎片/矩形块 = 漏判场景 → manifest 把该图移 scene 集(从 cut 删),重跑替换(它保原图)。
3. 白边/残洞/投影 = 抠图参数 → 调 cut_v3.py(该图 tol / 投影阈值)单独重出,替 worktree assets。
4. 重跑闸门(analyze + item_slot 测 + 全量)→ 再发 Codex 复验。
