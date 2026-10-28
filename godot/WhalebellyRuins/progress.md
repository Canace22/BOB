# 鲸腹遗城工程进度

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
