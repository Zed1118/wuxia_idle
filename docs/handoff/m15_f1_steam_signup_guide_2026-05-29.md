# F1 Steam Direct 注册 guide

> 起草:2026-05-29 · spec `m15_f_steam_spec_2026-05-29.md` Batch F1
> ☆ **关键路径**:F1 是 M15-16 lead time 最长瓶颈(~1 周)立即启动

## 入口

https://partner.steamgames.com/steamdirect — 登入日常 Steam 账号(不需新建)

## 7 步流程(顺序操作)

| Step | 内容 | 时长 | 关键 |
|---|---|---|---|
| 1 | 登入 + 同意 Steam Direct 协议 | 2min | — |
| 2 | 选注册主体:**Individual(个人)** | 1min | ✅ 推荐 Individual(1.x 公司化再升)|
| 3 | 填个人信息:姓名(护照拼音)/ 地址(大陆即可)/ 手机+邮箱(2FA)/ 出生日期+国籍 | 15min | 一次填对,改正需重 verify |
| 4 | **银行账户**:Payoneer 大陆账户(注册 1-3 天 · Steam 直连)优先 / fallback 招行 USD 借记卡 / 万里汇中转 | 1-3 天 | Step 1-3 信息可与此并行 |
| 5 | **W-8BEN 税务表**(海外 region 必填,免 30% 美国预扣税) | 10min + 1-3 天 verify | Part II 第 10 行填:`Article 7 · Paragraph 1 · Rate 0% · Royalties from sale of computer games`(中美税务协定)|
| 6 | $100 USD Steam Direct fee | 即时 | **不可退** · 慎重确认后再付 · 1 账号付 1 次 |
| 7 | 等待 Steam 人工审批 + 邮件通知 | 3-7 天 | 后台 dashboard 解锁 |

**总 lead time:~1 周**(关键路径起点)

## 关键注意

- ❌ 不要 VPN 注册(Steam 检测地理偏差延长审批)
- ❌ 不要小号 / 代练号(账号封禁无法发售)
- ✅ Step 1-3 + Step 4 并行启动(开户慢,先发起)
- ✅ 全程保留邮件 + 后台截图(F2 商品页 verify 可能用)
- ✅ W-8BEN 中美 1984 税务协定 0% 预扣税(IRS PDF 可查)

## 完成后

注册通过 → 通知 Claude 启动:
- **F2 商品页提交**(~3 周 lead time · Claude 起 trailer 脚本 + 截图 + Capsule MJ prompt + 中/英简介 + tag)
- **F3 成就接入**(纯工程 · Claude 主对话 ~4h · 9 成就)

## 阻塞 fallback

- Payoneer 失败 → 万里汇(PingPong)中转
- W-8BEN verify 卡 → 重填 / partner@steampowered.com(回复 ~3 天)
- Steam 人工审批卡 → 同邮件咨询

## 验收

- [ ] Step 1-3 信息提交
- [ ] Step 4 银行账户 verified(Penny test 收)
- [ ] Step 5 W-8BEN verified(0% 预扣税生效)
- [ ] Step 6 $100 支付成功
- [ ] Step 7 后台 dashboard 解锁
- [ ] 通知 Claude 进入 F2 商品页

---

**关键提示**:F2 商品页是 1.0 ship 前最长 lead time(~3 周审批 + 准备)。F1 完成后立刻启动 F2 准备。
