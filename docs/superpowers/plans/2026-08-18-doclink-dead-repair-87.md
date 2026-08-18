# 剩余 87 条死链修复批(2026-08-18)

> 分支 `fix/doclink-dead-repair-0818` · 基于 main `b077e939`
> 前置:扫描器已升级「可引用事实源」(merge `2d909517`),dead 87 可直接当修复清单
> 基线:scanned 1299 / refs 8296 / alive 6688 / **dead 87** / ignored 693 / archival 828

## 摸底分类(87 条 / 72 唯一目标)

- **A 类 · phase0 gate 报告缺 `tools/phase0minus_probe/` 前缀(16 条)**:
  `docs/phase0/2026-08-14-phase0-gate-readiness-report.md` 引用 probe 子项目
  (199 tracked 文件)内部路径时以 probe 根为基准写,机械可修
- **B 类 · 作者已标注 `(已移除)`/`(待创建)`(11 条)**:真死链且已标注,
  属扫描器括号后缀清洗口径问题,不修文档(处置待定,倾向留账)
- **C 类 · 唯一同名搬家/改名待实证(约 20 条)**:逐条 `git log --follow`/
  basename 候选查证,确证者修
- **D 类 · 计划未生成/历史规划路径(spec 内约 40 条)**:目标从未存在
  (asset manifest 计划图/m15 spec 计划工具/pvp 废弃域等),无可修项,
  归类留痕

## 验收标准

- [ ] A 类 16 条加前缀修复,候选唯一性逐条实证
- [ ] C 类逐条 git 历史查证,确证者修、存疑者归 D 类留痕
- [ ] 重扫对账:dead 降幅 = 修复条数,零新增(守恒)
- [ ] 扫描器两套件绿(纯文档批不动 tools/,应零回归)
- [ ] PROGRESS 登记守 ≤100 行 · 不可修残余入 BACKLOG 或报告留痕
- [ ] CI:flutter test 计数 5160 不变

## 红线

- 不动 `lib/`/`.dart`/`tools/`;不改写历史记录(spec 内计划路径不删引用,
  只修能确证搬家的);commit 中文动宾

## 当前恢复点

- **状态**:RP0,计划档冻结中
- **最后完成**:分支已建,基线落盘 `build/repair_0818_baseline.json`,
  87 条明细 `build/repair_0818_rows.txt`,机械摸底(tracked/历史/basename 候选)完成
- **下一步**:C 类逐条实证 → A/C 类修复 → 重扫对账
- **阻塞项**:无
