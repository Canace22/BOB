# V3 垂须接入主关卡

Godot唯一工程 `godot/WhalebellyRuins`，固定4.7.2.stable.official.ed1daf0bf，Compatibility。F5主入口 `scenes/main.tscn` 的 R1-01 与 F6 环境预览共用 `scenes/environment/xumen_reference.tscn`，现均已使用顶部三组新版垂须。

[实际主关卡录像](main-gameplay.mp4) · [主关卡截图](main-gameplay.png) · [固定视角替换前](before-fixed.png) · [固定视角替换后](after-fixed.png) · [测量与构建结果](result.json)

## 替换内容

- 左、中、右三处共用一张3072×2304图集，每格384×384，48帧，12FPS，4秒循环。相位偏移分别为0、13、29帧。
- 所有实例只做等比缩放、旋转及必要镜像，保留源绘画材质和末端延迟摆动。具体附着点、变换和帧数在 `placements.json`，可在Godot Inspector继续调整。
- 新绘画的根部位于洞顶后方，near节点z=-1；静态洞顶和附着组织遮住根带。六份旧ROOT资源逐一检查：左侧01含骨枝与藤蔓，完整保留；其它旧帘根部贴图清除重复静态细丝，右侧06保留壁缘。干净绘画与遮罩在 `master/`，来源及处理数量见 `static-cleanup.json`，原素材未覆盖。
- `BALEEN-DISTANT` 实际包含整块蓝色远景岩柱，原资源与36帧播放保持原状。替换为乳白小簇会破坏场景结构，因此不作同类替换。
- 主控、房间地形/路线/碰撞、鱼群、气泡、水面和音效逻辑未改。`protected-before.json` 与构建报告核对主脚本、主角场景、rooms.json、引擎配置及远柱场景的SHA256未变化。

## 实际验证

- 23项GPU环境定向检查：三处实际图集引用、48帧/12FPS、独立相位、等比尺度、根部变换稳定、仅垂须推进时道路/前景不变、两轮后截图完全一致。另实际输出左右相机边界截图。
- 14项GPU主场景检查：新动画实际播放、单一游戏角色、暂停/继续、环境开关、速度归零、当前控制器移动/跳跃、显式切换房间并返回，以及新鱼群保留。
- 现有环境总体验证通过，包括180秒加速状态模拟、气泡边界/回收和视差；此模拟不作为实时性能数据。
- 实际主关卡录制165帧、24FPS、6.875秒，见 `main-gameplay.mp4`。视频记录的是实际引擎运行与当前控制器测试，动画素材自身仍按12FPS播放。录像是测试过程，包含换房和暂停，不是新的动画源。
- 另运行10秒不录制环境采样：P50 16.673ms、P95 16.834ms，RTX5060 / OpenGL，约132MB贴图内存。它是环境预览采样，不代表所有关卡和机器的性能。
- 导出到临时PCK后，用现有独立EXE启动同样14项主场景检查，通过后替换 `G:/鲸落万物生/builds/WhalebellyRuins/WhalebellyRuins.pck`。包体及保护文件哈希见 `result.json`。采用既有官方便携程序+PCK，未冒称发行模板导出。

QA模式隔离真实玩家存档，本轮没有修改保存格式。测试使用Dummy音频，未重新验收物理扬声器；本轮没有音效修改。房间切换检查调用现有 `load_room`，没有将其宣称为本轮完整七房通关。

静态实机全景、近景、相机两端及动画不同相位已由代理复核。最终自然度与用户实际试玩感受分开记录。首次清理曾裁掉左骨枝/右壁缘，已按实际图修回；返修前图保留为 `cleanup-repair-before.png`。

## 文件与复跑

源制作与Krita母版：[上级说明](../README.md)。运行素材：`assets/runtime/baleen-loop-v3/`，Godot内副本：`assets/baleen_loop_v3/`。元素清单、场景布局JSON和SVG同步更新。

在BOB根目录用已有生产Python执行 `tools/integrate_baleen_loop_v3.py` 可重建本次接入；会覆盖这三处布局和派生清理贴图，手工改动前保存副本。当前原始输入备份为 `xumen-before.tscn.txt` 及三份 `*-before.tscn.txt`。总环境生成器在旧版本接入后再应用V3，避免静默退回旧图集。

固定Godot运行 `--path godot/WhalebellyRuins --audio-driver Dummy --script res://tests/baleen_loop_v3.gd -- --baleen-mode=environment` 或 `--baleen-mode=main`。证据在工程 `evidence/baleen_loop_v3/`；总体验证脚本是 `tests/motion_elements_qa.gd`。打包验证脚本为 `tools/package_baleen_loop_v3.py`；不必重新生成Wan视频。
