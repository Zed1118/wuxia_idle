# Phase 0A 丹房在线/离线一致性诊断

本文件由同一组 observations 生成；非更新模式逐字校验此文件与 CSV。

- 配方：brew_ningshen、brew_peiyuan、brew_liaoshang；丹房等级：1、3、5。
- 请求窗口：1.0、8.0、24.0、72.0、100.0 小时；分段数：4；场景总数：66。

| 配方 | 场景数 | 最大差异 | 瓶颈分类 |
|---|---:|---:|---|
| `brew_ningshen` | 21 | 5.684341886080802e-14 | herb, product_cap, rate|herb |
| `brew_peiyuan` | 21 | 1.4210854715202004e-14 | herb, product_cap, rate |
| `brew_liaoshang` | 24 | 5.684341886080802e-14 | herb, product_cap, rate|herb, spring |

理论产量由生产配置推导：`min(rate, herb, spring, product_cap)`。
正常场景使用合法最低源建筑等级 1；herb_starved/spring_starved 移除对应源建筑形成零可用量 fixture，丹房等级仍为 1/3/5。
一次结算与等分分段结算差异硬断言 `<= 1e-9`。
