# 外部审查修复 · 分诊与待拍板报告

**日期：** 2026-06-29
**输入：** `docs/code_review_report_2026-06-29{,_v2}.md` + `optimization_plan_2026-06-29.md` + `claude_fix_prompts_2026-06-29.md`（WorkBuddy AI 外部审查）
**分支：** `worktree-review-fixes-safe-batch`（6 commits，全量 `flutter test --no-pub -j1` 每条均绿）
**执行原则：** 只做低风险安全项；设计/平衡项不擅改，列此报告待你拍板；与已有决策冲突项 SKIP。

---

## 一、已完成安全批（6 项 · 已提交 · 全量回归绿）

| 项 | commit | 内容 | 验证 |
|---|---|---|---|
| P0-1 | `14e5050a` | 可选 yaml 加载区分「文件不存在」(静默) vs「解析失败」(FormatException 附文件名 rethrow)，抽 `_loadOptionalAsset` 改写 5 处；isar_setup 3 处安全网补 debugPrint | TDD+3 · 3374 绿 |
| P0-4 | `6db71152` | 新建 `ErrorFallback` 水墨兜底组件，替 12 屏 ~20 处 `'load error: $e'` 原始异常暴露，每处 onRetry 接对应 provider | TDD+5 · 3379 绿 |
| P0-5 | `41d9319d` | `_migrateSaveData` 段1(<0.18.0)/段3(<0.22.0) 补版本门，去段3 隐式启动顺序契约依赖 | TDD+4 · 3383 绿 |
| P0-2 | `6901e78b` | 新建 `InkLoadingIndicator` 墨晕水墨 loading，全项目 54 处 `CircularProgressIndicator` 替换（含 splash 第一屏） | TDD+6 · 3389 绿 |
| P2-3 | `a16ce903` | battle_screen 3 处 hex 魔数色收入 `WuxiaColors`（纯提取，色值不变） | analyze 0 · 3391 绿 |
| P2-6 | `ee9c2630` | `PlaqueButton` 去 Material InkWell 灰色水波纹，改 GestureDetector + 按下暗层 | TDD+2 · 3391 绿 |

> 注：P0-2(54 处)、P0-4(~20 处) 实际工作量均大于审查报告所述（报告称「约40」「8个文件」）。
> **挂账（CLI 测不到）**：P0-2 水墨 loading 各屏观感、P2-6 木牌按下手感 需 `flutter run -d macos` 目检。

---

## 二、跳过项（前提为假 / 违项目原则）

| 项 | 审查主张 | 证伪 / 理由 | 处置 |
|---|---|---|---|
| **P2-7** | festival 模块「FRAMEWORK STUB 未实装」 | **假**。`FestivalService.todayFestival` 经 `todayFestivalProvider` 被 `encounter_hook:75`→`encounter_service:524` 消费，是 8 条节日 encounter `festivalRequired` 维度门控的真实现（`festivalOn` 委托 config）。贴「未实装」会误标在用 service。审查报告自己也写「节日 encounter 已实装 8 条走 festivalRequired」——自相矛盾 | SKIP |
| **P2-8** | sect_event 加 `conflict/treasure/invasion` 枚举 | 加死枚举无生产/消费方，违项目「不加未消费物」原则（`feedback_yaml_config_unused_field` / 加 enum 需同步 fromDefId 反向映射否则 default 静默吞）。单一 type 是内容完整度缺口（1.0 打磨 backlog），非代码问题 | SKIP |
| **M1 中优先级** | 移所有 Isar `@collection` 到 core/domain 解 data→features 反向依赖 | v2 报告自己承认是 Isar **客观技术约束**。搬动 schema 注册极可能打断 32 版存档迁移，收益仅「架构整洁」，风险收益倒挂 | SKIP |
| **P2-11** | 删 `features/pvp/` schema | CLAUDE.md v1.24 用户**明确拍板保留** PVP schema 兼容旧档。删它违既有决策 | SKIP |

---

## 三、待你拍板（设计 / 平衡 / 需真机目检项）

> 这些不是 bug 修复，改了会动游戏行为/手感/平衡，或需不可逆删除。我**未改**，列建议供你定。

### 🛑 平衡 / 战斗行为决策（改了撞测试 + 改玩法）

