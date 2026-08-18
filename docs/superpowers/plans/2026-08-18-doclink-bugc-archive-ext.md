# Bug C 修复 + 归档扩类 + 扫描器定位升级实装(2026-08-18)

> 分支 `fix/doclink-bugc-archive-ext-0818` · 基于 main `6279f2a2`
> 用户已拍板:一#18「先修 Bug C 再升级」+ 一#20「(b) 扩归档类 + audio 单列」
> 依据:重评报告 `docs/dispatch/reports/2026-08-18_doclink_scanner_reeval.md`

## 实装内容

1. **Bug C 清洗**:`clean_target` 在已知扩展名后遇空格/§ 截断(与 Bug B 冒号
   截断同体例)。tracked 零空格路径(已实测),无误伤面。口径留痕:截断后不验
   段/章节存在性,与既有 `#锚点` 剥而不验口径一致——第 4 条
   `visual_capture.sh battle_interrupt_caption` 将从 dead 翻 alive(语义死、
   机器活,记为口径边界,不是回归)
2. **ARCHIVAL_DIRS 扩四目录**:sessions/dispatch/superpowers/audit(推翻
   08-12「只含 handoff」拍板——用户 2026-08-18 重拍)。常量注释同步更新
3. **audio 指南入 EXCLUDE_FILES**:`docs/audio_asset_generation_guide.md`
   36 条计划素材清单,与 PATH_MIGRATION_MAP 自指同构先例;
   另 1 条在 spec/m15_e(历史 spec 引用,归 archival 类吸收)
4. **tools/README.md 定位升级**:「可试用·非终审事实源」→「可引用事实源」,
   归档范围描述同步
5. **测试**:test_doc_link_scan.py 补 Bug C 样例(空格/§截断)+ 归档扩类样例
   + EXCLUDE_FILES 样例;既有 34 例零回归

## 验收标准

- [ ] Bug C 修法红绿轨迹:先加翻红测(钉 4 条形态中可测者)→ 实装复绿
- [ ] 破坏证红:反向补丁还原 Bug C 清洗 → 新测精确红 → 还原复绿
- [ ] 扫描器测试全绿(34 既有 + 新增)
- [ ] 新基线实测:dead 预期 ≈86(124 残余 - jianghu 翻 alive 1 - audio 36 -
      §十二×2 移 archival 计入吸收;以实跑为准并逐条归因)
- [ ] BACKLOG 一#18/#20 销行 · PROGRESS 登记守 ≤100 行
- [ ] CI:flutter test 计数 5160 不变

## 红线

- 不动 `lib/`/`.dart`;commit 中文动宾;修扫描器行为必须测试先行

## 当前恢复点

- **状态**:RP0,计划档冻结中
- **最后完成**:分支已建,预查完成(零空格路径/audio 单文档/Bug C 4 条分布)
- **下一步**:红测 → 实装
- **阻塞项**:无
