# P1 #44 · 35 件 continued_lore 池红线 case 验收 spec

> 2026-05-19 · Mac+Opus 起手(sonnet ~0.5h),DeepSeek 端 35 件文案落地后 Mac 端二阶段跑此 spec。
>
> **配套**:DeepSeek 派单 spec `p1_44_deepseek_continued_lore_spec.md`(35 件覆盖清单 + 占位符约定 + 量级风格)。Mac 端 wire closeout `p1_44_mac_wire_closeout_2026-05-19.md`(LoreContent schema + GameEventService 抽样 + fallback)。

## §1 验收范围

DeepSeek 端为 `data/lore/` 35 件装备 yaml(不含 `_archive/` `_templates/`)各加 2 池文案后,Mac 端跑本 spec 红线 case,**任一 fail 反馈 DeepSeek 端修**,全 pass 视为 DeepSeek 端交付完成。

Phase 0 实测:35/35 件 yaml 当前 `continued_lore_obtained` / `continued_lore_boss_defeated` 字段全缺(`grep -l continued_lore data/lore/*.yaml` 返回 0)。

## §2 实施路径

新增 group **加到现有 `test/data/lore_loader_test.dart` L124 「data/lore/ 35 个真实 yaml 红线」 group 之后**,体例对齐:文件扫 + 遍历 + 列失败 id 清单。不开新文件(避免 35 件 yaml 扫两次 IO)。

```dart
group('P1 #44 · 35 件 continued_lore 池红线', () {
  // 红线 1-5 test 案见 §3
});
```

## §3 红线 case 清单(5 strict + 1 soft)

### 红线 1 · 漏件防护(strict)

**语义**:35 件 yaml 两池**全部非空**,每池条数 ∈ [3, 5]。

**断言**:
- `continuedLoreObtainedPool.length` ∈ [3, 5]
- `continuedLoreBossDefeatedPool.length` ∈ [3, 5]

**失败信号**:列出 `<id>: obtained=N / bossDefeated=M`,便于 DeepSeek 端定位漏件 / 池数不足。

**理由**:池太少(< 3)玩家反复抽到同条频繁观感重复;池太多(> 5)超工作量预算且无观感增益(spec §4 量级 3-5 条)。

### 红线 2 · 占位符白名单(strict)

**语义**:所有 text 内出现的占位符**必须 ∈ 约定 3 个**:`{source}` / `{boss_name}` / `{stage_name}`。

**断言**:对每条 text,正则 `\{(\w+)\}` 抓全部占位符,集合 ⊆ {source, boss_name, stage_name}。

**失败信号**:列出 `<id> / <池名> / <条 idx>: 未约定占位符 {<var>}`。

**理由**:DeepSeek 端可能误写 `{equip_name}` / `{boss_realm}` / `{weather}` 等未约定占位符,Mac 端 wire 不替换 → 原样保留出现 bug。

**注**:池内"无占位符"是合法的(纯静态文案,如「此剑从此沾血」)。

### 红线 3 · 占位符语义分池约束(strict)

**语义**:占位符按池语义分流,不串台。

| 池 | 允许占位符 | 禁止占位符 | 理由 |
|---|---|---|---|
| `continued_lore_obtained` | `{source}` | `{boss_name}` / `{stage_name}` | 获得场景未必击败 Boss(可能 loot/奖励/拾取),且 `{source}` 已覆盖关卡/塔层来源语义 |
| `continued_lore_boss_defeated` | `{boss_name}` / `{stage_name}` | `{source}` | 击败场景语义明确,无需 source(stage_name 已含来源信息) |

**断言**:扫每条 text 占位符,按所属池查白名单。

**失败信号**:`<id> / <池名> / <条 idx>: 占位符 {<var>} 不属于此池`。

**理由**:防止 obtained 池写「斩 {boss_name}」(语义错位,获得时还没斩);防止 bossDefeated 池写「于「{source}」斩之」(冗余,应用 stage_name)。

### 红线 4 · 文案非空白 + 长度合理(strict)

**语义**:每条 text trim 后非空,字符数 ≤ 300。

**断言**:
- `text.trim().isNotEmpty`
- `text.length <= 300`

**失败信号**:`<id> / <池名> / <条 idx>: text 空白` / `text 超长 <N> 字`。

**理由**:空白条不可观感(玩家抽到空字符串);> 300 字超 GDD §6.6「1-3 行短典故」基调,违反水墨克制原则(派单 spec §4 风格)。

### 红线 5 · 网游词黑名单(strict)

**语义**:文案不出现网游风词汇,守 GDD §1 水墨克制 + §4 命名锁死。

**黑名单(扫每条 text 是否含)**:
- `传说之` `史诗` `神级` `无敌` `最强` `究极` `霸气` `逆天`
- `legendary` `epic`(英文混用)