**P1-1 战斗 AI 流派个性**（按流派改目标选择：刚猛打防御最低/灵巧打出手最快/阴柔维持血最低）
- 性质：改 `_pickTargetId` = **改战斗结果**，非 bug。战斗用 seeded-rng + 大量平衡 sim 测试，改 AI 选目标几乎必然让部分 seed 战局胜负翻盘。
- 风险：撞平衡测试；提示词自带「如果测试有 draw 断言需要调整」= **改断言迁就改动**，正是项目明令禁止的反模式。
- 我的建议：**想做的话单独立项**，先跑 balance_simulator 评估胜负偏移，再 TDD；不在本批做。需你定：要不要给 AI 加流派个性？

**P1-2 群战 wave 间回血 30%**（+ maxTicks 2000→3000，解 R5.1 全 draw）
- 性质：新增**平衡机制** + 改 numbers.yaml + 加 schema 字段（`intermissionHpRecoverPct`）。
- 风险：回血比例是数值平衡决策；提示词「如果测试有 draw 断言需要调整」同上反模式。
- 我的建议：值得做（群战确实打不赢是真问题），但回血比例/maxTicks 是**你拍板的数值**。需你定：回血 30% 是否合适？还是用「敌方后波数值递减」等其他杠杆？

### 🔧 表现层 / 功能增量（不破红线，可做，但需真机目检，且非 bug）

**P0-3 战斗屏拖拽性能**
- 降级版（只包 RepaintBoundary）：**边际收益**——RepaintBoundary 隔离 paint 不隔离 build，而拖招卡顿成本在 setState 重建（build）。
- 完整版（拖拽态/飘字层改 ValueNotifier 停整屏重建）：真有收益，但 2880 行最高曝光战斗屏重构，**手感回归 CLI 测不到**，需真机 profiling。
- 我的建议：**专开一个会话 + 你亲自真机 profiling/目检**做完整版；不在 bg 批里对战斗屏做边际改动。需你定：要不要单独排期做战斗屏性能重构？

**P1-3 心魔余毒 debuff 视觉**（头像紫雾边框 + 伤害飘字紫染 + 角色面板角标 + 闭关清除提示）
- 性质：纯视觉增量（不改数值），消除「莫名变弱」困惑。多文件（BattleCharacter 加字段透传 + damage_popup + character_panel + seclusion）。
- 我的建议：可做，价值实在；需真机目检紫雾观感。需你定：排不排期。

**P1-4 screen_shake 随机方向 + 指数衰减**（+ numbers.yaml 配置）
- 性质：表现层打击感增强。注意：随机方向需 seed 保确定性（若战斗测试依赖）。
- 我的建议：可做，低风险；绝对值（衰减 tau/角度）需真机边玩边校。

**P1-5 character_panel 响应式双栏**（宽屏 >900px 双栏，窄屏单列）
- 性质：布局改动，消宽屏留白。多子面板重排。
- 我的建议：可做；需真机目检双栏分配 + 720p 不溢出（`feedback_visual_size_min_resolution`）。

**P1-6 离线挂机 cap 时长提示**（闭关界面显「最长计入 X 小时」+ 归来卡 isCapped 温和提示）
- 性质：低风险 UI 增量，强化反留存哲学。
- 我的建议：**最接近可直接做**的 P1，纯加 inline 文字提示走 UiStrings，不弹窗不焦虑。需你点头即可纳入下批安全做。

### ❌ 建议不做（前提为假）

**P1-7 删 baike 模块**
- 审查主张：baike 疑似 codex 旧名残留，双轨维护风险。
- 证伪：`BaikeScreen` 被 `main_menu:399` + `zangjuange:67` 路由（百科 hub 入口）；`codex_tab.dart:12` 注释明示 **codex 是 BaikeScreen 的第 3 个「机制」tab**，非 baike 竞品。删 baike 会断百科入口。
- 我的建议：**不删**。baike(百科 hub) 与 codex(其中一个 tab) 是包含关系非重复。

---

## 四、外部审查质量评价

**准确且有价值**：P0-1（catch 位置一字不差）、P0-2/P0-4/P2-3 方向对、P0-5 段位判断准、对项目强项（红线校验/版本迁移/注释/测试覆盖）识别到位。

**事实错误 / 需证伪**（佐证不能照单全收）：
- festival「未实装 STUB」——实际在用（P2-7）
- baike「codex 旧名残留」——实际是百科 hub，codex 是其 tab（P1-7）
- 多处自相矛盾（festival、节日 encounter）+ 计数偏低（loading 40 vs 54）+ 把平衡决策包装成「修复」（P1-1/P1-2 的「改断言迁就改动」反模式）

**结论**：外部审查作 backlog 线索可用，但**每条前提需本会话证伪**，不可按 P0→P1→P2 顺序盲执行。
