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

- [x] A 类 16 条加前缀修复,候选唯一性逐条实证(16/16 probe 内文件存在)
- [x] C 类逐条 git 历史查证:仅 `tools/balance_simulator.dart` 有 08-15 确证
      先例,但其在 m15_d 同段与 perf_profile/idle_long_run 同为计划任务,
      一致性起见归 D 类不修;其余全部零历史踪迹或歧义候选,归 D 类
- [x] 重扫对账:dead 87 → **71**(恰 -16 守恒;+refs 6/+ignored 2 均本计划档
      自带引用)
- [x] 扫描器两套件绿(纯文档批零 tools/ 改动)
- [ ] PROGRESS 登记守 ≤100 行
- [ ] CI:flutter test 计数 5160 不变

## 残余 71 条定性留痕(机械可修项清零)

- **B 类 11 条**:作者已括号标注 `(已移除)`×7/`(待创建)`×4,真死链且已标注;
  扫描器括号后缀清洗口径问题,不影响清单可用性(标注即否决)
- **D 类 60 条**:全部 git 历史实证「从未存在」(计划未生成:asset manifest
  计划图 7 / m15 法务与性能 spec 计划路径 15 / inner_demon 提示词文档计划图 7)
  或「确曾删除且功能已废除」(pvp 域 GDD 切除 `2d0dcded` / camera_shake
  明删 `778652b5` / 06 月 spec 计划测试文件实装时改名不可确证);与 08-15 批
  同结论模式=接受残余,无 mechanically 可修项

## 红线

- 不动 `lib/`/`.dart`/`tools/`;不改写历史记录(spec 内计划路径不删引用,
  只修能确证搬家的);commit 中文动宾

## 当前恢复点

- **状态**:修复完成,收账中
- **最后完成**:A 类 16 条修复(`59b28090`)· 重扫 dead 71 守恒 · 两套件绿
- **commit 链**:`bbdbdcd3` RP0 → `59b28090` 修复
- **下一步**:merge main → PROGRESS 登记 → push → CI
- **阻塞项**:无
