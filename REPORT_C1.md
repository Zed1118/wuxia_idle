# 夜批单 C1 · 场景图伪文字题字清查报告

状态：**[READY]**

- 日期：2026-08-06（执行跨至本地 2026-08-07）
- 分支：`codex/tonight-inscription`
- 基线：`74a7993c`
- 范围：仅 `assets/scenes/` 内本单目标图、`docs/dispatch_evidence/inscription_2026-08-06/` 与本报告
- Flutter：按任务要求未运行

## 结果摘要

- 已确认清单：8/8 张完成。
- `narrative_stage_*.png`：105/105 张逐张放大目检；12 张有多字题字或伪字形并完成处理，93 张无目标问题、不处理。
- 合计处理：20 张。
- 所有处理图均保持原尺寸 `1456×816`、原数据格式 WebP（文件扩展名仍为 `.png`），以 `cwebp -q 80` 压回。
- 放大初检：20/20 未见冒充可读文本的多字题字、伪汉字、伪英文或签名残留。
- 印章：C1 复检返修后，本批 20/20 张均保留暗红/朱红印章母题；`narrative_stage_02_02.png` 已补回同批风格小印。
- [BLOCKED]：无。

## Phase 0 判定依据

工作树检出会刷新文件系统 mtime，因此不能直接复现历史的“2026-07-02 21:17”时间戳。改用 Git 首次纳入历史确认早期批次为 `narrative_stage_01_01.png` 至 `narrative_stage_06_05.png` 共 30 张，同时仍对当前库内全部 105 张 `narrative_stage_*.png` 做了逐张放大目检；07–21 章共 75 张均无本单目标问题。

### Phase 0 全量精确判定表

