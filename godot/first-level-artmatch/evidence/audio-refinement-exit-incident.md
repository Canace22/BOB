# 音频修订后的退出回归记录

首次重打包：正常主路 `passed=true deaths=0`，但退出日志出现 `4 ObjectDB instances were leaked` 和 `2 resources still in use`；因此打包脚本判失败，没有将退出判为通过。

同包增加verbose后重跑：见 `audio-package-lifecycle/run.log`，正常主路通过且退出干净；短程七房声音压力测试也无警告。说明此残留不是每次必现，未获得确切泄漏对象类型，不声称已证明单一根因。

定向处理：退出等待从“下次混音+输出延迟”调整为“输出延迟+三个测得混音周期”，并在deferred释放前后保留帧边界，让停止命令与后续播放资源释放跨越多个混音更新。没有隐藏、过滤或抑制引擎警告。

修订后须以最终package-normal、package-reload及三次短程生命周期日志判断复测结果。正常通关报告的pass和进程退出资源清理分开判断。
