# 战斗界面 V2 ≥85% 风格还原实施计划

> 日期：2026-07-19  
> 状态：实施中（Task 0.3 已完成）
> 阶段：1.0 长线打磨期  
> 基准分支：`main@ad94a2bb`  
> 推荐实施分支：`codex/battle-ui-v2-fidelity-85`  
> 推荐 worktree：`/Users/a10506/Desktop/Projects/挂机武侠/.worktrees/battle-ui-v2-fidelity-85`  
> 唯一视觉基准：`docs/spec/battle_ui_stage_command_desk_v2_2026-07-15.png`  
> 修复报告：`docs/spec/2026-07-19-battle-ui-v2-85-fidelity-repair-report.md`  
> 目标：1280×720、1440×900 常规桌面实机综合还原度 ≥85/100，A～E 核心分项得分率均 ≥80%

---

## 0. 开工前成本检查点

这是战斗核心屏的多阶段视觉重构，预计跨多个专注会话完成，明显超过 60 分钟。它会触及战斗表现层热点文件、视觉验收路由和少量 UI 资产，但不涉及部署、数据库迁移、数值平衡或存档版本。

开工前由主窗口确认：

- [ ] 用户同意以本计划串行推进，不拆成多个并行热点分支；
- [ ] 用户接受每个阶段先达分再继续，不以“功能已存在”代替视觉 Gate；
- [ ] 基准原图仍存在且 SHA-256 为 `fe5c8e8d1696c8136db140ae31ccb7e096b34e385bb21b442340e90b582f5957`；
- [ ] 修复报告与本计划已进入实施分支基线；
- [ ] 视觉 route 使用隔离调试数据，不再进入用户真实存档取图；
- [ ] 若需要新增技能签毛边/木匣/墨案纹理，先交 1280×720 单场样板给用户拍板，再批量接线。

用户只要求规划时，到此为止，不自动创建 worktree、不修改代码、不生成资产。

---

## 1. 目标与非目标

### 1.1 最终结果

完成后，生产战斗屏在不改变真实战斗状态的前提下，应达到：

- 人物第一视觉主体；
- 武学案台第二视觉主体；
- 顶栏、血条、真气、状态和日志退为辅助层；
- 人物、背景、技能签、HUD 像出自同一张写实水墨画卷；
- 标准 3v3、单 Boss、自动观战、允许点选都保持 ≥85% 风格还原；
- 空技能槽、冷却、真气不足、待发、破招等边缘状态不再暴露开发占位感；
- 1280×720 与 1440×900 无 overflow、遮挡和桌面交互语义回退。

### 1.2 当前分数与阶段 Gate

| 分项 | 当前估分 | 最终目标 | 对应阶段 |
|---|---:|---:|---|
| A 构图与空间比例 | 15/20 | ≥17/20 | 阶段 1 |
| B 人物与舞台融合 | 14/25 | ≥21/25 | 阶段 3 |
| C 武学案台 | 12/25 | ≥22/25 | 阶段 2 |
| D 色彩与材质 | 10/15 | ≥13/15 | 阶段 3～4 |
| E HUD 与信息层级 | 6/10 | ≥8/10 | 阶段 4 |
| F 动态效果 | 3/5 | ≥4/5 | 阶段 4 |
| **合计** | **60/100** | **≥85/100** | 阶段 5 |

任一阶段未达到对应 Gate：停在当前阶段修正，不将问题挂到后续阶段。

### 1.3 明确不做

- 不改战斗伤害、真气、冷却、AI、tick、胜负、掉落或敌队配置；
- 不新增前后排数值、开局站位倾向或 Boss 预兆图标；
- 不实现战斗药品规则或药品行囊自动补位；
- 不重做已终拍的 79+ 正式敌人立绘；
- 不引入 3D、Flame、骨骼系统或逐技能序列帧；
- 不新增教程弹窗；
- 不为 800×600 非正式小窗牺牲 1280×720 主构图；
- 不把视觉验收扩成全项目 UI 重构；
- 不将截图、视频、临时 mask 或分析输出误提交到源码目录。

### 1.4 已否任务边界

本计划已核对 `docs/spec/rejected_task_registry.md`，明确避开：

- 战斗开局站位倾向；
- Boss 技能预兆图标；
- 药品行囊自动补位；
- 战斗中药品自动禁用提示；
- 战斗术语百科入口；
- 武学装配一键补齐；
- 失败原因诊断等已否或暂缓方向。

---

## 2. 执行组织与恢复纪律

### 2.1 单分支串行原因

以下文件是共同热点，禁止多个执行者同时写：

- `lib/features/battle/presentation/battle_layout_tokens.dart`
- `lib/features/battle/presentation/widgets/battle_bottom_bar.dart`
- `lib/features/battle/presentation/widgets/battle_field.dart`
- `lib/features/battle/presentation/widgets/battle_header.dart`
- `lib/features/battle/presentation/character_avatar.dart`
- `lib/features/battle/presentation/battle_scene_background.dart`
- `lib/shared/theme/colors.dart`
- `lib/shared/theme/wuxia_tokens.dart`