| 文件名 | 有无题字 | 题字位置 | 是否处理 |
|---|---|---|---|
| `narrative_stage_01_01.png` | 无 | — | 否 |
| `narrative_stage_01_02.png` | 有 | 左下多字题字；门侧小牌伪字形 | 是 |
| `narrative_stage_01_03.png` | 有 | 右下多字题字 | 是 |
| `narrative_stage_01_04.png` | 无 | — | 否 |
| `narrative_stage_01_05.png` | 有 | 右下印章上方多字题字 | 是 |
| `narrative_stage_02_01.png` | 有 | 右下落款；车队旗面伪字形 | 是 |
| `narrative_stage_02_02.png` | 有 | 左下多字题字 | 是 |
| `narrative_stage_02_03.png` | 有 | 画面中央及背景卷轴、牌匾伪字形 | 是 |
| `narrative_stage_02_04.png` | 无 | — | 否 |
| `narrative_stage_02_05.png` | 有 | 左下伪英文签名 | 是 |
| `narrative_stage_03_01.png` | 有 | 左上多列题字 | 是 |
| `narrative_stage_03_02.png` | 有 | 擂台红幡及上方中立牌匾伪字形 | 是 |
| `narrative_stage_03_03.png` | 无 | — | 否 |
| `narrative_stage_03_04.png` | 无 | — | 否 |
| `narrative_stage_03_05.png` | 无 | — | 否 |
| `narrative_stage_04_01.png` | 有 | 右上多字题字 | 是 |
| `narrative_stage_04_02.png` | 无 | — | 否 |
| `narrative_stage_04_03.png` | 无 | — | 否 |
| `narrative_stage_04_04.png` | 有 | 红色、浅色军旗伪字形 | 是 |
| `narrative_stage_04_05.png` | 无 | — | 否 |
| `narrative_stage_05_01.png` | 无 | — | 否 |
| `narrative_stage_05_02.png` | 无 | — | 否 |
| `narrative_stage_05_03.png` | 无 | — | 否 |
| `narrative_stage_05_04.png` | 无 | — | 否 |
| `narrative_stage_05_05.png` | 无 | — | 否 |
| `narrative_stage_06_01.png` | 无 | — | 否 |
| `narrative_stage_06_02.png` | 无 | — | 否 |
| `narrative_stage_06_03.png` | 有 | 右上多字题字 | 是 |
| `narrative_stage_06_04.png` | 无 | — | 否 |
| `narrative_stage_06_05.png` | 无 | — | 否 |
| `narrative_stage_07_01.png` | 无 | — | 否 |
| `narrative_stage_07_02.png` | 无 | — | 否 |
| `narrative_stage_07_03.png` | 无 | — | 否 |
| `narrative_stage_07_04.png` | 无 | — | 否 |
| `narrative_stage_07_05.png` | 无 | — | 否 |
| `narrative_stage_08_01.png` | 无 | — | 否 |
| `narrative_stage_08_02.png` | 无 | — | 否 |
| `narrative_stage_08_03.png` | 无 | — | 否 |
| `narrative_stage_08_04.png` | 无 | — | 否 |
| `narrative_stage_08_05.png` | 无 | — | 否 |
| `narrative_stage_09_01.png` | 无 | — | 否 |
| `narrative_stage_09_02.png` | 无 | — | 否 |
| `narrative_stage_09_03.png` | 无 | — | 否 |
| `narrative_stage_09_04.png` | 无 | — | 否 |
| `narrative_stage_09_05.png` | 无 | — | 否 |
| `narrative_stage_10_01.png` | 无 | — | 否 |
| `narrative_stage_10_02.png` | 无 | — | 否 |
| `narrative_stage_10_03.png` | 无 | — | 否 |
| `narrative_stage_10_04.png` | 无 | — | 否 |
| `narrative_stage_10_05.png` | 无 | — | 否 |
| `narrative_stage_11_01.png` | 无 | — | 否 |
| `narrative_stage_11_02.png` | 无 | — | 否 |
| `narrative_stage_11_03.png` | 无 | — | 否 |
| `narrative_stage_11_04.png` | 无 | — | 否 |
| `narrative_stage_11_05.png` | 无 | — | 否 |
| `narrative_stage_12_01.png` | 无 | — | 否 |
| `narrative_stage_12_02.png` | 无 | — | 否 |
| `narrative_stage_12_03.png` | 无 | — | 否 |
| `narrative_stage_12_04.png` | 无 | — | 否 |
| `narrative_stage_12_05.png` | 无 | — | 否 |
| `narrative_stage_13_01.png` | 无 | — | 否 |
| `narrative_stage_13_02.png` | 无 | — | 否 |
| `narrative_stage_13_03.png` | 无 | — | 否 |
| `narrative_stage_13_04.png` | 无 | — | 否 |
| `narrative_stage_13_05.png` | 无 | — | 否 |
| `narrative_stage_14_01.png` | 无 | — | 否 |
| `narrative_stage_14_02.png` | 无 | — | 否 |
| `narrative_stage_14_03.png` | 无 | — | 否 |
| `narrative_stage_14_04.png` | 无 | — | 否 |
| `narrative_stage_14_05.png` | 无 | — | 否 |
| `narrative_stage_15_01.png` | 无 | — | 否 |
| `narrative_stage_15_02.png` | 无 | — | 否 |
| `narrative_stage_15_03.png` | 无 | — | 否 |
| `narrative_stage_15_04.png` | 无 | — | 否 |
| `narrative_stage_15_05.png` | 无 | — | 否 |
| `narrative_stage_16_01.png` | 无 | — | 否 |
| `narrative_stage_16_02.png` | 无 | — | 否 |
| `narrative_stage_16_03.png` | 无 | — | 否 |
| `narrative_stage_16_04.png` | 无 | — | 否 |
| `narrative_stage_16_05.png` | 无 | — | 否 |
| `narrative_stage_17_01.png` | 无 | — | 否 |
| `narrative_stage_17_02.png` | 无 | — | 否 |
| `narrative_stage_17_03.png` | 无 | — | 否 |
| `narrative_stage_17_04.png` | 无 | — | 否 |
| `narrative_stage_17_05.png` | 无 | — | 否 |
| `narrative_stage_18_01.png` | 无 | — | 否 |
| `narrative_stage_18_02.png` | 无 | — | 否 |
| `narrative_stage_18_03.png` | 无 | — | 否 |
| `narrative_stage_18_04.png` | 无 | — | 否 |
| `narrative_stage_18_05.png` | 无 | — | 否 |
| `narrative_stage_19_01.png` | 无 | — | 否 |
| `narrative_stage_19_02.png` | 无 | — | 否 |
| `narrative_stage_19_03.png` | 无 | — | 否 |
| `narrative_stage_19_04.png` | 无 | — | 否 |
| `narrative_stage_19_05.png` | 无 | — | 否 |
| `narrative_stage_20_01.png` | 无 | — | 否 |
| `narrative_stage_20_02.png` | 无 | — | 否 |
| `narrative_stage_20_03.png` | 无 | — | 否 |
| `narrative_stage_20_04.png` | 无 | — | 否 |
| `narrative_stage_20_05.png` | 无 | — | 否 |
| `narrative_stage_21_01.png` | 无 | — | 否 |
| `narrative_stage_21_02.png` | 无 | — | 否 |
| `narrative_stage_21_03.png` | 无 | — | 否 |
| `narrative_stage_21_04.png` | 无 | — | 否 |
| `narrative_stage_21_05.png` | 无 | — | 否 |


