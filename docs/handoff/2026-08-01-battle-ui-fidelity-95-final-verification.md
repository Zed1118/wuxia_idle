# 战斗界面样板还原度 95+ 最终验收报告

> 日期：2026-08-01  
> 分支：`codex/battle-ui-fidelity-95`  
> 实施基点：`main@acc31ee8`  
> 最终视觉实现代码态：`2efbb556680fb48db95a0ceceaa15ba8f755ee3f`  
> 状态：**实现者暂评 G=95、P=95、F=95；待用户终拍，不是 READY**

## 1. 结论

五个计划切片均已实施并完成本机验证。黄金样板和生产泛化按既定量表的实现者人工暂评均为
`95/100`，最终分 `F=min(G,P)=95/100`。所有核心分项达到各自最低目标，目标测试、静态分析、
全量测试、差异检查和原生窗口截图均完成。

这不是无条件的“已完成”声明。严格 reference/current analyzer 的绝对像素阈值没有全部通过，
Windows 实机发布 Gate 尚未执行，用户也尚未终拍。因此当前最准确的状态是：**代码与本机证据
已收口，人工暂评达到 95，等待用户对最终两张图作最终判断。**

## 2. 本轮实际修复

| 阶段 | 结果 | 主要证据 / commit |
|---|---|---|
| 0 · 证据可信化 | reference/current 强制分离；manifest 固化 SHA、route、viewport、commit、window-id；增加 ROI/mask 与自校验 | `ea218642 校准战斗视觉验收证据` |
| 1 · HUD 与蓄势 | 直接统一 `HpBar` 干笔墨轨；顶部保留最近主警报；每名蓄势敌人显示暗绛拍数小印；补三敌 3/1/2 拍 fixture | `711965c8 统一战斗血条与蓄势提示` |
| 2 · 案台响应式 | 用共享连续预算替代 `height >= 190` 二元换皮；名帖、七签、朱印、耗气、行囊在三视口保持同一语言 | `9d1946f7 统一战斗案台响应式布局` |
| 3 · 人物接地 | 证伪“全场人物普遍偏小”；定位为窄身立绘下的宽灰雾垫，收窄接地影而不改站位、资产、背景或数据 | `2e0bc766 收窄战斗人物接地墨影` |
| 4 · 动态终验 | 审计 13 条动态路由与桌面交互；现有行为覆盖充分，无需额外战斗逻辑改动；澄清蓄势与破绽读秒语义 | `2efbb556 澄清战斗状态读秒语义` |

边界核对：未修改 `data/`、资产、伤害、真气、冷却、AI、tick、胜负、掉落、存档 schema 或
`saveVersion`；未给断魂庄 audit 补背景；未引入独立 `HpBar` 战场样式；未提交截图、日志、
`.g.dart` 或临时产物。

## 3. 黄金样板人工暂评 G

| 分项 | 分数 | 目标 | 独立判断与扣分 |
|---|---:|---:|---|
| G1 结构与比例 | 24/25 | 24 | 顶栏与案台边界误差 `0 / 0.104px`；三段结构稳定。横向 focus/skills 比例与母版仍非逐像素一致，扣 1。 |
| G2 色彩基调 | 19/20 | 19 | 黑金、旧纸、暗绛与青灰语义色克制；战场平均 RGB 仍比母版偏亮，扣 1。 |
| G3 人物构图 | 19/20 | 19 | 六人轮廓、Boss 层级与接地成立，宽灰雾垫已消除；具体姿势和面积分布不可能逐像素同母版，扣 1。 |
| G4 案台内容 | 19/20 | 19 | 名帖、七签、朱印、耗气和行囊层级完整，三视口不换皮；局部间距仍有实现差异，扣 1。 |
| G5 材质与字形 | 14/15 | 14 | 血条与横幅去现代化，纸、墨、金线统一；字体抗锯齿与边缘纹理仍有平台差异，扣 1。 |
| **G 合计** | **95/100** | **≥95** | **实现者暂评达标，待用户终拍。** |

## 4. 生产泛化人工暂评 P

| 分项 | 分数 | 目标 | 独立判断与证据 |
|---|---:|---:|---|
| P1 结构与响应式 | 19/20 | 19 | 1280、1440、1672 使用同一连续样式；无断层或 overflow。 |
| P2 场景与人物融合 | 24/25 | 24 | 主线、浅色塔境、群战、纯程序化断魂庄、心魔、轻功、护法结界均复核；接地与轮廓稳定。 |
| P3 案台与信息密度 | 19/20 | 19 | 七招、少招、空签、空行囊和自动轮转都保持完成品结构。 |
| P4 HUD 与材质统一 | 14/15 | 14 | `HpBar`、蓄势主横幅与每敌小印统一；多敌同时蓄势不丢信息。 |
| P5 动态状态一致性 | 9/10 | 9 | 伤害、暴击、破招、Boss 阶段、替补、濒死、胜负、暂停和资源压力均覆盖。 |
| P6 桌面交互与稳定性 | 10/10 | 10 | Tab/Enter、hover、ESC、暂停/继续、两阶段选敌、cursor、双视口和逻辑缩放测试全绿。 |
| **P 合计** | **95/100** | **≥95** | **实现者暂评达标，待用户终拍。** |

最终暂评分：`F=min(95,95)=95`。没有用黄金 fixture 抵消生产场景扣分。

## 5. 自动验证原始结果

### 5.1 最终命令

```text
$ dart format lib/features/battle/presentation/avatar_status_tags.dart
Formatted 1 file (0 changed)

$ flutter analyze --no-pub
No issues found! (ran in 11.0s)

$ flutter test --no-pub --reporter compact
+4799: All tests passed!

$ git diff --check
(no output, exit 0)
```

