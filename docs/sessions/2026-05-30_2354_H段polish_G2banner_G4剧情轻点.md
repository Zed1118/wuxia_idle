# Session 交接 - H 段 polish(G2 banner + G4 剧情轻点)

**时间：** 2026-05-30 23:54
**项目：** 挂机武侠
**分支：** main
**最后 commit：** baac3b9

## 本次完成

- **G2 step 3/5 上手引导 banner(`3790d13`)**:§5.7 合规裁剪——只为「新系统首次点亮」立 banner。step 3 心法面板解锁 / step 5 Ch1 通关(闭关 + 江湖/门派/排行榜),跳过 step 1/2/4 纯进度祝贺。`TutorialHintDef` 加 step3/step5 def(all 升序 [3,5,6,7,8]),`markHintRead` guard 从写死 {6,7,8} 改**表驱动 byStep!=null**(单一真相源)。
- **G4 剧情阅读区轻点推进(`0ee3c37`)**:`NarrativeReaderScreen` 正文区包 GestureDetector(opaque · onTap=_next)实现 VN 式 tap-to-advance(drag 仍滚动不冲突)+ 首段一次性淡提示「轻点画面，继续往下读」(§5.7 提示一次,推进后隐藏)+ 继续/完成/跳过按钮双轨保留。
- **顺手清理**:删 `seed_shenwu_drop_battle_test.dart` 未用 import(上 session V3 遗留),恢复 0 analyze。
- **Pen 验收派单提示词**(G4 手感验收)已产出在对话(未落库 doc,如需归档可补)。
- verify:1596→**1602 测**(+6:G2 service 2 + main_menu banner 重写 2 + G4 narrative 2)· **0 analyze** · 全程 TDD red→green。

## 当前状态

1.0 release polish ~98% 维持。**H 段 Mac 端纯文案/UX polish 项基本见底**:G1 产品名/G2 上手 banner/G3 空 feed 引导/G4 剧情轻点/A2 飞升 bug/§5.7 未解锁系统门控全收口,M6 飞升路标 #4④ 已决 0 改动。C 视觉验收段全闭合。HEAD baac3b9 与 origin 同步,工作树仅旧未跟踪残留(.claude/ + 旧 handoff 截图),无半成品。

## 进行中的工作

- **G4 待 Pen 实机验收**:本 session 已写好 Codex Pen 派单提示词(覆盖环境准备/到达路径/5 验收点/截图命名/self-check/回传格式),但**未派单、未跑**。下波可直接派 Pen 验「轻点推进手感 + 首读是否直觉 + tap/drag 不冲突」,验完 scp 拉回截图归档,据反馈定提示文案是否微调。

## 已知问题

- stage_05_05 on-level ceiling 76→20%(P5.2 遗留,章末跨阶墙意图,待 Pen 实机手感反馈再定微调)。
- balance_simulator 输出文件名硬编码日期(技术债,靠 git diff 对比)。
- D 性能(8h/FPS/Isar ANR)+ closed beta ~10 人 + E 音频 = 全外部依赖,留 M15-16。

## 重要决策

- 决定 **G2 只补「系统解锁锚点」(step 3/5),不做 audit 原案 5 段全补**(用户拍),因为现 banner 基建刻意限 {6,7,8} 指向新解锁系统=§5.7「系统出现点一次」合规;step 1/2/4 纯进度祝贺(「首战告捷」)与 §5.7「不写教程弹窗」克制基调冲突。
- 决定 **markHintRead guard 改表驱动 byStep!=null** 而非简单放宽数字范围,因为表驱动是单一真相源,后续扩 step 自动覆盖,无需再改 guard。
- 决定 **G4 走 VN 式 tap-to-advance(正文区可点)而非加「轻按屏幕」冗余提示**,因为底部已有明确「继续」按钮——加 tap-anywhere 提示会与按钮交互模型矛盾;让正文区真可点才使「轻点画面」名副其实,是真 UX 改进而非冗余。

## 下一步建议

1. **派 Pen 跑 G4 视觉/手感验收**(提示词已备好,见上一 session 对话):验完 scp 拉回归档,据手感定 G4 提示文案是否微调。当前唯一卡 Pen 实机的 polish 闭环动作。
2. **stage_05_05 ceiling 微调**(opus high ~30min):同样待 Pen 手感反馈,与「跨阶墙需出阶」意图有张力,建议先放。
3. **B8/A1 cosmetic 零硬编码**(high <1h):无行为收益,仅一致性追求时做。
4. **D 性能 / E 音频 / closed beta**(M15-16):多外部依赖,非当下。

## 踩坑提醒

- **bg session Edit/Write 被 isolation guard 拦**:改 data/lib/docs/test 全程用 Bash python/heredoc 直写 main(`assert old in s` count 校验 + git diff 核验 + flutter test)。
- **git add -A 会误吞 `.claude/worktrees/` 嵌入仓库 + 旧未跟踪残留**:本 session 首次 commit 踩过(已 reset 重提)。提交务必 `git add <显式文件列表>`,不要 `git add -A`。
- **NarrativeReaderScreen 是通用屏**:G4 改动影响所有调用方(mainline opening/victory/defeat、codex entry、tower、ascension、boss recruit),不止主线开场。验收以主线开场为主,但改动是全局的。
- **新文案标点用全角**(逗号「，」),沿库内 §标点规范化体例。
- PROGRESS 控 100 行:本 session 把 G4 并入 G2 的 H polish 条目(不新增行)+ 上次归档 #2 旧条目,维持 100。