实施采用一个 worktree、一条线性提交链。若需要委派，只能把“只读截图评分”“独立读者检查”“单资产目检”交给其他执行者，不能并发修改上述文件。

### 2.2 小切片提交

建议提交序列：

1. `建立战斗风格实施基线`
2. `建立战斗风格验收基线`
3. `重标定战斗界面构图比例`
4. `收口战斗顶栏与案台分区`
5. `精修武学技能签五态`
6. `统一执招者与战备行囊装帧`
7. `校准人物舞台尺度与接地`
8. `统一战场背景层次与材质`
9. `收口战斗HUD与字体层级`
10. `压低题字与战斗特效饱和度`
11. `补齐战斗界面85%验收证据`
12. `[READY] 达成战斗界面V2风格还原`

每个提交必须在对应 targeted tests 通过后产生。禁止把多个未验阶段压成一个巨型提交。

### 2.3 测试节奏

- 自包含表现层切片：相关 targeted tests + `flutter analyze --no-pub`；
- 每个阶段末：双视口 visual smoke；
- 阶段 5 批末：相关 battle 测试族 + 一次全量 `flutter test --no-pub`；
- 不在每个小提交重复跑全量；
- 发现后续改动可能破坏前阶段构图时，重跑前阶段截图 Gate。

### 2.4 每次停下前更新恢复点

恢复点必须包含：

- 状态；
- 最后完成；
- 下一步；
- 已跑验证和通过数；
- 当前 A～F 分数；
- 证据目录；
- 阻塞项；
- worktree 是否干净、tip 是否 `[READY]` / `[BLOCKED]` / WIP。

---

## 3. 阶段 0：冻结基线与补齐验收基建

### Task 0.1：创建隔离 worktree，并固定文档基线

**目标**：把长任务与主 checkout 隔离。

**操作**：

1. 确认主 checkout 只有用户已知的报告/计划文档改动，不覆盖或夹带其他未提交工作；
2. 从锁定基点 `ad94a2bb2f600f8f0a7982d03f8566ee49178f45` 创建 `codex/battle-ui-v2-fidelity-85`；
3. worktree 路径固定为 `.worktrees/battle-ui-v2-fidelity-85`；
4. 由于修复报告和本计划在该 main 基点之后才生成，新 worktree 不会自动拥有它们；必须从主 checkout 精确复制这两个文件进新 worktree，不使用 glob；
5. 基准图已在锁定基点受 Git 跟踪，只校验哈希，不再覆盖；
6. 在本文件“当前恢复点”写入真实基点、worktree 和状态；
7. 在新分支单独提交两份文档，该提交成为实施文档基线。

**可复制的操作链**（只在用户明确开工后执行）：

```bash
git worktree add -b codex/battle-ui-v2-fidelity-85 \
  /Users/a10506/Desktop/Projects/挂机武侠/.worktrees/battle-ui-v2-fidelity-85 \
  ad94a2bb2f600f8f0a7982d03f8566ee49178f45
cp /Users/a10506/Desktop/Projects/挂机武侠/docs/spec/2026-07-19-battle-ui-v2-85-fidelity-repair-report.md \
  /Users/a10506/Desktop/Projects/挂机武侠/.worktrees/battle-ui-v2-fidelity-85/docs/spec/
cp /Users/a10506/Desktop/Projects/挂机武侠/docs/superpowers/plans/2026-07-19-battle-ui-v2-85-fidelity-implementation.md \
  /Users/a10506/Desktop/Projects/挂机武侠/.worktrees/battle-ui-v2-fidelity-85/docs/superpowers/plans/
cd /Users/a10506/Desktop/Projects/挂机武侠/.worktrees/battle-ui-v2-fidelity-85
# 先将本计划的“当前恢复点”更新为新 worktree 真实状态
git add docs/spec/2026-07-19-battle-ui-v2-85-fidelity-repair-report.md \
  docs/superpowers/plans/2026-07-19-battle-ui-v2-85-fidelity-implementation.md
git commit -m '建立战斗风格实施基线'
```

若分支名或 worktree 已存在，先停下做只读核对，不删分支、不删 worktree、不改用其他路径绕过。

**验证**：

```bash
git status --short
git branch --show-current
git log -1 --format='%H %s'
shasum -a 256 docs/spec/battle_ui_stage_command_desk_v2_2026-07-15.png
```

**退出条件**：worktree 干净；基准图哈希一致；计划恢复点已更新。

### Task 0.2：建立五个确定性视觉 route

**目标**：消除自由运行战斗随机截帧，使 S10～S12 可复现。

**新增 route**：

