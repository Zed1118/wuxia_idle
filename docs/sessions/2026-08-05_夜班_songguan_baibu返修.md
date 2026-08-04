# 夜班交接:送关旧部白布动势返修(BACKLOG 二#8 · 候选分支可审,待终拍)

> 2026-08-05 夜班 · 分支 `night/20260805-songguan-baibu` · 基线 main=`0bb16d37`
> 派单 `docs/superpowers/plans/2026-08-05-songguan-baibu-imagegen-dispatch.md`:§六.1-5 已走完,余 §六.6 用户终拍。

## 结果(全部本会话实测,不采信出图端自报)

- **PIL 独立复测通过**(自写脚本逐项):PNG 1024×1536 RGBA / 四角 alpha 全 0 /
  bbox(半开)=(43,91,1001,1423) / 纵跨 1332(现版 1339)/ 脚底 fraction **0.926432**,
  与 `character_avatar.dart` 表值 0.9277 偏差 0.0013 ≤ 派单 0.002 阈值 → **表值不动**。
  右缘 23px 是枪尖(现版同位 21px);飘布尾端在画面中部,距边 ≥30px 达标。复测与 Codex report 逐值一致。
- **资产已覆盖** `assets/enemies/ruguan_songguan_jiubu.png`(in-place,接线零改)。真 PNG 体例与批 C
  8 张一致(批 C 样本 PIL 实测 format=PNG);旧文件是 webp-in-png 82KB、新 820KB,待未来 webp 压缩批一并压。
- **targeted 五文件逐跑**(防 PROGRESS 两次实锤的批跑漏跑坑):character_avatar 21 / standee_asset_role 3 /
  asset_audit 4 / webp_in_png_decode 2 / art_tone_audit 3 = **33 pass 0 fail**;`flutter analyze` **0 issue**。
- **stage_20_04 smoke 通过**:1280×720,log 含 `VISUAL_ROUTE_READY` + `window_id:128154`(pid 绑窗,非
  fallback);合成明度/接地/体量无异常,白布向后飘 + 枪尖压下在战斗屏可辨,「势」金圈为脆弱窗口机制指示非异常。
  证据:`build/visual_acceptance/battle_audit_stage_20_04/1280x720/`;候选原图 + report 在
  `build/dispatch/songguan_baibu_20260805/`(均 gitignored,**终拍前勿删本 worktree**)。

## commit 清单(基线 `2c5278f1` 之上 3 个小切片)

1. `ea7bd91c` 资产覆盖 + character_avatar 注释补复测记录(表值/行为零改)
2. `d9cf98e4` cherry-pick `365237ad`(capture 工具 pid 绑窗修复,取自 `night/20260805-capture-window-pid`,
   仅 tools/ 两文件,零无关内容)
3. 本 commit:handoff + [BLOCKED] 就绪标记

## 自主决策(3,均局部可逆)

- fraction 未超阈值故不改表值,但 `character_avatar.dart` 该行旧注释引旧图 bbox,补 2 行复测注记防注释-实物 drift。
- capture 修复用 cherry-pick 单 commit 取证,不合那条分支的 docs commit(防混入晨批评审范围)。
- BACKLOG 二#8 销账与 PROGRESS 落账**留给晨间合并会话**——两条夜班分支若都改账本文件必撞合并冲突。

## 恢复点 / 晨间衔接

- 状态:**[BLOCKED] 待用户终拍**(派单 §七清单,同脸/动势/画风三项全归用户;材料=smoke 截图 + 候选 PNG)。
- 终拍 PASS → §8.2 Gate 复核 → 合并:本分支与 `night/20260805-capture-window-pid` 都含同源 capture 修复
  (cherry-pick,patch 相同),先合谁都行,后合者该两文件自动收敛 → BACKLOG 二#8 销账 + PROGRESS 落账。
- 终拍 FAIL → 沿派单 §三重出(锚不变),revert `ea7bd91c` 即回旧图。
- fresh worktree 坑已踩平:本 worktree 已跑 `flutter pub get` + `build_runner`(缺它们 flutter test 直接
  工具层崩 "Bad state: No element",非测试失败);`.g.dart` 未入库。
- 夜班无其他可自主候选:BACKLOG 一区 8 条全拍板类,二#9/#10 已由另一夜班分支查明/证伪待晨批销账,
  三区依赖锁死,四区塔扩展已实装待条目更新。