**断言**:扫 text,任一黑名单词 → fail。

**失败信号**:`<id> / <池名> / <条 idx>: 含网游词「<word>」`。

**理由**:GDD §4 已锁死命名口径(用「寻常货」不用「普通装备」/ 用「神物」不用「传说装备」),lore 文案同样必须遵循。寻常货 / 神物两端 tier 风格梯度建议在派单 spec §5,本红线挡住极端违例。

### 红线 6 · soft · 文风审计报告(非 fail · 仅 warning)

**语义**:扫文案文风潜在问题,产 warning 报告不 fail test。

**扫描项**:
- 含 emoji(unicode `\u{1F300}-\u{1F9FF}` 等区间)
- 单条 text < 10 字(疑似敷衍)
- 同件 yaml 同池内出现完全重复的 text(疑似复制粘贴漏改)

**失败信号**:`print` warning 列表,**不 fail**。Mac 端二阶段决定是否反馈 DeepSeek 端微调。

**理由**:soft 约束便于 DeepSeek 端在合规前提下保留文学化表达自由,Mac 端只挡硬错。

## §4 spec 落地后的二阶段动作

DeepSeek 35 件全到位后,Mac 端按序跑:

1. `flutter test test/data/lore_loader_test.dart` — 含本 spec 5 strict 红线 + 已有 35 件红线
2. `flutter test test/features/event/application/game_event_service_test.dart` — 现有 24 case 不破(P1 #44 wire 已 +6 case 至 1117 pass)
3. 全 pass 后拍板:**删 fallback Dart 模板 vs 保留作 graceful degradation**(Mac 端二阶段决定,本 spec 不强约束 — 倾向保留,生产 yaml 极端损坏时不崩)
4. 若 fail,把 fail 列表反馈 DeepSeek 端,DeepSeek 修后 Mac 重跑直至全 pass

## §5 实施时长预估

| 步 | 工时 | 备注 |
|---|---|---|
| 本 spec 起草 | 0.3-0.5h | sonnet 主对话(本批) |
| 二阶段实装 5 strict + 1 soft red line | 0.5-1h | sonnet,加在现有 group 后,体例对齐 |
| DeepSeek 文案到位后跑测 | 0.1h | 命令级 |
| 修 fail 反馈循环 | 0.1-0.5h × N 轮 | 视 DeepSeek 端首次落地质量 |

**总计 1-2h Mac 端**(不含 DeepSeek 端 3-5h)。

## §6 硬约束沿用

- Mac+Opus 不动 `data/lore/<id>.yaml` 文案(DeepSeek 领地,CLAUDE.md §8)
- DeepSeek 端不改 schema 字段名(`continued_lore_obtained` / `continued_lore_boss_defeated` 已锁,改字段名 Mac 端 wire break)
- 占位符花括号 `{var}` 形式,不识别其他模板语法(memory `feedback_red_line_test_semantics`:写约束语义不写瞬时事实,本 spec 5 strict 红线全部为白名单/集合自洽体例,符合)
- 红线 case 失败信号必须**精确到 yaml id + 池名 + 条 idx**,便于 DeepSeek 端定位修(memory `feedback_closeout_numbers_grep`:测试断言用 file IO 实测,不靠记数)
- 测试用 `test()` 不 `testWidgets()`(本 spec 无 Isar 副作用,纯 yaml 解析层,默认 test() 即可)
- Mac git 走代理需 `HTTP_PROXY=""` 前缀(hook 自动清,通常不用手加)

## §7 与 P1 #44 wire / DeepSeek spec 的契约关系

```
DeepSeek 派单 spec ──→ DeepSeek 端 35 件文案落地 ──→ Mac 端 wire(已落)+ 本 spec 5 红线 case ──→ 全 pass = #44 闭环
        (schema 字段名 / 占位符约定 / 量级)         (35 × 2 池 文案)         (LoreLoader / GameEventService 已实装 + 红线挡硬错)
```

本 spec **仅定义验收侧契约**,不修改 wire 实装;DeepSeek 端不需要读此 spec(派单 spec 已含约定),仅供 Mac 端二阶段实装与跑测参考。

## §8 closeout

本 spec 定位:**Mac 端 P1 #44 二阶段验收红线 case 契约**。5 strict + 1 soft red line 覆盖漏件 / 占位符白名单 / 占位符语义分池 / 长度 / 网游词 / 文风审计 6 维度,**断言层均为约束语义而非瞬时事实**(memory `feedback_red_line_test_semantics`),DeepSeek 端文案池量变化不破红线(只要 ∈ [3,5] 区间)。

下波:① DeepSeek 端 Windows 派单(35 件文案落地 3-5h),Mac 端等回收;② 本 spec 实装可与 ① 并行(无依赖),sonnet 起手 0.5-1h 即可加到 `lore_loader_test.dart` L124 group 后。