- `battle_v2_casualty_replacement`
- `battle_v2_fast_forward_peak`
- `battle_v2_pre_result`
- `battle_v2_neutral_3v3`：中性标准 3v3，无待发/大招/结算遮挡；
- `battle_v2_resource_pressure`：同帧固定呈现至少一张冷却签和一张真气不足签。

**主要文件**：

- `lib/features/debug/application/visual_route.dart`
- `lib/features/debug/presentation/visual_route_host.dart`
- `lib/features/debug/presentation/battle_test_menu.dart`
- `lib/features/debug/application/visual_acceptance_plan.dart`
- 对应 debug/visual route tests

**实现要求**：

1. route 使用固定 seed；
2. 回放至目标状态后自动暂停；
3. 显式重构现有 `VisualRouteHost` “目标 Widget 首帧即无条件 READY”机制：普通静态 route 保持首帧 READY，这五个状态 route 由目标状态回调/控制器拥有 READY 权；
4. 只有目标状态真实成立后打印 `VISUAL_ROUTE_READY`，每个 route 的 READY 断言写入测试；
5. 日志输出 route、seed、实际 tick、存活人数和状态摘要；
6. 相同 commit 连跑两次，tick 和状态摘要必须一致；
7. route 只服务 debug/profile 验收，不改变生产 `BattleScreen` 行为；
8. 不进入或覆盖用户真实存档。

**先写失败测试**：

- 新 route id 可解析；
- route 在目标状态前不 READY；
- 目标状态后暂停并产生一致摘要；
- battle suite/checklist 能列出五个 route；
- `battle_v2_neutral_3v3` 不存在待发/大招/结算 overlay；
- `battle_v2_resource_pressure` 同时存在冷却和真气不足语义状态。

**验证**：

```bash
flutter test --no-pub test/features/debug
flutter analyze --no-pub
flutter pub run tool/visual_acceptance.dart routes --suite full --format ids
```

**提交**：`建立战斗风格验收基线`

### Task 0.3：建立结构量测与评分产物

**目标**：让 85 分不是只凭印象。

**建议新增**：

- `tools/visual_capture/analyze_battle_v2_fidelity.py`
- `tools/visual_capture/battle_v2_fidelity_config.json`
- 对应工具测试或固定 fixture

**输出**：

- 内容区裁剪信息；
- 逻辑尺寸、PNG 像素尺寸、DPR；
- 顶栏/战场/案台纵向比例；
- 执招者/技能签/行囊横向比例；
- 人物 alpha 包围盒；
- Boss 面积比；
- 高饱和语义色占比；
- 原始 mask 路径；
- JSON/Markdown 评分骨架。

**限制**：

- 工具只量测可客观计算的部分；
- 不把脚本输出的单一数字冒充用户风格终拍；
- 阈值严格读取报告 §3.5，不在脚本内另写一套；
- 不增加运行时依赖；工具依赖只复用项目已有环境。

**验证**：

```bash
python3 tools/visual_capture/analyze_battle_v2_fidelity.py --help
python3 -m unittest discover tools/visual_capture -p '*battle_v2_fidelity*test*.py'
bash -n tools/visual_capture/visual_capture.sh
```

### Task 0.4：抓取改前基线

**固定核心 route**：

- `battle_tap_preview`
- `battle_tap_live`
- `battle_boss_phase`
- `mainline_first_clear_battle_auto`
- `battle_charge_break`
- `battle_first_clear_showcase`
- `battle_ultimate_caption`
- 五个新增 V2 route

**固定视口**：1280×720、1440×900。

**命令模板**：

```bash
tools/visual_capture/visual_capture.sh \
  --route battle_tap_preview \
  --resolutions 1280x720,1440x900 \
  --output build/visual_acceptance/battle_ui_v2_85/baseline
```

**证据要求**：

- 截图和日志完整；
- manifest 记录 commit/route/seed/tick/viewport/DPR；
- 生成两张主三联图：标准 3v3、单 Boss；
- 按报告 rubric 写入初始 60/100 的逐项理由；
- 将证据复制到主 checkout 稳定目录前先确认是否要入库，默认 build 产物不入 Git。

**阶段 0 Gate**：

- route 两次运行确定性一致；
- 基准截图可重复生成；
- A～F 初始评分与原报告无重大矛盾；
- 工作树只含计划内源文件。

---

## 4. 阶段 1：重标定整体构图

### Task 1.1：把固定尺寸升级为集中式响应布局

**目标**：顶栏 6%～7%、战场 67%～69%、案台 24%～26%。

**主要文件**：

- `lib/features/battle/presentation/battle_layout_tokens.dart`
- `lib/features/battle/presentation/battle_screen.dart`
- `lib/features/battle/presentation/widgets/battle_header.dart`
- `lib/features/battle/presentation/widgets/battle_bottom_bar.dart`

**设计**：

