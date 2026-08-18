# Phase 0C 工程嵌入验证报告

> 日期：2026-08-18
> 状态：`MAC_ENGINEERING_PASS / WINDOWS_AND_HUMAN_DEFERRED`
> 分支：`feat/phase0c-engineering-embed-verify-0818`(基于 main `a767fe91`)
> 上位:v2 方案 §11 Phase 0C / `docs/spec/2026-08-13-phase0a-gameplay-greybox-spec.md`
> 计划档:`docs/superpowers/plans/2026-08-18-phase0c-engineering-embed-verify.md`
> 裁决授权:项目主人 2026-08-18 拍板 6 人真人 Gate 与 Windows 实机后置

## 1. 验证对象

Phase 0A 生产表现层(Batch 1–9C 已合 main):
`lib/features/battle/{domain,application,presentation}/phase0a/`
(reducer + session + Ticker 驱动纯 Flutter 实现,路由
`phase0a_battle_playable` 等 4 条在产)。

## 2. v2 §11 Phase 0C 通过条件逐项裁决

| 通过条件 | 裁决 | 证据 |
|---|---|---|
| 连续进入/退出实时战斗 50 次无崩溃、输入失效或持续内存上涨 | **PASS(Mac·widget 口径)** | `phase0c_embed_verification_test.dart` 50 次 mount/unmount 零异常;每 10 次抽检键盘 attack 真实推进 tick + Esc 暂停通路;Ticker/FocusNode 泄漏由 flutter_test 框架 dispose 断言兜底(泄漏即红) |
| 常规窗口缩放、暂停和恢复通过 | **PASS** | 三视口(1280×720/1440×900/1152×648)切换整屏可重建且缩放后推进正常;Esc 暂停/继续本批实装(spec §3.1 缺口补齐):暂停中 tick 冻结零推进、键鼠不受理、纸幅横幅在位,恢复后推进复原、暂停中按键不补放;终局态 Esc 无效 |
| 正式存档前后校验无变化 | **PASS(架构级)** | phase0a 三层源码零 Isar/save 引用(静态守卫测试钉防回归);隔离非调用者自觉而是依赖缺失——生产层无持久化 import 路径 |
| 嵌入后目标档性能相对 0− 探针退化 ≤10% | **口径订正·Mac 基线成立** | 生产层为纯 Flutter、0− 探针为隔离 Flame,**非同载体**,帧时间直接对照不成立。批内替代基准:真实 fixture flow 全场 240 tick 结算,per-tick 91.1µs(JIT debug)= 16.6ms 帧预算的 0.55%,domain 模拟成本可忽略,帧成本由渲染主导。**正式帧时间对照待后置的 Mac Profile 实采(与 Windows 实机 Gate 同批执行)** |
| 授权与 Windows 构建链无未解阻塞 | **WINDOWS_DEFERRED** | 用户 2026-08-18 拍板后置;工具链已就绪(`ENGINEERING_READY`,33 项门禁测试在 `tools/phase0minus_probe/`) |

## 3. 附带裁决:Flame 生产去留

v2 §11 0C 要求「复核 Flame 验证结果并决定生产保留或更换」。事实:生产
表现层未引入 Flame(根 `pubspec.yaml` 零 flame 依赖),以纯 Flutter
reducer/Ticker 实现了同一玩法语义并经 Batch 1–9C 审计合入。裁决:
**Flame 仅保留为隔离探针载体(tools/phase0minus_probe),不进生产**;
0− 探针继续服务后置的 Windows/性能 Gate。

## 4. 破坏证红记录

反向补丁撤 Esc 暂停实装(commit `68317574` 全量逆应用)→ 恰 3 红:
50 次进退抽检 / 暂停中按键丢弃 / 暂停零推进,全部锚在暂停核心语义;
窗口缩放、存档守卫、终局 Esc(无横幅即过)按设计不依赖实装保持绿。
补丁正应用还原 → 6/6 复绿。

## 5. 批内守恒

- `flutter analyze --no-pub lib test` → No issues found
- 全量 `flutter test` → **5167 pass / 0 fail**(基线 5161 + 本批 6,逐值吻合)
- 新增文案走 `UiStrings.phase0aPausedBanner`,零硬编码中文

## 6. 遗留与移交

1. **后置硬门槛**(不阻塞本裁决,进正式生产前必须执行):6 人主观 Gate +
   目标最低档 Windows 实机(含帧时间对照,届时一并完成 §2 第 4 条的正式口径);
2. 暂停横幅为纸幅短条,真机观感并入试玩局目检(与一#19/#4/#5/#6 同局);
3. 50 次进退为 widget 口径,真机长时间 soak(分钟级 RSS 曲线)归入
   Windows 实机 Gate 的采集项。
