# 当前唯一工程：WhalebellyRuins

先读[统一工程说明](../../docs/godot-project.md)和[最新进度](progress.md)。下方为合并前交接内容；音频设备已恢复且用户已认可新版声音，勿把旧阻塞当当前结论。所有后续开发仅在本目录。

# 接续入口

1. 先读取本文件、.production/state.json、docs/element-manifest.json、docs/coverage-readiness.md。
2. 已有七房源件、可编辑遮罩、分层图、正常玩法、实际证据和独立包；不要重新生成全部图片，也不要覆盖旧v0.4。
3. 尚需恢复/选择可用Windows默认音频输出。当前Audiosrv服务运行，但Godot WASAPI ERR_CANT_OPEN并回落Dummy；不能用Dummy证明设备发声。
4. 音频可用后运行以下真实命令并保存新日志：

```powershell
& 'C:/Users/Kingsoft/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe' --path 'G:/鲸落万物生/BOB/godot/WhalebellyRuins' --script res://tests/audio_devices.gd
& 'C:/Users/Kingsoft/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe' --path 'G:/鲸落万物生/BOB/godot/WhalebellyRuins' --script res://tests/audio_mixer.gd
```

5. 只有driver=WASAPI且混音/独立包设备输出实际通过，才更新该全局阻塞。不要把以前成功、现在失败或主观未试听相混同。
6. 若源文件改动：先按manifest的摘要使依赖验收失效；只复测受影响项。完整重建母版脚本是 work/r1_v05_build.py（会重生成scene/mask并把阶段恢复in_progress，因此一般无需重跑）；图形capture是work/r1_v05_capture.py；包是work/r1_v05_package.py；交付册是work/r1_v05_delivery.py。
7. 当前构建是官方便携exe+导出PCK，不依赖未安装的export templates；正式发行前再采用发行模板构建和人工玩法/审美签收。

8. 分层边缘待返修：assets/runtime/layers/R1-02/World.png 的平台/锚环周边仍含源图背景。需逐物件精细分割，复验独显、合成和最大视差后再更新相关PNG/PCK；此前全局色键删坏地形的方案已撤回。
9. 最终包本次真实窗口关闭测试遇交互桌面拒绝访问；保留受阻记录。独立包自动流程正常退出通过，不冒充点击窗口关闭通过。桌面恢复后重跑正常窗口关闭脚本。