## 已处理图片与逐张自检

“规格通过”表示同尺寸、同数据格式；每张的字节数和 SHA-256 见证据目录中的 `spec_check.tsv`。

| 文件名 | 来源 | 原问题位置 | 方法 | 规格 | 零伪文字 | 印章 |
|---|---|---|---|---|---|---|
| `battle_frontier.png` | 确认清单 | 右侧竖列题字 | 参考图锚定同构重出/局部修补 | 通过 | 放大目检通过 | 原有暗红印章保留 |
| `battle_dock.png` | 确认清单 | 左上多字题字 | 参考图锚定同构重出/局部修补 | 通过 | 放大目检通过 | 原有暗红印章保留 |
| `battle_escortroad.png` | 确认清单 | 左上多字题字 | 参考图锚定同构重出/局部修补 | 通过 | 放大目检通过 | 原有暗红印章保留 |
| `battle_teahouse.png` | 确认清单 | 左上多字题字 | 参考图锚定同构重出/局部修补 | 通过 | 放大目检通过 | 原有暗红印章保留 |
| `battle_temple.png` | 确认清单 | 左上多字题字 | 参考图锚定同构重出/局部修补 | 通过 | 放大目检通过 | 原有暗红印章保留 |
| `chapter_02_cover.png` | 确认清单 | 左侧多字题字；门侧小牌伪字形 | 参考图锚定重出＋局部二次修补 | 通过 | 放大目检通过 | 原有暗红印章保留 |
| `chapter_04_cover.png` | 确认清单 | 右侧多字题字 | 参考图锚定同构重出/局部修补 | 通过 | 放大目检通过 | 原有暗红印章保留 |
| `chapter_06_cover.png` | 确认清单 | 左上多字题字 | 参考图锚定同构重出/局部修补 | 通过 | 放大目检通过 | 原有暗红印章保留 |
| `narrative_stage_01_02.png` | Phase 0 | 左下多字题字；门侧小牌伪字形 | 参考图锚定同构重出/局部修补 | 通过 | 放大目检通过 | 原有暗红印章保留 |
| `narrative_stage_01_03.png` | Phase 0 | 右下多字题字 | 参考图锚定同构重出/局部修补 | 通过 | 放大目检通过 | 原有暗红印章保留 |
| `narrative_stage_01_05.png` | Phase 0 | 右下印章上方多字题字 | 参考图锚定同构重出/局部修补 | 通过 | 放大目检通过 | 原有暗红印章保留 |
| `narrative_stage_02_01.png` | Phase 0 | 右下落款；车队旗面伪字形 | 参考图锚定同构重出/局部修补 | 通过 | 放大目检通过 | 原有暗红印章保留 |
| `narrative_stage_02_02.png` | Phase 0 | 左下多字题字 | C1 复检返修：复用同批印章母题，左下水岸留白补暗红小印 | 通过 | 放大目检通过 | **返修通过：无题字，暗红印章已补回** |
| `narrative_stage_02_03.png` | Phase 0 | 画面中央及背景卷轴、牌匾伪字形 | 参考图锚定同构重出/局部修补 | 通过 | 放大目检通过 | 原图无章，未新增 |
| `narrative_stage_02_05.png` | Phase 0 | 左下伪英文签名 | 参考图锚定同构重出/局部修补 | 通过 | 放大目检通过 | 原图无章，未新增 |
| `narrative_stage_03_01.png` | Phase 0 | 左上多列题字 | 参考图锚定同构重出/局部修补 | 通过 | 放大目检通过 | 原有暗红印章保留 |
| `narrative_stage_03_02.png` | Phase 0 | 擂台红幡及上方中立牌匾伪字形 | 参考图锚定重出＋局部二次修补 | 通过 | 放大目检通过 | 原图无章，未新增 |
| `narrative_stage_04_01.png` | Phase 0 | 右上多字题字 | 参考图锚定同构重出/局部修补 | 通过 | 放大目检通过 | 原有暗红印章保留 |
| `narrative_stage_04_04.png` | Phase 0 | 红色、浅色军旗伪字形 | 参考图锚定同构重出/局部修补 | 通过 | 放大目检通过 | 原有暗红印章保留 |
| `narrative_stage_06_03.png` | Phase 0 | 右上多字题字 | 参考图锚定同构重出/局部修补 | 通过 | 放大目检通过 | 原有暗红印章保留 |

