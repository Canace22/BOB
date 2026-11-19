# 第一章 · 鲸须庭探索预览

用于试玩第一章的空间连接和地牢转场，使用项目的 Godot 4.7.2。独立入口是 `res://content/prototypes/chapter01/main.tscn`，正式游戏默认入口不变。

## 操作与运行

- `A / D` 或左右方向键移动，`空格`跳跃，靠近通路后按 `E` 穿门。
- `R` 回到入口并重置本次探索，`F` 切换全屏。
- 主路、滤缝尽头、上下层回环与返程索均可走；抵达守口场后，预览中的返程索开放。该条件只服务地图预览，不代表完成 Boss 战。

当前已验证入口是原生桌面预览：

```sh
node tools/godot.mjs run -- res://content/prototypes/chapter01/main.tscn
```

使用 `GODOT` 环境变量指定 Godot 4.7.2。原生入口使用独立会话，不读取正式主线存档。

历史 Web 工具 `tools/chapter01-preview.mjs` 和 `tests/web_chapter01.mjs` 保留供参考。其构建依赖仍引用旧版 gate、idle 与四层背景路径，尚未跟随下方完整环境场景迁移，当前不能把它当作可用启动入口。需要 Web 预览时应先迁移依赖并重新导出验收；本次提交未导出或发布。

## 地图与转场

空间关系来自[第一章设计数据](../../../../docs/鲸腹遗城原画集/章节设计/data/maps-01-05.json)。本地 `layout.json` 配置十个稳定房间 ID、房名、复用外观和十一组双向通路。门的左右方向使用约 0.62 秒推镜；上下维护口使用暗场遮蔽、切换落点再淡入。转场期间冻结角色移动，进入位置由目标房间的反向门计算。

十个房间：巡视缝入口、补巢者住巢庭、低鸣须根台、滤缝观察窝、松须窄廊、旧巢修补台、守口前观察台、夹须甲魁守口场、战后运巢栈道、折井下行口。

这十个逻辑房间复用现有环境场景与对应地形轮廓，角色复用既有站立和跑步资源；未制作十套独立房间原画。上下门复用已有骨拱通道素材，不安排战斗、NPC 对白、道具或持久进度。

## 工具与验收（Web 部分为历史记录）

Web 导出使用与本机一致的官方 4.7.2 模板。将官方模板包中的 `templates/web_nothreads_release.zip` 放入 `.tools/godot-templates/`；构建脚本检查版本后使用它。模板、导入缓存、Web 包、截图与报告均不入库。

该示例没有声音，Web 启动在引擎创建前明确选择 `Dummy` 音频驱动，因此不依赖要求安全上下文的 AudioWorklet，可通过普通内网 HTTP 试玩。仅此独立预览采用该方式；正式游戏音频与 Web 入口不变。

```sh
node tools/godot.mjs check
node tools/godot.mjs test
node game/tests/web_chapter01.mjs
```

最后一条使用独立 Playwright 上下文和真实键盘，检查跳跃落地、十房通行、死路返回、返程索前后状态、推镜／井道暗场、重置和刷新；只读 `render_game_to_text()`，不提供传送或状态写入接口。可用 `CHAPTER01_URL` 指向内网入口，`PLAYWRIGHT_MODULE` 指定已有依赖。证据留在 `game/build/qa/chapter01/`。


## 2026-11-18 · 资源路径修复

旧预览已改用当前入库资源：待机帧在`art/whalebelly/animations/player/body/idle/000.png`；竖向通道复用`art/doorways/tunnel.png`，按150像素高度等比缩放并对齐门点。首房复用`content/whalebelly/environment/xumen_reference.tscn`的关卡模式，其余房复用`environment/chapter/R1-02`至`R1-07`完整场景。完整场景包含补底和环境动件，不能只替换为四张静态分层PNG，否则动件的挖空会变黑。预览仍使用自己的碰撞、路线和会话探索记录，不接主线战斗和存档。

原生资源专项实际按键验证待机/接地、行走、横向E转场、竖向E转场和会话访问记录；这不替代全部十房自然路线验收。`test_chapter01_dynamic_room_art_paths_load`覆盖十房引用的完整环境资源加载。
