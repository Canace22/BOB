# 须门遗港：全要素验收与接续

本文件为实际证据审阅结果，不以文件存在或日志没有脚本错误代替功能完成。美术/场景/数据已冻结；退出清理及独立构建已验证；独立素材返修、硬件音频与真实窗口关闭仍未通过。

## 当前结果

- 263 个唯一元素合同，包含 225 个固定对象/观察簇、38 个程序生成规则。观察簇可以共享渲染节点，225 不是 Godot 节点总数。
- 1022 个游戏内运行维度：1022 通过、0 待验证、0 未确定规格、0 当前已知合成画面失败。元素声音维度只签数字事件/混音，设备输出仍是blocked的整体验收。
- 整体验收 7/10 通过；独立图层资产 fail，音频设备输出及真实窗口关闭 blocked。独立便携程序正式通关/正确档重载已通过。`all_required_passed=false`。
- JSON 记录每项的素材、坐标、数量、运行节点、行为、适用性与证据；同目录 review-decisions 为审阅决定，reconcile 脚本可重新生成统计。初始合同保存在 element-manifest.baseline.json。

## 已运行验证

| 范围 | 真实证据 | 结果与边界 |
|---|---|---|
| 正式首访 | evidence/normal/normal-run.json | 19项通过；普通无能力开局连续01→05，实际击败Boss取得A1，0死亡；不是把F9全能力路线当首访 |
| 基础输入与支路 | evidence/flow/flow.json、controls.json | 33项路线/战斗检查及8项控制检查；移动、跳跃、冲刺、浮游、抓环、攻击、暂停、静音和死亡恢复 |
| 主角与营地 | evidence/flow/actors-camps.json | 13项通过；01/04/05实体营地、动作切换/脚点、Boss钳前摇/有效/恢复 |
| 舌台下层 | evidence/deep/deep-route.json | 8项通过；承重下沉、S+Space下钻、下层左右探索、中央弹返、回主路出口 |
| 高处奖励与封闩 | evidence/revisit/revisit.json | 28项通过；03普通跳跃取奖；06明示回访练习取高处奖、远侧闩拒绝、本路返02 |
| 补漏实例与边界 | evidence/elements/elements.json | 29项通过；七房库存，06两块补漏地形，07四环双向与右壁，四个主路反向门，05三软床和07两沟落体fixture |
| 持久状态 | normal/normal-reload.json、revisit/reward-reload.json、elements/reward7-reload.json | 独立进程恢复正式A1/完成/BossID/门状态、03/06/07奖励及安全落点；07奖励节点实际隐藏 |
| 机关时序 | evidence/mechanisms.json | 10/10；膜42px shader与碰撞同步、卸载恢复、Boss门状态、锚环事件/脉冲、奖励漂浮/隐藏 |
| 动态及暂停 | evidence/dynamics.json | 七房生成规则/时钟同步通过；近景代表房01实际两机位与两时刻截图，暂停/恢复/参考冻结通过 |
| 数字声音 | evidence/audio-mixer.json、audio-pcm-analysis.json、environment-fade.json | 实际Master波形非零/不削波/有变化；淡入、换房尾音淡出和释放规则通过。不能替代当前扬声器输出 |
| 帧率 | evidence/benchmark.json | RTX5060、1280×720、60fps cap，七房各120预热+300采样；p95约16.70–17.52ms，所有样本<25ms。此轮Dummy音频后端，不推断低配设备 |

## 视觉审阅

AI已对照七张最新实际固定机位截图反查九宫格和边缘。此前蓝水色键误删暗组织、台岸破洞和大块异色边界已修正；目前源图可见部分由四层互补保留，独立角色、门、奖励和钳接入真实状态。

`dynamic-camera-left/right.png`、`dynamic-motion-a/b.png` 是实际近景画面，角色脚点、平台边缘与敌人可读；未见此前露空或组织大块侵蚀。近景目视代表房为01，七房动态时钟与数量分别有运行快照。此为AI审阅，未声称用户审美签收。

**独立分层资产未通过**：不仅layer-0有源图残片，`assets/runtime/layers/R1-02/World.png` 的台阶与锚环周边还保留大块蓝色背景，不能称精细透明分件。完整合成保持原图不等于各层可自由重组。母版已交付，但透明边缘及遮挡后区域仍须逐对象精修；GLOBAL-LAYER-ASSETS与SYS-ASSET-DELIVERY明确fail。

## 必须保留的边界

- 原图鱼群/气泡光点为静态观察簇；新增缓游鱼/上升泡另列designed生成器。05/06的补充鱼为0；不能说每一条源图鱼都独立动画。
- 06/07能力来自后续章节，当前通过F9临时练习回访。退出练习恢复正式状态；练习测试不计作正式成长路线。
- 05中间缝仅23px，小于28px玩家胶囊。三软床测试以间隙内的初始落体fixture检验触发、扣血和回岸，不冒充自然步行跌落。
- 07两沟fixture检验落到底界后的扣血/回岸与抓环inactive后置状态，初始抓环已inactive，未声称测试了活动抓环中断。

## 尚未通过及接续

1. **硬件声音输出受阻**：`evidence/audio-devices.log` 中WASAPI `ERR_CANT_OPEN`，fallback Dummy，只有Default输出。系统服务/设备可见不等于Godot已输出。保留数字混音通过与设备输出blocked两种状态。父代理正在等待设备侧信息；本任务未修改系统音频设置。
2. **已修复的压力退出问题**：先前4个WAV/PlaybackWAV引用警告保留于elements-lifecycle-before.log。清理Tween/音频/场景并等待实际mix周期后，elements-lifecycle-after.log为29/29且无警告，startup-exit-clean.log普通启动退出亦无警告；七项生命周期已补签pass。
3. **独立图层必须返修**：先精修World02平台/环alpha，按对象蒙版与补绘，不再用全局蓝色色键误删组织。独显透明底与完整重合成都通过后才补签资产交付。
4. **真实窗口关闭未验**：package-startup-clean/result.json记录最终EXE启动，但捕获超时/GetCursorPos拒绝访问令Alt+F4未成功。强制回收只作清理。桌面输入恢复后重跑work/verify_package_normal_close.ps1。
5. **独立包已通过部分**：package-normal/normal-run.json 19/19、0死亡；package-reload/normal-reload.json正确正式档恢复通过。旧reload.json用错flow哨兵导致pass=false，保留失败历史；未以process exit0代替重载通过。43PNG已重导，数量成功不代表独立边缘质量通过。

仍未通过项目完成前不得把关卡称为“全部必需维度和整体验收通过”。源代码、场景或资产变化后，按element-manifest.json中的SHA256输入快照重验受影响证据。