- 新增集中式 `BattleLayoutMetrics.resolve(Size)` 或等价对象；
- 百分比为主、合理上下限为辅；
- `Header`、`BattleField`、`BottomBar` 读取同一份 metrics；
- 自动观战与允许点选保持同一案台占屏重量，不再使用 116px 普通工具栏式压缩；
- 视觉尺寸只放在 token/metrics，不在 Widget 散写。

**先写失败测试**：

- 1280×720 与 1440×900 的三段比例；
- 自动与点选案台高度同属 24%～26% 目标带；
- 两视口无 overflow；
- 旧 `autoRotationDeskHeight` 不再单独破坏构图。

**验证**：

```bash
flutter test --no-pub \
  test/features/battle/presentation/battle_command_console_test.dart \
  test/features/battle/presentation/battle_mode_pill_test.dart
flutter analyze --no-pub
```

### Task 1.2：重标定案台横向分区

**目标**：执招者 18%～20%，七签 58%～62%，行囊 20%～22%。

**实现要求**：

- 固定 222px 改为比例 + min/max；
- 7 签永远同时可见，无横向滚动；
- 1280 宽保留点击热区；
- 1440 宽增加留白和签宽，不额外堆信息；
- 区间不足时先收装饰、字距和 gap，不先缩核心文字。

**测试**：

- 为三段添加可定位 key 或诊断尺寸；
- 断言双视口百分比；
- 保留 7 签、3 行囊现有测试；
- 不出现 `SingleChildScrollView`。

### Task 1.3：重标定人物通用阵列

**目标**：先修通用槽位，不做逐资产 scale/shift。

**主要文件**：

- `lib/features/battle/presentation/battle_stage_geometry.dart`
- `lib/features/battle/presentation/widgets/battle_field.dart`
- `test/features/battle/presentation/battle_stage_geometry_test.dart`

**要求**：

- 标准 3v3 非对称纵深与基准一致；
- 中央交锋区保持 20%～28%；
- 1v1/2v2 自动放大但不失去左右方向；
- Boss 目标带先写入通用几何，逐资产校准留阶段 3；
- 轻功、心魔、群战原布局模式不退化。

**阶段 1 截图**：标准 3v3、单 Boss，双视口四张。

**阶段 1 Gate**：A ≥17/20；双视口 0 overflow；用户无需此时终拍。

**提交**：

- `重标定战斗界面构图比例`
- `收口战斗顶栏与案台分区`

---

## 5. 阶段 2：武学案台成品化

### Task 2.1：拆出可维护的案台组件

**目标**：避免继续膨胀 `battle_bottom_bar.dart`。

**建议文件**：

- `widgets/battle_command_desk.dart`
- `widgets/battle_skill_slip.dart`
- `widgets/battle_focus_rail.dart`
- `widgets/battle_pouch_rail.dart`

是否拆文件以实际 diff 为准，但必须保持：

- `BottomBar`/`AutoRotationBar` 对外 API 稳定；
- 交互仍走原生按钮或完整补回 semantics/focus/cursor；
- 中文显示文字继续来自 `UiStrings`；
- 视觉数值继续进入集中 token。

### Task 2.2：重做技能签基础形态

**目标**：第一眼不再像七个普通 `ElevatedButton`。

**形态要求**：

- 墨案下缘 + 局部纸签；
- 旧纸底、内墨线、局部毛边、轻微自然错落；
- 招式名为第一字阶；
- 性质印为第二识别点；
- 真气和冷却落在签底；
- 不用大面积圆角、默认阴影或现代按钮高光。

**资产策略**：

1. 优先复用 `paper_bg.png`、`scroll_vertical.png`、`seal_red.png` 和 CustomPainter；
2. 若仍不足，只新增最小可九宫格缩放材质；
3. 先做一张签和一套案台 1280×720 样板；
4. 用户拍板后再扩展到七签与行囊；
5. 不为每个技能制作独立底图。

### Task 2.3：完成技能签五态

**状态**：可用、冷却、真气不足、待发、破招。

**要求**：

- 冷却使用墨色浸染 + 数字；
- 真气不足使用气脉缺口和降墨，不走通用 disabled 灰；
- 待发使用克制绛红印，允许再点取消；
- 破招使用一次暗金抬签/描边，不持续闪烁；
- 长按简介、单体两段点选、群体直放原行为不变；
- 自动观战显示轮转和状态，不伪装成可点按钮。

**先写失败测试**：

- 五态各有可定位语义和视觉 key；
- disabled 仍可长按说明；
- 待发可取消；
- 自动模式不暴露 onPressed；
- 可破招角色与技能签连续高亮；
- 减少闪烁态不依赖动画才能识别。

### Task 2.4：修复空槽、执招者和行囊

**空槽**：淡墨留白签 + 小型空印，不再大字竖排“空技能位”。

**执招者**：当前角色展开名帖，显示姓名、流派、真气；其他两人收束，阵亡态褪墨。

**行囊**：木匣/旧锦格，与技能签不同形；保留三格和预留语义，不实现药品规则。

**测试**：

