# Codex W14-3-C visual check closeout(2026-05-14)

> 执行方: Codex Desktop @ Pen Windows
> 仓库: `F:\Projects\wuxia_idle`
> 最终验收 HEAD: `db046fa feat(W14-3-B): 补 W14-2 新 12 条 encounter events 文案`

---

## 1. 结论

最低线已达成: `5-2 / 5-3 / 6-1 / 6-2` 四张必收截图齐。

额外拿到 `5-4` cross-fade 中间帧,能清楚看到 opening 与 outcome 文案重叠淡入淡出,可作为 W14-3-C 节奏精修的强证据。

本次未强验 W14-2 12 条新 events placeholder,按派单跳过。EncounterSkillSection 仅验 disabled 空态,完整 unlocked 态 / bottom sheet / lock icon 留下批。

---

## 2. 环境与准备

| 项 | 结果 | 备注 |
|---|---|---|
| 派单要求 HEAD | `c8bfcb9` / 文档内旧写 `da61652` | 开局先见 `c8bfcb9`,执行中本地同步到 `db046fa` |
| 最终实际 HEAD | `db046fa` | 包含 W14-3-B 文案补丁 |
| `WuxiaRun` | Running,但无可见游戏窗口 | 任务在后台运行,当前桌面不可见 |
| 旧 Debug exe | 可启动,但 UI 无 EncounterSkillSection | 判定为旧构建,不适合验当前源码 |
| 本地生成 | `dart run build_runner build --delete-conflicting-outputs` 成功 | 写 28 个 gitignored outputs |
| 本地构建 | `flutter build windows --debug` 成功 | 随后启动 Debug exe 验收 |

备注:第一次 `flutter build windows --debug` 因缺 `encounter_progress.g.dart` / provider 生成文件失败,与 Pen 端既有 build_runner 踩坑一致。生成后重建通过。

---

## 3. 跑通情况表

| 验收点 | 截图 | 状态 | 视觉判断 |
|---|---|---|---|
| 5-1 dialog opening fade-in | `docs/screenshots/w14_3c_dialog_opening_fadein.png` | WARN 降级 | 未抢到 500ms fade-in 中间帧,文件为 opening 稳定帧副本 |
| 5-2 dialog opening full | `docs/screenshots/w14_3c_dialog_opening_full.png` | PASS | `du_ke_wen_dao` title/opening/3 choices 正常,无截断 |
| 5-3 dialog outcome full | `docs/screenshots/w14_3c_dialog_outcome_full.png` | PASS | 选择「喝下这杯」后 outcome body + 「行路 ->」正常 |
| 5-4 outcome cross-fade | `docs/screenshots/w14_3c_dialog_outcome_crossfade.png` | PASS | opening 与 outcome 同屏半透明叠化,证明非瞬间替换 |
| 6-1 EncounterSkillSection empty | `docs/screenshots/w14_3a_encounter_skill_section_empty.png` | PASS | 显示「未装备奇遇招式」与 disabled「尚无可装备奇遇招式」 |
| 6-2 EncounterSkillSection layout | `docs/screenshots/w14_3a_encounter_skill_section_in_layout.png` | PASS | 区段位于心法之后、师承之前,独立可识别 |

---

## 4. Dialog 节奏描述

触发路径: Phase 2 调试场景 -> VC seed -> 主线第一章 -> `stage_01_01` 重打胜利后触发 `du_ke_wen_dao`。

观察结果:
- opening 弹窗稳定显示后,整体暗幕 + 卡片层次清楚,色调克制。
- choice 点击后约 420ms cross-fade 可见:旧 opening 文案、choice 按钮与新 outcome 文案在同一帧中以不同透明度叠化。
- outcome 稳定帧布局正常,「行路 ->」确认按钮位置清楚,无文字截断或错位。

额外路径记录:先按派单建议打 `stage_01_05`,但当前 seed 下右队胜,不触发 victory hook;随后改打 `stage_01_01`,第二次低阶关卡胜利后触发奇遇。

---

## 5. EncounterSkillSection 空态判断

空态验收通过。

可见内容:
- 区段标题:「奇遇招式」
- slot 文案:「未装备奇遇招式」
- 按钮:「尚无可装备奇遇招式」,灰色 disabled
- 布局顺序:装备 -> 心法 -> 奇遇招式 -> 师承

这符合派单对 disabled 空态的限定范围。因无预 unlock seed,未验完整选择 bottom sheet / 境界锁图标。

---

## 6. 工具链评价

沿用 W7-W11 的 PowerShell + Win32 API 路线可用:
- `SetWindowPos` 固定 1280x900。
- `mouse_event` 坐标点击和滚轮可用。
- `System.Drawing.Bitmap.CopyFromScreen` 截图稳定。

本次新增注意点:
- `WuxiaRun` Running 不等于当前 RDP 桌面有可见窗口,需要枚举 `MainWindowHandle` 二次确认。
- Debug exe 可能是旧构建,必须用当前源码重建后再验 UI 新增项。
- Flutter/Isar/Riverpod 生成文件在 Pen 端仍需本地 build_runner,否则 Windows build 会缺 `.g.dart`。

---

## 7. 下次推荐路径

1. Mac 端补 `seedVisualCheckW14_3()`:
   - 预 unlock 1-2 个 encounter skill。
   - 至少一个可装备,一个境界不足 locked。
   - 让 EncounterSkillSection 完整态 / bottom sheet / lock icon 可验。
2. 给 dialog visual check 加一个强制触发入口:
   - 指定 event id,绕开 `baseProbability 0.5`。
   - 或在 VC seed 后增加「触发奇遇」按钮。
3. 若继续依赖胜利后 hook,优先用 `stage_01_01` 而不是 `stage_01_05`;后者当前 seed 容易右队胜。

---

## 8. 本次文件

新增截图:
- `docs/screenshots/w14_3c_dialog_opening_fadein.png`
- `docs/screenshots/w14_3c_dialog_opening_full.png`
- `docs/screenshots/w14_3c_dialog_outcome_crossfade.png`
- `docs/screenshots/w14_3c_dialog_outcome_full.png`
- `docs/screenshots/w14_3a_encounter_skill_section_empty.png`
- `docs/screenshots/w14_3a_encounter_skill_section_in_layout.png`

新增 closeout:
- `docs/handoff/codex_w14_3c_visual_check_2026-05-14.md`
