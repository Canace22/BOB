# 视频参考后的环境动态优化 · 2026-10-28

本轮只调整既有2D环境表现，复用已有47张位图，不新增玩法或声音。执行采用 game-production-pipeline 的纯场景分支及项目 consistent-2d-game-assets / bob-art-integration Skill。

## 输入和观察

- 构图和材质：`original/reference.png`。
- 用户视频：`F:/OtherProject/Downloads/Goolge/视频_bxK-0201.mp4`，约5.06秒，1280×720，24fps。抽查0–5秒代表帧，未试听音轨，不声称逐帧审片。
- 观察：道路和洞口大体稳定；垂须末端、鱼群和气泡有局部运动，右侧气泡较近。片段首尾不同，不是已证明无缝循环的视频。
- 原有实现：末端0.65px微摆、鱼群同步漂移、36个同类远泡。关闭动画重置时间，重新开启会跳变；Motion Strength 原先没有覆盖气泡。

## 本轮执行合同与结果

| 步骤 | 输入 | 产出 | 验收和下一步 |
|---|---|---|---|
| 核对母版 | 原图、视频、场景、Git状态 | 静动分组和优化前截图 | 保留道路/洞壁/前景/人物锚点 → 调整局部运动 |
| 调整动效 | 既有裁片、隐藏区补绘 | 修改环境脚本和根部权重Shader | 不超过已有裁片余量；无全屏形变 → 实机渲染 |
| 冻结与恢复 | 环境实例 | motion-checks.json、4张截图 | 9项通过，180秒模拟无累积；暂停/恢复/重载稳定 → 长时间运行 |
| 实际运行 | 固定机位、默认参数 | 72秒报告、24秒引擎录像 | 36气泡、161回收、无空纹理；P50 16.655ms/P95 17.012ms → 主场景接入回归 |
| 接入与交付 | 共用环境的R1-01、便携包 | 工程和包各27项检查、更新PCK | 全部通过；交付截图、视频、可调参数和限制 |

使用的实际工具是PowerShell、固定Godot 4.7.2 CLI及其渲染/录像、FFmpeg编码与解码、图片查看器。没有调用付费生成服务，没有新增或重绘贴图。既有补绘资产的来源保持原记录。

## 当前参数

- Foliage Amplitude Px：1.8，两个连续波叠加，各簇有相位差；顶部/侧壁固定区域沿用原权重。
- Fish Amplitude Px：8，分别28/34秒节奏，只有群组小范围漂游，不代表逐尾摆尾动画。
- 气泡总数仍36：33远泡、3右侧近泡；近泡9/12/15px，21/24/27px/s；近泡绘制在道路前、深色框景后。固定预热，有限回收。
- 灯与光束相位错开，亮度变化上限2%/1.2%；静帧初始状态保持原始亮度。
- Animate Environment关掉时保持当前姿态，再开启继续。Motion Strength作为0–1统一时间倍率，0冻结所有局部运动；单独幅度通过新增两个参数调节。
- Camera Drift默认关闭。此前微移视差仍可选，本轮未重做全部偏移机位检查。

本轮幅度和速度均为实现建议值，未经视频运动跟踪测量，不是从视频精确反推的参数。

## 证据与复跑

工程证据：`../../../godot/WhalebellyRuins/evidence/reference_environment/motion_refinement/`。其中motion-checks.json为确定性状态检查，runtime-report.json为72秒真实渲染统计，integration/reference-level-route.json为主游戏回归。180秒模拟不等同于180秒连续录像；录像24秒不是整场景首尾无缝循环承诺。

在工程目录使用固定Godot执行：

```powershell
& $GodotExe --path . --audio-driver Dummy --script res://tests/reference_environment_motion.gd
& $GodotExe --path . --audio-driver Dummy res://scenes/environment/xumen_reference.tscn -- --qa
& $GodotExe --path . --audio-driver Dummy -- --qa-reference-level --evidence=res://evidence/reference_environment/motion_refinement/integration
```

第三条运行既有接入检查，只写隔离QA存档。便携包使用同一参数，并把evidence设为可写绝对路径。不要把录像编码时间当实时渲染性能。24秒MP4全片解码无报错；实机0/2/5/11秒与编码18秒抽帧已目视检查，未声称逐帧人工审查。

## 限制与下一次制作指令

披风尚未独立拆件和动画；角色保持静态。鱼群仍整体漂游。视频中的大幅细丝形变未照搬：现有垂须含附着组织，只适合小幅变形。鱼群与顶部水体细节仍有此前补绘差异。近泡复用12px原泡纹理，继续放大需制作更高分辨率母版。未新增水面焦散、声音或其他视频未确认的效果。

下一次若继续提高表现：先拆分披风并补齐背后的躯干，保留头/脚/武器锚点；再制作有独立轮廓和尾部帧的鱼，最后扩大垂须变形。每件先做一个样板，真实引擎合成后检查透明边缘、根部、运动露底和比例，再批量接入。缺少清洁母版时不要直接扩大Shader幅度。
