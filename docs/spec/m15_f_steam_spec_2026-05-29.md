# M15-16 F 段:Steam 集成 spec

> 起草:2026-05-29 · 目标 M15-16 · 对应 RELEASE_CHECKLIST §F · ROADMAP P5.4
> 关联 Q1-Q5 拍板:**Q1 海外 only** / **Q4 Demo 先上 Steam(P5.4b 替代 itch.io 中间态)**

## 1. 目标

CHECKLIST F 7 子项 0/7 → 7/7。Steam 开发者账号 + 商品页 + 7 大成就 + 云存档(可选)+ Steam Demo 上架 + MSIX 打包 + Sentry release 监控 + 商品页本地化(中/英)+ 评测应对。

## 2. lead time 关键路径(关键 ☆ 最优先启动)

```
☆ F1 Steam 开发者账号注册 (~3-7 天审批)
    ├─ Steam Direct $100 一次性
    ├─ 公司/个人选项 → 个人(独立开发,无需公司)
    └─ 银行账户 + 税务表 W-8BEN(海外 region 必填)
        ↓
☆ F2 商品页提交 (~2-4 周审批)
    ├─ 游戏名 / 简介(中/英)/ tag / 截图 / trailer
    ├─ Capsule images(主图 460×215 / 头部 616×353)
    └─ Coming Soon → 商品页上线 → 后续 Demo 上架
        ↓
F3-F7 工程集成(主对话推)
```

## 3. 拆 Batch

| Batch | 内容 | Claude 推 | 用户办 | 估时 |
|---|---|---|---|---|
| **F1 开发者账号** | Steam Direct 注册指引 + 银行账户 / 税务表填表指引 | 30% | **$100 + 个人信息 + 等审** | ~3-7 天 lead |
| **F2 商品页** | 游戏简介 / tag / 截图 / trailer 脚本起草(中/英)+ Capsule 美术 prompt(MJ v7 沿装备 icon 体例) | 70% | **拍最终文案 + 提交** | ~2-4 周 lead + ~3h Claude 推 |
| **F3 成就接入** | 7 大成就 schema + `steamworks_sdk` Flutter wrap + 触发 hook + 测试 | 100% | — | ~4h |
| **F4 MSIX 打包** | `flutter_distributor` + `msix` package + signing cert + 发布 pipeline | 100% | 数字签名证书(可选)| ~3h |
| **F5 Sentry release** | Sentry SDK + sourcemap + release 监控 + crash 自动上报 | 100% | Sentry 项目创建 | ~2h |
| **F6 Steam Demo 上架** | Steamworks 后台 Demo 配置 + build upload + Playtest 邀请池 | 50% | 后台配置 + 邀请 | ~3h Claude + 用户操作 |
| **F7 商品页本地化** | 中文(简体)+ 英文 商品页 + 描述本地化 + tag 翻译 | 80% | 用户拍最终翻译 | ~2h |

**总 Claude 推:~17h · 用户操作:账号注册 / 商品页提交 / Demo 后台配置 / Sentry 项目创建**
**lead time:F1 ~1 周 + F2 ~3 周 = ~1 月 buffer(CHECKLIST §F 已注)**

## 4. 7 大成就清单(Q4 拍板)

| ID | 名称 | 触发条件 | 稀有度估 |
|---|------|---------|---------|
| `ach_realm_first_tier` | 初窥门径 | 玩家境界达「三流」 | 95% |
| `ach_realm_wusheng` | 武圣降世 | 玩家境界达「武圣」 | 5% |
| `ach_ascend_first` | 步入飞升 | 完成第一次飞升 | 3% |
| `ach_chapter_three` | 名扬江湖 | 通关 Ch3 | 80% |
| `ach_chapter_six` | 飞升仪式 | 通关 Ch6 | 10% |
| `ach_inner_demon_clear` | 心魔克己 | 心魔挑战全 5 关 | 8% |
| `ach_mass_battle_clear` | 千军万马 | 群战守城全 5 关 | 5% |
| `ach_light_foot_clear` | 一苇渡江 | 轻功对决全 5 关 | 5% |
| `ach_lineage_full` | 师承不绝 | 师徒传承 3 代 | 2% |

**9 个成就**(CHECKLIST §F 标 7 大,本批扩 9 覆盖核心系统更全面 · 终版本批拍 ≥7 即可)

## 5. 决策点

