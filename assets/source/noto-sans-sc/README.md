# Noto Sans SC

用于 Godot Web 版中文 UI。Web 导出不能依赖玩家设备安装中文字体。

- 上游：[Google Fonts Noto Sans SC](https://github.com/google/fonts/tree/main/ofl/notosanssc)
- 原始字体：[`assets/runtime/fonts/NotoSansSC.ttf`](../../runtime/fonts/NotoSansSC.ttf)，保留原文件；许可证见 [OFL.txt](OFL.txt)（SIL Open Font License 1.1）。
- [WhalefallUI.ttf](../../runtime/fonts/WhalefallUI.ttf) 是原字体的静态子集：保留当前工程文本、拉丁字符与原默认字重，并使用新的字体名；原文件和 OFL 许可保留。
- 修改中文文本后运行 `python assets/source/noto-sans-sc/build-ui-font.py`（需要 `fonttools`），然后执行 `node tools/godot.mjs sync-art`。脚本读取 `game/src/` 与 `game/content/` 的文本，来源哈希、工具版本和输出大小记录在 [subset.json](subset.json)。
- 运行副本由 `game/art/manifest.json` 同步至 `game/art/fonts/`，`game/src/ui/theme.tres` 统一使用。`test_ui_font.gd` 检查实际字体覆盖当前工程的中文，避免后续内容缺字。
- 这是 UI 字体依赖，不计入角色、场景或动作素材数量。
