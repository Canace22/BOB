# 鲸腹遗城工程进度

## 2026-10-28 · 视频参考动态优化

仅优化共用参考环境：根部固定的双波微摆、两群鱼分相位漂游、33远泡+3近泡、分相位局部光变。默认固定镜头。新增摆动/鱼群幅度参数，统一时间倍率，关闭动画保持当前姿态，修复启停跳变。

验证：9项环境状态检查通过（含180秒模拟、冻结/恢复、树暂停、重载）；72秒实机36气泡回收161次，RTX5060帧间隔P50 16.655ms/P95 17.012ms，无空纹理；24秒30fps引擎录像及MP4完整解码通过。工程和更新便携包各27项首房接入回归通过，只使用隔离QA存档。未重做所有七房支线或音频试听。

证据 `evidence/reference_environment/motion_refinement/`；视频和包内回归 `G:/鲸落万物生/outputs/须门遗港_视频动态优化/`。说明与当前参数见 `../../../assets/source/xumen-reference-environment/motion-refinement.md`。同步更新一致性2D素材Skill和源素材README。披风仍静态、鱼群非逐尾动画，细丝素材边缘继续沿用已记录限制；本批没有新增位图或完整复刻视频全部形变。

## 2026-10-28 · 单工程合并

- 唯一开发目录：`BOB/godot/WhalebellyRuins`，显示名 `Whalebelly Ruins · 鲸腹遗城`。
- 合并前 first-level-artmatch 的七房运行代码、分层场景及最新声音为当前版本；first-level 独有资产保留，旧逻辑/冲突件移入忽略导入的历史目录。
- 三个输入工程的源文件已独立ZIP备份，并检查CRC与复制后的SHA256；缓存可以由Godot重建。清单见 `../../docs/godot-consolidation.json`。
- Godot 4.7.2 导入通过，无解析/导入错误。主路通关与独立存档重载记录在 `evidence/consolidation/`，最终结果以其中JSON及合并清单为准。
- 项目迁移不清除玩家存档；保留 `WhalefallArtmatchV05` 数据目录。旧first-level存档保留在其原用户目录，不强行混用。

## 音频接续记录

迁移前最后一轮已恢复WASAPI输出；用户确认能听到声音，但指出旧音色刺耳/重复。已制作11类×3变体、24秒柔和水流底音，接入限流与声部上限。用户随后确认“明显改善，可以保留”。这些代码和素材已包含在合并后的工程。

音频技术记录：`evidence/audio-refined-project/`、`audio-refined-package/`、`audio-refinement-final/`。历史`.production/state.json`和旧图册中的设备阻塞描述早于该反馈；本记录明确保存新结论。本次合并回归使用Dummy以免重复播放声音，不冒充新的试听验收。

## 仍待完善

- 独立分层素材的平台/锚环周边仍有原图背景残留，需要定向精修。
- 最终包真实窗口关闭曾受系统桌面访问限制；自动测试正常退出与实际点击窗口关闭分开记录。
- 本次只合并Godot工程，没有发布或改变Web原型，也不因目录整理宣称完整关卡的全部美术验收通过。

最终迁移验证：只发现1个project.godot；19项正常首访检查通过，0死亡；独立进程恢复通过；导入和运行日志无ERROR/WARNING。三个旧工程因永久删除被策略阻止，改为移出开发区封存并停用入口。


## 2026-10-28 · 本轮图片环境场景

新增 `scenes/environment/xumen_reference.tscn`，仅环境/展示角色，无玩法碰撞和控制器，不替换main.tscn。46独立贴图节点+4区36气泡；50元素合同、47运行PNG，原件/SVG/补绘/布局与指令齐备。

本轮执行：固定机位截图、六组独显、四机位微移、32秒实际运行、24秒Godot录像、MP4全片解码、47素材与节点引用校验、零物理节点。RTX5060帧间隔P50 16.666ms/P95 16.761ms，36气泡回收70次；无空资源。

视觉边界：隐藏区补绘有细部色差，垂须裁片含固定附着组织，非通用精修单物件。小幅镜头验收不代表大幅移动完成。操作/来源见 `../../../assets/source/xumen-reference-environment/README.md`，证据 `evidence/reference_environment/`，交付页位于项目外 `outputs/须门遗港_参考图环境场景/交付与对照.html`。本批不发布Web版本。

## 2026-10-28 · 参考图环境接入实际地图

R1-01替换为参考环境实例，固定比例接入，重描路面碰撞，移除展示角色并接入Player；保留其他房间。修正旧环境重复、分层调试、暂停/镜头以及旧档路面坐标。工程与便携PCK实际往返/控制/复活27项、跨进程重载2项通过，证据`evidence/reference_level/`。构建缺少发行模板，按已有方式交付官方便携程序＋PCK。素材限制和音频验证边界见资产源integration/README.md。

独立包7房加载/出生碰撞冒烟均通过（各4层、落地true）；本轮没有重新跑全关Boss/支线战斗回归。

## 主场景编辑器同步

显式保存LevelMap，共享源环境；首房启动复用，其他房间启动清理初始实例。45个环境贴图的资源/变换/层级无差异，27项回归、R1-02直接启动及更新便携包启动通过；证据`evidence/main_scene_sync/`，绑定/运行说明见资产源integration/README.md。

## 2026-10-28 独立环境动画

R1-01与独立预览共用103个环境元素；48鱼/12帧图集、根部固定垂须、植物、36气泡、光束、焦散、独立前景与既有角色镜头跟随。没有新增玩法或碰撞。
17项环境状态、4项渲染循环、27项既有主场景回归通过；64秒真实渲染录像、32秒视差录像；无录制64秒P50 16.664ms/P95 16.844ms（RTX5060）。固定引擎+PCK独立启动截图通过，修复打包只读资源路径写证据问题。
来源、编辑母版、限制与接续：../../assets/source/xumen-motion-elements/README.md；证据：evidence/motion_elements/。主要形体与层级已检查，细小透明边缘仍可能有近看差异；未宣称人工逐帧连续审片。Web版本未发布。

## 顶部背景水面修正

按用户圈选：水面改为顶部远景独立纹理折射，删除中部/底部浮动焦散实例。102个运行元素；6项水面实机范围/遮挡/循环检查、17项环境检查和4项渲染循环检查通过。原交付页视频已切换本轮20秒水面/32秒视差录像；主关卡共享环境。证据：evidence/motion_elements/water-surface/。
## 2026-10-28 拾潮者动作评审场景

新增 `scenes/characters/locomotion_preview.tscn`，F6预览IDLE/Walk/Run各8帧。绘图来源、Blender序列工程、帧序/锚点与限制见 `../../assets/source/tide-picker-locomotion-v01/README.md`。本批没有替换主关卡角色，没有改动存档或发布Web游戏。

固定Godot4.7.2导入通过；`--headless --script res://tests/locomotion_assets.gd`通过24纹理、透明角、播放推进、暂停、循环、状态切换检查。真实渲染截图为 `evidence/locomotion-v01/playback-a.png` 与 `playback-b.png`。技术通过不等于美术签收：前后腿身份和支撑节奏仍需精修，资产保持candidate。
