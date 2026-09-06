# 试玩阻塞修复

- 目标：修复暗器 Bot 近身停滞、原生音频并发悬挂/内存增长、减少闪光设置失效。固定修复范围 3 项，正式 M0–M9 仍 1/10。
- 分支：`codex/p2-combat-audio-accessibility-fixes-20260906`；基线 `57889e115fb0bb8b26944a07e446304158b02c97` clean。
- 成本：2026-09-06 13:20 CST 开始，主成本记录墙钟；90 分钟检查实际修复证据并重评，不扩 SDK/塔层/数值范围。
- 单一主 WIP：本批试玩阻塞修复；Bot → 音频 → 闪光串行进入同一候选。音频后端可独立复现和实施，主窗口统一审查、原生测量与集成。

## 验收标准

1. 生产 Bot 通过原 InputAdapter/reducer；近身、边界、五武器、战术继续输出，合法冷档暗器反例闭合。
2. 真实 AudioPlayersBackend 并发准备不重入、不积压无界请求，BGM/SFX/dispose 正常；原生带声双视口复测及十分钟内存/告警验证。帧门未通过则单独留明，不冒充 M4 完成。
3. 实际战斗消费减少闪光设置，命中/伤害不变；1280×720、1440×900 视觉检查。
4. 针对性 RED/GREEN、analyze、批末持锁全量、构建；代码审查、受控集成、精确 SHA CI 与 clean 状态。
5. 不改数值/三系/奖励/经济/schema/saveVersion，不改变在线离线共用内核；产品文案/数值沿用配置。原存档和用户试玩档保持不变。

## 当前恢复点

- 状态：READY，生产修复与直接验证完成，按既有授权进入受控集成；正式 M0–M9 仍 1/10，M4 帧门保留。
- 最后完成：合法冷档五武器×三战术均进入终局，暗器 30.8 秒胜；真实宿主双视口减少闪光/领域不变；音频 35/35，原生十分钟 285→320 MiB、峰 328 MiB、告警 0；Windows 同代码 build/startup PASS。
- 回归：首轮定向 106/106；完整 6091 PASS / 1 旧夹具 FAIL，夹具修正后相关 20/20。完整首轮失败及修正均保留；最终集成版本再跑一次持锁全量与精确 SHA CI，结果写 `delivery.json`。
- 下一步：最终全量及 CI 收口；验证试玩程序退出后替换已签名程序，三个试玩存档与设置保持哈希一致。冷备份和新包均已准备。
- 生产路径：Bot → InputAdapter → reducer 共核；四种宿主 → GameplaySettingsProvider → BattleScreen；SoundManager → 真实 AudioPlayersBackend 固定池及串行 BGM。
- 红线：无数值/配置/依赖/schema/奖励/解锁改动，原生产三存档哈希一致。临时冷副本和隔离签名包不冒充自然人。
- 残留：密集帧耗仍红，不能关闭 M4；真人、物理 Windows 输入/音频/GPU 和 72h 继续挂账。详情 `docs/audit/phase2_blocker_fixes_2026-09-06.md`，外部证据 `/Users/a10506/Documents/Codex/2026-09-06/wuxia-blocker-fixes/`。
