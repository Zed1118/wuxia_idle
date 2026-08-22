# Route C 双平台 Gate 收口

> 裁决：`PASS`；Gate commit：`597a243b2506610b5cbb74e2919be79bbf99e283`；该 commit 已快进合入 `main` 并推送 `origin/main`。

## 工程结论

- 旧 3v3 产品源码、路由、启动工具与专属测试已原子删除；五个生产消费面统一使用 Phase 0A 单角色 ARPG 与同核 headless reducer。
- `flutter test --no-pub`：4218/4218 PASS。
- `flutter analyze --no-pub lib test tool`：0 issues。
- 删除树、生产消费者、证据 commit/AOT/fixture 一致性与主机声明经独立 Route C preflight 裁决为 PASS。
- 用户已取消六人真人 Gate；本轮不采集 P01–P06，也不把历史问卷或 Phase 0/0B probe 当作 Gate 证据。

## Mac 本地物理机矩阵

- 1280×720 三轮 p99：5.579ms、5.349ms、5.535ms。
- 1440×900 三轮 p99：5.371ms、5.649ms、5.754ms。
- 六轮均 PASS，连续严重慢帧均 0，样本帧 8624–8630，逻辑视口精确。
- ZIP：`/private/tmp/wuxia-dsh-delete-route-c-0822/build/route_c_macos_matrix/597a243b-final.zip`
- ZIP SHA-256：`f074b963e143bdd72de26f4e2347c346fd025ab478930fde22700457beabd238`
- AOT payload SHA-256：`ce70e726956055c652cdad405c6b0616f0da66bb7374fab1130ae23ec2772c22`

## Windows 本地物理机矩阵

- 主机：Ryzen 7 5800X、RTX 4070 SUPER、16GB、143Hz；本地 Console、非 RDP、非 VM、100% 缩放。
- 1280×720 三轮 p99：3.416ms、3.499ms、3.514ms。
- 1440×900 三轮 p99：3.573ms、3.539ms、3.471ms。
- 六轮均 PASS，连续严重慢帧均 0，样本帧 8625–8648，逻辑视口精确，GC 遥测完整。
- Windows 保留证据：`C:\Users\Administrator\Desktop\wuxia-route-c-b99a0dae-lf\build\route_c_windows_matrix\597a243b-final`
- Mac 回传 ZIP：`/private/tmp/wuxia-dsh-delete-route-c-0822/build/route_c_windows_597a243b-final.zip`
- ZIP SHA-256：`f48adcc600b8d609f5ccb597e2b2ca5a4b915985125ef1dce38c750f089a5fae`
- AOT `app.so` SHA-256：`73faa6e1b7120e88d5795c03c8081fa95f7933814a1e7c0960c7b68a02eb8916`
- 主机 manifest SHA-256：`d363b5ed3d06485beeaac71c363fd2189b50ffe3030a0f44952cf0923c774183`

## 共同绑定与范围

- fixture SHA-256：`ad10b473acc77fc84002ff6a2f023d0b1212512f64a49a113094d8fc20ef3fa4`
- Windows 证据包 34 项 checksum 已在 Mac 端独立复核全部通过。
- Windows renderer 按 Flutter 3.41.5 默认链路记录为 `Skia (ANGLE/Direct3D)`。
- 本结论只证明上述 Windows 实体机生产兼容性，不定义或证明产品最低配置；后续 commit 或新 AOT 不得沿用本证据冒签。
- 本轮未 deploy。