## 处理方法与提示词口径

使用内置 `image_gen` 的参考图锚定编辑，以原图为唯一构图参照；按画面情况选择同构重出或局部修补。输出后统一压回 WebP q80，并同名覆盖。二次复检发现两处小残留后再次定点处理：

- `chapter_02_cover.png`：补清门侧小牌伪字形。
- `narrative_stage_03_02.png`：补清擂台幡面细小笔画。

实际使用的规范化提示词集合如下（每张仅替换方括号中的对象/位置）：

> Use case: precise-object-edit. Input image: Image 1 is the exact edit target and composition anchor. Remove [specific multi-character calligraphy, pseudo-glyphs, pseudo-English signature, or banner/placard markings] and naturally reconstruct [the matching paper, wall, cloth, mist, or landscape surface]. Keep the exact crop, composition, palette, ink-wash brushwork, lighting, texture, and all scene objects. Preserve every existing dark-cinnabar/red seal as a single non-text decorative seal. No Chinese characters, pseudo-Chinese glyphs, English letters, signatures, captions, labels, watermarks, or readable writing outside the seal motifs. Do not add or remove unrelated objects. Use environmental and weather language only.

旗幡、卷轴与牌匾场景另加：目标载体保留为空白布面/纸面/木面，不改变其位置、数量和形状。

## 证据

- `build/visual_acceptance/2026-08-06_inscription/contact_sheet_01.png`：5 张 battle 图 before/after。
- `build/visual_acceptance/2026-08-06_inscription/contact_sheet_02.png`：3 张 chapter cover＋`01_02`、`01_03` before/after。
- `build/visual_acceptance/2026-08-06_inscription/contact_sheet_03.png`：`01_05`、`02_01`、`02_02`、`02_03`、`02_05` before/after。
- `build/visual_acceptance/2026-08-06_inscription/contact_sheet_04.png`：`03_01`、`03_02`、`04_01`、`04_04`、`06_03` before/after。
- `docs/dispatch_evidence/inscription_2026-08-06/spec_check.tsv`：20 张逐图尺寸、格式、编码参数、字节数与结果哈希。

## 第二轮交叉复检

对 20 张处理结果的四张 before/after contact sheet 做了逐角落复检，重点检查题字原位置、门牌、旗面、卷轴、牌匾和画面边缘。初轮发现的两处小残留已二次修补并重新生成证据；最终未见已知伪文字残留。构图、色调、水墨笔触和暗红印章母题均保持在同一视觉语系。

## 剩余风险

- 视觉终拍仍由用户完成；本报告仅代表执行侧放大初检。
- 参考图重出会产生局部笔触与纹理差异，虽已通过同构图和整体风格复检，但不等同像素级修复。
- 当前无已知未处理目标，也无需要留终审的 [BLOCKED] 图片。

## 边界与红线检查

未修改 `lib/`、`test/`、`data/`、`pubspec.yaml`、`assets/` 其他子目录或非本单文档；未涉及数值、玩法、文案配置或三系规则。