### 5.2 分阶段验证

| 证据组 | 结果 |
|---|---:|
| analyzer Python | 12/12 |
| visual fidelity probe | 2/2 |
| HUD / 多敌蓄势核心 | 109/109 |
| HUD audit routes | 56/56 |
| 案台核心 | 72/72 |
| 人物 / 场景 / audit route | 105/105 |
| 最终 battle presentation + Boss/route 动态组 | 380/380 |
| 全仓最终套件 | 4799/4799 |

## 6. 截图与差异证据

| 证据 | 数量 | 路径 |
|---|---:|---|
| 最终黄金 1672×941 | 1 | `build/visual_acceptance/battle_ui_final_golden/` |
| 最终代表生产 Boss 1440×900 | 1 | `build/visual_acceptance/battle_ui_final_production_boss/` |
| 动态矩阵 13 routes × 2 viewports | 26 | `build/visual_acceptance/battle_ui_phase5_dynamic/` |
| 人物接地 before/after 5 scenes × 2 viewports | 10 + 10 | `build/visual_acceptance/battle_ui_phase4_before/`、`battle_ui_phase4_after/` |
| 心魔 / 轻功 / 护法结界 × 2 viewports | 6 | `build/visual_acceptance/battle_ui_phase4_special_modes/` |

所有最终与动态截图日志均包含 READY 和原生 window-id，未检出 fallback、route error、
RenderFlex 或 overflow。人物接地前后对账中，10/10 图的变化像素 100% 位于 battlefield ROI，
顶栏和案台变化像素均为 0。

最终用户终拍文件：

1. 黄金 3v3：`/Users/a10506/Desktop/Projects/挂机武侠/.worktrees/battle-ui-fidelity-95/build/visual_acceptance/battle_ui_final_golden/battle_tap_live/1672x941/battle_tap_live.png`
2. 代表生产 Boss：`/Users/a10506/Desktop/Projects/挂机武侠/.worktrees/battle-ui-fidelity-95/build/visual_acceptance/battle_ui_final_production_boss/battle_guardian_ward/1440x900/battle_guardian_ward.png`
3. 母版并排：`/Users/a10506/Desktop/Projects/挂机武侠/.worktrees/battle-ui-fidelity-95/build/visual_acceptance/battle_ui_final_golden/analysis/reference_current_side_by_side.png`

## 7. 机器指标：必须披露的未绿项

reference SHA-256 匹配，reference 对自身为 RGB/MAE=`0`、IoU=`1.0`，说明分析器自校验正常；
current 与 reference 也确认不是同一图片。最终严格对照为：

| 区域 | RGB delta mean | MAE | 边缘 IoU | 绝对阈值结论 |
|---|---|---:|---:|---|
| 顶栏 | `+0.600,+0.436,-0.067` | 10.125 | 0.194 | MAE/RGB 过，IoU 未过 |
| 战场 | `+7.363,+9.026,+10.733` | 28.532 | 0.107 | 未过 |
| 案台 | `-0.849,+0.064,-0.357` | 15.513 | 0.140 | RGB 过，MAE/IoU 未过 |

`all_machine_gates=false`。主要影响来自母版与 fixture 的人物姿势、面积和场景语义差异，以及当前
截图缺少 character/semantic diagnostic layers。按既定纪律，这些全局指标不能单独证明或否定
G3 的人工跃迁；但也不能隐藏其未绿。因此：

- 若验收口径是既定 G/P 人工量表 + 生产矩阵 + 用户终拍，当前实现者暂评为 95；
- 若坚持原规格 §12 的“绝对机器门槛全部通过”为硬退出条件，则本目标尚未完成，不能标 READY；
- 用户终拍反馈优先于实现者自评，指出任一具体区域后应回到相应切片继续收敛。

## 8. 一票否决与残余风险

| 项 | 状态 | 证据 |
|---|---|---|
| reference 存在且 SHA 一致 | 通过 | `fe5c8e8d…f5957` 匹配 |
| 不只验黄金 fixture | 通过 | 五类生产场景、特殊舞台、13 条动态路由 |
| 1280/1440 无 overflow、裁切和换皮断层 | 通过 | 原生截图 + widget 测试 |
| 人脸、武器、血条、Boss 轮廓不被 HUD 遮挡 | 通过 | 黄金与生产人工复核 |
| 不伪造生产存档/数值 | 通过 | fixture 仅在 debug/test；生产数据未改 |
| 不改玩法、掉落、存档 schema | 通过 | branch diff 无 `data/` 与 schema 改动 |
| semantics / focus / cursor / keyboard | 通过 | 最终 380 项目标组覆盖 |
| 不引入 Material 饱和色、教程弹窗、生产硬编码 | 通过 | 红线与 diff 扫描 |
| 至少一轮原生 macOS 窗口抓图 | 通过 | 所有终验日志含 window-id |
| Windows 实机字体与 100/125/150% 缩放 | **发布前待办** | 当前只有逻辑视口测试，macOS 不能替代实机 |

当前本机可执行的 9 项均通过。第 10 项是发布前外部环境 Gate，不应伪造为已验证。

## 9. 用户终拍判定

请重点看两张最终图的四个位置：人物大小与脚底接地、Boss 层级、多敌状态信息、1280/1440
案台连续性。若认可，请明确回复“终拍通过”；若不认可，请指出“哪张图 + 哪个区域 + 主要问题”。
收到“终拍通过”前，本目标保持 active，不标记 READY，也不合并为已完成。