```bash
flutter test --no-pub \
  test/features/battle/presentation/battle_command_console_test.dart \
  test/features/battle/presentation/battle_tap_skill_test.dart \
  test/features/battle/presentation/battle_skill_info_popup_test.dart \
  test/features/battle/presentation/battle_mode_pill_test.dart
flutter analyze --no-pub
```

**阶段 2 截图**：S1、S3、S4、S5、S6、S7，双视口。

**阶段 2 Gate**：C ≥22/25；桌面 semantics/focus/cursor 通过；案台不得读成普通按钮阵列。

**提交**：

- `精修武学技能签五态`
- `统一执招者与战备行囊装帧`

---

## 6. 阶段 3：人物与场景融合

### Task 3.1：把光学校准从画布尺寸升级为视觉包围盒

**主要文件**：

- `lib/features/battle/presentation/character_avatar.dart`
- `lib/features/battle/presentation/battle_stage_geometry.dart`
- `test/features/battle/presentation/character_avatar_test.dart`
- `test/features/battle/presentation/battle_stage_geometry_test.dart`

**要求**：

- 延续现有 `_stageStandeeOpticalProfile`/校准映射，不另建第二套真相源；
- alpha >16/255 的包围盒作为量测口径；
- 同类人物光学高度进入统一带；
- Boss 面积比使用报告 §3.5 唯一算法，目标 1.25～1.45；
- 不把脚底影、题字、受击闪、弹道计入人物包围盒；
- 保留已终拍角色辨识度，不批量修改源图。

### Task 3.2：统一接地、边缘与人物色彩

**表现要求**：

- 脚底锚点误差 ≤视觉高度 2%；
- 使用淡墨椭圆/不规则影接地；
- 统一 alpha 白边/黑边处理；
- 运行时色彩校准只作用人物层；
- 低饱和、暖灰黑位、压高光；
- 同一人物跨三背景黑位漂移 ≤0.05；
- 阵亡态褪墨和下沉，不留下完整灰色剪纸。

**性能限制**：

- 静态人物继续使用 `RepaintBoundary`；
- 不给每个角色叠昂贵实时 blur；
- 色彩滤镜和接地影做固定层，动作只重绘必要子树。

### Task 3.3：重做人物信息板

**主要文件**：

- `lib/features/battle/presentation/character_avatar.dart`
- `lib/features/battle/presentation/hp_bar.dart`
- `lib/features/battle/presentation/avatar_status_tags.dart`
- 相关 tests

**要求**：

- 纯黑矩形改成窄墨拓/暗纸条；
- HP 深绛红，真气低饱和青灰；
- 名字优先，数值次之；
- 最多两个关键常驻状态；
- 不遮脸、兵器、腿或邻位角色；
- 缩略 50% 不形成六块黑砖。

### Task 3.4：按场景 profile 调整背景层次

**主要文件**：

- `lib/features/battle/presentation/battle_scene_background.dart`
- `lib/features/battle/presentation/battle_atmosphere_overlay.dart`
- `lib/shared/theme/colors.dart`
- `test/features/battle/presentation/battle_scene_background_test.dart`

**要求**：

- 主线、塔、Boss、心魔、轻功、群战各有受控 profile；
- scrim 不再对所有有图背景固定 40%；
- 保留远景、中景、接触层、前景压边；
- 中央交锋区低细节但不纯空白；
- 不让背景抢过人物脸和技能签；
- 三类背景抽样复核同一人物黑位。

**测试**：

```bash
flutter test --no-pub \
  test/features/battle/presentation/character_avatar_test.dart \
  test/features/battle/presentation/battle_stage_geometry_test.dart \
  test/features/battle/presentation/battle_scene_background_test.dart \
  test/features/battle/presentation/hp_bar_test.dart \
  test/features/battle/presentation/avatar_status_tags_test.dart \
  test/features/battle/presentation/battle_field_repaint_test.dart
flutter analyze --no-pub
```

**阶段 3 截图**：S1、S2、S10，另抽主线/塔/心魔三背景，同人物或同类人物对照。

**阶段 3 Gate**：B ≥21/25；D 阶段值 ≥11/15；标准 3v3 和 Boss 均通过；profile 模式在 `battle_v2_neutral_3v3` 中固定运行 60 秒，忽略前 5 秒预热，保存 Flutter performance overlay/时序摘要，后 55 秒内不得出现连续 3 帧 build 或 raster 超过 16.7ms。若当前捕获脚本无法导出时序，在进入阶段 3 前先补可复现的 profile 采样命令和产物路径，不以“目测流畅”代替。

**提交**：

- `校准人物舞台尺度与接地`
- `统一战场背景层次与材质`

---

## 7. 阶段 4：HUD、字体与动态效果

### Task 4.1：顶栏题签化

**主要文件**：

- `lib/features/battle/presentation/widgets/battle_header.dart`
- `lib/shared/widgets/wuxia_ui/wuxia_icon_button.dart`（仅在确需共用时）
- `test/features/battle/presentation/battle_mode_pill_test.dart`

