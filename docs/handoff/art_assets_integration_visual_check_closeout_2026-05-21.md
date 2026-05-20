# M4 PoC #46 美术 89 张 assets 归位 + Flutter UI 接入视觉验收 closeout(2026-05-21)

> **Codex 桌面 @ Pen Windows 视觉验收完工**(2026-05-21,Pen 跑 `flutter run -d windows` 截 4 图 + 自产 closeout)
> **结果**:**实质 4/4 全 PASS ✅** · 表面 2 PASS + 2 WARN,但 2 WARN 都不是 product bug

---

## §1 4 截图判定矩阵

| # | 文件 | 验收点 | Codex 自评 | 真因判定 | 实质 |
|---|---|---|---|---|---|
| 1 | codex_art_integration_01_splash.png | 启动闪屏 landscape_loading 全屏 + 标题 + 进度圈 | **WARN** | 搜狗输入法浮条叠加 + Pen 屏幕实际 1280×720 限制 — **非 product bug,Windows 测试环境** | **✅ PASS** |
| 2 | codex_art_integration_02_home_feed_seal.png | HomeFeedScreen 右上 36×36 印章 | **WARN** | 实际标题「江湖见闻」(`UiStrings.homeFeedTitle` strings.dart:456),派单 prompt 写「昨晚发生的事」是凭 home_feed_screen.dart:11 注释设计意图描述,不是实际文案 — **派单 prompt 教训,非 product bug** | **✅ PASS** |
| 3 | codex_art_integration_03_seclusion_maps.png | SeclusionMapListScreen 5 张地图缩略 96×64 | **PASS** | 5 张地图缩略全显示,水墨意境清晰 | **✅ PASS** |
| 4 | codex_art_integration_04_locked_map_dim.png | locked 地图 BlendMode.darken + 50% 黑色 alpha 灰化 | **PASS** | locked 灰化效果对比清晰 | **✅ PASS** |

---

## §2 工具链结果

| 项 | 结果 | 备注 |
|---|---|---|
| `git pull` | **FAIL** EOF 反复(SSH/HTTPS git pack 都) | 网络/防火墙/大 pack 问题,Codex 用 GitHub raw/blob fallback 拉运行所需文件,**未 stage/commit/push** |
| `flutter pub get` | ✅ | |
| `flutter run -d windows` | ✅ | |
| `build_runner` | **未跑** | 本次 Phase 2 无 codegen 改动(普通 class 加字段 + 新 Stateful Widget),**验证 派单 prompt 推断正确** |
| 清理 | ✅ | flutter/dart/wuxia_idle 进程已停 + WuxiaRun 计划任务已注销 |

---

## §3 Pen 工作树脏态处理建议(下次会话处理)

**现状**:
- Pen 本地 HEAD `8fbf1f4`(落后 origin/main `4eeb6a9` 2 个 commit)
- Codex 用 raw/blob fallback 拉了「运行所需」文件覆盖工作树,**部分文件 = 9ce0201 内容,git index 仍在 8fbf1f4**
- Pen 工作树是**混合脏态**

**下次 Pen 启动前必做**(memory sink):
1. **SSH 进 Pen** + cd F:\Projects\wuxia_idle
2. `git status` 看 Codex 覆盖的脏文件清单 — 可能与 9ce0201/4eeb6a9 内容相同(等 git stat 看)
3. `git fetch origin` 测试 git pack 是否仍 EOF
4. 如果 fetch 通:`git reset --hard origin/main`(把工作树 reset 到最新 4eeb6a9,清掉 Codex raw fallback 覆盖的脏状态)
5. 如果 fetch 仍 EOF:
   - 试启动 Pen 端 V2Ray/clash 代理后重试
   - 或者 Mac 端 `scp -r` 推 .git/ 到 Pen 绕开 GitHub
   - 或者**冷启动**:Pen 端 `git clone https://github.com/Zed1118/wuxia_idle.git`(浅 clone --depth 1 可能 EOF 触发率更低)

**不阻塞下波候选 1 启动** — 下波 1.0 Demo §7 UI 完善阶段是 Mac 端开发,Pen 不参与直到下次视觉验收。

---

## §4 教训沉淀 + memory sink

### 教训:派单 prompt 引用 UI 字符串必先 grep 实际值

派单 prompt §3 (#2 home_feed seal 验收点) 写「『昨晚发生的事』标题旁」— 凭 `home_feed_screen.dart:11` 注释「"昨晚发生的事"上线第一屏(GDD §9.2 / P1 #42 Phase 3)」描述意图。**实际 UI 显示是 `UiStrings.homeFeedTitle = '江湖见闻'`(strings.dart:456)**。Codex Pen 看到「江湖见闻」与派单 prompt 描述不符,标 WARN — 是派单方失误,不是 product 失误。

**应对**:派单 prompt 引用任何 UI 显示字符串前,必 `grep <KeyName>` lib/shared/strings.dart 拿实际 value。`UiStrings` 设计意图描述 vs 实际文案可能不同(后期改文案不动注释),**永远以 strings.dart 为准**。

sink:扩展 [[feedback_codex_pen_windows_visual_check]] 「派单方(Mac Opus)开工前必做」清单加第 5 项「UI 字符串引用必先 grep strings.dart 实际值」+ 加本次实战补充。

---

## §5 候选 1 完工总结

候选 1(M4 PoC #46 美术 89 张 assets 归位 + Flutter UI 3 处接入)**全闭环 ✅**:
- Mac 端 Phase 1+2+3 完工(commit `9ce0201`)
- 阶段性审查 4 项完工(commit `4eeb6a9`)
- Pen 视觉验收 4/4 实质 PASS(本 closeout)
- 1 教训 sink memory 扩展(派单 prompt UI 字符串必 grep)

**美术成果首次落入 Flutter app,Pen 实测视觉验证通过**。**P1.3 美术 PoC 完成度 ~80%**(余 LoRA 训练数据扩充未开工,候选 4 远期)。

---

## §6 下波候选(优先级排,与 stage_audit_2026-05-20.md §5 一致)

| # | 候选 | 模型 | 时长 | 备注 |
|---|---|---|---|---|
| 1 ⭐ | **1.0 Demo §7 UI 完善阶段**:装备列表页 + 详情弹窗 + 师徒展示页 + UI 类资源全接入 | opus xhigh | 2-5 工日 | P1.3 收口最后里程碑 · 一次性消费余下 64 装备 detail + 3 立绘 + 8 UI 资源 |
| 2 | 心法相生 §4.5 触上限 8 重设计 | sonnet+opus | 1-2h | 非阻塞 |
| 3 | Pen 工作树脏态处理 + git pack EOF 排查 | opus | 30min-1h | 下次 Pen 视觉验收前必做 |
| 4 | P2 第二条主线启动准备 | opus | 远期 | 需先候选 1 完工 |

---

**closeout 完结**。Codex Pen 视觉验收综合自评:Mac 端 3 处接入产物达标,2 WARN 是测试环境 + 派单 prompt 失误而非 product bug,实质 4/4 PASS。
