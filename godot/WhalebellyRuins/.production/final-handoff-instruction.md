# 最终交付核对与返修接续

输入：冻结的 scripts、assets、七房场景、element-manifest.json 和实际 evidence。

本轮执行：
1. 用固定 Godot 4.7.2 图形渲染执行 tools/export_layers.gd，重新导出43项层/角色，防止交付旧色键版本。证据 final-native-export.log。
2. work/r1_v05_package.py 导入并导出新PCK，再运行便携EXE正常首访，核对normal-run.json整体和每个测试项，而非只看退出码。
3. 重载必须使用 --qa-normal-reload。旧 --qa-reload 是另一套flow哨兵，失败JSON保留，不与正式通关档混用。
4. 退出清理分别记录自动graceful、模拟窗口通知和真实窗口关闭。--quit-after强制退出不能替代后两者。最终真实窗口关闭受桌面拒绝访问影响，不改为通过。
5. 核对独立导出可玩层。发现平台和锚环旁的源图背景残留，登记为素材交付返修，不允许以固定机位合成通过抵消。
6. 文档冻结后执行 work/r1_v05_delivery.py，再执行 work/r1_v05_finalize.py。校验HTML所有本地链接、资产数量、正常通关/重载JSON，更新状态和构建摘要与ZIP。

定向返修：
- 图层：从R1-02的World层样板开始，逐个描绘平台和锚环透明边缘；检查蓝色附带背景与软组织薄边，不能全局色键删蓝。保留源件；用新遮罩在固定机位与最大视差位置验证，不通过则保留失败版本和复现图。
- 音频：可用Windows播放设备恢复后，测试实际WASAPI和独立包声音；Dummy只用于隔离玩法/性能，不能关闭此阻塞。
- 窗口：交互桌面恢复后运行 work/verify_package_normal_close.ps1，正常关闭实际窗口，核对退出码、清理标记和无泄漏。仅回收本任务启动的进程。

通过条件：独立素材边缘、设备声音、真实窗口关闭全部有实际证据，再刷新覆盖表与整体验收。当前不满足，overall_accepted保持false。