**要求**：

- “自动 / 一倍 / 暂停 / 日志 / 撤退”采用短文字或字+极简图标；
- 墨边圆牌/窄题签替代通用圆形 Material 图标观感；
- 中央战斗人数最大，左侧场景名次之，节拍最弱；
- 右侧控制点击区 ≥36px；
- 帮助入口不抢主控制；
- 保留 tooltip、semantics、focus、键盘激活和 cursor。

### Task 4.2：建立战斗专用字阶与字体回退

**主要文件**：

- `battle_layout_tokens.dart` 或新建集中 `battle_typography_tokens.dart`
- `battle_header.dart`
- `battle_bottom_bar.dart` / 拆出组件
- `character_avatar.dart`
- `pubspec.yaml`（只有打包字体方案拍板后才改）

**要求**：

- T1～T5 字阶只存在一份；
- 最小辅助文字不低于 9 logical px；
- 小字对比度 ≥4.5:1，大字/粗体 ≥3:1；
- 数字使用稳定字宽，减少血量跳动；
- Windows 不依赖 macOS 独占字体；
- 若引入项目字体，先评估包体和授权，再由用户拍板。

### Task 4.3：统一题字和语义色

**主要文件**：

- `lib/shared/theme/colors.dart`
- `lib/features/battle/presentation/ultimate_caption_overlay.dart`
- `lib/features/battle/presentation/hero_camera_overlay.dart`
- `lib/features/battle/presentation/first_clear_showcase.dart`
- `lib/features/battle/presentation/damage_popup.dart`
- 相关 tests

**要求**：

- “初战”取消大面积鲜黄爆点，改为旧金/绛红墨章；
- 暴击金从纯金压到旧金色域；
- 首通、破招、大招共享纸墨边缘与消散语言；
- 非大招帧高饱和语义色面积 ≤8%；
- 大招峰值后 300～500ms 回到低彩；
- 快进与减少闪烁状态仍能读懂动作和目标；
- 不改实际技能伤害和播放结算时点。

**测试**：

```bash
flutter test --no-pub \
  test/features/battle/presentation/ultimate_caption_overlay_test.dart \
  test/features/battle/presentation/first_clear_showcase_test.dart \
  test/features/battle/presentation/battle_screen_first_clear_showcase_test.dart \
  test/features/battle/presentation/damage_popup_test.dart \
  test/features/battle/presentation/battle_mode_pill_test.dart
flutter analyze --no-pub
```

**阶段 4 截图**：S6、S8、S9、S11、S12，双视口。

**阶段 4 Gate**：D ≥13/15、E ≥8/10、F ≥4/5；对 S1～S12 的内容区 PNG 运行 `analyze_battle_v2_fidelity.py`，产出 `metrics.json` 和 `score.md`；非大招帧高饱和语义色面积 ≤8%；每个 T1～T5 文本 token 在实际背景抽样上对比度达标（小字 ≥4.5:1，大字/粗体 ≥3:1）；命令返回非零即 Gate 失败。

```bash
python3 tools/visual_capture/analyze_battle_v2_fidelity.py \
  --manifest build/visual_acceptance/battle_ui_v2_85/final/manifest.json \
  --config tools/visual_capture/battle_v2_fidelity_config.json \
  --output build/visual_acceptance/battle_ui_v2_85/final/analysis
```

**提交**：

- `收口战斗HUD与字体层级`
- `压低题字与战斗特效饱和度`

---

## 8. 阶段 5：全模式终验与收口

### Task 5.1：生成完整 24 图证据矩阵

每个视口抓取 S1～S12：

| 编号 | 状态 | route/入口 |
|---|---|---|
| S1 | 标准 3v3 中性帧 | `battle_v2_neutral_3v3` |
| S2 | 单 Boss | `battle_boss_phase` |
| S3 | 自动观战 | `mainline_first_clear_battle_auto` |
| S4 | 允许点选 | `battle_tap_live` |
| S5 | 单体待发 | `battle_tap_preview` |
| S6 | 蓄力可破 | `battle_charge_break` |
| S7 | 冷却/气不足 | `battle_v2_resource_pressure` |
| S8 | 初战 | `battle_first_clear_showcase` |
| S9 | 大招峰值 | `battle_ultimate_caption` |
| S10 | 阵亡递补 | `battle_v2_casualty_replacement` |
| S11 | 快进峰值 | `battle_v2_fast_forward_peak` |
| S12 | 结束前一拍 | `battle_v2_pre_result` |

**产物**：

- 24 张截图；
- 每张 route log；
- manifest；
- 结构量测 JSON；
- 标准 3v3、单 Boss 两组三联图；
- A～F 最终评分表；
- 残留差距清单。

