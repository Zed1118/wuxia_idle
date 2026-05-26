# Codex R2 视觉验收派单 · 强制招募 NPC 完整 flow

派单日期：2026-05-27
派单方：Mac Opus
范围：用「强制招募 NPC」debug 入口走完整 sect recruit flow + 验收 character_panel 非空成员列表

## 背景

Round 1（2026-05-26）3 个 FAIL：debug picker 不走 recruit wire / 打不赢 Boss / 非空列表未验。
已修：commit `6e771fd` 新增 `SectRecruitDebugScreen`，主菜单加「强制招募 NPC」按钮，跳过战斗/奇遇直接走 `runSectRecruitFlow`。

## 环境准备

```
cd C:\Users\Administrator\Desktop\wuxia_idle
git log --oneline -1        # 确认 HEAD = 5832e39
flutter build windows --debug 2>&1 | tail -5
```

如果 build 报缺 `.g.dart`：先 `dart run build_runner build --delete-conflicting-outputs` 再 build。
如果 GUI 行为异常：`flutter clean` → build_runner → flutter build（铁律）。

## 验收步骤

### Step 1：启动 + 进主菜单

1. `flutter run -d windows`
2. 点「直入江湖」进主菜单
3. **截图**：`step1_main_menu.png`（确认看到「强制招募 NPC」按钮）

### Step 2：强制招募第一个 NPC

1. 点「强制招募 NPC」按钮
2. **截图**：`step2_candidate_list.png`（应列 5 个候选 NPC，每个显 `名字 (id)` + `流派 · 境界`）
3. 点击第一个候选（竹林剑客 bamboo_swordsman）
4. 应弹出二次确认对话框，标题「是否招入门派?」，按钮「招入门派」/「婉拒」
5. **截图**：`step2_confirm_dialog.png`
6. 点「招入门派」
7. 应显示 SnackBar 含「已加入门派」+ 结果 SnackBar `结果: success`
8. **截图**：`step2_recruit_success.png`

### Step 3：强制招募第二个 NPC

1. 重复 Step 2 流程，点第二个候选（沙漠浪人 desert_wanderer）
2. **截图**：`step3_second_recruit.png`（确认 confirm dialog 再次弹出 + 成功）

### Step 4：character_panel 非空成员列表

1. 返回主菜单
2. 点「角色面板」
3. 滚动到「师承」区域
4. 找到「门派同道:」行
5. **截图**：`step4_sect_members_nonempty.png`（应列出刚招募的 NPC 名字，不应为「门派人少」）

### Step 5（能给则给）：婉拒流程

1. 返回主菜单 → 再进「强制招募 NPC」
2. 点第三个候选
3. 确认对话框弹出后点「婉拒」
4. **截图**：`step5_decline.png`（应无招募成功提示）

## 截图命名

统一存 `docs/handoff/p4_1_1_screenshots_r2/`，文件名见各 Step。

## 必收 vs 能给

| 截图 | 优先级 |
|---|---|
| step2_confirm_dialog.png | **必收**（R1 FAIL 核心） |
| step2_recruit_success.png | **必收** |
| step4_sect_members_nonempty.png | **必收**（R1 未验） |
| step1/step2_candidate_list/step3/step5 | 能给则给 |

## 硬约束

- 不动 `lib/` `test/` `data/` `GDD.md` `CLAUDE.md` `numbers.yaml` 代码/数值
- 不 push
- 不装新包
- 跑不通的场景保留反证截图 + closeout 标占位，不伪造

## closeout 必交

交付 `docs/handoff/pen_visual_verify_p4_1_1_round2_2026-05-27.md`：
- 每 Step 状态（PASS / FAIL）
- 截图路径
- 发现的问题
- 最后总结
