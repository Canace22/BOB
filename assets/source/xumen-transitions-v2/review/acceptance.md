# E02 本地验收

AI执行与视觉检查，用户审美单独记录。

- 固定Godot4.7.2：check-final0错误，test-final57/57，resources missing=[]。
- qa-savewait14/14；完整连通full-e0238/38；reload-savewait独立进程2/2。实际E02双向Input及同角色、原26地形、Boss封锁保持。
- visual-final：三个机位及关闭前景后结构均已查看，错误日志为空；最后局部水色选区也在原生GPU重看。更远的原房边缘仍留后续清理范围，不算整章精修完成。
- e02-clean-final-local：Chrome10/10，真实D/A/Space往返、同角色、暂停、28秒环境播放，errors=[]。起点是原有房间预览键2，后续跨房不是预览跳转。
- 无录像暖机：RTX5060/1280×720/Compatibility，中位16.656ms，p9517.587ms；只代表固定环境样本。
- camp读档最初失败：测试在0.5秒交互动画完成前退出，未落盘；等待65帧后14/14及独立2/2通过，未改变玩法或存档格式。完整连通测试的camp内存断言不能代替落盘。
- 浏览器初版仅D行走在原须筛坡面停住，添加真实Space跳跃后通过；没有修改碰撞以迁就测试。

线上发布另记production.json及game/progress.md。实际声音状态通过，未增加新音色或人工听感签收。