S1 与 S5 必须是两个不同的确定性状态：S1 不得出现待发高亮，S5 必须显示单体待发与可选敌人。S7 必须在一帧中同时显示冷却和真气不足，不允许执行时临时挑“看起来差不多”的帧。

### Task 5.2：生产路径与特殊模式回归

**必须目检**：

- 正式主线标准 3v3：`stage_01_03`，1280×720 + 1440×900；
- 正式主线单 Boss：`stage_01_05`，1280×720 + 1440×900；
- 塔 Boss/护法结界：`battle_guardian_ward`，两视口；
- 轻功错层：`battle_light_foot_stage`，两视口；
- 心魔镜像：`battle_inner_demon_stage`，两视口；
- 群战递补：`battle_mass_battle_stage` 与 `battle_v2_casualty_replacement`，两视口；
- 自动与点选；
- 快进；
- 减少闪烁；
- 阵亡和结算前状态。

自动/点选/快进/减少闪烁均以 `stage_01_03` 进入真实 `BattleScreen`，记录开关状态和实际截图；阵亡/结算前另与 S10/S12 对照。产物统一放在 `build/visual_acceptance/battle_ui_v2_85/final/production/`，manifest 记录入口、关卡、视口、开关和 commit。视觉 route PASS 不能替代正式关卡生产接线证据。

### Task 5.3：最终自动化验证

```bash
dart format --output=none --set-exit-if-changed lib test tool tools
flutter analyze --no-pub
flutter test --no-pub test/features/battle/presentation test/features/debug
flutter test --no-pub
bash -n tools/visual_capture/visual_capture.sh
```

若 `dart format` 的目录范围与仓库实际约定冲突，以 CI 同款格式命令为准，不为本任务机械格式化无关文件。

### Task 5.4：用户终拍与差距返修

向用户只提交两张主对照板：

1. 标准 3v3：基准图 / 最终实机 / 差异标注；
2. 单 Boss：基准图 / 最终实机 / 差异标注。

用户只需拍板：

- 是否达到基准风格；
- 是否存在一眼可见的案台、人物或色彩偏离；
- 是否接受最终 ≥85% 评分。

若用户否决，不把任务标记完成；按具体差距回到对应阶段，修复后重跑受影响 Gate。

### Task 5.5：交付收尾

- 更新本文件恢复点为完成；
- 更新修复报告状态和最终实测分数；
- 在 `PROGRESS.md` 顶段记录“已完成 / 已验证 / 已知风险 / 下批建议”；
- 截图证据按用户拍板决定稳定保存位置；
- 清理临时 capture，不误删最终拍板证据；
- 所有改动 commit，工作树干净；
- tip 提交使用 `[READY] 达成战斗界面V2风格还原`；
- 交由 Claude 按 §8.2 Gate 审核合并。

**阶段 5 Gate**：

- 总分 ≥85/100；
- A～E 每项得分率 ≥80%；
- 24 图齐全；
- targeted / analyze / 全量测试通过；
- 生产正式关卡目检通过；
- 用户终拍通过；
- 工作树干净且 tip `[READY]`。

---

## 9. §8.2 交付检查表

每个阶段恢复点和最终交付都必须回答：

### 生产接线证据

- [ ] 正式 `BattleScreen` 消费改动；
- [ ] 正式主线/Boss 关卡截图存在；
- [ ] debug route 只负责稳定验收，不承载唯一实现；
- [ ] 真实技能、真气、冷却、人数和掉落状态没有为截图伪造。

### Targeted tests

- [ ] 列出完整命令；
- [ ] 列出通过数/失败数；
- [ ] 新行为有先红后绿证据；
- [ ] 阶段末 `flutter analyze --no-pub` 0 issue。

### 红线影响

- [ ] 零改数值硬红线；
- [ ] 零改三系锁死；
- [ ] 零改在线=离线；
- [ ] 未引入反主流机制；
- [ ] 中文 UI 文案走 `UiStrings`；
- [ ] 无玩法数值常量散写进 Dart；
- [ ] 视觉 token 集中管理。

### 残留风险

- [ ] 未目检模式列清；
- [ ] Windows 字体/缩放风险列清；
- [ ] 性能和 RepaintBoundary 风险列清；
- [ ] 新资产透明边缘/包体风险列清；
- [ ] 截图驱动或动态 tick 风险列清。

### 桌面 UI 加码

- [ ] 1280×720；
- [ ] 1440×900；
- [ ] semantics；
- [ ] 键盘激活；
- [ ] focus；
- [ ] mouse cursor；
- [ ] tooltip/长按说明；
- [ ] 无 overflow。

### Git 与证据

- [ ] 无误提交 capture/log/temp；
- [ ] 用户要求保留的最终证据未随 worktree 清理丢失；
- [ ] 中文动宾 commit；
- [ ] 完成 tip `[READY]`；
- [ ] worktree 干净。

---

## 10. 主要风险与回退策略