| # | 问题 | 推荐默认 | 影响 |
|---|------|---------|------|
| F-Q1 | Steam Demo 模式:Steam Next Fest 申请 / 自主 Coming Soon Demo? | **自主 Demo**(Next Fest 1 年 2 次,lead time 慢) | F6 上架时机 |
| F-Q2 | 云存档:接 / 不接? | **不接**(Demo 单机存,1.x 加 Steam Cloud) | F 段子任务 -1 |
| F-Q3 | MSIX 数字签名:自签名 / DigiCert 商签? | **自签名**(Demo 期省钱 ~$300/年 商签,1.0 release 升商签) | F4 复杂度 |
| F-Q4 | Sentry 计费层:Free(5K events/月)/ Team($26/月)? | **Free**(Demo 期 < 1K 玩家)| F5 预算 |
| F-Q5 | 商品页 trailer:1 分钟纯演示 / 2 分钟带剧情 / 不做 trailer(Coming Soon 期截图 only)? | **1 分钟纯演示**(性价比 + 后续 1.0 升级 2 分钟) | F2 复杂度 |
| F-Q6 | 商品页 trailer 制作:OBS 自录 / 找外包? | **OBS 自录**(用户 Pen + 简单剪辑)| F2 预算 |
| F-Q7 | 价格:Demo $0 / 1.0 $? | **Demo $0**(免费试玩)+ **1.0 $14.99**(类比 Stardew Valley 定位)| F2 商品页 |

## 6. 子任务粒度

- **F1.1**:Steam Direct 注册指引 doc(`docs/handoff/m15_f1_steam_signup_guide.md`)
- **F1.2**:W-8BEN 填表指引(海外 only,免美国税)+ 银行账户(支持 USD 收款)
- **F2.1**:游戏简介中文 ~500 字 + 英文 ~300 words + tag 列表(20 个)
- **F2.2**:截图 8 张(主菜单 / 战斗 / 闭关 / 装备 / 心法 / 师徒 / 飞升 / Boss 战)+ trailer 脚本 ~1 分钟
- **F2.3**:Capsule images MJ prompt 起草 + 配 LoRA 武侠风格(沿装备 icon 体例)
- **F3.1**:`pubspec.yaml +steamworks` + Steamworks SDK 初始化
- **F3.2**:9 成就 `steam_achievements.dart` + 触发 hook + 测试
- **F4.1**:`flutter_distributor` 配置 + `msix` package + windows build
- **F4.2**:自签名 cert 生成 + MSIX 测试安装
- **F5.1**:`pubspec.yaml +sentry_flutter` + Sentry DSN + 自动 crash 上报
- **F5.2**:sourcemap upload pipeline + release tag
- **F6.1**:Steam Demo build upload + Playtest 邀请池组织
- **F7.1**:商品页中/英文本最终 + tag 本地化

## 7. 红线 / 风险

- **W-8BEN 表必填**(海外 region · 免美国 30% 预扣税)
- **Steam Direct $100 不可退**(慎重启动)
- **商品页提交后审批 ~2 周**,改商品页元数据需重审 → **首次提交务必拍准**
- **steamworks_sdk Flutter wrap**:目前社区有 `steamworks` package(2k star)但 maintain 不活,Phase 0 需 grep 替代 / fallback FFI
- **MSIX 自签名 → Windows SmartScreen 红屏**:玩家首次启动需手动允许 → 商签提前预算 ~$300/年(1.0 release 必须)
- **Sentry Free 5K events/月**:Demo 期若大规模 crash 会超额 → 需触发限流 + 升级 ROI
- **Demo 上 Steam ≠ 商品页上 Steam**:Demo 必须先有商品页(F2 → F6 串行)

## 8. 依赖 / 阻塞关系

- **F1 + F2 是其他全段的 lead time 瓶颈**:必须最优先启动
- F3-F5 工程独立(Claude 主对话并行推)
- F6 Steam Demo 依赖 F1+F2+D 段基线全过 + E 段 SoundManager 接入
- F7 本地化依赖 F2 商品页框架先定
- G 段「隐私+EULA」依赖 F2 商品页提交时勾选 EULA 模板

## 9. 验收

- [ ] F1 Steam 开发者账号通过审批 + 银行账户绑定
- [ ] F2 商品页 Coming Soon 上线 + 中/英本地化全
- [ ] F3 9 成就 Steam 后台配置 + 工程触发 + 测试 100% 解锁
- [ ] F4 MSIX 打包测试机器 4+ 台安装无报错
- [ ] F5 Sentry release 监控 + sourcemap + 自动 crash 上报
- [ ] F6 Steam Demo 上架 + Playtest 邀请 10 人(D6 closed beta 同源)
- [ ] F7 商品页中/英本地化完成 + tag 各 10+

## 10. closeout / 验收 doc

- 每 Batch:`docs/handoff/m15_f_<batch>_closeout_<date>.md` ≤80 行
- 最终段:`docs/handoff/m15_f_full_closeout_<date>.md` + CHECKLIST §F 7/7 全勾
