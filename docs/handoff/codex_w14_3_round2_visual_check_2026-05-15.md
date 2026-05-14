# Codex W14-3 round2 visual check closeout(2026-05-15)

> 执行方: Codex Desktop @ Pen Windows
> 仓库: `F:\Projects\wuxia_idle`
> 验收 HEAD: `6def63b docs(W14-3 round2): Codex 桌面 Pen 第二批 EncounterSkillSection 完整态视觉验收派单`

---

## 1. 结论

完美线达成: R2-1 / R2-2 / R2-3 / R2-4 四张必收截图齐,追加 R2-5 / R2-6 选做截图齐。

最低线也达成: 大弟子 slot 填充态 + bottom sheet 7 招列表 + 4 lock 清楚可见。

补跑说明: 首轮 R2-5 / R2-6 因 Codex 桌面窗口抢前台未纳入验收;本轮将游戏窗口置顶并按窗口矩形换算绝对坐标后重跑,证据干净。

---

## 2. 准备与自检

| 项 | 结果 | 备注 |
|---|---|---|
| 开局 HEAD | `66f0d5b` | 本地未拉到 round2 派单 |
| `git fetch` 后远端 | `6def63b` | 仅新增 `codex_dispatch_w14_3_round2_2026-05-15.md` |
| 实际验收 HEAD | `6def63b` | `git merge --ff-only origin/main` 成功 |
| fixture self-check | PASS | `flutter test test/services/phase2_seed_service_test.dart` 16/16 pass |
| `seedVisualCheckW14_3` | PASS | 7 招池 / 大弟子 tier 3 预装备 / 幂等覆盖三项测试通过 |
| `dart run build_runner build --delete-conflicting-outputs` | PASS | build_runner 提示该 option 已忽略,写 2 outputs |
| `flutter build windows --debug` | PASS | 第一次因旧 `wuxia_idle` 进程占用 `kernel_blob.bin` 失败;关进程后通过 |

---

## 3. 跑通情况表

| 验收点 | 截图 | 状态 | 视觉判断 |
|---|---|---|---|
| R2-1 大弟子 slot 填充 | `docs/screenshots/w14_3_round2_disciple1_slot_filled.png` | PASS | 奇遇招式区显示「校场连击」,tier 3 / 倍率 2100 / 强力技能 + 「卸下」按钮齐 |
| R2-2 大弟子 bottom sheet | `docs/screenshots/w14_3_round2_disciple1_bottom_sheet.png` | PASS | 7 招按 tier 1-7 排列;tier 1-2 可选,tier 3 当前,tier 4-7 lock,共 4 lock |
| R2-3 二弟子更多锁 | `docs/screenshots/w14_3_round2_disciple2_more_locks.png` | PASS | 二弟子 sanLiu:tier 1-2 可选,tier 3-7 lock,共 5 lock |
| R2-4 祖师更少锁 | `docs/screenshots/w14_3_round2_founder_fewer_locks.png` | PASS | 祖师 yiLiu:tier 1-4 可选,tier 5-7 lock,共 3 lock |
| R2-5 大弟子卸下 | `docs/screenshots/w14_3_round2_disciple1_unequip.png` | PASS | 大弟子点「卸下」后 slot 为空态,显示「未装备奇遇招式」+「选择招式」 |
| R2-6 大弟子改装 tier 2 | `docs/screenshots/w14_3_round2_disciple1_equip_new.png` | PASS | 从 bottom sheet 选择 tier 2「暗器初探」后 slot 显示新 skill + tier 2 / 倍率 1700 / 卸下按钮 |

---

## 4. 切角色实现路径

路径已确认,无 UI 阻塞:

主菜单 -> Phase 2 调试场景 -> `VC · W14-3 奇遇 skill 视觉验收预设` -> 自动进入 CharacterPanelScreen -> 顶部三段 tab:

- `祖师`
- `大弟子`
- `二弟子`

点击 tab 后角色面板切换。当前滚动位置可继续保留,切换角色后再滚到「奇遇招式」区点「选择招式」即可展开 bottom sheet。

---

## 5. 视觉判断对照

| 标准 | 结果 |
|---|---|
| slot 填充态: skill 名 / tier 标记 / 卸下按钮齐 | PASS |
| bottom sheet 7 项,tier 升序 | PASS |
| lock icon disabled 视觉明显 | PASS |
| 祖师 / 大弟子 / 二弟子 lock 数为 3 / 4 / 5 | PASS |
| 布局错位 / 文字截断 | 未见明显问题;第 7 项在 1280x900 bottom sheet 底部略贴边,但名称与锁图标可见 |

---

## 6. 工具链评价

沿用 PowerShell + Win32 API + `System.Drawing.Bitmap.CopyFromScreen` 可用。

本次新增坑:

- `Get-Process WuxiaRun` 不够,实际进程名是 `wuxia_idle`。`WuxiaRun Running` 与桌面窗口可见仍需用 `MainWindowHandle` 核验。
- 旧 `wuxia_idle` 进程会锁住 `Debug\data\flutter_assets\kernel_blob.bin`,导致 `flutter build windows --debug` 在 CMake install 阶段报 `Invalid argument` / 用户映射区域占用。关掉旧进程后重建通过。
- Codex 桌面窗口会在长操作后抢前台;截图前最好强制 `SetWindowPos(HWND_TOPMOST)` 把游戏窗口置前,再取消 topmost。
- PowerShell 鼠标点击坐标要按 `GetWindowRect` 换算为屏幕绝对坐标。窗口固定在 `(20,20)` 时,直接拿截图相对坐标会偏 20px,按钮边缘点击可能无效。

---

## 7. 下次推荐

1. 若继续做可选装/卸链路,建议单独派一轮,先把 Codex 桌面窗口最小化或全程用游戏窗口 topmost。
2. bottom sheet 在 1280x900 下第 7 项略贴底;若后续要做更漂亮的证据,可让 sheet 内部留 8-12px bottom padding。
3. 视觉验收脚本可沉淀一个通用 `capture-window.ps1`,封装置前 / 定位 / 截图,减少重复 C# Add-Type。

---

## 8. 本次文件

新增截图:

- `docs/screenshots/w14_3_round2_disciple1_slot_filled.png`
- `docs/screenshots/w14_3_round2_disciple1_bottom_sheet.png`
- `docs/screenshots/w14_3_round2_disciple2_more_locks.png`
- `docs/screenshots/w14_3_round2_founder_fewer_locks.png`
- `docs/screenshots/w14_3_round2_disciple1_unequip.png`
- `docs/screenshots/w14_3_round2_disciple1_equip_new.png`

新增 closeout:

- `docs/handoff/codex_w14_3_round2_visual_check_2026-05-15.md`