| 风险 | 早期信号 | 处理 |
|---|---|---|
| 自动案台恢复全高后压缩战场 | 720p 人物腿/血条被遮 | 先调分区 gap/装饰，不降低案台目标带；必要时重算人物区域 |
| 技能签材质过度影响可读性 | 4.5:1 对比失败 | 减纹理、提墨字，不用发光补救 |
| CustomPainter 变复杂导致维护困难 | 大量散写坐标 | 收入单一 painter/token，补 golden/尺寸测试 |
| 运行时人物滤镜损伤肤色 | 人物脸灰绿或黑位糊死 | 缩小滤镜强度，改场景 profile，避免改源图 |
| Boss 数字达标但观感仍小 | 用户终拍否决 | 以 alpha 面积比 + 主对照图共同裁决，不信 scale 常量 |
| 新 UI 资产系统性偏差 | 第一张样板已不贴基准 | 样板阶段停，用户拍板后再继续，不批量生成 |
| 视觉路由污染真实存档 | 存档内容改变 | 立即停，改用隔离数据目录/专用验收存档后重跑 |
| 截图证据随 worktree 消失 | build 目录是唯一副本 | 终拍前复制稳定证据，清理前逐文件核对 |
| 只把样板 route 修好 | 正式关卡仍偏离 | 阶段 5 强制正式主线/Boss/特殊模式生产目检 |
| Windows 字体漂移 | Windows 断行或字面高度变化 | ship 前 1920×1080 的 100%/125%/150% 缩放验证 |

任何阶段出现无法在表现层解决、需要改 schema/saveVersion/玩法数值或大量重生成已终拍立绘的情况，标记 `[BLOCKED]`，更新恢复点并交用户拍板，不擅自扩大范围。

---

## 11. 当前恢复点

- **状态**：阶段 1 已完成并通过 Gate；集中式响应比例、案台横向分区与人物通用阵列已接入正式战斗屏，尚未改生产战斗规则。
- **基点**：`main@ad94a2bb`（完整提交 `ad94a2bb2f600f8f0a7982d03f8566ee49178f45`）。
- **最后完成**：`BattleLayoutMetrics` 在 1280×720 / 1440×900 将顶栏、战场、案台闭合为 6.5% / 68.5% / 25%，自动与点选案台等高；点选案台三段实测均落 18%～20% / 58%～62% / 20%～22%，七签同屏无滚动；通用阵列改为非对称纵深，1v1/2v2 主体自动放大，主位交锋区 20%～28%，Boss 通用面积倍率进入 1.25～1.45。
- **下一步**：执行 Task 2.1；在保持 `BottomBar` / `AutoRotationBar` 外部 API 与原交互语义稳定的前提下拆出可维护案台组件，然后只制作 Task 2.2 的第一张技能签与一套 1280×720 案台样板。
- **已跑验证**：Task 1.1 红态：`BattleLayoutMetrics` / `Size` 不存在；初绿暴露 600p 执招栏 12px、继而 0.2px overflow，收装饰 padding 后转绿。Task 1.2 红态：三段 getters / keys 不存在；绿态双视口比例与七签无滚动通过。Task 1.3 红态：非对称、交锋区、1v1/2v2 放大、Boss 面积比 4 项失败；绿态通过。阶段 targeted 共 76/76，`flutter analyze --no-pub` 0 issue（3.9s）；四张 Gate 图 DPR=2 尺寸准确、日志 0 overflow/exception/error。
- **当前评分**：A 17/20、B 15/25、C 13/25、D 10/15、E 6/10、F 3/5，合计 64/100；阶段 1 Gate 的 A ≥17/20 达成。B/C 的主要增量留待阶段 2 样板与后续人物融合阶段。
- **证据目录**：基线保持在 `build/visual_acceptance/battle_ui_v2_85/baseline/`；阶段 1 四图、日志与 manifest 在 `build/visual_acceptance/battle_ui_v2_85/stage1/`，覆盖标准 3v3 / 单 Boss × 1280×720 / 1440×900。
- **阻塞项**：无。残留风险：Boss fixture 的视觉资产本身偏素，通用几何已达面积倍率但精确 alpha 面积仍待诊断层；Windows 字体/缩放未验证；案台当前仍是现代按钮阵列，正是阶段 2 样板范围。
- **§8.2 四证据**：①生产接线：正式 `BattleScreen` 的 `Header`、`BottomBar`、`AutoRotationBar`、`BattleField` 直接消费新 metrics/geometry，debug route 仅稳定取证；② targeted：76/76 + analyze 0 issue，四图双视口 0 overflow；③红线：零改 `data/`、战斗规则、数值/schema/saveVersion/持久化，新增值均为集中视觉 token；④残留风险：人物 alpha 精测、Windows 缩放、build 证据保全及阶段 2 样板用户终拍仍待后续。
- **Git 状态口径**：阶段 1 代码已提交 `e16005bb`；本恢复点待提交，tip 仍为 WIP；build 证据默认忽略，主 checkout 保持只读。
