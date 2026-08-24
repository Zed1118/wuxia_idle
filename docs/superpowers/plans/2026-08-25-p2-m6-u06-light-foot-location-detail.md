# P2-M6-U06-LIGHT-FOOT-LOCATION-DETAIL 计划

## 目标

把江湖地图的轻功试炼入口从直接进入关卡列表改为先展示生产地点详情，再沿原有战斗门禁进入关卡列表。

## 生产合同

- 只读聚合真实轻功解锁链、已通进度、下一可挑战关、推荐境界、地形、敌人与掉落配置。
- 只读展示当前掌门，不实装未签字的任意角色选择、差遣、前台 bot 或 headless 解锁。
- 异常、无掌门、配置链不唯一、无可用关卡时 fail closed，不显示进入 CTA。
- 五条路线全部完成时显示完成态，但保留从详情页进入原列表重打。

## 红绿与验收

1. 先提交地点详情 provider、UI、地图路由的真实红测。
2. 实装最小 domain/provider/screen 纵切，不改轻功关卡战斗流。
3. 运行聚焦测试、相邻江湖地图/轻功回归、1280×720 与 1440×900 布局、全仓 analyze 和一次全量测试。
4. 独立语义复核 P0/P1=0；更新 audit、registry 与权威文档，检查白名单和 `git diff --check`。
5. 产出 clean `[READY][CODEX][P2-M6-U06-LIGHT-FOOT-LOCATION-DETAIL]` tip，不合并、不 push、不修改 main。
