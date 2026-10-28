# 本轮实际执行记录与返修

1. 读取圈选图及现有分层、固定Godot4.7.2，检查Blender4.2.0；MCP未连接，选择独立CLI。
2. Godot原生Image提取四组paint输入、登记jobs.json；已有近景根片保持静态。
3. Blender构建带UV网格/形态键、透明正交相机，先试渲染关键帧。
4. 返修：预览发现旧抠图带蓝色碎片；补充尖端包络/根部连通筛选，重新渲染；中央区域定向再次清理。旧日志保存在review供本地诊断，不将失败预览作为最终帧。
5. 正式渲染288张PNG；Godot原生打包8×9图集；integrate_baleen_blender.py接回同一场景。
6. verify_blender.py与frame-checks.json记录几何/循环/透明边缘；Godot定向测试、相关回归和真实录制。
7. deliver_baleen_blender.py制作四组独立视频、更新布局SVG和原交付页；固定版本官方引擎+PCK独立启动验证。

返修原则：只修改被识别的问题组；必要时使用build_blender.py -- --only=<ID>，随后重新打包、场景检查。手工修改.blend后不要用自动构建覆盖；从保存母版直接渲染。已知限制与验收边界见README。
